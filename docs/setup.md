# Setup

What `install.sh` does, and what it leaves to you. The install commands are in the [README](../README.md#install).

## What the wizard does

Any folder works: `init.zsh` finds its own location. The wizard asks before every step; only trusting the Brewfile taps and creating an empty `secrets.zsh` (mode 600) happen without a prompt:

- **Packages**: `brew bundle`, runtimes and CLI tools via `mise install` (`home/.config/mise/config.toml`), npm/bun/pip globals
- **Config**: Stow symlinks, `~/.gitconfig.local`, repo-local git hooks, `~/.zshrc` source line, Ghostty config, skhd, fonts, atuin history import, brew zsh as login shell, Touch ID for sudo, Claude Code CLI
- **Logins + keys**: `gh`/`glab` auth, missing API keys into `secrets.zsh` (key list: `docs/secret-keys.txt`)
- **Default repos**: `~/dev` + `~/opt` created, missing clones from `docs/repos.txt`, each under `~/dev/hackersandwizards/` in `engines/`, `internal/`, `public/` or `trainings/`
- **Machine state from `docs/` snapshots**: Safari favorites (merge), Dock layout (replace), Finder sidebar (mirror; installs mysides via sudo from a GitHub pkg), Moom settings (import)

`macos.sh` also sets default apps: Zed opens txt/md/json/yaml/toml, Ghostty runs .sh/.command/.tool.

static.adguard.com drops TLS handshakes on some routes, so the adguard cask download hangs. The wizard's `brew bundle` step works around it and pre-seeds brew's cache from AdGuard's adtidy.org mirror. A manual `brew bundle` run skips that workaround.

## After the wizard

`install.sh` replays everything scriptable. These need a human: interactive logins and UI state macOS exposes no API for. Work through them once after the wizard:

- [ ] **GitHub / GitLab**: `gh auth login` and `glab auth login` if the wizard step was skipped.
- [ ] **skhd Accessibility**: the first hotkey press prompts for it. System Settings -> Privacy & Security -> Accessibility -> enable skhd.
- [ ] **Commercial fonts**: the wizard lists fonts from `docs/fonts.txt` that `fonts/` doesn't ship (no redistribution rights, the repo is public). Restore them from a `~/Library/Fonts` backup. Never commit them.
- [ ] **Widgets**: rebuild desktop + Notification Center widgets by hand (right-click desktop -> Edit Widgets). macOS has no supported export.
- [ ] **Default-app cleanup**: Apple system apps live in `/System/Applications` and are SIP-protected, so they cannot be deleted. The Dock replay already hides the unwanted ones. Delete unwanted App Store installs from `/Applications`.
- [ ] **App settings outside this repo**: GUI app preferences other than Moom's are not synced. Licensed apps restore their own settings after sign-in.
- [ ] **Dock / sidebar drift**: after curating Dock or Finder sidebar, run `bench-export` and commit. `bench-doctor` flags when a machine drifts from the snapshots.
- [ ] **Log out / restart**: the `macos.sh` trackpad and keyboard defaults only fully apply after a logout.
