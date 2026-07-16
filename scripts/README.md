# Scripts

This folder contains local automation helpers.

Current scripts:

- `auto_sync_to_github.sh`
- `install_autosync.sh`
- `com.serydoo.photomemo.autosync.plist`
- `export_options_v1_testing.plist` - local debugging export options
- `export_options_testflight.plist` - App Store Connect/TestFlight upload export options
- `collect-ios-runtime-evidence.sh` - pulls iPhone runtime diagnostics,
  shared defaults, queue summaries, and PhotoMemo crash reports for MGF-2B
  evidence review without copying private media.
- `summarize-ios-runtime-evidence.py` - summarizes collected iOS evidence and,
  when given a baseline plus scenario, evaluates V3 real-device Share Extension
  checks without inspecting private photo contents. New job summaries include
  total job duration and saved-task throughput so performance evidence can be
  compared across repeated real-device runs.

## V3 Runtime Evidence

Create a baseline before a manual Apple Photos -> Share -> MemoMark run:

```bash
PHOTOMEMO_RUNTIME_EVIDENCE_DIR=/tmp/PhotoMemoRuntimeEvidence/v3-baseline-$(date '+%Y%m%d-%H%M%S') \
PHOTOMEMO_RUNTIME_SCENARIO=baseline \
  scripts/collect-ios-runtime-evidence.sh '<device-id>'
```

After sharing a validation batch from Apple Photos, collect again with the
baseline directory:

```bash
PHOTOMEMO_RUNTIME_BASELINE_DIR=/tmp/PhotoMemoRuntimeEvidence/v3-baseline-YYYYMMDD-HHMMSS \
PHOTOMEMO_RUNTIME_EVIDENCE_DIR=/tmp/PhotoMemoRuntimeEvidence/v3-share-20-$(date '+%Y%m%d-%H%M%S') \
PHOTOMEMO_RUNTIME_SCENARIO=share-20 \
  scripts/collect-ios-runtime-evidence.sh '<device-id>'
```

Supported scenario values are:

- `baseline`
- `share-1`
- `share-20`
- `share-21-reject`
- `share-livephoto-1`
- `share-livephoto-mixed`
- `share-48mp`
- `manual`

The generated `runtime-evidence-summary.md` is the first file to inspect. For
the 21-photo rejection scenario, the script can only verify that no new handoff
request, batch job, or PhotoMemo crash appeared and that
`extension.input.tooManyPhotos` was recorded; the rejection copy still needs
manual UI confirmation on the device. Without that machine-readable rejection
event, the scenario is `needs-review` rather than `pass`. For `share-1` and
`share-20`, the summary requires a completed Share job, shared-container
readiness, and matching per-task `batch.task.duration` evidence before passing. For
`share-livephoto-1` and `share-livephoto-mixed`, the summary requires route
evidence and matching task-duration evidence scoped to the completed Share job
so unrelated route events cannot create a false pass. For `share-48mp`, the
summary requires a completed Share job with matching task-duration evidence
plus critical single-lane admission evidence.

The summary also reports each new batch job's `durationSeconds` and
`savedTasksPerMinute`. These fields are runtime evidence helpers, not a
replacement for Instruments. Use them to compare repeated 1-photo / 20-photo /
48MP smoke runs before deciding whether deeper `xctrace` collection is needed.
Current app builds also emit `batch.task.duration` diagnostics for completed
and failed tasks. Evidence summaries expose those events, task route events,
stage-duration events, and admission events so per-task route, duration, and
critical-memory scheduling can be compared during MainActor / performance
validation. Stage-duration summaries preserve optional `isMainThread`,
`threadName`, and `peakResidentMemoryBytes` fields when present so future
device traces can correlate slow stages with thread and memory evidence.

## TestFlight Export

Use `export_options_testflight.plist` only after creating a Release archive
that is signed with an Apple Distribution path.

The current Xcode-supported App Store Connect method is:

```text
method = app-store-connect
destination = upload
```

Keep `export_options_v1_testing.plist` for local/debugging exports. It uses
`method = debugging`, which is not the TestFlight upload path.

V2 note: the target structure names this bucket `Scripts`, but the existing repository uses lowercase `scripts`. Keep the current folder name unless a dedicated rename migration is planned.
