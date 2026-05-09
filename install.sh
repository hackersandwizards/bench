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

# ---------- 1. Brewfile ----------
step "Step 1/10: Install Homebrew packages from Brewfile"
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
step "Step 2/10: Symlink home/ via Stow"
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
step "Step 3/10: Personal git identity (~/.gitconfig.local)"
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
step "Step 4/10: Activate repo-local git hooks (gitleaks + shellcheck)"
if [[ "$(hooks_path)" == ".githooks" ]]; then
  ok "core.hooksPath already set to .githooks"
elif ask "Set core.hooksPath = .githooks for this repo?"; then
  git -C "$REPO_ROOT" config core.hooksPath .githooks
  ok "core.hooksPath set"
else
  skip "Skipped hook activation"
fi

# ---------- 5. Source init.zsh from ~/.zshrc ----------
step "Step 5/10: Source init.zsh from ~/.zshrc"
if grep -qF "$REPO_ROOT/init.zsh" "$HOME/.zshrc" 2>/dev/null; then
  ok "init.zsh already sourced in ~/.zshrc"
elif ask "Append source line to ~/.zshrc?"; then
  echo "[ -f \"$REPO_ROOT/init.zsh\" ] && source \"$REPO_ROOT/init.zsh\"" >> "$HOME/.zshrc"
  ok "Appended to ~/.zshrc"
else
  skip "Skipped ~/.zshrc append"
fi

# ---------- 6. Ghostty config ----------
step "Step 6/10: Ghostty config symlink"
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
step "Step 7/10: atuin history import"
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
step "Step 8/10: Pre-warm antidote plugin bundles"
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
step "Step 9/10: Switch login shell to brew zsh"
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
step "Step 10/10: Enable Touch ID for sudo"
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
