# --- PATH ---
export PATH="\
$ZSH_SETTINGS_DIR/bin:\
$HOME/.local/bin:\
$HOME/.cargo/bin:\
$HOME/go/bin:\
$HOME/.gem/ruby/4.0.0/bin:\
$HOME/.antigravity/antigravity/bin:\
$HOME/Library/Application Support/JetBrains/Toolbox/scripts:\
/opt/homebrew/opt/ruby/bin:\
/opt/homebrew/opt/python@3.14/libexec/bin:\
/opt/homebrew/opt/gnu-sed/libexec/gnubin:\
/opt/homebrew/opt/gnu-tar/libexec/gnubin:\
/opt/homebrew/opt/coreutils/libexec/gnubin:\
/opt/homebrew/opt/unzip/bin:\
/opt/homebrew/bin:\
/opt/homebrew/sbin:\
$PATH"

# --- Ruby ---
export GEM_HOME="$HOME/.gem/ruby/4.0.0"
export GEM_PATH="$GEM_HOME:/opt/homebrew/lib/ruby/gems/4.0.0"
export LDFLAGS="-L/opt/homebrew/opt/ruby/lib"
export CPPFLAGS="-I/opt/homebrew/opt/ruby/include"
export PKG_CONFIG_PATH="/opt/homebrew/opt/ruby/lib/pkgconfig"

# --- Google Cloud SDK (path only, completions deferred to init.zsh) ---
source "/opt/homebrew/share/google-cloud-sdk/path.zsh.inc"

# --- Manpages ---
export MANPATH="/opt/homebrew/opt/gnu-sed/libexec/gnuman:/opt/homebrew/opt/coreutils/libexec/gnuman:$MANPATH"

# --- Locale ---
export LANG="en_US.UTF-8"

# --- Claude Code ---
export CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1

# --- bat ---
export BAT_THEME="ansi"

# --- Secrets (untracked, gitignored) ---
[[ -f "$ZSH_SETTINGS_DIR/secrets.zsh" ]] && source "$ZSH_SETTINGS_DIR/secrets.zsh"
