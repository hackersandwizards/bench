# --- Color-aware diff (delta when interactive, plain otherwise) ---
diff() { if [ -t 1 ]; then delta "$@"; else command diff "$@"; fi }

# --- fzf-driven helpers ---
fkill() {
  local pid
  pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')
  [[ -n "$pid" ]] && echo "$pid" | xargs kill "-${1:-9}"
}

fview() {
  local f
  f=$(fzf --preview "$FZF_BAT_PREVIEW") && "$EDITOR" "$f"
}

cdf() {
  local file
  file=$(fzf +m -q "$1") && cd "${file:h}"
}

_git_log_graph() {
  git log --graph --format='%C(auto)%h%d %s %C(white)%C(bold)%cr' --color=always "$@"
}

gs() {
  local fzf=(fzf --ansi --reverse --tiebreak=index --no-sort
    --preview 'f() { set -- $(echo -- "$@" | grep -o "[a-f0-9]\{7\}"); [ $# -eq 0 ] || git show --name-only $1; }; f {}'
    --bind "ctrl-m:execute:
              (grep -o '[a-f0-9]\{7\}' | head -1 |
              xargs -I % sh -c 'git show --color=always % | less -R') << 'FZF-EOF'
              {}
  FZF-EOF")
  _git_log_graph --all "$@" | $fzf
}

gshow() {
  local fzf=(fzf --ansi --reverse --tiebreak=index --no-sort --bind=ctrl-s:toggle-sort
    --preview 'f() { set -- $(echo -- "$@" | grep -o "[a-f0-9]\{7\}"); [ $# -eq 0 ] || git show --color=always $1; }; f {}')
  _git_log_graph "$@" | $fzf | grep -o "[a-f0-9]\{7\}"
}

v() {
  local files
  files=$(grep '^>' ~/.viminfo | cut -c3- |
          while read line; do
            [ -f "${line/\~/$HOME}" ] && echo "$line"
          done | fzf -d -m -q "$*" -1) && vim ${files//\~/$HOME}
}
