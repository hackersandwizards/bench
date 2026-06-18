#!/usr/bin/osascript -l JavaScript
// ghostty-grid.js: tile all Ghostty windows into a dynamic grid on the main display.
ObjC.import('AppKit');

function run() {
  var GAP = 8;        // gap between windows and at screen edges (matches Moom)
  var APP = 'Ghostty';

  // Single-window target: when only one Ghostty window is open, snap it to this
  // reference geometry (top-left x/y, width/height) instead of maximizing it.
  // Captured from a manually-placed window; re-read with:
  //   osascript -l JavaScript -e 'Application("System Events").processes["Ghostty"].windows.position()' (and .size())
  var SOLO = { x: 352, y: 125, w: 1352, h: 948 };

  // --- main (primary) display work area, converted to AX top-left coords ---
  var screens = $.NSScreen.screens;
  if (screens.count === 0) return;
  var primary = screens.objectAtIndex(0);   // index 0 = primary (menu-bar) display
  var vf = primary.visibleFrame;             // work area, bottom-left origin (excl. menu bar/Dock/notch)
  var H = primary.frame.size.height;         // full display height, for the top-left flip below
  var workX = vf.origin.x;
  var workY = H - (vf.origin.y + vf.size.height);  // flip to top-left
  var workW = vf.size.width;
  var workH = vf.size.height;

  // --- gather Ghostty windows. Bulk reads: one Apple Event each, not one per window ---
  var se = Application('System Events');
  if (!se.processes[APP].exists()) return;
  var proc = se.processes[APP];
  var refs = proc.windows();
  var subroles = proc.windows.subrole();     // all subroles in a single round-trip
  var positions = proc.windows.position();   // all positions in a single round-trip
  var wins = [];
  for (var i = 0; i < refs.length; i++) {
    if (String(subroles[i]) === 'AXStandardWindow') {
      wins.push({ w: refs[i], x: positions[i][0], y: positions[i][1] });
    }
  }
  var n = wins.length;
  if (n === 0) return;

  // One window: restore the reference geometry, don't tile or maximize.
  if (n === 1) {
    var only = wins[0].w;
    only.size = [SOLO.w, SOLO.h];          // size before position: position write is then authoritative
    only.position = [SOLO.x, SOLO.y];
    return;
  }

  // Stable order: sort by current top, then left (reading order), not z-order.
  // Makes tiling idempotent: each window keeps its cell across runs, so nothing jumps.
  wins.sort(function (a, b) { return (a.y - b.y) || (a.x - b.x); });

  // --- grid dimensions: cols = ceil(sqrt n), rows = ceil(n/cols) ---
  var cols = Math.ceil(Math.sqrt(n));
  var rows = Math.ceil(n / cols);
  var cellW = Math.round((workW - GAP * (cols + 1)) / cols);
  var cellH = Math.round((workH - GAP * (rows + 1)) / rows);

  // --- place each window, row-major (last row left-aligned) ---
  // Size before position: the position write is then authoritative, so no re-apply.
  for (var j = 0; j < n; j++) {
    var col = j % cols, row = Math.floor(j / cols);
    var w = wins[j].w;
    w.size = [cellW, cellH];
    w.position = [Math.round(workX + GAP + col * (cellW + GAP)),
                  Math.round(workY + GAP + row * (cellH + GAP))];
  }
}
