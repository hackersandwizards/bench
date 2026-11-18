# mise shims serve non-interactive shells and apps; interactive shells get
# `mise activate` from init.zsh on top.
export PATH="\
$ZSH_SETTINGS_DIR/bin:\
$HOME/.local/bin:\
$HOME/.local/share/mise/shims:\
/opt/homebrew/opt/rustup/bin:\
$HOME/.cargo/bin:\
$HOME/go/bin:\
$HOME/Library/Application Support/JetBrains/Toolbox/scripts:\
$HOME/.t3/bin:\
/opt/homebrew/opt/python@3.14/libexec/bin:\
/opt/homebrew/opt/unzip/bin:\
/opt/homebrew/share/google-cloud-sdk/bin:\
/opt/homebrew/bin:\
/opt/homebrew/sbin:\
$PATH"

# Ask mode (plan-then-confirm prompt before install/upgrade/reinstall) became the
# default in recent Homebrew; HOMEBREW_NO_ASK is the documented opt-out so update
# runs (`ua`) and manual upgrades proceed unattended. A bare `--ask` still overrides.
export HOMEBREW_NO_ASK=1
export HOMEBREW_NO_ENV_HINTS=1

export LANG="en_US.UTF-8"

export EDITOR="vim"
export VISUAL="vim"

export CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1

# The Claude desktop app and terminal sessions share ~/.claude.json, and each caches the account of
# its own login there, so a tool that switches the terminal login finds the app's account in it.
# With CLAUDE_CONFIG_DIR naming the default folder, terminal sessions keep that file at
# ~/.claude/.claude.json and everything else where it was. The empty CLAUDE_SECURESTORAGE_CONFIG_DIR
# keeps the login in the default keychain item, which CLAUDE_CONFIG_DIR alone would move. Only where
# the file exists: copy ~/.claude.json there first, or a session starts without its project state.
if [[ -f $HOME/.claude/.claude.json ]]; then
  export CLAUDE_CONFIG_DIR="$HOME/.claude" CLAUDE_SECURESTORAGE_CONFIG_DIR=
fi

export BAT_THEME="ansi"

export RIPGREP_CONFIG_PATH="$ZSH_SETTINGS_DIR/ripgreprc"

# Homebrew's Python is externally-managed (PEP 668), so pip refuses to install
# without this. Tracked here instead of untracked ~/.config/pip so fresh
# machines work. bin/_lib.sh sets the same for the bash scripts.
export PIP_BREAK_SYSTEM_PACKAGES=1

# npm comes from mise ("npm:npm" in the mise config) so it stays at its latest
# release. Without this, that npm derives its global prefix from its own mise
# install folder. bin/_lib.sh sets the same.
export NPM_CONFIG_PREFIX=/opt/homebrew

# astro and vite call module.enableCompileCache(). Bun keys each entry by file path and never
# evicts, so every build's content-hashed chunks add entries to $TMPDIR/node-compile-cache without
# bound (53 GB in two days). ~/.claude/settings.json sets the same for Claude sessions.
export NODE_DISABLE_COMPILE_CACHE=1

# Bun never prunes its runtime transpiler cache (~/Library/Caches/bun/@t@): each Company OS check
# serving dist/server/entry.mjs adds a ~177 MB entry, 20-40 GB a day. Same in ~/.claude/settings.json.
export BUN_RUNTIME_TRANSPILER_CACHE_PATH=0

[[ -f "$ZSH_SETTINGS_DIR/secrets.zsh" ]] && source "$ZSH_SETTINGS_DIR/secrets.zsh"
