#!/bin/zsh

set -euo pipefail

REPO_DIR="/Users/rui/Desktop/PhotoMemo"
SUPPORT_DIR="$HOME/Library/Application Support/PhotoMemo"
RUNTIME_DIR="$SUPPORT_DIR/AutoSync"
PLIST_NAME="com.serydoo.photomemo.autosync.plist"
SOURCE_PLIST="$REPO_DIR/scripts/$PLIST_NAME"
SOURCE_SCRIPT="$REPO_DIR/scripts/auto_sync_to_github.sh"
TARGET_DIR="$HOME/Library/LaunchAgents"
TARGET_PLIST="$TARGET_DIR/$PLIST_NAME"
TARGET_SCRIPT="$RUNTIME_DIR/auto_sync_to_github.sh"

mkdir -p "$REPO_DIR/.autosync"
mkdir -p "$RUNTIME_DIR"
mkdir -p "$TARGET_DIR"

cp "$SOURCE_SCRIPT" "$TARGET_SCRIPT"
chmod +x "$TARGET_SCRIPT"

sed \
  -e "s#__REPO_DIR__#$REPO_DIR#g" \
  -e "s#__SUPPORT_DIR__#$SUPPORT_DIR#g" \
  -e "s#__TARGET_SCRIPT__#$TARGET_SCRIPT#g" \
  "$SOURCE_PLIST" >"$TARGET_PLIST"

launchctl bootout "gui/$(id -u)" "$TARGET_PLIST" >/dev/null 2>&1 || true
launchctl bootstrap "gui/$(id -u)" "$TARGET_PLIST"
launchctl enable "gui/$(id -u)/com.serydoo.photomemo.autosync"
launchctl kickstart -k "gui/$(id -u)/com.serydoo.photomemo.autosync"

echo "Installed auto sync agent at $TARGET_PLIST"
