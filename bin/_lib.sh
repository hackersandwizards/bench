# shellcheck shell=bash
# Shared helpers for bench-* and install.sh. Source via:
#   . "$(dirname "$0")/_lib.sh"

step() { printf '\n\033[1;36m▸ %s\033[0m\n' "$1"; }
ok()   { printf '\033[32m✓\033[0m %s\n' "$1"; }
warn() { printf '\033[33m⚠\033[0m %s\n' "$1"; }
fail() { printf '\033[31m✗\033[0m %s\n' "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }

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

# shellcheck disable=SC2034  # consumed by bench-* and install.sh
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck disable=SC2034  # consumed by bench-* and install.sh
STOW_FILES=(
  ".gitconfig"
  ".vimrc"
  ".mongorc.js"
  ".tmux.conf"
  ".gitignore_global"
  ".ssh/config"
)
