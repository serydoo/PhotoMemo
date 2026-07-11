# MemoMark Handoff

## Current Truth

- `Docs/CURRENT_STATUS.md` is the single source of truth for the active repository state.
- V3 evidence parser / 21-reject gate slice is implemented and locally
  verified. Runtime summaries now use stage-specific ordered parsing for
  `batch.task.duration`, `batch.task.route`, `batch.task.admission`, and
  `batch.task.stageDuration`, preserving filenames with key-like text while
  keeping route/admission/stage fields intact. The `share-21-reject` scenario
  now requires the machine-readable `extension.input.tooManyPhotos` event to
  pass; without it the run is `needs-review`, even if no request/job/crash was
  created.
- V3 Live Photo / 48MP evidence duration gate slice is implemented and locally
  verified. Runtime evidence evaluation for `share-livephoto-1`,
  `share-livephoto-mixed`, and `share-48mp` now requires matching completed
  total-duration evidence from the same completed Share job before route or
  admission evidence can pass. Route and 48MP admission evidence are scoped to
  completed jobs that also have duration evidence to prevent false passes from
  unrelated events. Known-bad Live Photo routes still fail before duration
  completeness is considered, so missing duration cannot hide static fallback.
- V3 diagnostics retention matrix slice is implemented and locally verified.
  Share diagnostics now retain a full 20-photo mixed evidence matrix
  (readiness plus provider/source/probe/static-fallback/recovery/route/
  stage-duration/total-duration events) by raising the bounded event cap from
  640 to 768. Stage-duration retention now covers future main-thread,
  thread-name, and peak-memory fields. Live Photo readiness helper dedupe is
  intentionally left as a future simplification, not a blocker before the next
  signed device pass.
- V3 share duration evidence gate slice is implemented and locally verified.
  Runtime evidence evaluation for `share-1` and `share-20` now requires
  shared-container readiness plus matching per-task `batch.task.duration`
  evidence for the completed Share job before it can pass. Scenario evaluation
  uses the full new event set instead of the Markdown tail, and
  `batch.task.stageDuration` summaries now preserve optional main-thread,
  thread-name, and peak-memory fields when present.
- V3 evidence scenario / RAW filename fallback slice is implemented and locally
  verified. Runtime evidence summaries now support `share-livephoto-1`,
  `share-livephoto-mixed`, and `share-48mp`; Live Photo route evaluation is
  scoped to the completed Share job; 48MP evaluation requires critical
  single-lane admission evidence; broad `public.image` declarations with RAW
  filename extensions now route and plan as RAW still-image input.
- V3 orientation / location / landscape logo closure slice is implemented and
  locally verified. Orientation-aware metadata dimensions now prevent
  EXIF-rotated portrait images from being classified as landscape; V1
  configuration saves no longer clear saved location display configuration
  when the request has no location update; Configuration Center summary shows
  saved location display mode even before the location module is inserted; the
  landscape Immers output logo now matches divider height while preserving the
  prior visual center.
- V3 Live Photo Share hardening / recovery confidence slice is implemented and
  locally verified. `PhotoProcessingInputPolicy` now owns shared Live Photo
  type identifiers; Share Extension Live Photo intake no longer preflights
  destructive provider loads before real import; mixed still + Live Photo
  batches route each task independently; static-fallback identity recovery now
  requires filename-basename agreement in addition to capture-date agreement.
  Signed real-device Live Photo Share validation is still required.
- V3 real Live Photo processor seam is implemented and locally verified. The
  real processor source-bundle branch now has a narrow pair-composer protocol
  seam proving it skips PhotoKit loading for valid source bundles, passes the
  inner still/movie URLs to composition, and saves with inner resource
  filenames. Route diagnostics now include `taskID`.
- V3 route evidence / Live Photo bundle type hardening is implemented and
  locally verified. Runtime evidence now preserves normal comma-space filenames,
  structures `batch.task.route` events, and makes `share-1` / `share-20`
  evaluation require shared-container readiness. `com.apple.live-photo-bundle`
  is now treated consistently as Live Photo content by policy and routing.
- V3 Live Photo bundle contract hardening is implemented and locally verified.
  Share drain now keeps valid `.livephoto` source bundles instead of filtering
  directories before queue enqueue; source-bundle resolution now requires one
  still, one movie, and matching basenames; Live Photo save requests use the
  still resource original filename; the Share Extension readiness mirror uses
  the same unique-pair rule; runtime evidence decoding now falls back from App
  Group preferences to app data preferences so App Group readiness fallback
  diagnostics are not hidden when the group plist is unavailable.
- V3 P1 closure batch 1 is implemented and locally verified on top of
  `9430598 Add Production Audit v2.0 reports`. This is not full V3 completion.
  It closes the first saved-configuration gate / output-configuration
  persistence / preset deletion / anchor sheet / Live Photo wording-gate slice.
- V3 P1 closure batch 2 is also implemented and locally verified. It closes
  the Share Extension 20-photo safe intake cap and the first Capture-Time
  production fix: legacy anchor results no longer use current time when capture
  date is missing, and `AnchorEngine.build` no longer has an implicit `Date()`
  default.
- V3 P1 closure batch 3 is implemented and locally verified.
  `MemorySubjectAdapter` no longer invents a reference date from the current
  clock; empty profile / anchor input uses a deterministic unspecified date.
  The production Capture-Time path is now clear of the reviewed `Date()`
  fallbacks.
- V3 P1 closure batch 4 is implemented and locally verified. It closes the
  preview-only `MainView+DerivedState.anchorPreviewResult` current-time guard
  and aligns static export metadata cleanup with VNext still-image metadata
  cleanup so stale Live Photo pairing metadata is removed from generated still
  outputs. Next work should focus on signed real-device / TestFlight smoke,
  20/21-photo Share Extension validation, concurrency/performance evidence,
  and 48MP memory-pressure validation.
- V3 real-device evidence collection now produces reusable summary artifacts:
  `runtime-evidence-summary.md` and `runtime-evidence-summary.json`. Use
  `PHOTOMEMO_RUNTIME_BASELINE_DIR` plus `PHOTOMEMO_RUNTIME_SCENARIO` when
  validating 1-photo, 20-photo, or 21-photo Share Extension flows so old queue
  entries do not contaminate the result.
- V3 validation batch 5 is implemented and locally verified. It adds a
  machine-readable `extension.input.tooManyPhotos` event for the 21-photo Share
  Extension rejection path and adds a model-level regression that treats
  non-RAW 48MP still images as critical single-lane work. Real 48MP device
  performance remains an Instruments / real-device evidence item.
- V3 validation batch 6 is locally verified and superseded by later V3 slices.
  It closed the Memory Engine
  capture-calendar regression and adds a no-file HEIC non-ASCII UserComment
  metadata-preservation regression. iPhone7 evidence now proves 21-photo
  rejection and proves 1-photo plus 20-photo Share Extension requests drain
  into completed `shareExtension` jobs after the main app launches. Stable
  evidence:
  `/tmp/PhotoMemoRuntimeEvidence/v3-iphone7-after-stable-20260710-220803`.
  The current dirty working tree was rebuilt, installed, and launched on
  iPhone7 after these code-only changes; post-install evidence is
  `/tmp/PhotoMemoRuntimeEvidence/v3-iphone7-after-current-install-20260710-222315`
  with no new requests, jobs, or crashes.
- The runtime evidence summarizer now records per-job `durationSeconds` and
  `savedTasksPerMinute`. The stable iPhone7 20-photo completed jobs measured
  `21.56s` / `55.66 saved tasks per minute` and `25.082s` / `47.84 saved tasks
  per minute`. This is a throughput evidence baseline, not a replacement for
  Instruments or main-thread stall analysis.
- Batch execution now records `batch.task.duration` events for completed and
  failed tasks. The next real-device Share run should use those events to
  inspect per-task route and duration before deciding whether to split
  `@MainActor` export/build work.
- The user-facing TestFlight version is now `1.6`. The App Store Connect /
  Xcode Cloud build counter has reached build `13`; the next successful cloud
  attempt is expected to appear as build `14`. Treat the cloud build number as
  owned by Xcode Cloud / App Store Connect, not as the product version.
- RAW / ProRAW high-resolution handling remains a V3 real-device validation
  item, not a 1.6 blocker. Current code has explicit RAW/ProRAW/DNG input
  policy, generated still-output policy, user-facing supported-format copy, and
  metadata-warning coverage without promising RAW output preservation. Current
  iPhone7 Share evidence after installing local `1.6` shows high-resolution /
  RAW-like Apple Photos inputs can arrive as `public.jpeg` and complete
  successfully; true RAW/ProRAW provider behavior still needs real-device
  evidence.
- External product branding is now `MemoMark` / `时光记`; internal engineering
  names such as `PhotoMemo` targets, bundle IDs, App Group, UserDefaults keys,
  source paths, and GitHub repository URL remain intentionally preserved until
  a dedicated engineering rename slice is approved.
- RFC documents are historical architecture records unless `CURRENT_STATUS.md` says their conclusions have been revalidated for the current live HEAD.
- `main` is now the active V1 source line after merging the former latest
  `v1-checkpoint-20260702` checkpoint into it.
- `main` now also contains the Live Photo main app picker release candidate via
  merge commit `c6b97d99`.
- Main App Picker Live Photo is release-candidate scope; Share Extension Live
  Photo remains a known limitation and future production-validation item.
- The temporary Live Photo integration worktree and local
  `codex/ios-livephoto-internal-test` branch have been removed after merge.
- Post-merge release verification has passed from the canonical `main`
  workspace:
  - `PhotoMemoiOS` Debug generic iOS build
  - `PhotoMemoShareExtension` Debug generic iOS build
  - `PhotoMemoWidgetExtension` Debug generic iOS build
  - `PhotoMemo` Debug macOS build
  - focused Live Photo / Media Geometry / main picker intake tests
- Historical release archive readiness dry-run also passed for `PhotoMemoiOS`
  before the 1.6 version bump:
  - local unsigned Release archive generated successfully at
    `/tmp/PhotoMemoReleaseReadinessArchive.xcarchive`
  - archive contains `PhotoMemoiOS.app`
  - archive embeds `PhotoMemoShareExtension.appex`
  - archive embeds `PhotoMemoWidgetExtension.appex`
  - archive app and extension bundle versions were `1.5` / `7`
  - no App Store Connect upload was attempted
- Local repository hygiene has been tightened:
  - only `main` remains as a local branch
  - only `/Users/rui/Desktop/PhotoMemo` remains as an active worktree
  - old WIP was preserved under `/Users/rui/Desktop/PhotoMemoWorktreeBackups/`
    and in the Git stash list before cleanup
- Future V1 builds and IPA packages should come from `main`, not from a
  temporary checkout or a separate V1 branch.
- The current V1 checkpoint is accepted as a functional baseline and now lives
  inside `main`.
- The V1 long-term maintenance baseline is accepted after the High Finding Closure Sprint.
- The previous local and remote `v1-checkpoint-20260702` branch lines have
  been merged into `main` and removed as active build sources.
- `5f583093` is the V1 boundary hardening code checkpoint.
- `e48508e9` remains the first accepted V1 maintenance freeze checkpoint.
- `2218878d` remains the functional device checkpoint that preceded the maintenance freeze.

## 2026-07-10 V3 P1 closure batch 1

- Main iOS processing now requires a saved V1 configuration for the selected
  memory subject before opening the processing picker.
- Share Extension now reads saved-configuration readiness; without a saved
  configuration it asks the user to open MemoMark and does not persist the
  incoming share items.
- V1 saved presets now include output configuration, and apply/save persistence
  snapshots fold current output settings into the selected configuration.
- Saves that do not have output context preserve the preset's previously saved
  output configuration instead of clearing it.
- Preset deletion now persists the subject library immediately through
  `V1PresetDeletionCoordinator`.
- Loading memory-subject anchor drafts no longer auto-opens the anchor edit
  sheet.
- Live Photo runtime terminology now uses a validation-candidate gate and the
  Settings wording no longer implies Share Extension Live Photo is fully
  supported.
- Verification passed:
  - focused macOS `PhotoMemoTests` for configuration lifecycle, subject library
    support, shared snapshot readiness, media runtime gate, and iOS time-anchor
    presentation
  - `PhotoMemoiOS` Debug generic iOS build
  - `PhotoMemoShareExtension` Debug generic iOS build
  - `git diff --check`
- Not completed in this batch:
  - Share Extension intake count cap / large-provider regression
  - Capture-Time Principle production fallback cleanup
  - static export metadata parity / stale Live Photo pairing metadata cleanup
  - MainActor, concurrency, and performance validation
  - 48MP and memory-pressure validation
  - signed TestFlight and real-device Share Extension smoke

## 2026-07-10 V3 P1 closure batch 2

- Share Extension intake now has an explicit safe cap of 20 supported photo
  providers per handoff.
- Oversized Share Extension batches are rejected before provider loading or
  persistence, and the confirmation UI uses the same service-layer cap instead
  of merely limiting preview thumbnails.
- `RecordCardBuildService` no longer calculates legacy anchor results from
  current time when photo capture time is missing.
- `AnchorEngine.build` now requires an explicit `photoDate`, removing the
  implicit `Date()` fallback at the API boundary.
- Verification passed:
  - focused macOS `PhotoMemoTests` for the new Capture-Time and Share cap
    regressions with explicit arm64 macOS destination
  - `PhotoMemoiOS` Debug generic iOS build
  - `PhotoMemoShareExtension` Debug generic iOS build
  - `git diff --check`
- Not completed in this batch:
  - `MemorySubjectAdapter` current-time fallback cleanup
  - preview-only current-time fallback review
  - static export metadata parity / stale Live Photo pairing metadata cleanup
  - MainActor, concurrency, performance, 48MP, signed TestFlight, and real
    device Share Extension smoke

## 2026-07-10 V3 P1 closure batch 3

- `MemorySubjectAdapter` no longer falls back to `Date()` when reference date,
  profile birthday, and anchors are all absent.
- Missing adapter reference input now resolves to a deterministic unspecified
  reference date, preventing processing time from becoming memory truth.
- Focused `MemorySubjectAdapterTests` cover the deterministic empty-input
  behavior.
- A parallel Capture-Time scan found no remaining production `Date()` fallback
  in `ProductionMemoryResolver`, `RecordCardBuildService`, `AnchorEngine`, or
  `MemoryExpressionEngine`.
- Verification passed:
  - focused macOS `PhotoMemoTests` for `MemorySubjectAdapterTests`
  - `PhotoMemoiOS` Debug generic iOS build
  - `git diff --check`
- Parallel scan follow-up:
  - `MainView+DerivedState.anchorPreviewResult` remains a preview-only current
    time fallback and should be closed in its own focused slice
  - static export metadata cleanup does not yet remove stale Live Photo pairing
    metadata inherited from source properties
  - signed TestFlight / real-device Share Extension smoke, 20/21-photo device
    validation, MainActor performance evidence, and 48MP memory-pressure
    validation remain open

## 2026-07-10 V3 P1 closure batch 4

- `MainView+DerivedState.anchorPreviewResult` no longer falls back to current
  time when the selected photo has no capture date; preview quick facts now
  disappear instead of inventing a time relationship.
- A source-boundary regression in `PreviewCompositionMigrationTests` prevents
  reintroducing `?? Date()` in that main-anchor preview path.
- Static `RecordCardExportService` export now removes inherited Live Photo
  pairing metadata before writing generated still-image output.
- `RecordCardExportService` and the VNext still-image writer now share
  `ImageIOStillImageMetadataCleanup` for QuickTime metadata and Apple
  MakerApple pairing identifiers.
- Cleanup coverage now includes numeric MakerApple `17` keys, matching the key
  shapes supported by the Live Photo pairing verifier.
- Verification passed:
  - focused macOS `PhotoMemoTests` for `PreviewCompositionMigrationTests`
  - focused macOS `PhotoMemoTests` for `StillImageMetadataWriterContractTests`
  - focused macOS `PhotoMemoTests` for `FixtureExportReadbackTests`
  - `PhotoMemoiOS` Debug generic iOS build
  - `PhotoMemoShareExtension` Debug generic iOS build
  - `git diff --check`
- Remaining V3 P1 / validation work:
  - signed build / TestFlight / real-device Share Extension behavior smoke
  - real-device 20-photo accept / 21-photo reject validation from Apple Photos
  - MainActor / concurrency evidence
  - 48MP / memory-pressure validation

## 2026-07-10 V3 real-device evidence summarizer

- Added `scripts/summarize-ios-runtime-evidence.py`.
- `scripts/collect-ios-runtime-evidence.sh` now automatically writes:
  - `runtime-evidence-summary.md`
  - `runtime-evidence-summary.json`
- The summarizer compares a post-test evidence directory against a baseline
  directory and supports:
  - `baseline`
  - `share-1`
  - `share-20`
  - `share-21-reject`
  - `manual`
- For accepted Share Extension scenarios, the script looks for a new
  `shareExtension` batch job with the expected task count and saved completed
  tasks.
- For the 21-photo rejection scenario, the script expects no new external
  intake request, no new batch job, and no new PhotoMemo crash relative to the
  baseline. Manual UI confirmation is still required for the split-batch
  rejection copy.
- `scripts/README.md` now documents the baseline and post-share collection
  commands.
- Verification passed:
  - `python3 -m py_compile scripts/summarize-ios-runtime-evidence.py`
  - `zsh -n scripts/collect-ios-runtime-evidence.sh`
  - baseline summary generation against
    `/tmp/PhotoMemoRuntimeEvidence/v3-iphone7-baseline-20260710-202508`
  - self-baseline `share-21-reject` dry run, confirming the no-new-job /
    no-new-request comparison path
- Device note:
  - `xcrun devicectl list devices` currently reports physical `iPhone7`
    (`863C2747-6742-5E93-B715-6F89DBF90B31`) as `unavailable`.
  - Wait for the device to be online / trusted before collecting the next
    Apple Photos -> Share -> MemoMark evidence run.

## 2026-07-10 V3 validation batch 5

- Share Extension confirmation UI now records
  `extension.input.tooManyPhotos` before cancelling an oversized share from the
  UI preflight path.
- `scripts/summarize-ios-runtime-evidence.py` recognizes that event in
  `share-21-reject` evidence summaries.
- `MediaMemoryBudgetTests` now explicitly covers non-RAW 48MP still images
  (`8064x6048`) as:
  - `.critical`
  - extended-preview work
  - single decode/render/export lane
  - `195,084,288` estimated decoded bytes
- Verification passed:
  - `PhotoMemoTests/MediaMemoryBudgetTests`
  - `PhotoMemoTests/PhotoProcessingInputPolicyTests`
  - `PhotoMemoTests/PhotoMemoShareIntakeDiagnosticsTests`
  - `python3 -m py_compile scripts/summarize-ios-runtime-evidence.py`
  - synthetic self-contained `share-21-reject` summarizer dry run with
    `extension.input.tooManyPhotos`
  - `PhotoMemoShareExtension` Debug generic iOS build
  - `PhotoMemoiOS` Debug generic iOS build
- Notes:
  - This does not close real 48MP performance / memory pressure validation.
    It only closes the automated budget-model regression gap.
  - True HEIC file-writing parity should stay out of normal unit tests until
    the ImageIO writer lane is stable enough for always-on execution. Current
    VNext fixture-writing coverage is intentionally disabled due to macOS test
    runner hang risk.

## 2026-07-10 V3 validation batch 6

- Memory Engine Capture-Time calendar fix:
  - `MemoryExpressionContext` now carries `captureCalendar`.
  - `MemoryExpressionEngine` resolves elapsed anchor values with
    `context.captureCalendar`.
  - `ProductionMemoryResolver` passes `photo.metadata.captureCalendar`.
  - New `MemoryExpressionEngineTests` coverage forces the process default
    timezone away from the photo capture timezone and verifies birthday elapsed
    months/days still follow the capture calendar.
- HEIC metadata parity guard:
  - `StillImageMetadataWriterContractTests` now preserves non-ASCII HEIC
    `UserComment` at dictionary level without invoking ImageIO HEIC writing.
- Runtime evidence script:
  - `scripts/summarize-ios-runtime-evidence.py` now includes privacy-safe
    `newRequests` summaries.
- Verification passed:
  - `PhotoMemoTests/StillImageMetadataWriterContractTests`
  - `PhotoMemoTests/MemoryExpressionEngineTests`
  - `PhotoMemoTests/ProductionMemoryResolverTests`
  - `PhotoMemoTests/MemoryResultContractTests`
  - `python3 -m py_compile scripts/summarize-ios-runtime-evidence.py`
  - manual evidence summary regeneration for
    `/tmp/PhotoMemoRuntimeEvidence/v3-iphone7-after-manual-open-check-20260710-214158`
  - `PhotoMemoiOS` Debug generic iOS build from
    `/tmp/PhotoMemoV3Batch6IOSBuild`
  - `git diff --check`
- iPhone7 evidence:
  - Installed signed Debug build:
    `/tmp/PhotoMemoV3DeviceBuild_20260710/Build/Products/Debug-iphoneos/PhotoMemoiOS.app`
  - Baseline:
    `/tmp/PhotoMemoRuntimeEvidence/v3-iphone7-baseline-20260710-211400`
  - After user shared 1 / 20 / 21 photos:
    `/tmp/PhotoMemoRuntimeEvidence/v3-iphone7-after-manual-open-check-20260710-214158`
  - 21-photo rejection recorded `extension.input.tooManyPhotos` and no new
    crash.
  - 20-photo request persisted:
    `9AA52C1B-F386-4CA2-9354-868E51D2898F`, `items=20`, `imported=20`.
  - 1-photo request persisted:
    `EB573745-A90D-40C0-8B2F-1991846ED921`, `items=1`, `imported=1`.
  - No new `shareExtension` batch job appeared yet. `devicectl` could not
    launch the main app because iOS reported the device as locked.
- Next required device step:
  - Unlock iPhone7 and open MemoMark / 时光记.
  - Collect evidence again with baseline
    `/tmp/PhotoMemoRuntimeEvidence/v3-iphone7-baseline-20260710-211400`.
  - Verify the two persisted requests are drained and enqueued.

## 2026-07-10 V1 iOS feedback stabilization pass

- A feedback-driven stabilization pass was applied on top of the existing dirty
  iOS polish worktree.
- Follow-up Live Photo intake correction:
  - The main app processing picker now opens the normal image library instead
    of filtering the picker to Live Photos only. It still uses the UIKit
    `PHPickerViewController` path with `PHPickerConfiguration(photoLibrary:
    .shared())`, `.current` representation mode, and `PHPickerResult
    .assetIdentifier` so selected Live Photos can retain PhotoKit asset
    identity.
  - Live Photo motion-preserving queue routing now requires both a Live Photo
    content type and a non-empty PhotoKit asset identity. This prevents Share
    Extension payloads that only contain flattened JPEG/HEIC representations
    from being misrouted into the Live Photo processor.
  - When a Live Photo-typed payload lacks asset identity and falls back to
    static processing, static import now uses the still-file extension/type
    rather than treating the copied still file as a Live Photo package.
  - Share Extension Live Photo remains a separate production-validation /
    implementation item because current runtime evidence shows Photos sharing
    can expose `com.apple.live-photo` while the extension persists only a
    static JPEG/HEIC representation without a usable `PHAsset.localIdentifier`
    or paired video resource.
- Fixed likely configuration reset cause by carrying `memoryPresets` and
  `selectedMemoryPresetID` through the V1 configuration apply/save request path
  instead of allowing subject-library saves to persist an empty preset list.
- Closed the remaining subject-flow reset path by preserving `memoryPresets`
  and `selectedMemoryPresetID` during memory-subject switch, add, delete, and
  editor-save persistence.
- Fixed repeated default time-anchor reappearance in the memory subject editor:
  default anchors are now only generated for subjects with no anchors, not every
  time an existing subject is opened for editing.
- Removed the temporary `旅行对象` fixture dependency from configuration
  lifecycle tests and neutralized default custom-anchor wording from
  `第一次旅行` to `重要日子` while preserving the `.custom` time-anchor type.
- Fixed district/county name truncation by preserving full reverse-geocoder
  administrative names instead of stripping suffixes such as `区` and `县`.
- Restored the main app processing picker to the UIKit Live Photo picker path
  so it keeps the `.livePhotos` filter and `PHPickerResult.itemIdentifier`
  behavior needed by the motion-preserving Live Photo pipeline.
- Added the recent-task expansion behavior: the task page still shows two rows,
  while the full recent list can be opened from the `…` button and upstream
  summaries keep the latest ten jobs.
- Adjusted memory-object UI polish around the identity overview, avatar sizing,
  and home statistics text sizing.
- Reverted the Home top area back to the previous lightweight header after
  device feedback; broader Home-top redesign is deferred until the next
  user-directed visual pass.
- Refined the Home memory-object card so the middle metadata row adapts when
  width is tight, and reduced the `可用配置` / `累计完成` statistics emphasis.
- Moved the `基本资料` / `锚点维护` navigation row inside the memory-object
  identity overview, directly below the avatar/header area and above the
  editable basic-profile fields.
- Verification:
  - `git diff --check` passed.
  - `PhotoMemoiOS` Debug generic iOS build passed with
    `CODE_SIGNING_ALLOWED=NO`.
  - `PhotoMemoShareExtension` Debug generic iOS build passed with
    `CODE_SIGNING_ALLOWED=NO`.
  - Focused Live Photo intake/routing tests passed for
    `PhotoProcessingInputPolicyTests`,
    `LivePhotoBatchQueueExecutionTests`,
    `PhotoMemoiOSV1PhotoIntakeTests`,
    `ExternalPhotoIntakeCenterTests`, and
    `PhotoMemoShareDiagnosticsTests`.
  - Earlier in this pass, `PhotoMemoiOS` Debug physical-device build passed for
    iPhone7 (`00008150-000A043136A1401C`), installed successfully, and launched
    successfully on the paired device.
  - Focused macOS `PhotoMemoTests` passed for configuration lifecycle, subject
    library support, Home projection, V1 apply request builder, and bootstrap
    flow/runtime suites.
- Not completed:
  - The latest Live Photo picker correction was not reinstalled to iPhone7
    because Xcode/CoreDevice currently reports the physical device as offline /
    unavailable.
  - Share Extension motion-preserving Live Photo still needs a dedicated intake
    implementation that can persist a real PhotoKit asset identity or paired
    still/video resources.

## 2026-07-09 V1 iOS task page visual redesign installed on device

- The V1 iOS `任务` page has been redesigned from a diagnostics-card surface
  into a compact processing overview:
  - top title and local-processing subtitle
  - four-item overview for active jobs, completed photos, failed photos, and
    today's processing count
  - current task card using the effective configuration name, template name,
    progress, first source thumbnail, and pipeline step statuses
  - recent task rows using real queue job summaries and configuration names
- The previous current-task control row was removed. There is no pause,
  restart, or task-operation menu because current processing jobs are short
  lifecycle tasks that auto-start from Apple Photos/share intake.
- A compact `查看相册` row is now shown in the current task card. Completed
  current/recent jobs carry the saved album name and saved asset identifier
  when available. For this V1 pass, tapping current/recent task album affordances
  opens the system Photos app to its recent-save experience. MemoMark still
  records and displays the target album name for continuity, but iOS does not
  expose a public API for deep-linking Photos directly into a specific user
  album and image position.
- Verification passed:
  - `V1SettingsPagePresenterTests`
  - `PhotoMemoiOS` Debug build for the connected physical device named
    `iPhone7`
  - install via `devicectl`
  - launch via `devicectl`

## 2026-07-09 V1 iOS design-language first polish pass installed on device

- The first low-risk MemoMark design-language polish pass is installed on the
  connected physical device named `iPhone7`.
- Scope intentionally stayed below information-architecture changes:
  - added shared V1 page header, section heading, and card chrome primitives
  - moved the Configuration Center preview title above the preview card border
    so it matches Output and Task page structure
  - aligned Output, Task, and preview/configuration headers around the same
    title/subtitle hierarchy
  - aligned compact card titles and section titles away from mixed uppercase
    caption styling toward one Apple-native type rhythm
  - unified the shared card shadow token for the current V1 surfaces
- Deferred to a separate design-system slice:
  - Home hero redesign
  - Configuration Center regrouping
  - floating Output save action
  - broader icon/color/token inventory
- Verification passed:
  - `git diff --check`
  - `PhotoMemoiOS` Debug build for the connected physical device named
    `iPhone7`
  - install via `devicectl`
  - launch via `devicectl`
  - `V1SettingsPagePresenterTests`

## 2026-07-09 V1 iOS Configuration Center grouped layout installed on device

- The Configuration Center top preview area remains on the existing V1 design.
  This pass did not change the preview card itself and did not add the reference
  mockup's top-right save action.
- The content below the preview is now grouped into three sections:
  - `记忆来源`: current memory subject, time anchor, and memory display style.
    The subject row is read-only and follows the same selected subject used on
    Home.
  - `卡片布局与内容`: Logo 标识, border style, location display, and a single
    region-content entry.
  - `配置操作`: save current configuration, save as new configuration, restore
    defaults, and delete current configuration.
- The previous always-visible A/B/C/D region editor list has been moved behind
  the `区域内容设置` row. Tapping it opens a large sheet that reuses the existing
  region editor cards, module insertion, text editing, and preview-refresh
  behavior.
- The `卡片布局与内容` rows were tightened after device review: the first three
  rows no longer show trailing navigation chevrons, `边框样式` is rendered as
  static text, and `区域内容设置` now exposes a single `进入设置` action label.
- Configuration naming now defaults new configurations to the current effective
  subject name plus active anchor name, for example `途途 生日`. Users can still
  edit the name from the Home current-configuration module.
- Saving while the current subject has no existing configuration now creates a
  saved configuration for that subject so it appears in Home's current
  configuration picker.
- Verification passed:
  - `git diff --check`
  - `ConfigurationSessionConfigurationLifecycleTests`
  - `PhotoMemoiOS` Debug build for the connected physical device named
    `iPhone7`
  - install via `devicectl`
  - launch via `devicectl`

## 2026-07-09 V1 iOS Home configuration list polish installed on device

- The Home page no longer shows the old `快捷操作` card. A single fixed bottom
  `处理照片` action now remains visible while the page scrolls.
- The previous `当前配置` module is now `我的配置`, with a compact `勾选生效`
  note. It lists the configurations belonging to the currently selected memory
  subject, so switching subjects refreshes Home to that subject's saved
  configurations.
- Home configuration rows now show the preset name, current border style, and
  saved/detail text. The old trailing picker and `管理` menu were removed.
  Tapping a row applies it, the selected row shows a checkmark and `重命名`,
  and swiping left reveals a delete action.
- Follow-up polish tightened Home configuration rows, made the swipe-to-delete
  interaction follow the drag more naturally, fully hides the delete action
  until the row is swiped, and aligned the Home rename input with the
  Configuration Center field chrome. The Output page `保存到当前配置` action was
  reduced from a large blue prominent button to a lower, lighter control.
- The Configuration Center `记忆来源` rows for `时间锚点` and `记忆显示` no longer
  show trailing navigation chevrons, matching the lower layout/content rows.
- The Task page current-task card was further softened:
  - active tasks now use a compact summary block, quieter pipeline rows, and a
    short Home-style `查看相册` action button instead of a heavy inset row
  - the no-current-task state now shows a camera icon, `还没有处理任务`,
    `从首页选择照片开始。`, and a direct `开始处理` button wired to the same photo
    picker entry flow
- Verification passed:
  - `git diff --check`
  - `PhotoMemoiOS` Debug build for the connected physical device named
    `iPhone7`
  - install via `devicectl`
  - launch via `devicectl`

## 2026-07-09 Live Photo main picker release candidate merged to main

- Merge commit: `c6b97d99 Merge Live Photo main picker release candidate`
- Feature checkpoint: `f7825e4f Add Live Photo main picker release candidate`
- Release scope:
  - Main App Picker Live Photo path is now on `main` as a release candidate.
  - Share Extension Live Photo remains a separate production-validation item.
  - Failed-item thumbnail/reason UI remains deferred polish.
- Release materials were aligned so TestFlight docs no longer describe Live
  Photo motion playback as entirely outside scope for builds from `c6b97d99`
  or later.
- Version/build numbers were not changed by this merge-doc follow-up.

## 2026-07-08 iOS release entry cleanup

- The project now has one iOS app release entry:
  - scheme/target: `PhotoMemoiOS`
  - product: `PhotoMemoiOS.app`
  - Info.plist: `PhotoMemoiOS-Info.plist`
  - bundle identifier: `com.serydoo.PhotoMemo.iOS`
  - version/build: `1.5` / `7`
- The former `PhotoMemoiOSV1` scheme/target naming has been retired from the
  Xcode project. Future local device builds, Xcode Cloud workflows, TestFlight
  builds, and archive work should select `PhotoMemoiOS`.
- Version progress should be represented by `MARKETING_VERSION` and
  `CURRENT_PROJECT_VERSION`, not by target/scheme names.
- The cleanup intentionally did not rename internal UI types such as
  `PhotoMemoiOSV1View`; those remain code-level V1 implementation names and
  can be handled in a separate low-risk refactor if desired.
- Verification passed:
  - project file lint
  - `xcodebuild -list`
  - `PhotoMemoiOS` Debug generic iOS Simulator build
  - `PhotoMemoiOS` Debug generic iOS build
  - `PhotoMemoiOS` signed Debug iPhone7 device build
  - iPhone7 install through `devicectl`
  - iPhone7 launch through `devicectl`
  - built-product inspection confirmed app display name, bundle identifier,
    version/build, embedded Share Extension, embedded Widget Extension, and
    privacy manifests
- Not completed:
  - local Release generic iOS build entered an Xcode internal idle wait and was
    interrupted without compile errors

References:

- [Docs/02_Architecture/V1_High_Finding_Closure_Checklist_2026-07-03.md](/Users/rui/Desktop/PhotoMemo/Docs/02_Architecture/V1_High_Finding_Closure_Checklist_2026-07-03.md)
- [Docs/02_Architecture/Maintenance_Baseline_Freeze_2026-07-03.md](/Users/rui/Desktop/PhotoMemo/Docs/02_Architecture/Maintenance_Baseline_Freeze_2026-07-03.md)
- [Docs/02_Architecture/V1_Boundary_Inventory_2026-07-04.md](/Users/rui/Desktop/PhotoMemo/Docs/02_Architecture/V1_Boundary_Inventory_2026-07-04.md)

## 2026-07-08 Live Photo internal-test simulator baseline

This work happened in the isolated integration worktree:

- `/Users/rui/Desktop/PhotoMemo-ios-livephoto-internal-test`
- branch: `codex/ios-livephoto-internal-test`

## 2026-07-09 MGF-2A Geometry Adoption Completion

This work happened in the isolated integration worktree:

- `/Users/rui/Desktop/PhotoMemo-ios-livephoto-internal-test`
- branch: `codex/ios-livephoto-internal-test`

MGF-2 has been split into:

- `MGF-2A: Geometry Adoption Completion`
- `MGF-2B: Runtime Validation`

Closed milestones:

- MGF-0 Foundation Freeze
- MGF-1 Geometry Core Implementation
- MGF-2A Geometry Adoption Completion

MGF-2A is complete.

What changed:

- `LivePhotoGeometryResolver` was added as the Live Photo adapter from
  MGF-1 `MediaGeometryResolver` into pair composition.
- Pair composition now resolves `CanonicalGeometry` once before still/video
  composition.
- The same `CanonicalGeometry` value is passed into still and video pairing
  composers.
- Still and video pairing composers now use `geometry.canvas` to construct the
  effective composition overlay.
- V1 renderer/footer visual content still comes from the existing rendered
  overlay image; MGF-2A did not redesign footer UI or output format behavior.
- The previous architecture-test red state was resolved.

Architecture rules captured during review:

```text
API shape is not Architecture Adoption.

CanonicalGeometry in a signature does not count as adoption unless the consumer
uses it to make composition decisions and removes duplicated geometry logic.
```

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
- [x] Legacy composer media-observation logic is guarded by tests.

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

Expected environment warning remains:

- macOS deployment target is set to `27.0`, while the installed SDK supports
  up to `26.5.99`

MGF-2 is not complete. Next work should be MGF-2B Runtime Validation.

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

Runtime validation boundary:

- treat rendered overlay inputs as Composition Facts, not Media Facts
- do not split `MediaGeometryResolver` until a second non-Live-Photo consumer
  proves the abstraction is needed
- do not treat MGF-2A as final Live Photo runtime acceptance

Simulator target:

- runtime: iOS 26.5
- device: `iPhone 17 Pro`
- UDID: `FD060AA4-67FE-4142-BA34-E7584089F350`

What was verified:

- the iOS 26.5 simulator runtime is installed and usable
- first boot completed after the expected one-time CoreSimulator migration
- `PhotoMemoiOS` Debug simulator build passed with signing disabled
- `PhotoMemoiOS` Debug simulator build also passed with normal local signing
- the signed simulator build is the preferred baseline for Share Extension,
  App Group, background queue, and Live Photo routing tests
- the app installed and launched successfully on the simulator
- the app reached the V1 home screen without a crash or white screen
- screenshot evidence:
  - `/tmp/memomark-livephoto-sim.png`
  - `/tmp/memomark-livephoto-sim-after-permission.png`
  - `/tmp/memomark-livephoto-sim-clean-launch.png`
  - `/tmp/memomark-livephoto-sim-signed-launch.png`

Important simulator notes:

- `simctl privacy grant photos` plus `photos-add` wrote the expected TCC rows,
  but the iOS full-photo-access prompt remained visible until the simulator was
  restarted
- after restart, the app launched directly to the V1 home screen without the
  permission sheet
- the unsigned simulator build launched, but App Group lookup logged
  `client is not entitled`
- the signed simulator build fixed that; App Group lookup logged `success`

Current simulator boundary:

- simulator is now good for UI smoke, output-mode surface checks, renderer
  geometry regressions, static-image no-stretch checks, and Share/queue routing
  diagnostics when using the signed simulator build
- simulator is not sufficient for final Live Photo acceptance:
  - Photos recognition as a Live Photo
  - long-press playback
  - HEIC+MOV pairing behavior
  - iCloud/AirDrop/real Photos behavior
  - device performance, memory, and thermal behavior

Next recommended verification:

- if automated output-page screenshots are needed, add a narrow internal-only
  simulator/development route to open the V1 `输出` tab directly, because the
  current `memomark://share` deep link does not select tabs
- reinstall the latest Live Photo geometry fix on the connected iPhone and run
  the true acceptance pass there

Device install follow-up:

- connected physical device used for this pass:
  - display name: `iPhone7`
  - devicectl ID: `863C2747-6742-5E93-B715-6F89DBF90B31`
  - Xcode destination ID used for the successful build:
    `00008150-000A043136A1401C`
- `PhotoMemoiOS` Debug iPhoneOS build passed with local development signing
- install succeeded after the user removed the older installed app:
  - bundle ID: `com.serydoo.PhotoMemo.iOS`
  - app path:
    `/tmp/PhotoMemoIOSLivePhotoDeviceDerivedData/Build/Products/Debug-iphoneos/PhotoMemoiOS.app`
- automatic launch was blocked by iOS security policy:
  - reason: developer profile/signature has not been explicitly trusted by the
    user on the device
- next manual action:
  - on iPhone, trust the Apple Development profile for `serydoo@163.com`
  - then relaunch `时光记` manually or rerun `devicectl device process launch`
  - after launch, run the Live Photo acceptance checklist on device

Real-device visual finding after launch:

- user confirmed the installed internal build can be tested on the physical
  device, but the Live Photo output still has a geometry/orientation regression
- observed symptom:
  - vertical Live Photo output becomes horizontal
  - image content still appears stretched
- next engineering priority:
  - pause further patching until the Live Photo geometry contract is
    re-specified end to end
  - trace the original still-image EXIF orientation, video
    `preferredTransform`, renderer output size, extracted footer frame,
    still composition canvas, video composition render size, and final
    PhotoKit import result as one consistent coordinate-system audit
  - add a vertical Live Photo fixture/test before changing the composer again

Architecture freeze follow-up:

- the portrait Live Photo regression has been elevated from a Live Photo bug to
  a media-pipeline foundation issue
- new foundation sprint name:
  - `Media Geometry Foundation`
- milestone:
  - `MGF-0 Media Geometry Foundation Freeze` is complete
  - next milestone is `MGF-1 Geometry Core Implementation`
- accepted architecture documents:
  - `Docs/02_Architecture/RFC-002-Media-Geometry-Foundation.md`
  - `Docs/ADR/ADR-008-MediaGeometryFoundation.md`
- foundation entry docs:
  - `Docs/Foundations/README.md`
  - `Docs/Foundations/MediaGeometry/Manifest.md`
  - `Docs/Foundations/MediaGeometry/README.md`
  - `Docs/Foundations/MediaGeometry/GeometryConstitution.md`
  - `Docs/Foundations/MediaGeometry/FoundationChecklist.md`
- frozen principles:
  - Geometry is a property of media, not Renderer, Composer, or Exporter
  - Geometry is resolved once, consumed everywhere
  - `CanonicalGeometry` is the only cross-module Geometry Truth and is
    immutable
  - geometry verification uses Geometry Linter and JSON Geometry Snapshot, not
    downstream runtime correction
- implementation stop rule:
  - Geometry Resolver's first consumer must be Geometry Snapshot, not Live
    Photo Composer
  - ordinary JPEG/HEIC still-image geometry must stabilize before Live Photo
    composer migration resumes
- checklist structure:
  - Phase A: Foundation covers Manifest, Constitution, models, resolver,
    linter, and snapshot
  - Phase B: Adoption covers JPEG/HEIC, Live Photo, RAW, HDR, ProRAW, Spatial
    Photo, Video, and Burst adoption
- MGF-1 implementation scope:
  - implement only `CanonicalGeometry`, `MediaGeometryResolver`,
    `GeometrySnapshotSerializer`, and `GeometryLinter` first
  - first resolver consumer must be JSON Geometry Snapshot
  - first tests should target ordinary portrait JPEG, landscape JPEG,
    portrait HEIC, landscape HEIC, Orientation Right, and Orientation Left
  - `GeometrySnapshotSerializer` must serialize `CanonicalGeometry`, not
    `UIImage`, `CGImage`, `AVAsset`, or renderer output
  - `GeometryLinter` must accept `CanonicalGeometry` and return
    `[GeometryIssue]`
  - do not touch Live Photo composer, renderer, or exporter during the first
    Geometry Core slice
- MGF-1 first implementation slice is now green:
  - added `CanonicalGeometry`, `MediaGeometryFacts`, `CanvasGeometry`, and
    `MediaGeometryOrientation`
  - added `MediaGeometryResolver` for still-image ImageIO facts and canonical
    display/canvas geometry
  - added `GeometryIssue`, `GeometryLinter`, and stable machine-readable issue
    codes
  - added `GeometrySnapshotSerializer` with versioned JSON output
  - added focused tests for portrait/landscape JPEG, portrait/landscape HEIC,
    HEIC Orientation Right, HEIC Orientation Left, linter issue codes, and
    Geometry Core dependency isolation
  - Geometry Core imports are currently limited to `Foundation`,
    `CoreGraphics`, `ImageIO`, and `UniformTypeIdentifiers`
  - no Live Photo composer, renderer, exporter, Overlay, UIKit, SwiftUI, or
    AVFoundation dependency was introduced in the Geometry Core slice
- Focused verification passed:
  - `xcodebuild -project Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoTests -destination 'platform=macOS' -only-testing:PhotoMemoTests/MediaGeometryFoundationCoreTests CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO test`
- Expected environment warning remains:
  - macOS deployment target is set to `27.0`, while the installed SDK supports
    up to `26.5.99`
- MGF-1 is now accepted as complete against its frozen Exit Criteria:
  - Media Geometry Core has established the unique,
    JSON-snapshot-verifiable `CanonicalGeometry` foundation layer
- MGF-2 boundary is frozen as `Live Photo Geometry Adoption`
- MGF-2 mission:
  - adopt Geometry Truth through the first real production consumer
- MGF-2 architecture guardrails:
  - Live Photo Composer consumes `CanonicalGeometry`
  - Live Photo Composer never derives geometry
  - Live Photo Composer never observes media
  - Live Photo Composer only observes composition inputs
- MGF-2 implementation rules:
  - resolve still-image geometry before composer entry
  - pass the same `CanonicalGeometry` into still and video composition
  - derive footer/canvas placement from display-space geometry
  - preserve existing V1 static-image routing and output behavior
  - reproduce the portrait Live Photo horizontal/stretch regression through a
    focused test before changing composer behavior
- MGF-2 composer prohibitions:
  - no EXIF orientation parsing inside composers
  - no `CGImageSource` or raw image property inspection inside composers
  - no `PHAsset` inspection inside composers
  - no `AVAsset` inspection inside composers
  - no `AVAssetTrack` inspection inside composers
  - no `naturalSize` or `preferredTransform` inference inside composers
  - no local width/height swap fix inside composers
- MGF-2 white-box acceptance:
  - dependency acceptance proves composer has no direct `ImageIO`, `PhotoKit`,
    or media-observation `AVFoundation` dependency
  - geometry consistency acceptance proves Resolver output equals Composer input
  - no code path reconstructs another `CanonicalGeometry` between Resolver and
    Composer
- MGF-2 final acceptance remains real-device based:
  - iPhone Photos must recognize the output as Live Photo
  - long-press playback must work
  - portrait output must remain portrait and unstretched
  - footer content must remain consistent with V1 renderer output rules
- Foundation Development Method is now recorded in
  `Docs/Foundations/README.md`:
  - `Problem -> Foundation Freeze -> Canonical Truth -> Consumers -> Adoption`
  - short form: `Freeze -> Truth -> Consumer -> Adoption`

## 2026-07-07 V1 Share Extension sheet layout adjusted

- User-reported symptom on the Apple Photos share flow:
  - the PhotoMemo share interface felt too high inside the system container
  - the primary action was not positioned as conveniently as expected
  - the full-screen-looking presentation raised the question of whether the
    Share Extension must occupy the whole screen
- Scope stayed in Share Extension presentation layout only.
- No share intake semantics, renderer drawing, export behavior, metadata
  extraction, or photo-library save behavior changed.
- What changed:
  - `PhotoMemoShareExtensionViewController` now suggests a shorter preferred
    content height for the host sheet
  - the main content stack sits inside a scroll view with extra top breathing
    room
  - the footer copy and primary action moved into a fixed bottom action area
  - the primary button height was slightly increased for easier tapping
- Platform note:
  - for a `com.apple.share-services` Share Extension, iOS controls the outer
    share-sheet presentation
  - `preferredContentSize` is only a suggestion and may not be honored exactly
  - the reliable fix is to improve the internal layout: lower content rhythm,
    scrollable details, and a stable bottom action
- Verification passed:
  - `git diff --check`
  - `PhotoMemoiOS` iPhone7 signed real-device build
  - iPhone7 install
  - iPhone7 launch via `devicectl`
- Manual device confirmation still wanted:
  - from Apple Photos, share one photo to PhotoMemo
  - confirm the top spacing feels calmer
  - confirm the primary action is easier to tap
  - confirm whether the host still presents the extension full-screen or
    honors the shorter preferred height on the current iOS build

## 2026-07-07 V1 output album refresh regression fixed

- User-reported symptom on the installed iPhone7 build:
  - entering `输出`
  - checking `已有相册`
  - album choices could look stale and appear to show only the previously
    loaded `photomemo` entry
- Root cause:
  - this was not a new `PhotoLibraryExportService` regression
  - the recent V1 UI split that moved output settings into a dedicated page
    left album loading on the root `.task` path only
  - returning to foreground or switching into the `输出` tab no longer
    triggered an album refresh, so the picker could keep stale state
- What changed:
  - `PhotoMemoiOSV1View` now reloads album options when:
    - scene phase returns to `.active`
    - the selected tab changes to `输出`
  - `V1OutputPageSurface` now exposes a lightweight `刷新相册` action inside
    the existing-album branch
  - output copy now also clarifies that `已有相册` is for directly addable
    destination albums, while general library return should use `系统图库`
- Verification passed:
  - `git diff --check`
  - focused `ExportAlbumPresenterTests`
  - `PhotoMemoiOS` iOS Simulator build
  - iPhone7 signed real-device build
  - iPhone7 install
  - iPhone7 launch via `devicectl`
- Manual device confirmation still wanted:
  - open `输出 -> 已有相册`
  - confirm returning from background or re-entering the tab refreshes the
    album list
  - confirm `刷新相册` updates the picker immediately on device

## 2026-07-07 V1 smart-module selected-subject projection fixed

- The remaining `家人` output issue was traced to the production smart-module
  fallback, not to renderer drawing or preview token insertion.
- Important source rule:
  - the selected subject identity comes from
    `MemorySubject.resolvedExpressionSubjectText`
  - `SettingsService.saveSelectedMemorySubject` writes that projection into
    shared defaults as `photomemo.selectedMemorySubjectText`
  - full app snapshots still prefer the embedded `MemorySubject`
  - Share Extension transport may only carry the projection as
    `BatchConfigurationSnapshot.memorySubjectText`
- `ProductionMemoryResolver` now falls back to that selected-subject identity
  projection before creating the final default `PersonalProfile()`.
- This preserves the priority order:
  - canonical frozen `ConfigurationSnapshot`
  - legacy frozen `MemorySubject`
  - selected subject identity projection from transport
  - safe default profile
- Regression coverage added:
  - `ProductionMemoryResolverTests.usesSelectedSubjectIdentityProjectionWhenFrozenMemoryConfigurationIsMissing`
  - `RecordCardBuildServiceTests.selectedSubjectIdentityProjectionFeedsSmartModuleOutput`
- Verification passed:
  - `git diff --check`
  - focused `ProductionMemoryResolverTests`
  - focused `RecordCardBuildServiceTests`
  - generic `PhotoMemoiOS` iOS build
  - iPhone7 signed real-device build
  - iPhone7 install
- Automatic launch on iPhone7 failed only because iOS rejected the untrusted
  developer profile/signature. The app is installed; trust the developer
  profile on device before launching manually.

## 2026-07-07 V1 UI optimization final review closeout

- Final review fixed a configuration lifecycle issue where restoring a saved
  preset could be marked pending again by normal dirtying setters.
- Homepage dead UI plumbing was removed after recent records moved to the
  `任务` tab, and compact Configuration Center rows now use a flexible trailing
  width instead of a fixed 124-point column.
- Verification passed:
  - focused V1 UI/configuration tests
  - `RecordCardBuildServiceTests`
  - required `PhotoMemo` build
  - `PhotoMemoiOS` iOS Simulator build
  - iPhone7 real-device build and install
- Automatic launch on iPhone7 was attempted but blocked because the device was
  locked. Manual visual confirmation should still be done by opening the
  installed app on device.

## 2026-07-07 V1 current-configuration save reconciliation fixed

- This slice fixed the V1 iOS gap where Configuration Center preview could
  look correct, but saving did not make the current preset appear on the
  homepage and subsequent processing could still use stale/default memory
  configuration.
- Scope stayed in V1 iOS configuration-state wiring and tests.
- No renderer drawing, export implementation, metadata extraction,
  share-extension behavior, or photo-library behavior changed.

- What changed:
  - successful V1 configuration apply now snapshots the current
    `MemoryPreset` back into the active `ConfigurationSession`
  - homepage current-configuration filtering can now see a previously unbound
    preset after `保存为当前配置`
  - failed configuration saves do not snapshot or mark the preset applied
  - V1 save-request building now prefers the selected subject's active
    time-anchor date over stale transient birthday state
  - this protects production memory output from receiving stale anchor context
    when the preview is already showing the selected object's current anchor

- Verification:
  - hygiene check passed:
    - `git diff --check`
  - focused tests passed:
    - `V1ConfigurationApplyRequestBuilderTests`
    - `V1ConfigurationApplyRuntimeCoordinatorTests`
    - `ConfigurationSessionConfigurationLifecycleTests`
  - production-output regression suite passed:
    - `RecordCardBuildServiceTests`
    - includes `previewAndExportShareTheSameFrozenMemoryExpression`, which
      protects against fallback output such as legacy `家人`
  - iOS Simulator build passed:
    - `xcodebuild -project Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -destination 'generic/platform=iOS Simulator' -configuration Debug -derivedDataPath /tmp/PhotoMemoIOSDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
  - iPhone7 real-device build and install passed:
    - `xcodebuild -project Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -destination 'id=00008150-000A043136A1401C' -configuration Debug -derivedDataPath /tmp/PhotoMemoIOSDeviceDerivedData build`
    - `xcrun devicectl device install app --device 863C2747-6742-5E93-B715-6F89DBF90B31 /tmp/PhotoMemoIOSDeviceDerivedData/Build/Products/Debug-iphoneos/PhotoMemoiOS.app`

- Not yet manually verified:
  - physical-device relaunch was blocked because the device was locked
  - user should unlock and manually open the installed app to confirm:
    - homepage current configuration refreshes after save
    - reprocessing the reported photo no longer outputs the legacy `家人`
      memory subject text

## 2026-07-07 V1 unified UI cleanup started

- This slice moved from feedback capture into implementation for the visible
  four-tab `PhotoMemoiOSV1View` path.
- Scope stayed in iOS SwiftUI presentation/layout only.
- No renderer drawing, export, metadata, share-extension, or photo-library
  behavior changed.

- What changed:
  - homepage `当前生效配置` was compressed into a compact `当前配置` row-card:
    - mini preview thumbnail
    - preset title/style
    - last modified time
    - existing preset picker/management affordance
  - homepage `主入口` title is now `快捷操作`
  - quick-action functions remain unchanged, but icon treatment is larger and
    more visually prominent
  - quick-action symbols were updated to:
    - `photo.on.rectangle.angled`
    - `slider.horizontal.3`
    - `calendar.badge.clock`
    - `book.pages`
  - homepage no longer renders the `最近记录` block; recent/current task state
    is now left to the rightmost `任务` tab
  - visible Configuration Center no longer renders:
    - the explanatory intro card
    - the `头像与标识` wrapper section
    - the separate `当前生效配置` summary card
    - the `区域内容` wrapper title
  - Configuration Center now renders a compact single-list control group:
    - `头像与标识`
    - `时间锚点`
    - `位置显示`
    - `记忆显示`
    - `边框样式`
  - the `时间锚点` row reads the currently selected homepage Memory Subject's
    anchors and uses a menu picker for immediate selection
  - the original A/B/C/D editor rows now sit directly below `边框样式`, without
    the extra ABCD chip/navigation wrapper
  - `V1EditorPageSurface` now keeps the preview outside the scroll view so the
    renderer preview remains visible while lower configuration content scrolls
  - the preview container uses slightly tighter horizontal padding to make the
    visible card larger while preserving the renderer/card internal ratio

- Verification:
  - hygiene check passed:
    - `git diff --check`
  - focused quick-action test passed:
    - `xcodebuild -project Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoTests -destination 'platform=macOS' -only-testing:PhotoMemoTests/V1IOSHomeQuickActionsTests CODE_SIGNING_ALLOWED=NO test`
  - iOS Simulator build passed:
    - `xcodebuild -project Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -destination 'generic/platform=iOS Simulator' -configuration Debug -derivedDataPath /tmp/PhotoMemoIOSDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
  - iOS device-architecture build passed:
    - `xcodebuild -project Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -destination 'generic/platform=iOS' -configuration Debug -derivedDataPath /tmp/PhotoMemoIOSDeviceDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`

- Not yet manually verified:
  - physical-device install/launch after this slice
  - current connected device `IPhone5` is visible to Xcode, but Developer Mode
    is disabled, so direct device build/install timed out waiting for the
    destination to become available
  - visual density on the actual small iPhone screen after removing homepage
    recent records and simplifying Configuration Center rows

## 2026-07-07 V1 visible Configuration Center migration continued

- The visible iOS runtime surface remains the four-tab `PhotoMemoiOSV1View`
  shell, not the standalone `ConfigurationCenteriOSView`.
- This slice continues correcting the earlier drift where polish landed in an
  off-path configuration surface.
- No renderer, export, metadata, share-extension, or photo-library behavior
  changed in this pass.

- What changed:
  - `PhotoMemoiOSV1View.editorPage` now renders the Configuration Center as:
    - explanation card
    - `头像与标识`
    - current effective configuration summary
    - folded region-content editor
    - bottom-only preset action panel
  - `V1AccessoryEntrySection` is now scoped to Logo 标识 only
  - time-anchor switching, location display, and memory display now stay in the
    visible summary panel instead of being duplicated in the old accessory area
  - `保存为当前配置` and `新建配置` remain bottom-only in the visible
    Configuration Center; the homepage still has no create/save entry
  - the old four-region editing capability is preserved, but now sits behind a
    clearer `区域内容` section instead of dominating the first visible page

- Verification:
  - hygiene check passed:
    - `git diff --check`
  - real-device build passed:
    - `xcodebuild -project Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -destination 'id=00008150-000A043136A1401C' -configuration Debug -derivedDataPath /tmp/PhotoMemoIOSDeviceDerivedData build`
  - installed and launched on connected iPhone7:
    - `xcrun devicectl device install app --device 863C2747-6742-5E93-B715-6F89DBF90B31 /tmp/PhotoMemoIOSDeviceDerivedData/Build/Products/Debug-iphoneos/PhotoMemoiOS.app`
    - `xcrun devicectl device process launch --device 863C2747-6742-5E93-B715-6F89DBF90B31 --terminate-existing --activate com.serydoo.PhotoMemo.iOS`

- Not yet manually verified:
  - the exact visual rhythm on the physical iPhone after tapping into the
    second `配置中心` tab
  - whether the summary panel still feels too text-heavy on smaller widths
  - whether the `区域内容` section should default-collapse all four regions even
    after users jump from the summary chips

- New user feedback to preserve before the next unified UI revision:
  - during upward scrolling on the lower Configuration Center page, the
    renderer/preview surface must not scroll offscreen
  - the intended behavior is a sticky/pinned preview container that remains
    visible while lower configuration content moves underneath or below it
  - treat this as a V1 configuration-page layout rule, not a renderer drawing
    change
  - preserve the renderer/card internal ratio while making the visible preview
    slightly larger for readability and stronger visual presence
  - this ratio-preserving enlargement existed in earlier
    `ConfigurationCenterTopPreviewSection` polish, but still needs to be
    applied to the currently visible V1 `PhotoMemoiOSV1View` /
    `V1EditorPageSurface` path
  - remove the separate summary module below the Configuration Center preview;
    the current `当前生效配置` card feels too complex and should not remain as
    an additional block
  - rework the Configuration Center controls toward the reference-image style:
    one compact list container with one row per configuration item
  - avoid first-level/second-level title stacking inside the configuration
    list; each row should be direct, simple, and scannable
  - proposed row model:
    - `头像与标识` combines avatar, Logo, and identity marker into one row
    - `时间锚点` is one row with current anchor and anchor count
    - `位置显示` is one row with current display mode/value
    - `记忆显示` is one row with current expression mode/result
    - `边框样式` is one row with the current locked style
  - tapping a row should reveal the relevant choices, such as the Logo
    three-option selector, allow selection, then collapse back to the clean
    one-line row
  - preserve function, but reduce visible structure: no extra summary card,
    no large explanatory sections, no nested visible editor hierarchy unless a
    row is actively opened
  - remove the lower summary panel as well; after the homepage selects the
    Memory Subject, the Configuration Center should not repeat the subject
    identity/object summary
  - Configuration Center rows should be driven by the currently selected
    homepage Memory Subject:
    - switching the Memory Subject on the homepage refreshes the Configuration
      Center's row values
    - `时间锚点` row reads the selected subject's available anchors
    - the right side of `时间锚点` shows the current anchor plus the subject's
      anchor count/status
    - tapping `时间锚点` opens the anchor choices, selecting one immediately
      applies it, and the row collapses back to the single-line state
  - subject editing and object identity remain in the homepage/object flow, not
    repeated inside the Configuration Center list
  - remove the ABCD icon/chip navigation area under `边框样式`; it does not add
    useful meaning once the rows are already simple and direct
  - remove the large section headers below the list, including the current
    `区域内容` style wrapper/title
  - after `边框样式`, place the original pre-optimization A/B/C/D configuration
    editing content directly underneath, preserving the actual editing
    behavior and row-style content from the earlier UI
  - keep the bottom save/create action area; the current save button treatment
    is acceptable

- Additional homepage feedback to preserve for the same unified revision:
  - compress the homepage `当前生效配置` area into the reference image's
    compact `当前配置` row-card style
  - homepage current-config row should be visually dense and direct:
    thumbnail/mini preview on the left, preset title + style in the middle,
    last modified time beneath, chevron / picker affordance on the right
  - keep homepage behavior: it switches among configurations owned by the
    currently selected Memory Subject; no homepage create/save entry
  - rename the lower main-entry section title from `主入口` to `快捷操作`
  - keep the four quick-action functions unchanged, but use larger, more
    expressive icon treatment
  - candidate large SF Symbols for the four existing quick actions:
    - `处理照片`: `photo.on.rectangle.angled`
    - `配置中心`: `slider.horizontal.3`
    - `时间锚点`: `calendar.badge.clock`
    - `使用说明`: `book.pages`
  - render quick-action icons as large visual anchors, not small inline glyphs:
    larger symbol font, soft rounded icon tile, clearer color per action
  - move the homepage `最近记录` section fully into the rightmost `任务` tab
  - if recent records remain visible during transition, keep them at the lower
    part of the Task page, not on the homepage
  - homepage goal after this revision: fit as a complete one-page overview with
    product header, current object, compact current config, and quick actions

## 2026-07-06 Phase 3 memory-display summary now owns anchor expression style

- The next Configuration Center polish slice is now in place and aligns more
  closely with the confirmed product boundary for time-anchor expression style.
- No renderer, export, metadata, or share-processing behavior changed in this
  pass.

- What changed:
  - `ConfigurationCenterSummarySection` now uses a dedicated:
    - `记忆显示`
    summary row
    for the current active time anchor
  - the new summary row shows:
    - current expression style title
    - formula-preview detail text
    - a direct style picker tied to the current active anchor
  - added `ConfigurationCenterMemoryDisplaySupport` as the summary/support
    helper for:
    - selected style
    - available styles
    - formula-preview detail
  - `ConfigurationSession` now exposes a focused mutation:
    - `selectCurrentTimeAnchorExpressionStyle(_:)`
    so the summary picker can update only the current active anchor
  - `MemorySubjectEditorView` no longer renders the old
    `表达样式` section under time-anchor maintenance
  - object-editor helper copy now explicitly says:
    - active-anchor switching
    - memory display
    both live in the Configuration Center summary area now

- Why this matters:
  - the “expression formula / display style” capability is no longer split
    awkwardly between:
    - object maintenance
    - top-level configuration summary
  - this better matches the intended rhythm:
    - object page maintains anchor data
    - configuration summary decides how the current anchor is displayed
  - it reduces one of the biggest remaining mismatches between the current UI
    and the user-confirmed Configuration Center structure

- Verification:
  - focused tests passed:
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoTests -destination 'platform=macOS' -only-testing:PhotoMemoTests/ConfigurationCenterMemoryDisplaySupportTests -only-testing:PhotoMemoTests/ConfigurationSessionConfigurationLifecycleTests CODE_SIGNING_ALLOWED=NO test`
  - required builds passed:
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -destination 'generic/platform=iOS Simulator' -configuration Debug -derivedDataPath /tmp/PhotoMemoIOSDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
  - hygiene check passed:
    - `git diff --check`

- Not yet manually verified:
  - the new `记忆显示` row wrapping behavior on smaller iPhone widths
  - whether the formula-preview detail feels too long beside the summary card
  - whether removing the old object-page `表达样式` block makes the overall
    anchor-maintenance page feel visually lighter in device use

## 2026-07-06 Phase 3 config-center preset actions reduced to bottom-only

- The next Configuration Center polish slice now matches the latest confirmed
  preset-action boundary more closely.
- No save/create behavior changed; only duplicate top-level entry points were
  removed from the iOS Configuration Center preview surface.

- What changed:
  - `ConfigurationCenterTopPreviewSection` no longer renders the duplicated:
    - `新建`
    - `保存当前`
    buttons inside the top preview profile card
  - the top preview now keeps:
    - current preset name
    - rename
    - reset
    - summary detail
    - an explicit reminder that save/create belong to the bottom action area
  - the actual functional save/create actions remain in the bottom
    Configuration Center context action group:
    - `新建配置`
    - `保存为当前配置`

- Why this matters:
  - it restores the user-confirmed rule that configuration creation and saving
    should happen in one consistent bottom location
  - the top preview becomes more of a summary/identity surface and less of a
    duplicated control center
  - this makes the boundary between:
    - homepage switch existing configs
    - Configuration Center bottom save/create
    clearer across both main surfaces

- Verification:
  - required builds passed:
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -destination 'generic/platform=iOS Simulator' -configuration Debug -derivedDataPath /tmp/PhotoMemoIOSDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
  - hygiene check passed:
    - `git diff --check`

- Not yet manually verified:
  - top preview spacing after removing the two action chips
  - whether the new `底部操作区` reminder is visually clear enough on smaller
    iPhones

## 2026-07-06 Phase 3 homepage current-config readability stabilized

- The latest homepage configuration-summary slice is now fully closed with
  clearer switching language and deterministic save-time formatting.
- No renderer, export, metadata, or processing behavior changed in this pass.

- What changed:
  - homepage current-configuration fact strip now reads:
    - `切换`
    - `下拉即生效`
    instead of the more internal-feeling:
    - `入口`
    - `首页切换`
  - `V1IOSHomeProjection.savedStatusValue` now formats save timestamps through
    an explicit Gregorian calendar + injectable time-zone path
  - homepage still defaults to the device's current time zone, so the visible
    `最近保存` line remains local to the user
  - focused test coverage now locks both:
    - unsaved fallback
    - saved timestamp rendering under explicit time zones

- Why this matters:
  - homepage current-configuration card now reads more like a product summary
    and less like an internal entry-point description
  - save-time formatting tests no longer depend on whichever locale/time zone
    happens to run the suite
  - this closes the remaining rough edge in the homepage “switch existing
    subject-owned configs only” boundary before moving deeper into
    Configuration Center polish

- Verification:
  - focused test passed:
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoTests -destination 'platform=macOS' -only-testing:PhotoMemoTests/V1IOSHomeProjectionTests CODE_SIGNING_ALLOWED=NO test`
  - required V1 iOS build passed:
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOSV1 -destination 'generic/platform=iOS Simulator' -configuration Debug -derivedDataPath /tmp/PhotoMemoiOSV1DerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
  - hygiene check passed:
    - `git diff --check`

- Not yet manually verified:
  - homepage `最近保存` line on real iPhone widths with longer month/day values
  - whether `切换 / 下拉即生效` feels visually balanced beside the `管理` menu
    on smaller screens

## 2026-07-06 Phase 3 task-vs-settings navigation split landed

- The next thin V1 navigation slice is now in place and stays in the iOS
  presentation/navigation layer only.
- No renderer, export, metadata, or task-processing semantics changed in this
  pass.
- This slice follows the newly confirmed boundary:
  - bottom fourth main tab = `任务`
  - homepage top-right button = `设置`
  - usage/welcome content moves out of the old combined task/settings surface

- What changed:
  - `PhotoMemoiOSV1View` bottom fourth tab now reads:
    - `任务`
    instead of:
    - `设置`
  - the bottom task tab now renders `V1TaskPageSurface`, which keeps only:
    - `当前处理`
    - `最近记录`
  - homepage `最近记录` section now routes its `查看全部` action to the
    bottom `任务` tab instead of the top-right settings entry
  - homepage top-right settings button now opens a separate sheet-level
    `V1SettingsPageSurface`
  - homepage `使用说明` quick entry also routes into the new settings sheet for
    now, so guide content converges in one place
  - the new `V1SettingsPageSurface` is now a lighter explanation/help surface
    that holds:
    - `重新查看欢迎说明`
    - `查看使用流程`
    - current product-principle reminders
  - `ConfigurationCenteriOSView` settings sheet was updated to use the same new
    explanation-style settings page, so the shared settings surface stays
    consistent
  - `V1EntryFlowCoordinator` now distinguishes:
    - opening the bottom `任务` tab
    - opening/closing the separate homepage settings sheet

- Verification:
  - focused tests passed via the testable scheme:
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoTests -destination 'platform=macOS' -only-testing:PhotoMemoTests/V1EntryFlowCoordinatorTests -only-testing:PhotoMemoTests/V1SettingsPagePresenterTests -only-testing:PhotoMemoTests/V1IOSHomeQuickActionsTests test`
  - required builds passed:
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -destination 'generic/platform=iOS Simulator' -configuration Debug -derivedDataPath /tmp/PhotoMemoIOSDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOSV1 -destination 'generic/platform=iOS Simulator' -configuration Debug -derivedDataPath /tmp/PhotoMemoiOSV1DerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
  - hygiene check passed:
    - `git diff --check`

- Not yet manually verified:
  - bottom tab label/icon rhythm after `设置 -> 任务`
  - homepage top-right settings icon visual balance on device
  - settings sheet open/close rhythm from homepage and from Configuration Center
  - whether routing `使用说明` into settings feels better than a direct guide
    jump on smaller iPhone widths

## 2026-07-06 Phase 3 home preset ownership alignment landed

- The next thin homepage configuration slice is now in place and stays focused
  on preset-selection behavior and V1 view wiring.
- No renderer, export, metadata, or share-processing behavior changed in this
  pass.
- This slice implements the newly confirmed rule that homepage configuration
  switching follows the currently selected memory subject.

- What changed:
  - `ConfigurationSession` now exposes:
    - `availableMemoryPresetsForSelectedSubject`
  - subject changes now actively realign the selected preset to the current
    memory subject when subject-owned presets exist
  - preset realignment also restores the saved anchor/output/write-text context
    from the matched subject preset
  - homepage preset picker now uses only the current subject's available preset
    list instead of the whole repository-wide preset array
  - homepage preset title falls back to a clearer empty-state line when the
    current subject has no available preset yet
  - mock seed presets now carry concrete subject ownership so the compact V1
    flow has realistic per-subject behavior during preview/testing

- Behavioral result:
  - switching `记忆对象` on homepage now refreshes the current configuration
    card toward that object's own preset context
  - homepage preset dropdown is no longer a global mixed-subject list

- Verification:
  - focused tests passed:
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoTests -destination 'platform=macOS' -only-testing:PhotoMemoTests/ConfigurationSessionConfigurationLifecycleTests -only-testing:PhotoMemoTests/V1EntryFlowCoordinatorTests -only-testing:PhotoMemoTests/V1IOSHomeQuickActionsTests test`
  - required builds passed:
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -destination 'generic/platform=iOS Simulator' -configuration Debug -derivedDataPath /tmp/PhotoMemoIOSDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOSV1 -destination 'generic/platform=iOS Simulator' -configuration Debug -derivedDataPath /tmp/PhotoMemoiOSV1DerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
  - hygiene check passed:
    - `git diff --check`

- Not yet manually verified:
  - homepage preset-card copy when the selected subject has zero owned presets
  - real user data upgraded from older subject-unowned presets
  - switching back and forth between multiple real saved subject presets on
    device

## 2026-07-06 Phase 3 config-center-create to home-picker continuity locked

- The interaction boundary was clarified again and is now explicitly preserved:
  - `新建配置` remains in the Configuration Center bottom action area
  - homepage `当前生效配置` remains a subject-scoped picker/switcher only
- No homepage create entry was kept.

- What changed:
  - added a focused lifecycle test that locks the intended continuity:
    - when the user creates a new configuration from the Configuration Center,
      the same subject immediately sees that new configuration in the homepage
      picker list
  - this confirms the shared-session wiring remains intact between:
    - Configuration Center bottom actions
    - homepage current-configuration picker

- Verification:
  - focused test passed:
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoTests -destination 'platform=macOS' -only-testing:PhotoMemoTests/ConfigurationSessionConfigurationLifecycleTests CODE_SIGNING_ALLOWED=NO test`
  - hygiene check passed:
    - `git diff --check`

- Not yet manually verified:
  - live device flow for:
    - create one preset in Configuration Center
    - return to homepage
    - switch presets under the same memory subject

## 2026-07-06 Phase 3 homepage preset card returned to switch-only mode

- The homepage current-configuration card was tightened again to match the
  latest product boundary more closely.
- Homepage no longer offers configuration-saving actions.
- The card is now focused on:
  - showing the current subject-scoped configuration state
  - switching among that subject's existing configurations
  - pointing users back to Configuration Center when none exist yet

- What changed:
  - removed the homepage `保存为当前配置 / 重新保存当前配置` action
  - homepage current-configuration card now treats the Configuration Center as
    the only place to:
    - `保存为当前配置`
    - `新建配置`
  - when the selected memory subject has no owned configurations:
    - the homepage card no longer renders an effectively empty picker menu
    - the preset summary no longer reuses another subject's stale summary copy
    - the card now shows an explicit empty-state explanation that tells the
      user to create the configuration in the Configuration Center bottom area
  - existing subject-owned configurations remain switchable from the homepage
    picker when available

- Verification:
  - focused tests passed:
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoTests -destination 'platform=macOS' -only-testing:PhotoMemoTests/V1IOSHomeProjectionTests -only-testing:PhotoMemoTests/ConfigurationSessionConfigurationLifecycleTests CODE_SIGNING_ALLOWED=NO test`
  - required V1 iOS build passed:
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOSV1 -destination 'generic/platform=iOS Simulator' -configuration Debug -derivedDataPath /tmp/PhotoMemoiOSV1DerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
  - hygiene check passed:
    - `git diff --check`

- Not yet manually verified:
  - homepage current-configuration card spacing after removing the bottom save
    button
  - empty-state readability on smaller iPhones when a subject has zero
    configurations
  - whether homepage rename affordance still feels discoverable enough once the
    card becomes switch-only

## 2026-07-06 Phase 3 homepage primary cards moved closer to summary-card rhythm

- The next thin homepage polish slice stayed inside the V1 iOS presentation
  layer and did not change configuration ownership or save/create boundaries.
- This slice focused on making the two top homepage cards feel less like
  stacked control panels and more like compact mobile summary surfaces.

- What changed:
  - `记忆对象` card now reads more like:
    - avatar
    - display name
    - relationship tag
    - configured anchor count
    - current active anchor
  - the subject card avatar was slightly reduced so the text summary gets more
    room without making the card feel heavier
  - `当前生效配置` card now foregrounds:
    - current configuration title
    - current object/anchor line
    - compact fact chips
    - switch area
  - removed more of the repeated explanatory copy from the middle of the card
    and replaced it with a denser summary rhythm
  - the preset operations affordance now reads `管理` instead of showing only an
    ellipsis icon, so `重命名配置` is easier to discover from the homepage
  - homepage reminder copy now reinforces the final boundary:
    - homepage only switches existing subject-owned configurations
    - create/save still belong to the Configuration Center bottom area

- Verification:
  - focused tests passed:
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoTests -destination 'platform=macOS' -only-testing:PhotoMemoTests/V1IOSHomeProjectionTests -only-testing:PhotoMemoTests/V1SubjectHomeSummaryPresenterTests -only-testing:PhotoMemoTests/V1IOSHomeQuickActionsTests CODE_SIGNING_ALLOWED=NO test`
  - required V1 iOS build passed:
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOSV1 -destination 'generic/platform=iOS Simulator' -configuration Debug -derivedDataPath /tmp/PhotoMemoiOSV1DerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
  - hygiene check passed:
    - `git diff --check`

- Not yet manually verified:
  - whether the new `管理` label feels balanced beside the picker on smaller
    iPhones
  - whether `锚点数量` should later be changed from total anchor count to a more
    explicit “已自定义” count if product semantics tighten further
  - final spacing balance between:
    - subject card
    - current configuration card
    - quick-entry tile row

## 2026-07-06 Phase 3 homepage top-cluster spacing tightened

- This follow-up homepage slice stayed purely visual and only tightened the
  rhythm between the first three homepage sections.

- What changed:
  - grouped:
    - `记忆对象`
    - `当前生效配置`
    - `主入口`
    into a slightly tighter top summary cluster
  - reduced the quick-entry tile grid gaps so the four primary actions read
    more like one compact strip instead of a heavier secondary panel
  - compressed the quick-entry tiles themselves:
    - slightly smaller icon block
    - slightly shorter copy
    - reduced minimum height
    - slightly smaller corner radius
  - pushed `最近记录` a touch lower so the homepage hierarchy is clearer:
    - top = summary and switching
    - lower = processing history

- Verification:
  - focused tests passed:
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoTests -destination 'platform=macOS' -only-testing:PhotoMemoTests/V1IOSHomeQuickActionsTests -only-testing:PhotoMemoTests/V1IOSHomeProjectionTests CODE_SIGNING_ALLOWED=NO test`
  - required V1 iOS build passed:
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOSV1 -destination 'generic/platform=iOS Simulator' -configuration Debug -derivedDataPath /tmp/PhotoMemoiOSV1DerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
  - hygiene check passed:
    - `git diff --check`

- Not yet manually verified:
  - whether the four primary tiles still feel easy enough to tap on smaller
    iPhones after the compression pass
  - whether `主入口` is a better title than `快捷入口` in live use

## 2026-07-06 Phase 3 homepage quick-entry tile polish landed

- The next thin homepage visual slice is now in place and stays inside the V1
  iOS presentation layer only.
- No renderer, export, metadata, or configuration-state semantics changed in
  this pass.
- This slice also preserves the clarified boundary that:
  - homepage does not carry renderer preview
  - Configuration Center keeps the preview surface

- What changed:
  - `V1HomePageSurface` top header is now lighter and reads more like a product
    definition block instead of another framed control card
  - the homepage header copy now reflects the README direction around
    local-first memory presentation
  - the top pills now emphasize:
    - `本地优先`
    - `Apple Photos`
    instead of repeating homepage object summary content
  - `V1IOSHomeQuickActionsContent` no longer renders a vertical settings-list
    row group
  - homepage quick entry is now rendered as four compact tiles in one row for:
    - `处理照片`
    - `配置中心`
    - `时间锚点`
    - `使用说明`
  - quick-action tiles use shorter helper copy so the one-row mobile layout
    stays compact without reintroducing a dashboard-style list

- Verification:
  - focused test passed:
    - `V1IOSHomeQuickActionsTests`
  - required builds passed:
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -destination 'platform=macOS' -only-testing:PhotoMemoTests/V1IOSHomeQuickActionsTests test`
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -destination 'generic/platform=iOS Simulator' -configuration Debug -derivedDataPath /tmp/PhotoMemoIOSDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOSV1 -destination 'generic/platform=iOS Simulator' -configuration Debug -derivedDataPath /tmp/PhotoMemoiOSV1DerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
  - hygiene check passed:
    - `git diff --check`

- Not yet manually verified:
  - one-row four-tile readability on smaller iPhone widths
  - top header spacing after removing the outer framed card
  - live tap comfort for the four compact tiles on device

## 2026-07-06 Phase 3 homepage current-configuration language convergence landed

- The next thin V1 homepage language slice is now in place without expanding
  into configuration logic or structural rewrites.
- Homepage summary language now aligns more closely with the active
  Configuration Center terminology around:
  - `记忆对象`
  - `当前生效配置`
  - `当前生效锚点`
  - `最近记录`

- What changed:
  - `V1HomePageSurface` now uses:
    - a product-definition subtitle closer to the current README positioning
    - `记忆对象` instead of `当前记忆对象`
    - `当前生效配置` instead of `当前配置`
    - `快捷入口` instead of `快捷操作`
    - `最近记录` instead of `最近处理`
    - `保存为当前配置` wording on the homepage action button
  - homepage helper copy now describes the active configuration as the current
    generation/display bundle rather than the old default-configuration wording
  - `V1IOSHomeProjection` fallback strings now prefer:
    - `当前生效配置`
    - `当前生效配置摘要`
  - `V1IOSHomeQuickAction.defaultActions` subtitles now align with the newer
    product language for Configuration Center, active anchor context, and Apple
    Photos usage guidance

- Verification:
  - focused tests passed:
    - `V1IOSHomeProjectionTests`
    - `V1IOSHomeQuickActionsTests`
  - required build passed:
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`

- Not yet manually verified:
  - V1 homepage card titles and helper copy rhythm on device
  - homepage save-current-configuration button wording in the live V1 flow
  - quick-entry subtitle wrapping on smaller iPhone widths

## 2026-07-06 Phase 3 save-current-configuration language convergence landed

- The follow-up wording slice is now in place behind the homepage so the save
  flow no longer mixes `当前配置` in the entry UI with `默认配置` in the
  confirmation and status language.

- What changed:
  - `V1ConfigurationStatus` default-configuration messages now use:
    - `尚未保存为当前配置`
    - `已保存为当前配置`
  - `PhotoMemoiOSV1View` preset-activation confirmation now uses:
    - `将当前生效配置保存下来？`
    - `保存为当前配置`
  - the activation helper message now describes future processing in terms of
    the current configuration, active time anchor, and output settings rather
    than the old default-configuration phrasing
  - the logo persistence hint now also points to `保存为当前配置`

- Verification:
  - focused tests passed:
    - `V1ConfigurationStatusTests`
    - `V1IOSHomeProjectionTests`
    - `V1IOSHomeQuickActionsTests`
  - required build passed:
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`

- Not yet manually verified:
  - V1 save-current-configuration confirmation dialog wording on device
  - dirty logo / 标识 persistence hint wording in the live editor flow
  - whether the new confirmation message wraps cleanly on narrower iPhone widths

## 2026-07-06 Phase 3 memory-subject title convergence landed

- The next thin wording slice is now in place across the V1 homepage/object
  summary path so the visible object language no longer mixes
  `当前记忆对象` and `记忆对象` for the same concept.

- What changed:
  - `V1IOSHomeProjection` subject fallback title now uses:
    - `记忆对象`
  - homepage/object-entry labels now converge to:
    - `记忆对象`
  - the homepage quick entry subtitle now uses:
    - `查看记忆对象与生效锚点`
  - the iOS subject overview sheet now uses:
    - `记忆对象`
    - `删除这个记忆对象？`
  - subject-home summary fallback tests and copy were updated to match the new
    wording

- Verification:
  - focused tests passed:
    - `V1IOSHomeProjectionTests`
    - `V1IOSHomeQuickActionsTests`
    - `V1SubjectHomeSummaryPresenterTests`
  - required build passed:
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`

- Not yet manually verified:
  - V1 object overview navigation title and delete-confirmation wording on device
  - homepage object card visual rhythm after the shorter `记忆对象` label
  - smaller iPhone widths for the updated quick-entry subtitle

## 2026-07-06 Phase 3 preset-entry language convergence landed

- The next thin wording slice is now in place around the V1 preset entry path.
- This slice stays intentionally narrow:
  - homepage/current-summary preset language only
  - no preset data-model changes
  - no Configuration Center preset-menu rewrite yet

- What changed:
  - `V1PresetPicker` now labels the picker as:
    - `当前生效配置`
    instead of:
    - `当前配置组合`
  - `V1PresetOperationsMenu` now uses:
    - `重命名配置`
    instead of:
    - `重命名配置组合`
  - the V1 subject-home summary helper line now says future processing will
    continue using:
    - `当前生效配置与时间锚点`
    instead of the older `配置组合` wording

- Verification:
  - focused tests passed:
    - `V1IOSHomeProjectionTests`
    - `V1IOSHomeQuickActionsTests`
    - `V1SubjectHomeSummaryPresenterTests`
  - required build passed:
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`

- Not yet manually verified:
  - V1 preset picker title and rename action wording on device
  - subject-home helper copy wrapping after the shorter preset language
  - any remaining `配置组合` wording inside Configuration Center preset menus,
    which is intentionally left for a later slice

## 2026-07-06 Phase 3 configuration-center preset title convergence landed

- The follow-up Configuration Center slice is now in place so the top preset
  control no longer uses a different label from the surrounding page chrome.

- What changed:
  - `ConfigurationCenterPresetMenu` now labels the control as:
    - `当前生效配置`
    instead of:
    - `配置组合`
  - this brings the preset menu into line with:
    - `ConfigurationCenterTopPreviewSection`
    - the homepage current-configuration wording

- Verification:
  - required build passed:
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
  - searched remaining iOS view/test surfaces for:
    - `配置组合`
    and found no remaining matches in the active iOS view layer

- Not yet manually verified:
  - Configuration Center top preset control wording on device
  - visual balance of the longer `当前生效配置` label inside the compact menu

## 2026-07-06 Phase 3 configuration-center current-configuration language convergence landed

- The next thin Configuration Center wording slice is now in place.
- This pass focuses on the remaining `当前配置` copy inside the active
  Configuration Center flow and converges it toward the newer
  `当前生效配置` language where appropriate.
- For status-pill language, this slice also avoids the awkward literal
  phrasing `当前生效配置尚未生效` and replaces it with more natural copy.

- What changed:
  - `ConfigurationCenterTopPreviewSection` now uses:
    - `当前生效配置预览`
  - `ConfigurationCenterSessionBindingPresenter` now reports:
    - `当前生效配置尚未保存`
  - `ConfigurationCenterLocationDisplaySupport` now says:
    - `当前生效配置里还没有插入位置模块...`
  - `ConfigurationCenterSummarySection` now points region jumps to:
    - `当前生效配置的编辑位置`
  - `ConfigurationCenterPageChromePresenter` status copy now uses:
    - `当前配置改动尚未生效`
    - `当前生效配置已同步`

- Verification:
  - focused tests passed:
    - `ConfigurationCenterPageChromePresenterTests`
    - `ConfigurationCenterSessionBindingPresenterTests`
    - `ConfigurationCenterLocationDisplaySupportTests`
  - required build passed:
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`

- Not yet manually verified:
  - Configuration Center preview title and top status pill wording on device
  - summary/detail helper wrapping after the longer `当前生效配置` wording

## 2026-07-06 Phase 3 configuration-center top rhythm polish landed

- The next thin UI-polish slice is now in place and stays strictly in the
  visual layer.
- No state flow, renderer flow, export flow, or configuration semantics were
  changed in this pass.

- What changed:
  - `ConfigurationCenterTopPreviewSection` product statement is now rendered as
    a distinct rounded card instead of bare text, which gives the page header a
    clearer visual starting point
  - the top status pill now uses:
    - icon + tinted background
    - applied vs pending visual distinction
  - `ConfigurationCenterSummarySection` introductory sentence is now rendered
    as a lightweight hint block instead of a loose top paragraph
  - `ConfigurationCenteriOSView` now passes the active preset state through so
    the top status pill can reflect it visually

- Verification:
  - required build passed:
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`

- Not yet manually verified:
  - top header card spacing on iPhone widths
  - pending/applied top status pill contrast and readability on device
  - summary intro hint block rhythm relative to the first summary row

## 2026-07-06 Phase 3 configuration-center responsive compile closure landed

- The follow-up responsive slice is now verified against the actual iOS build
  targets instead of only the repository-standard macOS scheme.
- This pass stayed narrow:
  - no state-flow expansion
  - no renderer/layout ownership change
  - no export or metadata behavior change

- What changed:
  - `ConfigurationCenterTopPreviewSection` now restores the intended
    `workflowChips` surface so the product-statement card keeps its compact
    object / anchor / output guidance row
  - `ConfigurationCenteriOSView` now uses explicit `return` statements in the
    new iOS-only computed properties that build the summary section and output
    panel model
  - this closes the gap where the earlier macOS-only build passed while the
    actual iOS schemes still failed to compile the newly added summary/polish
    surfaces

- Why this matters:
  - the latest Configuration Center top-area polish is now backed by the real
    `PhotoMemoiOS` and `PhotoMemoiOSV1` compile paths
  - future UI polishing can continue from a verified iPhone build baseline
    instead of relying on a macOS-only signal

- Verification:
  - passed iOS simulator build:
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -destination 'generic/platform=iOS Simulator' -configuration Debug -derivedDataPath /tmp/PhotoMemoIOSDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
  - passed V1 iOS simulator build:
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOSV1 -destination 'generic/platform=iOS Simulator' -configuration Debug -derivedDataPath /tmp/PhotoMemoiOSV1DerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
  - passed required repository build:
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
  - passed whitespace check:
    - `git diff --check`

- Not yet manually verified:
  - top product-statement chip row wrapping on narrower iPhone widths
  - summary/header spacing after the restored workflow-chip row
  - the latest compact top rhythm on physical device scroll behavior

## 2026-07-06 Phase 3 configuration-center mobile-summary visual convergence landed

- This follow-up stays in the same top-summary polish lane and only adjusts the
  visual hierarchy of the iOS Configuration Center.
- No configuration logic, renderer ownership, export behavior, or navigation
  flow changed in this pass.

- What changed:
  - `ConfigurationCenterTopPreviewSection` now pulls the product definition
    back out of the heavy rounded container and renders it closer to the
    reference direction:
    - stronger `PhotoMemo` title
    - lighter `配置中心` label
    - borderless explanatory copy area
    - compact object / anchor / output chip row
  - the preview block now reads more like a mobile preview stage:
    - clearer `记忆卡片预览` heading
    - softer gray stage background
    - slightly larger visible preview area while preserving renderer ratio
  - compact preset facts now stack more cleanly on narrow widths instead of
    trying to keep two facts on one compressed row
  - `ConfigurationCenterSummarySection` now reads more like a mobile settings
    list:
    - large rounded icon tiles on the left
    - stronger row titles
    - simpler top explanation line
    - whiter card surfaces with softer elevation

- Why this matters:
  - the Configuration Center top area is now closer to the visual rhythm shown
    in the product references: title first, preview second, concise summary rows
    below
  - the summary section feels less like a dense editor block and more like a
    scannable configuration digest

- Verification:
  - passed iOS simulator build:
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -destination 'generic/platform=iOS Simulator' -configuration Debug -derivedDataPath /tmp/PhotoMemoIOSDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
  - passed V1 iOS simulator build:
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOSV1 -destination 'generic/platform=iOS Simulator' -configuration Debug -derivedDataPath /tmp/PhotoMemoiOSV1DerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
  - passed required repository build:
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
  - passed whitespace check:
    - `git diff --check`

- Not yet manually verified:
  - actual live Configuration Center surface on simulator after clearing the
    current photo-permission onboarding interruption
  - title/subtitle balance on smaller iPhone widths
  - preview-stage spacing and summary-card elevation on physical device

## 2026-07-06 Phase 3 configuration-center summary trailing cleanup landed

- This follow-up remains a thin visual-only slice inside the same summary card.
- No selection logic, anchor switching, location switching, or navigation
  destination changed in this pass.

- What changed:
  - `ConfigurationCenterSummarySection` object row no longer uses the more
    engineering-flavored `进入对象配置` button label on the right
  - the object row now exposes a lighter mobile-list style affordance:
    - anchor count as the primary right-side value
    - `对象详情` as the small helper line
    - trailing chevron
  - the memory-write row now uses the same lighter disclosure rhythm:
    - `调整`
    - `表达方式`
    - trailing chevron
  - the border-style row now shows a quiet `当前锁定` status badge instead of
    leaving the right side visually empty

- Why this matters:
  - the summary list now reads closer to the product references:
    - left side = current effective state
    - right side = lightweight value / navigation hint
  - this reduces the “editor button” feeling and makes the page feel more like
    a compact configuration digest

- Verification:
  - passed iOS simulator build:
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -destination 'generic/platform=iOS Simulator' -configuration Debug -derivedDataPath /tmp/PhotoMemoIOSDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
  - passed V1 iOS simulator build:
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOSV1 -destination 'generic/platform=iOS Simulator' -configuration Debug -derivedDataPath /tmp/PhotoMemoiOSV1DerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
  - passed required repository build:
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
  - passed whitespace check:
    - `git diff --check`

- Not yet manually verified:
  - right-side disclosure rhythm beside long subject names
  - anchor-count/value balance on narrower iPhone widths
  - whether the new quiet badge/disclosure tone still feels obvious enough on
    device

## 2026-07-06 Phase 3 configuration-center preset-card action softening landed

- This follow-up remains inside the same top-summary lane and only adjusts the
  visual tone of the active-preset card.
- No preset lifecycle behavior, save semantics, or region-selection behavior
  changed in this pass.

- What changed:
  - `ConfigurationCenterTopPreviewSection` no longer uses the more toolbar-like
    helper line above the preset actions
  - the top preset card now surfaces:
    - `currentMemoryPresetSummary` as the short descriptive summary
    - softer capsule actions for `新建` and `保存当前`
    - lighter visual separation between summary text and actions

- Why this matters:
  - the active-preset block now reads more like a compact configuration card
    and less like a row of editor controls
  - this moves the top area closer to the reference direction of:
    - current config first
    - actions second

- Verification:
  - passed iOS simulator build:
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -destination 'generic/platform=iOS Simulator' -configuration Debug -derivedDataPath /tmp/PhotoMemoIOSDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
  - passed V1 iOS simulator build:
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOSV1 -destination 'generic/platform=iOS Simulator' -configuration Debug -derivedDataPath /tmp/PhotoMemoiOSV1DerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
  - passed required repository build:
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
  - passed whitespace check:
    - `git diff --check`

- Not yet manually verified:
  - summary text wrapping in the preset card on narrow widths
  - action-pill weight relative to the surrounding fact rows
  - whether the top card now feels sufficiently lighter than the preview stage

## 2026-07-06 Phase 3 configuration-center preset-status hierarchy cleanup landed

- This follow-up remains a thin visual cleanup inside the active-preset block.
- No save logic, preset identity, or status source changed in this pass.

- What changed:
  - `ConfigurationCenterTopPreviewSection` now uses the top-right pill only for
    a short state label:
    - `已同步`
    - `待保存`
  - the longer preset save-time/status text now lives under the preset title
    instead of competing inside both the pill and the fact row
  - the compact fact row was reduced to the 2 remaining stable summary facts:
    - `边框`
    - `输出`

- Why this matters:
  - the active-preset card now has clearer hierarchy:
    - title
    - save-time/status context
    - stable summary facts
  - this reduces duplicate status language and makes the top summary feel less
    crowded

- Verification:
  - passed iOS simulator build:
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -destination 'generic/platform=iOS Simulator' -configuration Debug -derivedDataPath /tmp/PhotoMemoIOSDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
  - passed V1 iOS simulator build:
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOSV1 -destination 'generic/platform=iOS Simulator' -configuration Debug -derivedDataPath /tmp/PhotoMemoiOSV1DerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
  - passed required repository build:
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
  - passed whitespace check:
    - `git diff --check`

- Not yet manually verified:
  - save-time line truncation on smaller widths
  - the balance between the short top-right state pill and the longer subtitle
  - whether the reduced fact row now reads cleaner on device

## 2026-07-06 P0 surface convergence landed

- The main iOS runtime no longer exposes the old dual-surface product switch
  (`V1` vs `Configuration Center`) through `PhotoMemoiOSTemporaryEntryView`
- `PhotoMemoRootSceneView` now enters `ConfigurationCenteriOSView` directly on
  iOS, which restores one active runtime product surface
- V1 is still preserved as code and target for maintenance/testing, but it is
  no longer part of the main runtime root-scene switch

- The second P0 issue from the latest V1 re-audit also landed:
  bootstrap/programmatic subject restore no longer shares the same dirtying
  behavior as user edits
- `V1SubjectSelectionMutationCoordinator` now distinguishes:
  - user birthday edits
  - subject-driven birthday sync that should refresh without dirtying
  - bootstrap-driven birthday sync that should neither dirty nor trigger an
    extra refresh

- Focused tests passed:
  - `IOSRuntimeSurfaceContractTests`
  - `V1SubjectSelectionMutationCoordinatorTests`
  - `V1BootstrapRuntimeCoordinatorTests`
  - `V1DraftRuntimeCoordinatorTests`
  - `V1SubjectLibrarySupportTests`
  - `PhotoMemoiOSTemporaryEntryTests`
- Required repo build passed:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`

- Still not manually verified after this slice:
  - device/runtime launch now entering Configuration Center directly
  - standalone V1 target behavior on device
  - device subject-switch / active-anchor visual behavior after dirty-path split

## 2026-07-06 P1 typed configuration status convergence landed

- The agreed Phase 2 status cleanup is now in place without mixing in the
  later anchor-language or projection-unification work.
- V1 configuration state is now modeled by `V1ConfigurationStatus`:
  - `idle`
  - `dirty`
  - `saving`
  - `saved`
  - `subjectSynced`
  - `failure(message:)`
- UI copy is now derived from status + context instead of driving behavior:
  - default configuration
  - share configuration
  - preset
- The main migration points are:
  - `V1DraftMutationCoordinator`
  - `V1DraftBridge`
  - `V1DraftOrchestrationCoordinator`
  - `V1ConfigurationApplySupport`
  - `V1ConfigurationApplyRuntimeCoordinator`
  - `V1SubjectFlowSupport`
  - `V1PresetSelectionCoordinator`
  - `V1LogoSelectionSupport`
  - `V1IOSHomeProjection`
  - `V1SubjectHomeSummarySupport`
  - `PhotoMemoiOSV1View`

- Focused tests passed:
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
- Required repo build passed:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`

- Still not manually verified after this slice:
  - device save / sync / failure badge transitions in V1 home/status surfaces
  - preset switch confirmation/cancel flow on device
  - subject overview -> editor -> save status callback path on device

## 2026-07-06 Phase 3 homepage language convergence landed

- The first product-language cleanup slice is now in place without jumping
  ahead into canonical projection sharing.
- Homepage summary surfaces no longer expose anchor-count language as a primary
  summary fact.
- Removed the old homepage `anchorCountLabel` chain from:
  - `V1IOSHomeProjection`
  - `V1SubjectHomeSummarySupport`
  - related homepage-focused tests
- Homepage fallback guidance now prefers:
  - `补充主角信息`
  instead of:
  - `补充主角与时间锚点`

- Kept intentionally out of scope:
  - `V1IOSSubjectOverviewPresenter`
  - subject overview detail-page anchor-count badge / expression
  - canonical projection extraction / presenter sharing

- Focused tests passed:
  - `V1IOSHomeProjectionTests`
  - `V1SubjectHomeSummaryPresenterTests`
- Required repo build passed:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`

- Still not manually verified after this slice:
  - homepage subject summary copy on device after subject switching
  - homepage spacing/visual rhythm after removing the old anchor-count detail

## 2026-07-06 Phase 3 overview anchor-language convergence landed

- The remaining old anchor-count expression inside the V1 subject overview path
  is now removed.
- `V1IOSSubjectOverviewPresentation` no longer carries `anchorCountLabel`.
- `V1IOSSubjectAnchorSection` no longer shows the old `X 个时间锚点` badge.
- The active-anchor detail card now stays focused on:
  - active anchor title
  - active anchor date
  - active anchor description
  - active anchor picker

- Focused tests passed:
  - `V1IOSSubjectOverviewPresenterTests`
- Required repo build passed:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`

- Still not manually verified after this slice:
  - overview active-anchor card spacing on device
  - anchor switching flow in overview after the badge removal

## 2026-07-06 iPhone7 Location and MemorySubject production fixes installed

- User device testing confirmed Location display configuration worked in
  preview but production output initially fell back to raw GPS coordinates for
  GPS-only photos.
- The production import path now enriches GPS metadata through the local Apple
  reverse-geocoding flow before Location provider resolution.
- Explicit Location display configuration no longer falls back to legacy raw
  coordinates when the configured semantic display cannot resolve text.
- A second device issue showed Time Anchor preview using the selected subject
  `途途` while production output showed the default subject text `家人`.
- Root cause: production snapshot loading only consulted the standalone
  selected subject payload before falling back to legacy profile defaults, while
  preview restored the selected subject from the V1 subject library record.
- `BatchConfigurationSnapshotProvider` now resolves the frozen production
  `MemorySubject` from the selected V1 subject-library record before using the
  standalone selected subject or legacy profile fallback.
- Verified focused tests:
  - `BatchConfigurationSnapshotProviderDiagnosticsTests`
  - `ProductionMemoryResolverTests`
  - `RecordCardBuildServiceTests`
  - `PhotoImportServiceTests`
- Verified `git diff --check`.
- Built `PhotoMemoiOSV1` for connected `iPhone7` using:
  `/tmp/PhotoMemoV1DeviceBuild_20260706_SubjectFix`.
- The previous app was uninstalled and the new build installed successfully on
  device. Automatic launch was blocked until the development profile is trusted
  on-device.

## 2026-07-03 iPhone7 usable V1 checkpoint

- The current `/Users/rui/Desktop/PhotoMemo` working tree is the accepted latest V1 functional baseline.
- It was built for the connected `iPhone7`, installed, launched, and then accepted by user inspection.
- Installed bundle id:
  - `com.serydoo.PhotoMemo.iOS`
- Device build product:
  - `/tmp/PhotoMemoV1DeviceBuild/Build/Products/Debug-iphoneos/PhotoMemoiOSV1.app`

- Important repository implication:
  - this usable app state is not fully represented by the remote branch yet
  - preserve the current working tree as a checkpoint before any cleanup or repository-line simplification
  - future work should continue in `/Users/rui/Desktop/PhotoMemo`

## 2026-07-03 V1 Render Contract baseline rebuilt

- `~/Desktop/PhotoMemo` is the canonical repository line again; the separate-V1 split decision has been withdrawn.
- V1 Contract convergence has been restored into the canonical repository while preserving the newer desktop V1 runtime/UI files.
- The previous `V1DraftOrchestrationCoordinatorTests` verification gap is resolved:
  - stale expectation was still treating `singleLineTemplateText` as display text
  - test now asserts Template Source and Display Text separately

- Verified:
  - `V1DraftOrchestrationCoordinatorTests` passed
  - Contract baseline group passed:
    - `PreviewCompositionMigrationTests`
    - `V1PreviewSyncCoordinatorTests`
    - `V1DraftOrchestrationCoordinatorTests`
    - `ConfigurationCenterPreviewCompositionHelperTests`
  - `PhotoMemoiOSV1` generic iOS Simulator build passed
  - `git diff --check` passed

- Next review baseline should continue by Contract + Runtime, not by file:
  1. Bootstrap Runtime
  2. Export Runtime
  3. real-device UI
  4. Metadata fidelity

## 2026-07-03 V1 live-code re-audit ready for follow-up

- The V1 codebase was re-reviewed against `~/Desktop/PhotoMemo`, not the archive line.
- Review output is recorded in:
  - [Docs/02_Architecture/V1_Live_Code_Reaudit_2026-07-03.md](/Users/rui/Desktop/PhotoMemo/Docs/02_Architecture/V1_Live_Code_Reaudit_2026-07-03.md)

- Highest-priority V1 follow-up risks are now:
  - subject-library corruption silently downgrades persistence behavior
  - bootstrap/programmatic restoration still drives dirty-state updates
  - preview remains a parallel local implementation instead of one render-backed contract
  - in-app picker staging files do not yet have a cleanup loop
  - focused V1 verification still contains one order-sensitive or flaky test:
    - `V1DraftOrchestrationCoordinatorTests.applyMutationUpdateBridgesStateAndReturnsDirtyPreviewDrafts()`

- Recommended next optimization order:
  1. state-safety fixes
  2. product-cleanup alignment
  3. preview/intake hardening

## 2026-07-02 live-repo revalidation checkpoint

- `~/Desktop/PhotoMemo` remains the only valid working repository.
- The live repository now has two important truths recorded at the same time:
  - the V1 UX fixes were reapplied in the correct repository and compile-verified
  - the archive-line RFC-001 / baseline conclusions are not automatically the live-repo truth

- Current live engineering evidence:
  - preview/configuration uses:
    - `ConfigurationSnapshotBuilder`
    - `ConfigurationSession.currentConfigurationSnapshot`
    - `MemoryExpressionEngine`
    - `MemoryExpressionPreviewResolver`
  - production/export still uses:
    - `BuildPreviewIntent`
    - `PreviewCoordinator`
    - `RecordCardBuildService`
    - `RecordCard(anchor / anchorResult / memorySubjectText)`
    - `CardVariableProvider`
    - `MemoryVariableProvider`

- Most important architectural correction:
  - do **not** assume the archive-line “RFC-001 achieved” conclusion is already true for the current live repository head
  - the live code still appears to have:
    - a newer Memory Engine preview/configuration path
    - an older production/export memory path

- Revalidation completed in this checkpoint:
  - focused V1 presenter/projection tests passed
  - `PhotoMemoiOSV1` generic iOS Simulator build passed

- Best next engineering step:
  - if V2-direction review continues, treat the restored baseline/RFC files as historical reference only
  - produce a fresh live-repo current-state assessment before accepting any production-pipeline migration conclusion

## 2026-07-03 canonical repository line restored

- `~/Desktop/PhotoMemo` is now treated as the only valid PhotoMemo working repository going forward.
- The V1 engineering baseline, RFC-001, RFC-001 implementation plan, and repository line strategy were restored into this repository so future V2 review work no longer depends on the archive copy.
- Active chronicle/handoff/plan documents had stale Codex worktree absolute paths normalized back to `~/Desktop/PhotoMemo`.

## 2026-07-03 V1 UX feedback re-landed in the correct repository

- 这次最重要的结论不是代码，而是仓库定位纠正了：
  - 刚开始安装到手机上的版本来自旧归档目录，而不是当时最新的 V1 主线
  - 后来确认真正持续演进的 V1 在 `~/Desktop/PhotoMemo`
  - 因此这轮 UX 修复已经全部重新落在原始 V1 工作树，而不是旧归档副本

- 本轮完成的 V1 UX 项：
  - 时间锚点标题不再使用硬编码 `途途生日`
  - 切换记忆对象时，V1 accessory / preview-side anchor date 跟随当前对象刷新
  - overview 区只保留当前状态表达
  - `关系类型 / 对象定义 / 行为映射` 已从当前 V1 subject surface 移除
  - `当前锚点名称` 改成 `自定义锚点名称`
  - 表达公式区改成单行选择器，不再重复展示灰色当前值

- 已验证：
  - focused macOS tests 通过
  - `git diff --check` 通过
  - `PhotoMemoiOSV1` 对 `iphone7` 的签名 build 通过
  - 真机重新安装并启动成功

- 当前手机上的版本：
  - 来自 `~/Desktop/PhotoMemo`
  - 构建目录：`/tmp/PhotoMemoV1UXDeviceBuild`
  - bundle id：`com.serydoo.PhotoMemo.iOS`

-- 这意味着下一轮继续测 V1 UX 时，可以直接基于手机上的这版反馈，而不用再担心装的是旧 archive 副本。

## 2026-07-02 V1 subject follow-up extraction completed

- 这一轮继续沿着 `View freeze` 的方向推进，没有去碰 renderer / export / share / photo library 边界。
- 目标很明确：
  - 继续让 `PhotoMemoiOSV1View` 留在 state + composition shell 的位置
  - 把 subject overview 之后那串 follow-up 行为从 root view 里抽出去

- 已处理：
  - [V1SubjectFlowSupport.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1SubjectFlowSupport.swift)
    - 新增 `V1SubjectFlowPatch`
    - 新增 `V1SubjectLibraryPersistenceCoordinator`
    - 新增 `V1SubjectOverviewActionCoordinator`
  - [PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift)
    - overview sheet 的 subject 交互现在统一委托给 `V1SubjectOverviewActionCoordinator`
    - root view 只接收 patch，再做本地状态应用
    - 已移除这些 inline helper：
      - `applyActiveSubjectAnchor(_:)`
      - `selectSubjectForOverview(_:)`
      - `beginAddingSubject()`
      - `deleteCurrentSubject()`
      - `persistSubjectToDefaults(_:)`
      - `persistSubjectLibraryToDefaults(selectedSubjectID:)`
  - [V1SubjectLibrarySupportTests.swift](/Users/rui/Desktop/PhotoMemo/Tests/PhotoMemoTests/ArchitectureTests/V1SubjectLibrarySupportTests.swift)
    - 补了 anchor confirm / add subject / editor flow patch 的测试锁定

- 当前保持住的关键行为：
  - 选中对象
  - 设置当前生效锚点
  - 新增对象
  - 删除对象
  - 从 overview 进入 editor
  都还走原来的 V1 逻辑，没有绕开 subject library 持久化链。

- 这轮特别保留的一点：
  - 新增 subject 时，`shouldSaveSubjectLibrary` 仍然必须强制保持开启
  - 现在这个规则通过 `V1SubjectFlowPatch.shouldEnableSubjectLibraryPersistence` 继续传回 root view

- 已验证：
  - `git diff --check` 通过
  - `V1IOSSubjectOverviewPresenterTests`
  - `V1SubjectLibrarySupportTests`
  - `PhotoMemoiOSV1PhotoIntakeTests`
  - `PhotoMemoiOSV1` generic iOS Simulator build 通过

- 还没做：
  - 这一轮还没有重新手动点一遍 subject sheet -> editor 的真机/模拟器流程
  - 下一刀最值得继续拆的是：
    1. `PhotoMemoiOSV1View` 的 modal / sheet routing
    2. root view 里残留的 bootstrap / restore follow-up
    3. view 内残留的 service ownership

## 2026-07-02 V1 main entry retained + PhotosPicker intake hardening complete

- 这一轮按你的最新判断处理：
  - V1 主界面作为新增窗口/新增入口保留
  - 不把它当成临时页删掉
  - 但主界面的 `处理照片` 不能形成第二套处理链，必须继续复用当前 V1 配置保存和 external intake center

- 本轮反向审查结论：
  - UI polish 本身不是主要风险
  - 主要风险在 App 内 PhotosPicker 快捷入口：
    - 如果继续只用 `loadTransferable(Data.self)`，会把整张图片读入内存
    - 对大 HEIC / 原始格式 / EXIF 保真都不够理想
    - 也和 Share Extension 更稳的 file-representation 思路不一致

- 已处理：
  - [V1PhotoIntakeSupport.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1PhotoIntakeSupport.swift)
    - 新增 `V1PickedPhotoFileRepresentation`
    - PhotosPicker 现在优先通过 `CoreTransferable` 拿系统文件表示
    - 先复制到 PhotoMemo V1 picker 临时目录，再交给 external intake center
    - `Data.self` 读取保留为 fallback
    - 支持类型从 `supportedContentTypes` 中筛选，而不是默认第一个就是可用类型
    - URL helper 标成 `nonisolated`，避免 Swift 6 actor warning
  - [PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift)
    - 继续使用注入的 `ExternalPhotoIntakeCenter`
    - 默认 `.shared` 改到 init body 内解析，去掉现有 actor-isolation warning
  - [PhotoMemoiOSV1PhotoIntakeTests.swift](/Users/rui/Desktop/PhotoMemo/Tests/PhotoMemoTests/BatchTests/PhotoMemoiOSV1PhotoIntakeTests.swift)
    - 新增文件表示复制测试

- 当前行为：
  - 用户从主界面点 `处理照片` 仍然会弹系统图库
  - 处理前仍然先保存/冻结当前 V1 配置
  - 保存失败不会导入也不会提交
  - 成功后仍然提交到现有 external intake center
  - 没有改 Renderer / Export / Share Extension / Photo Library / Layout Engine

- 已验证：
  - `git diff --check` 通过
  - focused intake test 通过：
    - `PhotoMemoiOSV1PhotoIntakeTests`
  - V1 入口组合测试通过：
    - `V1WelcomePresentationTests`
    - `V1IOSHomeQuickActionsTests`
    - `V1IOSSubjectOverviewPresenterTests`
    - `V1SubjectLibrarySupportTests`
    - `PhotoMemoiOSV1PhotoIntakeTests`
    - `ConfigurationMigrationTests`
    - `V1ConfigurationApplyCoordinatorTests`
  - `PhotoMemoiOSV1` generic iOS Simulator build 通过

- 还没做：
  - 这一轮未重新签名安装到 iPhone7
  - 还需要真机实际点一次 `处理照片`，尤其测试大 HEIC / Live Photo 派生图

## 2026-07-02 V1 iOS compile chain recovered + root-view review refreshed

- 这一轮先把一个关键问题查清楚了：
  - `PhotoMemoiOSV1` 之前那批报错，不只是沙箱里的宏噪音
  - 无沙箱 `xcodebuild` 后确认，第一处真实源码阻塞在：
    - [V1PhotoIntakeSupport.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1PhotoIntakeSupport.swift)

- 已处理：
  - [V1PhotoIntakeSupport.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1PhotoIntakeSupport.swift)
    - `V1PhotoIntakeURLResolver`
      - 保持跨平台
      - 继续给 macOS tests 直接使用
    - `V1PhotoIntakeImporter`
      - 收进 iOS-only guard
      - 明确依赖 `Photos / PhotosUI / SwiftUI`
    - 修复 `PhotosPickerItem` 在该文件里的解析失败
    - 顺手去掉 importer loop 外层不可达 `catch`

- 当前验证已经恢复：
  - `git diff --check` 通过
  - 无沙箱 iOS build 通过：
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOSV1 -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PhotoMemoV1IOSBuildEscalated CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO build`
  - 聚焦测试通过：
    - `PhotoMemoiOSV1PhotoIntakeTests`
    - `V1IOSSubjectOverviewPresenterTests`

- 这轮同步更新的结构判断，下一轮建议按这个顺序继续拆：
  1. `PhotoMemoiOSV1View` 的 modal / sheet routing
  2. subject 配置保存后的副作用链
  3. configuration apply request builder

- 额外要记住的结构风险：
  - `V1IOSSubjectConfigurationFlow` 还是直接嵌 `MemorySubjectEditorView`
    - V1 iOS 仍然耦合 Configuration Center editor internals
  - `V1SubjectLibraryRecord` 当前 decode failure 和 truly empty state 区分不够
    - subject library 持久化有 silent drop 风险
  - `legacyBirthdayAnchorTitle` 已经是误导性命名
    - 它更像 memory-subject text，不该继续混用成真实 anchor title

## 2026-07-02 V1 entry visual polish + subject library boundary extraction

- 这一轮继续做的是你刚确认的 V1 入口收口，不碰 renderer / export / share 规则：
  - 欢迎页继续向参考图靠拢
  - 首页顶部继续做成更像正式产品入口的卡片感
  - 记忆对象总览页的对象切换区，做成了更明确的横向卡片轨道
  - 同时顺手继续把 `PhotoMemoiOSV1View` 里的 subject 交互逻辑往 support 层抽

- 已落地文件：
  - [V1WelcomePresentation.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1WelcomePresentation.swift)
    - 欢迎页增加更完整的 hero 卡片
    - 增加 compact 的流程预览区
  - [V1HomePageSurface.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1HomePageSurface.swift)
    - 原顶部纯标题区改成 app entry hero
    - 保持原有快捷入口和行为不变
  - [V1IOSSubjectOverviewSupport.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectOverviewSupport.swift)
    - 顶部对象切换区改成 card rail
    - 单对象时保留一张主卡和右侧新增空间感
    - 删除按钮仍然只有 `subjects.count > 1` 才出现
  - [V1SubjectLibrarySupport.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1SubjectLibrarySupport.swift)
    - 新增 `V1SubjectLibraryMutationCoordinator`
    - 接走：
      - 选择对象
      - 激活锚点
      - 新增对象
      - 删除当前对象
  - [PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift)
    - 上述 subject 相关动作现在只负责：
      - 调 support coordinator
      - 做持久化
      - 刷 preview / dirty state
  - 新增测试：
    - [V1SubjectLibrarySupportTests.swift](/Users/rui/Desktop/PhotoMemo/Tests/PhotoMemoTests/ArchitectureTests/V1SubjectLibrarySupportTests.swift)

- 已验证：
  - `git diff --check` 通过
  - 目标测试通过：
    - `V1WelcomePresentationTests`
    - `V1IOSHomeQuickActionsTests`
    - `V1IOSSubjectOverviewPresenterTests`
    - `V1SubjectLibrarySupportTests`
    - `PhotoMemoiOSV1PhotoIntakeTests`

- 当前阻塞：
  - `PhotoMemoiOSV1` 的 generic iOS Simulator build 目前没有恢复到绿色
  - 最新这次失败点不在欢迎页 / 首页 / subject rail 这轮改动本身，而在旧 iOS 视图链：
    - `PhotoMemoiOSHomeView.swift`
    - `ConfigurationCenteriOSView.swift`
    - `PhotoMemoiOSV1View.swift`
    - `MemorySubjectEditorView.swift`
  - 失败形态主要是：
    - `SwiftUIMacros.StateMacro could not be found`
    - 随后连带出现的 immutable `self` 报错
  - 也就是说：
    - 这轮 V1 入口 polish 的行为测试是稳定的
    - 但如果下一轮目标是“重新推送 iPhone7”，优先级应该先切到 iOS SwiftUI 编译链恢复

- 这轮额外结构判断也已经有结论：
  - 继续该拆的前 3 个点是：
    1. `PhotoMemoiOSV1View` 里的 modal routing / sheet 编排
    2. 配置保存 request / receipt 映射
    3. `bootstrap + dirty-state + preview-sync` 的联动状态
  - 当前最适合下一轮直接做的是前 2 项
  - 第 3 项最好等编译链先恢复，再拆会更稳

## 2026-07-02 subject formula selector enabled by default + real-device reinstall complete

- 这轮是一次很小但很关键的交互收口：
  - 你在真机里看到“当前表述公式”下拉是灰的
  - 代码检查后确认，真正的问题不是 MME，也不是公式库本身
  - 而是 `MemorySubjectEditorView` 里还残留了一层旧的 `isEditingTimeAnchor` 编辑门槛

- 已处理：
  - [MemorySubjectEditorView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Editors/MemorySubjectEditorView.swift)
    - 顶部旧的 `编辑 / 完成` 按钮已去掉
    - 改成被动提示 `可直接编辑`
    - `loadDrafts()` 进入页面时直接把 `isEditingTimeAnchor` 设为 `true`
    - 保存后保持可编辑态，不再回落成“看起来像锁住”的模式

- 这意味着：
  - `记忆对象配置 -> 时间锚点` 下方这几项现在应该默认直接可用：
    - `日期`
    - `锚点类型`
    - `当前表述公式`
    - `锚点说明`

- 真机验证链也已经跑通：
  - 先用未签名包验证功能构建通过
  - 再切回自动签名，完成：
    - signed device build
    - install to `iPhone7`
    - launch on device
  - 所以当前 `iPhone7` 上已经是包含这次修正的新包，不是旧界面残留

- 关键结论：
  - 如果用户现在在 `iPhone7` 上继续看到旧的 `编辑` 顶栏样式或灰色下拉，就不再是“没装到新包”的问题了，而要继续排查更上层容器状态
  - 但本轮实际结果是：新包已成功安装并启动，用户随后确认“可以了”

## 2026-07-02 V1 formula selector surfaced + smart-module preview refresh aligned

- 这一轮把你刚确认的交互真正落到当前 V1 流程里了：
  - 公式选择仍然放在“记忆对象配置 -> 时间锚点”里
  - 但它不再只是一个埋在表单里的 menu，而是被提升成了明确可见的“当前表述公式”
  - 同时，保存后主 V1 页里已经插入到任意 `slotA/B/C/D` 的智能模块，也会立刻跟着新公式刷新预览

- 这轮核心改动：
  - [MemorySubjectEditorView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Editors/MemorySubjectEditorView.swift)
    - 时间锚点卡片里新增了当前公式摘要
    - `锚点表述方式` 改成更明确的 `当前表述公式`
    - 保留公式预览，但现在和公式选择放在同一个更清晰的配置块里
  - [V1TimeAnchorEntryPresenter.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1TimeAnchorEntryPresenter.swift)
    - 新增：
      - `currentFormulaTitle`
      - `currentFormulaValue`
    - 让主配置页时间锚点模块可以直接显示“当前表述公式”
  - [V1AccessoryEntrySection.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1AccessoryEntrySection.swift)
    - 时间锚点展开区现在会先显示当前公式风格，再显示该锚点对应的完整公式预览
  - [PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift)
    - subject 配置保存时，除了原来的持久化，还会：
      - 更新当前 active anchor date 到 V1 preview context
      - 主动 `refreshDynamicPreview()`
      - 把页面状态标成 `有未保存修改`
    - 这一步就是为了让已经插入到 A/B/C/D 任意区域的智能模块，一起按新公式重组，而不是只刷新默认 D 区
  - [ConfigurationSnapshotBuilder.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/ConfigurationSnapshotBuilder.swift)
    - runtime snapshot 现在不再直接吃 legacy nil anchor metadata
    - 会统一走：
      - `resolvedAnchorType`
      - `resolvedExpressionStyle`
    - 这样旧 mock / 旧 subject 在 preview runtime 里也会优先走 MME 公式，而不是回退到历史 block 文案

- 这一轮顺手修掉的一个重要历史兼容点：
  - 之前有些默认 mock anchor 没有 `anchorType`
  - 所以 preview runtime 会回退成老的：
    - `昵称 今天 年龄 啦`
  - 现在 snapshot runtime 会自动归一化成生日默认规则，所以 slot D 默认预览重新回到了：
    - `途途今天11个月28天啦！`

- 新增 / 更新测试：
  - [V1TimeAnchorEntryPresenterTests.swift](/Users/rui/Desktop/PhotoMemo/Tests/PhotoMemoTests/ArchitectureTests/V1TimeAnchorEntryPresenterTests.swift)
    - 现在锁住：
      - 当前公式标题
      - 当前公式值
      - relationship warm 等非默认风格的显示
  - [PreviewCompositionMigrationTests.swift](/Users/rui/Desktop/PhotoMemo/Tests/PhotoMemoTests/ArchitectureTests/PreviewCompositionMigrationTests.swift)
    - 新增断言：
      - 智能模块插入 `slotA` 时，也必须跟随当前公式风格输出
    - 同时旧 preview migration 基线已经重新对齐到新的 runtime 真相

- 本轮验证：
  - 通过：
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoTests -destination 'platform=macOS' -only-testing:PhotoMemoTests/V1TimeAnchorEntryPresenterTests -only-testing:PhotoMemoTests/PreviewCompositionMigrationTests CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO test`
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOSV1 -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO build`

- 下一轮如果继续：
  1. 可以直接上真机看这套“当前表述公式”信息块的视觉密度和层级是否还需要再收
  2. 如果你要继续扩每类锚点的公式库，当前这套 UI / presenter / preview refresh 链已经能承接
  3. 如果后面要把“公式选择后即时生效”进一步做到不经保存也能映射回主页，那就要明确是否打破当前 subject draft-save 的隔离边界；这轮还没有动这个边界

## 2026-07-02 V1.0 Anchor Formula Library multi-style expansion

- 这一轮不是再加一个 UI 下拉而已，而是把 `expressionStyle` 真正扩成了 V1.0 锚点公式库，并继续挂在同一条 MME / 预览 / 持久化链上。

- 本轮关键判断：
  - 之前的 `expressionStyle` 虽然已经进入真实处理链，但每个锚点类型还只有 1 套公式族
  - 现在要冻结的是：
    - `anchorType` 决定语义类别
    - `expressionStyle` 决定同类别下的表达风格
    - 每个 style 自带一套 `Before + After`
  - 所以这次的核心不是 view，而是：
    - [MemoryAnchorExpressionStyle.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Models/MemoryAnchorExpressionStyle.swift)
    - [MemoryAnchorExpressionResolver.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/MemoryEngine/MemoryAnchorExpressionResolver.swift)

- 已落地：
  - `birthday`
    - natural / ceremonial / growth / warm / minimal
  - `marriage`
    - natural / ceremonial / warm / minimal / memory
  - `relationship`
    - natural / ceremonial / memory / warm / minimal
  - `exam`
    - natural / ceremonial / motivational / minimal / record
  - `custom`
    - natural / ceremonial / memory / warm / minimal

- 重要实现细节：
  - [MemoryAnchorExpressionStyle.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Models/MemoryAnchorExpressionStyle.swift)
    - 旧 raw value 兼容已保留：
      - `birthdayAgeToday`
      - `relationshipAnniversary`
      - `marriageAnniversary`
      - `examCountdown`
    - 已保存旧配置不会因为这次扩枚举直接解码失败
  - [MemoryAnchorExpressionResolver.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/MemoryEngine/MemoryAnchorExpressionResolver.swift)
    - 现在按 style 分流 before / after 全句输出
    - `birthday natural before` 已按最新冻结口径改成：
      - `距离{主体}出生还有{倒计时天数}`
  - [MemorySubjectEditorView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Editors/MemorySubjectEditorView.swift)
    - 锚点类型切换时，会立刻把 `expressionStyle` 重置到该类型的默认合法 style
    - 避免出现“生日风格挂在结婚锚点上”的脏状态

- 这一轮之后的真实效果：
  - `MemoryExpressionEngine`
  - `MemoryExpressionPreviewResolver`
  - `V1PreviewCompositionEngine`
  - `V1TimeAnchorEntryPresenter`
  - legacy `Anchor / BatchConfigurationSnapshot / RecordCard`
    这几条链都已经开始理解“同类锚点下多风格公式”

- 新增 / 更新测试：
  - [MemoryExpressionEngineTests.swift](/Users/rui/Desktop/PhotoMemo/Tests/PhotoMemoTests/ArchitectureTests/MemoryExpressionEngineTests.swift)
    - 断言：
      - 每类 5 个可选 style
      - 默认 style
      - 多类风格文案 before / after 输出
      - 生日前默认文案已更新为“距离主体出生还有…”
  - [V1TimeAnchorEntryPresenterTests.swift](/Users/rui/Desktop/PhotoMemo/Tests/PhotoMemoTests/ArchitectureTests/V1TimeAnchorEntryPresenterTests.swift)
    - 断言：
      - 默认生日公式预览
      - relationship warm 风格预览
  - [BatchConfigurationSnapshotProviderDiagnosticsTests.swift](/Users/rui/Desktop/PhotoMemo/Tests/PhotoMemoTests/BatchTests/BatchConfigurationSnapshotProviderDiagnosticsTests.swift)
  - [RecordCardBuildServiceTests.swift](/Users/rui/Desktop/PhotoMemo/Tests/PhotoMemoTests/ExportTests/RecordCardBuildServiceTests.swift)
    - legacy payload 解码后重新编码时，现在会输出新 raw value，例如 `birthdayNatural`

- 本轮验证：
  - 通过：
    - `git diff --check`
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoTests -destination 'platform=macOS' -only-testing:PhotoMemoTests/MemoryExpressionEngineTests -only-testing:PhotoMemoTests/V1TimeAnchorEntryPresenterTests -only-testing:PhotoMemoTests/ConfigurationMigrationTests -only-testing:PhotoMemoTests/BatchConfigurationSnapshotProviderDiagnosticsTests -only-testing:PhotoMemoTests/RecordCardBuildServiceTests CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO test`
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOSV1 -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO build`

- 当前仍可继续的下一步：
  1. 继续把 `relationship / exam / custom` 的最终文案再打磨一轮
  2. 再补更全的“25 套 style 全覆盖”测试，而不是当前的代表性 coverage
  3. 如果要做用户可见说明，再单独决定是否在 share / output 页显式展示“当前表述方式”

## 2026-07-02 expression-style unified into batch/share/default-processing

- 这轮把上一条“先保留 UI / snapshot 元数据，暂不碰 batch/share”的边界正式往前推了一步：
  - `expressionStyle` 不再只停留在 subject 编辑 / V1 保存 / IA-003 snapshot
  - 旧的 `Anchor -> BatchConfigurationSnapshot -> RecordCard -> template-variable` 处理链现在也开始真正消费它

- 本轮关键判断：
  - 真正的断点不在 `MemorySubject` 持久化
  - 而在旧配置链路：
    - legacy `Anchor` 没有稳定保留 `expressionStyle`
    - `BatchConfigurationSnapshot` 没冻结主体文本
    - 旧导出文案仍可能走另一套 memory-summary 句式
  - 所以如果不把这些边界接上，就会出现：
    - 配置页显示的是一套公式
    - 预览 MME 看的是一套公式
    - 后台 / 默认说明 / 老输出链又是另一套

- 已落地：
  - 新增：
    - [MemoryAnchorExpressionStyle.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Models/MemoryAnchorExpressionStyle.swift)
      - expression-style 模型已提升到 shared runtime-safe 层
    - [MemorySubject+ExpressionStyle.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Models/MemorySubject+ExpressionStyle.swift)
      - 集中做 subject time-anchor 的 style 归一化
    - [MemoryAnchorExpressionResolver.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/MemoryEngine/MemoryAnchorExpressionResolver.swift)
    - [RelativeTimeMemoryCalculator.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/MemoryEngine/RelativeTimeMemoryCalculator.swift)
    - [ConfiguredAnchorExpressionProvider.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/MemoryEngine/ConfiguredAnchorExpressionProvider.swift)
      - 这三层把“时间怎么算”和“怎么算完以后怎么说”正式拆开
  - 更新：
    - [Anchor.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Models/Anchor.swift)
    - [BatchProcessing.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Models/BatchProcessing.swift)
    - [SettingsService.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Services/SettingsService.swift)
    - [BatchConfigurationSnapshotProvider.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/App/BatchConfigurationSnapshotProvider.swift)
      - legacy anchor 现在会保留 `expressionStyle`
      - batch/share snapshot 现在会冻结 `memorySubjectText`
    - [ConfigurationRepository.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Repositories/ConfigurationRepository.swift)
    - [ConfigurationCoordinator.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Coordinators/ConfigurationCoordinator.swift)
    - [MemorySubjectAdapter.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/MemoryEngine/MemorySubjectAdapter.swift)
    - [PersonalProfileStore.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Services/PersonalProfileStore.swift)
      - subject 编辑 -> legacy anchor 同步链现在会把 `anchorType + expressionStyle` 一起保存
      - legacy 读回 subject 时也不再丢 style
    - [MemoryAnchorTypeRegistry.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/MemoryEngine/MemoryAnchorTypeRegistry.swift)
      - 当前各 anchor type 已统一走同一套 relative-time calculator + configured expression provider
    - [RecordCard.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Models/RecordCard.swift)
    - [RecordCardBuildService.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Services/RecordCardBuildService.swift)
    - [MemoryContext.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/MemoryEngine/MemoryContext.swift)
    - [MemoryVariableProvider.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/MemoryEngine/MemoryVariableProvider.swift)
    - [CardVariableProvider.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Models/CardVariableProvider.swift)
      - 旧 memory-summary 输出现在会读取冻结下来的主体文本
      - 且改为复用 `MemoryAnchorExpressionResolver`
      - 这样 preview MME 与旧导出模板变量链终于开始讲同一句话

- 当前默认公式族已经冻结到第一版：
  - `birthday`
    - 锚点后：`主体今天年龄结果啦！`
    - 锚点前：`距离锚点还有天数`
  - `relationship`
    - 锚点后：`主体和锚点已经时间结果`
    - 锚点前：`主体距离锚点还有天数`
  - `marriage`
    - 锚点后：`主体和锚点已经时间结果`
    - 锚点前：`主体距离锚点还有天数`
  - `exam`
    - 锚点前：`距离锚点还有天数`
    - 锚点后：`锚点已经时间结果`
  - `custom`
    - 锚点后：`主体与锚点的记忆已有时间结果`
    - 锚点前：`主体距离锚点还有天数`

- 验证：
  - 通过：
    - `git diff --check`
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoTests -destination 'platform=macOS' -only-testing:PhotoMemoTests/MemoryExpressionEngineTests -only-testing:PhotoMemoTests/V1TimeAnchorEntryPresenterTests -only-testing:PhotoMemoTests/ConfigurationMigrationTests -only-testing:PhotoMemoTests/BatchConfigurationSnapshotProviderDiagnosticsTests -only-testing:PhotoMemoTests/SharedBatchConfigurationSnapshotServiceTests -only-testing:PhotoMemoTests/RecordCardBuildServiceTests -only-testing:PhotoMemoTests/MemoryEngineTests CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO test`
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOSV1 -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO build`

- 这一轮之后的真实边界：
  - `expressionStyle` 已经进入：
    - subject 持久化
    - V1 restore/save
    - IA-003 snapshot
    - legacy anchor 持久化
    - batch/share snapshot 冻结
    - 默认图片说明生成
    - 旧模板变量 memory summary 输出
  - 还没做的是：
    - share 界面自己的用户文案是否进一步显式提示“当前表述方式”
    - 更多公式族的持续扩充
  - 但“配置一套、后台另一套”的核心分叉，已经先被收掉了

## 2026-07-02 V1 editor fade removal + time-anchor type/style pass

- 这一轮把用户最新两条反馈一起落地了：
  - V1 配置页 `slot A/B/C/D` 编辑区偶发发灰 / 淡入淡出
  - 记忆对象时间锚点编辑区需要升级为：
    - `当前生效时间锚点`
    - `锚点类型`
    - `锚点表述方式`
    - `锚点说明`

- 本轮关键判断：
  - 发灰不是 renderer 问题，而是 page-level surface 自己在做透明度编舞
  - 根因在：
    - [V1EditorPageSurface.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1EditorPageSurface.swift)
      - scroll 内 preview 一份
      - pinned overlay 再一份
      - 两份都跟随 `previewPinProgress` 半透明交叉
      - editor 自身还吃 `editorRevealProgress`
  - 这会让白底和文字在某些滚动态里看起来像“发灰”

- 已落地：
  - 新增：
    - [MemoryAnchorExpressionStyle.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Models/MemoryAnchorExpressionStyle.swift)
      - 先冻结第一层锚点表述方式模型
      - 目前每个锚点类型先只挂一条默认表述方式
  - 更新：
    - [MemorySubject.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Models/MemorySubject.swift)
      - `MemorySubject.TimeAnchor` 增加可持久化 `expressionStyle`
    - [MemoryAnchor.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/MemoryEngine/MemoryAnchor.swift)
    - [ConfigurationSnapshotBuilder.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/ConfigurationSnapshotBuilder.swift)
      - IA-003 snapshot 不再立刻丢掉 expression-style 元数据
    - [MemorySubjectEditorView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Editors/MemorySubjectEditorView.swift)
      - 当前生效锚点卡片现在负责：
        - 选择
        - inline 命名
      - 旧的独立 `名称` 明细行已经去掉
      - 新增：
        - `锚点类型`
        - `锚点表述方式`
        - `当前公式预览`
      - legacy anchor 进入编辑器时会自动补齐默认 type/style
    - [V1TimeAnchorEntryPresenter.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1TimeAnchorEntryPresenter.swift)
    - [V1AccessoryEntrySection.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1AccessoryEntrySection.swift)
      - 折叠态保持：
        - `主体 · 当前生效锚点`
      - 展开态不再展示实时 smart-time 结果
      - 改为展示当前锚点对应的公式预览
    - [V1EditorPageSurface.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1EditorPageSurface.swift)
      - 去掉 editor / preview 的透明度 choreography
      - 改成 pinned / unpinned 的不透明切换
      - 删掉整个 scroll surface 的 tap-dismiss，避免和输入焦点互相打架

- 新增 / 更新测试：
  - [V1TimeAnchorEntryPresenterTests.swift](/Users/rui/Desktop/PhotoMemo/Tests/PhotoMemoTests/ArchitectureTests/V1TimeAnchorEntryPresenterTests.swift)
    - 现在断言 compact summary 与公式预览
  - [ConfigurationMigrationTests.swift](/Users/rui/Desktop/PhotoMemo/Tests/PhotoMemoTests/ArchitectureTests/ConfigurationMigrationTests.swift)
    - 增加 expression-style 在 V1 保存/引导恢复链路中的回归断言

- 本轮验证：
  - 通过：
    - `git diff --check`
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoTests -destination 'platform=macOS' -only-testing:PhotoMemoTests/V1TimeAnchorEntryPresenterTests -only-testing:PhotoMemoTests/ConfigurationMigrationTests CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO test`
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOSV1 -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO build`

- 当前仍需记住的边界：
  - 这轮是 UI / V1 入口层修正
  - 后续 expression-style 真正进入 batch/share/default-processing 的落地，见上方同日后续记录

## 2026-07-01 Architecture Freeze V1 compile recovery + V1 / ConfigurationCenter support-view extraction

- 这一轮先处理“验证基础设施”问题，而不是盲拆：
  - 先用放行后的真实 `xcodebuild` 区分沙箱噪音和真实编译错误
  - 真实剩余报错只剩一个：
    - [MemoryBlockInspectorView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Inspector/MemoryBlockInspectorView.swift:124)
    - `escaping closure captures non-escaping parameter 'content'`
  - 已修复：
    - `collapsibleSection` 的 `content` 改为 `@escaping`
  - 修后验证恢复为绿：
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO build`

- 在构建恢复后，继续只做低风险 support-view extraction：
  - 已新增：
    - [V1PreviewSection.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1PreviewSection.swift)
    - [V1PresetControls.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1PresetControls.swift)
    - [ConfigurationCenterPresetMenu.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenterPresetMenu.swift)
    - [ConfigurationCenterToolbarContent.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenterToolbarContent.swift)
  - 已更新：
    - [PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift)
      - `previewSection` 已退到 `V1PreviewSection`
      - `presetPicker` / `presetOperationsMenu` 已退到 `V1PresetControls`
      - 父层继续保留：
        - `selectedPresetBinding`
        - rename / reset / bootstrap / tab routing / preview data assembly
    - [ConfigurationCenteriOSView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift)
      - `profilePresetMenu` 已退到 `ConfigurationCenterPresetMenu`
      - `configurationToolbar` 已退到 `ConfigurationCenterToolbarContent`
      - 父层继续保留：
        - `session`
        - `selectedPanel`
        - all selection / apply / reset / keyboard dismissal routing

- 这一轮之后的大文件体量：
  - [PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift)
    - `1836`
  - [MemoryBlockInspectorView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Inspector/MemoryBlockInspectorView.swift)
    - `1015`
  - [ConfigurationCenteriOSView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift)
    - `900`
  - [InteractiveMemoryCard.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/MemoryCard/InteractiveMemoryCard.swift)
    - `799`

- 如果下一轮继续，推荐顺序：
  1. [PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift)
     - 下一刀优先评估 `editorCluster`
     - 但必须保持 parent 持有 draft / focus / module panel / mutation closures
  2. [InteractiveMemoryCard.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/MemoryCard/InteractiveMemoryCard.swift)
     - 只收纯展示孤岛
  3. [MemoryBlockInspectorView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Inspector/MemoryBlockInspectorView.swift)
     - 仅当还能找到明显孤立的 pure view 再继续
  4. [ConfigurationCenteriOSView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift)
     - 当前已经接近 freeze-safe stop point，不建议继续往 selection/binding seam 深挖

- 本轮验证结果：
  - 通过：
    - `git diff --check`
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO build`

## 2026-07-01 ConfigurationCenter detail-panel shell extraction

- 这一小轮继续严格守在 `Architecture Freeze V1`：
  - 只收 `ConfigurationCenteriOSView.swift` 的纯 detail-panel 装配壳
  - 不动 `regionDraftStore`
  - 不动 region binding adapters / mutation seam / `applySelectionUpdate` / session-owned state
  - 不改 renderer / export / metadata / share

- 已新增：
  - [ConfigurationCenterDetailPanelSection.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenterDetailPanelSection.swift)
    - 承接 `.memoryModule` / `.output` / `.configurationGuide` 三个 detail panel 的共同外壳装配
    - child 只接收：
      - title
      - systemImage
      - 已由父层算好的 model / binding / guide items

- 已更新：
  - [ConfigurationCenteriOSView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift)
    - `detailContent` 中上述 3 个分支已委托给新 support view
    - 父层继续保留 panel presentation 解析、session binding、model projection 与全部 mutation/selection seam

- 本轮验证：
  - 通过：
    - `git diff --check -- Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenterDetailPanelSection.swift`
  - 未通过，但与本次改动无直接关系：
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
    - 当前阻塞在 `MemoryBlockInspectorView.swift:124`
    - 报错：non-escaping `content` 被传给需要 `@escaping` 的位置

## 2026-07-01 ConfigurationCenter region-composer host + BackgroundStatus dead-helper cleanup

- 这一小轮继续严格守在 `Architecture Freeze V1`：
  - 本地主线继续收 `ConfigurationCenteriOSView`
  - 关键路径只做 `IOSRegionComposer` 宿主装配抽离
  - 并行 worker 清掉 `PhotoMemoiOSBackgroundStatusSheet` 里已经断线的旧展示块
  - 不改 renderer / export / metadata / share / queue semantics

- 已新增：
  - [ConfigurationCenterRegionComposerSection.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenterRegionComposerSection.swift)
    - 承接 `IOSRegionComposer` 的宿主装配
    - 只接收：
      - region
      - configuration options
      - parent-owned bindings
      - save / delete callbacks

- 已更新：
  - [ConfigurationCenteriOSView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift)
    - `activeRegionEditorContent` 的 `regionComposer` 分支已退到独立 support view
    - 父层继续保留 region binding adapter、draft store、preview helper、mutation seam
    - 顺手移除了已断线的本地 helper：
      - `refreshRegionPreview`
      - `selectedMemoryPresetBinding`
      - `moduleValue`
  - [PhotoMemoiOSBackgroundStatusSheet.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSBackgroundStatusSheet.swift)
    - 已清理未挂载的旧展示 helper：
      - `statusCounts`
      - `currentConfigurationCard`
      - `intakeSummaryCard`
      - `currentJobTimelineCard`
      - `recentFailuresCard`
      - `infoRow`
      - `countCard`
    - 以及只服务它们的辅助代码：
      - `intakeExplanation`
      - `resolvedTemplateTitle`
      - `resolvedAnchorTitle`
      - `resolvedDestinationTitle`
      - `jobTimelineRecords`
      - `taskPriority`
      - `JobTimelineRecord`

- 这轮最直接的结果：
  - [ConfigurationCenteriOSView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift)
    - `1021` 行
    - → `971` 行
  - [PhotoMemoiOSBackgroundStatusSheet.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSBackgroundStatusSheet.swift)
    - `890` 行
    - → `314` 行

- 本轮验证：
  - 通过：
    - `git -C /Users/rui/Desktop/PhotoMemo diff --check`
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -target PhotoMemo -configuration Debug CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO build`

- 这一轮之后，最值得继续的顺序：
  1. [PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift)
     - 继续 page-level surface / support-view shrink
  2. [MemoryBlockInspectorView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Inspector/MemoryBlockInspectorView.swift)
     - 再确认是否还有纯展示孤岛
  3. [ConfigurationCenteriOSView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift)
     - 继续只做 parent-owned seam 不变前提下的 support extraction

## 2026-07-01 PhotoMemoiOSV1 settings-page + ConfigurationCenter support extraction

- 这一轮继续沿着 `Architecture Freeze V1` 做同步收敛：
  - 本地先收 `PhotoMemoiOSV1View.settingsPage`
  - 并行 agent 盘点 `ConfigurationCenteriOSView` 和剩余低风险清理点
  - 再本地落 `ConfigurationCenteriOSView` 的最安全 support sections

- 已新增：
  - [V1SettingsPageSurface.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1SettingsPageSurface.swift)
    - 承接：
      - 设置页外壳
      - 处理进度卡片
      - progress summary / pipeline / queue lines
  - [ConfigurationCenterInsertableModuleLibrarySection.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenterInsertableModuleLibrarySection.swift)
    - 承接固定可插入模块库
  - [ConfigurationCenterActiveRegionEditorSection.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenterActiveRegionEditorSection.swift)
    - 承接 active-region editor header + outer shell

- 已更新：
  - [PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift)
    - `settingsPage` 已退到独立 surface
    - 父层只保留诊断 header/data projection 和 refresh / clear action
  - [ConfigurationCenteriOSView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift)
    - `fixedInsertableModuleLibrary` 已退到独立 section
    - `activeRegionEditor` 外壳已退到独立 section
    - 父层继续保留 region mutation seam、adapter、draft store、insert action

- 这轮最直接的结果：
  - [PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift)
    - `2370` 行
    - → `2095` 行
  - [ConfigurationCenteriOSView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift)
    - `1106` 行
    - → `1021` 行

- 并行 agent 结论：
  - `ConfigurationCenteriOSView`
    - 下一刀最值的是 `IOSRegionComposer` host assembly
    - 但必须继续让 parent 先组装 bindings / mutation closures，child 只吃值与动作
  - `PhotoMemoiOSBackgroundStatusSheet`
    - 比 `MemoryBlockInspectorView` 更值得做下一次低风险 cleanup
    - 里面像是还留着一组未挂载的旧展示块

- 本轮验证：
  - 通过：
    - `git -C /Users/rui/Desktop/PhotoMemo diff --check`
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -target PhotoMemo -configuration Debug CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO build`

## 2026-07-01 PhotoMemoiOSV1 home-page surface extraction

- 这一小轮继续只做 `Architecture Freeze V1` 范围内的 view shrink：
  - 不改 renderer / export / metadata / share semantics
  - 不碰 save/bootstrap/application seam
  - 只把 `PhotoMemoiOSV1View` 首页展示拼装退成独立 surface

- 已新增：
  - [V1HomePageSurface.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1HomePageSurface.swift)
    - 现在承接：
      - 当前记忆对象卡片
      - 当前配置卡片
      - 快捷操作
      - 最近处理
      - 默认输出摘要

- 已更新：
  - [PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift)
    - `homePage` 已经退到独立 surface
    - 父层只保留：
      - preset picker / operations menu
      - focus / binding
      - 保存默认配置动作
      - tab 跳转
      - offset reader
      - projection / message 组装

- 这轮最直接的结果：
  - [PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift)
    - `2556` 行
    - → `2370` 行

- 本轮验证：
  - 通过：
    - `git -C /Users/rui/Desktop/PhotoMemo diff --check`
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -target PhotoMemo -configuration Debug CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO build`

## 2026-07-01 InteractiveMemoryCard configuration-dock extraction

- 这一小轮继续只做 `Architecture Freeze V1` 范围内的 support-view extraction：
  - 不改 renderer / export / metadata / share semantics
  - 不碰 application seam
  - 只把 `InteractiveMemoryCard` 下方 dock 区退成独立 support view

- 已新增：
  - [InteractiveMemoryCardConfigurationComponentDock.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/MemoryCard/InteractiveMemoryCardConfigurationComponentDock.swift)
    - 现在承接：
      - 智能模块写入区
      - 可插入模块库
      - 当前配置展示
      - 输出 / 存储设置
      - 配置说明卡片

- 已更新：
  - [InteractiveMemoryCard.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/MemoryCard/InteractiveMemoryCard.swift)
    - `configurationComponentDock` 已经退到独立 support view
    - 父层只保留 expansion state、binding、resolved text、module insert action
    - `CenterInsertableModule` 已经从文件私有调整为可跨文件复用

- 这轮最直接的结果：
  - [InteractiveMemoryCard.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/MemoryCard/InteractiveMemoryCard.swift)
    - `1562` 行
    - → `1313` 行
    - → `1195` 行
    - → `867` 行

- 本轮验证：
  - 通过：
    - `git -C /Users/rui/Desktop/PhotoMemo diff --check`
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -target PhotoMemo -configuration Debug CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO build`

## 2026-07-01 InteractiveMemoryCard configuration-context extraction

- 这一小轮继续沿着 `Architecture Freeze V1` 收：
  - 不改 renderer / export / metadata / share semantics
  - 不碰 application seam
  - 只把 `InteractiveMemoryCard` 顶部配置区退成独立 support view

- 已新增：
  - [InteractiveMemoryCardConfigurationContext.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/MemoryCard/InteractiveMemoryCardConfigurationContext.swift)
    - 现在承接：
      - 总体配置 picker
      - 时间锚点状态
      - 预设重命名输入
      - 重置 / 保存并生效按钮

- 已更新：
  - [InteractiveMemoryCard.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/MemoryCard/InteractiveMemoryCard.swift)
    - 顶部 `configurationContext` 已经退到独立 support view
    - 父层只保留 preset binding、rename toggle state、apply/reset action routing

- 这轮最直接的结果：
  - [InteractiveMemoryCard.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/MemoryCard/InteractiveMemoryCard.swift)
    - `1562` 行
    - → `1313` 行
    - → `1195` 行

- 本轮验证：
  - 通过：
    - `git -C /Users/rui/Desktop/PhotoMemo diff --check`
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -target PhotoMemo -configuration Debug CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO build`

## 2026-07-01 MemoryBlockInspector custom-fields extraction + dead-helper cleanup

- 这一小轮继续严格守在 `Architecture Freeze V1`：
  - 不改 renderer / export / metadata / share semantics
  - 不碰 save/bootstrap/application seam
  - 只处理 `MemoryBlockInspectorView` 内已经成熟的纯展示抽离，以及已经断线的旧 helper 清理

- 已新增：
  - [MemoryBlockInspectorCustomFieldsSection.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Inspector/MemoryBlockInspectorCustomFieldsSection.swift)
    - 现在承接：
      - 自定义内容卡片列表
      - 拖拽/重排
      - 组合预览 token chip
      - 删除动作的展示层

- 已更新：
  - [MemoryBlockInspectorView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Inspector/MemoryBlockInspectorView.swift)
    - `customFieldsEditor` 已经退到独立 support view
    - 父层只保留自定义字段 state、binding、mutation routing
    - 顺手移除了当前完全未接进 `body` 的旧 helper：
      - `moduleInsertionLibrary`
      - `resolvedResult`
      - `behaviorSummary`
      - 以及相关未使用 enum cases / chip helpers

- 这轮最直接的结果：
  - [MemoryBlockInspectorView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Inspector/MemoryBlockInspectorView.swift)
    - `1589` 行
    - → `1520` 行
    - → `1053` 行

- 当前并行 agent 盘点出的下一刀建议：
  1. `InteractiveMemoryCard`
  2. `PhotoMemoiOSV1View`
     - `homePage`
     - `settingsPage`
  3. `ConfigurationCenteriOSView`
     - active-region editor 周边 support sections

## 2026-07-01 Multi-agent view-surface extraction pass

- 这一轮明确按“多 agent + 单一边界”来推：
  - 主线仍然是 `Architecture Freeze V1`
  - 不动 renderer / export / metadata / share semantics
  - 不碰 save/bootstrap/application seam
  - 只做纯 view / support-view extraction

- 本轮新增：
  - [MemoryBlockInspectorConfigurationPickerSection.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Inspector/MemoryBlockInspectorConfigurationPickerSection.swift)
  - [MemoryBlockInspectorCustomFieldsSection.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Inspector/MemoryBlockInspectorCustomFieldsSection.swift)
  - [MemoryBlockInspectorSystemModulesSection.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Inspector/MemoryBlockInspectorSystemModulesSection.swift)
  - [InteractiveMemoryCardCompactPreview.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/MemoryCard/InteractiveMemoryCardCompactPreview.swift)
  - [ConfigurationCenterDetailSupportPanels.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenterDetailSupportPanels.swift)
  - [V1OutputPageSurface.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1OutputPageSurface.swift)
  - [PhotoMemoiOSBackgroundStatusSheetSupportViews.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSBackgroundStatusSheetSupportViews.swift)

- 本轮更新：
  - [MemoryBlockInspectorView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Inspector/MemoryBlockInspectorView.swift)
    - 抽出了 configuration picker
    - 抽出了 custom fields section
    - 抽出了 system modules section
  - [InteractiveMemoryCard.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/MemoryCard/InteractiveMemoryCard.swift)
    - 抽出了 compact preview surface
    - 父层仍然保留 `session.select(...)` / `session.hoverRegion(...)`
  - [ConfigurationCenteriOSView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift)
    - 抽出了 detail-side 的 memory-write / output / guide panels
  - [PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift)
    - 抽出了 output-tab surface
  - [PhotoMemoiOSBackgroundStatusSheet.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSBackgroundStatusSheet.swift)
    - 抽出了 hero / pipeline / focus / latest-failure 显示块

- 这一轮最直观的结果：
  - [MemoryBlockInspectorView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Inspector/MemoryBlockInspectorView.swift)
    - `1589` 行
    - → `1053` 行
  - [InteractiveMemoryCard.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/MemoryCard/InteractiveMemoryCard.swift)
    - `1562` 行
    - → `1313` 行
  - [ConfigurationCenteriOSView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift)
    - `1197` 行
    - → `1106` 行
  - [PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift)
    - `2699` 行
    - → `2556` 行
  - [PhotoMemoiOSBackgroundStatusSheet.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSBackgroundStatusSheet.swift)
    - `1180` 行
    - → `890` 行

- 这轮中间有一个需要记住的现象：
  - 并行 agent 在同一时间段内落新 support files 时，`PhotoMemoiOSV1` scheme build 一度报“找不到新 type”
  - 不是代码边界错误，而是构建开始时文件列表还没完全包含刚落地的文件
  - 最终用更稳定的总体验证口径完成确认：
    - `git -C /Users/rui/Desktop/PhotoMemo diff --check`
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -target PhotoMemo -configuration Debug CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO build`
    - 最终 `BUILD SUCCEEDED`

- 当前剩余大头：
  - [PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift) `2370`
  - [ConfigurationCenteriOSView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift) `1106`
  - [MemoryBlockInspectorView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Inspector/MemoryBlockInspectorView.swift) `1053`
  - [PhotoMemoiOSBackgroundStatusSheet.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSBackgroundStatusSheet.swift) `890`
  - [InteractiveMemoryCard.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/MemoryCard/InteractiveMemoryCard.swift) `867`

- 下一刀建议严格按这个顺序继续：
  1. `PhotoMemoiOSV1View`
     - `settingsPage`
     - 继续 page-level surface extraction
  2. `ConfigurationCenteriOSView`
     - active-region editor 周边 support sections
  3. `MemoryBlockInspectorView`
     - 当前已不再是第一优先，但如果继续收，可以再检查是否还有可见的纯展示孤岛
  4. `PhotoMemoiOSBackgroundStatusSheet`
     - 现在已经不再是第一优先，可以后移

## 2026-07-01 ConfigurationCenter top preview extraction

- 这一小轮继续严格守住 `Architecture Freeze V1`：
  - 不改 renderer
  - 不改 export / metadata / share-extension 语义
  - 不碰 `ConfigurationCenteriOSView` 里真正的 binding / mutation 胶水
  - 只继续做纯 view support extraction

- 已新增：
  - [ConfigurationCenterTopPreviewSection.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenterTopPreviewSection.swift)
    - 现在承接：
      - 顶部 profile summary panel
      - compact preview 外层块
      - region strip
      - region strip button

- 已更新：
  - [ConfigurationCenteriOSView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift)
    - `topConfigurationPreview` 现在只保留父层 action/binding 路由
    - preset apply/reset、rename toggle、region selection 仍然走原来的父层 closure 和 `ConfigurationCenterSelectionCoordinator`

- 这轮最直接的结果：
  - [ConfigurationCenteriOSView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift)
    - `1419` 行
    - → `1197` 行
  - 顶部整块展示层已经从父文件里退出来，父文件更接近：
    - page shell
    - sidebar/detail assembly
    - binding / mutation seam

- 本轮验证：
  - 通过：
    - `git -C /Users/rui/Desktop/PhotoMemo diff --check`
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOSV1 -configuration Debug -destination 'generic/platform=iOS' -derivedDataPath /tmp/PhotoMemoiOSV1DerivedData-config-top-preview-pass CODE_SIGNING_ALLOWED=NO -quiet build`

- 并行 agent 盘点后的剩余 view 大头：
  - [PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift) `2699`
  - [MemoryBlockInspectorView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Inspector/MemoryBlockInspectorView.swift) `1589`
  - [InteractiveMemoryCard.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/MemoryCard/InteractiveMemoryCard.swift) `1562`
  - [ConfigurationCenteriOSView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift) `1197`
  - [PhotoMemoiOSBackgroundStatusSheet.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSBackgroundStatusSheet.swift) `1180`

- 建议下一刀按这个顺序继续：
  1. `MemoryBlockInspectorView`
     - 先抽 `configuration picker`
     - 再抽 `custom-field editor`
     - 再抽 `system modules`
  2. `InteractiveMemoryCard`
     - 先抽 `compact preview surface`
     - 再抽 `configuration context`
     - 再抽 `configuration dock`
  3. `PhotoMemoiOSV1View`
     - 继续抽 `home / output / settings` page-level surfaces
     - 仍然先做 view-only shrink，不急着回头碰 application seam
  4. `ConfigurationCenteriOSView`
     - 如果还要继续收，优先 detail-side 的 `memoryWritePanel / outputSelection / configurationGuide`

## 2026-07-01 ConfigurationSession presentation-state extraction + V1 draft orchestration cleanup

- 这一轮继续严格按 `Architecture Freeze V1` 的后续小切片推进，没有回头去做“大拆大改”。
- 目标只有三件事：
  1. 让 `ConfigurationSession` 少背一点明显属于 UI 的状态
  2. 把 `memory.configuration1` 的旧文案漂移再收一轮
  3. 让 `PhotoMemoiOSV1View` 继续保持 state in view，但把 draft / preview 编排胶水往外收

- 已新增：
  - [ConfigurationSessionPresentationState.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/ConfigurationSessionPresentationState.swift)
    - 新的职责很单一，只装：
      - `selectedOutputOption`
      - `selectedStorageOption`
      - `usesCustomMemoryWriteText`
      - `customMemoryWriteText`
      - `latestModuleInsertion`
      - `appliedMemoryPresetID`
  - [ConfigurationCenterMemoryTemplateCatalog.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/ConfigurationCenterMemoryTemplateCatalog.swift)
    - 现在 `memory.configuration1` 的生日年龄模板标题、说明、默认字段值、预览句子都集中在这里
  - [V1DraftOrchestrationCoordinator.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1DraftOrchestrationCoordinator.swift)
    - 负责：
      - `ViewState <-> MutationState` 桥接
      - dirty region 的 preview draft 批量生成
      - 默认 draft 回退

- 已更新：
  - [ConfigurationSession.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/ConfigurationSession.swift)
    - 现有对外属性基本没变，但底层不再把那组 UI-only 状态全摊在 session 顶层
  - [ConfigurationCenterPreviewDefaults.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/ConfigurationCenterPreviewDefaults.swift)
    - `memory.configuration1` 不再返回旧的 `"当天 11个月28天"` fallback
  - [ConfigurationCenterRegionDraftStore.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenterRegionDraftStore.swift)
  - [MemoryBlockInspectorView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Inspector/MemoryBlockInspectorView.swift)
  - [InteractiveMemoryCard.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/MemoryCard/InteractiveMemoryCard.swift)
    - 这三处都改成复用同一份 birthday-age 模板 copy，而不是各说各话
  - [PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift)
    - `draft(for:)` 现在走 orchestration helper
    - `applyDraftMutationUpdate(...)` 不再自己逐 region 刷 preview，而是一次桥接 view state 后，批量把 dirty preview draft 交给 `previewSyncCoordinator`
    - `refreshDynamicPreview()` 也不再自己拼 map，改由 helper 提供

- 对应测试：
  - 新增 [V1DraftOrchestrationCoordinatorTests.swift](/Users/rui/Desktop/PhotoMemo/Tests/PhotoMemoTests/ArchitectureTests/V1DraftOrchestrationCoordinatorTests.swift)
  - 更新 [ConfigurationCenterRegionDraftStoreTests.swift](/Users/rui/Desktop/PhotoMemo/Tests/PhotoMemoTests/ArchitectureTests/ConfigurationCenterRegionDraftStoreTests.swift)

- 这一轮真正的意义：
  - `ConfigurationSession` 继续朝“编辑壳 + 状态协调”方向收，不再无限往里塞输出页细节
  - `memory.configuration1` 现在更接近一份共享模板定义，而不是 preview / inspector / region-store / card 各自维护一套说法
  - `PhotoMemoiOSV1View` 继续瘦了一层，但没有把 `@State` 生硬搬离 view

- 本轮验证：
  - 通过：
    - `git -C /Users/rui/Desktop/PhotoMemo diff --check`
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -target PhotoMemoTests -configuration Debug CODE_SIGNING_ALLOWED=NO -quiet build`
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOSV1 -configuration Debug -destination 'generic/platform=iOS' -derivedDataPath /tmp/PhotoMemoiOSV1DerivedData-architecture-freeze-pass-4 CODE_SIGNING_ALLOWED=NO -quiet build`
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData-architecture-freeze-pass-2 CODE_SIGNING_ALLOWED=NO -quiet build`

- 建议下一刀：
  1. 把 `ConfigurationSession` 剩下的 presentation-only seams 再往外剥一层，尤其是 output / write 绑定和 preset applied 标记
  2. 继续把 placeholder-style 的 smart-module fallback 收到更少的位置，最终只留 MME / preview default 一条主路
  3. 再去处理更大的 application/usecase / intent 归一化，尤其旧 `Intent/` 里仍存在的 service fallback

## 2026-07-01 V1 pure-view support extraction

- 这一小轮继续做 view 层瘦身，但只做了最安全的一刀：
  - 不改交互
  - 不改状态流
  - 只把 `PhotoMemoiOSV1View` 里已经完全独立成型的纯 UI support views 拆出去

- 新增：
  - [V1IOSViewSupportComponents.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSViewSupportComponents.swift)
    - 现在承接：
      - `V1CardSurface`
      - `V1PreviewCard`
      - `V1RegionEditorCard`
      - `CardRegion.systemImage`

- 更新：
  - [PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift)
    - 只删除内联定义，调用点保持不变

- 这一轮最直观的结果：
  - `PhotoMemoiOSV1View.swift`
    - `3310` 行
    - → `2699` 行
  - 也就是说，只这一刀就又收掉了大约 `600+` 行最纯的 view 代码

- 本轮验证：
  - 通过：
    - `git -C /Users/rui/Desktop/PhotoMemo diff --check`
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOSV1 -configuration Debug -destination 'generic/platform=iOS' -derivedDataPath /tmp/PhotoMemoiOSV1DerivedData-view-slice-pass CODE_SIGNING_ALLOWED=NO -quiet build`

- 如果下一轮继续收 view，优先级建议是：
  1. `PhotoMemoiOSV1View`
     - 继续往外抽 page-level section/support presenters
     - 尤其 `home / output / settings` 这几块的展示拼装
  2. `ConfigurationCenteriOSView`
     - 现在还是 `2200+` 行
     - 里面的 `compact preview / region composer / output-memory panels` 已经具备进一步拆出去的条件
  3. `InteractiveMemoryCard`
     - 主要问题已经不只是大，而是 preview + dock + guide 全在一个文件里

## 2026-07-01 Architecture Freeze V1 + V1 save/bootstrap seam cleanup

- 这一轮不再只是继续“把大文件拆碎”，而是先把当前 V1 最容易失控的边界钉住：
  1. View 禁止直接 new Service
  2. save / bootstrap 必须走 application seam
  3. 后续 intent / usecase 开发要建立在 frozen boundary 上

- 已新增架构冻结文档：
  - [ARCHITECTURE_FREEZE_V1.md](/Users/rui/Desktop/PhotoMemo/Docs/ARCHITECTURE_FREEZE_V1.md)
  - 这份文档冻结了当前最重要的四条：
    - `Presentation -> Application -> Domain -> Infrastructure`
    - `View must not new Service`
    - `ConfigurationSession` 不能继续长成 God Object
    - MME 必须逐步成为唯一表达真相

- 本轮真正落地的代码变化：
  - 新增 [V1ConfigurationApplyCoordinator.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1ConfigurationApplyCoordinator.swift)
    - 现在由它统一处理：
      - 相册选择解析
      - `V1ConfigurationSaveRequest` 构建
      - `SaveV1ConfigurationIntent` 调用
  - 更新 [PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift)
    - `applyCurrentV1Configuration()` 不再直接 `SettingsService()`
    - 旧的本地 `persistTimeAnchor(...)` 已从 view 删除
    - 旧的本地 `resolvedOutputAlbumSelection()` 已从 view 删除
  - 更新 [V1ConfigurationBootstrapCoordinator.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1ConfigurationBootstrapCoordinator.swift)
    - `init(configurationCoordinator:)` 不再 `SettingsRepository(SettingsService())`
    - coordinator 缺失时只返回纯默认 bootstrap 状态，不再从 presentation helper 读持久化
  - 跟进的 `ConfigurationSession` 收口也一起落了：
    - 新增 [ConfigurationCenterPreviewDefaults.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/ConfigurationCenterPreviewDefaults.swift)
      - 把 preview default / template registry 停在 session 外面
    - 新增 [ConfigurationCenterMockSeed.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/ConfigurationCenterMockSeed.swift)
      - 把 `ConfigurationCenterState.mock` 停在独立 mock factory
    - [ConfigurationSession.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/ConfigurationSession.swift)
      - 现在只保留对 preview default 的薄封装，不再内联完整 registry 和 mock seed 构造

- 这一轮的意义不是“最终架构已经完成”，而是：
  - 当前最危险的 `View -> Service` 回退路径被真正切掉了
  - 后续如果继续做 `ApplyConfigurationUseCase` / `BootstrapUseCase`，已经有了一个更干净的起点
  - `ConfigurationSession` 继续长成 God Object 的速度也先被压住了一层

- 对应测试：
  - 新增 [V1ConfigurationApplyCoordinatorTests.swift](/Users/rui/Desktop/PhotoMemo/Tests/PhotoMemoTests/ArchitectureTests/V1ConfigurationApplyCoordinatorTests.swift)
  - 更新 [V1ConfigurationBootstrapCoordinatorTests.swift](/Users/rui/Desktop/PhotoMemo/Tests/PhotoMemoTests/ArchitectureTests/V1ConfigurationBootstrapCoordinatorTests.swift)

- 本轮验证：
  - 通过：
    - `git -C /Users/rui/Desktop/PhotoMemo diff --check`
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -target PhotoMemoTests -configuration Debug CODE_SIGNING_ALLOWED=NO -quiet build`
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOSV1 -configuration Debug -destination 'generic/platform=iOS' -derivedDataPath /tmp/PhotoMemoiOSV1DerivedData-architecture-freeze-pass-3 CODE_SIGNING_ALLOWED=NO -quiet build`
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData-architecture-freeze-pass CODE_SIGNING_ALLOWED=NO -quiet build`

- 下一刀建议严格按这个顺序继续：
  1. 继续拆 `ConfigurationSession` 的 UI-only output/write state
  2. 清掉旧的 `"当天 11个月28天"` / legacy smart-module wording
  3. 把 preview / draft orchestration 再从 `PhotoMemoiOSV1View` 收出去
  4. 再继续做真正的 application usecase / intent 归一化

## 2026-07-01 V1 subject persistence + MME smart-module preview alignment

- 这轮主要不是继续堆 UI，而是把用户刚指出的“假接通”问题收掉：
  1. `subject` 头像 / 主体来源 / 生效锚点不能再只活在 `ConfigurationSession`
  2. `smart module` 插入任意 `slotA/B/C/D` 后，预览不能再只是本地年龄拼接
  3. V1 配置页和 subject 配置页的键盘收起需要再稳一点

- 已落地的主干代码：
  - [ConfigurationSaveIntents.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Intent/ConfigurationSaveIntents.swift)
    - `V1ConfigurationSaveRequest` 新增 `subject`
    - `V1ConfigurationBootstrapState` 新增 `selectedSubject`
  - [SettingsService.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Services/SettingsService.swift)
    - 新增 `photomemo.selectedMemorySubject`
    - 新增 `saveSelectedMemorySubject(_:)`
    - 新增 `loadV1SelectedSubjectResult()`
    - `loadV1BootstrapReadState()` 现在返回 typed `subjectResult`
  - [SettingsRepository.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Repositories/SettingsRepository.swift)
    - V1 bootstrap 现在会把保存过的 `MemorySubject` 解出来
  - [ConfigurationCoordinator.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Coordinators/ConfigurationCoordinator.swift)
    - `saveV1Configuration(...)` 现在把 `subject` 一起落库
  - [ConfigurationSession.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/ConfigurationSession.swift)
    - 新增 `restoreSelectedSubject(_:)`
    - `generatedMemoryModule` 现在使用 preview capture date 走 MME
    - `generatedMemoryModuleText` 改走共享 preview resolver
  - 新增 [MemoryExpressionPreviewResolver.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/MemoryEngine/MemoryExpressionPreviewResolver.swift)
    - 当前唯一职责：
      - 给配置中心 / V1 预览统一生成一条“预览态 MME 智能模块文本”
  - [ConfigurationCenterPreviewCompositionHelper.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenterPreviewCompositionHelper.swift)
    - `smartTimeResult` 不再自己算月龄，而是走 MME preview resolver
  - [V1PreviewCompositionEngine.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1PreviewCompositionEngine.swift)
    - `smartTime` 的显示值现在走 MME preview resolver
    - `smartTime.rendererToken` 从 `{{anchor_age_text}}` 切到 `{{memory_summary}}`
    - slot-D 默认 draft 现在只放 smart module，不再继续本地拼 `对象 + 当天 + 年龄`
  - [PhotoMemoiOSModuleCatalog.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSModuleCatalog.swift)
    - `smartTime.rendererToken` 同步切到 `{{memory_summary}}`
  - [MemoryVariableProvider.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/MemoryEngine/MemoryVariableProvider.swift)
  - [AnchorEngine.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Engines/AnchorEngine.swift)
    - 生日摘要现在统一改成 `主体今天X...啦！`

- `PhotoMemoiOSV1View.swift` 这一轮的关键行为变化：
  - 保存默认配置时，先把当前 `session.state.selectedSubject` 按当前 anchor editor 的日期对齐，再一起传进 `V1ConfigurationSaveRequest`
  - bootstrap 恢复时，如果拿到了保存过的 subject，会通过 `session.restoreSelectedSubject(...)` 灌回当前 live session，而不是依赖 mock subject 的 UUID 恰好一致
  - `timeAnchorTitle` 现在优先使用 `resolvedExpressionSubjectText`，所以你选中的“表述主体”终于会进入 V1 默认保存链路
  - 新增页面级键盘收起：
    - home
    - editor
    - output
    - settings
    都加了 tap 空白区 / scroll dismiss
  - `V1IOSSubjectConfigurationFlow` 也补了 tap 空白区收键盘

- 这轮对用户反馈的直接响应关系：
  - “smart module 是通用模块，不局限于 D 区”
    - 已保持这个方向，没回退
    - 本轮重点是让它在任意区域插入后，显示值变成整句 MME，而不是只显示年龄结果
  - “默认内容用户自己知道怎么清，不用管”
    - 这次没有继续去大规模改所有默认底稿，只收口了真正导致公式不一致的 smart-module 链路
  - “subject 还没接进旧 V1 save pipeline，要及时处理”
    - 这一条本轮已经真正进入旧 V1 save/load seam 了

- 验证结果：
  - 通过：
    - `git -C /Users/rui/Desktop/PhotoMemo diff --check`
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -target PhotoMemoTests -configuration Debug CODE_SIGNING_ALLOWED=NO -quiet build`
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOSV1 -configuration Debug -destination 'generic/platform=iOS' -derivedDataPath /tmp/PhotoMemoiOSV1DerivedData-mme-subject-pass CODE_SIGNING_ALLOWED=NO -quiet build`
  - 尝试但被工程现状阻塞：
    - `xcodebuild ... -scheme PhotoMemo ... test`
    - 阻塞原因不是断言失败，而是：
      - `Scheme PhotoMemo is not currently configured for the test action.`

- 还没做的手工确认：
  1. 真机 kill app 后重新启动，是否能直接恢复最近保存的 subject
  2. iPhone 上在 multiline 字段弹出键盘后，点 preview 卡片或空白区域的 dismiss 体验
  3. 真正生成一张图时，`{{memory_summary}}` 切换后最终文案是否已经完全符合这条冻结公式

## 2026-07-01 V1 subject/avatar/logo alignment + active-anchor quick switch

- 本轮继续落实用户已确认的 V1 反馈，但仍然守住边界：
  - 不动 renderer
  - 不动 export
  - 不动 share extension 语义
  - 不动 photo-library 语义
- 这次真正落地了三条主线：
  1. `subject` 编辑器补齐头像与表述主体
  2. 首页 / 当前记忆对象 sheet 改成“当前生效时间锚点”语义
  3. `Logo 标识` 扩成三选项，并支持 `使用对象头像`

- 具体代码结果：
  - [MemorySubject.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Models/MemorySubject.swift)
    - `Identity` 新增：
      - `avatarImagePath`
      - `avatarBadgeImagePath`
      - `avatarPreviewImagePath`
    - 现有：
      - `activeTimeAnchorID`
      - `expressionSubjectSource`
      - `primaryTimeAnchor`
      这次开始真正进入 UI 使用链路
  - [SubjectAvatarAssetOptimizationService.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Services/SubjectAvatarAssetOptimizationService.swift)
    - 新增固定用途头像资源准备：
      - 头像显示图
      - 标识图
      - 预览图
    - 目标是把压缩/裁切处理停在 renderer 之前
  - [MemorySubjectEditorView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Editors/MemorySubjectEditorView.swift)
    - 已新增头像上传入口
    - 已新增 4 行资料的单选“表述主体”控制
    - 时间锚点区标题已改为 `当前生效时间锚点`
    - `selectedTimeAnchorID` 现在同步写回：
      - `activeTimeAnchorID`
      - `behavior.primaryAnchor`
      - `referenceDate`
  - [ConfigurationSession.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/ConfigurationSession.swift)
    - `currentConfigurationLabel`
    - `currentTimeAnchorTitle`
    - `currentTimeAnchorDescription`
    现在都优先走 `primaryTimeAnchor`
  - [V1IOSSubjectOverviewSupport.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectOverviewSupport.swift)
    - 首页 `当前记忆对象` 下方重复的 `时间锚点` 入口已去掉
    - 主卡片现在显示：
      - 头像
      - 当前生效时间锚点
    - `当前记忆对象` sheet 已支持：
      - 下拉选择锚点
      - `设为生效` 明确确认
      - `前往对象配置` 继续保留
  - [PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift)
    - 已接上 overview sheet 的生效锚点确认回写
    - `Logo 标识` 现在支持：
      - `Apple 标识`
      - `自选标识`
      - `使用对象头像`
    - 预览条也已支持 `subjectAvatar` 模式
  - [V1LogoMode.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1LogoMode.swift)
    - 把 logo mode 从 iOS 视图私有枚举抽到共享文件，解决 bootstrap / test 编译面可见性问题
  - [V1ConfigurationBootstrapPresenter.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1ConfigurationBootstrapPresenter.swift)
  - [ConfigurationSaveIntents.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Intent/ConfigurationSaveIntents.swift)
  - [SettingsRepository.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Repositories/SettingsRepository.swift)
    - V1 bootstrap 状态现在显式持有 `logoMode`
    - 通过 badge 名称 `对象头像` 恢复第三种 logo 模式
  - 补的收尾验证修正：
    - [V1IOSHomeSupportViews.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSHomeSupportViews.swift)
      - 取消 `iOS-only` 编译门，恢复 `V1IOSHomeRecentProcessingPresenter` 在 macOS/test 编译面的可见性
    - [V1IOSHomeProjectionTests.swift](/Users/rui/Desktop/PhotoMemo/Tests/PhotoMemoTests/ArchitectureTests/V1IOSHomeProjectionTests.swift)
      - 对齐当前 `MemoryBehavior` 初始化形状与 `DecorationStrategy` 枚举

- 本轮验证：
  1. 通过：
     - `git -C /Users/rui/Desktop/PhotoMemo diff --check`
  2. 通过 iOS V1：
     - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOSV1 -configuration Debug -destination 'generic/platform=iOS' -derivedDataPath /tmp/PhotoMemoiOSV1DerivedData-mee-ui-pass-2 CODE_SIGNING_ALLOWED=NO -quiet build`
     - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOSV1 -configuration Debug -destination 'generic/platform=iOS' -derivedDataPath /tmp/PhotoMemoiOSV1DerivedData-mee-ui-pass-3 CODE_SIGNING_ALLOWED=NO -quiet build`
  3. 通过 macOS 主 app：
     - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData-mac-shared-check CODE_SIGNING_ALLOWED=NO -quiet build`
  4. `PhotoMemoTests` target 级 build 现已恢复通过：
     - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -target PhotoMemoTests -configuration Debug CODE_SIGNING_ALLOWED=NO -quiet build`

- 这一轮重要提醒：
  - `subject` / 头像 / 表述主体 现在已经真实进入 V1 UI 与 MEE 路径
  - 但它们**仍然主要存在于 `ConfigurationSession` 内**
  - 也就是说：
    - logo mode 的三选项恢复了 bootstrap
    - subject object 本身的长期持久化还没有正式接入旧 V1 save pipeline
  - 如果下一轮继续，比较自然的顺序是：
    1. 把 subject 的长期持久化边界补上
    2. 再把 active anchor 与 birthday-only MEE 模块进一步对齐
    3. 最后再做真机交互细修

## 2026-07-01 repository file organization baseline

- 本轮没有继续扩写业务逻辑，先做了一次仓库层面的“文件整理基线”，目标是让后续继续推进 IA-003 / V1 时更容易找文件，而不冒然触碰物理迁移风险。
- 这次整理只做三件事：
  1. 给当前源码树补清楚目录说明
  2. 给 `iOS/Views` 补一份逻辑分区索引
  3. 清掉明显的本地残留
- 已更新：
  - [PROJECT_STRUCTURE.md](/Users/rui/Desktop/PhotoMemo/Docs/PROJECT_STRUCTURE.md)
  - [README.md](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/README.md)
  - [CURRENT_STATUS.md](/Users/rui/Desktop/PhotoMemo/Docs/CURRENT_STATUS.md)
- 当前明确约定：
  - `Source/PhotoMemo/PhotoMemo/iOS/Views/` 暂时继续保持物理平铺
  - 逻辑上按以下几组理解即可：
    - `ConfigurationCenter*` / `IOSConfigurationPanel.swift` / `MemoryWriteOptionPresenter.swift`
    - `PhotoMemoiOSV1View.swift` + `V1*`
    - `PhotoMemoiOSHomeView.swift` + `V1IOSHome*`
    - diagnostics / support 相关 helper
  - 之所以这轮**不**直接物理挪动这些文件，是因为当前工程使用 filesystem-synchronized groups，同时 `HANDOFF.md` / `CURRENT_STATUS.md` 里有大量历史路径引用；现在硬搬文件，收益不如风险低。
- 这轮整理后的含义是：
  - 先把“怎么看懂文件”整理清楚
  - 等后续如果真的要做物理迁移，再单独作为一个 reviewed cleanup slice 处理

## 2026-07-01 MEE foundation + configuration-center secondary-menu alignment

- 本轮开始把你确认过的 `Memory Expression Engine` 方向落到代码，但严格停在 IA-003A / IA-003B 的安全边界内：
  - 不动 renderer
  - 不动 export
  - 不动 share extension
  - 不动 photo-library 语义
- 这次落地分成两条并行主线：
  1. 建立一层可编译的 MEE foundation 壳
  2. 把 iOS 配置中心二级菜单从“`slotD` 专属记忆区”拉回到“先生成 1 个智能模块，再决定承载与写入”

- 新增的 foundation 文件：
  - [MemoryAnchor.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/MemoryEngine/MemoryAnchor.swift)
  - [MemoryModule.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/MemoryEngine/MemoryModule.swift)
  - [MemoryExpressionContext.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/MemoryEngine/MemoryExpressionContext.swift)
  - [MemoryExpressionEngine.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/MemoryEngine/MemoryExpressionEngine.swift)
  - [MemorySubjectAdapter.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/MemoryEngine/MemorySubjectAdapter.swift)
  - [ConfigurationSnapshotBuilder.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/ConfigurationSnapshotBuilder.swift)

- foundation 实际建立了这条最小闭环：
  - `MemorySubject`
  - `ConfigurationSnapshot`
  - `MemoryExpressionEngine.generateModule(context)`
  - `MemoryModule`
  - `preferredRegion`
- 当前实现含义：
  - 后台先生成 1 个 `MemoryModule`
  - module 自身带 `preferredRegion`
  - region 是承载者，不再是智能模块的所有者
  - 这一步还没有接入生产 renderer，只先在配置中心内部建立语义边界

- 本轮对现有配置中心语义的主要调整：
  - [IOSConfigurationPanel.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/IOSConfigurationPanel.swift)
    - `.writeMemory` 已升级为 `.memoryModule`
  - [ConfigurationCenterDetailPresenter.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenterDetailPresenter.swift)
    - 二级页面标题改为 `智能模块`
    - 副标题明确为“先生成 1 个智能模块，再决定承载与写入方式”
    - `slotA/B/C/D` 的编辑标题改成 `区域 A/B/C/D 配置`
  - [ConfigurationCenteriOSView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift)
    - sidebar 中 `记忆模块` 改成 `智能模块`
    - 二级入口改成 `智能模块 / 生成、承载与写入`
    - `区域 D` 文案改成 `记忆 · 默认承载`
    - `showsMemorySystemModules` 不再只给 `slotD`
    - 现在四个 memory card region 都能看到同一套智能模块插入能力
  - [ConfigurationCenterSessionBindingPresenter.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenterSessionBindingPresenter.swift)
  - [MemoryWriteOptionPresenter.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/MemoryWriteOptionPresenter.swift)
  - [InteractiveMemoryCard.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/MemoryCard/InteractiveMemoryCard.swift)
  - [PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift)
    - `写入记忆` 的用户可见文案统一改向：
      - `智能模块`
      - `单独录入相册说明`
      - `当前生成的智能模块完整结果`

- 对 `ConfigurationSession` 的关键收口：
  - 新增：
    - `smartModuleCarrierRegion`
    - `currentConfigurationSnapshot`
    - `generatedMemoryModule`
  - `resolvedMemoryWriteText` 现在优先消费 `generatedMemoryModule.renderedText`
  - `selectBlock(...)` 不再强制跳回 `slotD`
  - `select(region:)` 也不再因为离开 `slotD` 就清 `selectedBlockID`
  - 这一步的目的，是先把“智能模块内容”和“D 区布局默认值”拆开

- `ConfigurationSnapshot` 现在额外持有：
  - `primaryAnchor`
  - `smartModuleCarrierRegion`
- `MemorySubject` 现在有：
  - `resolvedShortName`
  - `primaryTimeAnchor`
  - `timeAnchor(named:)`

- 新增测试：
  - [MemorySubjectAdapterTests.swift](/Users/rui/Desktop/PhotoMemo/Tests/PhotoMemoTests/ArchitectureTests/MemorySubjectAdapterTests.swift)
  - [ConfigurationSnapshotBuilderTests.swift](/Users/rui/Desktop/PhotoMemo/Tests/PhotoMemoTests/ArchitectureTests/ConfigurationSnapshotBuilderTests.swift)
  - [MemoryExpressionEngineTests.swift](/Users/rui/Desktop/PhotoMemo/Tests/PhotoMemoTests/ArchitectureTests/MemoryExpressionEngineTests.swift)
  - 同时更新了 `ConfigurationCenterDetailPresenterTests`、`ConfigurationCenterPageChromePresenterTests`、`ConfigurationCenterSelectionCoordinatorTests`、`ConfigurationCenterSessionBindingPresenterTests`、`MemoryWriteOptionPresenterTests`

- 本轮验证结果：
  1. 主 macOS app build 通过：
     - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoMEEAppDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
     - 退出 `0`
  2. `PhotoMemoTests` target 级 build 仍被仓库内既有历史测试 debt 阻塞，但已确认不是本轮新 foundation 引入：
     - `V1IOSHomeProjectionTests`
       - 仍在使用旧 `MemoryBehavior` / `DecorationStrategy` 形状
     - `V1IOSHomeRecentProcessingPresenterTests`
       - 仍引用找不到的旧 presenter 名称
  3. 也就是说：
     - 本轮新增源代码已进入主 target 并编译通过
     - 当前 test build 失败仍主要来自旧 V1 测试残留，不是 renderer/export/share/photo-library 边界回归

- 当前仍然**没有**做的事：
  - 还没有把这套 MEE foundation 接进生产 renderer
  - 还没有把 `PersonalProfileStore` / `SettingsService` 正式迁移为新 subject 来源
  - 还没有开始 IA-003C 级别的 block resolver 真正重写
  - 还没有清理所有老 V1 architecture tests

## 下一轮建议

- 如果继续 IA-003 正线，最自然的后续顺序是：
  1. 让 `Configuration Snapshot` 真正成为配置中心对外唯一导出
  2. 开始把 `MemoryBlock Resolver` 接到 `generatedMemoryModule`
  3. 再讨论如何把当前 preview 中的 `slotD` 默认结果逐步降格为“默认承载”，而不是“唯一智能结果来源”

## 2026-07-01 V1 iOS subject flow + configuration center polish landed

- 本轮已经从“反馈记录”进入实际实现，并保持不触碰 renderer / export / share / photo-library 语义：
  1. 首页 `当前记忆对象` 入口不再通过概览 sheet 直接切回主 tab `配置中心`
  2. 现在改为进入独立的 subject 配置流
  3. 主 `配置中心` 同步完成页面级工具栏、键盘收起、淡入淡出移除、写入记忆语义修正
- subject 专属配置流已落地：
  - 相关文件：
    - [PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift)
    - [V1IOSSubjectOverviewSupport.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectOverviewSupport.swift)
    - [V1IOSSubjectConfigurationFlow.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectConfigurationFlow.swift)
  - 当前行为：
    1. `当前记忆对象` -> `V1IOSSubjectOverviewSheet`
    2. `前往对象配置` -> 打开独立 `V1IOSSubjectConfigurationFlow`
    3. flow 内复用 `MemorySubjectEditorView`
    4. 页面级 `返回` 直接关闭，不提交草稿
    5. 页面级 `保存` 才把 draft `ConfigurationSession` 回写到 live session
  - 这满足了用户要求的：
    - subject 入口聚焦概览 / 基本资料 / 时间锚点
    - 具备明确保存 / 返回
- 主 `配置中心` polish 已落地：
  - 相关文件：
    - [ConfigurationCenteriOSView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift)
    - [ConfigurationCenterPageChromePresenter.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenterPageChromePresenter.swift)
    - [ConfigurationCenterSelectionCoordinator.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenterSelectionCoordinator.swift)
    - [ConfigurationCenterSessionBindingPresenter.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenterSessionBindingPresenter.swift)
    - [InteractiveMemoryCard.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/MemoryCard/InteractiveMemoryCard.swift)
  - 实际变化：
    1. 页面级 toolbar 已补上 section/status + `重置` / `保存并生效`
    2. sidebar / detail / preview interaction 现在都会配合键盘收起
    3. `slotA/B/C/D` 编辑区域相关的 fade / slide 过渡残留已移除
    4. `写入记忆` 语义已改成“是否使用单独录入文字”，不再误导成“不勾选就不写入”
    5. 默认回退规则保持不变：仍然回退到 `slotD` 完整输出
- 本轮还额外补了 V1 输出页的统一语义 presenter：
  - [MemoryWriteOptionPresenter.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/MemoryWriteOptionPresenter.swift)
  - [MemoryWriteOptionPresenterTests.swift](/Users/rui/Desktop/PhotoMemo/Tests/PhotoMemoTests/ArchitectureTests/MemoryWriteOptionPresenterTests.swift)
- 本轮验证结论：
  1. `PhotoMemoiOSV1` iOS generic build 已通过：
     - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOSV1 -configuration Debug -destination 'generic/platform=iOS' -derivedDataPath /tmp/PhotoMemoiOSV1DerivedData-ui-pass CODE_SIGNING_ALLOWED=NO -quiet build`
     - 退出 `0`
  2. `PhotoMemoTests` target 级编译尝试仍被仓库内既有 iOS 架构测试残留阻塞，当前观察到的外部问题包括：
     - `V1IOSHomeRecentProcessingPresenterTests`
     - iOS-only view presenter / support 测试在 macOS test build 下的可见性条件
     - 这些不是本轮新增 UI 改动首次引入的唯一问题来源
- 当前剩余注意点：
  1. 本轮已完成 UI/交互主路径落地，但还没有做真机层面的手工点按验证
  2. 如果下一轮继续，应优先：
     - 真机看 subject flow 的保存 / 返回体验
     - 看主配置中心键盘 dismiss 是否完全符合预期
     - 再决定是否继续清理 `PhotoMemoTests` 里那些与当前 iOS 壳层重命名同步不一致的旧测试

## 2026-07-01 V1 UI feedback intake: subject entry should become dedicated subject configuration flow

- 用户最新补充的方向需要和前一轮反馈分开理解：
  1. 从首页 `当前记忆对象` 进入后的“配置中心”，本质上应该是**该记忆对象的专属配置流**
  2. 这个流里主要配置的是：
     - 概览
     - 基本资料
     - 时间锚点
  3. 该流应具备更明确的页面动作：
     - 保存
     - 返回
  4. 与此同时，主界面底部 tab 的 `配置中心` 仍可保持当前“自由切换不同页面”的能力
  5. 主 tab `配置中心` 仍需要按前面反馈修正：
     - 去掉配置区域淡入淡出
     - 补强保存动作感知
     - 统一键盘收起
     - 不必额外强调“返回上一级”，因为它本身就是底部一级页面
- 当前代码链路已经确认：
  1. 首页 `当前记忆对象` 点击后，先打开的是 `V1IOSSubjectOverviewSheet`
     - [PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift:288)
     - [V1IOSSubjectOverviewSupport.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectOverviewSupport.swift:184)
  2. 该 sheet 底部的 `前往配置中心` 目前不是进入独立 subject 配置流，而是：
     - 先关闭 sheet
     - 再把底部 tab 切到 `.editor`
     - [PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift:295)
     - [PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift:297)
  3. 也就是说，当前行为其实是：
     - `当前记忆对象 -> 概览 sheet -> 主 tab 配置中心`
     - 而不是
     - `当前记忆对象 -> 该对象的专属配置页`
- 当前已有可复用能力：
  1. 主 `配置中心` 里已经有 `.subject` 面板选择语义
     - [ConfigurationCenterSelectionCoordinator.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenterSelectionCoordinator.swift:22)
  2. `MemorySubjectEditorView` 已经覆盖了用户强调的核心资料项：
     - 显示名称 / 昵称 / 关系 / 定义
     - 时间锚点列表、主锚点选择、日期 / 名称 / 说明编辑
     - 区域内保存按钮
     - [MemorySubjectEditorView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Editors/MemorySubjectEditorView.swift:26)
     - [MemorySubjectEditorView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Editors/MemorySubjectEditorView.swift:82)
  3. 所以未来并不一定要重做 subject 编辑内容本体，更可能是：
     - 复用 `MemorySubjectEditorView`
     - 外层包一层专属的 iOS subject 配置容器
     - 给它补齐页面级保存 / 返回 / 导航语义
- 目前更合理的后续拆分应是：
  1. `当前记忆对象` 入口：
     - 改为进入独立的 subject 配置流
     - 页面聚焦 `概览 + 基本资料 + 时间锚点`
     - 具备保存与返回
  2. 主 tab `配置中心`：
     - 继续承担通用配置、卡片区域、输出、写入记忆等内容
     - 保留底部自由切页能力
     - 修正前面已经确认的问题，但不强行做成“返回链路”
- 这条反馈与仓库冻结边界不冲突，因为它仍属于：
  - 已冻结 IA-002 架构内的 iOS polish / entry semantics 调整
  - 不是重新设计新的整体配置中心架构
  - 也不要求进入 renderer / export / share / photo-library 语义改动

## 2026-07-01 V1 UI feedback intake: slot fade + page actions

- 用户最新反馈先记录，不在本轮立即改代码：
  1. `slotA/B/C/D` 区域不再需要沿用早期 MVP 为凸显 preview 而加的淡入淡出
  2. 当前页面感知上缺少更明确的保存按钮
  3. 当前页面感知上缺少返回上一级入口
  4. 配置页面键盘弹出后，点击其他区域应能收起，当前会卡住半屏操作
  5. 配置页面里的时间锚点，从产品理解上更应该是下拉可选内容；但这条当前先保持现状，后续再研究具体逻辑
  6. 输出模块里的“写入记忆”应改成：
     - 用户可选是否单独录入
     - 勾选后出现单独录入窗口，写入用户文字
     - 不勾选时，默认把 `slotD` 的完整输出结果写入图片说明栏
- 当前代码定位结论：
  1. `slotA/B/C/D` 相关的淡入淡出/滑入残留并不只是静态透明度，还包括交互过渡：
     - [InteractiveMemoryCard.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/MemoryCard/InteractiveMemoryCard.swift:64)
     - [InteractiveMemoryCard.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/MemoryCard/InteractiveMemoryCard.swift:982)
     - [ConfigurationCenteriOSView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift:540)
  2. 配置中心当前确实没有页面级 toolbar 保存动作，也没有页面级返回动作：
     - [ConfigurationCenteriOSView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift:24)
     - [ConfigurationCenteriOSView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift:57)
     - 当前只有 `navigationTitle`，没有对应 `.toolbar { ... }`
  3. 现有“保存”是区域级、局部保存，不是页面级主操作：
     - [ConfigurationCenteriOSView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift:1999)
     - 这会造成“局部能保存，但整页像没保存按钮”的感知
  4. `PhotoMemoiOSV1View` 的编辑页本身也是顶层 tab 页面，不天然带“返回上一级”：
     - [PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift:439)
     - 只有某些下钻页/弹层才有显式完成按钮，例如模块面板：
       - [PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift:1522)
  5. 键盘收起问题当前也成立，但原因是“局部有焦点清理，页面没有统一 dismiss 策略”：
     - 区域编辑器 `IOSRegionComposer` 只有组件内 `.onTapGesture { isFocused = false }`
       - [ConfigurationCenteriOSView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift:1910)
     - 文本输入真正绑定的是局部 `@FocusState private var isFocused`
       - [ConfigurationCenteriOSView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift:1861)
       - [ConfigurationCenteriOSView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift:2033)
     - 但页面容器 `NavigationStack -> GeometryReader -> VStack/HStack -> ScrollView`
       当前没有统一的 `scrollDismissesKeyboard` / 页面空白区 dismiss / 全局 focus reset
       - [ConfigurationCenteriOSView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift:24)
  6. 时间锚点这条目前需要区分“当前代码事实”和“后续产品表达”：
     - 在 `subject` 编辑器里，时间锚点实际上已经是 `Picker(.menu)` 选择当前锚点
       - [MemorySubjectEditorView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Editors/MemorySubjectEditorView.swift:198)
     - 选中后再编辑该锚点的日期 / 名称 / 说明
       - [MemorySubjectEditorView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Editors/MemorySubjectEditorView.swift:233)
     - 当前逻辑也确实是“一个 subject 持有多个 timeAnchors，并有一个 primaryAnchor 被选中”
       - [MemorySubjectEditorView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Editors/MemorySubjectEditorView.swift:334)
       - [MemorySubjectEditorView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Editors/MemorySubjectEditorView.swift:367)
     - 所以这条不是“完全没做成可选”，而是配置页整体还没有把这层选择语义表达得足够明确；按用户要求，本轮保持现状
  7. “写入记忆”这条当前是“底层回退逻辑基本正确，但 UI 语义不对”：
     - 当前底层解析 `resolvedMemoryWriteText` 的逻辑是：
       - 若勾选自定义且文本非空，则写入自定义文本
       - 否则回退为 `slotD` 的输出结果
       - [ConfigurationSession.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/ConfigurationSession.swift:199)
     - 这与用户想要的最终写入规则本质上是接近的
     - 但当前 UI 开关语义写成了：
       - `是否写入记忆说明`
       - `自定义写入内容`
       - [PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift:1354)
       - [ConfigurationCenteriOSView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift:894)
     - 这会让人误以为“不勾选 = 不写入”，但当前真实行为其实是“不勾选 = 写入 `slotD` 默认内容”
     - 所以后续更合理的改法不是重写底层 fallback，而是把 UI 改成：
       - 一个明确的勾选控件，表达“是否使用单独录入内容”
       - 勾选后出现录入框
       - 不勾选时明确展示“将默认写入记忆区域完整结果”
- 建议后续统一处理方向：
  1. 把 `slotA/B/C/D` 区域相关的 `.transition(.opacity...)` / 淡入淡出残留全部清掉，改成稳定直接显示
  2. 明确区分“区域级保存”与“页面级保存并生效”，避免用户把两者混淆
  3. 如果该页面未来仍定位为独立配置流，需要补一个明确的上级退出/返回语义；如果继续保留为顶层 tab，则要补足页面级主操作，让它不像“少了返回按钮”
  4. 为配置页加统一的键盘收起策略，至少满足“点空白区 / 滚动 / 切换面板时键盘能退”
  5. 时间锚点先不改逻辑，后续再决定是只强化现有 `subject -> 多锚点 -> 选 primaryAnchor` 表达，还是再抽到更明确的配置层入口
  6. “写入记忆”优先保留当前 fallback 规则，只重做控件语义、文案和勾选后的录入交互

## 2026-07-01 V1 target / scheme rename completion

- 本轮目标是把当前活跃 iOS V1 线剩余的工程层 `MVP` 命名全部收口到 `V1`：
  - target
  - shared scheme
  - app product name
  - 临时入口枚举残留
- 严格保持：
  - 不动 renderer
  - 不动 Memory Engine 边界
  - 不动 export / share / photo-library 语义
  - 不改 bundle identifier
- 本轮实际完成：
  1. 当前独立 iOS V1 target 已从 `PhotoMemoiOSMVP` 改成：
     - `PhotoMemoiOSV1`
  2. 当前 shared scheme 已改成：
     - `PhotoMemoiOSV1`
  3. 当前构建产物名已改成：
     - `PhotoMemoiOSV1.app`
  4. 临时入口最后一处旧枚举 case 也已收掉：
     - `.mvpTest` -> `.v1Preview`
  5. 活跃工程 / 源码 / 测试范围内，已扫空：
     - `MVP`
     - `mvp`
     - `PhotoMemoiOSMVP`
- 本轮验证：
  - `xcodebuild -list -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj`
    已确认 target / scheme 列表出现 `PhotoMemoiOSV1`
  - `git diff --check -- /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj/project.pbxproj /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj/xcshareddata/xcschemes/PhotoMemoiOSV1.xcscheme /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj/xcuserdata/rui.xcuserdatad/xcschemes/xcschememanagement.plist /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSTemporaryEntryView.swift /Users/rui/Desktop/PhotoMemo/Tests/PhotoMemoTests/BatchTests/PhotoMemoiOSTemporaryEntryTests.swift`
    通过
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOSV1 -configuration Debug -destination 'generic/platform=iOS' -derivedDataPath /tmp/PhotoMemoiOSV1DerivedData-v1-rename-check-2 CODE_SIGNING_ALLOWED=NO -quiet build`
    退出 `0`
- 当前结论：
  - 之后你直接说 `V1`，就对应当前这条 iOS 线
  - 下面文档里还保留的 `PhotoMemoiOSMVP`，现在都只应视为历史记录，不再是当前活跃 target / scheme 名
  - 后续如果要推真机，应该优先用 `PhotoMemoiOSV1`

## 2026-07-01 V1 real-device compile verification

- 本轮目标是重新检查工程后，确认当前 `V1` 线是否已经具备真机编译前提
- 严格保持：
  - 不动 renderer
  - 不动 export / photo-library 语义
  - 不扩成新的 UI / 架构改造
- 本轮确认结果：
  1. 当前 `PhotoMemoiOSMVP` 已可完成整条 iPhoneOS Debug 编译链
  2. 本次通过使用的是：
     - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOSMVP -configuration Debug -destination 'generic/platform=iOS' -derivedDataPath /tmp/PhotoMemoiOSMVPDerivedData-v1-final-check CODE_SIGNING_ALLOWED=NO -quiet build`
  3. 构建产物已实际生成：
     - `PhotoMemoiOSMVP.app`
     - `PhotoMemoShareExtension.appex`
     - `PhotoMemoWidgetExtension.appex`
  4. 说明当前关注点已经从“工程还能不能编译”前移到：
     - 签名
     - 真机安装
     - 设备侧行为验证
- 本轮没有继续做：
  - 真机签名配置修改
  - 安装到设备
  - 运行时交互验证

## 2026-07-01 Share Extension target membership shrink

- 本轮只修工程 membership 结构：
  - `Source/PhotoMemo/PhotoMemo.xcodeproj/project.pbxproj`
- 严格保持：
  - 不改 Share Extension 业务语义
  - 不动 renderer
  - 不动 export / photo-library 行为
  - 不把这轮扩成 UI / architecture feature work
- 根因确认：
  - `PhotoMemoShareExtension` 之前把整个 `PhotoMemo` 根目录作为
    `fileSystemSynchronizedGroups`
  - 再靠一大串 exception 排除
  - 结果是主工程一旦继续长新文件，extension target 就会自动重新吸进去
- 本轮完成的结构修正：
  1. `PhotoMemoShareExtension` 不再同步整棵 `PhotoMemo`
  2. 改成只同步三块白名单目录：
     - `PhotoMemo/App`
     - `PhotoMemo/Models`
     - `PhotoMemo/iOS/ShareExtension`
  3. 在 `App` 白名单里继续排掉 app-runtime-only 文件：
     - `PhotoMemoApp*`
     - `PhotoMemoBackgroundStatusService`
     - `PhotoMemoRootSceneView`
     - `PhotoMemoiOSTemporaryEntry`
  4. 在 `Models` 白名单里继续排掉非 share 需要的模型族：
     - `CardVariableProvider`
     - `PhotoMetadata`
     - `RecordCard`
     - `SelectedPhoto`
     - `TemplateVariable*`
  5. `iOS/ShareExtension` 目录内备用
     `PhotoMemoShareExtension-Info.plist`
     也排除了，避免被当成无关 build member
- 结果：
  - Share Extension 当前实际 Swift compile list 已收敛到 `28` 个文件
  - 原来被误吸进来的这些大片目录已不再进入该 target：
    - `ConfigurationCenter/*`
    - `Coordinators/*`
    - `Intent/*`
    - `iOS/Views/*`
    - `Views/Main/*`
    - `Renderers/*`
- 本轮验证：
  - `git diff --check -- Source/PhotoMemo/PhotoMemo.xcodeproj/project.pbxproj`
    通过
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -target PhotoMemoShareExtension -configuration Debug CODE_SIGNING_ALLOWED=NO -quiet build`
    退出 `0`
  - 另外也试了 scheme 级 `PhotoMemoShareExtension` build：
    - 发现当前 scheme 的 build action 还会顺带编
      `PhotoMemoiOS` / `PhotoMemoiOSMVP`
    - 所以它不适合作为这轮“extension target 是否独立干净”的唯一证据
    - target-only build 才是这轮最干净的验证
- 仍然存在、但和这轮修正分开的环境问题：
  - `CoreSimulatorService`
  - `simdiskimaged`
  - 这是本机 Simulator 服务层异常，不是这次 pbx 收缩造成的
- 这轮之后最自然的下一步：
  1. 如果还想继续收紧，可以再把 `App` / `Models` 从目录白名单进一步切成
     更细的显式共享文件白名单
  2. 单独处理 `PhotoMemoShareExtension` scheme build action
     为什么会 fan out 到 `PhotoMemoiOS` / `PhotoMemoiOSMVP`
  3. 另起一条环境线修 `CoreSimulatorService / simdiskimaged`

## 2026-07-01 V1 shell identifier migration batch 1

- 本轮继续严格保持：
  - 不动 renderer
  - 不动 Memory Engine 边界
  - 不动 Export / Share / Photo Library 语义
  - 不改 target / scheme / bundle 结构
- 本轮只做当前 iOS `V1` 壳层的内部命名迁移第一刀，并保留兼容别名
- 本轮接入文件：
  - `Source/PhotoMemo/PhotoMemo/iOS/App/PhotoMemoiOSMVPApp.swift`
  - `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSTemporaryEntryView.swift`
  - `Source/PhotoMemo/PhotoMemo/iOS/Views/MVPIOSHomeCardPrimitives.swift`
  - `Source/PhotoMemo/PhotoMemo/iOS/Views/MVPIOSHomeProjection.swift`
  - `Source/PhotoMemo/PhotoMemo/iOS/Views/MVPIOSHomeSupportViews.swift`
  - `Source/PhotoMemo/PhotoMemo/iOS/Views/MVPIOSSubjectOverviewSupport.swift`
  - `Source/PhotoMemo/PhotoMemo/iOS/Views/MVPSubjectHomeSummarySupport.swift`
  - `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSMVPTestView.swift`
  - 对应 Home / Subject architecture tests
- 实际完成的变化：
  1. 入口壳层类型已开始正式切到 `V1`：
     - `PhotoMemoiOSV1App`
     - `PhotoMemoiOSV1View`
  2. Home / Subject presenter 与 support surface 的核心命名已同步切到 `V1`：
     - `V1IOSHomeProjection`
     - `V1IOSHomeRecentProcessingPresenter`
     - `V1IOSSubjectOverviewPresenter`
     - `V1SubjectHomeSummaryPresenter`
  3. 当前批次没有硬删旧名，而是保留了 `typealias` 兼容层：
     - 这样后面还能继续按 Home / Subject / draft / preview contract 分批迁
  4. 顺手收掉一条还残留在 Subject Home 摘要里的旧语义文案：
     - `Preset` -> `配置组合`
- 本轮验证：
  - `git diff --check` 已通过
  - 已尝试：
    - `PhotoMemo` macOS build
    - `PhotoMemoiOSMVP` iOS build
  - 当前状态：
    - 两条 build 都进入了 Xcode build execution
    - 之后仍卡在同类 `in flight operation` / package-loading 路径
    - 最终为人工中断，因此没有最终 pass / fail verdict
    - 在中断前没有出现这轮 `V1` 壳层命名迁移带来的新增 compiler diagnostic
- 这轮之后最自然的下一步：
  1. 继续收 `PhotoMemoiOSMVPTestView` 周围还没进入本轮的 `MVP*` UI 壳层类型
  2. 再进入 Home / Subject 之外的 draft / helper / preview contract 家族
  3. target / scheme / product 级重命名仍然放到更后面，避免和 bundle / scheme 风险混在一起

## 2026-07-01 V1.0 visible-name cleanup

- 本轮只做用户可见层的 `MVP / MVPTest -> V1.0` 收口：
  - 不动 renderer
  - 不动 Memory Engine
  - 不做 target / scheme / 类型名级别的大重命名
- 本轮接入文件：
  - `Source/PhotoMemo/PhotoMemoiOSMVP-Info.plist`
  - `Source/PhotoMemo/PhotoMemo.xcodeproj/project.pbxproj`
  - `Source/PhotoMemo/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionViewController.swift`
  - `Source/PhotoMemo/PhotoMemo/PhotoMemo/App/PhotoMemoiOSTemporaryEntry.swift`
  - `Source/PhotoMemo/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSMVPTestView.swift`
- 实际完成的变化：
  1. 当前独立 iOS MVP app 的显示名已改成：
     - `PhotoMemo V1.0`
  2. 相册权限文案同步从：
     - `PhotoMemo MVP`
     收成：
     - `PhotoMemo V1.0`
  3. Share Extension 失败兜底文案已改成：
     - `请直接打开 PhotoMemo V1.0`
  4. 临时入口页标题从：
     - `MVP 测试页`
     改成：
     - `V1.0 预览`
  5. SwiftUI preview 标题从：
     - `iOS MVP 测试`
     改成：
     - `iOS V1.0 预览`
- 本轮验证：
  - `git diff --check` 通过
  - 定向 grep 已确认这批旧可见字符串在 `Source/PhotoMemo` +
    `PhotoMemo.xcodeproj` 中已经清空：
    - `PhotoMemo MVP`
    - `MVP 测试页`
    - `iOS MVP 测试`
  - 已尝试：
    - `PhotoMemoiOSMVP` iOS build
    - `PhotoMemo` macOS build
  - 当前状态：
    - 两条 build 都已进入 Xcode build execution
    - 但在本轮 handoff 记录时，还没有拿到最终 compiler verdict
- 与本轮并行盘点结果一致的当前共识：
  1. 用户可见层的 `MVP` 基本已经收干净
  2. 剩余主要是内部代码标识符层：
     - 约 `25` 个源码文件
     - 约 `74` 个 `MVP*` 类型
     - 约 `14` 个直接带 MVP 名的测试文件
  3. 下一步最合理顺序：
     - 先改入口壳层
     - 再改 Home / Subject 壳层
     - 再改 draft / helper / preview contract
     - 最后再碰 configuration / output 契约与 target / scheme

## 2026-07-01 iOS Classic White naming lift

- 本轮继续严格保持：
  - 不动 renderer / preview 内部规范
  - 不动 export / share / photo-library 语义
  - 只做 iOS 可见层的命名与层级收口
- 本轮接入文件：
  - `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSMVPTestView.swift`
  - `Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift`
  - `Source/PhotoMemo/PhotoMemo/iOS/Views/MVPIOSHomeCardPrimitives.swift`
- 实际完成的变化：
  1. Home 的 `当前配置` 卡片现在显式拆成两层：
     - `边框样式`
     - `配置组合`
  2. 当前唯一公开样式已经在 iOS 壳层固定露出为：
     - `Classic White`
  3. Home 卡片里原来偏内部实现的 preset 文案已收成更贴近产品语义的：
     - `切换配置组合`
     - `重命名配置组合`
     - `配置组合名称`
  4. 保存确认文案也同步从直接 `Preset` 说法，收成了
     `配置组合 + 时间锚点 + 输出设置`
  5. `ConfigurationCenteriOSView` 顶部摘要现在也补上同一套分层：
     - `边框样式`
     - `配置组合`
  6. 顺手修掉一个已存在的跨平台编译点：
     - `MVPIOSHomeStatusBadge.Tone.neutral`
       不再使用 mac 路径下会报错的 `secondarySystemBackground`
- 本轮验证：
  - `git diff --check` 通过
  - 首次 macOS build 明确抓到一个真实编译错误：
    - `MVPIOSHomeCardPrimitives.swift`
    - `Color(.secondarySystemBackground)` 在当前编译路径下无效
  - 这个错误已在本轮修复
  - 修复后重新尝试：
    - `PhotoMemoiOS`
    - `PhotoMemo`
    两条 build 都长时间停留在 Xcode 自己的 in-flight build/package
    operation，最终是人工中断，因此没有拿到最终 pass/fail verdict
  - 在人工中断前，没有再出现这轮 `Classic White / 配置组合`
    命名收口带来的新增编译诊断
- 这轮之后最自然的下一步：
  1. 继续把 iOS 壳层残留的 `Preset` 可见文案收掉
  2. 等 style 体系真正开放多个边框时，把 `Classic White`
     这一层接成可选样式入口
  3. 等壳层命名稳定后，再评估是否开始更大范围的
     `MVP* -> V1*` 代码标识迁移

## 2026-07-01 iOS compact editor entry-row patch

- 本轮严格保持：
  - 不动 renderer / preview internals
  - 不动 export / share / photo-library 语义
  - 只做 `PhotoMemoiOSMVPTestView` 的紧凑编辑入口 UI
- 本轮新增：
  - `Source/PhotoMemo/PhotoMemo/iOS/Views/IOSCompactEntryRow.swift`
- 本轮接入：
  - `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSMVPTestView.swift`
- 实际变化：
  1. 新增可复用的 compact entry-row helpers：
     - `IOSCompactEntryListGroup`
     - `IOSCompactEntryDisclosureRow`
  2. Slot A / B / C / D 改成更接近 Apple grouped list 的 compact entry rows
  3. `Logo 标识` 与 `时间锚点` 也统一成同一套 row + disclosure 展开样式
  4. 详细编辑内容仍保留在展开区：
     - slot 文本/模块编辑
     - logo picker / 上传
     - anchor date picker
- 本轮没有做：
  - preview composition 改造
  - renderer / export 边界改动
  - 新业务状态机
- 本轮验证：
  - `git diff --check` 通过
  - `PhotoMemoiOS` build 未能作为最终通过依据：
    - 当前被已有的 `MemorySubjectEditorView.swift` Swift macro/plugin 失败阻塞
    - 失败信息指向 `SwiftUIMacros.StateMacro` / `swift-plugin-server`
    - 编译日志没有显示本轮 compact row patch 的新增错误

## 2026-07-01 iOS MVP subject/home summary extraction

- 本轮继续严格保持：
  - 不动 renderer / export / share / photo-library 语义
  - 不动 preview typography / layout 规则
  - 尽量不扩散 `PhotoMemoiOSMVPTestView` 写入范围
- 本轮新增并接入：
  - `MVPSubjectHomeSummarySupport`
  - `MVPSubjectHomeSummaryPresenterTests`
- 实际完成的变化：
  1. 把 `PhotoMemoiOSMVPTestView` 顶部原本内联的 `当前记忆对象摘要`
     投影抽成独立 presenter + support view
  2. 顶部卡片标题从更旧的 `记忆档案` 提升为更贴近 V1.0/Home 语义的
     `记忆对象`
  3. 新 summary 结构改为更稳定的 Home/Subject overview 语义：
     - 当前配置
     - 记忆对象
     - 记录身份
     - 当前时间锚点
  4. fallback 文案统一收口，避免 view 里继续散落对象/锚点缺省判断
- 本轮没有做：
  - renderer / Memory Engine / Metadata 边界改动
  - preview card 几何、字体、底栏布局调整
  - share / output / album 行为变更
- 已确认通过：
  - `git diff --check`
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- 当前已知验证说明：
  - 试图跑 `PhotoMemoTests` 的 focused test 时，命中了工作区内已有的其他
    测试编译失败（如 `MVPIOSHomeProjectionTests` / `DecorationStrategy`
    相关），不是本轮新增 summary seam 直接引入的失败
  - 本轮新增测试文件已进入同一批编译目标中，但完整 tests 目前仍受上述
    现有失败阻塞
- 这轮之后最自然的下一步：
  1. 继续把 Home 顶部其它 subject-era 文案投影，从 view 中收成 presenter
  2. 如果要继续贴近 V1.0/Home，可考虑把 `记忆对象` 顶部 facts 再和后续
     一级导航入口做更明确分层
  3. 在现有测试工作区恢复后，再补跑 focused `MVPSubjectHomeSummaryPresenterTests`

## 2026-07-01 macOS Subject area in-place promotion

- 本轮严格保持：
  - 不动 renderer
  - 不动 Memory Engine 边界
  - 不动 Export / Share / Photo Library 语义
  - 不做大结构搬家
- 本轮只在 mac `MainView` 现有结构上，把原来的 `profile` 入口往
  `Subject` 正式位置抬了一步：
  - `MainView+LayoutSections.swift`
  - `MainView+PersonalProfile.swift`
- 实际完成的变化：
  1. 左侧入口从 `我的记录` 升级为 `当前记忆对象`
  2. `MainView` 侧新增更贴近产品语义的 `subjectSection`
  3. 原来的个人档案块被整理成更正式的 Subject 总览：
     - 概览卡
     - `基本资料`
     - `时间锚点`
  4. 时间锚点没有改语义，只是前置到 Subject 区域里展示：
     - 当前锚点
     - 记忆日期
     - 现有 quick facts
     - 进入锚点管理
- 这一轮特意没有做：
  - Home / Editor / Output / Settings 一级导航改造
  - Editor 区域重排
  - Preview / renderer 相关任何改动
  - Subject 模型层替换 PersonalProfile
- 已确认通过：
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
  - `git diff --check`
- 这轮之后最自然的下一步：
  1. 继续把 Home 顶部做成真正的 Subject overview 入口语言
  2. 盘一遍 `MainView` 里还残留的 profile-era 文案与命名
  3. 再决定是否进入一级导航 `Home / Editor / Output / Settings` 的最小迁移
  4. 在此之前仍不要碰 renderer / export / share 这条冻结边界

## 2026-07-01 MVP preview-sync + editor-draft bridge follow-up

- 本轮继续严格保持：
  - 不改 UI 行为
  - 不改 renderer / export / share / photo-library 语义
  - 只做 `PhotoMemoiOSMVPTestView` 内部职责收口
- 本轮新增并接入：
  - `MVPPreviewSyncCoordinator`
  - `MVPEditorDraft`
  - `MVPContentItem`
  - `MVPDraftBridge`
  - `MVPDraftBootstrapCoordinator`
- 实际收掉的是两类还留在 view 里的胶水：
  1. preview sync orchestration
     - compose preview text
     - single-region refresh
     - all-region refresh
     - preview text load fallback
  2. draft bridge / projection glue
     - editor <-> preview draft conversion
     - editor <-> mutation draft conversion
     - item / kind mapping
     - mutation state -> local view state writeback
  3. draft bootstrap fallback
     - templateIDs projection
     - preview-draft bootstrap intent call
     - default editor-draft fallback generation
- `PhotoMemoiOSMVPTestView` 现在不再自己维护那一长串：
  - `previewDraft`
  - `mutationDraft`
  - `editorDraft`
  - `previewItem`
  - `mutationItem`
  - `editorKind` / `previewKind` / `mutationKind`
- 为了让已接入的 mutation helper 与现有测试行为对齐，这轮还顺手稳定了
  `MVPDraftMutationCoordinator` 的尾部空文本规则：
  - append text 会复用 trailing empty input
  - duplicate trailing empty input 只保留一个
  - remove composed item 后仍然会清理多余的空尾巴
- 本轮新增测试：
  - `MVPPreviewSyncCoordinatorTests`
  - `MVPDraftBridgeTests`
  - `MVPDraftBootstrapCoordinatorTests`
- 本轮重新确认通过：
  - focused macOS-hosted tests（`CODE_SIGNING_ALLOWED=NO`）：
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
  - `PhotoMemo` macOS Debug build
  - `git diff --check`
- 这轮之后更清楚的下一步是：
  1. `PhotoMemoiOSMVPTestView`
     - `bootstrapDrafts()` 的 state/writeback seam
     - preset/config activation 的 side-effect grouping
  2. `ConfigurationCenter`
     - `IOSRegionComposer` 里剩余的 local interaction state
     - detail/card 组合层的继续压薄

## 2026-07-01 ConfigurationCenter detail/composer + MVP diagnostics/module/bootstrap follow-up

- 本轮继续严格保持：
  - 不改 UI 行为
  - 不改 renderer / export / share / photo-library 语义
  - 只做 `ConfigurationCenteriOSView` / `PhotoMemoiOSMVPTestView`
    的内部职责收口
- `ConfigurationCenteriOSView` 这轮新增并接入：
  - `ConfigurationCenterDetailPresenter`
  - `ConfigurationCenterRegionComposerPresenter`
- 实际收掉的是两段还留在 view / subview 里的投影分支：
  1. detail / panel routing
     - selected panel -> detail kind
     - selected region -> active editor header / content kind
     - 保留 `.card` 仍然是不包 `IOSDetailPanel` 的现状
  2. `IOSRegionComposer` projection
     - selected configuration title fallback
     - 已生效 / 未保存 图标和文案
     - placeholder 文案
- `PhotoMemoiOSMVPTestView` 这轮新增并接入：
  - `MVPDiagnosticsRefreshCoordinator`
  - `MVPModulePanelCoordinator`
  - `MVPConfigurationBootstrapCoordinator`
- 实际收掉的是三段仍在 view 里的编排胶水：
  1. diagnostics / queue refresh
     - refresh processing state
     - repository failure fallback
     - clear history preserving current job
  2. module panel state
     - editor focus dismiss
     - sheet presented-state resolution
     - usage persistence + dismiss order on module selection
  3. bootstrap loading
     - `configurationCoordinator` success path
     - fallback `SettingsRepository` path
- 这轮还顺手移除了一个已确认死状态：
  - `selectedModule`
- 本轮新增测试：
  - `ConfigurationCenterDetailPresenterTests`
  - `ConfigurationCenterRegionComposerPresenterTests`
  - `MVPDiagnosticsRefreshCoordinatorTests`
  - `MVPModulePanelCoordinatorTests`
  - `MVPConfigurationBootstrapCoordinatorTests`
- 本轮重新确认通过：
  - focused macOS-hosted tests（`CODE_SIGNING_ALLOWED=NO`）：
    - `ConfigurationCenterDetailPresenterTests`
    - `ConfigurationCenterRegionComposerPresenterTests`
    - `MVPConfigurationBootstrapCoordinatorTests`
    - `MVPConfigurationBootstrapPresenterTests`
    - `MVPDiagnosticsRefreshCoordinatorTests`
    - `MVPModulePanelCoordinatorTests`
    - `MVPModuleLibraryPresenterTests`
    - `MVPPresetSelectionCoordinatorTests`
    - `QueueStatusMigrationTests`
  - `PhotoMemo` macOS Debug build
  - `git diff --check`
- 这轮之后更清楚的下一步是：
  1. `PhotoMemoiOSMVPTestView`
     - draft state bridge / apply extraction
     - preview refresh / bootstrap coordination
  2. `ConfigurationCenter`
     - `IOSRegionComposer` 里剩余的 local interaction state
     - 继续把 card/detail 组合层压薄

## 2026-07-01 ConfigurationCenter binding-adapter + MVP preset-routing follow-up

- 本轮继续严格保持：
  - 不改 UI 行为
  - 不改 renderer / export / share / photo-library 语义
  - 只做 `ConfigurationCenteriOSView` / `PhotoMemoiOSMVPTestView`
    的内部职责收口
- `ConfigurationCenteriOSView` 这轮新增并接入：
  - `ConfigurationCenterSessionBindingPresenter`
  - `ConfigurationCenterRegionBindingAdapter`
- 实际收掉的是两层还留在 view 里的机械编排：
  1. 直接 session 绑定桥接
     - profile title rename binding
     - storage option
     - memory-write toggle
     - memory-write text
  2. region binding / mutation glue
     - text
     - modules
     - continuation text
     - selected configuration ID
     - configuration rename state
     - insert / remove module
     - refresh preview
- 这意味着 view 不再自己区分：
  - 只是改本地 store
  - 改 store 后还要不要同步 preview/session
  - 非记忆卡 region 的模块插入是否需要 guard return
- 这轮还顺手校准了两条 Configuration Center 旧回归测试，使它们锁住真实现状而不是错误预期：
  - text + token 之间不会自动补空格
  - slotC 的配置 ID 是 `context.configuration*`
- `PhotoMemoiOSMVPTestView` 这轮新增并接入：
  - `MVPPresetSelectionCoordinator`
- 收掉的是 `selectedPresetBinding` 里原本内联的：
  - same-preset no-op
  - preset lookup
  - pending activation title
  - dirty message
  - activation confirmation flag
- 本轮新增测试：
  - `ConfigurationCenterSessionBindingPresenterTests`
  - `ConfigurationCenterRegionBindingAdapterTests`
  - `MVPPresetSelectionCoordinatorTests`
- 本轮重新确认通过：
  - focused ConfigurationCenter suite
  - focused `MVPPresetSelectionCoordinatorTests`
  - `PhotoMemo` macOS Debug build
  - `git diff --check`
- 这轮之后更清楚的下一步是：
  1. `ConfigurationCenter`：
     - selection applier
     - detail/panel routing presenter
     - `IOSRegionComposer` local projection/focus seam
  2. `PhotoMemoiOSMVPTestView`：
     - draft bridge/apply adapter
     - diagnostics refresh coordinator
     - module panel / usage persistence adapter

## 2026-07-01 MVP draft-adoption + ConfigurationCenter coordinator/policy seam

- 本轮继续严格保持：
  - 不改 UI 行为
  - 不改 renderer / export / share / photo-library 语义
  - 只做内部职责收口与测试补强
- `PhotoMemoiOSMVPTestView.swift` 这轮已经把一段真正还在 view 内的本地草稿状态机接到
  `MVPDraftMutationCoordinator`：
  - `draft(for:)`
  - update text item
  - prepend / append
  - remove
  - insert module
- 为了保证接线后 editor 不丢展示信息，`MVPDraftMutationItem` 现在补齐并保留：
  - `title`
  - `systemImage`
- `ConfigurationCenteriOSView.swift` 这轮新增并接入：
  - `ConfigurationCenterRegionEditCoordinator`
  - `ConfigurationCenterInsertableModulePolicy`
- 其中 `ConfigurationCenterRegionEditCoordinator` 收掉的是一整组重复的
  `store 写入 -> preview 重算 -> session.updateRegionPreview`
  编排逻辑，覆盖：
  - region text
  - inserted modules
  - continuation text
  - selected configuration
  - insert/remove module
  - explicit refresh preview
- `ConfigurationCenterInsertableModulePolicy` 收掉的是 view 里原本直接判断：
  - 哪些 region 显示模块面板
  - slotD 和其它 region 分别显示哪些快捷模块
  - additional modules 如何计算
- 本轮新增/补强测试：
  - `ConfigurationCenterRegionEditCoordinatorTests.swift`
  - `ConfigurationCenterInsertableModulePolicyTests.swift`
  - `MVPDraftMutationCoordinatorTests.swift` 新增 token metadata 保真覆盖
- 本轮已确认通过：
  - focused `MVPDraftMutationCoordinatorTests`
  - focused architecture suite：
    - `MVPDraftMutationCoordinatorTests`
    - `ConfigurationCenterPreviewCompositionHelperTests`
    - `ConfigurationCenterRegionDraftStoreTests`
    - `ConfigurationCenterRegionEditCoordinatorTests`
    - `ConfigurationMigrationTests`
  - focused Configuration helper suite：
    - `ConfigurationCenterInsertableModulePolicyTests`
    - `ConfigurationCenterRegionEditCoordinatorTests`
    - `ConfigurationCenterPreviewCompositionHelperTests`
    - `ConfigurationCenterRegionDraftStoreTests`
  - `git diff --check`
- 这轮之后更清楚的下一步是：
  1. 继续把 `ConfigurationCenteriOSView` 里剩余的 session binding / selection routing 收口
  2. 再回头看 `PhotoMemoiOSMVPTestView` 还留在 view 内的 queue / diagnostics / panel routing 尾巴
  3. 暂时不要碰 renderer / export / share 业务本体

## 2026-07-01 ConfigurationCenter selection/preset/compact-preview seam

- 本轮继续保持：
  - 不改 UI 外观
  - 不改 renderer / export / share 语义
  - 只做 `ConfigurationCenteriOSView` 内部职责收口
- 本轮新增并接入：
  - `ConfigurationCenterSelectionCoordinator.swift`
  - `ConfigurationCenterCompactPreviewPresenter.swift`
  - `ConfigurationCenterPresetSelectionPresenter.swift`
  - `IOSConfigurationPanel.swift`
- `ConfigurationCenterSelectionCoordinator` 现在统一了这些入口的状态跳转：
  - sidebar card routes
  - sidebar subject routes
  - sidebar write-memory / output / guide routes
  - region strip routes
  - compact preview taps
- 特意保留了 compact preview 现有非对称行为：
  - preview tap 只切 `selectedRegion`
  - 不切 `selectedPanel`
- `ConfigurationCenterCompactPreviewPresenter` 收掉的是：
  - capture summary fact 裁剪
  - badge symbol fallback
- `ConfigurationCenterPresetSelectionPresenter` 收掉的是：
  - selected preset fallback
  - preset lookup by ID
  - preset selected-state projection
- 并行补上的 `ConfigurationCenterRegionDraftStoreTests` 也已经进入主工作树，覆盖：
  - region selection 不串草稿/continuation
  - rename state 跟随 configuration ID
- 本轮已确认通过：
  - `ConfigurationCenterSelectionCoordinatorTests`
  - `ConfigurationCenterCompactPreviewPresenterTests`
  - `ConfigurationCenterPresetSelectionPresenterTests`
  - `ConfigurationCenterInsertableModulePolicyTests`
  - `ConfigurationCenterRegionEditCoordinatorTests`
  - `ConfigurationCenterPreviewCompositionHelperTests`
  - `ConfigurationCenterRegionDraftStoreTests`
  - `git diff --check`
- 现在 `ConfigurationCenteriOSView` 最值得继续收的尾巴主要只剩：
  1. session binding adapters
  2. detail/panel switching glue
  3. `IOSRegionComposer` 里与 presentation 混在一起的本地 projection / focus 行为

## 2026-06-30 MVP draft-mutation helper/test seam

- 本轮继续严格保持：
  - 不改 `PhotoMemoiOSMVPTestView.swift`
  - 不改 UI 行为
  - 不改 renderer / export / share / photo-library 语义
  - 只新增 helper / test 文件
- 本轮新增了一个纯逻辑 seam，用来锁住 MVP 本地草稿编辑态目前真实行为：
  - `Source/PhotoMemo/PhotoMemo/iOS/Views/MVPDraftMutationCoordinator.swift`
- 这个 seam 目前是 **non-adopted**：
  - 目的不是立刻替换 view
  - 而是先把 `draft(for:)` / `updateDraft(for:transform:)` /
    `insert(_:into:)` / `activeTextItemIDs` 路由 /
    dirty-state message 这些本地职责提炼成纯输入输出
  - 这样下一轮如果要把 `PhotoMemoiOSMVPTestView` 接过去，会更像机械迁移
    而不是边猜边改
- helper 里镜像了当前 view 的关键语义：
  - prepend / append 只接受非空白文本
  - composed item 插入优先走 active text item 锚点
  - active 锚点如果正好指向空 trailing text，会在它前面插入
  - trailing text normalization 会：
    - 删除重复的空尾部 text item
    - 在最后一个 item 不是 text 时补一个空 text item
  - 每次 draft mutation 都会返回 dirty region，并把 message 置成
    `有未保存修改`
- 新增 focused tests：
  - `Tests/PhotoMemoTests/ArchitectureTests/MVPDraftMutationCoordinatorTests.swift`
  - 覆盖：
    - `draft(for:)` default fallback
    - prepend
    - append
    - remove
    - insert-after-active-item
    - active empty trailing item insertion
    - trailing-text normalization
- 这轮的价值主要是：
  - 把 `PhotoMemoiOSMVPTestView` 还留在 view 内的一块高风险本地状态机
    先变成可测试、可迁移、纯逻辑的契约
  - 不会碰到当前同文件里的并行修改

## 2026-06-30 Shared-defaults typed read seam follow-up

- 本轮继续严格保持：
  - 不改 UI 行为
  - 不改 renderer / 输出图
  - 不改 Share / Export / Photo Library 语义
  - 只做 shared-defaults / bootstrap read 侧 typed seam 补强
- 本轮实际落地的是一条很窄的 additive read seam：
  1. `SharedBatchConfigurationSnapshotService`
     - 新增 typed forwards：
       - `loadAnchorsResult()`
       - `loadTemplateResult()`
       - `loadBadgeResult()`
     - 旧 `loadSnapshot()` 容错语义不变
  2. `SettingsService`
     - 新增：
       `loadMVPBootstrapReadState()`
     - 现在可以在不依赖 `@Published` 状态刷新的前提下，
       直接拿到：
       - typed badge read result
       - fresh editor-state reads
  3. `SettingsRepository`
     - `loadMVPConfigurationBootstrapState()`
       现在改走新的 typed read adapter 投影 bootstrap state
     - 但旧行为保持不变：
       - badge 缺失/损坏仍然按非 custom-logo 处理
       - 不引入新的用户可见失败路径
- 本轮新增/补强测试：
  - `SharedBatchConfigurationSnapshotServiceTests`
  - `SettingsServiceTests` typed bootstrap read coverage
- 这轮的实际价值是：
  - shared-defaults typed diagnostics 现在从 provider 提升到了 service seam
  - 以后如果要继续做 main-thread integration 或 repository diagnostics，
    不需要再先触发一次 `selectedBadge` 刷新才能拿读侧结果

## 2026-06-30 ConfigurationCenter / MVP state-projection follow-up

- 本轮继续严格保持：
  - 不改 UI 行为
  - 不改 renderer / 输出图
  - 不改 Share / Export / Photo Library 语义
  - 只做 `ConfigurationCenteriOSView` / `PhotoMemoiOSMVPTestView`
    的本地状态收口，以及一个低风险 shared-defaults typed seam
- 本轮实际落地了三条低风险收口：
  1. `ConfigurationCenter region draft store`
     - 新增：
       `ConfigurationCenterRegionDraftStore`
     - `ConfigurationCenteriOSView` 不再直接散持：
       - selected configuration IDs
       - draft texts
       - inserted modules
       - continuation texts
       - save markers
       - rename state
       - configuration option/title projection
     - view 端保留：
       - 现有 `Binding`
       - `refreshRegionPreview(...)` 触发
       - 原本的 UI 布局与交互外观
  2. `MVP bootstrap -> local UI projection`
     - 新增：
       `MVPConfigurationBootstrapPresenter`
     - `PhotoMemoiOSMVPTestView.applyBootstrapState(_:)`
       不再自己内联完整 logo / output / album bootstrap 映射
     - view 端只保留本地 UI 文案：
       `已使用自选 Logo。`
  3. `shared defaults typed read seam`
     - `BatchConfigurationSnapshotProvider` 新增：
       - `loadAnchorsResult()`
       - `loadTemplateResult()`
       - `loadBadgeResult()`
     - 旧 `loadSnapshot()` 容错语义保持不变
     - 但现在内部可以区分：
       - noValue
       - success
       - decodingFailed
- 这一轮还把 module-usage 迁移测试的 target 可见性边界收掉了：
  - `PhotoMemoiOSModuleCatalog.swift`
  - `MVPModuleUsageTracker.swift`
  现在都从 `os(iOS)` 放宽到所有非 share-extension target
  因此 `PhotoMemoTests` 在 macOS host 下也能编译这组迁移测试
- 本轮新增测试：
  - `ConfigurationCenterRegionDraftStoreTests`
  - `MVPConfigurationBootstrapPresenterTests`
  - `BatchConfigurationSnapshotProviderDiagnosticsTests`
- 本轮重新确认通过：
  - `PhotoMemoTests` focused：
    - `ModuleUsageMigrationTests`
    - `ConfigurationCenterRegionDraftStoreTests`
    - `MVPConfigurationBootstrapPresenterTests`
    - `ConfigurationMigrationTests`
  - `PhotoMemo` macOS Debug build
  - `PhotoMemoiOSMVP` generic iOS Debug build
  - `git diff --check`
- 结合今天的持续迁移，现在边界状态更明确了：
  - `ConfigurationCenteriOSView`
    已经先收掉了最值钱的一层本地草稿/configuration 状态机
    还没动的是：
    - preview composition / module resolution
    - sidebar / panel 纯投影
  - `PhotoMemoiOSMVPTestView`
    已经补上 bootstrap state presenter
    还留在 view 里的高价值尾巴主要是：
    - draft mutation + focus routing
    - logo optimization UI 收尾
    - save/export 返回后的部分本地状态拼装
  - `静默失败 / typed diagnostics`
    现在除了 shared queue snapshot / share diagnostics / external intake，
    也开始覆盖到 shared defaults bootstrap read
- 如果下一轮继续同一任务，最自然顺序是：
  1. 抽 `ConfigurationCenter` 的 preview composition / module-resolution seam
  2. 再抽 `PhotoMemoiOSMVPTestView` 的 draft/focus helper
  3. 最后补一条跨 seam 的集成回归，而不只是继续加 seam 单测

## 2026-06-30 V1 Architecture Migration Phase 2F

- 本轮继续严格保持：
  - 不改 UI 行为
  - 不改 renderer / 输出图
  - 不改 Share / Export / Photo Library 语义
  - 只做 `PhotoMemoiOSMVPTestView` 残余职责收口和静默失败/配置读取边界补强
- 本轮实际落地了三条已经抽好的 seam adoption：
  1. `Queue / Share diagnostics`
     - `PhotoMemoiOSMVPTestView` 不再自己主要持有
       headline / subheadline / symbol / tint /
       progress / pipeline / event-display 映射
     - 现在改走：
       `PhotoMemoiOSQueueDiagnosticsProjectionEngine`
     - `loadProcessingDiagnosticsSnapshot()` 现在改走：
       `LoadQueueProcessingDiagnosticsSnapshotIntent`
  2. `Preview composition`
     - `PhotoMemoiOSMVPTestView.composedText(for:)`
       现在改走：
       `ComposeMVPPreviewTextIntent`
     - token 显示值解析现在改走：
       `ResolveMVPPreviewDisplayValueIntent`
     - 默认 drafts bootstrap 现在改走：
       `BootstrapMVPPreviewDraftsIntent`
     - view 端只保留本地编辑态桥接：
       `MVPEditorDraft <-> MVPPreviewDraft`
  3. `Configuration bootstrap`
     - `bootstrapSavedSettings()` 现在无论走 coordinator 还是 fallback，
       都统一应用
       `MVPConfigurationBootstrapState`
     - fallback 不再自己重写一套 album/logo 分支判断
     - 为了维持旧 view 的 fresh-read 语义，
       `SettingsService` 新增：
       `reloadMVPBootstrapState()`
     - `SettingsRepository.loadMVPConfigurationBootstrapState()`
       现在会先刷新 badge + editor-state 再投影
- 这轮还顺手修正了两组迁移测试的“校准问题”：
  - `PreviewCompositionMigrationTests`
    现在锁住的是旧 view 的真实输出：
    - `记录iPhone 17 Pro Max`
    - `记录于2026.05.24 14:33:00`
    - `途途当天11个月28天`
  - 不是错误地假定 text-token 之间会自动插入空格
  - `ConfigurationMigrationTests`
    修正了自定义 badge 的构造参数，并锁住 automatic bootstrap
    会在 repository seam 下继续恢复成 `.automatic + "photomemo"`
- 本轮重新确认通过：
  - `PhotoMemo` macOS Debug build
  - `PhotoMemoiOSMVP` generic iOS Debug build
  - focused `PhotoMemoTests`：
    - `PreviewCompositionMigrationTests`
    - `QueueStatusProjectionEngineTests`
    - `QueueStatusMigrationTests`
    - `ExportAlbumPresenterTests`
    - `ConfigurationMigrationTests`
  - `git diff --check`
- 结合今天中午开始的迁移要求，目前比较明确的状态是：
  - `Configuration`：
    - save path 已迁
    - bootstrap read path 已迁
    - bootstrap state 应用已统一
    - 还没做的是更细的 UI state presenter 化
  - `PhotoMemoiOSMVPTestView`：
    - Queue 主要 orchestration 已迁
    - Queue/share diagnostics mapping 已迁
    - Preview session read/write 已迁
    - Preview draft/bootstrap/composition/token display 已迁
    - Export album loading / output-target branching 已迁
    - 还留在 view 里的主要是本地编辑态和 UI 驱动状态
  - `静默失败`：
    - shared queue snapshot / share diagnostics / external intake
      的 typed diagnostics seam 已补
    - 旧 convenience API 仍保留兼容层
- 如果下一轮继续同一任务，最自然顺序是：
  1. 继续清理 `PhotoMemoiOSMVPTestView` 里仍然偏业务化的本地状态拼装
     - draft mutation helpers
     - module usage persistence
     - bootstrap 后的局部 UI state 应用
  2. 评估 `ConfigurationCenteriOSView` 是否沿同样 seam 模式继续瘦身
  3. 在确认这些内部边界稳定后，再决定是否进入下一阶段的
     Apple `AppIntents` 接边

## 2026-06-30 V1 Architecture Migration Phase 2E

- 本轮继续只做 `PhotoMemoiOSMVPTestView` 的 `Export` 尾巴收口，明确没有动：
  - UI 行为
  - 输出图本身
  - Share 语义
  - Preview / Queue 剩余职责
- 新增类型：
  - `Intent/ExportAlbumIntents.swift`
    - `MVPIOSOutputTarget`
    - `MVPResolvedAlbumSelection`
    - `MVPOutputAlbumSelectionRequest`
    - `ResolveMVPOutputAlbumSelectionIntent`
- 已落地的 export branching adoption：
  - `PhotoMemoiOSMVPTestView.resolvedOutputAlbumSelection()`
    不再自己保留完整的 output target 分支判断
  - 现在优先改走：
    `ResolveMVPOutputAlbumSelectionIntent`
  - `.newAlbum` 的确保相册逻辑仍通过现有
    `EnsureExportAlbumIntent -> ExportCoordinator`
  - view 端只保留本地 UI 后处理：
    - `await loadAlbumOptions()`
    - 同步 `selectedExistingAlbumIdentifier`
- 兼容层仍保留：
  - 当没有注入 `ExportCoordinator` 时，
    `ResolveMVPOutputAlbumSelectionIntent` 仍会 fallback 到
    `PhotoLibraryExportService().ensureAlbum(...)`
  - 所以这轮不会要求其它入口一起改
- 新增测试：
  - `ExportMigrationTests`
    - 锁住 existing-album resolution
    - 锁住 existing-album 缺失时回退 automatic
    - 锁住 new-album resolution 仍通过 `ExportCoordinator`
- 本轮我重新确认通过：
  - `PhotoMemoTests/ConfigurationMigrationTests`
  - `PhotoMemoTests/ExportMigrationTests`
  - `PhotoMemo` macOS Debug build
  - `PhotoMemoiOSMVP` generic iOS Debug build
  - `git diff --check`
- 当前结论：
  - export output-target branching 已经不再主要由 view 持有
  - 但 album picker 的 loading / status message 投影仍在 view 内
  - 如果下一轮继续只做 export，最自然的顺序是：
    1. 把 `loadAlbumOptions()` / `applyLoadedAlbumOptions(_:)` 抽成 presenter
    2. 再评估是否去掉新 intent 内的 direct service fallback

## 2026-06-30 V1 Architecture Migration Phase 2D

- 本轮补齐了 `PhotoMemoiOSMVPTestView.applyCurrentMVPConfiguration()` 的
  view adoption，明确没有动：
  - UI 行为
  - renderer / output image
  - Share / Export / Photo Library 语义
- 新增类型：
  - `Intent/ConfigurationSaveIntents.swift`
    - `MVPConfigurationSaveRequest`
    - `MVPConfigurationSaveReceipt`
    - `SaveMVPConfigurationIntent`
- configuration 基础设施补强：
  - `ConfigurationCoordinator` 新增：
    - `saveMVPConfiguration(...)`
  - `SettingsRepository` 新增：
    - `saveSelectedTemplate(...)`
    - `saveSelectedBadge(...)`
    - `savePhotoDescriptionSettings(...)`
    - `saveEditorState(...)`
  - `ConfigurationRepository` 新增：
    - `upsertBirthdayAnchor(...)`
- 已落地的 MVP view adoption：
  - `PhotoMemoiOSMVPTestView` 现在接收
    `configurationCoordinator`
  - `applyCurrentMVPConfiguration()` 现在优先改走：
    `SaveMVPConfigurationIntent -> ConfigurationCoordinator`
  - 没注入 coordinator 时，仍保留原来的 `SettingsService()` fallback
  - `session.applySelectedMemoryPreset()` 继续留在 view 层，
    因为它仍然是本地 session 状态同步
- 依赖注入路径已补齐：
  - `PhotoMemoiOSTemporaryEntryView`
  - `PhotoMemoiOSMVPTestView #Preview`
- 新增测试：
  - `ConfigurationMigrationTests`
    - 锁住 template / badge / photo description / editor state 的保存
    - 锁住 automatic album normalization
    - 锁住 birthday anchor 的 in-place upsert + `isCountdown = false`
- 本轮我重新确认通过：
  - `PhotoMemoTests/ConfigurationMigrationTests`
  - `PhotoMemo` macOS Debug build
  - `PhotoMemoiOSMVP` generic iOS Debug build
  - `git diff --check`
- 当前结论：
  - `applyCurrentMVPConfiguration()` 最大块的保存职责已经迁出 view
  - 但 preview 文字拼装、queue diagnostics 映射、album loading presenter
    仍然还在 view 内

## 2026-06-30 V1 Architecture Migration Phase 2C

- 本轮只迁移了 `PhotoMemoiOSMVPTestView` 的 `Export` 相关职责，明确没有动：
  - UI 行为
  - 输出图本身
  - Share / Queue / Preview 已稳定部分
  - 配置保存、时间锚点、badge 等非 export 逻辑
- 新增类型：
  - `Intent/ExportAlbumIntents.swift`
    - `LoadExportAlbumOptionsIntent`
    - `EnsureExportAlbumIntent`
- export 基础设施补强：
  - `PhotoLibraryExportService` 现在实现了 `PhotoLibraryExporting`
  - `PhotoLibraryRepository` 新增：
    - `fetchAlbumOptions()`
    - `ensureAlbum(named:)`
  - `ExportCoordinator` 新增：
    - `fetchAlbumOptions()`
    - `ensureAlbum(named:)`
- 已落地的 MVP view adoption：
  - `PhotoMemoiOSMVPTestView.loadAlbumOptions()`
    不再优先直接 new `PhotoLibraryExportService`
    现在优先改走：
    `LoadExportAlbumOptionsIntent -> ExportCoordinator`
  - `PhotoMemoiOSMVPTestView.resolvedOutputAlbumSelection()`
    在 `.newAlbum` 分支里不再优先直接
    `PhotoLibraryExportService.ensureAlbum(...)`
    现在优先改走：
    `EnsureExportAlbumIntent -> ExportCoordinator`
- 依赖注入路径已补齐：
  - `PhotoMemoiOSTemporaryEntryView`
    现在会把现有 `runtime.environment.coordinators.export` 传进
    `PhotoMemoiOSMVPTestView`
- 兼容层仍保留：
  - `PhotoMemoiOSMVPTestView` 在没有注入 export coordinator 时，
    仍会 fallback 到原来的 `PhotoLibraryExportService` 直接路径
  - 所以这轮不会要求其它入口一起修改
- 新增测试：
  - `ExportMigrationTests`
    - 锁住 album options 读取会通过 `ExportCoordinator`
    - 锁住 ensure album 会通过 `ExportCoordinator`
  - 为了让这组测试不碰真实 Photos 权限，这轮引入了
    `PhotoLibraryExporting` 协议并用 stub service 验证 repository/coordinator
    包装层
- 本轮我重新确认通过：
  - `PhotoMemoTests/ExportMigrationTests`
  - `PhotoMemoTests/PreviewMigrationTests`
  - `PhotoMemoTests/QueueStatusMigrationTests`
  - `PhotoMemoTests/ArchitectureMigrationFoundationTests`
  - `PhotoMemo` macOS Debug build
  - `PhotoMemoiOSMVP` generic iOS Debug build
  - `git diff --check`
- 当前结论：
  - 这轮可以视为 `PhotoMemoiOSMVPTestView` 的 `Export` 第一刀迁移已落地
  - 但还不是完整 export 解耦，因为：
    - output target 的 branching 仍留在 view 内
    - `applyCurrentMVPConfiguration()` 里的设置保存仍留在 view / settings 路径
  - 如果下一轮继续只做 export，最自然的顺序是：
    1. 把 output target -> resolved album selection 的 branching 抽成 export intent
    2. 再决定是否把“保存当前 MVP 配置”里与输出目标相关的部分从 view 中分离

## 2026-06-30 V1 Architecture Migration Phase 2B

- 本轮只迁移了 `PhotoMemoiOSMVPTestView` 的 `Preview` 相关职责，明确没有动：
  - UI 行为
  - 输出图
  - Share / Export / Photo Library 语义
  - Queue 之外已经迁稳的其它链路
- 新增类型：
  - `Intent/MVPPreviewIntents.swift`
    - `UpdateRegionPreviewIntent`
    - `UpdateRegionPreviewsIntent`
    - `LoadRegionPreviewTextIntent`
- 已补上的架构入口：
  1. `PreviewCoordinator.updateRegionPreview(...)`
  2. `PreviewCoordinator.updateRegionPreviews(...)`
  3. `PreviewCoordinator.previewText(...)`
- 已落地的 MVP view adoption：
  - `PhotoMemoiOSMVPTestView.refreshPreview(for:)`
    不再优先直接 `session.updateRegionPreview(...)`
    现在优先改走：
    `UpdateRegionPreviewIntent -> PreviewCoordinator`
  - `PhotoMemoiOSMVPTestView.refreshDynamicPreview()`
    现在优先改走：
    `UpdateRegionPreviewsIntent -> PreviewCoordinator`
  - `PhotoMemoiOSMVPTestView.previewText(for:)`
    现在优先改走：
    `LoadRegionPreviewTextIntent -> PreviewCoordinator`
- 依赖注入路径已补齐：
  - `PhotoMemoiOSTemporaryEntryView`
    现在会把现有 `runtime.environment.coordinators.preview` 传进
    `PhotoMemoiOSMVPTestView`
- 兼容层仍保留：
  - `PhotoMemoiOSMVPTestView` 在没有注入 preview coordinator 时，
    仍会 fallback 到原来的 `session` 直接读写路径
  - 所以这轮不会要求其它调用点一起修改
- 新增测试：
  - `PreviewMigrationTests`
    - 锁住单区域 preview sync 会通过 `PreviewCoordinator` 写回 session
    - 锁住多区域 sync 后，preview load intent 读回的文本保持不变
- 本轮我重新确认通过：
  - `PhotoMemoTests/PreviewMigrationTests`
  - `PhotoMemoTests/QueueStatusMigrationTests`
  - `PhotoMemoTests/ArchitectureMigrationFoundationTests`
  - `PhotoMemo` macOS Debug build
  - `PhotoMemoiOSMVP` generic iOS Debug build
  - `git diff --check`
- 当前结论：
  - 这轮可以视为 `PhotoMemoiOSMVPTestView` 的 `Preview` 第一刀迁移已落地
  - 但还不是完整 preview 解耦，因为：
    - draft -> composed text 的拼装仍留在 view 内
    - module/token 显示值解析仍留在 view 内
  - 如果下一轮继续只做 preview，最自然的顺序是：
    1. 把 draft -> preview text 的组装从 view 搬到 preview service/coordinator
    2. 再决定是否把默认 draft 生成与 preview bootstrap 分离

## 2026-06-30 V1 Architecture Migration Phase 2A

- 本轮只迁移了 `PhotoMemoiOSMVPTestView` 的 `Queue` 相关职责，明确没有动：
  - UI 行为
  - 输出图
  - Share / Export / Photo Library 语义
  - 其它 Preview / Preset / Logo / Album 逻辑
- 新增类型：
  - `Intent/QueueStatusIntents.swift`
    - `RefreshQueueProcessingStatusIntent`
    - `ClearCompletedQueueHistoryIntent`
- 已补上的架构入口：
  1. `DiagnosticsRepository.loadProcessingDiagnosticsSnapshot()`
     - 收口 MVP 视图对 processing diagnostics snapshot 的直接读取
  2. `QueueRepository.clearCompletedHistory(...)`
  3. `QueueCoordinator.clearCompletedHistory(...)`
- 已落地的 MVP view adoption：
  - `PhotoMemoiOSMVPTestView.refreshProcessingState()`
    不再只靠 view 自己串
    `refreshExternalIntake + PhotoMemoiOSProcessingDiagnosticsSnapshot.load()`
  - 现在优先改走：
    `RefreshQueueProcessingStatusIntent -> DiagnosticsRepository`
  - “清除历史”按钮不再直接调
    `backgroundStatusService.clearCompletedHistory()`
  - 现在优先改走：
    `ClearCompletedQueueHistoryIntent -> QueueCoordinator`
- 依赖注入路径已补齐：
  - `PhotoMemoRootSceneView`
  - `PhotoMemoiOSTemporaryEntryView`
  现在会把现有 `runtime.environment` 里的 queue / diagnostics 依赖传进
  `PhotoMemoiOSMVPTestView`
- 兼容层仍保留：
  - `PhotoMemoiOSMVPTestView` 在没有注入 queue / diagnostics 依赖时，
    仍会 fallback 到原来的直接读取/直接调用路径
  - 这样 Preview 和其它非迁移入口不需要一起被改
- 新增测试：
  - `QueueStatusMigrationTests`
    - 锁住 queue status refresh intent 会先执行 intake refresh，再读 diagnostics
    - 锁住 clear history intent 会通过 queue coordinator 清理已完成 external jobs
- 本轮我重新确认通过：
  - `PhotoMemoTests/QueueStatusMigrationTests`
  - `PhotoMemoTests/ArchitectureMigrationFoundationTests`
  - `PhotoMemo` macOS Debug build
  - `PhotoMemoiOSMVP` generic iOS Debug build
  - `git diff --check`
- 当前结论：
  - 这轮可以视为 `PhotoMemoiOSMVPTestView` 的 `Queue` 第一刀迁移已落地
  - 但还不是完整 queue 解耦，因为：
    - live queue display 仍然直接依赖 `PhotoMemoBackgroundStatusService`
    - share diagnostics 的标题/文案计算仍然留在 view 内
  - 如果下一轮继续只做 queue，最自然的顺序是：
    1. 把 `PhotoMemoBackgroundStatusService.currentSnapshot` 的展示适配再抽一层
    2. 再把 share/queue diagnostics 的展示文案从 view 中搬到 presenter/service

## 2026-06-30 V1 Architecture Migration Phase 2

- 本轮完成了 V1 / MVP `Share Workflow` 的第二阶段迁移，但仍严格守住边界：
  - 不改 UI 行为
  - 不改输出图
  - 不改 Share / Export / Photo Library 语义
  - 不删除旧接口
- 新增类型：
  - `Intent/ShareWorkflowIntents.swift`
    - `ProcessedShareRequest`
    - `ProcessShareIntent`
    - `ImportBatchPhotoIntent`
  - `Repositories/PhotoLibraryRepository.swift`
- 已落地的 adoption：
  1. app 侧 share drain
     - `PhotoMemoAppRuntime.flushExternalRequests()` 不再直接
       `batchQueueStore.enqueue(...)`
     - 现在改走：
       `ProcessShareIntent -> ShareCoordinator.process(...) -> QueueRepository`
  2. queued task processing
     - `BatchQueueExecution.processTask(...)` 继续保留旧状态机壳
     - 但内部四步业务调用已经迁到：
       - `ImportBatchPhotoIntent`
       - `BuildPreviewIntent`
       - `ExportRecordCardIntent`
       - `SaveRenderedPhotoIntent`
  3. photo-library save boundary
     - `ExportCoordinator` 现在通过 `PhotoLibraryRepository` 写回图库
- 这轮特意保留未删的兼容层：
  - `PhotoMemoAppRuntime.flushExternalRequests()`
  - `ExternalPhotoIntakeCenter.submit(...)`
  - `ExternalPhotoIntakeCenter.drainPendingRequests()`
  - `BatchQueueStore.enqueue(urls:...)`
  - `BatchQueueStore.enqueue(payloads:configuration:...)`
  - `BatchQueueExecution.processTask(at:in:)`
  - `BatchProcessingCoordinator.importPhoto/buildCard/exportCard/saveRenderedPhoto`
- 新增/更新测试：
  - `ShareDrainMigrationRegressionTests`
    - 锁住 `SubmitExternalURLsIntent` 的配置刷新 + 支持类型/去重语义
    - 锁住 drained request 入队后的 `launchSource` / snapshot / summary /
      payload metadata 不变
    - 锁住 `ProcessShareIntent` 新通路不改 share request 语义
- 本轮我重新确认通过：
  - `PhotoMemoTests/ShareDrainMigrationRegressionTests`
  - `PhotoMemoTests/ArchitectureMigrationFoundationTests`
  - `PhotoMemoTests/BatchFixtureCoverageTests`
  - `PhotoMemo` macOS Debug build
  - `PhotoMemoiOSMVP` generic iOS Debug build
- 一处本轮中途已修掉的问题：
  - `PhotoLibraryRepository` 兼容 `String` / `String?` album identifier 的
    overload 一开始写成了自递归调用
  - 现已改成显式走 optional 版本
- 仍需单独补一次确认：
  - `PhotoMemoShareExtension` generic iOS Debug build
  - 原因不是明确编译报错，而是一次撞上 derived-data `build.db` lock，
    另一次 `-quiet` rerun 没有在本轮里返回一个干净的结束信号，所以不要
    假设它已经确认通过
- 当前结论：
  - Phase 1 基础设施 + Phase 2 Share Workflow adoption 现在都已落地
  - 下一轮如果继续，不该再回头重写这层，而是：
    1. 单独补上 share extension build 确认
    2. 再决定是否进入更深的 error/result adoption，或者开始更大范围地
       清理 legacy direct-call 路径

## 2026-06-30 V1 Architecture Migration Phase 1

- 本轮按“只做基础设施、不改行为”的边界完成了 V1 / MVP 第一阶段架构迁移：
  - 不改 UI 行为
  - 不改输出图
  - 不改 Share / Export / Photo Library 语义
- 已新增完整的迁移骨架：
  - `Architecture/PhotoMemoResult.swift`
  - `Intent/PhotoMemoIntent.swift`
  - `Intent/BuildPreviewIntent.swift`
  - `Intent/AppFlowIntents.swift`
  - `Coordinators/ShareCoordinator.swift`
  - `Coordinators/QueueCoordinator.swift`
  - `Coordinators/PreviewCoordinator.swift`
  - `Coordinators/ExportCoordinator.swift`
  - `Coordinators/ConfigurationCoordinator.swift`
  - `Repositories/SettingsRepository.swift`
  - `Repositories/QueueRepository.swift`
  - `Repositories/DiagnosticsRepository.swift`
  - `Repositories/PhotoRepository.swift`
  - `Repositories/ConfigurationRepository.swift`
  - `Architecture/AppEnvironment.swift`
- 已对接的现有入口：
  - `PhotoMemoAppRuntime` 现在支持通过 `AppEnvironment` 注入
  - `ExternalPhotoIntakeCenter` 新增注入式 init，但保留原有零参行为
  - `BatchProcessingCoordinator` 新增注入式 init，但保留原有零参行为
- 本轮实际发现并修掉的一个直接问题：
  - `Intent/BuildPreviewIntent.swift` 最初只把首个 intent 放进
    `#if !PHOTOMEMO_SHARE_EXTENSION`
  - 导致 `PhotoMemoiOSMVP` 构建时，share extension target 会看到
    `ExportCoordinator` / `ConfigurationCoordinator` 等 app-only 类型并编译失败
  - 现已把整个文件都收进 guard，恢复 target 边界
- 新增验证：
  - `Tests/PhotoMemoTests/ArchitectureTests/ArchitectureMigrationFoundationTests.swift`
  - 锁住两件事：
    1. `PhotoMemoResult.map` 的 success/failure 语义
    2. `BuildPreviewIntent` 通过 `AppEnvironment.live(...)` 执行后，不改变
       `RecordCardBuildService` 的 card 输出
- 本轮我亲自重新跑过的验证：
  - `PhotoMemo` macOS Debug build
  - `PhotoMemoiOSMVP` generic iOS Debug build
  - `PhotoMemoTests/ArchitectureMigrationFoundationTests`
  - `PhotoMemoTests/RecordCardBuildServiceTests`
  - `PhotoMemoTests/ClassicWhiteSnapshotTests`
- 结论要点：
  - 架构迁移层当前已经能编译、能通过新增基础测试
  - 这轮 Phase 1 可以视为“基础设施完成”
  - 但“全面采用新链路”还没做，后续仍需要继续把高价值路径逐步迁到
    `View -> Intent -> Coordinator -> Repository`
- 两个旧的基线失败项，本轮再次单独复现，确认不是这次迁移引入：
  1. `RecordCardBuildServiceTests.buildsTemplate1WithProfileRelationshipAndBabyAgePhrasing`
     - 期望：`拍摄于2026.04.11 10:13:05`
     - 实际：`记录于2026.04.11 10:13:05`
  2. `ClassicWhiteSnapshotTests.landscapeStandardSnapshotStaysStable`
     - mismatch: `93 / 768000` pixels
     - `maxChannelDelta = 212`
- 已补充正式报告：
  - `Docs/ArchitectureMigrationReport.md`
  - 里面包含：
    - 当前完成内容
    - 所有新增类型说明
    - 后续迁移建议
    - 已知验证阻塞
    - Phase 1 与后续 adoption 的边界
  - 下一窗口如果要继续，最合适的顺序是：
    1. 先决定怎么处理上面两个旧失败项
    2. 再开始把真正的高频主链路迁到 intent/coordinator 入口
    3. 不要把 adoption 和大文件拆分、UI 改造、renderer 重写混在同一轮

## 2026-06-30 Additional Hot-Path Performance Follow-Up

- 本轮继续严格沿“提速但不改功能”的边界推进：
  - 不改 UI
  - 不改输出图
  - 不改 Share / Export / Photo Library / 通知内容语义
- 已落实 4 个很小但直接命中热路径的优化：
  1. `BatchQueueExecution` 成功链路里，移除了 4 个空转的 progress
     notification await
     - RAW 准备完成
     - metadata 完成
     - rendering 开始
     - 写入系统图库开始
     - 这些调用当前本来就是 no-op，所以去掉后只减少 async hop /
       job lookup，不改变任何通知结果
  2. `BatchQueueHistory.trimTerminalJobHistoryIfNeeded(...)` 增加了超便宜
     的早退
     - 当总 job 数已经 `<= 120` 时，直接返回
     - 避免每次 `persistJobs()` 前都无意义全表扫描
  3. `PhotoMetadataReader` 新增 data-backed 读取：
     - `properties(from data: Data)`
     - `read(from data: Data)`
  4. `PhotoImportService.importPhoto(from data: ...)` 现在会在 data 输入路径里
     复用一次 data-backed `CGImageSource`
     - 既用于 metadata properties
     - 也用于 display image
     - 这样 share/data 型导入不再必须“先写临时文件，再立刻从磁盘重新打开同一份内容”
  5. `TemplateVariableEngine.render(...)` 对不含 `{{` 的纯文本模板直接早退
     - 跳过 placeholder 扫描
- 新增测试：
  - `BatchQueueHistoryTests`
  - `TemplateVariableEngineTests`
  - `PhotoMetadataReaderTests`
  - `PhotoImportServiceTests`
- 本轮我亲自重新跑过的验证：
  - `BatchQueueHistoryTests`
  - `BatchQueueStorePersistenceTests`
  - `BatchQueueRecoveryTests`
  - `TemplateVariableEngineTests`
  - `RecordCardBuildServiceTests`
  - `git diff --check`
  - `PhotoMemo` macOS Debug build
  - `PhotoMemoiOSMVP` generic iOS Debug build
- 另外并行 agent 已验证通过：
  - `PhotoMetadataReaderTests`
  - `PhotoImportServiceTests`
- 额外说明：
  - `RecordCardBuildServiceTests` 首次在并发测试时出现过一次失败，但单独串行复跑已通过，判断不是这轮提速改动引入的问题，更像是并发测试/结果包噪音。
- 当前最值得继续、但尚未落地的下一刀：
  1. `.inAppPreview` 的 start/final notification 路径前移短路
     - 当前逻辑最终也不会发通知
     - 但仍会走一层 start/final 的调度或 async 路径
     - 这一步比本轮更靠近状态语义，建议下一轮单独做并补一组 routing 测试

## 2026-06-30 Photo Import ImageSource Reuse

- 本轮继续沿“提速但不改功能”的同一条线推进：
  - 不改 UI
  - 不改输出图
  - 不改 Share / Export / Photo Library 语义
- 已落实：
  - `PhotoMetadataReader` 新增 `properties(from source: CGImageSource)`。
  - `PhotoImportService` 在单次导入里会先创建一次 `CGImageSource`，然后复用给：
    - metadata properties 读取
    - ImageIO display image 生成
  - 也就是说，普通图片导入不再为了 metadata 和预览图各自重新打开一次 source。
- 实际收益：
  - 单张导入主路径减少了一次重复的 `CGImageSourceCreateWithURL` 和对应的源文件解析。
  - 这条优化命中每次照片导入，属于单张处理热路径，比前两轮更接近“每张都能吃到”的收益。
- 新增测试：
  - `PhotoMetadataReaderTests`
    - 新增 “reads properties from an existing image source”
- 已验证：
  - `PhotoMetadataReaderTests` 通过。
  - `PhotoImportServiceTests` 通过。
  - `git diff --check` 通过。
  - `PhotoMemo` macOS Debug build 通过。
  - `PhotoMemoiOSMVP` generic iOS Debug build 通过。
- 特意未改：
  - metadata 解析规则
  - RAW fallback 语义
  - output/export/save-to-library 行为
  - diagnostics / queue / notification 规则
- 下一轮如果继续只盯速度，最值得优先看的位置：
  1. `PhotoImportService` 的 RAW 路径是否还存在可安全复用的 decode/source
  2. `BatchQueuePersistence.persistJobs(...)` 的同步策略是否能继续细分
  3. `RecordCardBuildService` / token resolver 是否有重复计算热点

## 2026-06-30 Batch Queue Persistence Write Reduction Follow-Up

- 本轮继续沿“速度优先、功能不动”的同一条线推进：
  - 不改 UI
  - 不改输出结果
  - 不改用户可见工作流
- 已落实：
  - `BatchQueueExecution` 的 `metadataReady` 现在也改成 deferred persist。
  - 也就是：
    - `metadataReady`
    - `previewReady`
    两个连续中间态都只先更新内存，等到 `exporting` 再统一写回。
- 实际收益更新：
  - 单张任务成功链路的队列持久化写入，现在从最初的 7 次降到了 4 次。
  - 累计每张成功照片少了 3 次 `JSONEncoder + UserDefaults.set + synchronize`。
  - 这仍然不改变最终任务状态、通知、输出图、写回图库语义。
- 新增测试：
  - `BatchQueueStorePersistenceTests`
    - 新增 “multiple deferred task updates flush the latest state once”
- 已验证：
  - `BatchQueueStorePersistenceTests` 通过。
  - `BatchQueueRecoveryTests` 通过。
  - `PhotoMemo` macOS Debug build 通过。
  - `PhotoMemoiOSMVP` generic iOS Debug build 通过。
- 特意未改：
  - Renderer / Export / Photo Library / Share Extension 行为
  - 队列 JSON 格式
  - 恢复、重试、通知规则
- 下一轮如果继续提速，最值得优先排查的是：
  1. `PhotoImportService` 是否存在可复用的 metadata/image 读取路径
  2. `BatchQueuePersistence.persistJobs(...)` 是否需要更细粒度节流
     - 但这一步比当前更敏感，必须先补更多 shared-state / resume 测试

## 2026-06-30 Batch Queue Persistence Write Reduction

- 本轮目标收紧为：
  - 不动当前 UI
  - 不动输出内容与导出结果
  - 不改用户可见功能路径
  - 只做共享队列热路径里的低风险提速
- 已落实：
  - `BatchQueueStore.updateTask(...)` 新增 `persist` 开关，允许个别阶段先只更新内存，再在下一次稳定状态统一落盘。
  - `BatchQueueExecution` 的 `previewReady -> exporting` 之间，不再做中间那次持久化写入。
  - 成功路径完成后，移除了重复的 `store.persistJobs()`。
- 实际收益：
  - 单张任务成功链路里，队列持久化写入从原来的 7 次降到 5 次。
  - 也就是每张成功照片少了 2 次 `JSONEncoder + UserDefaults.set + synchronize`。
  - 这条优化只命中热路径，不改变最终任务状态、通知、输出图、写回图库语义。
- 新增测试：
  - `BatchQueueStorePersistenceTests`
    - 锁住“deferred task update 不会立即重写 persisted jobs，直到显式 flush”为止
- 已验证：
  - `BatchQueueStorePersistenceTests` 通过。
  - `BatchQueueRecoveryTests` 通过。
  - `git diff --check` 通过。
  - `PhotoMemo` macOS Debug build 通过。
  - `PhotoMemoiOSMVP` generic iOS Debug build 通过。
- 特意未改：
  - Renderer / Export / Photo Library 行为
  - Share Extension 行为
  - 队列 JSON 存储格式
  - 失败恢复与 resume 语义
- 下一轮如果继续沿“速度但不改功能”这条线，最值得看的位置：
  1. `metadataReady` 之后是否还存在可安全合并的同步落盘点
  2. `BatchQueuePersistence.persistJobs(...)` 是否需要更细粒度的写入节流，但这一步风险更高，必须先补更多恢复/共享状态测试
  3. `PhotoImportService` 的 metadata/image 双次读取是否能做纯内部复用
     - 这一条收益可能更大，但也比本轮风险高得多
## 2026-06-30 External Intake Persistence Diagnostics Consumption

- 本轮继续做“稳定优先的精简拆分”，第五刀仍然严格保持边界：
  - 不做 UI 重设计
  - 不做 Renderer / Export 逻辑重写
  - 不改预期输出结果
- 已落实：
  - `ExternalPhotoIntakeStore` 新增 typed `loadRequestsResult()`。
  - 外部接单持久化现在内部可区分：
    - 没有接单记录
    - 接单记录正常解码
    - 接单记录损坏 / 不可读
  - 同时保留原本兼容语义：
    - `loadRequests()` 在缺失 / 损坏时仍返回 `[]`
  - `PhotoMemoiOSProcessingDiagnosticsSnapshot` 现在除了 share diagnostics、
    shared queue snapshot 之外，也一起消费 external intake persisted state。
  - 因此 iOS MVP `处理进度` 卡片的 warning 现在可以覆盖三类共享持久化损坏：
    - 共享进度记录
    - 共享队列快照
    - 共享接单记录
- 新增测试：
  - `ExternalPhotoIntakeStoreDiagnosticsTests`
    - 补充 empty vs corrupted persisted requests 区分
  - `PhotoMemoiOSProcessingDiagnosticsSnapshotTests`
    - 补充 corrupted external intake payload surfaced
- 已验证：
  - 聚焦测试通过：
    - `ExternalPhotoIntakeStoreDiagnosticsTests`
    - `PhotoMemoiOSProcessingDiagnosticsSnapshotTests`
  - `git diff --check` 通过。
  - `PhotoMemo` macOS Debug build 通过。
  - `PhotoMemoiOSMVP` generic iOS Debug build 通过。
  - `PhotoMemoShareExtension` generic iOS Debug build 通过。
- 特意未改：
  - 接单成功/失败语义
  - Share handoff / queue execution / export / Photo Library 行为
  - persisted external intake request 的 JSON 格式
- 这一步的真实意义：
  - 又拿下一处真实主链路里的“静默坏状态”。
  - 现在如果共享接单记录损坏，主程序仍然安全回退，但不再完全不可见。
  - 给后面继续做 `SettingsService`、或者开始从 `PhotoMemoiOSMVPTestView`
    里抽更独立的 processing/share coordinator helper，提供了更稳的地基。

## 2026-06-30 MVP Processing Diagnostics Snapshot Consumption

- 本轮继续做“稳定优先的精简拆分”，第四刀仍然严格保持边界：
  - 不做 UI 重设计
  - 不做 Renderer / Export 逻辑重写
  - 不改预期输出结果
- 已落实：
  - 新增 `PhotoMemoiOSProcessingDiagnosticsSnapshot`。
  - 这层是一个很薄的 shared-defaults 适配器，统一消费：
    - `PhotoMemoShareDiagnostics.loadEventsResult(...)`
    - `SharedBatchQueueSnapshotService.loadJobsResult()`
  - 现在 iOS MVP `处理进度` 面板内部可以区分：
    - 共享诊断为空
    - 共享诊断可读
    - 共享诊断损坏
    - 共享队列为空
    - 共享队列可读
    - 共享队列损坏
  - `PhotoMemoiOSMVPTestView` 刷新处理进度时，不再只把 shared defaults
    读成“空数组”，而是先经过这层 typed snapshot。
  - 当共享进度记录或共享队列快照损坏时，MVP `处理进度` 卡片现在会显示
    一个轻量 warning，但仍保持原来的安全回退：
    - 不崩溃
    - 不改变处理流程
    - 继续按空状态运行
- 新增测试：
  - `PhotoMemoiOSProcessingDiagnosticsSnapshotTests`
  - 覆盖：
    - empty vs corrupted combined state
    - diagnostics 可读但 queue payload 损坏时，事件仍保留
- 已验证：
  - 聚焦测试通过：
    - `PhotoMemoiOSProcessingDiagnosticsSnapshotTests`
    - `PhotoMemoShareDiagnosticsTests`
    - `SharedBatchQueueSnapshotServiceTests`
  - `git diff --check` 通过。
  - `PhotoMemo` macOS Debug build 通过。
  - `PhotoMemoiOSMVP` generic iOS Debug build 通过。
- 特意未改：
  - Share / Queue / Export 的真实执行语义
  - Renderer、底部边框、布局、Photo Library 保存行为
  - shared defaults 持久化格式
- 这一步的真实意义：
  - 终于把“共享记录损坏”和“真的还没有任何记录”在一个真实 UI caller
    上分开了。
  - 后面继续做 Settings / External Intake 的静默失败收口，或者开始从 MVP
    大文件里抽更薄的 coordinator/helper，会更稳。

## 2026-06-30 Shared Persistence Result Foundation

- 本轮继续做“稳定优先的精简拆分”，第三刀仍然严格保持边界：
  - 不做 UI 重设计
  - 不做 Renderer / Export 逻辑重写
  - 不改预期输出结果
- 已落实：
  - 新增共享持久化结果模型：
    - `PhotoMemoSharedDefaultsReadResult`
    - `PhotoMemoSharedDefaultsWriteResult`
    - 对应 failure payload
  - `SharedBatchQueueSnapshotService` 现在内部可区分：
    - 没有持久化队列数据
    - 队列数据正常解码
    - 队列数据损坏/不可读
  - `PhotoMemoShareDiagnostics` 现在内部可区分：
    - 没有持久化诊断数据
    - 诊断数据正常解码
    - 诊断数据损坏
    - 诊断事件编码失败
  - 同时保留原本对外兼容语义：
    - `loadJobs()` 仍在缺失/损坏时返回空数组
    - `loadEvents()` 仍在缺失/损坏时返回空数组
    - `record(...)` 仍然不抛错，不改变现有产品流程
- 新增测试：
  - `SharedBatchQueueSnapshotServiceTests` 补充 empty vs corrupted 区分
  - `PhotoMemoShareDiagnosticsTests` 补充：
    - empty vs corrupted 区分
    - diagnostics 编码失败 surfaced 结果
- 已验证：
  - 聚焦测试通过。
  - `PhotoMemo` macOS Debug build 通过。
  - `PhotoMemoiOS` generic iOS Debug build 通过。
  - `PhotoMemoiOSMVP` generic iOS Debug build 通过。
  - `PhotoMemoShareExtension` generic iOS Debug build 通过。
  - `PhotoMemoTests` 全套仍只有仓库里已知的两处旧失败：
    - `ClassicWhiteSnapshotTests.landscapeStandardSnapshotStaysStable`
    - `RecordCardBuildServiceTests.buildsTemplate1WithProfileRelationshipAndBabyAgePhrasing`
- 特意未改：
  - diagnostics UI 呈现逻辑
  - Share / Queue / Export 的实际处理行为
  - Renderer、底部边框、布局、写回图库语义
- 这一步的真实意义：
  - 先把“空状态”和“持久化损坏”从内部语义上分开。
  - 给后续继续改静默失败、补诊断可见性、拆大 View / Coordinator 提供稳定基础，
    但不提前改动用户路径。

## 2026-06-30 Typed Share Diagnostics Stage Foundation

- 本轮继续做“稳定优先的精简拆分”，第二刀仍然严格保持边界：
  - 不做 UI 重设计
  - 不做 Renderer / Export 逻辑重写
  - 不改预期输出结果
- 已落实：
  - 新增 `PhotoMemoShareDiagnosticStage`，采用 typed wrapper + raw string
    兼容方案。
  - `PhotoMemoShareDiagnosticEvent` 现在对外暴露 typed `stage`，但持久化
    时仍写回原来的 `"stage": "..."` 字符串格式。
  - `PhotoMemoRootSceneView`、`PhotoMemoAppRuntime`、
    `PhotoMemoiOSLiveActivityDriverService`、
    `PhotoMemoShareExtensionViewController`、
    `PhotoMemoShareExtensionIntakeService`、
    `PhotoMemoiOSMVPTestView` 已从 share diagnostics 的裸字符串比较迁移到
    typed stage 常量。
- 新增测试：
  - `PhotoMemoShareDiagnosticsTests`
  - 覆盖：
    - 已知 stage raw value 映射
    - 未知/历史 stage 保持 round-trip
    - 旧持久化 JSON 事件解码兼容
- 已验证：
  - 新测试通过。
  - `PhotoMemo` macOS Debug build 通过。
  - `PhotoMemoiOS` generic iOS Debug build 通过。
  - `PhotoMemoiOSMVP` generic iOS Debug build 通过。
  - `PhotoMemoShareExtension` generic iOS Debug build 通过。
  - `PhotoMemoTests` 全套仍只有仓库里已知的两处旧失败：
    - `ClassicWhiteSnapshotTests.landscapeStandardSnapshotStaysStable`
    - `RecordCardBuildServiceTests.buildsTemplate1WithProfileRelationshipAndBabyAgePhrasing`
- 特意未改：
  - Share / Queue / Export 的实际处理行为。
  - 诊断持久化格式。
  - Renderer、底部边框、布局、保存回图库语义。
- 这一步的真实意义：
  - 把一批 `stage == "..."` 的业务分支从“能编译但可能拼错”的状态收成类型化常量。
  - 为下一步继续收口静默失败和拆 MVP / Share 协调层做准备，而不先动输出主链路。

## 2026-06-30 Typed iOS Temporary Entry Foundation

- 本轮开始进入“稳定优先的精简拆分”第一刀，但严格保持边界：
  - 不做 UI 重设计
  - 不做 Renderer / Export 逻辑重写
  - 不改预期输出结果
- 已落实：
  - 新增 `PhotoMemoiOSTemporaryEntry` 与
    `PhotoMemoiOSTemporaryEntryConfiguration`。
  - `PhotoMemoiOSHomeView`、`PhotoMemoRootSceneView`、
    `PhotoMemoiOSTemporaryEntryView` 不再各自传 raw string 形式的：
    - storage key
    - default entry
  - `PhotoMemoiOSMVPApp` 现在显式使用 `.mvp` 配置，继续保持独立 MVP App
    默认进入 `MVP 测试页`。
  - `PhotoMemoiOSTemporaryEntryView` 的 Picker / 切页逻辑改为 enum 驱动，
    不再直接对 `"configurationCenter"` / `"mvpTest"` 做字符串分支。
- 新增测试：
  - `PhotoMemoiOSTemporaryEntryTests`
  - 覆盖：
    - 已存 raw value 兼容
    - 非法值回退到默认入口
    - 正式 iOS 与 MVP 的存储 key / 默认入口隔离
- 已验证：
  - 新测试通过。
  - `PhotoMemoiOS` generic iOS Debug build 通过。
  - `PhotoMemoiOSMVP` generic iOS Debug build 通过。
  - `PhotoMemoTests` 全套仍只有仓库里已知的两处旧失败：
    - `ClassicWhiteSnapshotTests.landscapeStandardSnapshotStaysStable`
    - `RecordCardBuildServiceTests.buildsTemplate1WithProfileRelationshipAndBabyAgePhrasing`
- 特意未改：
  - Share/Queue/Export 逻辑。
  - Renderer、底部边框、布局、保存回图库行为。
  - MVP / 正式 iOS 的实际入口默认语义。
- 这一步的真实意义：
  - 先把一类“能编译但走错页”的 raw string 状态隐患收掉。
  - 给后续更大的 MVP View / Share coordinator 拆分准备一个低风险基础。

## 2026-06-30 iCloud Source Readiness Guard For Share Intake

- 用户反馈：
  - 当前仍可能卡在 `正在交给 PhotoMemo`、`检查待处理照片`、
    `正在读取刚接收的照片`。
  - 需要考虑 iCloud 照片完整原图缓存到本地后，PhotoMemo 才能取得完整数据。
  - 如果是本地可读图片，不需要额外显示 iCloud 准备环节。
- 根因判断：
  - 之前 Share Extension / 主 App 只把 `copyItem` 成功或 `fileExists`
    当作可处理依据。
  - 这不足以证明 App Group 内的文件已经是完整、可由 ImageIO 解码的图片。
- 已落实：
  - 新增 `PhotoMemoImageFileReadiness`。
  - Share intake 在复制 provider URL 前，会触发 iCloud 下载请求并等待源图可读。
  - 复制/写入 App Group 后，再用 ImageIO 验证目标文件能读出尺寸。
  - 主 App drain 时不再只检查文件存在，必须确认图片可读才入队。
  - `PhotoImportService` 在实际导入前再做一次短等待，避免刚接收文件尚未稳定。
  - Share Extension 新增只在必要时出现的诊断事件：
    - `extension.source.prepare`
    - `extension.source.ready`
    - `extension.source.unavailable`
  - Share 窗口处理态会根据诊断短轮询显示：
    - `正在读取 iCloud 原图`
    - `原图已可读取`
  - iOS MVP `处理进度` 面板同步显示 iCloud 原图准备环节。
- 特意未改：
  - renderer、底部边框、文字布局、Photo Library 保存、通知完成语义。
  - 本地已可读图片不会多出额外 iCloud 步骤。
- 已验证：
  - `PhotoMemoTests/ExternalPhotoIntakeStoreDiagnosticsTests` 通过。
  - `PhotoMemoTests/PhotoImportServiceTests` 通过。
  - `git diff --check` 通过。
  - `PhotoMemoShareExtension` generic iOS Debug build 通过。
  - `PhotoMemoiOSMVP` generic iOS Debug build 通过。
  - `PhotoMemoiOSMVP` iPhone7 Debug build 通过。
  - 已覆盖安装到 iPhone7 `863C2747-6742-5E93-B715-6F89DBF90B31`。
  - 自动启动被 iOS 拒绝，原因是当前 debug 签名 profile 未在设备上信任。
- 下一轮真机重点：
  - 从 Apple Photos 分享一张本地图片，确认不额外显示 iCloud 准备环节。
  - 从 Apple Photos 分享一张未下载原图的 iCloud 图片，确认 Share/主程序进度能显示原图准备，
    准备完成后继续入队并输出。

## 2026-06-30 Immers White Secondary Line And Divider Pixel Pass

- 用户要求：
  - 按上一轮横图、竖图像素对比结论执行解决方案。
  - 分隔符宽度可以进一步拉到位。
  - 本轮仍只处理底部边框输出形式，不改内容逻辑。
- 已落实：
  - `RendererConstants.CompactInformationBar` 新增
    `secondaryYOffsetToBarHeight`：
    - portrait `-0.028`
    - landscape `-0.037`
  - `ImmersWhiteRenderer.Layout` 新增 `secondaryYOffsetRatio`。
  - `pinnedColumn` 对 bottom/secondary B/D 文本应用视觉 offset，
    不影响 A/C 主文字已校准的位置。
  - portrait 右侧 cluster 继续左移：
    - `rightX 0.580 -> 0.566`
    - `dividerCenterX 0.554 -> 0.540`
    - `logoCenterX 0.504 -> 0.490`
    - renderer `rightColumnWidthRatio 0.375 -> 0.389`
  - 分隔符从固定 `4 px` 改成随白边高度比例绘制：
    - `dividerWidthToBarHeight 0.018 -> 0.022`
    - renderer 最小可见宽度 `6 px`
  - iOS MVP preview、正式 iOS Configuration Preview、macOS
    Interactive Memory Card Preview 同步使用 secondary offset。
- 特意未改：
  - 白边高度、照片拼接、主文字字号/字重、灰色副文字字号、内容字符串。
  - 自定义 Logo、EXIF、Share、Export、Photo Library 行为。
- 已验证：
  - `git diff --check` 通过。
  - `PhotoMemoTests/ImmersWhiteRendererLayoutTests` 通过。
  - `PhotoMemoTests/RendererConstantsTests` 通过。
  - `PhotoMemoiOSMVP` generic iOS Debug build 通过。
  - `PhotoMemo` macOS Debug build 通过。
- 下一轮真机重点：
  - 横图检查 B/D 是否从此前低约 `17-21 px` 回到目标线。
  - 竖图检查 B/D 是否从此前低约 `20-21 px` 回到目标线。
  - 竖图检查右侧内容/分隔符/Logo 是否整体左移约 `62 px`。
  - 分隔符应比 4px 版本更明显，但不要抢过文字和 Logo 标识。

## 2026-06-29 Immers White Pixel-Level Text Alignment Pass

- 用户要求：
  - 继续进行 PhotoMemo 底部边框像素级打磨。
  - 本轮只比较输出形式，不考虑内容差异。
  - 忽略红色自定义 Logo。
  - 同时参考 Logo 与右侧内容之间分隔符的差异，让 MVP 内分隔符稍微更宽、更显眼。
- 前两轮标线测量结论：
  - 横图白边高度正确，照片区/底部栏尺寸正确。
  - 竖图白边高度正确，照片区/底部栏尺寸正确。
  - 横图：
    - A 主文字比目标高约 `13 px`
    - C 主文字比目标高约 `8 px`
    - B/D 副文字垂直位置基本对齐
  - 竖图：
    - A 主文字比目标高约 `15 px`
    - C 主文字比目标高约 `14 px`
    - B/D 副文字垂直位置基本对齐
  - 结论：不能整体下移文字列，只能单独下移 A/C 主文字。
- 已落实：
  - `RendererConstants.CompactInformationBar` 新增
    `primaryYOffsetToBarHeight`：
    - portrait `0.019`
    - landscape `0.020`
  - `ImmersWhiteRenderer.Layout` 新增 `primaryYOffsetRatio`。
  - `pinnedColumn` 对 top/primary 文本应用视觉 offset，下移 A/C，
    不改变 B/D 副文字布局位置。
  - portrait 实际 renderer 锚点微调：
    - `horizontalPaddingRatio 0.041 -> 0.045`
    - `rightColumnWidthRatio 0.369 -> 0.375`
  - compact portrait spec 同步：
    - `leftX 0.046 -> 0.045`
    - `rightX 0.590 -> 0.580`
    - `dividerCenterX 0.564 -> 0.554`
    - `logoCenterX 0.514 -> 0.504`
  - 主文字颜色从 `black.opacity(0.92)` 调整为 `0.98`，更接近目标图纯黑质感。
  - `ImmersWhiteRenderer.dividerWidth 2 -> 4`，让 Logo 与右侧内容之间的分隔符更清楚。
  - iOS MVP preview、正式 iOS Configuration Preview、Interactive Memory Card Preview
    同步使用 primary offset，保持预览/导出方向一致。
  - 更新 `RendererConstantsTests` 和 `ImmersWhiteRendererLayoutTests` 锁住本轮校准。
- 特意未改：
  - 内容字符串、日期/秒数、年岁计算、EXIF 格式。
  - 白边高度、照片区拼接、底部栏背景色。
  - 自定义 Logo 处理逻辑。
- 已验证：
  - `git diff --check` 通过。
  - `PhotoMemoTests/ImmersWhiteRendererLayoutTests` 通过。
  - `PhotoMemoTests/RendererConstantsTests` 通过。
  - `PhotoMemoiOSMVP` generic iOS Debug build 通过。
  - `PhotoMemo` macOS Debug build 通过。
- 下一轮真机重点：
  - 重新生成同一组横图/竖图 MVP 输出。
  - 横图重点看 A/C 主文字是否不再偏高，B/D 是否仍对齐。
  - 竖图重点看 A/C 主文字高度、左侧文字右移、右侧文字左移是否接近目标。
  - 看 4px divider 是否比原来更接近目标，但不显得过重。

## 2026-06-29 Final Export Edge Guard And Share Confirmation Polish

- 用户反馈：
  - 最新真机输出仍能看到竖图左侧黑边。
  - Share 后确认页关闭时，内容整体向左上角缩小淡出，视觉很别扭。
  - 希望确认页短暂停留，明确说明已经开始处理，进度可在主 App 查看，然后自动关闭。
  - 多图预览希望更像系统级轻量预览，不要图片边框；少量横竖图应有更自然排布。
- 像素核对：
  - 旧输出 `IMG_0015(1) 2.JPG` 为 `4536 x 8817`。
  - 其中原照片区域高度 `8064`。
  - 左侧 `x = 0...50` 共 `51 px` 在照片区域为近黑色。
  - 白色信息条区域不含黑边，因此继续判定为照片层/最终合成图问题，不是底部信息条问题。
- 已落实：
  - `RecordCardExportService` 在 `ImageRenderer` 生成最终 `CGImage` 后，增加最终导出图防护。
  - 防护只采样照片区域，保守检测窄黑边；命中后裁掉左侧黑带，将照片区域恢复到原输出宽度。
  - 底部信息条单独裁出并原样复制回去，避免影响已锁定的边框效果。
  - 新增 `PhotoImportServiceTests/correctsRenderedPhotoAreaEdgeWithoutChangingInformationBar`。
  - Share Extension 成功态不再执行左上角缩小/淡出动画。
  - 成功态改为静态短暂停留约 1.15 秒后自动关闭。
  - 成功文案改为“已接收，PhotoMemo 已开始后台处理”，并提示可在主 App `处理进度` 查看。
  - Share Extension 预览缩略图去掉灰色卡片边框感。
  - 单张按横竖比例显示；三张若包含一张竖图和两张横图，则竖图在左、两张横图在右侧上下排列；更多图保持轻微堆叠。
- 特意未改：
  - Immers White 底部边框高度、文字布局、字号、Logo、EXIF 格式。
  - Metadata / Photo Library 保存逻辑。
  - 主 App 配置中心架构。
- 已验证：
  - `git diff --check` 通过。
  - `PhotoMemoShareExtension` generic iOS Debug build 通过。
  - `PhotoMemoTests/PhotoImportServiceTests` 通过。
  - `PhotoMemoiOSMVP` generic iOS Debug build 通过。
  - `PhotoMemo` macOS Debug build 通过。
  - `PhotoMemoiOSMVP` iPhone7 Debug build 通过。
  - 已覆盖安装并启动到 iPhone7
    `863C2747-6742-5E93-B715-6F89DBF90B31`。
- 下一轮真机重点：
  - 用同一张竖图重新 Share 生成新图，确认照片区域左侧 51px 黑边消失。
  - 测 1 张、2 张、3 张混合横竖图的 Share 确认预览。
  - 确认 Share 成功页不再向左上角收缩，而是稳定显示后自动关闭。

## 2026-06-29 Portrait Left Edge Artifact Guard

- 用户提供竖图输出样张 `IMG_9911(1).JPG`，反馈照片左侧隐约有黑色竖线。
- 像素核对：
  - 样张尺寸：`4536 x 8817`
  - 原照片区域高度：`8064`
  - 左侧 `x = 0...50` 共 `51 px` 在照片区域接近纯黑。
  - 底部信息条区域左侧为白色，没有黑条。
  - 因此问题属于导入显示图/照片层，不属于底部信息条或边框几何。
- 用户随后补充原图/输出图：
  - 原图：`IMG_0015.jpg`，尺寸 `4536 x 8064`
  - 输出：`IMG_0015(1).JPG`，尺寸 `4536 x 8817`
  - 原图左侧没有黑边，输出照片区域左侧新增 `51 px` 纯黑带。
  - 输出 `x = 51` 的内容与原图 `x = 0` 基本对应，说明照片内容整体被向右偏移。
- 根因方向：
  - 普通 JPEG 之前走 `PlatformImage(data:)`。
  - 在 SwiftUI `ImageRenderer` 导出时，这类 UIKit/AppKit 解码图可能产生边界绘制偏移。
  - 应优先让普通图片也走 ImageIO，生成方向已烘焙的 `CGImage` 后再交给 renderer。
- 已修复：
  - `PhotoImportService.loadDisplayImage(...)` 对非 RAW 图片优先调用
    `imageIODisplayImage(from:)`。
  - `PlatformImage.removingPhotoMemoLeftEdgeArtifact()` 检测窄黑边。
  - 仅在左边缘为近纯黑、贯穿至少 96% 采样高度、宽度小于 2% 且不超过 96px、
    后续列明显非黑时才触发。
  - 触发后裁掉左侧黑边，并将剩余画面轻微横向铺回原尺寸，保持 renderer 输出尺寸不变。
  - `PhotoImportService.importPhotoSync(...)` 在导入显示图后应用该保护。
  - 新增 `PhotoImportServiceTests/removesNarrowBlackLeftEdgeArtifact`。
- 特意未改：
  - Immers White 底部信息条、字号、布局、边框高度。
  - 原图文件、EXIF 元数据写入逻辑、Photo Library 保存逻辑。
- 已验证：
  - `git diff --check` 通过。
  - `PhotoMemoTests/PhotoImportServiceTests` 通过。
  - `PhotoMemoiOSMVP` generic iOS Debug build 通过。
  - `PhotoMemo` macOS Debug build 通过。
- 下一轮真机重点：
  - 用同一张竖图重新 Share 生成，确认照片区域左侧黑条消失。
  - 注意这是导入后生成新图的修复，已生成的旧图不会被回写修改。

## 2026-06-29 iOS MVP Configuration Surface Compression

- 用户反馈：
  - `记忆档案` 的 Preset 选择旁边需要一个可编辑按钮，用于自定义名称。
  - `当前记忆对象摘要` 文字希望上提并压缩空间。
  - `处理进度` 中历史队列溢出如 `另有40个队列` 需要可清理，但不影响当前进度。
  - ABCD 四个自定义区域中的分隔符快捷行占空间，用户可以自己输入分隔符。
- 已落实：
  - `PhotoMemoiOSMVPTestView.profileSection` 在 Preset picker 旁新增 pencil 按钮。
  - 点击后显示 inline `TextField`，提交时调用
    `ConfigurationSession.updateSelectedMemoryPresetTitle(...)`。
  - `当前记忆对象摘要` 与 `activeConfigurationMessage` 合并到同一摘要行，减少一行垂直占用。
  - `处理进度` 在出现 overflow queue 时，进度条下方右侧显示 `清除历史`。
  - `BatchQueueStore.clearCompletedExternalJobHistory(preserving:)` 只清除：
    - 外部 Share 来源
    - 已终态
    - 没有失败待处理
    - 且不是当前显示队列
  - `PhotoMemoBackgroundStatusService.clearCompletedHistory(...)` 暴露给 UI 使用。
  - `MVPRegionEditorCard` 移除固定分隔符快捷行，保留组合结果展示。
- 特意未改：
  - renderer / border / export / metadata / Share Extension / Photo Library。
  - 已保存配置的内容结构和分隔符 item 支持；只是去掉 MVP 编辑卡上的快捷按钮行。
- 已验证：
  - `git diff --check` 通过。
  - `PhotoMemoiOSMVP` generic iOS Debug build 通过。
  - `PhotoMemo` macOS Debug build 通过。
- 下一轮真机重点：
  - Preset 名称编辑、保存、切换后显示是否稳定。
  - `清除历史` 是否只移除历史 overflow，不影响当前/等待/失败队列。
  - ABCD 编辑卡高度是否明显收紧，组合结果是否仍实时显示。

## 2026-06-29 iOS MVP Processing Progress Panel

- 用户反馈：
  - 现阶段系统状态栏 / Live Activity 不够可信，Share 后需要在主 App 内直观看见是否正在处理。
  - 如果结束时间估不准，可以先展示进程；尤其要避免用户看不见 App 是否在工作。
  - 多个队列时，每行展示一个队列，命名应包含任务时间和图片张数。
  - 单个队列时保留 5 个处理进程。
  - 完成后主 App 模块也要更新，不应只依赖系统通知。
  - 模块标题不应再叫 `最近分享`。
- 已落实：
  - iOS MVP 主界面模块标题改为 `处理进度`。
  - `PhotoMemoiOSMVPTestView` 直接观察
    `PhotoMemoBackgroundStatusService.currentSnapshot`。
  - 单队列展示 5 步 Pipeline：
    `接收照片 / 读取信息 / 生成卡片 / 写入图库 / 完成`。
  - 多队列展示最多 3 行 queue lines，继续使用
    `HH:mm（X张）` / `昨天 HH:mm（X张）` 等任务标题。
  - 完成态标题改为类似 `15:20（2张）已完成`。
  - 诊断事件从 5 条收敛到 3 条，作为辅助记录，不再压过进度卡。
  - `extension.handoff.unconfirmed` / `extension.handoff.failed` 在主界面不再写成阻塞失败，
    改为“原图已接收，等待 PhotoMemo 接力处理”。
- 特意未改：
  - renderer / border / export / metadata / Share Extension / Photo Library 管线。
  - 背景队列估时算法，仅使用现有 `remainingTimeText` 和
    `PhotoMemoBackgroundStatusService` 快照。
- 已验证：
  - `git diff --check` 通过。
  - `PhotoMemoiOSMVP` generic iOS Debug build 通过。
  - `PhotoMemo` macOS Debug build 通过。
- 下一轮真机重点：
  - Share 1 张快图，确认主 App 中 `处理进度` 最终留在完成态。
  - Share 2-3 张照片，确认仍显示单队列 Pipeline，而不是误拆成多个任务。
  - 连续 Share 多批照片，确认最多 3 行队列摘要和 overflow 文案。

## 2026-06-29 Immers White Landscape Cluster Recalibration

- 用户提供新一轮横图/竖图三件套：
  - 原图
  - MVP 生成结果
  - 目标效果图
- 像素核对：
  - 横图原图 `4032 x 2268`，MVP/目标输出 `4032 x 2779`，底部白边均为
    `511 px`。
  - 竖图原图 `4536 x 8064`，MVP/目标输出 `4536 x 8817`，底部白边均为
    `753 px`。
  - 白边高度已经正确，本轮未改。
- 关键差异：
  - 横图真实 renderer 的右侧文字起点约 `x = 61.7%`。
  - 目标/冻结规格期望横图右侧文字起点约 `x = 69.6%`。
  - 竖图右侧 cluster 已基本按 portrait spec 工作。
  - MVP 样张中间红章来自当前保存的自定义 Logo 配置；目标图灰 Apple 是默认 fallback，
    这属于配置状态差异，不是 renderer 几何差异。
- 已修正：
  - `ImmersWhiteRenderer.layout(for: .landscape)` 同步到
    `RendererConstants.CompactInformationBar.landscape`：
    - right text start `~0.696`
    - divider center `~0.675`
    - logo center `~0.636`
  - `TemplateItem.captureDateLine` 改为
    `记录于{{capture_date_display}}`。
  - MVP 默认 Slot B 改为 `记录于 + 日期 + 时间`。
  - MVP 预览左主文字不再额外 `1.08x` 放大/加粗，减少预览和真实导出差异。
  - `ImmersWhiteRendererLayoutTests` 增加 landscape anchor 断言。
- 已验证：
  - `git diff --check` 通过。
  - `PhotoMemoTests/ImmersWhiteRendererLayoutTests` 通过。
  - `PhotoMemoiOSMVP` generic iOS Debug build 通过。
  - `PhotoMemo` macOS Debug build 通过。
- 真机注意：
  - 若 iPhone 上仍显示红章或旧时间顺序，需要在 MVP 配置里重置默认配置或重新保存生效配置；
    已保存配置不会被代码默认值强制覆盖。

## 2026-06-29 Share Deferred Handoff And Result Notification

- 用户确认方向：
  - 不希望多一个必须打开主 App 的步骤。
  - 只要 Share Extension 已经把图片安全暂存，就不应再把这次 Share 表达成失败。
  - 如果实在需要排查，主 App 的 `最近分享` 可以显示完整 Pipeline，但不是开心路径依赖。
  - 结果反馈要更清晰，例如 `15:20 处理 2 张照片已完成`。
  - 完成通知不需要再说明存入哪个相册，因为配置阶段用户已经知道。
- 真机诊断依据：
  - Share Extension 成功导入并持久化 2 张照片。
  - `extensionContext.open` 返回 false，responder-chain fallback 返回 true。
  - 6 秒内没有确认主 App drain，所以旧 UI 误报 handoff failure。
  - 主 App 后续实际 drain request、validated payloads、enqueue job，并完成输出。
  - 因此根因是“确认模型过严”，不是“照片没有处理”。
- 已修正：
  - `PhotoMemoShareExtensionViewController` 在 intake persistence 成功后，
    不再因为即时 handoff 未确认而停留失败界面。
  - 未确认 handoff 记录为 `extension.handoff.deferred`，供后续诊断。
  - Share Extension 会播放轻量完成过渡后结束，符合 Apple Photos ->
    Share -> Processing -> Notification -> Apple Photos 的安静链路。
  - `BatchNotificationMessageFormatter` 统一最终通知标题：
    - 成功：`15:20 处理 2 张照片已完成`
    - 全部失败：`15:20 2 张照片需要处理`
    - 部分成功：`15:20 已完成 4 张，1 张需要处理`
  - 最终通知正文移除目标相册描述。
  - 新增 `BatchNotificationMessageFormatterTests`。
- 产品边界：
  - “暂存成功”不等于最终生成永远不会失败。
  - 它表示 PhotoMemo 已经安全接单；后续解码、RAW、渲染、相册写入失败都属于队列结果，
    应通过最终通知或 `最近分享` 诊断表达。
- 已验证：
  - `git diff --check` 通过。
  - `PhotoMemoTests/BatchNotificationMessageFormatterTests` 通过。
  - `PhotoMemoShareExtension` generic iOS Debug build 通过。
  - `PhotoMemoiOSMVP` generic iOS Debug build 通过。
  - `PhotoMemoiOSMVP` iPhone7 Debug build 通过。
  - 已覆盖安装并启动到 iPhone7
    `863C2747-6742-5E93-B715-6F89DBF90B31`。
- 下一轮真机观察：
  - 从 Apple Photos 重新 Share 一张或两张照片。
  - 快速任务可只看到完成通知，不强求持续进度。
  - 最终通知应显示时间和数量，不再出现“系统没有把处理交给 PhotoMemo”的阻塞提示。

## 2026-06-29 Immers White Primary Typography Calibration

- 用户确认：
  - 不动白边高度。
  - 不动灰色第二行副文字。
  - 当前阶段先校准主文字字号和字重。
- 像素依据：
  - 横图/竖图 MVP 与目标图最终尺寸和底部白边高度一致。
  - 差异集中在第一行黑色主文字，MVP 明显更大、更重。
  - 灰色第二行高度已接近目标，保持不动。
- 已修复：
  - `RendererConstants.CompactInformationBar.primaryFontToBarHeight`
    从 `0.225` 调整为 `0.190`。
  - `ImmersWhiteRenderer` 横图/竖图主文字比例统一为 `0.190`。
  - Renderer 输出主文字字重从 `.bold` 改为 `.semibold`。
  - iOS MVP 预览、正式 iOS 配置预览、macOS Interactive Memory Card
    主文字字重同步为 `.semibold`。
  - MVP 预览强调态从 `.heavy` 降为 `.bold`。
- 特意未做：
  - 未改白边高度、图片拼接尺寸、灰色副文字字号/颜色/字重。
  - 未改 Logo、分割线、背景色、EXIF 格式、时间/年岁内容字符串。
  - 未改 Share、Export、Photo Library 或后台队列。
- 已验证：
  - `PhotoMemoTests/ImmersWhiteRendererLayoutTests` 通过。
  - `PhotoMemoTests/RendererConstantsTests` 通过。
  - `PhotoMemoiOSMVP` generic iOS Debug build 通过。
  - `PhotoMemo` macOS Debug build 通过。
  - `git diff --check` 通过。

## 2026-06-29 Formal iOS And macOS Composer Alignment

- 用户确认：
  - 将 MVP 已验证优化同步到正式版本和 macOS 版本。
  - 本轮先落地第一阶段：内容组织与输出一致性。
- 已同步：
  - 正式 iOS `ConfigurationCenteriOSView` 的四区域配置输出改用
    `InlineContentTextComposer`。
  - iOS 正式配置中心的 `baseText + insertedModules + continuationText`
    不再用 `.joined(separator: " ")` 强行插空格。
  - 正式 iOS inline module chip 间距收紧，和 MVP 编辑体验方向一致。
  - macOS V2 Configuration Center 的 `MemoryBlockInspectorView` 自定义字段
    组合预览改用同一 composer。
  - macOS `syncRegionPreview()` 最终写回 Memory Card 预览时也走同一 composer。
  - `ConfigurationSession.appendPreviewModule(...)` 中央卡片直接插入模块时也走
    composer。
  - `InlineContentTextComposerTests` 新增正式配置形态回归：
    `自定义文字 + 年岁模块 + 后缀`。
- 特意未做：
  - 没有把 `PhotoMemoiOSMVPTestView` 整页复制进正式 iOS。
  - 没有改变正式 iOS 默认入口结构。
  - 没有改变 macOS 的
    `Library -> Interactive Memory Card -> Object Inspector` 架构。
  - 没有改变 renderer 几何、边框字体、EXIF 映射、Share、Export 或 Photo Library。
- 已验证：
  - `PhotoMemoTests/InlineContentTextComposerTests` 通过。
  - `git diff --check` 通过。
- 仍建议下一轮：
  - 将正式 iOS 三段式编辑 UI 进一步升级为和 MVP 一致的单一 ordered item
    stream。
  - 将模块库 sheet/popover、使用频率排序同步到 iOS/macOS 正式配置中心。

## 2026-06-29 Default Logo Tint And Inline Content Spacing

- 用户反馈：
  - 默认苹果 Logo 仍然偏黑，希望改成柔和灰色。
  - 右上参数区域前面已经修正过，不希望因为这轮继续误改参数几何。
  - 自定义短语与模块组合后，不能出现类似 `途途今天 1 岁... 啦`
    这种不自然空格。
- 已修复：
  - `BadgeRenderer` 新增 `systemSymbolTint`，系统符号可直接使用指定 tint。
  - `ImmersWhiteRenderer.logoArea` 对默认 Apple / 系统符号 Logo 直接使用
    `ImmersWhiteRenderer.logoTintColor`，不再从 `.primary` 叠加
    `colorMultiply`。
  - `RendererConstants.CompactInformationBar.logoTint` 调整为更柔和的系统灰
    `#8E8E93`。
  - 新增 `InlineContentTextComposer`，统一处理 Text / Token / Separator /
    Line Break 的内联拼接。
  - iOS MVP 四区域编辑器的预览输出、保存模板文本、单行编辑展示现在都走同一
    composer。
- 当前拼接规则：
  - 自定义中文短语 + 模块：不自动加空格。
  - 模块 + 自定义后缀：不自动加空格。
  - 模块 + 模块：保留一个可读空格，除非用户显式用了分隔符。
  - 分隔符两侧不再额外加空格。
- 未触碰：
  - 右上拍摄参数区域几何。
  - 边框高度、字体、字号、图标尺寸、slot 坐标。
  - Share / Notification / Export 管线。
- 已验证：
  - `PhotoMemoTests/InlineContentTextComposerTests` 通过。
  - `PhotoMemoTests/ImmersWhiteRendererLayoutTests` 通过，确认右上参数几何仍保持
    已修正状态。
  - `PhotoMemoiOSMVP` generic iOS Debug build 通过。
  - `git diff --check` 通过。

## 2026-06-29 Immers White Portrait Right-Top Pixel Calibration

- 用户提供两张本地对比图，素材只作为临时测量输入，不进入仓库：
  - 预期参考样本：`IMG_9842 2.JPEG`
  - MVP 输出样本：`IMG_9943(1).JPG`
- 像素观察：
  - 参考图尺寸：`4536 x 8817`
  - MVP 输出尺寸：`3213 x 6246`
  - 底部白边高度比例基本正确，约为最终图高度的 `8.6%`
  - 主要问题不是白边高度，而是 portrait 右上拍摄参数区被压窄
  - MVP 输出右上文字起点约 `x = 0.609`
  - 测量规格期望右上文字起点 `x = 0.590`
  - 在 `3213 px` 宽输出里，这会损失约 `61 px`，导致
    `100mm f/2.8 1/100s IS...` 这类内容提前省略
- 根因：
  - `ImmersWhiteRenderer.layout(for: .portrait)` 中
    `rightColumnWidthRatio` 仍为 `0.35`
  - `dividerToTextSpacingRatio` 仍为 `0.007`
  - 这让 trailing cluster 的文字起点和分隔线都偏右
- 已修复：
  - `rightColumnWidthRatio: 0.369`
  - `dividerToTextSpacingRatio: 0.026`
  - portrait 几何现在对齐：
    - right text start `0.590`
    - divider center `0.564`
    - logo center about `0.514`
  - 新增测试保护 right text / divider / logo 三点关系
- 未触碰：
  - landscape Immers White
  - 白边高度
  - 字体、字号、颜色、logo size
  - 文本内容映射
  - share / notification / export pipeline
- 已验证：
  - 修复前聚焦 renderer layout test 确认失败
  - 修复后 `PhotoMemoTests/ImmersWhiteRendererLayoutTests` 通过
  - `PhotoMemoiOSMVP` generic iOS Debug build 通过
  - `git diff --check` 通过

## 2026-06-29 Share Intake Drain Order Fix

- 用户问题：
  - Share 后确认页正常，handoff 也不再停在失败界面。
  - 但用户看不见是否在处理，之前还出现过没有输出的情况。
- 真机抓数方式：
  - 通过 `xcrun devicectl device copy from` 拉取 iPhone7 的
    App Group `group.com.serydoo.PhotoMemo` 下 `Library/Preferences`。
  - 解码 `photomemo.shareDiagnostics.events` 和
    `photomemo.batchQueue.jobs`。
- 关键证据：
  - 旧请求：
    - `extension.request.persisted`
    - `extension.handoff.primary success=false`
    - `extension.handoff.fallback success=true`
    - `app.drain drainedRequests=1`
    - `app.request.validated payloads=1, valid=0`
    - `app.request.dropped No valid source files remained`
  - 说明 Share Extension 接收/持久化成功，主 App 也醒来了，真正失败点是
    App 端验证前源文件已消失。
- 根因：
  - `PhotoMemoAppRuntime.refreshExternalIntakeState()` 在 drain pending
    shared requests 之前先运行 `cleanupOrphanedManagedContent`。
  - 清理逻辑只保留 batch queue 已引用的文件，不保留 pending request 里的文件。
  - 刚分享进来的 `ExternalIntake/<requestID>/...` 文件还没入队，就被误判为孤儿并删除。
- 已修复：
  - `refreshExternalIntakeState()` 顺序改为：
    1. 更新默认配置
    2. `flushExternalRequests()`
    3. 再执行 orphan cleanup
  - 这样新分享文件会先进入队列引用集合，再参与清理判断。
  - 未触碰 Renderer、Export、底部边框布局/字体/图标/输出形式。
- 已验证：
  - `git diff --check` 通过。
  - `PhotoMemoiOSMVP` generic iOS Debug build 通过。
  - `PhotoMemoShareExtension` generic iOS Debug build 通过。
  - `PhotoMemoiOSMVP` iPhone7 Debug build 通过。
  - 已覆盖安装并启动到 iPhone7
    `863C2747-6742-5E93-B715-6F89DBF90B31`。
  - 用户重新从 Apple Photos 分享 1 张 JPEG 后，设备诊断显示：
    - `app.request.validated payloads=1, valid=1`
    - `app.enqueue.created tasks=1`
  - 队列 job `DFBAF8ED-C460-4629-89AC-4423A8B4C5B7` 为 `completed`，
    且写入了 `savedAssetIdentifier`，目标相册为 `🐣整理水印相册`。
- 仍需后续单独处理：
  - JPEG 单张处理太快，Live Activity 可能只留下 terminal payload，不一定形成可见持续进度。
  - 旧任务里曾记录 `liveActivity.request.failed`：
    `com.apple.ActivityKit.ActivityAuthorization / 7: Target is not foreground`。
  - 这属于 ActivityKit 可见性/启动时机问题，应作为下一条独立 follow-up，
    不再和“没有输出”的根因混在一起。

## 2026-06-29 Share Handoff Fallback And MVP Preview Width

- 用户基于新截图反馈：
  - Share 后弹出 `照片已经接收 / 但系统这次没有把处理交给 PhotoMemo`。
  - 说明扩展已经接收并保存了图片，但主 App handoff 仍然失败。
  - 配置界面预览左上区域 `记录 iPhone 17 Pro...` 过早出现省略号，实际右侧还有空间。
- 根因更新：
  - 构建产物 `PhotoMemoiOSMVP.app/Info.plist` 已确认包含：
    `CFBundleURLTypes -> photomemo`。
  - `PhotoMemoShareExtension.appex` 也已正确嵌入 MVP App。
  - 因此这次不是 URL scheme 缺失，而是 `extensionContext.open(photomemo://share)`
    在该 Share 上下文中返回失败。
- 已修复：
  - `requestMainAppRefresh()` 保留官方 `extensionContext.open` 作为第一路径。
  - 如果第一路径失败，新增 responder-chain fallback 再尝试打开 `photomemo://share`。
  - 原有 handoff 失败重试界面保留，作为最后可见兜底。
  - iOS MVP 配置预览的左上文本区域从渲染规格的窄宽度局部放宽到 Logo 前的安全空间，
    减少不必要省略号。
  - 该宽度调整只影响配置预览，不改变真实导出边框。
- 已验证：
  - `git diff --check` 通过。
  - `PhotoMemoShareExtension` generic iOS Debug build 通过。
  - `PhotoMemoiOSMVP` generic iOS Debug build 通过。
  - `PhotoMemoiOSMVP` iPhone7 Debug build 通过。
  - 已覆盖安装并启动到 iPhone7
    `863C2747-6742-5E93-B715-6F89DBF90B31`。
- 仍需用户真机观察：
  - 从 Apple Photos 重新分享一张照片，确认 handoff 不再停在失败界面。
  - 确认新任务进度出现。
  - 确认左上预览文本不再过早省略。

## 2026-06-29 Share Handoff And Live Activity Visibility Fix

- 用户澄清：
  - 截图里看到的 Live Activity 是前面添加的任务，不是刚刚添加的新任务。
  - 也就是说问题不是单纯“新任务完成太快”，而是新 Share 动作可能没有产生新的可见进度。
- 根因定位：
  - Share Extension 已经能持久化分享进来的图片。
  - 但 `persistIncomingItems()` 在调用 `requestMainAppRefresh()` 后丢弃了返回值。
  - 如果系统这次没有真的打开 `photomemo://share` 对应的 MVP 主 App，扩展仍然会
    `completeRequest` 并消失。
  - 这种情况下主 App 不会 drain `ExternalPhotoIntakeStore`，因此不会有新队列、新
    Live Activity 或新输出。
- 已修复：
  - Share Extension 现在必须确认主 App handoff 成功后才关闭。
  - handoff 失败时，会恢复到已有的 `重新交给 PhotoMemo` 可见重试状态。
  - Live Activity driver 增加最小可见窗口，避免新 job 很快进入终态时卡片被立即结束。
  - 若终态 payload 到达时还没有对应活动卡片，driver 会尝试创建一个短暂可见的终态
    Live Activity，而不是静默记录。
- 已验证：
  - `git diff --check` 通过。
  - `PhotoMemoiOSMVP` generic iOS Debug build 通过。
  - `PhotoMemoShareExtension` generic iOS Debug build 通过。
- 仍需用户真机观察：
  - 从 Apple Photos 分享一张新照片，确认看到的是新任务进度。
  - 若 handoff 偶发失败，确认 Share Sheet 不再直接消失，而是显示重试入口。

## 2026-06-29 Notification Progress Model Simplification

- 用户追问：
  - 发出去的任务似乎不能实时更新在普通通知栏。
  - 多层通知栏里展示进度是否合理。
- 判断：
  - 普通 Notification Center 不应该作为实时进度面。
  - Apple 风格更合理的模型是：
    - Live Activity / 锁屏 / 灵动岛承载持续进度。
    - 普通通知只提示“已接收 / 已完成 / 需要处理”。
  - 继续对 `raw / imported / rendering / saving` 阶段发本地通知，会导致通知中心堆叠，看起来像多层通知日志。
- 已修复：
  - `BatchQueueNotifications.deliverProgressNotificationIfNeeded(...)` 改为不再发送阶段型本地通知。
  - 队列任务进度仍会正常更新，Live Activity payload 仍跟随队列状态刷新。
  - 起始通知和最终结果通知保留。
- 已验证：
  - `git diff --check` 通过。
  - `PhotoMemoiOSMVP` generic iOS Debug build 通过。
  - `PhotoMemoiOSMVP` connected-device Debug build 通过。
  - 已覆盖安装并启动到 iPhone7
    `863C2747-6742-5E93-B715-6F89DBF90B31`。
- 仍需用户真机观察：
  - 重新 Share 一张照片，确认普通通知中心不再出现阶段堆叠。
  - 确认实时进度主要显示在 Live Activity 上。

## 2026-06-29 Live Activity Contrast Fix

- 用户基于锁屏截图反馈：
  - Live Activity 有进度，但状态正文颜色几乎看不见。
  - 截图中标题和百分比可见，`处理完成 · IMG_9927.jpg` 一行明显过暗。
- 根因定位：
  - Lock Screen 单任务视图里，任务标题 `09:34（1张）` 使用 `.secondary`。
  - 状态正文使用 `.tertiary`。
  - 在深色壁纸和通知中心磨砂背景上，`.tertiary` 被系统压到接近不可见。
- 已修复：
  - `PhotoMemoLiveActivityPresentation.swift` 中单任务锁屏状态正文从
    `.tertiary` 提升为 `.secondary`。
  - 未改 Live Activity 布局、进度模型、通知调度、Renderer 或 Export。
- 已验证：
  - `git diff --check` 通过。
  - `PhotoMemoiOSMVP` generic iOS Debug build 通过。
  - `PhotoMemoiOSMVP` connected-device Debug build 通过。
  - 已覆盖安装并启动到 iPhone7
    `863C2747-6742-5E93-B715-6F89DBF90B31`。
- 仍需用户真机观察：
  - 重新 Share 一张图片，让新的 Live Activity 状态刷新，确认状态正文在当前黑色壁纸上可读。

## 2026-06-29 MVP Preview And Inline Editor Polish

- 用户基于 iPhone 截图反馈：
  - 右上拍摄参数汇总适当缩小效果不错。
  - 左上 Recorder 区域被一起缩小后显得不对，应该恢复接近之前字号。
  - 编辑栏内自定义字段与模块之间间距偏大。
  - 当模块出现在最左侧时，用户无法点击模块前方插入光标输入自定义短语。
- 已修复：
  - iOS MVP 预览的左上文字使用更高的最小缩放比例：
    - primary `0.94`
    - secondary `0.90`
  - 右上拍摄参数仍保留更强的缩小能力：
    - primary `0.72`
    - secondary `0.82`
  - 编辑栏横向内容流收紧：
    - HStack spacing 从 `6` 收为 `3`
    - chip padding 从 `8/6` 收为 `7/5`
    - 尾部空短语输入槽从 `132pt` 收为 `58pt`
  - 模块位于最左侧时，前方会出现一个小号“短语”输入目标，输入内容会插入到模块之前。
- 已验证：
  - `git diff --check` 通过。
  - `PhotoMemoiOSMVP` generic iOS Debug build 通过。
  - `PhotoMemoiOSMVP` connected-device Debug build 通过。
  - 已覆盖安装并启动到 iPhone7
    `863C2747-6742-5E93-B715-6F89DBF90B31`。
- 仍需用户真机观察：
  - 左上 Recorder 是否恢复到满意的字号感。
  - 右上拍摄参数是否仍然完整。
  - 在区域 C 这类“模块在最左侧”的场景，点击模块前方输入短语是否顺手。

## 2026-06-29 MVP Content Builder Order And Notification Update

- 用户反馈：
  - MVP 编辑栏里，自定义字段和模块不能按真实输入顺序展示。
  - 先输入文字再插入模块时，模块会像被分组到前面，文字长期留在最后。
  - 编辑中的模块展示应更精简，不显示后面的具体解析值；预览区保持实时刷新。
  - 单个后台任务不应在通知栏里按阶段堆叠多条通知，应像同一条任务进度持续更新。
- 已修复：
  - `PhotoMemoiOSMVPTestView` 的四区域编辑器改为直接渲染同一个
    `MVPEditorDraft.items` 顺序流。
  - 自定义文字、Token 模块、分隔符在编辑区、保存模板和预览输出中共享同一顺序。
  - 模块插入会优先跟随当前正在编辑的文字项；若没有活动文字项，则追加到末尾。
  - 编辑区模块 chip 只显示图标、模块名和删除按钮，不再在 chip 内展示具体 EXIF /
    年岁解析内容。
  - `BatchNotificationService` 统一使用
    `photomemo.batch.<job-id>.status` 作为同一任务的本地通知 identifier。
  - 新通知会移除旧的 per-stage identifier：
    `start`、`final`、`progress.raw`、`progress.imported`、
    `progress.rendering`、`progress.saving`。
  - 进度更新设置为 passive，接收/完成通知保持 active。
- 已验证：
  - `git diff --check` 通过。
  - `PhotoMemoiOSMVP` generic iOS Debug build 通过。
  - `PhotoMemoiOSMVP` connected-device Debug build 通过。
  - 已覆盖安装并启动到 iPhone7
    `863C2747-6742-5E93-B715-6F89DBF90B31`。
- 仍需用户真机观察：
  - 在四个区域里测试“输入文字 -> 插入模块 -> 继续输入”的实际顺序。
  - 分享单张 JPEG / RAW，确认通知栏不再堆叠多个阶段通知。

## 2026-06-29 MVP Reliability Lock Foundation

- 本轮开始进入 `MVP Reliability Lock`，目标是把 PhotoMemo 从“功能可用”
  推向“像系统能力一样可靠、安静、可预期”。
- 明确冻结：
  - 底部边框输出内容
  - 布局
  - 字体 / 字号
  - 图标
  - 四区域内容映射
  - 渲染视觉形式
- 新增：
  - `Docs/MVP_RELIABILITY_LOCK.md`
- 该文档作为后续 MVP 可靠性发布门槛，覆盖：
  - Apple Photos -> Share -> PhotoMemo -> Processing -> Notification ->
    Apple Photos 生命周期
  - 支持 / 不支持的图片格式
  - 队列命名规则
  - 单任务、2-3 队列、4+ 聚合的状态表达
  - RAW / DNG 处理阶段
  - 完成、失败、部分成功的通知语义
  - 真机人工回归矩阵
- 自动化护栏：
  - `BatchFixtureCoverageTests` 新增队列标题格式测试。
  - `BatchFixtureCoverageTests` 新增“队列创建时间跟随最早 payload request
    time”的测试。
  - `PhotoMemoQueueDisplayFormatter` 的今天 / 昨天判断改为使用注入的 `now`，
    避免测试随真实日期漂移。
  - `RecordCardBuildServiceTests` 对齐当前 MVP 命名规则：
    `原图名(1).jpg`、`原图名(2).jpg`。
  - 命名测试增加临时导出目录清理，避免本地残留影响重复测试。
- 已验证：
  - `PhotoMemoTests/BatchFixtureCoverageTests` focused test 通过。
  - `PhotoMemoTests/RecordCardBuildServiceTests` focused test 通过。
  - `PhotoMemoiOSMVP` generic iOS Debug build 通过。
  - `PhotoMemo` macOS Debug build 通过。
  - `git diff --check` 通过。
- 当前完整 `PhotoMemoTests` 仍有一个非本轮新增失败：
  - `ClassicWhiteSnapshotTests.landscapeStandardSnapshotStaysStable`
  - 该项属于 Classic White 渲染快照；在“边框输出冻结”前提下，不应顺手更新
    snapshot，应单独调查。
- 设备状态：
  - `iPhone7` 当前在 `xcrun devicectl list devices` 中为 unavailable。
  - `IPhone5` 可见但 Developer Mode disabled，不能用于开发安装。
  - 本轮没有推送到手机，只完成 generic iOS build。
- 下一步建议：
  1. 为 `PhotoMemoBackgroundStatusService` 的 display mode 增加自动化测试。
  2. 为最终通知文案增加自动化测试。
  3. 单独调查 Classic White landscape snapshot。
  4. iPhone7 恢复 available 后，再推真机做真实 Share 回归。

## 2026-06-29 MVP Queue Naming Refinement

- 用户确认：
  - 每一个队列代表一次 Share 任务。
  - 队列名称用开始时间 + 照片数量更直观。
  - 期望示例：
    - `18:42（3张） · 1/3 · 约 2 分钟`
    - `18:42（3张） · 1 张需要处理`
    - `18:42（3张） · 已保存 3 张`
- 已实现：
  - 新增 `PhotoMemoQueueDisplayFormatter`，统一生成用户可读队列名称：
    - 当天：`18:42（3张）`
    - 昨天：`昨天 18:42（3张）`
    - 今年更早：`6月29日 18:42（3张）`
    - 跨年：`2025年12月31日 18:42（3张）`
  - `PhotoMemoAppRuntime.resolvedRequestTitle(...)` 不再生成
    `外部图片处理 yyyy.MM.dd HH:mm · X张`。
  - `BatchQueueExecution` 的默认后台任务标题不再生成
    `PhotoMemo 后台任务 ...`。
  - 新建 `BatchJob.createdAt` 改为跟随最早的 intake payload request time，
    更贴近真实 Share 开始时间。
  - `PhotoMemoBackgroundStatusService` 在 snapshot / queue line 展示层统一
    使用 compact queue title，因此旧持久化任务也不会继续露出旧标题。
  - 队列行文案收口为结果优先：
    - 完成：`已保存 X 张`
    - 失败：`X 张需要处理`
    - 部分完成：`已保存 X 张 · Y 张需要处理`
- 已验证：
  - `git diff --check` 通过。
  - `PhotoMemoiOSMVP` connected-device Debug build 通过。
  - 已覆盖安装到 iPhone7
    `863C2747-6742-5E93-B715-6F89DBF90B31`。
- 仍需人工复测：
  - 分享单张照片，确认通知/锁屏/状态 sheet 使用 compact 队列名。
  - 连续分享 2-3 批，确认每行代表一次 Share 任务。
  - 连续分享 4 批以上，确认聚合模式仍然克制。

## 2026-06-29 MVP Share Handoff URL Scheme Fix

- 用户反馈：
  - RAW 和 JPEG 从 Apple Photos 分享到 MVP 后，确认页能出现，但下拉通知栏没有进度，也没有看到输出结果。
  - 希望确认后有一个更接近系统感的“收起到通知/灵动岛方向”的过渡动画。
- 根因定位：
  - Share Extension 已能展示确认页并执行接单流程。
  - MVP 主 App target 虽然嵌入了 Share Extension 和 Widget Extension，也有 `NSSupportsLiveActivities`，但构建产物 `Info.plist` 没有真实生成 `CFBundleURLTypes`。
  - Share Extension 通过 `photomemo://share` 唤起主 App；MVP App 未注册 URL scheme 时，`extensionContext.open(...)` 会失败，主 App 不会被唤起 drain `ExternalPhotoIntakeStore`，因此队列、通知进度、输出都会缺席。
- 已修复：
  - 新增 `Source/PhotoMemo/PhotoMemoiOSMVP-Info.plist`，为 MVP App 明确注册：
    - `CFBundleURLTypes -> photomemo`
    - `NSSupportsLiveActivities`
    - 相册读写权限文案
  - `PhotoMemoiOSMVP` Debug / Release 改为使用这份专用 Info.plist。
  - Share Extension 的完成流程不再静默忽略唤起失败：
    - `requestMainAppRefresh()` 现在返回 Bool。
    - 如果系统没有打开主 App，确认页会停留在“照片已经接收 / 需要重新交给 PhotoMemo”的可见状态。
  - 持久化成功后增加轻量 UIKit 过渡：
    - 确认界面向顶部缩小并淡出。
    - 保留轻触感反馈。
    - 该动画只在接单成功后触发，不掩盖失败。
- 已验证：
  - `PhotoMemoiOSMVP` 真机 Debug build 通过。
  - 构建产物 `Info.plist` 已包含 `CFBundleURLTypes -> photomemo`。
  - 构建产物仍包含 `NSSupportsLiveActivities = true`。
  - 构建产物仍嵌入：
    - `PhotoMemoShareExtension.appex`
    - `PhotoMemoWidgetExtension.appex`
  - `PhotoMemoiOSMVP` 已覆盖安装到 iPhone7 `863C2747-6742-5E93-B715-6F89DBF90B31`。
  - `PhotoMemoiOSMVP` iOS Simulator Debug build 通过。
  - `PhotoMemo` macOS Debug build 通过。
  - `git diff --check` 通过。
- 未验证：
  - 设备当前锁定，无法通过 devicectl 远程启动 App。
  - 仍需要用户从 Apple Photos 手动分享 1 张 JPEG 和 1 张 RAW，确认：
    - 完成动画出现。
    - 主 App 被打开或后台接单。
    - 通知/锁屏 Live Activity 出现进度。
    - 成品写入 Apple Photos / `photomemo` 相册。

## 2026-06-29 Share Confirmation RAW Preview Refinement

- 用户反馈：
  - 竖图完整显示正常。
  - 2 张横图 / 竖图混合正常。
  - RAW 场景下确认页缩略图不能正常显示。
  - 预览图片不需要边框，只要能显示缩略图，选中时轻微放大即可。
- 根因定位：
  - Share 确认页此前只用 `loadItem(UTType.image)` 后尝试 `UIImage(data:)`。
  - RAW / ProRAW 分享时，系统可能不给可直接 `UIImage` 解码的数据；更稳定的方式是先请求系统预览图，再对文件表示用 ImageIO 生成小缩略图。
- 已修复：
  - Share 确认页预览加载顺序改为：
    1. `NSItemProvider.loadPreviewImage`
    2. `loadFileRepresentation` + `CGImageSourceCreateThumbnailAtIndex`
    3. 原有 `UIImage` / `Data` fallback
  - 预览缩略图限制为 `640px` 级别，避免 RAW 在 Share Extension 内造成内存压力。
  - 预览 provider 判断扩展为 PhotoMemo 当前支持的图片类型集合，覆盖 RAW / DNG 类型。
  - 预览卡片去掉容器边框和边框选中态。
  - 选中态只保留：
    - `1.06x` 轻微放大
    - 前景层级提高
    - 非选中项轻微降透明
- 已验证：
  - `PhotoMemoiOSMVP` connected-device Debug build 通过。
  - 已覆盖安装到 iPhone7 `863C2747-6742-5E93-B715-6F89DBF90B31`。
- 仍需人工验证：
  - 从 Apple Photos 分享 RAW / ProRAW 到 MVP，确认缩略图能出现。
  - 确认无边框预览在横图、竖图、多图下视觉足够克制。

## 2026-06-29 Share Confirmation Single Photo Simplification

- 用户反馈：
  - 单张分享不需要缩略图。
  - 用户刚看到之前图片的处理结果，说明后台处理耗时可能长短不一，需要重新梳理通知栏和主 App 进度表达。
- 已修复：
  - Share 确认页现在只有 `2 张及以上` 时显示多图缩略图卡片。
  - 单张分享隐藏整个预览 section，只保留：
    - 照片数量
    - 默认风格
    - 结果去向
    - 当前处理说明
    - 开始生成按钮
  - 目的：
    - 避免单张确认页像“结果预览”。
    - 降低 RAW 单张场景下的预览解码压力。
    - 保持 Apple Photos Share 的轻量确认感。
- 已验证：
  - `PhotoMemoiOSMVP` connected-device Debug build 通过。
  - 已覆盖安装到 iPhone7 `863C2747-6742-5E93-B715-6F89DBF90B31`。
- 后续交互方向：
  - 通知栏/Live Activity 应区分单任务、2-3 个任务、4+ 聚合、完成、失败。
  - 主 App 后台状态页应从“后台状态”继续收敛为“处理进度/最近结果”，单任务显示完整 Pipeline，多任务显示可展开队列。

## 2026-06-29 Single Task Pipeline Progress

- 用户确认继续推进后台进度交互。
- 本轮目标：
  - 单张照片不再用“批处理队列感”的表达。
  - 单张任务展示完整 Pipeline。
  - 2-3 个任务继续每队列一行。
  - 4 个及以上任务聚合成摘要。
  - 完成/失败通知文案更短，更接近系统通知。
- 已实现：
  - `PhotoMemoBackgroundJobSnapshot` 新增展示层字段：
    - `displayMode`
    - `pipelineSteps`
    - `activePipelineStepIndex`
  - 单张 Pipeline 固定为：
    1. 接收照片
    2. 读取信息
    3. 生成卡片
    4. 写入图库
    5. 完成
  - RAW 相关阶段继续通过状态文案表达：
    - `正在准备 RAW 照片`
    - `已生成 RAW 显示版本`
  - Live Activity / Lock Screen：
    - 单张显示当前状态 + 细进度 + Pipeline dots。
    - 多张继续显示 queue lines。
    - Dynamic Island expanded bottom 跟随单张/多张模式切换。
  - 主 App 后台 sheet：
    - 标题从 `后台状态` 改为 `处理进度`。
    - 单张显示 `处理流程` Pipeline。
    - 多张仍显示队列摘要和最近记录。
  - 本地最终通知文案收短：
    - 成功：`PhotoMemo 已保存 X 张照片`
    - 失败：`X 张照片需要处理`
    - 部分完成：`已保存 X 张，Y 张需要处理`
- 已验证：
  - `PhotoMemoiOSMVP` connected-device Debug build 通过。
  - 已覆盖安装到 iPhone7 `863C2747-6742-5E93-B715-6F89DBF90B31`。
  - `PhotoMemo` macOS Debug build 通过。
- 人工复测建议：
  - 分享 1 张 JPEG，观察 Lock Screen / Notification Center 是否显示 Pipeline。
  - 分享 1 张 RAW，确认 RAW 阶段文案能解释等待。
  - 分享 2-3 张，确认每队列一行。
  - 连续分享 4 组以上，确认聚合摘要出现。
  - 制造失败项，确认通知和主 App sheet 都显示“需要处理”。

## 2026-06-29 Share Confirmation Preview Card Stack

- 用户反馈：
  - Share 到 MVP 后的确认窗口体验不错，但下方待处理图片预览里，竖图显示不完整。
  - 希望保持当前窗口大小，适当缩小示意图或拉高一点，确保图片完整。
  - 多张图片时希望接近“扑克牌”式左右滑动，点击某张时轻微放大凸显。
- 根因：
  - Share Extension 确认页此前只有一个 `UIImageView`。
  - 固定高度 `180pt`，`contentMode = .scaleAspectFill`，竖图会被裁切。
  - 多张分享只预览第一张，无法感知待处理队列内容。
- 已修复：
  - 将单图 `UIImageView` 改为横向 `UIScrollView + UIStackView` 预览卡片组。
  - 图片预览卡片统一使用 `.scaleAspectFit`，竖图完整显示，不再裁切。
  - 预览区域高度收为 `168pt`，卡片高度 `158pt`，保持确认窗口整体克制。
  - 多张时最多加载前 10 张轻量预览，避免 Share Extension 内存压力。
  - 卡片采用轻微重叠的横向排列，形成低调的“扑克牌”感。
  - 点击某张卡片会：
    - 轻微放大到 `1.06x`
    - 加深边框
    - 自动滑动到可见区域
  - 文案改为：`左右滑动查看待处理照片，所有照片会使用相同风格处理。`
- 未改：
  - Share Extension 接单逻辑
  - 后台队列
  - Renderer
  - 输出格式
  - RAW 处理策略
- 验证：
  - `PhotoMemoShareExtension` Debug iOS Simulator build 通过。
  - `PhotoMemoiOSMVP` connected-device Debug build 通过。
  - 已覆盖安装到 iPhone7 `863C2747-6742-5E93-B715-6F89DBF90B31`。
  - `git diff --check` 通过。
- 人工复测建议：
  - 分享 1 张竖图，确认完整显示。
  - 分享 3-5 张横竖混合照片，左右滑动检查每张预览。
  - 点击不同卡片，确认轻微放大和滚动定位自然。

## 2026-06-29 MVP Live Activity Packaging Fix

- 用户反馈：从 Apple Photos 分享后，下拉通知栏看不到队列/进度，感觉没有进入队列。
- 根因定位：
  - `PhotoMemoiOSMVP.app` 的产物里只有 `PhotoMemoShareExtension.appex`。
  - MVP target 没有嵌入 `PhotoMemoWidgetExtension.appex`。
  - MVP target 生成的 Info.plist 里也没有 `NSSupportsLiveActivities = YES`。
  - 因此 ActivityKit 即使收到后台状态 payload，也没有可展示的 Live Activity widget 承载；驱动层此前 catch 后静默禁用请求，用户侧表现为通知栏没有持续进度。
- 已修复：
  - `PhotoMemoiOSMVP` target 增加 `PhotoMemoWidgetExtension` target dependency。
  - `PhotoMemoiOSMVP` target 的 `Embed App Extensions` 同时嵌入：
    - `PhotoMemoShareExtension.appex`
    - `PhotoMemoWidgetExtension.appex`
  - `PhotoMemoiOSMVP` Debug / Release build settings 增加：
    - `INFOPLIST_KEY_NSSupportsLiveActivities = YES`
- 已验证：
  - `PhotoMemoiOSMVP` connected-device Debug build 通过。
  - 构建产物 `PhotoMemoiOSMVP.app/PlugIns` 已包含 `PhotoMemoWidgetExtension.appex`。
  - 构建产物 Info.plist 已包含 `NSSupportsLiveActivities = true`。
  - 已覆盖安装到设备 `863C2747-6742-5E93-B715-6F89DBF90B31`。
  - `git diff --check` 通过。
- 复测建议：
  - 优先用 RAW 或多张照片测试，因为单张普通图片处理太快，Live Activity 可能还没形成持续可见状态就结束。
  - 如果仍看不到，下一步检查系统设置里的 PhotoMemo 通知权限与 Live Activities 开关。

## 2026-06-29 MVP RAW / ProRAW Priority Support

- 本轮按“RAW 优先处理，但不冒险”的原则补齐 MVP 后台链路：
  - RAW / DNG 不再在 Share Extension 前置校验中被跳过。
  - 原始 RAW 文件仍不被修改，只作为元数据与显示版本来源。
  - PhotoMemo 会生成一张普通输出图片：系统生成的 RAW 显示版本 + 当前底部边框。
  - 原 RAW 的 `sourceProperties` / EXIF 仍作为卡片内容和输出元数据来源。
- 输入策略更新：
  - 支持：`JPEG/JPG`、`HEIC/HEIF`、`PNG`、`TIFF`、`RAW/DNG`
  - 仍不支持：Live Photo、GIF、WebP、视频、超长比例图片。
  - RAW 仍遵守当前 iPhone 标准照片包络：
    - 单边最大 `8064 px`
    - 总像素最大 `8064 x 6048`
    - 最大长宽比 `3:1`
- RAW 导入策略：
  - 普通照片继续走原有 `Data -> PlatformImage` 稳定路径。
  - RAW 照片先尝试平台文件显示版本。
  - 失败后用 ImageIO 生成最大边长受控的显示版本。
  - 最后才回退 CoreImage 渲染，避免一开始就走重型路径。
- 进度感知更新：
  - RAW 任务开始显示 `正在准备 RAW 照片`。
  - RAW 导入完成显示 `已生成 RAW 显示版本`。
  - 单张队列摘要会显示 `准备 RAW` / `RAW 显示版本`，避免用户误以为卡住。
  - RAW 估时按更保守的 `75 秒/张` 计算；普通照片仍按 `14 秒/张`。
  - 本地通知新增 `raw` 阶段文案：`正在准备 RAW 照片`。
- 验证：
  - `PhotoProcessingInputPolicyTests` 通过。
  - `PhotoImportServiceTests` 通过。
  - `BatchFixtureCoverageTests` 通过。
  - `PhotoMemoiOSMVP` 真机 Debug build 通过。
  - `PhotoMemoShareExtension` Debug iOS Simulator build 通过。
  - `git diff --check` 通过。
- 已覆盖安装到设备：
  - `iPhone7`
  - device id `863C2747-6742-5E93-B715-6F89DBF90B31`
  - bundle id `com.serydoo.PhotoMemo.iOS`
- 未完成 / 需要人工验证：
  - 从 Apple Photos 分享真实 ProRAW / DNG 到 PhotoMemo。
  - 检查输出图片视觉、EXIF token、相册写入是否符合预期。
  - 在 iPhone7 上观察 RAW 大图处理时是否发生内存压力；如有，下一步应把 RAW 显示版本上限进一步下调到设备自适应。

## 2026-06-29 MVP Queue Summary Live Activity

- 本轮把“近期多个处理队列，每行仅展示一个队列进度”的 MVP 状态模型落地到真机版本。
- 新增后台状态摘要规则：
  - `PhotoMemoBackgroundJobSnapshot` 现在包含 `queueLines` 和 `overflowQueueCount`。
  - 最多展示 3 行，每行代表一个外部队列。
  - 排序优先级：当前处理 -> 失败/需处理 -> 等待/处理中 -> 最近完成。
  - 超过 3 个队列时显示 `另有 X 个队列`，避免通知区域变成任务列表。
- 队列行文案规则：
  - 单张：`正在处理 · 写入图库 · 约 14 秒`
  - 多张处理中：`正在处理 · 10/20 · 约 3 分钟`
  - 等待：`等待中 · 3 张`
  - 完成：`已完成 · 20 张已保存`
  - 失败：`需要处理 · 18/20 · 2 张需要查看`
- Live Activity 已接入：
  - `PhotoMemoBackgroundActivityAttributes.ContentState` 新增 `queueLines` / `overflowQueueCount`。
  - 锁屏主视图和 Dynamic Island expanded bottom 复用同一套三行摘要。
  - Dynamic Island compact 仍保持克制，只显示图标和进度百分比。
- App 内后台状态页已接入：
  - 右上角后台状态 sheet 展示同一组三行摘要。
- 当前剩余时间为保守估算：
  - 按剩余图片数粗略计算，先用于 MVP 体感验证。
  - 后续可改为最近 3 张平均耗时。
- 验证：
  - `PhotoMemoiOSMVP` 真机 Debug build 通过。
  - 已重新安装到设备 `863C2747-6742-5E93-B715-6F89DBF90B31`。
  - `git diff --check` 通过。
- 下一步人工测试建议：
  - 分享 1 张，观察单张阶段/剩余时间。
  - 连续分享多组照片，观察最多 3 行队列摘要。
  - 分享 10+ 张，观察 `10/20` 风格展示。
  - 制造失败项，确认失败队列优先显示且不被完成队列挤掉。

## 2026-06-29 MVP Share Output Runtime Fix

- 用户确认 Apple Photos Share Sheet 已能看到并进入 `PhotoMemo MVP`，确认动作也能完成，但之后没有生成/保存输出。
- 根因定位：
  - `PhotoMemoShareExtension` 已能把分享图片持久化为 `ExternalPhotoIntakeRequest`。
  - 正式 iOS App 入口会创建 `PhotoMemoAppRuntime`，并通过 `PhotoMemoRootSceneView` 在 `task/onAppear/onOpenURL/scenePhase` 中调用 `refreshExternalIntakeState()` / `flushExternalRequests()`。
  - `PhotoMemoiOSMVPApp` 之前直接打开 `PhotoMemoiOSTemporaryEntryView`，绕过了 `PhotoMemoiOSHomeView` 和 `PhotoMemoAppRuntime`，所以 Share Extension 确认后写入了请求，但 MVP App 没有 drain 请求，也没有启动 `BatchQueueStore` 输出链路。
- 已修复：
  - `PhotoMemoiOSMVPApp` 现在创建 `PhotoMemoAppRuntime` 并进入 `PhotoMemoiOSHomeView`。
  - `PhotoMemoiOSHomeView` 和 `PhotoMemoRootSceneView` 增加临时入口参数传递。
  - MVP 仍默认显示 `mvpTest` 页面，但外层保留正式 iOS runtime、deeplink flush、后台状态入口和 batch processing。
- 验证：
  - `PhotoMemoiOSMVP` 真机 Debug build 通过。
  - 已重新安装并启动到设备 `863C2747-6742-5E93-B715-6F89DBF90B31`。
  - `git diff --check` 通过。
- 下一步人工验证：
  - 从 Apple Photos 分享一张普通静态照片到 `PhotoMemo Share`。
  - 确认后允许相册权限。
  - 观察是否保存到系统图库 / `photomemo` 相册。
  - 如果失败，打开右上角后台状态按钮查看任务阶段与错误信息。

Compact AI summary for this round:

- `Docs/AI_HANDOFF_2026-06-21.md`
- `Docs/AI_HANDOFF_2026-06-22.md`

## 2026-06-29 Background Pipeline Input Policy

- 本轮围绕“快一点，但不冒险”的后台处理原则，补齐处理输入边界，并接入 Share Extension 前置校验；不改现有 UI、Renderer、Export 输出形式。
- 新增 `PhotoProcessingInputPolicy`：
  - 支持格式：`JPEG/JPG`、`HEIC/HEIF`、`PNG`、`TIFF`
  - 暂不支持：Live Photo、RAW/DNG、GIF、WebP、视频
  - 标准照片尺寸上限按当前 iPhone 48MP 静态照片包络确定：
    - 单边最大 `8064 px`
    - 总像素最大 `8064 x 6048`
    - 最大长宽比 `3:1`
  - 超大图、超高像素图、全景图、长截图、极端细长图片会得到明确拒绝原因和 Apple-native 风格反馈文案。
- `PhotoImportService.supportedTypes()` 已改为引用 `PhotoProcessingInputPolicy.supportedImageTypes`，避免支持格式出现第二套定义。
- 已继续接入 Share Extension intake 前置校验：
  - 复制到共享容器后读取文件类型与像素尺寸。
  - 不支持的图片立即清理临时副本。
  - 不支持项计入 `skippedCount`，不会进入 Batch Queue。
  - `skippedCount` 文案从“重复跳过”改为通用“已跳过”，因为跳过原因可能是重复，也可能是不支持。
- `3:1` 阈值按长边 / 短边计算，不区分横图和竖图：
  - `6048 x 8064` 竖图支持。
  - `3024 x 5376` 这类 9:16 竖图支持。
  - 超过 `3:1` 的长截图、全景图、特别细长图片暂不支持。
- 推荐后台处理策略继续保持：
  - Share Extension 只复制与持久化，不渲染。
  - Import / EXIF 可有限并发。
  - Render / Photo Library Save 保持串行。
  - 每张完成后立即清理临时文件。
- 验证通过：
  - `PhotoProcessingInputPolicyTests`
  - `PhotoImportServiceTests`
  - `PhotoFileNameResolverTests`
  - `PhotoMemoAlbumSelectionTests`
  - `PhotoMemoShareExtension` Debug iOS Simulator build
  - `PhotoMemoiOSMVP` Debug iOS Simulator build
  - `PhotoMemoiOS` Debug iOS Simulator build
  - `git diff --check`
- 已确认：
  - `PhotoMemo` scheme 没有配置 test action。
  - 定向测试应使用 `PhotoMemoTests` scheme。
- 后续接入建议：
  - 真机验证 Share Extension 部分成功、部分跳过反馈。
  - 进一步区分跳过原因的内部统计，但不要在 Share UI 里制造诊断噪音。

## 2026-06-28 MVP Album And Logo Output Completion

- 本轮补齐 MVP 输出设置的两个真实缺口：
  - 生成图片继续作为新图片进入 Apple Photos 系统图库。
  - 用户未选择相册时，自动创建/复用小写 `photomemo` 相册。
- `PhotoLibraryExportService` 新增 `ensureAlbum(named:)`：
  - 可按名称复用已有相册。
  - 不存在时创建新相册。
  - 默认相册名统一为 `photomemo`。
- iOS MVP 输出区现在支持：
  - 自动存入 `photomemo`
  - 仅保存到系统图库
  - 从现有相册下拉选择
  - 输入名称并在保存配置时新建/复用相册
- 保存配置时会把真实相册 localIdentifier 和 title 写入共享设置，Share 后的 snapshot 继续读取同一路径。
- 自选 Logo 已从占位补为真实上传：
  - 使用原生 `PhotosPicker`
  - 用户选择图片后异步优化
  - 优化文件写入共享容器 `LogoAssets`
  - 保存为 `.customUpload` Badge，并通过 `imagePath` 供渲染读取
- Logo 上传/优化规格：
  - 推荐上传 `2048 x 2048` 透明 PNG
  - 最低建议 `1024 x 1024`
  - 后台统一优化为 `2048 x 2048` 方形透明 PNG
  - 内容保留 `12%` 安全留白
- 推荐依据：
  - 当前 4032px 横向输出中 Logo 约显示 `209px`
  - 12000px 竖向未来输出中 Logo 约显示 `817px`
  - 2048px master 对大图输出和打印检查有足够余量
- 新增测试：
  - `PhotoMemoAlbumSelectionTests`
  - `LogoAssetOptimizationServiceTests`
- 验证通过：
  - 新增两组测试
  - `PhotoMemoiOSMVP` Debug iOS Simulator build
  - `PhotoMemoiOS` Debug iOS Simulator build
  - `PhotoMemoShareExtension` Debug iOS Simulator build
  - `PhotoMemo` Debug macOS build
  - `git diff --check`
- 未手动验证：
  - 真机 Apple Photos 相册创建
  - 真机 Logo 上传后的最终渲染效果
  - Share 后使用新建相册 + 自选 Logo 的完整实机链路

## 2026-06-28 MVP Share Pipeline Gap Closure

- 本轮继续收敛 MVP 到：
  - Apple Photos -> Share -> PhotoMemo -> Processing -> Notification -> Apple Photos
  - 原图不被修改
  - 输出为原图 + 底部边框的新图片
  - 元数据尽量继承原图，只有输出分辨率跟随新画布更新
- 已补齐输出命名规则：
  - `IMG_1234` 首次输出为 `IMG_1234(1).jpg`
  - 再次输出为 `IMG_1234(2).jpg`
  - 继续处理 `IMG_1234(1)` 不会生成 `IMG_1234(1)(1)`
- 已补齐 iOS MVP `设为生效` 的真实落盘：
  - 当前四个自定义区的单行 Content Builder 内容会写入共享 `Template`
  - Share Extension 读取 `SharedBatchConfigurationSnapshotService` 时可以拿到这份 active configuration
  - 编辑器中 token 仍展示示例值，但保存时写入真实渲染 token，例如 `{{model}}` / `{{capture_date_short}}` / `{{camera_summary}}`
- UI 反馈补齐：
  - 编辑区域或时间锚点后状态显示 `有未生效修改`
  - 点击 `设为生效` 后显示 `已生效`
- Profile 控制形态已调整：
  - 右侧只保留 `保存` 和小号重置图标按钮
  - 从 Preset 下拉切换到不同配置后，会弹出原生确认对话
  - 用户可选择 `保存为生效配置` 或 `仅切换查看`
- 时间锚点已纳入 MVP 保存范围：
  - 保存时会创建或更新 `.birthday` Anchor
  - 该 Anchor 会写入共享 `selectedAnchorID`
  - Share 后真实渲染中的 `{{anchor_age_text}}` 会走保存后的 Anchor，而不是 MVP 页面里的 mock 预览日期
- Logo / 输出目标也已跟随 `保存` 写入共享设置：
  - Apple 标识保存为 Apple badge
  - 输出目标写入共享相册选择状态
- 模块插入交互已从自绘遮罩改为原生 sheet：
  - 使用 medium / large detent
  - 列表行点选后直接加入当前区域
  - 去掉“先选模块再点插入”的工具感
- MVP 可见语言继续收口：
  - 移除 mock / UI-only / 测试说明类文案
  - `Token` 改为 `插入信息`
  - 输出说明改为面向用户的保存行为说明
- iOS 模块 token 映射收口：
  - 新增 `IOSInsertableModule.rendererToken`
  - MVP 页面不再维护第二套 renderer token switch
- 当前仍未完成：
  - 真机 Apple Photos share-sheet 手动回归
  - 多张照片分享后的真实输出视觉检查
  - 自选 Logo 上传后的真机视觉检查
  - 新建/指定相册后的真机 Apple Photos 写入检查
- 验证通过：
  - `PhotoMemoTests/PhotoFileNameResolverTests`
  - `PhotoMemoiOSMVP` Debug iOS Simulator build
  - `PhotoMemoiOSMVP` Profile 保存/重置交互修订后再次构建通过
  - `PhotoMemoiOSMVP` Time Anchor 持久化与原生模块 sheet 修订后再次构建通过
  - `PhotoMemoiOS` Debug iOS Simulator build
  - `PhotoMemoiOS` Time Anchor 持久化与原生模块 sheet 修订后再次构建通过
  - `PhotoMemoShareExtension` Debug iOS Simulator build
  - `PhotoMemoShareExtension` Time Anchor 持久化修订后再次构建通过
  - `PhotoMemo` Debug macOS build
  - `git diff --check`

## 2026-06-28 Apple First-Party UI Polish

- 本轮根据 Apple Photos / Journal / Health 的方向，只做 Configuration Center 表层 UI polish，不改功能与架构。
- 视觉方向：
  - Preview 继续作为第一视觉锚点。
  - 控制区降低视觉重量，避免工具软件感。
  - 使用 system colors / native typography / SF Symbols。
  - 扩大留白，统一圆角，减少边框、阴影和强调色。
- 已同步修改：
  - `ConfigurationUI` 统一系统背景、圆角、间距、hairline、shadow token。
  - macOS `InteractiveMemoryCard` 放大呼吸感，弱化顶部配置条与预览外框。
  - iOS `ConfigurationCenteriOSView` 放松 sidebar / detail spacing，降低按钮和面板的装饰性。
  - iOS MVP 测试页将 Preview 前置，并把 Profile / Preview / Output 等命名收敛到更接近产品语义的中文。
- 明确未改：
  - Renderer
  - Metadata
  - Export
  - Share Extension behavior
  - Photo Library behavior
  - Layout Engine
  - Memory Engine runtime
- 验证通过：
  - `git diff --check`
  - `PhotoMemo` Debug macOS build
  - `PhotoMemoiOS` Debug iOS Simulator build，destination `iPhone 17 Pro, iOS 26.4`
  - `PhotoMemoiOSMVP` Debug iOS Simulator build，destination `iPhone 17 Pro, iOS 26.4`
  - `PhotoMemoShareExtension` Debug iOS Simulator build

## 2026-06-28 MVP Single-Line Content Builder Refinement

- 本轮根据最新 MVP 边界修正：
  - MVP 页面继续保留 `记忆档案 / 时间锚点 / 智能模块 / 写入记忆` 这条线。
  - 四个自定义区域从两段式输入改为单行 Content Builder。
  - Content Builder 内部统一为 item 模型：
    - Text
    - Token
    - Separator
    - Line Break（模型预留，当前单行显示不暴露为换行操作）
  - Token 与分隔符作为同一行 chip 追加，预览仍只展示底部边框。
  - `应用` 按钮语义收敛为 `设为生效`，用于后续 Share 自动处理读取当前生效配置。
- 本轮仍未接入：
  - Share 后前后台自动处理配置读取改造
  - 真实 EXIF token 替换当前 MVP mock 值
  - Preset 持久化重建
- 验证通过：
  - `git diff --check`
  - `PhotoMemoiOSMVP` Debug iOS Simulator build，destination `iPhone 17 Pro, iOS 26.4`
  - `PhotoMemoiOS` Debug iOS Simulator build，destination `iPhone 17 Pro, iOS 26.4`

## 2026-06-28 Compact Border-Only Preview Correction

- 本轮根据真机检查反馈，进一步修正 preview 展示区域：
  - preview 现在只展示 Compact White Information Bar 底部边框。
  - 上方 photo placeholder / photo area 已从预览中移除。
  - 边框本身仍保持 `width * barHeightToWidth` 的原始比例，不拉伸、不重排。
- 已同步修改：
  - macOS `InteractiveMemoryCard`
  - iOS `ConfigurationCenteriOSView`
  - iOS MVP `PhotoMemoiOSMVPTestView`
- 验证通过：
  - `git diff --check`
  - `PhotoMemo` Debug macOS build
  - `PhotoMemoiOS` Debug iOS Simulator build，destination `iPhone 17 Pro, iOS 26.4`
  - `PhotoMemoiOSMVP` Debug iOS Simulator build，destination `iPhone 17 Pro, iOS 26.4`
  - `PhotoMemoiOSMVP` Debug connected-device build，destination `iPhone7`
- 已覆盖安装并启动到连接设备：
  - device: `iPhone7`
  - bundle id: `com.serydoo.PhotoMemo.iOS.MVP`
- 后续编译与文件整理补充：
  - 清理了 iOS compact preview 中已经不再使用的旧 PM-004/footer/slot helper。
  - 保留当前 compact 信息栏路径，减少后续维护噪音。
  - `PhotoMemo` Debug macOS build 通过。
  - `PhotoMemoiOS` Debug iOS Simulator build 通过。
  - `PhotoMemoiOSMVP` Debug iOS Simulator build 通过。
  - `PhotoMemoShareExtension` Debug iOS Simulator build 通过。
  - `RendererConstantsTests` 通过。
  - `CaptureTimeResolverTests` 通过。
  - 全量 `PhotoMemoTests` 首次运行时仅 `ClassicWhiteSnapshotTests.landscapeStandardSnapshotStaysStable()` 出现 93 像素快照差异；该单测随后单独重跑通过。
  - 第二次全量测试启动即被系统杀掉（exit 137），更像当前机器负载/内存压力，不作为代码断言失败处理。

## 2026-06-28 Compact White Information Bar Correction

- 本轮根据用户提供的原图/效果图成对样本，修正底部边框方向：
  - 当前参考图目标不是 PM-004 的 A/B/C/D 大 Memory Document 布局。
  - 当前参考图目标是 Compact White Information Bar：照片区 + 紧凑双列白色信息栏。
- `RendererConstants` 新增 `CompactInformationBar` 参数：
  - 竖图底栏高度：`W * 0.1660`
  - 横图底栏高度：`W * 0.1266`
  - 左列 / 右列 / Logo / Divider 坐标
  - Primary / Secondary 字号比例
  - Capture Summary 四项单行输出
- macOS `InteractiveMemoryCard` 已改为按比例缩小的 Compact 输出预览：
  - 左列：Slot A + Slot B
  - 中心：Logo 标识 + Divider
  - 右列：Slot C + Slot D
  - 四行内容仍保持各自 CardRegion 可点击选择。
- 本轮继续补齐精准映射：
  - Slot A / 记录 -> left primary -> `CardTextArea.leftTop`
  - Slot B / 时间线 -> left secondary -> `CardTextArea.leftBottom`
  - Slot C / 拍摄参数 -> right primary -> `CardTextArea.rightTop`
  - Slot D / 记忆 -> right secondary -> `CardTextArea.rightBottom`
- Slot C 已从宽泛的“上下文”收窄为“拍摄参数”，右上角始终服务于四项 Capture Summary。
- iOS MVP Preview 已同步为同一套 Compact 输出预览。
- iOS Configuration Center Preview 已同步为同一套 Compact 输出预览。
- `ImmersWhiteRenderer` 的颜色 token 已指向 Compact 信息栏常量；现有真实输出几何比例本来已接近样本，因此未重写真实 export layout。
- 验证通过：
  - `PhotoMemo` Debug macOS build
  - `PhotoMemoiOS` Debug iOS Simulator build，destination `iPhone 17 Pro, iOS 26.4`
  - `PhotoMemoiOSMVP` Debug iOS Simulator build，destination `iPhone 17 Pro, iOS 26.4`
  - `PhotoMemoTests/RendererConstantsTests`
  - `git diff --check`
- 未手动验证：
  - macOS 运行时视觉截图
  - iOS Simulator 视觉截图
  - reference image golden export comparison

## 2026-06-28 PM-004 Border Preview Foundation

- 本轮根据 Atlas 中整理出的边框规范，先落地 PM-004 的 preview 基础，不直接迁移真实 export renderer。
- 新增：
  - `Source/PhotoMemo/PhotoMemo/Renderers/RendererConstants.swift`
  - `Tests/PhotoMemoTests/RendererTests/RendererConstantsTests.swift`
- `RendererConstants` 目前冻结：
  - 8pt Grid token
  - PM-004 Typography token
  - Memory Document / Information Bar 颜色
  - Photo Area / Information Bar 几何比例
  - Information Bar 内 0-100% Anchor Coordinates
  - Slot A Recorder: X=6%, Y=18%
  - Slot B Timeline: X=42%, Y=18%
  - Slot C Capture Summary: X=74%, Y=18%
  - Slot D Memory Block: X=6%, Y=60%，最大权重
  - Badge: 右下预留装饰区域
  - Capture Summary 只允许四项：焦距 / 光圈 / ISO / 快门
- macOS `InteractiveMemoryCard` 已从旧左右两列结构改为：
  - Photo Area
  - Information Bar
  - A/B/C 上排
  - D 左下最大 Memory Block
  - Badge 右下
  - Icon region 仍保留可点击路由
- iOS MVP Preview 已从五列等分白底栏改为同一套 PM-004 坐标系统。
- 本轮仍未迁移真实输出 renderer：
  - `ImmersWhiteRenderer`
  - `ClassicWhiteCardRenderer`
  - `ClassicWhiteRenderer`
  - `RecordCardExportService`
- 验证通过：
  - `PhotoMemoTests/RendererConstantsTests`
  - `PhotoMemoiOSMVP` Debug iOS Simulator build
  - `PhotoMemo` Debug macOS build
  - `git diff --check`
- 未手动验证：
  - iOS 真机/模拟器视觉截图
  - macOS 运行时 hover/click 路由
  - 真实 export 输出像素级一致性

## 2026-06-26 iOS MVP Test Module Scaffold

- 本轮新增 iOS-only MVP 测试入口，不改 macOS 主流程，也不改正式 iOS Configuration Center 架构。
- 后续已补成独立 iPhone 测试 App：
  - target: `PhotoMemoiOSMVP`
  - scheme: `PhotoMemoiOSMVP`
  - bundle id: `com.serydoo.PhotoMemo.iOS.MVP`
- 新增临时入口切换：
  - `当前配置中心`
  - `MVP 测试页`
- iOS Root 通过临时入口进入 MVP 测试页，便于在手机上直接验证交互方向。
- 独立 MVP App 默认进入：
  - `MVP 测试页`
- 同时保留独立存储的临时入口切换，不影响现有 `PhotoMemoiOS` 的入口状态。
- 新增 iOS MVP 测试页，复用：
  - `ConfigurationSession`
  - 当前 mock preview 文本
  - 当前模块枚举
- 新增共享 iOS 模块目录，避免旧 iOS 页面和 MVP 测试页各自维护一套模块定义。
- MVP 测试页当前包含：
  - Profile 区：
    - 当前 Preset 选择
    - 应用 / 默认 / 重置
    - 当前记忆对象摘要
  - Sticky Preview 区：
    - 白色底栏记忆卡结构
    - 左侧：记录者 / 记录时间
    - 中间：Logo 标识
    - 右侧：拍摄参数 / 智能时间结果
  - 自定义功能区：
    - `记录`
    - `时间线`
    - `上下文`
    - `记忆`
    - 输入后实时刷新 Preview
  - 模块插入交互：
    - 编辑区聚焦后弹出约 70% 屏宽模块窗
    - 选中模块后插入到当前输入区域
  - Logo 标识：
    - 默认 Apple mini-logo
    - 可切换到自选上传占位
  - `途途生日` 日期输入
  - 输出区域 UI-only 测试项
  - 写入记忆 UI-only 状态和预览
- 页面行为目前为：
  - Profile 在滚动层内，向上滚动后被带走
  - Preview 固定优先显示
  - 自定义功能区在 Preview 下方随滚动淡入
- 新增智能时间格式化能力：
  - 基于 mock 拍摄时间与 `途途生日` 的差值输出
  - 默认格式 `X年X个月X天`
  - 若差值小于 1 年则不显示 `X年`
  - 兜底可输出 `X天`
- 新增测试覆盖：
  - `CaptureTimeResolverTests`
- 本轮仍然严格保持：
  - iOS-only
  - mock-first
  - UI-only
  - 不接 Renderer
  - 不接 Metadata pipeline
  - 不接 Export
  - 不接真实 Photo Library 写入
  - 不改 Layout Engine
- 验证通过：
  - `PhotoMemoTests/CaptureTimeResolverTests`
  - `PhotoMemoiOS` Debug iOS Simulator build
  - `PhotoMemoiOS` Debug connected-device build
  - 安装到连接 iPhone
  - 启动 `com.serydoo.PhotoMemo.iOS`
- 独立 MVP App 验证通过：
  - `PhotoMemoiOSMVP` target / scheme 已被 Xcode 识别
  - `PhotoMemoiOSMVP` Debug iOS Simulator build
  - `PhotoMemoiOSMVP` Debug connected-device build
  - 已为 `com.serydoo.PhotoMemo.iOS.MVP` 自动生成 Development provisioning profile
  - 已安装到连接 iPhone
  - 自动启动被设备锁屏阻止，需要设备解锁后手动打开或再次触发 launch

## 2026-06-25 iOS Compact Profile And Module Library Refinement

- 本轮继续 iOS Configuration Center 局部打磨。
- iOS 顶部导航标题从 `PhotoMemo` 改为：
  - `PhotoMemo 配置中心`
- 顶部 `总体配置` 区进一步压缩为两行：
  - 第一行：记忆预设下拉、编辑、重置、保存并生效 / 已生效
  - 第二行：自动输出摘要
- 区域配置编辑器调整：
  - 上方状态文案从重复的 `已保存` 改为 `已生效`
  - 保存按钮保留 `保存配置 / 已保存`
  - 配置选择、编辑按钮和状态保持横向排列
- 自定义输入窗口调整：
  - 用户文字、已插入模块和继续输入区处于同一个编辑容器
  - 已插入模块改为横向 token strip
  - 点击多个模块会继续追加到当前区域配置
- `可插入模块` 调整：
  - 默认展示当前区域常用的 6 个模块
  - 新增 `更多模块` 下拉，展示其余可用模块
  - 目前未接真实 EXIF 的扩展字段插入后输出为空，不生成假值
- 左侧 Library 调整：
  - `人物` 分组下方新增 `+ 新增人物` 入口
  - `旅行` 分组改为 `事件`
  - `事件` 分组下方新增 `+ 新增事件` 入口
- 本轮仍然是 iOS-only / UI-only / mock-first，没有接入：
  - Renderer
  - Metadata
  - Export
  - Share Extension behavior
  - Photo Library behavior
  - Layout Engine
  - real Memory Engine runtime
- 验证通过：
  - `git diff --check`
  - `PhotoMemoiOS` Debug iOS Simulator build
  - `PhotoMemoiOS` Debug connected-device build
- 已安装并启动到连接的 iPhone：
  - bundle id: `com.serydoo.PhotoMemo.iOS`

## 2026-06-25 iOS Two-Column Configuration Center Polish

- 本轮继续 iOS Configuration Center 打磨。
- iOS 主界面已切到两段式：
  - 左侧为 Apple Mail 风格资料库目录
  - 右侧为 Profile / Subject / Memory Card / Object Inspector / Output / Guidance 详情区
- 左侧包含：
  - 资料库
  - 人物
  - 旅行
  - 卡片区域
  - 记忆模块
  - 输出内容
  - 时间锚点说明
  - 记忆对象资料库说明
- 点击 Subject 后，右侧 Profile 区下方展示 `MemorySubjectEditorView`，不再直接占满右侧或改成 sheet。
- 点击卡片区域后，右侧展示：
  - 与 macOS 对齐的四区域 + 图标 Memory Card Preview
  - Region Strip
  - 同一套 `InspectorProvider` 对象检查器
  - 可插入模块库
- iOS 顶部 `总体配置` 支持：
  - 下拉选择记忆预设
  - 重命名
  - 重置
  - 保存并生效状态
- macOS 中间顶部同步补齐：
  - `总体配置`
  - 重置
  - 保存并生效
- `ConfigurationSession` 新增轻量 UI 状态：
  - `appliedMemoryPresetID`
  - `selectedMemoryPresetIsApplied`
  - `applySelectedMemoryPreset()`
  - `resetSelectedMemoryPreset()`
- 本轮仍然是 UI-only / mock-first，没有接入：
  - Renderer
  - Metadata
  - Export
  - Share Extension behavior
  - Photo Library behavior
  - Layout Engine
  - real Memory Engine runtime
- 验证通过：
  - `git diff --check`
  - `PhotoMemoiOS` Debug iOS Simulator build
  - `PhotoMemo` Debug macOS build
  - `PhotoMemoiOS` Debug connected-device build
- 已安装到连接的 iPhone：
  - bundle id: `com.serydoo.PhotoMemo.iOS`
- 自动启动被设备锁屏阻止：
  - `Unable to launch ... because the device was not, or could not be, unlocked`

## 2026-06-25 iOS Preview-First Configuration Refinement

- 本轮只修改 iOS 端 Configuration Center。
- macOS Configuration Center 保持现有结构。
- 本轮继续压缩 iOS 信息层级，让 Preview 成为第一视觉：
  - `总体配置` 从大卡片压缩为顶部薄工具条
  - `当前配置预览` 放大，优先占据右侧上方空间
  - 左侧资料库整体下移
  - 左侧目录行高压缩
- iOS 左侧移除：
  - `当前配置展示`
- iOS 左侧调整：
  - `配置说明` 单独进入低优先级 `说明` 分组
  - 不再和 `输出` 同级
- 卡片区域右侧不再直接复用 macOS 完整 Object Inspector。
- 新增 iOS 专用轻量区域编辑器：
  - 自由输入当前区域内容
  - 插入模块以浅色小方块展示
  - 每个插入模块可删除
  - 输入和模块变化实时刷新 Preview
- 非文字区域（例如图标）不再显示可插入模块。
- 文字区域显示底部模块插入区：
  - 记录 / 时间线 / 上下文：简化为配置窗口
  - 记忆：保留紧凑系统模块提示
- 本轮仍然是 mock-only / UI-only，没有接入：
  - Renderer
  - Metadata
  - Export
  - Share Extension behavior
  - Photo Library behavior
  - Layout Engine
  - real Memory Engine runtime
- 验证通过：
  - `git diff --check`
  - `PhotoMemoiOS` Debug iOS Simulator build
  - `PhotoMemo` Debug macOS build
  - `PhotoMemoiOS` Debug connected-device build
- 已安装并启动到连接的 iPhone。

## 2026-06-25 iOS Configuration Center Polish Shell

- 本轮开始 iOS 版本打磨准备。
- 新增 iOS-only：
  - `Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift`
- `PhotoMemoRootSceneView` 现在按平台选择：
  - iOS -> `ConfigurationCenteriOSView`
  - macOS -> `ConfigurationCenterView`
- iOS 第一版布局：
  - 左侧控制列：
    - Subject
    - Block Configuration
    - Content Library
    - Output
    - 写入记忆
  - 右侧预览列：
    - Profile
    - 保存并生效
    - 当前配置预览
- Subject 点击后进入档案管理 Sheet。
- Sheet 当前支持 mock 编辑：
  - 对象定义
  - 姓名 / 昵称
  - 记忆显示名称
  - 人生节点 / 时间锚点
- 本轮仍然是 UI-only / mock-first。
- 没有修改：
  - Renderer
  - Metadata
  - Export
  - Share Extension behavior
  - Photo Library behavior
  - Layout Engine
  - Memory Engine runtime
- 验证通过：
  - `PhotoMemoiOS` Debug iOS Simulator build
  - `PhotoMemo` Debug macOS build

## 2026-06-24 PDR-005 Memory Language Layer

- 本轮是 Repository Amendment。
- 没有修改：
  - Swift
  - Renderer
  - Metadata
  - Export
  - Share Extension
  - Photo Library behavior
  - Layout Engine
  - Memory Engine runtime
- 新增：
  - `Docs/PDR/PDR-005_Memory_Language_Layer.md`
- PDR-005 冻结：
  - MemoryBlock 是内容资产，不是布局资产
  - Subject + Action + Result 是 `Preset Schema #001`，不是底层 Core Model
  - 底层长期模型是 Field-Based MemoryBlock
  - 概念形态：

```text
MemoryBlock
-> BlockField
-> Value Source
```

- Value Source 包括：
  - Fixed Text
  - Token Binding
  - Smart Module Binding
  - Custom Field Binding
- Block Template 定义 field schema，不定义 slot position。
- Module 负责计算 field value，不定义整个 MemoryBlock。
- IA-003A 仍然是 MemorySubject Adapter。
- PDR-005 的首个实现落点是：

```text
IA-003C Memory Block Resolver
```

## 2026-06-24 IA-002 Freeze / IA-003 Product Realization

- 用户正式确认：

```text
IA-002 can end.
Product Definition -> Product Realization.
```

- IA-002 Architecture 冻结：
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
  - Region Strip
- 以后 UI 可以 Polish，但不能推翻 IA-002 架构。
- 五条 V3 设计基石登记为当前事实：
  - Configuration Center edits Objects, not Data.
  - Everything starts from the Memory Card.
  - Configuration Center previews the real Memory Card, not an abstract layout.
  - Capture-Time Principle.
  - Memory Subject = Identity + MemoryBehavior.
- 下一阶段：

```text
IA-003 Memory Engine Integration
```

- 目标：

```text
Photo
-> EXIF
-> Memory Subject
-> Configuration Snapshot
-> Memory Engine
-> Memory Card
-> Renderer
```

- 开发顺序：

```text
IA-003A MemorySubject Adapter
-> IA-003B Configuration Snapshot
-> IA-003C Memory Block Resolver
-> IA-003D CaptureTimeResolver
-> IA-003E Interactive Memory Card connects real data
-> IA-003F Renderer
```

- 下一轮如果开始写代码，应从 IA-003A 开始。
- IA-003A 只做 `PersonalProfile` / 现有身份配置到 `MemorySubject` 的 adapter 边界。
- IA-003A 不应修改：
  - Renderer
  - Metadata
  - Export
  - Share Extension
  - Photo Library behavior
  - Layout Engine

## 2026-06-24 Memory Card Preview Polish Amendment

- 新冻结原则：

```text
Preview is the Renderer before Rendering.
```

- 中文理解：
  - Configuration Center 里的 Preview，本质上就是 Renderer 的实时映射。
- 中间区域正式定义为：
  - Memory Card Preview
- 中间区域不再承载：
  - Photo
  - placeholder photo
  - abstract editor layout
  - visible configuration grid
- 产品边界：
  - Photos belong to Apple Photos.
  - PhotoMemo owns the Memory Card.
- Preview 默认应该像已经生成好的 Memory Card。
- 只有 hover / selected / Region Strip 暗示可编辑性。
- 本轮 UI polish：
  - 去掉 `InteractiveMemoryCard` 的灰色背景
  - 弱化卡片边框和阴影
  - 去掉 slot 区域灰底
  - 降低默认分隔线可见度
  - 保留 Region Strip 与 Object Inspector 路由

## 2026-06-24 IA-002C Real Bottom Card Preview Amendment

- 本轮从 tag 回滚点继续：

```text
ia-002c-ui-polish-checkpoint
0176b29 Checkpoint Configuration Center UI polish
```

- 本轮只重设计中间 `InteractiveMemoryCard`。
- 保留现有：
  - Library
  - Object Inspector
  - Inspector sections
  - Token UI
  - mock-only 边界
- 严格没有接入：
  - Renderer
  - Metadata
  - Export
  - Share Extension intake
  - Photo Library
  - Memory Engine runtime
  - `PersonalProfile` adapter
- 新冻结原则：

```text
Configuration Center previews the real Memory Card, not an abstract layout.
```

- 中间卡片改为真实 Bottom Card 结构：

```text
Decoration
-> Slot A
-> Slot B
-> Slot C + Slot D
```

- Decoration 包含：
  - Icon
  - Badge
- 四个可编辑 Slot：
  - Slot A = Recorder
  - Slot B = Timeline
  - Slot C = Location
  - Slot D = Memory Expression
- Region Strip 已加入卡片下方：
  - Recorder
  - Timeline
  - Location
  - Memory
- Region Strip 与真实卡片区域选择同一组 `CardRegion`。
- 同步更新：
  - `Docs/PDR/PDR-004_Configuration_Center_Architecture.md`
  - `Docs/FROZEN_REGISTRY.md`
  - `Docs/DESIGN_DECISIONS.md`
  - `Docs/CURRENT_STATUS.md`

## 2026-06-24 IA-002C UI Polish Foundation

- 本轮回应第一次 PhotoMemo V3 可视化 review。
- 仍然是 mock-only Configuration Center UI polish。
- 严格没有接入：
  - Renderer
  - Metadata
  - Export
  - Share Extension intake
  - Photo Library
  - Memory Engine runtime
  - `PersonalProfile` adapter
- 中间 Memory Card 已从六宫格改为真实 Bottom Card 构图。
- 所有 Memory Card 点击仍然通过 `CardRegion`。
- 当前视觉层级开始转向：
  - Icon
  - Slot D
  - Slot A
  - Slot B
  - Slot C
- 左侧 Sidebar 已升级为 Library 分组：
  - People
  - Travel
  - New Subject
- 新增 Configuration UI design-system primitives：
  - `InspectorSectionView`
  - `InspectorPropertyRow`
- Object Inspector 改为更清晰的 section 节奏和更大的 section 间距。
- Memory Subject Inspector 改为：
  - Overview
  - Behavior
- Memory Expression Inspector 改为：
  - Memory Expression
  - Properties
  - Token Library
- Token 从 bordered button 转向 inline Apple Token / capsule token。
- Mock decoration symbols 已统一为更 Apple 的 SF Symbols：
  - `person.fill`
  - `camera.fill`
  - `location.fill`
  - `flag.fill`
  - `apple.logo`
- 验证已通过：
  - `PhotoMemo`
  - `PhotoMemoiOS`
  - `PhotoMemoShareExtension`
- 手动查看注意：
  - `/tmp/PhotoMemoDerivedData` 的新构建可以直接运行
  - 但 Computer Use 仍把 `PhotoMemo` app 名称解析到旧 bundle 路径
  - 后续如果要稳定截图，应先清理旧 DerivedData / LaunchServices 缓存或用唯一 bundle id 运行

## 2026-06-24 Repository Amendment: Configuration Center Architecture Revision A

- 本轮是 Repository Amendment，不是开发指令。
- 严格没有修改：
  - Swift
  - SwiftUI
  - Renderer
  - Metadata
  - Export
  - Share Extension
  - Photo Library
  - Memory Engine runtime
  - adapter implementation
- 新增：
  - `Docs/PDR/PDR-004_Configuration_Center_Architecture.md`
- PDR-004 冻结：

```text
Configuration Center edits Objects, not Data.
```

```text
Everything starts from the Memory Card.
```

```text
Library
-> Interactive Memory Card
-> Object Inspector
```

- Configuration Center 正式定义为：
  - Memory Engine Configuration Center
  - 长期对象定义中心
  - 不是 Settings
  - 不是 Workspace
- Library 正式定义为：
  - Memory Object Library
- Interactive Memory Card 正式定义为：
  - Primary Object
  - Preview + Navigation + Selection
  - 不显示照片、示例图、背景图、Renderer Preview
- Object Inspector 正式替代 generic Editor 语言。
- Object Inspector 统一结构：
  - Overview
  - Properties
  - Behavior
  - Resources
  - Preview
- `CardRegion` 冻结：
  - `subject`
  - `icon`
  - `badge`
  - `slotA`
  - `slotB`
  - `slotC`
  - `slotD`
- `CardRegion -> InspectorProvider -> Object Inspector` 成为正式路由。
- `MemorySubject -> Identity + MemoryBehavior` 成为正式模型边界。
- `MemoryExpression -> MemoryTextBlock + MemoryTokenBlock` 成为正式表达结构。
- `TokenCategory` 冻结为：
  - Memory
  - Photo
  - System
- `DecorationAsset` 统一 Icon / Badge / Future Decoration。
- `Logo` 不再作为独立配置对象。
- `ConfigurationSession` 保持轻量，只负责 Selection / Hover / Editing / Future Undo / Future Redo。
- Capture-Time Principle 冻结：
  - Memory Token 基于 Photo Capture Date + Reference Date
  - 重新导出不得改变 Memory Expression
- PhotoMemo Design System 正式进入 Repository 事实层。
- 同步更新：
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
  - `Docs/CURRENT_STATUS.md`
- 下一轮顺序已修订：
  1. IA-002C Object Inspector
  2. IA-002D MemorySubject Adapter
- 验证：
  - `git diff --check` 通过
  - 未运行 build，因为本轮是 documentation-only repository amendment

## 2026-06-24 Sprint IA-002B Interactive Memory Card

- 本轮继续 IA-002 Configuration Center UI Architecture。
- 严格没有接入：
  - Renderer
  - Metadata
  - Export
  - Share Extension intake
  - Photo Library
  - Memory Engine runtime
  - `PersonalProfile` adapter
- 本轮核心原则：

```text
Everything starts from the Memory Card.
```

- `CardRegion` 已正式作为交互坐标冻结：
  - `subject`
  - `icon`
  - `badge`
  - `slotA`
  - `slotB`
  - `slotC`
  - `slotD`
- 新增：
  - `CardRegionBehavior`
  - `InspectorProvider`
  - `TokenCategory`
  - `MemoryBehavior`
- `CardSelection` 现在包含：
  - selected region
  - hovered region
- `InteractiveMemoryCard` 现在支持：
  - 点击 Subject / Icon / Badge / SlotA / SlotB / SlotC / SlotD
  - 当前 region selection
  - hover highlight
  - 轻量 Apple-native animation
  - region accessibility identifier / label
- `InspectorView` 不再直接膨胀 `switch(region)`，改为：

```text
CardRegion
-> CardRegionBehavior
-> InspectorProvider
-> Inspector View
```

- `MemoryBlock` 拆分为：
  - `MemoryTextBlock`
  - `MemoryTokenBlock`
  - `MemoryBlock`
- `TokenLibrary` 现在使用 `TokenCategory` 管理 Memory / Photo / System。
- `MemorySubject` 不再直接持有 behavior 字段，改为：

```text
MemorySubject
-> MemoryBehavior
```

- `MemoryBehavior` 当前包含：
  - Primary Anchor
  - Icon Strategy
  - Badge Strategy
  - Memory Expression

验证已通过：

- `PhotoMemo`
- `PhotoMemoiOS`
- `PhotoMemoShareExtension`
- `git diff --check`

未手动验证：

- 运行中点击每个 Memory Card region 的真实视觉反馈
- 指针设备 hover 体验
- VoiceOver 读出顺序

下一轮建议：

1. 进入 IA-002C `Object Inspector`
2. 建立 Object Inspector Design System
3. 继续使用 Mock Data
4. 不接入 Renderer / Metadata / Export / Memory Engine Runtime / PersonalProfile Adapter
5. 等 Object Inspector 稳定后，再进入 IA-002D `MemorySubject Adapter`

## 2026-06-24 Sprint IA-002A Configuration Center Skeleton

- 本轮正式进入 V3 Configuration Center UI skeleton。
- 严格没有接入：
  - Renderer
  - Metadata
  - Export
  - Share Extension intake
  - Memory Engine runtime behavior
- 新增 `Source/PhotoMemo/PhotoMemo/ConfigurationCenter/`，包含：
  - `Sidebar`
  - `MemoryCard`
  - `Inspector`
  - `Editors`
  - `Components`
  - `Models`
- 新增 skeleton 类型：
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
  - `ConfigurationCenterState`
  - `ConfigurationSession`
- 新增三栏 UI：
  - 左侧 `MemorySubjectListView`
  - 中间 `InteractiveMemoryCard`
  - 右侧 `InspectorView`
- 新增 Inspector skeleton：
  - `MemorySubjectEditorView`
  - `ExpressionEditor`
  - `TokenPicker`
  - `IconLibraryView`
  - `BadgeLibraryView`
- `PhotoMemoRootSceneView` 现在直接打开 `ConfigurationCenterView`。
- 旧 `MainView`、真实导入/渲染/导出链路仍保留，未接入本轮 UI skeleton。
- 验证已通过：
  - `PhotoMemo`
  - `PhotoMemoiOS`
  - `PhotoMemoShareExtension`

下一轮建议：

1. 对 IA-002A 进行 Architecture Review，确认 `MemorySubject / DecorationAsset / MemoryBlock / TokenLibrary` 边界
2. 再开始 IA-002B，把 mock `MemorySubject` 与旧 `PersonalProfile` 做 adapter，而不是直接替换真实业务
3. 继续保持 Renderer / Metadata / Export 不动，直到 Configuration Experience 骨架冻结

## 2026-06-24 RSR-001 Repository Simplification Review

- 本轮严格保持文档切片，没有改：
  - Swift
  - SwiftUI
  - Renderer
  - Engine
  - Metadata
  - Export
  - Database
  - Xcode project
  - Pipeline

- 本轮目标从 Repository Refactor 切换为 Repository Simplification：
  - 删除或降级不再符合 PhotoMemo Product Philosophy 的工作台、导入、仪表盘、任务中心、工作区、大批量优先叙事
  - 把当前仓库语言统一到 Configuration Center / Preset / Configuration Preview / Apple Photos Lifecycle

- 本轮新增：
  - `Docs/REPOSITORY_VOCABULARY.md`
  - `Docs/REPOSITORY_SIMPLIFICATION_REPORT.md`

- 本轮重写：
  - `README.md`
    - 保留 Repository Mission：
      - `PhotoMemo exists to help people read their memories, not just store their photos.`
      - `PhotoMemo 存在的意义，不是帮助人们保存照片，而是帮助人们阅读回忆。`
      - `Photos preserve moments. PhotoMemo reveals their meaning.`
      - `照片记录瞬间。PhotoMemo 赋予意义。`
    - 删除旧的 import-first 首页主链、旧路线图和旧 batch-first 暗示
    - 新增 Apple Photos Lifecycle / Behavior State Machine / Configuration Snapshot / batch scale

- 本轮同步：
  - `PROJECT_CONSTITUTION.md`
  - `Docs/MASTER_PLAN.md`
  - `RepositoryAudit.md`
  - `AI_CONTEXT.md`
  - `AGENTS.md`
  - `Docs/Interaction/IA-001_Interaction_Architecture.md`
  - `Docs/Behavior/BEHAVIOR_SPECIFICATION.md`
  - `Docs/Configuration/CONFIGURATION_MODEL.md`
  - `Docs/DESIGN_DECISIONS.md`
  - `Docs/FROZEN_REGISTRY.md`
  - `Docs/DOCUMENT_INDEX.md`
  - `Docs/CURRENT_STATUS.md`

- RSR-001 冻结：
  - Configuration Center
  - Preset
  - Configuration Preview
  - Apple Photos Lifecycle
  - Behavior State Machine
  - Configuration Snapshot
  - batch scale:
    - Primary: 1-20
    - Secondary: 20-50
    - Advanced: 50+

- 当前 Daily Workflow：

```text
Apple Photos
-> Share
-> PhotoMemo
-> Processing
-> Notification
-> Apple Photos
```

- 当前 Design Review 结束语：

```text
Every review should leave the repository simpler than before.
```

```text
每一次设计评审，都应该让 PhotoMemo 比昨天更简单一点。
```

- 后续建议：
  1. 研究规格稳定后，再决定旧 Workspace 文档归档/改名/迁移
  2. 不要马上改 Swift 中的 `Workspace*` / `Template` / `Preview` 标识，除非单独做 code-safe terminology refactor
  3. 下一次 runtime 恢复后再审查用户可见字符串里的 template / preview / import

## 2026-06-23 IA-001A Behavior / Boundary / Mission 补齐

- 本轮继续保持文档切片，没有改：
  - Swift
  - SwiftUI
  - Renderer
  - Engine
  - Metadata
  - Export
  - Database
  - Pipeline

- 本轮补齐的核心不是新设计，而是把第一轮 IA-001 冻结结果继续补成完整 repository product definition。

- 本轮新增：
  - `Docs/NEVER_BREAK.md`
  - `Docs/PDR/PDR_INDEX.md`

- 本轮完善：
  - `PROJECT_PHILOSOPHY.md`
    - 新增 Product Boundary 表格
    - 明确 Apple Photos / PhotoMemo 责任边界
  - `Docs/Behavior/BEHAVIOR_SPECIFICATION.md`
    - 新增 Behavior State Machine
    - 新增 Configuration Snapshot Principle
  - `Docs/Guidelines/APPLE_NATIVE_GUIDELINES.md`
    - 新增 Apple Review Checklist
  - `Docs/Guidelines/LANGUAGE_SYSTEM.md`
    - 正式明确 Soft Limit Language 是语言而不是限制
    - 新增 Smart Batch Recommendation
  - `Docs/Interaction/IA-001_Interaction_Architecture.md`
    - 新增 Smart Batch Recommendation
  - `PROJECT_CONSTITUTION.md`
    - 补齐 Apple Trust Design Rationale
    - 明确来自长期管理超过 11 万张生活照片的真实使用经验
  - `README.md`
    - 新增 Repository Mission：
      - `PhotoMemo exists to help people read their memories, not just store their photos.`
      - `PhotoMemo 存在的意义，不是帮助人们保存照片，而是帮助人们阅读回忆。`
  - `Docs/FROZEN_REGISTRY.md`
    - 登记本轮新增冻结项
  - `Docs/DESIGN_DECISIONS.md`
    - 补登记 Product Boundary / Configuration Snapshot / State Machine / Smart Batch / Apple Review / Never Break / Repository Mission
  - `Docs/DOCUMENT_INDEX.md`
    - 收录 `NEVER_BREAK` 与 `PDR_INDEX`

- 本轮 IA-001A 冻结补齐项：
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

- 验证：
  - 已确认仍然没有实现层文件改动
  - 本轮输出适合继续作为文档冻结的一部分进入后续 Product Design Review 之前的仓库事实层

## 2026-06-23 PM-003 冻结 + IA-001 Interaction Architecture 文档归档

- 本轮严格只做 repository documentation refactor，没有改：
  - Swift
  - SwiftUI
  - Renderer
  - Engine
  - Metadata
  - Export
  - Database
  - Pipeline

- 本轮先完成了 PM-003 第一阶段冻结同步：
  - 新增 `Docs/PM-003_Content_Layout_System.md`
  - 冻结：
    - Semantic Slot Principle
    - Slot A = Recorder
    - Slot B = Capture Summary
    - Slot C = Timeline
    - Slot D = Time Anchor
    - Life Anchor = Life Event
    - Slot D Grammar
    - Expression / Engine 解耦
    - Variable 分类
    - Typography Strategy（语义层）

- 本轮随后进入 IA-001 Interaction Architecture：
  - `PhotoMemo` 正式定义为：
    - Apple 生态内的 `Local First Memory Capability`
  - 同步北极星：
    - 不改变用户管理照片的方式
    - 只改变用户理解照片的方式

- 本轮新增 IA-001 文档群：
  - `Docs/Interaction/IA-001_Interaction_Architecture.md`
  - `Docs/Behavior/BEHAVIOR_SPECIFICATION.md`
  - `Docs/Guidelines/LANGUAGE_SYSTEM.md`
  - `Docs/Guidelines/PRODUCT_PERSONALITY.md`
  - `Docs/Guidelines/APPLE_NATIVE_GUIDELINES.md`
  - `Docs/Configuration/CONFIGURATION_MODEL.md`
  - `Docs/Product/ANTI_GOALS.md`
  - `Docs/DESIGN_DECISIONS.md`
  - `Docs/FROZEN_REGISTRY.md`
  - `Docs/PDR/PDR-003_Interaction_Architecture.md`

- 本轮新增永久理念文档：
  - `LIFE_TIMELINE_PHILOSOPHY.md`
    - 记录“PhotoMemo 不只是帮助用户回忆过去，更帮助用户连接过去、现在与未来……”

- 本轮同步更新顶层事实文档：
  - `PROJECT_CONSTITUTION.md`
  - `Docs/MASTER_PLAN.md`
  - `PROJECT_PHILOSOPHY.md`
  - `AI_CONTEXT.md`
  - `Docs/CURRENT_STATUS.md`
  - `Docs/DOCUMENT_INDEX.md`
  - `CHANGELOG.md`

- IA-001 当前冻结内容：
  - Main App = Configuration Center
  - Primary Entry = `Apple Photos -> Share -> PhotoMemo -> Memory Workflow -> Done`
  - Zero Interaction
  - Quiet Computing
  - Back To Photos
  - Task Recovery
  - Device Adaptive
  - Storage Verification
  - Library Consistency
  - Original Never Changes
  - Metadata Preservation
  - Apple Naming
  - Apple Trust
  - Product Personality
  - Language System
  - Configuration Layer
  - Product Boundary
  - Anti Goals

- 本轮还新增长期规则到 `Docs/MASTER_PLAN.md`：
  - 以后任何新功能必须经过：
    1. `PDR`
    2. `Repository Refactor`
    3. `Architecture Review`
    4. `Implementation`
    5. `Review & Freeze`

- 验证：
  - 已确认本轮无 `.swift`、`.plist`、`project.pbxproj` 实现层文件改动
  - 本轮适合直接作为文档归档同步到 GitHub

## 2026-06-22 Memory Presentation Engine 哲学升级

- 用户明确最高产品定义再次升级：
  - 不再只叫 `Photo Presentation Engine`
  - 更准确是 `Memory Presentation Engine`
  - 因为 PhotoMemo 不只是 present photographs，而是 present memories

- 本轮新增：
  - `PROJECT_PHILOSOPHY.md`
  - `PROJECT_DIRECTION.md`
  - `Docs/03_Research/MemoryPhilosophy.md`
  - `Docs/ARCHITECTURE.md`

- 核心哲学：
  - Photos have timestamps.
  - Memories have positions.
  - EXIF answers when / where / how.
  - Memory Engine answers what this moment means.
  - PhotoMemo preserves both objective metadata and emotional Life Position.

- 新增概念：
  - Life Position
  - Memory Timeline
  - one photo may belong to multiple timelines simultaneously

- 职责边界：
  - Memory Engine only calculates relationships
  - Presentation Engine expresses relationships
  - Layout Engine decides how meaning is presented
  - Renderer simply draws

- 本轮同步：
  - `PROJECT_CONSTITUTION.md`
  - `Docs/MASTER_PLAN.md`
  - `README.md`
  - `PROJECT_RESET.md`
  - `RepositoryAudit.md`
  - `AI.md`
  - `AI_CONTEXT.md`
  - `AGENTS.md`
  - `Docs/CURRENT_STATUS.md`
  - `Docs/DOCUMENT_INDEX.md`
  - `Docs/02_Architecture/README.md`
  - `Docs/03_Research/README.md`

- 未做：
  - 没有改 runtime code
  - 没有改 Renderer
  - 没有改 UI

## 2026-06-22 Project Constitution + Research Methodology

- 用户提供第二份 V2 宪章指令，明确：
  - V2 Reset 已完成
  - 当前阶段是 Research Phase，不是 Development Phase
  - 不继续功能开发
  - 不继续 Renderer 打磨
  - 不继续 UI 调整
  - 当前工作只做 Reverse Engineering / Research
  - 旧文档暂时不要立即迁移，等 Research Specification 稳定后再迁移，避免重复移动

- 本轮新增最高优先级入口：
  - `PROJECT_CONSTITUTION.md`
    - 现在优先级高于 `Docs/MASTER_PLAN.md`
    - 明确项目 mission、first principles、philosophy、immediate task、documentation strategy、research system、measurement rules

- 本轮补齐 Research 体系缺口：
  - `Research/ReverseEngineeringRoadmap.md`
  - `Research/CanvasSpecification.md`
  - `Research/PanelSpecification.md`
  - `Research/AdaptiveRules.md`
  - `Research/MeasurementMethodology.md`

- 本轮同步更新：
  - `Docs/MASTER_PLAN.md`
  - `PROJECT_RESET.md`
  - `RepositoryAudit.md`
  - `Research/README.md`
  - `Research/ResearchHistory.md`
  - `README.md`
  - `AI.md`
  - `AI_CONTEXT.md`
  - `AGENTS.md`
  - `Docs/DOCUMENT_INDEX.md`
  - `Docs/CURRENT_STATUS.md`

- `RepositoryAudit.md` 现在记录了：
  - product direction 文档重叠组
  - MainView refactor 文档重叠组
  - metadata/export 文档重叠组
  - session history 文档重叠组
  - V1 文档与 V2 宪章之间的关键冲突

- 重要边界：
  - 没有移动旧 `Docs/` 文件
  - 没有修改 runtime code
  - 没有改 Renderer / UI / Export / Metadata

下一轮最值得做：

1. 根据 `Research/MeasurementMethodology.md` 开始第一份真实 reverse-engineering 记录模板
2. 扩写 `Research/LayoutSpecification.md`，但仍不要写 LayoutEngine 代码
3. 等 Layout / Canvas / Panel 规格稳定后，再考虑旧 Docs 迁移

## 2026-06-22 PhotoMemo V2 Project Reset 落地

- 用户提供了新的最高优先级重置指令：
  - 停止功能开发
  - 停止 Renderer 继续打磨
  - 停止 UI 扩展
  - PhotoMemo 进入 Research Phase
  - 项目目标从 Photo Watermark App 转向 local-first Photo Presentation Engine

- 新的 V2 主链路：
  - `Photo -> Metadata Engine -> Presentation Engine -> Layout Engine -> Renderer -> Export`

- 本轮落地的永久入口：
  - `Docs/MASTER_PLAN.md`
    - V2 单一入口
    - 记录 vision、phase、roadmap、architecture、next step、forbidden actions
  - `PROJECT_RESET.md`
    - 记录为什么暂停开发、为什么开始 reverse engineering、为什么引入 Layout Engine、为什么进入 Repository V2
  - `RepositoryAudit.md`
    - 输出仓库审计：
      - Architecture
      - Documentation
      - Renderer
      - Workflow
      - Repository Health
      - Open Source Readiness
  - `Research/`
    - 建立研究骨架：
      - `ReverseEngineering.md`
      - `LayoutSpecification.md`
      - `TypographySpecification.md`
      - `ColorSpecification.md`
      - `BrandAnchorSpecification.md`
      - `MetadataSlotSpecification.md`
      - `AdaptiveLayout.md`
      - `OpticalLayout.md`
      - `ResearchHistory.md`

- 本轮同步的入口文件：
  - `README.md`
  - `AI.md`
  - `AI_CONTEXT.md`
  - `AGENTS.md`
  - `Docs/CURRENT_STATUS.md`
  - `Docs/DOCUMENT_INDEX.md`
  - `Docs/PROJECT_STRUCTURE.md`

- 本轮建立的非破坏性目标结构骨架：
  - `App/`
  - `DesignSystem/`
  - `LayoutEngine/`
  - `Renderer/`
  - `Examples/`
  - `Screenshots/`
  - `Docs/01_Product/`
  - `Docs/02_Architecture/`
  - `Docs/03_Research/`
  - `Docs/04_DesignSystem/`
  - `Docs/05_Renderer/`
  - `Docs/06_Development/`
  - `Docs/07_Releases/`

- 重要边界：
  - 本轮没有移动旧源码
  - 本轮没有删除旧文档
  - 本轮没有继续改 Renderer / UI / Export / Metadata 逻辑
  - 大规模文档迁移与源码结构迁移留给后续单独切片

- 验证：
  - `git diff --check` 通过
  - 未运行 Xcode build，因为本轮是文档与目录骨架重置，不改运行时代码

下一轮最值得做：

1. 先把旧 `Docs/` 文档迁移到 `Docs/01_Product` 到 `Docs/07_Releases`，每次迁移一组，并维护 redirect/index
2. 起草第一版 `Research/LayoutSpecification.md`
3. 起草 Layout Engine 数据契约，暂时不要改 renderer

## 2026-06-22 Immers White 双行文字簇收口

- 这一轮继续只收渲染层，没有碰：
  - Metadata Pipeline
  - Memory Engine
  - Share Intake
  - Export 命名
- 目标很明确：
  - 不再让白栏里的上下两层文字被 `Spacer` 撑成上下分离
  - 改成更接近目标样图的“垂直居中双行簇”

- 本轮代码收口：
  - `Source/PhotoMemo/PhotoMemo/Renderers/ImmersWhiteRenderer.swift`
    - `pinnedColumn(...)`
      - 去掉上下分离式 `Spacer`
      - 改为固定间距 + 整组居中
    - landscape 参数调整：
      - `title / metadata font ratio: 0.235 -> 0.218`
      - `bottom font ratio: 0.138 -> 0.132`
      - `group spacing ratio: 0.078 -> 0.112`
    - portrait 参数调整：
      - `title / metadata font ratio: 0.24 -> 0.225`
      - `bottom font ratio: 0.15 -> 0.142`
      - `group spacing ratio: 0.08 -> 0.098`
    - divider 强化：
      - `width: 1 -> 2`
      - 颜色改成更接近 `#D8D8D8`
    - 新增显式缩放阈值：
      - `primaryMinimumScaleFactor = 0.94`
      - `secondaryMinimumScaleFactor = 0.88`
    - 顶层主文字不再使用旧的 `0.72` 激进缩放
  - `Tests/PhotoMemoTests/RendererTests/ImmersWhiteRendererLayoutTests.swift`
    - 新增对 landscape / portrait 紧凑文字簇的参数回归保护
    - 新增对 divider width 与 minimumScaleFactor 的回归保护

- 本轮验证结果：
  - 通过了语法级 Swift parse：
    - `ImmersWhiteRenderer.swift`
    - `ImmersWhiteRendererLayoutTests.swift`
  - 后续进一步确认到机器上存在可用完整工具链：
    - `/Users/rui/Downloads/Xcode-beta.app/Contents/Developer`
  - `PhotoMemoiOS` 真机构建通过：
    - `xcodebuild -scheme PhotoMemoiOS -destination 'generic/platform=iOS' -allowProvisioningUpdates build`
  - 成品已安装到设备：
    - `iPhone7`
    - `00008150-000A043136A1401C`
  - 已成功拉起：
    - `com.serydoo.PhotoMemo.iOS`

- 当前真实状态更新为：
  - 代码改动已落地
  - 语法检查通过
  - iPhone 包已完成签名构建、安装、启动

- 本轮仍未完全收口的验证：
  1. `PhotoMemoTests` 还没有在当前 beta/macOS 路径下完成
  2. `PhotoMemo` macOS target 在当前 Xcode beta 下暴露出已有 `MainView` / `MainView+WorkspaceControls` 编译问题：
     - SwiftUI macro plugin response error
     - `isExpanded.toggle()` 的 immutable self 报错
  3. 这些问题不是这轮 `ImmersWhiteRenderer` 调整引入的，但会影响后续完整桌面编译链验证

## 2026-06-21 Classic White 人工视觉对照 + snapshot 回归链闭环

- 这一轮继续只收 `Classic White`，没有碰：
  - Metadata Pipeline
  - Memory Engine
  - Batch / Share 业务逻辑
- 目标不是继续调样式，而是把 `Classic White` 的视觉结果正式纳入可重复验证。

- 本轮新增内容：
  - `Tests/Fixtures/RendererSnapshots/ClassicWhite/full-card/`
    - 已提交 4 张人工视觉基准图：
      - `landscape_standard`
      - `landscape_long_exif`
      - `portrait_standard`
      - `portrait_long_memory`
  - `Tests/PhotoMemoTests/Support/ClassicWhiteSnapshotSupport.swift`
    - 提供 deterministic synthetic scenario
    - 支持：
      - record mode
      - reference compare
      - mismatch artifact 输出
      - test attachment 导出
  - `Tests/PhotoMemoTests/RendererTests/ClassicWhiteSnapshotTests.swift`
    - 为四个 full-card 场景提供 snapshot 级回归保护
  - `Docs/ClassicWhiteVisualQA.md`
    - 记录人工目视检查项
    - 记录基准图刷新流程

- 这轮里一个关键结论：
  - Xcode 测试附件导出的 PNG 与渲染原图之间，会存在极轻微色差
  - 当前观测值是：
    - `maxChannelDelta = 1`
    - 差异像素占比远低于 `0.05%`
  - 因此 snapshot compare 现在采用：
    - 先严格比较
    - 若只有极小 attachment-refresh 色差，则允许通过
  - 这不会放过真正的布局回归，因为：
    - divider
    - padding
    - font tier
    - truncation
    - module width
    这些变化都会远超这个容差

- 本轮验证：
  - `ClassicWhiteSnapshotTests` 正常模式通过
  - 录制模式也已验证可工作：
    - `.record-mode`
    - `xcresulttool export attachments`
    - 替换 reference PNG
    - 再回到正常模式复验
  - `PhotoMemoTests` 全量通过
  - 构建通过：
    - `PhotoMemo`
    - `PhotoMemoiOS`
    - `PhotoMemoShareExtension`
  - 真机安装并启动通过：
    - 设备：`iPhone7`
    - 型号：`iPhone 17 Pro Max`
    - bundle id：`com.serydoo.PhotoMemo.iOS`

- 当前意义：
  - Classic White 现在同时具备：
    - theme 常量保护
    - grid 数学保护
    - renderer 路由保护
    - full-card snapshot 保护
  - 后续再做字体、间距、分隔符等微调时，已经不是“靠眼睛记”，而是有稳定回归链可依赖

## 2026-06-21 Classic White 第二层回归保护

- 这一轮继续只收 `Classic White`，没有碰：
  - Metadata Pipeline
  - Memory Engine
  - Batch / Share 业务逻辑
- 目标不是继续改视觉，而是把已经落地的设计系统再锁紧一层，减少后续 refactor 误伤。

- 本轮新增两个可测试支点：
  - `RecordCardRenderer.destination(for:)`
    - 让 preset -> renderer 的路由成为显式边界
    - 不再只靠 `body` 内部 switch 隐式表达
  - `ClassicWhiteCardRenderer.layoutMetrics(forTotalWidth:)`
    - 把固定底栏布局里的几何结果抽成可测试度量
    - 当前锁定的是：
      - content width
      - left / center / right module width
      - fixed content height

- 本轮新增回归保护：
  - `Tests/PhotoMemoTests/RendererTests/RecordCardRendererRoutingTests.swift`
    - 锁定：
      - `template2 / template3 -> classicWhite`
      - `template1 / immersWhite -> immersWhite`
  - `Tests/PhotoMemoTests/RendererTests/ClassicWhiteCardRendererLayoutTests.swift`
    - 锁定：
      - `960pt` 总宽时，固定 `40 / 20 / 40` 会得到：
        - `320 / 160 / 320`
      - 当容器比水平 padding 更窄时，不会出现负宽度

- 这一轮的意义：
  - 之前已有：
    - 主题常量保护
    - 导出尺寸保护
  - 现在又补上：
    - renderer 路由保护
    - 固定 grid 宽度计算保护
  - Classic White 设计系统已经不只是“值固定”，而是“值如何落到真实布局里”也能被回归测试覆盖。

- 本轮验证：
  - 定向测试通过：
    - `RecordCardRendererRoutingTests`
    - `ClassicWhiteCardRendererLayoutTests`
  - `PhotoMemoTests` 全量通过
  - 构建通过：
    - `PhotoMemo`
    - `PhotoMemoiOS`
    - `PhotoMemoShareExtension`

- 当前仍保留的边界：
  - 还没有做真实视觉 snapshot / pixel comparison
  - 还没有把 line-box / baseline 对齐进一步抽成单独可测模型
  - 但 preset 路由和固定 grid 已经有第二层保护，后续继续整理 render theme 时会更安全

## 2026-06-21 Classic White Render Design System

- 这一轮严格只动 `Classic White` 渲染层，没有碰：
  - Metadata Pipeline
  - Memory Engine
  - Batch / Share 业务逻辑
- 目标是把旧的比例驱动白边实现，收成一套固定主题的 Information Card Renderer。

- 本轮新增主题层：
  - `Source/PhotoMemo/PhotoMemo/Renderers/RenderTheme.swift`
  - 当前已落地：
    - bottom height: `260`
    - background: `#F4F3F3`
    - grid: `40 / 20 / 40`
    - primary text: `28pt`
    - secondary text: `18pt`
    - horizontal padding: `80`
    - top padding: `54`
    - bottom padding: `42`
    - divider: `2 x 110`

- 本轮结构收口：
  - `ClassicWhiteRenderer`
    - 不再保留旧的 orientation ratio layout 结构
    - 现在只负责：
      - `theme`
      - `outputPixelSize(...)`
  - `ClassicWhiteCardRenderer`
    - 新增独立文件
    - 按：
      - left module
      - center module
      - right module
      的方式排列
    - 固定字号，不再 `minimumScaleFactor`
    - 长内容改为 truncation，优先保布局稳定
  - `RecordCardRenderer`
    - 现在只保留 preset -> renderer 路由
  - `RecordCardExportService`
    - Classic White 导出尺寸现在是固定规则：
      - `imageHeight + 260`

- 本轮新增回归保护：
  - `Tests/PhotoMemoTests/RendererTests/ClassicWhiteRendererThemeTests.swift`
  - 锁定：
    - 主题常量
    - 固定底栏高度
    - 固定导出尺寸
    - fallback size 行为

- 本轮还额外修了一处 target 边界问题：
  - `PhotoMemoiOS` 构建时会顺带编译 `PhotoMemoShareExtension`
  - share extension 当前不携带完整 renderer 依赖
  - 因此给：
    - `ClassicWhiteRenderer.swift`
    - `ClassicWhiteCardRenderer.swift`
    加了 `#if !PHOTOMEMO_SHARE_EXTENSION`
  - 这样新渲染文件不会误泄漏到轻量 share target

- 文档同步：
  - `Docs/RENDER_SPEC.md`
    - 已更新为新的 Classic White 设计系统规范
  - `Docs/CURRENT_STATUS.md`
    - 已增加这一轮状态记录

- 本轮验证：
  - `PhotoMemoTests` 全量通过
  - `PhotoMemo` build 通过
  - `PhotoMemoiOS` build 通过
  - `PhotoMemoShareExtension` build 通过

- 当前已知边界：
  - 这一轮没有做真实视觉截图回归
  - 还没有为 Classic White 建立 snapshot / pixel comparison
  - 但结构、主题常量和导出尺寸已经进入可测试状态

## 2026-06-21 Immers 右侧列收紧、占位命名兜底、真机重装

- 这一轮继续只做小切片，没有扩功能，也没有改架构边界。
- 当前聚焦的是两个用户直接能看到的问题：
  - `ImmersWhiteRenderer` 右侧上下两块内容要更明确地左对齐，并更贴近 logo / 分隔线
  - 导出命名不应继续把 `PhotoMemo Import` 当成真实原始文件名

- 本轮视觉收口：
  - `ImmersWhiteRenderer`
    - 右侧列继续保持 `leading` 对齐
    - 新增独立的：
      - `logoToDividerSpacingRatio`
      - `dividerToTextSpacingRatio`
    - 当前规则变成：
      - logo 到分隔线略保留呼吸
      - 分隔线到右侧文字更紧
    - portrait / landscape 都给右侧列增加了可用宽度
    - `styledText` 开启 `allowsTightening(true)`，减轻右上参数行被动缩小

- 本轮命名收口：
  - `PhotoFileNameResolver`
    - 现在会把以下都视为占位名，而不再当成真实原图名：
      - `Photo Library`
      - `Photo Library 2`
      - `PhotoMemo Import`
      - `PhotoMemo Import (1)`
    - 新增：
      - `outputBaseName(...)`
      - `timestampFallbackBaseName(...)`
  - `RecordCardExportService`
    - 导出文件名现在优先级变成：
      1. 已知真实原图名
      2. 通过 `assetLocalIdentifier` 再向系统相册回查原图名
      3. 如果仍然只有占位名，则退到稳定的拍摄时间命名：
         - `IMG_yyyyMMdd_HHmmss`
    - 复制后缀规则继续保留：
      - `xxx.jpg`
      - `xxx (1).jpg`
      - `xxx (2).jpg`

- 本轮新增回归保护：
  - `PhotoFileNameResolverTests`
    - 锁定 `PhotoMemo Import` 占位名不会被当成真实原图名
    - 锁定拍摄时间回退命名
  - `RecordCardBuildServiceTests`
    - 锁定 placeholder source name 会导出成 `IMG_yyyyMMdd_HHmmss.jpg`
  - `ImmersWhiteRendererLayoutTests`
    - 锁定右侧列继续左对齐
    - 锁定分隔线到右文案的间距小于 logo 到分隔线

- 本轮验证：
  - 定向测试通过：
    - `PhotoFileNameResolverTests`
    - `RecordCardBuildServiceTests`
    - `ExternalPhotoIntakeStoreDiagnosticsTests`
    - `ImmersWhiteRendererLayoutTests`
  - 构建通过：
    - `PhotoMemo`
    - `PhotoMemoiOS`
    - `PhotoMemoShareExtension`
  - 真机安装：
    - 已重新安装到设备 `00008150-000A043136A1401C`
  - 真机启动：
    - 安装成功
    - 自动启动被系统拒绝，原因是设备当时处于锁定状态

## 2026-06-21 First Run 向导按系统 Form 风格收口

- 这一轮根据 HIG 方向做了一个小范围 UI 提升，没有扩功能，也没有改架构边界。
- 本轮只把首次启动向导从自定义卡片堆叠，收回到更接近系统设置流程的 SwiftUI 结构：
  - `NavigationStack`
  - `Form`
  - `Section`
  - `Picker`
  - `TextField`
  - `DatePicker`
  - `LabeledContent`
- 首启流程仍然保持原来的 5 步：
  - 欢迎
  - 身份
  - 宝宝昵称
  - 出生日期
  - 保存位置
- UI 规则同步：
  - 使用标准字体层级，例如 `.title`、`.headline`、`.body`、`.footnote`
  - 使用 `.accentColor`、`.primary`、`.secondary` 等系统语义样式
  - 去掉首启向导里的固定宽度和自定义白卡片依赖
  - 步骤切换保留系统默认动画
- 编译收口：
  - 修复了前一轮未完成命名收口中残留的重复语法片段
  - `PhotoFileNameResolver` 标记为 `nonisolated static`，方便 Share / Batch 等非 UI 回调安全复用
  - Share intake 的原始文件名解析改为静态纯函数调用，避免隐式捕获 `self`
- 本轮验证：
  - `PhotoMemo` build 通过
  - `PhotoMemoiOS` build 通过
  - `PhotoFileNameResolverTests` 通过
- 尚未做：
  - 没有继续重构 Main App 全部页面
  - 没有改 Renderer / Export / Metadata / Memory
  - 没有重新安装到真机

## 2026-06-21 Share 成功反馈回退为纯计数文案

- 这一轮没有扩 intake 能力，也没有继续增加新反馈元素。
- 只把刚加上的“成功后显示文件名”撤回，改回更安静的产品表达。

- 当前用户可见变化：
  - 单张成功：
    - 不再显示具体文件名
    - 统一回到计数型提示
  - 多张成功：
    - 仍然只显示接收数量
    - 如果有部分跳过/失败，继续显示计数，不暴露某一个文件名示例

- 这样处理的原因：
  - 对多图分享来说，显示一个文件名并不能帮助用户定位到底哪张后续没保存成功
  - 用户真正判断成功与否的方式，仍然是系统相册里原图旁边是否出现了新的生成结果
  - Share 完成页应该尽量安静，只确认“PhotoMemo 已经接住了多少张”

- 本轮代码收口：
  - `PhotoMemoShareExtensionViewController`
    - 成功文案恢复为纯计数
  - `PhotoMemoShareExtensionImportResult`
    - 不再承载成功反馈用的 file name 列表
  - `PhotoMemoShareExtensionIntakeService`
    - 去掉只服务于成功提示的 file name 回传
  - `PhotoMemoShareWorkflowSummaryTests`
    - 去掉文件名成功文案 formatter 回归测试

- 本轮验证：
  - `PhotoMemoTests` 通过
  - `PhotoMemo` build 通过
  - `PhotoMemoiOS` build 通过
  - `PhotoMemoShareExtension` build 通过

## 2026-06-21 Share 成功反馈开始显示原始文件名

- 这条尝试后来已被上面的“纯计数文案”收回，保留这里只作为当天迭代历史。

- 这一轮继续保持“小而完整”的节奏，没有继续扩 provenance 模型本身，而是把已经打通的来源信息真正用到用户可见反馈里。

- 本轮新增：
  - `PhotoMemoShareProcessingFeedbackFormatter`

- 本轮实现范围：
  - `PhotoMemoShareExtensionImportResult`
    - 新增 `importedFileNames`
  - `PhotoMemoShareExtensionIntakeService`
    - 返回结果时，把 imported original file names 一起带回
  - `PhotoMemoShareExtensionViewController`
    - 成功状态文案不再只显示张数
    - 现在会优先显示原始文件名
  - `PhotoMemoShareWorkflowSummaryTests`
    - 新增 share success feedback formatter 回归测试

- 当前用户可见变化：
  - 单张成功时：
    - `已接收《IMG_9558.HEIC》。处理完成后会写回系统相册。`
  - 部分成功时：
    - 仍保留总数表达
    - 但会补一个具体文件名示例

- 这一轮的产品价值：
  - provenance 不再只是埋在模型里
  - 用户更容易确认“刚刚分享的那张照片”确实已经被 PhotoMemo 接住了
  - 反馈仍然保持安静，没有暴露技术词

- 本轮验证：
  - `PhotoMemoTests` 通过
  - `PhotoMemo` build 通过
  - `PhotoMemoiOS` build 通过
  - `PhotoMemoShareExtension` build 通过

- 当前仍保留的下一步：
  1. 是否把 file name 也用于 share 失败反馈
  2. 是否在确认页单张预览文案里显示具体文件名
  3. 是否把 provenance 进一步接入后续 save-back 成功提示或历史记录摘要

## 2026-06-21 share/request/task provenance 继续收口

- 这一轮是在上一刀 `PhotoSourceInfo` 的基础上继续往前推，但仍然保持小切片：
  - 不扩功能
  - 不改 renderer
  - 不改 memory
  - 只把 provenance 从 `SelectedPhoto` 继续接到 intake / request / task

- 本轮新增：
  - `ExternalPhotoIntakeItem`

- 本轮核心变化：
  - `ExternalPhotoIntakeRequest`
    - 现在除了 `urls` 之外，还可以持久化结构化 `items`
    - 新增 `intakePayloads`
  - `BatchTaskIntakePayload`
    - 现在会带：
      - `fileName`
      - `sourceIdentifier`
      - `contentTypeIdentifier`
  - `BatchTask`
    - 现在也继续保留这些字段
  - `PhotoMemoAppRuntime`
    - flush external requests 时，不再只用 URL 重建 payload
    - 现在会优先消费结构化 intake payload
  - `BatchProcessingCoordinator`
    - 批量导入时会把 task provenance 重新组装成 `PhotoSourceInfo`
  - `PhotoMemoShareExtensionIntakeService`
    - share intake 成功后，不再只持久化 managed URLs
    - 现在会一起持久化对应的结构化 intake items

- 这一轮真正解决的问题：
  - share 进来的文件名，不会在 request / task 这层又退化成 managed copy 名称推断
  - batch 状态、后续导入、导出命名，现在可以沿着同一条 provenance 线继续往下传
  - `share -> intake request -> batch task -> import -> export`
    这条链现在已经有了连续的结构化来源信息

- 新增回归保护：
  - `ExternalPhotoIntakeStoreDiagnosticsTests`
    - 锁定 structured intake item 持久化
  - `BatchFixtureCoverageTests`
    - 锁定 payload provenance 会覆盖 temporary URL naming
    - 锁定 batch import 后 `SelectedPhoto.sourceInfo` 仍然保留这些字段

- 本轮验证：
  - `PhotoMemoTests` 通过
  - `PhotoMemo` build 通过
  - `PhotoMemoiOS` build 通过
  - `PhotoMemoShareExtension` build 通过

- 当前仍保留的下一步：
  1. 是否把 provenance 进一步用于 share 失败反馈或调试 UI
  2. 是否给 non-share external intake 也补更完整的 source identifier 策略
  3. 是否继续把最终 save-back 的读回验证也接入这条 provenance 线

## 2026-06-21 导入来源信息切片落地

- 本轮沿着 `MainWorkflowChecklist` 继续往下做了一刀真正有代码价值的收口：
  - 不做大重构
  - 先把“导入来源事实”从零散 URL 语义里抽成一份轻量结构

- 本轮新增：
  - `PhotoSourceInfo`

- 当前挂载位置：
  - `SelectedPhoto.sourceInfo`

- 当前已经保留的来源字段：
  - `originalFileName`
  - `assetLocalIdentifier`
  - `contentTypeIdentifier`

- 本轮实现范围：
  - `SelectedPhoto`
    - 增加 `sourceInfo`
  - `PhotoImportService`
    - 数据导入时写入来源信息
    - URL 导入时补全基础来源信息
  - `PhotoImporterView`
    - 从 `PhotosPickerItem.itemIdentifier` 继续传递 asset identifier
  - `RecordCardExportService`
    - 导出文件命名优先使用 `sourceInfo.originalFileName`
    - 不再只依赖 `sourceURL.lastPathComponent`

- 这一轮解决的核心问题：
  - 原始文件名、资源标识、类型标识不再只是“散落在线索里”
  - 至少在 `SelectedPhoto` 生命周期内，来源事实现在有一份明确、可测试、可继续扩展的结构化承载点
  - 导出命名不再直接绑定临时源路径语义

- 这一轮刻意没有做的事情：
  - 不把 import provenance 强行塞进 `PhotoMetadata`
  - 不动 share intake 存储模型
  - 不做跨系统的大范围 rename

- 新增回归保护：
  - `PhotoImportServiceTests`
    - 锁定 `sourceInfo.originalFileName`
    - 锁定 `sourceInfo.contentTypeIdentifier`
    - 锁定 `sourceInfo.assetLocalIdentifier`
  - `RecordCardBuildServiceTests`
    - 锁定导出命名优先使用 imported original file name

- 本轮验证：
  - `PhotoMemoTests` 通过
  - `PhotoMemo` build 通过
  - `PhotoMemoiOS` build 通过
  - `PhotoMemoShareExtension` build 通过

- 当前仍保留的下一步：
  1. share intake / external intake request 是否也需要带结构化 provenance
  2. batch task 层是否要显式消费 `originalFileName` 而不只是 `sourceURL`
  3. 是否要把 provenance 的展示和诊断进一步接到用户可见反馈里

## 2026-06-21 主链路收口标准与开发清单落地

- 本轮没有扩功能，也没有做新的架构抽象。
- 重点是把 `PhotoMemo v0.4 Main Workflow Consolidation` 里真正值得吸收的部分，落成项目内部标准与执行清单。

- 本轮新增文档：
  - `Docs/MainWorkflowConsolidation.md`
  - `Docs/MainWorkflowChecklist.md`

- 当前明确吸收的方向：
  - 建立唯一内部主链路：
    - `Import -> Metadata -> Memory -> Renderer -> Export -> Share`
  - 明确六个阶段的职责边界：
    - Import 负责接入与保留来源事实
    - Metadata 负责规范化后的照片事实
    - Memory 负责时间与记忆语义
    - Renderer 负责最终视觉输出
    - Export 负责结果写出与保存
    - Share 负责轻量分享流程
  - 明确：
    - Renderer 很重要，但不再被当作产品中心
    - Template / Style 与 Renderer 继续解耦
    - Share-first 继续推进，但不做高风险的“一步到位重写”

- 当前明确不做的内容：
  - 不新增抽象 `PhotoWorkflow` 框架
  - 不做大规模目录重组
  - 不做全仓库 rename sweep
  - 不强行要求当前所有执行立即迁移到 Share Extension 内

- 这一轮最关键的工程判断：
  - 当前代码里，真正还需要继续收口的，不是再加一层架构，而是：
    1. import 来源事实的一致性
       - original filename
       - asset identifier
       - source type / UTI
    2. share happy path 的稳定性
    3. renderer 不再承载业务语义漂移

- 文档同步：
  - `README.md`
  - `Docs/ProductDirection.md`
  - `Docs/CURRENT_STATUS.md`
  - `HANDOFF.md`
  - 现在已经统一到同一套说法：
    - `Import -> Metadata -> Memory -> Renderer -> Export -> Share`

Build verification for this slice:

- `PhotoMemo` build passed
- `PhotoMemoiOS` build passed
- `PhotoMemoShareExtension` build passed

本轮没有改 Swift 源码，所以没有重复跑 `PhotoMemoTests`。

## 2026-06-21 Share 唤起闭环、原名导入收口、默认渲染切到 Immers White

- 本轮先把“文件名被临时导入路径污染”这条链彻底收口：
  - `PhotoImportService`
    - `PhotosPicker` 的临时导入现在改成：
      - 共享根目录
      - 每次导入一个独立 UUID 子目录
      - 子目录内保留原始文件名
    - 这样连续两次导入同名照片时，不会再把 `SelectedPhoto.sourceURL` 变成：
      - `IMG_7065 (1).JPEG`
  - 同时保留了你要的扩展名观感：
    - 显式给定 `IMG_9558.HEIC`
    - 现在会继续保留 `.HEIC`
  - `Photo Library` 这个占位名仍会回退到：
    - `PhotoMemo Import.jpg`
- 本轮补充了主程序导入命名的回归保护：
  - `Tests/PhotoMemoTests/ExportTests/PhotoImportServiceTests.swift`
  - 新增覆盖：
    - 显式文件名保留
    - `Photo Library` 占位名回退
    - 重复导入同名照片时，文件名仍保持原样

- Share Extension 这一轮不做大流程改造，只补最小闭环：
  - 新增：
    - `Source/PhotoMemo/PhotoMemo/App/PhotoMemoDeepLink.swift`
  - `PhotoMemoiOS` 新增 URL scheme：
    - `photomemo://share`
  - `PhotoMemoRootSceneView`
    - 现在会识别 `photomemo://share`
    - 收到后直接执行：
      - `runtime.refreshExternalIntakeState()`
  - `PhotoMemoShareExtensionViewController`
    - share intake 成功后会先尝试：
      - `extensionContext.open(photomemo://share)`
    - 再关闭分享页
  - 这样当前行为从：
    - “写进共享收件箱后直接关闭，主 App 不一定立刻处理”
    变成：
    - “写进共享收件箱后主动唤起主 App 刷新 intake，并继续生成/保存”
  - 这一轮仍然不是“完全在扩展里渲染保存”，但已经把当前真实断点补上了

- 默认渲染路径也收了一刀：
  - 之前当前主链默认还是：
    - `template1 -> ClassicWhiteRenderer`
  - 这正是你说“成片和目标样图差距很大”的核心原因之一
  - 现在新增统一渲染布局判定：
    - `TemplatePreset.renderLayout`
  - 当前映射：
    - `template1` -> `immersWhite`
    - `immersWhite` -> `immersWhite`
    - `template2 / template3` -> `classicWhite`
  - `RecordCardRenderer`
    - 预览已改用这套统一映射
  - `RecordCardExportService.outputPixelSize(...)`
    - 导出尺寸也改用同一映射
  - 这样至少保证：
    - 预览路径
    - 导出路径
    - 白栏比例
    - Immers 风格几何
    已经走到同一个分支

- Immers 风格本轮只做了一处非常保守的样图贴近：
  - `ImmersWhiteRenderer.infoBarColor`
    - 从纯白改成偏暖白：
      - `#F4F4F2`
  - 这一轮没有继续大动：
    - 字号
    - 分隔线宽度
    - 徽标几何
  - 因为先把“走错 renderer”这个更大的问题纠正掉更重要

- 本轮新增测试：
  - `Tests/PhotoMemoTests/RendererTests/TemplatePresetRenderLayoutTests.swift`
  - `Tests/PhotoMemoTests/BatchTests/PhotoMemoDeepLinkTests.swift`

- 本轮验证结果：
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

- 本轮仍需你真机继续确认的重点：
  1. 系统相册分享后，是否会真正自动切回 PhotoMemo 并开始处理
  2. 处理完成后，是否已经不再出现：
     - `Photo Library.JPG`
     - `Photo Library (1).JPG`
  3. 当前默认成片在横图 / 竖图下，是否已经明显更接近你持续提供的 Immers 样图
  4. Share 页在某些来源 App 中，`extensionContext.open(...)` 是否会被系统限制；如果被限制，下一轮需要进一步决定是：
     - 做更明确的“返回 PhotoMemo 完成保存”反馈
     - 还是继续推进扩展内单张 happy-path 处理

## 2026-06-21 Photo Library 原名回写修复、白栏颜色与分隔线微调

- 本轮确认并修复了一个真实的 Photo Library 命名问题：
  - 本地导出文件名原本已经符合系统复制规则：
    - `原文件名.jpg`
    - `原文件名 (1).jpg`
    - `原文件名 (2).jpg`
  - 但写回系统相册后，资产原始文件名没有沿用导出文件名，导致测试结果出现：
    - `Photo Library.JPG`
    - `Photo Library 2.JPG`
- 当前修复位置：
  - `Source/PhotoMemo/PhotoMemo/Services/PhotoLibraryExportService.swift`
  - 在 `saveImageResult(...)` 里补充：
    - `PHAssetResourceCreationOptions.originalFilename`
  - 新增：
    - `assetOriginalFilename(for:)`
  - 当前逻辑：
    - 默认使用导出文件的 `lastPathComponent`
    - 自动保留 ` (1)` / ` (2)` 这种系统复制后缀
    - 仅在文件名为空时回退到 `PhotoMemo.jpg`
- 本轮测试补强：
  - `Tests/PhotoMemoTests/ExportTests/RecordCardBuildServiceTests.swift`
  - 新增覆盖：
    - `usesExportedFileNameAsPhotoLibraryOriginalFilename()`
- 本轮渲染微调：
  - `ClassicWhiteRenderer.swift`
  - 继续按你提供的样图靠拢，只做小幅视觉回收：
    - 白栏底色改成偏暖的 `#F4F4F2`
    - 顶部主文字改深
    - 参数与次级文字颜色重新贴近样图层次
    - 分隔线改成更浅的显式灰色，并从 `1px` 提到 `2px`
    - `badge -> divider -> right text` 间距再收一轮
    - badge 与 divider 高度做了轻微缩短
- 本轮验证：
  - 定向测试通过：
    - `PhotoMemoTests/RecordCardBuildServiceTests`
  - 构建通过：
    - `PhotoMemo`
    - `PhotoMemoiOS`
    - `PhotoMemoShareExtension`
- 当前仍需人工核查：
  1. 真机系统相册写回后，文件名是否已经稳定沿用原图名与复制后缀
  2. 当前白栏暖灰底与分隔线粗细，是否已经更接近你提供的成品样图
  3. 顶层文字与次级文字的层级是否还需要继续按样图做最后一轮微调

## 2026-06-21 导出命名规则确认、Immers 样图校准一轮、徽标资源补充

- 本轮确认：
  - 导出图片命名规则当前已经是系统复制文件风格：
    - `原文件名.jpg`
    - `原文件名 (1).jpg`
    - `原文件名 (2).jpg`
  - 当前实现位置：
    - `Source/PhotoMemo/PhotoMemo/Services/RecordCardExportService.swift`
  - 当前命名测试也已锁住：
    - `Tests/PhotoMemoTests/ExportTests/RecordCardBuildServiceTests.swift`
  - 本轮没有再改命名逻辑，因为代码与测试已经符合要求，不再追加 `_PhotoMemo`

- 本轮补充：
  - 新增 4 个内置喜庆徽标资源：
    - `喜爱`
    - `囍`
    - `新生`
    - `福`
  - 相关文件：
    - `Source/PhotoMemo/PhotoMemo/Assets.xcassets/badge-love.imageset`
    - `Source/PhotoMemo/PhotoMemo/Assets.xcassets/badge-wedding.imageset`
    - `Source/PhotoMemo/PhotoMemo/Assets.xcassets/badge-birth.imageset`
    - `Source/PhotoMemo/PhotoMemo/Assets.xcassets/badge-fu.imageset`
  - 徽标库与选择器已同步接入：
    - `BadgeLibrary.swift`
    - `BadgeRenderer.swift`
    - `BadgePickerView.swift`
    - `MainView+LayoutSections.swift`

- 本轮渲染校准：
  - 已结合你提供的成品样图和 Immers `areas_light` 官方公开样片，对 `ClassicWhiteRenderer` 做了一轮更接近样图的参数回收
  - 重点只动：
    - 白栏高度比例
    - 左右区宽度
    - 上下两层字号比例
    - `badge -> divider -> right text` 间距关系
  - 当前改动文件：
    - `Source/PhotoMemo/PhotoMemo/Renderers/ClassicWhiteRenderer.swift`
    - `Source/PhotoMemo/PhotoMemo/Renderers/RecordCardRenderer.swift`
  - 这一轮还不是最终锁死版本，后续仍需要继续按真机成片对着样图微调

- Share intake：
  - `PhotoMemoShareExtensionIntakeService.swift` 继续保留并补强了 intake 诊断与失败阶段暴露
  - `ExternalPhotoIntakeStoreDiagnosticsTests.swift` 已同步覆盖相关诊断路径

- 本轮验证：
  - `PhotoMemoiOS` build 通过
  - `PhotoMemoTests` 定向 `RecordCardBuildServiceTests` 通过
    - 已明确验证命名规则测试：
      - `keepsOriginalBaseFilenameAndAppendsCopySuffixesForRepeatedExports()`

- 当前仍需继续人工核查：
  1. 真机导出结果与参考样图的底栏节奏是否已经足够接近
  2. Share Extension 真机分享失败是否已因前一轮 intake 修复而消失
  3. 新增徽标在横图、竖图和不同白栏高度下的视觉平衡

## 2026-06-20 Product Convergence 一轮完整收口

- 本轮目标：
  - 按 `North Star` 和 `Product Convergence` 规范，把主界面、Share 文案和 `Personal Profile / Style` 边界继续收紧
  - 不扩能力
  - 不动渲染、导出、Memory Engine、Metadata Pipeline
- 本轮主界面变化：
  - iPhone 顶层信息架构现在收成：
    - `我的记录`
    - `默认风格`
    - `输出设置`
    - `设置`
    - `关于`
  - `预览` 不再在 iPhone 顶层单独占一块
  - 预览现在回到 `默认风格` 内作为校准内容的一部分
  - macOS 仍保留右侧预览 detail，继续承担单张校准面
- 本轮术语收口：
  - `识别数据` -> `照片信息`
  - `智能数据` -> `记忆信息`
  - 多处 `时间点` -> `记忆日期`
  - Share 确认页 `当前设置` -> `这次会如何处理`
  - Share 确认页 `当前风格` -> `默认风格`
  - Share / intake 错误提示里的 `当前风格` 也统一改成 `默认风格`
- 本轮 Share 变化：
  - 确认页继续保持单页
  - 核心表达现在更接近：
    - 分享了几张
    - 默认风格
    - 结果去向
    - 接下来会发生什么
  - 单张预览说明改成：
    - `将按当前默认风格处理这张照片`
  - 处理中和失败后的反馈文案继续弱化技术感
- 本轮 `Personal Profile / Style` 边界变化：
  - `PersonalProfileStore` 新增：
    - `updateDefaultStyleIdentifier(_:)`
    - `updateSaveDestination(...)`
  - 切换默认风格时，会同步回写 `Personal Profile`
  - 切换保存相册时，也会同步回写 `Personal Profile`
  - 这样 Share 和 Main App 现在更明确地共用同一份长期资料来源
- 本轮风格保存边界：
  - `saveCurrentConfiguration()` 不再先把当前相册 / 记忆日期直接当成风格持久化来源
  - `applyWorkspaceConfigurationSnapshot(...)` 现在只回放风格相关内容：
    - template
    - badge
    - description-writing settings
  - 不再在切换风格时顺手改掉当前选中的记忆日期和相册去向
  - 这让 `Style = presentation-first` 又向前走了一步
- 本轮新增/更新测试：
  - `PhotoMemoShareWorkflowSummaryTests`
    - 从 `anchorTitle` 迁到 `memoryDateTitle`
    - 校验新的 Share 文案输出
  - `PersonalProfileStoreTests`
    - 覆盖默认风格回写
    - 覆盖保存位置回写
- 本轮验证：
  - 定向测试通过：
    - `PersonalProfileStoreTests`
    - `PhotoMemoShareWorkflowSummaryTests`
  - 全量测试通过：
    - `PhotoMemoTests`
  - 本轮我明确拿到：
    - `PhotoMemoTests` `TEST SUCCEEDED`
  - `PhotoMemo` / `PhotoMemoiOS` / `PhotoMemoShareExtension`
    - 构建命令已真实执行
    - 当前会话里没有完整保留三个命令各自的干净尾行
    - 但本轮修改涉及的主 app / share 文件已经被测试编译链真实覆盖
- 本轮仍保留的产品债务：
  1. `默认风格` 内部虽然已经更像设置，但 `进一步调整` 里仍有不少低频项，后续还值得继续往二级层级下沉。
  2. First Run 目前仍是 5 步，和最新 North Star 的“显式完成页”不完全一致；这是一次 deliberate simplification，但之后要不要补回安静的完成态，还需要产品判断。
  3. Share 已经更像用户确认页，但距离真正的 `Share -> Generate -> Save -> Done` 无感体验还有最后一段手感打磨。

## 2026-06-20 Main App 继续减法，First Run 再缩一轮

- 本轮目标：
  - 不加新能力
  - 继续遵守 `Main App is not the primary workflow`
  - 把主 App 再往“安静的配置中心”收
  - 把首次引导再往“一次性系统设置”收
- 本轮主界面变化：
  - macOS 右侧详情区不再重复显示一份 `默认风格`
  - 右侧重新只承担：
    - 选图
    - 预览
  - iPhone 顶层继续减法，默认主链现在更接近：
    - 我的记录
    - 默认风格
    - 输出
    - 预览
  - `设置` 只有在权限尚未就绪时才出现
  - `关于` 不再占首页顶层主块
- 本轮风格区变化：
  - `默认风格` 仍保留当前风格位切换、重命名、保存和恢复
  - 时间点 / 个性化区域 / 补充信息 / Logo 标识 被后置到：
    - `进一步调整`
  - 这意味着默认进入时先看到高频主项，低频调节不再一开始全部铺开
- 本轮首次引导变化：
  - 去掉独立 `完成页`
  - 最后一步 `保存位置` 直接完成并进入主界面
  - 当前 First Run 收成：
    1. 欢迎
    2. 记录身份
    3. 宝宝昵称
    4. 出生日期
    5. 保存位置
- 当前判断：
  - 这轮是实打实的复杂度下降，不是换地方加内容
  - 但 `默认风格` 内部仍然偏重，只是已经先后置了一批低频项
  - 下一轮如果继续这条线，最值得优先做的是：
    1. 决定哪些 `进一步调整` 项应继续留在主界面，哪些应真正迁往设置层
    2. 对 Share Extension 做同样级别的“默认更安静”减法
    3. 做真机手感核查，看这一轮首页是否已经更像 Apple Settings
- 本轮验证结果：
  - `PhotoMemoiOS` build 通过
    - 该次编译已真实覆盖 `PhotoMemoShareExtension`
  - `PhotoMemoTests` 通过
  - `PhotoMemo` 本轮单独补跑时遇到本机 `CoreSimulatorService` 异常噪音，未拿到干净尾行
  - `PhotoMemoShareExtension` 本轮单独补跑时同样遇到本机 `CoreSimulatorService` 异常噪音，未单独保留 `BUILD SUCCEEDED`
  - 但这两者本轮改动都已被 `PhotoMemoiOS` 全量编译链覆盖

## 2026-06-20 Share Extension intake diagnostics 已接通

- 本轮目标：
  - 不修分享失败根因
  - 只把 Share confirmation -> intake 这一段的诊断能力补齐
  - 下次真机失败时直接知道卡在哪一层
- 本轮核心新增：
  - `Source/PhotoMemo/PhotoMemo/App/PhotoMemoShareIntakeDiagnostics.swift`
  - Share intake 统一失败阶段：
    - `load`
    - `copy`
    - `persist`
    - `serialization`
    - `completion`
  - 统一 `NSError` 摘要：
    - `localizedDescription`
    - `domain`
    - `code`
    - `underlyingError`
- 本轮主要代码变化：
  - `ExternalPhotoIntakeStore`
    - 新增 detailed copy / persist 结果
    - 不再只返回 `nil`
    - 现在能给出 shared container 目标路径和失败上下文
  - `PhotoMemoShareExtensionImportResult`
    - 新增 provider 总数 / supported 数 / failure stage / failure context
  - `PhotoMemoShareExtensionIntakeService`
    - 现在会记录：
      - extension 收到的 item providers 数量
      - supported provider 数量
      - 选中的 `UTType.image` 与 provider 的首选图片类型
      - `loadFileRepresentation` 起止与返回 URL
      - `loadItem` fallback 起止与返回 URL/Data
      - temporary copy 结果
      - shared container destination
      - persist request 结果
      - final import result 值
  - `PhotoMemoShareExtensionViewController`
    - 失败页现在会带上简短诊断摘要：
      - `失败阶段`
      - `NSError domain / code`
- 本轮新增测试：
  - `Tests/PhotoMemoTests/BatchTests/PhotoMemoShareIntakeDiagnosticsTests.swift`
  - `Tests/PhotoMemoTests/BatchTests/ExternalPhotoIntakeStoreDiagnosticsTests.swift`
- 本轮验证：
  - 定向 `PhotoMemoShareIntakeDiagnosticsTests` 通过
  - 定向 `ExternalPhotoIntakeStoreDiagnosticsTests` 通过
  - `PhotoMemoiOS` build 通过
    - 编译链已经覆盖 `PhotoMemoShareExtension`
- 当前对你提供的两张截图的判断：
  - 分享确认页本身是正常的
  - 旧问题还没算解决，因为失败页仍然还是泛化高层文案
  - 本轮完成后，下一次同样失败时，理论上应该能直接看到：
    - `失败阶段：copy`
    - 或 `失败阶段：persist`
    - 并带 `NSError domain / code`
- 下一轮最值得继续：
  1. 让你在真机上重新走一遍：
     - 系统相册 -> 分享 -> PhotoMemo -> 按当前风格继续
  2. 拿新的失败截图或系统日志
  3. 按已经暴露出来的具体阶段直接修根因，不再泛查
  4. 如果卡在 shared container copy，再重点核对 security-scoped URL / provider payload 类型
  5. 如果卡在 persist，再重点核对 request 序列化和共享容器写入
  6. 如果已经成功进入 `persist`，再看是不是后续 render/save 才失败

## 2026-06-20 默认个性化文案、关系称呼注入与原名导出已落地

- 本轮目标：
  - 继续顺着 `Personal Profile + 默认风格` 收口模板 1 的默认语言
  - 让记录者身份真正进入最终成片文案
  - 导出文件名恢复原图命名，不再追加 `_PhotoMemo`
- 本轮实际改动：
  - 新增 `MetadataContext.Key.relationshipLabel`
  - 新增公开模板变量：
    - `记录者称呼`
  - 公开变量里原 `时间点名称` 已收口成：
    - `主角称呼`
  - 模板默认值更新为：
    - 左上：`{{relationship_label}}手持{{model}}记录`
    - 左下：`拍摄于{{capture_date_display}}`
    - 右下：`{{anchor_title}}今天{{anchor_age_text}}啦`
  - `Template.normalizedForEditing` 现在会兼容迁移旧默认文案：
    - `{{title}}` -> 新左上默认句式
    - `记录于...` -> `拍摄于...`
    - `今天{{anchor_age_text}}` -> `{{anchor_title}}今天{{anchor_age_text}}啦`
- 本轮运行时补充：
  - `RecordCardBuildService` 现在会从共享 `UserDefaults` 中读取 `photomemo.personalProfile`
  - 若存在有效 `PersonalProfile`，会把 `resolvedRelationshipLabel` 注入 `MetadataContext`
  - 这样默认左上角已经可以直接得到：
    - `他爹手持iPhone 15 Pro记录`
    - `爸爸手持Canon记录`
- 本轮导出命名变化：
  - 默认导出名改为沿用原图名
  - 重名时按复制规则递增：
    - `IMG_1234.jpg`
    - `IMG_1234 (1).jpg`
    - `IMG_1234 (2).jpg`
- 本轮新增测试：
  - `Tests/PhotoMemoTests/VariableTests/EditorProjectionEngineTests.swift`
    - 覆盖文字 + 模块 chip 的 round-trip
    - 覆盖前置文字删除后，后续 chip 不应损坏
  - `Tests/PhotoMemoTests/ExportTests/RecordCardBuildServiceTests.swift`
    - 覆盖 Personal Profile 记录者称呼注入
    - 覆盖默认成片语义与原名导出递增规则
- 本轮验证结果：
  - 定向 `RecordCardBuildServiceTests` 通过
  - 定向 `EditorProjectionEngineTests` 通过
  - `PhotoMemo` build 通过
  - `PhotoMemoiOS` build 通过
    - 此次成功编译已包含 Share Extension / Widget Extension 依赖
- 本轮需要诚实保留的边界：
  - 独立 `PhotoMemoShareExtension` scheme 单跑时，当前工程仍会拉起完整 iOS 依赖图
  - 那条命令为了节省时间被中断，没有单独保留 `BUILD SUCCEEDED`
  - 但共享文件已经在 `PhotoMemoiOS` 全量编译里真实通过
- 本轮还没完全收口的问题：
  - EXIF 参数摘要模块重新插入和删除边界，仍要继续盯
  - 用户提到的异常拼接：
    - `途途1岁24天）〕啦`
    - 还没有拿到稳定复现场景
  - 分享失败提示图还没收到，本轮未分析
  - `/Users/rui/Downloads/IMG_9565.HEIC` 本轮读取时本地未找到，需要你后续再补
- 下一轮最值得继续：
  1. 先复现并修正右下区域异常拼接
  2. 把 EXIF 参数摘要模块做成更稳定的可重插入 chip
  3. 拿到分享失败提示图后，直接排查 Share 保存失败链路

## 2026-06-20 First Run Wizard 与 Personal Profile 基础切片已落地

- 本轮目标：
  - 不做大规模架构迁移
  - 直接落一个真实可用的 `Personal Profile + First Run Wizard` 最小代码切片
  - 保持现有渲染、导出、Share 主链不变
- 本轮新增代码：
  - `Source/PhotoMemo/PhotoMemo/Models/PersonalProfile.swift`
  - `Source/PhotoMemo/PhotoMemo/Services/PersonalProfileStore.swift`
  - `Source/PhotoMemo/PhotoMemo/Views/FirstRun/FirstRunWizardView.swift`
  - `Tests/PhotoMemoTests/MetadataTests/PersonalProfileStoreTests.swift`
- 本轮接入方式：
  - `PhotoMemoRootSceneView` 现在会先判断 `requiresFirstRun`
  - 未完成首次初始化时，先进入 5 步向导
  - 完成后再进入现有 `MainView`
- 向导当前 5 步：
  1. 这是为谁记录
  2. 宝宝叫什么
  3. 出生日期
  4. 默认风格
  5. 保存位置
- 本轮在 UI 表达上又进一步收紧了一次：
  - 欢迎语改成更像系统首次设置的语气
  - 步骤标签收口成 `1 / 5` 这种更轻的表达
  - 完成页保留，但不再像信息面板，更接近安静的收尾确认
- 本轮兼容策略：
  - `PersonalProfileStore` 会从现有 `SettingsService` 回填：
    - 生日 anchor
    - 当前样式槽位
    - 当前默认相册
  - 完成向导后，再把结果写回现有 settings 路径
  - 这样旧的 `UserDefaults`、Share、导出、Batch 都不用迁移
- 本轮顺手补齐：
  - 默认保存位置现在支持明确区分：
    - `系统相册`
    - `photomemo 相册`
  - Share 摘要、主界面输出摘要、保存反馈文案都已同步识别 `系统相册`
- 本轮 target 边界修正：
  - 由于工程会把新文件自动带进 extension target
  - `PersonalProfileStore.swift`
  - `FirstRunWizardView.swift`
  - 已用 `#if !PHOTOMEMO_SHARE_EXTENSION` 收口，避免污染 Share Extension 编译边界
- 本轮验证：
  - `PhotoMemoTests` 通过
  - 定向 `PersonalProfileStoreTests` / `PhotoMemoShareWorkflowSummaryTests` 通过
  - `PhotoMemo` build 通过
  - `PhotoMemoiOS` build 通过
  - `PhotoMemoShareExtension` build 通过
- 本轮还没做：
  - `Personal Profile` 的独立编辑入口
  - Main App IA 真正改成：
    - Personal Profile
    - Styles
    - Settings
    - About
  - 首次完成后的“设置完成页”之外的后续信息架构收口
  - 真机手感验证
- 下一轮最值得继续：
  1. 给 `Personal Profile` 一个正式入口，而不是只存在于 First Run
  2. 开始把主界面上属于“人”的设置从 style/configuration 里继续剥离
  3. 让 Share 更明确读取 `Profile + Default Style`，继续向真正的 share-first 靠拢

## 2026-06-20 v1.0 产品模型基线已定义

- 本轮目标：
  - 不做大 UI 改造
  - 先定义 PhotoMemo 的长期产品模型
  - 把未来所有功能都收敛到 `Personal Profile -> Style -> Workflow`
- 本轮新增文档：
  - `Docs/ProductModel.md`
- 本轮同步更新：
  - `Docs/ProductDirection.md`
  - `Docs/ProductBacklog.md`
  - `Docs/CURRENT_STATUS.md`
  - `README.md`
- 本轮核心结论：
  - Main App 不是日常处理面，而是工作流准备面
  - Share Extension 不是技术交接面，而是未来主执行面
  - `Personal Profile` 负责：
    - relationship
    - baby nickname
    - birthday
    - default album
    - default style
  - `Style` 负责：
    - layout
    - variables
    - visual arrangement
    - bottom-card composition
    - renderer-facing behavior
  - `Workflow` 负责：
    - Apple Photos -> Share -> Generate -> Save
    - 运行时处理状态
    - 结果写回
- 本轮对当前仓库边界的判断：
  - `selectedTemplate` / `selectedBadge` / `configurationSlots` 已经接近 Style
  - `selectedAlbumIdentifier` / `selectedAlbumTitle` 应迁到 Personal Profile
  - 当前 `anchors` / `selectedAnchorID` 仍混合了身份信息与执行语义，后续应拆成：
    - profile-owned birthday / memory dates
    - style or workflow-owned reference choice
  - Share Extension 后续应只读取：
    - Personal Profile
    - default Style
- 本轮产品术语方向：
  - `Configuration` -> `Style`
  - `Configuration Slot` -> `Saved Style`
  - `Anchor` -> `Birthday` / `Memory Date`
  - 继续减少 `workspace / snapshot / batch` 这类实现词汇的外显
- 推荐实现顺序：
  1. 新增 `PersonalProfile` 数据模型
  2. 从现有 settings 做兼容性回填
  3. 上一次性 First Run
  4. 主界面 IA 收口到：
     - Personal Profile
     - Styles
     - Settings
     - About
  5. Share 默认直接执行 `Profile + Style -> Generate -> Save`
- 兼容性结论：
  - 本轮不需要破坏现有 `UserDefaults`
  - 不需要迁移 renderer / export / metadata pipeline
  - 不需要更新 ADR，因为还没有进入已实现的架构边界调整
- 本轮验证：
  - 文档改动，无需构建
- 下一轮最值得继续：
  - 开始设计 `PersonalProfile` 的最小可落地数据结构
  - 评估如何从当前 `SettingsService` 无损回填
  - 再进入 First Run 的最小实现切片

## 2026-06-20 首次权限窗与预览/补充信息收口

- 本轮目标：
  - 优化首次权限引导弹窗的视觉表现
  - 继续收紧 iPhone 预览/编辑页里的低价值入口
  - 恢复补充信息勾选逻辑
  - 修正补充信息中文导出时的 EXIF `UserComment` 稳定性
- 本轮主界面与 iPhone 变化：
  - `MainPermissionSetupSheet` 改成更接近系统卡片式的居中权限引导，不再左右拉满
  - iOS 预览导入区移除了 `从文件导入`，只保留系统照片选择
  - 预览侧 `Live Context` 模块已移除，页面更紧凑
  - 输出区改成更直接的 `保存至` + 相册选择表达，并补充：
    - 未指定时默认保存到 `PhotoMemo` 相册
  - 原先的 `写入位置 ...` 说明块已删除
  - 编辑页移除了 `风格` 分组，继续把主界面收敛成配置中心
  - 四个个性化区域输入高度继续压缩，和模块插入态更接近
  - `补充信息` 恢复为：
    - 勾选时输入自定义补充内容
    - 不勾选时自动回退到右下区域最终生成内容
  - 自定义补充输入框聚焦时会主动清掉其他编辑焦点，减少光标跳去别的窗口的问题
- 本轮导出稳定性修正：
  - `RecordCardBuildService` 已按最新产品语义保留：
    - 自定义补充关闭时，导出说明回退到右下区域完整结果
    - 自定义补充开启且有内容时，优先写入用户自定义内容
  - `RecordCardExportService` 新增 JPEG EXIF `UserComment` 的 Unicode patch：
    - 修正 `ImageIO` 直接写中文时出现截断/空字符异常的问题
    - 现在 fixture 回归里的中文说明写入已经恢复稳定
- 涉及文件：
  - `Source/PhotoMemo/PhotoMemo/Views/Main/PhotoImporterView.swift`
  - `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+PreviewPanels.swift`
  - `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+OutputSection.swift`
  - `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+Permissions.swift`
  - `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+LayoutSections.swift`
  - `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+TemplatePanels.swift`
  - `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+ComposerEditor.swift`
  - `Source/PhotoMemo/PhotoMemo/Services/RecordCardBuildService.swift`
  - `Source/PhotoMemo/PhotoMemo/Services/RecordCardExportService.swift`
  - `Tests/PhotoMemoTests/ExportTests/RecordCardBuildServiceTests.swift`
  - `Tests/PhotoMemoTests/ExportTests/FixtureExportReadbackTests.swift`
- 本轮验证：
  - `PhotoMemoTests` 通过
  - `PhotoMemo` build 通过
  - `PhotoMemoiOS` build 通过
  - `PhotoMemoShareExtension` build 通过
- 本轮仍未人工验证：
  - 真机上首次权限弹窗的新视觉比例和手感
  - iPhone 上补充信息勾选开关切换时，输入焦点是否已经完全稳定
  - 真实保存到系统相册后，外部查看工具对中文 `UserComment` 的兼容表现
  - 预览页新的 `保存至` 文案在 17 Pro Max 上的排版读感

## 2026-06-20 相册入口去重与 Share 相册去向同步修正

- 本轮目标：
  - iPhone 主界面只保留预览页里的相册写入入口
  - 修正 Share 确认页没有读取到最新目标相册的问题
- 本轮修正：
  - iPhone 紧凑布局下，`编辑` 页不再重复显示 `输出` 卡片
  - 主 App 现在会把当前选中的相册标识和相册名称一起立即写入共享 `UserDefaults`
  - Share 确认页的 `结果去向` 会优先显示真实相册名，例如 `存入“家庭相册”`
  - 相册列表刷新后，也会把当前选中相册的最新标题重新同步回共享配置
- 新增测试：
  - `PhotoMemoShareWorkflowSummaryTests`
    - 覆盖自定义相册名称展示与 generic fallback
  - `SettingsServiceTests`
    - 覆盖相册标识与相册名称的持久化
- 涉及文件：
  - `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+LayoutSections.swift`
  - `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+ModalAndLifecycle.swift`
  - `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+WorkspaceConfigurationState.swift`
  - `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+DerivedState.swift`
  - `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+ExportActions.swift`
  - `Source/PhotoMemo/PhotoMemo/Services/SettingsService.swift`
  - `Source/PhotoMemo/PhotoMemo/App/BatchConfigurationSnapshotProvider.swift`
  - `Source/PhotoMemo/PhotoMemo/App/SharedBatchConfigurationSnapshotService.swift`
  - `Source/PhotoMemo/PhotoMemo/App/PhotoMemoShareWorkflowSummary.swift`
  - `Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionViewController.swift`
  - `Tests/PhotoMemoTests/MetadataTests/SettingsServiceTests.swift`
  - `Tests/PhotoMemoTests/VariableTests/PhotoMemoShareWorkflowSummaryTests.swift`
- 本轮验证：
  - `PhotoMemoTests` 通过
  - `PhotoMemo` build 通过
  - `PhotoMemoiOS` build 通过
  - `PhotoMemoShareExtension` build 通过
- 本轮仍未人工验证：
  - 真机上重新选择目标相册后，立即从系统相册分享，确认页是否稳定显示最新相册名
  - 真实分享链路里写回目标相册是否已完全消除之前那次报错

## 2026-06-20 iPhone 全屏与时间点 sheet 修正

- 本轮目标：
  - 检查 iPhone 17 Pro Max 上主界面上下黑边
  - 核对时间锚点界面的时间设定入口
- 本轮修正：
  - `PhotoMemoiOS` target 已补齐：
    - `LaunchScreen`
    - iPhone / iPad 支持方向键
  - 已确认 `PhotoMemoiOS.app` 包内存在：
    - `LaunchScreen.storyboardc`
  - 时间点管理和时间点编辑 sheet 现在在 iPhone 上不再沿用 macOS 的固定最小尺寸
  - 时间选择文案从 `锚点时间` 调整为更明确的 `设定时间`
  - iPhone 上时间选择器改为更接近按钮入口的 compact 样式
- 涉及文件：
  - `Source/PhotoMemo/PhotoMemo.xcodeproj/project.pbxproj`
  - `Source/PhotoMemo/PhotoMemo/iOS/App/LaunchScreen.storyboard`
  - `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+ModalAndLifecycle.swift`
  - `Source/PhotoMemo/PhotoMemo/Views/Anchor/AnchorListView.swift`
  - `Source/PhotoMemo/PhotoMemo/Views/Anchor/AnchorEditorView.swift`
- 本轮验证：
  - `PhotoMemo` build 通过
  - `PhotoMemoiOS` build 通过
  - `PhotoMemoShareExtension` build 通过
  - `PhotoMemoTests` 通过
- 本轮仍未完成：
  - 还没有直接看到你真机 17 Pro Max 上修正后的实际画面
  - 如果你重装后仍有黑边，就需要继续排查是否是设备安装态或系统兼容模式缓存问题

## 2026-06-20 Alpha 0.8 产品减法切片已落地

- 本轮目标：
  - 不加新功能
  - 不改架构
  - 只做默认流程减法、术语收口和界面降噪
- 本轮新增：
  - `Docs/ProductScore.md`
- 本轮主界面变化：
  - 去掉了默认编辑流里的多张说明卡片：
    - 个性化区域说明
    - 补充信息说明
    - 输出说明
    - 智能模块说明
  - Anchor 列表移除了重复的 `设为当前`
  - Anchor 编辑页只保留核心输入，不再堆长段教学文字
  - 权限区文案改成更短的“为什么需要权限”
  - 默认主界面不再强调顶部 hero pills
- 本轮术语收口：
  - `配置工作区` -> `默认风格`
  - `当前配置` -> `当前风格`
  - 多处 `模板` 可见文案 -> `风格`
  - 多处 `EXIF` 可见文案 -> `照片信息 / 拍摄时间`
- iPhone / Share 变化：
  - 后台状态页只保留：
    - 当前处理
    - 失败重试
    - 最近失败
  - Share 页与相关失败提示改成 `当前风格` 语言，不再强调技术配置感
- 本轮验证：
  - `PhotoMemo` build 通过
  - `PhotoMemoiOS` build 通过
  - `PhotoMemoShareExtension` build 通过
  - `PhotoMemoTests` 通过
- 本轮还没手动验证：
  - 真机上主界面减掉说明卡后，第一次使用是否仍足够敢点
  - 真机 share sheet 中 `当前风格` 的读感
  - 精简后的后台状态页是否覆盖了最关键异常场景
- 下一轮最值得继续：
  - 继续沿 Share-first 主链推进
  - 优先补单张预览 / 生成保存反馈闭环
  - 继续把低频说明和管理动作从默认路径拿走

## 2026-06-20 Product audit completed

- 本轮目标：
  - 不改代码
  - 只做产品审查
  - 回答每个可见页面里的 UI 元素是否真的有必要继续留在主流程里
- 本轮新增：
  - `Docs/ProductAudit.md`
- 本轮同步更新：
  - `Docs/ProductDirection.md`
- 新写入的核心产品原则：
  - `The best PhotoMemo experience is the one users barely notice.`
  - `PhotoMemo 最好的体验，是用户几乎感觉不到它的存在。`
- 这轮审查后的高确定性结论：
  - 主 App 仍然有过多解释性 UI
  - Share Extension 还应继续朝“几乎无感”的执行流收缩
  - 帮助中心、重命名、Logo、自定义说明、后台状态等低频内容应继续下沉
  - 时间点编辑页和后台状态页里仍有一批可以直接删减的说明与次级动作
- 本轮验证：
  - 文档改动，无需构建
- 下一轮最适合承接：
  - 按 `Docs/ProductAudit.md` 的高确定性结论，挑一个最小 UI 切片继续减法
  - 优先从主界面解释性卡片、Anchor list 重复动作、Share 页过长说明做起

## 2026-06-20 Alpha 0.7 Share Alpha-01 单页确认面已落地

- 本轮目标：
  - 只做 Share Alpha-01
  - 解决“看得懂、敢点、知道结果”
  - 不进入完整生成保存
- 本轮核心变化：
  - `PhotoMemoShareExtensionViewController` 不再一打开就自动继续
  - 现在会先展示：
    - 分享了几张图
    - 当前配置名称
    - 结果去向
  - 主按钮改成明确确认动作：
    - `按当前配置继续`
  - 成功文案不再是“已加入收件箱”
  - 失败态现在会给出更可执行的重试建议
- 这轮刻意没做：
  - 单张预览
  - 生成 -> 保存闭环
  - 批量 share
  - 自动配置识别
  - 多页面 wizard
- 当前真实边界：
  - 这还是 share -> intake -> app-side continue 的链路
  - 只是入口产品表达已经从“技术交接面”变成“单页确认面”
- 本轮验证：
  - `PhotoMemoTests` 通过
  - `PhotoMemoShareExtension` build 通过
  - `PhotoMemoiOS` build 通过
  - `PhotoMemo` build 通过
- 本轮文档同步：
  - `Docs/Alpha/BugList.md`
  - `Docs/Alpha/UXNotes.md`
  - `Docs/CURRENT_STATUS.md`
- 下一轮最值得继续：
  - Share 单张预览
  - 然后才进入单张图 happy path 的最短主链雏形
  - 继续避免过早扩到批量/智能识别/复杂恢复

## 2026-06-20 Alpha 0.7 zero-friction share baseline landed

- 本轮目标：
  - 先重设计 Share-first 主链
  - 不直接做“大确认页”
  - 让默认分享路径尽量零摩擦
- 本轮新增：
  - `Docs/ShareZeroFrictionWorkflow.md`
  - `Source/PhotoMemo/PhotoMemo/App/PhotoMemoShareWorkflowSummary.swift`
  - `Tests/PhotoMemoTests/VariableTests/PhotoMemoShareWorkflowSummaryTests.swift`
- 产品层共识已进一步收口：
  - 默认路径是：
    - `Share -> PhotoMemo -> 使用当前配置 -> 继续处理 -> 写回系统相册`
  - 配置属于主 App，不属于日常分享时刻
  - 高级设置以后可以有，但不能打断默认路径
- Share Extension 本轮已做的最小实现切片：
  - 从“正在交给 PhotoMemo 处理”改成更接近自动处理入口的表达
  - 被动展示：
    - 当前配置
    - 当前时间点
    - 当前输出方式
  - 成功文案不再只强调“进入收件箱”，而是强调：
    - 已接收
    - 会按当前配置继续处理
- 这轮刻意没做：
  - 预览页
  - 配置切换
  - 高级设置展开
  - 真正的 extension 内生成并保存
- 当前真实边界：
  - 这还是 intake-backed 的分享主链，不是假装已经完成了全部处理
  - 但产品表述和默认心智已经从“技术交接面”转向“自动处理入口”
- 本轮验证：
  - `PhotoMemoTests` 通过
  - `PhotoMemoShareExtension` build 通过
  - `PhotoMemoiOS` build 通过
  - `PhotoMemo` build 通过
- 下一轮最值得继续：
  - 真机检查 share sheet 的实际停留时长和读感
  - 决定下一步是先做轻量预览，还是先增强完成反馈
  - 继续坚持“高级设置不打断默认路径”

## 2026-06-20 Alpha 0.7 validation rhythm established

- 本轮目标：
  - 不继续扩展功能
  - 把 PhotoMemo 正式切到“真实产品验证”节奏
- 本轮新增文档：
  - `Docs/Alpha/Alpha01.md`
  - `Docs/Alpha/BugList.md`
  - `Docs/Alpha/UXNotes.md`
  - `Docs/Alpha/KnownIssues.md`
- 本轮统一后的开发模式：
  - 发现一个体验问题
  - 判断是不是产品问题
  - 修一个小点
  - Build
  - 真机验证
  - Commit
- 当前建议的验证重点：
  - Share Extension：宝宝照 / 风景 / 夜景 / HEIC / JPEG / Live Photo
  - Main App：配置保存、配置切换、时间锚点、Memory、模板编辑
  - Export：连续导出 20-50 张，观察文件名、EXIF、保存与相册显示
- 当前明确暂停的方向：
  - 大规模 UI 重构
  - 新 Memory 功能
  - 新 Renderer
  - 新 Batch
  - 新 Metadata
- 版本语言：
  - 当前阶段建议叫 `Alpha 0.7`
  - 目标只有一句话：
    - 每天都愿意用，而不是每天都在开发
- 本轮验证：
  - 文档改动，无代码构建需求

## 2026-06-20 v0.7.4 Product polishing docs established

- 本轮目标：
  - 不改代码
  - 把 PhotoMemo 正式推进到“产品打磨期”的文档基线
- 本轮新增文档：
  - `Docs/ShareExtensionReview.md`
  - `Docs/DesignSystem.md`
  - `Docs/ProductBacklog.md`
- 本轮关键结论：
  - Share Extension 目前还是“技术交接面”，还不是完整的主产品体验
  - Main App 继续朝配置中心收敛
  - 之后所有 UI 需要开始遵守统一设计系统
  - 新想法以后先进入 backlog，不直接打断当前开发节奏
- Share Extension review 的核心判断：
  - 第一次使用的人仍然会有一点迷路
  - 当前成功态更像“已加入收件箱”，还不是“已完成生成并保存”
  - 最值得推进的是：预览、当前配置、生成、保存这条最短主链
- 本轮 backlog 分层：
  - `Now`：Share-first 主链、Alpha 可用性、真实设备体验、预览/导出信任
  - `Next`：Share Extension 内配置切换、保存反馈、术语统一、Design System 收敛
  - `Later`：批量分享、Quick Actions、更多默认智能化
  - `Icebox`：零配置智能模式、自动分类、模板生态扩张
- 本轮验证：
  - 文档改动，无代码构建需求

## 2026-06-20 v0.7.3 Product direction docs aligned

- 本轮目标：
  - 不改代码行为
  - 只把产品方向正式写进仓库文档
- 本轮新增文档：
  - `Docs/ProductDirection.md`
  - `Docs/UX_PRINCIPLES.md`
- 本轮统一后的核心口径：
  - PhotoMemo is a memory generator built around Apple Photos, not a photo editor.
  - PhotoMemo 不是修图工具，而是围绕系统相册构建的记忆生成器。
  - Share Extension 是主工作流
  - Main App 是配置中心
  - 未来 UX 以更少决策、更少滚动、更少阅读为优先
- 本轮同步调整：
  - `README.md` 首页定义已按新口径更新
  - `Docs/CURRENT_STATUS.md` 已补充这次方向对齐记录
- 本轮验证：
  - 文档改动，无代码构建需求

## 2026-06-20 v0.7.2 Alpha 可用性迭代（第一轮）已落地

- 本轮目标：
  - 不加新功能
  - 不动架构边界
  - 只围绕 Alpha 阶段的真实上手体验收敛主界面
- 本轮主界面改动：
  - 照片导入区已前移到工作区更靠上的位置
  - `PhotoImporterView` 现在优先提供系统 `PhotosPicker`
  - 文件导入改为次级入口，保留给桌面素材与外部图片
  - iPhone 预览流里原先重复出现的工作区配置卡片已移除
  - 空照片态在滚动容器里不再强占整块高度，减少无意义留白
- 本轮配置与模板交互收敛：
  - 工作区配置区不再显示“当前配置”独立摘要卡
  - 三个配置槽位改成更直接的模块列表样式
  - 点选槽位会立即切换并刷新预览
  - 每个槽位都提供内联“编辑”菜单，用于重命名、保存当前内容、恢复默认
  - 模板区去掉更偏开发期的“预设骨架 / 默认右下”等表述
  - 模板区现在更强调“当前名称 + 直接编辑下方内容”
- 本轮可用性修正：
  - iOS 自定义区域编辑器对 CJK 输入法改为优先走系统原生合成流程，降低中文输入被编辑投影层打断的概率
  - 时间点管理按钮改为更明确的“管理与编辑”
  - 时间点列表中的“编辑”入口已放大为明确按钮，并补充“设为当前”
  - 手动导出文件如果遇到同名目标，现在会自动生成：
    - `filename (1)`
    - `filename (2)`
    - `filename (3)`
    避免直接覆盖
- 本轮验证：
  - `PhotoMemo` build 通过
  - `PhotoMemoiOS` build 通过
  - `PhotoMemoShareExtension` build 通过
  - iOS 构建仍有既存警告：
    - interface orientations
    - launch configuration / launch storyboard
- 本轮尚未手动验证：
  - 真机上 `PhotosPicker` 导入一张系统照片后的完整 EXIF 读取体验
  - 中文输入法在长段连续编辑、删除 chip、跨 chip 插入时的最终手感
  - 时间点编辑页在 iPhone 上的最终触感
- 下一轮最值得继续：
  - 真机逐项复核 `PhotosPicker`、中文输入、时间点编辑
  - 继续检查预览页纵向节奏和各卡片间距是否还能更紧凑
  - 如果这轮手感稳定，再进入更细的 iPhone 主流程 polish

## 2026-06-20 v0.7.1 Fixture-backed Export Read-back 已落地

- 本轮目标：
  - 不改架构
  - 不改 renderer / workspace / batch 行为语义
  - 让 Sprint-009 的 smoke foundation 真正进入 fixture-backed correctness 验证
- 本轮新增测试与资产：
  - `Tests/Fixtures/GenerateSyntheticFixtures.swift`
  - `Tests/Fixtures/Synthetic/`
  - `Tests/PhotoMemoTests/Support/SyntheticFixtureLibrary.swift`
  - `Tests/PhotoMemoTests/ExportTests/FixtureExportReadbackTests.swift`
  - `Tests/PhotoMemoTests/BatchTests/BatchFixtureCoverageTests.swift`
- 当前已提交的 synthetic fixture 覆盖：
  - `01_iPhone_JPEG.jpg`
  - `02_iPhone_HEIC.heic`
  - `05_GPS.jpg`
  - `06_NoGPS.jpg`
  - `07_Portrait.jpg`
  - `08_Landscape.jpg`
  - `10_LowMetadata.jpg`
- 仍保留为 reserved-only：
  - `03_Canon.CR3`
  - `04_Nikon.JPG`
  - `09_LivePhotoStill.heic`
- 本轮自动化覆盖新增：
  - JPEG fixture export -> read-back
  - HEIC fixture import + export read-back
  - EXIF / TIFF / GPS / orientation / dimensions / description families 的显式断言
  - batch fixture enqueue / cancel / retry eligibility
- 本轮修到的真实 correctness 问题：
  - `RecordCardExportService` 之前用目标 render size 回写 metadata
  - 在实际渲染位图尺寸与目标尺寸出现 1px 差异时，可能导致：
    - 顶层 `PixelHeight`
    - EXIF `PixelYDimension`
    不一致
  - 现在已改为以最终 `CGImage` 实际尺寸回写 metadata
- 本轮当前验证状态：
  - `PhotoMemoTests` 已通过，共 19 个 tests
  - `PhotoMemo` build 已通过
  - `PhotoMemoiOS` build 已通过
  - `PhotoMemoShareExtension` build 已通过
- 下一轮最值得做：
  - renderer snapshot prep 继续往正式 snapshot 基线推进
  - 再评估是否要加入 Photos save-back read automation
  - 对 reserved 的 Nikon / Live Photo still fixtures 再补第二批 synthetic 或 licensed sample

## 2026-06-20 v0.7.0 Memory Engine Foundation 已落地

- 本轮目标：
  - 不改 renderer / export / batch / UI 行为
  - 引入真正的 Memory domain foundation
  - 让记忆语义从“零散逻辑”进入可测试、可扩展的独立边界
- 本轮新增架构文档：
  - `Docs/ADR/ADR-006-MemoryEngineFoundation.md`
  - `Docs/MemoryEngine.md`
- 本轮新增实现：
  - `Source/PhotoMemo/PhotoMemo/MemoryEngine/MemoryContext.swift`
  - `Source/PhotoMemo/PhotoMemo/MemoryEngine/MemoryCalculationResult.swift`
  - `Source/PhotoMemo/PhotoMemo/MemoryEngine/MemoryVariableProvider.swift`
- 本轮接入点：
  - `CardVariableProvider` 现在通过 Memory Engine 供给记忆变量
  - `TemplateVariable` 现在公开：
    - `{{days_since}}`
    - `{{years_since}}`
    - `{{months_since}}`
    - `{{weeks_since}}`
    - `{{baby_age}}`
- 当前刻意保持不变：
  - `AnchorEngine`
  - Renderer
  - Export
  - Batch
  - Share Extension 流程
  - 现有 `memory_summary` 的 story-first / anchor-summary-first 语义
- 本轮测试：
  - 新增 `MemoryEngineTests` suite（当前放在 `PhotoMemoTests` target 内）
  - 覆盖：
    - 不满 1 岁年龄文案
    - 闰年生日
    - 时区边界
    - 未来时间点 clamp
    - `CardVariableProvider` 集成
    - public variable catalog 暴露
- 版本节奏：
  - 从这一轮开始，面向 release / changelog / 外部总结时，优先使用版本号
  - 当前版本基线记作：
    - `v0.7.0`
  - 旧的 `Sprint-*` 记录继续保留为内部开发历史，不要求回写改名
- 本轮验证状态：
  - `PhotoMemoTests` 已通过
  - `PhotoMemo` build 已通过
  - `PhotoMemoiOS` build 已通过
  - `PhotoMemoShareExtension` build 已通过

## 2026-06-20 Sprint-009 回归验证基础已落地

- 本轮目标：
  - 不改架构
  - 不改 renderer / editor / workspace / batch 设计
  - 建立可长期复用的 fixture / regression / test foundation
- 本轮新增文档：
  - `Docs/FixtureSpecification.md`
  - `Docs/RegressionMatrix.md`
  - `Docs/AcceptanceCriteria.md`
  - `Docs/CIReadiness.md`
- 本轮新增目录与基础资产：
  - `Tests/Fixtures/README.md`
  - `Tests/Fixtures/FixtureManifest.json`
  - `Tests/PhotoMemoTests/`
- fixture 侧当前共识：
  - 现在先不提交真实照片二进制
  - 先把保留文件名、元数据要求、命名规范、后续引入规则固定下来
  - 预留的第一批 fixture 名称已覆盖：
    - iPhone JPEG / HEIC
    - 非 Apple 相机 JPEG
    - GPS / No GPS
    - Portrait / Landscape
    - Live Photo still 边界样本
    - Low metadata 样本
- 本轮工程变化：
  - `PhotoMemo.xcodeproj` 新增 `PhotoMemoTests` target
  - 新增 shared scheme：
    - `PhotoMemo.xcscheme`
    - `PhotoMemoTests.xcscheme`
  - 当前 `PhotoMemoTests` 依赖主 macOS app target，采用最小 unit-test bundle 形态
- 本轮新增 smoke tests：
  - `PhotoMetadataReaderTests`
    - EXIF timezone 解析
    - GPS ref 正负号归一化
  - `PhotoMetadataNormalizationTests`
    - aspect ratio / megapixels / location display
    - 坐标回退文案
  - `MetadataContextTests`
    - capture timezone 驱动的日期组件生成
  - `TemplateVariableEngineTests`
    - token 替换与缺失 token 清空
  - `RecordCardBuildServiceTests`
    - 说明写入开关关闭时不再导出说明
    - 开启时显式 override 生效
- 本轮实际验证结果：
  - `PhotoMemoTests` 测试通过，共 8 个 smoke tests
  - `PhotoMemo` build 通过
  - `PhotoMemoiOS` build 通过
  - `PhotoMemoShareExtension` build 通过
- 本轮过程中修掉的工程问题：
  - 空目录占位文件最初都叫 `.gitkeep`，Xcode 会把它们当成资源复制进 test bundle，导致输出冲突
  - 已改为唯一占位名：
    - `.batch-tests.keep`
    - `.export-tests.keep`
    - `.renderer-tests.keep`
  - 另外补了 `PhotoMemo.xcscheme`，避免新增 shared test scheme 后主 app scheme 在 `xcodebuild -list` 中消失
- 当前真实边界：
  - 已经有了第一层可持续回归验证能力
  - 但还没有真实 fixture 二进制，所以这轮更偏“模型/服务逻辑 correctness 锁定”
  - 还没有进入：
    - renderer snapshot
    - export binary diff
    - Photos integration automation
    - batch fixture E2E
- 下一轮最值得做：
  - 引入可合法提交的真实或合成 fixture 二进制
  - 建立 `PhotoMetadataReader -> export -> read-back` 的 fixture 驱动测试
  - 再评估是否要补 renderer snapshot 与导出文件 metadata 细粒度断言

## 2026-06-20 Sprint-008 输出完整性核对已完成

- 本轮目标：
  - 不做架构重构
  - 不改渲染设计
  - 不改 editor / workspace
  - 优先核对导出完整性、回读能力、批处理可靠性、Live Photo 边界
- 本轮新增文档：
  - `Docs/ExportMetadataAudit.md`
  - `Docs/ExportReadbackVerification.md`
  - `Docs/JPEG_HEIC_Compatibility.md`
  - `Docs/BatchExportReliability.md`
  - `Docs/LivePhotoAssessment.md`
  - `Docs/OutputIntegrityReport.md`
- 本轮确认的关键事实：
  - `RecordCardExportService` 当前采用的是“原始 metadata 字典透传 + 少量显式修补”的导出策略
  - 显式修改的主要字段包括：
    - 输出宽高
    - EXIF 像素尺寸
    - 顶层 orientation = `1`
    - `TIFF Software = PhotoMemo`
    - 说明类字段（开启时）
  - `PhotoLibraryExportService` 会把 `metadata.captureDate` 写到 `PHAssetCreationRequest.creationDate`
  - 但 `PhotoMetadataReader` 当前只回读：
    - width / height
    - TIFF
    - EXIF
    - GPS
    不会把 description/comment 再读回 `PhotoMetadata`
  - batch 路径仍然是单一主链：
    - import -> build -> render/export -> save to Photos
    没有第二套批量专用导出器
- 本轮确认并修掉的 correctness 问题：
  - `shouldWritePhotoDescription` 之前没有真正阻止导出 metadata 写入说明文本
  - 现在 `RecordCardBuildService` 已在该开关关闭时返回空的 export description
  - `MainView+TemplatePanels.swift` 的说明写入预览文案也已同步修正
- 本轮结论：
  - 当前 PhotoMemo 对“静态照片、JPEG-first、写回系统图库”的可靠性已经比较不错
  - 但以下边界仍应如实对待：
    - ICC / 色彩配置文件目前没有显式校验
    - HEIC 目前是可导出/可手动选择，但不是 batch 主验证路径
    - Live Photo 目前只能按 still-image 心智理解，不能宣称支持成对资源保留
    - 说明字段虽然现在能正确写入/关闭，但 app 自己还不能完整回读这些字段
- 本轮验证：
  - `PhotoMemo` build 通过
  - `PhotoMemoiOS` build 通过
  - `PhotoMemoShareExtension` build 通过
- 下一轮最值得做：
  - 建立小型导出 fixture 集，做真正的导出前后 metadata 对照
  - 评估是否把 description/comment 纳入 `PhotoMetadataReader` 的回读范围
  - 再决定是否要进入更细的 EXIF 保真验证或 Photos 写回回归测试

## 2026-06-20 Sprint-007 元数据归一化与变量目录对齐已落地

- 本轮目标：
  - 不改架构
  - 不改渲染/导出/批处理主链
  - 只在现有 metadata pipeline 内提升 correctness、consistency、catalog alignment
- 现在的关键事实：
  - `PhotoMetadataReader` 仍然是唯一 EXIF/GPS 读取入口
  - `PhotoMetadata.normalized()` 现在是 raw model 的统一归一化出口
  - `MetadataContext.Key` 现在是 runtime key 的统一定义
  - `PhotoMetadata.canonicalInventory` 现在是 metadata field inventory 的统一代码定义
- 本轮新增/改善：
  - 解析 capture-date 字符串中的 timezone suffix，保存到 `captureTimezoneOffsetSeconds`
  - `MetadataContext.build(from:)` 在渲染日期组件时，若 metadata 自带 timezone，则按 capture timezone 计算年/月/日/时/分/秒/weekday
  - GPS 现在会根据 `LatitudeRef` / `LongitudeRef` / `AltitudeRef` 处理正负号
  - 新增并公开的 metadata-facing variables：
    - `{{lens_brand}}`
    - `{{location}}`
    - `{{location_display}}`
    - `{{country}}`
    - `{{province}}`
    - `{{city}}`
    - `{{district}}`
    - `{{latitude}}`
    - `{{longitude}}`
    - `{{altitude}}`
    - `{{weekday}}`
    - `{{capture_date_short}}`
    - `{{capture_time_short}}`
    - `{{capture_timezone}}`
    - `{{orientation}}`
    - `{{aspect_ratio}}`
    - `{{megapixels}}`
    - `{{memory_summary}}`
  - `TemplateVariableLibrary.recognized` 的优先级也已按当前 PhotoMemo 使用价值重新排序
  - `TemplateVariableEngine` 的 token regex 现在缓存，不再每次 render 重新编译
- 有意保留为 internal-only 的 runtime keys：
  - `badge_name`
  - `anchor_hours`
  - `anchor_minutes`
  - `anchor_seconds`
- 本轮文档：
  - `Docs/MetadataInventory.md`
  - `Docs/VariableCatalogAlignment.md`
  - `Docs/MetadataNormalizationPlan.md`
  - `Docs/CURRENT_STATUS.md`
- 本轮验证：
  - `PhotoMemo` build 通过
  - `PhotoMemoiOS` build 通过
  - `PhotoMemoShareExtension` build 通过
- 没做的事：
  - 没新建 test target
  - 没做 reverse geocoding / location enrichment
  - 没改 share extension 的 metadata ownership
- 下一轮最值得做：
  - 为 `PhotoMetadataReader -> MetadataContext -> TemplateVariableEngine` 补回归测试
  - 再评估是否进入 `Sprint-008` 的 location enrichment / high-value variables

## 2026-06-20 Composer projection 已抽成独立 EditorProjectionEngine

- 已完成 `Sprint-005` 的保行为抽取：
  - 新增 `Source/PhotoMemo/PhotoMemo/Views/Main/EditorProjectionEngine.swift`
  - 删除旧的 `MainView+ComposerDisplayEngine.swift`
- 当前共识：
  - `String` 仍然是唯一真实来源
  - 没有引入 `ComposerDocument`
  - 没有引入 node tree / rich text / renderer-side projection
- 新引擎当前承接的责任：
  - raw template string -> display text
  - module span 生成与清洗
  - selection clamp
  - caret / selection 调整
  - chip 删除时 replacement range 调整
  - projection state 同步
- 已切换调用点：
  - `MainView+ComposerSession.swift`
  - `MainView+TemplateEditingActions.swift`
  - `MainView+ComposerEditor.swift`
  - `MainView+LayoutSections.swift`
- 明确保持不变：
  - `Template` 持久化格式
  - `RecordCardBuildService`
  - `TemplateVariableEngine`
  - Renderer / Export / Batch / Workspace / Settings
- 这轮目标不是改编辑模型，只是把 editor-specific projection 从 `MainView` 语义下抽离成独立引擎，方便后续继续做 composer 侧治理。

## 2026-06-20 WorkspaceSession Phase A 已铺架构壳层

- 已新增 4 个 workspace session 预备类型：
  - `WorkspaceSessionController`
  - `WorkspaceState`
  - `WorkspaceAction`
  - `WorkspaceEnvironment`
- `MainView` 只做了最小接线：
  - 新增 `workspaceSession` 持有者
  - `onAppear` 时把当前 `MainView` 状态与依赖 seed 进 session
- 这轮明确**没有**迁移：
  - 导出逻辑
  - 权限逻辑
  - 生命周期逻辑
  - 模板编辑逻辑
  - batch / queue 逻辑
- 当前真实状态：
  - `WorkspaceSessionController.send(action:)` 只承接基础状态更新壳层
  - 现有业务仍然全部走原来的 `MainView+*.swift` 实现
  - 这是为下一轮“分阶段把现有 workflow 移进 session”做准备，不代表迁移已开始
- 编译边界：
  - 这些新类型同样通过 `#if !PHOTOMEMO_SHARE_EXTENSION` 避免被 Share Extension target 编译
- 本轮验证：
  - `PhotoMemo` build 通过
  - `PhotoMemoiOS` build 通过
  - `PhotoMemoShareExtension` build 通过

## 2026-06-20 BatchQueueStore 已拆为 4 个聚焦组件

- 已完成 `Review-002`：
  - `BatchQueueStore` 保留为公开 façade 与 `ObservableObject` 状态拥有者
  - 内部职责已拆到：
    - `BatchQueueExecution`
    - `BatchQueuePersistence`
    - `BatchQueueHistory`
    - `BatchQueueNotifications`
- 本轮明确保持不变：
  - UI / 渲染 / 导出行为
  - 队列执行顺序
  - 重试与取消语义
  - `UserDefaults` key 与持久化格式
  - 启动恢复语义
  - 通知发送与 sentAt / stage 回写时机
- 这次没有引入额外 `QueueState` 层，也没有为了行数再继续拆更多人工抽象层。
- `PhotoMemoShareExtension` 当前通过 `#if !PHOTOMEMO_SHARE_EXTENSION` 编译边界避免把 app-side queue façade / notification wiring 拉进 extension target；后续不要误把这些 guard 删除。
- 本轮验证：
  - `PhotoMemo` build 通过
  - `PhotoMemoiOS` build 通过
  - `PhotoMemoShareExtension` build 通过
- 仍未做的验证：
  - 真机/手动回归 `retry`
  - 真机/手动回归 `cancel`
  - 真机/手动回归启动恢复后的继续处理
- 下一步更适合做：
  - 对 `BatchQueueStore` 子系统补最小可行的回归测试
  - 再考虑更高层的架构工作，不要在这轮拆分后立刻继续改 batch 语义

## 2026-06-20 BatchConfigurationSnapshot 单一来源已收口

- 已新增 `BatchConfigurationSnapshotProvider`，作为批处理默认快照与共享配置装配的单一来源。
- `SettingsService.buildBatchConfigurationSnapshot()` 已改为委托给该 provider，不再自己重复拼装默认模板 / 徽标 / 锚点 / 相册标识。
- `SharedBatchConfigurationSnapshotService.loadSnapshot()` 已改为直接复用同一 provider，Share Extension 与主 app 不再各自维护一套装配逻辑。
- 保持不变：
  - `UserDefaults` keys
  - 序列化格式
  - 默认值
  - UI、渲染、导出、通知与队列行为
- 本轮验证：
  - `PhotoMemo` build 通过
  - `PhotoMemoiOS` build 通过
  - `PhotoMemoShareExtension` build 通过
- 后续合适的下一步：
  - 继续拆 `BatchQueueStore`
  - 再收束 `MainView` 的 workspace/export 协调逻辑
  - 暂时不要回退这次 provider 收口，避免再次出现快照装配漂移

这份文件用于帮助新的 Codex 会话快速接手当前项目，避免只依赖历史聊天上下文。

现在仓库根目录还新增了一份更偏“持续接力开发手册”的文档：

- `AI.md`

建议新的 AI 会话把它也作为第一批必读文件之一。

## 2026-06-19 分享摘要已进一步贯穿到桌面端与主 app drain 校正

这一轮继续围绕 share-intake 主链收口，但重点不再是 iPhone sheet 本身，而是让同一份“分享时发生了什么”的摘要在更多真实入口里保持一致。

新增/调整：

- `ExternalPhotoImportSummary` 现在除了会跟着 share extension 请求一起进入 `BatchJob`
- 也会继续挂进：
  - `ExternalIntakeSummary`
  - macOS 主界面的 `记忆进度` 面板

用户现在能看到的变化：

- macOS 左侧 `记忆进度` 里，最近一次外部导入不再只写“来了几张”
- 如果是分享入口，并且分享时有：
  - 重复跳过
  - 导入失败
  - 选中数和真正入队数不一致
  现在文案会直接说清楚
- 也就是说，桌面端现在也能看到更像“处理回执”的信息，而不是只在 iPhone 后台状态里知道异常

这一轮还顺手补了一个主 app 侧的摘要口径修正：

- `PhotoMemoAppRuntime.flushExternalRequests()` 在 drain 共享请求时，会先重新检查真正仍然有效的文件 URL
- 如果 share extension 当时写进收件箱的部分文件，到了主 app 真正接单时已经失效：
  - 现在会把 `importSummary` 重新修正到真实可入队数量
  - 避免后续通知 / 记忆进度把“已经失效、其实没入队”的图片继续算成成功入队

注意：

- 这里修过一次 double-count 细节，最终保留的口径是：
  - 只把“原本标记为 imported，但主 app drain 时已经失效”的数量补进 `failedCount`
  - 不会重复累计

本轮验证：

- `PhotoMemoiOS` 构建通过
- `PhotoMemoShareExtension` 构建通过
- `PhotoMemo` 构建通过

## 2026-06-19 分享接收摘要已贯穿到通知与 iPhone 后台状态

这一轮继续沿着 iPhone / share-intake / background queue 主链做，但重点不是再扩 ActivityKit，而是把“分享时已经发生的部分成功、跳过、失败”真正带进后续反馈链路。

完成内容：

- 新增共享摘要模型：
  - `Source/PhotoMemo/PhotoMemo/App/ExternalPhotoIntakeRequest.swift`
  - `ExternalPhotoImportSummary`
- `ExternalPhotoIntakeRequest` 现在可携带：
  - 成功入队数
  - 重复跳过数
  - 导入失败数
- `PhotoMemoShareExtensionIntakeService` 在 share extension 侧会把这份摘要一起持久化进共享收件请求
- `PhotoMemoAppRuntime` / `BatchQueueStore` 会继续把这份摘要挂到最终 `BatchJob`

这带来的直接效果：

- 后台任务的开始通知现在不再只说“接收了多少张”
- 如果本次分享里有重复项被跳过、或有图片根本没能导入，现在通知里会明确说出来
- iPhone 后台状态页新增了“本次接收结果”卡片，能看到：
  - 分享选中
  - 成功入队
  - 重复跳过
  - 导入失败

这一轮还补了一刀取消保护：

- `BatchQueueStore.swift` 在真正调用 `saveRenderedPhoto` 前又加了一次终态检查
- 这样如果用户在“将要写入系统相册”前一刻取消，就不会再误把后续保存继续跑下去

补充说明：

- share extension 的 Data fallback 去重现在已经是基于内容 `SHA256`，不是旧的“大小 + 名称”近似判断
- 这一轮没有做模拟器启动回归，因为当前机器上的 `CoreSimulatorService` 仍然不可用；但三条构建命令都重新通过了

本轮验证：

- `PhotoMemoiOS` 构建通过
- `PhotoMemoShareExtension` 构建通过
- `PhotoMemo` 构建通过

## 2026-06-19 队列取消与分享去重再硬化

这一小轮没有继续扩界面，而是优先补了三个更容易变成“偶发失灵”的边界。

1. `BatchQueueStore` 取消边界补强

- 文件：
  - `Source/PhotoMemo/PhotoMemo/Services/BatchQueueStore.swift`
- 修正点：
  - 如果用户在任务处理中途取消，当前活跃 task 不再继续把后续流程一路跑到底
  - 现在在 `importPhoto` 返回后、`exportCard` 返回后，都会重新检查 task 是否已经进入终态
  - 如果取消导致处理中抛错，也不再把已取消任务错误地改写成 `failed`
- 结果：
  - 降低“明明取消了，结果还继续保存进系统相册”这类错误行为的风险

2. 失败项重试语义更准确

- 同样在 `BatchQueueStore.swift`
- 修正点：
  - managed intake 源文件如果仍然存在，失败项现在保留重试资格
  - 只有真正找不到受管源文件时，才把 `canRetry` 压成 `false`
- 结果：
  - 更符合之前已经确定的方向：
    - PhotoMemo 自己复制进 `ExternalIntake` 的文件可以临时保留
    - 单张失败不应该轻易丢掉重试机会

3. Share Extension 的 Data fallback 去重更稳

- 文件：
  - `Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionIntakeService.swift`
- 修正点：
  - 之前 Data fallback 的去重 key 近似于 `data.count + suggestedName`
  - 这会让“不同图片刚好大小相同、名字也接近”的情况有误判概率
  - 现在改成基于 `SHA256` 的内容哈希去重
- 结果：
  - 多图分享时，误把不同图片当成重复项跳过的风险更低

顺手补的一点：

- `PhotoMemoiOSLiveActivityDriverService.swift` 现在会在 activity 被结束/失效后更完整地同步 `lastAppliedPayloads`
- 这属于小型状态收口，主要是避免重复应用同一终态 payload

本轮验证：

- `PhotoMemoiOS` 构建通过
- `PhotoMemoShareExtension` 构建通过
- `PhotoMemo` 构建通过

## 2026-06-19 Live Activity widget extension 已接通

这一小轮把上一轮还没收口的 ActivityKit / widget 侧工程接线真正补完了。

完成内容：

- 新增真实 widget extension 入口：
  - `Source/PhotoMemo/PhotoMemoWidgetExtension/PhotoMemoWidgetExtensionBundle.swift`
- 新增 extension plist：
  - `Source/PhotoMemo/PhotoMemoWidgetExtension-Info.plist`
- `PhotoMemoLiveActivityPresentation.swift` 继续作为共享的 Live Activity 展示定义，被 widget extension 直接编译使用
- `PhotoMemoiOS` 现在会同时嵌入：
  - `PhotoMemoShareExtension.appex`
  - `PhotoMemoWidgetExtension.appex`

这轮顺手解决的关键工程坑：

- 之前 share extension 嵌入失败的核心原因，基本确认是 `ShareExtension-Info.plist` 缺少基础 bundle 键，导致嵌入校验时 bundle identifier 被视为 `(null)`
- widget extension 第一版又踩到 `Info.plist` 同时被“处理”和“Copy Bundle Resources”双重产出
- 处理方式是把 widget extension 的 plist 挪到同步组目录外，改成：
  - `Source/PhotoMemo/PhotoMemoWidgetExtension-Info.plist`

本轮验证：

- `PhotoMemoiOS` 构建通过
- `PhotoMemoShareExtension` 构建通过
- `PhotoMemo` 构建通过
- 额外验证了 `PhotoMemoiOS.app/PlugIns` 里已经存在：
  - `PhotoMemoShareExtension.appex`
  - `PhotoMemoWidgetExtension.appex`

当前真实结论：

- iPhone 线不再只是“app 可编译 + 分享扩展可编译”
- 现在已经进入“app + share extension + Live Activity widget extension 可一起构建并嵌入”的阶段
- 后续更值得优先做运行时与设备侧验证，而不是继续卡在 `xcodeproj` 嵌入层

## 项目根路径

- 实际项目路径：`/Users/rui/Desktop/PhotoMemo`
- 当前 Codex 工作区里通常会通过 `desktop_project -> /Users/rui/Desktop/PhotoMemo` 映射访问真实项目

## 产品一句话

PhotoMemo 是一个 **local-first 的 macOS 原生照片信息纪念卡生成器**。  
它不是修图软件，也不是云相册，而是一个基于 EXIF 和时间锚点，把照片转成“带记忆语义的信息卡”的工具。

## 核心原则

- 完全本地运行
- 不上传照片
- 不修改原图，生成新图
- 主界面是“模板校准中心”，不是未来的批量工作台
- 日常处理流程要逐步转向外部接入 + 后台处理 + 写回系统图库
- 不能为了 UI 漂亮而脱离真实渲染/导出链路

## 当前主链路

1. 设置模板
2. 设置时间锚点
3. 导入一张预览照片
4. 读取真实 EXIF
5. 生成真实预览内容
6. 实时预览底部信息卡
7. 保存配置
8. 后续通过外部导入/分享进入后台任务
9. 生成新图并存回系统图库/目标相册

## 已经成形的能力

- SwiftUI macOS 主应用
- EXIF 读取
- 时间锚点引擎
- 四个自定义区域
- 模板预设
- 图标/徽章区域
- 预览渲染
- 导出成新图
- 写回系统图库
- 默认 photomemo 相册策略
- 后台队列、通知、权限引导

## 时间锚点系统共识

智能模块只输出“时间结果本身”，不直接生成整句文案。

例如：

- `{{anchor_age_text}}` -> `1岁2个月18天`
- `{{anchor_duration_text}}` -> `2年4个月18天`
- `{{anchor_elapsed_text}}` -> `已过32天`
- `{{anchor_countdown_text}}` -> `还有86天`
- `{{anchor_day_index_text}}` -> `第128天`

最终表达由用户自己在前后补文字，例如：

- `途途今天` + `{{anchor_age_text}}`
- `距离高考` + `{{anchor_countdown_text}}`

这条原则很重要，不要回退到“模块直接输出整句文案”。

## 当前界面共识

- 整体风格走白色、极简、系统级方向
- 主预览区只保留一张校准照片
- 下面四个区域都必须能独立编辑
- 插入 EXIF/智能模块时，必须进入“当前选中的区域”
- 深色模式下也要可用，但主视觉优先保证浅色系统风格
- Immers 风格只借鉴底部白边语言，内容仍以 PhotoMemo 的记忆语义与智能模块为主
- 当前“徽章/badge”语义已经统一往“Logo 标识”方向收束
- `immersWhite` 在未自定义标识时，保留经典 Apple 小 logo 作为默认回退

## 最近已经处理过的重要问题

最近对 `MainView.swift` 做过一轮关键修正，新的会话不要把这些修回去：

1. 去掉了“没有明确选区时默认插到右下角”的隐式兜底
2. 模块插入前必须先明确选中左上/右上/左下/右下某一区域
3. 开始把四个区域的模块编辑态从“字符串即时反解析”往“更稳定的本地状态”方向收
4. 修正了拖拽重排的目标索引逻辑
5. 模板切换、恢复默认、模板改名后，需要同步刷新模块编辑态

如果后续继续重构 `MainView.swift`，优先保留这些行为。

## 当前最大技术债

`Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift` 已经明显瘦身，目前约 `72` 行，基本就是 coordinator state shell。

- 模板编辑
- 焦点/插入路由
- 拖拽与模块整理
- 权限状态
- 相册选择
- 导出动作
- 批量任务状态展示

最近已经抽出的 `MainView` 子文件包括：

- `MainView+MemoryProgress.swift`
- `MainView+OutputSection.swift`
- `MainView+Permissions.swift`
- `MainView+ComposerEditor.swift`
- `MainView+ComposerPanels.swift`
- `MainView+ComposerSession.swift`
- `MainView+TemplatePanels.swift`
- `MainView+SetupPanels.swift`
- `MainView+PreviewPanels.swift`
- `MainView+PermissionLifecycle.swift`
- `MainView+WorkspaceConfigurationState.swift`
- `MainView+ExportActions.swift`
- `MainView+DerivedState.swift`
- `MainView+CoordinatorSupport.swift`
- `MainView+TemplateEditingActions.swift`
- `MainView+PresentationState.swift`
- `MainView+StateModels.swift`
- `MainView+LayoutSections.swift`
- `MainView+UIPrimitives.swift`
- `MainView+ModalAndLifecycle.swift`
- `MainView+Feedback.swift`

这轮已经把 preview/detail 的显示壳层，以及 editor session / workspace configuration / export-save / permission lifecycle / derived state / template editing actions 都抽出去了。随后又把剩余 editor session 状态做了轻量分组，当前下一阶段更适合继续清理访问级别、少量 panel binding，以及补一轮手动回归，而不是为了拆而拆。

最近还补了三项当前体验修正：

- 相册权限被拒绝后，不再假装还能重新弹系统授权框，而是明确引导去系统设置恢复权限
- 年龄类智能模块在未满 1 岁时不再输出 `0岁...`
- `补充信息` 区已改成单卡片，勾选时使用单独批量说明，不勾选时回退到右下区域最终内容

随后单独起了一轮，把下面两条一起推进：

- 三个固定本地配置槽位，默认对应 `模板 1 / 模板 2 / 模板 3`
- 右侧负责“当前哪套配置生效”、保存到当前配置、恢复当前默认、打开操作指南
- 左侧复杂说明优先改成可关闭提示卡，完整说明收进右侧操作指南 sheet

这条线已经继续向前推进了一步，当前又补上了两项：

- 三个配置槽位现在支持单独自定义命名，用来区分“宝宝成长”“旅行纪念”“高考倒计时”等不同方案
- 右侧操作指南已升级为更像正式帮助中心的分组导航，入口菜单和帮助 sheet 都按主题分组

当前额外共识：

- 槽位命名只改配置槽位标签，不改模板名称
- 恢复槽位默认骨架时，只清除该槽位保存的配置快照，不会顺手清掉自定义槽位名称
- 左侧说明卡即使被用户关闭，完整说明仍可通过右侧帮助中心查看
- 当相册和通知都已授权时，侧边栏里的权限区不再继续占位
- 输出区优先保持“选相册 + 保存新图”主链，不再把元数据验证按钮留在主界面

最近又顺手做了一轮界面收口：

- `个性化区域` 的说明不再是写死文本，而是可关闭提示卡
- `补充信息` 已真正收成单卡，不再上下两块
- 帮助中心不再单独保留权限主题，改成只保留与当前主流程更相关的主题
- `MainView` 里原来那条已经没有界面入口的元数据验证调试支线也已经删掉

随后又完成了一轮更实质的 coordinator 收口：

- `MainView+ComposerSession.swift` 现在承接四个区域编辑器的 display text / selection / module span 会话态
- `MainView+WorkspaceConfigurationState.swift` 承接三个配置槽位的保存、切换、恢复默认和快照应用
- `MainView+ExportActions.swift` 承接相册权限申请、相册刷新、导出并写入系统图库
- `MainView+PermissionLifecycle.swift` 又继续承接了权限首启、scene active 刷新和通知权限反馈
- `MainView+DerivedState.swift` 承接预览、锚点、模板摘要等派生展示态
- `MainView+CoordinatorSupport.swift` 承接 anchor / preview 尺寸这类轻量 coordinator helper
- `MainView+TemplateEditingActions.swift` 承接模板值更新、模块插入和当前编辑区域路由
- `MainView+PresentationState.swift` 承接 rename / guide 相关 sheet 与本地 draft 状态
- `MainView+LayoutSections.swift` 承接 sidebar / detail 与各 section 的视图拼装
- `MainView+UIPrimitives.swift` 承接 `MainFieldSlot` 与主界面共用样式基元
- `MainView+ModalAndLifecycle.swift` 承接 body 外层 sheet / alert / 生命周期接线
- `MainView+Feedback.swift` 承接 alert helper 与 preview stub
- 同时已经把旧的 block-style composer widget / scrubber / literal-composer sheet 遗留清掉
- `MainView.swift` 当前大约回落到 `72` 行
- 这一轮 refactor 收口后，本地 `xcodebuild` 已重新通过

随后又补了一刀轻量 state grouping：

- `MainView+StateModels.swift` 现在统一承接 `MainAlertState`、`MainPresentationState`、`MainEditorSessionState`
- `MainEditorSessionState` 收起了 `focusedField`
- `MainEditorSessionState` 收起了四个区域的 display text / selection / module spans 会话态
- 这一步没有改插入逻辑、光标路由、模板同步或导出行为，只是把剩余 coordinator 状态按语义重新归位

这条线又继续推进了一小步，当前最新共识是：

- `个性化区域` 左侧不再保留顶部“额外控制/说明块”，界面只保留四个真实区域和插入按钮
- 自定义文字不再走原来的 raw token / inline editor 路径，而是作为和 EXIF、智能模块并列的单独文字 chip 进入区域内容流
- 再次点击已选中的文字 chip，可以直接回到文字编辑 sheet 修改当前这段文字
- `识别数据`、`智能数据` 继续保持按钮式插入，不把 `{{anchor_duration_text}}` 这类 token 直接暴露给普通编辑流程
- `补充信息` 和 `输出` 顶部说明都已经改成可关闭提示卡，完整说明继续放在右侧帮助中心
- 模板区里给用户看的“默认右下”文案已经改成更口语化的人类可读摘要，而不是 raw token

不过这条线又被用户继续纠偏了，当前最新真实方向应以这版为准：

- 四个自定义区域优先走“直接点进去输入”的内联编辑，而不是把用户短语拆成单独文字模块
- 点击上方 EXIF / 智能模块按钮时，要按当前光标位置插入到对应区域
- 正常编辑时不再把 raw `{{token}}` 暴露出来，而是显示成更人类可读的内联标签文本
- 如果后续继续打磨这一块，优先验证“光标位置是否准确保留”和“模块插入后前后继续输入是否顺手”，而不是先回到块状拖拽编辑

这条线随后又补了一步，当前最新交互目标还包括：

- 虽然底层已经回到光标式内联编辑，但模块在编辑区里的视觉表现要尽量接近“独立小方块”
- 光标贴着模块时，按删除应优先整块删除，而不是拆字符
- 编辑器显示映射不能只覆盖基础 token，像 `camera_summary` 这类模板里常用的组合 token 也必须转成可读标签，避免出现“半中文标签、半 raw token”的混合显示

如果后续继续这条线，优先检查：

- 切换配置后左侧字段和右侧预览是否同步刷新
- 未保存槽位是否正确回退到默认模板骨架
- 当前活动配置是否始终和 batch queue 默认配置快照保持一致
- 光标停在模块前后时，连续插入/删除是否仍然保持预期

## 建议优先阅读的文件

### 产品与文档

- `README.md`
- `AI_CONTEXT.md`
- `AGENTS.md`
- `Docs/CURRENT_STATUS.md`
- `Docs/PRODUCT_SPEC.md`
- `Docs/MVP.md`
- `Docs/DEVELOPMENT_PLAN.md`
- `Docs/ANCHOR_SYSTEM_DESIGN.md`
- `Docs/BATCH_TASK_SYSTEM_DESIGN.md`

### 核心代码

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift`
- `Source/PhotoMemo/PhotoMemo/Engines/AnchorEngine.swift`
- `Source/PhotoMemo/PhotoMemo/Models/CardVariableProvider.swift`
- `Source/PhotoMemo/PhotoMemo/Renderers/RecordCardRenderer.swift`
- `Source/PhotoMemo/PhotoMemo/Services/PhotoImportService.swift`
- `Source/PhotoMemo/PhotoMemo/Services/RecordCardExportService.swift`
- `Source/PhotoMemo/PhotoMemo/Services/PhotoLibraryExportService.swift`
- `Source/PhotoMemo/PhotoMemo/Services/BatchQueueStore.swift`
- `Source/PhotoMemo/PhotoMemo/Services/BatchProcessingCoordinator.swift`
- `Source/PhotoMemo/PhotoMemo/Services/PermissionCenter.swift`

## 新会话接手时建议先做什么

1. 确认当前工作目录是否直接是 `/Users/rui/Desktop/PhotoMemo`
2. 读取 `README.md`、`AI_CONTEXT.md`、`HANDOFF.md`、`AGENTS.md`
3. 读取 `Docs/CURRENT_STATUS.md`
4. 看 `git status`
5. 检查 `MainView.swift` 与最新的 `MainView+*.swift`
6. 如需编译，用既有命令：

```bash
xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build
```

## 当前工作流共识

本地已经安装适合后续开发的 skills：

- `spec-driven-development`
- `planning-and-task-breakdown`
- `incremental-implementation`
- `test-driven-development`
- `code-review-and-quality`
- `frontend-ui-engineering`

后续处理非小改动时，优先按这个顺序推进：

1. `/spec`
2. `/plan`
3. `/build`
4. `/test`
5. `/review`

## 当前最值得继续推进的方向

- 继续拆分 `MainView.swift`
- 优先收口访问级别与 ownership 表达
- 继续整理 badge / output / workspace 这类局部 binding
- 保证预览与最终导出一致
- 继续增强元数据保留策略
- 为未来 iOS 迁移减少 macOS 特有耦合

## 当前验证状态

最近几轮 `MainView` 拆分后，本地构建已通过。

已知情况：

- 编译通过
- 只存在 Xcode destination 选择 warning
- 当前 Xcode project 仍没有单独 test target，这一轮验证以 build 和结构 review 为主
- 仍建议补做手动 UI 回归检查：
  - 模板切换
  - 模板改名
  - 时间锚点选择
  - 照片导入
  - Live Context 与实时预览是否仍按当前模板刷新
  - `immersWhite` 默认 logo 回退
  - 预览与导出一致性
  - workspace slot 切换时的 caret 保留
  - 连续插入 EXIF / 智能模块时的光标路由

## Git 与同步说明

- 远程仓库：`origin git@github.com:serydoo/PhotoMemo.git`
- 当前主分支：`main`
- 已经建立了项目内 `.codex/skills`
- 发布/同步时，优先先检查构建、再看 `git status`、`git diff --stat`、最后 commit/push

## 给下一位 Codex 的一句话

不要把 PhotoMemo 当成“加边框工具”继续堆功能。  
它现在的真正方向是：**以模板、EXIF、时间锚点和后台处理为核心的本地照片记忆生成系统。**

## 2026-06-19 本轮补充

这一轮又继续往“稳住四个自定义区域的编辑模型”推进了一步，新增了：

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+ComposerDisplayEngine.swift`

这次的关键调整不是视觉，而是编辑语义：

- 不再把所有长得像 `〔...〕` 的可见文字都当成真实模块
- 只把真正插入或从模板同步出来的模块，记录为带范围信息的 module spans
- macOS 与 UIKit 两条编辑路径都改为共享这一套范围语义
- 删除或替换跨过模块时，不再只误伤模块本体而丢掉外围普通文本

这意味着后续如果继续打磨这块，优先方向不该再回到 raw token 暴露，而是继续围绕：

- caret 是否稳定
- 选择替换是否自然
- 模块插入与整块删除是否顺手

本轮额外记录文件：

- `Docs/OPTIMIZATION_LOG_2026-06-19.md`
- `Docs/COMPETITOR_NOTES_2026-06-19.md`
- `Docs/IOS_READINESS_2026-06-19.md`
- `Docs/MANUAL_REGRESSION_CHECKLIST_2026-06-19.md`

其中第一份记录了：

- 这次真正改了什么
- 为什么值得
- `MainView.swift` 下一轮最值得继续拆的三个区块

如果下一位 Codex 继续往下做，当前最值得继续清理的 3 块已经更新为：

- 访问级别收口
- badge / output / workspace 相关 binding
- 手动回归光标 / 槽位切换 / 保存反馈这三条高风险交互

第二份记录了：

- 2026-06-19 基于官网信息整理的相邻竞品/参考产品
- 各自最值得借鉴的亮点
- 对 PhotoMemo 后续产品提升最有价值的方向判断

第三份记录了：

- 当前仓库距离 iOS 开发的真实准备度
- 已具备的跨平台基础
- 当前主要 blockers 和最短启动路径

第四份记录了：

- 当前重构阶段最值得优先手动回归的链路
- 光标 / 模块插入 / 时间点 / 配置槽位 / 相册保存的检查步骤
- 每一步的预期结果与高风险回归信号

## 2026-06-19 晚些时候补充

这一小轮继续做了主界面收口，没有改导入、渲染、导出行为，主要是把用户能看到的主流程表述统一到当前固定模板 1 + 配置槽位方向：

- 右侧帮助中心不再混用“批量说明”“切换模板”等旧说法，统一改成当前的补充信息输入、配置槽位切换与保存语义
- 模板摘要不再展示 raw token 风格描述，`模板 1` 默认右下改为人类可读的“今天 + 年岁”
- 预览区、后台通知、补充信息预览等文案统一从“当前模板”进一步收口到更贴合现状的“当前配置”语义

本轮验证：

- 已再次通过：
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- 仍只有既有的 Xcode destination warning

这轮没有做新的手动 UI 操作验证，后续最值得继续盯的仍是：

- 参数摘要模块在模块左侧普通文本被删除后的显示/删除边界
- 配置槽位切换时四个自定义区域的光标与编辑态刷新
- 补充信息留空回退到右下内容时，预览与最终写回说明是否始终一致

## 2026-06-19 iOS 起步骨架

这一轮开始正式为 iOS 版本铺文件库与入口基础，但还没有在 `xcodeproj` 里新增 iOS target。

已经落地的结构：

- 新增共享 app runtime：
  - `Source/PhotoMemo/PhotoMemo/App/PhotoMemoAppRuntime.swift`
- 新增共享 root scene：
  - `Source/PhotoMemo/PhotoMemo/App/PhotoMemoRootSceneView.swift`
- 新增 iOS 专属目录骨架：
  - `Source/PhotoMemo/PhotoMemo/iOS/App/PhotoMemoiOSApp.swift`
  - `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSHomeView.swift`

这一步的意义：

- macOS `PhotoMemoApp` 不再自己背外部图片接单与队列注入逻辑，入口层开始可复用
- 后续新增 iOS target 时，可以直接复用 `PhotoMemoAppRuntime` 和 `PhotoMemoRootSceneView`
- 现在的 iOS 文件库已经有了明确落点，后面继续加 iOS 专属 import/export/navigation 代码时不会再混回 macOS 入口

这轮特别注意：

- 还没有修改真实导入、渲染、导出链路
- 还没有真正把 iOS target 写进 `PhotoMemo.xcodeproj`
- `PhotoMemoiOSApp.swift` 与 `PhotoMemoiOSHomeView.swift` 目前是受 `#if os(iOS)` 保护的起步壳层，先为后续 target 接入做准备

本轮验证：

- 已通过：
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- 中途遇到一次新的 `MainActor` 初始化编译错误，已在 `PhotoMemoAppRuntime` 中改为 runtime 内部构造默认对象后解决

下一轮如果继续 iOS 线，最合理的顺序是：

- 给 `PhotoMemo.xcodeproj` 真正新增 iOS app target
- 把共享源纳入 iOS target，先追求可编译
- 再拆 app entry / intake / export 的 iOS 专属实现

## 2026-06-19 iOS target 已接入

这一轮已经把真正的 iOS app target 接进工程：

- 新 target / scheme：
  - `PhotoMemoiOS`
- 工程文件：
  - `Source/PhotoMemo/PhotoMemo.xcodeproj/project.pbxproj`

同时顺手补了两类基础兼容工作：

- 给现有 `AppIcon.appiconset` 补齐了 iPhone / iPad / marketing icon 描述与实际 PNG 文件，继续与 macOS target 共用同一套 asset catalog
- 帮助中心 `MainOperationGuideSheetView` 改成双平台导航实现：
  - macOS 继续 `NavigationSplitView`
  - iOS 改为 `NavigationStack + 分组列表 + NavigationLink`

这意味着当前仓库已经从“只有 iOS 文件库骨架”推进到“工程里真实存在一个可编译的 iOS target”。

本轮验证：

- 通过 macOS：
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- 通过 iOS Simulator 泛目标：
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PhotoMemoIOSDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`

这轮真实踩到并解决的 iOS 阻塞：

- iOS target 最开始缺少可用 AppIcon
- 帮助中心的 `List(selection:)` / `NavigationSplitView` 用法不适合 iOS

下一轮如果继续 iOS 线，最值得优先推进的是：

- 让 `MainView` 在 iPad 竖屏/横屏下都更像正式可用界面，而不是仅仅“能编译”
- 开始拆 iOS 专属导出路径，例如 Photos-only / share sheet
- 开始整理 iOS 下不该继续暴露的 macOS 语义和交互细节

## 2026-06-19 iPhone 首轮适配

用户已经明确表示暂时不单独考虑 iPad，所以这一轮开始把 iOS 重点改成 iPhone 紧凑宽度体验。

这轮的核心不是“自动适配所有机型”，而是先把主界面改成更像手机产品的结构：

- iOS 首页不再是“预览 + 全量编辑”的超长单页
- 改成顶层 `预览 / 编辑` 分段切换
- 预览页优先展示：
  - 当前配置面板
  - 实时预览
- 编辑页优先展示：
  - 当前配置面板
  - 权限、照片、模板、时间点、四区编辑、补充信息、Logo、输出

相关文件：

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+LayoutSections.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+StateModels.swift`

这一步的意义：

- iPhone 17 Pro Max / 15 Pro 这类设备现在虽然还是同一套 SwiftUI 代码，但已经不再单纯依赖系统“自动缩放”
- 现在主信息架构开始主动面向紧凑宽度编排，用户进入时先看预览，再切到编辑，心智更清楚

本轮验证：

- 通过 iOS：
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PhotoMemoIOSDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- 通过 macOS：
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`

下一轮如果继续 iPhone 线，最值得优先推进的是：

- 输出区在 iPhone 上改成更明确的单主动作流程
- 导入/导出做更像 iOS 的路径，而不是继续沿用桌面心智
- 继续收紧手机端顶部信息密度和部分 section 的默认展开顺序

## 2026-06-19 iPhone 主链路第二轮

这一轮继续只做 iPhone 紧凑宽度体验，不碰底层渲染和相册写回实现。

重点推进了两件事：

- iPhone 的“预览”页现在不再只有预览本体，已经前置了：
  - 当前配置面板
  - 照片导入区
  - 输出区主动作
- 输出区在紧凑布局下改成更明确的单主动作表达：
  - 按钮文案直接带当前相册去向
  - 补了一条更贴近手机流程的说明，强调“先看预览，再保存”

相关文件：

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+LayoutSections.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+OutputSection.swift`

这意味着当前 iPhone 页面里，用户已经可以更顺地走完整个主链路：

- 导入照片
- 看预览
- 直接保存到当前相册

而不用一上来先掉进超长编辑页里找入口。

本轮验证：

- 通过 iOS：
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PhotoMemoIOSDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- 通过 macOS：
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`

下一轮如果继续 iPhone 线，最值得优先推进的是：

- iOS 下导出后的分享路径或系统相册完成反馈，做得更像原生手机 app
- 继续把“编辑”页里次要内容往后放，减少第一次进入时的认知负担

## 2026-06-19 iPhone 反馈与降噪

这一轮继续沿着 iPhone 体验收口，但仍然没有改底层导出/保存实现。

主要补了两件事：

- iPhone 紧凑布局下，保存成功后不再只有系统 alert
  - 额外补了一张短时出现的轻量成功反馈卡片
  - 文案会直接告诉用户已经写入哪个相册，并提示可以继续下一张
- 编辑页继续降噪
  - 首次进入编辑页时，主视觉更集中在模板、时间点、四区编辑和输出

## 2026-06-19 主界面职责再收口

用户已再次明确：

- 主界面永远只负责设定参数、自定义信息和实时预览
- 后台处理进度不应继续占用主界面区域

因此这一轮又补了一次职责收口：

- macOS 主界面移除了 `记忆进度` 可见面板
- iPhone 编辑页也移除了 `记忆进度` 展示入口
- 帮助中心 overview 中不再把 `记忆进度` 当成主界面组成部分描述

这意味着当前仓库的真实共识已经变成：

- 主界面 = 校准中心
- 后台自动处理 / 通知 / 后续灵动岛 = 独立的后台能力
- 两者可以共用同一套配置，但不应在一个界面里混着表达

相关文件：

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+StateModels.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+Feedback.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+ModalAndLifecycle.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+OutputSection.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+LayoutSections.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+ExportActions.swift`

本轮验证：

- 通过 iOS：
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PhotoMemoIOSDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- 通过 macOS：
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`

下一轮如果继续 iPhone 线，最值得优先推进的是：

- 把保存完成后的下一步动作做得更像 iOS，例如分享或继续处理的轻动作
- 继续梳理编辑页里哪些 section 适合默认折叠/后置，进一步降低第一次使用压力

## 2026-06-19 后台自动处理感知层

用户已经进一步明确真实使用模式应当是：

- 在系统相册或其他位置选中图片
- 通过分享发送到 PhotoMemo
- 后台自动处理
- 按预设配置直接写入指定相册
- 用户不需要逐张盯着保存

这一轮先没有直接上分享扩展或灵动岛，而是先把现有后台队列的“进度感知层”补强，作为下一步的基础。

已落地：

- 后台批次不再只有“开始接收”和“最终完成”两次通知
- 新增了三个批次级阶段进度通知：
  - `imported`
  - `rendering`
  - `saving`
- 每个批次会记住自己上一次已发送的阶段，避免同一阶段重复刷通知

相关文件：

- `Source/PhotoMemo/PhotoMemo/Models/BatchProcessing.swift`
- `Source/PhotoMemo/PhotoMemo/Services/BatchNotificationService.swift`
- `Source/PhotoMemo/PhotoMemo/Services/BatchQueueStore.swift`

这一步的实际意义：

- iPhone / Mac 端现在更接近“设好相册后不用继续操心”
- 通知栏里能看到后台任务不是卡死，而是在读取、生成、写入中的哪一段
- 后续如果继续接灵动岛 / Live Activity，这一套 stage 摘要可以直接复用，不用重新发明一遍后台进度模型

本轮验证：

- 通过 iOS：
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PhotoMemoIOSDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- 通过 macOS：
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`

下一轮如果继续按用户这条“后台自动处理”路线推进，最值得优先做的是：

- 真正接入 iOS share extension，让系统分享可以把图片送进当前后台队列
- 再做 `Live Activity / 灵动岛` 方向的进度展示，而不是继续只依赖本地通知

## 2026-06-19 外部接单持久化基础

这一轮没有把进度放回主界面，而是继续沿着“分享进入后台自动处理”的真实方向补底层：

- 新增共享容器与 App Group 基础：
  - `Source/PhotoMemo/PhotoMemo/App/PhotoMemoSharedContainer.swift`
- 新增持久化外部收件箱：
  - `Source/PhotoMemo/PhotoMemo/App/ExternalPhotoIntakeStore.swift`
- `ExternalPhotoIntakeCenter` 现在不再只靠内存暂存请求：
  - 外部 URL 进入时会优先复制到共享收件箱目录
  - 请求描述会持久化到共享 `UserDefaults`
  - App 下次激活时仍可继续自动消费
- `SettingsService`、`BatchQueueStore`、`PermissionCenter` 已切到共享 `UserDefaults` 入口，给未来 iOS Share Extension 复用默认配置和基础状态留好接口
- `PhotoMemoAppRuntime` / `PhotoMemoRootSceneView` 现在会在激活与初次进入时主动刷新外部接单状态并消费持久化请求

这一步的意义：

- 后面即使分享扩展与主 App 不是同一进程，也已经有可复用的收件箱和配置来源
- 主界面依旧保持“参数设定 + 自定义信息 + 预览”职责，没有重新引入后台进度面板

下一轮如果继续这条线，最合理顺序是：

- 正式新增 iOS Share Extension target
- 让扩展端把共享图片/URL 写入当前收件箱
- 主 App 继续沿现有 runtime 自动入队，不改主界面信息架构

## 2026-06-19 外部收件箱清理补充

这一小轮继续只补后台接单基础，不动主界面信息架构。

新增收口：

- `ExternalPhotoIntakeStore` 现在除了持久化请求，还负责清理自己复制进共享收件箱的源文件
- `BatchQueueStore` 在两条安全终态路径上接入了回收：
  - 单张任务处理完成后
  - 整个 job 被用户取消时

这次特意没有在失败态就删文件，因为失败任务还需要保留源图用于后续重试。

当前共识：

- 只清理 `ExternalIntake` 目录内、由 PhotoMemo 自己复制进去的托管文件
- 不碰用户原始文件路径
- 不影响现有导入、渲染、导出、写回图库行为

## 2026-06-19 外部收件箱孤儿目录整理

这一小轮继续补后台接单地基，目标是覆盖“上次处理中途退出”之后的残留目录。

新增收口：

- `BatchQueueStore` 现在会暴露当前任务仍在引用的托管源图 URL 集合
- `PhotoMemoAppRuntime.refreshExternalIntakeState()` 在每次启动/激活刷新外部接单状态前，会先让 `ExternalPhotoIntakeStore` 扫描 `ExternalIntake` 目录
- 没有任何请求或任务继续引用的孤儿文件/目录，会被自动整理掉

当前共识：

- 正在排队、处理中、失败待重试的托管源图不会被误删
- 只清理共享收件箱里的孤儿内容，不扫描用户原始目录

## 2026-06-19 iOS Share Extension 最小骨架

这一轮开始把真正的 iOS 分享入口接进工程，但仍然坚持“小切片、先求可编译”的节奏。

已落地：

- 新增分享扩展接单服务：
  - `Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionIntakeService.swift`
- 新增极简分享扩展入口控制器：
  - `Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionViewController.swift`
- 新增扩展专用 `Info.plist` 与 entitlement：
  - `Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtension-Info.plist`
  - `Source/PhotoMemo/PhotoMemo/PhotoMemoShareExtension.entitlements`
- `ExternalPhotoIntakeStore` 现在支持：
  - 扩展端先把分享进来的图片复制到共享收件箱
  - 再直接写入持久化请求，而不依赖主 App 进程内状态
- `PhotoMemoiOSApp.swift` 已加编译条件，避免 share extension target 编译时与 app 的 `@main` 入口冲突
- `PhotoMemo.xcodeproj` 已新增：
  - `PhotoMemoShareExtension` target

当前结果：

- iOS 主 app 仍可编译
- 新的 `PhotoMemoShareExtension` target 已可编译
- 当前还有一个非阻塞告警：
  - 扩展 target 的 Copy Bundle Resources 里包含了它自己的 `Info.plist`
  - 不影响当前构建通过，后续可以继续做工程级清理

这一步的真实意义：

- PhotoMemo 已经不再只是“未来可能支持分享扩展”
- 现在仓库里已经有了一个真实、可编译、能把分享图片送进共享收件箱的最小扩展骨架

下一轮如果继续这条线，最值得优先做的是：

- 用真实 `NSExtensionContext` 手动回归分享一张/多张图片的行为
- 继续清理 extension target 当前仍不必要编进来的主 app UI/服务文件范围
- 再决定是否要做“分享成功后自动唤起主 App”这类体验层动作

## 2026-06-19 ExternalIntake 纯临时策略收紧

这一轮根据最新共识，把共享收件箱里的托管源图进一步明确为“纯临时文件”，不再走失败后长期保留路线。

已落地：

- `ExternalIntake` 托管副本在三类终态都会清理：
  - 成功完成
  - 用户取消
  - 处理失败
- 对于这类失败任务，`BatchTaskFailure` 现在会显式标记：
  - `canRetry = false`
- `BatchQueueStore.retryFailedTasks` 只会真正重排那些仍可重试的失败项
- 批量任务持久化前会对终态历史做数量裁剪，避免队列记录无限增长

当前共识：

- `ExternalIntake` 里的托管文件不是长期缓存，也不是恢复仓库
- 真正边界仍然不变：
  - 只能清 PhotoMemo 自己复制进 `ExternalIntake` 的文件
  - 不碰用户原始路径
  - 写回系统相册的成品不当缓存处理

## 2026-06-19 少量失败作为例外处理

这一轮继续沿后台自动处理路线，把“很多照片里只失败 1 张”的表达方式收得更符合真实使用体验。

已落地：

- 当一批任务大多数已成功完成时，不再把整批语义简单打成“失败”
- `BatchJob` 现在会区分：
  - 整批失败
  - 部分完成
  - 大部分完成，仅少量例外
- 通知文案、失败摘要文案都已同步收口：
  - 例如更接近“已完成 99 张，另有 1 张作为例外未处理”
- 对于已经按纯临时策略清掉托管源图的失败项，会明确标记不可重试，不再给出误导性的重试入口

这样处理的原因：

- 用户真正关心的是“成功的大多数已经进相册了没有”
- 少量失败项应该作为例外单独提示，而不是把整批结果整体抹黑

当前共识：

- 成功结果先算成功写回
- 少量失败单独列出
- 失败原因保留可查
- 只有仍具备真实重试条件的失败项，才继续提供重试动作

## 2026-06-19 Share Extension 工程告警收口

这一小轮还顺手把 share extension 的 `Info.plist` 资源告警收掉了：

- 扩展专用 `Info.plist` 已挪到同步组外层：
  - `Source/PhotoMemo/ShareExtension-Info.plist`
- `PhotoMemoShareExtension` target 改为引用这份 plist

当前结果：

- macOS app 可编译
- iOS app 可编译
- `PhotoMemoShareExtension` 可编译
- share extension 原来的 `Info.plist` Copy Bundle Resources 告警已消失

## 2026-06-19 Share Extension 首轮瘦身

这一轮没有改主界面，也没有改真实导入/渲染/导出链路，主要是把分享扩展对主 app 设置系统的依赖先拆薄一层。

已落地：

- 新增轻量共享快照读取器：
  - `Source/PhotoMemo/PhotoMemo/App/SharedBatchConfigurationSnapshotService.swift`
- `PhotoMemoShareExtensionIntakeService` 不再直接依赖完整的 `SettingsService`
- 扩展端现在只通过共享 `UserDefaults` 读取：
  - 模板
  - 徽标
  - 时间点
  - 说明写入开关
  - 相册标识
  然后组装 `BatchConfigurationSnapshot`

这一步的意义：

- share extension 不再为了拿默认配置而拖进整套设置观察/保存语义
- 后续继续瘦 target 时，有了更清晰的共享边界

当前结果：

- macOS app 可编译
- iOS app 可编译
- `PhotoMemoShareExtension` 可编译

下一轮如果继续这条线，最值得优先做的是：

- 继续把 extension target 当前仍然会编进来的主 app 视图/权限/照片库写回相关文件尽量剥离
- 为真实系统分享手动回归做准备

## 2026-06-19 Share Intake 稳定性补强（二次）

这一轮继续沿着 iOS 分享入口做，但重点不是扩功能，而是先把“看不见的坏情况”压下去。

本轮已落地：

- 新增共享相册选择语义：
  - `Source/PhotoMemo/PhotoMemo/App/PhotoMemoAlbumSelection.swift`
- `SharedBatchConfigurationSnapshotService` 不再为了“自动相册”标识去依赖 `PhotoAlbumOption`
- `SettingsService` 也已切到同一套共享相册标识规范化逻辑
- `ExternalPhotoIntakeStore.persistManagedRequest(...)` 在请求列表写入失败时，会立即清理已经复制进去的托管临时文件
- `ExternalPhotoIntakeStore.persistRequest(...)` / `ExternalPhotoIntakeCenter.submit(...)` 都会先做重复 URL 去重
- `PhotoMemoAppRuntime.flushExternalRequests()` 现在会先过滤掉已经不存在的源文件：
  - 全部失效：直接跳过，并清理 PhotoMemo 自己管理的临时副本
  - 部分失效：只把仍然存在的那部分照片入队
- `PhotoMemoShareExtensionIntakeService` 现在返回一个结构化导入结果：
  - `importedCount`
  - `skippedCount`
  - `failedCount`
- share extension 侧的真实行为现在变成：
  - 单个 provider 失败，不再把整次分享直接判死
  - 只要至少有一张成功写进共享收件箱，就算接单成功
  - UI 文案会区分“全部成功”和“部分成功、附带跳过/失败计数”
- 分享 fallback 目前只保留两类：
  - `file URL`
  - `raw Data`
- 已明确**不**使用：
  - `UIImage -> JPEG` 重编码 fallback

这一条很重要，不要为了“更多来源都能进”把它再加回去，因为那样会有两个真实风险：

- 可能丢 EXIF
- 可能在进入 PhotoMemo 之前就已经改变图片二进制内容

当前这一轮的真实意义：

- Main App and Share Extension just completed another Alpha product-refinement slice focused on reduction rather than expansion.
- The biggest visible change is that the app is now closer to a `configuration center`:
  - `MainView` now receives `PersonalProfileStore`
  - a new `我的记录` section is live
  - long-term identity / baby / birthday information can now be edited directly from the main app
- iPhone main UI is no longer centered around the old `preview vs editor` split:
  - it now behaves more like one vertical settings-style flow
  - the preview remains, but it is demoted behind the configuration stack instead of acting like a separate mode
- default style presentation was softened:
  - visible slot titles now read `模块 1 / 模块 2 / 模块 3`
  - the style area is now collapsible and more settings-like
  - “current configuration summary” style repetition has been reduced
- first run was updated toward the newer product model:
  - welcome
  - relationship
  - nickname
  - birthday
  - default anchor explanation
  - destination
  - completion
- Share confirmation also moved one step closer to an Apple-like single-page experience:
  - first-photo preview is now attempted
  - multi-photo shares only preview the first item
  - the page explains that the remaining photos will use the same style
  - button copy now says `开始生成`
  - workflow summary wording was simplified from configuration terminology toward style / album terminology

- Compatibility work landed alongside the UI changes:
  - `PersonalProfileStore.updateProfile(_:)` now exists
  - main-app profile edits still backfill the old settings layer:
    - birthday anchor
    - active slot
    - album selection

- Verification completed for this slice:
  - passed:
    - `PhotoMemo`
    - `PhotoMemoiOS`
    - `PhotoMemoShareExtension`
    - `PhotoMemoTests`

- Important remaining product debt after this slice:
  1. the main app is still not yet fully reduced to the final `Profile / Default Style / Output Settings / Settings / About` structure
  2. anchor / personalized fields / supplemental content / badge are still visible on the main stage rather than pushed deeper into settings hierarchy
  3. Share is now easier to understand, but it still is not yet the final invisible `share -> generate -> save` experience
  4. `MainView+PersonalProfile.swift` is excluded from share behavior with `#if !PHOTOMEMO_SHARE_EXTENSION`; later target-boundary cleanup may still be worthwhile

- Recommended next slice:
  1. continue shrinking the main app surface
  2. make the share confirmation page even more automatic
  3. run real-device UX review specifically against the latest “Apple Settings + Apple Photos share” standard

- 共享收件箱更接近“可靠的临时接单层”，而不是“偶尔会留下垃圾和坏单子的黑盒”
- 失败和部分成功的语义更贴近真实用户感受
- 元数据保留优先级继续压过“表面兼容更多输入”

本轮构建验证：

- 已通过：
  - `PhotoMemoShareExtension`
  - `PhotoMemoiOS`
  - `PhotoMemo`
- 告警情况：
  - macOS 仍只有原来的 destination-selection warning

下一轮最值得优先做的事：

1. 真实设备/模拟器手动回归系统分享一张、多张、部分失效的情况
2. 继续观察 share extension target 当前仍被同步组编进去的主 app 文件范围，评估是否还值得再拆共享边界
3. 如果系统分享来源出现只给 `UIImage` 不给原始文件/数据的 App，再单独设计“拒收并解释原因”策略，而不是偷偷重编码接入

## 2026-06-19 Share Extension 编译面收口

这一轮继续做 share extension，但不是继续加功能，而是把 target 真正压回“共享接单核心”。

本轮已落地：

- 在 `PhotoMemo.xcodeproj/project.pbxproj` 里，为 `PhotoMemoShareExtension` 新增了同步组例外配置：
  - `PBXFileSystemSynchronizedBuildFileExceptionSet`
- 这套例外配置已经把一大批与分享接单无关的文件排出扩展 target：
  - `Views/*`
  - `PhotoMemoApp.swift`
  - `PhotoMemoAppDelegate.swift`
  - `PhotoMemoRootSceneView.swift`
  - `PhotoMemoiOSApp.swift`
  - 大部分 renderers / export / permission / queue / engine 文件
- 这条路已经被证明可行，不需要靠更多 `#if` 去硬隔离主 app UI

这一轮还顺手抽出了一份真正该共享的模型：

- 新增：
  - `Source/PhotoMemo/PhotoMemo/App/ExternalPhotoIntakeRequest.swift`
- 原因：
  - 之前 `ExternalPhotoIntakeRequest` 还定义在 `ExternalPhotoIntakeCenter.swift`
  - 一旦扩展 target 把 `ExternalPhotoIntakeCenter.swift` 排掉，`ExternalPhotoIntakeStore` 就失去请求模型定义
- 现在共享边界更干净了：
  - `ExternalPhotoIntakeStore` 依赖共享请求模型
  - `ExternalPhotoIntakeCenter` 只负责主 app 侧的提交与 drain 协调

当前最直观结果：

- `PhotoMemoShareExtension.SwiftFileList` 目前约 `19` 行
- 也就是 share extension 现在主要只编：
  - 共享收件箱持久化
  - 共享默认配置快照读取
  - share extension 自己的 intake / view controller
  - 少量必要模型

这一步的意义很实在：

- 真正把“主 app 校准中心”和“iOS 分享接单入口”拆成了两个更清楚的责任面
- 后续如果分享入口出 bug，不需要再怀疑 `MainView`、预览、模板视图是否拖进 target 造成噪音
- 后续继续做 iPhone 分享流、后台接单、失败例外处理时，工程复杂度会低很多

本轮还补了一个小体验修正：

- share extension 的成功提示现在只会展示非零的 `跳过 / 失败` 计数
- 不会再出现“失败 0 张”这种不自然提示

本轮构建验证：

- 已通过：
  - `PhotoMemoShareExtension`
  - `PhotoMemoiOS`
  - `PhotoMemo`

下一轮最值得继续的方向：

1. 真机/模拟器手动验证分享 1 张、多张、部分失效、重复来源
2. 视情况继续把扩展 target 资源面也收一轮，例如是否还需要把共享 asset/catalog 继续缩小
3. 如果真实分享来源暴露出新的 provider 形态，再决定是否补更明确的拒收提示或来源兼容策略

## 2026-07-02 V1 draft runtime extraction handoff

This round stayed inside the V1 view-freeze / decomposition track and did not change renderer, export, share extension, or photo-library write behavior.

### What changed

- added `Source/PhotoMemo/PhotoMemo/iOS/Views/V1DraftRuntimeCoordinator.swift`
- added `Tests/PhotoMemoTests/ArchitectureTests/V1DraftRuntimeCoordinatorTests.swift`
- updated `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift`

The new runtime coordinator now owns:

- draft fallback resolution
- draft mutation application
- text/module insertion side effects
- mutation -> preview refresh reconciliation
- bootstrap draft restoration -> preview refresh chaining

`PhotoMemoiOSV1View` still owns screen state, but no longer directly applies:

- `V1DraftMutationCoordinator.State`
- `V1DraftMutationCoordinator.Update`
- `V1DraftOrchestrationCoordinator.applyMutationUpdate(...)`
- local `refreshDynamicPreview` draft-map assembly
- local bootstrap-drafts assignment + refresh coupling

### Line-count movement

- `PhotoMemoiOSV1View.swift` was about `2130` lines before this slice
- after this extraction it is about `2020` lines

### Verification

- passed:
  - `git diff --check`
  - iOS simulator generic build:
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOSV1 -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PhotoMemoV1IOSRuntime CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO build`
- attempted but blocked by current environment:
  - targeted macOS `PhotoMemoTests`
  - targeted macOS `build-for-testing`

The macOS test/build blockage is not pointing at this slice's new coordinator logic. The failure is currently the sandboxed Xcode macro/plugin path:

- `swift-plugin-server` malformed response for SwiftUI macros / previews
- sandboxed distributed test-progress notification posting
- CoreSimulator service/logging noise in the same environment

### Best next seams

1. Collapse the root runtime wiring block in `PhotoMemoiOSV1View` into a single support/runtime bundle so the view stops constructing multiple coordinators inline.
2. Extract quick-action photo intake follow-up into its own runtime coordinator.
3. Extract preview-effect policy for subject/birthday/preset changes so root view only forwards state changes.
4. Wrap diagnostics/settings refresh logic behind one screen runtime.

### Manual follow-up still needed

- device check: smart-module insertion while keyboard/caret is active
- device check: subject switch -> birthday sync -> preview sync
- device check: preset switch while draft is dirty

## 2026-07-06 Configuration preset lifecycle closure

This slice stayed inside the existing Configuration Center architecture and only closed the missing preset lifecycle capability needed before broader V1 UI convergence.

What landed:

- extended `MemoryPreset` so a preset can now carry configuration-session context:
  - `savedAt`
  - `selectedSubjectID`
  - `selectedTimeAnchorID`
  - `outputOption`
  - `storageOption`
  - `usesCustomMemoryWriteText`
  - `customMemoryWriteText`
- added `ConfigurationSession.saveCurrentMemoryPreset()`
- added `ConfigurationSession.createMemoryPresetFromCurrent()`
- updated `ConfigurationSession.selectMemoryPreset(_:)` so preset switching restores:
  - selected subject
  - active time anchor
  - output/storage selection
  - custom memory-write state

Behavioral intent of this slice:

- “保存为当前配置” now has a real snapshot target instead of only renaming/updating the visual preset shell
- “新建配置” can duplicate the current working context into an unsaved preset copy
- switching presets now restores the saved context needed by the future homepage/configuration-summary UI

Verification:

- passed targeted lifecycle tests:
  - `xcodebuild test -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoTests -destination 'platform=macOS' -only-testing:PhotoMemoTests/ConfigurationSessionConfigurationLifecycleTests -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO`
- passed required repository build:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`

Not yet done in this slice:

- no homepage UI convergence yet
- no configuration-center mobile summary rearrangement yet
- no output/tasks/settings surface redesign yet
- no advanced avatar crop interaction yet

## 2026-07-06 Configuration preset actions wired into the UI

This follow-up stayed within the same preset-lifecycle slice and connected the newly-added preset persistence behavior to the visible Configuration Center controls.

What changed:

- `ConfigurationCenterTopPreviewSection` now exposes:
  - `保存为当前配置`
  - `新建配置`
  - current preset save-status text
- `ConfigurationCenteriOSView` now wires those actions to:
  - `session.saveCurrentMemoryPreset()`
  - `session.createMemoryPresetFromCurrent()`
- macOS `InteractiveMemoryCardConfigurationContext` was aligned with the same actions and status copy
- `ConfigurationCenterSessionBindingPresenter` now provides preset save-status copy
- `ConfigurationSession` now marks the selected preset pending again when snapshot-backed fields change, including:
  - selected subject
  - selected output/storage option
  - custom memory-write toggle/text

Why this matters:

- the Configuration Center buttons now perform real preset persistence instead of only showing apply-style copy
- a saved preset now correctly falls back to pending state after further edits, so the UI can honestly show whether the current configuration still needs saving
- later homepage/config-summary work can reuse the same `savedAt` + status copy path

Verification:

- passed targeted tests:
  - `xcodebuild test -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoTests -destination 'platform=macOS' -only-testing:PhotoMemoTests/ConfigurationCenterSessionBindingPresenterTests -only-testing:PhotoMemoTests/ConfigurationSessionConfigurationLifecycleTests -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO`
- passed required build:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`

Still not done in this follow-up:

- preset dropdown does not yet expose a richer “saved time / active configuration” summary row
- homepage has not yet been reworked into the new compact four-block structure
- output/tasks/settings surfaces still need the larger visual convergence pass

## 2026-07-06 Configuration center summary row refinement

This increment continued the configuration-center main-page summary slice without changing the frozen IA-002 architecture.

What changed:

- added `ConfigurationCenterSummarySection` as the compact mobile-style summary surface at the top of the iOS Configuration Center detail area
- summary row order now reflects the agreed structure:
  - 头像与标识
  - 时间锚点
  - 位置显示
  - 记忆显示
  - 边框样式
  - 四个区域快捷跳转
- `ConfigurationSession` time-anchor switching is now surfaced through the summary dropdown via:
  - `availableTimeAnchors`
  - `selectedTimeAnchorID`
  - `selectTimeAnchor(id:)`
- added `ConfigurationCenterLocationDisplaySupport` so the summary row:
  - shows `位置模块未插入` when slot C has no location module
  - disables the location-display dropdown until a location module exists
  - applies location-display changes back to the requested region instead of accidentally following the currently selected region
- added regression coverage for the location-display summary behavior

Why this matters:

- the configuration center now has a compact “current effective configuration” surface that matches the product direction you described, while still routing deeper edits into existing object/card/module panels
- the time-anchor row now acts as a lightweight switcher instead of forcing users back into full object editing
- the location-display dropdown no longer gives a false “already configured” impression when the location module is absent
- slot C display-mode changes are now safe even if the user is currently editing a different region

Verification:

- passed targeted tests:
  - `xcodebuild test -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoTests -destination 'platform=macOS' -only-testing:PhotoMemoTests/ConfigurationCenterLocationDisplaySupportTests -only-testing:PhotoMemoTests/ConfigurationSessionConfigurationLifecycleTests -only-testing:PhotoMemoTests/ConfigurationCenterSessionBindingPresenterTests -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO`
- passed required build:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`

Likely next step:

- continue the same staged convergence by thinning the subject editor surface:
  - remove/soften old overview emphasis
  - keep detailed anchor editing inside the object editor
  - move more “current effective configuration” responsibility into the summary surface

## 2026-07-06 Subject editor thinning and legacy overview cleanup

This increment continued the agreed V1 convergence order by thinning the subject-configuration flow and reducing duplicated “current active anchor” surfaces outside the Configuration Center summary.

What changed:

- `MemorySubjectEditorView` now reads more clearly as:
  - 基本资料
  - 时间锚点详细编辑
- the subject editor now:
  - promotes identity guidance to the top of the page
  - adds an explicit `关系` field back into the editable basic profile
  - rewrites the anchor picker copy from “当前生效时间锚点” to “选择要编辑的时间锚点”
  - explains that current effective-anchor switching has been moved into the Configuration Center summary surface
- the subject editor still keeps detailed anchor editing in place:
  - anchor dropdown
  - custom anchor title
  - date picker
  - anchor type
  - expression-style picker
- the heavy formula-preview block was removed from the object editor to reduce visual weight before later expression controls are fully re-homed
- the legacy V1 subject overview sheet was simplified:
  - removed the standalone `概览` card
  - removed the redundant “当前生效时间锚点” quick-switch card
  - footer now only routes into detailed object configuration, with copy that points active-anchor switching back to the Configuration Center

Why this matters:

- the object editor is now more aligned with the intended split:
  - Configuration Center summary owns “current effective state”
  - object editor owns detailed identity and anchor maintenance
- users no longer see the same active-anchor concept emphasized in multiple places with slightly different responsibilities
- the subject flow is lighter without deleting the detailed anchor-editing capability we still need during this stage

Verification:

- passed targeted tests:
  - `xcodebuild test -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoTests -destination 'platform=macOS' -only-testing:PhotoMemoTests/ConfigurationCenterLocationDisplaySupportTests -only-testing:PhotoMemoTests/ConfigurationSessionConfigurationLifecycleTests -only-testing:PhotoMemoTests/ConfigurationCenterSessionBindingPresenterTests -only-testing:PhotoMemoTests/V1IOSSubjectOverviewPresenterTests -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO`
- passed required build:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`

Likely next step:

- continue the staged UI convergence on the output/settings side:
  - output surface restructuring
  - settings entry consolidation
  - task/history surface refinement

## 2026-07-06 Output panel convergence

This increment continued the agreed V1 convergence order by tightening the Configuration Center output surface without changing export, metadata, or photo-library behavior.

What changed:

- added `ConfigurationCenterOutputPanelPresenter` so the output surface can be driven by explicit presentation copy instead of ad-hoc view strings
- the iOS Configuration Center output panel now groups output information into 4 clearer blocks:
  - 输出结果
  - 元数据保留
  - 图片存放地点
  - 相册说明写入
- the output panel now explicitly states:
  - default output remains `处理过的图片`
  - default behavior is to retain as much original metadata as possible
  - storage location still follows the existing local storage/album options
- the output panel now also shows the current smart-module write summary and provides a direct button back into the `智能模块` panel for deeper adjustment
- the detail-panel subtitle for `输出` was updated to better reflect the new scope:
  - new image result
  - metadata retention
  - album-description writing

Why this matters:

- the right-side output surface is now much closer to the desired “final output checklist” feeling, instead of reading like a low-level settings form
- users can understand output consequences in one place without needing to mentally stitch together output and smart-module write behavior
- this keeps the architecture frozen while still moving the UI toward the more compact V1 experience you described

Verification:

- passed targeted tests:
  - `xcodebuild test -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoTests -destination 'platform=macOS' -only-testing:PhotoMemoTests/ConfigurationCenterOutputPanelPresenterTests -only-testing:PhotoMemoTests/ConfigurationCenterSessionBindingPresenterTests -only-testing:PhotoMemoTests/ConfigurationSessionConfigurationLifecycleTests -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO`
- passed required build:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`

Likely next step:

- continue with settings-entry consolidation:
  - move settings access fully behind the top-right entry
  - rebuild the settings/task-history surface into the more visual current-task vs history layout

## 2026-07-06 Settings entry consolidation

This increment completed the next agreed UI slice by moving the active settings/task-history surface behind the Configuration Center top-right entry and reshaping the page into a clearer current-task vs history presentation.

What changed:

- added `V1SettingsPagePresenter` plus focused tests so the settings page is now driven by an explicit presentation model instead of directly rendering queue diagnostics primitives
- the settings page surface was rebuilt into 3 compact blocks:
  - `当前任务`
  - `历史任务`
  - `辅助设置`
- the new `当前任务` card now summarizes:
  - current status
  - current task headline/subtitle
  - photo count when available
  - completed progress summary
  - latest update time
  - refresh / clear-history actions
- the new `历史任务` list now renders as row summaries with:
  - thumbnail-like icon tiles
  - time
  - compact status pill
  - available photo-count extraction when diagnostics contain `tasks=` or `unique=`
- `ConfigurationCenterTopPreviewSection` now exposes a top-right settings entry button
- `ConfigurationCenteriOSView` now owns the settings sheet presentation and refresh flow:
  - it reuses the existing diagnostics repository + queue status services
  - it keeps processing logic unchanged
  - it can still reopen the welcome surface from inside settings
- `PhotoMemoRootSceneView` now passes the real runtime into `ConfigurationCenteriOSView`, and the temporary entry path was updated to do the same

Why this matters:

- the active iOS entry path now matches the intended flow better:
  - Configuration Center stays focused on configuration
  - settings/task status moves behind a dedicated top-right utility entry
- users get a much more legible split between “what is happening right now” and “what happened recently” without expanding the underlying feature surface
- this stays within the IA-002 frozen architecture while making the settings surface feel closer to the visual direction you requested

Verification:

- passed targeted tests:
  - `xcodebuild test -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoTests -destination 'platform=macOS' -only-testing:PhotoMemoTests/V1SettingsPagePresenterTests -only-testing:PhotoMemoTests/ConfigurationCenterOutputPanelPresenterTests -only-testing:PhotoMemoTests/ConfigurationCenterSessionBindingPresenterTests -only-testing:PhotoMemoTests/ConfigurationSessionConfigurationLifecycleTests -only-testing:PhotoMemoTests/PhotoMemoiOSTemporaryEntryTests -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO`
- passed required build:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`

Likely next step:

- continue the staged V1 convergence on the remaining visual polish:
  - tighten the configuration-center top summary copy and proportions if needed
  - revisit the task/history surface with real thumbnail assets later if the product layer adds durable snapshot references
  - evaluate the later avatar crop/zoom interaction as a separate isolated slice

## 2026-07-06 Configuration Center top-header polish

This increment stayed inside the frozen Configuration Center architecture and only tightened the visual hierarchy of the top preview surface.

What changed:

- rebuilt the topmost area of `ConfigurationCenterTopPreviewSection` into a lighter product-definition header instead of starting immediately with a bordered control block
- the new header now carries product-facing copy aligned with the repository README:
  - local-first Memory Presentation Engine
  - Apple Photos workflow alignment
  - no original-photo mutation
- moved the settings entry into the actual top-right position of the header so it reads more like a utility entry instead of part of the preset form
- compressed the preset controls into a softer “当前生效配置” block with lighter quick-fact chips for:
  - 边框
  - 输出
  - 状态
- tightened surrounding paddings and slightly widened the preview presentation so the ratio-locked renderer preview reads a little larger without changing the renderer’s internal proportion rules
- updated the preview caption to explicitly explain that only the viewing scale is enlarged while the renderer ratio stays locked

Why this matters:

- the top of the Configuration Center now reads more like product context first and controls second, which is closer to the visual direction requested for the V1 main surface
- the settings entry is easier to discover and more clearly separated from configuration-save actions
- the preview is marginally easier to inspect while still respecting the “preview is a calibration surface, not a layout redesign” rule

Verification:

- passed required build:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`

Likely next step:

- if we continue polishing this surface, the next thin slice should be one of:
  - adjust the top header copy density and line lengths after device inspection
  - further rebalance preview height vs control density without changing renderer ownership
  - continue converging the home-level summary language around “当前生效配置” and “记忆对象”

## 2026-07-06 Top preview density reduction

This follow-up increment kept working on the same fixed top-preview surface, but only targeted density reduction so the ratio-locked renderer preview can read slightly larger.

What changed:

- reduced the outer horizontal padding of the top preview section again
- compressed the “当前生效配置” block:
  - tightened internal paddings
  - reduced rename/reset button footprint
  - kept the save/new actions intact
- replaced the previous 3 separate fact chips with one lighter inline summary row:
  - 边框
  - 输出
  - 状态
- widened the preview presentation a little more by increasing the preview’s horizontal bleed inside the calibration card
- slightly tightened preview-card spacing so more vertical attention stays on the renderer itself

Why this matters:

- the top area now spends less vertical weight on repeated status chrome
- the preview gets a bit more space without touching renderer internals or changing the locked ratio behavior
- this keeps the UI moving toward the “summary first, controls second” direction while staying within the frozen Configuration Center architecture

Verification:

- passed required build:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`

Likely next step:

- after visual inspection, choose only one next polish slice:
  - further enlarge preview framing if the header still feels heavy
  - soften or shorten the top product copy if it wraps too aggressively on smaller devices
  - continue converging homepage summary language with the same compact pattern

## 2026-07-06 Summary language convergence

This increment stayed purely on user-facing language so the Configuration Center reads more like one product surface instead of several adjacent technical panels.

What changed:

- tightened the top product copy in `ConfigurationCenterTopPreviewSection`:
  - less repository-definition tone
  - more direct “这里负责长期配置……” wording
- replaced the small preset-summary helper copy in the top block with a clearer user-facing description:
  - `当前用于生成与展示的配置摘要`
- updated `ConfigurationCenterSummarySection` copy to align with the same naming pattern:
  - `头像与标识` -> `记忆对象`
  - `时间锚点` -> `当前生效锚点`
  - `记忆显示` -> `智能写入`
- adjusted summary helper descriptions so they consistently refer to:
  - `记忆对象`
  - `当前生效锚点`
  - current generated smart-module writing behavior

Why this matters:

- the top block and summary block now use closer language for the same concepts
- the surface reads less like internal configuration terminology and more like an end-user product summary
- this should make later homepage convergence easier because the naming can now be reused instead of translated again

Verification:

- passed required build:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`

Likely next step:

- continue the same language pass into one remaining surface:
  - homepage current-configuration summary
  - memory-subject entry wording
  - settings-page section labels if they still feel slightly off-tone after device inspection

## 2026-07-06 Memory-subject wording alignment

This increment continued the same terminology pass, but only around the memory-subject side of the Configuration Center.

What changed:

- updated `MemorySubjectEditorView` section titles and helper copy so the object editor now reads more consistently with the summary surface:
  - `基本资料` -> `记忆对象资料`
  - `时间锚点` -> `锚点维护`
  - related helper copy now explicitly says `记忆对象`
  - anchor-maintenance picker wording now uses `要维护的时间锚点`
- updated `ConfigurationCenterDetailPresenter` labels:
  - subject detail subtitle now reads `对象资料与锚点维护`
  - subject region title now reads `记忆对象资料`
  - smart-module subtitle now uses `智能结果` wording for consistency
- updated `ConfigurationCenterSidebarView` and `ConfigurationCenteriOSView` labels:
  - sidebar header now reads `配置资料`
  - sidebar subtitle now references `记忆对象、卡片区域与智能写入`
  - subject groups now read `人物对象` / `事件对象`
  - smart-module and guide subtitles now align with `智能写入` and `对象、锚点与输出原则`
  - guide-card wording now says `当前生效锚点与智能结果`

Why this matters:

- the object editor, sidebar, and summary area now describe the same concepts with closer product language
- users should need less mental translation between “current effective state” and “where to maintain that state”
- this reduces terminology drift before we continue homepage and detail-surface polish

Verification:

- passed required build:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`

Likely next step:

- continue the same convergence in one adjacent surface only:
  - homepage current-configuration summary
  - settings-page section labels
  - object-editor visual density after device inspection

## 2026-07-06 Settings-page language convergence

This increment kept the settings/task-history surface functionally unchanged and only aligned its section naming with the current Configuration Center language.

What changed:

- updated `V1SettingsPageSurface` section titles:
  - `当前任务` -> `当前处理`
  - `历史任务` -> `最近记录`
  - `辅助设置` -> `使用与说明`
- adjusted helper copy so the settings page now reads less like a task center and more like a product-facing summary surface
- updated the empty-state wording to match the new `最近记录` label

Why this matters:

- the settings sheet now fits more naturally beside the Configuration Center instead of sounding like a separate diagnostics product
- language is now more consistent across:
  - top preview summary
  - memory-subject summary
  - settings/task-history sheet

Verification:

- passed required build:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`

Likely next step:

- continue the same wording pass into the homepage/current-configuration summary surface, or switch from wording to density polish after device inspection

## 2026-07-06 Subject avatar crop flow

This increment completed the iPhone-contacts-style avatar adjustment slice for the memory-subject editor without changing renderer, export, metadata, or share behavior.

What changed:

- added a dedicated crop math helper:
  - `SubjectAvatarCropSupport`
  - `SubjectAvatarCropConfiguration`
- added a new iOS crop sheet:
  - `SubjectAvatarCropSheet`
  - supports drag, zoom, and position adjustment before applying
- updated `MemorySubjectEditorView` avatar upload flow:
  - selected image now opens the crop sheet first on UIKit-capable paths
  - confirm then generates synchronized avatar / badge / preview resources
  - non-UIKit fallback still applies the default centered crop path directly
- extended `SubjectAvatarAssetOptimizationService` so optimized avatar derivatives now honor the selected crop configuration
- added focused crop tests in `SubjectAvatarCropSupportTests`
- explicitly marked the crop support helpers as nonisolated pure computation so the new flow compiles cleanly under the repository's default main-actor isolation mode

Why this matters:

- the memory-subject editor now matches the requested “像 iPhone 联系人头像一样” interaction more closely
- avatar resources used by object summary, logo/mark areas, and preview thumbnails now come from one deliberate crop decision instead of a fixed centered fill
- this keeps the work scoped to V1 iOS configuration polish while avoiding the earlier actor-isolation warning regression

Verification:

- passed targeted tests:
  - `xcodebuild test -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoTests -destination 'platform=macOS' -only-testing:PhotoMemoTests/SubjectAvatarCropSupportTests -only-testing:PhotoMemoTests/ConfigurationCenterMemoryDisplaySupportTests -only-testing:PhotoMemoTests/ConfigurationSessionConfigurationLifecycleTests -derivedDataPath /tmp/PhotoMemoAvatarCropTests2 CODE_SIGNING_ALLOWED=NO`
- passed required build:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData2 CODE_SIGNING_ALLOWED=NO -quiet build`
- passed iOS build:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -destination 'generic/platform=iOS Simulator' -configuration Debug -derivedDataPath /tmp/PhotoMemoIOSDerivedData2 CODE_SIGNING_ALLOWED=NO -quiet build`
- passed:
  - `git diff --check`

Known remaining verification gap:

- the crop gesture itself was not manually exercised on a real iPhone simulator/device in this session

## 2026-07-06 Task page visual density follow-up

This increment stayed inside the existing `任务` entry and only tightened the display density of the current-task and recent-history cards.

What changed:

- updated `V1TaskPageSurface` so the current-task card now reads more like a compact thumbnail summary:
  - the left tile now uses a stacked photo-card treatment instead of one flat block
  - the metadata chips now adapt between horizontal and vertical flow
  - progress now shows both a linear bar and a compact percentage
  - detail text now sits inside a lighter inset panel
- rebuilt each recent-history row into a more visual row summary:
  - added a stacked thumbnail-style leading tile
  - preserved row title, detail, time, item count, and status
  - added a compact status chip to the metadata row so time / count / state can be scanned together
- kept all queue, diagnostics, and history behavior unchanged:
  - this is presentation-only polish on top of the existing `V1SettingsPagePresenter` data

Why this matters:

- the `任务` entry is now closer to the desired “缩略图 + 行摘要” direction without moving any settings or workflow boundaries again
- current task and recent history are easier to distinguish at a glance on mobile-width layouts
- the page stays aligned with the already confirmed structure:
  - `首页`
  - `配置中心`
  - `输出`
  - `任务`

Verification:

- passed:
  - `git diff --check`
- passed required build:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoTaskUIMac CODE_SIGNING_ALLOWED=NO -quiet build`
- additional verification in progress during this handoff:
  - a full `PhotoMemoiOS` build was rerun with `/tmp/PhotoMemoTaskUIIOS2`
  - the build reached `PhotoMemoiOS` compilation and compiled `V1TaskPageSurface.swift` without surfacing task-page-specific compile errors before this handoff note was written

Known remaining verification gap:

- this task-page polish was not manually inspected on a real simulator/device in this session

## 2026-07-06 Home preset activation follow-up

This increment tightened the homepage configuration-switch behavior so it matches the confirmed V1 interaction more closely.

What changed:

- updated the homepage preset-switch path in `PhotoMemoiOSV1View`:
  - selecting a preset from the homepage dropdown now immediately restores that preset context
  - the selection then directly applies the current configuration instead of showing the previous confirmation dialog
- simplified `V1PresetSelectionCoordinator`:
  - preset switching now reports an immediate activation state
  - removed the old pending-confirmation payload from the coordinator contract
- updated `V1PresetSelectionCoordinatorTests` to match the new instant-activation behavior

Why this matters:

- this aligns the homepage with the confirmed rule that configuration switching belongs on the main screen under the current memory subject
- the homepage now behaves closer to “点选即生效” instead of “点选后再决定是否保存”
- the save/create entry points remain scoped to the configuration center bottom area, as requested

Verification:

- passed:
  - `git diff --check`
- passed required build:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- passed iOS build:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -destination 'generic/platform=iOS Simulator' -configuration Debug -derivedDataPath /tmp/PhotoMemoiOSDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`

Known remaining verification gap:

- `xcodebuild test` could not be used for this slice through the `PhotoMemo` scheme because that scheme is not configured for the test action in the current project setup
- the homepage preset switch was not manually tapped through on a simulator/device in this session

## 2026-07-06 Configuration center pinned-preview follow-up

This increment refined the real iOS configuration-center entry so the top preview reads more like a locked renderer surface while the detail area scrolls underneath it.

What changed:

- updated `ConfigurationCenteriOSView`:
  - added a small detail-scroll offset reader
  - derived a `detailPreviewPinProgress` value from the detail panel scroll position
  - passed that progress into the top preview section instead of treating the top area as a completely static slab
- updated `ConfigurationCenterTopPreviewSection`:
  - tightened the surrounding padding as the detail area scrolls so the renderer preview gains a bit more visible size without changing its internal aspect ratio
  - strengthened the bottom divider and added a subtle pinned shadow when the detail area is actively scrolled
  - refreshed the top descriptive copy so it explicitly tells the user the preview remains locked while configuring objects, anchors, and output behavior
- important architecture note:
  - the active iOS root scene currently enters `ConfigurationCenteriOSView`, so this slice was applied to the real configuration-center path rather than only the older V1 surface experiments

Why this matters:

- the top renderer area now feels more intentionally “locked” during long inspector scrolling
- the preview is slightly easier to read on mobile-width layouts because more horizontal space is given back to the card itself
- the renderer preview still preserves its original ratio and composition rules; this is display-surface polish only

Verification:

- passed:
  - `git diff --check`
- passed required build:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- passed iOS build:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -destination 'generic/platform=iOS Simulator' -configuration Debug -derivedDataPath /tmp/PhotoMemoiOSDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`

Known remaining verification gap:

- this pinned-preview refinement was not manually inspected on a simulator/device in this session, so the exact “lock感” still deserves a real touch-scroll pass

## 2026-07-06 Settings entry visual refresh

This increment stayed within the lightweight settings entry and only improved how the docs/welcome area is presented visually.

What changed:

- refreshed `V1SettingsPageSurface` into a more thumbnail-led entry page:
  - the overview card now uses a small stacked artwork block instead of one plain icon tile
  - added a compact three-item summary strip for welcome / workflow / principles
  - kept the existing copy that tasks and recent records now live in the bottom `任务` entry
- rebuilt the two action rows:
  - `重新查看欢迎说明`
  - `查看使用流程`
  - both now use small stacked thumbnail-like previews and accent-colored outlines instead of generic single-icon rows
- refined the principle area:
  - each principle now has its own compact tinted marker tile for a denser, more deliberate read

Why this matters:

- the settings page now feels more like a curated entry surface instead of a leftover plain list
- it stays aligned with the confirmed structure:
  - settings holds docs / welcome / usage
  - task processing and recent records remain in `任务`
- this keeps the work scoped to presentation only without reopening workflow or queue boundaries

Verification:

- passed:
  - `git diff --check`
- passed required build:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- passed iOS build:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -destination 'generic/platform=iOS Simulator' -configuration Debug -derivedDataPath /tmp/PhotoMemoiOSDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`

Known remaining verification gap:

- this settings-page polish was not manually inspected on a simulator/device in this session

## 2026-07-06 Configuration summary list-density refresh

This increment stayed inside the configuration-center summary area and only tightened the presentation into a more mobile-style grouped summary list.

What changed:

- rebuilt `ConfigurationCenterSummarySection` from a stack of separate mini-cards into:
  - one outer summary panel
  - one grouped inner list
  - lightweight row dividers
- added a small top label pill:
  - `当前生效配置`
- rewrote the intro area into a compact summary header:
  - keeps the same guidance but reads more like a focused mobile summary surface
- tightened each row:
  - slightly smaller icon tiles
  - smaller titles
  - denser spacing
  - kept all existing controls and behavior for:
    - memory subject
    - active time anchor
    - location display
    - memory display
    - border
    - A/B/C/D region jump

Why this matters:

- the summary area is now closer to the requested “移动端列表摘要面” direction instead of reading like several unrelated floating cards
- information order and functions are preserved while the page gains more visual structure and less fragmentation
- this remains presentation-only polish on top of the existing IA-002 configuration-center architecture

Verification:

- passed:
  - `git diff --check`
- passed required build:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- passed iOS build:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -destination 'generic/platform=iOS Simulator' -configuration Debug -derivedDataPath /tmp/PhotoMemoiOSDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`

Known remaining verification gap:

- this grouped summary refresh was not manually inspected on a simulator/device in this session, so the final row density and touch rhythm still deserve a real pass

## 2026-07-06 Memory-subject editor structure cleanup

This increment stayed within the memory-subject configuration flow and cleaned up a few remaining presentation redundancies.

What changed:

- updated `V1IOSSubjectConfigurationFlow`:
  - removed the extra outer `基本资料` wrapping card
  - replaced it with a lighter intro card so the real editor content starts earlier on screen
- updated `MemorySubjectEditorView`:
  - added a compact identity snapshot card near the top of the identity section
  - this gives the current object a clearer “who am I editing” summary before the field list
  - removed the old always-on time-anchor edit gating logic:
    - date
    - custom anchor title
    - anchor type
    no longer pretend to have a disabled/edit mode split when the page always opens in editable state

Why this matters:

- this is closer to the requested direction of pushing basic profile information upward and avoiding redundant overview-like wrappers
- the object editor now reads more directly as:
  - intro
  - identity / avatar / relationship
  - anchor maintenance
- simplifying the always-editable anchor controls reduces unnecessary UI state and makes the editor easier to reason about

Verification:

- passed:
  - `git diff --check`
- passed required build:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- passed iOS build:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -destination 'generic/platform=iOS Simulator' -configuration Debug -derivedDataPath /tmp/PhotoMemoiOSDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`

Known remaining verification gap:

- this memory-subject editor cleanup was not manually inspected on a simulator/device in this session

## 2026-07-06 Memory-subject editor visual follow-up

This increment stayed inside the same memory-subject editor and only improved readability around the avatar and active-anchor editing surfaces.

What changed:

- updated the avatar area in `MemorySubjectEditorView`:
  - added compact resource chips for:
    - 头像
    - 标识
    - 预览
  - these now reflect whether derived avatar assets are already available
  - added a small in-progress capsule so avatar optimization state is easier to scan
- updated the time-anchor maintenance area:
  - added a compact “current anchor snapshot” card above the maintenance controls
  - the snapshot now surfaces:
    - current anchor title
    - date
    - anchor type
    - total anchor count

Why this matters:

- the avatar editor now communicates more clearly that one upload/crop action feeds multiple downstream resources
- the anchor editor now makes it easier to see which anchor is currently being maintained before editing the picker/date/type controls
- this remains a presentation-only refinement on top of the already cleaned-up object-editor structure

Verification:

- passed:
  - `git diff --check`
- passed required build:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- passed iOS build:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -destination 'generic/platform=iOS Simulator' -configuration Debug -derivedDataPath /tmp/PhotoMemoiOSDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`

Known remaining verification gap:

- this avatar/anchor readability follow-up was not manually inspected on a simulator/device in this session

## 2026-07-06 Memory-subject identity-field grouping follow-up

This increment stayed in the same memory-subject editor and only tightened how the identity text fields are grouped visually.

What changed:

- grouped the identity text fields into one inner panel:
  - 显示名称
  - 昵称
  - 关系
  - 关系备注
- added lightweight dividers between rows so the object editor now reads closer to the grouped-summary rhythm already used elsewhere in the configuration center
- kept all existing field behavior, focus handling, and expression-subject ownership logic unchanged

Why this matters:

- the object editor now feels more unified with the configuration-center summary/list styling instead of reading like unrelated standalone controls
- the visual scan path is clearer:
  - object snapshot
  - avatar resources
  - grouped identity fields
  - anchor maintenance

Verification:

- passed:
  - `git diff --check`
- passed required build:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- passed iOS build:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -destination 'generic/platform=iOS Simulator' -configuration Debug -derivedDataPath /tmp/PhotoMemoiOSDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`

Known remaining verification gap:

- this identity-field grouping follow-up was not manually inspected on a simulator/device in this session

## 2026-07-07 Configuration-top current-preset semantics cleanup

This increment stayed in the real iOS configuration-center top area and only tightened the meaning and presentation of the current-preset panel.

What changed:

- updated `ConfigurationCenterTopPreviewSection`:
  - corrected the compact fact strip so it now reflects:
    - 对象
    - 锚点
    - 边框
  - removed the misleading use of `session.currentConfigurationLabel` as if it were an output value
  - changed the action chip wording from a generic bottom-area pointer to a clearer `切换即生效`
  - added a footer hint explaining that:
    - save current configuration
    - create configuration
    remain in the lower action area, while the top area only handles view / switch / rename
  - added a faint outline to the profile panel so it sits more cleanly beside the already-refined summary/list surfaces

Why this matters:

- the top preset panel now matches the actual product model more honestly
- users can scan the active object, active anchor, and border directly without reading a mislabeled “输出” row
- the division of responsibility between the top preset area and bottom save/create actions is now more explicit

Verification:

- passed:
  - `git diff --check`
- passed required build:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- passed iOS build:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -destination 'generic/platform=iOS Simulator' -configuration Debug -derivedDataPath /tmp/PhotoMemoiOSDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`

Known remaining verification gap:

- this semantics/visual cleanup was not manually inspected on a simulator/device in this session

## 2026-07-07 Real iPhone config-center compact-width cleanup

This increment stayed on the real iOS runtime entry and focused only on
compact-width Configuration Center presentation behavior.

What changed:

- updated `ConfigurationCenteriOSView` so iPhone-width layouts no longer force
  the persistent left sidebar beside the detail panel
- compact widths now render:
  - top summary / preview area
  - full-width detail content
  - a separate sheet-based `配置导航` entry for subject / region / output jumps
- hid the extra system navigation bar on the real iOS Configuration Center so
  the product statement area becomes the visual top surface again
- updated `ConfigurationCenterTopPreviewSection`:
  - added a compact-width navigation button beside the top-right settings button
  - kept settings as the dedicated top-right action
  - preserved the current status pill in the same area
- selection changes made from the compact navigator now dismiss the navigator
  sheet immediately so the flow returns to the detail page without an extra tap

Why this matters:

- the real app entry now matches the intended mobile rhythm much more closely:
  - summary first
  - detail second
  - navigation on demand
- the earlier “sidebar squeezed into phone width” problem is removed from the
  primary iPhone path
- the top area no longer competes with a duplicated system title/toolbar stack,
  so the product-definition copy and current-configuration surface read more
  cleanly

Verification:

- passed:
  - `git diff --check`
- passed required build:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- passed iOS build:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -destination 'generic/platform=iOS Simulator' -configuration Debug -derivedDataPath /tmp/PhotoMemoIOSDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- manually spot-checked by simulator screenshot:
  - real runtime now shows the compact-width top area without the duplicated
    navigation title and without the persistent split sidebar

Known remaining verification gap:

- the new compact `配置导航` sheet was not manually tapped through end-to-end in
  this session
- lower sections of the summary/detail page were not fully scrolled through on
  device after this compact-width layout change

## 2026-07-07 iOS runtime entry restored to V1 four-tab shell

This correction responds to real-device feedback that the main UI had collapsed
into the Configuration Center instead of preserving the intended four-entry V1
main surface.

Root cause:

- commit `ff30f25a Converge V1 iOS runtime and status surfaces` changed the
  real iOS root scene from the temporary/V1 shell path into
  `ConfigurationCenteriOSView`
- the four bottom entries still existed inside `PhotoMemoiOSV1View`, but the
  app no longer launched into that view
- later Configuration Center polish made the single-page behavior more obvious
  on device, because homepage / configuration / output / task surfaces were no
  longer separated by the bottom TabView

What changed:

- `PhotoMemoRootSceneView` now launches `PhotoMemoiOSV1View` on iOS again
- the root view passes through the live runtime dependencies:
  - background status service
  - external intake refresh
  - preview/export/queue/configuration coordinators
  - external intake center
  - diagnostics repository
- the Configuration Center remains available inside the second bottom tab, so
  the recent Configuration Center UI work is preserved without owning the app
  root

Verification:

- passed:
  - `git diff --check`
- passed real-device build:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -destination 'id=00008150-000A043136A1401C' -configuration Debug -derivedDataPath /tmp/PhotoMemoIOSDeviceDerivedData build`
- installed and launched on physical device:
  - device: `iPhone7`
  - bundle id: `com.serydoo.PhotoMemo.iOS`

Known remaining verification gap:

- final visual confirmation is pending the user's real-device check that the
  bottom entries show as:
  - 首页
  - 配置中心
  - 输出
  - 任务

## 2026-07-07 V1 interaction feedback unification landed across share, activity, notification, and in-app status

This slice turns the earlier design/spec work for V1 interaction feedback into
real code, with one calmer state language flowing through the share handoff,
Live Activity, notification result wording, and in-app status/task surfaces.

Scope boundary:

- this remained a V1 interaction-polish and wording-unification slice
- no renderer drawing logic, export format, metadata extraction rules, or
  photo-library save behavior changed
- no Configuration Center architecture redesign was introduced

What changed:

- added canonical feedback-state derivation in
  `PhotoMemoBackgroundStatusService`:
  - `准备中`
  - `处理中`
  - `已完成`
  - `部分完成`
  - `需处理`
  - `暂不支持`
- batch failures are now classified so unsupported input can be surfaced as a
  calm product state instead of a generic failure
- share handoff copy was rewritten around:
  - accepted / handing off / received reassurance
  - unsupported-input clarity
  - softer retry guidance when the handoff itself fails
- Live Activity payloads now carry unified feedback-state data in addition to
  the older presentation-state field
- Live Activity presentation now uses the unified primary titles and matching
  icon/tint behavior for partial-success / attention / unsupported cases
- in-app V1 task/status presenters now derive their summary wording from the
  same feedback state instead of mixing older MVP labels
- queue diagnostics and notification tests were updated to reflect the new
  state language and calmer result wording
- new interaction documents were added:
  - `Docs/Interaction/V1_Interaction_Feedback_Unification.md`
  - `Docs/Interaction/V1_Interaction_Feedback_State_Matrix.md`

Verification:

- passed focused tests:
  - `BatchNotificationMessageFormatterTests`
  - `QueueStatusProjectionEngineTests`
  - `V1SettingsPagePresenterTests`
- passed builds:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData4 CODE_SIGNING_ALLOWED=NO -quiet build`
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -destination 'generic/platform=iOS Simulator' -configuration Debug -derivedDataPath /tmp/PhotoMemoIOSDerivedData5 CODE_SIGNING_ALLOWED=NO -quiet build`
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoShareExtension -destination 'generic/platform=iOS Simulator' -configuration Debug -derivedDataPath /tmp/PhotoMemoShareExtensionDerivedData5 CODE_SIGNING_ALLOWED=NO -quiet build`
- observed existing warning:
  - `GeocoderService.swift` still emits the known macOS 26 deprecation warning
    for `CLGeocoder`

Not yet manually verified:

- share extension visual hierarchy on a real device after the copy/layout
  changes
- Live Activity / Dynamic Island visual rhythm for:
  - `部分完成`
  - `需处理`
  - `暂不支持`
- end-to-end notification receipts on real iPhone hardware after a true share
  batch completes

## 2026-07-08 iOS Live Photo internal-test integration checkpoint

This work happened in the isolated integration worktree:

- `/Users/rui/Desktop/PhotoMemo-ios-livephoto-internal-test`
- branch: `codex/ios-livephoto-internal-test`

Scope boundary:

- the main `/Users/rui/Desktop/PhotoMemo` worktree was not touched
- this branch is for private V1/iOS Live Photo testing only
- ordinary V1 still-image behavior remains on the existing path
- Live Photo runtime processing is not fully wired into the queue yet

What landed in this checkpoint:

- migrated the VNext media pipeline core and Live Photo contract tests into the
  integration worktree
- fixed `LivePhotoVideoCompositionService` so iOS 18 builds use the compatible
  `AVMutableVideoComposition*` path while macOS keeps the newer configuration
  APIs
- added `MediaPipelineRuntimeGate` as the planner/writer boundary for VNext
  runtime modes
- kept `PhotoProcessingInputPolicy.standard` rejecting Live Photo by default,
  while allowing test/internal policy construction with `allowsLivePhoto: true`
- added a V1 output-page media mode:
  - `原格式`
  - `静态图片`
- persisted the V1 media output mode through the existing configuration save /
  bootstrap flow
- mapped those choices into `MediaProcessingIntent`:
  - `原格式` -> source-compatible output, automatic motion handling
  - `静态图片` -> source-compatible still-image output, still-only Live Photo

Verification passed:

- `git diff --check`
- focused VNext / V1 contract tests:
  - `MediaOutputPolicyTests`
  - `MediaPipelineRuntimeGateTests`
  - `PhotoProcessingInputPolicyTests`
  - `MediaProcessingPlannerTests`
  - `LivePhotoAssetWriterContractTests`
  - `V1ConfigurationApplyRequestBuilderTests`
  - `V1BootstrapRuntimeCoordinatorTests`
- iOS generic build:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo-ios-livephoto-internal-test/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -destination 'generic/platform=iOS' -configuration Debug -derivedDataPath /tmp/PhotoMemoIOSLivePhotoOutputModeIOSBuild3 CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO -quiet build`
- macOS app build:
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo-ios-livephoto-internal-test/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoIOSLivePhotoOutputModeMacBuild CODE_SIGNING_ALLOWED=NO COMPILER_INDEX_STORE_ENABLE=NO -quiet build`

Observed warnings:

- existing macOS deployment target warning: project target is `27.0`, installed
  SDK supports up to `26.5`
- existing `CLGeocoder` macOS 26 deprecation warning

True-device status:

- `IPhone5` is visible to `devicectl` as an available paired physical device:
  - UDID: `00008130-001C30EA213A001C`
  - model: iPhone 15 Pro
  - iOS: 27.0
- device build/install is currently blocked because Developer Mode is disabled
  on the phone
- next manual action: enable Developer Mode on the device in
  `Settings -> Privacy & Security -> Developer Mode`, restart/confirm, then
  retry a real-device build/install/log pass

Next recommended slice:

- wire V1 intake/queue so Live Photo inputs automatically route into the VNext
  Live Photo branch
- use the saved V1 media output mode to choose between motion-preserving output
  and static-image output
- keep existing still-image inputs on the current V1 render/export path

## 2026-07-09 Live Photo Release Readiness Review

This review happened in the isolated integration worktree:

- `/Users/rui/Desktop/PhotoMemo-ios-livephoto-internal-test`
- branch: `codex/ios-livephoto-internal-test`

Current product framing:

- `Media Geometry Foundation`: closed
- `Live Photo Main App Picker Pipeline`: release candidate / production
  candidate
- `Share Extension Live Photo`: known limitation and future production
  validation item
- failed-item thumbnail/reason UI: deferred polish, not a main app picker
  release blocker

What this review established:

- main app picker Live Photo support is no longer best described as active R&D
- the current workstream is `Release Readiness Review`
- main app picker evidence now covers automatic still/Live Photo routing,
  motion-preserving Live Photo output, static-image output,
  `CanonicalGeometry` adoption, shared pairing identity across still/video
  outputs, fixed footer/photo geometry, output-description metadata in the
  composed still image, and batch queue routing for Live Photo payloads

Verification passed in this review:

- `git diff --check`
- `PhotoMemoiOS` Debug generic iOS build
- `PhotoMemoShareExtension` Debug generic iOS build
- `PhotoMemoWidgetExtension` Debug generic iOS build
- `PhotoMemo` Debug macOS build
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

Test harness caveat:

- broad `PhotoMemoTests` / grouped runs may hang during Xcode result
  finalization rather than fail through product assertions
- observed Xcode finalization states:
  - `waiting for record to finish saving`
  - `Finalize test log`
  - `waiting for workers to materialize`
- do not interpret an interrupted exit code `75` as a product failure without a
  reproduced focused assertion failure

Known non-blocking warnings:

- macOS deployment target is set to `27.0`, while the installed SDK supports up
  to `26.5.99`
- `GeocoderService.swift` still emits macOS 26 deprecation warnings

Git state:

- the branch is behind `origin/main` by one commit
- the Live Photo integration diff is still uncommitted
- merge to `main` should wait until there is a clean checkpoint commit and the
  one-commit divergence from `origin/main` is resolved safely

Recommended next action:

- prepare a scoped checkpoint commit for the Live Photo release candidate
- rebase or merge `origin/main` only after the checkpoint strategy is clear
- keep Share Extension Live Photo validation as follow-up production validation
- do not reopen Media Geometry Foundation unless runtime evidence proves
  `CanonicalGeometry` itself is wrong

## 2026-07-09 Memory Subject iOS Polish

Implemented the first pass of the iOS Memory Subject configuration polish:

- the subject overview sheet now embeds editable basic subject information
  directly on the overview page
- avatar editing reuses the existing PhotosPicker/crop flow in a compact
  overview layout
- the overview has explicit `保存` and `切换` actions in the object rail
- single-subject switching now exposes `新增对象`; multi-subject switching keeps
  horizontal card selection plus `保存切换`
- the basic info header includes a `锚点维护` navigation entry
- the available anchor section is now titled `可用时间锚点` and uses tap rows
  with immediate active-anchor selection
- newly created subjects now receive three default anchors: `生日`, `百天`,
  and `第一次旅行`
- the anchor maintenance page lists the preset anchors first, then expands the
  selected anchor into editable name/date/type controls with `保存设定`

Verification:

- `git diff --check`
- `xcodebuild -project Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -configuration Debug -destination 'platform=iOS,id=00008150-000A043136A1401C' -derivedDataPath /tmp/PhotoMemoSubjectPolishBuild COMPILER_INDEX_STORE_ENABLE=NO -quiet build`
- installed to device `863C2747-6742-5E93-B715-6F89DBF90B31`
- launched bundle `com.serydoo.PhotoMemo.iOS`

Follow-up polish notes:

- review the object rail card height and empty/new-subject state on device
- decide whether anchor maintenance edits should persist only on `保存设定` or
  continue saving anchor draft changes live while the save button controls which
  anchor becomes active

## 2026-07-09 Memory Subject Overview Trim

Refined the iOS Memory Subject overview again based on device feedback:

- removed the large `对象浏览` overview card from the subject overview top area
- kept a compact current-subject summary with `保存` and `切换`
- single-subject switch mode now shifts the current subject chip left and shows
  a vertically centered plus button on the right
- multi-subject switch mode uses smaller horizontal subject chips with
  `保存切换`
- the basic info card header now presents `基本资料` and `锚点维护` side by side
  inside one bordered control
- removed the default `Kyoto Spring / Kyoto` demo subject from mock seed data
- added a narrow legacy demo filter so persisted `Kyoto Spring / Kyoto` entries
  are dropped during iOS subject-library restore/save

Verification:

- `git diff --check`
- `PhotoMemoiOS` Debug real-device build to
  `00008150-000A043136A1401C`
- installed to device `863C2747-6742-5E93-B715-6F89DBF90B31`
- launch was blocked by iOS because the device was locked; install succeeded

## 2026-07-09 Time Anchor Maintenance And Compact Identity

Refined Memory Subject editing again:

- time anchor maintenance now acts as source management rather than active
  selection
- the anchor page uses row-based anchors: numbered title, date, and type
- top copy now explains what anchors decide and how date/type/name affect
  memory calculations
- anchors can be configured by expanding a four-row editor:
  `锚点时间`, `锚点类型`, `锚点名称`, `保存当前锚点`
- added inline `新增时间锚点`, capped at 5 anchors
- custom swipe-delete is supported for every anchor, including presets, while
  preserving at least 1 anchor
- saving an anchor collapses its editor and refreshes the session
- the subject overview basic-info area is more compact:
  - removed per-row `主体已生效` controls from the overview mode
  - added one `主体名称` menu for display name / nickname / relation / relation note
  - shows the selected subject text on the right
  - reduced the four identity inputs to compact left-title/right-field rows

Verification:

- `git diff --check`
- `PhotoMemoiOS` Debug real-device build to
  `00008150-000A043136A1401C`
- installed and launched on device
  `863C2747-6742-5E93-B715-6F89DBF90B31`

## 2026-07-09 Anchor Sheet And Home Metrics

Further refined the iOS subject and bottom-action surfaces:

- anchor configuration no longer stays expanded under the anchor list
- tapping an anchor row opens a compact configuration sheet; saving or
  dismissing the sheet closes it
- removed the `收起` label from anchor rows
- the subject overview `可用时间锚点` section is now read-only:
  no active badge, checkbox, or selection action
- subject and anchor field titles now follow the Configuration Center row
  hierarchy with `subheadline semibold` titles and `caption` helper text
- Home `处理照片` and Output `保存到当前配置` now share a centered
  184 × 40 bottom-action size
- Output save moved from scroll content into the bottom safe-area footer
- Home subject card no longer shows a globally active anchor
- Home now shows one compact record row with:
  `可用配置 X 个` and `累计完成 X 张`
- completed count reuses the task overview's real
  `completedPhotoCount`

Verification:

- `git diff --check`
- `PhotoMemoiOS` Debug real-device build
- installed and launched on device
  `863C2747-6742-5E93-B715-6F89DBF90B31`

## 2026-07-09 Preset Logo And Output Icon Polish

Aligned Home configuration identity and Output actions with the current
Configuration Center design language:

- `MemoryPreset` now records only the selected three-state Logo mode:
  Apple mark, custom mark, or subject avatar
- custom Logo image paths remain owned by the existing global Logo asset flow;
  they are not copied into each preset
- saving or creating a configuration snapshots the current Logo mode
- selecting a configuration restores its Logo mode
- each Home configuration row replaces the generic card thumbnail with its
  mapped Logo mark; subject-avatar mode reads the current subject's existing
  avatar and falls back to the system avatar symbol
- Output `保存选项` icons now use compact semantic color containers for EXIF,
  Live Photo, and memory-description writing
- Home `处理照片` and Output `保存到当前配置` now share the same filled compact
  bottom-action treatment; the Output action uses a save icon

Verification:

- `git diff --check`
- focused configuration lifecycle tests for Logo-mode save/create passed
- `PhotoMemoTests` build-for-testing passed
- full lifecycle-suite execution remains blocked by existing tests that still
  index the removed second mock subject
- `PhotoMemoiOS` Debug real-device build passed
- installed and launched on device
  `863C2747-6742-5E93-B715-6F89DBF90B31`

## 2026-07-09 Row Rhythm And Preset Identity Icon Polish

Refined the iOS page rhythm after comparing Configuration Center, Output, and
Task surfaces:

- added shared compact information-row metrics:
  36pt icon, 9pt vertical padding, 12pt horizontal/content spacing
- Configuration Center source/layout rows now use the shared compact row
  metrics
- Output `写入与保留` rows now use the same row height and icon size as
  Configuration Center rows
- Configuration Center, Output, and Task continue sharing `V1PageHeader`; the
  header now has a stable minimum height
- Configuration Center and Output hide the extra navigation-bar title so the
  visible page header matches Task's title hierarchy
- Home configuration rows now use the selected preset's time-anchor type as the
  main identity icon, with the saved Logo mode shown as a small badge
- this keeps configuration meaning and output Logo choice visible at the same
  time instead of letting Logo mode replace the preset's semantic identity

Verification:

- `git diff --check`
- `PhotoMemoTests` build-for-testing passed
- `PhotoMemoiOS` Debug real-device build passed
- installed and launched on device
  `863C2747-6742-5E93-B715-6F89DBF90B31`

## 2026-07-09 Task Header And Location Preselection Polish

Refined the iOS task/header and Configuration Center location behavior:

- active Configuration Center, Output, and Task pages now share the same
  `V1PageHeader` rhythm with 16pt horizontal inset, 10pt top inset, and 12pt
  header-to-content spacing
- Task title was moved upward by reducing its top inset; no task icon optical
  offset is kept
- Output `写入与保留` rows now fully reuse the compact information-row metrics
  for toggle padding, label spacing, and divider inset/height
- Configuration Center `位置显示` can now be selected before a location module
  is inserted into any card region
- the missing-module reminder remains visible through the existing
  `未插入位置模块` detail text
- the selected location-display configuration continues to save independently
  through the existing `locationDisplayConfiguration` path

Verification:

- `git diff --check`
- `PhotoMemoTests` build-for-testing passed
- `PhotoMemoiOS` Debug real-device build passed
- installed and launched on device
  `863C2747-6742-5E93-B715-6F89DBF90B31`
## 2026-07-11 V3 Configuration And Rendering Handoff

The configuration engineering slice is implemented and unsigned-build clean.
The durable model is `ConfigurationLibraryRecord`; old UserDefaults fields and
configuration slots are compatibility projections only. Home local backup,
restore, restore-current and live deletion now operate around the aggregate and
hidden UUID identity. External Files import and self-contained export remain
disabled until their resource-package UI is complete.

The intermittent bottom-edge line was reproduced with odd source dimensions
and fixed by integer-rounding the Classic White output canvas height. Automated
coverage includes odd/even landscape and portrait Renderer output, JPEG
readback, and Live Photo still footer preservation.

Do not repeat 48MP/RAW work before the next product decision. Record it as a
later high-quality-output enhancement. When the user returns, perform signed
device validation last, beginning with `share-21-reject`, then `share-1`, mixed
Live Photo + still, and the 20-photo orientation/location batch. Instruments,
real AV Live Photo composition and PhotoKit save/readback follow those checks.

No commit or push was created in this slice. The worktree still contains the
broader uncommitted V3 body and must be reviewed as one intentional release
scope before syncing to GitHub or Xcode Cloud.

## 2026-07-11 Configuration Real-Device Regression Fixes

Real-device feedback identified four related configuration regressions. The
complete aggregate draft now wins over legacy template bootstrap after launch,
so saved region content is not replaced during restart. Home-row backup now
applies a dirty or newly created configuration before writing its local backup,
and backup/delete outcomes are shown immediately on Home. Deleting the oldest
durable configuration first persists a dirty sibling when necessary. The
configuration-row swipe uses continuous geometry for reveal, opacity, hit
testing, and snapping.

Focused configuration lifecycle, local-library presenter, and Home action
tests passed. A signed `PhotoMemoiOS` Debug build, including Share and Widget
extensions, was installed and launched on device
`863C2747-6742-5E93-B715-6F89DBF90B31`. Manual confirmation remains for region
content after restart, local-backup visibility, oldest-configuration deletion,
and swipe feel.

## 2026-07-11 Saved Preview Projection Regression

Fixed a save-time preview divergence where custom region drafts remained in the
Configuration Center but the renderer reverted to preset defaults. Aggregate
save reconciliation now emits the saved complete configuration for projection
only when the receipt is actually applied; a stale receipt never overwrites
newer concurrent edits. The iOS view reapplies the complete configuration and
refreshes all dynamic region previews after successful reconciliation.

Focused apply-runtime and configuration-lifecycle tests passed, and the signed
iOS build succeeded. The app was fully uninstalled and reinstalled on device
`863C2747-6742-5E93-B715-6F89DBF90B31`, intentionally clearing its container.
The first remote launch was denied until the development profile is trusted
again on the device.

## 2026-07-11 Unresolved Configuration Region Persistence Blocker

Status: unresolved and reproducible on the clean-installed physical device.

Exact reproduction:

1. Fully delete MemoMark from the device and install the signed `1.6 (7)` build.
2. Customize modules/content in the four Configuration Center regions.
3. Confirm the renderer updates correctly while editing.
4. Tap `保存为当前配置`.
5. The region editors still show the custom content, but the renderer returns
   to default content.
6. Terminate and relaunch the app.
7. The custom region content is then missing from the region editors as well.

Confirmed facts:

- this is not stale data left by an older installation; the device app
  container was deleted before the latest reproduction
- live editor state and renderer state are different sources: the editor reads
  local `regionDrafts`, while the renderer reads session `regionPreviewTexts`
- aggregate reconciliation calls `restoreConfigurationLibrary`, whose legacy
  `refreshPresetDrivenPreview` replaces preview text with template-ID defaults
- the first attempted fix added `applySavedConfigurationProjection` after a
  successful receipt and protected concurrent edits; its automated tests pass,
  but real-device behavior proves this is not the complete root cause
- restart loss means the durable aggregate written to disk, the aggregate
  selected during bootstrap, or the draft-to-template conversion still loses
  or bypasses the current four-region draft; do not treat this as a UI-only
  refresh bug

Files to resume from:

- `PhotoMemoiOSV1View.applyCurrentV1Configuration`
- `V1ConfigurationAggregateCandidateBuilder.build`
- `V1ConfigurationAggregateCandidateBuilder.template/area`
- `V1ConfigurationApplyRuntimeCoordinator.apply`
- `ConfigurationSession.reconcileConfigurationLibrarySave`
- `ConfigurationSession.restoreConfigurationLibrary`
- `V1ConfigurationDraftProjection.regionDrafts`
- `ConfigurationLibraryRepository` and `ConfigurationLibraryPersistence`
- `V1BootstrapRuntimeCoordinator` and bootstrap restoration

Required next test before another fix:

- create four distinct region drafts with text and token modules
- build the aggregate candidate
- persist it through the real repository
- construct a new session/runtime as an app restart would
- reload the aggregate and project all four regions
- assert the template items, projected drafts, and renderer preview text all
  retain the same custom content

Do not reinstall another device build until that repository-level round-trip
test fails before the fix and passes after it. The currently installed clean
device build still reproduces the blocker.
