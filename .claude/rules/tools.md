# Subagents

- Delegate when: (a) a task spans 3+ files, (b) research could fill the main context, (c) multiple independent queries can run in parallel.
- One task per subagent for focused execution.

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

**Git and code-host:**
- `gh` for GitHub (issues, PRs, CI runs)
- `lazygit` for git TUI, `git-filter-repo` for history rewrites

**System and shell:**
- `btop` over `htop`, `watch` for repeated commands
- `just` as command runner, `parallel` for fan-out
- `shellcheck` for shell-script linting

**JavaScript/TypeScript:**
- `bun` instead of `node` for running scripts
- `bunx` instead of `npx` for one-off package execution
- `bun install -g` for globals at `~/.bun/bin`

**Python:**
- `uv` for project envs and dependencies
- `uvx` for running tools without installing
- `pipx` for persistent CLI installs

**Token optimization:** `lean-ctx` compresses LLM context (shell hook + MCP server).

Environment: macOS (darwin), Homebrew, zsh, Ghostty terminal.
