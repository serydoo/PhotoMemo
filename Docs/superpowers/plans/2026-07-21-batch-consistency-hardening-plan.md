# Batch Consistency Hardening Implementation Plan

> **For agentic workers:** Use the incremental implementation and test-driven development skills while executing this plan.

**Goal:** Make batch processing, Share handoff, PhotoKit saving, cancellation, and recovery safe across crashes, concurrent processes, and persistence failures.

**Architecture:** Keep `BatchQueueStore` and processing on `@MainActor`. Make shared Share requests single-writer through a lock-backed transaction file, retain requests until enqueue succeeds, and surface queue corruption instead of converting it to an empty queue. Add a stable task save identity and recovery reconciliation so a PhotoKit side effect is not repeated after a crash; use a processing lease so cancellation cannot delete an in-use source.

**Tech Stack:** Swift 5, Swift Concurrency, Swift Testing, Foundation, Photos, UserDefaults shared app group.

---

### Task 1: Expose queue persistence failures

**Files:**
- Modify: `Source/PhotoMemo/PhotoMemo/Services/BatchQueuePersistence.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/Services/BatchQueueStore.swift`
- Test: `Tests/PhotoMemoTests/BatchTests/BatchQueueStorePersistenceTests.swift`

- [x] Add failing tests for corrupted queue startup and a failed persistence write being retained in diagnostics.
- [x] Make queue loading return an explicit result with raw payload context.
- [x] Keep corrupted jobs out of automatic processing and expose the startup error through `BatchQueueStore`.
- [x] Make every queue persistence call handle its result without silently discarding it.
- [x] Run the focused queue persistence and recovery tests.

### Task 2: Make Share handoff transactional

**Files:**
- Modify: `Source/PhotoMemo/PhotoMemo/App/ExternalIntakeRequestStore.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/App/ExternalPhotoIntakeStore.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/App/ExternalPhotoIntakeCenter.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/App/PhotoMemoAppRuntime.swift`
- Test: `Tests/PhotoMemoTests/BatchTests/ExternalPhotoIntakeStoreDiagnosticsTests.swift`
- Test: `Tests/PhotoMemoTests/BatchTests/ExternalPhotoIntakeCenterTests.swift`

- [x] Add failing tests proving failed enqueue retains the request and concurrent append/drain preserves every request.
- [x] Introduce a lock-scoped read/modify/write transaction for the shared request payload.
- [x] Return drained requests with an acknowledgment token rather than clearing them before processing.
- [x] Acknowledge each request only after successful enqueue or an explicit terminal drop decision.
- [x] Run focused Share handoff tests.

### Task 3: Add idempotent PhotoKit save identity

**Files:**
- Modify: `Source/PhotoMemo/PhotoMemo/Models/BatchProcessing.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/Services/BatchTaskProcessor.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/Services/PhotoLibraryExportService.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/MediaPipelineVNext/PhotoKitLivePhotoAssetWriter.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/Services/LivePhotoBatchTaskProcessor.swift`
- Test: `Tests/PhotoMemoTests/BatchTests/BatchQueueExecutionContractTests.swift`
- Test: `Tests/PhotoMemoTests/ArchitectureTests/LivePhotoAssetWriterContractTests.swift`

- [x] Add failing tests for stable save identities surviving encoding and retry.
- [x] Pass a task-scoped save identity through still-image and Live Photo save requests.
- [x] Reconcile an existing matching PhotoKit resource before creating a new asset.
- [x] Persist the save-intent state before the external write and reconcile it on restart.
- [x] Run focused static and Live Photo queue tests.

### Task 4: Make cancellation lease-aware

**Files:**
- Modify: `Source/PhotoMemo/PhotoMemo/Services/BatchQueueCoordinator.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/Services/BatchTaskProcessor.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/Services/BatchTaskResourceLifecycle.swift`
- Test: `Tests/PhotoMemoTests/BatchTests/BatchQueueExecutionContractTests.swift`

- [x] Add a failing test that cancels during a suspended save and proves no post-cancel completion is recorded.
- [x] Add phase-aware task lifetime handling and defer managed-source deletion until in-flight work releases the source.
- [x] Re-check cancellation immediately before and after every external side effect.
- [x] Release the in-flight source lifetime on success, failure, cancellation, and task teardown.
- [x] Run focused cancellation and resource lifecycle tests.

### Task 5: Verify release readiness

**Files:**
- Modify: `Docs/CURRENT_STATUS.md`
- Test/build: `PhotoMemoTests`, macOS app, iOS app, Share Extension

- [x] Run the complete serial macOS test suite.
- [x] Build all application targets with signing disabled.
- [x] Review the final diff for unrelated changes and residual ignored persistence results.
- [x] Record remaining manual verification limits and device installation status.
