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
secrets.zsh           # Untracked, gitignored — API keys go here
install.sh            # Fresh-machine bootstrap (sources bin/_lib.sh)
macos.sh              # Opt-in macOS system defaults
Brewfile              # Executable source of truth for brew packages
bin/                  # Maintenance commands (bench-doctor/update/export, _lib.sh)
.githooks/pre-commit  # gitleaks + shellcheck + zsh -n on staged files
.claude/              # Statusline command + Claude Code rules/settings
ghostty/              # Ghostty terminal config
home/                 # Dotfile templates symlinked via Stow
docs/                 # Package snapshots, replayed by install.sh (offline-readable)
```

## Conventions

- Modern CLI tools: `eza` (ls), `bat` (cat), `fd` (find), `rg` (grep), `xh` (curl)
- Internal paths use `$ZSH_SETTINGS_DIR` (set by `init.zsh` self-discovery — no hardcoded install location)
- Global npm/bun packages preferred over system installs
- `/opt/homebrew` hardcoded — Apple Silicon only (Intel Macs not supported)

## Verified facts & conventions

Durable, human-confirmed facts for this repo (merged from per-project memory; keep versioned here).

- **`CLAUDE_CODE_*` env duplication is intentional.** The same `CLAUDE_CODE_*` keys live in both `exports.zsh` and `.claude/settings.json` `env`. Keep both copies — do not flag them as duplicates or remove either side in reviews or `/simplify` passes. (User confirmed twice.)
