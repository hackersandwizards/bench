#!/usr/bin/osascript -l JavaScript
// Tile all Ghostty windows into a grid on the primary display.
ObjC.import('AppKit');

function run() {
  var GAP = 8;        // edge and inter-window gap, matches Moom
  var APP = 'Ghostty';

  // Lone-window geometry. Re-capture a hand-placed window with:
  //   osascript -l JavaScript -e 'Application("System Events").processes["Ghostty"].windows.position()' (and .size())
  var SOLO = { x: 352, y: 125, w: 1352, h: 948 };

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
  if (!se.processes[APP].exists()) return;
  var proc = se.processes[APP];
  var refs = proc.windows();
  var subroles = proc.windows.subrole();
  var positions = proc.windows.position();
  var wins = [];
  for (var i = 0; i < refs.length; i++) {
    if (String(subroles[i]) === 'AXStandardWindow') {
      wins.push({ w: refs[i], x: positions[i][0], y: positions[i][1] });
    }
  }
  var n = wins.length;
  if (n === 0) return;

  if (n === 1) {
    var only = wins[0].w;
    only.position = [SOLO.x, SOLO.y];      // position before size, see the loop
    only.size = [SOLO.w, SOLO.h];
    return;
  }

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
