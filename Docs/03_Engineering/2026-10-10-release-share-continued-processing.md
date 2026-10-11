# Release Share Continued Processing implementation

Date: 2026-10-10
Primary loop: Engineering Loop
Risk: P0 (cross-process execution, durable intake, cancellation and PhotoKit save)

## Decision gate

Observed state: Share persists durable intake and requests the existing
`BGProcessingTask` fallback. On iOS 26+, the DEBUG-only Continued Processing
probe has also exercised the full extension-owned queue, render and PhotoKit
receipt path on iOS 27.2 Beta. Release does not submit or execute that path.
The latest source checkpoint and ADR-012 leave production activation gated.

Bounded objective: move the already exercised Share Extension Continued
Processing adapter out of the DEBUG probe, make Release select it on iOS 26 and
later, and keep durable intake plus BGProcessing/foreground recovery as the
fallback. Preserve the same ledger, frozen configuration, execution lease,
media executor, save/readback receipts, accounting, and original-photo
protection. Remove probe-only controls, fixture overrides and diagnostics from
the Release path. Do not change user-facing workflows or output semantics.

Ownership and dependencies:

- Share Extension owns durable intake and submits its system-granted
  Continued Processing request after persisting the request.
- Its extension callback owns only the exact Continued Processing execution
  lease and invokes the existing shared queue/media/save pipeline.
- Batch ledger and PhotoKit save receipts remain canonical durable state.
- The containing app retains its existing BGProcessing handler and foreground
  recovery. Continued Processing submission never substitutes for recovery.
- The system owns the task presentation and cancellation surface while the
  Continued Processing callback is active.

Apple capability: use `BGContinuedProcessingTaskRequest` (iOS 26+) with a
per-request identifier beneath the permitted wildcard and the `.queue` strategy.
Continue using `BGProcessingTaskRequest` on iOS 18–25. If submission is
rejected, durable intake remains recoverable and the existing fallback path is
attempted. Background processing must not request Photos authorization.

Failure boundaries: submission is not completion; queued system work can be
canceled when the app is force-quit; expiration must cancel and quiesce the
worker before releasing the execution lease; interrupted work remains durable
and requires explicit recovery; a notification or progress value is not proof
of a PhotoKit save. Stable iOS 26 and older-system physical evidence is not
available in this environment, so implementation/build evidence cannot close
production certification or authorize an external release submission.

## Verification plan

1. Add focused architecture/runtime coverage for Release route selection,
   fallback scheduling, per-request identifier admission and probe exclusion.
2. Run the affected focused and full macOS test targets, then separate unsigned
   iOS Debug and formal-toolchain Release builds.
3. Inspect the Release app and Share extension products for probe symbols,
   probe arguments, and permitted task identifiers.
4. On the paired iPhone 17 Pro Max, verify signed Release installation and
   Photos-only Share to completion/readback, overlapping Shares, cancellation,
   expiration, recovery, static/Live Photo fidelity, originals and cleanup.
5. Keep stable iOS 26 hardware and iOS 18–25 recovery coverage explicitly open
   until performed; do not claim production certification from Beta evidence.

No commit, push, upload, Store submission or broad workspace cleanup is in
scope.

## Implementation and current evidence

- Release Share intake now schedules the durable BGProcessing recovery request
  first, then reserves the durable continuation session. The first admission
  submits a Continued Processing request on iOS 26+; overlapping Shares join
  its task through `ExternalIntakeRequestStore` instead of creating duplicate
  system progress surfaces. A failed native submission leaves the existing
  fallback path in place.
- The extension callback invokes the existing durable ledger, frozen
  configuration, execution arbiter, renderer/media executor, PhotoKit receipt,
  save accounting and result-notification flow. It reports session progress
  through the system task and cancels the worker on expiration. Interrupted
  requests remain held/recoverable under the existing queue rules.
- DEBUG probe controls remain DEBUG-only. Production Release diagnostics are
  no-ops; only the new task adapter and existing processing path are present.
  Temporary raster cleanup is now a small shared owner used by both the DEBUG
  raster experiment and the Release worker; it removes only UUID-owned regular
  raster files and refuses symlinks.
- RED/GREEN architecture contract: the new Release route failed before the
  adapter existed, then passed after implementation. The concurrency contract
  also failed before continuation reservation/drain/close was added, then
  passed. Final focused `BackgroundProcessingContractTests`: 3 passed, 0
  failed, 0 skipped. Full `MemoMarkTests`: 2,090 passed, 1 skipped, 0 failed;
  two existing fixture QoS warnings remain.
- Generic iOS Release builds passed with both Xcode 27.2 Beta and formal Xcode
  27.0. Release
  extension product includes the `continued-processing.share.*` prefix and its
  executable contains no `ContinuedProcessingSpike`,
  `MemoMarkBackgroundProbe`, or `continuedProductionPipelineProbe` strings.
- No device installation or Photos write was performed in this implementation
  turn. The paired iPhone 17 Pro Max is iOS 27.2 Beta; stable iOS 26 and
  iOS 18–25 physical evidence, signed Release Photos-only runtime, system
  expiration, persistence fault injection, resource-pressure and final
  production certification remain open. The Release route is implemented and
  compiled, not certified for external distribution.

## User-facing feedback follow-up, 2026-10-10

The product owner chose a quiet default for ordinary Share sessions. The Home
activity card remains tappable to open task details, but no longer offers an
in-app cancel control during active work. Terminal history deletion remains
available; an interrupted processing record does not show that delete control.
Pause/resume remains an internal recovery capability and is not exposed as a
routine Share action. On iOS 26+, the system-owned Continued Processing UI
still provides its own stop control and is not customizable by MemoMark.

Successful completion notifications now use active, silent delivery: the
system may show a visible banner without an alert sound. An
interruption/suspension notification remains active and audible because it
requires the user to know that work needs attention. Notification permission
and system presentation preferences continue to apply.

Follow-up after the observed two-item `任务失败` Dynamic Island surface: a
persisted foreground queue pause no longer gates a newly admitted, separately
owned Share Continued Processing worker. Non-cancellation worker failures now
attempt the existing durable suspended-session notification after recovery
holds are persisted. The exact cause of the photographed failure remains
unconfirmed without that device run's request diagnostics; this change closes
the known cross-owner pause coupling and improves actionable failure feedback.
The signed iPhone 17 Pro Max Debug build passes after this follow-up. No new
Photos Share runtime round or automated test suite was run, so the screenshot's
specific failure cause and post-fix notification delivery remain unverified.

## Physical QA follow-up, 2026-10-10

After the owner unlocked the paired iPhone 17 Pro Max, the seven-photo
`MemoMarkDeviceQA.testContinuedNativeProgressSurfaceSevenPhotos` UI test
completed its Photos Share submission flow and returned to Photos. The XCUITest
then performed eight foreground-independent QA Outputs album inventories over
four minutes; every readback remained at 0 of 7 outputs. The test failed at
`MemoMarkDeviceQAHarnessTests.swift:1390` as designed, without foreground
recovery. The baseline was 0 outputs, so this run created no QA output assets
and did not modify source inputs. The test request remains durably suspended
for recovery in the App Group; it must be resolved or removed as QA data before
using an empty-output baseline for another physical round.

The captured post-Share Dynamic Island screenshot showed no MemoMark activity;
the Notification Center capture showed no notification for this share. The
phone's status bar showed notifications silenced, so notification visibility
was not tested under an unsilenced presentation setting. This explains a
possible notification suppression, but not the missing PhotoKit outputs. The
UI test did not capture a Continued Processing callback or worker diagnostic,
request-level DEBUG diagnostics show that the system did invoke the Continued
Processing callback and the shared production worker acquired its execution
lease. Admission then failed with `configuration.contract.violation` /
`missingCanonicalSnapshot`; the DEBUG probe recorded
`extensionProductionInterrupted` / `admissionRejected` and suspended the
intake. The device's production configuration reference was revision 41, while
the Share request snapshot had no canonical snapshot. This is the direct cause
of the missing output in this run. The test exercises the DEBUG production
pipeline probe and shared worker, not the Release adapter's exact registration
route. The Release route and normal configuration-snapshot path still need
device verification after correcting the snapshot contract.

This is direct device evidence that the current Debug candidate does not yet
provide reliable background completion/status on this iOS 27.2 Beta phone; it
is not Release runtime certification and does not predict stable iOS 26
behavior.

The same turn passed focused `BackgroundProcessingContractTests` (3/3), the
full `MemoMarkTests` suite (2,090 passed, 1 skipped, 0 failed), a generic iOS
Release build with formal Xcode 27.0 (exit 0), `git diff --check`, and repository
governance validation. Device acceptance remains open pending repair of the
canonical Share snapshot for this persisted configuration, recovery/cleanup of
the held QA request, and a passing Photos-only run on the Release route.

## Production-route correction, 2026-10-11

Owner feedback then confirmed a user-visible regression: Photos Share showed a
system task failure and returning to MemoMark did not show processing progress.
The Release coordinator had completed Share immediately after Continued
Processing submission, without opening the host app. The preceding physical
QA evidence also showed that the extension-owned worker could not resolve the
canonical app configuration (`missingCanonicalSnapshot` / `admissionRejected`).

The ordinary production route has therefore been changed back to durable Share
intake followed by an unconditional host-app deep-link handoff. The host app's
`ShareCoordinator` owns canonical configuration resolution, queue admission,
and in-app progress; BGProcessing remains only a durable recovery request. The
extension-owned Continued Processing route is historical/experimental and is
not selected for ordinary Release Share until it can resolve the canonical
configuration and pass paired-device lifecycle acceptance.

The correction passed the 3 focused Share/background architecture contracts,
formal Xcode 27.0 generic iOS Release build, strict signature verification,
paired iPhone 17 Pro Max installation, and normal app launch. The subsequent
physical UI test runner exited with code 74 before connecting, so no Photos
Share ran; automatic handoff and visible progress remain unverified. See
`2026-10-11-share-foreground-handoff-regression.md` for the incident record.
