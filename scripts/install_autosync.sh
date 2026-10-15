#!/bin/zsh
set -euo pipefail
SCRIPT_DIR="${0:A:h}"
REPO_DIR="${MEMOMARK_REPO_DIR:-${SCRIPT_DIR:h}}"
SUPPORT_DIR="${MEMOMARK_SUPPORT_DIR:-$HOME/Library/Application Support/PhotoMemo}"
RUNTIME_DIR="$SUPPORT_DIR/AutoSync"
TARGET_DIR="$HOME/Library/LaunchAgents"
PLIST_NAME="com.serydoo.memomark.autosync.plist"
LEGACY_PLIST_NAME="com.serydoo.photomemo.autosync.plist"

# Stop the legacy whole-tree publisher before replacing its shared runner.
launchctl bootout "gui/$(id -u)/com.serydoo.photomemo.autosync" >/dev/null 2>&1 || true
launchctl bootout "gui/$(id -u)/com.serydoo.memomark.autosync" >/dev/null 2>&1 || true
launchctl disable "gui/$(id -u)/com.serydoo.photomemo.autosync"

/usr/bin/env python3 - "$REPO_DIR" "$SUPPORT_DIR" "$TARGET_DIR" <<'PY'
from pathlib import Path
import os
import plistlib
import shutil
import sys
import tempfile

repo, support, target = map(Path, sys.argv[1:])
runtime = support / 'AutoSync'
(runtime / 'backups').mkdir(parents=True, exist_ok=True)
target.mkdir(parents=True, exist_ok=True)
backup = Path(tempfile.mkdtemp(prefix='install-', dir=runtime / 'backups'))
runner = runtime / 'auto_sync_to_github.sh'
plist = target / 'com.serydoo.memomark.autosync.plist'
for old in (runner, runtime / 'memomark_source_sync.py', plist, target / 'com.serydoo.photomemo.autosync.plist'):
    if old.exists():
        shutil.copy2(old, backup / old.name)
config = plistlib.loads((repo / 'scripts/com.serydoo.memomark.autosync.plist').read_bytes())
config['ProgramArguments'] = [str(runner), 'prepare']
config['EnvironmentVariables'] = {'MEMOMARK_REPO_DIR': str(repo), 'MEMOMARK_SUPPORT_DIR': str(support)}
config['WorkingDirectory'] = str(runtime)
config['StandardOutPath'] = str(runtime / 'launchd.out.log')
config['StandardErrorPath'] = str(runtime / 'launchd.err.log')
runner_temp = runtime / 'runner-install.tmp'
shutil.copy2(repo / 'scripts/auto_sync_to_github.sh', runner_temp)
runner_temp.chmod(0o755)
os.replace(runner_temp, runner)
helper_temp = runtime / 'helper-install.tmp'
shutil.copy2(repo / 'scripts/memomark_source_sync.py', helper_temp)
os.replace(helper_temp, runtime / 'memomark_source_sync.py')
plist_temp = target / 'memomark-autosync-install.tmp'
plist_temp.write_bytes(plistlib.dumps(config))
os.replace(plist_temp, plist)
print('Installed safe prepare runner; previous files backed up at', backup)
PY

launchctl enable "gui/$(id -u)/com.serydoo.memomark.autosync"
launchctl bootstrap "gui/$(id -u)" "$TARGET_DIR/$PLIST_NAME"
echo "Scheduled prepare-only source inventory every 1800 seconds. Commit/push requires explicit sync."
