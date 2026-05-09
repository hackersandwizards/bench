#!/usr/bin/env bash
# macOS system defaults — opt-in. Run manually: ./macos.sh
# Re-runnable. Each `defaults write` is idempotent.
# Curated subset of mathiasbynens/dotfiles/.macos for macOS Tahoe (26).

set -u

# shellcheck source-path=SCRIPTDIR/bin
# shellcheck source=bin/_lib.sh
. "$(dirname "$0")/bin/_lib.sh"

step "Closing System Settings to avoid override conflicts"
osascript -e 'tell application "System Settings" to quit' 2>/dev/null || true

# ============================================================================
# Keyboard
# ============================================================================
defaults write NSGlobalDomain KeyRepeat -int 1
defaults write NSGlobalDomain InitialKeyRepeat -int 10
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

# ============================================================================
# Trackpad
# ============================================================================
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true

# ============================================================================
# Finder
# ============================================================================
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder ShowStatusBar -bool false
defaults write com.apple.finder ShowPathbar -bool false
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
defaults write com.apple.finder _FXSortFoldersFirst -bool true
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
defaults write com.apple.finder WarnOnEmptyTrash -bool false
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool false
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool false
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool false
defaults write com.apple.finder ShowMountedServersOnDesktop -bool false

# ============================================================================
# .DS_Store on network shares and USB drives
# (local disks have no official flag — the cleanup alias sweeps them after.)
# ============================================================================
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# ============================================================================
# Screenshots → ~/Documents/Screenshots, PNG, with shadow
# ============================================================================
mkdir -p "$HOME/Documents/Screenshots"
defaults write com.apple.screencapture location -string "$HOME/Documents/Screenshots"
defaults write com.apple.screencapture type -string "png"
defaults write com.apple.screencapture disable-shadow -bool false

# ============================================================================
# Security
# ============================================================================
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0
defaults write com.apple.LaunchServices LSQuarantine -bool false

# ============================================================================
# Software Updates — fully automatic
# ============================================================================
defaults write com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true
defaults write com.apple.SoftwareUpdate AutomaticDownload -bool true
defaults write com.apple.SoftwareUpdate CriticalUpdateInstall -bool true
defaults write com.apple.SoftwareUpdate ConfigDataInstall -bool true
defaults write com.apple.SoftwareUpdate AutomaticallyInstallMacOSUpdates -bool true
defaults write com.apple.commerce AutoUpdate -bool true

# ============================================================================
# Dock
# ============================================================================
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock mru-spaces -bool false
defaults write com.apple.dock launchanim -bool false
defaults write com.apple.dock minimize-to-application -bool true
defaults write com.apple.dock show-process-indicators -bool true
defaults write com.apple.dock tilesize -int 48

# ============================================================================
# Activity Monitor — Dock icon shows per-core CPU history bars
# ============================================================================
defaults write com.apple.ActivityMonitor OpenMainWindow -bool true
defaults write com.apple.ActivityMonitor IconType -int 6
defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
defaults write com.apple.ActivityMonitor SortDirection -int 0

# ============================================================================
# Time Machine + Image Capture
# ============================================================================
defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true
defaults write com.apple.ImageCapture disableHotPlug -bool true

# ============================================================================
# Restart affected processes
# ============================================================================
step "Restarting Finder, Dock, SystemUIServer"
killall Finder Dock SystemUIServer 2>/dev/null || true

ok "Done — some changes require logout/restart to fully take effect"
