---
name: update-bench
description: >-
  Daily maintenance of this machine and this repo. Runs bench-update and
  bench-clean, refreshes the docs/ snapshots and the home/ sync, then triages
  every warning into what the run fixed, what needs a human, and what the export
  decided. Use for "ua", "cleanup", "update the machine", "update the bench",
  "daily sweep", "what needs updating here".
allowed-tools: Bash, Read, Edit, Grep, Glob
---

# Update Bench

The `ua && cleanup` habit plus the repo upkeep around it. `bin/bench-*` does the work; this skill
sequences the scripts and reads what their warnings mean.

**The run fixes what is reversible, needs no password, and carries no judgment about what the baseline
should be. Everything else it reports, with the command that fixes it.** Never answer a password
prompt, never reach for `sudo`, never bypass the pre-commit hook, never write a secret value.

Every `bin/bench-*` script is unattended-safe by construction: `set -u` without `-e`, a failed step
downgrades to a warn and the run continues, and `ask` in `bin/_lib.sh` declines when there is no TTY. So
never wrap one in a retry and never re-run one with a password. Every step is a function of the
machine's current state, so a re-run changes nothing and a catch-up run is a normal run.

## The scripts

| Script | Effect | Step |
|---|---|---|
| `bench-test` | reads fixtures only, exits non-zero on failure | 1 and 5 |
| `bench-update` | mutates the machine | 2 |
| `bench-clean` | deletes caches, the cache of the Claude app hosting this run included | 2 |
| `bench-export` | writes `docs/` and `home/`, reports Brewfile drift without writing it | 3 |
| `bench-doctor` | read-only, and every warn names its own remedy | 4 |

The order is load-bearing. `bench-clean` purges the hosting app's cache, so it runs before anything is
written to the repo: a crash then costs a restart, not a half-finished export.

## Execution Flow

### 1. Preflight and pull

Work in `${ZSH_SETTINGS_DIR:-$PWD}`. Stop and say so if that is not this checkout.

Run `git status` and record every file it reports as modified, staged or untracked. That is this run's
exclusion set. Another session shares this tree and `~/.claude/scripts/sync-agent-config.sh` commits
into it on its own schedule, so nothing in that set may be edited or committed here. Step 6 re-derives
it, because it only grows.

Note the branch and stay on it.

`git fetch origin`, then bring the checkout forward:

- `git merge --ff-only origin/main` when it fast-forwards or is already current.
- Refused because local commits are ahead: an earlier run's push failed, so `git rebase origin/main`.
- Refused over local modifications: skip the pull, say so, and carry on against the tree as it stands.
- Fetch cannot reach origin: continue offline. Every step but the push works without a network, and
  step 6 keeps the commit for the next run.

Then `bench-test`. Red here means the tree just pulled has broken `_lib.sh`, which every `bench-*`
script sources. Stop before anything touches the machine and report which assertions failed.

### 2. Update the machine

`bench-update`, then `bench-clean`. That is `ua && cleanup`.

Keep the full output. The per-step warn lines are the product of this step, and a summary written from
memory loses them. Four shapes to read correctly:

- A remedy an earlier step of this run re-creates is not a remedy. Before naming one for an updater's
  warn, check whether that updater reinstates the condition on the next run. Where it does, report the
  recurring cause and name the step feeding it.

- A failed cask upgrade is a pkg installer or a privileged helper asking for a password an unattended
  run has no way to answer. Report `brew upgrade --cask <name>` for a terminal and move on.
- Every step failing at once is one network problem, not fifteen findings. Say that instead.
- A skipped Homebrew block is `brew_bottles_supported` false: macOS is newer than the bottles brew
  ships. Nothing to fix, and it clears itself when brew catches up.
- `SDKMAN prune` is the one step that deletes an installed tool rather than a cache. It removes only a
  version superseded by a newer install of the same major line, never what `current` points at, so the
  last JDK of a line survives. It names every removal; repeat those in the report. What it cannot
  decide is whether to adopt a newer line at all: `sdk upgrade` tracks SDKMAN's own default, so a new
  feature release is a human's call, not a silent install.

### 3. Refresh the repo's picture of the machine

`bench-export`. It rewrites the `docs/` snapshots, union-merges `docs/fonts.txt`, and copies real
`STOW_FILES` back into `home/`.

It also lists installed `brew leaves` the Brewfile does not declare, and refuses to write them. Add
each one by hand, in the section its neighbours sit in, with the upstream description comment above it
in the shape every other entry uses; `brew desc <name>` gives that line. Name every addition in the
commit body and the report, so a package installed for one experiment can be dropped again with a
one-line revert.

Never prune `docs/fonts.txt`, and never `brew bundle dump --force`. `bin/bench-export` says why.

### 4. Triage

`bench-doctor`. Sort every warn from steps 2 and 3 into three buckets, all three of which appear in
the report.

**Fixed by the run.** Only what is non-interactive, reversible, and free of judgment about what the
baseline should be. Today exactly three warns qualify: `core.hooksPath` not `.githooks`, without which
this run's own commit skips gitleaks on a public repo; `secrets.zsh` not mode 600; and a
`docs/repos.txt` target whose clone doctor found elsewhere by matching remote, where only the path
moved. The remote URL is the repo's identity, so that edit carries no judgment. A repo that was
renamed or retired is not that case: doctor cannot find it, and the new URL is a human's. Each doctor
warn already names its own remedy and stays the owner of it; apply the test, do not keep a catalogue
here.

**Needs a human.** Anything wanting a password, a browser login, a UI action, a font backup or a
logout, and anything whose remedy is `install.sh`, `macos.sh` or `brew bundle`, because those replay a
whole machine and are not a daily action. A stopped `skhd` and leftover rustup shims report too: the
service may have been stopped on purpose, and an uninstall is not this run's call. One line each, with
the command doctor gave.

**Resolved by the export, with the direction named.** Dock, Finder sidebar and Safari favorites drift
is ambiguous on its own: either the machine changed or the machine regressed. `bench-export` resolves
it machine-is-truth, which is what `README.md` assigns to this machine, so it is pre-authorized. Report
which way each snapshot went, from `git diff --stat -- docs/`. Step 5 owns the case where that
direction is wrong.

Fix the cause, never the check. Do not edit `bin/bench-doctor` to quiet a warning. Out of scope and not
to be started: `sync-agent-config.sh` pushes into fifteen repos, and this run owns one.

### 5. Gate

`bench-test` again. It answers a different question than step 1: did anything this run did break the
tree. Red blocks the commit. Fix it if this run caused it; report it and stop if step 1 already had it
red.

Its `parse_*` assertions run against fixtures, not against the snapshots `bench-export` just wrote, so
read `git diff -- docs/ home/` as well. A version bump removes a line and adds one. A diff that only
removes lines means state disappeared rather than changed: an App Store that signed itself out, a Dock
item dragged off by accident, a tool that stopped answering. Do not commit that file. Revert it with
`git checkout -- <path>`, commit the rest, and report the removal with its count and `bench-export` as
the way to accept it deliberately. `docs/fonts.txt` cannot shrink by design, and `docs/moom.plist` is
generated XML, so judge that one by size rather than by lines.

Never edit a file in the exclusion set to get past the gate, and never `--no-verify`. A gitleaks hit on
a refreshed snapshot stops the commit and gets reported; an allowlist is a human's call.

### 6. Commit, push, report

Re-run `git status` and drop any path that became dirty since step 1 without a write of yours. Name the
remaining paths as the `git commit` pathspec; `git.md` owns that rule. One commit: one line, then a
short body naming what changed. Nothing to commit is the normal quiet-day outcome; say it in one line
and go to the report.

Push to the branch from step 1. `origin` carries two push URLs, so a partial failure exits non-zero and
the next run pushes the already-pushed ref as a no-op. A rejection because `origin/main` moved mid-run
gets one `git fetch origin && git rebase origin/main` and one more push. Once. A second rejection is a
report, not a third attempt. Never force-push, never reset.

Report, in this order and short:

- what changed on the machine, and every warn steps 2 and 3 printed
- what the run fixed in the repo, each Brewfile addition named
- what needs a human, one line each with the command
- what the export decided for you, with the snapshot diffs
- the gate result, the commit and the push

## Edge Cases

| Scenario | Handling |
|---|---|
| Catch-up run on wake | A normal run. Nothing here is time-windowed. |
| Two runs overlap | brew holds its own lock; the second step warns and the run continues. |
| No network | `brew update`, antidote and `git fetch` warn. Export, commit and report still run; the push is reported as failed. |
| Push rejected, or one of the two URLs fails | Keep the commit, report the error and the command. The next run's push is a no-op for whatever already landed. |
| `origin/main` moved mid-run | One `fetch` + `rebase origin/main` + push, then a report. |
| Dirty tree from another session | Pull skipped, exclusion set honoured, only this run's own paths committed. |
| `bench-test` red in step 1 | Stop before touching the machine and name the failed assertions. |
| A snapshot diff that only removes lines | Revert that path, commit the rest, report the removal with its count. |
| Nothing changed | A one-line commit report plus the three triage buckets. Do not invent work. |
