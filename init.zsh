# --- Profiling toggle (set ZSH_PROFILE=1 before sourcing to enable) ---
[[ -n "$ZSH_PROFILE" ]] && zmodload zsh/zprof

# --- Self-discovery: resolve repo dir from this file's location ---
export ZSH_SETTINGS_DIR="${${(%):-%N}:A:h}"

# --- Exports (PATH must be set before tools that depend on it) ---
source "$ZSH_SETTINGS_DIR/exports.zsh"

# --- Starship prompt ---
export STARSHIP_CONFIG="$ZSH_SETTINGS_DIR/starship.toml"
eval "$(starship init zsh)"

# --- Antidote plugin manager (core plugins, before compinit) ---
source /opt/homebrew/opt/antidote/share/antidote/antidote.zsh
antidote load "$ZSH_SETTINGS_DIR/plugins.txt"

# --- zoxide ---
eval "$(zoxide init zsh)"

# --- atuin (replaces zsh native history with SQLite-backed search) ---
if command -v atuin >/dev/null 2>&1; then
  eval "$(atuin init zsh)"
else
  HISTSIZE=10000
  SAVEHIST=20000
  setopt HIST_IGNORE_DUPS
  setopt HIST_IGNORE_SPACE
  setopt SHARE_HISTORY
  setopt APPEND_HISTORY
fi

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

# --- compinit (once, cached) ---
autoload -Uz compinit
for dump in ~/.zcompdump(N.mh+24); do
  compinit
done
compinit -C

# --- fzf-tab (must load after compinit) ---
antidote load "$ZSH_SETTINGS_DIR/plugins-post.txt"
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

# entire CLI completion (cached, regenerated weekly)
local _entire_cache="$HOME/.cache/zsh/entire-completion.zsh"
if [[ ! -f "$_entire_cache" ]] || [[ -n $(find "$_entire_cache" -mtime +7 2>/dev/null) ]]; then
  mkdir -p "$HOME/.cache/zsh"
  entire completion zsh > "$_entire_cache" 2>/dev/null
fi
source "$_entire_cache" 2>/dev/null

# --- direnv (per-project env vars, runs after global secrets) ---
command -v direnv >/dev/null 2>&1 && eval "$(direnv hook zsh)"

# --- Profiling report (only emitted if ZSH_PROFILE=1) ---
[[ -n "$ZSH_PROFILE" ]] && zprof
