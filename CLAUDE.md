# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

Personal zsh configuration and dotfiles for Apple Silicon macOS. Contains shell initialization, aliases, exports, plugins, fzf integration, and terminal configuration (Ghostty, Starship prompt).

## Structure

```
init.zsh              # Main entry point, self-discovers $ZSH_SETTINGS_DIR
exports.zsh           # PATH, env vars (sources secrets.zsh if present)
aliases.zsh           # Shell aliases
fzf.zsh               # fzf config + helper functions
plugins.txt           # Antidote plugin list (plugins.zsh is generated, gitignored)
starship.toml         # Starship prompt config
secrets.zsh           # Untracked, gitignored — API keys go here
install.sh            # Fresh-machine bootstrap
ghostty/              # Ghostty terminal config
home/                 # Dotfile templates (.gitconfig, .vimrc, commit template)
docs/                 # Package manifests (brew, bun, gem, npm, pip, sdks)
```

## Conventions

- Modern CLI tools: `eza` (ls), `bat` (cat), `fd` (find), `rg` (grep), `xh` (curl)
- Internal paths use `$ZSH_SETTINGS_DIR` (set by `init.zsh` self-discovery — no hardcoded install location)
- Global npm/bun packages preferred over system installs
- `/opt/homebrew` hardcoded — Apple Silicon only (Intel Macs not supported)
