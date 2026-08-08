# shellcheck shell=bash
# Shared helpers for bench-* and install.sh. Source via:
#   . "$(dirname "$0")/_lib.sh"

step() { printf '\n\033[1;36m▸ %s\033[0m\n' "$1"; }
ok()   { printf '\033[32m✓\033[0m %s\n' "$1"; }
# A file, not an array: warns from piped subshells and child scripts
# (macos.sh) must reach install.sh's end-of-run recap.
warn() { printf '\033[33m⚠\033[0m %s\n' "$1"; printf '%s\n' "$1" >> "${WARN_LOG:-/dev/null}"; }
fail() { printf '\033[31m✗\033[0m %s\n' "$1"; }
skip() { printf '\033[2m·\033[0m %s\n' "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }
indent() { sed 's/^/    /'; }

# Scripts must not fall back to Apple's Ruby or bypass Homebrew's Python tools.
export PATH="/opt/homebrew/opt/ruby/bin:/opt/homebrew/opt/python3/libexec/bin:$PATH"

check() {
  local label="$1"; shift
  if "$@" >/dev/null 2>&1; then ok "$label"; else fail "$label"; fi
}

ask() {
  local prompt="$1" default="${2:-Y}" reply hint
  if [[ "$default" == "Y" ]]; then hint="[Y/n]"; else hint="[y/N]"; fi
  # EOF (no TTY) declines: a piped/unattended run must never auto-confirm.
  read -rp "$prompt $hint " reply || return 1
  reply="${reply:-$default}"
  [[ "$reply" =~ ^[Yy]$ ]]
}

run() {
  local label="$1"; shift
  step "$label"
  if "$@"; then ok "$label"; else warn "$label failed (continuing)"; fi
}

# Guards the docs/secret-keys.txt trust boundary: key names land unquoted in
# `export KEY=` lines that exports.zsh sources on every shell start.
valid_key_name() { [[ "$1" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; }

# One sourceable `export KEY='value'` line. Single quotes so $ ` \ never
# expand; the replacement rides a variable because bash 3.2 mangles
# backslashes written literally in ${var//pat/rep} (bash 4.3 change).
# Fails closed on an invalid key name; callers pre-check for the UX message.
secret_line() {
  valid_key_name "$1" || return 1
  local q="'\\''"
  printf "export %s='%s'\n" "$1" "${2//\'/$q}"
}

# Homebrew's Python is externally-managed (PEP 668); pip refuses to install into
# it without this. install.sh's replay and bench-update's upgrades run pip under
# bash, and on a fresh machine ~/.zshrc has not yet sourced exports.zsh, so set
# it here, the one file every script sources. Mirrors exports.zsh (interactive).
export PIP_BREAK_SYSTEM_PACKAGES=1

# --- Homebrew bottle-support guard ------------------------------------------
# Homebrew maps the running macOS major to a codename (its macos_version.rb
# SYMBOLS table). A macOS newer than the newest entry has no codename, so the
# bottle tag becomes "arm64_dunno" and every formulae.brew.sh JSON-API fetch
# 404s: brew upgrade/cleanup/leaves fail and retry in a loop. This lasts from a
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
# An unreadable map or non-macOS host counts as supported: never wrongly block.
brew_bottles_supported() {
  local major newest
  major="$(sw_vers -productVersion 2>/dev/null)"; major="${major%%.*}"
  newest="$(brew_newest_macos)"
  [[ -z "$major" || -z "$newest" ]] && return 0
  (( major <= newest ))
}

brew_unsupported_notice() {
  local major; major="$(sw_vers -productVersion 2>/dev/null)"; major="${major%%.*}"
  warn "Homebrew has no bottles for macOS $major yet (newest: $(brew_newest_macos)) — skipping brew steps"
  skip "tag is arm64_dunno; formulae.brew.sh 404s until Homebrew ships macOS $major support"
}

# shellcheck disable=SC2034  # consumed by bench-* and install.sh
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# macos.sh sets this wallpaper; bench-doctor verifies it. One owner, no drift.
# shellcheck disable=SC2034
WALLPAPER="$REPO_ROOT/assets/wallpaper.png"

hooks_path() {
  git -C "$REPO_ROOT" config core.hooksPath 2>/dev/null || echo "<unset>"
}

# shellcheck disable=SC2034  # consumed by bench-update / bench-doctor
ANTIDOTE_SH="/opt/homebrew/opt/antidote/share/antidote/antidote.zsh"

SDKMAN_INIT="$HOME/.sdkman/bin/sdkman-init.sh"
SDKMAN_CONFIG="$HOME/.sdkman/etc/config"

# Source SDKMAN's init so the `sdk` shell function exists. It is not a binary,
# so `have sdk` is false until this runs. The init reads unset vars, so `set +u`
# wraps it.
source_sdkman() {
  [[ -s "$SDKMAN_INIT" ]] || return 1
  if (( BASH_VERSINFO[0] < 4 )); then
    [[ -x /opt/homebrew/bin/bash ]] || return 1
    # shellcheck disable=SC2329
    sdk() {
      /opt/homebrew/bin/bash -c '
        set +u
        source "$1"
        shift
        sdk "$@"
      ' bash "$SDKMAN_INIT" "$@"
    }
    return 0
  fi
  set +u
  # shellcheck disable=SC1090
  source "$SDKMAN_INIT"
  set -u
}

# SDKMAN reads $2 and other unset vars unconditionally. `sdk selfupdate` aborts
# with "$2: unbound variable" under `set -u` (which all bench-* scripts enable),
# so relax nounset around it. Requires source_sdkman first.
sdk_run() {
  set +u
  sdk "$@"
  local rc=$?
  set -u
  return "$rc"
}

# An SDK version's "line": major version plus vendor suffix, so 21-tem and 26-tem
# are distinct and bench-update's prune never removes the last JDK of a line.
# Decides what gets deleted, so it lives here and bench-test covers it.
sdk_line() { local v="$1" s=""; case "$v" in *-*) s="-${v##*-}";; esac; printf '%s%s' "${v%%.*}" "$s"; }

# No `sed -i`: the temp-file edit works under both BSD and GNU sed. `cat >`
# preserves perms and inode.
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
  ".tmux.conf"
  ".gitignore_global"
  ".commitTemplate.txt"
  ".ssh/config"
  ".config/zed/settings.json"
)

# Checklist lines of $1 absent from directory $2. Shared by install.sh's fonts
# step and bench-doctor so the two reports can't drift. minimal: non-recursive
# ls, matching bench-export's docs/fonts.txt (basenames), so subfolders are invisible.
# shellcheck disable=SC2012
missing_fonts() { comm -23 <(sort "$1") <(ls "$2" 2>/dev/null | sort); }

# docs/ snapshot parsers: each reads a snapshot file ($1) and emits one package
# per line (parse_sdk emits "name version"); the output feeds install.sh's
# replay_globals. Sourced from here so they are unit-testable (see bench-test).
parse_uv()    { awk 'NF && $1 !~ /^-/ { print $1 }' "$1"; }
parse_cargo() { awk '/^[^[:space:]]/ { print $1 }' "$1"; }
parse_pip()   { awk -F'==' '/==/ { print $1 }' "$1"; }
parse_sdk()   { awk 'NF == 2 { print $1, $2 }' "$1"; }
# Replay only gems carrying a user-installed version; skip Ruby's bundled gems
# (those show a lone `default:` version).
parse_gem()   { awk -F' *[()] *' 'NF > 1 && $2 !~ /^default:/ { print $1 }' "$1"; }
# Drop `npm` itself: reinstalling the package manager is a no-op.
parse_node()  { awk 'NF && $NF ~ /@/ { n=$NF; sub(/@[^@]*$/, "", n); if (n != "npm") print n }' "$1"; }

pip_managed_freeze() {
  /opt/homebrew/bin/python3 -c 'import importlib.metadata as m
rows = {(d.metadata["Name"], d.version) for d in m.distributions()
        if d.metadata["Name"] and d.read_text("RECORD") is not None}
for name, version in sorted(rows, key=lambda row: row[0].lower()):
    print(f"{name}=={version}")'
}

pip_managed_names() { pip_managed_freeze | sed 's/==.*//'; }
# `dockutil --list` TSV -> one absolute path per line. Field 2 is a file:// URL
# natively but a plain path for entries dockutil itself wrote, so both forms
# must parse or an export-after-replay yields an empty snapshot. %XX-decode
# only the URL form: a plain path may contain a literal %. A leading $HOME
# (bench-export normalizes it so snapshots replay for any user) expands to
# the current user's home.
parse_dock() {
  awk -F'\t' '$2 ~ /^(file:\/\/|\/|\$HOME)/ { print $2 }' "$1" \
    | perl -pe 's{^file://}{} and s/%([0-9A-Fa-f]{2})/chr hex $1/ge; s{/$}{}; s{^\$HOME}{$ENV{HOME}}'
}
# `mysides list` ("Name -> URL") -> "name<TAB>url", $HOME token expanded (see
# parse_dock). Finder built-ins (iCloud, AirDrop: non-file URLs) are dropped;
# mysides cannot re-add them anyway.
parse_sidebar() {
  awk -F' -> ' -v home="$HOME" \
    'NF == 2 && $2 ~ /^file:\/\// { sub(/\$HOME/, home, $2); print $1 "\t" $2 }' "$1"
}
# Live-state reads shared by install.sh (replay) and bench-doctor (drift) so
# the two sides can't diverge on tool quirks (mysides stderr, /dev/stdin feed).
current_dock()    { dockutil --list | parse_dock /dev/stdin; }
current_sidebar() { mysides list 2>/dev/null | parse_sidebar /dev/stdin; }

# Mutating replay cores, driven by install.sh.
# Callers own the ask and the file-specific messaging; the helpers refuse
# empty input themselves as the last belt before a wipe.
apply_dock() {
  # Refuse empty input here too (callers also guard): an empty here-string
  # still iterates once, so the wipe below would run and nothing re-adds.
  [[ -n "$1" ]] || { warn "dock: empty snapshot — left untouched"; return 1; }
  dockutil --no-restart --remove all >/dev/null
  while IFS= read -r item; do
    if [[ ! -e "$item" ]]; then
      warn "dock: $item not on disk — skipped (install the app, re-run)"
    elif dockutil --no-restart --add "$item" >/dev/null 2>&1; then
      ok "dock: ${item##*/}"
    else
      warn "dock: adding $item failed"
    fi
  done <<<"$1"
  killall Dock 2>/dev/null || true
}
apply_sidebar() {
  [[ -n "$1" ]] || { warn "sidebar: empty snapshot — left untouched"; return 1; }
  # Replace-then-replay: mysides removes by name, one entry per call, so
  # per-URL diffing would delete the wrong twin when two favorites share a
  # name (the snapshot ships two "Downloads").
  current_sidebar | cut -f1 | while IFS= read -r name; do
    [[ -n "$name" ]] || continue
    mysides remove "$name" >/dev/null 2>&1 || warn "sidebar: removing $name failed"
  done
  while IFS=$'\t' read -r name url; do
    if mysides add "$name" "$url" >/dev/null 2>&1; then
      ok "sidebar: $name"
    else
      warn "sidebar: adding $name ($url) failed"
    fi
  done <<<"$1"
}
# docs/repos.txt ("<target-rel-$HOME> <url>", # comments) -> "target url" lines.
parse_repos() { awk 'NF == 2 && $1 !~ /^#/ { print $1, $2 }' "$1"; }
# A remote URL reduced to host/path, so the ssh and https forms of one repo
# compare equal. The URL is a repo's identity when its checkout has moved.
repo_slug() {
  printf '%s' "$1" | sed -e 's|^git@|https://|' -e 's|^\(https://[^/]*\):|\1/|' \
                         -e 's|\.git$||' -e 's|^https://||'
}
# Existing clones are left untouched, never pulled: local work must not be
# touched by a replay.
clone_repos() {
  local target url output
  while read -r target url; do
    # repos.txt is a trust boundary (PR-able): keep targets under $HOME and
    # `--` stops a crafted URL from becoming a git option (--upload-pack runs).
    if [[ "$target" == /* || "$target" == *..* ]]; then
      warn "repo: refusing target outside \$HOME: $target"
    elif [[ -d "$HOME/$target/.git" ]]; then
      ok "repo: $target already cloned"
    # GIT_TERMINAL_PROMPT=0: without gh/glab credentials git would stop and ask
    # for a username mid-run. Fail fast into the warn instead.
    elif output=$(GIT_TERMINAL_PROMPT=0 git clone -q -- "$url" "$HOME/$target" 2>&1); then
      ok "repo: $target"
    else
      warn "repo: cloning $target failed — check gh/glab auth, re-run"
      [[ -n "$output" ]] && printf '%s\n' "$output" | tail -n 3 | indent
    fi
  done < <(parse_repos "$1")
}
apply_moom() {
  # Quit first: Moom rewrites its prefs on exit and would clobber the import.
  osascript -e 'quit app "Moom Classic"' 2>/dev/null || true
  if defaults import com.manytricks.Moom "$1"; then
    ok "Moom settings imported — relaunch Moom Classic"
  else
    warn "Moom import failed"
  fi
}
