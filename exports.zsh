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
$HOME/.antigravity/antigravity/bin:\
$HOME/Library/Application Support/JetBrains/Toolbox/scripts:\
/opt/homebrew/opt/ruby/bin:\
/opt/homebrew/opt/python@3.14/libexec/bin:\
/opt/homebrew/opt/gnu-sed/libexec/gnubin:\
/opt/homebrew/opt/gnu-tar/libexec/gnubin:\
/opt/homebrew/opt/coreutils/libexec/gnubin:\
/opt/homebrew/opt/unzip/bin:\
/opt/homebrew/share/google-cloud-sdk/bin:\
/opt/homebrew/bin:\
/opt/homebrew/sbin:\
$PATH"

# --- Ruby ---
if [[ -n "$RUBY_API" ]]; then
  export GEM_HOME="$HOME/.gem/ruby/$RUBY_API"
  export GEM_PATH="$GEM_HOME:/opt/homebrew/lib/ruby/gems/$RUBY_API"
fi
unset RUBY_API
export LDFLAGS="-L/opt/homebrew/opt/ruby/lib"
export CPPFLAGS="-I/opt/homebrew/opt/ruby/include"
export PKG_CONFIG_PATH="/opt/homebrew/opt/ruby/lib/pkgconfig"

# --- Manpages ---
export MANPATH="/opt/homebrew/opt/gnu-sed/libexec/gnuman:/opt/homebrew/opt/coreutils/libexec/gnuman:$MANPATH"

# --- Locale ---
export LANG="en_US.UTF-8"

# --- Claude Code ---
export CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1

# --- bat ---
export BAT_THEME="ansi"

# --- ripgrep ---
export RIPGREP_CONFIG_PATH="$ZSH_SETTINGS_DIR/ripgreprc"

# --- Secrets (untracked, gitignored) ---
[[ -f "$ZSH_SETTINGS_DIR/secrets.zsh" ]] && source "$ZSH_SETTINGS_DIR/secrets.zsh"
