# Share foreground handoff regression — 2026-10-11

> Superseded for the ordinary production route by the owner's later explicit
> background requirement and the current canonical frozen-snapshot publication.
> See `2026-10-11-share-background-route-closure.md` for the new route and evidence.
> This document preserves the earlier observed scenario and checkpoint.


## Decision record before implementation

- **Observed scenario:** A Photos Share reaches MemoMark, reports a task failure, and returning to the main app shows no active progress. The owner explicitly requests the established foreground route: Share opens MemoMark, the app admits the durable request and shows its own progress.
- **Direct regression evidence:** `ShareExtensionIntakeCoordinator` now returns `.received` immediately after successful iOS 26+ `ShareContinuedProcessingAdapter.submit`, so `MemoMarkShareExtensionViewController` completes the extension without opening the app. The Dynamic Island/system task failure shown by the owner is consistent with that worker owning the operation while the app has no live queue presentation.
- **Confirmed worker incompatibility:** The 2026-10-10 physical QA follow-up records `missingCanonicalSnapshot` / `admissionRejected`. `SharedBatchConfigurationSnapshotService` builds an extension transport snapshot without the app-only canonical production snapshot. The foreground app's `ShareCoordinator` resolves the durable `ProductionConfigurationReference` through `ConfigurationRepository` and can construct the canonical snapshot; the extension worker directly admits the incomplete transport snapshot and cannot perform that resolution.
- **Bounded outcome:** After durable intake and the existing BGProcessing recovery submission, request host-app handoff on every Share. Keep the durable request and actionable handoff-failure UI when host opening fails. Do not select the extension-owned Continued Processing worker as the ordinary production route until canonical snapshot resolution and signed-device lifecycle acceptance pass.
- **Owner / risk / loop:** Share Extension owns intake and handoff; main app `ShareCoordinator` owns durable configuration resolution/admission and in-app progress. Engineering Loop; P1 primary workflow/lifecycle regression.
- **Source of truth:** `Docs/03_Engineering/2026-10-10-release-share-continued-processing.md`, `ShareExtensionIntakeCoordinator`, `SharedBatchConfigurationSnapshotService`, `ShareCoordinator.resolvedConfiguration`, and the persisted request/queue contracts.
- **Apple capability evaluated:** Continue using `NSExtensionContext.open` deep-link handoff for foreground continuation, with the existing `BGProcessingTask` only as durable system recovery. This matches the requested Apple Photos → Share → MemoMark → Processing → Notification → Apple Photos loop.
- **Verification:** Add a regression contract that host-app handoff follows every persisted Share regardless of BGProcessing scheduling outcome and that production intake does not submit Continued Processing. Run focused Share/processing tests and Xcode 27.0 Release build, install/launch on the paired physical iPhone 17 Pro Max, then perform a Photos Share round if the device QA state can be safely isolated. Do not clear existing App Group or Photos QA state to manufacture a clean run.

## Implementation and evidence

- `ShareExtensionIntakeCoordinator` still persists the Share request and
  schedules the existing BGProcessing recovery request, but now always requests
  `MemoMarkDeepLink.share` handoff. A failed handoff returns the existing
  actionable `.handoffFailed` state while leaving the durable request intact.
  The ordinary Release path no longer submits the extension-owned Continued
  Processing worker; its isolated DEBUG marker probe remains DEBUG-only.
- The main app's existing `MemoMarkRootSceneView.onOpenURL` refresh path drains
  the durable intake. `ShareCoordinator` remains the owner that resolves the
  canonical production configuration and queue admission, which also restores
  the Home activity/progress presentation.
- Updated the Share architecture contracts. Focused
  `BackgroundProcessingContractTests`: 3 passed, 0 failed. The Release
  `MemoMarkiOS` generic iOS build passed with formal Xcode 27.0. The signed
  Release app passed strict code-signature verification, installed over the
  existing app on the paired iPhone 17 Pro Max, and launched normally as
  2.3.6 (124).
- The physical Release UI test was attempted on the paired iPhone 17 Pro Max
  (iOS 27.2 Beta), but `MemoMarkDeviceQA-Runner` exited with code 74 before
  establishing its test connection. No test case ran and no Photos Share was
  initiated. Therefore automatic Share-to-app handoff and visible progress
  remain unverified on-device; the successful install/launch is not evidence of
  Share acceptance. No QA album or existing App Group request was cleared.
- Final `git diff --check` passed. The touched coordinator, handoff lifecycle,
  root-scene URL drain, focused architecture contracts, and current regression
  test changes were reviewed together. No original Photos item, purchase,
  GitHub, TestFlight, or App Store state was changed.
