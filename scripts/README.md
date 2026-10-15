# Scripts

This folder contains local automation helpers.

Current scripts:

- `auto_sync_to_github.sh` - defaults to a read-only full-source plan; explicit validated sync is required for commit/push.
- `memomark_source_sync.py` - exact source coverage, privacy/missing-input checks, validated-candidate/index matching, guarded commit and remote SHA readback.
- `validate_codex_governance.py` - checks the compact Codex routing entry,
  project Skill boundaries, physical-device evidence rule, and explicit release
  authorization contract.
- `install_autosync.sh`
- `com.serydoo.memomark.autosync.plist` (the installer also boots out the
  legacy `com.serydoo.photomemo.autosync` label if it is installed)
- `export_options_v1_testing.plist` - local debugging export options
- `export_options_testflight.plist` - App Store Connect/TestFlight upload export options
- `collect-ios-runtime-evidence.sh` - pulls iPhone runtime diagnostics,
  shared defaults, queue summaries, and MemoMark crash reports for MGF-2B
  evidence review without copying private media.
- `summarize-ios-runtime-evidence.py` - summarizes collected iOS evidence and,
  when given a baseline plus scenario, evaluates V3 real-device Share Extension
  checks without inspecting private photo contents. New job summaries include
  total job duration and saved-task throughput so performance evidence can be
  compared across repeated real-device runs.

## V3 Runtime Evidence

Create a baseline before a manual Apple Photos -> Share -> MemoMark run:

```bash
MEMOMARK_RUNTIME_EVIDENCE_DIR=/tmp/MemoMarkRuntimeEvidence/v3-baseline-$(date '+%Y%m%d-%H%M%S') \
MEMOMARK_RUNTIME_SCENARIO=baseline \
  scripts/collect-ios-runtime-evidence.sh '<device-id>'
```

After sharing a validation batch from Apple Photos, collect again with the
baseline directory:

```bash
MEMOMARK_RUNTIME_BASELINE_DIR=/tmp/MemoMarkRuntimeEvidence/v3-baseline-YYYYMMDD-HHMMSS \
MEMOMARK_RUNTIME_EVIDENCE_DIR=/tmp/MemoMarkRuntimeEvidence/v3-share-20-$(date '+%Y%m%d-%H%M%S') \
MEMOMARK_RUNTIME_SCENARIO=share-20 \
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
request, batch job, or MemoMark crash appeared and that
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

## Complete-source sync (2026-10-16)

The installed launch agent runs prepare every1800 seconds. It updates a local
plan in the existing Application Support/PhotoMemo/AutoSync directory, without
staging, committing or pushing. Source, tests, project/shared schemes, resources,
scripts, engineering documents and research source are considered together.
Raw local evidence/signing/private configuration stays local. Unknown or ignored
build inputs and generated-directory source without a published identical copy
block explicit sync for review. Review the plan's blocked and retained entries;
a saved plan is not a passed build or published checkpoint.

```sh
scripts/auto_sync_to_github.sh prepare
scripts/auto_sync_to_github.sh sync \
  --candidate /tmp/ReviewedCompleteSource \
  --receipt /tmp/ReviewedValidationReceipt.json \
  --message-file /tmp/ReviewedCommitMessage.txt
```

The receipt must bind base/branch and the full files map from the reviewed plan,
not only its changed paths. Each file entry has sha256 and executable fields.
checks.fullTests, checks.iosArchive and checks.scriptTests each require exit=0 and
an evidence path to a nonempty local result/summary file. Populate these from
actual commands on that exact complete candidate; this is a local execution
receipt contract, not cryptographic certification. New edits require refreshed
coverage and appropriate verification. See the cloud-build guide and release
sync standard. No receipt override or skip-validation flag exists.

Explicit sync requires an initially empty index and an unchanged remote baseline.
It stages literal exact paths, checks whitespace, exports the full index, compares
content and executable modes, and rejects a commit hook changing the validated
tree before push. Failure preserves the index or local commit for review; it does
not clean/reset or force-push. Do not run a second publisher or manually edit the
index concurrently. Scheduled and manual CLI runs share a checkout-level lock.
These gates do not substitute for human authorization of the sync command or for
private-material review. TestFlight/App Store actions remain separate.

Install/update the local prepare task with scripts/install_autosync.sh. It copies the runner and Python helper into Application Support and backs
up their previous copies and plists, disables the legacy label, and installs the modern
prepare-only task with explicit repository/support-directory environment values.
It preserves existing logs, source and local evidence. No fixed developer path
is embedded in the tracked scripts. MEMOMARK_REPO_DIR and MEMOMARK_SUPPORT_DIR
can override local checkout/support paths.

macOS may deny a launch agent access to a Desktop checkout even when an interactive
authorized terminal can read it. Such a task writes status=stopped with the system
error; installation alone is not a successful inventory or GitHub backup. Do not
bypass that permission or claim the scheduled run succeeded. The explicit manual
workflow remains usable from an authorized environment; verify the task separately
after the owner grants appropriate system access. Prepare also disables optional
Git index refresh so read-only inventory preserves index bytes.
