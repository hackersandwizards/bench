# --- Setup ---
if [[ ! "$PATH" == */opt/homebrew/opt/fzf/bin* ]]; then
  export PATH="${PATH:+${PATH}:}/opt/homebrew/opt/fzf/bin"
fi

# --- Completion & key bindings ---
[[ $- == *i* ]] && source "/opt/homebrew/opt/fzf/shell/completion.zsh" 2> /dev/null
source "/opt/homebrew/opt/fzf/shell/key-bindings.zsh"

# --- Defaults ---
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"
export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always --line-range :300 {}'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --icons --level=2 {}'"

# --- Functions ---
fkill() {
  local pid
  pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')
  if [ "x$pid" != "x" ]; then
    echo $pid | xargs kill -${1:-9}
  fi
}

fview() {
  $EDITOR $(fzf --preview 'bat --style=numbers --color=always --line-range :500 {}')
}

cdf() {
  local file dir
  file=$(fzf +m -q "$1") && dir=$(dirname "$file") && cd "$dir"
}

gs() {
  local g=(git log --graph --format='%C(auto)%h%d %s %C(white)%C(bold)%cr' --color=always --all "$@")
  local fzf=(fzf --ansi --reverse --tiebreak=index --no-sort
    --preview 'f() { set -- $(echo -- "$@" | grep -o "[a-f0-9]\{7\}"); [ $# -eq 0 ] || git show --name-only $1; }; f {}'
    --bind "ctrl-m:execute:
              (grep -o '[a-f0-9]\{7\}' | head -1 |
              xargs -I % sh -c 'git show --color=always % | less -R') << 'FZF-EOF'
              {}
  FZF-EOF")
  $g | $fzf
}

gshow() {
  local g=(git log --graph --format='%C(auto)%h%d %s %C(white)%C(bold)%cr' --color=always "$@")
  local fzf=(fzf --ansi --reverse --tiebreak=index --no-sort --bind=ctrl-s:toggle-sort
    --preview 'f() { set -- $(echo -- "$@" | grep -o "[a-f0-9]\{7\}"); [ $# -eq 0 ] || git show --color=always $1; }; f {}')
  $g | $fzf | grep -o "[a-f0-9]\{7\}"
}

v() {
  local files
  files=$(grep '^>' ~/.viminfo | cut -c3- |
          while read line; do
            [ -f "${line/\~/$HOME}" ] && echo "$line"
          done | fzf -d -m -q "$*" -1) && vim ${files//\~/$HOME}
}
