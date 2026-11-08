# Path stores

Every place on this Mac that keeps an absolute path under `~/dev` or `~/opt`, and how `bin/bench-paths` handles it when a folder moves.

## Moving a folder

1. `bench-paths <old>` lists every reference and every process whose working directory sits inside `<old>`.
2. Close the Claude Code sessions it lists, and quit the apps named in the plan.
3. `bench-paths <old> <new>` prints the plan. Nothing changes yet.
4. Move the folder with `mv <old> <new>`.
5. `bench-paths --apply <old> <new>` rewrites what is safe now and prints the remaining manual steps. It refuses to run before the move. Each changed file keeps its previous state next to it as `<file>.bench-paths-bak`.

A store whose app is running is left alone and named under "Manual steps": quit the app, then run `--apply` again. Rewriting is idempotent, so a second run only touches what the first one skipped.

## How a match works

A store may spell the same folder five ways: absolute (`/Users/…/opt/x`), `~/opt/x`, `$HOME/opt/x`, `${HOME}/opt/x`, and JetBrains' `$USER_HOME$/opt/x`. A match ends where the path ends, so `/opt/x` never hits `/opt/x-old` or `/opt/x.bak`, while a sentence's closing dot still ends it. Claude Code names a project folder after its path with every character other than a letter or digit turned into `-`. That encoding is lossy (`/opt/x-y` and `/opt/x/y` encode alike), so `bench-paths` reads the `cwd` field in a project's transcripts before it renames the project.

## Stores bench-paths rewrites

Measured on 08.11.2026 with three sample paths (`~/dev/hackersandwizards/internal/os`, `~/dev/hackersandwizards/internal/bench`, `~/dev/personal/benedikt.stemmildt.com`) and a sweep for any `~/dev` or `~/opt` path. The sweep covered `~/Library/Application Support`, `~/Library/Preferences`, `~/Library/LaunchAgents`, `~/Library/Containers`, `~/Library/Group Containers`, `~/.config`, `~/.local`, `~/.codex`, `~/.claude`, `~/.claude-swap-backup`, `~/.gemini`, `~/.docker`, `~/.orbstack`, `~/.ssh` and the dotfiles in `~`, binary files included.

| Store | Format, spelling | App to quit first | Method |
|---|---|---|---|
| `~/.claude.json` (`projects` keys, `githubRepoPaths`) | JSON, absolute | every Claude Code session | text |
| `~/.claude-swap-backup/configs/*.json` (cswap's copy of `.claude.json` per account, restored on switch) | JSON, absolute | every Claude Code session | text |
| `~/.claude/projects/<encoded>/` (transcripts, `memory` symlink) | folder name, encoded | the sessions inside the folder | rename; a name already taken becomes a manual merge |
| `~/.claude/plugins/known_marketplaces.json`, `installed_plugins.json` | JSON, absolute | none | text |
| `~/.claude/scheduled-tasks/*/SKILL.md` | Markdown, absolute | none | text |
| Claude app: `claude_desktop_config.json`, `git-worktrees.json`, `ccd-session-presets.json`, `remote-control-state.json` | JSON, absolute | Claude | text |
| Claude app: `claude-code-sessions/**/*.json` (session index with `cwd`, `originCwd`, `gitAnchors`; `scheduled-tasks.json`) | JSON, absolute | Claude | text |
| Claude app: `local-agent-mode-sessions/**/*.json` | JSON, absolute | Claude | text |
| `~/.codex/config.toml` (`[projects."<path>"]` trust), `.codex-global-state.json` (workspace roots, tab routes), `external_agent_session_imports.json` (imported Claude transcript paths, encoded) | TOML/JSON, absolute and encoded | codex, Codex | text |
| `~/.codex/state_*.sqlite` (`threads.cwd`, `project_roots.path`) | SQLite, absolute | codex, Codex | SQL update, backup via SQLite's backup API |
| `~/.codex/sqlite/codex-dev.db` (`local_thread_catalog.cwd`) | SQLite, absolute | codex, Codex | SQL update |
| JetBrains: `*/options/recentProjects.xml`, `trusted-paths.xml`, `other.xml`, `runner.layout.xml`, `*/workspace/*.xml`, `jba_config/*.xml`, `air/session-identities/*.json`, Toolbox and Daemon `rhizome/db.json` | XML/JSON, `$USER_HOME$` and absolute | idea, jetbrains-toolbox | text |
| Zed: `db/*/db.sqlite` (`workspaces`, `trusted_worktrees`, `sidebar_threads`, `editors.buffer_path`, `kv_store.value`) | SQLite, absolute | zed | SQL update |
| opencode: `storage/project/*.json`, `storage/session/*.json`, `opencode.db` (`project`, `session.directory`, `project_directory`) | JSON/SQLite, absolute | opencode | text, SQL update |
| Gemini and Antigravity: `~/.gemini/projects.json`, `trustedFolders.json`, `antigravity-cli/settings.json`, `antigravity-cli/cache/projects.json`, `config/projects/*.json` | JSON, absolute | Antigravity | text |
| `~/Library/LaunchAgents/*.plist` (skhd and t3code store a `PATH` with `~/dev/hackersandwizards/internal/bench/bin` and `node_modules/.bin` folders) | XML plist, absolute | none | text, then reload: `launchctl bootout` and `bootstrap` |
| Symlinks in `~` to depth 3, in `~/.claude/projects/*/` and `~/.claude-swap-backup/sessions/*/` (Stow links into this repo, `~/.claude/skills/claude-accounts`, project `memory` links) | symlink, relative or absolute | none | re-point, keeping the relative or absolute style |
| `~/.config/**` except `gcloud/` (mole `purge_paths` and `whitelist`, Zed, Ghostty, skhd configs) | text, absolute or `$HOME` | none | text, at the symlink's target; the backup lands there too, which this repo's `.gitignore` covers |
| `~/.zshrc`, `~/.zshenv`, `~/.zprofile` | zsh, `~` | none | text; open shells keep the old value until restarted |
| `~/Library/Application Support/rtk/trusted_filters.json` | JSON, absolute | none | text |

The app gate checks the process name with `pgrep -x`. The Claude Code gate counts every `claude` process from `ps`, since `pgrep` leaves out its own caller, so a run from inside a Claude Code session always leaves `~/.claude.json` for later. That is a choice made without testing whether Claude Code re-reads the file before writing it: a session holding the old content could write it back.

## Stores bench-paths lists for a manual step

| Store | Why not rewritten | Manual step |
|---|---|---|
| Processes with a working directory inside the folder (`lsof -d cwd`) | a running Claude Code session keeps writing transcripts to the old project folder, so it holds the project rename; other processes are listed only | close the Claude Code sessions, then run `--apply` again |
| `~/.claude/{rules,skills,agents,scripts}` | copies that `~/.claude/scripts/sync-agent-config.sh` writes from the hub | change the source, then sync |
| Claude app: `git-shadow/`, `Local Storage/leveldb`, `IndexedDB` | app-internal state; `git-shadow` folders carry a hash in their name, not the path | open the folder in the Claude app after the move and check it |
| t3code: `t3code-v2/IndexedDB` | LevelDB, binary | open the folder in t3code after the move |
| `~/.local/state/mise/trusted-configs/` | each link's name is a hash of the config path; re-pointing a link does not carry the trust over | `mise trust <moved config>` |
| Git worktrees inside the folder, or a repo there with worktrees | `.git` files and `.git/worktrees/*/gitdir` hold absolute paths | `git -C <repo> worktree repair` |
| Running containers with a bind mount inside the folder | the mount keeps the old source | recreate the container |
| Files in other repositories under `~/dev` and `~/opt` that name the folder (`.gitignore` respected) | another repository owns them | a change in that repository |

## History, not rewritten

These stores record where something happened. A stale entry there breaks nothing, or the tool drops or relearns it on its own: zoxide skips a folder that no longer exists.

- Claude Code: transcripts `~/.claude/projects/*/*.jsonl`, `history.jsonl`, `file-history/`, `shell-snapshots/`, `paste-cache/`, `backups/`, `.claude.json.backup` and `.claude.json.tmp.*`, cswap's `sessions/*/shell-snapshots/`; live registries `~/.claude/sessions/<pid>.json`, `jobs/*/state.json`, `daemon/roster.json`, which end with their process. One exception: T3 files a transcript under its first recorded `cwd` and skips it when that folder is gone, so `t3-import-session` links the old path to the new one while it imports.
- Codex: `logs_*.sqlite`, `memories_*.sqlite`, `threads.title`, `threads.preview` and `threads.first_user_message` in `state_*.sqlite`.
- Shell and CLI history: atuin `history.db`, zoxide `db.zo`, rtk `history.db` and `tee/*.log`, wrangler logs in `~/Library/Preferences/.wrangler/logs`.
- macOS: Finder's Go-to-folder history in `com.apple.finder.plist`, the open/save panel's recents, `com.apple.sharedfilelist` recents, Office and Safari sandbox bookmarks, `Knowledge/knowledgeC.db`.
- Chrome for Testing crash dumps and the `Chrome-headless/scoped_dir*` profiles that headless runs leave behind.
- JetBrains `tasks/*.zip` and `app-internal-state.db`, Zed `threads/`, Gemini and Antigravity conversations, opencode `storage/message` and `storage/part`, Docker buildx refs.

## Searched and empty

`~/.gitconfig` has no `includeIf` and no `safe.directory`. direnv's allow list is empty. 1Password has no SSH agent config (`~/.config/1Password/ssh/agent.toml` does not exist). `~/.ssh/config`, `~/.tmux.conf`, skhd's `skhdrc` and the Ghostty config name no folder under `~/dev` or `~/opt`. VS Code and Cursor are not installed.
