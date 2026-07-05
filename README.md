Terminal setup for hackers&wizards: zsh, Ghostty, Starship, fzf, modern CLI replacements. macOS Apple Silicon only.

> [!CAUTION]
> **Highly opinionated. Don't install blindly.**
>
> Every choice reflects specific tooling preferences. Walk through the files with an AI agent (Claude Code, Cursor, etc.) before running `install.sh` so you understand:
> - what gets installed (Brewfile: brew CLI packages, GUI app casks — Ghostty, browsers, editors, Office, Slack, … — Mac App Store apps, and VS Code extensions)
> - what gets configured globally (Stow symlinks home/ → $HOME, line appended to `~/.zshrc`, Ghostty config symlink)
> - which choices wouldn't fit your setup

## Setup

```bash
git clone <repo> ~/opt/zsh-settings
cd ~/opt/zsh-settings
./install.sh        # interactive wizard, idempotent, re-runnable
./macos.sh          # ~45 macOS system defaults (also offered as an install.sh step)
```

The wizard handles each step opt-in: `brew bundle`, Stow symlinks, `~/.gitconfig.local` generation, `gh`/`glab` logins, repo-local git hooks, `~/.zshrc` source line, Ghostty config symlink, language-ecosystem globals (uv/npm/bun/cargo/gem/pip), SDKMAN + JVM SDKs, Safari favorites merge, Dock layout replay (`docs/dock.txt`), Finder sidebar merge (`docs/finder-sidebar.txt`), macOS system defaults (`macos.sh`), missing API keys into `secrets.zsh` (Fathom, Qonto). `macos.sh` also sets default apps: Zed opens txt/md/json/yaml/toml, Ghostty runs .sh/.command/.tool.

static.adguard.com drops TLS handshakes on some routes, so the adguard cask download hangs. The wizard's `brew bundle` step works around it and pre-seeds brew's cache from AdGuard's adtidy.org mirror. A manual `brew bundle` run skips that workaround.

## Onboarding accounts

New team member, fresh machine. Provision these before running `install.sh`. The Brewfile, `secrets.zsh`, and `home/.gitconfig` assume they exist.

| Account          | Setup                                                                                          |
|------------------|------------------------------------------------------------------------------------------------|
| Apple Account    | Sign into the App Store first, else `brew bundle` skips the `mas` apps (Keynote, Numbers, Pages, Xcode, Moom) |
| Google Workspace | Gmail, Calendar, Meet, Gemini, plus the `@googleworkspace/cli` and `@google/gemini-cli` globals |
| GitHub           | Org membership. Run `gh auth login` after install (`.gitconfig` routes credentials through `gh`) |
| GitLab           | Run `glab auth login` after install (`.gitconfig` routes credentials through `glab`)            |
| Slack            | hackersandwizards.slack.com                                                                      |
| Anthropic        | claude.ai, Claude desktop app, Claude Code CLI and VS Code extension                             |
| LinkedIn         | Personal profile, linked to the hackers&wizards company page                                     |
| Qonto            | `QONTO_API_KEY`, `QONTO_ORGANIZATION_ID`, `QONTO_THIRDPARTY_HOST` in `secrets.zsh`               |
| Circle           | Community platform                                                                               |

Optional, per person: Fathom (`FATHOM_API_KEY` in `secrets.zsh`), OpenAI (Codex CLI, ChatGPT), Cloudflare, Namecheap, AWS, Google Cloud (Workspace sign-in). JetBrains Toolbox, Cursor, Warp, CleanMyMac, DaisyDisk, CrossOver, and superwhisper bring their own licenses.

## New-machine checklist (manual)

`install.sh` replays everything scriptable. These need a human — interactive logins and UI state macOS exposes no API for. Work through them once after the wizard:

- [ ] **Apple Mail + Calendar**: System Settings → Internet Accounts → Add Account → Google → sign in with the Workspace account → enable Mail, Calendar, Contacts.
- [ ] **Notion Calendar**: launch, sign in with the same Google account, connect the Workspace calendar.
- [ ] **Slack**: launch, sign in to `hackersandwizards.slack.com`.
- [ ] **Google Workspace in the browser**: sign in once so Claude's Workspace MCP connectors can request permissions against the right account.
- [ ] **GitHub / GitLab**: `gh auth login` and `glab auth login` if the wizard step was skipped.
- [ ] **Widgets**: rebuild desktop + Notification Center widgets by hand (right-click desktop → Edit Widgets). macOS has no supported export.
- [ ] **Default-app cleanup**: Apple system apps live in `/System/Applications` and are SIP-protected — they cannot be deleted. The Dock replay already hides the unwanted ones; drag anything else out of the Dock and delete unwanted App Store installs from `/Applications`.
- [ ] **Dock / sidebar drift**: after curating Dock or Finder sidebar on any machine, run `bench-export` and commit so the snapshots follow you.

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
  bench-clean           Reclaim disk: caches, .DS_Store, VS Code extension dedup
  bench-test            Unit tests for _lib.sh helpers (plain bash asserts)
macos/                Hotkey-driven scripts (ghostty-grid.js, idea-reset-layout.py); bound in skhd/skhdrc
home/                 Stow package — symlinked into $HOME
  .gitconfig            Aliases, delta, includes ~/.gitconfig.local
  .gitignore_global     .DS_Store, IDE noise, etc.
  .commitTemplate.txt   Conventional commit message template
  .vimrc, .mongorc.js, .tmux.conf
  .ssh/config           Hardened (Keychain, ControlMaster, no ForwardAgent)
ghostty/              Ghostty terminal config (single source of truth for theme)
docs/                 Package inventory snapshots (committed; replayed by install.sh)
.claude/              Claude Code statusline + rules + settings
.githooks/pre-commit  gitleaks + shellcheck + zsh -n (repo-local)
```

## Theming — Ghostty as single source of truth

The 16 ANSI palette colors plus `background`/`foreground`/`cursor`/`selection` in `ghostty/config.ghostty` are the **only** literal color definitions in this repo. Most tools inherit them via ANSI indices; delta is the exception — it pins a GitHub light theme to match the white background:

| Tool       | How it inherits                                          |
|------------|----------------------------------------------------------|
| starship   | ANSI color names (`cyan`, `bright-black`, …)             |
| bat        | `BAT_THEME=ansi`                                         |
| fzf        | `FZF_DEFAULT_OPTS --color=fg:0,bg:-1,hl:4,…`             |
| delta      | `syntax-theme = GitHub`, `light = true` (not ANSI)       |
| vim        | no `termguicolors` → terminal palette                    |
| tmux       | named colors in status-style                             |

To change the theme: edit the `palette` section in `ghostty/config.ghostty`. Every tool except delta follows automatically.

## Maintenance

```bash
bench-doctor                   # verify everything is wired up
bench-update                   # upgrade brew, antidote, rust, ruby, python, uv, bun, sdkman
bench-export                   # snapshot installed packages + sync home/ from $HOME
bench-clean                    # reclaim disk: caches, .DS_Store, VS Code dedup (alias: cleanup)
bench-test                     # run unit tests for bin/_lib.sh helpers
ZSH_PROFILE=1 zsh -i -c exit   # profile shell startup (zprof report)
```

## Pre-commit hook

`.githooks/pre-commit` runs gitleaks (secrets), shellcheck (`*.sh`), and `zsh -n` (`*.zsh`) on staged files. Repo-local — does not affect other projects. Activated automatically by the install wizard.
