---
name: claude-accounts
description: >-
  Run Claude Code across several subscription accounts with one kept protected, for "switch claude
  account", "which account am I on", "I hit my usage limit", "rate limit", "account rotation",
  "claude usage", "how much did this session cost", and for Claude threads in T3 Code.
---

# Claude accounts

Claude Code holds one login at a time. `claude-swap` (`cswap`) stores several and switches
between them without a browser flow.

Claude Desktop keeps its own credential in
`~/Library/Application Support/Claude/config.json`. It is untouched by everything here, and a
terminal switch never changes which account the Desktop app or its scheduled tasks use.

## Keep an account out of rotation

An account you want protected must never be registered. `cswap add` captures whichever account is
logged in at that moment, so log into an account you are happy to spend before running it.

`cswap disable <num|email>` is the weaker second option. It holds a registered account out of
auto-switch and out of the `best` and `next-available` strategies, but an explicit
`cswap switch <num|email>` still activates it.

## T3 Code

T3 Code runs Claude through the SDK, so `cswap` reaches it under one condition: the Claude
provider's config-dir field stays empty. An explicit `~/.claude` there makes Claude read a suffixed
keychain item that `cswap` never writes. A `cswap switch` then reaches a running T3 thread on its
next turn; the rate-limit `resetsAt` in `~/.t3/userdata/logs/provider/events.*.log` shows which
account served each turn. That works while the accounts' windows reset at different times.

- The T3 desktop app runs its own server unless `localEnvironmentEnabled` is false in
  `~/.t3/userdata/desktop-settings.json`. The launchd service from `t3 up` or `t3 service install`
  holds `~/.t3`, so with the service running the app must run remote-only (that setting false) and be
  paired to the service once with `t3 pair` and its `t3code://pair` link; otherwise it shows "This T3
  home is unavailable" and quits. `t3 connect` is `t3 up --connect`. T3 Connect's tunnel needs
  outbound port 7844; a network that allows only 443 leaves the Mac unreachable from the phone.
- A session import needs a project first, and the Claude provider skips sessions older than 30
  days or whose folder is gone.

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

`cswap run` leaves the global login alone. `cswap switch` moves every later session too.

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

Rotation is proactive polling. The separate Claude Code setting `autoContinueAtUsageLimit` waits
for the window to reset instead of switching, and the two do not combine usefully.

## Seeing the limits

`cswap menubar` puts every account's windows in the macOS menu bar, and
`cswap menubar --install-service` keeps it running through a LaunchAgent. The menu bar needs the
`menubar` extra, so install the tool with `rumps` alongside it, as the mise config does with
`"pypi:claude-swap" = { version = "latest", with = ["rumps"] }`: without `rumps` the LaunchAgent
registers and then has nothing to run.

Auto-switching is off by default even with the menu bar running. Turn it on in the menu bar itself,
or run `cswap auto`; both drive the same engine and share the `autoswitch.*` settings.

The statusline renders the active account and the running cost of the current session.

## Cost

A subscription has no per-token bill, so no tool reports a real one.

| Question | Where |
|---|---|
| what this session is costing now | the statusline, from `total_cost_usd` in its own payload |
| what recent days cost | `npx ccusage@latest`, local logs priced at API rates |
| how much of each limit is left | `cswap list`, or the menu bar |

ccusage reports one total across every account. `cswap switch` swaps the credential inside the same
config home, so all accounts write to one `~/.claude/projects` and no account dimension exists in
the logs. `cswap run` is the exception: it points `CLAUDE_CONFIG_DIR` at a per-slot profile whose
`projects/` is separate unless `--share-history` is passed, so those runs are invisible to a
default ccusage read.

## When it breaks

`/login` still works by hand, and `cswap remove <num|email>` or
`cswap purge` returns the machine to a single ordinary login. Accounts and their windows are also
readable offline: each config home's `.claude.json` carries `cachedUsageUtilization` with the 5h
and 7d percentages and a `fetchedAtMs` stamp, which is a cache and only as fresh as that home's
last session.
