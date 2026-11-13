# delta takes two paths and no diff flags: any other call goes to diff itself.
diff() {
  if [[ -t 1 && $# -eq 2 && $1 != -* && $2 != -* ]] && (( $+commands[delta] )); then delta "$@"
  else command diff "$@"
  fi
}

fkill() {
  local pid
  pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')
  [[ -n "$pid" ]] && echo "$pid" | xargs kill "-${1:-9}"
}

fview() {
  local f
  f=$(fzf --preview "$FZF_BAT_PREVIEW") && "${EDITOR:-vim}" "$f"
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
    --preview 'f() { set -- $(echo -- "$@" | grep -o "[a-f0-9]\{7,\}"); [ $# -eq 0 ] || git show --name-only $1; }; f {}'
    --bind "ctrl-m:execute:
              (grep -o '[a-f0-9]\{7,\}' | head -1 |
              xargs -I % sh -c 'git show --color=always % | less -R') << 'FZF-EOF'
              {}
FZF-EOF")
  _git_log_graph --all "$@" | $fzf
}

gshow() {
  local fzf=(fzf --ansi --reverse --tiebreak=index --no-sort --bind=ctrl-s:toggle-sort
    --preview 'f() { set -- $(echo -- "$@" | grep -o "[a-f0-9]\{7,\}"); [ $# -eq 0 ] || git show --color=always $1; }; f {}')
  _git_log_graph "$@" | $fzf | grep -o "[a-f0-9]\{7,\}" | head -1
}

v() {
  local files
  files=$(grep '^>' ~/.viminfo | cut -c3- |
          while read -r line; do
            [ -f "${line/#\~/$HOME}" ] && echo "$line"
          done | fzf -m -q "$*" -1) && vim ${${(f)files}/#\~/$HOME}
}

# Claude Desktop keeps a repository's .mcp.json servers off where its .claude/settings.local.json
# lists them, and brings its own connectors. A terminal session loads every .mcp.json server: the
# flag adds them as a separate source, which that list does not reach. It also skips the trust
# prompt for project servers. Subcommands (mcp, auth, agents ...) take no such flag. A claude that
# an agent starts from its Bash tool (CLAUDECODE is set there, Desktop sessions included) gets no
# flag either: the tool's shell carries this function, and a child session keeps to its settings.
claude() {
  if [[ -z $CLAUDECODE && ( $# -eq 0 || $1 == -* ) && -f .mcp.json ]]; then
    command claude --mcp-config .mcp.json "$@"
  else
    command claude "$@"
  fi
}
