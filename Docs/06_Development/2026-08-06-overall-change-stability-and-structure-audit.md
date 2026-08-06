# Overall Change Stability And Structure Audit

Date: 2026-08-06

Status: Implemented And Automatically Verified; Physical Acceptance Pending

Primary loop: Engineering Loop

Risk: P0 for PhotoKit external-commit ownership; P1 for recovery, memory truth,
accessibility, and compatibility behavior; P2 for structure and documentation
consistency.

## Observed Evidence

The working tree has grown across PhotoKit recovery, birthday-day expression,
Configuration Center presentation, appearance, Photo Description, tests, and
release records. Automated builds and tests pass, but a read-only review found
failure paths and source-of-truth conflicts that are not covered by the current
suite:

- a receipt-backed Photos asset that is temporarily inaccessible can be treated
  as absent after a fixed timeout and saved again;
- a queued PhotoKit save does not honor cancellation before it acquires the
  shared save gate;
- a readback-pending retry becomes terminal failure instead of remaining
  recoverable;
- startup receipt reconciliation clears file references without performing
  post-persistence resource cleanup;
- receipt identifier and timestamp are stored as separate values and can tear;
- compatibility anchor metrics mix calendar-day components with cumulative
  sub-day components;
- Photo Description composition differs between the Configuration Session and
  the production build path;
- some localized titles are passed through runtime `String` values without
  localization lookup, and the new Photo Description control has Dynamic Type
  and Reduce Motion gaps.

## Accepted Product Semantics

1. Time-anchor day relationships use calendar-day boundaries. Crossing local
   midnight enters the next day even when fewer than 24 hours have elapsed.
2. Birthday anchor-day wording remains the dedicated birth-day expression.
3. Photo Description starts with the complete resolved Memory Expression from
   the right-bottom smart region.
4. When custom Photo Description text is enabled, that text supplements the
   complete Memory Expression on the next line. Both values are trimmed before
   joining, neither value is silently rewritten, and no persistence migration
   is required.

## Ownership And Source-Of-Truth Impact

- Apple Photos remains the external asset owner.
- `BatchTask.id` remains the stable logical save identity.
- `PhotoLibrarySaveReceiptStore` remains the local receipt owner, but one
  receipt must be read and written as one value.
- `BatchQueueStore` remains the stable public batch facade under ADR-002.
- Startup reconciliation may coordinate task projection and cleanup, but it
  must persist terminal state before deleting recoverable files.
- Calendar-day relationship remains Memory Engine behavior. Renderer and Layout
  Engine remain unchanged.
- One shared Photo Description composer must serve preview, Configuration
  Session, and production output. SwiftUI must not become a second composer.
- SwiftUI surfaces continue to own presentation only; localization and
  accessibility fixes must not create new configuration state.

## Apple-Native Capabilities Evaluated

- `PHAssetCreationRequest.placeholderForCreatedAsset` supplies the exact local
  identifier but does not create a transaction with MemoMark persistence.
- `PHAsset.fetchAssets(withLocalIdentifiers:)` proves visibility only; a nil
  fetch does not prove non-commit when Photos access is limited or changing.
- Swift task cancellation must be rechecked after waiting for serialized access
  and before `PHPhotoLibrary.performChanges` begins.
- SwiftUI semantic localization, Dynamic Type, and
  `accessibilityReduceMotion` remain the accepted native mechanisms.

## Failure Policy

- An existing receipt with a non-visible asset fails closed. Time alone must not
  authorize another Photos write. Startup and later queue wakeups keep that
  task in `.savingToPhotoLibrary`, retain its receipt and any already-persisted
  recoverable files, and repeat only direct exact-identifier readback.
- A cancelled waiter must leave the save gate without running its operation.
- Readback pending remains a recoverable `.savingToPhotoLibrary` projection;
  it must not be persisted as terminal failure.
- Receipt-backed startup completion persists first, then cleans rendered output
  and managed intake copies. Cleanup remains idempotent.
- Legacy receipt values remain readable during migration; new receipts use one
  encoded value to avoid identifier/timestamp tearing.

## Bounded Implementation Plan

1. Add failing receipt-policy, cancellation, queue-recovery, and file-backed
   cleanup tests.
2. Repair PhotoKit receipt, save-gate, readback-pending, diagnostic, and startup
   cleanup behavior without changing the public queue boundary.
3. Add calendar-day compatibility tests and keep sub-day fields bounded rather
   than cumulative across years or months.
4. Establish one Photo Description composition contract and update preview,
   Configuration Session, production build, copy, and tests together.
5. Fix the confirmed localization, Dynamic Type, and Reduce Motion gaps without
   changing the accepted card layout.
6. Update the accepted specifications, language guide, status chronicle, and
   three release-note audiences.
7. Run focused tests after each slice, then the complete suite, localization
   validation, `git diff --check`, unsigned build, signed-device build, and an
   overwrite installation on the paired iPhone 15 Pro. Do not use a simulator.

## Structure Audit Standard

Historical MemoMark decomposition treats line count as a signal, not a target.
A next split requires at least one concrete boundary:

- multiple independent side-effect owners in one file;
- mutable source-of-truth duplication;
- domain behavior implemented in a SwiftUI surface;
- a public facade absorbing an independently testable policy or lifecycle;
- unrelated presentation surfaces sharing one compile unit;
- tests so broad that one suite no longer communicates one contract.

The preferred extraction keeps the parent owner stable, passes resolved values
or explicit intents, introduces no parallel session, and proves behavior before
and after the move. Structure work must remain separate from product or
transaction behavior changes unless extraction is required to restore one
canonical source of truth.

## Initial Split Candidates

- `PhotoLibraryExportService.swift`: save serialization, receipt persistence,
  reconciliation policy, album operations, static asset writing, and readback
  are independent testable responsibilities in one source file.
- `BatchQueueStore.swift`: retain the ADR-002 facade, but startup receipt
  reconciliation is a candidate focused collaborator after TX-001 behavior is
  stable.
- Photo Description composition: move the canonical pure composer out of the
  iOS view source so Configuration Session and production output do not depend
  on presentation code.
- Large SwiftUI sources such as `MemorySubjectEditorView.swift`,
  `V1SettingsPageSurface.swift`, and `V1ConfigurationOptionList.swift` require a
  responsibility map before extraction; line count alone does not authorize a
  split.

## Non-Goals

- no Renderer, Layout Engine, Metadata extraction, original-photo, Share intake,
  commerce, or durable configuration redesign;
- no new workspace, generic session, or parallel queue public API;
- no broad visual redesign or speculative abstraction;
- no production-certification claim. TX-001, BP-001, and the historical
  `FAIL (Conditional)` verdict remain open until superseding evidence exists.

## Completion Evidence

- The TX-001 follow-up regression suite proves a missing receipt-backed asset
  remains out of the queued rendering path at automatic startup, and that a
  later exact receipt-backed readback completes the existing task without a
  replacement PhotoKit write. This closes the identified queue-normalization
  loop only; it does not provide signed-device interruption or delayed-
  visibility evidence.
- Focused red/green coverage confirmed the newline-separated Photo Description
  contract across Configuration Session, iOS preview, production Memory Module,
  Expression Context, and final output. Existing legacy
  `photoDescriptionOverride` compatibility tests remain green.
- The complete `PhotoMemoTests` run contains `1,303` tests: `1,302` passed,
  `1` existing platform-conditional test was skipped, and `0` failed.
- Simplified Chinese and English localization resources pass `plutil -lint`,
  contain `618` symmetric keys each, and contain no duplicate keys.
- `git diff --check`, the required unsigned `PhotoMemo` Debug build, the
  unsigned generic-iOS `PhotoMemoiOS` build, and the signed iPhone Debug build
  pass. Main app, Share Extension, and Widget Extension signatures satisfy
  strict verification for `2.0.2 (69)`.
- The signed app was overwrite-installed on the paired `IPhone5` iPhone 15 Pro
  without uninstalling or clearing local data and launched successfully after
  the device was unlocked. No simulator was started or used; final
  physical-device visual, Dynamic Type, VoiceOver, Reduce Motion, appearance,
  and Apple Photos acceptance remain with the product owner.
- `TX-001`, `BP-001`, the final release version/build lock, and a superseding
  production certification remain open. This evidence does not replace the
  current `FAIL (Conditional)` verdict.
