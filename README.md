Terminal setup for hackers&wizards: zsh, Ghostty, Starship, fzf, modern CLI replacements. macOS Apple Silicon only.

> [!CAUTION]
> **Highly opinionated. Don't install blindly.**
>
> Every choice reflects specific tooling preferences. Walk through the files with an AI agent (Claude Code, Cursor, etc.) before running `install.sh` so you understand:
> - what gets installed (brew packages + Ghostty cask)
> - what gets configured globally (git delta defaults, line appended to `~/.zshrc`, Ghostty config symlink)
> - which choices wouldn't fit your setup

## Setup

1. Clone this repository anywhere (`init.zsh` self-discovers its location)
2. Run `./install.sh`
3. Copy `home/.gitconfig` to `~/.gitconfig`
4. Create `~/.gitconfig.local` with your `[user]` block (name + email)
5. Copy `home/.vimrc` to `~/.vimrc`
6. (Optional) Create `secrets.zsh` next to `init.zsh` for API keys (gitignored)
7. Open a new terminal

## File structure

```
init.zsh        Main entrypoint (shell setup, compinit, tool inits)
exports.zsh     PATH, env vars (sources secrets.zsh if present)
aliases.zsh     All aliases
fzf.zsh         fzf config, defaults, and functions
secrets.zsh     Untracked, gitignored. API keys go here
starship.toml   Starship prompt config
plugins.txt     Antidote plugin list
install.sh      Fresh machine setup
home/           Dotfile templates (.gitconfig, .vimrc, .mongorc.js)
docs/           Package inventory snapshots
```
