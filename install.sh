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
step "Step 1/7: Install Homebrew packages from Brewfile"
if ! have brew; then
  warn "Homebrew not installed — install from https://brew.sh first"
elif ask "Run 'brew bundle' now?"; then
  brew bundle --file="$REPO_ROOT/Brewfile"
  ok "Brewfile installed"
else
  skip "Skipped Brewfile install"
fi

# ---------- 2. Stow symlinks ----------
step "Step 2/7: Symlink home/ via Stow"
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
step "Step 3/7: Personal git identity (~/.gitconfig.local)"
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
step "Step 4/7: Activate repo-local git hooks (gitleaks + shellcheck)"
current_hooks=$(git -C "$REPO_ROOT" config core.hooksPath 2>/dev/null || echo "")
if [[ "$current_hooks" == ".githooks" ]]; then
  ok "core.hooksPath already set to .githooks"
elif ask "Set core.hooksPath = .githooks for this repo?"; then
  git -C "$REPO_ROOT" config core.hooksPath .githooks
  ok "core.hooksPath set"
else
  skip "Skipped hook activation"
fi

# ---------- 5. Source init.zsh from ~/.zshrc ----------
step "Step 5/7: Source init.zsh from ~/.zshrc"
if grep -qF "$REPO_ROOT/init.zsh" "$HOME/.zshrc" 2>/dev/null; then
  ok "init.zsh already sourced in ~/.zshrc"
elif ask "Append source line to ~/.zshrc?"; then
  echo "[ -f \"$REPO_ROOT/init.zsh\" ] && source \"$REPO_ROOT/init.zsh\"" >> "$HOME/.zshrc"
  ok "Appended to ~/.zshrc"
else
  skip "Skipped ~/.zshrc append"
fi

# ---------- 6. Ghostty config ----------
step "Step 6/7: Ghostty config symlink"
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
step "Step 7/7: atuin history import"
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

# ---------- Final hints ----------
step "Optional next steps"
echo "  • Run './macos.sh' to apply ~45 macOS system defaults (keyboard, finder, dock, etc.)"
echo "  • Run 'bench-doctor' to verify the install"
echo "  • Run 'bench-export' to refresh Brewfile/docs/ snapshots"
echo "  • Create '$REPO_ROOT/secrets.zsh' for API keys (gitignored)"

step "Done"
echo "Open a new terminal or run 'exec zsh' to load the new config."
