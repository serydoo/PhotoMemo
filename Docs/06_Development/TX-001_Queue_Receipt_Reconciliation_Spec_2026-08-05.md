# TX-001 Queue Receipt Reconciliation Specification

Status: Accepted for Slice 2; TX-001 and production certification remain open

Date: 2026-08-05

Primary loop: Engineering Loop

Risk: P0 - a committed Apple Photos asset can be rerendered and saved again if
the process stops before the durable queue records task completion.

## Observed Evidence

`BatchTaskProcessor` persists `.savingToPhotoLibrary` before requesting the
PhotoKit write, then records the returned asset identifier and `.completed`
afterward. The save writers record the PhotoKit placeholder identifier in the
receipt store within `performChanges`.

Before this amendment, `BatchQueuePersistence.normalizeJobsForResume` turned
every non-terminal task back into `.queued` after startup reconciliation. A
receipt-backed `.savingToPhotoLibrary` task whose exact asset was not yet
visible therefore rerendered and attempted another save on the next start.
That behavior treated an ambiguous external outcome as a local failure.

## Objective

Before general resume normalization, reconcile only persisted tasks whose phase
is `.savingToPhotoLibrary`:

```text
durable BatchTask.id
-> durable PhotoKit placeholder receipt
-> direct PHAsset.localIdentifier lookup
-> visible asset
-> durable BatchTask.completed
```

The queue must treat a visible matching asset as committed output and finish the
local projection without rendering or issuing another Photos save.

## Invariants

1. Only `.savingToPhotoLibrary` tasks are eligible for startup receipt
   reconciliation.
2. The stable `BatchTask.id.uuidString` remains the only receipt key.
3. A result is trusted only when a receipt exists and direct lookup by its
   recorded `PHAsset.localIdentifier` finds a visible asset.
4. No filename, capture-date, album-wide, or complete-library scan is allowed.
5. A visible asset changes the task to `.completed`, records that same local
   identifier, clears the transient rendered-file reference, and persists the
   queue before terminal resource cleanup.
6. A missing or ambiguous asset keeps a receipt-backed task in
   `.savingToPhotoLibrary`, retains its receipt and any already-persisted
   recoverable rendered/source references, and does not rerender or issue
   another Photos write.
7. Later foreground or background resume attempts may repeat only the same
   direct local-identifier lookup. They complete the task only after the exact
   receipt-backed asset becomes visible.
8. The reconciliation must not add a second transaction identity or modify the
   original media.

## Scope

Add an injectable, direct-local-identifier asset locator and a startup
reconciliation pass in `BatchQueueStore`, invoked before
`normalizeJobsForResume`. The generic normalizer receives the remaining
receipt-backed saving task identities as protected tasks and leaves them in
their reconciliation state. `startProcessingIfNeeded()` repeats the same
reconciliation before it selects queued work, so a later Photos readback can
finalize the task without a process restart.

The pass may update the existing Free allowance ledger through the established
terminal-task transition, but it must not rerender media, create a notification
attachment, or perform a new Photos write.

## Verification

- red/green test for a persisted `.savingToPhotoLibrary` task with a visible
  receipt-backed asset: startup yields durable `.completed` and preserves the
  recorded local identifier;
- test that a missing receipt-backed asset remains durably
  `.savingToPhotoLibrary`, retains its receipt and any existing recoverable
  file references, and is not selected for automatic processing;
- test that a later exact readback completes that protected task without
  requeueing, rendering, or a new Photos save;
- source contract proving direct local-identifier lookup only;
- existing receipt, queue-persistence, queue-recovery, diagnostic, and complete
  test coverage remains green;
- unsigned app, iOS app, Share Extension, and Widget Extension builds pass.

## Non-Goals

- deciding whether any future signed-device evidence can prove that an absent
  receipt-backed asset was never committed;
- forced termination during receipt writes;
- final static-asset readback validation;
- cancellation semantics after PhotoKit acceptance;
- changing rendering, layout, Memory Engine, Share intake, or original-media
  behavior;
- closing TX-001 or changing the V3 certification verdict.
