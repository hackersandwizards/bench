# --- Profiling toggle ---
[[ -n "$ZSH_PROFILE" ]] && zmodload zsh/zprof

# --- zsh options ---
# EXTENDED_GLOB: required for (#q...) glob qualifiers used below.
# HIST_*: keep raw ~/.zsh_history clean even though atuin handles search.
setopt EXTENDED_GLOB AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS \
       HIST_IGNORE_DUPS HIST_REDUCE_BLANKS HIST_VERIFY
HISTSIZE=100000
SAVEHIST=100000
HISTFILE="$HOME/.zsh_history"

# --- Self-discovery: resolve repo dir from this file's location ---
export ZSH_SETTINGS_DIR="${${(%):-%N}:A:h}"

# --- Exports (PATH must be set before tools that depend on it) ---
# -U dedups path/fpath: nested shells (tmux, `zsh` in zsh) re-prepend everything.
typeset -gU path fpath
source "$ZSH_SETTINGS_DIR/exports.zsh"

# --- Init-output cache: source cached `init zsh` output, regenerating when the
#     binary is newer. Cache hit forks nothing ($commands is a zsh builtin). ---
_init_cache() {
  local bin="$1"; shift
  local out="$HOME/.cache/zsh/$bin.zsh"
  if [[ ! -f "$out" || "$commands[$bin]" -nt "$out" ]]; then
    mkdir -p "$HOME/.cache/zsh"
    # tmp+mv: a partial write must never poison later shells. An absent
    # binary caches an empty no-op (fork-free until installed; -nt regens
    # then); a present-but-failing one retries next shell instead.
    if "$bin" "$@" > "$out.tmp" 2>/dev/null; then
      mv "$out.tmp" "$out"
    elif (( $+commands[$bin] )); then
      rm -f "$out.tmp" "$out"; return 1
    else
      rm -f "$out.tmp"; : > "$out"
    fi
  fi
  source "$out" 2>/dev/null
}

# --- Starship prompt ---
export STARSHIP_CONFIG="$ZSH_SETTINGS_DIR/starship.toml"
_init_cache starship init zsh

# --- Antidote (static bundle loading) ---
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

# --- Bracketed paste magic (quote URLs / shell metachars when pasting) ---
# zsh ships the widget but does not wire it up by default.
autoload -Uz bracketed-paste-magic url-quote-magic
zle -N bracketed-paste bracketed-paste-magic
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
# Re-assert history keybindings last: fzf's key-bindings.zsh (sourced above)
# grabs Ctrl-R and would shadow atuin-search without this. fzf keeps Ctrl-T +
# Alt-C, hence only those have FZF_*_OPTS in fzf.zsh.
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey '^R' atuin-search
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

# --- Bun (binary from brew; `bun add -g` still targets $BUN_INSTALL/bin) ---
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# --- Deferred completions (lazy-loaded, ~10ms saved at startup) ---
# Trade-off: tab-complete on gcloud/entire is silent until the command is run
# once per session, direct invocations always work. (bun needs no stub, brew
# ships _bun via site-functions/compinit.)
# Stub only when the SDK exists: on a fresh machine the stub's `source` would
# error where the shell's own "command not found" is the honest answer.
# (entire needs no guard: _init_cache fails silently and cleans up.)
if [[ -f /opt/homebrew/share/google-cloud-sdk/completion.zsh.inc ]]; then
  function gcloud() {
    unfunction gcloud
    source "/opt/homebrew/share/google-cloud-sdk/completion.zsh.inc"
    gcloud "$@"
  }
fi
function entire() {
  unfunction entire
  _init_cache entire completion zsh
  entire "$@"
}

# direnv adds a chpwd hook: it must be registered eagerly to fire on every cd.
_init_cache direnv hook zsh

# --- Profiling report ---
[[ -n "$ZSH_PROFILE" ]] && zprof
