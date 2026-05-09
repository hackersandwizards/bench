Terminal setup for hackers&wizards: zsh, Ghostty, Starship, fzf, modern CLI replacements. macOS Apple Silicon only.

> [!CAUTION]
> **Highly opinionated. Don't install blindly.**
>
> Every choice reflects specific tooling preferences. Walk through the files with an AI agent (Claude Code, Cursor, etc.) before running `install.sh` so you understand:
> - what gets installed (Brewfile: brew packages + Ghostty cask)
> - what gets configured globally (Stow symlinks home/ → $HOME, line appended to `~/.zshrc`, Ghostty config symlink)
> - which choices wouldn't fit your setup

## Setup

```bash
git clone <repo> ~/opt/zsh-settings
cd ~/opt/zsh-settings
./install.sh        # interactive wizard, idempotent, re-runnable
./macos.sh          # optional: ~45 macOS system defaults
```

The wizard handles each step opt-in: `brew bundle`, Stow symlinks, `~/.gitconfig.local` generation, repo-local git hooks, `~/.zshrc` source line, Ghostty config symlink.

## File structure

```
init.zsh              Main entrypoint (sourced from ~/.zshrc)
exports.zsh           PATH + env vars (sources secrets.zsh if present)
aliases.zsh           Aliases
functions.zsh         Shell functions (fkill, fview, cdf, gs, gshow, v, diff)
fzf.zsh               fzf config + ANSI color mapping
plugins.txt           Antidote plugin list (core)
plugins-post.txt      Antidote plugin list (post-compinit)
starship.toml         Starship prompt
Brewfile              brew bundle source-of-truth
install.sh            Interactive wizard
macos.sh              Opt-in macOS system defaults
secrets.zsh           Untracked, gitignored. API keys go here
bin/
  _lib.sh               Shared helpers (step/ok/warn/skip/have, STOW_FILES, ANTIDOTE_SH, REPO_ROOT)
  bench-update          Update brew, antidote, language tools, globals
  bench-export          Refresh Brewfile + docs/ snapshots + sync home/ from $HOME
  bench-doctor          Health check
home/                 Stow package — symlinked into $HOME
  .gitconfig            Aliases, delta, includes ~/.gitconfig.local
  .gitignore_global     .DS_Store, IDE noise, etc.
  .commitTemplate.txt   Conventional commit message template
  .vimrc, .mongorc.js, .tmux.conf
  .ssh/config           Hardened (Keychain, ControlMaster, no ForwardAgent)
ghostty/              Ghostty terminal config (single source of truth for theme)
docs/                 Package inventory snapshots (committed; portable)
.claude/              Claude Code statusline + rules + settings
.rtk/                 Token-saving CLI proxy filters
.githooks/pre-commit  gitleaks + shellcheck + zsh -n (repo-local)
```

## Theming — Ghostty as single source of truth

The 16 ANSI palette colors plus `background`/`foreground`/`cursor`/`selection` in `ghostty/config.ghostty` are the **only** color definitions in this repo. Every other tool inherits via ANSI indices:

| Tool       | How it inherits                                          |
|------------|----------------------------------------------------------|
| starship   | ANSI color names (`cyan`, `bright-black`, …)             |
| bat        | `BAT_THEME=ansi`                                         |
| fzf        | `FZF_DEFAULT_OPTS --color=fg:0,bg:-1,hl:4,…`             |
| delta      | `minus-style = syntax`, `plus-style = syntax`            |
| vim        | no `termguicolors` → terminal palette                    |
| tmux       | named colors in status-style                             |

To change the theme: edit the `palette` section in `ghostty/config.ghostty`. All tools follow automatically.

## Maintenance

```bash
bench-doctor                   # verify everything is wired up
bench-update                   # upgrade brew, antidote, rust, ruby, python, bun, sdkman
bench-export                   # snapshot installed packages + sync home/ from $HOME
ZSH_PROFILE=1 zsh -i -c exit   # profile shell startup (zprof report)
```

## Pre-commit hook

`.githooks/pre-commit` runs gitleaks (secrets), shellcheck (`*.sh`), and `zsh -n` (`*.zsh`) on staged files. Repo-local — does not affect other projects. Activated automatically by the install wizard.
