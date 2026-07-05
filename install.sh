#!/usr/bin/env bash
# Interactive bootstrap for zsh-settings. Re-runnable, idempotent.
set -u

# shellcheck source-path=SCRIPTDIR/bin
# shellcheck source=bin/_lib.sh
. "$(dirname "$0")/bin/_lib.sh"
cd "$REPO_ROOT" || exit 1

# Ledger for the end-of-run recap: every warn() also lands here (see _lib.sh).
# Exported so child scripts' warns (macos.sh) reach it too.
if WARN_LOG=$(mktemp); then trap 'rm -f "$WARN_LOG"' EXIT; else WARN_LOG=/dev/null; fi
export WARN_LOG

ask() {
  local prompt="$1" default="${2:-Y}" reply hint
  if [[ "$default" == "Y" ]]; then hint="[Y/n]"; else hint="[y/N]"; fi
  # EOF (no TTY) declines: a piped run must never auto-confirm system changes.
  read -rp "$prompt $hint " reply || return 1
  reply="${reply:-$default}"
  [[ "$reply" =~ ^[Yy]$ ]]
}

# Self-numbering step headers — adding or removing a step never renumbers the
# rest. Grep the file via REPO_ROOT, not $0: after the cd above a relative $0
# no longer resolves. bench-test asserts every istep call sits at column 0.
STEP_TOTAL=$(grep -c '^istep ' "$REPO_ROOT/install.sh")
STEP_N=0
istep() { step "Step $((++STEP_N))/$STEP_TOTAL: $1"; }

backup() {
  local target="$1" bak
  [[ -e "$target" ]] || return 0
  [[ -L "$target" ]] && return 0
  bak="${target}.backup-$(date +%s)"
  mv "$target" "$bak"
  warn "backed up $target → $bak"
}

# Install each stdin line as a package: runs `"$@" <fields…>` per line, so
# single-token lines and multi-token `sdk` lines (name version) both work.
# `< /dev/null` keeps a package manager that reads stdin from draining the loop.
# On failure the captured output is shown — a fresh-machine install needs the
# reason (missing toolchain, native-extension build error), not a bare "failed".
replay_globals() {
  local label="$1"; shift
  local -a fields
  local output
  while read -r -a fields; do
    [[ ${#fields[@]} -gt 0 ]] || continue
    if output=$("$@" "${fields[@]}" < /dev/null 2>&1); then
      ok "$label: ${fields[*]}"
    else
      warn "$label: ${fields[*]} failed"
      [[ -n "$output" ]] && printf '%s\n' "$output" | tail -n 8 | indent
    fi
  done
}

# parse_* docs/ snapshot parsers live in _lib.sh (sourced above) so they are
# sourceable and unit-tested by bench-test; replay_ecosystem calls them by name.

#   replay_ecosystem <tool> <docs-basename> <parser-fn> <install-cmd…>
replay_ecosystem() {
  local tool="$1" file="$2" parser="$3"; shift 3
  local doc="$REPO_ROOT/docs/$file"
  if have "$tool" && [[ -s "$doc" ]]; then
    "$parser" "$doc" | replay_globals "$tool" "$@"
  else
    skip "$tool globals — $tool missing or docs/$file empty"
  fi
}

# ---------- Brewfile ----------
istep "Install Homebrew packages from Brewfile"
if ! have brew; then
  if ask "Homebrew not installed. Install it now?"; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
    ok "Homebrew installed"
  else
    skip "Skipped — Homebrew required for remaining steps"
  fi
fi
# HOMEBREW_REQUIRE_TAP_TRUST=1 (exports.zsh; default in Homebrew 6.0/5.2) makes
# brew warn on untrusted taps, so trust them even when bundle is skipped or
# declined. Parsed from the Brewfile's own `tap` lines, the single source of truth.
# brew trust is idempotent and works before the tap is tapped.
if have brew; then
  awk -F'"' '/^tap /{print $2}' "$REPO_ROOT/Brewfile" | while read -r tap; do
    [[ -n "$tap" ]] || continue
    if brew trust --tap "$tap" >/dev/null 2>&1; then
      ok "Trusted tap: $tap"
    else
      warn "Could not trust tap: $tap"
    fi
  done
fi
if have brew && ! brew_bottles_supported; then
  brew_unsupported_notice
  skip "Skipped Brewfile install — bottles unavailable until Homebrew ships support"
elif have brew && ask "Run 'brew bundle' now?"; then
  # Cask pkg installers call sudo over and over, and macOS forgets the
  # credential after 5 idle minutes, so a long bundle re-prompts constantly.
  # Ask once, then refresh the timestamp in the background until this
  # script exits (sudo -n never prompts, and the loop dies with the script).
  if sudo -v; then
    ( while kill -0 $$ 2>/dev/null; do sudo -n -v 2>/dev/null; sleep 50; done ) &
  fi
  # static.adguard.com drops TLS handshakes on some routes (RU CDN edge), so
  # the adguard cask download hangs. Pre-seed brew's cache from AdGuard's
  # adtidy.org mirror. Same file, and brew still verifies the cask's sha256.
  # Download lands in a temp file so a Ctrl-C can't poison the cache. Only
  # install needs this: `brew upgrade` skips auto_updates casks like adguard.
  # minimal: one hardcoded cask, generalize to a mirror map if a second cask
  # hits this, drop when the route heals.
  if grep -q '^cask "adguard"' "$REPO_ROOT/Brewfile" \
      && adguard_cache=$(brew --cache --cask adguard 2>/dev/null) \
      && [[ "$adguard_cache" == *--* && ! -f "$adguard_cache" ]]; then
    mkdir -p "${adguard_cache%/*}"
    if curl -fLo "$adguard_cache.mirror" --connect-timeout 5 --retry 2 \
        --speed-limit 10240 --speed-time 30 \
        "https://static.adtidy.org/mac/release/${adguard_cache##*--}" \
        && mv "$adguard_cache.mirror" "$adguard_cache"; then
      ok "Pre-seeded adguard download from adtidy.org mirror"
    else
      rm -f "$adguard_cache.mirror"
      warn "adguard mirror download failed, brew bundle will retry the primary CDN"
    fi
  fi
  brew bundle --file="$REPO_ROOT/Brewfile"
  ok "Brewfile installed"
else
  skip "Skipped Brewfile install"
fi

# ---------- Stow symlinks ----------
istep "Symlink home/ via Stow"
if ! have stow; then
  warn "stow not installed — run the Brewfile step first or 'brew install stow'"
elif ask "Symlink dotfiles in home/ to \$HOME via stow?"; then
  for rel in "${STOW_FILES[@]}"; do
    backup "$HOME/$rel"
  done
  mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
  mkdir -p "$HOME/.ssh/control" && chmod 700 "$HOME/.ssh/control"
  stow --dir="$REPO_ROOT" --target="$HOME" --restow home
  ok "Stow symlinks applied"
else
  skip "Skipped stow"
fi

# ---------- Personal git identity ----------
istep "Personal git identity (~/.gitconfig.local)"
if [[ -f "$HOME/.gitconfig.local" ]]; then
  ok "$HOME/.gitconfig.local already exists, skipping"
elif ask "Create ~/.gitconfig.local with [user] block?"; then
  read -rp "  Full name: " git_name
  read -rp "  Email: " git_email
  cat > "$HOME/.gitconfig.local" <<EOF
[user]
	name = $git_name
	email = $git_email
EOF
  ok "Created ~/.gitconfig.local"
else
  skip "Skipped — you'll need ~/.gitconfig.local for [user] block to work"
fi

# ---------- GitHub / GitLab CLI logins ----------
# home/.gitconfig routes git credentials through gh and glab, so an
# unauthenticated CLI breaks every HTTPS clone/push. Both logins are
# interactive (browser or token paste).
istep "GitHub and GitLab CLI logins (gh / glab)"
for cli in gh glab; do
  if ! have "$cli"; then
    warn "$cli not installed — run the Brewfile step first, then '$cli auth login'"
  elif "$cli" auth status >/dev/null 2>&1; then
    ok "$cli already authenticated"
  elif ask "Run '$cli auth login' now?"; then
    if "$cli" auth login; then
      ok "$cli authenticated"
    else
      warn "$cli auth login failed — run '$cli auth login' later"
    fi
  else
    skip "Skipped — run '$cli auth login' later"
  fi
done

# ---------- Repo-local git hooks ----------
istep "Activate repo-local git hooks (gitleaks + shellcheck)"
if [[ "$(hooks_path)" == ".githooks" ]]; then
  ok "core.hooksPath already set to .githooks"
elif ask "Set core.hooksPath = .githooks for this repo?"; then
  git -C "$REPO_ROOT" config core.hooksPath .githooks
  ok "core.hooksPath set"
else
  skip "Skipped hook activation"
fi

# ---------- Source init.zsh from ~/.zshrc ----------
istep "Source init.zsh from ~/.zshrc"
if grep -qF "$REPO_ROOT/init.zsh" "$HOME/.zshrc" 2>/dev/null; then
  ok "init.zsh already sourced in ~/.zshrc"
elif ask "Append source line to ~/.zshrc?"; then
  echo "[ -f \"$REPO_ROOT/init.zsh\" ] && source \"$REPO_ROOT/init.zsh\"" >> "$HOME/.zshrc"
  ok "Appended to ~/.zshrc"
else
  skip "Skipped ~/.zshrc append"
fi

# ---------- Ghostty config ----------
istep "Ghostty config symlink"
mkdir -p "$HOME/.config/ghostty"
ghostty_target="$HOME/.config/ghostty/config.ghostty"
if [[ -L "$ghostty_target" ]]; then
  ok "Ghostty config already symlinked"
elif [[ ! -d "/Applications/Ghostty.app" ]]; then
  warn "Ghostty.app not found in /Applications — install it first (https://ghostty.org), then re-run"
elif ask "Symlink Ghostty config?"; then
  backup "$ghostty_target"
  ln -sf "$REPO_ROOT/ghostty/config.ghostty" "$ghostty_target"
  ok "Ghostty config symlinked"
else
  skip "Skipped Ghostty"
fi

# ---------- skhd hotkey daemon ----------
# Wires up the macos/ hotkey scripts (Ghostty grid, IDEA layout reset).
istep "skhd hotkeys (symlink + service)"
skhd_target="$HOME/.config/skhd/skhdrc"
skhd_plist="$HOME/Library/LaunchAgents/com.koekeishiya.skhd.plist"
if ! have skhd; then
  warn "skhd not installed — run the Brewfile step first"
elif [[ "$(readlink "$skhd_target" 2>/dev/null)" == "$REPO_ROOT/skhd/skhdrc" ]] && pgrep -xq skhd; then
  ok "skhd already linked and running"
elif ask "Symlink skhdrc and start the skhd service?"; then
  mkdir -p "$HOME/.config/skhd"
  backup "$skhd_target"
  ln -sf "$REPO_ROOT/skhd/skhdrc" "$skhd_target"
  # --restart-service aborts when the LaunchAgent was never installed;
  # --start-service installs it when missing — branch on the plist, not pgrep.
  if [[ -f "$skhd_plist" ]]; then skhd_cmd=--restart-service; else skhd_cmd=--start-service; fi
  if skhd "$skhd_cmd"; then
    ok "skhd linked and service started"
    printf '%s\n' "First hotkey use prompts for Accessibility permission (System Settings → Privacy & Security → Accessibility)." | indent
  else
    warn "skhd $skhd_cmd failed — check /tmp/skhd_$USER.err.log, then re-run"
  fi
else
  skip "Skipped skhd"
fi

# ---------- Fonts ----------
# fonts/ holds only fonts with verified redistribution rights (repo is public);
# the caskable free families come from the Brewfile. docs/fonts.txt inventories
# the old machine's full ~/Library/Fonts — commercial/brand fonts listed there
# must be restored manually from a backup, never committed here.
istep "Install fonts (fonts/ + checklist from docs/fonts.txt)"
fonts_doc="$REPO_ROOT/docs/fonts.txt"
if ask "Copy fonts/ into ~/Library/Fonts?"; then
  mkdir -p "$HOME/Library/Fonts"
  # minimal: -n never overwrites a user's existing copy — repo fonts are static,
  # so no backup dance like the config symlinks need.
  if cp -n "$REPO_ROOT"/fonts/* "$HOME/Library/Fonts/"; then
    ok "fonts/ installed (existing files kept)"
  else
    warn "fonts/ copy failed (see error above)"
  fi
else
  skip "Skipped fonts"
fi
# Report-only checklist: runs even when the copy is declined — on a re-run the
# missing-fonts report is the step's real value.
if [[ -s "$fonts_doc" ]]; then
  missing=$(missing_fonts "$fonts_doc" "$HOME/Library/Fonts")
  if [[ -n "$missing" ]]; then
    warn "fonts from docs/fonts.txt not installed — restore manually from a backup; first few:"
    printf '%s\n' "$missing" | head -n 5 | indent
  else
    ok "all fonts from docs/fonts.txt present"
  fi
else
  skip "docs/fonts.txt missing/empty — run bench-export on the old machine"
fi

# ---------- atuin history migration ----------
istep "atuin history import"
if ! have atuin; then
  warn "atuin not installed — run the Brewfile step first"
elif [[ -f "$HOME/.local/share/atuin/history.db" ]]; then
  ok "atuin database already exists — skipping import"
elif ask "Import existing ~/.zsh_history into atuin?"; then
  atuin import auto
  ok "atuin history imported"
else
  skip "Skipped — run 'atuin import auto' manually later"
fi

# ---------- Antidote pre-warm ----------
# Generate plugins.zsh + plugins-post.zsh ahead of first interactive shell so
# the user doesn't pay the cold-cache cost (~5–10s of git clones + bundle
# compile) on first login. Mirrors init.zsh:_antidote_bundle exactly.
# bench-update invalidates these caches by deleting them; this is the inverse.
istep "Pre-warm antidote plugin bundles"
if [[ ! -f "$ANTIDOTE_SH" ]]; then
  warn "antidote not at $ANTIDOTE_SH — run the Brewfile step first"
elif [[ -s "$REPO_ROOT/plugins.zsh" && -s "$REPO_ROOT/plugins-post.zsh" \
        && "$REPO_ROOT/plugins.zsh" -nt "$REPO_ROOT/plugins.txt" \
        && "$REPO_ROOT/plugins-post.zsh" -nt "$REPO_ROOT/plugins-post.txt" ]]; then
  ok "Antidote bundles already cached and up to date"
elif ask "Pre-warm antidote bundles now? (avoids slow first shell start)"; then
  zsh -c "source '$ANTIDOTE_SH'
          antidote bundle < '$REPO_ROOT/plugins.txt' > '$REPO_ROOT/plugins.zsh'
          antidote bundle < '$REPO_ROOT/plugins-post.txt' > '$REPO_ROOT/plugins-post.zsh'"
  ok "Antidote bundles pre-warmed"
else
  skip "Skipped antidote pre-warm"
fi

# ---------- chsh to brew zsh ----------
# Apple ships zsh in /bin/zsh; brew ships its own at /opt/homebrew/bin/zsh.
# Both usually match major version, but switching ensures future zsh updates
# land via brew on the user's cadence rather than tied to macOS releases.
istep "Switch login shell to brew zsh"
BREW_ZSH=/opt/homebrew/bin/zsh
if [[ ! -x "$BREW_ZSH" ]]; then
  warn "$BREW_ZSH not found — run the Brewfile step first"
elif [[ "$SHELL" == "$BREW_ZSH" ]]; then
  ok "Login shell already $BREW_ZSH"
elif ask "Switch login shell from $SHELL to $BREW_ZSH?"; then
  if ! grep -qxF "$BREW_ZSH" /etc/shells; then
    echo "$BREW_ZSH" | sudo tee -a /etc/shells > /dev/null
  fi
  chsh -s "$BREW_ZSH"
  ok "Login shell changed — open a new terminal to verify"
else
  skip "Skipped chsh"
fi

# ---------- Touch ID for sudo ----------
istep "Enable Touch ID for sudo"
if [[ -f /etc/pam.d/sudo_local ]] && grep -qE '^auth\s+sufficient\s+pam_tid\.so' /etc/pam.d/sudo_local; then
  ok "Touch ID for sudo already enabled"
elif [[ ! -f /etc/pam.d/sudo_local.template ]]; then
  warn "/etc/pam.d/sudo_local.template missing — needs Sonoma+ (you're on macOS Tahoe so this should exist)"
elif ask "Enable Touch ID for sudo? (uses /etc/pam.d/sudo_local — survives system updates)"; then
  sudo cp /etc/pam.d/sudo_local.template /etc/pam.d/sudo_local
  sudo sed -i '' 's/^#auth/auth/' /etc/pam.d/sudo_local
  ok "Touch ID enabled — your next 'sudo' will prompt for fingerprint"
else
  skip "Skipped Touch ID for sudo"
fi

# ---------- Language-ecosystem global CLIs ----------
# Replay the package snapshots bench-export writes to docs/ (per-package
# failure handling lives in replay_globals above).
istep "Install language-ecosystem global CLIs (uv, npm, bun, cargo, gem, pip)"
if ask "Install uv / npm / bun / cargo / gem / pip global CLIs from docs/ snapshots?"; then
  # brew ruby and python are keg-only, so their gem/pip aren't on PATH until
  # exports.zsh runs — which it hasn't on a fresh machine. Without this the replay
  # would use /usr/bin/gem (system ruby, wrong ABI) and never find `pip` (brew
  # links only pip3). Mirror exports.zsh so the replay uses brew's gem and pip.
  # python3 is brew's alias for the current default python — version-agnostic, so
  # it tracks upgrades instead of pinning python@3.14.
  export PATH="/opt/homebrew/opt/ruby/bin:/opt/homebrew/opt/python3/libexec/bin:$PATH"
  # The six managers come from brew bundle, not installed here. The replay only
  # needs them on PATH: gem/pip via the keg-only fix, the rest linked in bin.
  replay_ecosystem uv    uv.txt    parse_uv    uv tool install
  replay_ecosystem npm   npms.txt  parse_node  npm install -g
  replay_ecosystem bun   buns.txt  parse_node  bun add -g
  replay_ecosystem cargo cargo.txt parse_cargo cargo install
  replay_ecosystem gem   gems.txt  parse_gem   gem install
  replay_ecosystem pip   pip.txt   parse_pip   pip install
else
  skip "Skipped language-ecosystem globals"
fi

# ---------- SDKMAN + JVM-ecosystem SDKs ----------
# SDKMAN_INIT and source_sdkman live in _lib.sh — `sdk` is a shell function, not
# a binary, so its init must be sourced before `sdk install` works.
istep "Install SDKMAN and JVM-ecosystem SDKs"
if [[ ! -s "$SDKMAN_INIT" ]] && ask "SDKMAN not installed. Install it now?"; then
  curl -fsSL "https://get.sdkman.io" | bash
fi
sdks_doc="$REPO_ROOT/docs/sdks.txt"
if [[ ! -s "$SDKMAN_INIT" ]]; then
  skip "Skipped SDKMAN"
else
  # Auto-answer every prompt: install/upgrade always set the newest as default
  # and never ask. Keeps interactive `sdk` and unattended `bench-update` silent.
  sdkman_set_config sdkman_auto_answer true && ok "SDKMAN auto-answer enabled"
  if [[ -s "$sdks_doc" ]] && ask "Install JVM SDKs from docs/sdks.txt?"; then
    source_sdkman
    # sdk_run, not raw sdk: the `sdk` function reads $2 and other vars unset under
    # install.sh's `set -u` (see _lib.sh). `sdk install <name> <ver>` clears the
    # $2 read, but the install path goes deeper — sdk_run relaxes nounset for the
    # whole call, matching how bench-update and bench-export invoke sdk.
    parse_sdk "$sdks_doc" | replay_globals sdk sdk_run install
  else
    skip "Skipped JVM SDK install"
  fi
fi

# ---------- Safari favorites bar ----------
# Merge-only: prepends snapshot entries missing from the favorites bar, never
# deletes or reorders existing ones. bin/safari-favorites owns the guarantees
# (Safari-quit re-check, Full Disk Access message, backup, atomic write).
istep "Merge Safari favorites from docs/safari-favorites.txt"
fav_doc="$REPO_ROOT/docs/safari-favorites.txt"
if [[ ! -s "$fav_doc" ]]; then
  skip "docs/safari-favorites.txt missing/empty — run bench-export on the old machine"
# Read-only probe before the prompts: bin/safari-favorites owns the diagnosis
# (no Full Disk Access, Safari never launched), so its stderr is the message.
elif ! "$REPO_ROOT/bin/safari-favorites" missing "$fav_doc" >/dev/null; then
  warn "Safari favorites: cannot read Safari bookmarks (see message above) — fix and re-run install.sh"
elif ask "Prepend missing snapshot favorites into Safari's favorites bar?"; then
  if pgrep -xq Safari && ask "Safari must be quit for the write to stick. Quit it now?"; then
    osascript -e 'quit app "Safari"'
    for _ in {1..10}; do pgrep -xq Safari || break; sleep 1; done
  fi
  if "$REPO_ROOT/bin/safari-favorites" merge "$fav_doc"; then
    ok "Safari favorites merged"
  else
    warn "Safari favorites merge failed (see message above) — fix and re-run install.sh"
  fi
else
  skip "Skipped Safari favorites"
fi

# ---------- Dock layout ----------
# Replace, don't merge: a fresh machine's Dock is all Apple defaults, and an
# append-only replay would keep them. The wipe is why this has its own ask.
istep "Apply Dock layout from docs/dock.txt"
dock_doc="$REPO_ROOT/docs/dock.txt"
if ! have dockutil; then
  warn "dockutil not installed — run the Brewfile step first"
elif [[ ! -s "$dock_doc" ]]; then
  skip "docs/dock.txt missing/empty — run bench-export on the old machine"
elif ask "Replace the current Dock with the docs/dock.txt layout?"; then
  dockutil --no-restart --remove all >/dev/null
  # Process substitution, not a pipe: the while loop stays in the parent shell.
  while IFS= read -r item; do
    if [[ ! -e "$item" ]]; then
      warn "dock: $item not on disk — skipped (install the app, re-run install.sh)"
    elif dockutil --no-restart --add "$item" >/dev/null 2>&1; then
      ok "dock: ${item##*/}"
    else
      warn "dock: adding $item failed"
    fi
  done < <(parse_dock "$dock_doc")
  killall Dock 2>/dev/null || true
  ok "Dock layout applied"
else
  skip "Skipped Dock layout"
fi

# ---------- Finder sidebar ----------
# Merge-only, like Safari favorites: add snapshot entries missing from the
# sidebar, never remove or reorder existing ones. Finder built-ins (iCloud,
# AirDrop, tags) never appear here — parse_sidebar keeps file:// entries only.
istep "Merge Finder sidebar favorites from docs/finder-sidebar.txt"
sidebar_doc="$REPO_ROOT/docs/finder-sidebar.txt"
if ! have mysides; then
  warn "mysides not installed — run the Brewfile step first"
elif [[ ! -s "$sidebar_doc" ]]; then
  skip "docs/finder-sidebar.txt missing/empty — run bench-export on the old machine"
elif ask "Add missing Finder sidebar favorites from the snapshot?"; then
  sidebar_current="$(mysides list 2>/dev/null || true)"
  while IFS=$'\t' read -r name url; do
    if grep -qF "$url" <<<"$sidebar_current"; then
      ok "sidebar: $name already present"
    elif mysides add "$name" "$url" >/dev/null 2>&1; then
      ok "sidebar: $name added"
    else
      warn "sidebar: adding $name ($url) failed"
    fi
  done < <(parse_sidebar "$sidebar_doc")
else
  skip "Skipped Finder sidebar"
fi

# ---------- macOS system defaults ----------
# Wallpaper and the trackpad/keyboard/Finder/Dock defaults all live in
# macos.sh. Offering it as a real step (not a closing hint) is what gets it
# run on a fresh machine — "optional next steps" were skipped in practice.
istep "Apply macOS system defaults (macos.sh)"
if ask "Run ./macos.sh now? (keyboard, trackpad, Finder, Dock, wallpaper)"; then
  if "$REPO_ROOT/macos.sh"; then
    ok "macos.sh applied — log out/restart for trackpad + keyboard changes"
  else
    warn "macos.sh exited with an error partway — re-run './macos.sh'"
  fi
else
  skip "Skipped — run './macos.sh' anytime later"
fi

# ---------- API keys in secrets.zsh ----------
# Prompt for every key the toolchain expects and that secrets.zsh is missing.
# exports.zsh sources secrets.zsh, so the keys are live in the next shell.
# Fathom: fathom.video account settings. Qonto: app.qonto.com API settings.
istep "API keys in secrets.zsh"
secrets_file="$REPO_ROOT/secrets.zsh"
for key in FATHOM_API_KEY QONTO_API_KEY QONTO_ORGANIZATION_ID QONTO_THIRDPARTY_HOST; do
  if grep -q "^export $key=" "$secrets_file" 2>/dev/null; then
    ok "$key already in secrets.zsh"
  elif ask "Set $key in secrets.zsh now?"; then
    read -rsp "  $key (input hidden): " secret_val; echo
    if [[ -n "$secret_val" ]]; then
      printf 'export %s="%s"\n' "$key" "$secret_val" >> "$secrets_file"
      ok "$key written to secrets.zsh"
    else
      skip "Empty input — add 'export $key=...' to secrets.zsh later"
    fi
  else
    skip "Skipped — add 'export $key=...' to secrets.zsh later"
  fi
done

# ---------- Secure secrets.zsh ----------
# Why 600: an unprivileged process could otherwise slurp live API keys.
if [[ -f "$REPO_ROOT/secrets.zsh" ]]; then
  chmod 600 "$REPO_ROOT/secrets.zsh"
  ok "secrets.zsh chmod 600"
fi

# ---------- Final hints ----------
step "Optional next steps"
echo "  • Run 'bench-doctor' to verify the install"
echo "  • Run 'bench-export' to refresh Brewfile/docs/ snapshots"
echo "  • Create '$REPO_ROOT/secrets.zsh' for API keys (auto-chmod 600 on next install run)"

if [[ -s "$WARN_LOG" ]]; then
  step "Recap: $(grep -c . "$WARN_LOG") warning(s) need attention"
  indent < "$WARN_LOG"
fi

step "Done"
echo "Open a new terminal or run 'exec zsh' to load the new config."
