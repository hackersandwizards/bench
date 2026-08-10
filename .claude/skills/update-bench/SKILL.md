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

**The run fixes what is reversible, needs no password, and carries no judgment about what the
baseline should be. Everything else it reports, with the command that fixes it.** Never answer a
password prompt, never reach for `sudo`, never bypass the pre-commit hook, never write a secret
value.

Never retry a `bench-*` script and never re-run one with a password: a failed step downgrades to a
warn on its own and the run continues. Each script is a function of the machine's current state, so
a catch-up run is a normal run.

## The scripts

| Script | Effect | Step |
|---|---|---|
| `bench-test` | reads fixtures only, exits non-zero on failure | 1 and 5 |
| `bench-update` | mutates the machine | 2 |
| `bench-clean` | deletes caches, the cache of the Claude app hosting this run included | 2 |
| `bench-export` | writes `docs/` and `home/`, reports Brewfile drift without writing it | 3 |
| `bench-doctor` | read-only, and every warn names its own remedy | 4 |

The order is load-bearing: `bench-clean` purges the hosting app's cache, so it runs before anything
is written to the repo.

## Execution Flow

### 1. Preflight and pull

Work in `${ZSH_SETTINGS_DIR:-$PWD}`. Stop and say so if that is not this checkout.

Run `git status` and record every file it reports as modified, staged or untracked. That is this
run's exclusion set: another session shares this tree, so nothing in it may be edited or committed
here. Step 6 re-derives it, because it only grows.

`git fetch origin`, then:

- Fast-forwards or already current: `git merge --ff-only origin/main`.
- Refused, local commits ahead: `git rebase origin/main`.
- Refused over local modifications: skip the pull, say so, carry on against the tree as it stands.
- Fetch cannot reach origin: continue offline. Only the push needs a network, and step 6 keeps the
  commit for the next run.

Then `bench-test`. Red stops the run before anything touches the machine; name the failed
assertions.

### 2. Update the machine

`bench-update`, then `bench-clean`. That is `ua && cleanup`.

Keep the full output; the warn lines are this step's product. Shapes to read correctly:

- A failed cask upgrade is an installer asking for a password. Report `brew upgrade --cask <name>`
  for a terminal and move on.
- Every step failing at once is one network problem, not fifteen findings. Say that instead.
- A skipped Homebrew block is `brew_bottles_supported` false: macOS is newer than brew's bottles.
  Nothing to fix, and it clears itself.
- `SDKMAN prune` deletes installed tools rather than caches. Repeat every removal it names in the
  report. Adopting a newer feature line is a human's call, not a silent install.

### 3. Refresh the repo's picture of the machine

`bench-export`. It rewrites the `docs/` snapshots, union-merges `docs/fonts.txt`, and copies real
`STOW_FILES` back into `home/`.

It also lists installed `brew leaves` the Brewfile does not declare, and refuses to write them. Add
each by hand, in the section its neighbours sit in, with the `brew desc <name>` line as the comment
above it. Name every addition in the commit body and the report.

Never prune `docs/fonts.txt`, and never `brew bundle dump --force`. `bin/bench-export` says why.

### 4. Triage

`bench-doctor`. Sort every warn from steps 2 and 3 into three buckets, all three of which appear in
the report.

Find a warn's cause before naming its fix, and check that the next run of the same step does not
undo that fix.

**Fixed by the run.** What passes the test this skill opens with. Of the warns doctor names, three
qualify today: `core.hooksPath` not `.githooks`, `secrets.zsh` not mode 600, and a `docs/repos.txt`
target doctor matched by remote at another path. Each doctor warn names its own remedy and stays
the owner of it; apply the test, do not keep a catalogue here.

**Needs a human.** Anything wanting a password, a browser login, a UI action, a font backup or a
logout; anything whose remedy is `install.sh`, `macos.sh` or `brew bundle`, which replay a whole
machine; a stopped `skhd`, which may have been stopped on purpose; leftover rustup shims, since an
uninstall is not this run's call. One line each, with the command doctor gave.

**Resolved by the export.** `bench-export` settles Dock, Finder sidebar and Safari favorites drift
machine-is-truth, which `README.md` pre-authorizes. Report which way each snapshot went, from
`git diff --stat -- docs/`. Step 5 owns the case where that direction is wrong.

Fix the cause, never the check. Do not start `sync-agent-config.sh`: it pushes into fifteen repos,
and this run owns one.

### 5. Gate

`bench-test` again, now asking whether this run broke the tree. Red blocks the commit. Fix it if
this run caused it; report it and stop if step 1 was already red.

Its assertions run against fixtures, not against the snapshots `bench-export` just wrote, so read
`git diff -- docs/ home/` as well. A version bump removes a line and adds one; a diff that only
removes lines means state disappeared rather than changed. Do not commit that file. Revert it with
`git checkout -- <path>`, commit the rest, and report the removal with its count and `bench-export`
as the way to accept it deliberately. `docs/fonts.txt` cannot shrink by design, and
`docs/moom.plist` is generated XML, so judge that one by size rather than by lines.

Never edit a file in the exclusion set to get past the gate, and never `--no-verify`. A gitleaks hit
stops the commit and gets reported; an allowlist is a human's call.

### 6. Commit, push, report

Re-run `git status` and drop any path that became dirty since step 1 without a write of yours. Name
the remaining paths as the `git commit` pathspec, per `git.md`. One commit: one line, then a short
body naming what changed. Nothing to commit is the normal quiet-day outcome. Do not invent work.

Push. `origin` carries two push URLs, so a partial failure exits non-zero and the next run pushes
what already landed as a no-op. A rejection because `origin/main` moved mid-run gets one
`git fetch origin && git rebase origin/main` and one more push. Once. A second rejection is a
report, not a third attempt. Never force-push, never reset.

Report, in this order and short:

- what changed on the machine, and every warn steps 2 and 3 printed
- what the run fixed in the repo, each Brewfile addition named
- what needs a human, one line each with the command
- what the export decided for you, with the snapshot diffs
- the gate result, the commit and the push
