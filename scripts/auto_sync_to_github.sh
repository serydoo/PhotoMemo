#!/bin/zsh

set -euo pipefail

REPO_DIR="${PHOTOMEMO_REPO_DIR:-/Users/rui/Desktop/PhotoMemo}"
SUPPORT_DIR="${PHOTOMEMO_SUPPORT_DIR:-$HOME/Library/Application Support/PhotoMemo}"
LOG_DIR="$SUPPORT_DIR/AutoSync"
LOG_FILE="$LOG_DIR/auto-sync.log"

mkdir -p "$LOG_DIR"

exec >>"$LOG_FILE" 2>&1

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Auto sync started"

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

if [[ ! -d "$REPO_DIR/.git" ]]; then
  echo "Repository not found: $REPO_DIR"
  exit 1
fi

CURRENT_BRANCH="$(git -C "$REPO_DIR" branch --show-current)"

if [[ -z "$CURRENT_BRANCH" ]]; then
  echo "No current branch, skip."
  exit 0
fi

git -C "$REPO_DIR" add -A

git -C "$REPO_DIR" reset --quiet -- ':(glob)**/*.xcuserstate' ':(glob)**/xcuserdata/**' || true

if git -C "$REPO_DIR" diff --cached --quiet; then
  echo "No staged changes, skip."
  exit 0
fi

STAMP="$(date '+%Y-%m-%d %H:%M:%S')"
git -C "$REPO_DIR" commit -m "chore: auto sync ${STAMP}"
git -C "$REPO_DIR" push origin "$CURRENT_BRANCH"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Auto sync finished"
