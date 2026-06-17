#!/usr/bin/osascript -l JavaScript
// ghostty-grid.js: tile all Ghostty windows into a dynamic grid on the main display.
ObjC.import('AppKit');

function run() {
  var GAP = 8;        // gap between windows and at screen edges (matches Moom)
  var APP = 'Ghostty';

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

  // --- gather real Ghostty windows ---
  var se = Application('System Events');
  if (!se.processes[APP].exists()) return;
  var wins = se.processes[APP].windows().filter(function (w) {
    if (w.subrole() !== 'AXStandardWindow') return false;
    try { if (w.minimized()) return false; } catch (e) {}  // Ghostty omits AXMinimized
    return true;
  }).map(function (w) {
    var p = w.position();
    return { w: w, x: p[0], y: p[1] };
  });
  var n = wins.length;
  if (n === 0) return;

  // Stable order: sort by current top, then left (reading order), not z-order.
  // Makes tiling idempotent: each window keeps its cell across runs, so nothing jumps.
  wins.sort(function (a, b) { return (a.y - b.y) || (a.x - b.x); });

  // --- grid dimensions: cols = ceil(sqrt n), rows = ceil(n/cols) ---
  var cols = Math.ceil(Math.sqrt(n));
  var rows = Math.ceil(n / cols);
  var cellW = (workW - GAP * (cols + 1)) / cols;
  var cellH = (workH - GAP * (rows + 1)) / rows;

  // --- place each window, row-major (last row left-aligned) ---
  for (var i = 0; i < n; i++) {
    var col = i % cols, row = Math.floor(i / cols);
    var x = Math.round(workX + GAP + col * (cellW + GAP));
    var y = Math.round(workY + GAP + row * (cellH + GAP));
    var w = wins[i].w;
    w.position = [x, y];
    w.size = [Math.round(cellW), Math.round(cellH)];
    w.position = [x, y];   // re-apply: window may shift when resized
  }
}
