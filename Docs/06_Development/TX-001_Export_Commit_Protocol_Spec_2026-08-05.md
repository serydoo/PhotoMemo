# TX-001 Export Commit Protocol Specification

Status: Accepted for Slice 1; production certification remains open

Date: 2026-08-05

Primary loop: Engineering Loop

Risk: P0 - duplicate Apple Photos output, ambiguous recovery, and false local
completion can affect user-visible output ownership.

## Objective

Define the transaction invariants that connect one durable `BatchTask` to at
most one logical Apple Photos output. This specification narrows the first
implementation slice to reconciliation of a persisted PhotoKit placeholder
receipt when the corresponding `PHAsset` is not yet visible.

This document does not close TX-001 or supersede the 2026-07-20 Production
Reliability Certification. Closure still requires failure-injection coverage
for every commit boundary and signed-device forced-termination evidence.

## Observed Engineering Evidence

The 2026-07-20 certification identified an interruption window between a
successful external PhotoKit commit and durable local task completion. The
repository subsequently added these protections:

- static and Live Photo batch saves use the stable `BatchTask.id` as the
  idempotency key;
- both save paths record the PhotoKit placeholder local identifier inside the
  `performChanges` transaction before it can complete;
- startup and retry use direct `PHAsset` lookup by that identifier instead of
  scanning the user's photo library;
- save receipts remain retained while their task IDs remain in the durable
  queue and are removed only after successful queue persistence.

One current divergence remains: Live Photo recovery preserves a recent receipt
when its asset is temporarily unavailable, while static recovery immediately
deletes that receipt and permits another save. A recent missing asset is an
unknown external outcome, not proof that PhotoKit did not commit.

## Ownership And Source Of Truth

- Apple Photos owns the external asset and its `PHAsset.localIdentifier`.
- `BatchTask.id` owns the stable logical export transaction identity.
- `PhotoLibrarySaveReceiptStore` owns the local mapping from transaction ID to
  PhotoKit placeholder identifier and receipt timestamp.
- `BatchQueuePersistence` owns durable queue state.
- static and Live Photo writers may query and reconcile these facts; they must
  not invent a second task identity or scan the complete Photos library.
- Renderer, Metadata Engine, Memory Engine, Layout Engine, Commerce, and Share
  intake are outside this transaction boundary.

## Apple-Native Capability Decision

PhotoKit provides the asset placeholder and local identifier inside
`PHPhotoLibrary.performChanges`. It does not provide a cross-store transaction
that atomically commits both PhotoKit state and MemoMark queue state. MemoMark
therefore needs a durable local receipt and recovery policy around the native
PhotoKit lifecycle.

Full-library filename scans are rejected because they add unbounded work,
require broader read behavior, and cannot prove logical task identity. Direct
lookup by the recorded local identifier remains the only accepted query path.

## Transaction Model

```text
Queued
-> Processing
-> SavingToPhotoLibrary
-> Placeholder Receipt Persisted
-> PhotoKit Outcome Pending
-> Asset Reconciled
-> Queue Commit Persisted
-> Completed
```

`Completed` is a local projection of a reconciled external asset. A task must
not become `completed` merely because a file was rendered or a PhotoKit request
was initiated.

## Invariants

1. One `BatchTask.id` identifies one logical Photos output across retries and
   process restarts.
2. Retry always reuses the same transaction ID.
3. A recorded asset identifier is queried directly before a new PhotoKit save.
4. A visible recorded asset is reused and no second asset is created.
5. A receipt whose asset is not visible is an unknown outcome. The receipt is
   retained and a new save is blocked until direct readback finds the exact
   recorded asset or signed-device evidence defines a safe negative-commit
   proof.
6. Receipt age alone must not discard a receipt or authorize a replacement
   save.
7. Static and Live Photo writers use the same receipt reconciliation decision.
8. Queue persistence failure must not remove a receipt needed by recovery.
9. Cancellation before external commit produces no output. Cancellation after
   a reconciled commit finalizes the task as committed, not cancelled.
10. Original media is never modified.

## Receipt Reconciliation Decision

| Recorded asset visible | Receipt age | Decision |
|---|---|---|
| Yes | Any | Reuse the committed asset |
| No | Within visibility window | Retain receipt and await visibility |
| No | Timestamp missing | Retain receipt and await recovery; external ownership is ambiguous |
| No | Outside visibility window | Retain receipt and await visibility; elapsed time is not negative-commit proof |

The former 30-second visibility assumption is superseded for all automatic
recovery decisions. A later signed-device study may define a narrowly-scoped
negative-commit proof, but no duration is a tuning constant that can currently
authorize another Photos write.

## Failure Policy

- `reuse committed asset`: return the recorded asset identity and continue
  local completion without creating another Photos asset.
- `await visibility`: fail retryably without deleting the receipt or creating
  another asset.
- `timestamp missing`: preserve the receipt and fail closed. A partial local
  receipt is not evidence that PhotoKit did not commit.
- `unresolved receipt`: keep the queue task in its saving/reconciliation state.
  It must not automatically rerender the source, discard the receipt, or issue
  another PhotoKit write.
- Receipt corruption, queue corruption, or persistence failure must fail
  closed and retain recoverable state where ownership is ambiguous.

## Slice 1

Implement one shared, deterministic receipt-reconciliation policy and adopt it
in the static and Live Photo direct-lookup paths. Serialize in-process PhotoKit
saves so concurrent retries cannot both pass receipt reconciliation before a
receipt is recorded.

Acceptance criteria:

- focused tests cover all three decisions;
- static and Live Photo source paths use the shared policy;
- a recent missing static asset no longer deletes its receipt or creates a
  second asset;
- a receipt with a missing timestamp fails closed rather than permitting a new
  output;
- static and Live Photo saves share one non-reentrant in-process gate;
- existing receipt lifecycle, batch recovery, Live Photo readback, full test,
  and target build evidence remains green.

## Remaining TX-001 Work

- injectable failure proof before save, during save, after external commit,
  before/after receipt persistence, and before queue completion persistence;
- signed-device evidence for interruption, delayed visibility, and the only
  conditions that could prove a recorded external commit did not occur;
- cancellation semantics across the PhotoKit acceptance boundary;
- receipt durability failure behavior;
- static asset readback contract after successful save;
- signed-device forced termination during static and Live Photo save windows;
- superseding Production Reliability Certification.

## Non-Goals

- changing Renderer, Layout Engine, Metadata, Memory, Commerce, or Share intake;
- scanning the complete photo library;
- changing batch limits or adding parallel workers;
- claiming TX-001, BP-001, or Production Certification closure;
- changing user-facing workflow or original-photo behavior.

## Verification

Focused tests:

```bash
xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj \
  -scheme PhotoMemoTests \
  -destination 'platform=macOS' \
  -only-testing:PhotoMemoTests/PhotoLibrarySaveReceiptStoreTests \
  test
```

Final automated gate:

- complete `PhotoMemoTests` suite;
- unsigned `PhotoMemo`, `PhotoMemoiOS`, `PhotoMemoShareExtension`, and
  `PhotoMemoWidgetExtension` builds;
- `git diff --check`.

Manual closure evidence remains pending and cannot be inferred from automated
tests or simulator builds.
