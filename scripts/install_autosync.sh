#!/bin/zsh

set -euo pipefail

REPO_DIR="/Users/rui/Desktop/PhotoMemo"
PLIST_NAME="com.serydoo.photomemo.autosync.plist"
SOURCE_PLIST="$REPO_DIR/scripts/$PLIST_NAME"
TARGET_DIR="$HOME/Library/LaunchAgents"
TARGET_PLIST="$TARGET_DIR/$PLIST_NAME"

mkdir -p "$REPO_DIR/.autosync"
mkdir -p "$TARGET_DIR"

chmod +x "$REPO_DIR/scripts/auto_sync_to_github.sh"
cp "$SOURCE_PLIST" "$TARGET_PLIST"

launchctl bootout "gui/$(id -u)" "$TARGET_PLIST" >/dev/null 2>&1 || true
launchctl bootstrap "gui/$(id -u)" "$TARGET_PLIST"
launchctl enable "gui/$(id -u)/com.serydoo.photomemo.autosync"
launchctl kickstart -k "gui/$(id -u)/com.serydoo.photomemo.autosync"

echo "Installed auto sync agent at $TARGET_PLIST"
