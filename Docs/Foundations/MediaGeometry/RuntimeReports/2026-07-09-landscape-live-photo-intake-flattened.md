# MGF-2B Runtime Report 2026-07-09

## Scope

- Scenario: Landscape Live Photo shared from iPhone Photos into MemoMark.
- Device: TestDeviceB, iPhone 17 Pro Max; device identifier intentionally omitted.
- iOS: iOS 27.0, build `24A5380h`.
- App build: `PhotoMemoiOS` 1.5 (7), bundle `com.serydoo.PhotoMemo.iOS`.
- Input orientation: Landscape.
- Output mode: `originalFormat`.

## Runtime Pipeline

- [x] User initiated share from Photos.
- [ ] Import Live Photo.
- [ ] Export Live Photo.
- [ ] Photos recognizes Live Photo.
- [ ] Long press playback.
- [ ] Still-to-video transition.
- [ ] Footer geometry.
- [ ] Portrait output.
- [ ] Landscape output.

## Runtime Report

- [ ] Live Photo Recognized.
- [ ] Asset Identifier Match.
- [ ] Long Press Playback.
- [ ] Still-to-Video Transition.
- [ ] Geometry Hash Match.
- [ ] Footer Bounds Match.
- [ ] Portrait OK.
- [ ] Landscape OK.

## Finding

- Issue: Landscape Live Photo was imported as a static JPEG before the Live Photo pipeline could run.
- Classification: R.
- Code: R005 Export / Import.
- Layer: Runtime.
- Root cause: Photos exposed a provider that advertised `com.apple.live-photo`, but the Share Extension intake path selected `UTType.image` and persisted the image representation (`public.jpeg`) instead of preserving a Live Photo asset identifier or paired HEIC/MOV resources. `BatchQueueExecution.shouldUseLivePhotoProcessing` routes only when `task.contentTypeIdentifier` is a Live Photo content type, so the task followed the static image path and completed as JPEG.
- Decision: Stop MGF-2B validation at the first failed runtime step. Do not modify Media Geometry Foundation. Next investigation should stay in intake/runtime: determine how Photos exposes Live Photo assets to the Share Extension and preserve the asset identifier or paired resources before enqueue.
- Foundation changed: No.

## Evidence

- Device evidence folder: `/tmp/PhotoMemoMGF2BDeviceEvidence`.
- Shared defaults: `/tmp/PhotoMemoMGF2BDeviceEvidence/appgroup/group.com.serydoo.PhotoMemo.plist`.
- Latest device evidence folder: `/tmp/PhotoMemoRuntimeEvidence/20260709-064632`.
- Latest Share Extension provider evidence:
  - `extension.provider.observed`: `preferredImageType=public.jpeg`.
  - `supportsLivePhoto=true`.
  - `supportsMovie=false`.
  - `registeredTypes=public.jpeg,com.apple.live-photo,public.heic`.
- Latest intake route evidence:
  - `extension.item.imported`: a redacted JPEG source.
  - `app.enqueue.taskRoute`: `contentType=public.jpeg, hasSourceIdentifier=false`.
  - `batch.task.route`: `contentType=public.jpeg, hasSourceIdentifier=false, route=staticImage`.
- Latest batch queue job:
  - Job: `REDACTED_JOB_ID`.
  - Task: `REDACTED_TASK_ID`.
  - File name: `REDACTED_SOURCE.jpeg`.
  - Content type: `public.jpeg`.
  - Source URL: `ExternalIntake/REDACTED_REQUEST_ID/REDACTED_SOURCE.jpeg`.
  - Saved asset identifier: `REDACTED_ASSET_IDENTIFIER`.
  - Phase: `completed`.
- Share diagnostics:
  - `extension.request.created`: `providers=1, itemProviders=1`.
  - `extension.item.imported`: a redacted JPEG source.
  - `app.enqueue.created`: `tasks=1`, job identifier redacted.
- Batch queue job:
  - Job: `REDACTED_JOB_ID`.
  - Task: `REDACTED_TASK_ID`.
  - File name: `REDACTED_SOURCE.jpeg`.
  - Content type: `public.jpeg`.
  - Source URL: `ExternalIntake/REDACTED_REQUEST_ID/REDACTED_SOURCE.jpeg`.
  - Saved asset identifier: `REDACTED_ASSET_IDENTIFIER`.
  - Phase: `completed`.
- Code evidence:
  - `ShareExtension-Info.plist` declares `NSExtensionActivationSupportsImageWithMaxCount=50` and no Live Photo-specific activation rule.
  - `PhotoMemoShareExtensionIntakeService.supportedImageProviders` filters providers by `UTType.image`.
  - `PhotoMemoShareExtensionIntakeService.loadFileRepresentationResult` requests `UTType.image`.
  - `BatchQueueExecution.shouldUseLivePhotoProcessing` checks only `task.contentTypeIdentifier` for a Live Photo content type.
- Notes:
  - The connected device also contains older `PhotoMemoiOS` crash logs around 02:50 involving `PhotoMemoiOSLiveActivityDriverService.bootstrapExistingActivities`; these are not the root cause of this 06:28 intake flattening finding.
  - No private HEIC, MOV, screenshots, or screen recordings are stored in this report.
