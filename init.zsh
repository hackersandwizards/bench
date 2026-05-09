# --- Profiling toggle (set ZSH_PROFILE=1 before sourcing to enable) ---
[[ -n "$ZSH_PROFILE" ]] && zmodload zsh/zprof

# --- zsh options ---
# EXTENDED_GLOB: required for (#q...) glob qualifiers used below.
# AUTO_CD / AUTO_PUSHD / PUSHD_IGNORE_DUPS: bare directory cd's, with a dedup'd dir stack.
# HIST_*: keep raw ~/.zsh_history clean even though atuin handles search.
setopt EXTENDED_GLOB AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS \
       HIST_IGNORE_DUPS HIST_REDUCE_BLANKS HIST_VERIFY
HISTSIZE=100000
SAVEHIST=100000
HISTFILE="$HOME/.zsh_history"

# --- Self-discovery: resolve repo dir from this file's location ---
export ZSH_SETTINGS_DIR="${${(%):-%N}:A:h}"

# --- Exports (PATH must be set before tools that depend on it) ---
source "$ZSH_SETTINGS_DIR/exports.zsh"

# --- Init-output cache: source $1's `init zsh` output from disk; regenerate
#     when the binary is newer than the cached file. Zero forks on cache hit
#     ($commands is a zsh builtin associative array). ---
_init_cache() {
  local bin="$1"; shift
  local out="$HOME/.cache/zsh/$bin.zsh"
  if [[ ! -f "$out" || "$commands[$bin]" -nt "$out" ]]; then
    mkdir -p "$HOME/.cache/zsh"
    "$bin" "$@" > "$out" 2>/dev/null
  fi
  source "$out" 2>/dev/null
}

# --- Starship prompt ---
export STARSHIP_CONFIG="$ZSH_SETTINGS_DIR/starship.toml"
_init_cache starship init zsh

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
_init_cache zoxide init zsh
_init_cache atuin init zsh

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

# --- fzf-tab + history-substring-search (must load after compinit) ---
_antidote_bundle plugins-post
# Up/Down walk history filtered by the prefix already typed on the command line.
# Atuin owns Ctrl-R for fuzzy search; this covers the "I just want the previous
# command starting with `git p`" reflex.
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
# fzf-tab inherits FZF_DEFAULT_OPTS, so layout/border/colors are already covered.
# Reuse the FZF_*_PREVIEW commands from fzf.zsh, swapping the `{}` placeholder
# for fzf-tab's `$realpath` (single source of truth for preview formatting).
_eza_pv="${FZF_EZA_PREVIEW//\{\}/\$realpath}"
_bat_pv="${FZF_BAT_PREVIEW//\{\}/\$realpath}"
for _ctx in cd ls eza; do
  zstyle ":fzf-tab:complete:$_ctx:*" fzf-preview "$_eza_pv"
done
for _ctx in cat bat vim; do
  zstyle ":fzf-tab:complete:$_ctx:*" fzf-preview "$_bat_pv"
done
unset _eza_pv _bat_pv _ctx
zstyle ':fzf-tab:complete:git-checkout:*' fzf-preview 'git log --color=always --oneline -20 $word'
zstyle ':fzf-tab:complete:git-log:*' fzf-preview 'git log --color=always --oneline -20 $word'
zstyle ':fzf-tab:complete:kill:*' fzf-preview 'ps -p $word -o pid,user,%cpu,%mem,command'

# --- SDKMAN (candidates on PATH, sdk command lazy-loaded) ---
export SDKMAN_DIR="$HOME/.sdkman"
_sdk_bins=( "$SDKMAN_DIR/candidates/"*/current/bin(N) )
(( $#_sdk_bins )) && export PATH="${(j.:.)_sdk_bins}:$PATH"
unset _sdk_bins
function sdk() {
  unfunction sdk
  source "$SDKMAN_DIR/bin/sdkman-init.sh"
  sdk "$@"
}

# --- Bun ---
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# --- Deferred completions (lazy-loaded on first invocation, ~10ms saved at startup) ---
# Trade-off: tab-complete on `gcloud`/`entire`/`bun <TAB>` is silent until the
# command has been run once per session — then completions register and behave
# normally. Direct invocations (`bun --version`) always work — they hit the
# function stub which sources, unsets itself, and execs the binary.
function gcloud() {
  unfunction gcloud
  source "/opt/homebrew/share/google-cloud-sdk/completion.zsh.inc"
  gcloud "$@"
}
function entire() {
  unfunction entire
  _init_cache entire completion zsh
  entire "$@"
}
function bun() {
  unfunction bun
  [ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
  bun "$@"
}

# direnv adds a chpwd hook — must be registered eagerly to fire on every cd.
_init_cache direnv hook zsh

# --- Profiling report (only emitted if ZSH_PROFILE=1) ---
[[ -n "$ZSH_PROFILE" ]] && zprof
