# Theming: Ghostty as single source of truth

The 16 ANSI palette colors plus `background`/`foreground`/`cursor`/`selection` in `ghostty/config.ghostty` are the **only** literal color definitions for the terminal tools. Most inherit them via ANSI indices. delta is the exception, pinning a GitHub light theme to match the white background. Beyond the tools in the table, the Claude Code statusline (`.claude/statusline-command.sh`) pins three RGB colors and Zed picks its own One Light and One Dark themes:

| Tool       | How it inherits                                          |
|------------|----------------------------------------------------------|
| starship   | ANSI color names (`cyan`, `bright-black`, ...)           |
| bat        | `BAT_THEME=ansi`                                         |
| fzf        | `FZF_DEFAULT_OPTS --color=fg:0,bg:-1,hl:4,...`           |
| delta      | `syntax-theme = GitHub`, `light = true` (not ANSI)       |
| vim        | no `termguicolors` -> terminal palette                   |
| tmux       | named colors in status-style                             |

To change the theme: edit the `palette` section in `ghostty/config.ghostty`. Every tool in the table except delta follows automatically.
