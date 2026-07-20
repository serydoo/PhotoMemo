# MemoMark V3 Production Reliability Certification

Date: 2026-07-20

Baseline: `f2b50833 Polish subject editor and add home feedback`

Product stage: `V3 Production Quality And Delivery`

## Purpose

This certification continues the Production Audit v2.0 work after the V3
configuration, media, responsibility-split, TestFlight, and signed-device
closures.

This is not a style audit. It evaluates whether the current production
pipeline can preserve correctness across interruption, retry, recovery,
memory pressure, cancellation, and future concurrency expansion.

The primary review questions are:

- Can PhotoKit output be committed exactly once?
- Can recovery distinguish committed work from uncommitted work?
- Is retry safe, bounded, and error-aware?
- Does cancellation propagate through import, render, export, and PhotoKit?
- Does `MediaMemoryBudget` control execution or only describe it?
- Are current module boundaries still holding after the V3 responsibility
  splits?

No production code was modified during this audit.

## Scope

The review covered:

1. Architecture boundary revalidation
2. SwiftUI and configuration-state concentration
3. Swift concurrency and Swift 6 migration readiness
4. Image decode, render, export, and peak-memory behavior
5. Batch queue persistence, retry, cancellation, and resume
6. Static-image and Live Photo PhotoKit save paths
7. Export Commit Protocol And Transaction Audit
8. Adaptive Scheduling Audit
9. Terminal State Audit

## Repository Baseline

Current code scale:

- production Swift files: `432`
- production Swift lines: `105,039`
- Swift test files: `180`
- Swift test lines: `56,299`

The largest production files remain:

- `PhotoMemoiOSV1View.swift`: `4,689` lines
- `MemorySubjectEditorView.swift`: `2,002` lines
- `ConfigurationCenteriOSView.swift`: `1,469` lines
- `PhotoMemoBackgroundStatusService.swift`: `1,441` lines
- `ConfigurationEditingState.swift`: `1,238` lines
- `BatchProcessing.swift`: `1,122` lines

Static concurrency indicators:

- `@MainActor` occurrences: `140`
- `Sendable` occurrences: `85`
- `nonisolated` occurrences: `321`
- production actors: `2`
- `autoreleasepool` occurrences: `0`
- `CIContext` construction sites: `1`

## Executive Verdict

Architecture boundary rating: **A**

Current functional delivery rating: **B+**

Current Production Certification verdict: **FAIL (Conditional)**

Based on the evidence collected during this audit, the current V3 architecture
is considered production-capable. The certification failure is currently
attributable to identified release-blocking reliability gaps affecting
transaction semantics and execution-resource validation, rather than evidence
of architectural instability.

This is not an architectural failure. It is a bounded release-blocking
reliability gap.

The certification failure is narrow but fundamental. The current PhotoKit save
flow has no durable, queryable commit protocol between successful external save
and local queue completion. A process termination in that window can cause
recovery to save the same output again.

The second production blocker is an Execution Budget Enforcement gap. The
current serial pipeline has no evidence of 20 tasks rendering concurrently.
However, `MediaMemoryBudget` does not yet drive scheduling policy, resource
quotas, or peak-memory enforcement, and the export pipeline can hold several
full-resolution buffers simultaneously. Certification is therefore withheld
for true 48MP, true RAW/ProRAW/DNG, long-running mixed-media workloads, and
future parallel-worker execution.

These are the two P0 certification blockers identified by this audit. The
remaining runtime certification work may reveal additional issues; this report
does not claim that the current evidence proves no other blocker exists.

## Release Gate

| Gate | Status | Evidence Basis |
|---|---|---|
| Architecture Boundary | PASS | Renderer, Memory Engine, persistence, and PhotoKit dependency directions remain intact |
| Functional Delivery | PASS | Current builds, focused tests, and retained 1.7 signed-device evidence |
| Reliability Contract | FAIL | Export commit, terminal-state, retry, cancellation, and checkpoint gaps remain |
| Transaction Correctness | FAIL | Exactly-once recovery cannot reconcile an ambiguous PhotoKit commit |
| Execution Budget Enforcement | FAIL | Budget values do not enforce scheduling policy or measured peak limits |
| Runtime Certification | Pending | TSan, ASan, Instruments, Memory Graph, true 48MP, and true RAW evidence remain open |

## What Remains Healthy

The core architecture boundaries continue to hold:

- Renderer does not read Repository, UserDefaults, or PhotoKit state.
- Memory Engine remains Foundation-only and does not depend on SwiftUI/UIKit.
- Photo metadata acquisition remains outside Share Extension expression logic.
- Configuration Library is the durable configuration aggregate.
- Batch work uses frozen configuration identity and revision.
- Share intake has a real 20-photo admission cap.
- Batch tasks have progress, failure, retry, resume, and diagnostic models.
- Static and Live Photo export have extensive file-level metadata and readback
  tests.

The evidence supports targeted reliability engineering. No reviewed boundary
failure indicates that a broad rewrite would close the identified blockers.

## Level A Findings

### A-01: Export Commit Protocol does not provide exactly-once semantics

Severity: **P0 Production Blocker**

Reliability dimensions: Duplicate, Recovery, Silent Wrong Output

Static-image execution persists `.savingToPhotoLibrary` before calling
PhotoKit:

- `Source/PhotoMemo/PhotoMemo/Services/BatchTaskProcessor.swift:227`
- `Source/PhotoMemo/PhotoMemo/Services/BatchTaskProcessor.swift:244`

The returned PhotoKit asset identifier is written only afterward, together
with `.completed`:

- `Source/PhotoMemo/PhotoMemo/Services/BatchTaskProcessor.swift:270`

Startup recovery converts every non-terminal task back to `.queued`:

- `Source/PhotoMemo/PhotoMemo/Services/BatchQueuePersistence.swift:104`
- `Source/PhotoMemo/PhotoMemo/Services/BatchQueuePersistence.swift:157`

Failure sequence:

```text
persist savingToPhotoLibrary
-> PhotoKit commits the new asset
-> process is terminated before completed is persisted
-> startup changes task back to queued
-> task renders and saves again
-> Apple Photos contains a duplicate output
```

`savedAssetIdentifier` cannot close this window because it is not available or
persisted until after the PhotoKit callback returns.

A receipt written only after PhotoKit success is also insufficient by itself;
the process can terminate between the external commit and local receipt write.
The transaction needs a pre-save durable intent plus a queryable idempotency
identity that can be reconciled against Apple Photos after restart.

Required Export Commit Protocol:

```text
Queued
-> Running
-> Durable Export Intent And Transaction ID
-> PhotoKit Accepted
-> Commit Persisted
-> Completed
```

`Commit Persisted` is the local commit point. Because a local commit log written
only after PhotoKit acceptance still has an interruption window, recovery also
needs a queryable idempotency identity that can reconcile the external PhotoKit
commit before retrying.

Recovery must be able to decide:

- committed externally and not finalized locally -> finalize without saving
- not committed -> retry safely
- outcome unknown -> reconcile before retry

Required regression evidence:

- PhotoKit succeeds, local receipt write fails, restart does not duplicate
- process terminates after PhotoKit commit and before completed persistence
- committed receipt with non-terminal task finalizes without another save
- static and Live Photo paths use the same transaction semantics
- signed-device forced termination during the save window produces one asset

### A-02: Execution Budget Enforcement is incomplete for high-cost media

Severity: **P0 Execution Budget Certification Blocker**

This is a certification gap, not proof that the current implementation is
already failing or that 20 tasks execute concurrently.

Blocked certification scope:

- true 48MP processing
- true RAW/ProRAW/DNG processing
- future multi-worker batch execution
- future video or AI media pipelines

`MediaMemoryBudget` defines concurrency values:

- `Source/PhotoMemo/PhotoMemo/Models/MediaAsset.swift:319`
- `Source/PhotoMemo/PhotoMemo/Models/MediaAsset.swift:330`
- `Source/PhotoMemo/PhotoMemo/Models/MediaAsset.swift:341`

Production usage is limited to progress language and diagnostics:

- `Source/PhotoMemo/PhotoMemo/Services/BatchTaskDiagnosticsRecorder.swift:49`
- `Source/PhotoMemo/PhotoMemo/Services/BatchQueueCoordinator.swift:135`

`BatchPipelinePolicy` also declares import, preview, export, and PhotoKit write
concurrency but has no production consumer:

- `Source/PhotoMemo/PhotoMemo/Models/BatchProcessing.swift:176`

Current execution is hard-coded serial:

- queue tasks: `Source/PhotoMemo/PhotoMemo/Services/BatchQueueCoordinator.swift:127`
- Share providers: `Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionIntakeService.swift:334`

Current Batch Pipeline execution is serial. No evidence was found of
multi-task concurrent rendering causing the current memory peak.

`MediaMemoryBudget` currently provides classification, diagnostics, and user
feedback. It does not drive worker count, resource quotas, concurrency limits,
or adaptive scheduling. Therefore it is not yet Memory Budget Enforcement.

The actual risks are:

1. no adaptive scheduling contract exists for future concurrency;
2. the budget does not constrain peak memory inside one task;
3. a 48MP task can retain multiple full-resolution buffers at once.

The export pipeline holds the SwiftUI-rendered image and decodes a source image:

- `Source/PhotoMemo/PhotoMemo/Services/RecordCardExportPipeline.swift:53`
- `Source/PhotoMemo/PhotoMemo/Services/RecordCardExportPipeline.swift:62`

The artifact guard then allocates full-canvas RGBA byte arrays twice:

- `Source/PhotoMemo/PhotoMemo/Services/PhotoMemoRenderedImageArtifactGuard.swift:19`
- `Source/PhotoMemo/PhotoMemo/Services/PhotoMemoRenderedImageArtifactGuard.swift:148`

At 8064 x 6048, one RGBA buffer is approximately `195 MB` before allocator,
image-provider, SwiftUI renderer, source image, output bar, and ImageIO overhead.
The current path can overlap several such buffers and has no autorelease pool or
measured peak-memory gate.

Required closure order:

1. enforce a single-task peak-memory contract before adding workers;
2. make memory tier select concrete stage permits;
3. reuse or bound expensive contexts and image buffers;
4. add worker pools only after measured single-task closure;
5. certify with Instruments and Jetsam evidence on target devices.

## Level B Findings

### B-01: State Machine Integrity Violation — terminal state is mutable

Severity: **P1 Release Reliability**

The valid terminal states are:

```text
Completed
Failed
Cancelled
```

Once entered, a terminal state must be immutable unless an explicit new retry
attempt creates a new execution transition.

Terminal state must be immutable by construction, rather than by caller
discipline.

The static save path violates this invariant. If cancellation occurs while
awaiting PhotoKit, the task becomes `.cancelled`; when PhotoKit returns, the
completion path does not re-check terminal state and overwrites the task as
`.completed`:

- `Source/PhotoMemo/PhotoMemo/Services/BatchTaskProcessor.swift:244`
- `Source/PhotoMemo/PhotoMemo/Services/BatchTaskProcessor.swift:270`

Observed illegal transition:

```text
Running
-> Cancelled
-> Completed
```

This is broader than cancellation behavior. Retry, recovery, resume, and user
status all depend on terminal-state immutability.

### B-02: Cancellation does not propagate through the pipeline

Severity: **P1**

`cancelJob` changes model state and deletes managed sources, but does not cancel
the active processing task:

- `Source/PhotoMemo/PhotoMemo/Services/BatchQueueCoordinator.swift:104`
- `Source/PhotoMemo/PhotoMemo/Services/BatchQueueStore.swift:219`

The processing chain contains no `Task.checkCancellation()` and no cancellation
handler.

Live Photo processing checks terminal state after its processor returns, but
PhotoKit may already have saved the asset. The task can therefore remain
`.cancelled` while Apple Photos contains a new output.

Required closure:

- one cancellation token/Task identity per active task
- cancellation checks before and after every stage boundary
- explicit semantics once PhotoKit commit begins
- no immediate deletion of a source still in use
- tests for cancellation during import, render, static save, and Live Photo save

### B-03: Export retry is manual-only, unbounded, and not error-aware

Severity: **P1**

Current retry maturity:

| Capability | Current State |
|---|---|
| Manual Retry | Yes |
| Automatic Retry Policy | No |
| Retry Classification | No |
| Retry Budget | No |
| Exponential Backoff | No |
| Idempotency Token | No |
| Ambiguous Commit Reconciliation | No |

Manual retry resets failed tasks and increments `retryCount`:

- `Source/PhotoMemo/PhotoMemo/Services/BatchQueueCoordinator.swift:77`

There is no:

- automatic retry policy
- exponential backoff
- maximum attempt count
- transient/permanent PhotoKit error classification
- idempotency key
- committed-output reconciliation

`BatchTaskFailurePolicy` classifies only import errors. Other errors, including
authorization, missing album, PhotoKit transaction failure, and media export
failure, collapse into `.processingFailure`:

- `Source/PhotoMemo/PhotoMemo/Services/BatchTaskFailurePolicy.swift:6`

Automatic retry before transaction idempotency would increase duplicate-output
probability. A-01 must therefore close before an automatic retry policy is
introduced.

Recommended policy:

- permanent: authorization denied, unsupported input, invalid configuration
- recoverable after user action: missing album, unavailable iCloud resource
- transient: bounded PhotoKit/AV/File I/O failures with jittered backoff
- ambiguous commit: reconcile, never blind retry

### B-04: Checkpoint Recovery Gap during execution interruption

Severity: **P1**

The current concrete evidence is the iOS expiration handler, which only ends
the UIKit background task:

- `Source/PhotoMemo/PhotoMemo/iOS/App/PhotoMemoiOSBackgroundExecutionService.swift:70`

It does not:

- cancel active processing
- record an interruption checkpoint
- prevent entry into a new heavy stage
- distinguish safe retry from ambiguous PhotoKit commit

The missing checkpoint contract is platform-independent even though the current
evidence comes from iOS. It amplifies A-01 and B-01.

### B-05: Heavy import and export work remains MainActor-bound

Severity: **P1**

The current product is not a continuously interactive browser or editor, so
MainActor usage outside the media path is not the leading production risk.
The relevant problem is narrow: CPU and allocation-heavy media stages share the
UI actor.

Evidence:

- all targets use `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`
- queue loop starts with `Task { @MainActor in ... }`
- `BatchTaskProcessor`, `RecordCardExportService`, and
  `RecordCardExportPipeline` are MainActor-isolated
- static import calls `PhotoImportService.importPhoto`, which synchronously
  enters decode before its first suspension
- ImageRenderer, ImageIO source decode, artifact replacement, and final write
  execute synchronously in the export pipeline

This should be addressed after transaction correctness and peak-memory control.

### B-06: Queue persistence failures are not propagated by BatchQueueStore

Severity: **P1 Reliability Improvement**

`BatchQueuePersistence.persistJobs` returns a typed failure, but
`BatchQueueStore.persistJobs` ignores it:

- `Source/PhotoMemo/PhotoMemo/Services/BatchQueuePersistence.swift:184`
- `Source/PhotoMemo/PhotoMemo/Services/BatchQueueStore.swift:341`

Loading also converts backend or decoding failure into an empty queue:

- `Source/PhotoMemo/PhotoMemo/Services/BatchQueuePersistence.swift:85`

The diagnostics surface can report a corrupt shared queue payload, but the
runtime store has no last-known-good queue, raw-payload preservation, or write
failure state transition. This weakens resume guarantees.

### B-07: Swift 6 strict-concurrency migration is not yet clean

Severity: **P1 Engineering Readiness**

The project currently compiles in Swift 5 language mode while enabling
Approachable Concurrency and MainActor default isolation.

An isolated audit build with:

```text
SWIFT_VERSION=6
SWIFT_STRICT_CONCURRENCY=complete
```

fails first at:

- `Source/PhotoMemo/PhotoMemo/Models/PhotoProcessingInputPolicy.swift:30`

Error:

```text
main actor-isolated default value in a nonisolated context
```

The probe stops at the first module error, so it does not establish the total
migration count. Swift 6 conversion should be a dedicated slice after the
processing-actor boundary is explicit.

## Level C Findings

### C-01: Managed-intake containment checks are inconsistent

Severity: **P2**

`IntakeCleanupService` correctly checks `root` or `root + "/"`, but three batch
helpers use raw string prefix checks:

- `Source/PhotoMemo/PhotoMemo/Services/BatchQueuePersistence.swift:239`
- `Source/PhotoMemo/PhotoMemo/Services/BatchTaskFailurePolicy.swift:65`
- `Source/PhotoMemo/PhotoMemo/Services/BatchTaskResourceLifecycle.swift:61`

A sibling such as `ExternalIntake-Originals` is therefore misclassified as a
managed descendant. This can incorrectly mark an external missing source as
non-retryable during recovery.

### C-02: The iOS root coordinator remains a high-change concentration point

Severity: **P2 Architecture Improvement**

The V3 responsibility splits reduced several service and controller files, but
`PhotoMemoiOSV1View.swift` is now `4,689` lines and still contains approximately
`224` state, computed-property, and function declarations.

It owns `ConfigurationSession` plus mirrored draft, output, album, Logo,
diagnostics, local-backup, processing-picker, save, and presentation state.
This is not a release blocker, but it remains the most likely source of future
state-synchronization regressions.

## Module 7: Export Commit Protocol And Transaction Audit

### Current transaction model

```text
Queued
-> Importing
-> Exporting
-> SavingToPhotoLibrary
-> PhotoKit Commit
-> Completed + Asset Identifier Persistence
```

### Required commit model

```text
Queued
-> Running
-> Durable Export Intent And Transaction ID
-> PhotoKit Accepted
-> Commit Persisted
-> Completed
```

### Commit invariants

1. One task ID produces at most one logical Apple Photos output.
2. Recovery never blind-retries an ambiguous external commit.
3. A durable commit log can finalize an interrupted local state transition.
4. Retry reuses the transaction identity instead of creating a new identity.
5. Static image and Live Photo paths share the same commit semantics.
6. Cancellation before commit produces no output; cancellation after commit
   finalizes as committed, not cancelled.

### Recommended first implementation slice

Create a transaction specification and failure-injection tests before changing
PhotoKit code. The test seam must simulate process death or persistence failure
at every boundary:

- before save
- during save
- after external commit
- before receipt write
- after receipt write
- before completed projection

## Module 8: Adaptive Scheduling Audit

### Current behavior

- Share Extension imports providers sequentially.
- Batch Queue processes one task at a time.
- PhotoKit writes are effectively single-lane.
- No worker pool, semaphore, task group, or adaptive scheduler exists.
- `MediaMemoryBudget` concurrency values are diagnostic-only and do not drive a
  scheduling policy.
- `CIContext` is created per RAW Core Image fallback and is not pooled.
- no `autoreleasepool` boundaries exist in the production media path.

### Correct next direction

Do not begin by increasing worker count.

The safe order is:

```text
Measure single-task peak
-> reduce duplicate full-resolution buffers
-> define stage permits
-> make MemoryBudget enforce permits
-> add bounded workers
-> adapt by device and media tier
```

Suggested execution boundaries:

- import/decode permit
- render permit
- metadata/write permit
- PhotoKit commit permit
- Live Photo AV composition permit

The scheduler should choose permits from media tier and current in-flight
estimated bytes, not only from photo count.

## Module 9: Terminal State Audit

Terminal-state rules:

```text
Completed -> immutable
Failed -> immutable until explicit retry begins a new attempt
Cancelled -> immutable
```

Forbidden transitions:

```text
Completed -> Cancelled
Cancelled -> Completed
Failed -> Completed
Completed -> Failed
```

Current result:

- `.cancelled -> .completed` is possible in the static PhotoKit save path.
- retry explicitly moves eligible `.failed -> .queued`, but the model does not
  record an attempt identity, so the new attempt is not separated from the old
  state machine.
- no central transition validator rejects illegal terminal-state mutation.

Required closure:

- one transition function owns legal phase changes
- terminal states reject ordinary mutation
- retry creates or increments an execution-attempt identity
- tests cover every terminal state against every later event

## Runtime Certification Additions

Future Production Certification should add:

- Instruments Time Profiler
- Instruments Allocations and peak resident memory
- Main Thread Checker / hang evidence
- Thread Sanitizer on deterministic non-PhotoKit suites
- Address Sanitizer on import/render/export fixtures
- Memory Graph for long-lived Configuration and queue sessions
- signed-device background-expiration interruption
- signed-device forced termination during PhotoKit commit
- true 48MP and true RAW/ProRAW/DNG inputs
- static and Live Photo PhotoKit save/readback including creation date,
  location, resource filenames, and playback

Sanitizers are supporting evidence, not substitutes for the transaction and
memory contracts.

These items validate implementation behavior. They do not establish
transaction correctness.

## Verification Performed

Passed:

- unsigned macOS `PhotoMemo` Debug build
- iOS Simulator `PhotoMemoiOS` Debug build, run serially
- iOS Simulator `PhotoMemoShareExtension` Debug build, run serially
- focused `PhotoMemoTests` suites:
  - `BatchQueueStorePersistenceTests`
  - `BatchQueueRecoveryTests`
  - `MediaMemoryBudgetTests`
- 13 focused tests passed
- `git diff --check`

Expected diagnostic failure:

- Swift 6 strict-concurrency probe failed at
  `PhotoProcessingInputPolicy.standard`

Not performed in this audit:

- Thread Sanitizer
- Address Sanitizer
- Instruments
- Memory Graph
- forced process termination during PhotoKit save
- real 48MP or true RAW/ProRAW/DNG processing
- new signed-device PhotoKit location/readback certification

Recent repository evidence for 1.7 functional delivery remains valid, but it
does not close the newly identified exactly-once transaction window.

## Deferred Improvements (Non-blocking)

These improvements remain valuable but do not determine the current release
decision:

- broader MainActor reduction outside the media hot path
- wider Sendable coverage
- additional actor decomposition
- Renderer micro-optimization without a measured bottleneck
- SwiftUI root-state and coordinator simplification
- provider and service protocol expansion where tests need a seam

They should not delay a release after the two P0 certification blockers are
closed unless new runtime evidence promotes one of them.

## Priority Order

| Priority | Work | Release Meaning |
|---|---|---|
| P0 | Export Commit Protocol / idempotency / commit reconciliation | Required for Production Certification |
| P0 | Execution Budget Enforcement / adaptive scheduling / peak-memory evidence | Required for 48MP/RAW and future workers |
| P1 | Terminal State Integrity | Required for trustworthy queue state |
| P1 | Cancellation propagation and post-save semantics | Required for reliable user cancellation |
| P1 | Error-aware bounded retry with backoff | Must follow idempotency closure |
| P1 | Background expiration checkpointing | Required for safe interruption recovery |
| P1 | Move media-heavy work off MainActor | Performance hardening after correctness |
| P2 | Sanitizers, Instruments, and Memory Graph certification | Release evidence expansion |

## Recommended Next Two Engineering Slices

### Slice 1: TX-001 Export Commit Protocol Specification And Failure Tests

Deliverables:

- durable export intent and commit-log state model
- queryable idempotency identity decision
- static/Live Photo shared receipt contract
- recovery state machine
- failure-injection tests for every commit boundary

No production behavior should change until the transaction invariants are
reviewed and frozen.

No feature work should precede TX-001.

### Slice 2: BP-001 Enforced Single-Task Memory Contract

Deliverables:

- measured allocation map for import/render/artifact/write stages
- reduced full-canvas buffer duplication
- production stage permits selected by `MediaMemoryBudget`
- reusable/bounded Core Image context policy
- 48MP device peak-memory and Jetsam evidence

Worker-pool expansion should remain deferred until this slice passes.

## Final Assessment

MemoMark has entered reliability engineering rather than feature engineering.
The reviewed module boundaries support focused production hardening.

Closing A-01 and A-02 would materially change the readiness level. No evidence
collected during this audit suggests that another architectural redesign would
resolve the identified release blockers. After those two items, the remaining
known work is primarily state-machine hardening, cancellation, retry policy,
runtime evidence, and long-term maintainability rather than foundational
architecture repair.
