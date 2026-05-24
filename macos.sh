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
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

# ============================================================================
# Trackpad — tap to click everywhere (built-in, Bluetooth, login screen)
# ============================================================================
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# ============================================================================
# Cursor — disable shake-to-find-cursor magnification
# ============================================================================
defaults write NSGlobalDomain CGDisableCursorLocationMagnification -bool true

# ============================================================================
# Save / print panels — expanded by default
# Skip the disclosure-triangle click on every ⌘S and ⌘P. The "2"-suffixed keys
# cover apps built against the newer NSSavePanel/PMPrintPanel APIs.
# ============================================================================
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

# ============================================================================
# Crash reporter — quiet notification instead of blocking modal dialog
# ============================================================================
defaults write com.apple.CrashReporter DialogType none

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
# Activity Monitor — Dock icon shows the default application icon
# ============================================================================
defaults write com.apple.ActivityMonitor OpenMainWindow -bool true
defaults write com.apple.ActivityMonitor IconType -int 0
defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
defaults write com.apple.ActivityMonitor SortDirection -int 0

# ============================================================================
# Desktop wallpaper
# Sets the image on every active space. Placement (Fill Screen) and
# "Show on all Spaces" are preserved from existing user prefs — no public
# Tahoe API to force them. Image matches display res (5120x2880), so all
# placement modes render identically on this hardware.
# ============================================================================
WALLPAPER="$REPO_ROOT/assets/wallpaper.png"
if [[ -f "$WALLPAPER" ]]; then
  if osascript -e "tell application \"System Events\" to set picture of every desktop to \"$WALLPAPER\"" 2>/dev/null; then
    ok "Wallpaper set"
  else
    warn "Wallpaper set failed (may need login or System Events permission)"
  fi
else
  warn "Wallpaper missing at $WALLPAPER — skipping"
fi

# ============================================================================
# Time Machine + Image Capture
# ============================================================================
defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true
defaults write com.apple.ImageCapture disableHotPlug -bool true

# ============================================================================
# cmux — UI-only settings that don't round-trip through ~/.config/cmux/cmux.json.
# The schema'd settings (app/sidebar/sidebarAppearance/shortcuts/…) live in the
# symlinked cmux.json. The keys below are only reachable via the Settings UI
# and persist in NSUserDefaults, so replay them here. Quit cmux before running
# or the in-memory state will overwrite the writes on exit.
# ============================================================================
defaults write com.cmuxterm.app appearanceMode -string "light"
defaults write com.cmuxterm.app appIconMode -string "light"
defaults write com.cmuxterm.app sendAnonymousTelemetry -bool false
defaults write com.cmuxterm.app showMenuBarExtra -bool false
defaults write com.cmuxterm.app sidebarMatchTerminalBackground -bool true
defaults write com.cmuxterm.app sidebarTintHex -string "#000000"
defaults write com.cmuxterm.app sidebarTintOpacity -float 0.18
defaults write com.cmuxterm.app sidebarPreset -string "nativeSidebar"
defaults write com.cmuxterm.app sidebarMaterial -string "sidebar"
defaults write com.cmuxterm.app sidebarBlendMode -string "withinWindow"
defaults write com.cmuxterm.app sidebarBlurOpacity -float 1
defaults write com.cmuxterm.app sidebarCornerRadius -int 0
defaults write com.cmuxterm.app sidebarHideAllDetails -bool false
defaults write com.cmuxterm.app sidebarState -string "followWindow"
defaults write com.cmuxterm.app "rightSidebar.mode" -string "files"
defaults write com.cmuxterm.app "fileExplorer.width" -int 276
defaults write com.cmuxterm.app browserImportHintVariant -string "toolbarChip"

# ============================================================================
# Restart affected processes
# ============================================================================
step "Restarting Finder, Dock, SystemUIServer"
killall Finder Dock SystemUIServer 2>/dev/null || true

ok "Done — some changes require logout/restart to fully take effect"
