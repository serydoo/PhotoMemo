# PhotoMemo Current Status

Last updated: 2026-06-29

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
