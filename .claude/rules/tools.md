# Subagents

- Delegate when: (a) a task spans 3+ files, (b) research could fill the main context, (c) multiple independent queries can run in parallel.
- One task per subagent for focused execution.

# Reading large files (avoid "Output too large")

A single tool result that exceeds ~25k tokens gets truncated. Long transcripts, research and data dumps, and big `git diff` outputs trip this regularly.

- Default to `Read(file, offset=N, limit=M)` for any file over ~1000 lines. Do not full-file-read a transcript to answer a question about one section.
- Grep first, Read second. Use `rg` or the Grep tool to locate exact line numbers, then Read a narrow window around them.
- Pipe Bash output through filters at the source: `head`, `tail`, `rg`, `jaq`. Never dump full logs. For `git diff`, scope to a path or run `--stat` first to triage.
- When a single source file is chronically too large to read in one pass, propose splitting it (e.g. `YYYY-MM-DD-context-part1.md` / `part2.md`) rather than working around it every session.

# Tooling preferences

Modern CLI replacements installed via Homebrew. Prefer when running shell commands.

**Text and file navigation:**
- `eza` over `ls`, `bat` over `cat` and `less`
- `fd` over `find` for terse search; `bfs` when `find` syntax is needed (POSIX-compatible, faster traversal)
- `rg` over `grep` for code search; `ugrep` for searching inside archives, compressed files, or PDFs
- `delta` for diffs, `tree` for directory tree, `fzf` for fuzzy selection
- `zoxide` for directory jumping (`z <pattern>`)

**HTTP and data:**
- `xh` over `curl` and `httpie`
- `jaq` over `jq` (Rust port, faster), `pandoc` for document conversion
- `scrapling` to scrape web pages to markdown (`scrapling extract get <url> out.md`)

**Git and code-host:**
- `gh` for GitHub (issues, PRs, CI runs)
- `lazygit` for git TUI, `git-filter-repo` for history rewrites
- Global git aliases from `~/.gitconfig` that add workflow behavior:
  - `git all <args...>` -> run `git <args...>` in every repository under the current tree
  - `git integrate <branch>` -> merge a branch with `--no-ff --edit` after confirming `HEAD` is up to date with that branch

**System and shell:**
- `btop` over `htop`, `watch` for repeated commands
- `just` as command runner, `parallel` for fan-out
- `shellcheck` for shell-script linting
- `cdxe` to start Codex exec (`codex exec`)

**JavaScript/TypeScript:**
- `bun` instead of `node` for running scripts
- `bunx` instead of `npx` for one-off package execution
- `bun install -g` for globals at `~/.bun/bin`

**Python:**
- `uv` for project envs and dependencies
- `uvx` for running tools without installing
- `pipx` for persistent CLI installs

**Token optimization:** `lean-ctx` over `rtk` — both compress shell output via Claude Code hooks; lean-ctx adds MCP-cached file reads and code graph search.

Environment: macOS (darwin), Homebrew, zsh, Ghostty terminal.
