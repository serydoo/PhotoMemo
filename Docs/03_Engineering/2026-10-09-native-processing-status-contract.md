# Native processing status contract

## Product behavior

MemoMark uses the same meaning across devices and interface languages: accepted, preparing, processing, saving, completed, or requiring attention. Acceptance means the durable intake is committed; it does not mean background execution or saving has completed. Progress comes from the execution session and committed task transitions, never elapsed-time estimates. Completion requires saved-asset receipts and no intake failures or other items requiring attention.

## System surfaces

| Runtime capability | Processing surface | Result surface |
| --- | --- | --- |
| Continued Processing actually owns execution | System-managed continued-processing activity; localized title, stage, completed count and percentage | Native local notification after verified saving |
| ActivityKit available, no Continued Processing owner | Existing MemoMark activity projecting the same durable session | Native local notification |
| No Dynamic Island | System chooses lock-screen and other supported surfaces; do not promise island UI | Native notification center / banner according to user settings |
| iOS 18–25 recovery | Existing foreground recovery and BGProcessing scheduling | Native result notification after actual saving; no immediate-background-completion promise |
| Notifications denied or suppressed | Processing remains durable; foreground status is available | Respect permission, Focus, summaries and system presentation decisions |

An execution session has one presentation authority. Do not start a second ActivityKit processing display when Continued Processing owns the session. Do not post percentage notifications on every update. Ordinary photo processing uses normal notification interruption level and does not bypass Focus. Do not request notification permission from a Share Extension.

## Language and region

Use the user's interface language for processing feedback, independently of output-card language. Current catalogs cover Chinese, English, Japanese and Korean. Format percentages and timestamps with the selected language/locale. Keep photo counts, album names and state semantics consistent; system typography, icon placement, notification grouping and appearance remain system-owned. Do not infer device capability from region or a hard-coded device list.

## Evidence and remaining gates, 2026-10-09

The iOS 27.2 Beta signed-device experiment has produced seven actual outputs without activating MemoMark after Share and has shown a fresh native completion notification under Focus. This is DEBUG opt-in evidence, not Release certification. Latest full automated baseline is 2,046 passing tests, one skipped; formal Xcode 27.0 Release compilation passed.

Dynamic Island visibility after Photos Share, stable-system runtime behavior, physical non-island devices, system cancellation/expiration recovery, and production promotion remain separate acceptance gates. System UI appearance is not controlled by MemoMark. Apple DTS discusses this boundary in https://developer.apple.com/forums/thread/804515; the API contract is https://developer.apple.com/documentation/backgroundtasks/bgcontinuedprocessingtask.

The Photos-versus-Home round captured a system processing banner on App Library with “0% · 已完成0/6张 · 正在准备照片”; the Photos foreground screenshot had no visible processing island. This proves a native banner appeared after the Home transition, not persistent compact-island visibility. The round failed: six inputs were actually persisted despite seven intended selections, only three outputs were independently observed, and the owner released its lease and reported unfinished after about 215 seconds. Foreground cleanup/recovery occurred later and is excluded from background completion evidence. Cancellation/deletion and named-output-album cleanup subsequently passed two real-device tests. Expiration and system-condition probes were added for the next round; neither thermal pressure nor system expiration has yet been established as the cause.

Partial failures must never produce the full-success notification. The current completion-only projection withholds that message when attention is required; native partial-result and recovery delivery still need an explicit implementation and acceptance test.

The diagnostic retry persisted seven inputs. It exited without cancellation, pause or a stop request: four tasks were `savingToPhotoLibrary`, three completed. No expiration callback was recorded; initial thermal state was fair and Low Power Mode was off. This retry reused the previous frozen test caption after its outputs had been deleted, so the retained receipts correctly prevented replacement writes for that intent. The test was stopped as invalid fresh-output certification. Future fresh-output rounds freeze a unique per-round caption; repeated-intent tests must preserve their outputs until deduplication and readback have been checked. Receipt deletion is not a test reset.

The completion-intake-failure regression was reproduced before the fix, then passed in a ten-test focused run. The subsequent complete automated suite passed 2,047 tests with one skipped and zero failures; its two existing fixture readback QoS warnings remain recorded separately.

The next unique-intent round independently saved five of seven assets, then recorded an actual system expiration callback at approximately 98 seconds. Its exit snapshot was cancelled, with five completed tasks, one exporting and one queued. This is a separate failure from retained-receipt readback. A synchronous raster strip loop blocked the main execution actor for a long interval; this is a performance risk to address, not proof of the system's undocumented expiration reason.

The DEBUG mapped-raster experiment now amortizes render setup with up to 64 rows, retaining a two MiB owned pixel-strip buffer (a temporary write-data copy may additionally occupy up to two MiB). The initial change exposed an intra-strip row-order error and failed asymmetric readback. The repair traverses unflipped Core Image rectangles from the top of the canvas. A subsequent 22-test focused suite passed, including every row of a 70-row gradient, the partial final strip, EXIF orientations 1/6/8, full dimensions, JPEG/HEIC Live Photo pairing metadata and scratch cleanup. Actual background timing remains a device gate; these changes remain DEBUG only.

The corrected bounded-strip round passed signed-device UI validation. Seven inputs were persisted, seven real outputs and their per-round frozen descriptions were read back without MemoMark foreground activation. Independent owner completion followed submission by about 102 seconds, reached 700/700 units, released its lease and scheduled the native seven-output completion notification. The App Library system card showed “11% · 已完成0/7张 · 正在生成 Live Photo” with its native cancel button. Named-output cleanup verified zero assets. The full automated suite then passed 2,049 tests, one skipped, zero failures; existing fixture QoS warnings persisted. This remains warm-background iOS 27.2 Beta evidence.

The first native-stop UI test failed before submission because the Photos image query had not populated; PhotoKit still independently counted seven source assets and zero outputs. It is not cancellation evidence. The harness now waits for the named input grid and records its hierarchy on readiness failure before selecting anything.

## Native stop and durable hold follow-up

- Signed-device native Stop verification: `/tmp/MemoMarkNativeStopHeldRound.xcresult` passed. Session `751027A8-131D-4DF6-930B-01A0F95FFB1C` retained 2/3 confirmed outputs and one queued item. Suspension was persisted before lease release. Opening and relaunching the host did not restart processing.
- The native Cancel action invoked expiration while `task.progress.isCancelled` remained false. That flag cannot distinguish user cancellation from system expiration; preserve unfinished work as a durable hold rather than permanently deleting it.
- Explicit Home resume: `/tmp/MemoMarkExplicitNativeResumeRound.xcresult` passed; final count 3, previous saved identifiers retained, one Live Photo, protected source count 7, generated output cleanup count 0. This is foreground recovery evidence.
- Full regression before suspension-notification transport: `/tmp/MemoMarkNativeSessionHoldFull.xcresult`: 2053 passed, 1 skipped, 0 failed. Formal Release build `/tmp/MemoMarkSessionHoldStableRelease.log` exited 0.
- Suspension notification uses the same stable session status identifier as completion, reports distinct confirmed asset saves and unfinished items, and does not acknowledge final delivery. Explicit resume/cancel removes the owned stale status notification. Native transport remains within the DEBUG opt-in extension experiment.
- Model/localization checks `/tmp/MemoMarkSuspensionNoticeModelRetry.xcresult` passed (7 cases, 13 runs). Signed-device transport build `/tmp/MemoMarkSuspensionNotificationDeviceBuild.log` exited 0. Notification visibility and the latest integrated full regression are pending; no production acceptance implied.

### Native pause notification verification

`/tmp/MemoMarkNativeSuspensionNoticeRound.xcresult` passed: Photos-origin three-input round stopped through the actual native Cancel control without host activation. Independent App Group readback confirmed 2/3 completed, durable hold before lease release, and native suspension notification scheduling. Notification Center accessibility readback found “时光记处理已暂停” before opening MemoMark; subsequent host opening/relaunch retained the explicit resume state. Read-only evidence: task artifacts `native-stop-suspension-notice.json`.

`/tmp/MemoMarkNativeNoticeFullRegression.xcresult`: 2055 passed, 1 skipped, 0 failed (2118 parameterized runs). Two existing fixture readback QoS warnings remain. First explicit-resume follow-up failed before action due to CoreDevice process-launch resolution; retry pending, not a processing acceptance result.

### Follow-up blocked by device trust

`/tmp/MemoMarkNativeNoticeExplicitResumeRetry.xcresult` could not launch the test runner: iOS reports Developer App Certificate not trusted / invalid signature or profile not explicitly trusted. Local embedded profile expires 2027-10-08 and includes the paired device. Device-side trust verification is required; no app uninstall or receipt clearing performed. The prior native-stop round passed before this launch restriction. Explicit resume of the latest notice integration and output cleanup are not yet verified; preserve the held session and two generated outputs until retry.

Formal toolchain Release build `/tmp/MemoMarkNativeSuspensionNoticeStableRelease.log` exited 0; existing native backdrop actor-isolation warnings remain. `git diff --check` passed.

Review follow-up: queue task selection skips held sessions, but BGProcessing scheduling still counts all pending tasks, including held work. It cannot resume those jobs through the selector; unnecessary rescheduling remains an open efficiency issue, requiring an explicit runnable-pending projection and tests. No production completion claim.

### Certificate recheck after device-side inspection

User reports no developer trust entry in Settings. Local strict/deep verification of the test runner passed; main app and runner profiles both include the paired device and remain valid (2027-07-12 and 2027-10-08 respectively). Device is paired, Developer Mode enabled, and unlocked. Previous CoreDevice wording is a launch-rejection report, not proof that the account certificate is missing. Retrying without uninstalling, clearing receipts, or changing signing credentials; exact root cause remains unconfirmed until launch/runtime evidence.

Certificate recheck retry `/tmp/MemoMarkCertificateRecheckResume.xcresult` passed without signing changes or device trust changes. Explicit resume completed all three outputs, retained earlier identifiers, preserved seven sources and cleaned generated outputs to zero. Previous trust error is no longer a blocker; its precise transient cause remains unconfirmed. Latest pause → explicit resume → cleanup integration is verified on this beta device.

Latest two-Share regression `/tmp/MemoMarkNativeNoticeOverlapRound.xcresult` passed: 12 selections, 7 unique saved outputs, still metadata readback and output cleanup verified without host foreground during processing. Independent evidence shows first request completed before second submission; leases do not overlap, but sessions are distinct. This certifies sequential cross-Share idempotency, not contended admission. Added a faster second Share (one duplicate input) to seek actual overlap, with independent timing checks required regardless of UI test result.

True overlapping submission `/tmp/MemoMarkAppendDuplicateRound.xcresult` passed: seven inputs followed immediately by one duplicate, no host foreground while processing, final seven outputs, metadata verified, cleanup zero. Independent records confirm second submission (1791509364.064) preceded first completion (1791509369.345), same session `CC5F03F0-0D1E-4277-84E1-7901CC9038DB`, second lease acquired only after first released. Both notifications share the same stable session identifier and confirmed save count seven. Safe evidence artifact: `native-status-overlapping-share-owner-readback.json`.

### Held-session scheduling correction

Added executable pending projection excluding held and deleted jobs while preserving the existing user-visible pending count. Foreground-to-background submission and grace-expiration submission now require executable work. BGProcessing reports paused when only held work remains, and destination authorization checks ignore held/deleted jobs. Focused test RED `/tmp/MemoMarkHeldSchedulingRed.xcresult` failed for the absent API; GREEN `/tmp/MemoMarkHeldSchedulingGreen.xcresult` passed 7 cases. Signed-device build `/tmp/MemoMarkHeldSchedulingDeviceBuild.log` exited 0. Integrated full regression, formal Release build, and native Stop/resume regression are pending.

Held scheduling full regression initially failed one architecture assertion still expecting the old pending-count expression; corrected to executable pending semantics. `/tmp/MemoMarkHeldSchedulingFullCorrected.xcresult`: 2056 passed, 1 skipped, 0 failed. Formal Release `/tmp/MemoMarkHeldSchedulingStableRelease.log` exited 0.

Stop follow-up diagnostics: first attempt lacked the production launch flag and used legacy intake. The harness now explicitly terminates Xcode's automatically launched host before applying scenario arguments. Retry confirmed production=true but all three PhotoKit saves completed before cancellation settled; `/tmp/MemoMarkDeterministicStopRetry.xcresult` failed its prerequisite expecting <3 outputs. Probe phases were all completed, completion notification saved=3, lease released. No incomplete-state claim; cancellation cannot undo committed saves. Expand stop/resume round to all seven inputs for a genuine unfinished-work window. Named output cleanup test passed in `/tmp/MemoMarkHeldSchedulingStopCleanup.xcresult`; its history-deletion test failed an absence assertion and remains under review, without a broad history reset.

Seven-input native stop regression `/tmp/MemoMarkSevenNativeStopRound.xcresult` passed on the updated held-work scheduling build: actual system Cancel, unfinished output count, native pause notice before host activation, explicit resume surface, no automatic processing on host opening and durable hold across relaunch. Seven-input explicit resume and cleanup follow-up pending.

History deletion harness correction: retained earlier completed sessions may become the Home projection after deleting the current record. Tracking disappearance of the selected record's stable accessibility identifier replaces the incorrect requirement that all history/delete controls disappear. The added identifier is internal automation metadata, not a visible label; no broad history purge.

Seven-input explicit resume `/tmp/MemoMarkSevenExplicitResumeRetry.xcresult` passed after one transient process-launch failure: seven final outputs, earlier saved identifiers preserved, one Live Photo, seven original sources intact, generated output cleanup zero. Scoped current-record deletion `/tmp/MemoMarkScopedHistoryDeleteRetry.xcresult` passed: the selected record disappears and stays deleted across relaunch while earlier history remains. Container-level accessibility identity uses explicit child containment so individual action identifiers remain exposed. The first grouped-identifier attempt failed to find the delete button and was corrected before this passing runtime check.

Current verified scope: warm-background DEBUG opt-in extension pipeline on iOS 27.2 beta; static and Live Photo inputs, output deduplication, exclusive owners, same-session overlapping submissions, native interruption hold/notice, foreground explicit resume and scoped history deletion. Outstanding production gates remain stable iOS 26 hardware, non-island/older OS runtime coverage, cold host launch claims, Release pipeline enablement, identity revision migration, and cancellation before durable admission. Neither successful beta evidence nor Release compilation certifies these gates. Original user configuration, receipts, protected source album and unrelated dirty work remain preserved. No commit, push, uninstall or broad history purge.

Final current-source formal Release build `/tmp/MemoMarkNativeStatusFinalStableRelease.log` exited 0. Existing backdrop actor-isolation warnings remain. Final `git diff --check` passed. Latest complete automated suite remains 2056 passed / 1 skipped / 0 failed, with subsequent accessibility-container change verified by signed-device compilation and scoped deletion runtime test.
