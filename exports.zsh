# Ruby ABI from the brew keg (the /opt/homebrew/opt/ruby symlink follows upgrades).
_ruby_dirs=( /opt/homebrew/opt/ruby/lib/ruby/gems/*(/N:t) )
RUBY_API="${_ruby_dirs[1]-}"
unset _ruby_dirs

# --- PATH ---
export PATH="\
$ZSH_SETTINGS_DIR/bin:\
$HOME/.local/bin:\
$HOME/.cargo/bin:\
$HOME/go/bin:\
${RUBY_API:+$HOME/.gem/ruby/$RUBY_API/bin:}\
$HOME/.antigravity-ide/antigravity-ide/bin:\
$HOME/Library/Application Support/JetBrains/Toolbox/scripts:\
/opt/homebrew/opt/ruby/bin:\
/opt/homebrew/opt/python3/libexec/bin:\
/opt/homebrew/opt/unzip/bin:\
/opt/homebrew/share/google-cloud-sdk/bin:\
/opt/homebrew/bin:\
/opt/homebrew/sbin:\
$PATH:\
/opt/homebrew/opt/llvm/bin"

# --- Ruby ---
if [[ -n "$RUBY_API" ]]; then
  export GEM_HOME="$HOME/.gem/ruby/$RUBY_API"
  export GEM_PATH="$GEM_HOME:/opt/homebrew/lib/ruby/gems/$RUBY_API"
  # Keg-only ruby: native gem builds need the header/lib paths. Inside the
  # guard so a machine without the ruby keg does not point every build here.
  export LDFLAGS="-L/opt/homebrew/opt/ruby/lib"
  export CPPFLAGS="-I/opt/homebrew/opt/ruby/include"
  export PKG_CONFIG_PATH="/opt/homebrew/opt/ruby/lib/pkgconfig"
fi
unset RUBY_API

# --- Homebrew ---
# Load formulae/casks/commands only from official or explicitly-trusted taps
# (default in Homebrew 6.0 / 5.2). Trust state lives in ~/.homebrew/trust.json;
# add taps with `brew trust --tap <user>/<tap>`.
export HOMEBREW_REQUIRE_TAP_TRUST=1
# Ask mode (plan-then-confirm prompt before install/upgrade/reinstall) became the
# default in recent Homebrew; HOMEBREW_NO_ASK is the documented opt-out so update
# runs (`ua`) and manual upgrades proceed unattended. A bare `--ask` still overrides.
export HOMEBREW_NO_ASK=1

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

# --- Secrets (untracked, gitignored) ---
[[ -f "$ZSH_SETTINGS_DIR/secrets.zsh" ]] && source "$ZSH_SETTINGS_DIR/secrets.zsh"
