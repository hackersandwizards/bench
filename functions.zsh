# --- Color-aware diff (delta when interactive, plain otherwise) ---
diff() { if [ -t 1 ]; then delta "$@"; else command diff "$@"; fi }

# --- fzf-driven helpers ---
fkill() {
  local pid
  pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')
  [[ -n "$pid" ]] && echo "$pid" | xargs kill "-${1:-9}"
}

fview() {
  $EDITOR $(fzf --preview 'bat --style=numbers --color=always --line-range :500 {}')
}

cdf() {
  local file
  file=$(fzf +m -q "$1") && cd "${file:h}"
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
