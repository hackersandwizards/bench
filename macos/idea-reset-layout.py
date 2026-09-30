#!/usr/bin/env python3
"""Normalize IntelliJ IDEA tool-window weights by anchor (see fix()), drop each
project's dialog bounds (WindowStateProjectService) and each window's frame bounds
in recentProjects.xml, the home window's included, and delete window.state.xml /
window.layouts.xml plus .layout-backups, which holds copies of both and survives a
config import into the next major version. Quit IDEA first."""
import re, shutil, subprocess, sys
from pathlib import Path

JB = Path.home() / "Library/Application Support/JetBrains"

if subprocess.run(["pgrep", "-f", "IntelliJ IDEA.app"],
                  stdout=subprocess.DEVNULL).returncode == 0:
    sys.exit("Quit IntelliJ IDEA first, then re-run.")

def fix(tag):  # set weight by anchor (add if missing); no anchor == left
    w = "0.33" if 'anchor="bottom"' in tag or 'anchor="right"' in tag else "0.165"
    if "weight=" in tag:
        return re.sub(r'weight="[^"]*"', f'weight="{w}"', tag)
    return tag[:-2].rstrip() + f' weight="{w}" />'

for cfg in JB.glob("IntelliJIdea*"):
    for ws in (cfg / "workspace").glob("*.xml"):
        if ws.name.startswith("."):
            continue
        text = ws.read_text()
        new = re.sub(r'<window_info\b[^>]*/>', lambda m: fix(m.group(0)), text)
        new = re.sub(r'\s*<component name="WindowStateProjectService"(?:\s*/>|>.*?</component>)',
                     "", new, flags=re.S)
        if new != text:
            tmp = ws.with_name(ws.name + ".tmp")
            tmp.write_text(new)
            tmp.replace(ws)  # atomic: never leave the workspace half-written
            print(f"weights and dialog bounds reset: {ws}")
    recent = cfg / "options" / "recentProjects.xml"
    if recent.exists():
        text = recent.read_text()
        new = re.sub(r'\s*<frame\b[^>]*/>', "", text)
        if new != text:
            tmp = recent.with_name(recent.name + ".tmp")
            tmp.write_text(new)
            tmp.replace(recent)
            print(f"frame bounds cleared: {recent}")
    for name in ("window.state.xml", "window.layouts.xml"):
        f = cfg / "options" / name
        if f.exists():
            f.unlink()
            print(f"deleted: {f}")
    backups = cfg / ".layout-backups"
    if backups.is_dir():
        shutil.rmtree(backups)
        print(f"deleted: {backups}")
