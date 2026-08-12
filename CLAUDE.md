# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

Personal zsh configuration and dotfiles for Apple Silicon macOS. Contains shell initialization, aliases, exports, plugins, fzf integration, and terminal configuration (Ghostty, Starship prompt).

## Structure

```
init.zsh              # Main entry point, self-discovers $ZSH_SETTINGS_DIR
exports.zsh           # PATH, env vars (sources secrets.zsh if present)
aliases.zsh           # Shell aliases
functions.zsh         # Shell functions (fkill, cdf, gs, gshow, v, fview, diff)
fzf.zsh               # fzf defaults + preview command env vars
plugins.txt           # Antidote main plugins (plugins.zsh generated, gitignored)
plugins-post.txt      # Antidote post-compinit plugins (fzf-tab)
starship.toml         # Starship prompt config
ripgreprc             # rg defaults, wired via RIPGREP_CONFIG_PATH in exports.zsh
secrets.zsh           # Untracked, gitignored - API keys go here
install.sh            # Fresh-machine bootstrap (sources bin/_lib.sh)
macos.sh              # Opt-in macOS system defaults
Brewfile              # Executable source of truth for brew packages
bin/                  # Maintenance commands (bench-doctor/update/export, _lib.sh)
macos/                # Hotkey-driven scripts (ghostty-grid.js, idea-reset-layout.py); bound in skhd/skhdrc
skhd/                 # skhd hotkey config, symlinked to ~/.config/skhd/skhdrc by install.sh
fonts/                # Only fonts with verified redistribution rights (repo is public); free families come as Brewfile font casks
.githooks/pre-commit  # gitleaks + shellcheck + zsh -n on staged files
.claude/              # Statusline command + Claude Code rules/settings
.codex/               # Codex CLI config
ghostty/              # Ghostty terminal config
home/                 # Dotfile templates symlinked via Stow
docs/                 # Package + machine-state snapshots, replayed by install.sh (offline-readable); fonts.txt (restore checklist) and secret-keys.txt (expected key names) are hand-maintained, never dumped by bench-export; repos.txt (default clones) is hand-maintained in its selection, with bench-export repointing an entry whose clone moved or was renamed
```

## Conventions

- Modern CLI tools: `eza` (ls), `bat` (cat), `fd` (find), `rg` (grep), `xh` (curl)
- Internal paths use `$ZSH_SETTINGS_DIR` (set by `init.zsh` self-discovery, no hardcoded install location)
- Global npm/bun packages preferred over system installs
- `/opt/homebrew` hardcoded, Apple Silicon only (Intel Macs not supported)

## Behavioral rules

Project rules live in `.claude/rules/*.md` (relative to this file). Files with no YAML frontmatter are always-on: read and apply them this session. Files with a `paths:` frontmatter list apply only when editing files matching those globs. Claude loads these natively and excludes the global `~/.claude/rules` here via `claudeMdExcludes`. Codex and pi must read `.claude/rules/` themselves and ignore the global set. These project rules supersede it.
