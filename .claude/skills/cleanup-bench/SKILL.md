---
name: cleanup-bench
description: >-
  Weekly deep clean of this Mac with mole and Docker, deleting only what rebuilds itself and
  reporting every deletion of data with its command, for "weekly cleanup", "deep clean",
  "mo clean", "free disk space", "what can I delete".
allowed-tools: Bash, Read
---

# Cleanup Bench

The run deletes what rebuilds itself: caches, logs, the Docker build cache and unused images. Data
it never deletes. It reports the Trash, Docker volumes, Time Machine local snapshots and project
artifacts, each with the command that deletes it. Never `sudo`, never answer a password prompt, and
never delete anything outside the steps below.

Strip ANSI codes from every `mo` output (`sed 's/\x1b\[[0-9;]*[a-zA-Z]//g'`) and run it with
`</dev/null`.

## 1. Guard

`~/.config/mole/whitelist` replaces mole's built-in defaults once it exists. It must hold
`$HOME/.Trash` and `$HOME/Library/Caches/antidote/*`. Without the first, `mo clean` empties the
Trash. Without the second, it deletes the zsh plugins antidote clones there. If either line is
missing, skip step 2 and report it.

Record the free space from `df -h /`.

## 2. mole

`mo clean --dry-run`, check that the Trash is not listed, then `mo clean`. Keep the
`Tracked cleanup` line.

## 3. Docker

If `docker info` fails, OrbStack is not running: skip this step and say so. Otherwise run
`docker builder prune -af` and `docker image prune -af`, and keep each `Total reclaimed space` line.
Never `docker volume prune` and never `docker system prune --volumes`: volumes hold data.

## 4. Shell check

`zsh -ic 'echo ok'` must print `ok` and nothing else. A `can't open file` under
`~/Library/Caches/antidote` means the plugins were deleted. Rebuild them, then report that the
guard failed:

```bash
cd "${ZSH_SETTINGS_DIR:-$HOME/opt/zsh-settings}" && zsh -c 'source /opt/homebrew/opt/antidote/share/antidote/antidote.zsh; antidote bundle < plugins.txt > plugins.zsh && antidote bundle < plugins-post.txt > plugins-post.zsh'
```

## 5. What needs Benedikt

Read-only. One line each, with size and the command:

| Item | Read with | His command |
|---|---|---|
| Trash | `du -sh ~/.Trash`, item names | empty in Finder |
| Unused Docker volumes | `docker volume ls -qf dangling=true`, sizes from `docker system df -v` | `docker volume prune -af` |
| Time Machine local snapshots | `tmutil listlocalsnapshots /` | `sudo tmutil deletelocalsnapshots /` |
| Project artifacts | `mo purge --dry-run`, each path with size | `mo purge` |
| System caches | not previewable without a password | `sudo -v && mo clean` |

Never run `mo purge` without `--dry-run`: it deletes `node_modules` and virtualenvs in repos another
session may be running, the MCP servers under `~/opt` included. Skip mole's `Large files` section.

## 6. Report

- free space before and after, and that local snapshots hold deleted space until they expire or
  are deleted
- mole's `Tracked cleanup` line and Docker's reclaimed space, verbatim
- the shell check result
- the table from step 5, empty rows left out

The run writes nothing to this repository and commits nothing.
