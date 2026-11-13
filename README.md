# bench

The machine setup of hackers&wizards for Apple Silicon Macs: an install wizard that installs our Brewfile and links our zsh, Ghostty, Starship and fzf configuration, and the `bench-*` commands that keep a machine current. It is our own setup, published as it is, not a general dotfiles framework. Intel Macs are not supported.

> [!CAUTION]
> **Highly opinionated. Don't install blindly.** The wizard installs CLI packages, apps (Ghostty, browsers, editors, Office, Slack) and Mac App Store apps from the [Brewfile](Brewfile), symlinks `home/` into `$HOME`, appends a line to `~/.zshrc` and links the Ghostty config. Walk through the files, with an AI agent if you like, before you run `install.sh`.

| You want | Go to |
| --- | --- |
| See what gets installed | [Brewfile](Brewfile), [docs/setup.md](docs/setup.md) |
| Set up a new Mac | [Before you start](#before-you-start), then [Install](#install) |
| Finish what the wizard leaves to you | [docs/setup.md](docs/setup.md#after-the-wizard) |
| Keep a machine current, move a folder, capture a setting | [Daily use](#daily-use) |
| Transcribe a recording | [docs/transcription.md](docs/transcription.md) |
| Change the terminal colours | [docs/theming.md](docs/theming.md) |
| Change this repository | [Work on it](#work-on-it) |

## Before you start

- Colleagues at hackers&wizards: set up your company accounts first, as the onboarding in the Company OS handbook lists them.
- Sign into the App Store, else `brew bundle` skips the `mas` apps (Xcode, Moom).
- Have your GitHub account, and a GitLab account if you use one: the wizard runs `gh auth login` and `glab auth login`.
- Grant the terminal Full Disk Access (System Settings -> Privacy & Security) before the wizard's Safari-favorites step: it reads `~/Library/Safari/Bookmarks.plist` and can only warn without it.

## Install

```bash
git clone https://github.com/hackersandwizards/bench.git \
  ~/dev/hackersandwizards/internal/bench
cd ~/dev/hackersandwizards/internal/bench
./install.sh
```

The wizard asks before every step and can be re-run. It ends on `Done` with a recap of any warnings. Open a new terminal, then run `bench-doctor`: it checks that everything is wired up. Then work through [After the wizard](docs/setup.md#after-the-wizard).

`./macos.sh` sets about 60 macOS system defaults and the default apps; the wizard offers it as one of its steps. Its trackpad and keyboard defaults apply after a logout.

The Dock, Finder sidebar and Moom steps replace your own layout with the snapshots in `docs/`. Say no to them to keep yours.

## Daily use

- `bench-doctor`: verify everything is wired up.
- `bench-update`: upgrade brew, antidote, mise tools, Rust toolchains, pip, bun and npm globals.
- `bench-clean`: reclaim disk: caches, .DS_Store, stale IDE versions, finished Claude temp folders. Alias `cleanup`; `--dry-run` lists the temp folders it would remove and changes nothing.
- `bench-export`: check the Brewfile, snapshot installed packages into `docs/` and sync `home/` from `$HOME`.
- `bench-paths <old> [<new>]`: before moving a folder, list every reference to it; `--apply` after the move.
- `bench-prefs-diff snap`, change the setting in System Settings, then `bench-prefs-diff diff`: shows what changed, as `defaults` keys for `macos.sh`.
- `transcribe <file>`: speech to text, writes `.txt` and `.srt` ([docs/transcription.md](docs/transcription.md)).
- `safari-favorites`: export or merge the Safari favorites bar.
- `t3-import-session <session-id>`: import one ended Claude session into its T3 project.
- `ZSH_PROFILE=1 zsh -i -c exit`: profile shell startup.

The `update-bench` skill (`.claude/skills/update-bench/`) runs the daily loop of these commands and commits the refreshed snapshots. The `update-bench-daily` scheduled task fires it at 06:00, which is why `docs/` changes most days.

## Documentation

- [Setup](docs/setup.md): what each wizard step does, the checklist after it, the AdGuard download workaround.
- [Transcription](docs/transcription.md): the `transcribe` command and the measurements behind its model and flags.
- [Theming](docs/theming.md): Ghostty's palette as the one colour source for the terminal tools.
- [Path stores](docs/path-stores.md): every store that keeps a `~/dev` or `~/opt` path, the list behind `bench-paths`.
- The `.txt` files in `docs/`: package and machine-state snapshots that `install.sh` replays, except the Homebrew lists (`brews.txt`, `brew-leaves.txt`, `brew-taps.txt`): they record what is installed, and `install.sh` installs from the [Brewfile](Brewfile).

## Work on it

- `bench-test`: tests for `bin/_lib.sh`, the `bin/` scripts and repository invariants.
- `.githooks/pre-commit` runs betterleaks, shellcheck and `zsh -n` on staged files. The wizard activates it for this repository only.
- There are no releases: a new machine clones `main`.
- Layout, conventions and who maintains the defaults: [CLAUDE.md](CLAUDE.md).

## Licence

Maintained by hackers&wizards GmbH under the [PolyForm Strict License 1.0.0](LICENSE): you may use it for noncommercial purposes, but not distribute it or make changes or new works based on it. The Weather Icons font in `fonts/` is under the SIL Open Font License 1.1.
