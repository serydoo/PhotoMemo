# MGF-2B Runtime Report 2026-07-09

## Scope

- Scenario: Landscape Live Photo shared from iPhone Photos into MemoMark.
- Device: iPhone7, iPhone 17 Pro Max, device identifier `863C2747-6742-5E93-B715-6F89DBF90B31`.
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
  - `extension.item.imported`: `IMG_6093.jpeg`.
  - `app.enqueue.taskRoute`: `fileName=IMG_6093.jpeg, contentType=public.jpeg, hasSourceIdentifier=false`.
  - `batch.task.route`: `fileName=IMG_6093.jpeg, contentType=public.jpeg, hasSourceIdentifier=false, route=staticImage`.
- Latest batch queue job:
  - Job: `1AE0185C-69D9-462E-94AA-8E25E824F84C`.
  - Task: `93285AD1-6DB6-45B1-86DC-9E273E12EBB3`.
  - File name: `IMG_6093.jpeg`.
  - Content type: `public.jpeg`.
  - Source URL: `ExternalIntake/828BC22D-76EC-4405-B555-60A5687E4402/IMG_6093.jpeg`.
  - Saved asset identifier: `1E978916-4E1A-4437-981B-1998EEF733B4/L0/001`.
  - Phase: `completed`.
- Share diagnostics:
  - `extension.request.created`: `providers=1, itemProviders=1`.
  - `extension.item.imported`: `IMG_6059.jpeg`.
  - `app.enqueue.created`: `tasks=1`, job `4496D5D0-28AE-4A92-8EB3-647DC83D8CF0`.
- Batch queue job:
  - Job: `4496D5D0-28AE-4A92-8EB3-647DC83D8CF0`.
  - Task: `95EEB695-BDCA-4BD9-8396-33DBC329D5A2`.
  - File name: `IMG_6059.jpeg`.
  - Content type: `public.jpeg`.
  - Source URL: `ExternalIntake/D92300C2-C9C0-4999-8352-FEBDFD6EA1E1/IMG_6059.jpeg`.
  - Saved asset identifier: `84FF198D-3A6B-4993-A36C-CD66E2F88D65/L0/001`.
  - Phase: `completed`.
- Code evidence:
  - `ShareExtension-Info.plist` declares `NSExtensionActivationSupportsImageWithMaxCount=50` and no Live Photo-specific activation rule.
  - `PhotoMemoShareExtensionIntakeService.supportedImageProviders` filters providers by `UTType.image`.
  - `PhotoMemoShareExtensionIntakeService.loadFileRepresentationResult` requests `UTType.image`.
  - `BatchQueueExecution.shouldUseLivePhotoProcessing` checks only `task.contentTypeIdentifier` for a Live Photo content type.
- Notes:
  - The connected device also contains older `PhotoMemoiOS` crash logs around 02:50 involving `PhotoMemoiOSLiveActivityDriverService.bootstrapExistingActivities`; these are not the root cause of this 06:28 intake flattening finding.
  - No private HEIC, MOV, screenshots, or screen recordings are stored in this report.
