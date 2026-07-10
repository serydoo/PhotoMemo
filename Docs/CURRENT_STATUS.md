# MemoMark Current Status

Last updated: 2026-07-10

## 2026-07-10 Production Audit v2.0 Completed

MemoMark Production Audit v2.0 has been completed as a modular engineering
readiness review.

New release-review documents:

- `Docs/07_Releases/MemoMark_Production_Audit_v2_0_Plan_2026-07-10.md`
- `Docs/07_Releases/MemoMark_Production_Audit_v2_0_Module_1_Architecture_Dependency_2026-07-10.md`
- `Docs/07_Releases/MemoMark_Production_Audit_v2_0_Module_2_State_Repository_2026-07-10.md`
- `Docs/07_Releases/MemoMark_Production_Audit_v2_0_Module_3_Memory_Expression_2026-07-10.md`
- `Docs/07_Releases/MemoMark_Production_Audit_v2_0_Module_4_Media_Pipeline_2026-07-10.md`
- `Docs/07_Releases/MemoMark_Production_Audit_v2_0_Module_5_SwiftUI_2026-07-10.md`
- `Docs/07_Releases/MemoMark_Production_Audit_v2_0_Module_6_Release_2026-07-10.md`
- `Docs/07_Releases/MemoMark_Production_Audit_v2_0_Final_2026-07-10.md`

Final review conclusion:

- confirmed P0 findings: none
- release decision: Conditional Yes for a controlled TestFlight validation
  candidate
- not a claim that TestFlight distribution has already completed
- supported validation scope: still-image flow, small-batch processing, and main
  app picker Live Photo release-candidate path
- explicitly not ready to claim: Share Extension Live Photo, robust 48MP
  processing, 100-batch reliability, HDR/RAW preservation, video, Spatial Photo,
  or fully production-grade Memory Engine

Top release conditions identified:

- fix or re-verify preset deletion persistence with reload coverage
- fix or re-verify anchor-maintenance auto-edit sheet behavior
- align Live Photo product wording with current main-app picker RC scope
- complete real signed archive/upload/App Store Connect/TestFlight install smoke
  before saying TestFlight has shipped
- keep Share Extension Live Photo as a known limitation until a signed-build
  handoff and resource-identity path is proven

Architecture note:

- v2.0 did not authorize unscoped renderer/export/layout rewrites.
- Renderer/Layout Engine work remains governed by the V2 Reset flow:
  Research -> Specification -> Layout Engine -> Renderer -> Validation ->
  Release.

## 2026-07-09 TestFlight Archive Readiness Dry-Run Passed

The canonical `main` workspace passed a local Release archive dry-run for the
`PhotoMemoiOS` scheme without uploading anything to App Store Connect.

Verification command shape:

```bash
xcodebuild -project Source/PhotoMemo/PhotoMemo.xcodeproj \
  -scheme PhotoMemoiOS \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath /tmp/PhotoMemoReleaseReadinessArchive.xcarchive \
  CODE_SIGNING_ALLOWED=NO \
  COMPILER_INDEX_STORE_ENABLE=NO \
  -quiet archive
```

Archive inspection:

- archive was created at
  `/tmp/PhotoMemoReleaseReadinessArchive.xcarchive`
- archived app path: `Applications/PhotoMemoiOS.app`
- app bundle identifier: `com.serydoo.PhotoMemo.iOS`
- app version/build from project settings: `1.5` / `7`
- embedded extensions:
  - `PhotoMemoShareExtension.appex`
  - `PhotoMemoWidgetExtension.appex`
- extension bundle identifiers:
  - `com.serydoo.PhotoMemo.iOS.ShareExtension`
  - `com.serydoo.PhotoMemo.iOS.WidgetExtension`
- app and Share Extension privacy manifests are present in the archive

Release export options remain aligned for TestFlight upload:

- `scripts/export_options_testflight.plist`
- `method = app-store-connect`
- `destination = upload`
- `teamID = UK7ZR8G564`

No upload was attempted in this local dry-run. Xcode Cloud / App Store Connect
still owns the external build counter for TestFlight.

## 2026-07-09 Live Photo Main App Picker Post-Merge Verification Passed

After `main` was cleaned and synchronized to `origin/main`, the Live Photo main
app picker release-candidate line was verified again from the canonical
workspace.

Build matrix passed:

- `PhotoMemoiOS` Debug generic iOS build
- `PhotoMemoShareExtension` Debug generic iOS build
- `PhotoMemoWidgetExtension` Debug generic iOS build
- `PhotoMemo` Debug macOS build

Focused tests passed:

- `MediaGeometryArchitectureTests`
- `MediaGeometryFoundationCoreTests`
- `LivePhotoVideoCompositionServiceTests`
- `LivePhotoStillImageCompositionServiceTests`
- `LivePhotoPairCompositionServiceTests`
- `LivePhotoAssetLoaderContractTests`
- `LivePhotoAssetWriterContractTests`
- `LivePhotoPairingIdentityVerifierTests`
- `LivePhotoBatchQueueExecutionTests`
- `PhotoMemoiOSV1PhotoIntakeTests`

Known non-blocking warnings remain unchanged:

- macOS deployment target `27.0` exceeds the installed SDK's supported range.
- `GeocoderService.swift` still uses `CLGeocoder` APIs deprecated in macOS 26.

Repository hygiene result:

- local worktree is clean
- `main` is synchronized with `origin/main`
- local branches were reduced to `main`
- the old Live Photo worktree was removed after preserving its dirty WIP in
  `/Users/rui/Desktop/PhotoMemoWorktreeBackups/`

## 2026-07-09 Live Photo Main App Picker Release Candidate Merged

The Live Photo main app picker release candidate has been merged into `main`
and pushed to `origin/main`.

Merge checkpoint:

- `c6b97d99` - `Merge Live Photo main picker release candidate`
- feature checkpoint: `f7825e4f` - `Add Live Photo main picker release candidate`

Current product status:

- Main App Picker Live Photo path: release candidate / production candidate.
- Share Extension Live Photo path: known limitation and future production
  validation item.
- Failed-item thumbnail/reason UI: deferred polish after the Live Photo main
  app picker capability is safely on `main`.
- Media Geometry Foundation remains closed/stable; do not reopen it unless
  runtime evidence proves `CanonicalGeometry` itself is wrong.

Release-materials follow-up:

- V1.5 TestFlight materials now state that builds from `c6b97d99` or later
  include Main App Picker Live Photo release-candidate support.
- Version/build numbers are unchanged; Xcode Cloud / App Store Connect still
  owns the build counter.

## 2026-07-09 Live Photo Description Metadata Parity Verified

Live Photo runtime output now preserves the MemoMark description metadata path
used by still-image export.

Runtime / metadata finding:

- Classification: Composition / metadata propagation
- Symptom: Live Photo visual output was present, but the motion-preserving still
  HEIC resource did not yet have the same smart-module / right-bottom export
  description behavior as ordinary still-image export.
- Root cause: `LivePhotoBatchTaskProcessor` needed to pass
  `CardVariableProvider.exportDescription(from:)` into the Live Photo still
  composition path, and HEIC `UserComment` must not receive non-ASCII text that
  ImageIO reads back as corrupted truncated Unicode.
- Foundation changed: No.

Implementation result:

- Live Photo motion-preserving output now derives the export description from
  the built `RecordCard`.
- `LivePhotoPairCompositionService` passes that description only into the still
  HEIC composer, not the MOV composer.
- The composed still HEIC writes stable description metadata through TIFF
  `ImageDescription` and IPTC `CaptionAbstract`.
- Non-ASCII HEIC descriptions are no longer written into EXIF `UserComment`
  when ImageIO would produce corrupted truncated text.

Verification:

```bash
xcodebuild -project Source/PhotoMemo/PhotoMemo.xcodeproj \
  -scheme PhotoMemoTests \
  -destination 'platform=macOS' \
  -only-testing:PhotoMemoTests/LivePhotoStillImageCompositionServiceTests \
  -only-testing:PhotoMemoTests/LivePhotoPairCompositionServiceTests \
  -only-testing:PhotoMemoTests/LivePhotoBatchQueueExecutionTests \
  -only-testing:PhotoMemoTests/ExternalPhotoIntakeCenterTests \
  -only-testing:PhotoMemoTests/PhotoImportServiceTests \
  -only-testing:PhotoMemoTests/MediaOutputPolicyTests \
  -only-testing:PhotoMemoTests/MediaProcessingRouterTests \
  CODE_SIGNING_ALLOWED=NO \
  COMPILER_INDEX_STORE_ENABLE=NO \
  test

git diff --check

xcodebuild -project Source/PhotoMemo/PhotoMemo.xcodeproj \
  -scheme PhotoMemoiOS \
  -destination 'generic/platform=iOS' \
  -configuration Debug \
  -derivedDataPath /tmp/PhotoMemoLivePhotoReviewIOSBuild \
  CODE_SIGNING_ALLOWED=NO \
  COMPILER_INDEX_STORE_ENABLE=NO \
  -quiet build

xcodebuild -project Source/PhotoMemo/PhotoMemo.xcodeproj \
  -scheme PhotoMemoShareExtension \
  -destination 'generic/platform=iOS' \
  -configuration Debug \
  -derivedDataPath /tmp/PhotoMemoLivePhotoReviewShareExtensionBuild \
  CODE_SIGNING_ALLOWED=NO \
  COMPILER_INDEX_STORE_ENABLE=NO \
  -quiet build
```

- Focused tests passed.
- `git diff --check` passed.
- `PhotoMemoiOS` Debug generic iOS build passed.
- `PhotoMemoShareExtension` Debug generic iOS build passed.

Merge-readiness note:

- The main iOS picker path has the strongest evidence for Live Photo adoption
  because it preserves the PhotoKit asset identifier needed for still + MOV
  resource export.
- Share Extension intake has diagnostics and build coverage, but real-device
  Live Photo sharing remains a separate production-validation evidence item.
- UI refinements for failed-item thumbnail/reason presentation remain deferred
  until after Live Photo support is merged into `main`.

## 2026-07-09 Live Photo Release Readiness Review

Current product status:

- `Media Geometry Foundation`: closed
- `Live Photo Main App Picker Pipeline`: release candidate / production
  candidate
- `Share Extension Live Photo`: known limitation and future production
  validation item
- failed-item thumbnail/reason UI: deferred polish, not a merge blocker for the
  main app picker capability

Release review conclusion:

- Live Photo should no longer be described as active feature R&D for the main
  app picker path.
- The correct current label is `Release Readiness Review`.
- Main app picker evidence now covers automatic media routing, motion-preserving
  Live Photo output, static-image output, geometry adoption through
  `CanonicalGeometry`, still/video pairing identity consistency, footer/photo
  geometry consistency, output-description metadata on the composed still image,
  and batch queue routing.

Build matrix passed in the integration worktree:

- `PhotoMemoiOS` Debug generic iOS build
- `PhotoMemoShareExtension` Debug generic iOS build
- `PhotoMemoWidgetExtension` Debug generic iOS build
- `PhotoMemo` Debug macOS build

Focused verification passed:

- `MemoryResultContractTests/batchConfigurationSnapshotRemainsTransportDTOForProductionSemantics`
- `MediaGeometryArchitectureTests`
- `MediaGeometryFoundationCoreTests`
- `LivePhotoVideoCompositionServiceTests`
- `LivePhotoStillImageCompositionServiceTests`
- `LivePhotoVideoMetadataWriterContractTests/revisesMOVMetadataByReplacingPairingContentIdentifier`
- `LivePhotoPairCompositionServiceTests`
- Live Photo asset/identity/readback focused group:
  - `LivePhotoAssetLoaderContractTests`
  - `LivePhotoAssetWriterContractTests`
  - `LivePhotoPairingIdentityVerifierTests`
  - `LivePhotoAssetReadbackVerificationTests`
- media routing/policy/planner/router/runtime-gate focused group
- `PhotoMemoiOSV1PhotoIntakeTests`
- `LivePhotoBatchQueueExecutionTests`
- `ExternalPhotoIntakeCenterTests`

Important test-harness caveat:

- broad `PhotoMemoTests` runs can still hang during Xcode result finalization
- observed Xcode state includes:
  - `waiting for record to finish saving`
  - `Finalize test log`
  - `waiting for workers to materialize`
- interrupting that state can produce exit code `75` and false-looking
  `TEST INTERRUPTED` output
- current focused reruns do not reproduce a stable Live Photo assertion failure

Known non-blocking warnings:

- macOS deployment target is set to `27.0`, while the installed SDK supports up
  to `26.5.99`
- `GeocoderService.swift` still uses APIs deprecated in macOS 26

Git/release caveat:

- branch `codex/ios-livephoto-internal-test` is behind `origin/main` by one
  commit
- the worktree remains intentionally dirty with the Live Photo integration
  diff
- do not merge to `main` until the branch has a clean checkpoint commit and the
  one-commit divergence from `origin/main` has been resolved safely

Recommended next action:

- treat the main app picker Live Photo path as merge-candidate scope after a
  safe commit/rebase or merge-from-main pass
- keep Share Extension Live Photo runtime validation as a separate known
  limitation, not as a blocker for the main app picker release candidate
- avoid reopening Media Geometry Foundation unless runtime evidence proves
  `CanonicalGeometry` itself is wrong

## 2026-07-09 Task Status Terminal History Cleanup Verified

The persistent `需处理 / 待处理` task-page state after successful Live Photo
runtime output has been classified as a queue-history lifecycle issue, not a
Media Geometry Foundation, renderer, composer, or export failure.

Runtime finding:

- Classification: Runtime / task-state projection
- Symptom: the main app task page continued to show `需处理 / 待处理` after the
  Live Photo runtime path had already produced successful output.
- Root cause: old terminal external jobs from pre-fix `PHPhotosErrorDomain 3164`
  runs remained in the persisted App Group queue and were still projected as
  needs-attention history after restart.
- Decision: `清理历史` must clear terminal external jobs, including failed
  retryable histories, while preserving active jobs and in-app preview jobs.
- Foundation changed: No.

Implementation result:

- `PhotoMemoBackgroundStatusService` no longer lets older retryable failure jobs
  mask the latest external job.
- `BatchQueueStore.clearTerminalExternalJobHistory` clears terminal external
  history instead of only completed external jobs.
- Task-page presentation now exposes `清理历史` for terminal snapshots, including
  single failed / unsupported histories.

Verification:

```bash
git diff --check

xcodebuild -project Source/PhotoMemo/PhotoMemo.xcodeproj \
  -scheme PhotoMemoTests \
  -destination 'platform=macOS' \
  -only-testing:PhotoMemoTests/V1SettingsPagePresenterTests \
  -only-testing:PhotoMemoTests/QueueStatusMigrationTests \
  -only-testing:PhotoMemoTests/PhotoMemoBackgroundStatusServiceTests \
  CODE_SIGNING_ALLOWED=NO \
  COMPILER_INDEX_STORE_ENABLE=NO \
  test
```

- Focused tests passed.
- `PhotoMemoiOS` Debug iPhone7 device build passed.
- The build was installed and launched on the connected iPhone7.
- Before cleanup, device evidence showed only old failed terminal jobs, all from
  earlier `PHPhotosErrorDomain 3164` runs.
- After tapping `清理历史`, device evidence showed `batchQueue.jobs` was empty.
- After a process-level app restart, the old failed jobs did not return.
- A pending external-intake request was drained after restart and completed as a
  new `10:57（5张）` job; all five tasks completed successfully and
  `externalIntake.requests` was empty.

Private evidence paths:

- `/tmp/PhotoMemoRuntimeEvidence/20260709-task-status-still-pending-current`
- `/tmp/PhotoMemoRuntimeEvidence/20260709-task-status-terminal-clear-postfix`
- `/tmp/PhotoMemoRuntimeEvidence/20260709-task-status-terminal-clear-relaunch`
- `/tmp/PhotoMemoRuntimeEvidence/20260709-task-status-terminal-clear-process-restart`

## 2026-07-09 MGF-2B Runtime R005 iCloud Resource Export Fixed

MGF-2B runtime validation found and fixed a Runtime-layer Live Photo export
failure without reopening Geometry Foundation.

Runtime finding:

- Classification: Runtime / R005 Export / Import
- Failed phase: `exporting`
- Symptom: iCloud-backed Live Photo `.HEIC` assets failed before geometry or
  composition.
- Error: `PHPhotosErrorDomain 3164`
- Root cause: `3164` is `PHPhotosErrorNetworkAccessRequired`; PhotoKit resource
  export was using default `PHAssetResourceRequestOptions`, so iCloud-backed
  Live Photo MOV resources could not be downloaded before export.

Fix:

- `PhotoKitLivePhotoAssetResourceExporter` now exports resources with
  `PHAssetResourceRequestOptions.isNetworkAccessAllowed = true`.
- Existing paired-video fallback remains in place:
  `fullSizePairedVideo -> pairedVideo`.
- No `CanonicalGeometry`, Geometry Core, Renderer, Composer, or Foundation
  document was modified for this runtime-only failure.

Verification:

```bash
xcodebuild -project Source/PhotoMemo/PhotoMemo.xcodeproj \
  -scheme PhotoMemoTests \
  -destination 'platform=macOS' \
  -only-testing:PhotoMemoTests/LivePhotoAssetLoaderContractTests \
  CODE_SIGNING_ALLOWED=NO \
  COMPILER_INDEX_STORE_ENABLE=NO \
  test
```

- Focused contract tests passed, including the regression guard that PhotoKit
  resource exports allow network access.
- `git diff --check` passed.
- `PhotoMemoiOS` Debug iPhone7 device build passed.
- The build was installed and launched on the connected iPhone7.

Runtime evidence:

- Private evidence directory:
  `/tmp/PhotoMemoRuntimeEvidence/20260709-mgf2b-network-access-progress2`
- Job `3FF84449-DE92-4A2B-A251-77E6A5BBFF0E` processed 11 Live Photos and
  completed successfully.
- All 11 tasks have `phase=completed` and saved asset identifiers.
- The previous `PHPhotosErrorDomain 3164` events remain only on the old
  pre-fix job `BD1F5D7E-59A1-463C-B206-3AE0873F7C32`.

Next validation:

- User should confirm Photos runtime behavior for the newly saved outputs:
  recognition as Live Photo, long-press playback, still-to-video transition,
  and portrait/landscape geometry.

## 2026-07-09 MGF-2A Geometry Adoption Completed

MGF-2 has been split into two implementation stages:

```text
MGF-2A: Geometry Adoption Completion
MGF-2B: Runtime Validation
```

Closed milestones:

- MGF-0 Foundation Freeze: Closed
- MGF-1 Geometry Core Implementation: Closed
- MGF-2A Geometry Adoption Completion: Closed

MGF-2A is complete. The first production consumer has accepted the Geometry
Foundation boundary: Live Photo composition no longer owns duplicated geometry
logic and now consumes `CanonicalGeometry` for composition decisions.

What changed:

- `LivePhotoGeometryResolver` now adapts MGF-1 `MediaGeometryResolver` facts
  into the Live Photo composition path.
- Live Photo pair composition resolves `CanonicalGeometry` once before still
  and video composition.
- The same `CanonicalGeometry` value is passed to still and video pairing
  composers.
- Still and video pairing composition use `geometry.canvas` to construct their
  effective composition overlay.
- The V1 renderer footer image content remains sourced from the existing
  rendered overlay, preserving current footer visual rules.
- Composer architecture guardrails remain active: composers no longer observe
  `CGImageSource`, `PHAsset`, `AVAssetTrack`, `naturalSize`, or
  `preferredTransform`.

Important architecture rule frozen during review:

```text
API shape is not Architecture Adoption.
```

`CanonicalGeometry` appearing in a function signature is not enough. Adoption
requires the consumer to remove duplicated domain logic and make composition
decisions from the Foundation truth.

MGF-2A completion rule:

```text
A Foundation is not proven by its implementation. It is proven by the first
consumer that no longer owns the same domain logic.
```

MGF-2A Adoption Review Checklist:

- [x] Consumer no longer derives Geometry Truth.
- [x] Consumer receives Geometry Truth.
- [x] Consumer uses Geometry Truth for canvas/photo/footer composition frames.
- [x] Consumer does not recreate Geometry Truth between resolver and composer.
- [x] Legacy composer media-observation logic is protected by architecture
  tests.

Focused verification passed:

```bash
xcodebuild -project Source/PhotoMemo/PhotoMemo.xcodeproj \
  -scheme PhotoMemoTests \
  -destination 'platform=macOS' \
  -only-testing:PhotoMemoTests/LivePhotoPairCompositionServiceTests \
  -only-testing:PhotoMemoTests/LivePhotoVideoCompositionServiceTests \
  -only-testing:PhotoMemoTests/LivePhotoStillImageCompositionServiceTests \
  -only-testing:PhotoMemoTests/MediaGeometryArchitectureTests \
  CODE_SIGNING_ALLOWED=NO \
  COMPILER_INDEX_STORE_ENABLE=NO \
  test
```

Debug build passed:

```bash
xcodebuild -project Source/PhotoMemo/PhotoMemo.xcodeproj \
  -scheme PhotoMemo \
  -configuration Debug \
  -derivedDataPath /tmp/PhotoMemoMGF2BRouteBuild \
  CODE_SIGNING_ALLOWED=NO \
  COMPILER_INDEX_STORE_ENABLE=NO \
  -quiet build
```

Known environment warning remains:

- Xcode reports the current macOS deployment target as `27.0`, while the
  installed SDK supports up to `26.5.99`; tests still pass.

MGF-2 is not complete yet. Remaining work belongs to MGF-2B Runtime Validation.

MGF-2B mission:

```text
Prove Media Geometry Foundation holds in the iOS Photos Runtime.
```

Runtime validation principle:

```text
Runtime Validation validates runtime behavior. It never redesigns Foundation.
```

MGF-2B is a Runtime Sprint, not a refactor sprint. Do not optimize or reshape
implementation code unless a runtime failure has first been reproduced and
classified.

Runtime quality discipline:

```text
One runtime failure, one root cause.
```

Investigate one failing runtime scenario at a time. Do not bundle portrait,
landscape, metadata, footer, animation, and playback changes into one fix.

Required first question for every runtime finding:

```text
Is Truth wrong, or is the Consumer wrong?
```

Foundation change burden:

```text
Do not ask whether Foundation should change. Prove CanonicalGeometry is wrong.
```

If that proof is missing, the finding must remain Runtime or Composition.

MGF-2B issue triage order:

1. Runtime bug:
   Photos recognition, pairing identity, MOV pairing, long-press playback,
   export/import, or runtime metadata behavior.
2. Composition bug:
   Footer, overlay, canvas, crop, stretch, or transition geometry after
   `CanonicalGeometry` has already been consumed.
3. Foundation bug:
   Only when evidence proves `CanonicalGeometry`, the resolver, or the linter
   produced incorrect truth.

Issue classification:

| Area | Code | Meaning |
|---|---|---|
| Runtime | R001 | Pairing |
| Runtime | R002 | Photos Recognition |
| Runtime | R003 | Playback |
| Runtime | R004 | Transition |
| Runtime | R005 | Export / Import |
| Runtime | R006 | Runtime Metadata |
| Composition | C001 | Footer |
| Composition | C002 | Overlay |
| Composition | C003 | Canvas |
| Composition | C004 | Crop / Stretch |
| Foundation | F001 | Canonical Geometry |
| Foundation | F002 | Resolver |
| Foundation | F003 | Linter |

RuntimeValidationChecklist:

- [ ] Photos recognizes the output as a Live Photo.
- [ ] Still image and MOV pairing identity remains intact.
- [ ] Long-press playback works.
- [ ] Still-to-motion transition is visually stable.
- [ ] Portrait Live Photo output remains portrait.
- [ ] Portrait Live Photo output is not stretched.
- [ ] Footer remains fixed and visually consistent with V1 renderer output.
- [ ] Static JPEG/HEIC output behavior remains unchanged.
- [ ] Simulator smoke is used only for UI/static routing regressions.
- [ ] Final acceptance is performed on the connected iPhone Photos runtime.

Runtime Regression Matrix:

| Validation | Portrait | Landscape |
|---|---|---|
| Recognized by Photos | [ ] | [ ] |
| Long press playback | [ ] | [ ] |
| Still-to-motion transition | [ ] | [ ] |
| Footer fixed and aligned | [ ] | [ ] |
| No stretch | [ ] | [ ] |
| Static export unchanged | [ ] | [ ] |

Fixed device validation order:

1. Import Live Photo.
2. Export Live Photo.
3. Verify Photos recognition.
4. Verify long-press playback.
5. Verify still-to-motion transition.
6. Verify footer geometry.
7. Verify portrait output.
8. Verify landscape output.

Stop on the first failed runtime pipeline step. For example, if Photos does not
recognize the output as a Live Photo, do not continue to long-press playback,
transition, footer, portrait, or landscape validation.

Runtime Report format:

```text
Runtime Validation

[ ] Live Photo Recognized
[ ] Asset Identifier Match
[ ] Long Press Playback
[ ] Still-to-Video Transition
[ ] Geometry Hash Match
[ ] Footer Bounds Match
[ ] Portrait OK
[ ] Landscape OK

Issue:
Classification:
Code:
Layer:
Root Cause:
Decision:
Foundation Changed: No
```

MGF-2B Stop Rule:

```text
MGF-2B ends when all runtime failures can be classified without changing
Foundation.
```

MGF-2B Exit Gates:

- Gate 1: Foundation is not modified for runtime-only failures.
- Gate 2: Every issue is classified as Runtime, Composition, or Foundation.
- Gate 3: Runtime Regression Matrix passes for the accepted validation scope.
- Gate 4: Runtime behavior is stable on the connected iPhone Photos runtime.

Runtime Evidence:

- Runtime reports live under
  `Docs/Foundations/MediaGeometry/RuntimeReports/`.
- Private `.heic`, `.mov`, screenshots, and screen recordings must not be
  committed.
- Store private evidence outside the repository and record only safe paths,
  hashes, dimensions, and conclusions.

Suggested daily scope:

- Day 1: Portrait Runtime.
- Day 2: Landscape Runtime.
- Day 3: Playback Transition.
- Day 4: Runtime Metadata Validation.

## 2026-07-08 MGF-1 Complete and MGF-2 Boundary Frozen

MGF-1 is complete against the frozen Exit Criteria.

Formal conclusion:

```text
MGF-1 is complete: Media Geometry Core has established the unique,
JSON-snapshot-verifiable CanonicalGeometry foundation layer.
```

Implemented Geometry Core:

- `CanonicalGeometry`
- `MediaGeometryFacts`
- `CanvasGeometry`
- `MediaGeometryOrientation`
- `MediaGeometryResolver`
- `GeometryIssue`
- `GeometryLinter`
- `GeometrySnapshotSerializer`

Implementation boundary preserved:

- no Live Photo composer changes
- no renderer changes
- no exporter changes
- no Overlay adoption
- no UIKit or SwiftUI dependency in Geometry Core
- no AVFoundation dependency in Geometry Core

The first resolver consumer is now JSON Geometry Snapshot.

Focused verification passed:

```bash
xcodebuild -project Source/PhotoMemo/PhotoMemo.xcodeproj \
  -scheme PhotoMemoTests \
  -destination 'platform=macOS' \
  -only-testing:PhotoMemoTests/MediaGeometryFoundationCoreTests \
  CODE_SIGNING_ALLOWED=NO \
  COMPILER_INDEX_STORE_ENABLE=NO \
  test
```

Covered cases:

- portrait JPEG stable JSON snapshot
- landscape JPEG stable JSON snapshot
- portrait HEIC stable JSON snapshot
- landscape HEIC stable JSON snapshot
- HEIC Orientation Right display-space resolution
- HEIC Orientation Left display-space resolution
- machine-readable linter issue code
- source dependency guard for Geometry Core imports

Known environment warning:

- Xcode reports the current macOS deployment target as `27.0`, while the
  installed SDK supports up to `26.5.99`; tests still pass.

Next MGF-1 work should stay inside Geometry Core unless implementation feedback
requires a narrow adjustment. Live Photo adoption remains paused until the
Geometry Core result is reviewed and accepted.

MGF-2 is now the next implementation boundary:

```text
MGF-2: Live Photo Geometry Adoption
```

MGF-2 mission:

```text
Adopt Geometry Truth through the first real production consumer.
```

MGF-2 architecture guardrails:

```text
Live Photo Composer consumes CanonicalGeometry. It never derives geometry.

Live Photo Composer never observes media. It only observes composition inputs.
```

MGF-2 scope:

- resolve still-image geometry before composer entry
- pass the same `CanonicalGeometry` into still and video composition
- derive footer/canvas placement from display-space geometry
- preserve existing V1 static-image routing and output behavior
- verify the current portrait Live Photo horizontal/stretch regression through
  tests before changing composer behavior

MGF-2 non-goals:

- output format UI redesign
- metadata policy redesign
- RAW/HDR/ProRAW adoption
- general video export support
- renderer visual polish unrelated to geometry

MGF-2 acceptance target:

- portrait Live Photo output remains portrait
- portrait Live Photo output is not stretched
- landscape Live Photo output remains landscape
- still and video composition consume the same `CanonicalGeometry`
- composer code does not parse EXIF orientation, inspect `AVAssetTrack`, infer
  from `naturalSize` or `preferredTransform`, or swap width/height locally
- composer code does not inspect `CGImageSource`, raw image properties,
  `PHAsset`, `AVAsset`, or source media objects
- dependency acceptance proves composer has no direct `ImageIO`, `PhotoKit`, or
  media-observation `AVFoundation` dependency
- geometry consistency acceptance proves Resolver output equals Composer input
  without reconstructing another `CanonicalGeometry`
- static JPEG/HEIC output behavior remains unchanged
- focused tests and Debug build pass
- final acceptance is real iPhone Photos recognition and long-press playback

## 2026-07-08 MGF-0 Complete: Media Geometry Foundation Freeze

The Live Photo portrait regression has been elevated from a Live Photo-specific
bug to a media-pipeline foundation issue.

Foundation status:

- `Media Geometry Foundation`
- MGF-0 Foundation Freeze: `Completed`
- MGF-1 Geometry Core Implementation: `Completed`
- MGF-2 Live Photo Geometry Adoption: `Boundary frozen / next`

Architecture status:

| Layer | Item | Status |
|---|---|---|
| Production Ready | iOS V1 release line | Active |
| Foundations | Configuration Foundation | Accepted |
| Foundations | Memory Expression Foundation | Accepted |
| Foundations | Production Media Pipeline | In progress |
| Foundations | Media Geometry Foundation | MGF-0 completed |
| Implementations | Geometry Core | MGF-1 completed |
| Implementations | Live Photo Geometry Adoption | MGF-2 boundary frozen / next |

Canonical architecture documents:

- `Docs/Foundations/README.md`
- `Docs/Foundations/MediaGeometry/Manifest.md`
- `Docs/02_Architecture/RFC-002-Media-Geometry-Foundation.md`
- `Docs/ADR/ADR-008-MediaGeometryFoundation.md`
- `Docs/Foundations/MediaGeometry/README.md`
- `Docs/Foundations/MediaGeometry/GeometryConstitution.md`
- `Docs/Foundations/MediaGeometry/FoundationChecklist.md`

Frozen principles:

- Geometry is a property of media, not Renderer, Composer, or Exporter.
- Geometry is resolved once, consumed everywhere.
- `CanonicalGeometry` is the only cross-module Geometry Truth and is immutable.
- Geometry verification uses Geometry Linter and JSON Geometry Snapshot, not
  downstream runtime correction.

Implementation boundary:

- The first consumer of Geometry Resolver must be Geometry Snapshot, not Live
  Photo Composer.
- Ordinary JPEG/HEIC still-image geometry must be stable before Live Photo
  composer migration resumes.
- No further Live Photo-specific geometry patch should be applied until
  Geometry Models, Resolver, Linter, and Snapshot are in place.

MGF-1 acceptance target:

- Produce stable JSON-snapshot-verifiable `CanonicalGeometry` for ordinary
  JPEG/HEIC still images.
- Start with portrait HEIC, landscape HEIC, Orientation Right, and Orientation
  Left.
- Add portrait JPEG and landscape JPEG snapshot stability before adoption work.
- Keep `GeometrySnapshotSerializer` pure: input is `CanonicalGeometry`, not
  image or asset objects.
- Keep `GeometryLinter` pure: input is `CanonicalGeometry`, output is
  `[GeometryIssue]`.
- Do not modify Live Photo composer, renderer, or exporter during the first
  Geometry Core implementation slice.

MGF-1 mission:

```text
MGF-1 does not render anything. It proves that MemoMark can derive one
immutable Geometry Truth from a still image.
```

## 2026-07-08 iOS settings About content expanded for TestFlight

The iOS homepage settings sheet now behaves more like a lightweight About and
TestFlight information surface.

What changed:

- settings content order now follows a clearer About-page rhythm:
  - About MemoMark
  - version and Xcode Cloud build-number note
  - supported input/output scope
  - post-1.5 development plan
  - feedback channels
  - usage guide
  - current principles
- feedback channels now include:
  - TestFlight built-in feedback
  - email
  - Xiaohongshu ID `49956456623` for contact and group discussion
  - GitHub Issues for public reproducible issues
- the 1.6 plan explicitly includes Live Photo support as the next-version
  focus while 1.5 remains scoped to static-photo validation

Verification passed:

- `git diff --check`
- project file lint
- `PhotoMemoiOS` Debug generic iOS Simulator build

Not manually verified:

- visual inspection on a physical iPhone after opening the settings sheet

## 2026-07-08 Xcode Cloud build-number ownership clarified

The app's user-facing release version remains:

- `MARKETING_VERSION = 1.5`

The App Store Connect / Xcode Cloud build counter has already reached build
`13` after repeated workflow/apply/cancel attempts consumed intermediate build
numbers.

Current release interpretation:

- user-facing version: `1.5`
- TestFlight build number: owned by Xcode Cloud / App Store Connect
- current observed cloud build number: `13`
- next successful cloud attempt is expected to appear as build `14`

What changed:

- V1.5 TestFlight release materials no longer treat the next cloud build number
  as a manually owned repository value
- tester-facing material describes the release as MemoMark `1.5`
- App Store Connect materials record that the cloud build number is currently
  `13` and the next expected successful build is `14`

Release guidance:

- keep `MARKETING_VERSION = 1.5`
- let Xcode Cloud / App Store Connect own the visible TestFlight build number
  for cloud-produced builds
- if another cloud attempt consumes build `14`, do not change the user-facing
  version unless the submitted release scope changes

## 2026-07-08 iOS release entry unified as PhotoMemoiOS

The old parallel iOS app-target setup has been cleaned up after the
TestFlight/Xcode Cloud packaging path moved past the `PhotoMemoiOSV1` naming
phase.

Current iOS release/build rule:

- use the single `PhotoMemoiOS` scheme/target for local device builds, Xcode
  Cloud, TestFlight, and future archive work
- track product progress through `MARKETING_VERSION` and
  `CURRENT_PROJECT_VERSION`, not through target names
- keep the App Store bundle identifier stable:
  `com.serydoo.PhotoMemo.iOS`

What changed:

- removed the duplicate legacy iOS app target from the Xcode project
- renamed the active `PhotoMemoiOSV1` release scheme to `PhotoMemoiOS`
- renamed the active iOS Info.plist to `PhotoMemoiOS-Info.plist`
- removed the obsolete `PhotoMemoiOSV1App.swift` entry file
- preserved the existing app display name, bundle identifier, entitlements,
  Share Extension embedding, Widget Extension embedding, and version/build
  values

Verification passed:

- project file lint passed
- `xcodebuild -project Source/PhotoMemo/PhotoMemo.xcodeproj -list` now shows
  one iOS app target/scheme: `PhotoMemoiOS`
- `PhotoMemoiOS` Debug generic iOS Simulator build passed
- `PhotoMemoiOS` Debug generic iOS build passed
- `PhotoMemoiOS` signed Debug iPhone7 device build passed
- iPhone7 install passed through `devicectl`
- iPhone7 launch passed through `devicectl`
- built app inspection confirmed:
  - `CFBundleDisplayName = 时光记`
  - `CFBundleIdentifier = com.serydoo.PhotoMemo.iOS`
  - version/build = `1.5` / `7`
  - `PhotoMemoShareExtension.appex` is embedded
  - `PhotoMemoWidgetExtension.appex` is embedded
  - app and Share Extension privacy manifests are present

Not completed:

- a local Release generic iOS build was attempted, but Xcode entered an
  internal idle operation wait and was interrupted without compile errors

## 2026-07-08 TestFlight build 6 invalid; Xcode Cloud build 7 planned

Apple rejected the uploaded `1.5` / `6` binary during automated processing,
before human App Review, with:

- `ITMS-90111: Unsupported SDK or Xcode version`

Local inspection showed the IPA was built with:

- `DTXcodeBuild = 17F113`
- `DTSDKName = iphoneos26.5`
- `BuildMachineOSBuild = 26A5378j`

The likely blocker is that the local archive was produced on `macOS 27.0`
beta, which writes the beta OS build into the binary metadata. The next
release attempt should not be archived locally from this beta macOS machine.

Current release direction:

- use Xcode Cloud to build from GitHub in Apple's supported cloud environment
- raise `CURRENT_PROJECT_VERSION` from `6` to `7`
- keep marketing version at `1.5`
- select build `7` in App Store Connect and resubmit after Xcode Cloud uploads
  the processed build

## 2026-07-07 TestFlight 1.5 build 6 ready IPA prepared with Xcode 26.6

The first TestFlight-ready local package accepted for manual upload preparation
after reinstalling the App Store Xcode line has been prepared as build
`1.5` / `6`.

Packaging output:

- archive:
  `/Users/rui/Desktop/时光记_1.5_build6_xcode26_upload/TimeMemo-1.5-6.xcarchive`
- exported IPA:
  `/Users/rui/Desktop/时光记_1.5_build6_xcode26_upload/export/PhotoMemoiOS.ipa`
- manual-upload export options:
  `/Users/rui/Desktop/时光记_1.5_build6_xcode26_upload/export_options_manual_upload.plist`

What changed in the repository:

- added `INFOPLIST_KEY_CFBundleDisplayName = "时光记"` to the active
  `PhotoMemoiOS` target Debug and Release build settings
- this fixes the previously exported package where the main app Info.plist
  still exposed `CFBundleName = PhotoMemoiOS` and no display-name override
- adjusted the Xcode project compatibility metadata back to the App Store
  Xcode line after the project had been opened by the beta Xcode
- raised `CURRENT_PROJECT_VERSION` to build `6`
- fixed two Xcode 26.6 Swift compile issues in the current UI/history code

App icon status:

- prepared desktop icon:
  `/Users/rui/Desktop/PhotoMemo_Release_AppIcon/PhotoMemo-AppStoreIcon-1024.png`
- project App Store icon:
  `Source/PhotoMemo/PhotoMemo/Assets.xcassets/AppIcon.appiconset/appicon-ios-marketing.png`
- both files are `1024x1024`, have no alpha channel, and share the same
  SHA-256:
  `af9374a11d4ea7dc015ee0c8dd78668da1a30f78a2a2a1050b63a329238ed1b5`

Verification:

- project file lint passed
- Xcode 26.6 Debug simulator build passed
- Xcode 26.6 Release archive passed with `-allowProvisioningUpdates`
- App Store Connect local export passed without direct upload
- final IPA package checks passed:
  - `CFBundleDisplayName = 时光记`
  - `CFBundleIdentifier = com.serydoo.PhotoMemo.iOS`
  - version/build = `1.5` / `6`
  - `DTXcodeBuild = 17F113`
  - `DTSDKName = iphoneos26.5`
  - app and Share Extension privacy manifests are embedded
  - exported signing certificate is `Cloud Managed Apple Distribution`
  - app and embedded extensions use Store provisioning profiles
  - exported entitlements have `get-task-allow = false`

Recommended next action:

- upload
  `/Users/rui/Desktop/时光记_1.5_build6_xcode26_upload/export/PhotoMemoiOS.ipa`
  through Transporter or Xcode Organizer for the next TestFlight attempt

## 2026-07-07 Product brand renamed to MemoMark / 时光记

This branding slice updates the external product identity from PhotoMemo to:

- English: `MemoMark`
- Chinese: `时光记`

What changed:

- app-facing display names now use `时光记`
- Share Extension display name now uses `时光记分享`
- Widget/Live Activity display name now uses `时光记 Live`
- user-facing Chinese app copy now uses `时光记`
- English docs, privacy policy, and TestFlight/App Review materials now use
  `MemoMark`
- generated output file fallbacks and export metadata software now use
  `MemoMark`
- `memomark://share` is now the generated deep link
- `photomemo://share` remains accepted as a compatibility alias

Intentionally preserved for project stability:

- Bundle IDs under `com.serydoo.PhotoMemo...`
- App Group identifier `group.com.serydoo.PhotoMemo`
- Xcode target, scheme, module, source folder, and Swift type names
- existing `photomemo.*` UserDefaults keys and internal compatibility markers
- GitHub repository URL and local path names

## 2026-07-07 TestFlight upload reached App Store Connect

The App Store Connect app record now exists for the iOS app bundle ID:

- `com.serydoo.PhotoMemo.iOS`

This cleared the previous local upload blocker:

- `IDEDistribution.DistributionAppRecordProviderError.missingApp`

The first upload attempt for local build `1.5` / `5` reached App Store
Connect, but Apple rejected the upload during server-side processing because
the archive was built with an unsupported SDK or Xcode version.

Current TestFlight blocker:

- rebuild/archive/upload with a currently supported Xcode and SDK version

Release materials prepared in this slice include:

- public privacy policy at `PRIVACY.md`
- TestFlight/App Store Connect materials under
  `Docs/07_Releases/V1.5-TestFlight/`
- TestFlight upload export options at `scripts/export_options_testflight.plist`

## 2026-07-07 TestFlight privacy-manifest readiness check

This release-readiness slice closed the most file-like TestFlight blocker found
in the local project: missing privacy manifests for the app and Share
Extension.

What changed:

- added an app privacy manifest at `Source/PhotoMemo/PhotoMemo/PrivacyInfo.xcprivacy`
- added a Share Extension privacy manifest at
  `Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PrivacyInfo.xcprivacy`
- declared required-reason API usage for:
  - UserDefaults in the app and Share Extension
  - file timestamp access in the main app
- declared no tracking and no collected data types in both manifests
- excluded the Share Extension manifest from main-app synchronized target
  membership so it is copied only into the extension bundle and not duplicated
  by app targets

Verification:

- `plutil -lint` passed for the project file and both privacy manifests
- `git diff --check` passed
- `PhotoMemoShareExtension` iOS Simulator target build passed with signing
  disabled
- `PhotoMemoiOS` iOS Simulator target build passed with signing disabled
- built products contain:
  - `PhotoMemoiOS.app/PrivacyInfo.xcprivacy`
  - `PhotoMemoiOS.app/PlugIns/PhotoMemoShareExtension.appex/PrivacyInfo.xcprivacy`
- Release archive passed with `-allowProvisioningUpdates`
- local App Store Connect export passed without uploading
- exported IPA is signed with `Cloud Managed Apple Distribution`
- Store provisioning profiles were generated for:
  - `com.serydoo.PhotoMemo.iOS`
  - `com.serydoo.PhotoMemo.iOS.ShareExtension`
  - `com.serydoo.PhotoMemo.iOS.WidgetExtension`
- exported app and embedded extensions have `get-task-allow = false`

Remaining TestFlight blockers:

- local keychain still shows only an Apple Development identity, but Xcode
  successfully used Cloud Managed Apple Distribution during export
- direct App Store Connect upload has not yet been executed
- version/build numbers are now set to `1.5` / `5`
- App Store Connect listing/test information and tester-facing instructions
  are prepared under `Docs/07_Releases/V1.5-TestFlight/`

## 2026-07-07 V1 subject-switch preview draft synchronization fixed

This slice fixed the remaining V1 iOS risk where switching Memory Subjects
could align the current Preset but leave renderer preview content partially
stale, defaulted, or missing.

Root cause:

- `ConfigurationSession.selectSubject` aligned the selected Memory Preset to
  the new subject, but the subject-switch alignment path did not rebuild the
  four region preview texts the same way explicit Preset selection did.
- The V1 subject overview patch refreshed ordinary preview state only in some
  cases, but it did not tell `PhotoMemoiOSV1View` to rebuild the local
  `regionDrafts` that feed the visible renderer preview.

What changed:

- subject-to-Preset alignment now rebuilds region preview texts from the
  selected subject's configuration
- switching, adding, or deleting a Memory Subject now emits a
  `rebootstrapPreviewDrafts` one-shot event
- those subject-switch patches also carry the newly selected subject's active
  time-anchor date so smart-time preview rebuilding does not reuse the previous
  object's date context
- `PhotoMemoiOSV1View` consumes that event by bootstrapping editor drafts from
  the selected subject/Preset before refreshing the renderer preview
- ordinary subject editor saves still use refresh-only behavior so they do not
  wipe the user's current region draft editing state

Verification:

- `git diff --check` passed
- focused tests passed:
  - `ConfigurationSessionConfigurationLifecycleTests`
  - `V1SubjectLibrarySupportTests`
- `PhotoMemoiOS` iOS Simulator build passed
- `PhotoMemoiOS` generic iOS build passed

Not yet manually verified:

- iPhone7 install was not attempted in this slice because the connected device
  list reported `iPhone7` as unavailable

## 2026-07-07 V1 output configuration boundary documented

This documentation slice formalized the V1 output-configuration boundary after
the Memory Subject switch confirmation fix.

What changed:

- added `Docs/02_Architecture/V1_Output_Configuration_Boundary_2026-07-07.md`
- documented the two current output-configuration layers:
  - Preset-scoped presentation output in `ConfigurationSession` / `MemoryPreset`
  - production output destination in `V1IOSOutputTarget`, resolved album
    selection, shared settings, and `BatchConfigurationSnapshot`
- froze the rule that browsing Memory Subjects only changes display context,
  while production behavior changes only after `保存为当前配置` succeeds
- clarified that switching to a subject with no configurations must clear stale
  current-configuration display state instead of falling back to another
  subject's Preset
- recorded the current ambiguity that `MemoryPreset.storageOption` is not the
  same thing as the actual iOS album destination

Verification:

- documentation/code-path review covered:
  - `ConfigurationSession`
  - V1 output page state
  - V1 configuration apply/save coordinators
  - bootstrap projection
  - `BatchConfigurationSnapshotProvider`
  - related regression tests
- no production code changed in this slice

## 2026-07-07 V1 memory-subject switch confirmation fixed

This slice fixed the confusing V1 iOS subject-switch behavior where the
Memory Subject sheet implied horizontal browsing could switch the active
subject, while the app only changed the active subject after an explicit card
tap. It also closed the state gap where switching to a subject without any
bound configuration could leave the previous subject's current configuration
temporarily visible.

What changed:

- the Memory Subject sheet now separates browsing from activation:
  - default state is object browsing only
  - `切换` enters explicit switch mode
  - card taps select a candidate only while switch mode is active
  - `保存切换` commits the selected subject through the existing subject
    selection path
- current-configuration state now clears stale selected preset IDs when the
  newly selected subject has no available configurations
- the homepage/current configuration title now shows a clear empty state for
  subjects without configurations instead of falling back to another subject's
  preset
- regression coverage was added for switching to a subject without
  configurations

Verification:

- `git diff --check` passed
- focused tests passed:
  - `ConfigurationSessionConfigurationLifecycleTests`
  - `V1SubjectLibrarySupportTests`
- `PhotoMemoiOS` iOS Simulator build passed

Not yet manually verified:

- physical-device interaction pass for:
  - browse objects by horizontal scrolling
  - tap `切换`
  - choose another object
  - tap `保存切换`
  - return to homepage and confirm the current configuration belongs to that
    object or shows the no-configuration empty state

## 2026-07-07 V1 smart-module selected-subject projection fixed

This slice fixed the remaining real-device issue where Configuration Center
preview could show the selected Memory Subject correctly, but actual output
from the Share/queue path could still render the default `家人` subject inside
the smart module.

Root cause:

- smart modules such as `{{memory_summary}}` are recomputed in production by
  `ProductionMemoryResolver`, not directly copied from preview text
- the full app snapshot carries the selected `MemorySubject`, but Share
  Extension transport can only carry a degraded `BatchConfigurationSnapshot`
- that degraded snapshot still contains `memorySubjectText`, which is the
  selected subject identity projection written from
  `MemorySubject.resolvedExpressionSubjectText`
- the production fallback ignored that projection and rebuilt a default
  `PersonalProfile()`, whose default relationship label is `家人`

What changed:

- production fallback now resolves in this order:
  - canonical frozen `ConfigurationSnapshot`
  - legacy frozen `MemorySubject`
  - selected subject identity projection from transport `memorySubjectText`
  - final safe default profile
- the fallback helper was named around the transport subject projection so the
  source is explicit and does not look like arbitrary free text
- regression tests now cover both:
  - `ProductionMemoryResolver` recovering the selected subject projection
  - `RecordCardBuildService` producing final `{{memory_summary}}` output
    without `家人`

Verification:

- `git diff --check` passed
- focused tests passed:
  - `ProductionMemoryResolverTests`
  - `RecordCardBuildServiceTests`
- `PhotoMemoiOS` generic iOS build passed
- iPhone7 real-device signed build passed
- install to iPhone7 succeeded
- automatic launch was blocked by iOS trust/signature policy; the app is
  installed, but the device must trust the developer profile before launch

## Architecture Progress

IA-003 is treated as Production Pipeline Convergence. Its goal is not to create
new architecture, but to complete the convergence of the accepted architecture
around one frozen production input path.
The V1 Architecture Review document is now frozen unless a new ADR is accepted
or IA-003 Completion Criteria change.

| Area | Status | Notes |
| --- | --- | --- |
| Renderer Contract | ✅ Frozen | Renderer remains the locked V1 output contract. |
| Production Freeze Line | ✅ Phase 1 Complete | Production now prefers frozen Memory input over live defaults. |
| Frozen MemorySubject | ✅ Complete | App production snapshots freeze the saved Configuration Center `MemorySubject`. |
| Frozen ConfigurationSnapshot | ✅ Complete (App Pipeline) | App production snapshots carry a frozen `ConfigurationSnapshot`. |
| Structured MemoryResult | ✅ Engine Boundary Complete | `MemoryExpressionEngine` now exposes `MemoryResult` as its output boundary. |
| Snapshot Convergence | ✅ Production Converged | New app snapshots embed MemorySubject in `ConfigurationSnapshot`; production paths consume `canonicalProductionSnapshot`; legacy DTO fields and frozen compatibility writes are behind named projections/helpers. |
| Live Defaults Cleanup | ✅ Production Pipeline Closed | App and Share Extension `RecordCardBuildService` plus `ProductionMemoryResolver` no longer read runtime `UserDefaults`; legacy fallback uses only DTO input plus safe defaults. |
| Naming Freeze | ⬜ Post IA-003 | Engineering hygiene after IA-003 completion. |
| Legacy Cleanup | ⬜ Post IA-003 | Old DTOs, stubs, and naming cleanup remain maintenance work, not IA-003 exit criteria. |
| Testing Infrastructure | 🟡 Remaining | Full-suite parallel run still has two independently passing flaky/order-sensitive tests. |

## IA-003 Milestones

| Milestone | Status |
| --- | --- |
| Production Freeze Line Phase 1 | ✅ Complete |
| Structured `MemoryResult` | ✅ Engine Boundary Complete |
| Snapshot Convergence | ✅ Production Converged |
| Production Runtime Cleanup | ✅ Complete |
| IA-003 Completion | ✅ Complete |

## IA-003 Completion Criteria

| Criterion | Status |
| --- | --- |
| Production Pipeline consumes only frozen input | ✅ Complete |
| Memory Engine outputs structured `MemoryResult` | ✅ Complete |
| `ConfigurationSnapshot` is the single production Snapshot | ✅ Complete for Memory Production |
| `BatchConfigurationSnapshot` is Legacy / Transport DTO only | ✅ Complete for Memory Production |
| Production Pipeline no longer depends on runtime configuration | ✅ Complete |
| Naming Freeze is complete | ⬜ Post IA-003 |
| Renderer Contract remains stable with no new runtime-state dependency | ✅ Maintained |

## 2026-07-07 V1 subject nickname output parity fixed

This slice fixed the remaining V1 issue where Configuration Center preview
could show the selected subject nickname correctly, but actual production
output still rendered legacy relationship copy such as `家人`.

Root cause:

- the V1 `对象昵称` insertable module displayed `subject_nickname` in the UI,
  but saved `{{relationship_label}}` as the renderer token
- production `MetadataContext` did not expose a separate
  `subject_nickname` value, so nickname and relationship-label semantics were
  conflated
- after changing the module token, the preview draft needed one additional
  guard so `{{subject_nickname}}` remains a dynamic production token instead
  of being folded into the current literal preview text

What changed:

- added `MetadataContext.Key.subjectNickname`
- `RecordCardBuildService` now projects the frozen `MemorySubject` short
  name/display name into `subject_nickname`
- V1/iOS subject nickname module tokens now save `{{subject_nickname}}`
  instead of `{{relationship_label}}`
- added regression coverage for:
  - V1 subject nickname module saved token
  - production output resolving `{{subject_nickname}}` as `途途` while keeping
    `{{relationship_label}}` as `家人`

Verification:

- `git diff --check` passed
- focused regression tests passed:
  - `PreviewCompositionMigrationTests.subjectNicknameModuleSavesProductionNicknameToken`
  - `RecordCardBuildServiceTests.productionOutputResolvesSubjectNicknameSeparatelyFromRelationshipLabel`
- related regression suites passed:
  - `PreviewCompositionMigrationTests`
  - `ConfigurationCenterPreviewCompositionHelperTests`
  - `RecordCardBuildServiceTests`
  - `ProductionMemoryResolverTests`
- iPhone7 real-device `PhotoMemoiOS` build succeeded
- install to iPhone7 succeeded
- automatic launch was blocked only because the device was locked

## 2026-07-07 V1 iOS UI optimization checkpoint completed

This checkpoint consolidates the visible V1 iOS four-tab surface after the
latest physical-device feedback round.

What changed:

- the active iOS root surface is the V1 four-tab shell:
  - `首页`
  - `配置中心`
  - `输出`
  - `任务`
- homepage now focuses on:
  - product identity
  - selected Memory Subject
  - compact current configuration
  - four quick actions
- settings/help moved out of the bottom tab and into the homepage top-right
  settings entry
- rightmost bottom tab is now `任务`, showing current processing and recent
  records
- Configuration Center now uses a sticky preview plus compact one-row option
  controls for:
  - avatar / Logo identity
  - time anchor
  - location display
  - memory display
  - border style
- Configuration Center save/create actions remain bottom-only
- saving the current configuration now writes the active `MemoryPreset` back to
  the selected subject so the homepage current-configuration card refreshes
- production save request building now preserves the selected subject's active
  time-anchor date, preventing output from falling back to stale memory copy
  such as legacy `家人`
- task thumbnails were simplified to avoid overlapping icon/card layers on
  smaller physical-device screens
- final review cleanup fixed a state-regression risk where restoring a saved
  configuration could be marked pending again by normal dirtying setters
- homepage cleanup removed dead recent-record/task callback plumbing after
  recent records moved to the `任务` tab

Verification:

- focused V1 UI/configuration tests passed
- `RecordCardBuildServiceTests` passed, including preview/export memory
  expression regression coverage
- iOS Simulator build passed
- iPhone7 real-device build and install passed
- automatic real-device launch was attempted after install but blocked because
  the device was locked

Scope boundary:

- this checkpoint stayed in V1 iOS UI/state wiring
- renderer drawing, export implementation, metadata extraction,
  share-extension behavior, and photo-library behavior were not changed

## 2026-07-06 P0 runtime-surface and dirty-path convergence completed

This slice closes two high-priority V1 maintenance findings without mixing in
the later P1/P2 cleanup work:

1. main iOS runtime no longer exposes dual product surfaces
2. bootstrap/programmatic subject restore no longer reuses the same dirty
   pipeline as user edits

What changed:

- `PhotoMemoRootSceneView` now renders `ConfigurationCenteriOSView` directly on
  iOS instead of routing runtime users through `PhotoMemoiOSTemporaryEntryView`
- the main runtime path no longer carries
  `PhotoMemoiOSTemporaryEntryConfiguration`
- V1 remains present in the repository and its app target still exists for
  maintenance/testing, but it is no longer the main runtime product switch
  inside the active iOS root scene
- V1 subject-selection side effects now flow through
  `V1SubjectSelectionMutationCoordinator`
- user birthday edits still refresh preview and mark dirty
- subject/bootstrap-driven birthday synchronization now supports two non-user
  behaviors:
  - refresh without dirtying
  - suppress both refresh and dirtying during bootstrap

Behavioral result:

```text
App
-> Root Scene
-> Configuration Center
```

```text
Bootstrap restore
-> subject restore
-> birthday sync
-> no dirty state

User edit
-> mutation
-> preview refresh
-> dirty state
```

Verification:

- focused new tests passed:
  - `IOSRuntimeSurfaceContractTests`
  - `V1SubjectSelectionMutationCoordinatorTests`
- focused regression tests passed:
  - `V1BootstrapRuntimeCoordinatorTests`
  - `V1DraftRuntimeCoordinatorTests`
  - `V1SubjectLibrarySupportTests`
  - `PhotoMemoiOSTemporaryEntryTests`
- build passed:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- observed warning:
  - existing macOS 26 deprecation warnings in `GeocoderService.swift`

Not yet manually verified:

- iOS app launch path now opening directly into Configuration Center on device
- V1 standalone app target behavior on device after the root-scene change
- subject switch / active-anchor switch visual behavior on device while editing
- deep link / external intake behavior on iOS hardware after the single-surface
  runtime change

## 2026-07-06 P1 typed configuration status convergence completed

This follow-up closes the agreed Phase 2 status-safety slice from the latest
V1 re-audit without mixing in the later product-language cleanup:

1. V1 configuration state no longer depends on localized status strings
2. dirty / saving / saved / subject-sync / failure now flow through one typed
   semantic model

What changed:

- added `V1ConfigurationStatus` and `V1ConfigurationStatusContext` as the
  canonical V1 configuration-state model
- V1 draft mutation/orchestration/bridge/runtime paths now carry
  `activeConfigurationStatus` instead of raw status strings
- V1 configuration apply success/failure/saving reconciliation now reports
  semantic state first, then derives user-facing copy from context
- V1 subject overview / preset selection / logo selection / home summary
  presentation paths now consume the typed status model
- `PhotoMemoiOSV1View` no longer keeps the old string-driven dirty marker in
  the remaining preset reset path

Behavioral result:

```text
Semantic state
-> badge tone
-> context copy
```

instead of:

```text
localized copy
-> behavior / tone / branching
```

Verification:

- focused tests passed:
  - `V1ConfigurationStatusTests`
  - `V1DraftBridgeTests`
  - `V1DraftMutationCoordinatorTests`
  - `V1DraftRuntimeCoordinatorTests`
  - `V1DraftOrchestrationCoordinatorTests`
  - `V1ConfigurationApplyRuntimeCoordinatorTests`
  - `V1ConfigurationApplyReconciliationTests`
  - `V1SubjectLibrarySupportTests`
  - `V1PresetSelectionCoordinatorTests`
  - `V1IOSHomeProjectionTests`
  - `V1SubjectHomeSummaryPresenterTests`
- required build passed:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- observed warning:
  - existing Xcode destination-selection warning only

Not yet manually verified:

- V1 home/status badge transitions on device after save / sync / failure flows
- preset switch + cancel-confirmation path after typed status migration
- subject overview -> editor -> save callback visual status behavior on device

## 2026-07-06 Phase 3 home-language convergence completed

This follow-up lands the agreed first product-language cleanup without mixing
in the later projection-unification work:

1. home summary no longer treats anchor count as a primary homepage concept
2. the old `X 个时间锚点` expression is removed from the home summary chain

What changed:

- `V1IOSHomeSubjectSummaryProjection` no longer carries `anchorCountLabel`
- `V1SubjectHomeSummaryPresentation` no longer carries `anchorCountLabel`
- the homepage subject summary now shows:
  - current subject
  - current active time anchor
  - subject fallback guidance
- home fallback language now prefers `补充主角信息`
  instead of `补充主角与时间锚点`

Scope boundary kept in this slice:

- home / subject-home summary language: ✅ converged
- subject overview detail page anchor-count expression: intentionally left in
  place for later review, because it still behaves more like an object-detail
  projection than a homepage summary

Verification:

- focused tests passed:
  - `V1IOSHomeProjectionTests`
  - `V1SubjectHomeSummaryPresenterTests`
- required build passed:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- observed warning:
  - existing Xcode destination-selection warning only

Not yet manually verified:

- homepage subject card copy after switching between subjects with and without
  anchors
- homepage object summary and status card visual spacing after removing the old
  count detail

## 2026-07-06 Phase 3 overview anchor-language convergence completed

This follow-up completes the remaining old anchor-count cleanup inside the V1
subject overview/detail path without expanding into projection unification:

1. subject overview no longer uses anchor count as a primary detail expression
2. the old `X 个时间锚点` badge is removed from the active-anchor card

What changed:

- `V1IOSSubjectOverviewPresentation` no longer carries `anchorCountLabel`
- `V1IOSSubjectAnchorSection` no longer renders the old count badge
- the overview anchor card now focuses on:
  - current active anchor title
  - current active anchor date
  - current active anchor description
  - active-anchor picker

Behavioral result:

- home summary: no anchor-count language
- overview/detail card: no anchor-count language
- remaining anchor content now stays focused on the active anchor itself

Verification:

- focused tests passed:
  - `V1IOSSubjectOverviewPresenterTests`
- required build passed:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- observed warning:
  - existing Xcode destination-selection warning only

Not yet manually verified:

- subject overview anchor card spacing after removing the count badge
- subject overview anchor picker behavior on device after switching anchors

## 2026-07-06 Device acceptance fixes for Location output and MemorySubject production snapshot

Follow-up device testing on `iPhone7` found two preview-to-output mismatches in
the user-visible Location Module / Time Anchor flow:

- Location display preview correctly showed the selected presentation mode, but
  production output fell back to raw coordinates when the imported photo only
  carried GPS facts.
- Time Anchor preview correctly used the selected memory subject `途途`, but
  production output could fall back to the legacy default subject text `家人`
  when the standalone selected subject payload was stale or missing.

Fixes:

- `PhotoImportService` now supports location metadata enrichment after EXIF/GPS
  import through `PhotoLocationMetadataEnricher`, using the platform reverse
  geocoder to populate address hierarchy fields consumed by the existing
  Location provider.
- Explicit Location display configuration now suppresses legacy coordinate
  fallback when the requested presentation cannot be resolved, so production
  does not silently replace a configured semantic display with raw GPS text.
- `BatchConfigurationSnapshotProvider` now resolves the frozen production
  `MemorySubject` from the V1 subject library selected record before falling
  back to the older standalone selected subject and legacy profile path. This
  keeps Configuration Center preview and production export aligned around the
  same selected object.

Verification:

- `BatchConfigurationSnapshotProviderDiagnosticsTests` passed, including the
  regression where the subject library selects `途途` while the standalone
  selected subject is stale.
- `ProductionMemoryResolverTests` passed.
- `RecordCardBuildServiceTests` passed, including Location production output
  and explicit Location display fallback coverage.
- `PhotoImportServiceTests` passed for location metadata enrichment.
- `git diff --check` passed.
- `PhotoMemoiOSV1` signed device build passed for connected `iPhone7`.
- Device install succeeded after uninstalling the previous app. Automatic launch
  was blocked by iOS developer-profile trust and requires the user to trust the
  development profile on-device before opening.

## 2026-07-06 Location Module Feature save and production consumption implemented

Location Module Adoption now has the user-visible configuration loop connected
to the app production render/export path:

```text
Location Module
-> Object Inspector 位置显示
-> ExpressionModuleConfiguration
-> BatchConfigurationSnapshot
-> RecordCardBuildService
-> CardTextBlockEngine
```

Completed checkpoints:

- V1 configuration save/apply requests now carry the selected Location display
  configuration.
- `SettingsService`, `SettingsRepository`, and
  `BatchConfigurationSnapshotProvider` persist and reload the selected
  Location display configuration through the existing shared defaults seam.
- V1 bootstrap restore now reloads the saved Location display configuration
  into Object Inspector and preview composition state instead of falling back
  to the local default after restart.
- `BatchConfigurationSnapshot` now carries the saved
  `ExpressionModuleConfiguration` as production transport data.
- `RecordCardBuildService` compiles the saved Location display configuration
  into a production `ExpressionContext` value before card text rendering.
- `CardTextBlockEngine` preserves the production Location expression value and
  does not overwrite it with the legacy-compatible fallback provider.
- `SharedBatchConfigurationSnapshotService` now proves the shared snapshot
  carrier can read the saved Location display configuration used by Share
  intake.
- `PhotoMemoShareExtension` compiles with the shared Expression carrier files
  needed to decode that snapshot field.

Scope review:

- No new Location provider capability was introduced.
- `ExpressionLookup`, `ExpressionValue`, `ExpressionContext`,
  `ExpressionModuleConfiguration`, `Expression_System_Contract.md`, and
  ADR-007 were not modified.
- Renderer drawing, layout, typography, export implementation, metadata
  mutation, photo-library save behavior, and Layout Engine behavior were not
  changed.

Feature Completion Gate status:

- Preview: ✅ focused tests pass.
- Production render/export path: ✅ focused tests pass through
  `RecordCardBuildService` and `CardTextBlockEngine`.
- Share intake carrier: ✅ shared snapshot test and Share Extension build pass.
- Manual Product Acceptance: 🟡 not manually exercised on device in this gate.
- Feature Completion Gate: ✅ PASS.
- Merge to `main`: ✅ merged and pushed at `35baa64c`.

Verification:

- `git diff --check` passed.
- Focused Location display / preview tests passed:
  - `LocationDisplayInspectorPresenterTests`
  - `ConfigurationCenterRegionBindingAdapterTests`
  - `ConfigurationCenterPreviewCompositionHelperTests`
  - `LocationConfigurationAdapterTests`
- Focused save / production / boundary tests passed:
  - `V1ConfigurationApplyRequestBuilderTests`
  - `ConfigurationMigrationTests`
  - `V1ConfigurationBootstrapPresenterTests`
  - `V1BootstrapFlowCoordinatorTests`
  - `V1BootstrapRuntimeCoordinatorTests`
  - `RendererDependencyIsolationTests`
  - `RecordCardBuildServiceTests`
- Focused shared snapshot tests passed:
  - `SharedBatchConfigurationSnapshotServiceTests`
  - `BatchConfigurationSnapshotProviderDiagnosticsTests`
- Builds passed:
  - `PhotoMemo` Debug
  - `PhotoMemoiOSV1` generic iOS Simulator
  - `PhotoMemoShareExtension` generic iOS Simulator

Post-main-merge verification:

- `origin/main` was merged into `codex/expression-platform-baseline` at
  `9938ba9` and conflicts were resolved by preserving both main-line status
  history and Location Feature regression coverage.
- `main` was fast-forwarded to `35baa64c` and pushed to GitHub.
- Focused Location display / preview / save / production / shared snapshot
  tests passed after the merge.
- Post-merge builds passed:
  - `PhotoMemo` Debug
  - `PhotoMemoiOSV1` generic iOS Simulator
  - `PhotoMemoShareExtension` generic iOS Simulator
- Post-merge simulator smoke passed for app install and launch:
  `PhotoMemoiOSV1.app` launched as `com.serydoo.PhotoMemo.iOS` and reached the
  system Photos permission dialog without a main-app crash.
- Location data acceptance passed with a GPS-bearing Photos render:
  `0194231B-1F96-4A84-A5D7-B32200353811_1_201_a.jpeg` resolved to
  `33.930355, 116.444153` through the real PhotoMemo metadata, Location
  provider, configuration adapter, and `ExpressionContext` lookup sources.
- Product Acceptance Gate remains blocked only for full manual interaction and
  real export validation.
- Release event:
  `Docs/07_Releases/Expression_Platform_Main_Merge_2026-07-06.md`.

## 2026-07-06 Location Module Feature Slice A frozen

Location Module Adoption has moved from platform completion into feature
experience completion. This slice exposes the existing Location display
capability through Object Inspector without adding new platform capability.

Checkpoints:

- `c96403a` freezes the Slice A product boundary and Object Inspector boundary
  scan.
- `25936da` adds the Object Inspector `位置显示` panel.
- User-facing language is product language only:
  - `位置显示`
  - `自动兼容`
  - `省份 · 城市`
  - `城市 · 区县`
  - `省份 · 城市 · 区县`
  - `经纬度`
  - `位置模块未插入`
- `LocationDisplayInspectorPresenter` maps those labels to existing
  `ExpressionModuleConfiguration` values.
- Selecting a Location display option writes configuration to the inserted
  module and recomputes Configuration Center preview through the existing
  Location adapter/provider path.
- Non-location modules are ignored by the location-display update path.

Scope review:

- No new Location provider capability was introduced.
- `ExpressionLookup`, `ExpressionValue`, `ExpressionContext`,
  `ExpressionModuleConfiguration`, `Expression_System_Contract.md`, and
  ADR-007 were not modified.
- Renderer, Export, Share Extension, Metadata mutation, Photo Library
  behavior, and Layout Engine behavior were not changed.

Remaining feature completion work:

- Persist Location display choices through the production configuration path.
- Make production render/export consume the persisted Location display
  configuration.
- Run the Location Module Feature Completion Gate before merging this feature
  into `main`.

Verification:

- `git diff --check` passed.
- Focused Location display / preview tests passed:
  - `LocationDisplayInspectorPresenterTests`
  - `ConfigurationCenterRegionBindingAdapterTests`
  - `ConfigurationCenterPreviewCompositionHelperTests`
  - `LocationConfigurationAdapterTests`
- `PhotoMemo` Debug build passed.
- `PhotoMemoiOSV1` generic iOS Simulator build passed.

## 2026-07-06 V1 Memory Summary entry cleanup

V1 time-anchor expression entry points now prefer the new Memory layer.

Completed checkpoints:

- Default presets `template1`, `template2`, `template3`, and `immersWhite`
  now use `{{memory_summary}}` as the right-bottom smart-time entry.
- Legacy built-in anchor sentence templates are migrated to
  `{{memory_summary}}` during `Template.normalizedForEditing`.
- The public intelligent variable catalog no longer exposes legacy
  `anchor_*` variables as user-selectable smart-expression options.
- Memory Anchor expression wording now has a refreshed baseline for birthday,
  marriage, relationship, exam, and custom anchor tones, including `岁`
  wording after full years and `结婚` wording instead of `婚礼` for countdowns.
- Birthday, marriage, and relationship anchor expressions now have a local
  annual-occurrence helper for next birthday / anniversary wording when the
  caller explicitly requests annual occurrence phrasing.
- The old `anchor_*` `MetadataContext` keys and `CardVariableProvider`
  projection path remain as compatibility plumbing so existing saved templates
  and transport snapshots do not fail abruptly.
- Renderer, Export, Share Extension, Metadata mutation, Photo Library behavior,
  and Layout Engine behavior were not changed.

Verification:

- `PhotoMemoTests/PreviewCompositionMigrationTests` passed.
- `PhotoMemoTests/MemoryExpressionEngineTests` passed.
- `PhotoMemoTests/MemoryEngineTests` passed.
- Production/snapshot compatibility group passed:
  - `RecordCardBuildServiceTests`
  - `PhotoMemoShareWorkflowSummaryTests`
  - `BatchConfigurationSnapshotProviderDiagnosticsTests`
  - `SharedBatchConfigurationSnapshotServiceTests`
- `PhotoMemo` Debug build passed.

## 2026-07-06 Location Expression architecture candidate through Phase 4-D

The Location Expression work is isolated on the `codex/地址模块` branch as a
post-IA-003 architecture candidate.

Completed checkpoints:

- `Location_Expression_Pipeline.md` records the Provider-Based Expression
  Architecture proposal and is treated as architecture scope only.
- `Location_Expression_Implementation_Plan.md` records the migration plan and
  Phase 0-9 rollout checkpoints.
- Phase 0 code skeleton exists for the new Expression and LocationExpression
  boundaries without wiring into production rendering, export, metadata, share,
  or photo-library behavior.
- Phase 1 maps normalized `PhotoMetadata` location facts into an independent
  `LocationContext` through `LocationContextBuilder`, including GPS,
  altitude, address hierarchy, and location name availability.
- Phase 2 adds pure `LocationFormatter` presentation string shaping for
  Province + City, City + District, Province + City + District, and Coordinate
  without fallback, Provider, Renderer, or UI dependencies.
- Phase 3 adds deterministic `LocationResolver` strategy resolution with
  immutable request-scoped `LocationResolution`, downgrade / coordinate
  fallback / empty policies, and Formatter-owned final text representation.
- Phase 4-A is now scoped as Expression System contract work before Provider
  integration. `Expression_System_Contract.md` defines the provider-neutral
  flow, hard rules, and extension rules that future Providers must follow.
- Phase 4-B starts code verification with provider-neutral `ExpressionValue`:
  it carries `ExpressionToken` plus resolved text, is `Hashable` / `Codable`,
  and is tested as a non-bare-string, provider-neutral value object.
- Phase 4-C adds `ExpressionContext` as the only current aggregation container
  for expression values: it stores `ExpressionValue` by semantic token and
  rejects duplicate tokens at construction.
- Phase 4-D entry is guarded by `ExpressionSystemSmokeTests`, which validates
  fake provider-like sources -> `ExpressionValue` -> `ExpressionContext` ->
  mock renderer without introducing a production Provider API.
- Phase 4-D adds the first real Canonical Provider compiler validation:
  `LocationExpressionProvider` consumes `LocationContext`,
  `LocationResolver`, and `LocationFormatter` output to produce a
  provider-neutral `ExpressionValue` for the `location` token.
- Phase 4-D intentionally supports only `location`; raw `latitude`,
  `longitude`, and `altitude` output remain future Location Provider expansion
  work.
- `LocationExpressionPhase4DTests` covers the full isolated chain from
  `PhotoMetadata` to `LocationContextBuilder`, `LocationExpressionProvider`,
  and `ExpressionContext` without connecting Renderer, UI, Export, Share
  Extension, Metadata mutation, or Photo Library behavior.

Guardrail:

- The two Location proposal documents are considered responsibility-complete;
  future rationale should move into ADRs or platform-level constitution docs
  instead of expanding those files.
- Phase 3 remains isolated internals only; no Provider, `ExpressionContext`,
  Renderer, UI, Export, Share Extension, Metadata mutation, or Photo Library
  production wiring was added.
- Phase 4-D Provider code is isolated compiler validation only and does not
  connect any production renderer path to `ExpressionContext`.

## 2026-07-06 Platform Integration PI-1 ExpressionLookup frozen

Expression Platform work has moved from Stage 1 baseline creation into Stage 2
platform integration.

Stage status:

| Stage | Status | Notes |
| --- | --- | --- |
| Stage 1: Expression Platform Baseline | ✅ Complete | Baseline commit `d2daedf9` establishes `ExpressionToken`, `ExpressionValue`, `ExpressionContext`, Canonical Provider Pipeline, platform contract, ADR-007, and Location as the first validation Provider. |
| Stage 2: Platform Integration | ✅ Complete | PI-1 is frozen at commit `739b76fd`; PI-2 implementation is frozen at commit `0fec6bb`; PI-3 implementation is frozen at commit `da775c7`; PI-4 implementation is frozen at commit `dcdc257`. |
| Stage 3: Legacy Compatibility Adoption | ✅ PI-20 Location Provider Production Adoption Frozen | PI-5 boundary scan is frozen at commit `fd51a03`; PI-5 implementation is frozen at commit `1b20bdb`; PI-6 implementation is frozen at commit `06dd0a2`; PI-7 scan is frozen at commit `44c4883` with no implementation seam approved; PI-8 scan is frozen at commit `72cfff6`; PI-9 implementation is frozen at commit `c866fdc`; PI-10 implementation is frozen at commit `e6455c5`; PI-11 implementation is frozen at commit `5d122f2`; PI-12 scan is frozen at commit `c572230a`; PI-12 implementation is frozen at commit `1ffc3efb`; PI-13D implementation is frozen at commit `0aca215`; PI-14 parity proof is frozen at commit `750d74d`; PI-15 scan is frozen at commit `3467eaa`; PI-16 implementation is frozen at commit `6ab34aa`; PI-17 implementation is frozen at commit `2686649`; PI-18 mismatch proof is frozen at commit `6dd9da4`; PI-19 scan is frozen at commit `848fe96`; PI-19 implementation is frozen at commit `18e2b6e`; PI-20 scan is frozen at commit `d3acf93`; PI-20 implementation is frozen at commit `dd5d156`. |

Release status:

| Area | Status | Notes |
| --- | --- | --- |
| Expression Platform Architecture | ✅ Completed | ADR-007 and the Semantic Baseline remain governing decisions. |
| Expression Platform Implementation | ✅ Completed | Core language, lookup capability, providers, configuration carrier, preview adoption, and production text lookup adoption are implemented. |
| Platform Integration | ✅ Completed | Renderer text resolution, preview source, and production lookup seams are integrated without platform contract changes. |
| Platform Governance | ✅ Established | Work proceeded through boundary scans, approved seams, regression tests, freeze records, and architectural deltas. |
| Merge Readiness | 🟡 Conditional Pass | `Expression_Platform_RC_Merge_Readiness_Review.md` approves the RC to proceed to Product Acceptance Validation. |
| Production Acceptance | 🟡 Pending Acceptance Validation | Requires product-level end-to-end validation across Preview, Production render/export, Share Extension impact, and Photo Library/save-back impact. |

PI-1 completed checkpoints:

- `ExpressionLookup` defines the renderer dependency as pure lookup capability:
  `value(for:)`.
- PI-1 freezes the platform principle: Renderers depend on lookup capability
  rather than expression storage.
- `ExpressionContext` now conforms to `ExpressionLookup` and becomes the
  default lookup adapter, not the required renderer dependency.
- `ExpressionLookupContractTests` enforce that lookup exposes no enumeration
  or mutation surface.
- A lookup-only renderer stub proves mock lookup and `ExpressionContext`-
  backed lookup can produce identical output without renderer knowledge of
  concrete context storage.

Guardrail:

- PI-1 does not connect the production Renderer, Preview, Export, Share
  Extension, Metadata adapter, UI, or Photo Library behavior.
- Future renderer work should depend on `ExpressionLookup` capability, not
  concrete `ExpressionContext` storage.
- Renderer must treat lookup as read-only and per-render-cycle input.
- PI-2 should migrate renderer dependency only. It must not change layout,
  typography, drawing, color, modules, Export, Share Extension, Metadata
  adapter, UI, or Photo Library behavior.

## 2026-07-06 PI-2 Renderer Dependency Boundary Scan frozen

PI-2 has completed discovery before implementation.

Boundary scan artifact:

- `Docs/02_Architecture/PI-2_Renderer_Dependency_Isolation_Boundary_Scan.md`

Scan conclusion:

- The approved PI-2 seam is the renderer text-block lookup path:
  `CardTextBlockEngine -> TemplateVariableEngine.render(...) ->
  MetadataContext lookup`.
- PI-2 should replace only this text lookup dependency with
  `ExpressionLookup` capability.
- `RecordCardRenderer(image:card:)`, `RecordCard`, Export, Share Extension,
  batch processing, preview call sites, provider integration, layout,
  typography, drawing, color, and module behavior remain out of scope.

Freeze rule:

- Only one renderer integration seam is approved for PI-2.
- PI-2 must choose the seam with the smallest architectural surface, not the
  smallest line count.
- Renderer output change is not allowed.

## 2026-07-06 PI-2 Renderer Dependency Isolation frozen

PI-2 has completed the approved implementation seam.

Implementation checkpoint:

- `0fec6bb` replaces the `CardTextBlockEngine` text dependency from
  `MetadataContext` lookup to `ExpressionLookup` capability.

Architectural delta:

```text
Renderer text dependency: MetadataContext -> ExpressionLookup
```

Scope review:

- The approved seam was the only architectural surface modified:
  `CardTextBlockEngine -> TemplateVariableEngine.render(...)`.
- `MetadataContextExpressionLookup` is a local engine-side compatibility
  adapter for the approved seam; it is not a platform contract.
- `RecordCardRenderer`, `RecordCard`, Export, Share Extension, batch
  processing, preview call sites, provider integration, layout, typography,
  drawing, color, and module behavior were not changed.
- `ExpressionLookup`, `ExpressionValue`, `ExpressionContext`,
  `Expression_System_Contract.md`, and ADR-007 were not modified.

Verification:

- `git diff --check` passed.
- `PhotoMemo` Debug build passed.
- PI-2 focused tests passed:
  - `RendererDependencyIsolationTests`
  - `TemplateVariableEngineTests`
  - `ExpressionLookupContractTests`
- Renderer regression tests passed:
  - `ClassicWhiteCardRendererLayoutTests`
  - `ClassicWhiteRendererThemeTests`
  - `ImmersWhiteRendererLayoutTests`
  - `RecordCardRendererRoutingTests`
  - `TemplatePresetRenderLayoutTests`

Known verification note:

- `ClassicWhiteSnapshotTests.landscapeStandardSnapshotStaysStable()` passes
  when run alone, but the full `ClassicWhiteSnapshotTests` suite still shows
  an order-sensitive text antialiasing/truncation mismatch in that case. This
  was not fixed in PI-2 because snapshot stability work is outside the
  approved seam and no renderer behavior change is allowed.

## 2026-07-06 PI-3 Memory Provider Compilation frozen

PI-3 has completed the second canonical provider validation without changing
platform contracts.

Boundary scan artifact:

- `Docs/02_Architecture/PI-3_Memory_Provider_Boundary_Scan.md`

Checkpoints:

- `aeacae1` freezes the approved PI-3 seam:
  `MemoryExpressionContext -> MemoryExpressionEngine ->
  MemoryResultPresentationAdapter -> MemoryModule.renderedText`.
- `da775c7` adds `MemoryProvider`, which compiles the completed Memory
  presentation output into a provider-neutral `ExpressionValue`.

Architectural delta:

```text
Memory expression compilation: MemoryModule.renderedText -> ExpressionValue
```

Scope review:

- PI-3 supports only the canonical `memory` token.
- The provider consumes existing Memory pipeline output and does not implement
  Memory calculation or formatting rules itself.
- `MemoryResult`, `MemoryExpressionEngine`, `MemoryResultPresentationAdapter`,
  Renderer, Export, Share Extension, batch processing, `RecordCard`,
  `RecordCardBuildService`, `CardVariableProvider`, and production output were
  not changed.
- `ExpressionLookup`, `ExpressionValue`, `ExpressionContext`,
  `Expression_System_Contract.md`, and ADR-007 were not modified.

Verification:

- `MemoryProviderTests` passed.
- Memory / Expression contract tests passed:
  - `MemoryExpressionEngineTests`
  - `MemoryResultContractTests`
  - `ExpressionValueContractTests`
  - `ExpressionContextContractTests`
  - `ExpressionSystemSmokeTests`
- `PhotoMemo` Debug build passed.

## 2026-07-06 PI-4 Metadata Provider Compilation frozen

PI-4 has completed legacy metadata fact compiler validation without changing
platform contracts or production metadata acquisition.

Boundary scan artifact:

- `Docs/02_Architecture/PI-4_Metadata_Provider_Boundary_Scan.md`

Checkpoints:

- `942811d` freezes the approved PI-4 seam:
  `PhotoMetadata -> MetadataContext.build(from:) -> MetadataContext[model]`.
- `dcdc257` adds `MetadataProvider`, which compiles the existing normalized
  metadata model fact into a provider-neutral `ExpressionValue`.

Architectural delta:

```text
Metadata fact compilation: MetadataContext[model] -> ExpressionValue
```

Scope review:

- PI-4 supports only the canonical `model` token.
- The provider consumes the existing `MetadataContext.build(from:)` projection
  and does not implement EXIF acquisition, production template lookup, or
  renderer behavior.
- `PhotoMetadataReader`, `MetadataContext.build(from:)`,
  `CardVariableProvider`, `TemplateVariableLibrary`, Renderer, Export, Share
  Extension, batch processing, preview, and Photo Library behavior were not
  changed.
- `ExpressionLookup`, `ExpressionValue`, `ExpressionContext`,
  `Expression_System_Contract.md`, and ADR-007 were not modified.

Verification:

- `MetadataProviderTests` passed.
- Metadata / Expression contract tests passed:
  - `MetadataContextTests`
  - `PhotoMetadataNormalizationTests`
  - `ExpressionValueContractTests`
  - `ExpressionContextContractTests`
  - `ExpressionSystemSmokeTests`
- `git diff --check` passed.
- `PhotoMemo` Debug build passed.

## 2026-07-06 Stage 2 Platform Integration frozen

Stage 2 is complete as an Architecture-Governed Refactoring stage.

Completed checkpoints:

- PI-1 established `ExpressionLookup` as the renderer dependency capability.
- PI-2 isolated renderer text lookup at the approved
  `CardTextBlockEngine -> ExpressionLookup` seam without changing renderer
  output.
- PI-3 validated the second canonical provider through Memory provider
  compilation.
- PI-4 validated legacy metadata facts entering Expression Language through
  Metadata provider compilation.

Stage 2 completion criteria:

- Renderer text resolution depends on `ExpressionLookup` capability rather
  than concrete `ExpressionContext` storage.
- At least two canonical providers are validated without platform contract
  changes. Stage 2 now has Location, Memory, and Metadata provider compiler
  validation.
- No Stage 2 implementation changed `ExpressionLookup`, `ExpressionValue`,
  `ExpressionContext`, `Expression_System_Contract.md`, or ADR-007.
- No Stage 2 implementation changed Renderer layout, typography, drawing,
  Export, Share Extension, Photo Library behavior, or metadata acquisition.

Guardrail:

- At the time of Stage 2 freeze, no PI-5 seam was approved.
- PI-5 was later opened through its own frozen Boundary Scan before
  implementation.
- Any further Platform Adoption work after PI-5 must begin with a new Boundary
  Scan before implementation.

## 2026-07-06 PI-5 Legacy Metadata Adapter frozen

PI-5 has completed the first legacy compatibility adapter without changing
platform contracts or production rendering.

Boundary scan artifact:

- `Docs/02_Architecture/PI-5_Legacy_Metadata_Adapter_Boundary_Scan.md`

Checkpoints:

- `fd51a03` freezes the approved PI-5 seam:
  `ExpressionContext -> ExpressionContextMetadataAdapter ->
  MetadataContext[location_display]`.
- `1b20bdb` adds `ExpressionContextMetadataAdapter`, which projects the
  completed Expression Language `location` value into a legacy
  `MetadataContext` copy for existing template consumers.

Architectural delta:

```text
Legacy metadata compatibility projection: ExpressionContext[location] -> MetadataContext[location_display]
```

Scope review:

- PI-5 supports only the approved `location -> location_display` projection.
- The adapter consumes `ExpressionContext` and produces a `MetadataContext`
  projection or copy.
- The adapter does not mutate `ExpressionContext`, does not make
  `MetadataContext` own Expression semantics, and does not connect production
  rendering.
- `ExpressionLookup`, `ExpressionValue`, `ExpressionContext`,
  `Expression_System_Contract.md`, and ADR-007 were not modified.
- `LocationExpressionProvider`, `PhotoMetadataReader`,
  `MetadataContext.build(from:)`, `CardVariableProvider`,
  `TemplateVariableEngine`, `RecordCard`, `RecordCardBuildService`, Renderer,
  Export, Share Extension, batch processing, preview, and Photo Library
  behavior were not changed.

Verification:

- `ExpressionContextMetadataAdapterTests` passed.
- Expression / legacy template regression tests passed:
  - `ExpressionContextContractTests`
  - `ExpressionValueContractTests`
  - `ExpressionLookupContractTests`
  - `TemplateVariableEngineTests`
  - `MetadataContextTests`
- `git diff --check` passed.
- `PhotoMemo` Debug build passed.

## 2026-07-06 PI-6 V1 Preview Expression Source frozen

PI-6 has completed the first preview Expression Language adoption seam without
changing platform contracts, production rendering, or Configuration Center
module insertion behavior.

Boundary scan artifact:

- `Docs/02_Architecture/PI-6_V1_Preview_Expression_Source_Boundary_Scan.md`

Checkpoints:

- `5398c89` freezes the approved PI-6 seam:
  `V1PreviewCompositionEngine.moduleDisplayText(.location) -> preview sample
  facts -> LocationExpressionProvider -> ExpressionContext[location]`.
- `06dd0a2` changes the V1 preview location module source from a
  preview-local rendered string to a provider-produced `ExpressionValue`
  stored in `ExpressionContext`.

Architectural delta:

```text
V1 preview location source: preview-local string -> ExpressionContext[location]
```

Scope review:

- PI-6 supports only the approved `location` preview token.
- V1 preview output text remains `河南 · 商丘`.
- V1 preview template token remains `{{location_display}}`.
- No `PreviewExpressionContext` model was introduced.
- `ExpressionLookup`, `ExpressionValue`, `ExpressionContext`,
  `Expression_System_Contract.md`, and ADR-007 were not modified.
- `LocationExpressionProvider`, `ExpressionContextMetadataAdapter`,
  `ConfigurationCenterPreviewCompositionHelper`, `PhotoMemoiOSModuleCatalog`,
  `CardVariableProvider`, `TemplateVariableEngine`, `RecordCard`,
  `RecordCardBuildService`, Renderer, Export, Share Extension, batch
  processing, Photo Library behavior, and production preview behavior were not
  changed.

Verification:

- `PreviewCompositionMigrationTests` passed.
- Expression / Location / legacy adapter regression tests passed:
  - `LocationExpressionPhase4DTests`
  - `ExpressionContextMetadataAdapterTests`
  - `ExpressionContextContractTests`
  - `ExpressionValueContractTests`
- `git diff --check` passed.
- `PhotoMemo` Debug build passed.

## 2026-07-06 PI-7 Location Module Configuration Boundary Scan frozen

PI-7 completed a stopping Boundary Scan and did not approve implementation.

Boundary scan artifact:

- `Docs/02_Architecture/PI-7_Location_Module_Configuration_Boundary_Scan.md`

Checkpoint:

- `44c4883` freezes the PI-7 scan conclusion:
  no existing approved seam can persist Location module presentation
  configuration without introducing a configuration carrier or crossing
  Configuration Center, Inspector, snapshot, preview, production, or renderer
  boundaries.

Architectural delta:

```text
No implementation seam approved: Expression module configuration requires a separate contract review
```

Scope review:

- No implementation was performed for PI-7.
- `ExpressionLookup`, `ExpressionValue`, `ExpressionContext`,
  `Expression_System_Contract.md`, and ADR-007 were not modified.
- `LocationExpressionProvider`, `LocationResolver`, `LocationFormatter`,
  `ConfigurationSnapshot`, `ConfigurationSession`,
  `MemoryBlockInspectorView`, `V1PreviewCompositionEngine`,
  `ConfigurationCenterPreviewCompositionHelper`, `CardVariableProvider`,
  `RecordCardBuildService`, Renderer, Export, Share Extension, batch
  processing, Photo Library behavior, and production behavior were not changed.

Required next architecture question:

```text
Where does provider-neutral Expression Module Configuration live?
```

Until that question is answered through a focused scan or ADR, Stage 3 should
not continue with Location module configuration implementation.

## 2026-07-06 PI-8 Expression Module Configuration Boundary Scan frozen

PI-8 answered the follow-up ownership question without implementation.

Boundary scan artifact:

- `Docs/02_Architecture/PI-8_Expression_Module_Configuration_Boundary_Scan.md`

Checkpoint:

- `72cfff6` freezes the PI-8 scan conclusion:
  provider-neutral Expression Module Configuration should live on the inserted
  module instance.

Architectural delta:

```text
Expression module configuration ownership: unowned -> inserted module instance
```

Scope review:

- No implementation was performed for PI-8.
- The recommended owner is the inserted module instance because presentation
  configuration belongs to one concrete module insertion.
- The carrier must be provider-neutral, token-addressed, `Codable`, and
  `Hashable`.
- `ExpressionLookup`, `ExpressionValue`, `ExpressionContext`,
  `Expression_System_Contract.md`, and ADR-007 were not modified.
- `LocationExpressionProvider` token support remains unchanged; Location still
  supports only the canonical `location` token.
- Renderer, Template, `MetadataContext`, `ExpressionContext`, and
  `ExpressionLookup` must not read or infer presentation strategy.

Next implementation boundary:

```text
Inserted module instance -> provider-neutral expression module configuration carrier
```

Any implementation must remain scoped to the inserted-module ownership
boundary and must not jump directly into Renderer, Template, Provider,
ExpressionContext, live session, snapshot, export, share, photo-library, or
production behavior.

## 2026-07-06 PI-9 Expression Module Configuration Carrier frozen

PI-9 completed the approved carrier implementation seam without wiring behavior.

Boundary scan artifact:

- `Docs/02_Architecture/PI-9_Expression_Module_Configuration_Carrier_Boundary_Scan.md`

Checkpoints:

- `8a9ef96` freezes the approved PI-9 seam:
  `ExpressionModuleConfiguration` plus
  `IOSInsertedModule.expressionConfiguration`.
- `c866fdc` adds the provider-neutral `ExpressionModuleConfiguration` carrier
  and attaches it as optional inserted-module data.

Architectural delta:

```text
Expression module configuration carrier: absent -> optional inserted-module data
```

Scope review:

- The approved carrier seam was the only implementation surface modified.
- `ExpressionModuleConfiguration` is `Codable`, `Hashable`, keyed by
  `ExpressionToken`, and provider-neutral.
- `IOSInsertedModule` keeps legacy construction working through a nil default.
- No Location-specific fields were added to the generic carrier.
- `ExpressionLookup`, `ExpressionValue`, `ExpressionContext`,
  `Expression_System_Contract.md`, and ADR-007 were not modified.
- `LocationExpressionProvider`, `LocationResolver`, `LocationFormatter`,
  `ConfigurationSession`, `ConfigurationSnapshot`, `MemoryBlock`,
  `MemoryTokenBlock`, `MemoryExpression`, `MemoryBlockInspectorView`,
  `V1PreviewCompositionEngine`, `ConfigurationCenterPreviewCompositionHelper`,
  `CardVariableProvider`, `RecordCardBuildService`, Renderer, Export, Share
  Extension, batch processing, Photo Library behavior, and production behavior
  were not changed.

Verification:

- `ExpressionModuleConfigurationContractTests` passed.
- Expression / inserted-module regression tests passed:
  - `ExpressionValueContractTests`
  - `ExpressionContextContractTests`
  - `ConfigurationCenterPreviewCompositionHelperTests`
  - `ConfigurationCenterRegionEditCoordinatorTests`
  - `ConfigurationCenterRegionDraftStoreTests`
  - `ConfigurationCenterRegionBindingAdapterTests`
- `git diff --check` passed.
- `PhotoMemo` Debug build passed.

## 2026-07-06 PI-10 Location Configuration Adapter frozen

PI-10 completed the approved Location adapter seam without wiring UI, preview,
production, or renderer behavior.

Boundary scan artifact:

- `Docs/02_Architecture/PI-10_Location_Configuration_Adapter_Boundary_Scan.md`

Checkpoints:

- `e0bad54` freezes the approved PI-10 seam:
  `ExpressionModuleConfiguration -> LocationConfigurationAdapter ->
  LocationPresentationMode -> LocationResolutionConfiguration`.
- `e6455c5` adds `LocationConfigurationAdapter`, which translates the
  provider-neutral carrier into typed Location provider input.

Architectural delta:

```text
Location configuration adapter: ExpressionModuleConfiguration -> typed Location provider input
```

Scope review:

- The approved adapter seam was the only implementation surface modified.
- Unknown or invalid options are deterministic and use typed defaults:
  `provinceCity` and `allowsCoordinateFallback = false`.
- The adapter consumes `ExpressionModuleConfiguration` but does not mutate or
  store configuration.
- `ExpressionLookup`, `ExpressionValue`, `ExpressionContext`,
  `ExpressionModuleConfiguration`, `Expression_System_Contract.md`, and
  ADR-007 were not modified.
- `LocationExpressionProvider`, `LocationResolver`, `LocationFormatter`,
  `IOSInsertedModule`, `ConfigurationSession`, `ConfigurationSnapshot`,
  `MemoryBlockInspectorView`, `V1PreviewCompositionEngine`,
  `ConfigurationCenterPreviewCompositionHelper`, `CardVariableProvider`,
  `RecordCardBuildService`, Renderer, Export, Share Extension, batch
  processing, Photo Library behavior, and production behavior were not changed.

Verification:

- RED confirmed `LocationConfigurationAdapterTests` failed before the adapter
  existed.
- `LocationConfigurationAdapterTests` passed.
- Location / Expression regression tests passed:
  - `LocationExpressionPhase4DTests`
  - `LocationExpressionPhase3Tests`
  - `ExpressionModuleConfigurationContractTests`
  - `ExpressionValueContractTests`
  - `ExpressionContextContractTests`
- `git diff --check` passed.
- `PhotoMemo` Debug build passed.

## 2026-07-06 PI-11 Configuration Persistence frozen

PI-11 completed the approved insertion-chain persistence seam without disk,
snapshot, preview-provider, production, or renderer adoption.

Boundary scan artifact:

- `Docs/02_Architecture/PI-11_Configuration_Persistence_Boundary_Scan.md`

Checkpoints:

- `e22e7e7` freezes the approved PI-11 seam:
  `ConfigurationCenterRegionBindingAdapter.insertModule(...) ->
  ConfigurationCenterRegionEditCoordinator.insertModule(...) ->
  ConfigurationCenterPreviewCompositionHelper.insertModule(...) ->
  IOSInsertedModule.expressionConfiguration`.
- `5d122f2` forwards optional `ExpressionModuleConfiguration` through the
  insertion chain and stores it on the resulting `IOSInsertedModule`.

Architectural delta:

```text
Expression module configuration persistence: insertion input -> stored inserted module instance
```

Scope review:

- The approved insertion chain was the only implementation surface modified.
- Existing module insertion still works with no configuration.
- Configured insertion stores the configuration on the inserted module instance
  under the active region configuration ID.
- Preview text remains derived from the same inserted-module rendered value.
- `ExpressionLookup`, `ExpressionValue`, `ExpressionContext`,
  `ExpressionModuleConfiguration`, `Expression_System_Contract.md`, and
  ADR-007 were not modified.
- `LocationExpressionProvider`, `LocationConfigurationAdapter`,
  `LocationResolver`, `LocationFormatter`, `ConfigurationSnapshot`,
  `ConfigurationSession`, `MemoryBlock`, `MemoryExpression`,
  `MemoryBlockInspectorView`, `V1PreviewCompositionEngine`,
  `CardVariableProvider`, `RecordCardBuildService`, Renderer, Export, Share
  Extension, batch processing, Photo Library behavior, and production behavior
  were not changed.

Verification:

- RED confirmed configured insertion failed before the insertion chain accepted
  `expressionConfiguration`.
- Configuration insertion regression tests passed:
  - `ConfigurationCenterPreviewCompositionHelperTests`
  - `ConfigurationCenterRegionBindingAdapterTests`
  - `ConfigurationCenterRegionEditCoordinatorTests`
  - `ConfigurationCenterRegionDraftStoreTests`
- Expression / Location configuration tests passed:
  - `ExpressionModuleConfigurationContractTests`
  - `LocationConfigurationAdapterTests`
- `git diff --check` passed.
- `PhotoMemo` Debug build passed.

## 2026-07-06 PI-12 Preview Expression Platform Adoption frozen

PI-12 completed the Configuration Center preview Expression Platform adoption
seam without changing production, renderer, export, share extension, photo
library, or platform contract behavior.

Boundary scan artifact:

- `Docs/02_Architecture/PI-12_Preview_Expression_Platform_Boundary_Scan.md`

Checkpoints:

- `c572230a` freezes the approved PI-12 preview seam:
  `ConfigurationCenterPreviewCompositionHelper.insertModule(...) ->
  moduleDisplayText(.location, expressionConfiguration) -> preview sample
  facts -> LocationConfigurationAdapter -> LocationExpressionProvider ->
  ExpressionContext[location]`.
- `1ffc3efb` changes the Configuration Center preview location source from a
  hardcoded preview string to Expression Platform output through the Location
  adapter and provider pipeline.

Architectural delta:

```text
Configuration Center preview location source: hardcoded string -> ExpressionContext[location]
```

Scope review:

- The approved Configuration Center preview location source was the only
  implementation surface modified.
- Default preview output remains `河南 · 商丘`.
- Configured preview output is produced through `LocationConfigurationAdapter`
  and `LocationExpressionProvider`.
- `V1PreviewCompositionEngine`, `CardVariableProvider`, `RecordCard`,
  `RecordCardBuildService`, Renderer, Export, Share Extension, batch
  processing, Photo Library behavior, and production behavior were not changed.
- `ExpressionLookup`, `ExpressionValue`, `ExpressionContext`,
  `ExpressionModuleConfiguration`, `Expression_System_Contract.md`, and
  ADR-007 were not modified.

Verification:

- Configuration Center preview regression tests passed:
  - `ConfigurationCenterPreviewCompositionHelperTests`
- Location / Expression configuration tests passed:
  - `LocationConfigurationAdapterTests`
  - `LocationExpressionPhase4DTests`
- `git diff --check` passed.
- `PhotoMemo` Debug build passed.

## 2026-07-06 PI-13D Model Provider Production Adoption frozen

PI-13D completed the approved model-only production adoption seam without
changing platform contracts, renderer layout/drawing, export behavior, share
extension behavior, photo-library behavior, or provider token support.

Boundary scan artifact:

- `Docs/02_Architecture/PI-13D_Model_Provider_Production_Adoption_Boundary_Scan.md`

Prerequisite checkpoints:

- `e10fc1ff` freezes the PI-13 production lookup scan with no direct
  implementation seam approved.
- `2506c378` freezes the production `ExpressionLookup` source definition.
- `36330b66` freezes the token-level production provider parity gate.
- `18b7c342` proves `MetadataProvider[model]` parity with the current legacy
  production lookup value.
- `dce18405` freezes the PI-13D model-only production adoption seam.

Implementation checkpoint:

- `0aca215` adopts `MetadataProvider[model]` at the text lookup seam by
  projecting provider output through `ExpressionContextMetadataAdapter` into
  the legacy `MetadataContext[model]` lookup used by `CardTextBlockEngine`.

Architectural delta:

```text
Production model authority: legacy MetadataContext[model] -> parity-proven MetadataProvider[model] projected into legacy lookup
```

Scope review:

- Only the approved `model` token was adopted.
- `ExpressionContextMetadataAdapter` now projects
  `ExpressionContext[model] -> MetadataContext[model]`.
- `CardTextBlockEngine` still builds the legacy `CardVariableProvider` base
  context, overlays the parity-proven provider model projection, and continues
  to pass `ExpressionLookup` into `TemplateVariableEngine`.
- `location` and `memory` production adoption remain blocked.
- `MetadataProvider` token support was not expanded.
- `ExpressionLookup`, `ExpressionValue`, `ExpressionContext`,
  `ExpressionModuleConfiguration`, `Expression_System_Contract.md`, and
  ADR-007 were not modified.
- `CardVariableProvider`, `RecordCard`, `RecordCardBuildService`,
  `TemplateVariableEngine`, Renderer, Export, Share Extension, batch
  processing, Photo Library behavior, and Layout Engine behavior were not
  changed.

Verification:

- RED confirmed PI-13D adapter and approved-seam tests failed before
  implementation.
- PI-13D focused tests passed:
  - `ExpressionContextMetadataAdapterTests`
  - `RendererDependencyIsolationTests`
  - `MetadataProviderTests`
- `git diff --check` passed.
- `PhotoMemo` Debug build passed.

## 2026-07-06 PI-14 Memory Provider Production Parity frozen

PI-14 completed a test-only parity proof for Memory provider production
adoption. It does not adopt Memory provider output as production authority.

Boundary scan artifact:

- `Docs/02_Architecture/PI-14_Memory_Provider_Production_Parity_Boundary_Scan.md`

Checkpoints:

- `82b197f` freezes the PI-14 scan conclusion:
  `MemoryProvider[memory]` may receive a focused parity proof only.
- `750d74d` proves that, for the same frozen production Memory input,
  `ProductionMemoryResolver` and `MemoryProvider[memory]` produce identical
  resolved text.

Architectural delta:

```text
Memory provider production adoption: blocked -> parity proven, adoption still requires a separate approved seam
```

Scope review:

- PI-14 added tests only.
- Memory provider output does not become production authority in PI-14.
- `location` production adoption remains blocked.
- `MemoryProvider`, `MemoryExpressionEngine`,
  `MemoryResultPresentationAdapter`, `ProductionMemoryResolver`,
  `ExpressionContextMetadataAdapter`, `CardVariableProvider`, `RecordCard`,
  `RecordCardBuildService`, Renderer, Export, Share Extension, batch
  processing, Photo Library behavior, and Layout Engine behavior were not
  changed.
- `ExpressionLookup`, `ExpressionValue`, `ExpressionContext`,
  `ExpressionModuleConfiguration`, `Expression_System_Contract.md`, and
  ADR-007 were not modified.

Verification:

- `MemoryProviderTests` passed.
- Memory production regression tests passed:
  - `ProductionMemoryResolverTests`
  - `MemoryResultContractTests`
- `git diff --check` passed.
- `PhotoMemo` Debug build passed.

## 2026-07-06 PI-15 Memory Provider Production Adoption Scan frozen

PI-15 completed the Memory provider production adoption scan after PI-14
proved text parity. No implementation seam is approved.

Boundary scan artifact:

- `Docs/02_Architecture/PI-15_Memory_Provider_Production_Adoption_Boundary_Scan.md`

Checkpoint:

- `3467eaa` freezes the scan conclusion:
  Memory provider production adoption remains blocked until a production
  Expression value carrier/source decision exists.

Architectural delta:

```text
Memory provider production adoption: parity proven -> blocked pending production expression value carrier
```

Scope review:

- PI-15 performed no implementation.
- `CardTextBlockEngine` cannot run `MemoryProvider` at the approved text seam
  because it has `RecordCard`, not `MemoryExpressionContext`.
- Using `RecordCard.memoryModule.renderedText` would preserve text, but would
  bypass `MemoryProvider` and create a parallel production expression source.
- Running `MemoryProvider` in `RecordCardBuildService` would require an
  approved carrier for provider-produced values across the production card
  boundary.
- `location` production adoption remains blocked.
- `ExpressionLookup`, `ExpressionValue`, `ExpressionContext`,
  `ExpressionModuleConfiguration`, `Expression_System_Contract.md`, and
  ADR-007 were not modified.
- `MemoryProvider`, `ProductionMemoryResolver`,
  `ExpressionContextMetadataAdapter`, `CardVariableProvider`, `RecordCard`,
  `RecordCardBuildService`, Renderer, Export, Share Extension, batch
  processing, Photo Library behavior, and Layout Engine behavior were not
  changed.

Required follow-up:

```text
Production Expression Value Carrier
```

## 2026-07-06 PI-16 Production Expression Value Carrier frozen

PI-16 completed the approved carrier-only implementation. Provider-produced
Memory expression values are now carried through the production Memory payload
and `RecordCard`, but they are not consumed by text lookup.

Boundary scan artifact:

- `Docs/02_Architecture/PI-16_Production_Expression_Value_Carrier_Boundary_Scan.md`

Checkpoints:

- `d340345` freezes the approved carrier-only seam:
  `ProductionMemoryResolver -> ExpressionContext[memory] ->
  ProductionMemoryPayload.productionExpressionContext ->
  RecordCard.productionExpressionContext`.
- `6ab34aa` implements the inert production expression carrier.

Architectural delta:

```text
Production expression value carrier: absent -> inert ExpressionContext on production payload/card
```

Scope review:

- `ProductionMemoryResolver` produces `ExpressionContext[memory]` from the
  existing canonical Memory input through `MemoryProvider`.
- `ProductionMemoryPayload` carries the optional expression context.
- `RecordCardBuildService` forwards the expression context only; it does not
  construct provider values or change template lookup.
- `RecordCard` carries the optional production expression context for future
  approved adoption seams.
- `CardTextBlockEngine`, `ExpressionContextMetadataAdapter`,
  `CardVariableProvider`, Renderer, Export, Share Extension, batch
  processing, Photo Library behavior, and Layout Engine behavior were not
  changed.
- Memory provider output is still not production text authority.
- `ExpressionLookup`, `ExpressionValue`, `ExpressionContext`,
  `ExpressionModuleConfiguration`, `Expression_System_Contract.md`, and
  ADR-007 were not modified.

Verification:

- RED confirmed the carrier tests failed before implementation.
- PI-16 focused tests passed:
  - `ProductionMemoryResolverTests`
  - `RecordCardBuildServiceTests`
  - `RendererDependencyIsolationTests`
- Memory / provider regression tests passed:
  - `MemoryProviderTests`
  - `MemoryResultContractTests`
- `git diff --check` passed.
- `PhotoMemo` Debug build passed.

## 2026-07-06 PI-17 Memory Provider Production Adoption frozen

PI-17 completed the approved memory-only production adoption seam.
The parity-proven and carried `MemoryProvider[memory]` value now projects into
legacy `MetadataContext[memory_summary]` at the text lookup seam.

Boundary scan artifact:

- `Docs/02_Architecture/PI-17_Memory_Provider_Production_Adoption_Boundary_Scan.md`

Checkpoints:

- `1d073a2` freezes the approved memory-only adoption seam.
- `2686649` adopts the carried Memory provider value at the text lookup seam.

Architectural delta:

```text
Production memory authority: legacy MetadataContext[memory_summary] -> parity-proven MemoryProvider[memory] projected into legacy lookup
```

Scope review:

- Only the approved `memory` token was adopted.
- `ExpressionContextMetadataAdapter` now projects
  `ExpressionContext[memory] -> MetadataContext[memory_summary]`.
- `CardTextBlockEngine` overlays `RecordCard.productionExpressionContext`
  through the legacy adapter after the existing model overlay.
- `CardTextBlockEngine` does not call `MemoryProvider`; it consumes carried
  provider-neutral values only.
- `RecordCardBuildService` remains forwarding-only and does not own provider
  policy.
- `location` production adoption remains blocked.
- `MemoryProvider`, `ProductionMemoryResolver`, `CardVariableProvider`,
  `RecordCard`, `RecordCardBuildService`, Renderer, Export, Share Extension,
  batch processing, Photo Library behavior, and Layout Engine behavior were
  not changed in PI-17.
- `ExpressionLookup`, `ExpressionValue`, `ExpressionContext`,
  `ExpressionModuleConfiguration`, `Expression_System_Contract.md`, and
  ADR-007 were not modified.

Verification:

- RED confirmed PI-17 adapter and text-seam tests failed before
  implementation.
- PI-17 focused tests passed:
  - `ExpressionContextMetadataAdapterTests`
  - `RendererDependencyIsolationTests`
- Production Memory regression tests passed:
  - `RecordCardBuildServiceTests`
  - `ProductionMemoryResolverTests`
  - `MemoryProviderTests`
  - `MemoryResultContractTests`
- `git diff --check` passed.
- `PhotoMemo` Debug build passed.

## 2026-07-06 PI-18 Location Provider Production Parity frozen

PI-18 completed the Location provider production parity scan and focused
evidence tests. No production adoption seam is approved.

Boundary scan artifact:

- `Docs/02_Architecture/PI-18_Location_Provider_Production_Parity_Boundary_Scan.md`

Checkpoints:

- `dbc1313` freezes the PI-18 scan conclusion:
  `LocationExpressionProvider[location]` is not output-identical to legacy
  `MetadataContext[location_display]`.
- `6dd9da4` adds focused mismatch proof tests for full hierarchy, POI /
  location name, and coordinate fallback cases.

Architectural delta:

```text
Location provider production adoption: blocked -> mismatch proven, product decision required
```

Scope review:

- PI-18 performed evidence-only testing after the scan.
- Location provider output does not become production authority.
- `model` and `memory` production adoption remain unchanged.
- `LocationExpressionProvider`, `LocationResolver`, `LocationFormatter`,
  `PhotoMetadata.locationDisplay`, `MetadataContext.build(from:)`,
  `ExpressionContextMetadataAdapter`, `CardTextBlockEngine`,
  `CardVariableProvider`, `RecordCard`, `RecordCardBuildService`, Renderer,
  Export, Share Extension, batch processing, Photo Library behavior, and
  Layout Engine behavior were not changed.
- `ExpressionLookup`, `ExpressionValue`, `ExpressionContext`,
  `ExpressionModuleConfiguration`, `Expression_System_Contract.md`, and
  ADR-007 were not modified.

Required product decision:

```text
Location production authority:
keep legacy location_display, accept canonical provider output change, or
approve a legacy-compatible Location provider mode.
```

Verification:

- `LocationProviderProductionParityTests` passed.
- Location regression tests passed:
  - `LocationExpressionPhase4DTests`
  - `LocationExpressionPhase3Tests`
  - `LocationConfigurationAdapterTests`
- `git diff --check` passed.
- `PhotoMemo` Debug build passed.

## 2026-07-06 PI-19 Legacy-Compatible Location Mode frozen

PI-19 completed the approved product decision from PI-18: production-visible
location output must remain legacy-compatible before Location provider
authority can move forward.

Boundary scan artifact:

- `Docs/02_Architecture/PI-19_Legacy_Compatible_Location_Mode_Boundary_Scan.md`

Checkpoints:

- `848fe96` freezes the PI-19 scan conclusion:
  add a Location-domain `legacyDisplay` presentation mode rather than changing
  production output or modifying platform contracts.
- `18e2b6e` adds `LocationPresentationMode.legacyDisplay`, updates
  `LocationResolver` and `LocationFormatter`, and proves
  `LocationExpressionProvider[legacyDisplay]` matches legacy
  `MetadataContext[location_display]` for representative hierarchy, POI /
  location name, and coordinate fallback cases.

Architectural delta:

```text
Location provider parity: unavailable -> legacy-compatible presentation mode available
```

Scope review:

- PI-19 changed only the approved Location-domain seam:
  `LocationPresentationMode`, `LocationResolver`, `LocationFormatter`, and
  focused Location provider parity tests.
- Production adoption is still not connected in PI-19.
- Renderer, Export, Share Extension, batch processing, Metadata mutation,
  Photo Library behavior, Layout Engine behavior, and production lookup wiring
  were not changed.
- `ExpressionLookup`, `ExpressionValue`, `ExpressionContext`,
  `ExpressionModuleConfiguration`, `Expression_System_Contract.md`, and
  ADR-007 were not modified.

Verification:

- PI-19 focused parity tests passed:
  - `LocationProviderProductionParityTests`
- Location regression tests passed:
  - `LocationExpressionPhase2Tests`
  - `LocationExpressionPhase3Tests`
  - `LocationExpressionPhase4DTests`
  - `LocationConfigurationAdapterTests`
- `git diff --check` passed.
- `PhotoMemo` Debug build passed.

Next approved work:

- PI-20 should begin with a Location Provider Production Adoption boundary
  scan. It must not connect production adoption directly without first
  freezing the approved seam.

## 2026-07-06 PI-20 Location Provider Production Adoption Scan frozen

PI-20 completed discovery for Location provider production adoption after
PI-19 proved the legacy-compatible provider mode.

Boundary scan artifact:

- `Docs/02_Architecture/PI-20_Location_Provider_Production_Adoption_Boundary_Scan.md`

Checkpoint:

- `d3acf93` freezes the approved production adoption seam:
  use `LocationContextBuilder` and
  `LocationExpressionProvider[location, legacyDisplay]` at the existing
  `CardTextBlockEngine` text lookup overlay, then project through the existing
  `ExpressionContextMetadataAdapter` into `MetadataContext[location_display]`.

Architectural delta:

```text
Production location authority: legacy MetadataContext[location_display] -> parity-proven LocationProvider[legacyDisplay] projected into legacy lookup
```

Scope review:

- PI-20 is a scan-only freeze; no production adoption code has been added yet.
- The only approved future implementation surface is the existing text
  resolution overlay in `CardTextBlockEngine`.
- `PhotoMetadata.locationDisplay`, `MetadataContext.build(from:)`,
  `CardVariableProvider`, `RecordCard`, `RecordCardBuildService`, Renderer,
  Export, Share Extension, batch processing, Photo Library behavior, and
  Layout Engine behavior remain out of scope.
- `ExpressionLookup`, `ExpressionValue`, `ExpressionContext`,
  `ExpressionModuleConfiguration`, `Expression_System_Contract.md`, and
  ADR-007 must remain unchanged.

Implementation readiness:

- PI-20 implementation may proceed only inside the approved seam.
- Required tests must prove `{{location_display}}` resolves through the
  provider-backed legacy-compatible value without visible output change for
  POI / location name, full hierarchy with country, and coordinate fallback.

## 2026-07-06 PI-20 Location Provider Production Adoption frozen

PI-20 completed the approved Location provider production adoption seam.
Production text lookup now overlays the parity-proven
`LocationExpressionProvider[location, legacyDisplay]` value before
`{{location_display}}` is resolved.

Implementation checkpoint:

- `dd5d156` adopts the legacy-compatible Location provider value inside the
  approved `CardTextBlockEngine` text lookup seam.

Architectural delta:

```text
Production location authority: legacy MetadataContext[location_display] -> parity-proven LocationProvider[legacyDisplay] projected into legacy lookup
```

Scope review:

- The approved seam was the only implementation surface modified:
  `CardTextBlockEngine -> MetadataContextExpressionLookup`.
- `LocationContextBuilder` and `LocationExpressionProvider[legacyDisplay]`
  are consumed from `card.metadata`; no new production carrier is introduced.
- `CardVariableProvider`, `RecordCard`, `RecordCardBuildService`,
  `PhotoMetadata.locationDisplay`, `MetadataContext.build(from:)`, Renderer,
  Export, Share Extension, batch processing, Photo Library behavior, and
  Layout Engine behavior were not changed.
- `ExpressionLookup`, `ExpressionValue`, `ExpressionContext`,
  `ExpressionModuleConfiguration`, `Expression_System_Contract.md`, and
  ADR-007 were not modified.

Verification:

- RED confirmed PI-20 boundary and location text authority tests failed before
  implementation.
- PI-20 focused tests passed:
  - `RendererDependencyIsolationTests`
- Location parity and regression tests passed:
  - `LocationProviderProductionParityTests`
  - `LocationExpressionPhase2Tests`
  - `LocationExpressionPhase3Tests`
  - `LocationExpressionPhase4DTests`
  - `LocationConfigurationAdapterTests`
- `git diff --check` passed.
- `PhotoMemo` Debug build passed.

## 2026-07-05 High-Resolution Media Intake Foundation started

The RAW / high-resolution media work has started as a bounded intake
foundation sprint, not as renderer or export-quality work.

Scope frozen for this sprint:

- establish canonical, memory-safe, file-first media intake for high-resolution
  assets
- keep RAW / DNG / HEIC / TIFF complexity before the rendering pipeline
- preserve Renderer, Export Contract, Memory Pipeline, Photo Library behavior,
  and Live Photo output boundaries

Completed checkpoints:

- Media Intake Convergence:
  - `ExternalPhotoIntakeCenter` and V1 Quick Action URL filtering now use
    `PhotoProcessingInputPolicy` instead of local extension lists.
  - RAW / DNG policy support is covered by focused tests.
- File-first PhotosPicker import:
  - Main App PhotosPicker now prefers `CoreTransferable` file
    representations before falling back to `Data`.
  - Picked RAW-like file representations are copied into an app-owned
    temporary location before import.
  - `MediaIntakeFileFirstContractTests` now guards the ordering contract for
    Main App PhotosPicker, V1 Quick Action PhotosPicker, and Share Extension
    intake so `Data` / `loadItem` paths remain fallback-only.
- Thin canonical media representation:
  - `MediaAsset`, `MediaRepresentation`, and `DecodePurpose` now exist as the
    first internal media facts model.
  - `PhotoImportService` attaches a canonical `MediaAsset` and preview
    representation to `SelectedPhoto`.
  - RAW detection and Live Photo detection remain routed through
    `PhotoProcessingInputPolicy`.
- Memory Budget thin policy:
  - `MediaCost` and `MediaMemoryBudget` now classify normal, high, and
    critical media work from canonical media facts or file-backed ImageIO
    properties.
  - `BatchQueueExecution` now derives RAW / high-resolution preview
    preparation progress from `MediaMemoryBudget` instead of a local RAW-only
    branch.
  - Queue behavior remains serial in this increment; no renderer, export
    contract, Memory Pipeline, or Photo Library behavior was changed.
- Diagnostics & Import Report:
  - `MediaImportReport` now derives support-safe import facts from
    `MediaAsset`, preview `MediaRepresentation`, and `MediaMemoryBudget`.
  - The report is `Codable` and contains media identity, format facts, pixel
    size, memory tier, preview downsample facts, and decode purpose.
  - The report does not persist or copy image bytes, and remains a derived model
    instead of a new diagnostics service in this slice.
  - `PhotoImportService` now rejects unsupported or oversized media through
    `PhotoProcessingInputPolicy` before preview decode, and surfaces the
    policy title, message, and rejection reason through `PhotoImportError`.
  - Main App PhotosPicker and File Import unsupported preflight messages now
    use `PhotoProcessingInputPolicy` verdict title/message instead of a generic
    unsupported-format string.
  - Main App import error presentation now includes `LocalizedError.failureReason`
    so policy rejections can show both the diagnostic title and the concrete
    reason.
  - V1 Quick Action no-supported-photo feedback now uses
    `PhotoProcessingInputPolicy` diagnostics when the selected providers expose
    unsupported content types, while preserving the existing fallback when no
    concrete rejection is known.
  - Share Extension unsupported skips now preserve policy rejection facts in
    `PhotoMemoMediaIntakeRejectionReport` and carry them through
    `PhotoMemoShareExtensionImportResult` for diagnostic summaries without
    turning skipped unsupported media into failed imports.
- Single Decode Entry foundation:
  - `MediaDecodeService` is now the app-side media decode layer for
    `PhotoImportService` preview image preparation.
  - `PhotoImportService` no longer owns direct ImageIO, CoreImage, data-backed
    platform-image fallback, or thumbnail decode details.
  - `PhotoSourceInfo` now lives with the shared media model so `MediaAsset`
    remains buildable in the Share Extension target.
  - `MediaDecodeService` now lives in the shared media model layer so the Share
    Extension can use the same decode boundary without importing the app
    service graph.
  - `PlatformImage` helpers and `PhotoImportError` are now shared thin model
    utilities instead of being owned by `SelectedPhoto` / `PhotoImportService`.
  - Share Extension file-preview thumbnails now delegate to
    `MediaDecodeService.thumbnailImage(from:maxPixelDimension:)`; the share
    controller no longer contains direct ImageIO thumbnail decode calls.
  - Share Extension preview `Data` fallback now also delegates to
    `MediaDecodeService.thumbnailImage(from:maxPixelDimension:)` so fallback
    previews stay downsampled and do not decode provider data directly in the
    view controller.
- Renderer Isolation contract:
  - `MediaDecodeLayerContractTests` now scans renderer sources for source-media
    format decisions such as RAW / DNG / HEIC / TIFF, `UTType`, ImageIO, or
    CoreImage usage.
  - This keeps high-resolution media complexity on the intake/decode side and
    prevents future RAW work from adding renderer-facing format branches.

Verification completed:

- focused intake/import/policy tests
- `MediaMemoryBudgetTests`
- `MediaDecodeLayerContractTests`
- full `PhotoImportServiceTests`
- focused RAW-like import report encode/decode test
- `BatchFixtureCoverageTests`
- `git diff --check`
- `PhotoMemo` Debug build
- `PhotoMemoShareExtension` iOS Simulator build

Latest decode convergence verification:

- `MediaDecodeLayerContractTests`
- Share Extension preview file and data fallback decode isolation
- renderer source media-format isolation contract
- `MediaIntakeFileFirstContractTests`
- Main App intake policy-diagnostics contract for unsupported preflight
  messages
- Main App import error diagnostic reason contract
- `PhotoMemoiOSV1PhotoIntakeTests` coverage for V1 Quick Action unsupported
  policy diagnostic messages
- `PhotoImportServiceTests`
- policy-backed unsupported format / oversized dimension import rejection
- `PhotoMemoShareIntakeDiagnosticsTests` coverage for codable rejection
  reports and Share Extension unsupported skip report preservation
- `git diff --check`
- `PhotoMemo` Debug build
- `PhotoMemoShareExtension` iOS Simulator build

## 2026-07-05 IA-003 Production Pipeline Convergence complete

IA-003 is now complete for the V1 Memory production pipeline.

Completion summary:

- `ConfigurationSnapshot` is the canonical production Memory model.
- `BatchConfigurationSnapshot` remains as a transport / legacy DTO and is not
  the place for new Memory production semantics.
- App production snapshots carry frozen `ConfigurationSnapshot` input through
  `canonicalProductionSnapshot`.
- App and Share Extension build services no longer read runtime
  `UserDefaults` or `photomemo.personalProfile` during production build.
- `ProductionMemoryResolver` consumes frozen input first and has no live
  defaults dependency.
- `MemoryExpressionEngine` outputs structured `MemoryResult`; presentation
  adapters own final text projection.
- Preview/export Memory Expression WYSIWYG is regression-tested through the
  frozen MemoryResult path.

Boundaries maintained:

- Renderer remains the locked V1 Output Contract.
- No Layout Engine, Photo Library, Metadata, or renderer evolution was added.
- Naming Freeze, broad legacy cleanup, helper cleanup, and stub removal are
  post-IA-003 engineering hygiene.

Verification completed:

- IA-003 focused test group
- `git diff --check`
- `PhotoMemo` Debug build
- `PhotoMemoShareExtension` iOS Simulator build

## 2026-07-05 Batch DTO frozen writes isolated

IA-003 Snapshot Convergence tightened the remaining mutable DTO boundary.

Scope:

- `BatchConfigurationSnapshot.frozenMemorySubject` and
  `frozenConfigurationSnapshot` are now `private(set)` compatibility fields.
- Canonical production input is written through
  `withCanonicalProductionSnapshot(_:)`.
- Historical paired-subject compatibility is written only through explicitly
  named legacy helpers:
  - `withLegacyPairedFrozenMemoryConfiguration(...)`
  - `withLegacyFrozenMemorySubject(_:)`
- Removed the lower-signal `withFrozenConfigurationSnapshot(_:)` writer.
- Updated resolver, build-service, batch-history, and share-summary tests away
  from direct DTO frozen-field mutation.
- Strengthened `MemoryResultContractTests` so production source cannot call the
  legacy frozen-subject writers and so frozen DTO fields remain write-protected.

Why this matters:

- `BatchConfigurationSnapshot` remains Codable-compatible as a transport /
  legacy DTO.
- New production semantics are harder to add accidentally to the DTO because
  direct frozen-field mutation is no longer available outside the model.
- `ConfigurationSnapshot` remains the canonical production model while legacy
  migration paths stay explicit and reviewable.

Verification completed:

- `MemoryResultContractTests`
- IA-003 focused tests
- `git diff --check`
- `PhotoMemo` Debug build
- `PhotoMemoShareExtension` iOS Simulator build

## 2026-07-05 Production resolver runtime defaults removed

IA-003 Stage 3 closed the remaining resolver-level runtime configuration
dependency.

Scope:

- Removed `ProductionMemoryResolver(legacyDefaults:)`.
- Removed `ProductionMemoryResolver` storage and reads of `UserDefaults`.
- Legacy runtime fallback now uses only `BatchConfigurationSnapshot` DTO input
  plus a safe default `PersonalProfile`.
- Updated resolver and BuildService tests away from runtime defaults injection.
- Strengthened `MemoryResultContractTests` so `ProductionMemoryResolver` cannot
  regain `UserDefaults`, `legacyDefaults`, or direct personal profile defaults
  reads.

Why this matters:

- The production Memory resolver is now independent of running app state.
- Submit-time freeze remains the only path for user-specific Memory
  configuration to enter production.
- Legacy DTO compatibility still exists, but it can no longer refill production
  semantics from live defaults.

Verification completed:

- `ProductionMemoryResolverTests`
- `MemoryResultContractTests`
- IA-003 focused tests
- `git diff --check`
- `PhotoMemo` Debug build
- `PhotoMemoShareExtension` iOS Simulator build

## 2026-07-05 App BuildService runtime defaults entry closed

IA-003 Stage 3 moved from named fallback to app production closure for
`RecordCardBuildService`.

Scope:

- Removed the app-side `RecordCardBuildService(legacyDefaults:)` initializer.
- App `RecordCardBuildService` now constructs `ProductionMemoryResolver()`
  without any runtime defaults dependency.
- Updated BuildService tests to use frozen Memory input instead of injecting
  runtime profile defaults.
- At this point, `ProductionMemoryResolver(legacyDefaults:)` still existed as a
  direct compatibility fallback; it was removed in the follow-up resolver
  closure recorded above.
- Strengthened `MemoryResultContractTests` so the app BuildService cannot
  regain a `legacyDefaults` parameter.

Why this matters:

- The normal app production build path no longer has a runtime configuration
  injection point.
- Runtime profile defaults are no longer available to production through
  `RecordCardBuildService`.
- The remaining `legacyDefaults` access was isolated below the production
  service boundary at this step, then removed in the resolver closure recorded
  above.

Verification completed:

- IA-003 focused tests
- `git diff --check`
- `PhotoMemo` Debug build
- `PhotoMemoShareExtension` iOS Simulator build

## 2026-07-05 Canonical production snapshot projection named

IA-003 Stage 1/2 convergence moved another step toward a single production
model.

Scope:

- Added `BatchConfigurationSnapshot.canonicalProductionSnapshot` as the
  production-facing projection for the frozen `ConfigurationSnapshot`.
- Production paths now consume the canonical projection in:
  - `ProductionMemoryResolver`
  - `RecordCardBuildService`
  - `PhotoMemoShareWorkflowSummaryBuilder`
- Kept `completedFrozenConfigurationSnapshot` as a compatibility alias instead
  of deleting it.
- Added `withCanonicalProductionSnapshot(_:)` and moved app snapshot creation
  to that naming.
- Removed the app-side `RecordCardBuildService` stored defaults reference.
- At this point, the remaining explicit compatibility injection point was
  renamed to `legacyDefaults`; the follow-up resolver closure above removed it
  entirely.
- Extended `MemoryResultContractTests` to guard canonical production snapshot
  use and prevent production paths from returning to the old completed-snapshot
  naming.

Why this matters:

- `ConfigurationSnapshot` is now named as the canonical production input at the
  production read boundary.
- `BatchConfigurationSnapshot` remains a transport / compatibility DTO without
  becoming the place for new production semantics.
- The app build service no longer carries runtime configuration state, and the
  remaining resolver fallback is named as legacy compatibility.

Verification completed:

- `MemoryResultContractTests`
- IA-003 focused tests
- `git diff --check`
- `PhotoMemo` Debug build
- `PhotoMemoShareExtension` iOS Simulator build

## 2026-07-05 IA-003 testing IPA packaged

Generated a new signed `PhotoMemoiOSV1` testing IPA from the current working
tree after IA-003 Production Pipeline Convergence completion.

Output:

- `/Users/rui/Desktop/photomemo过程中测试版本软件/PhotoMemoiOSV1-main-6fee4d45-20260705143030.ipa`
- `/Users/rui/Desktop/photomemo过程中测试版本软件/PhotoMemoiOSV1-main-6fee4d45-20260705143030.ipa.sha256`

Packaging policy maintained:

- The desktop testing folder keeps only the latest `.ipa` and matching
  `.sha256`.
- Package name follows
  `PhotoMemoiOSV1-main-<commit>-<timestamp>.ipa`.

IPA metadata verified:

- bundle id: `com.serydoo.PhotoMemo.iOS`
- short version: `1.0`
- bundle version: `1`
- embedded extensions:
  - `PhotoMemoShareExtension.appex`
  - `PhotoMemoWidgetExtension.appex`
- sha256:
  `c66f201b9ce6e83cb88078f6f0729df7e3bff674959a2049351851768b7271cf`

Verification completed:

- `PhotoMemoiOSV1` generic iOS build with signing disabled
- `PhotoMemoiOSV1` signed generic iOS archive
- testing IPA export via `scripts/export_options_v1_testing.plist`
- exported IPA metadata / embedded extension inspection

## 2026-07-05 Legacy DTO anchor and subject text projections named

The remaining app production paths no longer read legacy
`BatchConfigurationSnapshot.anchor` and `memorySubjectText` fields directly.

Scope:

- Added named legacy projections:
  - `BatchConfigurationSnapshot.legacyAnchor`
  - `BatchConfigurationSnapshot.legacyMemorySubjectText`
- `ProductionMemoryResolver` legacy runtime fallback now reads the old anchor
  through `legacyAnchor`.
- `RecordCardBuildService` legacy fallback now reads the old anchor and subject
  text through the named projections.
- `PhotoMemoShareWorkflowSummaryBuilder` uses the same legacy anchor projection
  after the frozen snapshot path is unavailable.
- `MainView` memory progress summary now uses
  `resolvedProductionAnchorTitle`, aligning its displayed anchor title with
  the frozen production snapshot rule.
- `MemoryResultContractTests` guards that production paths use named legacy DTO
  projections instead of direct field reads.

Why this matters:

- `BatchConfigurationSnapshot` remains compatible as a transport DTO, but
  production code now has explicit legacy access points.
- This reduces the chance that legacy fields are mistaken for canonical
  production truth while preserving old snapshot compatibility.

Boundaries maintained:

- Renderer, Export, Share Extension behavior, Photo Library behavior, Layout
  Engine, and UI architecture were not modified.

Verification completed:

- IA-003 focused tests
- `git diff --check`
- `PhotoMemo` Debug build
- `PhotoMemoShareExtension` iOS Simulator build

## 2026-07-05 Share workflow summary follows frozen production anchor

The app-side share workflow summary now uses the same completed frozen snapshot
authority as the production build and batch status surfaces.

Scope:

- `PhotoMemoShareWorkflowSummaryBuilder` now prefers
  `BatchConfigurationSnapshot.completedFrozenConfigurationSnapshot` for the
  Memory Date summary in the app target.
- A frozen `ConfigurationSnapshot.primaryAnchor` overrides the legacy
  `BatchConfigurationSnapshot.anchor` summary.
- A complete frozen `ConfigurationSnapshot` with no `primaryAnchor` keeps
  "no Memory Date" authoritative instead of refilling from the legacy batch
  anchor.
- Share Extension summary behavior is preserved through conditional
  compilation; the extension continues using its legacy-compatible snapshot
  fields.

Why this matters:

- External/share intake surfaces no longer display legacy Memory Date text that
  disagrees with the frozen production input.
- `BatchConfigurationSnapshot.anchor` is further reduced to compatibility /
  transport fallback instead of acting as a second production truth.

Boundaries maintained:

- Renderer, Export, Share Extension behavior, Photo Library behavior, Layout
  Engine, and UI architecture were not modified.

Verification completed:

- `PhotoMemoShareWorkflowSummaryTests`
- IA-003 focused tests
- `git diff --check`
- `PhotoMemo` Debug build
- `PhotoMemoShareExtension` iOS Simulator build

## 2026-07-05 App build service default path no longer injects live defaults

The app-side `RecordCardBuildService` default path now starts without a live
`UserDefaults` dependency.

Scope:

- `RecordCardBuildService()` now defaults to `defaults: nil` for the app target.
- `AppEnvironment.live` no longer injects shared defaults into the app
  production build service.
- Share Extension behavior is preserved with its existing shared-defaults
  default initializer.
- Legacy runtime defaults fallback remains available only through an explicit
  `RecordCardBuildService(defaults:)` or `ProductionMemoryResolver(defaults:)`
  injection.

Why this matters:

- Normal app preview, queue, batch, and export build paths are pushed further
  toward frozen-input-only consumption.
- Runtime defaults are no longer carried by the default production build
  service merely because the service was constructed.
- Legacy fallback stays possible for compatibility tests and historical inputs,
  but it is now an explicit opt-in dependency.

Boundaries maintained:

- Renderer, Export, Share Extension behavior, Photo Library behavior, Layout
  Engine, and UI architecture were not modified.

Verification completed:

- `MemoryResultContractTests`
- IA-003 focused tests
- `git diff --check`
- `PhotoMemo` Debug build
- `PhotoMemoShareExtension` iOS Simulator build

## 2026-07-05 ProductionMemoryResolver default path no longer captures live defaults

`ProductionMemoryResolver` now defaults to a frozen-input-first resolver with
no implicit shared `UserDefaults` dependency.

Scope:

- `ProductionMemoryResolver.defaults` is optional.
- The default initializer now uses `defaults: nil`.
- Legacy runtime defaults are still supported only when a caller explicitly
  injects `UserDefaults`.
- `RecordCardBuildService` continues injecting its existing defaults so legacy
  batch fallback behavior remains compatible while frozen paths stay isolated.

Why this matters:

- Direct frozen `ConfigurationSnapshot` resolution can now be used without
  carrying live runtime state.
- The remaining live defaults dependency is easier to audit because it is an
  explicit legacy fallback dependency rather than resolver construction
  behavior.

Boundaries maintained:

- Renderer, Export, Share Extension behavior, Photo Library behavior, Layout
  Engine, and UI architecture were not modified.

Verification completed:

- `MemoryResultContractTests`
- `ProductionMemoryResolverTests`
- IA-003 focused tests

## 2026-07-05 Preview and Export Memory Expression contract guarded

A device feedback item reported that Configuration Preview could show the
correct Memory Expression while final export fell back to legacy subject /
anchor wording.

Current code review result:

- Preview and export now both resolve Memory through:

```text
MemoryExpressionEngine.generateResult
    ↓
MemoryResultPresentationAdapter
```

- App production freezes the current `MemorySubject` and
  `ConfigurationSnapshot` before build/export.
- `RecordCardBuildService` publishes the resolved `MemoryResult` and
  `MemoryModule` into `RecordCard`.
- `CardVariableProvider` uses `RecordCard.memoryModule.renderedText` for
  `{{memory_summary}}` when frozen Memory input exists.

Regression guard added:

- `RecordCardBuildServiceTests.previewAndExportShareTheSameFrozenMemoryExpression`
  now verifies that Preview text and export `{{memory_summary}}` are identical
  for the same frozen `MemorySubject`, capture date, and expression style.

Boundary:

- Export does not reuse the preview object's in-memory instance. It consumes
  the frozen input and resolves the same `MemoryResult` shape through the same
  presentation adapter.
- This matches the current IA-003 `Submit -> Freeze -> Consume` contract.

Verification completed:

- `RecordCardBuildServiceTests`

## 2026-07-05 BuildService completed frozen snapshot authority

`RecordCardBuildService` no longer treats raw
`BatchConfigurationSnapshot.frozenConfigurationSnapshot` presence as production
authority.

Scope:

- `resolvedAnchor(...)` now suppresses legacy batch fallback only when
  `completedFrozenConfigurationSnapshot` exists.
- `resolvedTitle(...)` now treats an empty frozen primary anchor title as
  authoritative only when `completedFrozenConfigurationSnapshot` exists.
- Incomplete frozen snapshots without an embedded or paired `MemorySubject`
  continue through the legacy fallback path instead of suppressing legacy
  anchor/title data.

Why this matters:

- BuildService, ProductionMemoryResolver, and batch status projections now share
  the same completed frozen snapshot rule.
- This keeps partially migrated historical inputs compatible while preventing
  raw DTO fields from acting as a second production truth.

Boundaries maintained:

- Renderer, Export, Share Extension behavior, Photo Library behavior, Layout
  Engine, and UI architecture were not modified.

Verification completed:

- `MemoryResultContractTests`
- `RecordCardBuildServiceTests`
- IA-003 focused tests

## 2026-07-05 New snapshots stop dual-writing frozen MemorySubject

New app production snapshots no longer populate
`BatchConfigurationSnapshot.frozenMemorySubject` when a complete frozen
`ConfigurationSnapshot` is available.

Scope:

- `BatchConfigurationSnapshotProvider` now writes the frozen Memory input as:

```text
ConfigurationSnapshot.memorySubject
```

- `BatchConfigurationSnapshot.frozenMemorySubject` remains available only as a
  legacy paired-subject compatibility field for older snapshots.
- `completedFrozenConfigurationSnapshot` still completes old paired snapshots by
  embedding `frozenMemorySubject` when the snapshot lacks an embedded subject.

Why this matters:

- Newly submitted production input now has one Memory truth inside
  `ConfigurationSnapshot`.
- `BatchConfigurationSnapshot` moves one step closer to being a transport /
  compatibility DTO instead of carrying parallel domain state.

Boundaries maintained:

- Renderer, Export, Share Extension behavior, Photo Library behavior, Layout
  Engine, and UI architecture were not modified.

Verification completed:

- `BatchConfigurationSnapshotProviderDiagnosticsTests`
- `ProductionMemoryResolverTests`
- `RecordCardBuildServiceTests`
- `BatchQueueHistoryTests`

## 2026-07-05 Legacy paired frozen subject isolated behind named projection

The remaining paired `frozenMemorySubject` path is now explicitly marked as
legacy compatibility instead of appearing as a normal production write/read
API.

Scope:

- Renamed `withFrozenMemoryConfiguration(...)` to
  `withLegacyPairedFrozenMemoryConfiguration(...)`.
- Added `BatchConfigurationSnapshot.legacyFrozenMemorySubject` as the only
  production resolver projection for older snapshots that contain a frozen
  subject without a complete frozen `ConfigurationSnapshot`.
- `ProductionMemoryResolver` no longer reads
  `BatchConfigurationSnapshot.frozenMemorySubject` directly.
- `MemoryResultContractTests` now guards that production source does not call
  the legacy paired writer and that new app snapshots use
  `withFrozenConfigurationSnapshot(...)`.

Why this matters:

- New production input continues to have a single Memory truth inside
  `ConfigurationSnapshot`.
- The old paired subject field remains available for Codable compatibility and
  historical tests, but production code now treats it as a legacy projection.

Boundaries maintained:

- Renderer, Export, Share Extension behavior, Photo Library behavior, Layout
  Engine, and UI architecture were not modified.

Verification completed:

- `MemoryResultContractTests`
- IA-003 focused tests

## 2026-07-05 Batch status completed frozen snapshot authority

Batch status surfaces now use the same completed frozen snapshot rule as the
production resolver path.

Scope:

- `BatchConfigurationSnapshot.resolvedProductionAnchorTitle` now reads
  `completedFrozenConfigurationSnapshot` instead of raw
  `frozenConfigurationSnapshot`.
- Complete frozen snapshots still override legacy batch anchor titles.
- Complete frozen snapshots with no primary anchor still keep "no anchor" as an
  authoritative production decision.
- Incomplete frozen snapshots without an embedded or paired `MemorySubject` no
  longer suppress the legacy batch anchor on queue/external-intake status
  surfaces.

Why this matters:

- Status projections now follow the same "completed frozen input first" rule as
  `RecordCardBuildService` and `ProductionMemoryResolver`.
- `BatchConfigurationSnapshot` continues moving toward a compatibility DTO
  instead of acting as a second production truth.

Boundaries maintained:

- Renderer, Export, Share Extension behavior, Photo Library behavior, Layout
  Engine, and UI architecture were not modified.

Verification completed:

- `BatchQueueHistoryTests`
- IA-003 focused tests

## 2026-07-05 Paired frozen snapshot completion moved before legacy adapter

BuildService and ProductionMemoryResolver now share the same completed frozen
snapshot projection:

```text
BatchConfigurationSnapshot.frozenConfigurationSnapshot
    + frozenMemorySubject
    ↓
completedFrozenConfigurationSnapshot
    ↓
resolve(photo:frozenSnapshot:)
```

Scope:

- Added `BatchConfigurationSnapshot.completedFrozenConfigurationSnapshot`.
- The helper embeds paired `frozenMemorySubject` into older frozen snapshots
  whose `ConfigurationSnapshot.memorySubject` is missing.
- `RecordCardBuildService` now tries the completed frozen snapshot before
  falling back to `resolveLegacyBatchConfiguration(...)`.
- `ProductionMemoryResolver` also reuses the completed frozen snapshot helper
  instead of hand-writing paired snapshot completion logic.

Why this matters:

- Older paired frozen inputs can now enter the direct frozen
  `ConfigurationSnapshot` resolver path.
- The legacy batch adapter remains for compatibility, but its real work surface
  is smaller and more explicit.

Boundaries maintained:

- Renderer, Export, Share Extension behavior, Photo Library behavior, Layout
  Engine, and UI architecture were not modified.

Verification completed:

- `MemoryResultContractTests`
- `BatchQueueHistoryTests`
- `RecordCardBuildServiceTests`
- IA-003 focused tests

## 2026-07-05 Production resolver legacy batch adapter naming complete

`ProductionMemoryResolver` now names the batch DTO entry as a legacy adapter:

```text
resolveLegacyBatchConfiguration(...)
```

Scope:

- The direct frozen `ConfigurationSnapshot` resolver entry remains the primary
  production-facing path.
- The `BatchConfigurationSnapshot` resolver entry has been renamed from the
  generic `resolve(photo:configuration:)` shape to an explicit legacy adapter
  name.
- `RecordCardBuildService` still prefers the direct frozen snapshot entry and
  uses the legacy adapter only as fallback.
- Existing compatibility behavior is unchanged for old or incomplete snapshots.

Why this matters:

- `BatchConfigurationSnapshot` is now represented in resolver code as a
  compatibility transport input, not as the core production model.
- This continues Snapshot Convergence without deleting old queue/share
  compatibility paths prematurely.

Boundaries maintained:

- Renderer, Export, Share Extension behavior, Photo Library behavior, Layout
  Engine, and UI architecture were not modified.

Verification completed:

- `ProductionMemoryResolverTests`
- `MemoryResultContractTests`

## 2026-07-05 Frozen status anchor absence authority complete

Batch status surfaces now treat a frozen `ConfigurationSnapshot` with no
`primaryAnchor` as authoritative instead of refilling the missing title from
the legacy `BatchConfigurationSnapshot.anchor`.

Scope:

- `BatchConfigurationSnapshot.resolvedProductionAnchorTitle` now falls back to
  the legacy batch anchor only when no frozen `ConfigurationSnapshot` exists.
- Queue usage snapshots no longer count a legacy anchor when the frozen
  production snapshot explicitly has no primary anchor.
- External intake summaries and queued notification text use the same helper,
  so their anchor labels follow the frozen production snapshot consistently.

Why this matters:

- Frozen "no anchor" now remains "no anchor" across production-adjacent status
  surfaces.
- This closes another edge where legacy DTO fields could still override frozen
  production input.

Boundaries maintained:

- Renderer, Export, Share Extension behavior, Photo Library behavior, Layout
  Engine, and UI architecture were not modified.

Verification completed:

- `BatchQueueHistoryTests`

## 2026-07-05 MemoryResult Contract Freeze accepted

The next IA-003 convergence step has been started as a contract-first slice:

- [Docs/02_Architecture/MemoryResult_Contract_Freeze_2026-07-05.md](/Users/rui/Desktop/PhotoMemo/Docs/02_Architecture/MemoryResult_Contract_Freeze_2026-07-05.md)

Decision:

- `MemoryResult` is the structured semantic output boundary for Memory Engine.
- Memory Engine answers what it knows about frozen Memory input and capture time.
- Presentation owns final sentence composition, localization, expression style,
  and compatibility projection to current rendered text.
- `displayText`, `renderedText`, `fullSentence`, and similar final-copy fields
  are explicitly excluded from the target `MemoryResult` contract.

This is a contract freeze only. No Memory Engine implementation code has been
changed in this slice.

Implementation rule:

- Do not change the frozen `MemoryResult` contract for a single caller's display
  need. Display needs should be handled by Presentation or a compatibility
  adapter.
- Change the contract only when a new domain semantic is accepted, and update
  the contract freeze document in the same reviewed slice.
- Migration should remain one-way:

```text
Old Resolver
    ↓
MemoryResult
    ↓
Presentation Adapter
    ↓
Current UI / output path
```

Avoid long-term parallel outputs where Memory Engine directly maintains both
structured semantic output and final strings.

## 2026-07-05 ConfigurationSession MemoryResult projection slice complete

`ConfigurationSession.generatedMemoryModule` now follows the frozen
`MemoryResult` migration path internally:

```text
MemoryExpressionEngine.generateResult
    ↓
MemoryResultPresentationAdapter
    ↓
MemoryModule
```

Scope:

- Configuration Center still exposes the same `MemoryModule` compatibility
  output to existing preview/UI callers.
- The session no longer directly asks `MemoryExpressionEngine` for a final
  module string.
- A contract test now guards this migration boundary so the session path does
  not regress to direct `generateModule(...)` use.

Boundaries maintained:

- Renderer, Export, Share Extension behavior, Photo Library behavior, Layout
  Engine, and UI architecture were not modified.
- This is a caller migration slice only; `generateModule(...)` remains as a
  compatibility API while remaining callers are migrated.

Verification completed:

- `MemoryResultContractTests`

## 2026-07-05 Preview resolver MemoryResult projection slice complete

`MemoryExpressionPreviewResolver` now follows the same one-way migration path
as production and Configuration Session callers:

```text
MemoryExpressionEngine.generateResult
    ↓
MemoryResultPresentationAdapter
    ↓
Preview text
```

Scope:

- Preview resolver output remains unchanged: callers still receive the trimmed
  rendered preview text they used before.
- Source code no longer directly calls `MemoryExpressionEngine.generateModule`.
- Remaining `.generateModule(...)` references are compatibility tests around
  the legacy API.

Boundaries maintained:

- Renderer, Export, Share Extension behavior, Photo Library behavior, Layout
  Engine, and UI architecture were not modified.

Verification completed:

- `MemoryResultContractTests`

## 2026-07-05 MemoryExpressionEngine output boundary completed

`MemoryExpressionEngine` now exposes structured `MemoryResult` as its output
boundary.

Scope:

- Removed the legacy `generateModule(...)` API from `MemoryExpressionEngine`.
- Existing module projection tests now use the same production shape:

```text
MemoryExpressionEngine.generateResult
    ↓
MemoryResultPresentationAdapter
    ↓
MemoryModule compatibility projection
```

- Source callers no longer ask Memory Engine to generate final module strings.

Why this matters:

- The Memory Engine no longer owns final presentation copy.
- Presentation compatibility is explicitly handled by
  `MemoryResultPresentationAdapter`.
- The IA-003 criterion "Memory Engine outputs structured `MemoryResult`" is now
  complete at the engine boundary.

Boundaries maintained:

- Renderer, Export, Share Extension behavior, Photo Library behavior, Layout
  Engine, and UI architecture were not modified.

Verification completed:

- `MemoryResultContractTests`
- `MemoryExpressionEngineTests`

## 2026-07-05 Frozen anchor status projection slice complete

Batch status surfaces now prefer the frozen production anchor title over the
legacy batch anchor title.

Scope:

- Added `BatchConfigurationSnapshot.resolvedProductionAnchorTitle`.
- `BatchQueueHistory.usageSnapshot(...)` now counts anchor usage from the
  frozen `ConfigurationSnapshot.primaryAnchor` when available.
- `BatchQueueHistory.latestExternalIntakeSummary(...)` now reports the frozen
  anchor title when available.
- Batch queued notification text now uses the same frozen-first anchor helper.

Why this matters:

- Queue history, external intake summaries, and notifications no longer mix a
  frozen Memory calculation with a stale legacy batch anchor label.
- This continues Snapshot Convergence without changing renderer/export output.

Boundaries maintained:

- Renderer, Export, Share Extension behavior, Photo Library behavior, Layout
  Engine, and UI architecture were not modified.

Verification completed:

- `BatchQueueHistoryTests`

## 2026-07-05 ProductionMemoryResolver direct snapshot entry slice complete

`ProductionMemoryResolver` now has a direct frozen `ConfigurationSnapshot`
entry point:

```text
ConfigurationSnapshot(memorySubject embedded)
    ↓
ProductionMemoryResolver
    ↓
MemoryResult
```

Scope:

- Added `resolve(photo:frozenSnapshot:)`.
- The direct entry requires an embedded `MemorySubject`; snapshots without an
  embedded subject are treated as incomplete frozen input.
- The legacy `resolve(photo:configuration:)` entry remains as an adapter for
  `BatchConfigurationSnapshot`, older frozen subject payloads, and final
  compatibility fallback.
- The batch adapter now delegates to the direct snapshot entry when possible.

Why this matters:

- The resolver's core production path no longer needs to understand the legacy
  batch DTO when a complete frozen `ConfigurationSnapshot` is present.
- This is a concrete step toward making `ConfigurationSnapshot` the single
  production Snapshot while preserving compatibility for older snapshots.

Boundaries maintained:

- Renderer, Export, Share Extension behavior, Photo Library behavior, Layout
  Engine, and UI architecture were not modified.

Verification completed:

- `ProductionMemoryResolverTests`

## 2026-07-05 BuildService direct frozen snapshot consumption complete

`RecordCardBuildService` now prefers the direct frozen
`ConfigurationSnapshot` resolver entry when complete frozen input exists:

```text
BatchConfigurationSnapshot.frozenConfigurationSnapshot
    ↓
ProductionMemoryResolver.resolve(photo:frozenSnapshot:)
    ↓
RecordCard
```

Scope:

- Added a narrow BuildService helper that tries
  `resolve(photo:frozenSnapshot:)` before falling back to the legacy
  `resolve(photo:configuration:)` adapter.
- Older or incomplete snapshots still use the existing compatibility adapter.
- Added a contract test so BuildService cannot silently regress to only using
  the legacy batch DTO entry.

Why this matters:

- App production assembly now consumes complete frozen `ConfigurationSnapshot`
  input directly instead of always entering through the legacy batch adapter.
- This continues Snapshot Convergence while preserving old snapshot
  compatibility.

Boundaries maintained:

- Renderer, Export, Share Extension behavior, Photo Library behavior, Layout
  Engine, and UI architecture were not modified.

Verification completed:

- `MemoryResultContractTests`
- IA-003 focused tests:
  - `MemoryEngineTests`
  - `MemoryExpressionEngineTests`
  - `ProductionMemoryResolverTests`
  - `RecordCardBuildServiceTests`
  - `MemoryResultContractTests`
  - `BatchConfigurationSnapshotProviderDiagnosticsTests`
  - `BatchQueueHistoryTests`
- `PhotoMemo` Debug build
- `PhotoMemoShareExtension` generic iOS Simulator build
- `git diff --check`

## 2026-07-05 Production live defaults fallback isolated

`ProductionMemoryResolver` now keeps its runtime `UserDefaults` profile read
behind an explicit legacy fallback helper:

```text
Frozen Snapshot
    ↓
Frozen Subject
    ↓
Legacy Runtime Defaults Fallback
```

Scope:

- Moved the final runtime profile fallback into
  `resolveLegacyRuntimeDefaultsFallback(...)`.
- Existing behavior is unchanged: old snapshots without frozen Memory input can
  still resolve through legacy defaults.
- Added a contract test so live defaults fallback remains visibly isolated
  while IA-003 continues toward production-path purity.

Why this matters:

- Runtime defaults are no longer visually mixed into the primary production
  resolver flow.
- The remaining cleanup target is now explicit: remove or retire the legacy
  runtime fallback once all production submissions carry frozen input.

Boundaries maintained:

- Renderer, Export, Share Extension behavior, Photo Library behavior, Layout
  Engine, and UI architecture were not modified.

Verification completed:

- `MemoryResultContractTests`
- IA-003 focused tests:
  - `MemoryEngineTests`
  - `MemoryExpressionEngineTests`
  - `ProductionMemoryResolverTests`
  - `RecordCardBuildServiceTests`
  - `MemoryResultContractTests`
  - `BatchConfigurationSnapshotProviderDiagnosticsTests`
  - `BatchQueueHistoryTests`
- `PhotoMemo` Debug build
- `PhotoMemoShareExtension` generic iOS Simulator build
- `git diff --check`

## 2026-07-05 Frozen snapshot empty-anchor authority complete

`RecordCardBuildService` now treats a complete frozen
`ConfigurationSnapshot` without a primary anchor as authoritative.

Scope:

- When `ProductionMemoryPayload.snapshot.primaryAnchor` is absent and the batch
  configuration carries a frozen `ConfigurationSnapshot`, app production no
  longer refills `RecordCard.anchor`, `RecordCard.anchorResult`, or title from
  legacy `BatchConfigurationSnapshot.anchor`.
- Legacy batch anchor fallback remains available only for inputs that do not
  carry a frozen `ConfigurationSnapshot`.
- Added BuildService regression coverage for a mixed snapshot where the legacy
  batch DTO has an anchor but the frozen production snapshot intentionally has
  none.

Why this matters:

- "No frozen primary anchor" is now treated as a frozen production decision,
  not as missing data to repair from the legacy DTO.
- This closes another Snapshot Convergence drift point before retiring
  `BatchConfigurationSnapshot` domain semantics.

Boundaries maintained:

- Renderer, Export, Share Extension behavior, Photo Library behavior, Layout
  Engine, and UI architecture were not modified.

Verification completed:

- `RecordCardBuildServiceTests`
- IA-003 focused tests:
  - `MemoryEngineTests`
  - `MemoryExpressionEngineTests`
  - `ProductionMemoryResolverTests`
  - `RecordCardBuildServiceTests`
  - `MemoryResultContractTests`
  - `BatchConfigurationSnapshotProviderDiagnosticsTests`
  - `BatchQueueHistoryTests`
- `PhotoMemo` Debug build
- `PhotoMemoShareExtension` generic iOS Simulator build
- `git diff --check`

## 2026-07-05 Legacy paired frozen snapshot completion complete

`ProductionMemoryResolver` now completes legacy paired frozen inputs before
publishing the production payload.

Scope:

- Older compatibility inputs can still carry:
  - `BatchConfigurationSnapshot.frozenConfigurationSnapshot`
  - `BatchConfigurationSnapshot.frozenMemorySubject`
- When the frozen snapshot is missing its embedded `MemorySubject`, resolver
  output now returns a completed `ConfigurationSnapshot` with the frozen subject
  embedded.
- The direct `resolve(photo:frozenSnapshot:)` entry still requires a complete
  frozen snapshot and returns `nil` for incomplete direct input.

Why this matters:

- Downstream production code can rely on `ProductionMemoryPayload.snapshot`
  being closer to the future single production Snapshot shape.
- The paired legacy subject remains a compatibility input, but it is no longer
  leaked forward as an incomplete production snapshot.

Boundaries maintained:

- Renderer, Export, Share Extension behavior, Photo Library behavior, Layout
  Engine, and UI architecture were not modified.

Verification completed:

- `ProductionMemoryResolverTests`
- IA-003 focused tests:
  - `MemoryEngineTests`
  - `MemoryExpressionEngineTests`
  - `ProductionMemoryResolverTests`
  - `RecordCardBuildServiceTests`
  - `MemoryResultContractTests`
  - `BatchConfigurationSnapshotProviderDiagnosticsTests`
  - `BatchQueueHistoryTests`
- `PhotoMemo` Debug build
- `PhotoMemoShareExtension` generic iOS Simulator build
- `git diff --check`

## 2026-07-05 Snapshot Convergence phase 1 started

Snapshot Convergence has started as a narrow compatibility-preserving slice.

Scope:

- `ConfigurationSnapshot` now carries an embedded frozen `MemorySubject`.
- `ConfigurationSnapshotBuilder` freezes the selected `MemorySubject` into the
  snapshot it builds.
- `BatchConfigurationSnapshot.withFrozenMemoryConfiguration(...)` now ensures
  the stored `ConfigurationSnapshot` also carries the frozen subject.
- `ProductionMemoryResolver` now prefers:

```text
ConfigurationSnapshot.memorySubject
    ↓
MemoryExpressionContext
    ↓
MemoryResult
```

before falling back to the legacy paired `frozenMemorySubject`.

Why this matters:

- Production can now resolve Memory from the frozen `ConfigurationSnapshot`
  itself when that embedded subject is available.
- This is the first code step toward making `ConfigurationSnapshot` the single
  production Snapshot.
- `BatchConfigurationSnapshot` remains a compatibility / transport layer and
  has not been removed.

Boundaries maintained:

- Renderer, Export, Share Extension, Photo Library behavior, Layout Engine, and
  UI architecture were not modified.
- The legacy `frozenMemorySubject` path remains available for older snapshots.
- This does not complete Snapshot Convergence; it starts the migration by
  moving frozen Memory subject ownership into `ConfigurationSnapshot`.

Verification completed:

- `ProductionMemoryResolverTests`
- `ConfigurationSnapshotBuilderTests.buildsSnapshotFromSession` passed when run
  alone; it remains listed as a known order-sensitive full-suite test.
- IA-003 focused tests:
  - `MemoryEngineTests`
  - `ProductionMemoryResolverTests`
  - `RecordCardBuildServiceTests`
  - `MemoryResultContractTests`
  - `BatchConfigurationSnapshotProviderDiagnosticsTests`
- `PhotoMemo` Debug build
- `PhotoMemoShareExtension` generic iOS Simulator build
- `git diff --check`

## 2026-07-05 Live Defaults cleanup compatibility slice complete

The production relationship-label path now prefers frozen compatibility input
before falling back to live defaults.

Scope:

- `RecordCardBuildService` already preferred
  `ConfigurationSnapshot.memorySubject.relationship.label`.
- It now also prefers legacy `BatchConfigurationSnapshot.frozenMemorySubject`
  when an older frozen `ConfigurationSnapshot` does not yet embed a
  `MemorySubject`.
- The live `PersonalProfile` defaults fallback remains only for snapshots that
  do not carry frozen Memory input.

Why this matters:

- App production output now keeps relationship-label context aligned with the
  same frozen input consumed by `ProductionMemoryResolver`.
- Older compatibility snapshots no longer mix a frozen Memory calculation with
  a live relationship label.
- This reduces, but does not eliminate, production fallback dependence on
  runtime `UserDefaults`.

Boundaries maintained:

- Renderer, Export, Share Extension, Photo Library behavior, Layout Engine, and
  UI architecture were not modified.
- Share Extension compatibility fallback was not changed.

Verification completed:

- `RecordCardBuildServiceTests`
- IA-003 focused tests:
  - `MemoryEngineTests`
  - `ProductionMemoryResolverTests`
  - `RecordCardBuildServiceTests`
  - `MemoryResultContractTests`
  - `BatchConfigurationSnapshotProviderDiagnosticsTests`
- `PhotoMemo` Debug build
- `PhotoMemoShareExtension` generic iOS Simulator build
- `git diff --check`

## 2026-07-05 BuildService Memory context ownership narrowed

`RecordCardBuildService` now receives app production relationship context from
`ProductionMemoryResolver` output instead of resolving Memory relationship
state directly.

Scope:

- App production builds now derive `MetadataContext.relationship_label` from
  `ProductionMemoryPayload.subject`.
- The resolver remains the app production entry point for frozen Memory input.
- The direct `PersonalProfile` defaults fallback in `RecordCardBuildService`
  is now compiled only for the Share Extension compatibility path.

Why this matters:

- BuildService no longer duplicates app production Memory input resolution.
- App production relationship context now follows the same frozen / legacy /
  compatibility order as `ProductionMemoryResolver`.
- This is another small step toward production purity: remaining runtime
  defaults fallback is concentrated in the resolver / submit-freeze boundary
  instead of being repeated in the build coordinator.

Boundaries maintained:

- Renderer, Export, Share Extension behavior, Photo Library behavior, Layout
  Engine, and UI architecture were not modified.
- Share Extension fallback behavior remains available behind its existing
  compatibility boundary.

Verification completed:

- `RecordCardBuildServiceTests`
- IA-003 focused tests:
  - `MemoryEngineTests`
  - `ProductionMemoryResolverTests`
  - `RecordCardBuildServiceTests`
  - `MemoryResultContractTests`
  - `BatchConfigurationSnapshotProviderDiagnosticsTests`
- `PhotoMemo` Debug build
- `PhotoMemoShareExtension` generic iOS Simulator build
- `git diff --check`

## 2026-07-05 Frozen primary anchor title projection complete

Production card title projection now prefers the frozen production snapshot
primary anchor over the legacy batch anchor.

Scope:

- App production builds now derive `RecordCard.title` from
  `ProductionMemoryPayload.snapshot.primaryAnchor.title` when available.
- Legacy `BatchConfigurationSnapshot.anchor.title` remains the fallback for
  older snapshots and Share Extension compatibility.
- `CardVariableProvider` therefore projects `MetadataContext.title` from the
  same frozen primary anchor that drives `MemoryResult`.

Why this matters:

- Mixed-input production cards no longer combine frozen Memory semantics with a
  legacy title variable.
- This is a Snapshot Convergence slice: production output moves one more
  display-adjacent value from `BatchConfigurationSnapshot` toward
  `ConfigurationSnapshot`.
- `BatchConfigurationSnapshot` still carries the legacy anchor and has not yet
  been reduced to a transport DTO.

Boundaries maintained:

- Renderer, Export, Share Extension behavior, Photo Library behavior, Layout
  Engine, and UI architecture were not modified.
- The change is limited to production input selection before existing variable
  and template rendering.

Verification completed:

- `RecordCardBuildServiceTests`
- IA-003 focused tests:
  - `MemoryEngineTests`
  - `ProductionMemoryResolverTests`
  - `RecordCardBuildServiceTests`
  - `MemoryResultContractTests`
  - `BatchConfigurationSnapshotProviderDiagnosticsTests`
- `PhotoMemo` Debug build
- `PhotoMemoShareExtension` generic iOS Simulator build
- `git diff --check`

## 2026-07-05 Frozen production card input projection complete

App production card input projection now consumes more of the frozen production
payload before falling back to legacy batch fields.

Scope:

- `RecordCard.memorySubjectText` now derives from
  `ProductionMemoryPayload.subject.resolvedExpressionSubjectText`.
- `RecordCard.anchor` and `RecordCard.anchorResult` now prefer
  `ProductionMemoryPayload.snapshot.primaryAnchor` when it can be converted to
  the existing compatibility `Anchor`.
- Legacy `BatchConfigurationSnapshot.memorySubjectText` and
  `BatchConfigurationSnapshot.anchor` remain fallback inputs for older snapshots
  and Share Extension compatibility.

Why this matters:

- App production cards no longer mix a frozen `MemoryResult` with legacy
  subject text or legacy card anchor payload when frozen inputs are available.
- This continues Snapshot Convergence without changing the Renderer, Export, or
  Share Extension contracts.
- `BatchConfigurationSnapshot` still exists as a compatibility / transport DTO;
  this slice only reduces app production's dependence on its domain fields.

Boundaries maintained:

- Renderer, Export, Share Extension behavior, Photo Library behavior, Layout
  Engine, and UI architecture were not modified.
- Final Memory wording remains owned by Presentation compatibility projection
  and existing user-controlled template variables.

Verification completed:

- `RecordCardBuildServiceTests`
- IA-003 focused tests:
  - `MemoryEngineTests`
  - `ProductionMemoryResolverTests`
  - `RecordCardBuildServiceTests`
  - `MemoryResultContractTests`
  - `BatchConfigurationSnapshotProviderDiagnosticsTests`
- `PhotoMemo` Debug build
- `PhotoMemoShareExtension` generic iOS Simulator build
- `git diff --check`

## 2026-07-05 Frozen input fallback narrowing complete

Two additional IA-003 convergence edges were closed.

Scope:

- When a frozen `ConfigurationSnapshot.primaryAnchor` exists but cannot be
  converted to the legacy compatibility `Anchor` shape, app production no
  longer refills `RecordCard.anchor` / `RecordCard.anchorResult` from
  `BatchConfigurationSnapshot.anchor`.
- When an older app production snapshot carries `frozenMemorySubject` but does
  not yet carry `frozenConfigurationSnapshot`, `ProductionMemoryResolver` now
  rebuilds a compatibility `ConfigurationSnapshot` from the frozen subject
  instead of falling through to live defaults.

Why this matters:

- Unsupported frozen anchor semantics stay authoritative and do not silently
  mix with legacy batch anchor values.
- Older frozen inputs now remain frozen inputs even before full Snapshot
  Convergence metadata is present.
- This reduces production runtime `UserDefaults` fallback surface without
  changing Share Extension behavior.

Boundaries maintained:

- Renderer, Export, Share Extension behavior, Photo Library behavior, Layout
  Engine, and UI architecture were not modified.

Verification completed:

- `ProductionMemoryResolverTests`
- `RecordCardBuildServiceTests`
- IA-003 focused tests:
  - `MemoryEngineTests`
  - `ProductionMemoryResolverTests`
  - `RecordCardBuildServiceTests`
  - `MemoryResultContractTests`
  - `BatchConfigurationSnapshotProviderDiagnosticsTests`
- `PhotoMemo` Debug build
- `PhotoMemoShareExtension` generic iOS Simulator build
- `git diff --check`

## 2026-07-05 Frozen provider subject-text alignment complete

The app-side batch snapshot provider now keeps its legacy subject-text
compatibility field aligned with the frozen `MemorySubject`.

Scope:

- `BatchConfigurationSnapshotProvider` still freezes:
  - `frozenMemorySubject`
  - `frozenConfigurationSnapshot`
- On the app pipeline, `BatchConfigurationSnapshot.memorySubjectText` now uses
  `frozenMemorySubject.resolvedExpressionSubjectText`.
- The Share Extension compile path keeps its existing shared-defaults
  compatibility behavior.

Why this matters:

- A submitted app production snapshot no longer carries two different subject
  texts: one from the frozen `MemorySubject`, and another from the old
  `selectedMemorySubjectText` default.
- This is another small Snapshot Convergence step: legacy DTO fields remain for
  compatibility, but their app-side values are derived from the frozen input.

Boundaries maintained:

- Renderer, Export, Share Extension behavior, Photo Library behavior, Layout
  Engine, and UI architecture were not modified.

Verification completed:

- `BatchConfigurationSnapshotProviderDiagnosticsTests`
- IA-003 focused tests:
  - `MemoryEngineTests`
  - `ProductionMemoryResolverTests`
  - `RecordCardBuildServiceTests`
  - `MemoryResultContractTests`
  - `BatchConfigurationSnapshotProviderDiagnosticsTests`
- `PhotoMemo` Debug build
- `PhotoMemoShareExtension` generic iOS Simulator build
- `git diff --check`

## 2026-07-05 MemoryResult implementation slice 1 complete

The first structured `MemoryResult` implementation slice is complete.

Scope:

- Added structured semantic result types:
  - `MemoryResult`
  - `MemoryAnchorResult`
  - `MemoryElapsedTime`
  - `MemoryResultDirection`
  - `MemoryResultPrecision`
  - `MemoryAnchorResultStatus`
  - `MemoryResultSource`
- Added `MemoryExpressionEngine.generateResult(context:)` as the first
  structured Memory Engine output path.
- Added `MemoryResultPresentationAdapter` as the only compatibility projection
  from `MemoryResult` back to current `MemoryModule.renderedText`.
- Updated `MemoryExpressionEngine.generateModule(context:)` to flow through:

```text
MemoryResult
    ↓
Presentation Adapter
    ↓
MemoryModule
```

- Removed the old `OutputStrategy` projection hook so Memory Engine does not
  maintain parallel structured and final-string output paths.

Boundaries maintained:

- Renderer, Export, Share Extension, Photo Library behavior, Layout Engine, and
  UI architecture were not modified.
- Existing rendered text behavior is preserved through the Presentation adapter.
- This is not full IA-003 completion; broader caller migration and legacy
  removal remain.

Verification completed:

- `MemoryResultContractTests`
- `MemoryExpressionEngineTests`
- `ProductionMemoryResolverTests`
- `PhotoMemo` Debug build

## 2026-07-05 MemoryResult implementation slice 2 complete

The second structured `MemoryResult` implementation slice is complete.

Scope:

- `ProductionMemoryPayload` now exposes:
  - `result: MemoryResult`
  - existing `module: MemoryModule`
- `ProductionMemoryResolver` now resolves production Memory through one
  structured result and one Presentation projection:

```text
Frozen / legacy production input
    ↓
MemoryResult
    ↓
Presentation Adapter
    ↓
MemoryModule
```

- Production tests now assert both structured semantic output and preserved
  rendered text.

Boundaries maintained:

- Renderer, Export, Share Extension, Photo Library behavior, Layout Engine, and
  UI architecture were not modified.
- This remains a migration slice. Existing callers may continue consuming
  `MemoryModule` while later IA-003 slices migrate toward `MemoryResult`.

Verification completed:

- `ProductionMemoryResolverTests`
- `MemoryResultContractTests`
- `MemoryExpressionEngineTests`
- `PhotoMemo` Debug build

## 2026-07-05 MemoryResult implementation slice 3 complete

The third structured `MemoryResult` implementation slice is complete.

Scope:

- `RecordCard` now carries optional structured Memory output:
  - `memoryResult: MemoryResult?`
  - existing `memoryModule: MemoryModule?`
- `RecordCardBuildService` now transfers `ProductionMemoryPayload.result` onto
  the built `RecordCard`.
- Build-service tests now assert that downstream cards retain structured
  semantic Memory output while existing variable/rendered-text behavior remains
  unchanged.

Current migration path:

```text
ProductionMemoryResolver
    ↓
ProductionMemoryPayload.result
    ↓
RecordCard.memoryResult
```

Compatibility path retained:

```text
ProductionMemoryPayload.module
    ↓
RecordCard.memoryModule
    ↓
Current variable/render output
```

Boundaries maintained:

- Renderer, Export, Share Extension, Photo Library behavior, Layout Engine, and
  UI architecture were not modified.
- `CardVariableProvider` still consumes the existing compatibility
  `MemoryModule` projection; it has not been migrated to read `MemoryResult`.

Verification completed:

- `RecordCardBuildServiceTests.buildChainKeepsRawAnchorExpressionStylePayloadsAvailableToDownstreamOutput`
- `ProductionMemoryResolverTests`
- `MemoryResultContractTests`
- `MemoryEngineTests.projectsExplicitMemoryModuleIntoVariableAndTemplateFlow`
- `PhotoMemo` Debug build

## 2026-07-05 MemoryResult implementation slice 4 complete

The fourth structured `MemoryResult` implementation slice is complete.

Scope:

- `MemoryExpressionEngine.generateResult(context:)` now preserves anchor-level
  semantic status when capture time is missing.
- If a frozen primary anchor exists but capture date is unavailable,
  `MemoryResult` now returns a primary `MemoryAnchorResult` with:
  - `status: .missingCaptureDate`
  - `precision: .missingCaptureDate`
  - zero elapsed values
- The Presentation adapter continues to preserve existing compatibility text
  behavior for missing capture-date cases.

Boundaries maintained:

- Renderer, Export, Share Extension, Photo Library behavior, Layout Engine, and
  UI architecture were not modified.
- No final display-copy fields were added to `MemoryResult`.

Verification completed:

- `MemoryResultContractTests`
- `ProductionMemoryResolverTests`
- `RecordCardBuildServiceTests.buildChainKeepsRawAnchorExpressionStylePayloadsAvailableToDownstreamOutput`
- `PhotoMemo` Debug build

## 2026-07-05 MemoryResult implementation slice 5 complete

The fifth structured `MemoryResult` implementation slice is complete.

Scope:

- `MemoryAnchorResultStatus` now includes:
  - `.disabledAnchor`
- `MemoryExpressionEngine.generateResult(context:)` now preserves anchor-level
  semantic status when the frozen primary anchor is disabled.
- Disabled anchors produce a primary `MemoryAnchorResult` with zero elapsed
  values and `status: .disabledAnchor`.
- The Presentation adapter continues to preserve existing compatibility text
  behavior for disabled-anchor cases.

Boundaries maintained:

- Renderer, Export, Share Extension, Photo Library behavior, Layout Engine, and
  UI architecture were not modified.
- No final display-copy fields were added to `MemoryResult`.
- Configuration Center behavior was not changed; this slice only defines the
  lower-level Memory Engine semantic response when a disabled anchor reaches the
  engine.

Verification completed:

- `MemoryResultContractTests`
- `ProductionMemoryResolverTests`
- `RecordCardBuildServiceTests.buildChainKeepsRawAnchorExpressionStylePayloadsAvailableToDownstreamOutput`
- `PhotoMemo` Debug build

## 2026-07-05 MemoryResult implementation slice 6 complete

The sixth structured `MemoryResult` implementation slice is complete.

Scope:

- `MemoryExpressionEngine.generateResult(context:)` now preserves anchor-level
  semantic status when the frozen primary anchor has no supported anchor type.
- Unsupported anchors produce a primary `MemoryAnchorResult` with:
  - `status: .unsupportedAnchor`
  - zero elapsed values
- The Presentation adapter continues to preserve existing compatibility text
  behavior for unsupported-anchor cases.

Boundaries maintained:

- Renderer, Export, Share Extension, Photo Library behavior, Layout Engine, and
  UI architecture were not modified.
- No final display-copy fields were added to `MemoryResult`.
- This slice preserves the previous behavior that unsupported anchors should not
  be silently treated as birthday anchors.

Verification completed:

- `MemoryResultContractTests`
- `ProductionMemoryResolverTests`
- `RecordCardBuildServiceTests.buildChainKeepsRawAnchorExpressionStylePayloadsAvailableToDownstreamOutput`
- `PhotoMemo` Debug build

## 2026-07-05 MemoryResult implementation slice 7 complete

The seventh structured `MemoryResult` implementation slice is complete.

Scope:

- `CardVariableProvider` now projects resolved `RecordCard.memoryResult`
  elapsed values into existing memory variables:
  - `daysSince`
  - `yearsSince`
  - `monthsSince`
  - `weeksSince`
  - `babyAge`
- `memorySummary` remains on the Presentation compatibility path through
  `MemoryModule.renderedText`.
- Existing legacy `anchorResult` projection remains as fallback while caller
  migration continues.

Current migration path:

```text
RecordCard.memoryResult
    ↓
CardVariableProvider semantic variable projection
    ↓
Existing variable/template flow
```

Compatibility path retained:

```text
RecordCard.memoryModule
    ↓
memorySummary
```

Boundaries maintained:

- Renderer, Export, Share Extension, Photo Library behavior, Layout Engine, and
  UI architecture were not modified.
- No final display-copy fields were added to `MemoryResult`.
- This slice migrates elapsed semantic variables only; final wording remains
  Presentation/user controlled.

Verification completed:

- `MemoryEngineTests`
- IA-003 focused tests:
  - `MemoryEngineTests`
  - `ProductionMemoryResolverTests`
  - `RecordCardBuildServiceTests`
  - `MemoryResultContractTests`
- `PhotoMemo` Debug build
- `PhotoMemoShareExtension` generic iOS Simulator build
- `git diff --check`
- `MemoryResult` final-display-field keyword scan
- `ProductionMemoryResolverTests`
- `RecordCardBuildServiceTests`
- `MemoryResultContractTests`
- `PhotoMemo` Debug build
- `PhotoMemoShareExtension` generic iOS Simulator build
- `ProductionMemoryResolverTests`
- `RecordCardBuildServiceTests.buildChainKeepsRawAnchorExpressionStylePayloadsAvailableToDownstreamOutput`
- `MemoryResultContractTests`
- `PhotoMemo` Debug build

## 2026-07-05 MemoryResult variable projection boundary coverage added

The `MemoryResult` variable projection boundary now has focused regression
coverage.

Scope:

- Future-relative resolved `MemoryResult` values continue to project existing
  variable semantics:
  - `daysSince = 0`
  - `yearsSince = 0`
  - `monthsSince = 0`
  - `weeksSince = 0`
  - empty `babyAge`
- Unresolved `MemoryResult` values, such as disabled anchors, do not project
  elapsed values into the variable flow.
- `memorySummary` remains on the Presentation compatibility path through
  `MemoryModule.renderedText`.

Boundaries maintained:

- No production code behavior was changed in this coverage slice.
- Renderer, Export, Share Extension, Photo Library behavior, Layout Engine, and
  UI architecture were not modified.
- No final display-copy fields were added to `MemoryResult`.

Verification completed:

- `MemoryEngineTests`

## 2026-07-05 MemoryResult implementation slice 8 complete

The eighth structured `MemoryResult` implementation slice is complete.

Scope:

- `CardVariableProvider` now projects resolved `RecordCard.memoryResult` into
  anchor time-result variables when legacy `RecordCard.anchorResult` is absent.
- Covered past anchor time-result variables include:
  - `anchorTitle`
  - `anchorSmartText`
  - `anchorAgeText`
  - `anchorDurationText`
  - `anchorTotalDaysText`
  - `anchorElapsedText`
  - `anchorDayIndexText`
  - `anchorWeekText`
  - `anchorMonthAgeText`
  - numeric anchor year/month/day/day-total values
- Covered future anchor variables include countdown-oriented values:
  - `anchorCountdownText`
  - raw day duration
  - raw total days

Boundaries maintained:

- The new projection only runs when the legacy `anchorResult` path is absent.
- Unresolved `MemoryResult` values still do not project elapsed values.
- No full sentence / summary projection was added from `MemoryResult`; final
  wording remains Presentation/user controlled.
- Renderer, Export, Share Extension, Photo Library behavior, Layout Engine, and
  UI architecture were not modified.
- No final display-copy fields were added to `MemoryResult`.

Verification completed:

- `MemoryEngineTests`

## 2026-07-05 MemoryResult implementation slice 9 complete

The ninth structured `MemoryResult` implementation slice is complete.

Scope:

- `CardVariableProvider` now prefers resolved `RecordCard.memoryResult` for
  anchor time-result variables even when legacy `RecordCard.anchorResult` is
  still present.
- This moves production-style cards closer to the frozen semantic source while
  preserving legacy compatibility during migration.
- Legacy `anchorResult` remains responsible for full summary/primary/secondary
  compatibility fields that are still outside the pure `MemoryResult` contract.

Boundaries maintained:

- The projection still requires `MemoryAnchorResultStatus.resolved`.
- No full sentence / summary projection was added from `MemoryResult`.
- Renderer, Export, Share Extension, Photo Library behavior, Layout Engine, and
  UI architecture were not modified.
- No final display-copy fields were added to `MemoryResult`.

Verification completed:

- `MemoryEngineTests`
- `ProductionMemoryResolverTests`
- `RecordCardBuildServiceTests`
- `MemoryResultContractTests`
- `PhotoMemo` Debug build
- `PhotoMemoShareExtension` generic iOS Simulator build

## 2026-07-05 MemoryResult implementation slice 10 complete

The tenth structured `MemoryResult` implementation slice is complete.

Scope:

- `CardVariableProvider` now clears stale legacy anchor time-result values when
  a resolved `MemoryResult` changes anchor direction.
- Future-relative `MemoryResult` projection removes legacy past-only values:
  - `anchorAgeText`
  - `anchorElapsedText`
  - `anchorDayIndexText`
  - `anchorWeekText`
  - `anchorMonthAgeText`
  - `anchorMilestoneText`
- Past-relative `MemoryResult` projection removes legacy future-only values:
  - `anchorCountdownText`
- This keeps frozen semantic Memory input from mixing with legacy
  compatibility values during the one-way migration.

Boundaries maintained:

- The projection still requires `MemoryAnchorResultStatus.resolved`.
- `MemoryResult` still projects only time-result variables, not final
  sentence, summary, primary, or secondary display copy.
- Renderer, Export, Share Extension, Photo Library behavior, Layout Engine, and
  UI architecture were not modified.
- No final display-copy fields were added to `MemoryResult`.

Verification completed:

- `MemoryEngineTests`

## 2026-07-05 MemoryResult implementation slice 11 complete

The eleventh structured `MemoryResult` implementation slice is complete.

Scope:

- `CardVariableProvider` now treats an explicitly unresolved frozen
  `MemoryResult` as authoritative for anchor time-result variables.
- When a primary `MemoryResult` exists but its anchor status is not
  `.resolved`, legacy `anchorResult` time-result variables are removed from the
  output context.
- Cleared legacy time-result variables include smart text, countdown, age,
  duration, elapsed/day-index/week/month-age/milestone values, and numeric
  anchor time components.
- Legacy `anchorSummary`, `anchorPrimary`, and `anchorSecondary` remain on the
  compatibility path until Presentation migration removes those fields.

Boundaries maintained:

- No final display-copy fields were added to `MemoryResult`.
- Renderer, Export, Share Extension, Photo Library behavior, Layout Engine, and
  UI architecture were not modified.
- This remains Structured `MemoryResult` migration work, not Snapshot
  Convergence.

Verification completed:

- `MemoryEngineTests`
- IA-003 focused tests:
  - `MemoryEngineTests`
  - `ProductionMemoryResolverTests`
  - `RecordCardBuildServiceTests`
  - `MemoryResultContractTests`
- `PhotoMemo` Debug build
- `PhotoMemoShareExtension` generic iOS Simulator build
- `git diff --check`
- `MemoryResult` final-display-field keyword scan

## 2026-07-05 MemoryResult implementation slice 12 complete

The twelfth structured `MemoryResult` implementation slice is complete.

Scope:

- `CardVariableProvider.memoryValues(from:)` now treats an explicitly
  unresolved frozen `MemoryResult` as authoritative for elapsed semantic
  variables.
- When a primary `MemoryResult` exists but is not `.resolved`, legacy
  `MemoryVariableProvider` elapsed values no longer refill:
  - `daysSince`
  - `yearsSince`
  - `monthsSince`
  - `weeksSince`
  - `babyAge`
- Presentation compatibility summary from `MemoryModule.renderedText` is still
  preserved while those elapsed semantic variables remain empty.

Boundaries maintained:

- No final display-copy fields were added to `MemoryResult`.
- Renderer, Export, Share Extension, Photo Library behavior, Layout Engine, and
  UI architecture were not modified.
- This remains Structured `MemoryResult` migration work, not Snapshot
  Convergence.

Verification completed:

- `MemoryEngineTests`
- IA-003 focused tests:
  - `MemoryEngineTests`
  - `ProductionMemoryResolverTests`
  - `RecordCardBuildServiceTests`
  - `MemoryResultContractTests`
- `PhotoMemo` Debug build
- `PhotoMemoShareExtension` generic iOS Simulator build
- `git diff --check`
- `MemoryResult` final-display-field keyword scan

## 2026-07-05 MemoryResult implementation slice 13 complete

The thirteenth structured `MemoryResult` implementation slice is complete.

Scope:

- `CardVariableProvider` now treats the presence of a frozen `MemoryResult` as
  authoritative even when it has no primary anchor result.
- If `MemoryResult.primaryAnchorResultID` is absent or cannot resolve to a
  primary anchor, legacy `anchorResult` time-result variables are removed from
  the output context instead of being reused.
- `memoryValues(from:)` no longer refills elapsed semantic variables from
  legacy `MemoryVariableProvider` when a frozen `MemoryResult` exists without a
  primary anchor.
- Presentation compatibility summary from `MemoryModule.renderedText` remains
  preserved for the current output path.

Boundaries maintained:

- No final display-copy fields were added to `MemoryResult`.
- Renderer, Export, Share Extension, Photo Library behavior, Layout Engine, and
  UI architecture were not modified.
- This remains Structured `MemoryResult` migration work, not Snapshot
  Convergence.

Verification completed:

- `MemoryEngineTests`
- IA-003 focused tests:
  - `MemoryEngineTests`
  - `ProductionMemoryResolverTests`
  - `RecordCardBuildServiceTests`
  - `MemoryResultContractTests`
- `PhotoMemo` Debug build
- `PhotoMemoShareExtension` generic iOS Simulator build
- `git diff --check`
- `MemoryResult` final-display-field keyword scan

## 2026-07-05 MemoryResult implementation slice 14 complete

The fourteenth structured `MemoryResult` implementation slice is complete.

Scope:

- `CardVariableProvider.memoryValues(from:)` now treats resolved
  `MemoryResult` elapsed semantic values as authoritative as a group.
- Empty semantic fields from a resolved `MemoryResult` are preserved as valid
  domain output rather than interpreted as missing values.
- This prevents legacy `MemoryVariableProvider` values from refilling fields
  such as `babyAge` when the frozen primary anchor is not a birthday anchor.
- Legacy fallback remains available only when no frozen `MemoryResult` exists.
- Presentation compatibility summary from `MemoryModule.renderedText` remains
  preserved for the current output path.

Boundaries maintained:

- No final display-copy fields were added to `MemoryResult`.
- Renderer, Export, Share Extension, Photo Library behavior, Layout Engine, and
  UI architecture were not modified.
- This remains Structured `MemoryResult` migration work, not Snapshot
  Convergence.

Verification completed:

- `MemoryEngineTests`
- IA-003 focused tests:
  - `MemoryEngineTests`
  - `ProductionMemoryResolverTests`
  - `RecordCardBuildServiceTests`
  - `MemoryResultContractTests`
- `PhotoMemo` Debug build
- `PhotoMemoShareExtension` generic iOS Simulator build
- `git diff --check`
- `MemoryResult` final-display-field keyword scan

## 2026-07-05 MemoryResult implementation slice 15 complete

The fifteenth structured `MemoryResult` implementation slice is complete.

Scope:

- Added production-path regression coverage in `RecordCardBuildServiceTests`
  for frozen `MemoryResult` variable authority.
- The new test covers a mixed-input production card where:
  - legacy `BatchConfigurationSnapshot.anchor` is a birthday anchor;
  - frozen `ConfigurationSnapshot.primaryAnchor` is a relationship anchor;
  - production output must preserve the frozen relationship `MemoryResult`
    semantics.
- `babyAge` remains empty in the final production variable context and export
  description when the frozen primary anchor is not a birthday anchor.
- This locks the Slice 14 behavior at the build-service boundary, where legacy
  `anchorResult` is still created for compatibility during migration.

Boundaries maintained:

- No production behavior was changed in this coverage slice.
- No final display-copy fields were added to `MemoryResult`.
- Renderer, Export, Share Extension, Photo Library behavior, Layout Engine, and
  UI architecture were not modified.
- This remains Structured `MemoryResult` migration work, not Snapshot
  Convergence.

Verification completed:

- `RecordCardBuildServiceTests`
- IA-003 focused tests:
  - `MemoryEngineTests`
  - `ProductionMemoryResolverTests`
  - `RecordCardBuildServiceTests`
  - `MemoryResultContractTests`
- `PhotoMemo` Debug build
- `PhotoMemoShareExtension` generic iOS Simulator build
- `git diff --check`
- `MemoryResult` final-display-field keyword scan

## 2026-07-05 MemoryResult implementation slice 16 complete

The sixteenth structured `MemoryResult` implementation slice is complete.

Scope:

- `CardVariableProvider` now treats a present frozen `MemoryResult` as
  authoritative for legacy Anchor display-copy variables.
- When `MemoryResult` is present, the variable context clears:
  - `anchorPrimary`
  - `anchorSecondary`
  - `anchorSummary`
- This prevents old `AnchorResult` sentence/display-copy fields from leaking
  into the production variable context after frozen Memory semantics have been
  resolved.
- Structured `MemoryResult` still projects only semantic time-result values;
  it does not add display text, final sentence, subtitle, badge text, or other
  Presentation-owned copy fields.
- Added production-path regression coverage ensuring templates that still
  reference legacy Anchor display-copy variables do not refill those values
  from the legacy `BatchConfigurationSnapshot.anchor` once frozen
  `MemoryResult` exists.

Boundaries maintained:

- Renderer, Export, Share Extension, Photo Library behavior, Layout Engine, and
  UI architecture were not modified.
- This remains Structured `MemoryResult` migration work, not Snapshot
  Convergence.
- Existing legacy fallback remains available when no frozen `MemoryResult`
  exists.

Verification completed:

- `MemoryEngineTests`
- `RecordCardBuildServiceTests`
- IA-003 focused tests:
  - `MemoryEngineTests`
  - `ProductionMemoryResolverTests`
  - `RecordCardBuildServiceTests`
  - `MemoryResultContractTests`
- `PhotoMemo` Debug build
- `PhotoMemoShareExtension` generic iOS Simulator build
- `git diff --check`
- `MemoryResult` final-display-field keyword scan

## 2026-07-05 MemoryResult implementation slice 17 complete

The seventeenth structured `MemoryResult` implementation slice is complete.

Scope:

- `CardVariableProvider` now treats frozen `MemoryResult` as authoritative for
  `anchorTitle`.
- When a primary `MemoryResult` anchor exists, `anchorTitle` is projected from
  `MemoryAnchorResult.anchorTitle` even if the result status is unresolved
  such as `.disabledAnchor`.
- When a frozen `MemoryResult` has no primary anchor, legacy `anchorTitle` is
  removed from the output context instead of being refilled from legacy
  `AnchorResult`.
- Added production-path regression coverage for a mixed snapshot where:
  - legacy `BatchConfigurationSnapshot.anchor.title` is `旧生日`;
  - frozen `ConfigurationSnapshot.primaryAnchor.title` is `冻结生日`;
  - frozen primary anchor is disabled;
  - production output must keep `冻结生日` and must not refill old time-result
    values from the legacy birthday anchor.

Boundaries maintained:

- `anchorTitle` remains anchor identity metadata, not final sentence copy.
- No final display-copy fields were added to `MemoryResult`.
- Renderer, Export, Share Extension, Photo Library behavior, Layout Engine, and
  UI architecture were not modified.
- Existing legacy fallback remains available when no frozen `MemoryResult`
  exists.
- This remains Structured `MemoryResult` migration work, not Snapshot
  Convergence.

Verification completed:

- `MemoryEngineTests`
- `RecordCardBuildServiceTests`
- IA-003 focused tests:
  - `MemoryEngineTests`
  - `ProductionMemoryResolverTests`
  - `RecordCardBuildServiceTests`
  - `MemoryResultContractTests`
- `PhotoMemo` Debug build
- `PhotoMemoShareExtension` generic iOS Simulator build
- `git diff --check`
- `MemoryResult` final-display-field keyword scan

## 2026-07-05 MemoryResult implementation slice 19 complete

The nineteenth structured `MemoryResult` implementation slice is complete.

Scope:

- `CardVariableProvider` now treats frozen resolved `MemoryResult` as
  authoritative over legacy milestone projection.
- After projecting `MemoryResult` day-level values, the variable context clears:
  - `anchorMilestoneText`
- This prevents old `AnchorResult.milestoneText` values from leaking into
  templates once frozen `MemoryResult` has become the source of anchor time
  semantics.
- Added production-path regression coverage for templates that still reference
  `{{anchor_milestone_text}}` while production is consuming frozen Memory
  input.

Boundaries maintained:

- No milestone semantic field was added to `MemoryResult`; milestone remains
  outside the frozen Contract until accepted as a domain semantic.
- No final display-copy fields were added to `MemoryResult`.
- Renderer, Export, Share Extension, Photo Library behavior, Layout Engine, and
  UI architecture were not modified.
- Existing legacy fallback remains available when no frozen `MemoryResult`
  exists.
- This remains Structured `MemoryResult` migration work, not Snapshot
  Convergence.

Verification completed:

- `MemoryEngineTests`
- `RecordCardBuildServiceTests`
- IA-003 focused tests:
  - `MemoryEngineTests`
  - `ProductionMemoryResolverTests`
  - `RecordCardBuildServiceTests`
  - `MemoryResultContractTests`
- `PhotoMemo` Debug build
- `PhotoMemoShareExtension` generic iOS Simulator build
- `git diff --check`
- `MemoryResult` final-display-field keyword scan

## 2026-07-05 MemoryResult implementation slice 18 complete

The eighteenth structured `MemoryResult` implementation slice is complete.

Scope:

- `CardVariableProvider` now treats frozen resolved `MemoryResult` day
  precision as authoritative for anchor numeric projection.
- After projecting `MemoryResult` day-level values, the variable context clears
  legacy sub-day anchor components:
  - `anchorHours`
  - `anchorMinutes`
  - `anchorSeconds`
- This prevents old `AnchorResult` hour/minute/second values from leaking into
  templates once frozen `MemoryResult` has become the source of anchor time
  semantics.
- Added production-path regression coverage for templates that still reference
  `{{anchor_hours}}`, `{{anchor_minutes}}`, and `{{anchor_seconds}}`.

Boundaries maintained:

- `MemoryResult` remains day precision; no sub-day semantic fields were added.
- No final display-copy fields were added to `MemoryResult`.
- Renderer, Export, Share Extension, Photo Library behavior, Layout Engine, and
  UI architecture were not modified.
- Existing legacy fallback remains available when no frozen `MemoryResult`
  exists.
- This remains Structured `MemoryResult` migration work, not Snapshot
  Convergence.

Verification completed:

- `MemoryEngineTests`
- `RecordCardBuildServiceTests`
- IA-003 focused tests:
  - `MemoryEngineTests`
  - `ProductionMemoryResolverTests`
  - `RecordCardBuildServiceTests`
  - `MemoryResultContractTests`
- `PhotoMemo` Debug build
- `PhotoMemoShareExtension` generic iOS Simulator build
- `git diff --check`
- `MemoryResult` final-display-field keyword scan

## 2026-07-04 IA-003 production freeze slice started

The first code slice from the accepted V1 Architecture Review Final has landed
against the IA-003 production freeze line.

Scope:

- `BatchConfigurationSnapshot` now carries frozen Memory configuration in app
  targets:
  - `MemorySubject`
  - `ConfigurationSnapshot`
- `BatchConfigurationSnapshotProvider` freezes Memory configuration when
  loading the current/default batch configuration.
  - Saved `MemorySubject` from the Configuration Center is preferred as the
    frozen source.
  - Legacy `PersonalProfile` adaptation remains the fallback when no saved
    `MemorySubject` exists.
- `ProductionMemoryResolver` now prefers frozen Memory configuration over live
  `UserDefaults` profile state.
- Legacy fallback remains in place for old snapshots without frozen Memory
  configuration.
- Share Extension compatibility is preserved by keeping the new Memory fields
  out of `PHOTOMEMO_SHARE_EXTENSION` builds.

This is a P0 production-freeze step, not full IA-003 completion. Remaining IA-003
work still includes structured `MemoryResult` semantics and later snapshot
convergence.

Verification completed:

- `ProductionMemoryResolverTests`
- `BatchConfigurationSnapshotProviderDiagnosticsTests`
- `RecordCardBuildServiceTests.buildChainKeepsRawAnchorExpressionStylePayloadsAvailableToDownstreamOutput`
- `ConfigurationSnapshotBuilderTests.buildsSnapshotFromSession`
- `PhotoMemo` Debug build
- `PhotoMemoiOSV1` generic iOS Simulator build
- `PhotoMemoShareExtension` generic iOS Simulator build

## 2026-07-04 V1 Architecture Review Final accepted

The V1 closure and IA-003 migration architecture review has been accepted as
the governance baseline through IA-003 completion:

- [Docs/02_Architecture/V1_Architecture_Review_Final_2026-07-04.md](/Users/rui/Desktop/PhotoMemo/Docs/02_Architecture/V1_Architecture_Review_Final_2026-07-04.md)

Decision:

- Renderer remains the locked V1 output contract and is not reopened for
  architecture polish during V1 closure.
- The architecture focus moves to the IA-003 production freeze line:
  `Submit -> Freeze -> Build -> Render -> Export`.
- Submitted Memory configuration should become the production pipeline's single
  source of truth.
- Future capabilities should extend existing contracts instead of introducing
  new runtime state sources.

Architecture checklist:

- Submit: configuration is frozen at submission time.
- Freeze: there is one single source of truth.
- Consume: production consumes only frozen input.

## 2026-07-04 V1 source line unified into main

The V1 source split has been closed for active development.

- `main` now contains the former latest V1 checkpoint from `v1-checkpoint-20260702`,
  including Subject Library management, the welcome flow, V1 runtime
  coordinators, the current app icon assets, and the focused V1 test set.
- The previous packaging mistake was caused by building from `origin/main`
  before these V1 files were present there. Future V1 builds should use the
  current `main` worktree after this unification, not a separate temporary
  checkout.
- the local and remote `v1-checkpoint-20260702` branch lines have been merged
  into `main` and removed as active build sources.
- P1 UI / IA convergence has been reapplied on top of the unified V1 code:
  duplicate Memory Subject save semantics remain removed, the repeated subject
  overview is removed, the current-configuration row stays compact, and Profile
  names continue to normalize with trim, empty fallback, and a 24-character
  maximum.
- P1.5 remains the state-boundary contract:
  [V1_Configuration_State_Boundary.md](/Users/rui/Desktop/PhotoMemo/Docs/02_Architecture/V1_Configuration_State_Boundary.md)

Verification completed:

- focused V1 tests passed:
  - `ConfigurationCenterSessionBindingPresenterTests`
  - `V1IOSSubjectOverviewPresenterTests`
  - `V1IOSHomeProjectionTests`
  - `SettingsServiceTests`
- `PhotoMemoiOSV1` generic iOS build passed with signing disabled.
- generated unified testing IPA policy:
  - use `/Users/rui/Desktop/photomemo过程中测试版本软件`
  - keep only the latest `.ipa` and matching `.sha256` in that folder
  - name packages with `PhotoMemoiOSV1-main-<commit>-<timestamp>.ipa`
- IPA metadata verified:
  - bundle id: `com.serydoo.PhotoMemo.iOS`
  - bundle version: `20260704190048`
  - short version: `1.0`

## 2026-07-04 V1 app icon replacement and testing IPA

The V1 app icon has been replaced across the active app icon asset catalog and
the V1 release icon asset bundle.

- source image:
  - `/Users/rui/Pictures/Photos Library.photoslibrary/resources/derivatives/F/F2648987-5AB9-4DE0-98F3-9CE4F1264043_1_105_c.jpeg`
- updated app icon catalog:
  - `Source/PhotoMemo/PhotoMemo/Assets.xcassets/AppIcon.appiconset`
- updated release icon assets:
  - `Docs/07_Releases/V1.0/IconAssets/PhotoMemo-V1-AppIcon-1024.png`
  - `Docs/07_Releases/V1.0/IconAssets/PhotoMemo-V1-AppIcon.appiconset.zip`
- generated testing IPA:
  - `/Users/rui/Desktop/photomemo过程中测试版本软件/v1-7-4.ipa`

Verification completed:

- all app icon PNG dimensions match `Contents.json`
- `PhotoMemoiOSV1` generic iOS Simulator build passed
- `PhotoMemoiOSV1` generic iOS archive passed
- `PhotoMemoiOSV1` testing IPA export passed

## 2026-07-04 V1 boundary hardening follow-up

After the V1 maintenance baseline freeze, a focused code-review follow-up
closed three boundary clarity issues without reopening V1 architecture:

- latest V1 source branch: `v1-checkpoint-20260702` HEAD
- boundary hardening code checkpoint: `5f583093`
- maintenance freeze checkpoint: `e48508e9`
- boundary inventory:
  - [Docs/02_Architecture/V1_Boundary_Inventory_2026-07-04.md](/Users/rui/Desktop/PhotoMemo/Docs/02_Architecture/V1_Boundary_Inventory_2026-07-04.md)

- `V1SubjectFlowPatch` now separates state from event semantics by carrying
  explicit one-shot `V1SubjectFlowEvent` values. Reopening Subject Library
  persistence is now an event consumed when the patch is applied, not a
  misleading boolean state.
- `PhotoMemoSharedContainer.ensureDirectory(at:)` now throws instead of
  swallowing directory-creation failures, and wraps failures in
  `SharedContainerError`. All current production call sites have been updated
  to handle the throwing contract.
- `BatchQueuePersistence` now separates encoding from persistence through a
  small `BatchQueuePersistenceBackend` seam, returns `PhotoMemoResult<Void>` for
  persistence writes, reports encoding/save failures, and no longer calls
  `UserDefaults.synchronize()` on each queue save.

Verification completed:

- focused tests passed:
  - `PhotoMemoSharedContainerTests`
  - `BatchQueueStorePersistenceTests`
  - `V1SubjectLibrarySupportTests`
- related tests passed:
  - `BatchQueueRecoveryTests`
  - `ExternalPhotoIntakeStoreDiagnosticsTests`
  - `PhotoMemoiOSV1PhotoIntakeTests`
- `PhotoMemoiOSV1` generic iOS Simulator build passed
- `git diff --check` passed

Not manually verified in this follow-up:

- real-device reinstall
- export/share/photo-library runtime

Recommended next review focus:

- Photo Intake boundary
- Render Pipeline boundary
- Export Pipeline boundary

## 2026-07-03 V1 Maintenance Baseline frozen

The High Finding Closure Sprint has been completed and archived:

- [Docs/02_Architecture/V1_High_Finding_Closure_Checklist_2026-07-03.md](/Users/rui/Desktop/PhotoMemo/Docs/02_Architecture/V1_High_Finding_Closure_Checklist_2026-07-03.md)
- [Docs/02_Architecture/Maintenance_Baseline_Freeze_2026-07-03.md](/Users/rui/Desktop/PhotoMemo/Docs/02_Architecture/Maintenance_Baseline_Freeze_2026-07-03.md)

Decision:

- V1 Functional Baseline: accepted
- V1 long-term Maintenance Baseline: accepted
- maintenance freeze checkpoint: `e48508e9`
- functional device checkpoint: `2218878d`

Current Truth:

- `CURRENT_STATUS.md` is the single source of truth for the active repository state.
- RFC documents are historical architecture records unless this file explicitly says their conclusions have been revalidated for the current live HEAD.

Closure:

- HF-001 Subject Library Data Protection is closed.
- HF-002 Documentation Consistency is closed.
- The corrupt-library protection contract is now explicit:
  - implicit library persistence stays disabled after corrupt-library bootstrap
  - normal Subject edits do not re-enable library persistence
  - only explicit Recovery / Reset behavior may re-enable persistence
  - recovery preserves the original raw payload before overwrite
  - UI editing remains available while disk writes are frozen

Verification completed:

- HF-001 focused tests passed
- related bootstrap / configuration / migration tests passed
- `PhotoMemoiOSV1` generic iOS Simulator build passed
- `git diff --check` passed
- global persistence-gate search found no normal-edit path that bypasses the corrupt-library gate

Not manually verified in this closure:

- new real-device install after HF closure
- export/share/photo-library runtime

## 2026-07-03 V1 Release Readiness Review archived

The V1 Release Readiness Review for checkpoint `2218878d` has been archived:

- [Docs/02_Architecture/V1_Release_Readiness_Review_2026-07-03.md](/Users/rui/Desktop/PhotoMemo/Docs/02_Architecture/V1_Release_Readiness_Review_2026-07-03.md)

Historical note:

- The decision below was the review-time decision.
- It is superseded by the High Finding Closure Sprint and Maintenance Baseline Freeze recorded above.
- For packaging the complete current V1 source, use the latest V1 source checkpoint recorded at the top of this file, not this review-time checkpoint.

Decision:

- V1 Functional Baseline: accepted
- V1 long-term Maintenance Baseline: not yet accepted

Why:

- the current checkpoint remains suitable for continued V1 development, validation, and bug-fix work
- the subject-library corrupt-payload recovery risk must be resolved before the checkpoint becomes a durable maintenance baseline
- active architecture/status documentation still needs historical/current-state normalization before the next V2 or RFC slice treats it as source-of-truth input

## 2026-07-03 V1 usable device checkpoint confirmed on iPhone7

The current `/Users/rui/Desktop/PhotoMemo` working tree was built, installed, launched, and accepted as the latest usable V1 version after one bug-fix pass.

Device verification:

- device name: `iPhone7`
- bundle id: `com.serydoo.PhotoMemo.iOS`
- build product: `/tmp/PhotoMemoV1DeviceBuild/Build/Products/Debug-iphoneos/PhotoMemoiOSV1.app`
- install result: succeeded
- launch result: succeeded
- user check result: accepted as the latest fixed V1 build

This checkpoint confirms that the current local working tree contains required product state that is not yet represented by the remote branch. It should be preserved as the maintenance baseline before any cleanup, splitting, or branch-line simplification continues.

Historical wording note:

- The sentence above predated the High Finding Closure Sprint.
- The current maintenance-baseline decision is the frozen baseline section at the top of this file.

## 2026-07-03 V1 Render Contract review baseline rebuilt in ~/Desktop/PhotoMemo

The earlier decision to split V1 into a separate project line has been withdrawn. The canonical working repository remains:

- `/Users/rui/Desktop/PhotoMemo`

The V1 Render Contract convergence work was restored into the canonical repository without wholesale overwriting the newer desktop V1 runtime/UI files.

Contract baseline now verified:

- `singleLineTemplateText` is Template Source
- `resolvedSingleLineText` is Display Text
- preview refresh consumes `V1PreviewRenderModel.displayText`
- `PhotoMemoiOSV1View` builds render models through `BuildV1PreviewRenderModelIntent`
- old `composeText` / `ComposeV1PreviewTextIntent` / `ResolveV1PreviewDisplayValueIntent` production-test entry points have no residual matches
- old external `moduleValue` entry points have no residual matches
- `resolvedDisplayValue` remains internal to `V1PreviewCompositionEngine`

Verification completed:

- `V1DraftOrchestrationCoordinatorTests`: passed
- Contract baseline test group passed:
  - `PreviewCompositionMigrationTests`
  - `V1PreviewSyncCoordinatorTests`
  - `V1DraftOrchestrationCoordinatorTests`
  - `ConfigurationCenterPreviewCompositionHelperTests`
- `PhotoMemoiOSV1` generic iOS Simulator build passed
- `git diff --check` passed

The earlier re-audit note that `V1DraftOrchestrationCoordinatorTests.applyMutationUpdateBridgesStateAndReturnsDirtyPreviewDrafts()` was order-sensitive is now superseded. The failure was a stale test expectation from the old text contract; the test now asserts Template Source and Display Text separately.

Not manually verified in this checkpoint:

- real-device UI behavior
- export/share/photo-library runtime

## 2026-07-03 V1 live-code re-audit completed against ~/Desktop/PhotoMemo

A full V1 re-review was completed against the live repository to replace older archive-line assumptions with current code evidence.

Primary output:

- [Docs/02_Architecture/V1_Live_Code_Reaudit_2026-07-03.md](/Users/rui/Desktop/PhotoMemo/Docs/02_Architecture/V1_Live_Code_Reaudit_2026-07-03.md)

Most important findings:

- subject-library decode failure currently downgrades V1 into silent selected-subject-only persistence mode
- bootstrap/programmatic state restoration still shares the same dirty-state path as real user edits
- V1 preview remains a parallel presentation implementation rather than the real renderer/export contract
- live code still shows the anchor-count summary that V1 UX Iteration 001 intended to remove
- V1 photo-picker staging creates temporary files without a dedicated cleanup loop

Verification recorded for this re-audit:

- focused V1 macOS test suite still has one failing test:
  - `V1DraftOrchestrationCoordinatorTests.applyMutationUpdateBridgesStateAndReturnsDirtyPreviewDrafts()`
  - broader suite saw `singleLineTemplateText` stay at `记录{{memory_summary}}` instead of the expanded display text
  - isolated rerun of the same test passed, so this currently reads as an order-sensitive or flaky verification gap
- `PhotoMemoiOSV1` generic iOS Simulator build passed

## 2026-07-02 Live-repo engineering revalidation: archive RFC conclusions preserved as history, not yet re-proven as current-state fact

After the repository-line correction, the next step was to revalidate the earlier V2-direction architecture conclusions against the real live repository head in `~/Desktop/PhotoMemo` instead of trusting the archive copy.

What was revalidated:

- the Product Loop V1 UX fixes remain landed in the canonical repository
- focused V1 presenter/projection tests still pass
- `PhotoMemoiOSV1` generic iOS Simulator build now also passes again after the live-repo cleanup

What the code currently shows on the Engineering Loop:

- the preview/configuration path uses the newer Memory Engine objects:
  - `ConfigurationSnapshotBuilder`
  - `ConfigurationSession.currentConfigurationSnapshot`
  - `MemoryExpressionEngine`
  - `MemoryExpressionPreviewResolver`
- the production/export path is still driven by the older card-building chain:
  - `BuildPreviewIntent`
  - `PreviewCoordinator`
  - `RecordCardBuildService`
  - `RecordCard`
  - `CardVariableProvider`
  - `MemoryVariableProvider`
- `RecordCardBuildService` still builds `RecordCard` from `BatchConfigurationSnapshot.anchor` and `memorySubjectText`
- `RecordCard` does not currently carry the archive-line `memoryModule` production seam
- `CardVariableProvider` still computes memory-facing output from legacy `MemoryContext`, not from a first-class production `MemoryModule`

Why this matters:

- the restored V1 engineering baseline and RFC-001 remain valuable repository history and review assets
- but their “Memory enters the production pipeline” closure cannot yet be treated as a revalidated fact for the current live repository head
- the live repository still reads as a dual-track system:
  - newer Memory Engine preview/configuration path
  - older production/export memory path

Current disposition:

- Product Loop V1 UX Iteration 001: implemented in the canonical repository and compile-verified
- Engineering Loop RFC/Baseline artifacts: preserved as historical engineering memory
- Live engineering state: requires a fresh current-state baseline before any new V2 migration conclusion is treated as true for `~/Desktop/PhotoMemo`

## 2026-07-03 Canonical repository line and V2 review assets normalized into ~/Desktop/PhotoMemo

After the archive/install confusion this repository was reasserted as the only canonical PhotoMemo working line:

- `~/Desktop/PhotoMemo` is now the sole research and implementation target going forward
- restored the missing architecture-review artifacts into the live repository:
  - [Docs/02_Architecture/PhotoMemo_V1_Engineering_Baseline.md](/Users/rui/Desktop/PhotoMemo/Docs/02_Architecture/PhotoMemo_V1_Engineering_Baseline.md)
  - [Docs/02_Architecture/RFC-001-Memory-Enters-the-Production-Pipeline.md](/Users/rui/Desktop/PhotoMemo/Docs/02_Architecture/RFC-001-Memory-Enters-the-Production-Pipeline.md)
  - [Docs/02_Architecture/RFC-001-Implementation-Plan.md](/Users/rui/Desktop/PhotoMemo/Docs/02_Architecture/RFC-001-Implementation-Plan.md)
  - [Docs/07_Releases/REPOSITORY_LINE_STRATEGY.md](/Users/rui/Desktop/PhotoMemo/Docs/07_Releases/REPOSITORY_LINE_STRATEGY.md)
- normalized stale absolute worktree links in active chronicle/handoff/plan docs so they now point back to `~/Desktop/PhotoMemo`

Why this matters:

- the repository now keeps the V1 product loop artifacts and the V2 engineering-loop artifacts in one canonical tree
- future baseline / RFC / implementation references no longer depend on a transient Codex worktree path
- the earlier archive copy is no longer a competing documentation source

## 2026-07-03 V1 UX Feedback Iteration 001 reapplied in the live V1 repository and reinstalled on iPhone7

Scoped to the real `~/Desktop/PhotoMemo` V1 working tree after confirming the archive copy was behind the active V1 line:

- kept the work in the Product Loop
- reapplied the V1 UX fixes against the newer split V1 iOS structure instead of the older archive surface
- preserved the existing V1 pipeline, renderer, export, and share boundaries

What landed:

- Added [Docs/01_Product/V1_UX_Feedback_Iteration_001.md](/Users/rui/Desktop/PhotoMemo/Docs/01_Product/V1_UX_Feedback_Iteration_001.md)
  - records the first V1 UX iteration as a product-source artifact
- Updated [Source/PhotoMemo/PhotoMemo/iOS/Views/V1TimeAnchorEntryPresenter.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1TimeAnchorEntryPresenter.swift)
  - time-anchor presentation now exposes the dynamic current anchor title for the V1 accessory editor
- Updated [Source/PhotoMemo/PhotoMemo/iOS/Views/V1AccessoryEntrySection.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1AccessoryEntrySection.swift)
  - removed the stale hardcoded anchor label from the date picker
- Updated [Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift)
  - selected-subject anchor date now falls back safely during subject switches
  - accessory summary date now resolves from the active subject path instead of a stale local date only
- Updated [Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectOverviewCardSections.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectOverviewCardSections.swift)
  - overview simplified to current-state content
  - active anchor promoted as the highlighted state row
  - relationship type removed from identity details
- Updated [Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Editors/MemorySubjectEditorView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Editors/MemorySubjectEditorView.swift)
  - removed `关系类型`
  - removed `对象定义`
  - removed `行为映射`
  - renamed `当前锚点名称` to `自定义锚点名称`
  - collapsed formula selection into one inline row
  - removed duplicate current-formula block and extra helper copy
- Updated [Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenterDetailPresenter.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenterDetailPresenter.swift)
  - subject-panel subtitle now matches the simplified V1 subject surface

Verification:

- passed:
  - `git diff --check`
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoTests -destination 'platform=macOS' -derivedDataPath /tmp/PhotoMemoV1UXTests CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO -only-testing:PhotoMemoTests/V1TimeAnchorEntryPresenterTests -only-testing:PhotoMemoTests/ConfigurationCenterDetailPresenterTests -only-testing:PhotoMemoTests/V1IOSSubjectOverviewPresenterTests test`
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOSV1 -destination 'id=863C2747-6742-5E93-B715-6F89DBF90B31' -derivedDataPath /tmp/PhotoMemoV1UXDeviceBuild COMPILER_INDEX_STORE_ENABLE=NO build`
  - `xcrun devicectl device install app --device 863C2747-6742-5E93-B715-6F89DBF90B31 /tmp/PhotoMemoV1UXDeviceBuild/Build/Products/Debug-iphoneos/PhotoMemoiOSV1.app`
  - `xcrun devicectl device process launch --device 863C2747-6742-5E93-B715-6F89DBF90B31 com.serydoo.PhotoMemo.iOS`

Not manually verified yet:

- the actual on-device feel of the updated V1 subject overview and time-anchor editor after this corrected reinstall

## 2026-07-02 V1 subject follow-up extraction moved out of the root view

Scoped to the next safe follow-up inside the V1 view-freeze plan:

- keep `PhotoMemoiOSV1View.swift` as the V1 state/composition shell
- move subject-overview follow-up behavior out of the root view
- preserve the current subject library save pipeline and preview refresh behavior

What landed:

- Added [Source/PhotoMemo/PhotoMemo/iOS/Views/V1SubjectFlowSupport.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1SubjectFlowSupport.swift)
  - now owns `V1SubjectFlowPatch`
  - now owns `V1SubjectLibraryPersistenceCoordinator`
  - now owns `V1SubjectOverviewActionCoordinator`
- Updated [Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift)
  - subject overview callbacks now delegate to `V1SubjectOverviewActionCoordinator`
  - root view now applies compact patch results through `applySubjectFlowPatch(_:)`
  - removed inline helpers for:
    - subject selection
    - active-anchor confirmation
    - add-subject flow
    - delete-subject flow
    - subject persistence
    - subject-library persistence
- Updated [Tests/PhotoMemoTests/ArchitectureTests/V1SubjectLibrarySupportTests.swift](/Users/rui/Desktop/PhotoMemo/Tests/PhotoMemoTests/ArchitectureTests/V1SubjectLibrarySupportTests.swift)
  - locks anchor-confirmation patch behavior
  - locks add-subject patch behavior
  - locks editor-flow patch creation behavior

Behavior result:

- subject selection, active-anchor confirmation, add, delete, and open-editor still behave the same from the V1 subject sheet
- adding a new subject still forces subject-library persistence to stay enabled
- preview refresh and dirty-state follow-up continue to happen from the root view after the support-layer patch is applied

Verification:

- passed:
  - `git diff --check`
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoTests -destination 'platform=macOS' -derivedDataPath /tmp/PhotoMemoV1SubjectFlowTests CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO -only-testing:PhotoMemoTests/V1IOSSubjectOverviewPresenterTests -only-testing:PhotoMemoTests/V1SubjectLibrarySupportTests -only-testing:PhotoMemoTests/PhotoMemoiOSV1PhotoIntakeTests test`
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOSV1 -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PhotoMemoV1IOSBuildSubjectFlow CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO build`

Not manually verified yet:

- the iOS subject sheet and subject editor handoff on device/simulator after this follow-up extraction

## 2026-07-02 V1 subject overview sheet display split

Scoped to the follow-up slice you requested inside the V1 view-freeze area:

- refactor `V1IOSSubjectOverviewSheetSurface.swift` into smaller display-focused surfaces
- keep `PhotoMemoiOSV1View.swift` and subject-persistence logic untouched
- preserve existing behavior and fit around the current in-flight V1 edits

What landed:

- Added [Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectOverviewRailSurface.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectOverviewRailSurface.swift)
  - now owns the subject rail display surface
  - now owns the rail card, add button, spacer, and empty-state subviews
- Added [Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectOverviewFooterSurface.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectOverviewFooterSurface.swift)
  - now owns the bottom action/footer surface for anchor confirmation and editor entry
- Updated [Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectOverviewSheetSurface.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectOverviewSheetSurface.swift)
  - keeps sheet-level state and toolbar wiring
  - now composes the extracted rail and footer surfaces instead of owning their full view bodies inline

Behavior result:

- sheet callbacks, bindings, and local state ownership stay in `V1IOSSubjectOverviewSheet`
- subject selection, anchor confirmation, add/delete, and open-editor behavior are unchanged
- `PhotoMemoiOSV1View.swift` and subject-persistence flow were not modified

Verification:

- passed:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoTests -destination 'platform=macOS' -derivedDataPath /tmp/PhotoMemoV1OverviewTests CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO -only-testing:PhotoMemoTests/V1IOSSubjectOverviewPresenterTests -only-testing:PhotoMemoTests/V1SubjectLibrarySupportTests test`
  - `V1IOSSubjectOverviewPresenterTests`: 4 passed, 0 failed
  - `V1SubjectLibrarySupportTests`: 3 passed, 0 failed
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOSV1 -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PhotoMemoV1OverviewBuild CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO build`

Not manually verified yet:

- the iOS subject overview sheet UI in simulator or on device after this display-only split

## 2026-07-02 V1 subject overview presenter/state split

Scoped to the safest first slice from `Docs/superpowers/plans/2026-07-02-v1-view-freeze-followup.md` Task 3:

- move subject overview presenter/presentation out of the large support file
- move subject configuration flow state into its own file
- move subject configuration flow presenter into its own file
- keep `V1IOSSubjectOverviewSupport.swift` focused on the existing sheet/card UI, with no behavior change

What landed:

- Added [Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectOverviewPresenter.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectOverviewPresenter.swift)
  - now owns `V1IOSSubjectOverviewPresentation`
  - now owns `V1IOSSubjectOverviewPresenter`
- Added [Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectConfigurationFlowState.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectConfigurationFlowState.swift)
  - now owns `V1IOSSubjectConfigurationFlowState`
- Added [Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectConfigurationFlowPresenter.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectConfigurationFlowPresenter.swift)
  - now owns `V1IOSSubjectConfigurationFlowPresenter`
- Updated [Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectOverviewSupport.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectOverviewSupport.swift)
  - removed the moved presenter/state symbols
  - left the large sheet/card UI structure in place

Behavior result:

- root view and flow references stay the same
- subject overview sheet behavior is unchanged
- no renderer/export/share/photo-library/layout-engine work was touched

Verification:

- passed:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoTests -destination 'platform=macOS' -derivedDataPath /tmp/PhotoMemoV1SubjectFlowTests CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO -only-testing:PhotoMemoTests/V1IOSSubjectOverviewPresenterTests test`
  - `V1IOSSubjectOverviewPresenterTests`: 4 passed, 0 failed

Not manually verified yet:

- iOS sheet/card UI on device or simulator after this refactor-only split

## 2026-07-02 V1 main entry kept + PhotosPicker intake hardened

Scoped to one V1 system-optimization slice:

- keep the new V1 main/home entry as an additional user choice instead of removing it
- preserve the existing Apple Photos / Share / external-intake processing boundary
- make the in-app `处理照片` shortcut safer before real-device testing by avoiding a Data-only PhotosPicker path

What landed:

- Updated [Source/PhotoMemo/PhotoMemo/iOS/Views/V1PhotoIntakeSupport.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1PhotoIntakeSupport.swift)
  - added `V1PickedPhotoFileRepresentation`
  - PhotosPicker import now prefers system file representation through `CoreTransferable`
  - file representations are copied into PhotoMemo's temporary picker folder before submission
  - Data loading remains only as a fallback path
  - content-type filtering now picks a supported type from the item instead of assuming the first advertised type is usable
  - pure URL/file helper methods are `nonisolated`, avoiding new Swift 6 actor-isolation warnings
- Updated [Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift)
  - preserved the injected `ExternalPhotoIntakeCenter`
  - resolved the default shared intake center inside the initializer body instead of a default argument, removing the existing Swift 6 actor-isolation warning
- Updated [Tests/PhotoMemoTests/BatchTests/PhotoMemoiOSV1PhotoIntakeTests.swift](/Users/rui/Desktop/PhotoMemo/Tests/PhotoMemoTests/BatchTests/PhotoMemoiOSV1PhotoIntakeTests.swift)
  - added coverage that file representations are copied before their URLs enter the V1 processing shortcut

Behavior result:

- the V1 home `处理照片` entry remains a first-class extra route for users
- the route still freezes/saves the current V1 configuration before importing and submitting selected photos
- picked photos now have a more stable file-based path into the existing external intake center
- Renderer, Export, Share Extension, Photo Library save behavior, and Layout Engine were intentionally not changed

Verification:

- passed:
  - `git diff --check`
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoTests -destination 'platform=macOS' -derivedDataPath /tmp/PhotoMemoV1IntakeTests CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO -only-testing:PhotoMemoTests/PhotoMemoiOSV1PhotoIntakeTests test`
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoTests -destination 'platform=macOS' -derivedDataPath /tmp/PhotoMemoV1PolishTests CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO -only-testing:PhotoMemoTests/V1WelcomePresentationTests -only-testing:PhotoMemoTests/V1IOSHomeQuickActionsTests -only-testing:PhotoMemoTests/V1IOSSubjectOverviewPresenterTests -only-testing:PhotoMemoTests/V1SubjectLibrarySupportTests -only-testing:PhotoMemoTests/PhotoMemoiOSV1PhotoIntakeTests -only-testing:PhotoMemoTests/ConfigurationMigrationTests -only-testing:PhotoMemoTests/V1ConfigurationApplyCoordinatorTests test`
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOSV1 -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PhotoMemoV1IOSBuild CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO build`

Not manually verified yet:

- real-device picker behavior with large HEIC/Live Photo-derived assets
- signed install / launch after this specific intake-hardening slice

## 2026-07-02 V1 iOS build stabilization: photo intake boundary fixed + entry review refreshed

Scoped to one V1 stabilization slice:

- confirm whether the remaining `PhotoMemoiOSV1` failures were real source issues or sandbox-only macro noise
- repair the first true compile blocker without reopening renderer / export / share boundaries
- refresh the V1 root-view decomposition audit so the next extraction work is guided by current code, not stale assumptions

What landed:

- Updated [Source/PhotoMemo/PhotoMemo/iOS/Views/V1PhotoIntakeSupport.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1PhotoIntakeSupport.swift)
  - split the file into:
    - cross-platform `V1PhotoIntakeURLResolver`
    - iOS-only `V1PhotoIntakeImporter`
  - restored the missing `SwiftUI` cross-import dependency required for `PhotosPickerItem`
  - removed the unreachable outer `catch` path in the importer loop while preserving the same intake behavior
- Confirmed with an unsandboxed build that the earlier `SwiftUIMacros.StateMacro` noise was not the whole story
  - the real first source failure was in `V1PhotoIntakeSupport.swift`
  - after the intake-boundary fix, `PhotoMemoiOSV1` now compiles cleanly again for generic iOS Simulator

Updated architecture findings:

- `PhotoMemoiOSV1View.swift` still has three highest-value extraction targets:
  1. modal / sheet routing state
  2. subject-configuration save side effects
  3. configuration-save request building
- additional review findings to carry forward:
  - `V1IOSSubjectConfigurationFlow` still directly embeds `MemorySubjectEditorView`, so V1 iOS remains coupled to Configuration Center editor internals
  - `V1SubjectLibraryRecord` currently treats decode failure too much like “no saved library”, which makes subject persistence brittle
  - `V1ConfigurationApplyCoordinator` still duplicates a large part of the configuration save payload instead of wrapping one canonical save request
  - `legacyBirthdayAnchorTitle` is now a misleading migration-era name and should be separated from real anchor-title semantics in a later cleanup pass

Verification:

- passed:
  - `git diff --check`
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOSV1 -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PhotoMemoV1IOSBuildEscalated CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO build`
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoTests -destination 'platform=macOS' -only-testing:PhotoMemoTests/PhotoMemoiOSV1PhotoIntakeTests -only-testing:PhotoMemoTests/V1IOSSubjectOverviewPresenterTests CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO test`

Recommended next step:

1. keep the compile chain green
2. extract `PhotoMemoiOSV1View` modal routing into a dedicated entry-flow coordinator
3. then extract subject-configuration follow-up effects and save-request building in two smaller follow-up slices

## 2026-07-02 V1.0 entry polish continued: welcome/home refinement + subject library flow extraction

Scoped to one V1 iOS polish and decomposition slice:

- keep the approved V1 onboarding / home direction moving toward the reference UI style
- continue reducing `PhotoMemoiOSV1View` coordination pressure without reopening renderer, export, or share boundaries

What landed:

- Updated [Source/PhotoMemo/PhotoMemo/iOS/Views/V1WelcomePresentation.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1WelcomePresentation.swift)
  - welcome page now uses a stronger hero card, compact workflow preview, and more intentional first-open visual hierarchy
- Updated [Source/PhotoMemo/PhotoMemo/iOS/Views/V1HomePageSurface.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1HomePageSurface.swift)
  - home top area now reads more like an app entry card instead of a plain nav row
  - keeps the same actions and behavior while aligning better with the approved V1 visual direction
- Updated [Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectOverviewSupport.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectOverviewSupport.swift)
  - subject management sheet now uses a more iOS-like horizontal card rail
  - single-subject state keeps one main preview card plus dedicated add-entry spacing
  - delete remains guarded behind `subjects.count > 1`
- Updated [Source/PhotoMemo/PhotoMemo/iOS/Views/V1SubjectLibrarySupport.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1SubjectLibrarySupport.swift)
  - added `V1SubjectLibraryMutationCoordinator`
  - subject select / activate-anchor / add / delete interaction logic is now formally owned by support code instead of the root V1 view
- Updated [Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift)
  - root view now delegates subject library mutations to the new coordinator and only keeps persistence / preview follow-up work
- Added [Tests/PhotoMemoTests/ArchitectureTests/V1SubjectLibrarySupportTests.swift](/Users/rui/Desktop/PhotoMemo/Tests/PhotoMemoTests/ArchitectureTests/V1SubjectLibrarySupportTests.swift)
  - locks subject add / activate-anchor / delete behavior at the support-layer boundary

Verification:

- passed:
  - `git diff --check`
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoTests -destination 'platform=macOS' -derivedDataPath /tmp/PhotoMemoV1PolishTests CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO -only-testing:PhotoMemoTests/V1WelcomePresentationTests -only-testing:PhotoMemoTests/V1IOSHomeQuickActionsTests -only-testing:PhotoMemoTests/V1IOSSubjectOverviewPresenterTests -only-testing:PhotoMemoTests/V1SubjectLibrarySupportTests -only-testing:PhotoMemoTests/PhotoMemoiOSV1PhotoIntakeTests test`
- currently blocked:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOSV1 -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PhotoMemoV1IOSBuild CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO build`
  - current failure is outside this slice's new welcome/home/subject work and remains in older iOS SwiftUI surfaces:
    - repeated `SwiftUIMacros.StateMacro` expansion failures in `PhotoMemoiOSHomeView.swift`, `ConfigurationCenteriOSView.swift`, `PhotoMemoiOSV1View.swift`, and `MemorySubjectEditorView.swift`
    - follow-on immutable-`self` errors in `ConfigurationCenteriOSView.swift`

Next best follow-up:

1. isolate whether the current iOS macro-expansion failures are an environment/toolchain issue or a syntax/structure issue in the older iOS surfaces
2. keep shrinking `PhotoMemoiOSV1View` by extracting modal routing and configuration-apply mapping, as identified in this round's structure audit
3. once the iOS target is green again, resume signed build and real-device install verification

## 2026-07-02 V1.0.0-test1 IPA packaged and synced for tester distribution

Scoped to one release-packaging slice:

- produce the first GitHub-synced V1 testing IPA from the current `PhotoMemoiOSV1` target
- keep the packaging path reproducible inside the repository instead of relying on one-off local Xcode export steps

What landed:

- Added [scripts/export_options_v1_testing.plist](/Users/rui/Desktop/PhotoMemo/scripts/export_options_v1_testing.plist)
  - repository-owned IPA export configuration for the current signed `debugging` export path
- Added [Docs/07_Releases/V1.0/README.md](/Users/rui/Desktop/PhotoMemo/Docs/07_Releases/V1.0/README.md)
  - release label, packaging notes, install limits, and reproducible commands
- Added:
  - [PhotoMemo-V1.0.0-test1.ipa](/Users/rui/Desktop/PhotoMemo/Docs/07_Releases/V1.0/PhotoMemo-V1.0.0-test1.ipa)
  - [PhotoMemo-V1.0.0-test1.sha256](/Users/rui/Desktop/PhotoMemo/Docs/07_Releases/V1.0/PhotoMemo-V1.0.0-test1.sha256)

Verification:

- passed:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOSV1 -destination 'generic/platform=iOS' -archivePath /tmp/PhotoMemo-V1.0.0-test1.xcarchive COMPILER_INDEX_STORE_ENABLE=NO archive`
  - `xcodebuild -exportArchive -archivePath /tmp/PhotoMemo-V1.0.0-test1.xcarchive -exportPath /tmp/PhotoMemo-V1.0.0-test1-export -exportOptionsPlist /Users/rui/Desktop/PhotoMemo/scripts/export_options_v1_testing.plist`

Release note:

- this IPA is suitable for the current signed tester flow, but broader public installation still depends on provisioning coverage or a later TestFlight/distribution path

## 2026-07-02 V1.0 subject formula selector default-edit fix + iPhone7 install verification

Scoped to one small V1 interaction/debugging slice:

- remove the last confusing edit gate around subject time-anchor controls
- ensure the formula/style picker is immediately usable when entering the subject configuration page
- verify the corrected build can be signed, installed, and launched on the real `iPhone7`

What landed:

- Updated [MemorySubjectEditorView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Editors/MemorySubjectEditorView.swift)
  - removed the old top-level `编辑 / 完成` toggle from the active-anchor card
  - replaced it with the passive status hint `可直接编辑`
  - `loadDrafts()` now defaults `isEditingTimeAnchor = true`
  - saving the subject keeps the time-anchor section in the directly editable state instead of returning to a locked-looking mode

Behavior result:

- entering `记忆对象配置 -> 时间锚点` no longer requires a second edit-mode step before the lower controls become active
- `锚点类型` and `当前表述公式` should open directly instead of appearing as a disabled gray selector
- the visible UI state now better matches the actual V1 editing model

Verification:

- passed:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOSV1 -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO build`
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOSV1 -destination 'id=863C2747-6742-5E93-B715-6F89DBF90B31' -derivedDataPath /tmp/PhotoMemoDeviceSignedBuild COMPILER_INDEX_STORE_ENABLE=NO build`
  - `xcrun devicectl device install app --device 863C2747-6742-5E93-B715-6F89DBF90B31 /tmp/PhotoMemoDeviceSignedBuild/Build/Products/Debug-iphoneos/PhotoMemoiOSV1.app`
  - `xcrun devicectl device process launch --device 863C2747-6742-5E93-B715-6F89DBF90B31 com.serydoo.PhotoMemo.iOS`

## 2026-07-02 V1.0 time-anchor formula selection surfaced in subject configuration and live preview sync

Scoped to one focused V1 + IA-003-compatible interaction slice:

- keep formula ownership inside MME/runtime instead of UI string branching
- make the active anchor formula visible in both the subject editor and the V1 time-anchor accessory surface
- ensure saving subject-level anchor formula changes refreshes inserted smart-module previews, not just the default slot D fallback

What landed:

- Updated [V1TimeAnchorEntryPresenter.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1TimeAnchorEntryPresenter.swift)
  - the V1 time-anchor presentation now exposes:
    - `当前表述公式`
    - the resolved current style title, such as `自然（默认）` or `温馨`
- Updated [V1AccessoryEntrySection.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1AccessoryEntrySection.swift)
  - the expanded time-anchor area now shows the current formula style as a dedicated info block
  - the formula preview remains below it as the readable MME output rule
- Updated [MemorySubjectEditorView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Editors/MemorySubjectEditorView.swift)
  - the time-anchor editor now surfaces:
    - current active formula summary
    - a clearer `当前表述公式` selection block
    - an explicit note that the first formula is the default and changing it immediately affects smart-module preview behavior
- Updated [PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift)
  - saving the subject configuration now:
    - persists the subject as before
    - realigns the active anchor date back into the V1 preview context
    - forces a dynamic preview refresh so smart modules already inserted into `slotA/B/C/D` recompose against the newly selected formula
- Updated [ConfigurationSnapshotBuilder.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/ConfigurationSnapshotBuilder.swift)
  - runtime snapshots now normalize legacy subject anchors to `resolvedAnchorType + resolvedExpressionStyle`
  - old mock / legacy anchors with missing type metadata no longer fall back to historical block text during preview composition

Behavior result:

- the time-anchor formula is now a first-class visible configuration concept instead of a hidden picker detail
- V1 smart-module preview recomposition now stays aligned with the selected anchor formula even when the module is inserted outside slot D
- preview-time runtime defaults now prefer normalized MME anchor rules over legacy `昵称 / 今天 / 年龄` block wording

Verification:

- passed:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoTests -destination 'platform=macOS' -only-testing:PhotoMemoTests/V1TimeAnchorEntryPresenterTests -only-testing:PhotoMemoTests/PreviewCompositionMigrationTests CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO test`
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOSV1 -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO build`

## 2026-07-02 V1.0 anchor formula library expanded into multi-style MME rules

Scoped to one focused Memory Engine slice:

- expand `expressionStyle` from one default formula per anchor type into a real V1.0 anchor-formula library
- keep the rule owned by MME and preview resolvers, not by UI string branching
- preserve legacy payload compatibility for already-saved style values

What landed:

- Updated [MemoryAnchorExpressionStyle.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Models/MemoryAnchorExpressionStyle.swift)
  - each anchor type now exposes 5 selectable styles
  - current library covers:
    - `birthday`: natural / ceremonial / growth / warm / minimal
    - `marriage`: natural / ceremonial / warm / minimal / memory
    - `relationship`: natural / ceremonial / memory / warm / minimal
    - `exam`: natural / ceremonial / motivational / minimal / record
    - `custom`: natural / ceremonial / memory / warm / minimal
  - old saved raw values such as `birthdayAgeToday` still decode and normalize into the new library
- Updated [MemoryAnchorExpressionResolver.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/MemoryEngine/MemoryAnchorExpressionResolver.swift)
  - the full before/after formula text now resolves from the selected style
  - birthday natural before now follows the frozen wording:
    - `距离{主体}出生还有{倒计时天数}`
- Updated [MemorySubjectEditorView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Editors/MemorySubjectEditorView.swift)
  - anchor-type changes now immediately reset the style picker to the new type's default legal style
  - the editor no longer risks carrying an invalid previous-type style into the current anchor
- Updated tests:
  - [MemoryExpressionEngineTests.swift](/Users/rui/Desktop/PhotoMemo/Tests/PhotoMemoTests/ArchitectureTests/MemoryExpressionEngineTests.swift)
  - [V1TimeAnchorEntryPresenterTests.swift](/Users/rui/Desktop/PhotoMemo/Tests/PhotoMemoTests/ArchitectureTests/V1TimeAnchorEntryPresenterTests.swift)
  - [BatchConfigurationSnapshotProviderDiagnosticsTests.swift](/Users/rui/Desktop/PhotoMemo/Tests/PhotoMemoTests/BatchTests/BatchConfigurationSnapshotProviderDiagnosticsTests.swift)
  - [RecordCardBuildServiceTests.swift](/Users/rui/Desktop/PhotoMemo/Tests/PhotoMemoTests/ExportTests/RecordCardBuildServiceTests.swift)

Behavior result:

- `expressionStyle` is now a real formula-library selector, not just a type label
- MME generation, preview resolver output, V1 formula preview, and legacy/batch snapshot persistence now all understand the expanded style system
- share-safe shared models keep compiling with the new enum shape

Verification:

- passed:
  - `git diff --check`
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoTests -destination 'platform=macOS' -only-testing:PhotoMemoTests/MemoryExpressionEngineTests -only-testing:PhotoMemoTests/V1TimeAnchorEntryPresenterTests -only-testing:PhotoMemoTests/ConfigurationMigrationTests -only-testing:PhotoMemoTests/BatchConfigurationSnapshotProviderDiagnosticsTests -only-testing:PhotoMemoTests/RecordCardBuildServiceTests CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO test`
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOSV1 -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO build`

## 2026-07-02 expression-style unified into batch/share/default-processing

Scoped to one focused IA-003 follow-up slice:

- keep `expressionStyle` from stopping at the V1 editor and configuration snapshot
- make the old `Anchor / BatchConfigurationSnapshot / RecordCard / template-variable` chain consume the same anchor-level expression rule
- preserve the renderer/export/layout boundary and avoid reopening visual architecture

What landed:

- Added [MemoryAnchorExpressionStyle.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Models/MemoryAnchorExpressionStyle.swift)
  - moved the anchor expression-style model into a shared runtime-safe location
  - keeps one normalized definition that can be used by app, batch, and share-facing snapshot code
- Added [MemoryAnchorExpressionResolver.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/MemoryEngine/MemoryAnchorExpressionResolver.swift), [RelativeTimeMemoryCalculator.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/MemoryEngine/RelativeTimeMemoryCalculator.swift), and [ConfiguredAnchorExpressionProvider.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/MemoryEngine/ConfiguredAnchorExpressionProvider.swift)
  - freezes one shared relative-time + formula-resolution layer
  - makes anchor type decide the event category, calculator decide the time result, and expression style decide how that result is spoken
- Updated [MemoryAnchorTypeRegistry.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/MemoryEngine/MemoryAnchorTypeRegistry.swift)
  - the current anchor families now route through the shared relative-time calculator and configured expression provider instead of diverging per-type
- Updated [Anchor.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Models/Anchor.swift), [BatchProcessing.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Models/BatchProcessing.swift), [SettingsService.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Services/SettingsService.swift), and [BatchConfigurationSnapshotProvider.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/App/BatchConfigurationSnapshotProvider.swift)
  - old persisted anchors now retain `expressionStyle`
  - batch/share-facing snapshots now also freeze `memorySubjectText`
- Updated [ConfigurationRepository.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Repositories/ConfigurationRepository.swift), [ConfigurationCoordinator.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Coordinators/ConfigurationCoordinator.swift), [MemorySubjectAdapter.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/MemoryEngine/MemorySubjectAdapter.swift), and [PersonalProfileStore.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Services/PersonalProfileStore.swift)
  - subject anchor edits now sync back into the legacy anchor store with both `anchorType` and `expressionStyle`
  - loading legacy subject data back into the IA-003 subject model preserves those fields instead of dropping them
- Updated [RecordCard.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Models/RecordCard.swift), [RecordCardBuildService.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Services/RecordCardBuildService.swift), [MemoryContext.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/MemoryEngine/MemoryContext.swift), [MemoryVariableProvider.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/MemoryEngine/MemoryVariableProvider.swift), and [CardVariableProvider.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Models/CardVariableProvider.swift)
  - the legacy preview/export template-variable path now reads the same resolved subject text and expression style as the newer MME path
  - old `memorySummary` generation no longer depends on a separate hard-coded sentence family

Behavior result:

- `expressionStyle` is now a real persisted configuration field across:
  - subject editing
  - V1 save / restore
  - IA-003 snapshot projection
  - legacy anchor persistence
  - batch/share configuration snapshot freezing
  - default photo-description generation
  - legacy template-variable memory summary output
- the system still keeps capture time as the truth for time calculation
- the current first-family formula behavior now branches by anchor type and by whether capture time is before or after the anchor date

Verification:

- passed:
  - `git diff --check`
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoTests -destination 'platform=macOS' -only-testing:PhotoMemoTests/MemoryExpressionEngineTests -only-testing:PhotoMemoTests/V1TimeAnchorEntryPresenterTests -only-testing:PhotoMemoTests/ConfigurationMigrationTests -only-testing:PhotoMemoTests/BatchConfigurationSnapshotProviderDiagnosticsTests -only-testing:PhotoMemoTests/SharedBatchConfigurationSnapshotServiceTests -only-testing:PhotoMemoTests/RecordCardBuildServiceTests -only-testing:PhotoMemoTests/MemoryEngineTests CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO test`
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOSV1 -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO build`

Current boundary:

- `expressionStyle` is now in the real processing chain, not just the editor chain
- renderer/layout/export architecture was intentionally not redesigned in this slice
- share-facing user copy still does not independently explain expression-style choices; the runtime behavior is aligned first
## 2026-07-02 V1 editor fade removal + time-anchor type/style configuration

Scoped to one focused V1 polish slice:

- remove the intermittent washed-out/fade treatment in the iOS V1 editor surface
- keep preview pinning, but stop blending two semi-transparent preview copies
- stop using the accessory time-anchor disclosure as a time-result panel and switch it to formula presentation
- restructure subject time-anchor editing into:
  - current active anchor selection + inline naming
  - anchor type
  - anchor expression style
  - anchor note
- keep the change additive to the current save pipeline and avoid touching renderer/export/share behavior

What landed:

- Added [MemoryAnchorExpressionStyle.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Models/MemoryAnchorExpressionStyle.swift)
  - establishes the first persisted anchor-level expression-style model
  - currently maps one default style per anchor type and provides formula preview text
- Updated [MemorySubject.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Models/MemorySubject.swift)
  - `MemorySubject.TimeAnchor` now carries optional `expressionStyle`
- Updated [MemoryAnchor.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/MemoryEngine/MemoryAnchor.swift) and [ConfigurationSnapshotBuilder.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/ConfigurationSnapshotBuilder.swift)
  - IA-003 snapshot projection now keeps anchor expression-style metadata instead of dropping it immediately
- Updated [MemorySubjectEditorView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Editors/MemorySubjectEditorView.swift)
  - active-anchor card now owns selection and inline naming
  - removed the old redundant detail `名称` row
  - added `锚点类型`, `锚点表述方式`, and `当前公式预览`
  - normalizes legacy anchors into explicit type/style defaults when loaded for editing
- Updated [V1TimeAnchorEntryPresenter.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1TimeAnchorEntryPresenter.swift) and [V1AccessoryEntrySection.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1AccessoryEntrySection.swift)
  - folded state keeps `主体 · 当前生效锚点`
  - expanded content now shows the current formula preview instead of the live smart-time result
- Updated [V1EditorPageSurface.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1EditorPageSurface.swift)
  - removed the page-level opacity choreography that caused the intermittent washed-out editor/preview effect
  - switched preview pinning to an opaque pinned/unpinned swap
  - removed the scroll-surface tap-dismiss path that was fighting inline editing focus

Verification:

- passed:
  - `git diff --check`
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoTests -destination 'platform=macOS' -only-testing:PhotoMemoTests/V1TimeAnchorEntryPresenterTests -only-testing:PhotoMemoTests/ConfigurationMigrationTests CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO test`
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOSV1 -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO build`

Known follow-up:

- preview tap-to-dismiss remains the preferred explicit keyboard-dismiss surface; no broad editor-page tap catcher was reintroduced
- share-facing user copy may still want a later explicit explanation of which expression style is active, but the processing chain itself is now aligned

## 2026-07-01 Architecture Freeze V1 compile recovery + V1 / ConfigurationCenter support-view extraction

Scoped to one more strict `Architecture Freeze V1` pass:

- first restore real compile verification after the latest support-view extraction
- then continue only low-risk pure presentation/support-view slices
- do not change renderer, export, metadata, share, photo-library, or application-flow semantics

What landed:

- Updated [MemoryBlockInspectorView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Inspector/MemoryBlockInspectorView.swift)
  - fixed the real compile blocker by marking the `collapsibleSection` content closure as `@escaping`
  - this unblocked the already-landed support-view split around:
    - `MemoryBlockInspectorCollapsibleSection`
    - `MemoryBlockInspectorOverviewSection`
    - `MemoryBlockInspectorConfigurationPickerSection`
    - `MemoryBlockInspectorSystemModulesSection`
    - `MemoryBlockInspectorCustomFieldsSection`
- Added [V1PreviewSection.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1PreviewSection.swift)
  - extracted the `previewSection` shell from `PhotoMemoiOSV1View`
  - child receives only already-resolved preview inputs:
    - `logoMode`
    - logo image paths
    - four resolved region strings
- Added [V1PresetControls.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1PresetControls.swift)
  - extracted:
    - `V1PresetPicker`
    - `V1PresetOperationsMenu`
  - parent keeps preset selection binding and rename/reset behaviors
- Updated [PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift)
  - `previewSection` now delegates to `V1PreviewSection`
  - `presetPicker` now delegates to `V1PresetPicker`
  - `presetOperationsMenu` now delegates to `V1PresetOperationsMenu`
- Added [ConfigurationCenterPresetMenu.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenterPresetMenu.swift)
  - extracted the `profilePresetMenu` shell from `ConfigurationCenteriOSView`
  - child receives:
    - preset list
    - selected preset
    - current title
    - preset selection callback
- Added [ConfigurationCenterToolbarContent.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenterToolbarContent.swift)
  - extracted the `configurationToolbar` shell from `ConfigurationCenteriOSView`
  - child receives:
    - page chrome presentation
    - reset/apply callbacks
- Updated [ConfigurationCenteriOSView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift)
  - `profilePresetMenu` now delegates to `ConfigurationCenterPresetMenu`
  - `configurationToolbar` now delegates to `ConfigurationCenterToolbarContent`
  - parent keeps session ownership, panel selection, and mutation routing

Current effect:

- [PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift)
  - `1866` -> `1836`
- [ConfigurationCenteriOSView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift)
  - `968` -> `900`
- current remaining view-heavy priority is now:
  - [PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift) `1836`
  - [MemoryBlockInspectorView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Inspector/MemoryBlockInspectorView.swift) `1015`
  - [ConfigurationCenteriOSView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift) `900`
  - [InteractiveMemoryCard.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/MemoryCard/InteractiveMemoryCard.swift) `799`

Verification:

- passed:
  - `git diff --check`
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO build`

Recommended next safe order:

- `PhotoMemoiOSV1View`
  - next safest target remains `editorCluster`, but only if kept as parent-owned action routing with child view receiving closures and resolved drafts
- `InteractiveMemoryCard`
  - inspect for one more pure display/support-view island before touching anything stateful
- `MemoryBlockInspectorView`
  - likely close to diminishing returns after this round; only continue if another isolated pure display section is obvious
- `ConfigurationCenteriOSView`
  - now near the stop point for freeze-safe view slicing; avoid pushing into selection/binding/model assembly seams

## 2026-07-01 ConfigurationCenter detail-panel shell extraction

Scoped to one more strict `Architecture Freeze V1` support-view slice:

- keep `ConfigurationCenteriOSView` as the owner of:
  - panel presentation resolution
  - session bindings
  - model projection
  - region draft / mutation / selection seams
- move only the pure detail-panel shell assembly for:
  - memory module
  - output
  - configuration guide
- leave renderer, export, metadata, and share behavior untouched

What landed:

- Added [ConfigurationCenterDetailPanelSection.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenterDetailPanelSection.swift)
  - extracted the shared `IOSDetailPanel` host assembly for the `.memoryModule`, `.output`, and `.configurationGuide` branches
  - child now receives already-prepared values only:
    - title
    - system image
    - panel models / bindings / guide items
- Updated [ConfigurationCenteriOSView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift)
  - `detailContent` now delegates those three pure assembly branches to the new support view
  - parent keeps all stateful and mutation-bearing responsibilities

Verification:

- passed:
  - `git diff --check -- Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenterDetailPanelSection.swift`
- not passing due to a pre-existing compile blocker outside this slice:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
  - current failure:
    - [MemoryBlockInspectorView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Inspector/MemoryBlockInspectorView.swift:124)
    - `passing non-escaping parameter 'content' to function expecting an '@escaping' closure`

## 2026-07-01 ConfigurationCenter region-composer host extraction + background-status dead-helper cleanup

Scoped to another strict `Architecture Freeze V1` slice:

- keep `ConfigurationCenteriOSView` as the owner of region bindings, draft-store state, and mutation routing
- move only the `IOSRegionComposer` host assembly into a dedicated support view
- remove only clearly disconnected display helpers from the iOS background-status sheet
- leave renderer, export, metadata, share, and queue semantics untouched

What landed:

- Added [ConfigurationCenterRegionComposerSection.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenterRegionComposerSection.swift)
  - extracted the `IOSRegionComposer` host assembly out of [ConfigurationCenteriOSView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift)
  - child view now receives:
    - region value
    - configuration option list
    - parent-owned bindings
    - save/delete callbacks
- Updated [ConfigurationCenteriOSView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift)
  - `activeRegionEditorContent` now delegates the region-composer branch to the new support view
  - removed now-unused local helpers:
    - `refreshRegionPreview`
    - `selectedMemoryPresetBinding`
    - `moduleValue`
- Updated [PhotoMemoiOSBackgroundStatusSheet.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSBackgroundStatusSheet.swift)
  - removed disconnected display helpers that were no longer mounted:
    - `statusCounts`
    - `currentConfigurationCard`
    - `intakeSummaryCard`
    - `currentJobTimelineCard`
    - `recentFailuresCard`
    - `infoRow`
    - `countCard`
  - also removed helper code only used by that disconnected cluster:
    - `intakeExplanation`
    - `resolvedTemplateTitle`
    - `resolvedAnchorTitle`
    - `resolvedDestinationTitle`
    - `jobTimelineRecords`
    - `taskPriority`
    - `JobTimelineRecord`

Current effect:

- [ConfigurationCenteriOSView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift) `1021` -> `971`
- [PhotoMemoiOSBackgroundStatusSheet.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSBackgroundStatusSheet.swift) `890` -> `314`
- current remaining view-heavy priority is now:
  - [PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift) `2095`
  - [MemoryBlockInspectorView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Inspector/MemoryBlockInspectorView.swift) `1053`
  - [ConfigurationCenteriOSView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift) `971`
  - [InteractiveMemoryCard.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/MemoryCard/InteractiveMemoryCard.swift) `867`
  - [PhotoMemoiOSBackgroundStatusSheet.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSBackgroundStatusSheet.swift) `314`

Verification:

- passed:
  - `git -C /Users/rui/Desktop/PhotoMemo diff --check`
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -target PhotoMemo -configuration Debug CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO build`

## 2026-07-01 PhotoMemoiOSV1 settings-page surface extraction

Scoped to one more `Architecture Freeze V1` presentation-only slice:

- keep diagnostics refresh and history-clear actions in the parent view
- move the settings-page shell and diagnostics presentation rendering into a dedicated iOS surface
- leave persistence and background processing semantics untouched

What landed:

- Added [V1SettingsPageSurface.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1SettingsPageSurface.swift)
  - extracted:
    - settings page shell
    - diagnostics card
    - progress summary
    - pipeline / queue line rendering
- Updated [PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift)
  - `settingsPage` now delegates to the new surface
  - parent keeps header/data projections plus refresh/clear actions only

Current effect:

- [PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift) `2370` -> `2095`

## 2026-07-01 ConfigurationCenter active-region support extraction

Scoped to the next safe `ConfigurationCenteriOSView` support-view pass:

- keep region mutation routing, adapters, and draft-store ownership in the parent
- extract only the insertable-module library and active-region editor shell
- do not let child views read `session` or policy objects directly

What landed:

- Added [ConfigurationCenterInsertableModuleLibrarySection.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenterInsertableModuleLibrarySection.swift)
  - extracted the fixed insertable-module library row/chips/menu surface
- Added [ConfigurationCenterActiveRegionEditorSection.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenterActiveRegionEditorSection.swift)
  - extracted the active-region editor outer shell, header, and `.id(selectedRegion)` container
- Updated [ConfigurationCenteriOSView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift)
  - parent keeps:
    - `ConfigurationCenterDetailPresenter` resolution
    - region content switching
    - `regionDraftStore` bindings
    - `insertModuleIntoCurrentRegion`

Current effect:

- [ConfigurationCenteriOSView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift) `1106` -> `1021`
- current remaining view-heavy priority is now:
  - [PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift) `2095`
  - [MemoryBlockInspectorView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Inspector/MemoryBlockInspectorView.swift) `1053`
  - [ConfigurationCenteriOSView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift) `1021`
  - [PhotoMemoiOSBackgroundStatusSheet.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSBackgroundStatusSheet.swift) `890`
  - [InteractiveMemoryCard.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/MemoryCard/InteractiveMemoryCard.swift) `867`

Agent findings recorded:

- `ConfigurationCenteriOSView` next safest target after this pass:
  - the `IOSRegionComposer` host assembly inside `activeRegionEditorContent`
  - keep all bindings/mutation closures parent-owned
- lower-priority cleanup candidate:
  - [PhotoMemoiOSBackgroundStatusSheet.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSBackgroundStatusSheet.swift) appears to contain a leftover disconnected display cluster that is more worth cleaning than any remaining tiny `MemoryBlockInspectorView` pure-view pieces

Verification:

- passed:
  - `git -C /Users/rui/Desktop/PhotoMemo diff --check`
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -target PhotoMemo -configuration Debug CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO build`

## 2026-07-01 PhotoMemoiOSV1 home-page surface extraction

Scoped to the next `Architecture Freeze V1` presentation-only slice:

- keep `PhotoMemoiOSV1View` as the owner of state, focus, persistence, and tab-routing behavior
- move only the home-page presentation assembly into a dedicated support surface
- keep save/bootstrap/application seams unchanged

What landed:

- Added [V1HomePageSurface.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1HomePageSurface.swift)
  - extracted the full home-page surface assembly:
    - current subject card
    - current preset card
    - quick actions
    - recent processing
    - default output summary
- Updated [PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift)
  - `homePage` now delegates to the new surface
  - parent keeps:
    - preset picker/menu views
    - title editing focus/binding
    - save action
    - tab switching
    - scroll offset reader
    - projections and messages

Current effect:

- [PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift) `2556` -> `2370`
- current remaining view-heavy priority is now:
  - [PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift) `2370`
  - [ConfigurationCenteriOSView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift) `1106`
  - [MemoryBlockInspectorView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Inspector/MemoryBlockInspectorView.swift) `1053`
  - [PhotoMemoiOSBackgroundStatusSheet.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSBackgroundStatusSheet.swift) `890`
  - [InteractiveMemoryCard.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/MemoryCard/InteractiveMemoryCard.swift) `867`

Verification:

- passed:
  - `git -C /Users/rui/Desktop/PhotoMemo diff --check`
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -target PhotoMemo -configuration Debug CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO build`

## 2026-07-01 InteractiveMemoryCard configuration-dock extraction

Scoped to another pure `Architecture Freeze V1` slice:

- continue support-view extraction only
- keep live session mutation and module insertion routing in the parent
- loosen only the minimum type visibility needed to share the insertable-module model across files

What landed:

- Added [InteractiveMemoryCardConfigurationComponentDock.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/MemoryCard/InteractiveMemoryCardConfigurationComponentDock.swift)
  - extracted the lower configuration dock surface:
    - memory-write panel
    - insertable-module library
    - current output preview
    - output/storage panel
    - configuration guide cards
- Updated [InteractiveMemoryCard.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/MemoryCard/InteractiveMemoryCard.swift)
  - parent now keeps only dock bindings, resolved strings, expansion state, and module-insert action routing
  - `CenterInsertableModule` was widened from file-private to shared file scope for the new support view

Current effect:

- [InteractiveMemoryCard.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/MemoryCard/InteractiveMemoryCard.swift) `1562` -> `1313` -> `1195` -> `867`
- current remaining view-heavy priority is now:
  - [PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift) `2556`
  - [ConfigurationCenteriOSView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift) `1106`
  - [MemoryBlockInspectorView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Inspector/MemoryBlockInspectorView.swift) `1053`
  - [PhotoMemoiOSBackgroundStatusSheet.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSBackgroundStatusSheet.swift) `890`
  - [InteractiveMemoryCard.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/MemoryCard/InteractiveMemoryCard.swift) `867`

Verification:

- passed:
  - `git -C /Users/rui/Desktop/PhotoMemo diff --check`
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -target PhotoMemo -configuration Debug CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO build`

## 2026-07-01 InteractiveMemoryCard configuration-context extraction

Scoped to the next safe `Architecture Freeze V1` slice:

- continue pure view/support-view extraction only
- keep `ConfigurationSession` ownership, preset mutation, and apply/reset behavior in the parent
- do not touch renderer, export, metadata, share, or storage semantics

What landed:

- Added [InteractiveMemoryCardConfigurationContext.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/MemoryCard/InteractiveMemoryCardConfigurationContext.swift)
  - extracted the top configuration header surface:
    - preset picker
    - time-anchor status
    - rename field
    - reset/apply actions
- Updated [InteractiveMemoryCard.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/MemoryCard/InteractiveMemoryCard.swift)
  - parent now owns only:
    - preset bindings
    - rename toggle state
    - apply/reset routing
  - removed the inline header-building helpers from the main memory-card file

Current effect:

- [InteractiveMemoryCard.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/MemoryCard/InteractiveMemoryCard.swift) `1562` -> `1313` -> `1195`
- current remaining view-heavy priority is now:
  - [PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift) `2556`
  - [InteractiveMemoryCard.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/MemoryCard/InteractiveMemoryCard.swift) `1195`
  - [ConfigurationCenteriOSView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift) `1106`
  - [MemoryBlockInspectorView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Inspector/MemoryBlockInspectorView.swift) `1053`
  - [PhotoMemoiOSBackgroundStatusSheet.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSBackgroundStatusSheet.swift) `890`

Verification:

- passed:
  - `git -C /Users/rui/Desktop/PhotoMemo diff --check`
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -target PhotoMemo -configuration Debug CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO build`

## 2026-07-01 MemoryBlockInspector custom-fields extraction + dead-helper cleanup

Scoped to one more strict `Architecture Freeze V1` slice:

- keep the work inside pure view/support-view boundaries
- do not reopen session mutation, renderer/export semantics, or application seams
- remove clearly unused inspector helper UI only where it is already disconnected from the live surface

What landed:

- Added [MemoryBlockInspectorCustomFieldsSection.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Inspector/MemoryBlockInspectorCustomFieldsSection.swift)
  - extracted the custom-field card list, drag/drop ordering, inline preview chips, and delete controls out of the main inspector file
- Updated [MemoryBlockInspectorView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Inspector/MemoryBlockInspectorView.swift)
  - parent file now keeps custom-field state ownership, bindings, and mutation routing only
  - removed disconnected legacy helper surfaces that were no longer mounted in `body`:
    - `moduleInsertionLibrary`
    - `resolvedResult`
    - `behaviorSummary`
    - related unused enum cases and chip helpers

Current effect:

- [MemoryBlockInspectorView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Inspector/MemoryBlockInspectorView.swift) `1589` -> `1520` -> `1053`
- current remaining view-heavy priority is now:
  - [PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift) `2556`
  - [ConfigurationCenteriOSView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift) `1106`
  - [MemoryBlockInspectorView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Inspector/MemoryBlockInspectorView.swift) `1053`
  - [InteractiveMemoryCard.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/MemoryCard/InteractiveMemoryCard.swift) `1195`
  - [PhotoMemoiOSBackgroundStatusSheet.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSBackgroundStatusSheet.swift) `890`

Next safest queue now:

- `InteractiveMemoryCard`
  - `configurationContext`
  - `configurationComponentDock`
  - note: `configurationComponentDock` will need `CenterInsertableModule` visibility loosened or adapted before separate-file extraction
- `PhotoMemoiOSV1View`
  - `homePage`
  - `settingsPage`
- `ConfigurationCenteriOSView`
  - active-region editor support sections

## 2026-07-01 Multi-agent view-surface extraction pass

Scoped to one coordinated post-freeze shrink pass:

- keep all work at the pure view/support-view layer
- leave live session mutation, save/bootstrap seams, renderer rules, and export semantics unchanged
- use parallel agents only on disjoint files so the current dirty workspace stays manageable

What landed:

- Added [MemoryBlockInspectorConfigurationPickerSection.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Inspector/MemoryBlockInspectorConfigurationPickerSection.swift)
- Added [MemoryBlockInspectorCustomFieldsSection.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Inspector/MemoryBlockInspectorCustomFieldsSection.swift)
- Added [MemoryBlockInspectorSystemModulesSection.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Inspector/MemoryBlockInspectorSystemModulesSection.swift)
- Updated [MemoryBlockInspectorView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Inspector/MemoryBlockInspectorView.swift)
  - extracted the configuration-picker section
  - extracted the custom-fields section
  - extracted the system-modules section
  - parent file now keeps the data mapping, template-selection binding, and delete action routing
- Added [InteractiveMemoryCardCompactPreview.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/MemoryCard/InteractiveMemoryCardCompactPreview.swift)
- Updated [InteractiveMemoryCard.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/MemoryCard/InteractiveMemoryCard.swift)
  - moved the compact preview surface out of the main memory-card file
  - parent still owns `session.select(...)` and `session.hoverRegion(...)`
- Added [ConfigurationCenterDetailSupportPanels.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenterDetailSupportPanels.swift)
- Updated [ConfigurationCenteriOSView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift)
  - extracted the detail-side memory-write, output, and guide panels
  - parent still owns session-derived models and bindings
- Added [V1OutputPageSurface.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1OutputPageSurface.swift)
- Updated [PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift)
  - moved the output-tab surface out of the main V1 page shell
  - output state and actions remain in the parent
- Added [PhotoMemoiOSBackgroundStatusSheetSupportViews.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSBackgroundStatusSheetSupportViews.swift)
- Updated [PhotoMemoiOSBackgroundStatusSheet.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSBackgroundStatusSheet.swift)
  - extracted the hero, pipeline, focus, and latest-failure display sections
  - service reads and retry behavior remain in the parent

Current effect:

- [MemoryBlockInspectorView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Inspector/MemoryBlockInspectorView.swift) `1589` -> `1053`
- [InteractiveMemoryCard.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/MemoryCard/InteractiveMemoryCard.swift) `1562` -> `1313`
- [ConfigurationCenteriOSView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift) `1197` -> `1106`
- [PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift) `2699` -> `2556`
- [PhotoMemoiOSBackgroundStatusSheet.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSBackgroundStatusSheet.swift) `1180` -> `890`

Verification:

- passed:
  - `git -C /Users/rui/Desktop/PhotoMemo diff --check`
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -target PhotoMemo -configuration Debug CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO build`
  - agent-local slice verification also passed for:
    - `PhotoMemoiOSBackgroundStatusSheet`
    - `InteractiveMemoryCard`
- attempted earlier but not used as final signal:
  - multiple `PhotoMemoiOSV1` scheme builds were temporarily blocked by parallel file-landing timing while new support files were still appearing

Updated remaining view-heavy priority:

- [PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift) `2556`
- [InteractiveMemoryCard.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/MemoryCard/InteractiveMemoryCard.swift) `1313`
- [ConfigurationCenteriOSView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift) `1106`
- [MemoryBlockInspectorView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Inspector/MemoryBlockInspectorView.swift) `1053`
- [PhotoMemoiOSBackgroundStatusSheet.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSBackgroundStatusSheet.swift) `890`

Next safest queue now:

- `InteractiveMemoryCard`
  - configuration context header
  - configuration dock
- `PhotoMemoiOSV1View`
  - home/settings page surfaces
  - more output-adjacent support sections only after current slice settles
- `ConfigurationCenteriOSView`
  - active-region editor support sections after current detail panels settle

## 2026-07-01 ConfigurationCenter top preview extraction

Scoped to one more post-freeze pure-view slice only:

- continue shrinking `ConfigurationCenteriOSView` without touching live mutation seams
- keep keyboard dismissal, preset actions, and region selection behavior unchanged
- do not reopen session / application / MME boundaries in this pass

What landed:

- Added [ConfigurationCenterTopPreviewSection.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenterTopPreviewSection.swift)
  - extracted the entire top preview/profile surface into one dedicated support view:
    - profile summary panel
    - compact preview card wrapper
    - region strip
    - region strip buttons
- Updated [ConfigurationCenteriOSView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift)
  - `topConfigurationPreview` now delegates to the new support view
  - preset apply/reset, rename toggle, and region-switch actions still route through the same parent closures and selection coordinator

Current effect:

- `ConfigurationCenteriOSView.swift` dropped from about `1419` lines to `1197` lines
- the parent file now reads more clearly as:
  - navigation shell
  - sidebar/detail composition
  - binding/mutation seam
- the extracted top section is still presentation-only and does not instantiate services or own business flow

Verification:

- passed:
  - `git -C /Users/rui/Desktop/PhotoMemo diff --check`
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOSV1 -configuration Debug -destination 'generic/platform=iOS' -derivedDataPath /tmp/PhotoMemoiOSV1DerivedData-config-top-preview-pass CODE_SIGNING_ALLOWED=NO -quiet build`

Remaining view-heavy priority after this slice:

- [PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift) `2699`
- [MemoryBlockInspectorView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Inspector/MemoryBlockInspectorView.swift) `1589`
- [InteractiveMemoryCard.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/MemoryCard/InteractiveMemoryCard.swift) `1562`
- [ConfigurationCenteriOSView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift) `1197`
- [PhotoMemoiOSBackgroundStatusSheet.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSBackgroundStatusSheet.swift) `1180`

Next safest extraction queue:

- `MemoryBlockInspectorView`
  - configuration picker
  - custom-field editor
  - system-modules section
- `InteractiveMemoryCard`
  - compact preview surface
  - configuration context header
  - configuration dock
- `PhotoMemoiOSV1View`
  - page-level home/output/settings surfaces
  - more pure support sections before touching save/bootstrap seams

## 2026-07-01 ConfigurationSession presentation-state extraction + V1 draft orchestration cleanup

Scoped to the next post-freeze narrow slice only:

- `ConfigurationSession` should stop owning UI-only output/write flags inline
- legacy `memory.configuration1` wording should stop drifting away from the frozen birthday-age smart-module expression
- `PhotoMemoiOSV1View` should keep state in the view, but move draft/preview orchestration glue outward
- no renderer, export, metadata, share-extension, or photo-library semantic rewrite

What landed:

- Added [ConfigurationSessionPresentationState.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/ConfigurationSessionPresentationState.swift)
  - extracted the session’s UI-only presentation fields into one dedicated state holder:
    - selected output option
    - selected storage option
    - custom memory-write toggle/text
    - latest module insertion
    - applied preset marker
- Updated [ConfigurationSession.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/ConfigurationSession.swift)
  - the public surface stays compatible for current views/tests
  - the inline UI-only state no longer lives as six separate top-level session fields
- Added [ConfigurationCenterMemoryTemplateCatalog.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/ConfigurationCenterMemoryTemplateCatalog.swift)
  - centralizes the `memory.configuration1` birthday-age smart-module copy
  - provides one shared fallback preview sentence aligned to the current frozen formula
- Updated these smart-module wording callers to use the shared catalog instead of parallel hardcoded copy:
  - [ConfigurationCenterPreviewDefaults.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/ConfigurationCenterPreviewDefaults.swift)
  - [ConfigurationCenterRegionDraftStore.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenterRegionDraftStore.swift)
  - [MemoryBlockInspectorView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Inspector/MemoryBlockInspectorView.swift)
  - [InteractiveMemoryCard.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/MemoryCard/InteractiveMemoryCard.swift)
- Added [V1DraftOrchestrationCoordinator.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1DraftOrchestrationCoordinator.swift)
  - keeps `@State` in [PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift)
  - moves draft-state bridging and dirty-preview fan-out into one pure helper
- Updated [PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift)
  - `draft(for:)` now routes through the orchestration helper
  - mutation updates now bridge state once and batch preview refresh through `refreshDynamicPreview(...)`

Tests:

- Added [V1DraftOrchestrationCoordinatorTests.swift](/Users/rui/Desktop/PhotoMemo/Tests/PhotoMemoTests/ArchitectureTests/V1DraftOrchestrationCoordinatorTests.swift)
- Updated [ConfigurationCenterRegionDraftStoreTests.swift](/Users/rui/Desktop/PhotoMemo/Tests/PhotoMemoTests/ArchitectureTests/ConfigurationCenterRegionDraftStoreTests.swift) for the shared birthday-age template title

Current effect:

- `ConfigurationSession` is still the live editing shell, but the most obvious UI-only output/write state is now isolated behind one smaller state object
- the birthday-age smart-module no longer has one preview sentence in one place and older `当天多大` copy in another
- `PhotoMemoiOSV1View` still owns view state, but less of the draft/preview synchronization choreography

Verification:

- passed:
  - `git -C /Users/rui/Desktop/PhotoMemo diff --check`
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -target PhotoMemoTests -configuration Debug CODE_SIGNING_ALLOWED=NO -quiet build`
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOSV1 -configuration Debug -destination 'generic/platform=iOS' -derivedDataPath /tmp/PhotoMemoiOSV1DerivedData-architecture-freeze-pass-4 CODE_SIGNING_ALLOWED=NO -quiet build`
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData-architecture-freeze-pass-2 CODE_SIGNING_ALLOWED=NO -quiet build`

Next queued slice:

- keep shrinking `ConfigurationSession` by moving the remaining presentation-only state and bindings behind dedicated seams
- continue replacing parallel smart-module placeholder logic with shared MME-driven preview defaults
- then resume broader application/usecase normalization, especially older intent fallbacks

## 2026-07-01 V1 pure-view support extraction

Scoped to a safe view-only shrink pass:

- keep behavior unchanged
- move already-self-contained UI support views out of `PhotoMemoiOSV1View`
- no business-logic, renderer, export, or persistence rewrite

What landed:

- Added [V1IOSViewSupportComponents.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSViewSupportComponents.swift)
  - moved:
    - `V1CardSurface`
    - `V1PreviewCard`
    - `V1RegionEditorCard`
    - the local `CardRegion.systemImage` support extension
- Updated [PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift)
  - removed the inline definitions and kept the call sites intact

Current effect:

- `PhotoMemoiOSV1View.swift` dropped from about `3310` lines to `2699` lines
- the V1 iOS shell is still large, but the most obviously reusable pure-view block is no longer mixed into the main page file

Verification:

- passed:
  - `git -C /Users/rui/Desktop/PhotoMemo diff --check`
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOSV1 -configuration Debug -destination 'generic/platform=iOS' -derivedDataPath /tmp/PhotoMemoiOSV1DerivedData-view-slice-pass CODE_SIGNING_ALLOWED=NO -quiet build`

## 2026-07-01 Architecture Freeze V1 + V1 save/bootstrap seam cleanup

Scoped to the first “strict boundary” slice only:

- added [ARCHITECTURE_FREEZE_V1.md](/Users/rui/Desktop/PhotoMemo/Docs/ARCHITECTURE_FREEZE_V1.md) to freeze the current near-term architecture rules
- removed the direct `SettingsService()` save fallback from `PhotoMemoiOSV1View`
- removed the settings-backed bootstrap fallback from `V1ConfigurationBootstrapCoordinator`
- introduced one dedicated V1 application seam for “resolve album + save configuration”
- no renderer, export semantics, share semantics, or photo-library behavior rewrite

What landed:

- Added [V1ConfigurationApplyCoordinator.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1ConfigurationApplyCoordinator.swift)
  - new `V1ConfigurationApplyRequest`
  - new `V1ConfigurationApplyReceipt`
  - one orchestration path for:
    - output album resolution
    - `V1ConfigurationSaveRequest` construction
    - `SaveV1ConfigurationIntent` execution
- Updated [PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift)
  - `applyCurrentV1Configuration()` no longer directly instantiates `SettingsService`
  - save flow now routes through `V1ConfigurationApplyCoordinator`
  - the old local `persistTimeAnchor(...)` seam was removed from the view
  - the old local `resolvedOutputAlbumSelection()` seam was removed from the view
- Updated [V1ConfigurationBootstrapCoordinator.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1ConfigurationBootstrapCoordinator.swift)
  - `init(configurationCoordinator:)` no longer reads `SettingsRepository(SettingsService())`
  - nil-coordinator bootstrap now falls back to a pure default value state instead of touching persistence from presentation helpers
- Added/updated tests:
  - [V1ConfigurationApplyCoordinatorTests.swift](/Users/rui/Desktop/PhotoMemo/Tests/PhotoMemoTests/ArchitectureTests/V1ConfigurationApplyCoordinatorTests.swift)
  - [V1ConfigurationBootstrapCoordinatorTests.swift](/Users/rui/Desktop/PhotoMemo/Tests/PhotoMemoTests/ArchitectureTests/V1ConfigurationBootstrapCoordinatorTests.swift)
- Follow-up `ConfigurationSession` boundary cleanup also landed in the same architecture-freeze workstream:
  - [ConfigurationCenterPreviewDefaults.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/ConfigurationCenterPreviewDefaults.swift) now owns the preview-default/template registry
  - [ConfigurationCenterMockSeed.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/ConfigurationCenterMockSeed.swift) now owns `ConfigurationCenterState.mock`
  - [ConfigurationSession.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/ConfigurationSession.swift) keeps thin wrapper seams instead of embedding the full registry + mock construction inline

Current effect:

- the active V1 iOS save path no longer lets the view decide whether to bypass the application seam and write settings directly
- the active V1 bootstrap helper no longer reaches into persisted settings on its own when the coordinator is absent
- the repo now has a written architecture freeze that explicitly forbids `View -> Service` regression for this line of work
- `ConfigurationSession` is still not fully lightweight yet, but the preview-default registry and mock seed are no longer owned inline by the session file

Verification:

- passed:
  - `git -C /Users/rui/Desktop/PhotoMemo diff --check`
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -target PhotoMemoTests -configuration Debug CODE_SIGNING_ALLOWED=NO -quiet build`
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOSV1 -configuration Debug -destination 'generic/platform=iOS' -derivedDataPath /tmp/PhotoMemoiOSV1DerivedData-architecture-freeze-pass-3 CODE_SIGNING_ALLOWED=NO -quiet build`
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData-architecture-freeze-pass CODE_SIGNING_ALLOWED=NO -quiet build`

Next queued slice:

- continue shrinking `ConfigurationSession` by moving UI-only output/write state and then removing legacy smart-module wording drift from shared defaults/templates

## 2026-07-01 V1 subject persistence + MME smart-module preview alignment

Scoped to the user-confirmed V1 gaps only:

- `subject` avatar / expression-subject / active-anchor data must stop living only inside `ConfigurationSession`
- smart-module insertion must behave as a cross-region module for `slotA / slotB / slotC / slotD`
- preview smart-module wording must align to the frozen MME birthday formula
- keyboard dismissal must behave more like an iOS configuration page
- no renderer rewrite, export rewrite, or share/photo-library semantic change

What landed:

- Old V1 save/bootstrap now carries a persisted `MemorySubject`:
  - `V1ConfigurationSaveRequest` and `V1ConfigurationBootstrapState` now include `subject`
  - `SettingsService` now stores and reads `photomemo.selectedMemorySubject`
  - `SettingsRepository` and `ConfigurationCoordinator` now persist/load that subject through the existing V1 configuration seam
- `PhotoMemoiOSV1View` now restores the saved subject back into the live session through a dedicated `restoreSelectedSubject(...)` path instead of relying on mock subject IDs matching across launches.
- V1 save now persists an aligned subject object:
  - current avatar paths
  - selected expression-subject source
  - active anchor
  - primary anchor date/reference date aligned to the current anchor editor date
- V1 bootstrap now also restores the subject-driven anchor date back into the page-level `birthdayDate`, so the anchor editor and restored subject no longer drift immediately after launch.
- Smart-module preview text is now driven by one shared MME preview resolver:
  - new file: `MemoryExpressionPreviewResolver.swift`
  - `ConfigurationSession.generatedMemoryModule`
  - `ConfigurationCenterPreviewCompositionHelper.smartTimeResult`
  - `V1PreviewCompositionEngine.smartTime`
  now all resolve through the same `MemoryExpressionEngine` path with a preview capture date.
- V1 default slot-D preview draft now resolves from the smart module directly instead of the older `subject + 当天 + age` local splice.
- Smart-module save tokens were upgraded from age-only output to full memory-summary output:
  - `PhotoMemoiOSModuleCatalog.smartTime.rendererToken`
  - `V1PreviewCompositionModule.smartTime.rendererToken`
  now use `{{memory_summary}}`
- Birthday summary wording was tightened to the frozen first formula direction:
  - `MemoryVariableProvider.memorySummary`
  - `AnchorEngine` birthday `summaryText`
  now append `啦！`
- Keyboard dismissal was tightened on iOS:
  - `PhotoMemoiOSV1View` home/editor/output/settings scroll surfaces now use scroll-dismiss plus tap-to-dismiss
  - `V1IOSSubjectConfigurationFlow` now also dismisses the keyboard when tapping blank space
  - the V1 page-level preset title focus is cleared together with first responder dismissal

Current effect:

- `subject` is no longer only a temporary editing object inside `ConfigurationSession`; V1 save/load now has a real long-term subject seam.
- Smart-module insertion remains user-controlled and cross-region, but the preview wording now follows the MME formula instead of the older local age-only splice.
- Saving a V1 configuration now preserves the subject-side expression choice that the future real photo run needs.

Verification:

- passed:
  - `git -C /Users/rui/Desktop/PhotoMemo diff --check`
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -target PhotoMemoTests -configuration Debug CODE_SIGNING_ALLOWED=NO -quiet build`
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOSV1 -configuration Debug -destination 'generic/platform=iOS' -derivedDataPath /tmp/PhotoMemoiOSV1DerivedData-mme-subject-pass CODE_SIGNING_ALLOWED=NO -quiet build`
- attempted but blocked by existing project scheme setup, not by a compiler/test failure in this slice:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -destination 'platform=macOS' -only-testing:PhotoMemoTests/PreviewCompositionMigrationTests -only-testing:PhotoMemoTests/ConfigurationMigrationTests -only-testing:PhotoMemoTests/ConfigurationCenterPreviewCompositionHelperTests -only-testing:PhotoMemoTests/SettingsServiceTests -only-testing:PhotoMemoTests/MemoryEngineTests -only-testing:PhotoMemoTests/RecordCardBuildServiceTests CODE_SIGNING_ALLOWED=NO test`
  - current blocker: `Scheme PhotoMemo is not currently configured for the test action.`

Not yet manually verified:

- tapping the preview card itself on iPhone while a multiline field is focused
- subject restore behavior across a full kill-and-relaunch cycle on device
- real generated-image output using the newly switched `{{memory_summary}}` token on device

## 2026-07-01 V1 subject/avatar/logo alignment + active-anchor quick switch

Scoped to the confirmed V1 feedback and IA-003-compatible subject/MEE enrichment only:

- `Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Models/MemorySubject.swift`
- `Source/PhotoMemo/PhotoMemo/ConfigurationCenter/ConfigurationSession.swift`
- `Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Editors/MemorySubjectEditorView.swift`
- `Source/PhotoMemo/PhotoMemo/Services/SubjectAvatarAssetOptimizationService.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSHomeProjection.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectOverviewSupport.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/V1LogoMode.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/V1ConfigurationBootstrapPresenter.swift`
- `Source/PhotoMemo/PhotoMemo/Intent/ConfigurationSaveIntents.swift`
- `Source/PhotoMemo/PhotoMemo/Repositories/SettingsRepository.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift`
- updated V1 bootstrap tests and related architecture assertions only
- no renderer, export, share-extension behavior, photo-library semantic, or layout-engine change

What landed:

- `MemorySubject.Identity` now carries three avatar-purpose paths:
  - display avatar
  - logo/badge avatar
  - preview avatar
- Added `SubjectAvatarAssetOptimizationService` to prepare fixed-purpose avatar PNGs before renderer consumption.
- `MemorySubjectEditorView` now supports:
  - avatar upload/optimization
  - single-choice “表述主体” selection across the four basic-profile rows
  - active-anchor-aligned time-anchor editing
- `ConfigurationSession` now resolves current anchor title/description from `primaryTimeAnchor`, so `activeTimeAnchorID` becomes the live source of truth instead of only `behavior.primaryAnchor`.
- Home `当前记忆对象` no longer repeats the lower duplicate time-anchor entry.
- Home subject card now shows:
  - subject avatar when available
  - `当前生效时间锚点`
- `V1IOSSubjectOverviewSheet` now acts as a quick active-anchor chooser:
  - dropdown selection
  - explicit `设为生效` confirmation
  - full subject editor remains available as the deeper path
- V1 logo mode now has three options:
  - `Apple 标识`
  - `自选标识`
  - `使用对象头像`
- Added shared `V1LogoMode` so both app/bootstrap and test-side compilation can see the same mode enum.
- V1 bootstrap/persistence interpretation now restores the third logo mode by detecting the saved badge name `对象头像`.
- Follow-up verification cleanup also landed:
  - `V1IOSHomeProjectionTests` was updated to the current `MemoryBehavior` initializer and current `DecorationStrategy` values
  - `V1IOSHomeSupportViews.swift` was opened to the non-share macOS/test compile surface so `V1IOSHomeRecentProcessingPresenter` is available to the test target again

Current assessment:

- The requested interaction direction is now materially in code:
  - active anchor is explicit
  - expression subject is explicit
  - avatar assets are prepared before preview/logo consumption
  - subject-home duplication is reduced
- Important remaining limitation:
  - subject/avatar/expression-subject edits still live inside `ConfigurationSession` and are not yet persisted through the older V1 save pipeline as first-class subject data
  - logo mode persistence is restored, but subject object persistence remains a later slice

Verification:

- passed:
  - `git -C /Users/rui/Desktop/PhotoMemo diff --check`
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOSV1 -configuration Debug -destination 'generic/platform=iOS' -derivedDataPath /tmp/PhotoMemoiOSV1DerivedData-mee-ui-pass-2 CODE_SIGNING_ALLOWED=NO -quiet build`
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOSV1 -configuration Debug -destination 'generic/platform=iOS' -derivedDataPath /tmp/PhotoMemoiOSV1DerivedData-mee-ui-pass-3 CODE_SIGNING_ALLOWED=NO -quiet build`
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData-mac-shared-check CODE_SIGNING_ALLOWED=NO -quiet build`
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -target PhotoMemoTests -configuration Debug CODE_SIGNING_ALLOWED=NO -quiet build`

Not yet manually verified:

- device-side avatar upload flow in the subject editor
- quick active-anchor switch UX on iPhone
- `使用对象头像` logo mode on a real device preview/save path

## 2026-07-01 Repository file organization baseline

Scoped to repository hygiene only:

- `Docs/PROJECT_STRUCTURE.md`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/README.md`
- `HANDOFF.md`
- `Docs/CURRENT_STATUS.md`
- cleanup of obvious local residue only

What landed:

- Added an explicit source-tree map for the newer app-facing folders that had already appeared in code:
  - `Architecture/`
  - `Repositories/`
  - `Intent/`
  - `Coordinators/`
- Added an `iOS/Views` lookup note so the current flat folder is easier to navigate by responsibility:
  - Configuration Center
  - V1 shell / subject flow
  - Home
  - Diagnostics / support
- Kept the physical `iOS/Views` folder flat for now to avoid breaking:
  - filesystem-synchronized Xcode membership assumptions
  - historical handoff links
  - in-progress V1 verification flow
- Removed obvious local residue that did not belong in the repository structure baseline.

Current assessment:

- The repository is easier to scan without reopening a broad filesystem migration.
- A future physical move of `iOS/Views` files should be treated as its own reviewed cleanup slice, not mixed into IA-003 implementation work.

## 2026-07-01 MEE foundation + configuration-center secondary-menu alignment

Scoped to the first IA-003-compatible Memory Expression Engine foundation slice plus configuration-center semantic alignment only:

- `Source/PhotoMemo/PhotoMemo/MemoryEngine/MemoryAnchor.swift`
- `Source/PhotoMemo/PhotoMemo/MemoryEngine/MemoryModule.swift`
- `Source/PhotoMemo/PhotoMemo/MemoryEngine/MemoryExpressionContext.swift`
- `Source/PhotoMemo/PhotoMemo/MemoryEngine/MemoryExpressionEngine.swift`
- `Source/PhotoMemo/PhotoMemo/MemoryEngine/MemorySubjectAdapter.swift`
- `Source/PhotoMemo/PhotoMemo/ConfigurationCenter/ConfigurationSnapshotBuilder.swift`
- `Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Models/MemorySubject.swift`
- `Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Models/ConfigurationSnapshot.swift`
- `Source/PhotoMemo/PhotoMemo/ConfigurationCenter/ConfigurationSession.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/IOSConfigurationPanel.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenterDetailPresenter.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenterPageChromePresenter.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenterSessionBindingPresenter.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/MemoryWriteOptionPresenter.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift`
- `Source/PhotoMemo/PhotoMemo/ConfigurationCenter/MemoryCard/InteractiveMemoryCard.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift`
- related architecture tests for the same MEE foundation and secondary-menu wording slice
- no renderer, export, share-extension, photo-library semantic, or layout-engine change

What landed:

- A minimal Memory Expression Engine foundation now exists in code:
  - `MemoryAnchor`
  - `MemoryModule`
  - `MemoryExpressionContext`
  - `MemoryExpressionEngine.generateModule(context)`
  - `MemorySubjectAdapter`
  - `ConfigurationSnapshotBuilder`
- `ConfigurationSnapshot` now carries the minimum data needed for the new foundation:
  - `primaryAnchor`
  - `smartModuleCarrierRegion`
- `ConfigurationSession` now exposes:
  - `smartModuleCarrierRegion`
  - `currentConfigurationSnapshot`
  - `generatedMemoryModule`
- The generated smart-module path is now explicit:
  - `MemorySubject -> ConfigurationSnapshot -> MemoryExpressionEngine -> MemoryModule`
- `resolvedMemoryWriteText` now resolves from the generated module first rather than only from the old inline string helper.
- `selectBlock(...)` no longer forces the editor back to `slotD`, and selecting another region no longer auto-clears `selectedBlockID`.
- The iOS configuration-center secondary menu no longer presents the old `writeMemory` concept as if it were the core semantic owner:
  - `IOSConfigurationPanel.writeMemory` -> `IOSConfigurationPanel.memoryModule`
  - sidebar section `记忆模块` -> `智能模块`
  - panel title `写入记忆` -> `智能模块`
  - panel subtitle now explicitly says:
    - generate one smart module first
    - then decide carrier and write behavior
- The visible copy was tightened to remove the stronger `slotD / current anchor generated` bias:
  - `单独录入相册说明`
  - `当前生成的智能模块完整结果`
  - V1 and Configuration Center surfaces now share the same wording direction
- Region-level editor titles are now expressed as carrier/configuration titles instead of claiming that `slotD` alone owns memory semantics:
  - `区域 A 配置`
  - `区域 B 配置`
  - `区域 C 配置`
  - `区域 D 配置`
- The insertable smart-module strip is no longer shown only for `slotD`; all memory-card regions can now surface the same smart-module entry path.

Verification:

- passed:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoMEEAppDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- attempted but still blocked by unrelated existing architecture-test debt:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -target PhotoMemoTests -configuration Debug CODE_SIGNING_ALLOWED=NO build`
  - currently observed unrelated blockers remain in older V1 tests such as:
    - `V1IOSHomeProjectionTests`
      - still expects older `MemoryBehavior` / `DecorationStrategy` shapes
    - `V1IOSHomeRecentProcessingPresenterTests`
      - still references a missing older presenter symbol

Current assessment:

- The new MEE foundation source compiles inside the main `PhotoMemo` target.
- The current failure surface is still dominated by pre-existing V1 architecture-test debt, not by the new Memory Engine boundary files.
- This slice stays inside the requested boundary:
  - no renderer rewrite
  - no export/share behavior change
  - no photo-library semantic change
  - no layout-engine work

## 2026-07-01 V1 iOS subject flow + configuration center polish

Scoped to the approved V1 UI polish slice only:

- `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectOverviewSupport.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectConfigurationFlow.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenterPageChromePresenter.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenterSelectionCoordinator.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenterSessionBindingPresenter.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/MemoryWriteOptionPresenter.swift`
- `Source/PhotoMemo/PhotoMemo/ConfigurationCenter/MemoryCard/InteractiveMemoryCard.swift`
- related architecture tests for the same subject-flow / page-chrome / memory-write wording slice
- no renderer, Memory Engine boundary, export/share/photo-library semantic, or Layout Engine change

What landed:

- Home `当前记忆对象` now continues into a dedicated subject configuration flow instead of jumping back to the root editor tab.
- The dedicated subject flow reuses `MemorySubjectEditorView` inside an iOS shell with explicit page-level `返回` and `保存`.
- Subject edits are isolated in a draft `ConfigurationSession`; closing the page discards the draft, and page-level save commits back into the live session.
- The main iOS/mac-style Configuration Center now has page-level toolbar chrome with status + `重置` / `保存并生效`.
- Keyboard dismissal was tightened for blank-area taps, scroll surfaces, and preview/panel selection changes.
- The earlier MVP-style fade/slide emphasis around region editing and rename affordances was removed from the current Configuration Center surfaces.
- Memory-write wording now clearly distinguishes:
  - optional separately entered text
  - default fallback to the full `slot D` memory output
- The V1 Output page now shares the same corrected memory-write wording through a dedicated presenter.

Verification:

- passed:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOSV1 -configuration Debug -destination 'generic/platform=iOS' -derivedDataPath /tmp/PhotoMemoiOSV1DerivedData-ui-pass CODE_SIGNING_ALLOWED=NO -quiet build`
- attempted but still blocked by unrelated existing test-suite debt:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -target PhotoMemoTests -configuration Debug CODE_SIGNING_ALLOWED=NO -quiet build`
  - current blockers remain in older V1 architecture tests such as `V1IOSHomeRecentProcessingPresenterTests` plus iOS-only view/test visibility mismatches under the macOS test target

Current assessment:

- The active `PhotoMemoiOSV1` app path is compile-valid after this UI slice.
- Remaining work is now manual UX validation and selective cleanup of older architecture tests, not another wide UI redesign.

## 2026-07-01 V1 target / scheme rename completion

Scoped to the last active `MVP -> V1` identifier cleanup for the current iOS V1 line:

- `Source/PhotoMemo/PhotoMemo.xcodeproj/project.pbxproj`
- `Source/PhotoMemo/PhotoMemo.xcodeproj/xcshareddata/xcschemes/PhotoMemoiOSV1.xcscheme`
- `Source/PhotoMemo/PhotoMemo.xcodeproj/xcuserdata/rui.xcuserdatad/xcschemes/xcschememanagement.plist`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSTemporaryEntryView.swift`
- `Tests/PhotoMemoTests/BatchTests/PhotoMemoiOSTemporaryEntryTests.swift`
- no renderer, Memory Engine boundary, export/share/photo-library semantic, or bundle-identifier change

What landed:

- the active standalone iOS V1 target name is now:
  - `PhotoMemoiOSV1`
- the active standalone iOS V1 shared scheme is now:
  - `PhotoMemoiOSV1`
- the built app product name is now:
  - `PhotoMemoiOSV1.app`
- the last active shell-entry enum/test residue was also removed:
  - `.mvpTest` -> `.v1Preview`
- a targeted active-code scan over:
  - `Source/PhotoMemo/PhotoMemo`
  - `Tests/PhotoMemoTests`
  - `Source/PhotoMemo/PhotoMemo.xcodeproj`
  returned no remaining active `MVP / mvp / PhotoMemoiOSMVP` matches

Verification:

- passed:
  - `xcodebuild -list -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj`
  - scheme/target list now includes `PhotoMemoiOSV1`
- passed:
  - `git diff --check -- /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj/project.pbxproj /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj/xcshareddata/xcschemes/PhotoMemoiOSV1.xcscheme /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj/xcuserdata/rui.xcuserdatad/xcschemes/xcschememanagement.plist /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSTemporaryEntryView.swift /Users/rui/Desktop/PhotoMemo/Tests/PhotoMemoTests/BatchTests/PhotoMemoiOSTemporaryEntryTests.swift`
- passed:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOSV1 -configuration Debug -destination 'generic/platform=iOS' -derivedDataPath /tmp/PhotoMemoiOSV1DerivedData-v1-rename-check-2 CODE_SIGNING_ALLOWED=NO -quiet build`

Current assessment:

- `PhotoMemoiOSV1` is now the current active V1 iOS target/scheme to use going forward
- older `PhotoMemoiOSMVP` references below remain as historical session logs only
- the next step is device signing / install / runtime verification, not more `MVP` cleanup in active code

## 2026-07-01 V1 real-device compile verification

Scoped to a final compile-readiness verification for the active V1 iOS app:

- `Source/PhotoMemo/PhotoMemo.xcodeproj/project.pbxproj`
- no renderer / export / photo-library semantic change
- no new feature work

What was confirmed:

- the current V1 app path `PhotoMemoiOSMVP` now completes a full iPhoneOS Debug build
- the previously blocking shared-defaults diagnostics gap is no longer present in the app-extension chain
- the current build produces all three expected products:
  - `PhotoMemoiOSMVP.app`
  - `PhotoMemoShareExtension.appex`
  - `PhotoMemoWidgetExtension.appex`

Verification:

- passed:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOSMVP -configuration Debug -destination 'generic/platform=iOS' -derivedDataPath /tmp/PhotoMemoiOSMVPDerivedData-v1-final-check CODE_SIGNING_ALLOWED=NO -quiet build`
  - product check under:
    - `/tmp/PhotoMemoiOSMVPDerivedData-v1-final-check/Build/Products/Debug-iphoneos`
- passed:
  - `git diff --check -- /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj/project.pbxproj /Users/rui/Desktop/PhotoMemo/Docs/CURRENT_STATUS.md /Users/rui/Desktop/PhotoMemo/HANDOFF.md`

Current assessment:

- V1 is currently compile-ready for real-device follow-up work
- the remaining next step is no longer project-file compile recovery; it is signing / install / device-side verification

## 2026-07-01 Share Extension target membership shrink

Scoped to a project-structure correction only:

- `Source/PhotoMemo/PhotoMemo.xcodeproj/project.pbxproj`
- no Share Extension behavior change
- no renderer / export / photo-library semantic change
- no new app or extension feature work

What landed:

- `PhotoMemoShareExtension` no longer syncs the whole `PhotoMemo` source tree
- the target now syncs only these narrowed source groups:
  - `PhotoMemo/App`
  - `PhotoMemo/Models`
  - `PhotoMemo/iOS/ShareExtension`
- the narrowed `App` sync excludes app-runtime-only files such as:
  - `PhotoMemoApp*`
  - `PhotoMemoBackgroundStatusService`
  - `PhotoMemoRootSceneView`
  - `PhotoMemoiOSTemporaryEntry`
- the narrowed `Models` sync excludes non-share-only model families such as:
  - `CardVariableProvider`
  - `PhotoMetadata`
  - `RecordCard`
  - `SelectedPhoto`
  - `TemplateVariable*`
- the share-extension folder sync also excludes its unused nested
  `PhotoMemoShareExtension-Info.plist` companion file

Current effect:

- the Share Extension Swift compile list is now reduced to `28` files
- the previously observed accidental compile-in set is no longer present:
  - `ConfigurationCenter/*`
  - `Coordinators/*`
  - `Intent/*`
  - `iOS/Views/*`
  - `Views/Main/*`
  - `Renderers/*`
  - other unrelated shell/UI files

Verification:

- passed:
  - `git diff --check -- Source/PhotoMemo/PhotoMemo.xcodeproj/project.pbxproj`
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -target PhotoMemoShareExtension -configuration Debug CODE_SIGNING_ALLOWED=NO -quiet build`
- observed:
  - a scheme-level build with `-scheme PhotoMemoShareExtension` still fans out into
    `PhotoMemoiOS` / `PhotoMemoiOSMVP` target compilation because of current scheme
    build-action wiring, so it is not a clean proof of Share Extension isolation by itself
  - the target-only build above is the clean verification evidence for this slice

Current assessment:

- the file-count rebound was caused by target-level `fileSystemSynchronizedGroups`
  pointing at the entire `PhotoMemo` root and relying on a large exception list
- the structural rebound path is now removed for `PhotoMemoShareExtension`
- separate simulator-service instability still exists outside this project-file fix:
  - `CoreSimulatorService`
  - `simdiskimaged`

## 2026-07-01 V1 shell identifier migration batch 1

Scoped to a narrow internal naming cleanup for the active iOS V1 shell only:

- `Source/PhotoMemo/PhotoMemo/iOS/App/PhotoMemoiOSMVPApp.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSTemporaryEntryView.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/MVPIOSHomeCardPrimitives.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/MVPIOSHomeProjection.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/MVPIOSHomeSupportViews.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/MVPIOSSubjectOverviewSupport.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/MVPSubjectHomeSummarySupport.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSMVPTestView.swift`
- related architecture tests for the same Home / Subject shell cluster
- no renderer, Memory Engine boundary, export/share/photo-library semantics, or target/scheme renames in this slice

What landed:

- the live iOS V1 shell app entry type now promotes:
  - `PhotoMemoiOSV1App`
- the current iOS V1 shell view now promotes:
  - `PhotoMemoiOSV1View`
- the Home / Subject shell presenter family now promotes `V1` naming:
  - `V1IOSHomeProjection`
  - `V1IOSHomeRecentProcessingPresenter`
  - `V1IOSSubjectOverviewPresenter`
  - `V1SubjectHomeSummaryPresenter`
- matching SwiftUI support surfaces were also lifted to `V1` names:
  - `V1IOSHomeInsetGroup`
  - `V1IOSHomeQuickActionsContent`
  - `V1IOSSubjectOverviewSheet`
  - related Home / Subject support views
- compatibility aliases were intentionally kept for the previous `MVP` symbols so the wider refactor can keep moving in batches without forcing one risky rename wave
- one remaining user-facing line inside the Subject home summary was also tightened from:
  - `Preset`
  to:
  - `配置组合`

Verification:

- passed:
  - `git diff --check -- /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/App/PhotoMemoiOSMVPApp.swift /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSTemporaryEntryView.swift /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/MVPIOSHomeCardPrimitives.swift /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/MVPIOSHomeProjection.swift /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/MVPIOSHomeSupportViews.swift /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/MVPIOSSubjectOverviewSupport.swift /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/MVPSubjectHomeSummarySupport.swift /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSMVPTestView.swift /Users/rui/Desktop/PhotoMemo/Tests/PhotoMemoTests/ArchitectureTests/MVPIOSHomeProjectionTests.swift /Users/rui/Desktop/PhotoMemo/Tests/PhotoMemoTests/ArchitectureTests/MVPIOSSubjectOverviewPresenterTests.swift /Users/rui/Desktop/PhotoMemo/Tests/PhotoMemoTests/ArchitectureTests/MVPSubjectHomeSummaryPresenterTests.swift /Users/rui/Desktop/PhotoMemo/Tests/PhotoMemoTests/ArchitectureTests/MVPIOSHomeRecentProcessingPresenterTests.swift`
- attempted but no final compiler verdict:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData-v1-shell-rename CODE_SIGNING_ALLOWED=NO -quiet build`
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOSMVP -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PhotoMemoIOSMVPDerivedData-v1-shell-rename CODE_SIGNING_ALLOWED=NO -quiet build`
- current verification note:
  - both build attempts reached Xcode build execution and were then manually interrupted after stalling in the same package-loading / in-flight operation path
  - no new compiler diagnostic from this `V1` shell-identifier slice surfaced before interruption

## 2026-07-01 V1.0 visible-name migration

Scoped to a narrow user-visible naming cleanup only:

- `Source/PhotoMemo/PhotoMemoiOSMVP-Info.plist`
- `Source/PhotoMemo/PhotoMemo.xcodeproj/project.pbxproj`
- `Source/PhotoMemo/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionViewController.swift`
- `Source/PhotoMemo/PhotoMemo/PhotoMemo/App/PhotoMemoiOSTemporaryEntry.swift`
- `Source/PhotoMemo/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSMVPTestView.swift`
- no renderer, Memory Engine, export/share semantics, or internal target/type renames in this slice

What landed:

- the current user-visible MVP app name now reads:
  - `PhotoMemo V1.0`
- the iOS V1.0 target photo-library permission strings were updated from
  `PhotoMemo MVP` to `PhotoMemo V1.0`
- the share-extension fallback guidance now says:
  - `请直接打开 PhotoMemo V1.0`
- the temporary-entry display label was softened from:
  - `MVP 测试页`
  to:
  - `V1.0 预览`
- the SwiftUI preview label for the current V1 shell preview was also updated:
  - `iOS V1.0 预览`
- a targeted grep pass over the app/project layer no longer found the old
  user-visible strings:
  - `PhotoMemo MVP`
  - `MVP 测试页`
  - `iOS MVP 测试`

Verification:

- passed:
  - `git diff --check -- Source/PhotoMemo/PhotoMemoiOSMVP-Info.plist Source/PhotoMemo/PhotoMemo.xcodeproj/project.pbxproj Source/PhotoMemo/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionViewController.swift Source/PhotoMemo/PhotoMemo/PhotoMemo/App/PhotoMemoiOSTemporaryEntry.swift Source/PhotoMemo/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSMVPTestView.swift`
  - targeted grep over `Source/PhotoMemo` and `PhotoMemo.xcodeproj` returned no
    remaining matches for the old visible strings above
- in progress / attempted:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOSMVP -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PhotoMemoIOSMVPDerivedData-v1-visible-rename CODE_SIGNING_ALLOWED=NO -quiet build`
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData-v1-visible-rename CODE_SIGNING_ALLOWED=NO -quiet build`
- current verification note:
  - both builds entered Xcode build execution but had not yet produced a final
    compiler verdict at the time this note was updated

Current assessment:

- the user-visible `MVP / MVPTest` cleanup is now largely complete for the
  active V1 app path
- the remaining larger work is no longer wording; it is the deeper internal
  `MVP* -> V1*` symbol and file-family migration

## 2026-07-01 iOS border-style naming lift

Scoped to a narrow iOS shell-language and form-polish slice only:

- `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSMVPTestView.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/MVPIOSHomeCardPrimitives.swift`
- no renderer, preview-internal typography/layout rules, export, share, or photo-library semantic changes

What landed:

- promoted `边框样式` into an explicit first-class line in the iOS shell instead
  of letting it stay visually mixed inside preset/config wording
- Home `当前配置` card now reads in two layers:
  - `边框样式`
  - `配置组合`
- the currently exposed style name is now explicitly shown as:
  - `Classic White`
- the Home card copy was tightened so preset-level controls now read more like
  configuration-combination controls:
  - `切换配置组合`
  - `重命名配置组合`
  - `配置组合名称`
- the save-confirmation wording was also softened away from direct `Preset`
  phrasing toward the new `配置组合` layer
- the iOS Configuration Center top summary now mirrors the same split:
  - `边框样式`
  - `配置组合`
- fixed one existing cross-platform compile blocker in the iOS Home support
  primitives:
  - `MVPIOSHomeStatusBadge.Tone.neutral` no longer uses the unresolved
    `secondarySystemBackground` path on the macOS compile route

Verification:

- passed:
  - `git diff --check -- Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSMVPTestView.swift Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift Source/PhotoMemo/PhotoMemo/iOS/Views/MVPIOSHomeCardPrimitives.swift`
- observed:
  - an initial macOS build attempt surfaced a real compile blocker in
    `MVPIOSHomeCardPrimitives.swift` around the neutral badge background
  - that blocker was fixed in this slice
- attempted but not completed to a final success/failure verdict:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PhotoMemoIOSDerivedData-ui-polish-4 CODE_SIGNING_ALLOWED=NO -quiet build`
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData-ui-polish-5 CODE_SIGNING_ALLOWED=NO -quiet build`
- current verification note:
  - after the neutral-badge fix, both Xcode build attempts remained stuck in
    Xcode in-flight build/package operations long enough that they were
    manually interrupted before a final compiler verdict
  - no additional compiler diagnostic from the new `Classic White` naming/UI
    slice surfaced before interruption

Current assessment:

- the iOS shell is now materially closer to the agreed V1.0 product language:
  - style first
  - configuration combination second
  - renderer/output rules still frozen underneath
- the next natural continuation on this line is:
  - continue replacing remaining visible `Preset` wording in the iOS shell
    where it still reads like internal structure instead of product language
  - decide whether the current single-style `Classic White` line should later
    become a real picker once multiple border styles are unlocked
  - keep delaying broad `MVP* -> V1*` symbol/file renames until the shell copy
    and hierarchy stabilize

## 2026-07-01 iOS home semantic card tightening

Scoped to a narrow iOS Home support-view refresh only:

- `Source/PhotoMemo/PhotoMemo/iOS/Views/MVPIOSHomeCardPrimitives.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/MVPIOSHomeSupportViews.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/MVPIOSHomeProjection.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/MVPSubjectHomeSummarySupport.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSMVPTestView.swift`
- `Tests/PhotoMemoTests/ArchitectureTests/MVPIOSHomeProjectionTests.swift`
- `Tests/PhotoMemoTests/ArchitectureTests/MVPSubjectHomeSummaryPresenterTests.swift`
- no renderer, export, share, photo-library, or `PhotoMemoiOSMVPTestView` editor-flow logic changes

What landed:

- added reusable Home card primitives for a more compact Apple-grouped style:
  - inset grouped surface
  - semantic value rows
  - compact navigation rows
  - applied/pending status badge
- upgraded the top Home summary so it now reads more clearly as:
  - current active configuration
  - current memory subject
  - current time anchor
  - card-ready summary
- upgraded the output summary from loose fact chips into explicit rows for:
  - output mode
  - save destination
  - memory-write behavior
- tightened quick actions and recent-processing summary into denser grouped rows
  so the Subject / Preset / Output cards hold stronger visual priority
- kept the main MVP view touch narrow:
  - only retitled Home card sections to better match the new semantic hierarchy

Verification:

- passed:
  - `git diff --check`
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- attempted:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoTests -destination 'platform=macOS' -only-testing:PhotoMemoTests/MVPIOSHomeProjectionTests -only-testing:PhotoMemoTests/MVPSubjectHomeSummaryPresenterTests -only-testing:PhotoMemoTests/MVPIOSHomeRecentProcessingPresenterTests CODE_SIGNING_ALLOWED=NO test`
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PhotoMemoIOSDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- current verification note:
  - the focused test attempt is still blocked by pre-existing repository test/build issues outside this patch, including existing `MVPIOSHomeRecentProcessingPresenter` / `MVPIOSSubjectOverviewPresenter` visibility gaps and older `MemoryBehavior` test fixtures that no longer match the current initializer
  - the iOS simulator build was still in progress at the time this note was written and had not yet produced a compiler verdict or a direct diagnostic from the new Home support files

## 2026-07-01 iOS home subject-entry promotion

Scoped to a narrow iOS Home/Subject shell refinement only:

- `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSMVPTestView.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/MVPIOSHomeProjection.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/MVPIOSSubjectOverviewSupport.swift`
- `Tests/PhotoMemoTests/ArchitectureTests/MVPIOSHomeProjectionTests.swift`
- `Tests/PhotoMemoTests/ArchitectureTests/MVPIOSSubjectOverviewPresenterTests.swift`
- no renderer, preview-internal typography/layout, export, share, or photo-library semantic changes

What landed:

- promoted the Home top surface from a mixed `Preset + Subject + save-state`
  card toward a clearer two-layer V1.0 shell:
  - `当前记忆对象`
  - `当前配置`
- added a dedicated iOS Subject overview support surface so Home now opens a
  separate Subject sheet instead of keeping Subject fully trapped inside the
  Home summary card
- reused existing `ConfigurationSession` state instead of introducing a parallel
  iOS Subject model:
  - `selectedSubject`
  - `currentTimeAnchorTitle`
  - `currentTimeAnchorDescription`
  - current preset/configuration label state
- added new iOS projections/presenters for:
  - Home preset summary
  - Subject overview presentation
- tightened visible V1.0-facing copy on the iOS shell:
  - default configuration wording instead of share-test wording
  - `默认输出` / `快捷操作`
  - softer settings explanatory copy

Verification:

- passed:
  - `git diff --check`
- attempted:
  - focused tests via `xcodebuild ... test -only-testing:...`
- current verification note:
  - the `PhotoMemo` scheme is not currently configured for the test action, so
    the focused test command could not serve as execution evidence in this slice
- in progress / follow-up verification:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOSMVP -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`

Current assessment:

- iOS Home now reads more like:
  - current memory object
  - current configuration
  - quick actions
  - recent processing
  - default output
- this is still a shell-level refinement, not a full Subject editor migration
- the next safest continuation is:
  - decide whether Subject overview should later become push-navigation instead
    of a sheet
  - continue moving Subject-specific editing deeper while keeping preset editing
    in `editor`
  - delay large-scale `MVP*` symbol/file renames until the iOS shell settles

## 2026-07-01 iOS home/detail polish follow-up

Scoped to a second narrow iOS shell-polish pass only:

- `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSMVPTestView.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/MVPIOSHomeSupportViews.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/MVPIOSSubjectOverviewSupport.swift`
- no renderer, preview-internal typography/layout, export, share, or photo-library semantic changes

What landed:

- tightened visible iOS shell copy toward a more stable V1.0 tone:
  - `编辑配置` -> `配置中心`
  - quick-action and recent-processing labels softened toward product language
- refined the Subject primary card so it reads more like an entry object card:
  - explicit `当前记忆对象` eyebrow
  - relationship label as supporting text
  - anchor state moved into a lighter badge + fact treatment
- refined the current-configuration card:
  - status promoted into a semantic badge
  - supporting copy clarifies that the block controls the next default run
- refined Subject overview sheet footer:
  - `前往配置中心` remains, but now reads more like a downstream action with
    supporting explanation instead of a lone raw button

Verification:

- passed:
  - `git diff --check`
- attempted:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOSMVP -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PhotoMemoIOSMVPDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- current verification note:
  - one run failed due to an Xcode build-database lock on the derived-data path,
    not a compiler diagnostic from this polish slice
- follow-up verification in progress:
  - rerun on a fresh derived-data path:
    `/tmp/PhotoMemoIOSMVPDerivedData-ui-polish`

## 2026-07-01 iOS home role-separation polish

Scoped to a third narrow iOS shell-polish pass only:

- `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSMVPTestView.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/MVPIOSSubjectOverviewSupport.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/MVPIOSHomeCardPrimitives.swift`
- no renderer, preview-internal typography/layout, export, share, or photo-library semantic changes

What landed:

- tightened Home information ownership:
  - `当前记忆对象` now focuses on Subject only
  - `当前配置` now owns preset/default-run semantics more explicitly
- reduced the old “many small controls in one row” feel on the current
  configuration card:
  - direct reset action moved behind a more natural overflow menu
  - save action is now a clearer bottom action instead of competing inline
- added a neutral status-badge tone so non-applied/default states do not all
  read like warnings
- tightened Subject-sheet explanatory copy so it points to configuration
  adjustments without restating too much internal jargon

Verification:

- passed:
  - `git diff --check`
- in progress:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOSMVP -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PhotoMemoIOSMVPDerivedData-ui-polish-2 CODE_SIGNING_ALLOWED=NO -quiet build`

## 2026-07-01 iOS home support blocks extraction

Scoped to a bounded iOS Home-surface support patch only:

- `Source/PhotoMemo/PhotoMemo/iOS/Views/MVPIOSHomeSupportViews.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSMVPTestView.swift`
- `Tests/PhotoMemoTests/ArchitectureTests/MVPIOSHomeRecentProcessingPresenterTests.swift`
- no renderer, export, share, or photo-library semantic changes

What landed:

- extracted the Home-page support blocks out of the MVP view into a dedicated
  helper file for:
  - quick actions
  - recent processing summary
  - default output summary
- added a compact recent-processing presenter so Home can summarize:
  - current state
  - launch source
  - latest update time
  - optional shared-diagnostics recovery notice
- kept `PhotoMemoiOSMVPTestView` changes narrow:
  - adopted the new Home support helpers
  - removed the old inline quick-action/fact-chip helpers
  - added the missing selected-existing-album title projection used by the
    default output summary

Verification:

- passed:
  - `git diff --check`
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- attempted:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PhotoMemoIOSDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- current verification note:
  - the iOS build did not reach a compile verdict before the Xcode build
    operation was interrupted while package/build operations were still in
    flight
  - no direct compiler diagnostic from the new Home support files surfaced
    before interruption

## 2026-07-01 iOS compact editor entry-row patch

Scoped to a bounded iOS MVP editor-surface refresh only:

- `Source/PhotoMemo/PhotoMemo/iOS/Views/IOSCompactEntryRow.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSMVPTestView.swift`
- no renderer, preview-internal, export, share, or photo-library semantic changes

What landed:

- added reusable compact entry-row helpers for iOS:
  - `IOSCompactEntryListGroup`
  - `IOSCompactEntryDisclosureRow`
- adopted those helpers in `PhotoMemoiOSMVPTestView` so:
  - Slot A / B / C / D now read as compact grouped-list entry rows
  - `Logo 标识` and `时间锚点` use the same row language
  - the existing detailed controls remain inside the expanded disclosure area
- kept the patch UI-scoped:
  - no preview composition rewiring
  - no renderer/export/share/photo-library boundary changes

Verification:

- passed:
  - `git diff --check`
- attempted:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PhotoMemoIOSDerivedData CODE_SIGNING_ALLOWED=NO build`
- current blocker:
  - the iOS build is currently failing in pre-existing repository code under
    `Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Editors/MemorySubjectEditorView.swift`
  - failure signature points to `SwiftUIMacros.StateMacro` /
    `swift-plugin-server`, not to the compact entry-row patch

## 2026-07-01 macOS Subject area in-place promotion

Scoped to a minimal mac-front-end wording and information-architecture upgrade only:

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+LayoutSections.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+PersonalProfile.swift`
- no renderer, Memory Engine, export, share, or photo-library semantic changes
- no large navigation restructure yet

What landed:

- promoted the existing mac sidebar/profile entry from `我的记录` to
  `当前记忆对象`
- introduced a clearer `subjectSection` seam in `MainView` so the mac app now
  reads more like a real Subject surface than a personal-profile form hook
- upgraded the existing profile block into a more formal Subject overview:
  - overview summary card
  - `基本资料`
  - `时间锚点`
- surfaced current time-anchor state inside the same Subject area without
  moving renderer or editor ownership:
  - current anchor selection
  - anchor date summary
  - quick facts derived from the existing anchor preview result
  - direct entry to anchor management
- intentionally kept the existing editor-side anchor behavior intact so this is
  an in-place promotion, not a wider flow migration

Verification:

- passed macOS Debug build:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- passed `git diff --check`

Current assessment:

- macOS has its first small but real shift from `profile form` language toward
  `Memory Subject` language
- the next safe follow-up on this line is:
  - keep lifting Subject wording in the Home surface
  - decide whether Home should become a true `Subject overview` shell before
    touching Editor / Output navigation
  - only then continue moving remaining profile-era labels and shallow entry
    points

## 2026-07-01 MVP preview-sync + editor-draft bridge follow-up

Scoped to behavior-preserving internal migration only:

- `PhotoMemoiOSMVPTestView`
- new MVP helper/model/test seams only
- no UI behavior, renderer, export, share, or photo-library semantic changes

What landed:

- added `MVPPreviewSyncCoordinator`
  and routed the remaining preview sync glue in
  `PhotoMemoiOSMVPTestView` through it:
  - compose single-region preview text
  - sync a single region preview
  - sync all memory-region previews together
  - load preview text through coordinator/session fallback
- added `MVPEditorDraft`
  and `MVPContentItem`
  as standalone view-model types instead of keeping them private at the bottom of
  `PhotoMemoiOSMVPTestView`
- added `MVPDraftBridge`
  and moved out the repetitive draft/item/kind bridge between:
  - `MVPEditorDraft`
  - `MVPPreviewDraft`
  - `MVPDraftMutationDraft`
  - `MVPDraftMutationCoordinator.State`
- `PhotoMemoiOSMVPTestView` now no longer keeps local:
  - preview/mutation/editor draft conversions
  - preview/mutation/editor item conversions
  - kind-mapping glue
  - mutation-state projection back into local view state
- added `MVPDraftBootstrapCoordinator`
  and moved out the `bootstrapDrafts()` intent/fallback branch:
  - session template ID projection
  - preview-draft bootstrap intent call
  - fallback default editor-draft generation
- tightened `MVPDraftMutationCoordinator` tail-input normalization so the adopted
  helper stays aligned with the current tested editor behavior:
  - append text reuses the trailing empty text input slot
  - duplicate empty trailing text inputs collapse to one
  - removing a composed item still clears the now-unneeded trailing empty text

Tests added:

- `MVPPreviewSyncCoordinatorTests`
- `MVPDraftBridgeTests`
- `MVPDraftBootstrapCoordinatorTests`

Verification:

- passed focused macOS-hosted tests with `CODE_SIGNING_ALLOWED=NO`:
  - `MVPPreviewSyncCoordinatorTests`
  - `MVPDraftBridgeTests`
  - `MVPDraftBootstrapCoordinatorTests`
  - `MVPDraftMutationCoordinatorTests`
  - `MVPConfigurationBootstrapCoordinatorTests`
  - `MVPConfigurationBootstrapPresenterTests`
  - `MVPDiagnosticsRefreshCoordinatorTests`
  - `MVPModulePanelCoordinatorTests`
  - `MVPModuleLibraryPresenterTests`
  - `MVPPresetSelectionCoordinatorTests`
  - `PreviewMigrationTests`
  - `PreviewCompositionMigrationTests`
- passed macOS Debug build:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- passed `git diff --check`

Current assessment:

- `PhotoMemoiOSMVPTestView` has now shed another full class of local work:
  - preview refresh orchestration
  - draft bridge/projection glue
  - draft bootstrap fallback wiring
- the highest-value remaining MVP tail is now more clearly:
  - `bootstrapDrafts()` state/writeback seam
  - configuration/preset activation side-effect grouping
  - editor/card composition helpers that are still embedded in the view

## 2026-07-01 ConfigurationCenter detail/composer + MVP diagnostics/module/bootstrap follow-up

Scoped to behavior-preserving internal migration only:

- `ConfigurationCenteriOSView`
- `PhotoMemoiOSMVPTestView`
- new presenter/coordinator/test seams only
- no UI behavior, renderer, export, share, or photo-library semantic changes

What landed:

- added `ConfigurationCenterDetailPresenter`
  and moved out the remaining detail/panel routing projection from
  `ConfigurationCenteriOSView`:
  - selected panel -> detail surface kind
  - subject panel title/subtitle/icon projection
  - selected region -> region editor title/icon/content kind
  - preserved the existing card-panel quirk:
    - `.card` still renders as an unwrapped region editor surface
    - it still reads the actual region from session state
- added `ConfigurationCenterRegionComposerPresenter`
  and adopted it inside `IOSRegionComposer` for:
  - selected configuration title fallback
  - saved/unsaved status symbol and title
  - text / continuation placeholders
- added `MVPDiagnosticsRefreshCoordinator`
  and routed `PhotoMemoiOSMVPTestView` diagnostics/queue orchestration through it:
  - refresh processing state
  - repository failure fallback to local diagnostics snapshot
  - clear completed history while preserving current job ID
- removed one confirmed dead MVP state:
  - `selectedModule`
- added `MVPModulePanelCoordinator`
  and routed the remaining module-sheet glue through it:
  - editor focus dismisses the module panel
  - sheet presented-state dismissal
  - module usage persistence + dismiss order on selection
- added `MVPConfigurationBootstrapCoordinator`
  so `PhotoMemoiOSMVPTestView` no longer keeps the
  `configurationCoordinator -> fallback SettingsRepository` branch inline

Tests added:

- `ConfigurationCenterDetailPresenterTests`
- `ConfigurationCenterRegionComposerPresenterTests`
- `MVPDiagnosticsRefreshCoordinatorTests`
- `MVPModulePanelCoordinatorTests`
- `MVPConfigurationBootstrapCoordinatorTests`

Verification:

- passed focused macOS-hosted tests with `CODE_SIGNING_ALLOWED=NO`:
  - `ConfigurationCenterDetailPresenterTests`
  - `ConfigurationCenterRegionComposerPresenterTests`
  - `MVPConfigurationBootstrapCoordinatorTests`
  - `MVPConfigurationBootstrapPresenterTests`
  - `MVPDiagnosticsRefreshCoordinatorTests`
  - `MVPModulePanelCoordinatorTests`
  - `MVPModuleLibraryPresenterTests`
  - `MVPPresetSelectionCoordinatorTests`
  - `QueueStatusMigrationTests`
- passed macOS Debug build:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- passed `git diff --check`

Current assessment:

- `ConfigurationCenteriOSView` now has most of its remaining view-owned logic
  concentrated in:
  - some card/sidebar composition layout
  - `IOSRegionComposer` local interaction state
- `PhotoMemoiOSMVPTestView` has shed another three orchestration pockets:
  - diagnostics refresh
  - module panel state
  - bootstrap loading
- the highest-value remaining MVP tail is now more clearly:
  - draft state bridge/apply extraction
  - preview refresh/bootstrap coordination
  - compact preview / editor composition helpers that are still local to the view

## 2026-07-01 ConfigurationCenter binding-adapter + MVP preset-routing follow-up

Scoped to behavior-preserving internal migration only:

- `ConfigurationCenteriOSView`
- `PhotoMemoiOSMVPTestView`
- new presenter/coordinator/helper tests only
- no UI behavior, renderer, export, share, or photo-library semantic changes

What landed:

- added `ConfigurationCenterSessionBindingPresenter`
  and adopted it for the remaining direct session-backed bindings in
  `ConfigurationCenteriOSView`:
  - profile title rename binding
  - storage option binding
  - memory-write toggle binding
  - memory-write text binding
- added `ConfigurationCenterRegionBindingAdapter`
  and adopted it for the remaining region binding/mutation layer in
  `ConfigurationCenteriOSView`
  so the view no longer hand-codes the distinction between:
  - store-only mutations
  - store + preview recomposition mutations
  - guarded insert-module no-ops for non-memory-card regions
- calibrated two Configuration Center regression tests to the current real
  behavior already present in code:
  - preview composition does not auto-insert a space between text and a token
  - slotC region configuration IDs are `context.configuration*`
- added `MVPPresetSelectionCoordinator`
  and adopted it in `PhotoMemoiOSMVPTestView.selectedPresetBinding`
  so the view no longer keeps the preset-selection guard/lookup/activation
  payload branching inline

Tests added:

- `ConfigurationCenterSessionBindingPresenterTests`
- `ConfigurationCenterRegionBindingAdapterTests`
- `MVPPresetSelectionCoordinatorTests`

Verification:

- passed focused macOS-hosted ConfigurationCenter suite:
  - `ConfigurationCenterSessionBindingPresenterTests`
  - `ConfigurationCenterRegionBindingAdapterTests`
  - `ConfigurationCenterRegionEditCoordinatorTests`
  - `ConfigurationCenterRegionDraftStoreTests`
  - `ConfigurationCenterPreviewCompositionHelperTests`
  - `ConfigurationCenterSelectionCoordinatorTests`
  - `ConfigurationCenterInsertableModulePolicyTests`
  - `ConfigurationCenterCompactPreviewPresenterTests`
  - `ConfigurationCenterPresetSelectionPresenterTests`
- passed focused:
  - `MVPPresetSelectionCoordinatorTests`
- passed macOS Debug build:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- passed `git diff --check`

Current assessment:

- `ConfigurationCenteriOSView` has now shed most of its remaining binding glue;
  the highest-value tail is now more clearly:
  - selection appliers
  - detail/panel routing projection
  - `IOSRegionComposer` local projection/focus behavior
- `PhotoMemoiOSMVPTestView` has one more view-owned branch type (`Preset`
  selection routing) extracted behind a dedicated coordinator
- the next best safe MVP slices remain:
  - draft bridge/apply adapter
  - diagnostics refresh coordinator
  - module panel + usage persistence adapter

## 2026-07-01 MVP draft-adoption + ConfigurationCenter edit-coordinator follow-up

Scoped to behavior-preserving internal migration only:

- `PhotoMemoiOSMVPTestView`
- `MVPDraftMutationCoordinator`
- `ConfigurationCenteriOSView`
- new helper/test seams only
- no renderer / export / share semantic changes

What landed:

- `PhotoMemoiOSMVPTestView` now routes its draft fallback and the main local
  draft-mutation paths through `MVPDraftMutationCoordinator`:
  - `draft(for:)`
  - text-item updates
  - prepend / append
  - remove
  - module insert
- the helper now preserves token display metadata during mutation bridging:
  - `title`
  - `systemImage`
- added `ConfigurationCenterRegionEditCoordinator` to own the repetitive
  `store write -> preview recompute -> session preview sync` flow for:
  - region text
  - inserted modules
  - continuation text
  - selected region configuration
  - insert/remove module actions
  - explicit preview refresh
- added `ConfigurationCenterInsertableModulePolicy` to move region-based module
  visibility policy out of `ConfigurationCenteriOSView`

Tests added or strengthened:

- `MVPDraftMutationCoordinatorTests`
  now also locks token metadata preservation during insert
- added
  `ConfigurationCenterRegionEditCoordinatorTests`
- added
  `ConfigurationCenterInsertableModulePolicyTests`

Verification:

- passed focused test run:
  - `MVPDraftMutationCoordinatorTests`
- passed focused architecture run:
  - `MVPDraftMutationCoordinatorTests`
  - `ConfigurationCenterPreviewCompositionHelperTests`
  - `ConfigurationCenterRegionDraftStoreTests`
  - `ConfigurationCenterRegionEditCoordinatorTests`
  - `ConfigurationMigrationTests`
- passed focused Configuration helper run:
  - `ConfigurationCenterInsertableModulePolicyTests`
  - `ConfigurationCenterRegionEditCoordinatorTests`
  - `ConfigurationCenterPreviewCompositionHelperTests`
  - `ConfigurationCenterRegionDraftStoreTests`
- passed `git diff --check`

Current assessment:

- `PhotoMemoiOSMVPTestView` has one more real local state pocket moved behind a
  tested helper without changing its preview/export coordination boundary
- `ConfigurationCenteriOSView` now delegates both draft-store state and
  preview-write choreography to dedicated helpers, which makes the remaining
  tail more clearly about selection routing and session bindings than hidden
  local state mutation

## 2026-07-01 ConfigurationCenter selection/preset/compact-preview follow-up

Scoped to behavior-preserving View-thinning only:

- `ConfigurationCenteriOSView`
- new pure helper/presenter seams
- focused architecture tests only

What landed:

- added `ConfigurationCenterSelectionCoordinator`
  and adopted it for:
  - sidebar card routes
  - sidebar subject routes
  - sidebar panel-only routes
  - region strip routes
  - compact preview tap routing
- preview taps explicitly keep the existing asymmetry:
  - they update `selectedRegion`
  - they do not switch `selectedPanel`
- added `IOSConfigurationPanel.swift`
  so the selection seam compiles cleanly in macOS-hosted architecture tests
- added `ConfigurationCenterCompactPreviewPresenter`
  and moved out:
  - capture-summary fact truncation
  - badge symbol fallback/projection
- added `ConfigurationCenterPresetSelectionPresenter`
  and moved out:
  - selected preset fallback resolution
  - preset lookup by ID
  - preset selected-state projection

Tests added or expanded:

- `ConfigurationCenterSelectionCoordinatorTests`
- `ConfigurationCenterCompactPreviewPresenterTests`
- `ConfigurationCenterPresetSelectionPresenterTests`
- `ConfigurationCenterRegionDraftStoreTests`
  now also covers:
  - region selection changes not leaking draft/continuation state
  - rename state following configuration ID

Verification:

- passed focused selection/helper suite:
  - `ConfigurationCenterSelectionCoordinatorTests`
  - `ConfigurationCenterRegionEditCoordinatorTests`
  - `ConfigurationCenterInsertableModulePolicyTests`
  - `ConfigurationCenterRegionDraftStoreTests`
- passed focused presenter/helper suite:
  - `ConfigurationCenterSelectionCoordinatorTests`
  - `ConfigurationCenterCompactPreviewPresenterTests`
  - `ConfigurationCenterPresetSelectionPresenterTests`
  - `ConfigurationCenterInsertableModulePolicyTests`
  - `ConfigurationCenterRegionEditCoordinatorTests`
  - `ConfigurationCenterPreviewCompositionHelperTests`
  - `ConfigurationCenterRegionDraftStoreTests`
- passed `git diff --check`

Current assessment:

- `ConfigurationCenteriOSView` is now materially less of a mixed
  navigation/state/composition controller
- the most obvious remaining non-UI tail is now concentrated in:
  - session binding adapters
  - some panel/detail switching glue
  - `IOSRegionComposer` local projection/focus behavior

## 2026-06-30 ConfigurationCenter preview-composition helper/test seam

Scoped to behavior-preserving helper/test additions only:

- `ConfigurationCenteriOSView` preview-composition local logic
- new pure helper/test files only
- no `ConfigurationCenteriOSView.swift` edit in this slice

What landed:

- added
  `Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenterPreviewCompositionHelper.swift`
  as a local-only seam for the current iOS Configuration Center preview logic
- the helper mirrors the view-owned behavior for:
  - `insertModuleIntoCurrentRegion`
  - `removeInsertedModule`
  - `refreshRegionPreview` text composition
  - `moduleValue(...)`
  - smart-time result projection
- the helper intentionally stays local to Configuration Center and does not
  reuse `MVPPreviewCompositionEngine`
- added focused regression coverage in:
  `Tests/PhotoMemoTests/ArchitectureTests/ConfigurationCenterPreviewCompositionHelperTests.swift`
  covering:
  - insert seeding default region text
  - removal recomposition
  - trimming/composition behavior
  - smart-time and token-value projection

Verification:

- passed `PhotoMemo` macOS Debug build:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- attempted focused `PhotoMemoTests` run for:
  - `ConfigurationCenterPreviewCompositionHelperTests`
  - `ConfigurationCenterRegionDraftStoreTests`
- the test scheme is currently blocked by an unrelated pre-existing compile
  failure in
  `Tests/PhotoMemoTests/ArchitectureTests/ConfigurationCenterRegionPreviewComposerTests.swift`
  where `MemorySubject(...)` argument order is invalid

Current assessment:

- the seam is ready for main-thread adoption without changing renderer/export
  or photo-library behavior
- the remaining step is view integration from `ConfigurationCenteriOSView.swift`
  once it is safe to touch that file in the active branch

## 2026-06-30 MVP draft-mutation helper/test seam

Scoped to behavior-preserving helper/test additions only:

- `PhotoMemoiOSMVPTestView` local draft/focus semantics
- new pure helper file only
- focused architecture tests only

What landed:

- added `MVPDraftMutationCoordinator` as a pure, non-adopted seam for the MVP
  editor-local state machine:
  - `draft(for:)`
  - `updateDraft(for:transform:)`
  - `insert(_:into:)`
  - active text-item routing
  - dirty-state message triggering
- the helper mirrors the current view semantics rather than redesigning them:
  - prepend/append ignore all-whitespace input
  - insert prefers the active text-item anchor when present
  - inserting at an active empty trailing text item places the new module before
    that trailing slot
  - trailing normalization removes duplicate empty trailing text items and
    restores one empty trailing text item after a non-text item when needed
- added focused Swift Testing coverage in:
  - `MVPDraftMutationCoordinatorTests`
  - covered:
    - default-draft fallback
    - prepend
    - append
    - remove
    - insert-after-active-item
    - insertion at active empty trailing text
    - trailing-text normalization

Verification:

- pending in this note until the new focused tests + build finish

Current assessment:

- this lands the missing testable contract for one of the last high-value
  `PhotoMemoiOSMVPTestView` local responsibilities without touching the active
  view file
- the next safe step would be opt-in adoption by the view once the seam proves
  stable under focused regression tests

## 2026-06-30 Shared-defaults typed read seam follow-up

Scoped only to additive typed diagnostics/read seams around shared-defaults and
bootstrap reads:

- `SharedBatchConfigurationSnapshotService`
- `SettingsService`
- `SettingsRepository`
- direct batch/settings tests only

What landed:

- `SharedBatchConfigurationSnapshotService` now forwards the existing typed
  shared-defaults read APIs already owned by
  `BatchConfigurationSnapshotProvider`:
  - `loadAnchorsResult()`
  - `loadTemplateResult()`
  - `loadBadgeResult()`
- `SettingsService` now exposes a typed bootstrap read adapter:
  - `loadMVPBootstrapReadState()`
  - this returns the typed badge-read result together with the fresh
    read-side editor-state values needed for MVP bootstrap
- `SettingsRepository.loadMVPConfigurationBootstrapState()` now projects
  bootstrap state from that typed read adapter instead of depending on a
  mutating `selectedBadge` refresh as its source
- old convenience behavior remains unchanged:
  - tolerant snapshot loading still falls back the same way
  - MVP bootstrap still treats missing/corrupted badge payloads as
    non-custom-logo state rather than surfacing a new user-visible failure

Verification:

- passed `git diff --check`
- added direct tests for:
  - `SharedBatchConfigurationSnapshotServiceTests`
  - `SettingsServiceTests` typed bootstrap read coverage
- focused Xcode verification was run for the new seams plus the existing
  bootstrap migration coverage
- macOS Debug build was rerun for compile safety

Current assessment:

- typed shared-defaults diagnostics are now available one layer higher without
  forcing current callers to migrate
- bootstrap read behavior is now easier to integrate into future main-thread
  or repository-level diagnostics because the read-side seam no longer depends
  on published state mutation as its only source

## 2026-06-30 ConfigurationCenter/MVP state-projection follow-up

Scoped to behavior-preserving local-state cleanup only:

- `ConfigurationCenteriOSView`
- `PhotoMemoiOSMVPTestView`
- `BatchConfigurationSnapshotProvider`
- focused architecture/batch tests only

What landed:

- `ConfigurationCenteriOSView` no longer owns its full region draft/config
  state bag directly:
  - added `ConfigurationCenterRegionDraftStore`
  - moved region configuration selection, draft text, inserted modules,
    continuation text, rename state, save markers, and option/title projection
    into the new store
  - the view now keeps the same binding surface and preview refresh triggers,
    but the underlying local state machine is centralized
- `PhotoMemoiOSMVPTestView` no longer keeps the bootstrap-to-local-UI mapping
  inline:
  - added `MVPConfigurationBootstrapPresenter`
  - `applyBootstrapState(_:)` now projects typed bootstrap state through the
    presenter before assigning local UI state
  - view-only status copy remains local (`"已使用自选 Logo。"`), so no product
    semantics were broadened
- additive typed diagnostics landed for shared defaults bootstrap reads:
  - `BatchConfigurationSnapshotProvider` now exposes:
    - `loadAnchorsResult()`
    - `loadTemplateResult()`
    - `loadBadgeResult()`
  - old tolerant snapshot behavior remains unchanged while callers can now
    distinguish missing values from decoding corruption
- the focused module-usage migration tests now compile on the macOS-hosted
  `PhotoMemoTests` target because the Foundation-only helper files were widened
  from `os(iOS)` to all non-share-extension targets:
  - `PhotoMemoiOSModuleCatalog.swift`
  - `MVPModuleUsageTracker.swift`

Verification:

- passed `git diff --check`
- passed focused macOS-hosted `PhotoMemoTests` selection for:
  - `ModuleUsageMigrationTests`
  - `ConfigurationCenterRegionDraftStoreTests`
  - `MVPConfigurationBootstrapPresenterTests`
  - `ConfigurationMigrationTests`
- passed `PhotoMemo` macOS Debug build
- passed `PhotoMemoiOSMVP` generic iOS Debug build

Current assessment:

- `ConfigurationCenteriOSView` has one of its highest-value mixed-responsibility
  slices centralized without changing preview/output behavior
- `PhotoMemoiOSMVPTestView` now has a dedicated seam for bootstrap UI-state
  projection, which reduces the remaining “state assignment” logic still living
  in the view
- next safest cleanup order remains:
  1. `ConfigurationCenter` preview composition / module-resolution extraction
  2. `PhotoMemoiOSMVPTestView` draft mutation / focus-routing helper
  3. additional fallback/integration regression coverage across the new seams

## 2026-06-30 ModuleUsage migration test compile-boundary fix

Scoped only to module-usage helper visibility and the focused migration test
compile path:

- no product-behavior change
- no `ConfigurationCenteriOSView` change
- no `PhotoMemoiOSMVPTestView` change

What landed:

- widened the compile guard on the Foundation-only module-usage helper types so
  the macOS-hosted `PhotoMemoTests` target can see them:
  - `iOS/Views/PhotoMemoiOSModuleCatalog.swift`
  - `iOS/Views/MVPModuleUsageTracker.swift`
- both files now compile for all non-share-extension targets instead of only
  `os(iOS)`, which preserves share-extension exclusion while making the
  migration tests able to reference:
  - `IOSInsertableModule`
  - `MVPModuleUsageTracker`

Verification:

- passed focused macOS-hosted test run:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoTests -only-testing:PhotoMemoTests/ModuleUsageMigrationTests -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO test`

Current assessment:

- the compile failure was a target-visibility boundary, not a behavior bug
- runtime module ordering / recording logic remains unchanged
- no broader architecture or UI files were modified for this fix

## 2026-06-30 V1 Architecture Migration Phase 2F

Scoped to behavior-preserving cleanup only:

- `PhotoMemoiOSMVPTestView`
- `MVPPreviewCompositionEngine`
- `PhotoMemoiOSQueueDiagnosticsProjectionEngine`
- `SettingsRepository` / `SettingsService`
- focused migration tests only

What landed:

- `PhotoMemoiOSMVPTestView` now adopts the previously-extracted seams instead of
  keeping the remaining preview/queue composition logic inline:
  - share/queue header mapping now reads through
    `PhotoMemoiOSQueueDiagnosticsProjectionEngine.headerProjection(...)`
  - progress/pipeline/queue-line display now reads through
    `PhotoMemoiOSQueueDiagnosticsProjectionEngine.progressProjection(...)`
  - diagnostic event display now reads through
    `PhotoMemoiOSQueueDiagnosticsProjectionEngine.eventDisplayProjections(...)`
  - processing-diagnostics snapshot load now goes through
    `LoadQueueProcessingDiagnosticsSnapshotIntent`
- preview composition responsibilities are no longer primarily implemented
  inside the view:
  - `composedText(for:)` now goes through
    `ComposeMVPPreviewTextIntent`
  - token display resolution now goes through
    `ResolveMVPPreviewDisplayValueIntent`
  - default draft bootstrap now goes through
    `BootstrapMVPPreviewDraftsIntent`
  - `PhotoMemoiOSMVPTestView` keeps only thin draft/item bridging for its local
    editor state
- configuration bootstrap readback is now more consistent with the old view
  behavior:
  - `bootstrapSavedSettings()` applies one typed
    `MVPConfigurationBootstrapState`
    for both coordinator-backed and compatibility fallback paths
  - `SettingsService` now exposes `reloadMVPBootstrapState()`
  - `SettingsRepository.loadMVPConfigurationBootstrapState()` refreshes badge +
    editor-state fields from defaults before projecting bootstrap state
  - this fixes the stale automatic/system-library bootstrap mismatch that the
    new repository seam introduced compared with the old fresh-read view path
- test calibration was corrected to match the actual historical MVP preview
  wording already present in the old view implementation:
  - preview draft composition intentionally keeps
    `记录于2026.05.24 14:33:00`
    and
    `途途当天11个月28天`
    without extra inserted spaces

Verification:

- passed `git diff --check`
- passed `PhotoMemo` macOS Debug build
- passed `PhotoMemoiOSMVP` generic iOS Debug build
- passed focused `PhotoMemoTests` selection for:
  - `PreviewCompositionMigrationTests`
  - `QueueStatusProjectionEngineTests`
  - `QueueStatusMigrationTests`
  - `ExportAlbumPresenterTests`
  - `ConfigurationMigrationTests`

Current assessment:

- `PhotoMemoiOSMVPTestView` no longer owns the main queue/share diagnostics
  translation logic
- `PhotoMemoiOSMVPTestView` no longer owns the main default-preview bootstrap /
  token-display / preview-text composition logic
- configuration bootstrap readback is now type-directed on both the new seam and
  the compatibility fallback path
- remaining view-owned responsibilities are now mostly local editor/UI concerns:
  - draft mutation and cursor/selection routing
  - module-usage persistence
  - logo optimization flow
  - final state assignment after bootstrap/save/export intents return

## 2026-06-30 Diagnostics/Persistence Silent-Failure Cleanup

Scoped only to:

- `Source/PhotoMemo/PhotoMemo/App/SharedBatchQueueSnapshotService.swift`
- `Source/PhotoMemo/PhotoMemo/App/PhotoMemoShareDiagnostics.swift`
- `Source/PhotoMemo/PhotoMemo/App/ExternalPhotoIntakeStore.swift`
- direct `Tests/PhotoMemoTests/BatchTests/*` coverage for those paths

What landed:

- `SharedBatchQueueSnapshotService` now exposes a specific-job
  `loadSnapshotResult(for:)` helper so internal callers can distinguish:
  - no shared payload
  - corrupted shared payload
  - requested job missing
  - successful snapshot load
- `PhotoMemoShareDiagnostics` now exposes `resetResult(...)` so reset/write
  failures can be observed in the same typed way as `recordResult(...)`
- `ExternalPhotoIntakeStore` now exposes:
  - `ExternalPhotoIntakeDrainResult`
  - `drainRequestsResult(...)`
  - `saveRequestsResult(...)`
- existing convenience APIs remain unchanged:
  - `loadSnapshot(for:)`
  - `reset(reason:)`
  - `drainRequests()`

Verification:

- passed `PhotoMemo` macOS Debug build
- reran focused `PhotoMemoTests` selection for:
  - `SharedBatchQueueSnapshotServiceTests`
  - `PhotoMemoShareDiagnosticsTests`
  - `ExternalPhotoIntakeStoreDiagnosticsTests`
- current blocker remains unrelated `ArchitectureTests` compile failures
  outside this slice, including missing MVP preview / queue migration symbols
- the rerun confirmed the new owned-file diagnostics APIs compile past their
  prior missing-method failures before the unrelated test-target breakage stops
  the full scheme

## 2026-06-30 V1 Architecture Migration Phase 2E

Export branching follow-up slice for `PhotoMemoiOSMVPTestView`:

- no UI redesign
- no renderer/output-image change
- no Share semantic change
- scoped only to output-target branching extraction

What landed:

- extended `Intent/ExportAlbumIntents.swift` with:
  - `MVPIOSOutputTarget`
  - `MVPResolvedAlbumSelection`
  - `MVPOutputAlbumSelectionRequest`
  - `ResolveMVPOutputAlbumSelectionIntent`
- updated `PhotoMemoiOSMVPTestView.resolvedOutputAlbumSelection()` so
  output-target branching now flows through the new export intent instead of
  keeping the full decision tree in the view
- the view now only keeps local UI-state follow-up for `.newAlbum`:
  - reload album options
  - sync `selectedExistingAlbumIdentifier`
- added focused regression coverage for:
  - existing-album resolution
  - automatic fallback when an existing-album selection is missing
  - new-album ensure behavior through `ExportCoordinator`

Verification:

- passed `PhotoMemoTests/ConfigurationMigrationTests`
- passed `PhotoMemoTests/ExportMigrationTests`
- passed `PhotoMemo` macOS Debug build
- passed `PhotoMemoiOSMVP` generic iOS Debug build
- passed `git diff --check`

Current assessment:

- export output-target branching is no longer owned entirely by the view
- album-picker loading/error projection still remains in the view
- direct `PhotoLibraryExportService()` fallback remains preserved inside the new
  intent for compatibility

## 2026-06-30 V1 Architecture Migration Phase 2D

Configuration-only adoption slice for `PhotoMemoiOSMVPTestView`:

- no UI redesign
- no renderer/output-image change
- no Share / Export / Photo Library semantic change
- scoped only to configuration-save persistence

What landed:

- added `Intent/ConfigurationSaveIntents.swift` with:
  - `MVPConfigurationSaveRequest`
  - `MVPConfigurationSaveReceipt`
  - `SaveMVPConfigurationIntent`
- extended `ConfigurationCoordinator` with:
  - `saveMVPConfiguration(...)`
- extended `SettingsRepository` with thin save helpers for:
  - template
  - badge
  - photo-description settings
  - editor state
- extended `ConfigurationRepository` with:
  - `upsertBirthdayAnchor(...)`
- updated `PhotoMemoiOSMVPTestView.applyCurrentMVPConfiguration()` so the
  persistence path now flows through:
  `SaveMVPConfigurationIntent -> ConfigurationCoordinator`
- updated `PhotoMemoiOSTemporaryEntryView` and the `#Preview` wiring so the MVP
  view now receives `ConfigurationCoordinator` through `AppEnvironment`

Verification:

- passed `PhotoMemoTests/ConfigurationMigrationTests`
- passed `PhotoMemo` macOS Debug build
- passed `PhotoMemoiOSMVP` generic iOS Debug build
- passed `git diff --check`

Current assessment:

- the largest configuration-save side effects have been removed from the view
- `session.applySelectedMemoryPreset()` intentionally remains in the view as
  local session-state synchronization
- preview / queue diagnostics mapping / album loading UI state are still pending

## 2026-06-30 V1 Architecture Migration Phase 2C

Export-only adoption slice for `PhotoMemoiOSMVPTestView`:

- no UI redesign
- no renderer/output-image change
- no Share semantic change
- scoped only to export-album capability access

What landed:

- added `LoadExportAlbumOptionsIntent`
- added `EnsureExportAlbumIntent`
- introduced `PhotoLibraryExporting` so export-album repository tests can use a
  stubbed photo-library service without touching platform Photos behavior
- extended `PhotoLibraryRepository` with:
  - `fetchAlbumOptions()`
  - `ensureAlbum(named:)`
- extended `ExportCoordinator` with:
  - `fetchAlbumOptions()`
  - `ensureAlbum(named:)`
- updated `PhotoMemoiOSMVPTestView` so export-related album operations now flow
  through injected architecture seams instead of directly constructing
  `PhotoLibraryExportService`:
  - loading album options
  - ensuring a new destination album
- updated `PhotoMemoiOSTemporaryEntryView` to pass the existing
  `AppEnvironment` export coordinator into the MVP view

Verification:

- passed `PhotoMemoTests/ExportMigrationTests`
- passed `PhotoMemoTests/PreviewMigrationTests`
- passed `PhotoMemoTests/QueueStatusMigrationTests`
- passed `PhotoMemoTests/ArchitectureMigrationFoundationTests`
- passed `PhotoMemo` macOS Debug build
- passed `PhotoMemoiOSMVP` generic iOS Debug build
- passed `git diff --check`

Current assessment:

- `PhotoMemoiOSMVPTestView` no longer directly constructs
  `PhotoLibraryExportService` for output-album operations
- output-target branching still remains inside the view, so this is an
  export-capability migration, not a full export-flow extraction
- settings-save and time-anchor persistence logic remain intentionally untouched

## 2026-06-30 V1 Architecture Migration Phase 2B

Preview-only adoption slice for `PhotoMemoiOSMVPTestView`:

- no UI redesign
- no renderer/output change
- no Share / Export / Photo Library semantic change
- scoped only to preview-session read/write responsibilities

What landed:

- added `UpdateRegionPreviewIntent`
- added `UpdateRegionPreviewsIntent`
- added `LoadRegionPreviewTextIntent`
- extended `PreviewCoordinator` with:
  - single-region preview sync
  - multi-region preview sync
  - region preview text load
- updated `PhotoMemoiOSMVPTestView` so preview-related session operations now
  flow through injected architecture seams instead of direct session mutation:
  - single-region preview refresh
  - dynamic preview refresh across all memory-card regions
  - preview text reads for the preview card
- updated `PhotoMemoiOSTemporaryEntryView` to pass the existing
  `AppEnvironment` preview coordinator into the MVP view

Verification:

- passed `PhotoMemoTests/PreviewMigrationTests`
- passed `PhotoMemoTests/QueueStatusMigrationTests`
- passed `PhotoMemoTests/ArchitectureMigrationFoundationTests`
- passed `PhotoMemo` macOS Debug build
- passed `PhotoMemoiOSMVP` generic iOS Debug build
- passed `git diff --check`

Current assessment:

- `PhotoMemoiOSMVPTestView` no longer directly owns preview-session read/write
  routing
- draft-to-text composition still remains inside the view, so this is a preview
  migration slice, not a full preview-editor decomposition
- Queue migration from the previous slice remains intact and unchanged

## 2026-06-30 V1 Architecture Migration Phase 2A

Queue-only adoption slice for `PhotoMemoiOSMVPTestView`:

- no UI redesign
- no renderer/output change
- no Share / Export / Photo Library semantic change
- scoped only to queue-status and queue-history responsibilities

What landed:

- added `RefreshQueueProcessingStatusIntent`
- added `ClearCompletedQueueHistoryIntent`
- extended `QueueRepository` / `QueueCoordinator` with
  completed-history cleanup support
- extended `DiagnosticsRepository` with
  `loadProcessingDiagnosticsSnapshot()`
- updated `PhotoMemoiOSMVPTestView` so queue-related actions now flow through
  injected architecture seams instead of directly coordinating:
  - processing-status refresh now uses
    `RefreshQueueProcessingStatusIntent -> DiagnosticsRepository`
  - completed-history cleanup now uses
    `ClearCompletedQueueHistoryIntent -> QueueCoordinator`
- updated `PhotoMemoRootSceneView` and `PhotoMemoiOSTemporaryEntryView` to pass
  the existing `AppEnvironment` queue/diagnostics dependencies into the MVP
  view without changing visible behavior

Verification:

- passed `PhotoMemoTests/QueueStatusMigrationTests`
- passed `PhotoMemoTests/ArchitectureMigrationFoundationTests`
- passed `PhotoMemo` macOS Debug build
- passed `PhotoMemoiOSMVP` generic iOS Debug build
- passed `git diff --check`

Current assessment:

- `PhotoMemoiOSMVPTestView` no longer directly owns queue refresh orchestration
  or queue-history cleanup
- live queue display still remains in the view via
  `PhotoMemoBackgroundStatusService`, so this is a partial queue migration, not
  a full queue-view-model extraction
- Preview / Export / Preset / Logo / Album responsibilities were intentionally
  left untouched in this slice

## 2026-06-30 V1 Architecture Migration Phase 2

Behavior-preserving share-workflow adoption slice for PhotoMemo V1 / MVP:

- no UI behavior change
- no renderer/output change
- no Share / Export / Photo Library semantic change
- no old interface deletion

What landed:

- added `ProcessShareIntent`, `ImportBatchPhotoIntent`, and
  `ProcessedShareRequest`
- added `PhotoLibraryRepository`
- updated `ShareCoordinator` so drained share requests now flow through:
  - validation
  - in-drain de-duplication
  - managed-temp cleanup
  - intake-summary adjustment
  - queue-title derivation
  - `QueueRepository.enqueue(...)`
- updated `PhotoMemoAppRuntime.flushExternalRequests()` so it now routes through
  `ProcessShareIntent -> ShareCoordinator -> QueueRepository` instead of
  reaching directly into `BatchQueueStore.enqueue(...)`
- updated `BatchQueueExecution.processTask(...)` so the existing queue phase
  state machine now executes its business steps through the new intent path:
  - `ImportBatchPhotoIntent`
  - `BuildPreviewIntent`
  - `ExportRecordCardIntent`
  - `SaveRenderedPhotoIntent`
- updated `ExportCoordinator` so photo-library save-back now goes through
  `PhotoLibraryRepository`
- updated `AppEnvironment` and `BatchQueueStore` wiring so the new repository /
  coordinator seams are injected without removing legacy facades

Verification:

- passed `PhotoMemoTests/ShareDrainMigrationRegressionTests`
- passed `PhotoMemoTests/ArchitectureMigrationFoundationTests`
- passed `PhotoMemoTests/BatchFixtureCoverageTests`
- passed `PhotoMemo` macOS Debug build
- passed `PhotoMemoiOSMVP` generic iOS Debug build

Not fully reconfirmed in this slice:

- `PhotoMemoShareExtension` generic iOS Debug build

Reason:

- one rerun hit a derived-data `build.db` lock during overlapping build work
- one later `-quiet` rerun did not yield a clean completion signal before the
  session moved on, so it should be treated as pending verification rather than
  assumed green

Current assessment:

- app-side share drain adoption is complete
- queued processing adoption is complete inside the existing
  `BatchQueueExecution` compatibility shell
- old queue/runtime/share entry points are still preserved
- Phase 2 is now a real vertical migration slice rather than only foundation

## 2026-06-30 V1 Architecture Migration Phase 1

Behavior-preserving architecture-foundation slice for PhotoMemo V1 / MVP:

- no UI behavior change
- no renderer/output change
- no Share / Export / Photo Library semantic change

What landed:

- added `PhotoMemoResult`, `PhotoMemoError`, and `PhotoMemoErrorCode`
- added base async `PhotoMemoIntent` protocol
- added thin intents for preview, export, configuration loading, queue enqueue,
  and share submission
- added `ShareCoordinator`, `QueueCoordinator`, `PreviewCoordinator`,
  `ExportCoordinator`, and `ConfigurationCoordinator`
- added `SettingsRepository`, `QueueRepository`, `DiagnosticsRepository`,
  `PhotoRepository`, and `ConfigurationRepository`
- added `AppEnvironment` as the app-side dependency container
- updated `PhotoMemoAppRuntime`, `ExternalPhotoIntakeCenter`, and
  `BatchProcessingCoordinator` to support explicit dependency injection
- tightened share-extension compile guards so app-only intent/coordinator types
  do not leak into the extension target

Verification:

- passed `PhotoMemo` macOS Debug build
- passed `PhotoMemoiOSMVP` generic iOS Debug build
- passed focused `PhotoMemoTests/ArchitectureMigrationFoundationTests`

Known baseline blockers re-confirmed after this migration:

- `RecordCardBuildServiceTests.buildsTemplate1WithProfileRelationshipAndBabyAgePhrasing`
  still expects `拍摄于...`, but current output remains `记录于...`
- `ClassicWhiteSnapshotTests.landscapeStandardSnapshotStaysStable`
  still reports a mismatch of `93 / 768000` pixels with `maxChannelDelta = 212`

Current assessment:

- Phase 1 infrastructure is complete as an additive migration layer
- broad adoption of `View -> Intent -> Coordinator -> Repository` is not yet
  finished and should happen in later vertical slices
- the two failing tests above are treated as existing baseline issues, not as
  regressions introduced by this migration

Reference:

- `Docs/ArchitectureMigrationReport.md`

## 2026-06-30 Additional Hot-Path Performance Follow-Up

Fourth same-day performance slice, still strictly behavior-preserving:

- no UI redesign
- no renderer/export logic rewrite
- no intended output-behavior change

What changed:

- `BatchQueueExecution` no longer awaits the four stage-by-stage progress
  notification calls on the successful processing path:
  - RAW prepared
  - metadata imported
  - rendering started
  - photo-library save started
- This is safe because `BatchQueueNotifications.deliverProgressNotificationIfNeeded`
  is currently a deliberate no-op; removing those awaits only cuts async hops and
  repeated job lookups from the queue hot path.
- `BatchQueueHistory.trimTerminalJobHistoryIfNeeded(...)` now exits immediately
  when the total job count is already within the retained-history limit, avoiding
  an unnecessary full scan before every persisted queue write.
- `PhotoMetadataReader` now supports reading directly from `Data`.
- `PhotoImportService.importPhoto(from data: ...)` now creates one data-backed
  `CGImageSource` after writing the temporary file and reuses it for:
  - metadata property extraction
  - display-image generation
- This removes the immediate "write temp file, then reopen the same bytes from
  disk again" step from data/share-style imports.
- `TemplateVariableEngine.render(...)` now returns immediately for plain-text
  templates that do not contain `{{`, skipping token-scan work on the common
  no-placeholder path.

Measured structural effect:

- successful queue processing no longer pays for four no-op progress
  notification awaits per photo
- queue persistence no longer scans terminal history when total jobs are already
  `<= 120`
- data imports now reuse one in-memory image source instead of reparsing the
  just-written temporary file from disk
- plain-text template rendering now bypasses placeholder scanning entirely

Preserved:

- No queue state format, recovery semantics, notification content, renderer,
  export, share, or photo-library behavior was changed.
- RAW file-path fallback order remains unchanged.
- Metadata parsing rules remain unchanged.
- Output imagery and user-visible workflow remain unchanged.

Verification:

- passed focused `PhotoMemoTests/BatchQueueHistoryTests`
- passed focused `PhotoMemoTests/BatchQueueStorePersistenceTests`
- passed focused `PhotoMemoTests/BatchQueueRecoveryTests`
- passed focused `PhotoMemoTests/TemplateVariableEngineTests`
- passed focused `PhotoMemoTests/RecordCardBuildServiceTests`
- passed focused `PhotoMemoTests/PhotoMetadataReaderTests`
- passed focused `PhotoMemoTests/PhotoImportServiceTests`
- passed `git diff --check`
- passed `PhotoMemo` macOS Debug build
- passed `PhotoMemoiOSMVP` generic iOS Debug build
- manual device verification was not run for this slice because all changes are
  internal hot-path reductions rather than visible UI/output behavior

## 2026-06-30 Photo Import ImageSource Reuse

Third performance slice, still scoped to behavior-preserving internal hot paths:

- no UI redesign
- no renderer/export logic rewrite
- no intended output-behavior change

What changed:

- Added `PhotoMetadataReader.properties(from source: CGImageSource)`.
- `PhotoImportService` now creates one `CGImageSource` up front for a readable
  file import and reuses it for both:
  - metadata property extraction
  - ImageIO display-image creation
- This removes a duplicate source-open / source-parse step from the normal
  single-photo import path.

Measured structural effect:

- Before this slice, a standard import path opened an ImageIO source once for
  metadata and then again for display-image generation.
- After this slice, the same import path reuses one shared source for both
  steps.
- This optimization applies per photo import and does not depend on batch size.

Preserved:

- No metadata parsing rules were changed.
- No share, queue, export, renderer, or photo-library behavior was changed.
- RAW fallback behavior remains unchanged; only the reusable source path for the
  common import flow was tightened.

Verification:

- passed focused `PhotoMemoTests/PhotoMetadataReaderTests`
- passed focused `PhotoMemoTests/PhotoImportServiceTests`
- passed `git diff --check`
- passed `PhotoMemo` macOS Debug build
- passed `PhotoMemoiOSMVP` generic iOS Debug build
- manual device verification was not run for this slice because the change is
  internal import-path reuse rather than visible UI/output behavior

## 2026-06-30 Batch Queue Persistence Write Reduction Follow-Up

Second low-risk performance slice on the same queue hot path:

- no UI redesign
- no renderer/export logic rewrite
- no intended output-behavior change

What changed:

- `BatchQueueExecution` now also defers persistence for the intermediate
  `metadataReady` state.
- The success path now keeps both:
  - `metadataReady`
  - `previewReady`
  as in-memory-only transitions until the subsequent persisted `exporting`
  boundary.
- Added another focused regression in
  `PhotoMemoTests/BatchQueueStorePersistenceTests` to confirm multiple deferred
  task updates flush only the latest state once.

Measured structural effect:

- The original successful processing path wrote queue state 7 times.
- The first slice reduced that to 5.
- This follow-up reduces it again to 4.
- Net result: 3 queue-persistence writes removed per successful photo.

Preserved:

- No queue JSON format was changed.
- No share-extension, renderer, export, or photo-library behavior was changed.
- Recovery semantics remain covered by the same queue recovery tests.

Verification:

- passed focused `PhotoMemoTests/BatchQueueStorePersistenceTests`
- passed focused `PhotoMemoTests/BatchQueueRecoveryTests`
- passed `PhotoMemo` macOS Debug build
- passed `PhotoMemoiOSMVP` generic iOS Debug build
- manual device verification was not run for this slice because the change is
  limited to queue persistence frequency, not visible UI or output semantics

## 2026-06-30 Batch Queue Persistence Write Reduction

Low-risk performance slice focused on the queue hot path:

- no UI redesign
- no renderer/export logic rewrite
- no intended output-behavior change

What changed:

- Added a `persist` control to `BatchQueueStore.updateTask(...)` so specific
  synchronous stage transitions can update in-memory state first and flush the
  persisted queue at the next stable boundary.
- `BatchQueueExecution` no longer persists the intermediate `previewReady`
  state before immediately advancing to `exporting`.
- Removed the redundant `store.persistJobs()` call on the successful completion
  path after the task had already been persisted as `.completed`.
- Added focused regression coverage in
  `PhotoMemoTests/BatchQueueStorePersistenceTests`.

Measured structural effect:

- A successful task previously wrote queue state 7 times across the main
  processing path.
- The same successful path now writes 5 times.
- This removes 2 queue-persistence writes per successful photo without changing
  final task state, output, notification semantics, or resume behavior.

Preserved:

- No queue JSON format was changed.
- No renderer, export, photo-library, or share-extension behavior was changed.
- Recovery semantics for missing managed intake files remain covered by the
  existing recovery tests.

Verification:

- passed focused `PhotoMemoTests/BatchQueueStorePersistenceTests`
- passed focused `PhotoMemoTests/BatchQueueRecoveryTests`
- passed `git diff --check`
- passed `PhotoMemo` macOS Debug build
- passed `PhotoMemoiOSMVP` generic iOS Debug build
- manual device verification was not run for this slice because the change is
  limited to queue persistence frequency, not visible UI or output semantics

## 2026-06-30 External Intake Persistence Diagnostics Consumption

Fifth stabilization slice for the upcoming refactor:

- no UI redesign
- no renderer/export logic rewrite
- no intended output-behavior change

What changed:

- Added typed `loadRequestsResult()` to `ExternalPhotoIntakeStore`.
- The external-intake store now internally distinguishes:
  - no persisted intake-request payload
  - successful intake-request decode
  - corrupted/unreadable persisted intake-request payload
- `loadRequests()` still preserves the old compatibility behavior and returns
  `[]` on missing/corrupt payloads.
- `PhotoMemoiOSProcessingDiagnosticsSnapshot` now also consumes the persisted
  external-intake request state, in addition to:
  - share-diagnostics events
  - shared queue snapshots
- The iOS MVP `处理进度` warning path can now surface corrupted:
  - shared diagnostics history
  - shared queue snapshots
  - shared external-intake request storage
- Added focused regression coverage for:
  - empty vs corrupted external-intake persisted requests
  - corrupted external-intake payload surfacing through the shared MVP
    diagnostics snapshot

Preserved:

- No queue execution, share handoff semantics, export behavior, or photo-library
  behavior was changed.
- Persisted external-intake request JSON format was not changed.
- Missing/corrupted intake request payloads still fail safe to an empty request
  list instead of crashing or blocking the host app.

Verification:

- passed focused `PhotoMemoTests/ExternalPhotoIntakeStoreDiagnosticsTests`
- passed focused `PhotoMemoTests/PhotoMemoiOSProcessingDiagnosticsSnapshotTests`
- passed `git diff --check`
- passed `PhotoMemo` macOS Debug build
- passed `PhotoMemoiOSMVP` generic iOS Debug build
- passed `PhotoMemoShareExtension` generic iOS Debug build
- no new test failure was introduced by this slice
- manual device verification was not run for this slice because the change is
  confined to persistence diagnostics and MVP warning surfacing

## 2026-06-30 MVP Processing Diagnostics Snapshot Consumption

Fourth stabilization slice for the upcoming refactor:

- no UI redesign
- no renderer/export logic rewrite
- no intended output-behavior change

What changed:

- Added `PhotoMemoiOSProcessingDiagnosticsSnapshot` as a thin shared-defaults
  adapter for the iOS MVP processing panel.
- The adapter now consumes:
  - `PhotoMemoShareDiagnostics.loadEventsResult(...)`
  - `SharedBatchQueueSnapshotService.loadJobsResult()`
- It distinguishes:
  - empty shared diagnostics state
  - readable shared diagnostics state
  - corrupted shared diagnostics payload
  - empty shared queue state
  - readable shared queue state
  - corrupted shared queue payload
- `PhotoMemoiOSMVPTestView` now refreshes its processing panel through that
  adapter instead of reading diagnostics as a plain empty-array fallback.
- The MVP `处理进度` card now surfaces a lightweight warning when shared
  diagnostics history or queue snapshots are unreadable, while still falling
  back safely to the existing empty-state behavior.
- Added focused regression coverage for:
  - empty vs corrupted combined processing state
  - readable diagnostics events preserved even when shared queue payload is
    corrupted

Preserved:

- No share queue execution, export, renderer, metadata, or photo-library
  behavior was changed.
- No persisted storage format was changed.
- Corrupted shared payloads still do not crash the MVP surface; they are simply
  diagnosable now instead of silently appearing as “nothing happened.”

Verification:

- passed focused `PhotoMemoTests/PhotoMemoiOSProcessingDiagnosticsSnapshotTests`
- passed focused `PhotoMemoTests/PhotoMemoShareDiagnosticsTests`
- passed focused `PhotoMemoTests/SharedBatchQueueSnapshotServiceTests`
- passed `git diff --check`
- passed `PhotoMemo` macOS Debug build
- passed `PhotoMemoiOSMVP` generic iOS Debug build
- no new test failure was introduced by this slice
- manual device verification was not run for this slice because the change is
  confined to MVP diagnostics surfacing and shared-defaults interpretation

## 2026-06-30 Shared Persistence Result Foundation

Third stabilization slice for the upcoming refactor:

- no UI redesign
- no renderer/export logic rewrite
- no intended output-behavior change

What changed:

- Added shared typed persistence-result models for lightweight shared-defaults
  reads/writes:
  - `PhotoMemoSharedDefaultsReadResult`
  - `PhotoMemoSharedDefaultsWriteResult`
  - matching failure payloads with storage key, payload size, and underlying
    error description
- `SharedBatchQueueSnapshotService` now internally distinguishes:
  - no persisted queue payload
  - successful queue decode
  - corrupted/unreadable persisted queue payload
- `PhotoMemoShareDiagnostics` now internally distinguishes:
  - no persisted diagnostics payload
  - successful diagnostics decode
  - corrupted diagnostics payload
  - encoding failure while attempting to persist diagnostics
- Existing non-throwing behavior is preserved:
  - `loadJobs()` still returns `[]` on missing/corrupt payloads
  - `loadEvents()` still returns `[]` on missing/corrupt payloads
  - `record(...)` still does not throw or change user-visible flow
- Added targeted regression coverage for:
  - empty vs corrupted shared queue data
  - empty vs corrupted share-diagnostics data
  - surfaced encoding failure for diagnostics persistence

Preserved:

- No renderer/layout/export/photo-library behavior was changed.
- No user-visible workflow, UI copy, or output behavior was changed.
- Existing callers that rely on non-throwing empty-array fallbacks still behave
  the same.

Verification:

- passed focused `PhotoMemoTests/SharedBatchQueueSnapshotServiceTests`
- passed focused `PhotoMemoTests/PhotoMemoShareDiagnosticsTests`
- passed `PhotoMemo` macOS Debug build
- passed `PhotoMemoiOS` generic iOS Debug build
- passed `PhotoMemoiOSMVP` generic iOS Debug build
- passed `PhotoMemoShareExtension` generic iOS Debug build
- full `PhotoMemoTests` still shows the same two pre-existing failures:
  - `ClassicWhiteSnapshotTests.landscapeStandardSnapshotStaysStable`
  - `RecordCardBuildServiceTests.buildsTemplate1WithProfileRelationshipAndBabyAgePhrasing`
- no new test failure was introduced by this slice

## 2026-06-30 Typed Share Diagnostics Stage Foundation

Second stabilization slice for the upcoming refactor:

- no UI redesign
- no renderer/export logic rewrite
- no intended output-behavior change

What changed:

- Added typed `PhotoMemoShareDiagnosticStage` values while preserving the
  existing persisted `"stage": "..."` JSON shape in shared defaults.
- `PhotoMemoShareDiagnosticEvent` now decodes stored stage strings into the
  typed wrapper and re-encodes them back as the same raw strings, so existing
  diagnostics history remains readable.
- Migrated `PhotoMemoRootSceneView`, `PhotoMemoAppRuntime`, iOS MVP progress
  surfaces, Live Activity driver code, Share Extension controller, and Share
  intake service off raw share-diagnostics stage strings and onto typed stage
  constants.
- Added focused regression coverage for:
  - known stage raw-value compatibility
  - unknown/legacy stage round-tripping
  - decoding stored diagnostic events that already contain raw stage strings

Preserved:

- No renderer/layout/export/photo-library behavior was changed.
- Persisted diagnostics still use the same `stage` string values in storage.
- Unknown future/legacy diagnostic stage strings are preserved instead of being
  dropped.

Verification:

- passed new `PhotoMemoTests/PhotoMemoShareDiagnosticsTests`
- passed `PhotoMemo` macOS Debug build
- passed `PhotoMemoiOS` generic iOS Debug build
- passed `PhotoMemoiOSMVP` generic iOS Debug build
- passed `PhotoMemoShareExtension` generic iOS Debug build
- full `PhotoMemoTests` still shows the same two pre-existing failures:
  - `ClassicWhiteSnapshotTests.landscapeStandardSnapshotStaysStable`
  - `RecordCardBuildServiceTests.buildsTemplate1WithProfileRelationshipAndBabyAgePhrasing`
- no new test failure was introduced by this slice

## 2026-06-30 Typed iOS Temporary Entry Foundation

First optimization slice for the upcoming stability-focused refactor:

- no UI redesign
- no renderer/export logic rewrite
- no intended output-behavior change

What changed:

- Added a typed `PhotoMemoiOSTemporaryEntry` model and
  `PhotoMemoiOSTemporaryEntryConfiguration` so the iOS root/MVP entry flow no
  longer depends on raw strings for:
  - `configurationCenter`
  - `mvpTest`
- `PhotoMemoiOSHomeView`, `PhotoMemoRootSceneView`, and
  `PhotoMemoiOSTemporaryEntryView` now pass one typed temporary-entry
  configuration instead of separate storage-key/default-entry strings.
- `PhotoMemoiOSMVPApp` now opts into the dedicated MVP temporary-entry
  configuration explicitly, preserving the existing behavior that the standalone
  MVP app boots into the MVP page by default.
- Added focused regression coverage for:
  - raw-value compatibility with existing stored defaults
  - fallback behavior for invalid persisted values
  - isolation between the standard iOS and MVP temporary-entry storage keys

Preserved:

- No renderer/layout/export/photo-library behavior was changed.
- The standard iOS app still defaults to `configurationCenter`.
- The standalone MVP app still defaults to `mvpTest`.

Verification:

- passed new `PhotoMemoTests/PhotoMemoiOSTemporaryEntryTests`
- passed `PhotoMemoiOS` generic iOS Debug build
- passed `PhotoMemoiOSMVP` generic iOS Debug build
- `PhotoMemoTests` full suite still shows the same two pre-existing
  order-dependent failures:
  - `ClassicWhiteSnapshotTests.landscapeStandardSnapshotStaysStable`
  - `RecordCardBuildServiceTests.buildsTemplate1WithProfileRelationshipAndBabyAgePhrasing`
- no new test failure was introduced by this slice
- manual device verification was not run for this slice because the behavior
  change is internal typing/storage cleanup rather than a user-visible workflow

## 2026-06-30 iCloud Source Readiness Guard For Share Intake

User reported the MVP could still sit at:

- `正在交给 PhotoMemo`
- `检查待处理照片`
- `正在读取刚接收的照片`

Additional requirement:

- account for iCloud Photos needing to cache/download the full original before
  PhotoMemo can safely process it
- show this only when it matters; local readable photos should not gain an
  extra visible step

What changed:

- Added `PhotoMemoImageFileReadiness` as a shared guard for external intake.
- Share intake now waits for provider URLs to become real readable image files
  before copying them into App Group storage.
- Managed copies are verified after copy/write with ImageIO before being
  persisted as successful intake.
- The host app no longer treats `fileExists` alone as enough to enqueue a
  Share request; the file must be readable as an image.
- `PhotoImportService` now performs a final bounded readiness wait before
  metadata/image decoding.
- Share Extension diagnostics now emit source-readiness events only when the
  source needs preparation:
  - `extension.source.prepare`
  - `extension.source.ready`
  - `extension.source.unavailable`
- The Share sheet can briefly show `正在读取 iCloud 原图` while the source is
  being prepared.
- The iOS MVP `处理进度` panel maps those events to an iCloud-original
  preparation step, then proceeds to handoff/queue status.

Preserved:

- Renderer/layout/export/photo-library save behavior was not changed.
- Local already-readable images skip the extra user-visible iCloud preparation
  step.

Verification:

- passed focused `PhotoMemoTests/ExternalPhotoIntakeStoreDiagnosticsTests`
- passed focused `PhotoMemoTests/PhotoImportServiceTests`
- passed `git diff --check`
- passed `PhotoMemoShareExtension` generic iOS Debug build
- passed `PhotoMemoiOSMVP` generic iOS Debug build
- passed `PhotoMemoiOSMVP` iPhone7 Debug build
- installed `PhotoMemoiOSMVP` on iPhone7
  `863C2747-6742-5E93-B715-6F89DBF90B31`
- automatic launch after install was denied by iOS because the current debug
  signing profile is not trusted on the device

## 2026-06-30 Share Handoff And Stale Queue Recovery Fix

User reported the latest device build regressed in four linked ways:

- after tapping the Share stage-1 start button, the sheet could close before the
  stage-2 queue was useful
- stage 2 could wait without any real processing starting
- the iOS MVP processing panel kept showing an old `09:05` task
- newly shared photos could fail to produce output

Root cause:

- The Share Extension can persist intake and observe shared queue snapshots, but
  it does not own the renderer/export/photo-library pipeline.
- The previous follow-up removed the automatic main-app handoff, so the
  extension could wait for a `BatchJob` that the main app had not been woken to
  create.
- The queue stores newest jobs at index `0`, but the execution selector walked
  indices in reverse, so an older non-terminal job could block the newest Share
  job.
- On resume, missing managed App Group intake files were re-queued instead of
  being marked as non-retryable failures, allowing stale jobs to stay visible
  and keep occupying progress.

What changed:

- Share stage 1 now persists intake, switches visibly into stage 2, waits
  briefly, then requests the main app handoff so processing can actually start.
- If handoff is not confirmed, the stage-2 queue stays visible and offers the
  explicit open-PhotoMemo recovery path.
- `BatchQueueExecution.nextPendingTaskReference` now honors the queue ordering
  created by `jobs.insert(job, at: 0)`, so newest queued Share jobs run first.
- `BatchQueuePersistence.normalizeJobsForResume` now marks missing managed
  intake sources as failed/non-retryable instead of re-queuing them.
- Batch queue persistence now synchronizes shared defaults after writes so the
  Share Extension snapshot reader can see fresh state sooner.
- Added focused regression coverage for newest-job selection and stale managed
  source recovery.

Verification:

- passed focused `PhotoMemoTests/BatchQueueRecoveryTests`
- passed focused `PhotoMemoTests/SharedBatchQueueSnapshotServiceTests`
- passed focused `PhotoMemoTests/BatchNotificationMessageFormatterTests`
- passed `git diff --check`
- passed `PhotoMemoShareExtension` generic iOS Debug build
- passed `PhotoMemoiOSMVP` iPhone7 Debug build
- installed and launched `PhotoMemoiOSMVP` on iPhone7
  `863C2747-6742-5E93-B715-6F89DBF90B31`

Follow-up device finding:

- Real-device testing with 2 photos showed that automatic main-app handoff from
  inside the Share Extension still makes iOS close the share sheet before the
  stage-2 queue can be observed.
- The automatic handoff path was removed again from the stage-1 start flow.
- Stage 2 now stays inside the Share Extension and presents the queue/waiting
  state first.
- Opening PhotoMemo is kept as an explicit recovery action from the stage-2
  waiting state, because opening the containing app is what dismisses the share
  sheet on iOS.
- Share copy no longer says processing has already started before a host-app
  queue is observed; it now says the photos were received and are waiting to be
  added to the processing queue.

Follow-up verification:

- passed focused `PhotoMemoTests/BatchQueueRecoveryTests`
- passed `git diff --check`
- passed `PhotoMemoShareExtension` generic iOS Debug build
- passed `PhotoMemoiOSMVP` iPhone7 Debug build
- installed `PhotoMemoiOSMVP` on iPhone7
  `863C2747-6742-5E93-B715-6F89DBF90B31`
- automatic launch was blocked only because the device was locked

Second follow-up after user device test:

- User confirmed the two-stage Share sheet remained unreliable: no useful stage
  2 and no output.
- Product decision for the MVP test path: stop attempting a two-stage Share
  observation sheet for now.
- Share Extension is reduced back to a single confirmation surface:
  - shows detected photo count
  - explains that tapping the button opens PhotoMemo
  - persists the intake
  - immediately requests host-app handoff
  - leaves detailed progress to the main app's `处理进度` module
- Main-app progress now allows a newer Share diagnostic event to override an
  older completed snapshot, so a previous `09:05` completed card does not hide
  a fresh `10:44` intake/drain state before the new queue appears.

Second follow-up verification:

- passed focused `PhotoMemoTests/BatchQueueRecoveryTests`
- passed `git diff --check`
- passed `PhotoMemoShareExtension` generic iOS Debug build
- passed `PhotoMemoiOSMVP` iPhone7 Debug build
- installed and launched `PhotoMemoiOSMVP` on iPhone7
  `863C2747-6742-5E93-B715-6F89DBF90B31`

Third follow-up for output stability:

- User clarified the priority is stable output before any further Share UI
  polish.
- `requestMainAppRefresh` no longer waits for
  `app.enqueue.created` / handoff confirmation after iOS accepts the open-app
  request.
- The Share Extension now treats its responsibility as:
  persist intake -> request opening PhotoMemo -> let the main app drain and
  process.
- This removes an unnecessary confirmation wait from the extension lifecycle
  and keeps renderer/export/photo-library output owned by the main app.

Third follow-up verification:

- passed focused `PhotoMemoTests/BatchQueueRecoveryTests`
- passed `git diff --check`
- passed `PhotoMemoShareExtension` generic iOS Debug build
- passed `PhotoMemoiOSMVP` iPhone7 Debug build
- installed `PhotoMemoiOSMVP` on iPhone7
  `863C2747-6742-5E93-B715-6F89DBF90B31`
- automatic launch was blocked only because the device was locked

## 2026-06-30 Share Two-Stage Flow And Result Notification Polish

User clarified the MVP share flow should be staged:

- Stage 1 only confirms the share payload is usable:
  `检测到 X 张照片` plus one `开始处理 X 张` button.
- Stage 1 should not show thumbnails, configuration details, or target-album
  details.
- Stage 2 appears after tapping start and acts as a short observation window:
  thumbnails are shown there, PhotoMemo indicates processing has started, and
  the user can close the window while final feedback comes through the system
  notification.
- Live Activity is not appropriate for the current fast MVP path; keep final
  completion/failure notification as the main system-level result feedback.

What changed:

- `PhotoMemoShareExtensionViewController` now hides the preview and workflow
  summary during the initial confirmation stage.
- The confirmation title now reads like `检测到 2 张照片`, with a single start
  button.
- After the user starts processing, the same share sheet switches into the
  processing/received stage, loads the thumbnail queue, and leaves a stable
  close button instead of auto-dismissing immediately.
- The processing/received stage now shows per-photo status badges backed by
  the real persisted batch queue:
  - gray: waiting
  - blue: processing
  - green: completed
  - red: needs attention
- The second-stage queue display was corrected from horizontal thumbnail cards
  to compact per-photo rows, matching the referenced queue design direction:
  thumbnail on the left, photo row text in the middle, status icon on the right.
- The Share Extension now reads a lightweight App Group batch queue snapshot,
  finds the job created for the current share request through share diagnostics,
  and polls briefly at high frequency so very fast jobs can visibly complete in
  the sheet.
- Root-cause clarification: the Share Extension can persist the request, but it
  does not own the real batch renderer/export pipeline. The queue starts when
  the main PhotoMemo app consumes the shared request and creates a `BatchJob`.
  If that handoff does not produce `app.enqueue.created`, the sheet now says the
  photos are received but waiting for PhotoMemo to take over, with a button to
  open PhotoMemo and continue processing.
- Final batch notifications now include the saved album name when available,
  e.g. `已保存到「家庭相册」。`
- Completed tasks now keep a small local notification thumbnail attachment
  copied from the generated output before the temporary render file is cleaned
  up. The final notification attaches the first completed thumbnail when
  available.
- Added focused snapshot-reader coverage for the new shared queue observation
  layer.

Preserved:

- No renderer layout, metadata extraction, Photo Library save behavior, or
  original-photo mutation behavior was changed.
- Stage-by-stage local notifications remain disabled; detailed real-time
  progress remains a main-app concern.

Verification:

- passed `git diff --check`
- passed focused `PhotoMemoTests/BatchNotificationMessageFormatterTests`
- passed focused `PhotoMemoTests/SharedBatchQueueSnapshotServiceTests`
- passed `PhotoMemoShareExtension` generic iOS Debug build
- passed `PhotoMemoiOSMVP` generic iOS Debug build
- passed `PhotoMemoiOSMVP` iPhone7 Debug build
- passed `PhotoMemo` macOS Debug build
- installed `PhotoMemoiOSMVP` on iPhone7
  `863C2747-6742-5E93-B715-6F89DBF90B31`
- installed the follow-up compact queue build and launched it on iPhone7
  `863C2747-6742-5E93-B715-6F89DBF90B31`

## 2026-06-30 Immers White Portrait Right Cluster Pixel Pass

User provided the newest portrait Apple-target and MVP-red-seal samples:

- Target: `/Users/rui/Downloads/IMG_0015 3.JPEG`
- MVP: `/Users/rui/Downloads/IMG_0015(1) 5.JPG`

Measured finding:

- Canvas remains `4536 x 8817`.
- Photo area remains `8064 px`.
- Bottom information bar remains `753 px`.
- Therefore the correction is not a border-height or canvas-size change.
- Compared with the Apple baseline, the MVP portrait right-side cluster still
  sits about `75-78 px` too far right.
- The right primary metadata line is about `25 px` taller than the Apple
  baseline.
- The divider is about `57 px` taller than the baseline.
- The custom red Logo visual footprint is smaller than the Apple fallback and
  its visible center sits about `62 px` to the right of the baseline Apple
  center.

What changed:

- Portrait Immers White right-side frame now moves left by increasing the right
  column width from `0.389` to `0.406`, making the effective right anchor
  `0.549`.
- Portrait right-primary metadata font ratio is separated from the left-primary
  title ratio and reduced to `0.154`.
- Portrait divider height is reduced to `0.465` of the bar height.
- Portrait custom image Logo rendering is scaled by `1.36x` so the red seal
  occupies a footprint closer to the Apple fallback. System-symbol Apple
  fallback remains unscaled.
- Compact preview specs now expose `rightPrimaryFontToBarHeight` and
  `customLogoScale` so preview surfaces can stay aligned with the renderer.

Preserved:

- Landscape Immers White values were intentionally left unchanged.
- Photo-area preservation, export metadata, Share Extension, and Photo Library
  behavior were not changed.

Verification:

- passed `git diff --check`
- passed focused `PhotoMemoTests/ImmersWhiteRendererLayoutTests`
- passed focused `PhotoMemoTests/RendererConstantsTests`
- passed `PhotoMemoiOSMVP` generic iOS Debug build
- passed `PhotoMemo` macOS Debug build

## 2026-06-30 Portrait Left Edge Artifact Threshold Follow-Up

Follow-up after device review:

- User noticed the generated portrait output still felt slightly shifted right
  compared with the original photo, as if the right side of the original image
  had been removed.
- Pixel mapping confirmed this observation:
  - in older generated samples, output `x ~= 122` corresponded to original
    `x = 0`
  - the output right edge corresponded to original `x ~= width - 122`
  - therefore the previous crop-and-stretch safety guard could hide the black
    line, but it could not restore the already-missing right-edge content
- Export now treats this as a photo-area preservation problem instead of only an
  edge-artifact cleanup problem.
- For Immers White output, `RecordCardExportService` now:
  1. renders the full card normally to preserve the existing information bar
  2. decodes the original source photo again with ImageIO for export
  3. replaces only the rendered photo area with that source image
  4. keeps the bottom information bar from the SwiftUI render unchanged
  5. leaves the previous black-edge guard as a fallback safety pass
- Added regression coverage proving that a shifted rendered photo area with a
  `122 px` lost right edge is replaced by the original source image and keeps
  the original right edge intact.
- This supersedes the crop-and-stretch guard as the primary fix for Immers White
  final output. The guard remains only as a conservative fallback.

Additional verification:

- passed focused `PhotoMemoTests/PhotoImportServiceTests`
- passed `git diff --check`
- passed `PhotoMemoiOSMVP` generic iOS Debug build
- passed `PhotoMemo` macOS Debug build

User provided three original/output portrait sample pairs generated through the
iOS MVP flow:

- `IMG_9704.jpg` -> `IMG_9704(1).JPG`
- `IMG_9856.jpg` -> `IMG_9856(1).JPG`
- `IMG_9910.jpg` -> `IMG_9910(1).JPG`

Finding:

- The original photos do not contain a solid black left border.
- The generated outputs contain a pure-black strip only in the photo area, not
  in the bottom information bar.
- Measured strip widths:
  - `IMG_9704(1).JPG`: about `86 px`
  - `IMG_9856(1).JPG`: about `122 px`
  - `IMG_9910(1).JPG`: about `51 px`
- The previous artifact guard was still too conservative for the newest MVP
  outputs because it only accepted up to `2%` of width, capped at `96 px`.

What changed:

- The import display-image guard and final rendered-image guard now accept a
  still-narrow left-edge artifact up to `3%` of image width, capped at
  `160 px`.
- Detection remains conservative: the left columns must be near-solid black
  across almost the full photo height and the transition column must be visibly
  non-black.
- Added regression coverage for a `4536 px`-wide portrait case with a
  `122 px` black strip at both the import-display and final-rendered stages.

Preserved:

- No bottom information bar layout, text, Logo 标识, metadata writing, Photo
  Library behavior, Share Extension behavior, or renderer layout constants were
  changed.

Verification:

- passed `git diff --check`
- passed focused `PhotoMemoTests/PhotoImportServiceTests`
- passed `PhotoMemoiOSMVP` generic iOS Debug build
- passed `PhotoMemo` macOS Debug build
- full `PhotoMemoTests` still reports two order-dependent failures when run as
  a full suite:
  - `ClassicWhiteSnapshotTests.landscapeStandardSnapshotStaysStable`
  - `RecordCardBuildServiceTests.buildsTemplate1WithProfileRelationshipAndBabyAgePhrasing`
- both full-suite failures pass when rerun individually, and are outside the
  import/export edge-guard path changed in this slice.

## 2026-06-29 Immers White Pixel-Level Text Alignment Pass

Follow-up on 2026-06-30:

- Applied the second measured border-form correction after the newest
  landscape/portrait MVP-vs-target comparison.
- Preserved the locked photo area and bottom white-bar height.
- Added a measured `secondaryYOffsetToBarHeight` compact-bar token:
  - portrait `-0.028`
  - landscape `-0.037`
- `ImmersWhiteRenderer` now applies this as a visual offset only to the
  secondary B/D line, while keeping the already-corrected primary A/C offset.
- Portrait right-side cluster was moved left to match the newest measured
  target:
  - right text start `0.580 -> 0.566`
  - divider center `0.554 -> 0.540`
  - logo center `0.504 -> 0.490`
- Divider width now follows a bar-height ratio:
  - `dividerWidthToBarHeight 0.018 -> 0.022`
  - renderer minimum visible width `4 px -> 6 px`
- iOS MVP preview, formal iOS configuration preview, and macOS interactive
  memory card preview now apply the same secondary-line offset.
- Focused renderer tests and constant tests were updated to lock these values.

Verification:

- passed `git diff --check`
- passed focused `PhotoMemoTests/ImmersWhiteRendererLayoutTests`
- passed focused `PhotoMemoTests/RendererConstantsTests`
- passed `PhotoMemoiOSMVP` generic iOS Debug build
- passed `PhotoMemo` macOS Debug build

Manual follow-up:

- Reinstall on iPhone and regenerate the same horizontal/vertical samples.
- Confirm B/D no longer sit about `20 px` low.
- Confirm portrait right cluster no longer sits about `62 px` too far right.
- Confirm the divider reads closer to the target without overpowering the Logo
  标识.

This slice performs a pixel-level output-form polish for the Immers White
bottom information bar. It does not change generated content strings.

Finding:

- New landscape and portrait MVP-vs-target border comparisons showed that the
  bottom bar height is already correct.
- The measured difference is line-specific rather than bar-wide:
  - landscape primary A is about `13 px` high, primary C about `8 px` high
  - portrait primary A is about `15 px` high, primary C about `14 px` high
  - secondary B/D are already vertically aligned
- Therefore the column should not be moved as a whole. Only the primary line
  needs a visual downward correction.
- Portrait horizontal alignment still needs a small refinement:
  - left text is slightly too far left
  - right text is too far right
- The divider between the logo and right text was too subtle compared with the
  target samples.

What changed:

- Added a measured `primaryYOffsetToBarHeight` compact-bar token:
  - portrait `0.019`
  - landscape `0.020`
- `ImmersWhiteRenderer` applies this as a visual offset only to primary A/C
  text, preserving the secondary B/D line position.
- Portrait renderer layout now nudges the left column right and the right
  cluster left by updating the measured compact anchors.
- Primary text color is slightly darker, moving from black `0.92` opacity to
  `0.98`.
- The logo/right-content divider width is increased from `2 px` to `4 px`.
- iOS MVP preview, formal iOS configuration preview, and the interactive memory
  card preview now apply the same primary-line visual offset.
- Renderer constant and layout tests now lock the new offsets and divider width.

Preserved:

- Border height, photo area, secondary text line position, content generation,
  metadata/export behavior, and custom logo handling are unchanged.

Verification:

- passed `git diff --check`
- passed focused `PhotoMemoTests/ImmersWhiteRendererLayoutTests`
- passed focused `PhotoMemoTests/RendererConstantsTests`
- passed `PhotoMemoiOSMVP` generic iOS Debug build
- passed `PhotoMemo` macOS Debug build

## 2026-06-29 Final Export Edge Guard And Share Confirmation Polish

This slice adds a final safety guard for the portrait left-edge artifact and
polishes the iOS Share Extension confirmation experience.

Finding:

- The newest user sample still showed the same pattern: the original photo
  area can contain a narrow near-black strip on the left edge, while the bottom
  information bar remains correct.
- Pixel inspection of the generated portrait sample found a `51 px` near-black
  strip in the photo area only.
- Because the strip appears after the full card is composed, import-time
  decoding protection is not enough by itself.

What changed:

- `RecordCardExportService` now applies a conservative final rendered-image
  guard after `ImageRenderer` produces the composed card.
- The guard samples only the photo area, detects a narrow near-solid black left
  strip, crops that strip, stretches the photo area back to the original output
  width, and copies the information bar unchanged.
- Share Extension success no longer animates the content stack toward the
  top-left. It now holds a stable received/processing state briefly, then
  dismisses.
- Success copy now says the photos have been received and PhotoMemo has started
  background processing; progress can be checked in the main app's `处理进度`.
- Share Extension preview thumbnails no longer use a visible card/border
  background. Small batches now use calmer orientation-aware sizing, including a
  portrait-plus-two-landscape arrangement.

Preserved:

- Immers White border height, text layout, typography constants, logo behavior,
  metadata writing, and Photo Library behavior are unchanged.

Verification:

- passed `git diff --check`
- passed `PhotoMemoShareExtension` generic iOS Debug build
- passed focused `PhotoMemoTests/PhotoImportServiceTests`
- passed `PhotoMemoiOSMVP` generic iOS Debug build
- passed `PhotoMemo` macOS Debug build
- passed `PhotoMemoiOSMVP` iPhone7 Debug build
- installed and launched `PhotoMemoiOSMVP` on iPhone7
  `863C2747-6742-5E93-B715-6F89DBF90B31`

## 2026-06-29 Portrait Left Edge Artifact Guard

This slice fixes a generated portrait image issue where the photo area could
contain a narrow black vertical strip on the left edge while the bottom
information bar remained correct.

Finding:

- The user sample `IMG_9911(1).JPG` is `4536 x 8817`.
- Pixel inspection showed the photo area left edge had a `51 px` near-black
  strip from `y = 0` through the original photo area.
- The bottom information bar started at `y = 8064` and did not contain the
  strip, so the issue belongs to the imported photo display layer, not the
  Immers White information bar.
- A later source/output pair (`IMG_0015.jpg` and `IMG_0015(1).JPG`) confirmed
  the original source image itself has no black strip at the left edge, while
  the generated image introduces a `51 px` black strip in the photo area.
- Root cause direction: normal JPEG import used `PlatformImage(data:)`, leaving
  UIKit/AppKit image decoding details for SwiftUI `ImageRenderer`. For this
  source, the final rendered photo content was shifted right by `51 px`.

What changed:

- Normal non-RAW image import now prefers ImageIO display decoding through
  `CGImageSourceCreateThumbnailAtIndex(..., kCGImageSourceCreateThumbnailWithTransform)`,
  producing an orientation-baked `CGImage` before SwiftUI rendering.
- `PlatformImage.removingPhotoMemoLeftEdgeArtifact()` now detects a narrow,
  near-solid black strip at the left edge.
- Detection is intentionally conservative:
  - maximum trim is `2%` of image width, capped at `96 px`
  - the edge column must be near black across at least `96%` of sampled height
  - the transition column must be visibly non-black
- When detected, the image is cropped and stretched back to its original pixel
  width and height, so renderer/export dimensions remain unchanged.
- `PhotoImportService` applies ImageIO decoding and then the guard to the display
  image used by render and export.
- Added `PhotoImportServiceTests/removesNarrowBlackLeftEdgeArtifact`.

Preserved:

- Original source files are not modified.
- Renderer geometry, bottom border height, typography, metadata, export
  metadata, and Photo Library behavior are unchanged.

Verification:

- passed `git diff --check`
- passed focused `PhotoMemoTests/PhotoImportServiceTests`
- passed `PhotoMemoiOSMVP` generic iOS Debug build
- passed `PhotoMemo` macOS Debug build

## 2026-06-29 iOS MVP Configuration Surface Compression

This slice tightens the iOS MVP configuration surface without changing the
locked renderer output.

What changed:

- `记忆档案` now has a small edit button next to the Preset picker.
- Tapping the edit button opens an inline Preset-name field and commits the new
  name through `ConfigurationSession.updateSelectedMemoryPresetTitle`.
- `当前记忆对象摘要` is moved into the same compact summary block as the active
  configuration message, reducing vertical space.
- `处理进度` now shows a small `清除历史` action below the progress bar when
  historical queue overflow is visible.
- Clearing history removes only completed external-history jobs while preserving
  the currently displayed queue, active/waiting queues, and failure records that
  may still need attention.
- The four custom region cards no longer show the dedicated separator shortcut
  row; users can still type separators directly in the inline text field and
  the composed result remains visible.

Preserved:

- No renderer, border typography, export, metadata, Share Extension, or Photo
  Library behavior was changed.

Verification:

- passed `git diff --check`
- passed `PhotoMemoiOSMVP` generic iOS Debug build
- passed `PhotoMemo` macOS Debug build

## 2026-06-29 iOS MVP Processing Progress Panel

This slice makes the iOS MVP foreground app the trusted place to inspect Share
processing progress when system notification or Live Activity updates are too
fast or unreliable to observe.

Decision:

- Rename the foreground Share status module from `最近分享` to `处理进度`.
- Treat a single processing queue as one job, even when it contains multiple
  photos.
- When there is one queue, show the full five-stage pipeline:
  `接收照片 -> 读取信息 -> 生成卡片 -> 写入图库 -> 完成`.
- When there are multiple queues, show at most three queue lines using the
  existing `开始时间（X张）` queue title format, plus a compact overflow count.
- Completion state should remain visible in the module, using titles such as
  `15:20（2张）已完成`.
- Deferred handoff is no longer worded as a blocking failure once intake has
  persisted the original photos.

What changed:

- `PhotoMemoiOSMVPTestView` now renders `PhotoMemoBackgroundStatusService`
  snapshots directly in the main configuration surface.
- The progress card shows a linear progress value, current status text, and
  either the five pipeline steps or compact queue lines.
- Diagnostic event display is reduced to three recent meaningful events so the
  progress surface stays calm.
- Handoff-unconfirmed copy now says PhotoMemo is waiting to continue, instead
  of telling the user to retry or open the app.

Preserved:

- No renderer, border geometry, export, metadata, Share Extension, or Photo
  Library behavior was changed in this progress-panel slice.

Verification:

- passed `git diff --check`
- passed `PhotoMemoiOSMVP` generic iOS Debug build
- passed `PhotoMemo` macOS Debug build

## 2026-06-29 Immers White Landscape Cluster Recalibration

This slice responds to the new horizontal and vertical MVP-vs-target samples:

- `横图mvp生成图片1.JPG`
- `竖图mvp生成图片1.JPG`
- `横图我的目标.JPEG`
- `竖图我的目标.JPEG`

Pixel findings:

- Horizontal output and target both keep the original `4032 x 2268` photo area
  and add a `511 px` bottom information bar.
- Vertical output and target both keep the original `4536 x 8064` photo area
  and add a `753 px` bottom information bar.
- Therefore the white border height is already correct and was not changed.
- The largest real renderer mismatch was horizontal right-cluster placement:
  current renderer placed the right text start around `x = 61.7%`, while the
  measured landscape spec expects `x = 69.6%`.
- Portrait right-cluster placement already follows the measured compact spec.
- The red seal seen in the MVP sample is a saved/custom Logo configuration,
  while the target uses the gray Apple fallback. This is configuration state,
  not a renderer geometry bug.

What changed:

- Horizontal Immers White renderer now matches the landscape compact spec:
  - right text start about `0.696`
  - divider center about `0.675`
  - logo center about `0.636`
- The default capture-time line now uses `记录于{{capture_date_display}}`, matching
  the target wording/order when defaults are reset.
- MVP default Slot B now composes `记录于 + 日期 + 时间`.
- MVP preview no longer enlarges/boldens the left-primary line beyond the real
  renderer direction.
- Added test coverage so horizontal renderer geometry must match the measured
  `RendererConstants.CompactInformationBar.landscape` anchors.

Verification:

- passed `git diff --check`
- passed focused `PhotoMemoTests/ImmersWhiteRendererLayoutTests`
- passed `PhotoMemoiOSMVP` generic iOS Debug build
- passed `PhotoMemo` macOS Debug build

Manual note:

- Existing iPhone presets may still carry the old custom Logo or old Slot B
  ordering until the user resets/defaults or saves a new effective preset.

## 2026-06-29 Share Deferred Handoff And Result Notification

This slice corrects the Share interaction model after real-device diagnostics
showed that photos were already persisted and later processed successfully even
when the Share Extension could not confirm immediate host-app handoff.

Decision:

- Share Extension persistence is the user-facing success boundary for intake.
- A missing immediate handoff confirmation is recorded as deferred diagnostic
  state, not shown as a blocking failure.
- Later decode, render, save, or permission failures remain queue/result
  failures and are reported through the final result notification.
- Opening the main app can help inspect the recent Share pipeline, but it is
  not required on the happy path.

What changed:

- After successful intake persistence, the Share Extension now completes calmly
  even if `photomemo://share` handoff is not confirmed before timeout.
- The deferred handoff path records `extension.handoff.deferred` for later
  diagnostics.
- Final batch notifications now use clear result titles such as
  `15:20 处理 2 张照片已完成`.
- Final notification bodies no longer repeat the target album because album
  selection is already configured by the user.
- Added formatter coverage for successful, failed, and partial completion
  result messages.

Verification:

- passed `git diff --check`
- passed focused `PhotoMemoTests/BatchNotificationMessageFormatterTests`
- passed `PhotoMemoShareExtension` generic iOS Debug build
- passed `PhotoMemoiOSMVP` generic iOS Debug build
- passed `PhotoMemoiOSMVP` Debug build on iPhone7
- installed and launched `PhotoMemoiOSMVP` on iPhone7
  `863C2747-6742-5E93-B715-6F89DBF90B31`

Manual verification still needed:

- Share one new JPEG from Apple Photos and confirm the Share sheet no longer
  stays on the old handoff-failed screen after persistence.
- Confirm fast jobs may show only the completion result notification, which is
  acceptable when processing finishes before Live Activity becomes visible.
- Confirm the final notification title includes clock time and photo count.

## 2026-06-29 Immers White Primary Typography Calibration

This slice responds to the horizontal and vertical border-only pixel
comparison between the MVP exports and the target references.

Pixel findings:

- Horizontal and vertical bottom border heights already match the target
  outputs exactly.
- Secondary gray text height is already close enough and was intentionally
  preserved.
- The visible mismatch is the primary black line: MVP output reads larger and
  heavier than the target.

What changed:

- Compact information-bar primary font ratio changed from `0.225` to `0.190`.
- Immers White renderer primary title and metadata ratios changed to `0.190`
  for both landscape and portrait.
- Primary line weight changed from `.bold` to `.semibold` in renderer output,
  formal iOS preview, MVP preview, and the interactive memory card.
- MVP emphasized preview state now uses `.bold` instead of `.heavy`.

Preserved:

- Border height and final image size.
- Secondary gray text ratio, color, and weight.
- Image area, metadata/export pipeline, logo geometry, divider geometry, and
  content strings.

Verification:

- passed focused `PhotoMemoTests/ImmersWhiteRendererLayoutTests`
- passed focused `PhotoMemoTests/RendererConstantsTests`
- passed `PhotoMemoiOSMVP` generic iOS Debug build
- passed `PhotoMemo` macOS Debug build
- `git diff --check` passed

## 2026-06-29 Formal iOS And macOS Composer Alignment

This slice syncs the MVP inline-composition behavior into the formal
Configuration Center surfaces without copying the MVP test page into the
production app.

What changed:

- `ConfigurationCenteriOSView` now composes base text, inserted modules, and
  continuation text through `InlineContentTextComposer`.
- The formal iOS region editor uses tighter inline module spacing, matching the
  MVP direction without changing the overall Configuration Center structure.
- `ConfigurationSession.appendPreviewModule(...)` now uses the shared composer
  when inserting a module into the currently selected memory-card region.
- `MemoryBlockInspectorView` on macOS now uses the shared composer for custom
  field previews and for the final region preview sync.
- Added a regression test for the formal configuration shape:
  custom text + module + continuation text.

Preserved:

- The MVP temporary entry remains a test entry and was not copied into the
  formal iOS app.
- The macOS app remains the V2
  `Library -> Interactive Memory Card -> Object Inspector` Configuration
  Center.
- Renderer geometry, border typography, EXIF metadata mapping, export, Share
  Extension, and photo-library behavior were not changed.

Verification:

- passed focused `PhotoMemoTests/InlineContentTextComposerTests`
- `git diff --check` passed

## 2026-06-29 Default Logo Tint And Inline Content Spacing

This slice keeps the locked Immers White border geometry intact and fixes two
small output-readability issues found during MVP review.

What changed:

- Default system-symbol logos now render with the compact information bar logo
  tint directly instead of starting from `.primary` and using color multiply.
- The compact information bar logo tint now matches a softer Apple system gray
  direction: `#8E8E93`.
- User-uploaded bitmap logos are not recolored by this default-symbol tint path.
- The iOS MVP four-region Content Builder now uses
  `InlineContentTextComposer` for preview output, saved template text, and
  editor single-line display.
- Custom Chinese text and smart/token modules no longer receive automatic
  spaces between every item, while adjacent token values can still remain
  readable when no explicit separator is provided.

Preserved:

- The previously corrected Immers White portrait right-top capture-summary
  geometry was not changed.
- Border height, slot coordinates, font sizes, icon sizes, and parameter layout
  remain locked.

Verification:

- passed focused `PhotoMemoTests/InlineContentTextComposerTests`
- passed focused `PhotoMemoTests/ImmersWhiteRendererLayoutTests`
- passed `PhotoMemoiOSMVP` generic iOS Debug build
- passed `git diff --check`

## 2026-06-29 Immers White Portrait Right-Top Pixel Calibration

This slice responds to the comparison between the MVP-generated output
`IMG_9943(1).JPG` and the expected reference `IMG_9842 2.JPEG`.

Pixel findings:

- Reference image: `4536 x 8817`.
- MVP output: `3213 x 6246`.
- Bottom information bar height ratio is already aligned at about `8.6%` of
  final image height.
- The visible mismatch is in the portrait right-top capture-summary cluster:
  the MVP output starts the right text around `x = 0.609`, while the measured
  compact information-bar spec expects `x = 0.590`.
- That difference costs about `61 px` on a `3213 px` wide output and causes
  the capture summary to truncate earlier than the reference.

What changed:

- Adjusted the Immers White portrait renderer right column from `0.350` to
  `0.369`.
- Adjusted the divider-to-text spacing from `0.007` to `0.026`.
- This aligns the portrait geometry with the frozen measured spec:
  - right text start: `0.590`
  - divider center: `0.564`
  - logo center: about `0.514`
- Landscape Immers White geometry was not changed.
- Border height, fonts, colors, logo size, text content, export pipeline, and
  share/notification behavior were not changed.

Verification:

- confirmed focused renderer layout test failed before the renderer constant
  fix
- passed focused `PhotoMemoTests/ImmersWhiteRendererLayoutTests`
- passed `PhotoMemoiOSMVP` generic iOS Debug build
- passed `git diff --check`

## 2026-06-29 Share Intake Drain Order Fix

This slice fixes the real-device Share path where PhotoMemo appeared to accept
a photo but then showed no visible progress or output.

Evidence gathered from iPhone7 App Group diagnostics:

- Share Extension successfully imported `IMG_9943.jpg`.
- Share Extension persisted the request into the shared intake store.
- The primary `extensionContext.open(photomemo://share)` path returned false,
  but the responder-chain fallback returned true.
- The MVP host app received/drained the request.
- Before the fix, app-side validation reported `payloads=1, valid=0` and
  dropped the request as `No valid source files remained`.

Root cause:

- `PhotoMemoAppRuntime.refreshExternalIntakeState()` cleaned orphaned managed
  intake files before draining pending shared requests.
- The cleanup only kept files already referenced by the batch queue.
- A freshly shared file was still referenced only by the pending shared request,
  so the host app deleted the managed copy before validating/enqueuing it.

What changed:

- `refreshExternalIntakeState()` now updates configuration, drains pending
  shared requests into the batch queue, and only then runs orphan cleanup.
- This preserves freshly shared files until they become queue-owned.
- No renderer, export layout, border typography, or locked bottom-border output
  behavior changed.

Verification:

- passed `git diff --check`
- passed `PhotoMemoiOSMVP` generic iOS Debug build
- passed `PhotoMemoShareExtension` generic iOS Debug build
- passed `PhotoMemoiOSMVP` Debug build on iPhone7
- installed and launched `PhotoMemoiOSMVP` on iPhone7
  `863C2747-6742-5E93-B715-6F89DBF90B31`
- after a fresh Apple Photos Share test, diagnostics reported:
  - `extension.request.persisted`
  - `app.drain drainedRequests=1`
  - `app.request.validated payloads=1, valid=1`
  - `app.enqueue.created tasks=1`
- the resulting queue job `DFBAF8ED-C460-4629-89AC-4423A8B4C5B7` completed
  and recorded a `savedAssetIdentifier` in the target Photos album.

Remaining follow-up:

- Longer RAW / ProRAW tasks should be manually tested next, because fast JPEG
  jobs can complete before a persistent Live Activity becomes visible.
- One older terminal Live Activity attempt produced
  `Target is not foreground`; treat that as a separate ActivityKit visibility
  follow-up rather than the root cause of missing output.

## 2026-06-29 Share Progress Diagnostics Layer

This slice adds a local diagnostic timeline because the latest real-device
behavior can still leave users unable to tell whether a Share task is running.

Problem:

- The Share confirmation sheet no longer stays in the handoff-failed state.
- However, no visible progress appears afterward.
- Without instrumentation, the failure point could be any of:
  Share Extension intake, shared inbox persistence, main-app URL handoff,
  app-side drain, queue enqueue, or ActivityKit request.

What changed:

- Added `PhotoMemoShareDiagnostics`, a small App Group backed diagnostic store.
- Share Extension now records:
  - input item count
  - supported photo count
  - request creation
  - imported / skipped / failed item results
  - persisted request ID
  - primary and fallback handoff result
  - extension errors
- MVP host app now records:
  - `photomemo://share` receipt
  - shared-intake drain count
  - valid payload count
  - dropped request reason
  - created queue job ID
- Live Activity driver now records:
  - Activity authorization disabled state
  - terminal payload receipt
  - Live Activity request success
  - Live Activity request failure domain/code/message
- iOS MVP configuration screen now includes a calm `最近分享` diagnostic card
  that shows the latest Share timeline and a manual refresh button.

Verification:

- passed `git diff --check`
- passed `PhotoMemoShareExtension` generic iOS Debug build
- passed `PhotoMemoiOSMVP` generic iOS Debug build
- passed `PhotoMemoiOSMVP` Debug build on iPhone7
- installed and launched `PhotoMemoiOSMVP` on iPhone7
  `863C2747-6742-5E93-B715-6F89DBF90B31`

Manual verification needed:

- Share one new photo from Apple Photos.
- Open PhotoMemo MVP after 10-20 seconds.
- Screenshot the `最近分享` card.
- Use the stage timeline to identify the exact failing boundary.

## 2026-06-29 Share Handoff Fallback And MVP Preview Width

This slice responds to the device screenshot where the Share Extension showed
the explicit handoff-failed state after receiving the photo.

Root cause:

- The MVP app bundle still correctly registers the `photomemo` URL scheme.
- The Share Extension is installed and persisted the incoming photo.
- The system `extensionContext.open(photomemo://share)` call can still return
  `false` in this Share context, so the first handoff path is not reliable
  enough by itself.

What changed:

- `requestMainAppRefresh()` now keeps the official `extensionContext.open`
  path first.
- If that path fails, the Share Extension attempts a responder-chain fallback
  to open `photomemo://share`.
- The visible handoff-failed retry state remains as the final safety net.
- The iOS MVP configuration preview gives the left-top text area more width
  before the logo, reducing unnecessary ellipsis in strings such as
  `记录 iPhone 17 Pro...`.
- This preview-width change is local to the MVP configuration preview and does
  not change the locked rendered border/export layout.

Verification:

- passed `git diff --check`
- passed `PhotoMemoShareExtension` generic iOS Debug build
- passed `PhotoMemoiOSMVP` generic iOS Debug build
- passed `PhotoMemoiOSMVP` Debug build on iPhone7
- installed and launched `PhotoMemoiOSMVP` on iPhone7
  `863C2747-6742-5E93-B715-6F89DBF90B31`

Manual verification still needed:

- Share a new photo from Apple Photos and confirm the sheet no longer stays in
  the handoff-failed state.
- Confirm the new task appears as fresh progress rather than showing only a
  previous completed card.
- Confirm the left-top configuration preview no longer truncates too early.

## 2026-06-29 Share Handoff And Live Activity Visibility Fix

This slice addresses the latest real-device observation: the visible Live
Activity card could be from a previous task, while a newly shared task did not
show fresh progress.

Root cause:

- The Share Extension persisted incoming photos and called the
  `photomemo://share` handoff.
- The return value from `requestMainAppRefresh()` was ignored.
- If iOS did not actually open the MVP host app, the extension still completed
  and disappeared.
- In that failed handoff path, the host app never drained the shared intake
  store, so no new queue, new Live Activity, or new output could be created.

What changed:

- Share Extension now treats host-app handoff as required before completing the
  extension request.
- If the handoff fails, the confirmation UI stays open and shows the existing
  `重新交给 PhotoMemo` retry state instead of closing silently.
- Live Activity driver now tracks activity start time and keeps terminal states
  visible for a short minimum window.
- If a job reaches terminal state before an activity was visible, the driver
  attempts to create a short-lived final Live Activity instead of silently
  recording the payload.

Verification:

- passed `git diff --check`
- passed `PhotoMemoiOSMVP` generic iOS Debug build
- passed `PhotoMemoShareExtension` generic iOS Debug build

Manual verification still needed:

- Install to iPhone7 and share a new photo from Apple Photos.
- Confirm the Share confirmation sheet only disappears when PhotoMemo handoff
  succeeds.
- Confirm a new Live Activity appears for the new Share task, not only the
  previous completed card.

## 2026-06-29 Notification Progress Model Simplification

This slice clarifies the MVP progress surface after real lock-screen testing.

Decision:

- Local notifications are not the real-time progress surface.
- Stage-by-stage progress belongs to Live Activity / Lock Screen / Dynamic
  Island.
- Notification Center should stay quiet and only carry lifecycle results such
  as received, completed, or needs attention.

What changed:

- `BatchQueueNotifications.deliverProgressNotificationIfNeeded(...)` no longer
  reposts local notifications for `raw`, `imported`, `rendering`, or `saving`
  stages.
- The execution pipeline still updates task progress and Live Activity payloads
  through the queue state.
- Start and final local notifications remain available.
- This prevents stacked Notification Center cards from being used as a pseudo
  progress UI.

Verification:

- passed `git diff --check`
- passed `PhotoMemoiOSMVP` generic iOS Debug build
- passed `PhotoMemoiOSMVP` Debug build on connected iPhone7
- installed and launched `PhotoMemoiOSMVP` on iPhone7
  `863C2747-6742-5E93-B715-6F89DBF90B31`

Manual verification still needed:

- Share a new photo and confirm ordinary Notification Center no longer stacks
  stage updates.
- Confirm Live Activity remains the place where live progress changes.

## 2026-06-29 Live Activity Contrast Fix

This slice fixes a lock-screen readability issue found during iPhone testing.

What changed:

- The single-task Lock Screen Live Activity status line now uses `.secondary`
  instead of `.tertiary`.
- This makes messages such as `处理完成 · IMG_9927.jpg` readable on dark
  wallpapers and Notification Center blur backgrounds.
- No layout, progress model, notification scheduling, renderer, or export
  behavior changed.

Verification:

- passed `git diff --check`
- passed `PhotoMemoiOSMVP` generic iOS Debug build
- passed `PhotoMemoiOSMVP` Debug build on connected iPhone7
- installed and launched `PhotoMemoiOSMVP` on iPhone7
  `863C2747-6742-5E93-B715-6F89DBF90B31`

Manual verification still needed:

- Start a new Share task and confirm the Lock Screen / Notification Center
  status line is visible against the current dark wallpaper.

## 2026-06-29 MVP Preview And Inline Editor Polish

This slice responds to the latest iPhone visual review while preserving the
locked rendered bottom-border output.

What changed:

- The iOS MVP preview now applies strong text shrinking only to the right-side
  capture-summary area where overflow is most likely.
- The left-top preview line keeps a much higher minimum scale factor so recorder
  text returns closer to the previous visual size.
- The four-region inline editor spacing is tighter:
  - chip-to-text spacing reduced
  - chip padding reduced slightly
  - trailing phrase input width reduced so empty editor space no longer feels
    oversized
- When a module is the first item in a region, the editor now shows a small
  leading phrase input target so users can insert custom text before that
  module.

Verification:

- passed `git diff --check`
- passed `PhotoMemoiOSMVP` generic iOS Debug build
- passed `PhotoMemoiOSMVP` Debug build on connected iPhone7
- installed and launched `PhotoMemoiOSMVP` on iPhone7
  `863C2747-6742-5E93-B715-6F89DBF90B31`

Manual verification still needed:

- Confirm the preview left-top recorder text no longer looks over-shrunk.
- Confirm the right-top capture summary still fits without obvious truncation.
- Confirm typing before a leading module feels natural on the iPhone keyboard.

## 2026-06-29 MVP Content Builder Order And Notification Update

This slice fixes the latest iPhone review feedback without touching the locked
bottom-border rendering output.

What changed:

- The iOS MVP four-region editor now treats text, modules, separators, and
  future line-break items as one ordered content stream.
- User-entered phrases and inserted modules now keep the same order in the
  editing row, saved preset text, and live preview.
- Module insertion follows the currently edited text item when possible, so
  typing a phrase and then inserting a module places that module after the
  phrase instead of grouping modules separately.
- Editor module chips stay compact and only show the module title/icon plus the
  remove action; resolved EXIF/time values remain in the preview output.
- Share-driven local notifications now use one stable `status` notification
  identifier per batch job and remove older per-stage identifiers such as
  `progress.raw`, `progress.rendering`, and `progress.saving`.
- Progress updates are marked as passive notification updates, while queued and
  completed states remain active.

Verification:

- passed `git diff --check`
- passed `PhotoMemoiOSMVP` generic iOS Debug build
- passed `PhotoMemoiOSMVP` Debug build on connected iPhone7
- installed and launched `PhotoMemoiOSMVP` on iPhone7
  `863C2747-6742-5E93-B715-6F89DBF90B31`

Manual verification still needed:

- In the iPhone editor, type custom text, insert a module, continue typing, and
  confirm the row order and preview output stay aligned.
- Share one RAW or JPEG and confirm Notification Center keeps one task status
  instead of stacking stage notifications.

## 2026-06-29 MVP Reliability Lock Foundation

This slice starts the MVP Apple-System Capability Sprint without touching the
locked bottom-border output.

Principle:

- Border layout, typography, icons, content mapping, and rendered visual form
  remain frozen for this sprint.
- The current hardening target is the daily Apple Photos lifecycle:

```text
Apple Photos
-> Share
-> PhotoMemo
-> Processing
-> Notification
-> Apple Photos
```

What changed:

- Added `Docs/MVP_RELIABILITY_LOCK.md` as the current reliability gate for the
  MVP.
- The document freezes:
  - supported and unsupported input formats
  - queue naming semantics
  - single-task / multi-queue / aggregate progress behavior
  - RAW / DNG progress wording expectations
  - notification and Live Activity result language
  - manual regression scenarios required before reliability releases
- Added automated queue-regression coverage:
  - queue titles format from Share/start time plus photo count
  - queue creation follows the earliest intake payload request time
- Refined `PhotoMemoQueueDisplayFormatter` so today/yesterday decisions use the
  injected `now` value, making queue-title behavior deterministic in tests.
- Re-aligned `RecordCardBuildServiceTests` with the current MVP output naming
  rule where generated files use the original base name plus copy suffixes such
  as `(1)` and `(2)`.
- Added cleanup around naming tests so temporary export leftovers do not affect
  repeated local test runs.

Verification:

- passed focused `PhotoMemoTests/BatchFixtureCoverageTests`
- passed focused `PhotoMemoTests/RecordCardBuildServiceTests`
- passed `PhotoMemoiOSMVP` generic iOS Debug build
- passed `PhotoMemo` macOS Debug build
- passed `git diff --check`
- full `PhotoMemoTests` currently has one remaining failure:
  `ClassicWhiteSnapshotTests.landscapeStandardSnapshotStaysStable`

Next:

- Add automated coverage for background snapshot display modes and final
  notification copy.
- Investigate the remaining Classic White landscape snapshot separately without
  changing the locked border output casually.
- Run real-device manual regression for JPEG / HEIC / RAW / multi-share /
  partial-failure paths before the next phone push.

## 2026-06-29 MVP Queue Naming Refinement

This slice aligns the Share-driven progress surface with the latest interaction
decision: one queue represents one Share action, and the user-facing queue name
should be based on the share/start time plus the number of photos.

What changed:

- New Share-driven jobs now use compact queue names instead of engineering
  titles:
  - today: `18:42（3张）`
  - yesterday: `昨天 18:42（3张）`
  - earlier this year: `6月29日 18:42（3张）`
- Existing persisted jobs are also normalized at display time through
  `PhotoMemoBackgroundStatusService`, so old titles such as external image
  processing labels no longer leak into the status sheet or Live Activity.
- Queue lines now start with the queue name:
  - `18:42（3张） · 1/3 · 约 2 分钟`
  - `18:42（3张） · 1 张需要处理`
  - `18:42（3张） · 已保存 3 张`
- Completed and failed line copy was tightened from queue-state labels to
  result-first wording:
  - `已保存 X 张`
  - `X 张需要处理`
- `BatchJob.createdAt` now follows the earliest intake payload request time for
  newly enqueued jobs, which keeps queue naming closer to the actual Share
  action.

Verification:

- passed `git diff --check`
- passed `PhotoMemoiOSMVP` Debug build on connected iPhone7
- installed the updated MVP app to connected iPhone7

Manual verification still needed:

- Share one photo and confirm the status sheet / notification progress uses the
  compact queue name.
- Share 2-3 batches and confirm each queue line maps to one Share action.
- Share 4+ batches and confirm aggregate mode stays calm.

## 2026-06-29 MVP Share Handoff URL Scheme Fix

This slice fixes the next concrete reason the Share-driven MVP could appear to
accept RAW/JPEG input but then produce no visible progress or output.

Root cause:

- The Share Extension confirmation UI could run and persist incoming items.
- The MVP host app had Live Activity support and embedded extensions, but its
  built `Info.plist` did not contain a real `CFBundleURLTypes` entry.
- The Share Extension hands work to the host app by opening
  `photomemo://share`.
- Without the URL scheme registered on `PhotoMemoiOSMVP`, the host app could
  fail to open, which means it would not drain the shared intake store, enqueue
  jobs, start Live Activity progress, or save outputs.

What changed:

- Added `Source/PhotoMemo/PhotoMemoiOSMVP-Info.plist`.
- `PhotoMemoiOSMVP` now uses that Info.plist for Debug and Release.
- The MVP Info.plist explicitly contains:
  - `CFBundleURLTypes -> photomemo`
  - `NSSupportsLiveActivities`
  - photo-library usage strings
- Share Extension handoff is now observable:
  - `requestMainAppRefresh()` returns whether the host app opened.
  - If handoff fails, the confirmation UI stays visible with a retry action
    instead of silently completing.
- After successful intake, the confirmation stack now performs a subtle
  upward shrink/fade transition before handing work to the host app.

Verification:

- passed `PhotoMemoiOSMVP` Debug build on connected iPhone7
- confirmed built MVP `Info.plist` includes `CFBundleURLTypes -> photomemo`
- confirmed built MVP `Info.plist` includes `NSSupportsLiveActivities = true`
- confirmed built MVP app still embeds both Share and Widget extensions
- installed the updated MVP app to connected iPhone7
- passed `PhotoMemoiOSMVP` Debug iOS Simulator build
- passed `PhotoMemo` Debug macOS build
- passed `git diff --check`

Manual verification still needed:

- share a JPEG from Apple Photos into PhotoMemo MVP
- share a RAW / DNG from Apple Photos into PhotoMemo MVP
- confirm the host app handoff no longer silently fails
- confirm Lock Screen / Notification Center progress appears for non-trivial
  work
- confirm output appears in Apple Photos / the configured album

## 2026-06-29 Single Task Pipeline Progress

This slice refines the Share-driven background progress model so short and long
tasks feel more understandable without turning PhotoMemo into a batch dashboard.

What changed:

- `PhotoMemoBackgroundJobSnapshot` now exposes a display mode:
  - single task
  - queue lines
  - aggregate
- Single-photo tasks now use a fixed five-step progress model:
  - receive photo
  - read information
  - generate card
  - save to library
  - complete
- Lock Screen / Live Activity presentation now switches by display mode:
  - single task: status line + fine progress + pipeline dots
  - 2-3 queues: existing queue lines
  - 4+ queues: aggregate summary
- The iOS status sheet title is now `处理进度`.
- The iOS status sheet shows the full pipeline for single-photo tasks.
- Final local notification copy is shorter:
  - success: `PhotoMemo 已保存 X 张照片`
  - failure: `X 张照片需要处理`
  - partial success: `已保存 X 张，Y 张需要处理`

Verification:

- passed `PhotoMemoiOSMVP` Debug build on connected iPhone7
- installed updated MVP app to connected iPhone7
- passed `PhotoMemo` Debug macOS build

Manual verification still needed:

- single JPEG task on Lock Screen / Notification Center
- single RAW task with RAW-stage wording
- 2-3 share batches as separate queue lines
- 4+ batches as aggregate summary
- failure path with retry from the iOS status sheet

## Current Stage

PhotoMemo is now in V2.1 Memory Engine Product Realization.

Unscoped feature development, renderer polishing, and UI architecture redesign remain paused.

PM-003 Phase 1 is frozen.

IA-002 Configuration Center Architecture is frozen.

The current implementation track is:

```text
IA-003 Memory Engine Integration
```

The current target is a local-first Memory Presentation Engine:

`Photo -> Metadata Engine -> Memory Engine -> Presentation Engine -> Layout Engine -> Renderer -> Export`

Product principle:

- Photos have timestamps.
- Memories have positions.
- Memory Engine calculates Life Position.
- Presentation Engine expresses meaning.
- Layout Engine presents meaning.
- Renderer draws.

The highest-priority entry documents are:

- `PROJECT_CONSTITUTION.md`
- `Docs/MASTER_PLAN.md`
- `PROJECT_RESET.md`
- `RepositoryAudit.md`
- `Research/README.md`
- `Docs/REPOSITORY_VOCABULARY.md`
- `Docs/REPOSITORY_SIMPLIFICATION_REPORT.md`
- `Docs/PDR/PDR-004_Configuration_Center_Architecture.md`

## 2026-06-29 MVP RAW / ProRAW Priority Support

This slice upgrades the Share-driven MVP pipeline so RAW-oriented users are no
longer blocked at intake while preserving the non-destructive product rule.

Principle:

- RAW originals remain untouched.
- PhotoMemo creates a standard rendered output image from a system display
  representation plus the configured bottom card.
- The original RAW metadata remains the source of truth for EXIF-derived card
  content and metadata propagation.

What changed:

- `PhotoProcessingInputPolicy` now supports:
  - `JPEG/JPG`
  - `HEIC/HEIF`
  - `PNG`
  - `TIFF`
  - `RAW/DNG`
- The unsupported-format message no longer lists RAW / DNG as unsupported.
- RAW detection uses UTType conformance plus common RAW file extensions such as
  `dng`, `raw`, `arw`, `cr2`, `cr3`, `nef`, `orf`, `raf`, `rw2`, and `srw`.
- RAW inputs still follow the current standard photo envelope:
  - max single side: `8064 px`
  - max total pixels: `8064 x 6048`
  - max aspect ratio: `3:1`
- `PhotoImportService` now keeps normal photos on the existing stable data
  decode path, but routes RAW photos through a display-representation path:
  - platform file display image
  - ImageIO thumbnail/display generation with a bounded max pixel size
  - CoreImage fallback
- Batch progress now exposes RAW-specific stages:
  - `正在准备 RAW 照片`
  - `已生成 RAW 显示版本`
- Queue summaries now treat RAW as slower work:
  - single RAW items can show `准备 RAW` or `RAW 显示版本`
  - RAW estimate is currently `75 秒/张`
  - normal still-image estimate remains `14 秒/张`
- Local progress notification copy now includes the `raw` stage.

Verification:

- passed `PhotoMemoTests/PhotoProcessingInputPolicyTests`
- passed `PhotoMemoTests/PhotoImportServiceTests`
- passed `PhotoMemoTests/BatchFixtureCoverageTests`
- passed `PhotoMemoiOSMVP` Debug build on connected device `iPhone7`
- installed `PhotoMemoiOSMVP` to connected device `iPhone7`
- passed `PhotoMemoShareExtension` Debug iOS Simulator build
- passed `git diff --check`

Not yet manually verified:

- real Apple Photos share using an actual ProRAW / DNG asset
- final visual output and EXIF-token correctness for RAW-derived outputs
- memory-pressure behavior on iPhone7 with very large RAW files

## 2026-06-29 Share Confirmation Preview Card Stack

This slice improves the Share Extension confirmation window while keeping the
Share -> Processing behavior unchanged.

Problem:

- The confirmation window used a single fixed-height `UIImageView`.
- The preview used `.scaleAspectFill`, so portrait photos could be visibly
  cropped.
- Multi-photo shares only previewed the first photo, which made the upcoming
  queue feel less concrete.

What changed:

- The preview area now uses a horizontal `UIScrollView + UIStackView` card
  strip.
- Preview images use `.scaleAspectFit`, so portrait photos remain fully visible.
- The preview height is slightly reduced to `168pt`, with cards at `158pt`, so
  the confirmation window stays calm and compact.
- Multi-photo shares load up to the first 10 previews for memory safety inside
  the Share Extension.
- Cards use a subtle overlapping layout to create a restrained card-stack feel.
- Tapping a card now:
  - scales it to `1.06x`
  - strengthens its border
  - scrolls it into view
- User-facing copy now says:
  - `左右滑动查看待处理照片，所有照片会使用相同风格处理。`

Verification:

- passed `PhotoMemoShareExtension` Debug iOS Simulator build
- passed `PhotoMemoiOSMVP` Debug build on connected device `iPhone7`
- installed the updated MVP app to connected device `iPhone7`
- passed `git diff --check`

Manual verification still needed:

- share a single portrait photo and confirm it is no longer cropped
- share several mixed portrait/landscape photos and check horizontal swiping
- tap preview cards and verify the selected-card emphasis feels subtle

## 2026-06-29 MVP Live Activity Packaging Fix

This slice fixes the first concrete cause of "no queue progress appears in the
notification shade" for the MVP test app.

Root cause:

- The installed `PhotoMemoiOSMVP.app` only embedded the Share Extension.
- It did not embed `PhotoMemoWidgetExtension.appex`, which owns the Live
  Activity widget presentation.
- The MVP app Info.plist also missed `NSSupportsLiveActivities = YES`.
- ActivityKit therefore had no valid Live Activity presentation surface for the
  queue payloads.

What changed:

- `PhotoMemoiOSMVP` now depends on `PhotoMemoWidgetExtension`.
- `PhotoMemoiOSMVP` now embeds both app extensions:
  - `PhotoMemoShareExtension.appex`
  - `PhotoMemoWidgetExtension.appex`
- `PhotoMemoiOSMVP` Debug and Release generated Info.plist settings now include:
  - `INFOPLIST_KEY_NSSupportsLiveActivities = YES`

Verification:

- passed `PhotoMemoiOSMVP` Debug build on connected device `iPhone7`
- verified the built app bundle contains
  `PlugIns/PhotoMemoWidgetExtension.appex`
- verified the built app Info.plist contains
  `NSSupportsLiveActivities = true`
- installed the fixed app to connected device `iPhone7`
- passed `git diff --check`

Manual verification still needed:

- share a RAW or multi-photo batch from Apple Photos and check Lock Screen /
  Notification Center progress
- if no Live Activity appears, check system Settings for PhotoMemo Live
  Activities and notification permissions

## 2026-06-29 Background Pipeline Input Policy

This slice formalizes the first processing boundary for the Share-driven
background pipeline while preserving the current Configuration Center,
Renderer output, and Photo Library save behavior.

Principle:

- Keep the pipeline faster where it is safe.
- Do not parallelize rendering or Apple Photos writes before the runtime has
  stronger cancellation and memory-pressure controls.
- Reject unsupported inputs early with calm, system-style feedback instead of
  letting them fail deep inside rendering.

What changed:

- Added `PhotoProcessingInputPolicy` as the single source of truth for MVP
  input support.
- Supported still-image formats are:
  - `JPEG/JPG`
  - `HEIC/HEIF`
  - `PNG`
  - `TIFF`
- Explicitly unsupported for MVP:
  - Live Photo
  - RAW / DNG
  - GIF
  - WebP
  - video
- The current standard photo envelope is based on the highest iPhone still
  photo class used by the MVP:
  - max single side: `8064 px`
  - max total pixels: `8064 x 6048`
  - max aspect ratio: `3:1`
- Extremely wide, tall, panoramic, long-screenshot, or very thin images are
  rejected with a specific reason.
- `PhotoImportService.supportedTypes()` now reads from
  `PhotoProcessingInputPolicy.supportedImageTypes`, so format support is no
  longer duplicated.
- Share Extension intake now validates copied files before persisting a batch
  request:
  - copied files are checked through `PhotoProcessingInputPolicy`
  - unsupported copied files are immediately cleaned up
  - unsupported items increment `skippedCount`
  - skipped wording is now generic (`已跳过`) rather than duplicate-only
- The `3:1` aspect-ratio rule uses long side divided by short side. Portrait
  photos are supported when they remain inside the same envelope:
  - `6048 x 8064` portrait is supported
  - `3024 x 5376` 9:16 portrait is supported
  - panorama, long screenshot, and very thin images remain unsupported

Recommended interaction language:

- Live Photo: `暂不支持 Live Photo`
- Unsupported format: `暂不支持这种格式`
- Oversized image: `照片尺寸过大`
- Extreme aspect ratio: `暂不支持超长比例图片`
- Missing size: `无法读取照片尺寸`

Verification:

- passed `PhotoMemoTests/PhotoProcessingInputPolicyTests`
- passed `PhotoMemoTests/PhotoImportServiceTests`
- passed `PhotoMemoTests/PhotoFileNameResolverTests`
- passed `PhotoMemoTests/PhotoMemoAlbumSelectionTests`
- passed `PhotoMemoShareExtension` Debug iOS Simulator build
- passed `PhotoMemoiOSMVP` Debug iOS Simulator build
- passed `PhotoMemoiOS` Debug iOS Simulator build
- passed `git diff --check`

Known tooling note:

- The app scheme `PhotoMemo` is not configured for test action.
- Use the `PhotoMemoTests` scheme for focused unit tests.

Deferred:

- Real-device partial-success interaction still needs manual verification once
  the policy is connected to intake.
- Render/save concurrency remains intentionally serial for this slice.

## 2026-06-28 MVP Album And Logo Output Completion

This slice closes the remaining MVP output-setting gaps for album placement
and custom Logo assets while preserving the existing Share-driven processing
flow.

What changed:

- Generated photos still enter the Apple Photos system library as new images.
- If the user does not choose an output album, PhotoMemo now resolves the
  automatic destination to a lowercase `photomemo` album.
- `PhotoLibraryExportService` can now create or reuse an album by name through
  `ensureAlbum(named:)`.
- The iOS MVP output section now supports:
  - automatic `photomemo` album behavior
  - system-library-only output
  - choosing an existing user album
  - creating/reusing a new album name when saving the configuration
- The saved album identifier and title still flow through shared settings into
  the Share Extension / batch snapshot path.
- Custom Logo upload is now real instead of placeholder-only:
  - iOS MVP uses the native `PhotosPicker`
  - selected images are optimized in the background
  - optimized Logo files are stored in the shared container under `LogoAssets`
  - the active Badge is persisted as `.customUpload` with `imagePath`
- Logo optimization now normalizes uploads into a square transparent PNG:
  - recommended upload: `2048 x 2048`
  - minimum useful upload: `1024 x 1024`
  - stored optimized asset: `2048 x 2048`
  - safe inset: `12%`
- The recommendation is based on current compact renderer metrics:
  - landscape 4032 px output displays the Logo at about `209 px`
  - future 12000 px portrait output displays the Logo at about `817 px`
  - a 2048 px master keeps enough headroom for large exports and print review

Verification:

- passed `PhotoMemoTests/PhotoMemoAlbumSelectionTests`
- passed `PhotoMemoTests/LogoAssetOptimizationServiceTests`
- passed `PhotoMemoiOSMVP` Debug iOS Simulator build on `iPhone 17 Pro, iOS 26.4`
- passed `PhotoMemoiOS` Debug iOS Simulator build on `iPhone 17 Pro, iOS 26.4`
- passed `PhotoMemoShareExtension` Debug iOS Simulator build
- passed `PhotoMemo` Debug macOS build
- passed `git diff --check`

Not yet manually verified:

- real-device album creation inside Apple Photos
- real-device custom Logo upload and visual output review
- Apple Photos share-sheet run using a custom Logo and newly created album

## 2026-06-28 MVP Share Pipeline Gap Closure

This slice closes two concrete MVP gaps while preserving the current
bottom-border-only preview and single-line four-region Content Builder.

What changed:

- PhotoMemo output file naming now follows the requested original-name copy
  convention:
  - `IMG_1234` -> `IMG_1234(1).jpg`
  - next output -> `IMG_1234(2).jpg`
  - repeated processing no longer produces nested names such as
    `IMG_1234(1)(1)`
- iOS MVP `设为生效` now writes the current four-region single-line Content
  Builder result into the shared active Template configuration used by the
  Share Extension snapshot reader.
- MVP token chips still display preview/example values in the editor, but the
  saved configuration stores renderer-readable tokens such as:
  - `{{model}}`
  - `{{capture_date_short}}`
  - `{{capture_time_short}}`
  - `{{camera_summary}}`
  - `{{anchor_age_text}}`
- The apply state now returns to `有未生效修改` when users edit region content or
  the time-anchor date, then reads `已生效` after saving the current
  configuration.
- The iOS MVP Profile control now keeps the right side to `保存` plus a compact
  reset icon. Selecting another Preset opens a native confirmation dialog so
  users can choose whether to save that selected Preset as the active Share
  processing configuration.
- Time Anchor is now part of the MVP saved configuration:
  - saving the MVP configuration creates or updates the active birthday Anchor
  - the saved Anchor is selected through shared editor state
  - Share Extension snapshot loading can resolve `{{anchor_age_text}}` from the
    real saved Anchor instead of the MVP-only preview date
- Logo and output target are now included in the same MVP save action:
  - Apple Logo saves as the Apple badge
  - output target writes shared album selection metadata
- The module picker was moved from a custom overlay into a native iOS sheet with
  medium/large detents and list rows. Selecting a row immediately inserts the
  information into the active region.
- User-facing MVP language was reduced:
  - removed visible mock/test/UI-only wording from the MVP page
  - `Token` is now expressed as `插入信息`
  - output notes now describe the intended photo-save behavior
- iOS module token mapping now has one source of truth in
  `PhotoMemoiOSModuleCatalog.rendererToken`; the MVP page no longer maintains a
  second renderer-token switch.
- Export metadata behavior remains aligned with the MVP rule: source metadata
  is carried forward, while output pixel dimensions are rewritten to the new
  rendered canvas size.

Current MVP gap review after this slice:

- closed: original photo is not modified; generated output is a new image
- closed: output canvas keeps original width and extends downward through the
  existing renderer/export path
- closed: output metadata updates pixel dimensions while preserving useful
  source metadata
- closed: output file naming uses original base name plus `(1)`, `(2)`, ...
- closed: MVP four-region single-line configuration can be made active for
  Share Extension processing
- still open: real device manual share-sheet verification from Apple Photos
- still open: final real EXIF token display should be visually reviewed against
  multiple source photos after share processing
- still open: `smart time` in MVP maps to the existing anchor token path; the
  birthday picker is still not a full persisted Memory Engine anchor editor

Verification:

- passed `PhotoMemoTests/PhotoFileNameResolverTests`
- passed `PhotoMemoiOSMVP` Debug iOS Simulator build on `iPhone 17 Pro, iOS 26.4`
- passed `PhotoMemoiOS` Debug iOS Simulator build on `iPhone 17 Pro, iOS 26.4`
- passed `PhotoMemoShareExtension` Debug iOS Simulator build
- passed `PhotoMemo` Debug macOS build
- passed `PhotoMemoiOSMVP` Debug iOS Simulator build after the Profile
  save/reset interaction revision
- passed `PhotoMemoiOSMVP` Debug iOS Simulator build after Time Anchor
  persistence and native module-sheet revisions
- passed `PhotoMemoiOS` Debug iOS Simulator build after Time Anchor
  persistence and native module-sheet revisions
- passed `PhotoMemoShareExtension` Debug iOS Simulator build after Time Anchor
  persistence and native module-sheet revisions
- passed `git diff --check`

## 2026-06-28 Apple First-Party UI Polish

This slice polishes the Configuration Center and iOS MVP surfaces toward an
Apple first-party application feel without changing product behavior or
architecture.

Design direction:

- Preview remains the visual anchor.
- Surrounding controls become quieter and more content-supportive.
- Surfaces use system colors instead of custom decorative RGB palettes.
- Radius, spacing, hairlines, and shadows now follow shared
  `ConfigurationUI` tokens.
- Buttons and icons use lower visual weight unless they are active selection
  feedback.
- The iOS MVP page presents the preview before profile controls so the memory
  card remains the first thing users read.

Files changed:

- `Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Components/InspectorSectionView.swift`
- `Source/PhotoMemo/PhotoMemo/ConfigurationCenter/MemoryCard/InteractiveMemoryCard.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSMVPTestView.swift`

No Renderer, Metadata, Export, Share Extension behavior, Photo Library
behavior, Layout Engine, or Memory Engine runtime work changed in this slice.

Verification:

- passed `git diff --check`
- passed `PhotoMemo` Debug macOS build
- passed `PhotoMemoiOS` Debug iOS Simulator build on `iPhone 17 Pro, iOS 26.4`
- passed `PhotoMemoiOSMVP` Debug iOS Simulator build on `iPhone 17 Pro, iOS 26.4`
- passed `PhotoMemoShareExtension` Debug iOS Simulator build

## 2026-06-28 MVP Single-Line Content Builder Refinement

This slice adjusts the iOS MVP page after the latest MVP boundary decision:
the page remains a configuration surface, keeps the memory/time-anchor line,
and moves the four custom regions to a single-line shared Content Builder.

What changed:

- kept `记忆档案`, `时间锚点`, smart-time display, output, and write-memory
  configuration visible in the MVP page
- changed each of the four custom regions from a two-part editor to a
  single-line builder
- introduced `MVPContentItem` as the local item model for:
  - Text
  - Token
  - Separator
  - Line Break, reserved for future use while the current MVP stays single-line
- token and separator chips now append into the same single-line output string
- the MVP preset action now reads as `设为生效`, matching the future Share
  automatic-processing path

Still deferred:

- Share intake reading the active MVP configuration
- replacing current MVP mock token values with real EXIF-backed token values
- persistent MVP preset storage

Verification:

- passed `git diff --check`
- passed `PhotoMemoiOSMVP` Debug iOS Simulator build on `iPhone 17 Pro, iOS 26.4`
- passed `PhotoMemoiOS` Debug iOS Simulator build on `iPhone 17 Pro, iOS 26.4`

## 2026-06-28 Compact White Information Bar Correction

This slice corrects the bottom-border preview direction after measuring paired
reference outputs and source photos. The current target for the provided
reference images is now the compact two-column white information bar, not the
PM-004 document-style A/B/C/D large Memory Block layout.

What changed:

- added measured `CompactInformationBar` constants in `RendererConstants` for:
  - portrait bar height: `W * 0.1660`
  - landscape bar height: `W * 0.1266`
  - fixed left/right text anchors
  - fixed Logo / divider anchors
  - primary and secondary typography ratios
  - single-line capture-summary behavior
- macOS `InteractiveMemoryCard` preview now renders:
  - scaled Photo Area
  - compact Information Bar
  - left column: Slot A + Slot B
  - center: Logo 标识 + divider
  - right column: Slot C + Slot D
- iOS MVP preview now uses the same compact scaled output card.
- iOS Configuration Center preview now uses the same compact scaled output card.
- `ImmersWhiteRenderer` now points its color tokens at the compact information
  bar constants while preserving its existing measured output geometry.
- locked the text-region mapping from Configuration Center custom regions to
  compact border positions and renderer text areas:
  - Slot A / 记录 -> left primary -> `CardTextArea.leftTop`
  - Slot B / 时间线 -> left secondary -> `CardTextArea.leftBottom`
  - Slot C / 拍摄参数 -> right primary -> `CardTextArea.rightTop`
  - Slot D / 记忆 -> right secondary -> `CardTextArea.rightBottom`
- Slot C wording is now narrowed from broad context language to capture
  parameters so the right-primary border slot remains a four-fact capture
  summary.

Verification:

- passed `PhotoMemo` Debug macOS build
- passed `PhotoMemoiOS` Debug iOS Simulator build on `iPhone 17 Pro, iOS 26.4`
- passed `PhotoMemoiOSMVP` Debug iOS Simulator build on `iPhone 17 Pro, iOS 26.4`
- passed `PhotoMemoTests/RendererConstantsTests`
- passed `git diff --check`

Not yet manually verified:

- visual screenshot comparison inside the running macOS app
- visual screenshot comparison inside iOS Simulator
- full export golden-image comparison against the provided reference samples

## 2026-06-28 PM-004 Border Preview Foundation

This slice starts the PM-004 border rendering foundation from the Atlas-derived
specification, but keeps the real export renderer migration for a later reviewed
renderer slice.

What changed:

- added `RendererConstants` as the first PM-004 engineering entry point for:
  - 8pt grid tokens
  - PM-004 typography tokens
  - document / information-bar colors
  - border geometry ratios
  - slot anchor coordinates in the 0-100% information-bar coordinate system
  - Capture Summary's four allowed facts
- updated the macOS `InteractiveMemoryCard` preview so the bottom card now uses:
  - `Photo Area`
  - `Information Bar`
  - Slot A / B / C on the top row
  - Slot D as the larger lower-left Memory Block
  - Badge in the lower-right reserved decoration slot
- updated the iOS MVP test preview to use the same PM-004 slot coordinates instead
  of the previous equal-column bottom bar.
- Capture Summary in the preview is now constrained to four facts:
  - focal length
  - aperture
  - ISO
  - shutter speed

Current bottom-border code map:

- PM-004 constants:
  - `Source/PhotoMemo/PhotoMemo/Renderers/RendererConstants.swift`
- macOS Configuration Center preview:
  - `Source/PhotoMemo/PhotoMemo/ConfigurationCenter/MemoryCard/InteractiveMemoryCard.swift`
- iOS MVP preview:
  - `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSMVPTestView.swift`
- current real export renderer path, not migrated in this slice:
  - `Source/PhotoMemo/PhotoMemo/Renderers/ImmersWhiteRenderer.swift`
  - `Source/PhotoMemo/PhotoMemo/Renderers/ClassicWhiteCardRenderer.swift`
  - `Source/PhotoMemo/PhotoMemo/Renderers/ClassicWhiteRenderer.swift`
  - `Source/PhotoMemo/PhotoMemo/Services/RecordCardExportService.swift`
- legacy preview/export support paths still relevant for audit:
  - `Source/PhotoMemo/PhotoMemo/Views/Preview/RecordCardPreview.swift`
  - `Source/PhotoMemo/PhotoMemo/Views/Preview/InfoBarPreview.swift`
  - `Source/PhotoMemo/PhotoMemo/Models/Template.swift`
  - `Source/PhotoMemo/PhotoMemo/Models/TemplateArea.swift`
  - `Source/PhotoMemo/PhotoMemo/Engines/CardTextBlockEngine.swift`

Verification:

- passed `PhotoMemoTests/RendererConstantsTests`
- passed `PhotoMemoiOSMVP` Debug iOS Simulator build
- passed `PhotoMemo` Debug macOS build with separate PM-004 DerivedData
- passed `git diff --check`

Not yet manually verified:

- on-device visual review of the iOS MVP preview
- macOS runtime click/hover review for all card regions after the PM-004 preview
  remap
- real rendered/exported image parity, because `ImmersWhiteRenderer` and
  `ClassicWhiteRenderer` have not yet been migrated to PM-004 constants

## 2026-06-26 iOS MVP Test Module Scaffold

This slice adds an iOS-only MVP test path for phone-side interaction validation without changing the frozen IA-002 Configuration Center architecture.

What changed:

- added a fully separate iPhone MVP app target:
  - `PhotoMemoiOSMVP`
  - bundle id `com.serydoo.PhotoMemo.iOS.MVP`
  - shared scheme `PhotoMemoiOSMVP`
- added a temporary iOS root entry switcher with:
  - `当前配置中心`
  - `MVP 测试页`
- added a dedicated iOS MVP test view that reuses:
  - `ConfigurationSession`
  - current mock preview text
  - current module enumeration
- the standalone MVP app now defaults to `MVP 测试页` while keeping its own entry-switch persistence separate from the existing `PhotoMemoiOS` app
- added a shared iOS module catalog so the existing iOS Configuration Center and the MVP test page use one module definition source
- the MVP test page now includes:
  - a Profile area for preset selection, apply/default/reset actions, and current memory-subject summary
  - a sticky white-bottom-bar Memory Card preview
  - four simplified editors for `记录`, `时间线`, `上下文`, and `记忆`
  - real-time preview refresh as each editor changes
  - a module insertion overlay sized for phone interaction
  - `Logo 标识` switching between the default Apple mini-logo and a custom-upload placeholder
  - a `途途生日` date input
  - UI-only output options
  - UI-only write-memory controls and preview
- scrolling behavior now follows the MVP test direction:
  - Profile scrolls away with content
  - Preview remains visible at the top
  - the custom editing area fades in under the preview as the user scrolls upward
- `CaptureTimeResolver` now exposes formatted smart-time text for the mock capture-date minus `途途生日` case:
  - default format `X年X个月X天`
  - omits the year when the difference is below one year
  - falls back to `X天` when needed
- added focused tests for the smart-time formatter

Still mock-only:

- no Renderer integration
- no Metadata pipeline integration
- no Export integration
- no real Photo Library write behavior
- no Layout Engine changes
- no real Memory Engine runtime data binding yet

Verification:

- passed `PhotoMemoTests/CaptureTimeResolverTests`
- passed `PhotoMemoiOS` Debug iOS Simulator build
- passed `PhotoMemoiOS` Debug connected-device build
- installed `PhotoMemoiOS` on the connected iPhone
- launched `com.serydoo.PhotoMemo.iOS` on the connected iPhone
- passed `PhotoMemoiOSMVP` Debug iOS Simulator build
- passed `PhotoMemoiOSMVP` Debug connected-device build
- Xcode generated a Development provisioning profile for `com.serydoo.PhotoMemo.iOS.MVP`
- installed `PhotoMemoiOSMVP` on the connected iPhone
- automatic launch of `com.serydoo.PhotoMemo.iOS.MVP` was blocked because the device was locked

## 2026-06-25 iOS Compact Profile And Module Library Refinement

This slice is iOS-only UI refinement and keeps the frozen IA-002 architecture intact.

What changed:

- the iOS navigation title now reads `PhotoMemo 配置中心`
- the top profile area is compressed into a two-row layout:
  - row 1: memory preset menu, rename, reset, save-and-apply state
  - row 2: automatic output summary
- region configuration editing now separates active state from save action:
  - top status uses `已生效`
  - the save button remains `保存配置 / 已保存`
- custom region editing now keeps literal text, inserted module chips, and continuation text in one editing container
- inserted module chips use a horizontal token strip so multiple modules can be appended without wrapping the field vertically
- the insertable module library now:
  - shows 6 common modules by default
  - exposes remaining modules through a `更多模块` menu
  - leaves unavailable EXIF-derived module values blank instead of generating mock values
- the iOS Library sidebar now exposes placeholder add actions:
  - `新增人物`
  - `新增事件`
- the previous `旅行` group label is generalized to `事件`

Still mock-only:

- add actions are UI placeholders
- module availability does not call the real metadata pipeline
- no Renderer, Metadata, Export, Share Extension behavior, Photo Library behavior, Layout Engine, or real Memory Engine runtime work was changed

Verification:

- passed `git diff --check`
- passed `PhotoMemoiOS` Debug iOS Simulator build
- passed `PhotoMemoiOS` Debug connected-device build
- installed and launched `PhotoMemoiOS` on the connected iPhone

## 2026-06-25 iOS Two-Column Configuration Center Polish

This slice continues the iOS Configuration Center polish and keeps the frozen IA-002 architecture intact.

What changed:

- iOS now uses a two-column Configuration Center shell with:
  - a Mail-style left Library sidebar
  - a right detail surface for profile, subject, card preview, inspector, output, and guidance
- the right surface now keeps a compact `总体配置` panel at the top
- the top profile area now supports:
  - preset selection
  - rename
  - reset
  - save-and-apply state
- the center card preview remains mock-first and still mirrors the macOS memory-card structure
- the right-side subject area stays inline inside the detail surface rather than opening a sheet
- the card-region preview, insertable module library, write-memory panel, and output panel remain mock UI only

Also updated on macOS:

- the top Memory Card context now presents the overall configuration as `总体配置`
- the same preset can now be reset or saved-and-applied from the center card context

No Renderer, Metadata, Export, Share Extension behavior, Photo Library behavior, Layout Engine, or real Memory Engine runtime work was changed.

Verification:

- passed `git diff --check`
- passed `xcodebuild` for `PhotoMemoiOS` on the iOS Simulator destination
- passed `xcodebuild` for `PhotoMemo` on macOS
- passed `xcodebuild` for `PhotoMemoiOS` on the connected device destination
- installed `PhotoMemoiOS` on the connected device
- launch was blocked because the device was locked

## 2026-06-25 iOS Preview-First Configuration Refinement

This slice is iOS-only UI refinement and keeps macOS Configuration Center behavior unchanged.

What changed:

- compressed the iOS `总体配置` area into a thin top toolbar
- expanded the `当前配置预览` area so the Memory Card Preview has stronger first-visual priority
- moved the Library sidebar content downward and compressed row height
- removed the iOS `当前配置展示` entry from the left sidebar
- moved `配置说明` into a separate lower-priority sidebar group instead of grouping it with Output
- removed the module-insertion area when the selected card region is non-text, such as the icon region
- replaced direct macOS Object Inspector reuse in card text regions with an iOS-specific lightweight region composer
- text regions now support:
  - free-form input
  - inserted module chips
  - module deletion
  - immediate preview refresh
- only the Memory region shows a compact system-module strip; Recorder, Timeline, and Context use the simpler configuration-window model

Still mock-only:

- inserted module chips update the Configuration Center preview state only
- no Renderer, Metadata, Export, Share Extension behavior, Photo Library behavior, Layout Engine, or real Memory Engine runtime work was changed

Verification:

- passed `git diff --check`
- passed `PhotoMemoiOS` Debug iOS Simulator build
- passed `PhotoMemo` Debug macOS build
- passed `PhotoMemoiOS` Debug connected-device build
- installed and launched `PhotoMemoiOS` on the connected iPhone

Memory Engine is now a first-class architecture module. Renderer is no longer allowed to be the source of layout truth. Future layout work must be researched, specified, measured, and owned by a Layout Engine before renderer implementation.

## 2026-06-25 iOS Configuration Center Polish Shell

This slice starts iOS-specific Configuration Center polishing without changing the frozen IA-002 architecture.

What changed:

- added an iOS-only `ConfigurationCenteriOSView`
- routed the iOS app root to the new iOS shell while macOS still uses `ConfigurationCenterView`
- introduced a wide iOS / iPad layout with:
  - left control column for Subject, Block Configuration, Content Library, Output, and 写入记忆
  - right preview column for Profile selection, 保存并生效, and 当前配置预览
- added a Subject profile sheet for lightweight mock editing:
  - object definition
  - display name choice
  - time anchors
- kept all behavior mock-first and UI-only

No Renderer, Metadata, Export, Share Extension, Photo Library behavior, Layout Engine, or real Memory Engine runtime behavior was changed.

## 2026-06-24 IA-002 Frozen And IA-003 Product Realization

IA-002 is now complete at the architecture level.

Frozen IA-002 areas:

- Configuration Center
- Library
- Interactive Memory Card
- Object Inspector
- CardRegion
- InspectorProvider
- TokenLibrary
- MemoryBlock
- DecorationAsset
- Configuration Snapshot
- Region Strip as Memory Card Navigation

Frozen foundation principles:

- Configuration Center edits Objects, not Data.
- Everything starts from the Memory Card.
- Configuration Center previews the real Memory Card, not an abstract layout.
- Preview is the Renderer before Rendering.
- Capture-Time Principle.
- Memory Subject = Identity + MemoryBehavior.

PhotoMemo now moves from:

```text
Product Definition
-> Product Realization
```

Next implementation track:

```text
IA-003 Memory Engine Integration
```

Approved IA-003 order:

```text
IA-003A MemorySubject Adapter
-> IA-003B Configuration Snapshot
-> IA-003C Memory Block Resolver
-> IA-003D CaptureTimeResolver
-> IA-003E Interactive Memory Card connects real data
-> IA-003F Renderer
```

IA-003A is the next allowed implementation slice. It should connect existing personal/profile configuration into `MemorySubject` and must not modify Renderer, Metadata, Export, Share Extension, Photo Library behavior, or Layout Engine work.

## 2026-06-24 Memory Card Preview Polish Amendment

The center surface is now defined as Memory Card Preview.

Frozen principle:

```text
Preview is the Renderer before Rendering.
```

Meaning:

- Photos belong to Apple Photos.
- PhotoMemo owns the Memory Card.
- The center area should not show a photo placeholder, abstract layout, or editor grid.
- Memory Card Preview should look like an already-generated Memory Card.
- Hover, selection, and Region Strip reveal editability only when needed.

UI polish in this slice:

- removed the gray center background from `InteractiveMemoryCard`
- weakened the Memory Card border and shadow
- removed the bottom-slot gray panel feel
- reduced default region boundary contrast
- kept hover, selection, Object Inspector routing, and Region Strip behavior unchanged

## 2026-06-24 Bottom Card Slot Preview Local Revision

This slice keeps Library and Object Inspector unchanged.

Only the center `InteractiveMemoryCard` presentation was revised.

What changed:

- changed Memory Card Preview from a tall card into a horizontal bottom-card information window
- modeled the four slot areas after the existing output-card structure:
  - Slot A: Recorder
  - Slot B: Timeline
  - Slot C: Location / photo facts
  - Slot D: Memory
- kept the center Apple decoration region clickable through `CardRegion.icon`
- preserved Region Strip selection
- preserved `CardRegion -> Object Inspector` routing
- updated `CardRegion` semantic labels so Slot B is Timeline, Slot C is Location, and Slot D is Memory

No Renderer, Metadata, Export, Share Extension, Photo Library behavior, or real Memory Engine runtime behavior was changed.

## 2026-06-24 PDR-005 Memory Language Layer

This slice is a repository amendment only.

No Swift, Renderer, Metadata, Export, Share Extension, Photo Library behavior, Layout Engine, or Memory Engine runtime work was changed.

New source of truth:

- `Docs/PDR/PDR-005_Memory_Language_Layer.md`

Frozen decisions:

- MemoryBlock is a content asset, not a layout asset.
- MemoryBlock must not be permanently shaped by Slot A / Slot B / Slot C / Slot D.
- The long-term MemoryBlock model is field-based:

```text
MemoryBlock
-> BlockField
-> Value Source
```

- `Subject + Action + Result` is frozen as:

```text
Preset Schema #001
Narrative Memory Block
```

- BlockField values may come from:
  - Fixed Text
  - Token Binding
  - Smart Module Binding
  - Custom Field Binding
- Modules calculate field values; they do not define the whole MemoryBlock.
- Block Templates define field schemas, not slot positions.
- IA-003A remains MemorySubject Adapter.
- The first implementation point for PDR-005 is IA-003C Memory Block Resolver.

## 2026-06-24 Memory Block Inspector Prototype

This slice implements the first mock-only Object Inspector structure for PDR-005.

What changed:

- Slot regions now use `MemoryBlockInspectorView` instead of the old generic expression editor.
- The right Inspector now follows:

```text
Overview
-> Memory Block Template
-> Fields
-> Value Binding
-> Resolved Result
-> Behavior
```

- Recorder, Timeline, Context, and Memory each have their own mock Block Template and editable fields.
- Field values can be edited locally inside the Inspector.
- Resolved Result updates inside the Inspector.
- Slot C is now labeled Context because it owns photo context such as camera parameters and location.

Still mock-only:

- field edits do not yet write back into Memory Card Preview
- no Renderer, Metadata, Export, Share Extension, Photo Library behavior, Layout Engine, or real Memory Engine runtime work was changed

## 2026-06-24 Memory Block Custom Fields Module Insertion

This slice refines the right Object Inspector for the four Memory Card regions.

What changed:

- added a `Custom Fields` section with `Add Field`
- selecting a custom field makes it the insertion target
- clicking a module chip inserts that module token into the selected custom field
- if no custom field is selected, module insertion creates one automatically
- added a unified module library below the four region inspectors:
  - Photo Facts
  - Memory
  - System
- Recorder, Timeline, Context, and Memory keep system-derived values read-only in the Inspector
- Memory Subject values now map from the selected subject nickname / short name
- custom fields can be reordered with lightweight up/down controls as the first placeholder for future drag sorting

Still mock-only:

- module chips expose normalized token names but do not yet call the real metadata pipeline
- custom fields are local Inspector state and do not yet persist into Configuration Snapshot
- no Renderer, Metadata, Export, Share Extension, Photo Library behavior, Layout Engine, or real Memory Engine runtime work was changed

## 2026-06-24 Configuration Inspector Feedback Refinement

This slice applies the first visual review feedback to the Configuration Center Inspector.

What changed:

- user-facing Configuration Center labels were localized to Chinese while Swift type names and internal tokens stayed unchanged
- Memory Subject Inspector removed the visible Reference Date field
- Definition and note fields now start as compact one-line vertical text fields and expand as needed
- Custom Time editing now exposes an edit / complete button beside the time dropdown
- Recorder no longer maps from Memory Subject and no longer generates photo-taking wording
- Recorder now defaults to a single user-owned custom field
- Context defaults to one read-only capture-parameters summary module
- module insertion no longer exposes raw `{{token}}` strings in the editing UI
- inserted modules now appear as light Apple-style token blocks
- Custom Fields now support:
  - selection
  - confirmation state
  - deletion
  - clearer up/down ordering controls

Still mock-only:

- Custom Fields remain local Inspector state
- module tokens keep internal identifiers for future resolver work, but no real metadata resolver is called
- no Renderer, Metadata, Export, Share Extension, Photo Library behavior, Layout Engine, or real Memory Engine runtime work was changed

## 2026-06-24 Live Preview And Smart Time Module Prototype

This slice closes the first editing feedback loop between Object Inspector and Memory Card Preview.

What changed:

- added shared preview text state to `ConfigurationSession`
- Memory Card Preview now reads region text from the shared session state
- Recorder, Timeline, Context, and Memory edits can update the center preview immediately
- default system modules can be deleted from the Inspector
- deleting a default system module allows the region preview to become empty instead of falling back to the default
- Custom Field edits now sync to the center preview while typing, inserting, confirming, deleting, or reordering
- added a mock `智能时间结果` module
- `智能时间结果` uses the selected Memory Subject time anchor and a mock capture date to produce a readable result such as `2岁1个月6天`
- Memory Expression is now prepared for Block composition through user-owned custom fields plus insertable modules

Still mock-only:

- the mock capture date is fixed in Configuration Center UI code
- the smart time calculation is a prototype for IA-003C Memory Block Resolver
- no real EXIF, Metadata Pipeline, Renderer, Export, Share Extension, Photo Library behavior, Layout Engine, or Memory Engine runtime work was changed

## 2026-06-24 Configuration Inspector Inline Composition Refinement

This slice applies the latest Configuration Center editing feedback.

What changed:

- added a live current-configuration context above the center Memory Card Preview
- the context label follows the selected Memory Subject display name and selected custom time anchor
- Memory Subject draft edits now update the Configuration Session live before the save button is pressed
- blank-area taps in the active Inspector clear text-field focus
- Custom Fields were simplified into user-owned content blocks:
  - no separate field-name input
  - one editable content container per block
  - inserted modules appear as inline Apple-style chips inside the same container
  - each inserted module chip can be removed individually
  - custom content blocks can be reordered with visible up/down controls and drag/drop
- Memory Card Preview continues to refresh while content is typed, modules are inserted or removed, and block order changes

Still mock-only:

- inline modules are local Configuration Center draft objects
- drag/drop ordering is an Inspector prototype for later MemoryBlock resolver work
- no real EXIF, Metadata Pipeline, Renderer, Export, Share Extension, Photo Library behavior, Layout Engine, or Memory Engine runtime work was changed

## 2026-06-24 Apple-Native Configuration Center Polish

This slice refines the existing Configuration Center without changing IA-002 architecture.

What changed:

- introduced shared Configuration Center visual primitives for:
  - app background
  - panel background
  - control background
  - selected / hover states
  - hairline borders
  - field chrome
- refined the three-column shell so the center and Inspector read as one macOS-style tool window
- upgraded the Library sidebar with quieter selected rows, stronger hierarchy, and lighter bottom context
- refined Memory Card Preview:
  - current-configuration context is now a compact status panel
  - card surface uses a softer white panel treatment
  - Region Strip is lighter and more toolbar-like
  - hover and selection styling now share the same visual system
- refined Object Inspector:
  - header now behaves like an object status row
  - selected region uses a matching SF Symbol
  - section spacing and panel styling are more restrained
- refined Memory Block / Token editing:
  - system rows, custom content blocks, and resolved preview now share panel styling
  - inserted modules and library tokens use a lighter Apple-token style
  - decoration library tiles now use the shared panel style

Still mock-only:

- this is UI polish only
- no Renderer, Metadata Pipeline, Export, Share Extension, Photo Library behavior, Layout Engine, or Memory Engine runtime work was changed
- IA-002 `Library -> Interactive Memory Card -> Object Inspector` remains unchanged

## 2026-06-24 Region Configuration Slots Refinement

This slice continues Configuration Center UI refinement based on visual review feedback.

What changed:

- Memory Block Inspector now treats each card region as having three local configuration slots.
- Each slot can be selected from the region configuration picker:
  - Recorder: `配置 1：记录者信息`, `配置 2：自定义记录`, `配置 3：自定义记录`
  - Timeline: `配置 1：拍摄时间`, `配置 2：日期`, `配置 3：自定义时间线`
  - Context: `配置 1：拍摄参数概要`, `配置 2：位置`, `配置 3：自定义上下文`
  - Memory: `配置 1：当天多大`, `配置 2：自定义记忆`, `配置 3：自定义记忆`
- Recorder configuration 1 now includes a default device-model module:
  - `拍摄设备型号`
- Default system modules remain removable.
- Custom content is now stored per local configuration slot, so switching configuration slots does not overwrite another slot's draft content.
- The old default `动态字段` memory configuration was removed from the Memory region.
- Secondary Inspector sections now collapse by default:
  - Insert Module
  - Current Output
  - Behavior
- Memory Card Preview is slightly larger and the center decoration is visually quieter.
- Library row spacing was lightly compressed.

Still mock-only:

- region configuration slots are local Configuration Center draft state
- save / rename controls are UI-level preparation for the future Configuration Snapshot flow
- no Renderer, Metadata Pipeline, Export, Share Extension, Photo Library behavior, Layout Engine, or Memory Engine runtime work was changed

## 2026-06-24 Time Anchor Language Polish

This slice refines the Configuration Center language around Memory Subject time anchors.

What changed:

- Center Memory Card context now shows:
  - `时间锚点`
  - the selected anchor description, such as `图图出生日期`
- The center context deliberately does not mention capture time because real photo time is not connected in this UI slice.
- The right Memory Subject Inspector now labels the former custom-time area as `时间锚点`.
- The per-anchor note field is now presented as `锚点说明`.
- `锚点说明` is used as the short text shown in the center context.
- The Library sidebar now explains, in concise Apple-style language, that different memory objects can have different time anchors and different memory angles.
- Mock anchor descriptions were shortened so they read as display strings rather than long notes.

Still mock-only:

- anchor descriptions remain Configuration Center draft data
- no real capture-time, EXIF, Metadata Pipeline, Renderer, Export, Share Extension, Photo Library behavior, Layout Engine, or Memory Engine runtime work was changed

## 2026-06-24 Memory Preset Activation Prototype

This slice introduces `记忆预设` as the active region-configuration combination in the Configuration Center.

What changed:

- Center Memory Card context now shows:
  - `记忆预设`
  - `时间锚点`
- `记忆预设` has three mock options:
  - `成长记录`
  - `第一次旅行`
  - `自定义预设`
- Selecting a memory preset updates the active configuration for Recorder, Timeline, Context, and Memory.
- The right Memory Block Inspector now reads and writes the selected region configuration through the current memory preset.
- The active region configuration displays a light `当前记忆预设使用中` status chip.
- Memory preset names can be renamed from the center context without opening a separate settings surface.

Still mock-only:

- memory presets remain Configuration Center draft state
- preset switching uses mock region-template mappings
- no real Configuration Snapshot, Renderer, Metadata Pipeline, Export, Share Extension, Photo Library behavior, Layout Engine, or Memory Engine runtime work was changed

## 2026-06-24 Center Component Dock Prototype

This slice moves shared editing components from the bottom of the right Inspector into the center Memory Card area.

What changed:

- Center Memory Card area now includes a lower `Configuration Component Dock`.
- The dock contains:
  - insertable module chips
  - current configuration display for the selected region
  - output selection
  - compact configuration / about guidance
- Output selection defaults to:
  - `处理过的图片`
- Output storage now presents:
  - `PhotoMemo 文件夹`
  - `现有文件夹`
  - `新建文件夹`
  - `目标相册`
- If no custom storage destination is selected, the UI describes the default PhotoMemo folder behavior.
- The guidance style follows the previous iOS help-center language pattern:
  - grouped title
  - compact white explanation card
  - short secondary description
- The right Object Inspector no longer shows the old `插入模块`, `当前输出`, and `行为` tail sections for Memory Block regions.
- Inserting a dock module appends its display value to the currently selected Memory Card region preview.
- Dock module insertion now also broadcasts the module to the right Inspector so the current custom content field shows the inserted module chip.
- The insertable module list now includes a broader set of Apple photo / EXIF-facing fields and records that later ordering should be usage-frequency aware.
- The insertable module list is now compact by default and can be expanded when users need the full EXIF-facing list.
- Right-side custom content fields are now immediate-editing surfaces:
  - the old per-field confirmation button was removed
  - deleting a custom content field is now a larger action beside the editing field
  - saving / confirmation responsibility stays at the upper configuration level

Still mock-only:

- dock module insertion currently updates the live Configuration Center preview only
- output selection is UI state and does not call the export pipeline
- no real Configuration Snapshot, Renderer, Metadata Pipeline, Export, Share Extension, Photo Library behavior, Layout Engine, or Memory Engine runtime work was changed

## 2026-06-24 Write Memory Caption Prototype

This slice adds a mock-only `写入记忆` control to the center Configuration Component Dock.

What changed:

- Added a `写入记忆` panel above insertable modules.
- The default write-memory text uses the generated Memory region output.
- Users can enable `自定义写入内容` and enter their own memory description.
- If custom writing is enabled but the custom field is empty, the UI falls back to the generated Memory region output.
- The panel shows the actual text that would be written.
- User-facing language avoids raw `Caption` terminology and presents this as memory writing for Apple Photos search and review.

Still mock-only:

- this does not write to Apple Photos yet
- future implementation must verify whether Photos-visible captions can be written directly or whether EXIF/IPTC/XMP description fields are required
- no real Configuration Snapshot, Renderer, Metadata Pipeline, Export, Share Extension, Photo Library behavior, Layout Engine, or Memory Engine runtime work was changed

## 2026-06-24 Configuration Center Interaction Freeze

This slice records the accepted Configuration Center baseline after the latest UI review.

New reference:

- `Docs/Configuration/CONFIGURATION_CENTER_INTERACTION_FREEZE.md`

Frozen baseline:

- Library -> Interactive Memory Card -> Object Inspector
- Memory Preset
- Time Anchor
- Region Strip
- Configuration Component Dock
- Write Memory
- Current Configuration Display
- Output storage selection
- immediate right-side custom content editing

Still mock-only:

- this freeze records the interaction baseline only
- it does not connect Renderer, Metadata Pipeline, Export, Share Extension, Photo Library behavior, Layout Engine, or Memory Engine runtime work

## 2026-06-24 Memory Subject Inspector Customization

This slice opens the right-side Object Inspector customization surface for Memory Subject.

What changed:

- `MemorySubject` now carries:
  - definition
  - three mock custom time anchors
  - per-anchor note
- `MemorySubjectEditorView` now supports editing:
  - display name
  - short name
  - relationship role
  - relationship label
  - subject definition
  - reference date
  - custom time anchor title
  - custom time anchor date
  - custom time anchor note
- Time Window now uses a dropdown to choose among custom dates.
- Edit mode unlocks the selected custom time anchor.
- Save writes the edited subject back into `ConfigurationSession`.
- Saving a selected time anchor maps it into:
  - `behavior.primaryAnchor`
  - `referenceDate`

Still mock-only:

- this does not yet persist to `PersonalProfileStore`
- this does not yet connect to real Renderer, Metadata, Export, Share Extension, Photo Library behavior, Layout Engine, or Memory Engine runtime

## 2026-06-24 IA-002C UI Polish Foundation

This slice responds to the first visible PhotoMemo V3 review.

Scope stayed limited to Configuration Center mock UI polish.

No Renderer, Metadata, Export, Share Extension intake logic, Photo Library behavior, Memory Engine runtime behavior, or `PersonalProfile` adapter was changed.

What changed:

- reworked `InteractiveMemoryCard` from a six-region grid into a true Bottom Card composition
- kept all Memory Card interaction routed through `CardRegion`
- made the Memory Card hierarchy favor:
  - Icon
  - Slot D
  - Slot A
  - Slot B
  - Slot C
- changed the center card from dashboard-like blocks toward a final-card preview surface
- upgraded the sidebar into Library with grouped sections:
  - People
  - Travel
  - New Subject
- added `InspectorSectionView` and `InspectorPropertyRow` as first Configuration UI design-system primitives
- changed Object Inspector spacing and heading hierarchy
- changed Memory Subject editing into Overview and Behavior sections
- changed Memory Expression editing into section-based Inspector UI
- changed Apple Tokens from bordered buttons toward inline token chips
- updated Token Library chips to use SF Symbol-backed capsule styling
- changed mock decoration symbols toward consistent SF Symbols:
  - `person.fill`
  - `camera.fill`
  - `location.fill`
  - `flag.fill`
  - `apple.logo`

Verification:

- passed macOS build:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- passed iOS simulator build:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PhotoMemoIOSDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- passed Share Extension build:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoShareExtension -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PhotoMemoShareExtensionDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`

Manual verification note:

- direct app execution from `/tmp/PhotoMemoDerivedData` launched, but Computer Use continued resolving the `PhotoMemo` app name to an older registered bundle path
- LaunchServices inspection should be cleaned up before relying on Computer Use screenshots for PhotoMemo

## 2026-06-24 IA-002C Real Bottom Card Preview Amendment

This slice keeps the existing Library and Object Inspector design from the UI polish checkpoint.

Only the center Interactive Memory Card was redesigned.

No Renderer, Metadata, Export, Share Extension intake logic, Photo Library behavior, Memory Engine runtime behavior, or `PersonalProfile` adapter was changed.

Rollback point before this slice:

```text
ia-002c-ui-polish-checkpoint
0176b29 Checkpoint Configuration Center UI polish
```

What changed:

- froze the principle:

```text
Configuration Center previews the real Memory Card, not an abstract layout.
```

- changed the center card into the real Bottom Card structure:

```text
Decoration
-> Slot A
-> Slot B
-> Slot C + Slot D
```

- Decoration contains Icon and Badge
- Slot A is Recorder
- Slot B is Timeline
- Slot C is Location
- Slot D is Memory Expression
- added Region Strip below the card:

```text
Recorder
Timeline
Location
Memory
```

- Region Strip selects the same `CardRegion` values as clicking the real card regions
- updated:
  - `Docs/PDR/PDR-004_Configuration_Center_Architecture.md`
  - `Docs/FROZEN_REGISTRY.md`
  - `Docs/DESIGN_DECISIONS.md`

## 2026-06-24 Repository Amendment: Configuration Center Architecture Revision A

This slice is a repository amendment, not a development instruction.

No runtime code was changed.

No Swift, SwiftUI, Renderer, Metadata, Export, Share Extension, Photo Library, Memory Engine runtime, or adapter implementation work was introduced.

What changed:

- added `Docs/PDR/PDR-004_Configuration_Center_Architecture.md`
- froze Configuration Center as the Memory Engine Configuration Center
- froze:

```text
Configuration Center edits Objects, not Data.
```

- froze:

```text
Everything starts from the Memory Card.
```

- froze the Configuration Center layout:

```text
Library
-> Interactive Memory Card
-> Object Inspector
```

- froze Library as Memory Object Library
- froze Interactive Memory Card as the primary object
- froze Object Inspector as the selected-object inspection surface
- froze `CardRegion` as `subject`, `icon`, `badge`, `slotA`, `slotB`, `slotC`, `slotD`
- froze `InspectorProvider` routing
- froze `MemorySubject -> Identity + MemoryBehavior`
- froze `MemoryExpression -> MemoryTextBlock + MemoryTokenBlock`
- froze `TokenCategory` as Memory / Photo / System
- froze `DecorationAsset` as the unified Icon / Badge / future Decoration abstraction
- froze lightweight `ConfigurationSession`
- froze Capture-Time Principle
- established PhotoMemo Design System as a required future Configuration UI foundation
- updated:
  - `PROJECT_CONSTITUTION.md`
  - `Docs/MASTER_PLAN.md`
  - `README.md`
  - `AI_CONTEXT.md`
  - `AGENTS.md`
  - `Docs/PDR/PDR_INDEX.md`
  - `Docs/FROZEN_REGISTRY.md`
  - `Docs/DESIGN_DECISIONS.md`
  - `Docs/Configuration/CONFIGURATION_MODEL.md`
  - `Docs/REPOSITORY_VOCABULARY.md`
  - `Docs/NEVER_BREAK.md`
  - `Docs/DOCUMENT_INDEX.md`

Historical next sprint at the time was:

```text
IA-002C Object Inspector
```

This has since been superseded by the IA-002 freeze recorded above.

Historical follow-up at the time was:

```text
IA-002D MemorySubject Adapter
```

Verification:

- repository amendment reviewed against current source-of-truth documents
- `git diff --check` passed
- no build was run because this slice is documentation-only

## 2026-06-24 Sprint IA-002B Interactive Memory Card

This slice continues Configuration Center UI architecture only.

Scope stayed limited to mock Configuration Center state and SwiftUI interaction architecture.

No Renderer, Metadata, Export, Share Extension intake logic, Photo Library behavior, Memory Engine runtime behavior, or `PersonalProfile` adapter was changed.

What changed:

- made `CardRegion` the frozen interaction coordinate for:
  - `subject`
  - `icon`
  - `badge`
  - `slotA`
  - `slotB`
  - `slotC`
  - `slotD`
- added `CardRegionBehavior` so card interaction now flows through:

```text
CardRegion
-> CardRegionBehavior
-> CardSelection
-> InspectorProvider
```

- expanded `CardSelection` to carry selected and hovered regions
- added accessibility identifiers and labels for card regions
- replaced the core `InspectorView` region switch with `InspectorProvider`
- added Inspector transition animation for region changes
- made `InteractiveMemoryCard` regions clickable, hoverable, selected, lightly highlighted, and accessibility-addressable
- split memory expression blocks into:
  - `MemoryTextBlock`
  - `MemoryTokenBlock`
  - `MemoryBlock`
- added `TokenCategory` for Memory / Photo / System token grouping
- updated `TokenLibrary` and `TokenPicker` to use `TokenCategory`
- added `MemoryBehavior`
- moved Memory Subject behavior fields under `MemorySubject.behavior`:
  - Primary Anchor
  - Icon Strategy
  - Badge Strategy
  - Memory Expression

IA-002B decisions reflected in code:

- Everything in Configuration Center starts from the Memory Card.
- The Memory Card is now the central navigation object, not a static preview.
- Future card region hover, selection, Inspector routing, and accessibility should use `CardRegion`.
- `ConfigurationSession` remains lightweight and only owns selection, hover, and mock expression/decorations editing.
- Identity and behavior are separated in `MemorySubject`.

Verification:

- passed macOS build:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- passed iOS simulator build:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PhotoMemoIOSDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- passed Share Extension build:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoShareExtension -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PhotoMemoShareExtensionDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- passed:
  - `git diff --check`

Not yet manually verified:

- running app click-through of every Memory Card region
- visual hover behavior on a physical pointer device
- VoiceOver traversal of the new region accessibility labels

## 2026-06-24 Sprint IA-002A Configuration Center Skeleton

This slice starts PhotoMemo V3 Configuration Center UI development.

Scope stayed limited to architecture skeleton and mock data.

No Renderer, Metadata, Export, Share Extension intake logic, or Memory Engine runtime behavior was changed.

What changed:

- added a new `ConfigurationCenter/` SwiftUI surface with `Sidebar`, `MemoryCard`, `Inspector`, `Editors`, `Components`, and `Models`
- added skeleton domain types:
  - `MemorySubject`
  - `MemoryBlock`
  - `MemoryBlockType`
  - `MemoryBlockLibrary`
  - `MemoryExpression`
  - `TokenLibrary`
  - `DecorationAsset`
  - `DecorationKind`
  - `ConfigurationSnapshot`
  - `CaptureTimeResolver`
  - `CardRegion`
  - `CardSelection`
  - `InteractiveMemoryCardSelection`
- added `ConfigurationSession` and `ConfigurationCenterState` with mock data only
- added a three-column `NavigationSplitView`:
  - left: `MemorySubjectListView`
  - center: `InteractiveMemoryCard`
  - right: `InspectorView`
- added skeleton editors:
  - `MemorySubjectEditorView`
  - `ExpressionEditor`
  - `TokenPicker`
  - `IconLibraryView`
  - `BadgeLibraryView`
- changed `PhotoMemoRootSceneView` so the main window now opens directly into `ConfigurationCenterView`

IA-002A decisions reflected in code:

- Configuration Center is an object editor, not a form editor
- Interactive Memory Card is configuration navigation, not photo preview
- Memory Expression is composed from text plus Apple-style `MemoryBlock` tokens
- Token Library is grouped by Memory, Photo, and System
- Decoration is unified under `DecorationAsset`
- Capture-time calculation is represented by a dedicated `CaptureTimeResolver` skeleton and must not use current export time

Verification:

- passed macOS build:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- passed iOS simulator build:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PhotoMemoIOSDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- passed Share Extension build:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoShareExtension -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PhotoMemoShareExtensionDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`

Not yet manually verified:

- visual interaction in a running app window
- keyboard navigation through all Inspector controls
- real connection to Memory Engine, Renderer, Metadata, Export, or Share Extension

## 2026-06-24 RSR-001 Repository Simplification Review

This slice is repository documentation simplification only.

No runtime code was changed.

No Swift, SwiftUI, Renderer, Engine, Metadata, Export, Database, Xcode project, or pipeline files were modified.

What changed:

- rewrote `README.md` into a simpler repository entry centered on Mission, Configuration Center, Apple Photos Lifecycle, Behavior State Machine, Configuration Snapshot, batch scale, and V2 architecture
- added `Docs/REPOSITORY_VOCABULARY.md`
- added `Docs/REPOSITORY_SIMPLIFICATION_REPORT.md`
- updated `PROJECT_CONSTITUTION.md` so the active slice is RSR-001 and Repository Simplification is a first-class rule
- updated `Docs/MASTER_PLAN.md` so Repository Simplification Review replaces the old Repository Refactor step for this phase
- updated `AI_CONTEXT.md` and `AGENTS.md` with the new vocabulary rules
- updated IA-001, Behavior, Configuration, Design Decisions, Frozen Registry, RepositoryAudit, and Document Index to use the Apple Photos Lifecycle and Configuration Center language

Frozen RSR-001 language:

- Configuration Center
- Preset
- Configuration Preview
- Apple Photos Lifecycle
- Behavior State Machine
- Configuration Snapshot
- Primary / Secondary / Advanced batch scale

Daily workflow is now:

```text
Apple Photos
-> Share
-> PhotoMemo
-> Processing
-> Notification
-> Apple Photos
```

Design review principle:

```text
Every review should leave the repository simpler than before.
```

```text
每一次设计评审，都应该让 PhotoMemo 比昨天更简单一点。
```

## 2026-06-23 IA-001A Interaction Architecture Completion

This slice continues the repository documentation refactor only.

No runtime code was changed.

No business logic was modified.

What changed:

- added Product Boundary into `PROJECT_PHILOSOPHY.md`
- expanded `Docs/Behavior/BEHAVIOR_SPECIFICATION.md` with a Behavior State Machine and Configuration Snapshot Principle
- expanded `Docs/Guidelines/APPLE_NATIVE_GUIDELINES.md` with an implementation review checklist
- expanded `Docs/Guidelines/LANGUAGE_SYSTEM.md` with Smart Batch Recommendation clarification
- expanded `Docs/Interaction/IA-001_Interaction_Architecture.md` with Smart Batch Recommendation
- added `Docs/NEVER_BREAK.md`
- added `Docs/PDR/PDR_INDEX.md`
- updated `PROJECT_CONSTITUTION.md` with the Apple Trust rationale
- updated `README.md` with the repository mission
- updated `AI_CONTEXT.md` and `Docs/FROZEN_REGISTRY.md`

Completion items now recorded:

- Product Boundary
- Behavior State Machine
- Configuration Snapshot
- Apple Review Checklist
- Smart Batch Recommendation
- Soft Limit Language clarification
- Apple Trust Design Rationale
- Never Break List
- PDR Index
- Repository Mission

## 2026-06-23 IA-001 Interaction Architecture Frozen

This slice is repository documentation refactor only.

No runtime code was changed.

No SwiftUI, Renderer, Engine, Metadata, Export, Database, or pipeline code was modified.

What changed:

- updated `PROJECT_CONSTITUTION.md`
- updated `Docs/MASTER_PLAN.md`
- updated `PROJECT_PHILOSOPHY.md`
- updated `AI_CONTEXT.md`
- updated `Docs/CURRENT_STATUS.md`
- updated `Docs/DOCUMENT_INDEX.md`
- added IA-001 documentation files under `Docs/Interaction`, `Docs/Behavior`, `Docs/Guidelines`, `Docs/Configuration`, `Docs/Product`, and `Docs/PDR`
- added `Docs/DESIGN_DECISIONS.md`
- added `Docs/FROZEN_REGISTRY.md`

IA-001 status:

```text
Frozen
```

Frozen interaction rules now recorded in the repository:

- PhotoMemo is a local-first Memory Capability inside Apple workflows
- PhotoMemo does not manage photos and only owns Memory Workflow
- the Main App is a permanent Configuration Center
- the primary path is `Apple Photos -> Share -> PhotoMemo -> Memory Workflow -> Done`
- the happy path follows Zero Interaction
- the default computing posture is Quiet Computing
- completion should return users to Photos instead of drawing them into the Main App
- progress language is human, gentle, calm, and non-technical
- percentage-based progress language is prohibited
- PhotoMemo should automatically recover tasks when possible
- PhotoMemo should automatically follow Apple device constraints
- storage should be estimated before processing begins
- completed results should remain near the source photo and also join the PhotoMemo output album
- original photos never change
- metadata remains preserved, with canvas size as the only allowed output change
- naming should follow Apple conventions such as `IMG_1234 (1)`
- PhotoMemo trusts Apple Photos and does not rebuild library, timeline, map, people, search, or sync systems
- product personality is calm, quiet, respectful, invisible, and trustworthy
- all configuration belongs to `System Defaults -> User Preferences -> Advanced`
- anti-goals now explicitly prohibit PhotoMemo-owned gallery, timeline, map, people, search, browser, editor, dashboard, workspace, and task center

Verification for this slice:

- repository entry documents and overlapping interaction docs were reviewed before editing
- IA-001 frozen decisions were synchronized into dedicated repository documents
- no runtime implementation was introduced

## 2026-06-23 PM-003 Architecture Frozen

This slice is documentation synchronization only.

No runtime code was changed.

No Swift files were modified.

No UI, Renderer, Layout, Export, or Engine implementation work was started.

What changed:

- added `Docs/PM-003_Content_Layout_System.md` as the single source of truth for PM-003
- updated `PROJECT_PHILOSOPHY.md`
- updated `AI_CONTEXT.md`
- updated `Docs/CURRENT_STATUS.md`

PM-003 status:

```text
Architecture Frozen
```

Frozen items:

- Semantic Slot Principle
- Recorder
- Capture Summary
- Timeline
- Time Anchor
- Life Anchor
- Expression Grammar
- Typography Strategy

All items above are now:

```text
Frozen
```

Frozen PM-003 decisions now recorded in the repository:

- Slot means semantic role, not layout position
- Slot A = Recorder
- Slot B = Capture Summary
- Slot C = Timeline
- Slot D = Time Anchor
- Slot C default expression = `记录于｜日期｜时间`
- Timeline Action default = `记录于`
- seconds do not display
- Slot D does not show metadata and only shows Life Anchor Expression
- Life Anchor is defined as a Life Event, not a raw Date
- Life Anchor V1 supports 3 user-defined anchors
- V1 active fields are `name`, `date`, `description`
- `category` and `enabled` remain reserved
- Time Anchor supports both past and future through one Time Anchor Engine
- Slot D grammar is `Subject -> Anchor Prompt -> Anchor Result -> Anchor Suffix`
- Expression and Engine remain fully decoupled
- Variable categories are reorganized by semantic ownership
- typography is frozen at the semantic-strategy level, not at layout-measurement level

Why this matters:

- PhotoMemo no longer frames the content system as EXIF presentation
- PM-003 now defines the memory expression contract before future layout work
- future Layout Engine work can consume semantic slot definitions instead of ad hoc renderer-era assumptions

Verification for this slice:

- repository documentation was reviewed against current V2 reset documents
- PM-003 frozen rules were synchronized into the designated source files
- no runtime implementation was introduced

## 2026-06-22 Memory Presentation philosophy

This slice upgraded the highest-level product definition.

What changed:

- PhotoMemo is now defined as a Memory Presentation Engine, not only a Photo Presentation Engine
- added `PROJECT_PHILOSOPHY.md`
- added `PROJECT_DIRECTION.md`
- added `Docs/03_Research/MemoryPhilosophy.md`
- updated `Docs/ARCHITECTURE.md` with the V2 engine chain
- clarified Life Position and Memory Timeline as core product concepts
- preserved the boundary that Memory Engine calculates relationships but does not write stories

No runtime code was changed.

Documentation migration is explicitly paused until research specifications stabilize. Old documents remain reference material, not current marching orders.

## 2026-06-22 Project Constitution and research docs

This slice continued the V2 reset without touching runtime code.

What changed:

- added `PROJECT_CONSTITUTION.md` as the highest-level repository instruction
- clarified that current work is Research Phase, not Development Phase
- clarified that old `Docs/` migration should wait until research specifications stabilize
- added required research documents:
  - `Research/ReverseEngineeringRoadmap.md`
  - `Research/CanvasSpecification.md`
  - `Research/PanelSpecification.md`
  - `Research/AdaptiveRules.md`
  - `Research/MeasurementMethodology.md`
- updated `RepositoryAudit.md` with duplicated, outdated, and conflicting document groups
- updated project entry files so future sessions read `PROJECT_CONSTITUTION.md` before `Docs/MASTER_PLAN.md`

No build was run for this slice because it changes only documentation and research structure.

## Previous V1 State

Before the V2 reset, PhotoMemo was in a combined refinement stage:

- Product-wise, it is moving from a **template calibration center** toward a **workflow preparation app built on Personal Profile + Style + Share-first Workflow**
- Engineering-wise, it is moving from a large prototype-style `MainView` toward a more maintainable coordinator structure
- Capability-wise, the project has already crossed the MVP foundation line:
  - real EXIF import
  - anchor calculation
  - preview rendering
  - export to new image
  - save back to Photo Library
  - background queue and permission foundation

According to `Docs/DEVELOPMENT_PLAN.md`, the project is between:

- Phase 2: Template Calibration Center
- Phase 5: Render Fidelity And Metadata Hardening

## 2026-06-22 Repository orientation cleanup

This housekeeping slice verified the repository connection and refreshed the file/document map before the next implementation session.

Confirmed:

- `origin` points to `git@github.com:serydoo/PhotoMemo.git`
- the local branch is `main` tracking `origin/main`
- the working tree was clean before this documentation-only cleanup

What changed:

- added `Docs/DOCUMENT_INDEX.md`
  - separates startup references, current product direction, architecture/workflow docs, renderer/template docs, metadata/export docs, MainView refactor notes, QA docs, and historical notes
  - records the precedence order to use when documents disagree
- refreshed `Docs/PROJECT_STRUCTURE.md`
  - updates the source tree map to include current app, iOS, share-extension, MemoryEngine, renderer, service, and test structure
  - records the current `MainView` decomposition pattern so future sessions do not assume the old large-file structure

No build was run for this slice because it only changes documentation.

## 1.30 Immers White now uses a centered two-line text cluster instead of a stretched top-bottom split

This slice stays tightly scoped to the Immers-inspired renderer.

It does not change:

- metadata pipeline behavior
- memory engine behavior
- share intake behavior
- export naming behavior

What landed:

- `Source/PhotoMemo/PhotoMemo/Renderers/ImmersWhiteRenderer.swift`
  - the left and right text regions no longer use a `Spacer` to push the top row upward and the bottom row downward
  - both sides now render as a vertically centered two-line cluster
  - landscape typography was tightened toward the target samples:
    - top font ratio `0.235 -> 0.218`
    - bottom font ratio `0.138 -> 0.132`
    - cluster gap ratio `0.078 -> 0.112`
  - portrait typography was tightened in the same direction:
    - top font ratio `0.24 -> 0.225`
    - bottom font ratio `0.15 -> 0.142`
    - cluster gap ratio `0.08 -> 0.098`
  - the divider is now more explicit:
    - width `1 -> 2`
    - color moved from translucent black toward `#D8D8D8`
  - primary text no longer allows the previous aggressive shrink:
    - minimum scale factor is now explicitly near-full-size for top rows
- `Tests/PhotoMemoTests/RendererTests/ImmersWhiteRendererLayoutTests.swift`
  - now locks the tighter landscape and portrait cluster expectations
  - now locks the stronger divider width and the new minimum scale factors

Why this matters:

- the current PhotoMemo output had the correct white-bar height, but the internal composition was still off
- the biggest visible mismatch versus the user-provided target samples was that the top row sat too high, the bottom row sat too low, and the inter-row gap was too large
- this slice directly addresses that geometry instead of only nudging font sizes

Verification for this slice:

- syntax-level Swift parsing passed for:
  - `ImmersWhiteRenderer.swift`
  - `ImmersWhiteRendererLayoutTests.swift`
- after locating the real toolchain under:
  - `/Users/rui/Downloads/Xcode-beta.app/Contents/Developer`
  the iOS build path was verified with full `xcodebuild`
- the Xcode app was then normalized into the standard location:
  - `/Applications/Xcode.app`
- current default developer path now resolves to:
  - `/Applications/Xcode.app/Contents/Developer`
- `PhotoMemoiOS` build succeeded with:
  - `-destination 'generic/platform=iOS'`
  - `-allowProvisioningUpdates`
- the resulting iPhone app was installed onto:
  - `iPhone7` (`00008150-000A043136A1401C`)
- the installed app was also launched successfully on-device:
  - `com.serydoo.PhotoMemo.iOS`
- compatibility note:
  - `PhotoMemoShareExtension` and `PhotoMemoWidgetExtension` were both compiled as dependencies of the successful `PhotoMemoiOS` build
- not fully green yet:
  - a standalone `PhotoMemo` macOS build under the current Xcode beta toolchain failed in existing `MainView` / `MainView+WorkspaceControls` code, with SwiftUI macro/plugin-response errors unrelated to the Immers renderer slice
  - `PhotoMemoTests` were not completed in this session because the current beta/macOS toolchain path is still noisy for test execution

Immediate next step:

1. visually review the freshly installed iPhone build against the target samples
2. separately stabilize the current macOS build path under the active Xcode beta
3. rerun `PhotoMemoTests`, especially `ImmersWhiteRendererLayoutTests`, once the macOS toolchain path is stable

## 1.29 Classic White now has manual visual references and snapshot-grade regression checks

This slice stays renderer-only.

It does not change:

- metadata pipeline behavior
- memory engine behavior
- batch behavior
- share product flow

What landed:

- committed manual reference PNGs under:
  - `Tests/Fixtures/RendererSnapshots/ClassicWhite/full-card/`
- new snapshot support:
  - `ClassicWhiteSnapshotSupport`
  - deterministic synthetic scenarios for:
    - `landscape_standard`
    - `landscape_long_exif`
    - `portrait_standard`
    - `portrait_long_memory`
- new snapshot regression suite:
  - `ClassicWhiteSnapshotTests`
- new workflow doc:
  - `Docs/ClassicWhiteVisualQA.md`

Why this matters:

- Classic White is no longer protected only by theme constants and width math
- the project now has a small but real visual baseline for the full rendered card
- future typography, spacing, divider, or truncation drift can be caught before it reaches device testing

Snapshot policy:

- reference images are synthetic and deterministic
- record mode is explicit via `.record-mode`
- reference refresh uses exported Xcode test attachments
- normal comparison allows only a tiny tolerance for attachment-refresh color drift:
  - `maxChannelDelta <= 1`
  - differing pixels below `0.05%`

Verification for this slice:

- targeted snapshot tests passed:
  - `ClassicWhiteSnapshotTests`
- `PhotoMemoTests` full suite passed
- builds passed:
  - `PhotoMemo`
  - `PhotoMemoiOS`
  - `PhotoMemoShareExtension`
- device install passed:
  - `iPhone7` (`iPhone 17 Pro Max`)
- device launch passed:
  - `com.serydoo.PhotoMemo.iOS`

## 1.28 Classic White now has second-layer regression guards for routing and grid math

This slice continues the Classic White renderer-only hardening work.

It still does not change:

- metadata pipeline behavior
- memory engine behavior
- batch behavior
- share product flow

What landed:

- `RecordCardRenderer`
  - now exposes an explicit `destination(for:)` helper
  - the view body routes through that helper instead of hiding the preset switch inline
- `ClassicWhiteCardRenderer`
  - now exposes `layoutMetrics(forTotalWidth:)`
  - the live layout uses the same computed metrics that tests can assert against
- new renderer regression tests:
  - `RecordCardRendererRoutingTests`
  - `ClassicWhiteCardRendererLayoutTests`

Why this matters:

- Classic White routing is now locked at the renderer boundary instead of only indirectly through preset tests
- the fixed `40 / 20 / 40` grid is now covered as real width math, not just as theme constants
- future refactors are less likely to silently break module widths or route the wrong preset into the wrong renderer

Verification for this slice:

- tests passed:
  - `PhotoMemoTests`
- targeted renderer tests passed:
  - `RecordCardRendererRoutingTests`
  - `ClassicWhiteCardRendererLayoutTests`
  - `ClassicWhiteRendererThemeTests`
- builds passed:
  - `PhotoMemo`
  - `PhotoMemoiOS`
  - `PhotoMemoShareExtension`

## 1.27 Classic White now uses a fixed render design system

This slice is renderer-only.

It does not change:

- metadata pipeline behavior
- memory engine behavior
- batch behavior
- share product flow

What landed:

- `RenderTheme.swift`
  - introduces shared render-theme tokens for:
    - bottom bar
    - colors
    - grid
    - typography
    - spacing
    - divider
    - center module
- `ClassicWhiteRenderer`
  - no longer uses ratio-based border math
  - now exposes a fixed-height export sizing rule:
    - `imageHeight + 260`
- `ClassicWhiteCardRenderer`
  - extracts Classic White out of `RecordCardRenderer`
  - now renders with an explicit:
    - left module
    - center module
    - right module
  - uses fixed text sizes and truncation instead of scaling
- `RecordCardRenderer`
  - is back to being a layout router only
- `RecordCardExportService`
  - now reads Classic White export size from the renderer instead of old border ratios
- `Docs/RENDER_SPEC.md`
  - is now aligned with the new design-system values

Why this matters:

- Classic White now behaves like an information-card system instead of a proportional border experiment
- preview and export sizing are easier to reason about
- future themes can reuse the same theme-driven structure instead of adding more magic numbers inside the renderer

Verification for this slice:

- tests passed:
  - `PhotoMemoTests`
- targeted theme tests passed:
  - `ClassicWhiteRendererThemeTests`
- builds passed:
  - `PhotoMemo`
  - `PhotoMemoiOS`
  - `PhotoMemoShareExtension`
- compatibility note:
  - `ClassicWhite` files are now explicitly excluded at compile time from the share-extension target path via `PHOTOMEMO_SHARE_EXTENSION`, so renderer refactors do not leak into the lightweight intake target

## 1.26 Immers right-column alignment and placeholder naming fallback are now tightened

This slice keeps the scope narrow and user-facing.

What landed:

- `ImmersWhiteRenderer`
  - keeps the right column explicitly left aligned
  - now uses separate spacing for:
    - logo -> divider
    - divider -> right text
  - gives the right column more usable width in both portrait and landscape
  - enables text tightening so long EXIF lines are less likely to look visibly smaller than the left title line
- `PhotoFileNameResolver`
  - now treats `PhotoMemo Import` placeholder variants as non-canonical names, alongside `Photo Library`
  - now exposes:
    - `outputBaseName(...)`
    - `timestampFallbackBaseName(...)`
- `RecordCardExportService`
  - export naming priority is now:
    1. real imported original file name
    2. photo-library original file name resolved again from `assetLocalIdentifier`
    3. deterministic capture-date fallback:
       - `IMG_yyyyMMdd_HHmmss`
  - copy suffix behavior remains:
    - `name.jpg`
    - `name (1).jpg`
    - `name (2).jpg`

Why this matters:

- the right-side two-block area is now visually more anchored to the logo/divider cluster instead of drifting rightward
- `PhotoMemo Import` should no longer survive into final exported names when there is either a real original file name or at least a capture date available
- this improves the two most visible quality issues from the latest real-device review without touching renderer architecture, memory logic, or metadata boundaries

Verification for this slice:

- targeted tests passed:
  - `PhotoFileNameResolverTests`
  - `RecordCardBuildServiceTests`
  - `ExternalPhotoIntakeStoreDiagnosticsTests`
  - `ImmersWhiteRendererLayoutTests`
- builds passed:
  - `PhotoMemo`
  - `PhotoMemoiOS`
  - `PhotoMemoShareExtension`
- device install passed:
  - app reinstalled onto iPhone `00008150-000A043136A1401C`
- device launch was not verified automatically:
  - launch request was denied because the phone was locked at the time

## 1.25 Share success feedback is intentionally count-only again

This round does not expand capability.

It simplifies the Share completion language back to the quieter product decision:

- do not surface file names after Share finishes
- do not imply that a shown file name proves save-back succeeded
- keep success feedback focused on how many photos PhotoMemo accepted

What landed:

- `PhotoMemoShareExtensionViewController`
  - success wording remains count-based only
- `PhotoMemoShareExtensionImportResult`
  - no longer carries UI-only imported file name feedback
- `PhotoMemoShareWorkflowSummaryTests`
  - filename-oriented success formatter tests were removed

Why this matters:

- for multi-photo shares, one displayed file name does not help users identify which photo failed later
- the real success criterion is still whether a new generated photo appears in the library beside the original
- Share feedback stays simpler and more Apple-like while the intake and save-back pipeline continues to be debugged separately

Verification for this slice:

- `PhotoMemoTests` passed
- `PhotoMemo` build passed
- `PhotoMemoiOS` build passed
- `PhotoMemoShareExtension` build passed

## 1.24 Share success feedback now surfaces original file names when available

This slice was later superseded by 1.25 after product review simplified Share completion feedback back to count-only wording.

This round keeps the scope narrow and user-visible.

What landed:

- `PhotoMemoShareProcessingFeedbackFormatter`
  - formats share success feedback from counts plus imported original file names
- `PhotoMemoShareExtensionImportResult`
  - now carries `importedFileNames`
- `PhotoMemoShareExtensionIntakeService`
  - now forwards imported original file names into the result object
- `PhotoMemoShareExtensionViewController`
  - now uses the formatter for the success status message

User-facing effect:

- single-photo share success can now say:
  - `已接收《IMG_9558.HEIC》。处理完成后会写回系统相册。`
- partial success can now keep counts while still showing one concrete example file name

Why this matters:

- provenance is no longer only a hidden implementation detail
- users get clearer confirmation that the photo they intended to share was the one PhotoMemo actually received
- this builds toward calmer, more trustworthy share feedback without exposing technical pipeline terms

Verification for this slice:

- `PhotoMemoTests` passed
- `PhotoMemo` build passed
- `PhotoMemoiOS` build passed
- `PhotoMemoShareExtension` build passed

## 1.23 Share and external intake provenance now survives into batch tasks and imported photos

This round extends the prior `PhotoSourceInfo` slice across the intake pipeline instead of stopping at `SelectedPhoto`.

What landed:

- `ExternalPhotoIntakeItem`
  - managed URL
  - original file name
  - source identifier
  - content type identifier
- `ExternalPhotoIntakeRequest`
  - now optionally persists structured intake items
  - now exposes `intakePayloads`
- `BatchTaskIntakePayload`
  - now carries `fileName`
  - `sourceIdentifier`
  - `contentTypeIdentifier`
- `BatchTask`
  - now preserves the same provenance fields
- `BatchProcessingCoordinator`
  - now rebuilds `PhotoSourceInfo` from batch task provenance before import
- `PhotoMemoShareExtensionIntakeService`
  - now persists structured intake items instead of only raw managed URLs
- `PhotoMemoAppRuntime`
  - now enqueues batch tasks from structured intake payloads

Why this matters:

- share-first intake no longer falls back to temporary managed-copy naming in the batch layer
- background status and later imports can keep showing the original shared file name
- batch import can now rehydrate `SelectedPhoto.sourceInfo` from request/task provenance instead of reconstructing everything from the managed file path

What is still not finished:

- provenance is not yet promoted into every user-visible diagnostic surface
- non-share external URL intake still only preserves a lighter provenance set than the ideal long-term model
- canonical provenance is now cleaner across selected photo, request, payload, and task, but the save-back side still only consumes the parts needed today

Verification for this slice:

- `PhotoMemoTests` passed
- `PhotoMemo` build passed
- `PhotoMemoiOS` build passed
- `PhotoMemoShareExtension` build passed

## 1.22 Import source facts now have a lightweight canonical home inside `SelectedPhoto`

This round continues the workflow-consolidation checklist with a small code slice instead of a broad refactor.

What landed:

- `SelectedPhoto` now carries a dedicated `PhotoSourceInfo`
- `PhotoSourceInfo` currently preserves:
  - `originalFileName`
  - `assetLocalIdentifier`
  - `contentTypeIdentifier`
- `PhotoImportService` now writes that source info during imports
- `PhotoImporterView` now forwards the Photos asset identifier when available
- `RecordCardExportService` now prefers the imported original file name when generating export file names

Why this matters:

- original import facts are no longer represented only indirectly through `sourceURL`
- export naming is less dependent on temporary-path details
- future work on asset provenance can build on a real typed surface instead of more ad hoc URL parsing

Scope discipline for this slice:

- no new architecture layer
- no ADR change
- no renderer behavior change beyond export naming input
- no batch/share rewrite

What is still not finished:

- share intake still does not preserve every provenance field end to end
- source provenance is now cleaner, but not yet fully unified across all batch/request models
- `PhotoMetadata` remains the canonical photo-fact model, while `PhotoSourceInfo` is currently the lightweight canonical import-provenance model for selected photos

Verification for this slice:

- `PhotoMemoTests` passed
- `PhotoMemo` build passed
- `PhotoMemoiOS` build passed
- `PhotoMemoShareExtension` build passed

## 1.21 Main workflow consolidation is now explicitly documented as the current development standard

This round does not add features and does not introduce a new architecture layer.

Instead, it absorbs the worthwhile parts of `PhotoMemo v0.4 Main Workflow Consolidation` into project standards:

- PhotoMemo now has one explicit internal workflow:
  - `Import -> Metadata -> Memory -> Renderer -> Export -> Share`
- A new workflow standard document now records:
  - stage ownership
  - accepted boundaries
  - near-term consolidation focus
  - explicit non-goals
- A new workflow checklist now turns that direction into small follow-up items instead of a risky rewrite

The main judgment from this round:

- worth absorbing now:
  - one canonical workflow standard
  - clearer stage ownership
  - keeping renderer as the final visual layer instead of the product center
  - preserving Template/Style vs Renderer separation
  - continuing to tighten metadata-origin consistency
- not worth doing now:
  - broad architecture refactors
  - a new abstract workflow framework
  - codebase-wide structural reorganization
  - forcing all daily execution into Share before the current path is stable

New docs:

- `Docs/MainWorkflowConsolidation.md`
- `Docs/MainWorkflowChecklist.md`

This round keeps the existing ADR set unchanged.

Reason:

- the workflow rule is a clarification and execution standard within already accepted boundaries
- it does not replace the canonical template string model
- it does not alter the Memory Engine boundary
- it does not redefine renderer/export/batch responsibilities

Build verification for this slice is recorded after the compilation step in `HANDOFF.md`.

This round's build verification:

- `PhotoMemo` build passed
- `PhotoMemoiOS` build passed
- `PhotoMemoShareExtension` build passed

Tests were not rerun for this slice because the new work is documentation-only.

## 1.20 Share wake-up, original-filename import preservation, and default renderer routing now align with the current product direction

这一轮没有扩能力，重点是把三个已经影响真实体验的问题收口：

- 主程序从 `PhotosPicker` 导入同名照片时，不再因为临时目录冲突把原始文件名污染成 `(... 1)`
- Share confirmation 成功后，不再只是“写进共享收件箱然后静默关闭”，而是会主动尝试唤起主 App 刷新 intake
- 当前默认风格 `template1` 不再走 `ClassicWhiteRenderer`，而是统一切到更接近目标样图的 `ImmersWhite` 渲染路径

本轮已落地：

- `PhotoImportService`
  - 每次数据导入改成独立 UUID 临时子目录
  - 子目录内保留原始文件名
  - 显式传入的扩展名大小写继续保留
  - `Photo Library` 占位名继续回退到 `PhotoMemo Import.jpg`
- `PhotoMemoDeepLink`
  - 新增 `photomemo://share`
  - `PhotoMemoRootSceneView` 现在会识别这个 deep link 并执行 `runtime.refreshExternalIntakeState()`
- `PhotoMemoShareExtensionViewController`
  - share intake 成功后现在会先尝试唤起主 App，再关闭当前分享页
- 渲染路径统一：
  - 新增 `TemplatePreset.renderLayout`
  - `template1` 现在改走 `ImmersWhite`
  - `RecordCardRenderer` 预览路径与 `RecordCardExportService` 导出尺寸路径已经统一使用这套判定
- `ImmersWhiteRenderer`
  - 底栏背景改成偏暖白 `#F4F4F2`

本轮新增回归保护：

- `PhotoImportServiceTests`
  - 显式文件名保留
  - `Photo Library` 占位名回退
  - 重复导入同名照片时仍保持原始文件名
- `TemplatePresetRenderLayoutTests`
  - 锁定当前默认风格 renderer 路由
- `PhotoMemoDeepLinkTests`
  - 锁定 share deep link 解析

本轮验证：

- 定向测试通过：
  - `PhotoImportServiceTests`
  - `ExternalPhotoIntakeStoreDiagnosticsTests`
  - `TemplatePresetRenderLayoutTests`
  - `PhotoMemoDeepLinkTests`
- 全量测试通过：
  - `PhotoMemoTests`
- 构建通过：
  - `PhotoMemo`
  - `PhotoMemoiOS`
  - `PhotoMemoShareExtension`

这一轮仍需继续真机验证的部分：

1. `photomemo://share` 在系统分享后的真实唤起是否稳定
2. Share 触发后的生成与保存反馈是否已经足够清楚
3. 当前默认成片是否已经明显接近目标 Immers 样图
4. 写回系统相册后的最终文件名是否已经完全摆脱 `Photo Library.*`

## 1.19 Photo Library original-filename preservation is now explicitly wired, and renderer calibration moved one step closer to the sample output

这一轮继续遵守“小切片、先把真实链路修准”的方向，没有扩新能力，只修正真实导出回写行为并对样图视觉再靠近一步。

本轮已落地：

- Photo Library 写回命名补上了明确的原始文件名传递：
  - `PhotoLibraryExportService.saveImageResult(...)` 现在会设置：
    - `PHAssetResourceCreationOptions.originalFilename`
  - 值直接来自当前导出文件名
  - 这意味着如果导出结果已经是：
    - `IMG_1234.jpg`
    - `IMG_1234 (1).jpg`
    - `IMG_1234 (2).jpg`
    写回系统相册时也会尽量沿用同样的文件名语义
- 新增了一个小而明确的回归保护：
  - `usesExportedFileNameAsPhotoLibraryOriginalFilename()`
  - 这条测试锁住了：
    - 正常文件名
    - 带复制后缀文件名
    - 空白文件名回退
- `ClassicWhiteRenderer` 又做了一轮只影响展示细节的轻微参数回收：
  - 白栏背景改成更接近样图的暖灰白
  - 主文字、参数文字、次级文字层次更清楚
  - 分隔线颜色由透明黑改成显式浅灰
  - 分隔线宽度从 `1` 调整到 `2`
  - 中部徽标与右侧文案的几何节奏继续向样图贴近

本轮验证：

- 定向测试通过：
  - `PhotoMemoTests/RecordCardBuildServiceTests`
- 构建通过：
  - `PhotoMemo`
  - `PhotoMemoiOS`
  - `PhotoMemoShareExtension`

这一轮仍保留的人工验证债务：

1. 需要真机再次验证写回系统相册后的真实命名是否已经不再退化成 `Photo Library.*`
2. 白栏底色、分隔线粗细与中部几何关系仍要继续以你给的成品样图为准
3. 这一轮没有继续动更大的排版结构，只做了安全的小幅视觉回收

## 1.18 Product convergence: Main App now matches the five-layer direction more closely, Share wording is quieter, and Profile/Style boundaries are tighter

这一轮继续严格按 `North Star` 做减法，没有增加新功能，重点是把可见结构、用户语言和长期资料边界再往产品模型上收。

本轮已落地：

- Main App 顶层继续收口：
  - iPhone 主界面现在更接近最终目标：
    - `我的记录`
    - `默认风格`
    - `输出设置`
    - `设置`
    - `关于`
  - `预览` 不再在 iPhone 顶层单独占一个主块
  - 预览被下沉回 `默认风格` 内部，作为校准内容的一部分
  - macOS 仍保留右侧 detail 预览，用作单张真实校准面

- 用户可见术语继续去技术化：
  - `识别数据` 改为 `照片信息`
  - `智能数据` 改为 `记忆信息`
  - 多处 `时间点` 改为 `记忆日期`
  - Share 页 `当前设置` 改为 `这次会如何处理`
  - Share 页 `当前风格` 改为 `默认风格`

- Share Extension 又安静了一层：
  - 确认页继续保持单页
  - 现在更明确地只说：
    - 分享了几张
    - 默认风格
    - 结果去向
    - 接下来会发生什么
  - 单张预览说明也更直接：
    - `将按当前默认风格处理这张照片`
  - 失败提示不再让用户理解“当前风格”这类过于编辑态的概念

- `Personal Profile` 成为长期信息来源又前进了一步：
  - `PersonalProfileStore` 现在可以单独更新：
    - 默认风格
    - 默认保存位置
  - 主界面切换默认风格时，会同步回写 `Personal Profile`
  - 主界面切换保存相册时，也会同步回写 `Personal Profile`
  - 这意味着 Share 和 Main App 在默认风格/默认输出上的共同来源更加明确

- `Style` 更接近 presentation-only：
  - 保存当前风格时，不再先把当前相册和记忆日期当作风格持久化来源
  - 应用某个风格快照时，也不再顺手改掉当前相册和当前记忆日期
  - 现阶段风格恢复的核心重新聚焦到：
    - 模板
    - 标识
    - 说明写入相关设置

本轮验证：

- 定向测试通过：
  - `PersonalProfileStoreTests`
  - `PhotoMemoShareWorkflowSummaryTests`
- 全量测试通过：
  - `PhotoMemoTests`
- 这一轮我明确拿到了 `PhotoMemoTests` 的 `TEST SUCCEEDED`
- `PhotoMemo` / `PhotoMemoiOS` / `PhotoMemoShareExtension`
  - 构建命令已实际执行
  - 当前会话未保留三个 scheme 各自完整、干净的成功尾行
  - 但本轮涉及的主 app / share 文件已经被测试编译链真实编译覆盖

这一轮仍保留的产品债务：

1. `默认风格` 虽然已经更像设置层，但 `进一步调整` 里仍有不少低频项，后续依旧值得继续下沉。
2. First Run 目前是更短的 5 步版本，符合“更安静”的方向，但与最新 North Star 的显式完成页仍有一点差异，需要继续做产品判断。
3. Share confirmation page 现在更看得懂，但距离真正几乎无感的 `Share -> Generate -> Save -> Done` 体验还有最后一段真机手感打磨。

## 1.17 Alpha convergence cleanup: Main App lost another layer of dashboard feeling, and First Run became shorter

这一轮继续遵守 `complexity must go down every sprint` 这条规则，没有扩能力，只继续做减法。

本轮已落地：

- `Main App` 又收掉了一层重复表达：
  - macOS 右侧详情区不再重复显示一份 `默认风格`
  - 右侧重新回到更单纯的预览校准面
- iPhone 主界面继续收短：
  - 顶层不再默认并列 `关于`
  - `设置` 只在权限还没准备好时才出现
  - 默认主链现在更接近：
    - 我的记录
    - 默认风格
    - 输出
    - 预览
- `默认风格` 默认展开层继续减法：
  - 保留风格位切换和基础风格信息
  - 时间点 / 个性化区域 / 补充信息 / Logo 标识 被后置到 `进一步调整`
  - 这样首次进入时不会立刻看到整页低频项
- `FirstRunWizardView` 继续缩短：
  - 不再单独保留“完成页”
  - 最后一步直接完成设置并进入主界面
  - 当前首次流程收成：
    - 欢迎
    - 记录身份
    - 宝宝昵称
    - 出生日期
    - 保存位置

这一轮的产品含义：

- Main App 更接近真正的配置中心，而不是一层层展开的调试台
- First Run 更像一次性的系统设置，而不是“小向导 + 总结页”
- 低频项目还在，但默认不再抢占主流程注意力

这一轮仍保留的产品债务：

1. `默认风格` 内部依然承载了较多低频项，只是先后置，还没有完全迁到真正的二级设置结构。
2. `设置 / 关于` 还没有形成独立而稳定的入口层级；当前只是先从首页主舞台继续降权。
3. Share Extension 仍然不是最终的“几乎无感”生成保存体验；这轮没有继续动 Share 主链。

本轮验证：

- 构建与测试正在执行：
  - `PhotoMemo`
  - `PhotoMemoiOS`
  - `PhotoMemoShareExtension`
  - `PhotoMemoTests`
- 最终结果会同步记录到 `HANDOFF.md`

## 1.16 Alpha product refinement: Main App is closer to a configuration center, Share is closer to a single-page confirmation flow

这一轮没有继续扩能力，而是按 `PhotoMemo is a natural extension of Apple Photos` 这条方向，把主 App 和 Share Extension 再往“更少配置、更少技术词、更接近系统产品”推进了一步。

本轮已落地：

- Main App 开始更明显地从“工作台”收成“配置中心”：
  - `MainView` 现在接入了 `PersonalProfileStore`
  - 主界面新增并提前了 `我的记录`
  - `我的记录` 直接承接长期资料：
    - 记录身份
    - 宝宝昵称
    - 出生日期
    - 默认风格摘要
    - 默认保存位置摘要
- iPhone 主界面不再强调原先的 `预览 / 编辑` 双模式切换，而是改成单页配置流：
  - 我的记录
  - 默认风格
  - 照片
  - 时间锚点
  - 个性化区域
  - 补充信息
  - Logo 标识
  - 输出
  - 预览
- 默认风格区域进一步去工具化：
  - 头部直接显示当前生效模块
  - 展开后显示更像设置列表的模块项
  - 用户可见名称已从 `配置 1/2/3` 改为 `模块 1/2/3`
  - 操作仍保留切换、重命名、保存当前风格、恢复默认，但提示语更像用户语言
- 旧的“当前配置”式摘要继续降权：
  - `workspaceConfigurationSummary` 已收成更轻的说明文案
  - 风格保存和恢复提示不再重复强调一整串内部配置域

首次启动体验也更贴近新的产品模型：

- `FirstRunWizardView` 已从旧的 5 步配置导向，收成更接近长期使用模型的流程：
  - 欢迎
  - 记录身份
  - 宝宝昵称
  - 出生日期
  - 默认时间锚点说明
  - 保存位置
  - 完成
- 首次启动不再要求用户在一开始就理解多个风格位
- 默认时间锚点页面明确告诉用户：
  - 默认使用出生时间
  - 年龄会自动计算

Share Extension 继续从“技术交接面”往“确认一下就开始”的单页靠拢：

- `PhotoMemoShareExtensionViewController` 现在会尝试显示第一张照片预览
- 多张分享时只显示第一张，并提示：
  - 其余照片会使用相同风格处理
- 确认页继续去技术词：
  - `当前设置`
  - `开始生成`
  - `处理完成后会写回系统相册`
- `PhotoMemoShareWorkflowSummary` 的对外语言也更自然了：
  - `styleTitle` 替代旧的 `configurationTitle`
  - 输出去向统一成：
    - `系统相册`
    - `photomemo 相册`
    - `“家庭相册”相册`
    - `当前选定相册`

兼容层这一轮也补了一步：

- `PersonalProfileStore` 新增了 `updateProfile(_:)`
- 这让主界面中的 `我的记录` 能直接更新长期资料，同时继续复用现有兼容桥接：
  - birthday anchor 同步
  - 默认风格位同步
  - 默认相册同步
  - 旧设置桥接保持不变

本轮验证：

- 已通过：
  - `PhotoMemo`
  - `PhotoMemoiOS`
  - `PhotoMemoShareExtension`
  - `PhotoMemoTests`
- 新旧测试继续通过，包含：
  - `PhotoMemoShareWorkflowSummaryTests`
  - `PersonalProfileStoreTests`
  - metadata / memory / export / batch / editor projection 既有测试集合

当前还留着的产品债务：

1. Main App 还没有完全收成最终理想形态的 `我的记录 / 默认风格 / 输出设置 / 设置 / 关于` 五层结构。
2. `时间锚点 / 个性化区域 / 补充信息 / Logo 标识` 仍然在首页主舞台上，虽然层级已变轻，但还没有真正下沉成二级配置。
3. Share confirmation page 已经更容易看懂，但还没有做到真正的“几乎感觉不到存在”的自动生成保存体验。
4. `MainView+PersonalProfile.swift` 目前通过编译条件避开 Share target，后续如果继续收 target 边界，最好再回头检查一次同步组覆盖范围。

下一轮最值得继续的三件事：

1. 继续给 Main App 做减法，把 `输出设置 / 设置 / 关于` 真正梳理成稳定层级。
2. 把 Share confirmation page 继续向 `生成 -> 保存 -> 完成` 的更短主链推进。
3. 做一轮真机 UX 回归，重点看：
   - 首次启动是否足够像系统设置
   - iPhone 主界面是否仍有“像工具”的感觉
   - 分享确认页是否已经足够让第一次使用的人敢点 `开始生成`

## 1.15 Share intake diagnostics are now wired through the full confirmation pipeline

PhotoMemo 的 Share Extension 这一轮没有改工作流本身，只强化了 intake 阶段的可观测性，目标是把“照片没有成功交给 PhotoMemo”从笼统报错升级成可定位的阶段性诊断。

本轮已落地：

- 新增共享诊断基础：
  - `PhotoMemoShareIntakeFailureStage`
  - `PhotoMemoShareIntakeNSErrorSummary`
  - `PhotoMemoShareIntakeFailureContext`
  - `PhotoMemoShareIntakeOperationSeed`
- `ExternalPhotoIntakeStore` 现在保留详细 copy / persist / serialization 失败上下文
- `PhotoMemoShareExtensionImportResult` 现在会携带：
  - `itemProviderCount`
  - `supportedProviderCount`
  - `failureStage`
  - `failureContext`
- `PhotoMemoShareExtensionIntakeService` 现在会对以下步骤逐一打点：
  - extension 收到多少个 item providers
  - 支持的 provider 数量
  - 选中的 UTType 与 provider 注册类型
  - `loadFileRepresentation` 开始 / 返回 URL / 失败
  - `loadItem` fallback 开始 / 返回 URL 或 Data / 失败
  - temporary copy 结果
  - shared container 目标路径
  - request 持久化结果
  - final import result 摘要
- `PhotoMemoShareExtensionViewController` 失败态现在会追加简短诊断：
  - 失败阶段
  - `NSError domain / code`

本轮验证：

- 新增 `PhotoMemoShareIntakeDiagnosticsTests` 通过
- 新增 `ExternalPhotoIntakeStoreDiagnosticsTests` 通过
- `PhotoMemoTests` 定向测试通过
- `PhotoMemoiOS` build 通过
  - 该次编译已包含 `PhotoMemoShareExtension` target

这代表什么：

- 从你下一次真机重试开始，如果 share 再失败，我们应该能立刻知道它卡在：
  - `load`
  - `copy`
  - `persist`
  - `serialization`
  - `completion`
- 并且能同时拿到对应的底层 `NSError.localizedDescription / domain / code / underlyingError`

还没完成的部分：

- 还没有基于新的诊断结果去真正修复 intake 根因
- 还需要你下一次在真机上重试一次，确认失败页是否已经从纯泛化文案升级成带阶段的错误
- 如果新的失败截图出现，我们就可以直接按阶段下刀，不需要再盲查整个 Share 流程

## 1.14 默认个性化文案与导出命名规则已收口一轮

PhotoMemo 在这一轮继续沿着 `Personal Profile + 默认风格` 的方向，把模板 1 的默认语言再向真实家庭记录语境推进了一步。

这一轮的目标仍然是：

- 不改渲染结构
- 不改导出流程
- 不改 Share 工作流
- 只收口默认模板语义、导出命名和变量注入

本轮已经落地：

- 新增 `relationship_label` 元数据键，用于把首次引导里的记录者身份注入运行时上下文
- 模板 1 左上默认语义改成：
  - `{{relationship_label}}手持{{model}}记录`
- 模板 1 右下默认语义改成：
  - `{{anchor_title}}今天{{anchor_age_text}}啦`
- `记录于{{capture_date_display}}` 默认文案改成：
  - `拍摄于{{capture_date_display}}`
- 模板归一化时会兼容迁移旧默认内容，避免已有模板直接失真
- 导出文件名现在默认沿用原图名称：
  - `IMG_1234.jpg`
  - `IMG_1234 (1).jpg`
  - `IMG_1234 (2).jpg`

本轮代码上的关键补充：

- `RecordCardBuildService` 现在会读取共享 `PersonalProfile`，把记录者称呼注入 `MetadataContext`
- `TemplateVariable` 新增公开变量：
  - `记录者称呼`
- 时间点标题的公开展示名进一步收口为：
  - `主角称呼`

本轮新增或补强验证：

- `RecordCardBuildServiceTests` 通过
- `EditorProjectionEngineTests` 通过
- `PhotoMemo` macOS build 通过
- `PhotoMemoiOS` build 通过
  - 该次编译已包含 iOS App、Share Extension、Widget Extension 依赖图

本轮仍需继续人工核查：

- 自定义区域中 EXIF 参数摘要模块的重新插入与删除边界
- 个别文本异常拼接，例如：
  - `途途1岁24天）〕啦`
- 右下区域在真实中文输入与多模块混排下的最终显示稳定性
- 你后续准备发送的分享失败提示图，还没有进入本轮分析

额外说明：

- 本轮尝试过独立 `PhotoMemoShareExtension` scheme 编译，但该 scheme 在当前工程里仍会拉起完整 iOS 依赖图，且命令被人为中断，没有保留单独的成功结论
- 但 `PhotoMemoiOS` 的完整成功编译已经覆盖到 Share Extension target 的真实编译路径，所以当前可以把 iOS/Share 视为可编译状态
- 你提供的样图里：
  - `/Users/rui/Downloads/IMG_5667.jpg`
  - `/Users/rui/Downloads/IMG_5668.JPEG`
  已可用于继续对齐文案观感
  - `/Users/rui/Downloads/IMG_9565.HEIC`
  本轮读取时本地未找到文件

## 1.13 First Run Wizard foundation landed

PhotoMemo now has its first implemented `Personal Profile + First Run` product slice in code.

This round stays compatibility-first:

- no renderer behavior change
- no export content change
- no template data-model redesign
- no share workflow redesign
- existing `SettingsService` and `UserDefaults` keys remain readable

What landed in code:

- additive `PersonalProfile` model
- additive `PersonalProfileStore`
- one-time `FirstRunWizardView`
- root-scene gating so first launch enters the setup flow before `MainView`
- compatibility backfill from existing birthday anchor / selected album / active style slot
- compatibility write-back into the current settings pipeline when first run completes

Current wizard shape:

1. who is recording
2. baby nickname
3. birthday
4. default style
5. save destination

What is user-visible now:

- first launch is no longer a raw settings surface
- users get a simpler setup path with human language
- `时间锚点` is not exposed in first run
- default style is presented as `宝宝成长（推荐）`
- save destination can now distinguish:
  - `系统相册`
  - `photomemo 相册`
- the onboarding copy and hierarchy were further tightened toward a more Apple-like first-device setup feel:
  - welcome copy now emphasizes `只需要花 1 分钟完成设置`
  - step labels are simplified to `1 / 5 ... 5 / 5`
  - the setup summary is quieter and less dashboard-like

Important compatibility note:

- `系统相册` default save is now wired through runtime save behavior and summary wording
- `photomemo 相册` remains the automatic-album default
- this round does not yet add a post-onboarding `Personal Profile` editing page
- this round does not yet migrate the Main App information architecture to `Profile / Styles / Settings / About`

Files added in this round:

- `Source/PhotoMemo/PhotoMemo/Models/PersonalProfile.swift`
- `Source/PhotoMemo/PhotoMemo/Services/PersonalProfileStore.swift`
- `Source/PhotoMemo/PhotoMemo/Views/FirstRun/FirstRunWizardView.swift`
- `Tests/PhotoMemoTests/MetadataTests/PersonalProfileStoreTests.swift`

Files updated in this round:

- `Source/PhotoMemo/PhotoMemo/App/PhotoMemoRootSceneView.swift`
- `Source/PhotoMemo/PhotoMemo/App/BatchConfigurationSnapshotProvider.swift`
- `Source/PhotoMemo/PhotoMemo/App/PhotoMemoShareWorkflowSummary.swift`
- `Source/PhotoMemo/PhotoMemo/Services/PhotoLibraryExportService.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+DerivedState.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+ExportActions.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+MemoryProgress.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+OutputSection.swift`
- `Tests/PhotoMemoTests/VariableTests/PhotoMemoShareWorkflowSummaryTests.swift`

Verification for this round:

- `PhotoMemoTests` passed
- focused `PersonalProfileStoreTests` and `PhotoMemoShareWorkflowSummaryTests` passed after the final target-boundary fix
- `PhotoMemo` build passed
- `PhotoMemoiOS` build passed
- `PhotoMemoShareExtension` build passed

Still not manually verified:

- the feel of the new first-run flow on real iPhone hardware
- whether the five-step flow is short enough for a genuine first-time user
- whether `系统相册` vs `photomemo 相册` wording feels natural inside the existing Main App output panel
- whether users miss a direct post-onboarding place to edit Personal Profile

## 1.12 v1.0 product model foundation defined

PhotoMemo now has a formal product model document:

- `Docs/ProductModel.md`

This round is documentation-only.

It does not change architecture, renderer behavior, export behavior, share behavior, or persistence behavior in code.

What is newly defined:

- Personal Profile is now the owner of:
  - relationship
  - baby nickname
  - birthday
  - default album
  - default style
- Style is now the owner of:
  - layout
  - variables
  - visual arrangement
  - renderer-facing behavior
- Workflow is now the owner of:
  - share execution
  - generate/save flow
  - runtime progress and result state

What this changes at the product level:

- the Main App is no longer best understood as a general configuration dashboard
- it is becoming a workflow-preparation app
- the Share Extension is no longer just a technical intake surface
- it is the future primary execution surface
- First Run is now the preferred place for identity and default-output setup

Main App information architecture target is now:

- Personal Profile
- Styles
- Settings
- About

This round also aligns the repository slogan around:

- Configure once. Remember forever.
- 一次设定，永久记录。

Docs added or updated in this round:

- `Docs/ProductModel.md`
- `Docs/ProductDirection.md`
- `Docs/ProductBacklog.md`
- `Docs/CURRENT_STATUS.md`
- `HANDOFF.md`
- `README.md`

Recommended next implementation sequence:

1. add Personal Profile as additive data
2. backfill from current settings
3. introduce one-time First Run
4. move visible IA toward Profile / Styles / Settings / About
5. make Share read Profile + default Style automatically

ADR status:

- no ADR update in this round
- reason: product model was defined, but no implemented architecture boundary changed yet

## 1.11 Alpha 0.8 product simplification slice landed

PhotoMemo has now shipped the first code-level UI reduction slice that follows `Docs/ProductAudit.md`.

This round does not change architecture, renderer behavior, metadata logic, batch semantics, or export behavior.

What changed in the Main App:

- removed several dismissible guide cards from the default editing flow
- reduced explanatory copy in:
  - custom-region editing
  - supplemental content
  - output
  - anchor editing
  - permissions
- reduced the anchor list by removing the duplicated `设为当前` action
- removed the compact/header hero pills from the main editor path
- changed more visible language from:
  - configuration/workspace/template
  - toward:
  - style / current style / default style

What changed in iPhone/supporting UI:

- background status now keeps only:
  - current task
  - retry failed
  - latest failure
- the rest of the background dashboard-style detail is no longer shown in the default sheet

What changed in Share wording:

- `当前配置` now reads as `当前风格`
- confirmation, processing, retry, and follow-up wording are less technical

Docs added or updated in this round:

- `Docs/ProductScore.md`
- `Docs/ProductDirection.md`
- `Docs/ProductBacklog.md`
- `Docs/Alpha/BugList.md`
- `Docs/Alpha/UXNotes.md`

Verification for this round:

- `PhotoMemo` build passed
- `PhotoMemoiOS` build passed
- `PhotoMemoShareExtension` build passed
- `PhotoMemoTests` passed

Still not manually verified:

- real-device reaction to the lighter Main App with fewer guide cards
- whether first-time users miss any removed helper copy
- whether the reduced background-status sheet still feels sufficient in failure scenarios
- whether `当前风格` reads naturally enough in the real share sheet

## 1.10 Product audit completed

PhotoMemo now has its first repository-level UI product audit:

- `Docs/ProductAudit.md`

This round is documentation-only.

It does not modify architecture, renderer behavior, metadata logic, or workflow code.

What this audit adds:

- a page-by-page review of every current visible product surface
- a UI-element audit asking:
  - does the user need this
  - can it be removed
  - can it become automatic
  - can it move into settings
- a stronger product principle now written into `Docs/ProductDirection.md`:
  - The best PhotoMemo experience is the one users barely notice.

Highest-confidence conclusions from the audit:

- the Main App still explains itself too much
- the Share Extension should keep shrinking toward near-invisible execution
- help, troubleshooting, and low-frequency configuration actions should continue moving away from the main daily surface
- background status should keep losing prominence

## 1.8 Zero-Friction share baseline landed

PhotoMemo now has an explicit Zero-Friction share workflow baseline in both docs and the first runtime surface.

This round adds:

- `Docs/ShareZeroFrictionWorkflow.md`
- `Source/PhotoMemo/PhotoMemo/App/PhotoMemoShareWorkflowSummary.swift`
- `Tests/PhotoMemoTests/VariableTests/PhotoMemoShareWorkflowSummaryTests.swift`

What changed in product direction:

- default share no longer assumes in-flow configuration
- the Main App stays the configuration center
- the Share Extension now explicitly prefers:
  - use current configuration automatically
  - continue processing
  - write back to Photos
- advanced settings are now documented as future-optional rather than part of the default path

What changed in the current Share Extension slice:

- the extension no longer speaks like a technical handoff screen first
- it now shows a calmer automatic-processing surface
- it passively summarizes:
  - current configuration
  - current time point usage
  - output mode
- success wording now confirms receipt and continued automatic processing instead of only saying the photo entered an inbox

What intentionally did not change:

- intake persistence architecture
- render behavior
- export behavior
- batch semantics
- save-back pipeline ownership
- share preview / confirmation flow

Verification for this round:

- `PhotoMemoTests` passed
- `PhotoMemoShareExtension` build passed
- `PhotoMemoiOS` build passed
- `PhotoMemo` build passed

Still not manually verified:

- real-device share-sheet appearance on smaller iPhones
- whether the new share surface feels appropriately brief before auto-closing
- real-user understanding of the new wording in first-time use

## 1.9 Share Alpha-01 single-page confirmation landed

PhotoMemo has now taken the first Alpha usability slice on the Share Extension itself.

This round keeps the existing intake-backed architecture, but changes the extension from an automatic handoff surface into a clearer single-page confirmation surface.

What changed in this round:

- the Share Extension no longer starts immediately on open
- it now shows:
  - shared photo count
  - current configuration name
  - output destination summary
- the primary action is now an explicit confirmation button instead of an invisible auto-continue step
- success wording no longer says only “joined the inbox”
- failure states now provide retry-oriented, user-facing suggestions

Files touched in the core slice:

- `Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionViewController.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionIntakeService.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionImportResult.swift`

What intentionally did not change:

- no share preview yet
- no in-extension generate/save loop yet
- no batch-share expansion
- no smart configuration selection
- no multi-page wizard

Verification for this round:

- `PhotoMemoTests` passed
- `PhotoMemoShareExtension` build passed
- `PhotoMemoiOS` build passed
- `PhotoMemo` build passed

Not yet verified:

- real-device share-sheet layout and tap confidence
- whether the confirmation wording feels short enough in actual Photos sharing
- whether users still expect immediate completion instead of “continue processing”

## 1.7 Alpha 0.7 validation mode started

PhotoMemo has now entered a real product-validation phase.

This stage is intentionally different from the earlier architecture and feature-building rounds.

The current priority is:

- run the real product in normal life
- find friction through repeated use
- fix one issue at a time
- keep `main` usable

This round adds:

- `Docs/Alpha/Alpha01.md`
- `Docs/Alpha/BugList.md`
- `Docs/Alpha/UXNotes.md`
- `Docs/Alpha/KnownIssues.md`

The current milestone language should now prefer:

- `Alpha 0.7`

over open-ended sprint naming for this validation stage.

This round is documentation-only.

No runtime implementation changed.

## 1.5 Product direction alignment documented

PhotoMemo now has an explicit share-first product direction baseline in documentation.

This round adds:

- `Docs/ProductDirection.md`
- `Docs/UX_PRINCIPLES.md`

The direction is now stated clearly:

- PhotoMemo is a memory generator built around Apple Photos, not a photo editor
- the Share Extension is the primary workflow
- the Main App is a configuration center
- future UX decisions should reduce reading, scrolling, and duplicate information

This round is documentation-only.

No architecture, renderer, metadata, or workflow implementation changed in code.

## 1.6 Product polishing docs established

PhotoMemo now has the first product-polishing documentation layer beyond high-level direction.

This round adds:

- `Docs/ShareExtensionReview.md`
- `Docs/DesignSystem.md`
- `Docs/ProductBacklog.md`

What this round establishes:

- the Share Extension is now being reviewed as the real primary product surface
- the repository now has a concrete UI consistency baseline
- future ideas now have a backlog structure:
  - Now
  - Next
  - Later
  - Icebox

This round is documentation-only.

No runtime implementation changed.

## 1.4 v0.7.2 Alpha usability iteration started

PhotoMemo has now begun the first real Alpha usability pass.

This round intentionally avoids new features and architecture work.

The focus is simplifying the main workspace so users think about photos first and configuration second.

What changed in this round:

- photo selection was moved nearer to the top of the workspace flow
- `PhotoImporterView` now prefers Apple Photos picking first and keeps file import as a secondary path
- the compact preview flow no longer renders the workspace configuration panel twice
- the empty preview state inside scrolling containers no longer stretches into unnecessary blank space
- workspace configuration now behaves more like a direct module list:
  - tap to switch immediately
  - inline edit menu for rename / save / restore
  - no separate “current configuration” summary card
- the template section now speaks in more user-facing language and emphasizes direct editing instead of internal preset concepts
- the iOS composer now gives CJK input methods a more native path during text composition
- anchor management and editing affordances are more explicit
- manual export filename collisions now resolve with numbered suffixes instead of overwriting

Verification for this round:

- `PhotoMemo` build passed
- `PhotoMemoiOS` build passed
- `PhotoMemoShareExtension` build passed

Still waiting for hands-on validation:

- real-device `PhotosPicker` import feel
- Chinese IME behavior in longer composer sessions
- iPhone anchor editing flow

## 1.3 v0.7.1 Fixture-backed export read-back landed

PhotoMemo now has its first committed synthetic fixture binaries and real export read-back regression coverage.

This round added:

- `Tests/Fixtures/GenerateSyntheticFixtures.swift`
- `Tests/Fixtures/Synthetic/`
- `Tests/PhotoMemoTests/Support/SyntheticFixtureLibrary.swift`
- `Tests/PhotoMemoTests/ExportTests/FixtureExportReadbackTests.swift`
- `Tests/PhotoMemoTests/BatchTests/BatchFixtureCoverageTests.swift`

Coverage added in this round:

- JPEG fixture export -> read-back verification
- HEIC fixture import plus normalized export verification
- metadata-family assertions for:
  - EXIF
  - TIFF
  - GPS
  - orientation
  - dimensions
  - description fields
- batch fixture coverage for:
  - single-item enqueue
  - multi-item enqueue
  - cancellation cleanup
  - retry eligibility

One correctness fix also landed:

- `RecordCardExportService` now writes output dimension metadata using the actual rendered `CGImage` size instead of the intended render target size
- this removes a real off-by-one risk between top-level pixel dimensions and EXIF pixel dimensions

Verification for this round:

- `PhotoMemoTests` passed with 19 tests
- `PhotoMemo` build passed
- `PhotoMemoiOS` build passed
- `PhotoMemoShareExtension` build passed

## 1.2 v0.7.0 Memory Engine foundation landed

PhotoMemo has now entered its first explicitly versioned product-evolution release.

This round introduces the initial Memory Engine domain boundary without changing renderer, export, batch, or UI behavior.

New foundation types:

- `MemoryContext`
- `MemoryCalculationResult`
- `MemoryVariableProvider`

New public variables:

- `days_since`
- `years_since`
- `months_since`
- `weeks_since`
- `baby_age`
- `memory_summary` now also flows through the Memory Engine boundary

Key behavior choices:

- metadata capture time remains the source of truth
- existing anchor summaries remain preserved when already available
- future-relative anchors never produce negative `*_since` values
- baby-age formatting avoids awkward `0岁...` wording

Docs added:

- `Docs/MemoryEngine.md`
- `Docs/ADR/ADR-006-MemoryEngineFoundation.md`

Verification for this round:

- `PhotoMemoTests` passed, including the dedicated `MemoryEngineTests` suite
- `PhotoMemo` build passed
- `PhotoMemoiOS` build passed
- `PhotoMemoShareExtension` build passed

Process note:

- `v0.7.0` starts the repository's forward-looking version rhythm
- older `Sprint-*` notes remain as historical engineering records, but future release-facing summaries should prefer semantic version labels

## 1.1 Regression verification foundation landed

Sprint-009 moves PhotoMemo into the first real engineering-confidence stage.

This round added verification foundation docs:

- `Docs/FixtureSpecification.md`
- `Docs/RegressionMatrix.md`
- `Docs/AcceptanceCriteria.md`
- `Docs/CIReadiness.md`

This round also added repository-level test/fixture structure:

- `Tests/Fixtures/`
- `Tests/PhotoMemoTests/`

Important current decisions:

- no copyrighted real photos are committed yet
- fixture filenames and metadata requirements are now reserved through:
  - `Tests/Fixtures/FixtureManifest.json`
- the first automated layer is intentionally pure logic smoke coverage, not snapshot-heavy or Photos-integration-heavy testing

`PhotoMemoTests` now exists as a real Xcode target and shared scheme.

Current smoke coverage includes:

- EXIF timezone parsing
- GPS sign normalization
- metadata-derived aspect ratio / megapixels / location display
- `MetadataContext` capture-timezone date-field generation
- `TemplateVariableEngine` token replacement
- `RecordCardBuildService` description-writing switch behavior

Build and test verification for this round:

- `PhotoMemoTests` test passed
- `PhotoMemo` build passed
- `PhotoMemoiOS` build passed
- `PhotoMemoShareExtension` build passed

What still remains intentionally deferred:

- committed real fixture binaries
- renderer snapshot coverage
- export-file binary diff tests
- Photo Library integration automation
- batch end-to-end fixture execution

## 1.0 Output integrity verification sprint landed

Sprint-008 focused on verification and product reliability, not feature expansion.

This round added six dedicated docs:

- `Docs/ExportMetadataAudit.md`
- `Docs/ExportReadbackVerification.md`
- `Docs/JPEG_HEIC_Compatibility.md`
- `Docs/BatchExportReliability.md`
- `Docs/LivePhotoAssessment.md`
- `Docs/OutputIntegrityReport.md`

What this round clarified:

- PhotoMemo's export path is currently a pass-through-plus-patching metadata strategy:
  - it starts from original `sourceProperties`
  - rewrites final dimensions and orientation
  - conditionally writes export description fields
- output integrity is strongest today for:
  - still-photo JPEG-first workflows
  - deterministic batch export
  - dimension/orientation normalization
- output integrity is not yet fully guaranteed for:
  - ICC / color-profile preservation
  - explicit JPEG / HEIC parity
  - Live Photo paired-resource support
  - complete metadata round-trip validation for description/comment fields

One correctness fix also landed in this sprint:

- disabling `shouldWritePhotoDescription` now truly stops PhotoMemo from writing export description metadata
- the corresponding UI preview text now matches that behavior

Build verification for this round:

- `PhotoMemo` build passed
- `PhotoMemoiOS` build passed
- `PhotoMemoShareExtension` build passed

Architecture note:

- no architecture redesign was introduced
- no renderer redesign was introduced
- no workspace/editor migration was performed

## 0.8 Metadata audit and roadmap docs were added

The latest non-code sprint produced a dedicated metadata review set:

- `Docs/MetadataPipelineReview.md`
- `Docs/VariableEngineRoadmap.md`
- `Docs/MetadataTechnicalDebt.md`
- `Docs/MetadataRoadmap.md`

What this round clarified:

- PhotoMemo already has one real metadata-read path:
  - `PhotoMetadataReader -> PhotoMetadata -> MetadataContext / CardVariableProvider -> TemplateVariableEngine -> Renderer / Export`
- the iOS share extension does not create a second EXIF pipeline:
  - it persists files and configuration only
  - real metadata reading still begins in the main app import path
- the biggest current metadata gaps are:
  - location enrichment is modeled but not populated
  - variable catalog coverage lags behind runtime context coverage
  - time/GPS normalization and metadata regression coverage should be hardened before expanding variable surface

Recommended next metadata sprint from these docs:

- `Sprint-007: Metadata Normalization And Catalog Alignment`

## 0.9 Metadata normalization and catalog alignment landed

Sprint-007 is now implemented without changing the architecture baseline.

Core results:

- `PhotoMetadata` now acts as the metadata normalization center
- canonical metadata inventory now exists in code:
  - `PhotoMetadata.canonicalInventory`
- canonical runtime keys now exist in code:
  - `MetadataContext.Key`
- `PhotoMetadataReader` now normalizes:
  - timezone suffix extraction
  - GPS sign handling
  - altitude reference
- public variable catalog now exposes the previously missing high-value metadata fields:
  - `location`
  - `location_display`
  - `latitude`
  - `longitude`
  - `altitude`
  - `country`
  - `province`
  - `city`
  - `district`
  - `weekday`
  - `capture_date_short`
  - `capture_time_short`
  - `capture_timezone`
  - `orientation`
  - `aspect_ratio`
  - `megapixels`
  - `lens_brand`
  - `memory_summary`

This round also added three new metadata docs:

- `Docs/MetadataInventory.md`
- `Docs/VariableCatalogAlignment.md`
- `Docs/MetadataNormalizationPlan.md`

Build verification for this round:

- `PhotoMemo` build passed
- `PhotoMemoiOS` build passed
- `PhotoMemoShareExtension` build passed

Architecture note:

- no ADR update was required
- no new architectural layer was introduced

## What Was Completed In This Round

### 0. Project-local Swift/iOS skills were added for the next PhotoMemo phase

The project-local skills folder now also includes:

- `activitykit`
- `background-processing`
- `ios-simulator`
- `photokit`
- `swift-testing`
- `swiftui-patterns`

Why these were added:

- `photokit` directly supports photo-library permission, picker, and save-back work
- `background-processing` matches the share-intake and batch/export direction
- `activitykit` prepares for iPhone progress surfaces like Dynamic Island / Lock Screen
- `swiftui-patterns` helps keep `MainView` and the future iPhone UI aligned with modern state/composition rules
- `swift-testing` gives a better path for new Swift-native tests
- `ios-simulator` helps future iPhone regression, privacy, push, and location validation

These were installed into:

- `Source control path`: `/Users/rui/Desktop/PhotoMemo/.codex/skills`

Important current-session note:

- the skills are already present in the project and readable on disk
- but an already-open Codex session may not auto-refresh its built-in skill registry
- in practice, a restart or a fresh session is the stable way to make them appear as normal installed skills

### 0.1 iPhone background-status groundwork was added

The latest iPhone-facing slice also adds a lightweight intermediate status layer:

- `Source/PhotoMemo/PhotoMemo/App/PhotoMemoBackgroundStatusService.swift`

What it does:

- observes `BatchQueueStore`
- resolves the most relevant external/background job snapshot
- normalizes progress, phase title, retryability, and status text into one stable model

Why this matters:

- future iPhone progress surfaces should not couple directly to `BatchQueueStore`
- the next Dynamic Island / Lock Screen / iPhone shell work can build on this snapshot service instead of re-deriving queue state ad hoc

### 0.2 iPhone now has a dedicated background-status entry without polluting the main editor

The latest follow-up iPhone slice also adds:

- a top-right background-status entry in `PhotoMemoiOSHomeView`
- a dedicated sheet:
  - `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSBackgroundStatusSheet.swift`

Behavior choice for this slice:

- the main iPhone editor remains focused on template calibration and preview
- background progress is not pushed back into the main editing content area
- users can open a separate sheet to check queue status, failure summaries, and retry failed items

### 0.3 iPhone background-status updates are now live, and active jobs get extra background run time

The latest follow-up after that also tightens the iPhone shell behavior:

- `PhotoMemoiOSHomeView` now directly observes both:
  - `BatchQueueStore`
  - `PhotoMemoBackgroundStatusService`
- the background-status sheet now reads live queue state instead of only receiving a one-time snapshot payload
- iPhone app runtime now owns:
  - `PhotoMemoiOSBackgroundExecutionService`
- when the app moves to the background while `BatchQueueStore` is still processing, PhotoMemo now requests a standard iOS background task window so the current batch has a better chance to keep progressing before suspension

Why this matters:

- the iPhone background-status entry is no longer just structurally present; it now reflects queue changes in real time
- the app is better aligned with the intended workflow of “share photo -> leave the foreground -> let PhotoMemo continue for a while”
- this improves reliability without turning the main calibration UI into a progress dashboard and without changing the underlying import-render-export behavior

### 0.4 iPhone background-status sheet is now closer to a formal control center

The latest follow-up also upgrades the dedicated iPhone background-status sheet:

- adds a clearer processing-focus card:
  - current photo
  - task state
  - latest update time
- adds a per-job configuration card:
  - template
  - anchor
  - description-writing mode
  - save destination summary
- adds a current-job recent-records card so users can see which photos are:
  - currently running
  - failed
  - queued
  - completed

Why this matters:

- users no longer need to infer everything from one hero string and a failure list
- the sheet now behaves more like a real mobile-side background control center while still staying outside the main editor
- this also creates a cleaner stepping stone before any future ActivityKit / Dynamic Island integration

### 0.5 ActivityKit-ready bridge groundwork now exists without forcing a widget target yet

The latest follow-up also adds a dedicated bridge layer for future Live Activity work:

- shared display titles were normalized in `BatchProcessing` for:
  - `BatchJobState`
  - `BatchJobLaunchSource`
- added a Live Activity payload model:
  - `Source/PhotoMemo/PhotoMemo/iOS/Activity/PhotoMemoBackgroundLiveActivityPayload.swift`
- added a bridge service:
  - `Source/PhotoMemo/PhotoMemo/iOS/Activity/PhotoMemoiOSLiveActivityBridgeService.swift`
- iPhone app runtime now owns that bridge service so future ActivityKit driver code can consume one stable source instead of re-deriving queue state again

What this bridge does:

- converts `PhotoMemoBackgroundStatusService` output into ActivityKit-ready attributes and content-state payloads
- tracks the current projected job and any obsolete job IDs that a future ActivityKit driver should end
- keeps Live Activity preparation separated from the main editor and from the raw queue model

Why this matters:

- the next Dynamic Island / Lock Screen slice can focus on the actual ActivityKit lifecycle and widget presentation
- PhotoMemo avoids coupling future Live Activity code directly to `BatchQueueStore`
- this keeps the current iteration small and build-safe while still moving the iPhone roadmap forward

### 0.6 App-side Live Activity driver is now wired, with a safe fallback when presentation is not fully available yet

The latest follow-up after that takes one more small step:

- adds an app-side driver:
  - `Source/PhotoMemo/PhotoMemo/iOS/Activity/PhotoMemoiOSLiveActivityDriverService.swift`
- the driver now:
  - observes `PhotoMemoiOSLiveActivityBridgeService`
  - restores any existing PhotoMemo activities on launch
  - requests a new Live Activity for an active external job
  - updates the activity while progress changes
  - ends the activity when the job becomes terminal or obsolete
- `PhotoMemoiOS` target now declares:
  - `NSSupportsLiveActivities = YES`

Safety choice for this slice:

- if the current environment can compile ActivityKit but still cannot successfully request a Live Activity, the driver disables repeated request attempts instead of spamming the pipeline with the same failure over and over

Why this matters:

- the iPhone app now has a real ActivityKit lifecycle driver, not only payload preparation
- the next slice can focus on the widget / Lock Screen / Dynamic Island presentation side instead of redoing app-side lifecycle work
- the current implementation still keeps risk controlled because it fails closed when full presentation support is not ready

### 0.7 Live Activity presentation and widget-extension wiring are now buildable end to end

The latest follow-up first added a presentational shell:

- `Source/PhotoMemo/PhotoMemo/iOS/Activity/PhotoMemoLiveActivityPresentation.swift`

What it contains:

- a `Widget` definition for the PhotoMemo Live Activity presentation
- Lock Screen layout
- Dynamic Island compact / minimal / expanded regions
- shared icon, tint, and status helpers that read from the new ActivityKit-ready payload

This line then moved past the project-wiring blocker:

- `Source/PhotoMemo/PhotoMemoWidgetExtension/PhotoMemoWidgetExtensionBundle.swift`
- `Source/PhotoMemo/PhotoMemoWidgetExtension-Info.plist`
- `Source/PhotoMemo/ShareExtension-Info.plist`
- `Source/PhotoMemo/PhotoMemo.xcodeproj/project.pbxproj`

What was resolved:

- the share extension plist now includes the base bundle keys Xcode expects, so the embedded extension no longer collapses to a `(null)` bundle identifier
- `PhotoMemoiOS` now embeds both:
  - `PhotoMemoShareExtension.appex`
  - `PhotoMemoWidgetExtension.appex`
- the new widget extension target now builds cleanly and hosts:
  - `PhotoMemoLiveActivityWidgetDefinition`
  - shared Live Activity payload/presentation files

Why this matters:

- the UI/presentation side for Live Activities is no longer just a shell inside the app target; it now has a real extension target and real embedded product output
- PhotoMemo's iPhone line has crossed from “ActivityKit groundwork only” into “project can build app + share extension + widget extension together”
- the next Live Activity slice can focus on runtime behavior and device validation instead of re-fighting `xcodeproj` embed wiring

### 1. Addy Osmani skills installed for future development workflow

The following skills are now installed in local Codex:

- `spec-driven-development`
- `planning-and-task-breakdown`
- `incremental-implementation`
- `test-driven-development`
- `code-review-and-quality`
- `frontend-ui-engineering`

Recommended usage pattern for future work:

1. `/spec`
2. `/plan`
3. `/build`
4. `/test`
5. `/review`

### 2. MainView refactor continued in controlled slices

`MainView.swift` is still large, but it has been meaningfully reduced and split into focused subviews.

Recent extracted files:

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+MemoryProgress.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+OutputSection.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+Permissions.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+ComposerEditor.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+ComposerPanels.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+TemplatePanels.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+SetupPanels.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+PreviewPanels.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+StateModels.swift`

MainView line-count trend observed in this refactor stream:

- `5706`
- `5096`
- `4885`
- `4614`
- `4529`
- `4314`
- `4164`
- `3974`
- `3648`
- `3496`
- `2905`
- `2842`
- `1186`
- `467`
- `300`
- `228`
- `112`
- `72`

Current result:

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift` is now acting more like a coordinator
- its remaining coordinator state is now partially grouped through `MainPresentationState`, `MainAlertState`, and `MainEditorSessionState`
- template setup, logo setup, photo import summary, anchor setup, live preview shell, and multiple editor/panel regions have been extracted
- composer session state, workspace configuration lifecycle, and export/save actions have now also been split into dedicated `MainView+*.swift` files
- dead block-style composer helpers and their unused widget file have now been removed instead of being kept as stale compatibility code
- some dead UI helpers were removed after extraction to prevent stale code from remaining in `MainView`

### 3. Template-calibration UI structure is more stable

Completed structural extractions now cover:

- template section
- template rename sheet
- custom content section
- logo section
- photo section
- anchor section
- preview/detail display shell
- inline custom-region editor
- variable library panels
- field editor wrappers
- output / permission panels

This means future MainView work should prioritize:

- any lingering state-heavy editing helpers that still live inline
- any remaining preview-adjacent helper logic that is still coupled to coordinator code
- any permission/scene lifecycle actions that still sit beside unrelated coordinator code

### 4. Immers-style white border direction has already been integrated

Product/UI decisions already established in this workstream:

- only borrow the bottom white-bar design language from Immers
- keep PhotoMemo content centered on memory + smart modules, not generic EXIF-only filler
- unify the old badge semantics toward `Logo 标识`
- for `immersWhite`, when no custom logo is selected, use a classic Apple mini logo fallback
- horizontal layout was tuned to better match the reference direction while still staying consistent with PhotoMemo

Key related files:

- `Source/PhotoMemo/PhotoMemo/Renderers/ImmersWhiteRenderer.swift`
- `Source/PhotoMemo/PhotoMemo/Renderers/RecordCardRenderer.swift`
- `Source/PhotoMemo/PhotoMemo/Models/TemplatePreset.swift`
- `Source/PhotoMemo/PhotoMemo/Models/Template.swift`
- `Source/PhotoMemo/PhotoMemo/Models/TemplateItem.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Template/BadgePickerView.swift`

### 5. Permission and content wording refinement started

Latest refinement work now also covers:

- denied photo-library permission no longer pretends the system prompt can be re-shown; the UI now guides the user toward System Settings
- birthday-style smart text suppresses awkward under-one-year wording like `0岁8个月`
- the `补充信息` section now uses a single card and treats the checkbox as custom batch-description mode; when it is off, PhotoMemo falls back to the rendered right-bottom content

### 6. Multi-configuration workspace controls are now in progress

Latest MainView work now also adds a real right-side configuration workflow:

- three persisted local configuration slots
- one active slot at a time
- right-side save / restore-default actions instead of the old toolbar-only save entry
- a right-side operation-guide menu and sheet
- dismissible helper cards for anchor, smart-module, and supplemental-content guidance

Behavior expectations for this slice:

- switching slots should refresh the left-side configuration state and right-side preview together
- unsaved slots should fall back to `模板 1 / 2 / 3` default skeletons
- the active slot should remain aligned with the batch queue's default configuration snapshot

### 7. Workspace naming and help-center navigation were refined

The latest follow-up refinement now also adds:

- custom naming for each of the three configuration slots
- a dedicated rename sheet for the active slot
- a grouped right-side help-center menu instead of a flat operation-guide list
- a formal split-view help center with category navigation and topic detail panes

Important behavior choices:

- slot renaming changes only the workspace slot label, not the template name
- restoring a slot to its default skeleton clears the saved snapshot but keeps the custom slot name
- already-dismissed inline tips remain removable from the left side, while the full explanation stays available inside the help center

### 8. Left-side clutter and output controls were reduced further

The latest cleanup pass now also does the following:

- memory-progress guidance is dismissible like the other helper cards
- the personalized-region guidance is dismissible instead of being hard-coded inline text
- the supplemental-content area is truly reduced to a single card
- the permission block no longer occupies the sidebar after both permissions are granted
- the help center no longer keeps a separate permission topic after the permission flow is already understood
- the output area now focuses on album selection plus save-to-library, without the extra metadata-validation buttons

### 9. Dead validation UI paths were cleaned out of MainView

The latest internal cleanup pass now also removes:

- the no-longer-reachable metadata-validation sheet flow from `MainView`
- the old metadata debug view file that was only serving that removed flow
- the collapsed-permission-summary branch that no longer matters now that the whole permission block hides after authorization

This keeps the UI simplification aligned with the actual coordinator code instead of only hiding old actions visually.

### 10. Custom-region editing moved closer to visual module composition

The latest refinement slice now also does the following:

- the extra top control/help block under `个性化区域` is gone from the left side
- the old inline raw-token editing path was removed from `MainView`
- manual text is now added and edited as its own literal chip inside the same single-line module flow
- `识别数据` and `智能数据` keep acting as direct insert buttons into the explicitly selected region
- user-facing help copy in the editor/help center no longer leans on raw `{{token}}` syntax
- the `补充信息` and `输出` section explanations now use dismissible guide cards, with the fuller explanation still preserved in the right-side help center

Behavior expectations for this slice:

- tapping a region still defines the only valid insertion target
- inserted EXIF / smart modules should remain human-readable instead of exposing raw tokens
- users should be able to keep composing around modules without switching to a separate text-entry sheet
- the template section should show human-readable default-output summaries instead of raw template tokens

### 11. Custom-region editing now favors cursor-based inline composition

The latest follow-up slice now also does the following:

- the four custom regions no longer require a separate “添加文字 / 编辑文字” action
- users can click directly into a region and type their own short phrase inline
- EXIF and smart-module buttons now insert into the current text cursor position instead of inserting as separate manual-text chips
- inserted modules are shown as human-readable inline labels such as `〔年岁〕`, so the editor no longer exposes raw `{{token}}` syntax during normal editing
- the right-side help-center wording for the custom-region topic now reflects the new cursor-first editing model

Behavior expectations for this slice:

- clicking a region should place or restore the caret inside that region
- clicking a module button should insert that module exactly at the current caret or selected text range
- users should be able to continue typing before or after an inserted module without opening any extra sheet
- the underlying template still persists real raw tokens, so preview/render/export behavior should remain on the existing pipeline

### 12. Inline module visuals were restored closer to block-style editing

The latest follow-up slice now also does the following:

- inline module labels inside the four custom regions are rendered with block-like highlighted styling instead of appearing as plain text only
- deletion near a module now expands to the full inline module label, so backspace/delete behaves closer to removing one whole block
- editor-side display mapping now also covers common composite tokens such as `camera_summary`, avoiding mixed output like one readable label plus one raw token

Behavior expectations for this slice:

- a module inserted at the caret should look visually distinct from ordinary typed text
- when the caret is immediately next to a module, delete/backspace should remove the whole module display label in one action
- display-only labels must still map back to the original raw template tokens before preview/render/export

### 13. Share-intake persistence and fallback hardening advanced again

The latest iOS-readiness slice focused on making the external intake path safer for novice users without changing the main calibration UI.

Completed in this round:

- added a shared album-selection helper:
  - `Source/PhotoMemo/PhotoMemo/App/PhotoMemoAlbumSelection.swift`
- removed the share-extension snapshot path's dependence on `PhotoAlbumOption` constants from the photo-library export layer
- strengthened `ExternalPhotoIntakeStore` so persistence failure now cleans up managed inbox copies instead of leaving orphaned temporary files behind
- deduplicated repeated URLs before persisting or queueing external-intake requests
- `PhotoMemoAppRuntime.flushExternalRequests()` now filters out missing source files before enqueuing, so stale requests degrade into smaller valid batches instead of failing later at import time
- `PhotoMemoShareExtensionIntakeService` now:
  - accepts partial success instead of treating one provider failure as a whole-share failure
  - reports imported / skipped / failed counts back to the share UI
  - tries a safer fallback path using file URLs or raw image data when direct file representation is unavailable
  - does **not** fall back to `UIImage -> JPEG` rewriting, to avoid silently stripping EXIF or changing the source photo bits during intake

Why this matters:

- it stays aligned with the "ExternalIntake is pure temporary storage" decision
- it reduces invisible failure modes before the real import/render/export pipeline starts
- it keeps metadata-retention priorities ahead of convenience fallbacks

Verification for this round:

- passed:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoShareExtension -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PhotoMemoShareExtensionDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PhotoMemoIOSDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- observed:
  - only the existing Xcode destination-selection warning on macOS build
- not yet manually verified:
  - real Photos share-sheet input that provides only `loadItem` data and not file representation
  - multi-photo share where one or more items disappear before the host app flushes the request
  - user-facing wording and timing of the share-extension success/partial-success message on device

### 14. Share-extension compile surface was reduced to a small shared core

The latest architecture slice focused on trimming `PhotoMemoShareExtension` so it only compiles what the share-intake pipeline actually needs.

Completed in this round:

- added a synchronized-group target-exception set in:
  - `Source/PhotoMemo/PhotoMemo.xcodeproj/project.pbxproj`
- excluded clearly app-only files from the share-extension target, including:
  - main app shells
  - `Views/*`
  - renderers
  - queue / export / permission services
  - unused engines and helper extensions
- extracted `ExternalPhotoIntakeRequest` into its own shared file:
  - `Source/PhotoMemo/PhotoMemo/App/ExternalPhotoIntakeRequest.swift`
- this removes the previous coupling where `ExternalPhotoIntakeStore` depended on `ExternalPhotoIntakeCenter.swift` just to see the request model
- refined the share-extension success message so partial-success feedback only shows the non-zero skipped / failed counts

Current result:

- the share-extension target now compiles against a much smaller shared core
- the generated `PhotoMemoShareExtension.SwiftFileList` is now `19` lines, down from the previous much broader compile surface that still included:
  - `MainView`
  - preview/template/anchor views
  - app entry shells
  - queue/export/permission services

Why this matters:

- iOS share flow is now less coupled to the macOS calibration UI
- future extension-specific bugs become easier to isolate
- future share-flow testing is less likely to be blocked by unrelated UI/service regressions

Verification for this round:

- passed:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoShareExtension -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PhotoMemoShareExtensionDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PhotoMemoIOSDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- observed:
  - only the existing Xcode destination-selection warning on macOS build
- not yet manually verified:
  - real share-sheet behavior after the new target slimming on device
  - whether any third-party share source relies on a file path or raw data shape not yet seen in manual testing

## Behavior Rules Preserved During Refactor

These behaviors were intentionally preserved and should not be reverted:

- variable insertion must target an explicitly selected custom region
- no implicit fallback that silently inserts into the right-bottom region
- template switching, restoring defaults, and template rename must refresh composer editing state
- preview-side template calibration must stay connected to the real render/export chain

## Verification Status

Recent verification command:

```bash
xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build
```

Status:

- build passes
- only Xcode destination-selection warning observed
- no new compile error from the latest MainView extraction rounds
- there is still no separate automated test target in the current Xcode project, so refactor validation is currently build-first plus manual regression checks

## Current Technical Debt

### Coordinator shell is now thin, but needs semantic cleanup

`Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift` is now down to about `72` lines, which is a strong coordinator-shell result.

The remaining debt is no longer raw file size. It is now about whether the remaining state is grouped at the right boundary and whether access control / ownership are as clear as the new structure suggests.

### Multi-config and in-app guidance still need a dedicated design slice

The newly requested three-slot configuration system and right-side operation guide are both product-shaping changes. They should be implemented as a dedicated state/persistence redesign instead of being mixed into small UI tweaks.

### Manual UI regression checks are still needed

Builds are passing, but some refactor rounds were verified mainly by compilation and structure review. Manual checks remain important for:

- template rename flow
- anchor selection flow
- photo import flow
- logo fallback behavior on `immersWhite`
- preview/export visual parity

## Recommended Next Steps

### Near-term

1. Tighten access control now that the `MainView` coordinator shell has settled
2. Revisit badge / output / workspace bindings and move any obviously local binding logic beside the related panels
3. Run a deliberate manual check for:
   - template switching
   - template rename
   - anchor selection
   - photo import
   - live preview rendering after import
   - white-border logo fallback

### Product hardening

1. Continue preview/export parity work
2. Continue metadata-retention validation
3. Harden failed-task retry and library save feedback

### Architecture

1. Keep reducing macOS-only assumptions where practical
2. Preserve future iOS migration room
3. Avoid adding new feature surface faster than the real processing chain can support

## Best Entry Files For A New Session

Read in this order:

1. `README.md`
2. `AI_CONTEXT.md`
3. `HANDOFF.md`
4. `AGENTS.md`
5. `Docs/CURRENT_STATUS.md`
6. `Docs/DEVELOPMENT_PLAN.md`

Then inspect:

- `git status`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift`
- the newest `MainView+*.swift` extraction files

## 2026-06-19 Follow-Up

This round added a dedicated inline-composer display engine:

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+ComposerDisplayEngine.swift`

Purpose:

- stop treating every visible `〔...〕` label as a real token
- track real inserted modules by span instead of regex-only text matching
- keep module-aware selection/deletion behavior aligned across macOS and UIKit

Related notes kept for the next session:

- optimization log:
  - `Docs/OPTIMIZATION_LOG_2026-06-19.md`
- competitor and product-direction notes:
  - `Docs/COMPETITOR_NOTES_2026-06-19.md`
- iOS readiness audit:
  - `Docs/IOS_READINESS_2026-06-19.md`
- manual regression checklist:
  - `Docs/MANUAL_REGRESSION_CHECKLIST_2026-06-19.md`

MainView re-review result for this follow-up:

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift` is now around `3621` lines
- the next most valuable extractions are:
  - composer session state
  - workspace configuration lifecycle
  - export/save actions

## 2026-06-19 External Intake Foundation Follow-Up

The latest infrastructure slice now also does the following:

- adds a shared app-container helper:
  - `Source/PhotoMemo/PhotoMemo/App/PhotoMemoSharedContainer.swift`
- adds a persisted intake inbox:
  - `Source/PhotoMemo/PhotoMemo/App/ExternalPhotoIntakeStore.swift`
- updates `ExternalPhotoIntakeCenter` so external image requests are no longer in-memory only
- updates settings, permission-primer state, and batch-queue persistence to read/write through a shared defaults entry point
- updates app runtime activation flow so persisted intake requests are automatically flushed on launch/activation without adding any progress UI back into the main screen

Behavior expectations for this slice:

- external intake requests should survive app relaunch instead of being lost with process memory
- the default batch configuration snapshot used for background intake should stay aligned with the current saved workspace configuration
- the main UI should remain a calibration center only; no queue/progress panel should reappear

## 2026-06-19 External Intake Cleanup Follow-Up

The latest follow-up now also does the following:

- teaches `ExternalPhotoIntakeStore` to clean up only the managed source files that PhotoMemo copied into the shared `ExternalIntake` inbox
- wires that cleanup into safe terminal paths:
  - after a task completes successfully
  - when a queued/running job is explicitly cancelled

Behavior expectations for this slice:

- shared intake files should no longer accumulate forever after successful background processing
- failed tasks should still retain their managed source files so retry remains possible
- original user-selected files outside the managed intake inbox must never be deleted by this cleanup path

## 2026-06-19 External Intake Orphan Cleanup Follow-Up

The latest follow-up now also does the following:

- exposes the currently referenced managed source URLs from `BatchQueueStore`
- runs an orphaned managed-intake cleanup scan during app-side external-intake refresh
- removes inbox child files/directories that are no longer referenced by any pending request or persisted batch task

Behavior expectations for this slice:

- a previously interrupted app session should not leave unmanaged `ExternalIntake` directories accumulating forever
- queued, running, or failed-for-retry managed sources must remain intact while still referenced by queue state

## 2026-06-19 Share Extension Skeleton Follow-Up

The latest follow-up now also does the following:

- adds a minimal iOS share-extension intake service that writes incoming shared images into the existing shared `ExternalIntake` inbox
- adds a minimal share-extension view controller and extension plist/entitlement files
- wires a real `PhotoMemoShareExtension` target into the Xcode project
- keeps the main iOS app entry isolated behind a compilation condition so the extension target can compile cleanly without conflicting `@main` app entrypoints

Behavior expectations for this slice:

- the repository now contains a real compilable share-extension target rather than only “future-ready” architecture
- shared images can be persisted into the same intake pipeline foundation already used by the app runtime
- the main calibration-center UI remains unchanged; this slice is project/runtime groundwork only

## 2026-06-19 Strict Temporary Intake Follow-Up

The latest follow-up now also does the following:

- tightens the shared `ExternalIntake` copies into a strict temporary-file policy
- cleans managed intake source files on all terminal outcomes, including failed tasks
- marks failures that have lost their managed temporary source as non-retryable
- trims persisted terminal job history before saving queue state

Behavior expectations for this slice:

- managed intake files should not linger as a long-term cache after success, cancellation, or failure
- retry should remain available only for failures whose source is still genuinely available
- queue history should stop growing without bound across long-term usage

## 2026-06-19 Partial Failure Semantics Follow-Up

The latest follow-up now also does the following:

- refines batch-result semantics so small failure counts are treated as exceptions instead of making the whole batch feel like a total failure
- updates failure summaries and completion notifications to prefer “mostly completed, with exceptions” language when most photos succeeded
- hides retry actions for failures that no longer have a real recoverable source under the strict temporary-file policy

Behavior expectations for this slice:

- when a large batch finishes with only one or a few failures, users should still feel that the batch fundamentally completed
- failure handling remains explicit, but it no longer overstates the impact of isolated exceptions

## 2026-06-19 Share Extension Warning Cleanup

The latest follow-up now also does the following:

- moves the share-extension plist outside the synchronized `PhotoMemo/` group root
- points `PhotoMemoShareExtension` at the new external plist path
- removes the previous share-extension `Info.plist` bundle-resource warning during build verification

## 2026-06-19 Share Extension Slimming Follow-Up

The latest follow-up now also does the following:

- extracts a lightweight shared batch-configuration snapshot reader:
  - `Source/PhotoMemo/PhotoMemo/App/SharedBatchConfigurationSnapshotService.swift`
- moves the share-extension intake flow away from the full `SettingsService` dependency
- keeps the extension reading only the minimum persisted configuration inputs it needs to enqueue shared photos consistently

Behavior expectations for this slice:

- the share extension should now rely on a smaller, clearer configuration boundary
- future target slimming can focus on removing additional unnecessary app-only compile dependencies without changing the user-visible flow

## 2026-06-19 Refactor Completion

This follow-up successfully landed the three extractions that were queued in the previous note:

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+ComposerSession.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+WorkspaceConfigurationState.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+ExportActions.swift`

What moved out of `MainView.swift`:

- editor display text / selection / module-span session state
- workspace-slot save, switch, restore-default, and snapshot application flow
- photo-library permission prompt, album reload, and save-to-library actions

Updated structure result:

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift` is now around `2905` lines
- build succeeds again after removing the leftover duplicate legacy method definition
- the coordinator file is now meaningfully less responsible for low-level editing and save-flow mechanics

One more safe follow-up extraction has already landed after that:

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+PermissionLifecycle.swift`

That file now owns:

- first-appearance permission refresh
- active-scene permission refresh
- primer-sheet permission request flow
- notification permission request feedback

Latest line-count result after this extra slice:

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift` is now around `2842` lines

This workstream then continued with a more aggressive but still behavior-preserving cleanup:

- removed the no-longer-used block-style composer item state, chip widgets, literal-composer sheet, and scrubber helpers
- extracted `MainView+DerivedState.swift`
- extracted `MainView+CoordinatorSupport.swift`
- extracted `MainView+TemplateEditingActions.swift`

Latest line-count result after that cleanup:

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift` is now around `1186` lines

The refactor then continued with two more coordinator-focused extractions:

- extracted `MainView+PresentationState.swift`
- extracted `MainView+LayoutSections.swift`

That moved:

- rename-sheet / help-center sheet presentation and local draft state
- sidebar/detail assembly and section-level view composition

Latest line-count result after that follow-up:

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift` is now around `467` lines

One final light cleanup also landed immediately after:

- extracted `MainView+UIPrimitives.swift`

That moved:

- `MainFieldSlot`
- palette and card/chip style primitives
- small shared layout wrappers used by the main editor flow

Latest line-count result after this step:

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift` is now around `300` lines

The coordinator shell then kept shrinking in two small, safe follow-ups:

- extracted `MainView+ModalAndLifecycle.swift`
- extracted `MainView+Feedback.swift`

That moved:

- anchor sheet / rename sheet / help sheet / alert wiring
- onAppear / onChange lifecycle routing
- alert presentation helper and local preview stub

Latest line-count trend after these last follow-ups:

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift` is now around `228` lines
- then around `112` lines
- and after grouping the remaining editor session state, around `72` lines

Verification for this completion slice:

- passed:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- observed:
  - only the existing Xcode destination-selection warning
- not yet manually verified:
  - permission primer -> authorize -> album refresh flow
  - switching workspace slots while custom-region editor caret is active
  - save-to-library success and failure alerts against a real photo

One more light state-ownership follow-up has now landed:

- added `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+StateModels.swift`
- grouped the remaining editor-session fields into `MainEditorSessionState`
- moved `focusedField`, display texts, selections, and module spans under that single coordinator-facing state model

Latest result after this follow-up:

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift` is now about `72` lines
- the coordinator shell now mostly declares service/state ownership and forwards `body` to `mainScene`
- the earlier `MainPresentationState` / `MainAlertState` grouping is now joined by `MainEditorSessionState`, which makes the remaining state easier to reason about without changing editor behavior

Verification for this extra slice:

- passed:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- observed:
  - only the existing Xcode destination-selection warning
- not yet manually verified:
  - workspace-slot switching while editor caret is active
  - live caret preservation while repeatedly inserting EXIF / smart modules
  - save-to-library success and failure alerts against a real photo

Next three most valuable areas after this slice:

1. selective access-control tightening after the refactor settles
2. badge/output/workspace bindings that can move beside their related panels
3. manual regression coverage for caret routing, slot switching, and export feedback now that the coordinator shell is structurally stable

## 2026-07-02 V1 Root View Freeze Follow-up

This follow-up continued the V1 iOS entry decomposition without touching renderer, export, share-extension behavior, or the Memory Engine boundary.

What landed in this slice:

- added `Source/PhotoMemo/PhotoMemo/iOS/Views/V1DraftRuntimeCoordinator.swift`
- moved the remaining draft-editing runtime bridge out of `PhotoMemoiOSV1View`
- `PhotoMemoiOSV1View` now delegates:
  - draft lookup fallback
  - text/module mutation application
  - dirty-state propagation
  - region preview refresh
  - batch dynamic preview refresh
  - draft bootstrap rehydration

What this specifically removed from the root view:

- direct ownership of `V1DraftMutationCoordinator.State` bridging
- direct ownership of `V1DraftMutationCoordinator.Update` application
- local preview-refresh policy for draft mutations
- local draft-bootstrap -> preview-refresh chaining

Current line-count result:

- `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift` moved from about `2130` lines down to about `2020` lines in this follow-up

Current remaining high-value root-view seams after this extraction:

1. root runtime wiring block that still constructs multiple coordinators in-view
2. quick-action photo intake runtime follow-up
3. subject/birthday driven preview-effect policy
4. diagnostics/settings runtime state wrapper

Verification for this slice:

- passed:
  - `git diff --check`
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOSV1 -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PhotoMemoV1IOSRuntime CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO build`
- attempted but environment-blocked:
  - targeted macOS `PhotoMemoTests` runs/build-for-testing for:
    - `V1DraftRuntimeCoordinatorTests`
    - `V1DraftBootstrapCoordinatorTests`
    - `V1DraftOrchestrationCoordinatorTests`
    - `V1PreviewSyncCoordinatorTests`
- blocking condition:
  - current sandboxed macOS `xcodebuild` test/build-for-testing path is failing in SwiftUI macro/plugin loading and distributed test-notification plumbing (`swift-plugin-server` / sandbox notification posting), outside this slice's edited files

Manual verification still not done in this follow-up:

- iPhone-side editor typing/caret behavior after repeated smart-module insertion
- preset switching while draft content is already dirty
- subject switch / birthday change / preview refresh behavior on device
