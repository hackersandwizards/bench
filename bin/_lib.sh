# shellcheck shell=bash
# Shared helpers for bench-* and install.sh. Source via:
#   . "$(dirname "$0")/_lib.sh"

step() { printf '\n\033[1;36m▸ %s\033[0m\n' "$1"; }
ok()   { printf '\033[32m✓\033[0m %s\n' "$1"; }
warn() { printf '\033[33m⚠\033[0m %s\n' "$1"; }
fail() { printf '\033[31m✗\033[0m %s\n' "$1"; }
skip() { printf '\033[2m·\033[0m %s\n' "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }
indent() { sed 's/^/    /'; }  # detail lines under an ok/warn/fail

# Run "$@" silently; ok on success, fail on non-zero. Used by bench-doctor.
check() {
  local label="$1"; shift
  if "$@" >/dev/null 2>&1; then ok "$label"; else fail "$label"; fi
}

# Print step header, run "$@", ok or warn (continuing on failure). Used by bench-update.
run() {
  local label="$1"; shift
  step "$label"
  if "$@"; then ok "$label"; else warn "$label failed (continuing)"; fi
}

# Homebrew's Python is externally-managed (PEP 668); pip refuses to install into
# it without this. install.sh's replay and bench-update's upgrades run pip under
# bash — and on a fresh machine ~/.zshrc has not yet sourced exports.zsh — so set
# it here, the one file every script sources. Mirrors exports.zsh (interactive).
export PIP_BREAK_SYSTEM_PACKAGES=1

# --- Homebrew bottle-support guard ------------------------------------------
# Homebrew maps the running macOS major to a codename (its macos_version.rb
# SYMBOLS table). A macOS newer than the newest entry has no codename, so the
# bottle tag becomes "arm64_dunno" and every formulae.brew.sh JSON-API fetch
# 404s — brew upgrade/cleanup/leaves fail and retry in a loop. This lasts from a
# major macOS release until Homebrew ships support for it. Reading brew's own
# map (not a hardcoded ceiling) makes the guard self-clear the day brew updates.

# Newest macOS major Homebrew ships bottles for; empty when the map is unreadable.
brew_newest_macos() {
  local map; map="$(brew --repository 2>/dev/null)/Library/Homebrew/macos_version.rb"
  [[ -r "$map" ]] || return 0
  sed -n 's/^[[:space:]]*[a-z_]*:[[:space:]]*"\([0-9][0-9.]*\)".*/\1/p' "$map" \
    | cut -d. -f1 | sort -n | tail -1
}

# True unless the running macOS is newer than brew's newest supported major.
# An unreadable map or non-macOS host counts as supported — never wrongly block.
brew_bottles_supported() {
  local major newest
  major="$(sw_vers -productVersion 2>/dev/null)"; major="${major%%.*}"
  newest="$(brew_newest_macos)"
  [[ -z "$major" || -z "$newest" ]] && return 0
  (( major <= newest ))
}

# One-line explanation for why brew steps were skipped on an unsupported macOS.
brew_unsupported_notice() {
  local major; major="$(sw_vers -productVersion 2>/dev/null)"; major="${major%%.*}"
  warn "Homebrew has no bottles for macOS $major yet (newest: $(brew_newest_macos)) — skipping brew steps"
  skip "tag is arm64_dunno; formulae.brew.sh 404s until Homebrew ships macOS $major support"
}

# shellcheck disable=SC2034  # consumed by bench-* and install.sh
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Current core.hooksPath setting; "<unset>" when unconfigured.
hooks_path() {
  git -C "$REPO_ROOT" config core.hooksPath 2>/dev/null || echo "<unset>"
}

# shellcheck disable=SC2034  # consumed by bench-update / bench-doctor
ANTIDOTE_SH="/opt/homebrew/opt/antidote/share/antidote/antidote.zsh"

SDKMAN_INIT="$HOME/.sdkman/bin/sdkman-init.sh"
SDKMAN_CONFIG="$HOME/.sdkman/etc/config"

# Source SDKMAN's init so the `sdk` shell function exists (it is not a binary,
# so `have sdk` is false until this runs). The init script references unset
# vars, so `set +u` wraps it; `set -u` after re-enables nounset — both callers
# run under `set -u` and depend on it staying on. Returns 1 when SDKMAN is absent.
source_sdkman() {
  [[ -s "$SDKMAN_INIT" ]] || return 1
  set +u
  # shellcheck disable=SC1090
  source "$SDKMAN_INIT"
  set -u
}

# Run the `sdk` function with nounset relaxed and restore it after. SDKMAN reads
# $2 (and other unset vars) unconditionally — `sdk selfupdate` aborts with
# "$2: unbound variable" under `set -u`, which all bench-* scripts enable.
# Requires source_sdkman to have run first. Returns sdk's own exit code.
sdk_run() {
  set +u
  sdk "$@"
  local rc=$?
  set -u
  return "$rc"
}

# Idempotently set KEY=VALUE in SDKMAN's etc/config (the file holding prompt and
# auto-answer settings). Rewrites an existing KEY= line or appends a new one.
# No-op when SDKMAN is absent. Edits via a temp file (no `sed -i`) so it works
# under both BSD and GNU sed; `cat >` preserves the config's perms and inode.
sdkman_set_config() {
  local key="$1" value="$2" tmp
  [[ -f "$SDKMAN_CONFIG" ]] || return 1
  if grep -q "^${key}=" "$SDKMAN_CONFIG"; then
    tmp="$(mktemp)"
    sed "s/^${key}=.*/${key}=${value}/" "$SDKMAN_CONFIG" > "$tmp" \
      && cat "$tmp" > "$SDKMAN_CONFIG"
    rm -f "$tmp"
  else
    printf '%s=%s\n' "$key" "$value" >> "$SDKMAN_CONFIG"
  fi
}

# shellcheck disable=SC2034  # consumed by bench-* and install.sh
STOW_FILES=(
  ".gitconfig"
  ".vimrc"
  ".mongorc.js"
  ".tmux.conf"
  ".gitignore_global"
  ".commitTemplate.txt"
  ".ssh/config"
)

# docs/ snapshot parsers — each reads a snapshot file ($1) and emits one package
# per line (parse_sdk emits "name version"); the output feeds install.sh's
# replay_globals. Sourced from here so they are unit-testable (see bench-test).
parse_uv()    { awk 'NF && $1 !~ /^-/ { print $1 }' "$1"; }
parse_cargo() { awk '/^[^[:space:]]/ { print $1 }' "$1"; }
parse_pip()   { awk -F'==' '/==/ { print $1 }' "$1"; }
parse_sdk()   { awk 'NF == 2 { print $1, $2 }' "$1"; }
# Replay only gems carrying a user-installed version; skip Ruby's bundled gems
# (those show a lone `default:` version).
parse_gem()   { awk -F' *[()] *' 'NF > 1 && $2 !~ /^default:/ { print $1 }' "$1"; }
# npm/bun global lists: take the last `name@version` field and strip the version.
# `npm` is dropped — reinstalling the package manager is a no-op.
parse_node()  { awk 'NF && $NF ~ /@/ { n=$NF; sub(/@[^@]*$/, "", n); if (n != "npm") print n }' "$1"; }
