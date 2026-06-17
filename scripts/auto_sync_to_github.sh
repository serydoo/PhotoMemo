#!/bin/zsh

set -euo pipefail

REPO_DIR="/Users/rui/Desktop/PhotoMemo"
LOG_DIR="$REPO_DIR/.autosync"
LOG_FILE="$LOG_DIR/auto-sync.log"

mkdir -p "$LOG_DIR"

exec >>"$LOG_FILE" 2>&1

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Auto sync started"

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

cd "$REPO_DIR"

CURRENT_BRANCH="$(git branch --show-current)"

if [[ -z "$CURRENT_BRANCH" ]]; then
  echo "No current branch, skip."
  exit 0
fi

git add -A

git reset --quiet -- ':(glob)**/*.xcuserstate' ':(glob)**/xcuserdata/**' || true

if git diff --cached --quiet; then
  echo "No staged changes, skip."
  exit 0
fi

STAMP="$(date '+%Y-%m-%d %H:%M:%S')"
git commit -m "chore: auto sync ${STAMP}"
git push origin "$CURRENT_BRANCH"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Auto sync finished"
