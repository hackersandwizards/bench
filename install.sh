#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Add taps
while IFS= read -r tap; do
  [ -n "$tap" ] && brew tap "$tap"
done < "$SCRIPT_DIR/docs/brew-taps.txt"

# Install all brew packages
xargs brew install < "$SCRIPT_DIR/docs/brew-leaves.txt"

# Install Ghostty (cask)
brew install --cask ghostty

# Add init.zsh source line to ~/.zshrc if not already present (idempotent, non-destructive)
if ! grep -qF "$SCRIPT_DIR/init.zsh" ~/.zshrc 2>/dev/null; then
  echo "[ -f \"$SCRIPT_DIR/init.zsh\" ] && source \"$SCRIPT_DIR/init.zsh\"" >> ~/.zshrc
fi

# Set up Ghostty config — backup any existing non-symlink config before overwriting
mkdir -p ~/.config/ghostty
ghostty_target=~/.config/ghostty/config.ghostty
if [ -e "$ghostty_target" ] && [ ! -L "$ghostty_target" ]; then
  mv "$ghostty_target" "${ghostty_target}.backup-$(date +%s)"
fi
ln -sf "$SCRIPT_DIR/ghostty/config.ghostty" "$ghostty_target"

# Configure git delta — only set keys that are not already configured (respects existing user values)
gset() { git config --global --get "$1" >/dev/null 2>&1 || git config --global "$1" "$2"; }
gset core.pager delta
gset interactive.diffFilter 'delta --color-only'
gset delta.navigate true
gset delta.side-by-side true
gset delta.light true
gset merge.conflictstyle diff3
