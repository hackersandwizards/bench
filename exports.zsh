# --- PATH ---
# mise shims serve non-interactive shells and apps; interactive shells get
# `mise activate` from init.zsh on top.
export PATH="\
$ZSH_SETTINGS_DIR/bin:\
$HOME/.local/bin:\
$HOME/.local/share/mise/shims:\
/opt/homebrew/opt/rustup/bin:\
$HOME/.cargo/bin:\
$HOME/go/bin:\
$HOME/.antigravity-ide/antigravity-ide/bin:\
$HOME/Library/Application Support/JetBrains/Toolbox/scripts:\
/opt/homebrew/opt/python3/libexec/bin:\
/opt/homebrew/opt/unzip/bin:\
/opt/homebrew/share/google-cloud-sdk/bin:\
/opt/homebrew/bin:\
/opt/homebrew/sbin:\
$PATH"

# --- Homebrew ---
# Load formulae/casks/commands only from official or explicitly-trusted taps
# (default in Homebrew 6.0 / 5.2). Trust state lives in ~/.homebrew/trust.json;
# add taps with `brew trust --tap <user>/<tap>`.
export HOMEBREW_REQUIRE_TAP_TRUST=1
# Ask mode (plan-then-confirm prompt before install/upgrade/reinstall) became the
# default in recent Homebrew; HOMEBREW_NO_ASK is the documented opt-out so update
# runs (`ua`) and manual upgrades proceed unattended. A bare `--ask` still overrides.
export HOMEBREW_NO_ASK=1
export HOMEBREW_NO_ENV_HINTS=1

# --- Locale ---
export LANG="en_US.UTF-8"

# --- Editor ---
export EDITOR="vim"
export VISUAL="vim"

# --- Claude Code ---
export CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1

# --- bat ---
export BAT_THEME="ansi"

# --- ripgrep ---
export RIPGREP_CONFIG_PATH="$ZSH_SETTINGS_DIR/ripgreprc"

# --- Python / pip ---
# Homebrew's Python is externally-managed (PEP 668), so pip refuses to install
# without this. Tracked here instead of untracked ~/.config/pip so fresh
# machines work. bin/_lib.sh sets the same for the bash scripts.
export PIP_BREAK_SYSTEM_PACKAGES=1

# --- npm ---
# npm comes from mise ("npm:npm" in the mise config) so it stays at its latest
# release without touching the node formula's npm. Without this, that npm derives
# its global prefix from the Cellar path of node. bin/_lib.sh sets the same.
export NPM_CONFIG_PREFIX=/opt/homebrew

# --- Secrets (untracked, gitignored) ---
[[ -f "$ZSH_SETTINGS_DIR/secrets.zsh" ]] && source "$ZSH_SETTINGS_DIR/secrets.zsh"
