#!/usr/bin/osascript -l JavaScript
// Tile all Ghostty windows into a grid on the primary display.
ObjC.import('AppKit');

function run() {
  var GAP = 8;        // edge and inter-window gap, matches Moom
  var APP = 'Ghostty';

  // Lone-window spot. Center is scaled to the current work area (refW x refH), so
  // it lands in the same relative place on any screen. Size stays as captured, but
  // shrinks to fit a work area smaller than the window (never grows past capture).
  // Re-capture: read .position()/.size(), subtract workX/workY, set refW/refH to the work size.
  var SOLO = { x: 924, y: 206, w: 1352, h: 948, refW: 3200, refH: 1770 };

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

  // Bulk reads: one Apple Event per property, not one per window.
  var se = Application('System Events');
  var proc = se.processes[APP];
  if (!proc.exists()) return;
  var refs = proc.windows();
  var subroles = proc.windows.subrole();
  var std = [];                              // indices of standard (tileable) windows
  for (var i = 0; i < refs.length; i++) {
    if (String(subroles[i]) === 'AXStandardWindow') std.push(i);
  }
  var n = std.length;
  if (n === 0) return;

  if (n === 1) {
    var s = Math.min(1, workW / SOLO.refW, workH / SOLO.refH);    // shrink to fit, never grow
    var soloW = Math.round(SOLO.w * s), soloH = Math.round(SOLO.h * s);
    var cx = workX + (SOLO.x + SOLO.w / 2) / SOLO.refW * workW;   // captured center, scaled to work area
    var cy = workY + (SOLO.y + SOLO.h / 2) / SOLO.refH * workH;
    var only = refs[std[0]];
    only.position = [Math.round(cx - soloW / 2),                 // position before size, see the loop
                     Math.round(cy - soloH / 2)];
    only.size = [soloW, soloH];
    return;
  }

  // Grid (2+ windows). Positions feed only the stable sort below, so read them
  // here — the lone-window path above skips this Apple Event.
  var positions = proc.windows.position();
  var wins = std.map(function (i) { return { w: refs[i], x: positions[i][0], y: positions[i][1] }; });

  // Sort by top then left so each window keeps its cell across runs (idempotent).
  wins.sort(function (a, b) { return (a.y - b.y) || (a.x - b.x); });

  var cols = Math.ceil(Math.sqrt(n));
  var rows = Math.ceil(n / cols);
  var cellW = Math.round((workW - GAP * (cols + 1)) / cols);
  var cellH = Math.round((workH - GAP * (rows + 1)) / rows);

  // Position before size. macOS clamps a size write to keep the window on-screen
  // from its current spot, but never clamps a position write. Move first, then
  // the full cell fits and the size lands in one pass. Size-first needs two runs.
  for (var j = 0; j < n; j++) {
    var col = j % cols, row = Math.floor(j / cols);
    var w = wins[j].w;
    w.position = [Math.round(workX + GAP + col * (cellW + GAP)),
                  Math.round(workY + GAP + row * (cellH + GAP))];
    w.size = [cellW, cellH];
  }
}
