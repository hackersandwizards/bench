#!/usr/bin/osascript -l JavaScript
// Tile visible Ghostty windows into a grid on the primary display.
ObjC.import('AppKit');
ObjC.import('Foundation');

function sleep(seconds) {
  $.NSThread.sleepForTimeInterval(seconds);
}

function attr(win, name, fallback) {
  try {
    return win.attributes.byName(name).value();
  } catch (_) {
    return fallback;
  }
}

function sameFrame(win, x, y, w, h) {
  var p = win.position();
  var s = win.size();
  return Math.abs(p[0] - x) <= 2 &&
         Math.abs(p[1] - y) <= 2 &&
         Math.abs(s[0] - w) <= 2 &&
         Math.abs(s[1] - h) <= 2;
}

function setFrame(win, x, y, w, h) {
  var lastError = null;
  for (var attempt = 0; attempt < 3; attempt++) {
    try {
      // Position before size. macOS clamps a size write to keep the window
      // on-screen from its current spot, but never clamps a position write.
      win.position = [x, y];
      win.size = [w, h];
      sleep(0.06);
      if (sameFrame(win, x, y, w, h)) return;
    } catch (e) {
      lastError = e;
    }
    sleep(0.06);
  }
  throw new Error('Ghostty window did not settle at requested frame' +
                  (lastError ? ': ' + lastError : ''));
}

function run() {
  var GAP = 8;        // edge and inter-window gap, matches Moom
  var APP = 'Ghostty';

  // Lone-window spot. Fixed size, center scaled to the current work area (refW x refH),
  // so it lands the same on any screen.
  // Re-capture: read .position()/.size(), subtract workX/workY, set refW/refH to the work size.
  var SOLO = { x: 352, y: 86, w: 1352, h: 948, refW: 2056, refH: 1290 };

  // Primary display work area, flipped from AppKit bottom-left to AX top-left.
  var screens = $.NSScreen.screens;
  if (screens.count === 0) return;
  var primary = screens.objectAtIndex(0);
  var vf = primary.visibleFrame;             // excludes menu bar, Dock, notch
  var H = primary.frame.size.height;
  var workX = vf.origin.x;
  var workY = H - (vf.origin.y + vf.size.height);
  var workW = vf.size.width;
  var workH = vf.size.height;

  var se = Application('System Events');
  var proc = se.processes[APP];
  if (!proc.exists()) return;
  var wins = [];
  for (var i = 0, count = proc.windows().length; i < count; i++) {
    try {
      var win = proc.windows.at(i);
      if (String(win.subrole()) !== 'AXStandardWindow') continue;
      if (attr(win, 'AXMinimized', false)) continue;
      if (attr(win, 'AXFullScreen', false)) continue;

      var pos = win.position();
      wins.push({ w: win, x: pos[0], y: pos[1] });
    } catch (_) {
      // Window vanished or AX refused one read; tile the remaining windows.
    }
  }
  var n = wins.length;
  if (n === 0) return;

  if (n === 1) {
    var cx = workX + (SOLO.x + SOLO.w / 2) / SOLO.refW * workW;   // captured center, scaled to work area
    var cy = workY + (SOLO.y + SOLO.h / 2) / SOLO.refH * workH;
    setFrame(wins[0].w, Math.round(cx - SOLO.w / 2),
             Math.round(cy - SOLO.h / 2), SOLO.w, SOLO.h);
    return;
  }

  // Sort by top then left so each window keeps its cell across runs (idempotent).
  wins.sort(function (a, b) { return (a.y - b.y) || (a.x - b.x); });

  var cols = Math.ceil(Math.sqrt(n));
  var rows = Math.ceil(n / cols);
  var cellW = Math.round((workW - GAP * (cols + 1)) / cols);
  var cellH = Math.round((workH - GAP * (rows + 1)) / rows);

  for (var j = 0; j < n; j++) {
    var col = j % cols, row = Math.floor(j / cols);
    setFrame(wins[j].w,
             Math.round(workX + GAP + col * (cellW + GAP)),
             Math.round(workY + GAP + row * (cellH + GAP)),
             cellW, cellH);
  }
}
