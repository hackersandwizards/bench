#!/usr/bin/env bash
# Interactive bootstrap for zsh-settings. Re-runnable, idempotent.
# Each step is opt-in via a Y/n prompt.
set -u

# shellcheck source-path=SCRIPTDIR/bin
# shellcheck source=bin/_lib.sh
. "$(dirname "$0")/bin/_lib.sh"
cd "$REPO_ROOT" || exit 1

ask() {
  local prompt="$1" default="${2:-Y}" reply hint
  if [[ "$default" == "Y" ]]; then hint="[Y/n]"; else hint="[y/N]"; fi
  read -rp "$prompt $hint " reply
  reply="${reply:-$default}"
  [[ "$reply" =~ ^[Yy]$ ]]
}

backup() {
  local target="$1" bak
  [[ -e "$target" ]] || return 0
  [[ -L "$target" ]] && return 0
  bak="${target}.backup-$(date +%s)"
  mv "$target" "$bak"
  warn "backed up $target → $bak"
}

# Install each stdin line as a package: runs `"$@" <line fields…>` per line, so
# single-token lines (uv/npm/bun/cargo) and multi-token lines (sdk: name version)
# both work. Idempotent — re-running skips already-installed packages.
# `< /dev/null` stops a package manager that reads stdin from draining the loop.
replay_globals() {
  local label="$1"; shift
  local -a fields
  while read -r -a fields; do
    [[ ${#fields[@]} -gt 0 ]] || continue
    if "$@" "${fields[@]}" < /dev/null > /dev/null 2>&1; then
      ok "$label: ${fields[*]}"
    else
      warn "$label: ${fields[*]} failed"
    fi
  done
}

# Extract package names from an `npm`/`bun` global-list snapshot: last field of
# each entry, keep versioned lines, strip the trailing @version. `npm` itself is
# dropped — re-installing the package manager is a no-op.
parse_node_globals() {
  awk 'NF { print $NF }' "$1" | grep '@' | sed -E 's/@[^@]*$//' | grep -vx npm
}

# ---------- 1. Brewfile ----------
step "Step 1/12: Install Homebrew packages from Brewfile"
if ! have brew; then
  if ask "Homebrew not installed. Install it now?"; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
    ok "Homebrew installed"
  else
    skip "Skipped — Homebrew required for remaining steps"
  fi
fi
if have brew && ask "Run 'brew bundle' now?"; then
  brew bundle --file="$REPO_ROOT/Brewfile"
  ok "Brewfile installed"
else
  skip "Skipped Brewfile install"
fi

# ---------- 2. Stow symlinks ----------
step "Step 2/12: Symlink home/ via Stow"
if ! have stow; then
  warn "stow not installed — run step 1 first or 'brew install stow'"
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

# ---------- 3. Personal git identity ----------
step "Step 3/12: Personal git identity (~/.gitconfig.local)"
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

# ---------- 4. Repo-local git hooks ----------
step "Step 4/12: Activate repo-local git hooks (gitleaks + shellcheck)"
if [[ "$(hooks_path)" == ".githooks" ]]; then
  ok "core.hooksPath already set to .githooks"
elif ask "Set core.hooksPath = .githooks for this repo?"; then
  git -C "$REPO_ROOT" config core.hooksPath .githooks
  ok "core.hooksPath set"
else
  skip "Skipped hook activation"
fi

# ---------- 5. Source init.zsh from ~/.zshrc ----------
step "Step 5/12: Source init.zsh from ~/.zshrc"
if grep -qF "$REPO_ROOT/init.zsh" "$HOME/.zshrc" 2>/dev/null; then
  ok "init.zsh already sourced in ~/.zshrc"
elif ask "Append source line to ~/.zshrc?"; then
  echo "[ -f \"$REPO_ROOT/init.zsh\" ] && source \"$REPO_ROOT/init.zsh\"" >> "$HOME/.zshrc"
  ok "Appended to ~/.zshrc"
else
  skip "Skipped ~/.zshrc append"
fi

# ---------- 6. Ghostty config ----------
step "Step 6/12: Ghostty config symlink"
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

# ---------- 7. atuin history migration ----------
step "Step 7/12: atuin history import"
if ! have atuin; then
  warn "atuin not installed — run step 1 (Brewfile) first"
elif [[ -f "$HOME/.local/share/atuin/history.db" ]]; then
  ok "atuin database already exists — skipping import"
elif ask "Import existing ~/.zsh_history into atuin?"; then
  atuin import auto
  ok "atuin history imported"
else
  skip "Skipped — run 'atuin import auto' manually later"
fi

# ---------- 8. Antidote pre-warm ----------
# Generate plugins.zsh + plugins-post.zsh ahead of first interactive shell so
# the user doesn't pay the cold-cache cost (~5–10s of git clones + bundle
# compile) on first login. Mirrors init.zsh:_antidote_bundle exactly.
# bench-update invalidates these caches by deleting them; this is the inverse.
step "Step 8/12: Pre-warm antidote plugin bundles"
if [[ ! -f "$ANTIDOTE_SH" ]]; then
  warn "antidote not at $ANTIDOTE_SH — run step 1 (Brewfile) first"
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

# ---------- 9. chsh to brew zsh ----------
# Apple ships zsh in /bin/zsh; brew ships its own at /opt/homebrew/bin/zsh.
# Both usually match major version, but switching ensures future zsh updates
# land via brew on the user's cadence rather than tied to macOS releases.
step "Step 9/12: Switch login shell to brew zsh"
BREW_ZSH=/opt/homebrew/bin/zsh
if [[ ! -x "$BREW_ZSH" ]]; then
  warn "$BREW_ZSH not found — run step 1 (Brewfile) first"
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

# ---------- 10. Touch ID for sudo ----------
step "Step 10/12: Enable Touch ID for sudo"
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

# ---------- 11. Language-ecosystem global CLIs ----------
# Replay the package snapshots bench-export writes to docs/. The package
# managers skip anything already installed, so re-running is safe.
step "Step 11/12: Install language-ecosystem global CLIs (uv, npm, bun, cargo, gem, pip)"
if ask "Install uv / npm / bun / cargo / gem / pip global CLIs from docs/ snapshots?"; then
  uv_doc="$REPO_ROOT/docs/uv.txt"
  if have uv && [[ -s "$uv_doc" ]]; then
    awk 'NF && $1 !~ /^-/ { print $1 }' "$uv_doc" \
      | replay_globals uv uv tool install
  else
    skip "uv globals — uv missing or docs/uv.txt empty"
  fi

  npm_doc="$REPO_ROOT/docs/npms.txt"
  if have npm && [[ -s "$npm_doc" ]]; then
    parse_node_globals "$npm_doc" | replay_globals npm npm install -g
  else
    skip "npm globals — npm missing or docs/npms.txt empty"
  fi

  bun_doc="$REPO_ROOT/docs/buns.txt"
  if have bun && [[ -s "$bun_doc" ]]; then
    parse_node_globals "$bun_doc" | replay_globals bun bun add -g
  else
    skip "bun globals — bun missing or docs/buns.txt empty"
  fi

  cargo_doc="$REPO_ROOT/docs/cargo.txt"
  if have cargo && [[ -s "$cargo_doc" ]]; then
    awk '/^[^[:space:]]/ { print $1 }' "$cargo_doc" \
      | replay_globals cargo cargo install
  else
    skip "cargo globals — cargo missing or docs/cargo.txt empty"
  fi

  gem_doc="$REPO_ROOT/docs/gems.txt"
  if have gem && [[ -s "$gem_doc" ]]; then
    # Skip Ruby's bundled gems (a lone `default:` version) — replay only gems
    # carrying a user-installed version.
    awk -F' *[()] *' 'NF > 1 && $2 !~ /^default:/ { print $1 }' "$gem_doc" \
      | replay_globals gem gem install
  else
    skip "gem globals — gem missing or docs/gems.txt empty"
  fi

  pip_doc="$REPO_ROOT/docs/pip.txt"
  if have pip && [[ -s "$pip_doc" ]]; then
    awk -F'==' '/==/ { print $1 }' "$pip_doc" | replay_globals pip pip install
  else
    skip "pip globals — pip missing or docs/pip.txt empty"
  fi
else
  skip "Skipped language-ecosystem globals"
fi

# ---------- 12. SDKMAN + JVM-ecosystem SDKs ----------
# SDKMAN_INIT and source_sdkman live in _lib.sh — `sdk` is a shell function, not
# a binary, so its init must be sourced before `sdk install` works.
step "Step 12/12: Install SDKMAN and JVM-ecosystem SDKs"
if [[ ! -s "$SDKMAN_INIT" ]] && ask "SDKMAN not installed. Install it now?"; then
  curl -s "https://get.sdkman.io" | bash
fi
sdks_doc="$REPO_ROOT/docs/sdks.txt"
if [[ ! -s "$SDKMAN_INIT" ]]; then
  skip "Skipped SDKMAN"
elif [[ -s "$sdks_doc" ]] && ask "Install JVM SDKs from docs/sdks.txt?"; then
  source_sdkman
  awk 'NF == 2 { print $1, $2 }' "$sdks_doc" | replay_globals sdk sdk install
else
  skip "Skipped JVM SDK install"
fi

# ---------- Secure secrets.zsh ----------
# Why 600: an unprivileged process could otherwise slurp live API keys.
if [[ -f "$REPO_ROOT/secrets.zsh" ]]; then
  chmod 600 "$REPO_ROOT/secrets.zsh"
  ok "secrets.zsh chmod 600"
fi

# ---------- Final hints ----------
step "Optional next steps"
echo "  • Run './macos.sh' to apply ~45 macOS system defaults (keyboard, finder, dock, etc.)"
echo "  • Run 'bench-doctor' to verify the install"
echo "  • Run 'bench-export' to refresh Brewfile/docs/ snapshots"
echo "  • Create '$REPO_ROOT/secrets.zsh' for API keys (auto-chmod 600 on next install run)"

step "Done"
echo "Open a new terminal or run 'exec zsh' to load the new config."
