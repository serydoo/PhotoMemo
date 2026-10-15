#!/bin/zsh
# Scheduled invocations only prepare a plan. Publishing requires explicit sync inputs.
set -euo pipefail
SCRIPT_DIR="${0:A:h}"
REPO_DIR="${MEMOMARK_REPO_DIR:-${PHOTOMEMO_REPO_DIR:-${SCRIPT_DIR:h}}}"
SUPPORT_DIR="${MEMOMARK_SUPPORT_DIR:-${PHOTOMEMO_SUPPORT_DIR:-$HOME/Library/Application Support/PhotoMemo}}"
exec /usr/bin/env python3 "$SCRIPT_DIR/memomark_source_sync.py" \
  --repo "$REPO_DIR" --output "$SUPPORT_DIR/AutoSync/latest-plan-or-sync.json" "$@"
