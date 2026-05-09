# --- Completion & key bindings (interactive shells only — key-bindings touches zle) ---
if [[ $- == *i* ]]; then
  source "/opt/homebrew/opt/fzf/shell/completion.zsh" 2> /dev/null
  source "/opt/homebrew/opt/fzf/shell/key-bindings.zsh"
fi

# --- Preview commands (reused by fzf-tab styles in init.zsh and functions.zsh) ---
export FZF_BAT_PREVIEW='bat --style=numbers --color=always --line-range :300 {}'
export FZF_EZA_PREVIEW='eza --tree --icons --level=2 {}'

# --- Defaults ---
# Colors map to ANSI palette → inherits Ghostty theme automatically.
export FZF_DEFAULT_OPTS="\
--height 40% --layout=reverse --border \
--color=fg:0,bg:-1,hl:4,fg+:0,bg+:7,hl+:1 \
--color=info:6,prompt:5,pointer:1,marker:2,spinner:3,header:6,border:8,gutter:-1"
export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="--preview '$FZF_BAT_PREVIEW'"
export FZF_ALT_C_OPTS="--preview '$FZF_EZA_PREVIEW'"
