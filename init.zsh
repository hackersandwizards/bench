# --- Profiling toggle (set ZSH_PROFILE=1 before sourcing to enable) ---
[[ -n "$ZSH_PROFILE" ]] && zmodload zsh/zprof

# --- Glob qualifiers (#q...) need EXTENDED_GLOB ---
setopt EXTENDED_GLOB

# --- Self-discovery: resolve repo dir from this file's location ---
export ZSH_SETTINGS_DIR="${${(%):-%N}:A:h}"

# --- Exports (PATH must be set before tools that depend on it) ---
source "$ZSH_SETTINGS_DIR/exports.zsh"

# --- Init-output cache: source $1's `init zsh` output from disk; regenerate
#     when the binary is newer than the cached file. Zero forks on cache hit
#     ($commands is a zsh builtin associative array). ---
_init_cache() {
  local name="$1" bin="$2"; shift 2
  local out="$HOME/.cache/zsh/$name.zsh"
  if [[ ! -f "$out" || "$commands[$bin]" -nt "$out" ]]; then
    [[ -d "$HOME/.cache/zsh" ]] || mkdir -p "$HOME/.cache/zsh"
    "$bin" "$@" > "$out" 2>/dev/null
  fi
  source "$out" 2>/dev/null
}

# --- Starship prompt ---
export STARSHIP_CONFIG="$ZSH_SETTINGS_DIR/starship.toml"
_init_cache starship starship init zsh

# --- Antidote (static bundles regenerated when source txt changes) ---
_antidote_bundle() {
  local txt="$ZSH_SETTINGS_DIR/$1.txt" out="$ZSH_SETTINGS_DIR/$1.zsh"
  if [[ ! -f "$out" || "$txt" -nt "$out" ]]; then
    source /opt/homebrew/opt/antidote/share/antidote/antidote.zsh
    antidote bundle < "$txt" > "$out"
  fi
  source "$out"
}
_antidote_bundle plugins

# --- zoxide / atuin (cached) ---
_init_cache zoxide zoxide init zsh
_init_cache atuin atuin init zsh

# --- Completions fpath (must be before compinit) ---
fpath=(/opt/homebrew/share/zsh/site-functions $HOME/.docker/completions $fpath)

# --- Source modules ---
source "$ZSH_SETTINGS_DIR/fzf.zsh"
source "$ZSH_SETTINGS_DIR/functions.zsh"
source "$ZSH_SETTINGS_DIR/aliases.zsh"

# --- Bracketed paste magic ---
pasteinit() {
  OLD_SELF_INSERT=${${(s.:.)widgets[self-insert]}[2,3]}
  zle -N self-insert url-quote-magic
}
pastefinish() {
  zle -N self-insert $OLD_SELF_INSERT
}
zstyle :bracketed-paste-magic paste-init pasteinit
zstyle :bracketed-paste-magic paste-finish pastefinish

# --- compinit (full check max once per 24h, else use cached dump) ---
autoload -Uz compinit
if [[ -n ~/.zcompdump(#qNmh-24) ]]; then
  compinit -C
else
  compinit
fi

# --- fzf-tab (must load after compinit) ---
_antidote_bundle plugins-post
zstyle ':fzf-tab:*' fzf-flags --height 40% --layout=reverse --border
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --tree --icons --level=2 $realpath'
zstyle ':fzf-tab:complete:ls:*' fzf-preview 'eza --tree --icons --level=2 $realpath'
zstyle ':fzf-tab:complete:eza:*' fzf-preview 'eza --tree --icons --level=2 $realpath'
zstyle ':fzf-tab:complete:cat:*' fzf-preview 'bat --style=numbers --color=always --line-range :300 $realpath'
zstyle ':fzf-tab:complete:bat:*' fzf-preview 'bat --style=numbers --color=always --line-range :300 $realpath'
zstyle ':fzf-tab:complete:vim:*' fzf-preview 'bat --style=numbers --color=always --line-range :300 $realpath'
zstyle ':fzf-tab:complete:git-checkout:*' fzf-preview 'git log --color=always --oneline -20 $word'
zstyle ':fzf-tab:complete:git-log:*' fzf-preview 'git log --color=always --oneline -20 $word'
zstyle ':fzf-tab:complete:kill:*' fzf-preview 'ps -p $word -o pid,user,%cpu,%mem,command'

# --- SDKMAN (candidates on PATH, sdk command lazy-loaded) ---
export SDKMAN_DIR="$HOME/.sdkman"
for _dir in "$SDKMAN_DIR/candidates/"*/current/bin(N); do
  export PATH="$_dir:$PATH"
done
unset _dir
function sdk() {
  unfunction sdk
  source "$SDKMAN_DIR/bin/sdkman-init.sh"
  sdk "$@"
}

# --- Bun ---
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# --- Deferred completions (lazy-loaded after compinit) ---
function gcloud() {
  unfunction gcloud
  source "/opt/homebrew/share/google-cloud-sdk/completion.zsh.inc"
  gcloud "$@"
}

# entire CLI completion + direnv hook (cached, auto-invalidate on binary upgrade)
_init_cache entire entire completion zsh
_init_cache direnv direnv hook zsh

# --- Profiling report (only emitted if ZSH_PROFILE=1) ---
[[ -n "$ZSH_PROFILE" ]] && zprof
