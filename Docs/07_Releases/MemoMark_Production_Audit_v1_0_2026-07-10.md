# MemoMark Production Audit v1.0

Date: 2026-07-10

Scope: current `main` at `4c155e60 Stabilize V1 iOS feedback and Live Photo intake`.

This audit is a release-readiness review of the product engineering system, not
a normal bug sweep. It reviews architecture, state management, data flow,
rendering, Live Photo, repository/configuration, export, performance, error
handling, UI consistency, and release hygiene.

## Executive Summary

Production readiness score: **78 / 100**

TestFlight recommendation: **Conditional Yes**

MemoMark is now well beyond MVP quality. The core workflow exists, the app has
real configuration, metadata, memory expression, render/export, Live Photo,
Share Extension intake, persistence, and release packaging paths.

No P0 release blockers were found. The main risk is not missing feature surface.
The main risk is **state and persistence consistency under edge cases**:
configuration save paths, MemorySubject draft synchronization, missing capture
time semantics, Share Extension/App Group handoff observability, and Live Photo
route parity.

Before presenting the current build as a stable external release candidate, the
P1 list below should either be fixed or explicitly accepted with targeted
manual validation.

## Module Scores

| Module | Score | Notes |
|---|---:|---|
| Architecture & App Entry | 4/5 | Good AppEnvironment assembly; App Group fallback and macOS singleton intake need hardening. |
| Module Boundary | 4/5 | Boundaries mostly hold; queue execution/store and view-level intake are still coupled. |
| Domain Model | 3/5 | Memory and configuration models work, but some fallback dates can create false memory facts. |
| State Management | 3/5 | SwiftUI state is powerful but too distributed around subject drafts, presets, lifecycle refresh. |
| Data Flow | 4/5 | Metadata -> Memory -> Expression -> Render path is understandable; old compatibility bridges remain thick. |
| Rendering Pipeline | 4/5 | Renderer/export path is functional; some metadata parity and color/quality policies remain implicit. |
| Live Photo | 3/5 | Main app picker path is strong; Share Extension remains limited, and Live Photo route needs policy guards. |
| Repository & Persistence | 3/5 | Repository containers exist; some save APIs can still silently overwrite preset payloads. |
| Configuration | 3/5 | Configuration Center is usable, but preset and anchor mutation boundaries need stricter persistence rules. |
| Export & Photo Library | 4/5 | Static export is mature; Live Photo album fallback differs from static-image behavior. |
| Performance & Concurrency | 3/5 | No infinite loop found; large files, main-actor media work, and repeated lifecycle refresh are debt. |
| Release Hygiene | 4/5 | No TODO/FIXME/print/try!/fatalError/assert in source; `try?` observability remains broad. |

## Release Decision

### Can upload to TestFlight?

Yes, **if the build is treated as a validation candidate** and the P1 scenarios
below are tested or patched before broader external distribution.

### Can call this production-stable?

Not yet. It is close, but the current risk profile is still more
`Release Candidate / TestFlight validation` than `long-term stable production`.

## P0 Findings

No P0 findings.

No evidence was found for:

- app startup failure
- inevitable build/target breakage
- destructive photo mutation
- cloud/private-data leak
- renderer reading repository state directly
- `try!`, `fatalError`, `assert`, `print`, or TODO/FIXME debug debris in source

## P1 Findings

### P1-01: Missing capture time can generate false memory time

Evidence:

- `Source/PhotoMemo/PhotoMemo/Services/RecordCardBuildService.swift:178`

Finding:

`selectedPhoto.metadata.captureDate ?? Date()` can generate an `AnchorResult`
from runtime time when the photo has no capture date. That violates the
Capture-Time Principle because the app can create a memory age/countdown from a
time that is not in the photo.

Impact:

Images without EXIF capture time, screenshots, or flattened Share Extension
payloads may produce believable but false memory values.

Recommendation:

When capture date is missing, do not generate legacy `AnchorResult`. Let memory
variables resolve to missing/empty state, matching the newer Memory Engine
contract.

Release posture:

Block external stable release. For TestFlight, either patch or explicitly test
no-EXIF/screenshot/share payload behavior.

### P1-02: MemorySubject adapter uses `Date()` as unknown reference date

Evidence:

- `Source/PhotoMemo/PhotoMemo/MemoryEngine/MemorySubjectAdapter.swift:23`

Finding:

`referenceDate ?? birthday ?? anchors.first?.date ?? Date()` turns unknown
subject reference time into the current runtime date.

Impact:

A subject without a real reference date can appear to have a valid life anchor.
This can contaminate preview, summaries, and future snapshot semantics.

Recommendation:

Model unknown reference time explicitly. Restrict default dates to preview/mock
fixtures, not production adapter output.

Release posture:

Conditional TestFlight blocker for first-run or empty-profile flows.

### P1-03: Configuration save APIs still allow silent empty preset overwrite

Evidence:

- `Source/PhotoMemo/PhotoMemo/Intent/ConfigurationSaveIntents.swift:47`
- `Source/PhotoMemo/PhotoMemo/Coordinators/ConfigurationCoordinator.swift:89`
- `Source/PhotoMemo/PhotoMemo/Repositories/SettingsRepository.swift:71`
- `Source/PhotoMemo/PhotoMemo/Services/SettingsService.swift:446`

Finding:

`memoryPresets` and `selectedMemoryPresetID` still have empty/default values
across several save APIs. The current V1 view passes them explicitly, but future
or secondary callers can still overwrite the saved preset list with an empty
payload.

Impact:

This is a structural recurrence risk for "configuration reset/disappears" bugs.

Recommendation:

Remove silent defaults. Introduce an explicit `V1PresetPersistencePayload` or
make preset payload required for all subject-library save paths.

Release posture:

Recommended TestFlight blocker because configuration reset was a real user
feedback item.

### P1-04: Preset rename/delete operations can remain draft-only

Evidence:

- `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift:1014`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift:1290`

Finding:

Some preset identity/destructive operations mutate `ConfigurationSession` first
and rely on later save/apply flows to persist.

Impact:

Users can rename or delete a preset, leave the app, then see old state return.
This reads as configuration reset.

Recommendation:

Persist rename/delete immediately through the repository, or make the UI
explicitly draft-based and require a visible save action.

Release posture:

Recommended TestFlight blocker for configuration stability.

### P1-05: Opening MemorySubject editor can mark configuration dirty

Evidence:

- `Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Editors/MemorySubjectEditorView.swift:139`
- `Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Editors/MemorySubjectEditorView.swift:1138`
- `Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Editors/MemorySubjectEditorView.swift:1245`
- `Source/PhotoMemo/PhotoMemo/ConfigurationCenter/ConfigurationSession.swift:203`

Finding:

`loadDrafts()` writes multiple `@State` values. Follow-up `.onChange` handlers
can call `syncDraftToSession()`, and session subject updates can mark the active
preset as needing reapply.

Impact:

Opening or switching an object editor may change applied/dirty state even if the
user did not edit anything.

Recommendation:

Add an `isLoadingDrafts` transaction guard or collapse subject edit state into a
single draft model. Add a regression test that opening the editor does not
change applied state.

Release posture:

Recommended TestFlight blocker because it matches the current feedback family.

### P1-06: Time-anchor sheet has local edits that may not reach session

Evidence:

- `Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Editors/MemorySubjectEditorView.swift:831`
- `Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Editors/MemorySubjectEditorView.swift:867`
- `Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Editors/MemorySubjectEditorView.swift:890`
- `Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Editors/MemorySubjectEditorView.swift:931`

Finding:

The time-anchor sheet mutates local `timeAnchors`, while session sync depends on
the explicit "save current anchor" action.

Impact:

If the user dismisses the sheet, the list may appear changed locally while
preview/save/processing can still use old anchor state.

Recommendation:

Use either auto-sync on real changes or an explicit isolated draft with
Cancel/Save and interactive dismiss disabled.

Release posture:

Recommended TestFlight blocker for Time Anchor editing.

### P1-07: App Group fallback is silent in the Share Extension handoff path

Evidence:

- `Source/PhotoMemo/PhotoMemo/App/PhotoMemoSharedContainer.swift:27`
- `Source/PhotoMemo/PhotoMemo/App/PhotoMemoSharedContainer.swift:46`
- `Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionIntakeService.swift:198`
- `Source/PhotoMemo/PhotoMemo/Architecture/AppEnvironment.swift:126`
- `Source/PhotoMemo/PhotoMemo/PhotoMemoiOS.entitlements:5`
- `Source/PhotoMemo/PhotoMemo/PhotoMemoShareExtension.entitlements:5`

Finding:

If App Group UserDefaults/container resolution fails, the app falls back to
standard defaults or App Support. Entitlements currently look correct, but if
provisioning/App Group setup breaks, Share Extension can write to one sandbox
while the main app reads another.

Impact:

User sees a successful share handoff, but the main app drains no request.

Recommendation:

Expose App Group readiness as a diagnosable state. Do not silently fallback for
Share Extension handoff. Add a TestFlight/real-device share handoff smoke test.

Release posture:

Conditional TestFlight blocker unless real-device/TestFlight Share Extension
handoff has been verified.

### P1-08: Queue persistence result is discarded

Evidence:

- `Source/PhotoMemo/PhotoMemo/Services/BatchQueueStore.swift:334`
- `Source/PhotoMemo/PhotoMemo/Services/BatchQueuePersistence.swift:184`

Finding:

`persistJobs()` discards the persistence result.

Impact:

If UserDefaults/App Group persistence fails, in-memory state may show complete
while reboot/share snapshots remain stale. This can lose history or repeat work.

Recommendation:

Surface persistence failures into diagnostics and last-error state. For terminal
states, consider persisting successfully before cleanup and notification.

Release posture:

Not an upload blocker, but a release reliability P1.

### P1-09: Live Photo and static export differ on invalid album fallback

Evidence:

- `Source/PhotoMemo/PhotoMemo/MediaPipelineVNext/PhotoKitLivePhotoAssetWriter.swift:292`
- `Source/PhotoMemo/PhotoMemo/Services/PhotoLibraryExportService.swift:363`

Finding:

Static photo export falls back to the default MemoMark album if the configured
album ID is stale. Live Photo export fails with `albumNotFound`.

Impact:

The same configuration can succeed for static images and fail for Live Photos,
especially after a user deletes/recreates albums.

Recommendation:

Unify the strategy. Prefer Live Photo fallback to default album for V1
resilience, or make both paths fail explicitly with a refresh prompt.

Release posture:

Recommended before advertising Live Photo as a TestFlight capability.

### P1-10: Live Photo route bypasses still-image input policy checks

Evidence:

- `Source/PhotoMemo/PhotoMemo/MediaPipelineVNext/MediaProcessingRouter.swift:25`

Finding:

Live Photo route selection returns `.livePhoto` before applying
`PhotoProcessingInputPolicy` size/pixel/aspect checks.

Impact:

Abnormal or extremely large Live Photo still resources can enter the
motion-preserving pipeline and create memory/export failures.

Recommendation:

After extracting the still resource, run the same policy checks before rendering
or saving. Unsupported cases should degrade to static or fail with a clear
reason.

Release posture:

High-priority hardening; not a standard iPhone Live Photo TestFlight blocker.

### P1-11: Live Photo processor relies too heavily on upstream route guards

Evidence:

- `Source/PhotoMemo/PhotoMemo/Services/LivePhotoBatchTaskProcessor.swift:445`

Finding:

The processor builds an input descriptor with `isLivePhotoAsset: true`, relying
on upstream batch execution to guarantee route correctness.

Impact:

Future reuse or tests that bypass the batch gate could incorrectly run
non-Live-Photo input through the Live Photo processor.

Recommendation:

Add a processor-level guard using explicit asset identity/content type or
`PhotoProcessingInputPolicy.canUseLivePhotoProcessing(...)`.

Release posture:

Not a current main-entry blocker, but should be fixed as boundary hardening.

### P1-12: macOS AppDelegate uses singleton intake center outside runtime

Evidence:

- `Source/PhotoMemo/PhotoMemo/App/PhotoMemoAppDelegate.swift:16`
- `Source/PhotoMemo/PhotoMemo/App/PhotoMemoAppDelegate.swift:31`
- `Source/PhotoMemo/PhotoMemo/App/PhotoMemoAppDelegate.swift:53`
- `Source/PhotoMemo/PhotoMemo/App/PhotoMemoAppRuntime.swift:68`
- `Source/PhotoMemo/PhotoMemo/Architecture/AppEnvironment.swift:202`
- `Source/PhotoMemo/PhotoMemo/App/ExternalPhotoIntakeCenter.swift:9`

Finding:

The macOS app delegate submits to `ExternalPhotoIntakeCenter.shared`, while
runtime uses `environment.externalIntakeCenter`.

Impact:

Runtime dependency graph and file-open entry can split. If persistence fails,
pending requests may sit in the singleton center and never reach runtime.

Recommendation:

Inject a runtime-owned intake router into AppDelegate or make AppDelegate only
forward URLs to the active runtime.

Release posture:

Not an iOS TestFlight blocker; macOS architecture P1.

## P2 Technical Debt Backlog

### Architecture / Boundaries

- `BatchQueueStore` and `BatchQueueExecution` form a two-way manager/executor
  structure. Move toward event/reducer or actor ownership.
- `PhotoMemoiOSV1View` still performs intake mutation directly. Prefer a
  coordinator/intent boundary.
- `ShareExtensionViewController` is a mega-controller. Extract view model,
  handoff monitor, preview loader, and diagnostic presenter.
- `ConfigurationCenteriOSView` and `PhotoMemoiOSV1View` carry overlapping
  configuration-state models. Mark legacy/internal or converge.
- `ConfigurationSnapshot` is narrower than the future IA-003B production
  snapshot. Distinguish `MemorySubjectSnapshot` from full configuration
  snapshot or expand it.

### State / UI

- `PhotoMemoiOSV1View.swift` is 3400+ lines and owns too many state categories.
- Root and V1 view both refresh on task/appear/active; centralize lifecycle
  refresh in one coordinator.
- Task thumbnails use detached loading and can briefly show stale images under
  fast refresh.
- Inspector mutates full `ConfigurationSession`; future undo/snapshot needs a
  command boundary.

### Data Flow

- `CardVariableProvider` is a thick compatibility facade. Split metadata,
  memory-result, legacy-anchor, and export-description projection.
- `ProductionMemoryResolver` can compute memory expression twice in one resolve.
- Provider assembly is spread across `CardTextBlockEngine` and related preview
  helpers. Introduce a production expression-context builder.

### Export / Persistence

- Managed-intake path checks use `path.hasPrefix`; replace with normalized URL
  boundary checks.
- `MemoMarkExports` temporary output folder needs age-based startup cleanup.
- Notification attachment thumbnails need retention cleanup tied to queue
  history.
- JPEG/HEIC output quality should be explicit and tested.
- P3/wide-color policy is implicit; define sRGB conversion or true profile
  preservation strategy.
- Static HEIC non-ASCII `UserComment` handling should match the safer Live
  Photo still path.

### Error Handling / Observability

- Source contains 81 `try?` uses. Many are acceptable cleanup/sleep/decode
  fallbacks, but configuration persistence, metadata patching, and intake
  cleanup should become observable.
- Share/App Group readiness should be visible in diagnostics before users see
  silent handoff failure.

### Release Hygiene

- No TODO/FIXME/debug print/fatal/try! source findings.
- Existing release hygiene is strong; the next improvement is not cleanup, but
  making failure states diagnosable.

## Suggested Fix Order

1. Fix capture-time fallback and MemorySubject unknown reference-date fallback.
2. Remove silent empty defaults from configuration save APIs.
3. Persist preset rename/delete immediately or explicitly model draft state.
4. Guard MemorySubject editor draft loading and time-anchor sheet save/cancel
   semantics.
5. Verify or harden App Group handoff behavior on real TestFlight/physical
   device.
6. Align Live Photo album fallback with static export.
7. Add Live Photo policy checks and processor-level route guard.
8. Surface batch queue persistence failures in diagnostics.

## Verification Notes

Already known from the current session:

- `main` is synchronized with `origin/main`.
- Unsigned IPA was generated from current `main`.
- Release archive creation for `PhotoMemoiOS` succeeded while producing the IPA.
- Prior focused tests and Debug builds for the stabilization pass were recorded
  in `HANDOFF.md`.

Not verified by this audit:

- Full broad `PhotoMemoTests` suite.
- Xcode Cloud TestFlight upload.
- Real TestFlight Share Extension App Group handoff.
- Manual no-EXIF/screenshot/invalid-album Live Photo scenarios.

## Final Recommendation

MemoMark can proceed as a TestFlight validation candidate, but should not be
described as production-stable until the P1 configuration, memory-time, and
handoff consistency items are resolved or explicitly accepted with test evidence.

