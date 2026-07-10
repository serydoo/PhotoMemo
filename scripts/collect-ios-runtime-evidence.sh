#!/bin/zsh

set -euo pipefail

DEVICE_ID="${1:-863C2747-6742-5E93-B715-6F89DBF90B31}"
STAMP="$(date '+%Y%m%d-%H%M%S')"
OUTPUT_DIR="${PHOTOMEMO_RUNTIME_EVIDENCE_DIR:-/tmp/PhotoMemoRuntimeEvidence/$STAMP}"
APP_BUNDLE_ID="com.serydoo.PhotoMemo.iOS"
APP_GROUP_ID="group.com.serydoo.PhotoMemo"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$OUTPUT_DIR"/{appdata,appgroup,crashes,decoded}

echo "Collecting MemoMark runtime evidence"
echo "Device: $DEVICE_ID"
echo "Output: $OUTPUT_DIR"

xcrun devicectl device info details \
  --device "$DEVICE_ID" \
  >"$OUTPUT_DIR/device-details.txt" 2>&1 || true

xcrun devicectl device info processes \
  --device "$DEVICE_ID" \
  >"$OUTPUT_DIR/processes.txt" 2>&1 || true

xcrun devicectl device info apps \
  --device "$DEVICE_ID" \
  >"$OUTPUT_DIR/apps.txt" 2>&1 || true

xcrun devicectl device info files \
  --device "$DEVICE_ID" \
  --domain-type appDataContainer \
  --domain-identifier "$APP_BUNDLE_ID" \
  --recurse \
  --columns '*' \
  >"$OUTPUT_DIR/appdata-files.txt" 2>&1 || true

xcrun devicectl device info files \
  --device "$DEVICE_ID" \
  --domain-type appGroupDataContainer \
  --domain-identifier "$APP_GROUP_ID" \
  --recurse \
  --columns '*' \
  >"$OUTPUT_DIR/appgroup-files.txt" 2>&1 || true

xcrun devicectl device copy from \
  --device "$DEVICE_ID" \
  --domain-type appDataContainer \
  --domain-identifier "$APP_BUNDLE_ID" \
  --source "Library/Preferences/$APP_BUNDLE_ID.plist" \
  --destination "$OUTPUT_DIR/appdata/$APP_BUNDLE_ID.plist" \
  >"$OUTPUT_DIR/copy-appdata-preferences.log" 2>&1 || true

xcrun devicectl device copy from \
  --device "$DEVICE_ID" \
  --domain-type appGroupDataContainer \
  --domain-identifier "$APP_GROUP_ID" \
  --source "Library/Preferences/$APP_GROUP_ID.plist" \
  --destination "$OUTPUT_DIR/appgroup/$APP_GROUP_ID.plist" \
  >"$OUTPUT_DIR/copy-appgroup-preferences.log" 2>&1 || true

xcrun devicectl device info files \
  --device "$DEVICE_ID" \
  --domain-type systemCrashLogs \
  --recurse \
  --search PhotoMemo \
  --columns '*' \
  >"$OUTPUT_DIR/crash-files.txt" 2>&1 || true

awk '/PhotoMemo.*\.ips/ {print $1}' "$OUTPUT_DIR/crash-files.txt" \
  | sort -u \
  | while read -r crash_file; do
      [[ -z "$crash_file" ]] && continue
      xcrun devicectl device copy from \
        --device "$DEVICE_ID" \
        --domain-type systemCrashLogs \
        --source "$crash_file" \
        --destination "$OUTPUT_DIR/crashes/$crash_file" \
        >"$OUTPUT_DIR/crashes/copy-$crash_file.log" 2>&1 || true
    done

python3 - "$OUTPUT_DIR" "$APP_GROUP_ID" <<'PY'
import json
import plistlib
import sys
from pathlib import Path

output_dir = Path(sys.argv[1])
app_group_id = sys.argv[2]
plist_path = output_dir / "appgroup" / f"{app_group_id}.plist"
decoded_dir = output_dir / "decoded"

if not plist_path.exists():
    print(f"App group plist not found: {plist_path}")
    raise SystemExit(0)

root = plistlib.loads(plist_path.read_bytes())

for key, filename in [
    ("photomemo.shareDiagnostics.events", "shareDiagnostics.events.json"),
    ("photomemo.batchQueue.jobs", "batchQueue.jobs.json"),
    ("photomemo.externalIntake.requests", "externalIntake.requests.json"),
]:
    value = root.get(key)
    if not isinstance(value, (bytes, bytearray)):
        continue

    try:
        decoded = json.loads(value.decode("utf-8"))
    except Exception as error:
        (decoded_dir / f"{filename}.decode-error.txt").write_text(
            str(error),
            encoding="utf-8",
        )
        continue

    (decoded_dir / filename).write_text(
        json.dumps(decoded, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

events_path = decoded_dir / "shareDiagnostics.events.json"
if events_path.exists():
    events = json.loads(events_path.read_text(encoding="utf-8"))
    summary = [
        {
            "timestamp": event.get("timestamp"),
            "stage": event.get("stage"),
            "message": event.get("message"),
            "requestID": event.get("requestID"),
            "jobID": event.get("jobID"),
        }
        for event in events[-30:]
    ]
    (decoded_dir / "shareDiagnostics.tail.json").write_text(
        json.dumps(summary, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

jobs_path = decoded_dir / "batchQueue.jobs.json"
if jobs_path.exists():
    jobs = json.loads(jobs_path.read_text(encoding="utf-8"))
    summary = []
    for job in jobs[-5:]:
        tasks = job.get("tasks") or []
        summary.append(
            {
                "jobID": job.get("id"),
                "title": job.get("title"),
                "launchSource": job.get("launchSource"),
                "state": job.get("state"),
                "taskCount": len(tasks),
                "tasks": [
                    {
                        "taskID": task.get("id"),
                        "fileName": task.get("fileName"),
                        "contentTypeIdentifier": task.get("contentTypeIdentifier"),
                        "sourceIdentifierPresent": bool(task.get("sourceIdentifier")),
                        "phase": task.get("phase"),
                        "savedAssetIdentifier": task.get("savedAssetIdentifier"),
                    }
                    for task in tasks[:20]
                ],
            }
        )

    (decoded_dir / "batchQueue.summary.json").write_text(
        json.dumps(summary, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
PY

echo "Runtime evidence collected at: $OUTPUT_DIR"
echo "Useful files:"
echo "- $OUTPUT_DIR/decoded/shareDiagnostics.tail.json"
echo "- $OUTPUT_DIR/decoded/batchQueue.summary.json"
echo "- $OUTPUT_DIR/crash-files.txt"

SUMMARY_ARGS=("$OUTPUT_DIR" "--write")
if [[ -n "${PHOTOMEMO_RUNTIME_BASELINE_DIR:-}" ]]; then
  SUMMARY_ARGS+=("--baseline" "$PHOTOMEMO_RUNTIME_BASELINE_DIR")
fi
if [[ -n "${PHOTOMEMO_RUNTIME_SCENARIO:-}" ]]; then
  SUMMARY_ARGS+=("--scenario" "$PHOTOMEMO_RUNTIME_SCENARIO")
fi

if [[ -f "$SCRIPT_DIR/summarize-ios-runtime-evidence.py" ]]; then
  python3 "$SCRIPT_DIR/summarize-ios-runtime-evidence.py" "${SUMMARY_ARGS[@]}" \
    >"$OUTPUT_DIR/runtime-evidence-summary.log" 2>&1 || true
  echo "- $OUTPUT_DIR/runtime-evidence-summary.md"
  echo "- $OUTPUT_DIR/runtime-evidence-summary.json"
fi
