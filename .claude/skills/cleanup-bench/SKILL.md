---
name: cleanup-bench
description: >-
  Weekly deep clean of this Mac with mole and Docker: deletes what Benedikt has cleared and asks
  about anything new, for "weekly cleanup", "deep clean", "mo clean", "mo purge",
  "free disk space", "what can I delete".
allowed-tools: Bash, Read
---

# Cleanup Bench

Never `sudo`, never answer a password prompt, and never delete anything outside the steps below.
Run every `mo` command with `</dev/null` and strip its ANSI codes
(`sed 's/\x1b\[[0-9;]*[a-zA-Z]//g'`).

## 1. Guard

`~/.config/mole/whitelist` replaces mole's built-in defaults once it exists, and both `mo clean`
and `mo purge` honour it. Skip steps 2 and 3 and report the gap unless it holds all five:

| Line | Protects |
|---|---|
| `$HOME/.Trash` | the Trash from `mo clean` |
| `$HOME/Library/Caches/antidote/*` | the zsh plugins antidote clones there |
| `$HOME/dev/hackersandwizards/internal/company/os/*` | Company OS, in use all day |
| `$HOME/.cache/puppeteer/*` | the Chrome for Testing builds repos pin, which `mo clean` deletes whole |
| `$HOME/Library/Application Support/Google/Chrome/*` | Benedikt's Chrome profiles, whose caches `mo clean` empties |

Record the free space from `df -h /`.

## 2. mole

`mo clean`, then `mo purge --yes`. Keep the `Tracked cleanup` and `Would free` or freed lines.

## 3. Docker

If `docker info` fails, OrbStack is not running: skip this step and say so.

`docker builder prune -af`, `docker image prune -af` and `docker volume prune -af`. Before the
last one, record the names of `docker volume ls -qf dangling=true`.

## 4. Shell check

`zsh -ic 'echo ok'` must print `ok` and nothing else. A `can't open file` under
`~/Library/Caches/antidote` means the guard failed: rebuild the plugins and report it.

```bash
cd "${ZSH_SETTINGS_DIR:-$PWD}" && zsh -c 'source /opt/homebrew/opt/antidote/share/antidote/antidote.zsh; antidote bundle < plugins.txt > plugins.zsh && antidote bundle < plugins-post.txt > plugins-post.zsh'
```

## 5. Versions and browsers

In `~/.cache/puppeteer/*`, `~/Library/Caches/ms-playwright`, `~/.local/share/mise/installs/*`,
`~/.local/share/claude/versions`, `~/Library/Application Support/Claude/claude-code` and
`~/.codex/packages/app-server-daemon/releases`, keep the newest version, the one a symlink or
`current` names, and every version a repo under `~/dev` or `~/opt` pins: the browser builds in its
`node_modules/puppeteer-core/lib/**/revisions.js` or `playwright-core/browsers.json`, the
runtimes in `.tool-versions`, `mise.toml`, `.nvmrc`, `.node-version`, `.ruby-version` or
`packageManager`. `mise prune` misses repos mise never loaded, so it decides nothing. Skip any
version `lsof` shows open. Remove the rest with `mise uninstall`, else move it to `~/.Trash`. Then
run `brew autoremove`, `brew cleanup -s`, `bun pm cache rm` and `uv cache prune`, and move
`~/.npm/_npx/*` to `~/.Trash`.

## 6. Report

- free space before and after, and that Time Machine local snapshots hold deleted space until
  macOS expires them after 24 hours
- the mole lines and Docker's reclaimed space, verbatim, and the removed volumes by name
- each version removed in step 5, and each kept with the repo that pins it
- the shell check result
- the Trash with its size, for Benedikt to empty in Finder
- as a question, anything `mo clean` lists under `Large files` beyond Mail data, Time Machine
  local snapshots, Docker storage, OrbStack data and mise Java installs, which Benedikt keeps
