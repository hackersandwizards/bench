---
name: claude-accounts
description: >-
  Run Claude Code across several subscription accounts on one machine: keep heavy terminal
  work off a protected account, switch without a browser login, and read limits and cost.
  Use for "switch claude account", "which account am I on", "I hit my usage limit",
  "rate limit", "account rotation", "claude usage", "how much did this session cost".
---

# Claude accounts

Claude Code holds one login at a time. `claude-swap` stores several and switches between them
without a browser flow, so a usage limit costs one command instead of a re-authentication.

Claude Desktop keeps its own credential in
`~/Library/Application Support/Claude/config.json`. It is untouched by everything here, and a
terminal switch never changes which account the Desktop app or its scheduled tasks use.

## Keep an account out of rotation

An account you want protected must never be registered. `cswap add` captures whichever account is
logged in at that moment, so log into an account you are happy to spend before running it. An
account the tool has never seen cannot be chosen by any strategy.

`cswap disable <num|email>` is the weaker second option. It holds a registered account out of
auto-switch and out of the `best` and `next-available` strategies, but an explicit
`cswap switch <num|email>` still activates it.

## Daily use

| Command | Effect |
|---|---|
| `cswap list` | every account with its 5h, 7d and per-model windows and reset times |
| `cswap status` | which account is active now |
| `cswap switch --strategy best` | jump to the account with the most quota left |
| `cswap switch <num\|email>` | activate one account |
| `cswap run <num\|email> -- --resume` | run one session as that account, this terminal only |
| `cswap map <num\|email> <path>` | pin a directory to an account, then bare `cswap run` uses it |
| `cswap auto` | poll and switch on its own before a limit lands |
| `cswap tui` | interactive dashboard |

`cswap run` leaves the global login alone, so it is the safe way to borrow another account for one
task. `cswap switch` moves every later session too.

## Automatic switching

`cswap auto` has to be running for rotation to happen. Installing the tool does not start it.
`cswap auto --once` is a single tick and suits a cron entry. Defaults, readable with
`cswap config`:

| Key | Default | Meaning |
|---|---|---|
| `autoswitch.strategy` | `best` | pick the account with the most headroom |
| `autoswitch.threshold` | `90` | switch once the active account passes this percent |
| `autoswitch.intervalSeconds` | `60` | how often it checks |
| `autoswitch.cooldownSeconds` | `300` | minimum gap between switches |
| `autoswitch.hysteresisPct` | `10` | margin that stops it oscillating near the threshold |

Change one with `cswap config set autoswitch.threshold 80`.

Rotation is proactive polling, not a reaction to hitting a wall. The separate Claude Code setting
`autoContinueAtUsageLimit` waits for the window to reset instead of switching, so it solves a
different problem and the two do not combine usefully.

## Seeing the limits

`cswap menubar` is the tool's own macOS menu bar, and `cswap menubar --install-service` keeps it
running through a LaunchAgent.

CodexBar (`brew install --cask codexbar`) covers every provider in one bar, Claude alongside Codex,
Gemini, Copilot and z.ai. It reads Claude accounts through an adapter that has to be switched on:
enable "Read accounts from claude-swap" in its settings and point it at the `cswap` executable,
otherwise it shows a single Claude account. Set Settings > Menu > Multi-account layout to Segmented
for a side by side switcher. CodexBar never touches credentials; it runs `cswap --list --json` and
reads the numbers.

The statusline renders the active account and the running cost of the current session, because the
active account can change underneath a session once auto-switching is on.

## Cost

A subscription has no per-token bill, so no tool reports a real one.

| Question | Where |
|---|---|
| what this session is costing now | the statusline, from `total_cost_usd` in its own payload |
| what recent days cost | `npx ccusage@latest`, local logs priced at API rates |
| how much of each limit is left | `cswap list`, or a menu bar app |

CodexBar's Usage and Spend pane has a known gap with several accounts: it prices one home directory
only and undercounts the rest without reporting an error. Read cost elsewhere until that is fixed.

## When it breaks

Nothing here is load bearing. `/login` still works by hand, and `cswap remove <num|email>` or
`cswap purge` returns the machine to a single ordinary login. Accounts and their windows are also
readable offline: each config home's `.claude.json` carries `cachedUsageUtilization` with the 5h
and 7d percentages and a `fetchedAtMs` stamp, which is a cache and only as fresh as that home's
last session.
