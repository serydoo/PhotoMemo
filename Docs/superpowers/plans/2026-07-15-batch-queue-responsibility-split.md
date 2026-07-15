# Batch Queue Responsibility Split Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Split `BatchQueueExecution` into queue coordination, single-task processing, diagnostics, and resource lifecycle units while preserving all production behavior and `BatchQueueStore` contracts.

**Architecture:** Keep `BatchQueueExecution` as a compatibility facade and keep `BatchQueueStore` as the sole task-state owner. Move pure policy first, then diagnostics and resource cleanup, then single-task processing, and finally queue coordination. All extracted collaborators remain `@MainActor` until no cross-actor state is required.

**Tech Stack:** Swift 5, SwiftUI/UIKit app targets, Swift Testing, Xcode 26/27 toolchain, PhotoKit/ImageIO, existing batch intents and diagnostics.

---

### Task 1: Establish the Batch Queue Contract Baseline

**Files:**
- Create: `Tests/PhotoMemoTests/BatchTests/BatchQueueExecutionContractTests.swift`
- Inspect: `Source/PhotoMemo/PhotoMemo/Services/BatchQueueExecution.swift`
- Inspect: `Source/PhotoMemo/PhotoMemo/Services/BatchQueueStore.swift`

- [ ] **Step 1: Add outcome-level tests for the current state machine**

Cover these observable outcomes with the existing fake repositories and temporary-file fixtures already used by `LivePhotoBatchQueueExecutionTests` and `BatchQueueRecoveryTests`:

```swift
@Test("retry clears terminal output fields")
@MainActor
func retryResetsRenderedAndSavedState() throws {
    let jobID = UUID()
    var jobs = [
        BatchJob(
            id: jobID,
            title: "failed",
            state: .failed,
            configuration: BatchConfigurationSnapshot(
                template: .classicWhite,
                badge: nil,
                anchor: nil,
                shouldWritePhotoDescription: true,
                photoDescriptionOverride: "",
                selectedAlbumIdentifier: ""
            ),
            tasks: [
                BatchTask(
                    sourceURL: URL(fileURLWithPath: "/tmp/input.jpg"),
                    phase: .failed,
                    savedAlbumName: "MemoMark",
                    savedAssetIdentifier: "asset-id",
                    renderedFileURL: URL(fileURLWithPath: "/tmp/output.jpg"),
                    notificationAttachmentURL: URL(fileURLWithPath: "/tmp/attachment.jpg"),
                    failure: BatchTaskFailure(phase: .exporting, message: "failed")
                )
            ],
            finalNotificationSentAt: Date()
        )
    ]
    let didRetry = BatchQueueExecution().retryFailedTasks(
        in: &jobs,
        jobID: jobID
    )

    #expect(didRetry)
    #expect(jobs[0].tasks[0].phase == .queued)
    #expect(jobs[0].tasks[0].renderedFileURL == nil)
    #expect(jobs[0].tasks[0].notificationAttachmentURL == nil)
    #expect(jobs[0].tasks[0].savedAssetIdentifier == nil)
    #expect(jobs[0].tasks[0].retryCount == 1)
    #expect(jobs[0].finalNotificationSentAt == nil)
}
```

Implement equivalent outcome tests for processor failure leaving no rendered or
saved output, managed-source preservation after retryable failure, and
final-notification at-most-once delivery. Use state assertions on
`BatchJob`/`BatchTask`; do not assert private helper calls.

The Task 1 processor-failure contract does not claim to exercise
`ProductionRenderHealthCheck.validate`. The current concrete final Preview and
Export coordinators do not provide a safe injection seam for forcing that
rejection before save. Add the true Production Render Health Check rejection
contract in Task 4 after `BatchTaskProcessor` establishes the required seam;
that test must prove rejection leaves no rendered or saved output.

- [ ] **Step 2: Run only the new contract test file and confirm the baseline**

Run:

```bash
xcodebuild -project Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoTests -configuration Debug -destination 'platform=macOS' -derivedDataPath /tmp/PhotoMemoBatchContractTests CODE_SIGNING_ALLOWED=NO -only-testing:PhotoMemoTests/BatchQueueExecutionContractTests test
```

Expected: existing behavior passes before extraction; if a scenario cannot be made deterministic, record the missing seam before changing production code.

- [ ] **Step 3: Commit the contract baseline**

```bash
git add Tests/PhotoMemoTests/BatchTests/BatchQueueExecutionContractTests.swift
git commit -m "Add batch queue behavior contracts"
```

### Task 2: Extract Pure Batch Policies

**Files:**
- Create: `Source/PhotoMemo/PhotoMemo/Services/BatchTaskFailurePolicy.swift`
- Create: `Source/PhotoMemo/PhotoMemo/Services/BatchTaskMemoryPolicy.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/Services/BatchQueueExecution.swift`
- Test: `Tests/PhotoMemoTests/BatchTests/BatchQueueExecutionContractTests.swift`

- [ ] **Step 1: Move failure classification and retry policy**

Create concrete static functions for `failureClassification`, `canRetryTaskAfterFailure`, `shouldAbortFurtherProcessing`, and `shouldIgnoreErrorBecauseTaskEnded`. The functions must not access `BatchQueueStore` or write diagnostics.

- [ ] **Step 2: Move memory-budget and content-type policy**

Move `mediaMemoryBudget`, `shouldUseLivePhotoProcessing`, and `staticImportContentTypeIdentifier` without changing returned values or thresholds.

- [ ] **Step 3: Replace facade calls with policy calls and delete duplicate helpers**

Keep method names at the facade only where existing tests call them; otherwise update internal calls to the new policies.

- [ ] **Step 4: Run batch tests and iOS build**

```bash
xcodebuild -project Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoTests -configuration Debug -destination 'platform=macOS' -derivedDataPath /tmp/PhotoMemoBatchPolicyTests CODE_SIGNING_ALLOWED=NO -only-testing:PhotoMemoTests/BatchTests test
xcodebuild -project Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PhotoMemoBatchPolicyBuild CODE_SIGNING_ALLOWED=NO -quiet build
```

- [ ] **Step 5: Commit the policy extraction**

```bash
git add Source/PhotoMemo/PhotoMemo/Services/BatchTaskFailurePolicy.swift Source/PhotoMemo/PhotoMemo/Services/BatchTaskMemoryPolicy.swift Source/PhotoMemo/PhotoMemo/Services/BatchQueueExecution.swift Tests/PhotoMemoTests/BatchTests/BatchQueueExecutionContractTests.swift
git commit -m "Extract batch task policies"
```

### Task 3: Extract Diagnostics And Resource Lifecycle

**Files:**
- Create: `Source/PhotoMemo/PhotoMemo/Services/BatchTaskDiagnosticsRecorder.swift`
- Create: `Source/PhotoMemo/PhotoMemo/Services/BatchTaskResourceLifecycle.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/Services/BatchQueueExecution.swift`
- Test: `Tests/PhotoMemoTests/BatchTests/BatchQueueExecutionContractTests.swift`

- [ ] **Step 1: Extract diagnostics with the existing `UserDefaults` dependency**

Move admission, route, stage timing, task duration, notification-stage timing, and Render Health Check evidence recording. Preserve exact diagnostic stages and messages; only the owner changes.

- [ ] **Step 2: Extract resource cleanup and attachment generation**

Move temporary-file cleanup, managed source cleanup, retry preservation, managed URL detection, retry eligibility, and notification attachment generation. Every cleanup operation must remain safe when called twice.

- [ ] **Step 3: Inject both collaborators into the facade**

Initialize them from existing dependencies; preserve default construction and test injection. Do not add a new persistence store.

- [ ] **Step 4: Add cancellation, failure, retry, and attachment assertions**

Assert terminal task state, rendered URL cleanup, managed-source retention/deletion, and notification attachment behavior.

- [ ] **Step 5: Run focused tests, full batch tests, and iOS build**

Use the commands from Task 2 with a new DerivedData path and require exit code `0`.

- [ ] **Step 6: Commit the diagnostics/resource extraction**

```bash
git add Source/PhotoMemo/PhotoMemo/Services/BatchTaskDiagnosticsRecorder.swift Source/PhotoMemo/PhotoMemo/Services/BatchTaskResourceLifecycle.swift Source/PhotoMemo/PhotoMemo/Services/BatchQueueExecution.swift Tests/PhotoMemoTests/BatchTests/BatchQueueExecutionContractTests.swift
git commit -m "Extract batch diagnostics and resource lifecycle"
```

### Task 4: Extract Single-Task Processing

**Files:**
- Create: `Source/PhotoMemo/PhotoMemo/Services/BatchTaskProcessor.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/Services/BatchQueueExecution.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/Services/BatchQueueStore.swift` only if required for access adapters
- Test: `Tests/PhotoMemoTests/BatchTests/BatchQueueExecutionContractTests.swift`
- Test: `Tests/PhotoMemoTests/BatchTests/LivePhotoBatchQueueExecutionTests.swift`

- [ ] **Step 1: Define a `BatchTaskExecutionContext` value**

Include task reference, task snapshot, memory budget, route, total progress units, and start time. Keep it immutable after route selection.

- [ ] **Step 2: Move static and Live Photo task execution**

Move the body of `processTask` and `processLivePhotoTask` into `BatchTaskProcessor`. Keep `@MainActor`, existing intents, existing progress units, and existing Render Health Check order.

- [ ] **Step 3: Add a facade delegation method**

`BatchQueueExecution.processTask(at:in:)` delegates to `BatchTaskProcessor.process(at:in:)` and remains available to existing callers/tests.

- [ ] **Step 4: Run all batch tests and verify Live Photo scenarios**

Require existing static/live route, identity, fallback, mixed-batch, cancellation, retry, and persistence tests to pass.

- [ ] **Step 5: Commit the processor extraction**

```bash
git add Source/PhotoMemo/PhotoMemo/Services/BatchTaskProcessor.swift Source/PhotoMemo/PhotoMemo/Services/BatchQueueExecution.swift Source/PhotoMemo/PhotoMemo/Services/BatchQueueStore.swift Tests/PhotoMemoTests/BatchTests
git commit -m "Extract batch task processor"
```

### Task 5: Reduce The Facade To Queue Coordination

**Files:**
- Create: `Source/PhotoMemo/PhotoMemo/Services/BatchQueueCoordinator.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/Services/BatchQueueExecution.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/Services/BatchQueueStore.swift`
- Test: `Tests/PhotoMemoTests/BatchTests/BatchQueueRecoveryTests.swift`
- Test: `Tests/PhotoMemoTests/BatchTests/BatchQueueStorePersistenceTests.swift`

- [ ] **Step 1: Move admission, retry, cancel, pending-reference, and derived-job-state methods**

`BatchQueueCoordinator` owns queue-level decisions but delegates task execution to `BatchTaskProcessor`. Preserve `BatchQueueStore`’s single `processingTask` lane and `Task { @MainActor in ... }` creation.

- [ ] **Step 2: Keep `BatchQueueExecution` as a compatibility facade**

Forward current public/internal entry points to `BatchQueueCoordinator` so existing callers do not change in this slice.

- [ ] **Step 3: Run recovery, persistence, notification, and full batch tests**

Confirm duplicate processing starts remain impossible, queued references recover, state persistence remains durable, and final notifications remain gated.

- [ ] **Step 4: Build all affected targets**

```bash
xcodebuild -project Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoBatchFinalBuild CODE_SIGNING_ALLOWED=NO -quiet build
xcodebuild -project Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PhotoMemoBatchFinalIOSBuild CODE_SIGNING_ALLOWED=NO -quiet build
```

- [ ] **Step 5: Commit the coordinator reduction and update status**

Update `Docs/CURRENT_STATUS.md` with the completed boundary and verification evidence, then commit:

```bash
git add Source/PhotoMemo/PhotoMemo/Services/BatchQueueCoordinator.swift Source/PhotoMemo/PhotoMemo/Services/BatchQueueExecution.swift Source/PhotoMemo/PhotoMemo/Services/BatchQueueStore.swift Tests/PhotoMemoTests/BatchTests Docs/CURRENT_STATUS.md
git commit -m "Reduce batch queue execution to coordination facade"
```

### Task 6: Review And Push The Batch Slice

- [ ] **Step 1: Inspect final diff and file sizes**

Confirm `BatchQueueExecution.swift` contains only compatibility forwarding and composition, no direct ImageIO or task-stage state machine logic.

- [ ] **Step 2: Run `git diff --check` and all relevant tests/builds**

Do not claim completion without fresh exit-code evidence.

- [ ] **Step 3: Push each committed slice to `origin/main`**

```bash
git push origin main
```

- [ ] **Step 4: Generate the next independent plan**

After this slice is verified, create a separate plan for `PhotoMemoiOSV1View`; do not combine UI extraction with export or Share changes.
