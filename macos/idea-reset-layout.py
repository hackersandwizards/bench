#!/usr/bin/env python3
"""Normalize IntelliJ IDEA tool-window weights by anchor (see fix()) and delete
window.state.xml / window.layouts.xml. Quit IDEA first."""
import re, subprocess, sys
from pathlib import Path

JB = Path.home() / "Library/Application Support/JetBrains"

if subprocess.run(["pgrep", "-f", "IntelliJ IDEA.app"],
                  stdout=subprocess.DEVNULL).returncode == 0:
    sys.exit("Quit IntelliJ IDEA first, then re-run.")

def fix(tag):  # set weight by anchor (add if missing); no anchor == left
    w = "0.33" if 'anchor="bottom"' in tag else "0.33" if 'anchor="right"' in tag else "0.165"
    if "weight=" in tag:
        return re.sub(r'weight="[^"]*"', f'weight="{w}"', tag)
    return tag[:-2].rstrip() + f' weight="{w}" />'

for cfg in JB.glob("IntelliJIdea*"):
    for ws in (cfg / "workspace").glob("*.xml"):
        if ws.name.startswith("."):
            continue
        text = ws.read_text()
        new = re.sub(r'<window_info\b[^>]*/>', lambda m: fix(m.group(0)), text)
        if new != text:
            tmp = ws.with_name(ws.name + ".tmp")
            tmp.write_text(new)
            tmp.replace(ws)  # atomic: never leave the workspace half-written
            print(f"weights set: {ws}")
    for name in ("window.state.xml", "window.layouts.xml"):
        f = cfg / "options" / name
        if f.exists():
            f.unlink()
            print(f"deleted: {f}")
