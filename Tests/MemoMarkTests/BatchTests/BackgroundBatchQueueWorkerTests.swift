import Foundation
import Testing
@testable import MemoMark

@Suite("Shared system background queue worker")
@MainActor
struct BackgroundBatchQueueWorkerTests {
    @Test("Both system owners execute the same queue and release their exact lease")
    func systemOwnersUseOneQueue() async {
        for owner in [BackgroundExecutionOwner.bgProcessing, .continuedProcessing] {
            let runtime = Runtime()
            let worker = BackgroundBatchQueueWorker(queueRuntime: runtime, prepareQueue: { .prepared },
                hasPhotoLibraryAuthorization: { true })
            #expect(await worker.run(owner: owner) == .completed)
            #expect(runtime.owners == [owner])
            #expect(runtime.events == ["reserved", "started", "released"])
            #expect(runtime.finishedLease == runtime.reservedLease)
        }
    }

    @Test("A busy execution lease prevents preparation and rendering")
    func busyOwnerDoesNotPrepare() async {
        let runtime = Runtime()
        runtime.reservationAllowed = false
        var prepared = false
        let worker = BackgroundBatchQueueWorker(queueRuntime: runtime, prepareQueue: { prepared = true; return .prepared },
            hasPhotoLibraryAuthorization: { true })
        #expect(await worker.run(owner: .continuedProcessing) == .retryScheduled)
        #expect(!prepared)
        #expect(runtime.events.isEmpty)
    }

    @Test("A permission boundary returns user action without starting media processing")
    func inaccessibleAlbumDoesNotStart() async {
        let runtime = Runtime()
        runtime.canProcessPhotoLibraryDestinations = false
        let worker = BackgroundBatchQueueWorker(queueRuntime: runtime, prepareQueue: { .prepared },
            hasPhotoLibraryAuthorization: { true })
        #expect(await worker.run(owner: .continuedProcessing) == .requiresUserAction)
        #expect(runtime.events == ["reserved", "released"])
    }

    @Test("A held queue never automatically renders under a system owner")
    func heldQueueDoesNotStart() async {
        let runtime = Runtime()
        runtime.isProcessingPaused = true
        let worker = BackgroundBatchQueueWorker(queueRuntime: runtime, prepareQueue: { .prepared },
            hasPhotoLibraryAuthorization: { true })
        #expect(await worker.run(owner: .continuedProcessing) == .paused)
        #expect(runtime.events == ["reserved", "released"])
    }

    @Test("Foreground ownership cannot enter the system queue adapter")
    func rejectsNonSystemOwner() async {
        let runtime = Runtime()
        let worker = BackgroundBatchQueueWorker(queueRuntime: runtime, prepareQueue: { .prepared },
            hasPhotoLibraryAuthorization: { true })
        #expect(await worker.run(owner: .foreground) == .retryScheduled)
        #expect(runtime.owners.isEmpty)
    }

    @Test("An expired callback cannot cancel a successor, and the current run stops before release")
    func cancellationRequiresExactRunAndQuiescence() async {
        let runtime = Runtime()
        runtime.finishesImmediately = false
        let worker = BackgroundBatchQueueWorker(queueRuntime: runtime, prepareQueue: { .prepared },
            hasPhotoLibraryAuthorization: { true })
        let runID = UUID()
        let operation = Task { await worker.run(runID: runID, owner: .continuedProcessing) }
        while !runtime.isProcessing { await Task.yield() }
        await worker.cancel(runID: UUID())
        #expect(runtime.isProcessing)
        #expect(runtime.events == ["reserved", "started"])
        await worker.cancel(runID: runID)
        #expect(await operation.value == .retryScheduled)
        #expect(runtime.events == ["reserved", "started", "stopped", "released"])
        #expect(runtime.finishedLease == runtime.reservedLease)
    }

    @Test("Cancelling the system operation quiesces its processing before releasing ownership")
    func taskCancellationStopsBeforeRelease() async {
        let runtime = Runtime()
        runtime.finishesImmediately = false
        let worker = BackgroundBatchQueueWorker(queueRuntime: runtime, prepareQueue: { .prepared },
            hasPhotoLibraryAuthorization: { true })
        let operation = Task { await worker.run(owner: .continuedProcessing) }
        while !runtime.isProcessing { await Task.yield() }
        operation.cancel()
        #expect(await operation.value == .retryScheduled)
        #expect(runtime.events == ["reserved", "started", "stopped", "released"])
    }

    @Test("Cancellation during preparation stops late-started processing before lease release")
    func cancellationDuringPreparationStopsLateProcessing() async {
        let runtime = Runtime()
        let worker = BackgroundBatchQueueWorker(queueRuntime: runtime, prepareQueue: {
            runtime.isProcessing = true
            runtime.events.append("prepared-and-started")
            withUnsafeCurrentTask { $0?.cancel() }
            return .permanentFailure
        }, hasPhotoLibraryAuthorization: { true })
        let operation = Task { await worker.run(owner: .continuedProcessing) }
        _ = await operation.value
        #expect(!runtime.isProcessing)
        #expect(runtime.events == ["reserved", "prepared-and-started", "stopped", "released"])
    }

    private final class Runtime: BackgroundQueueRuntime {
        var isProcessing = false
        var pendingTaskCount = 1
        var executablePendingTaskCount = 1
        var isProcessingPaused = false
        var canProcessPhotoLibraryDestinations = true
        var reservationAllowed = true
        var finishesImmediately = true
        var owners: [BackgroundExecutionOwner] = []
        var events: [String] = []
        var reservedLease: ExecutionLease?
        var finishedLease: ExecutionLease?

        func reserveSystemExecution(owner: BackgroundExecutionOwner) -> ExecutionLease? {
            owners.append(owner)
            guard reservationAllowed else { return nil }
            let lease = ExecutionLease(id: UUID(), owner: owner)
            reservedLease = lease
            events.append("reserved")
            return lease
        }
        func finishSystemExecution(_ lease: ExecutionLease) async {
            finishedLease = lease
            events.append("released")
        }
        func stopProcessingForBackgroundExpiration(lease: ExecutionLease) async {
            events.append("stopped")
            isProcessing = false
        }
        func stopProcessingForBackgroundExpiration() async { isProcessing = false }
        func startProcessingIfNeeded() async {
            events.append("started")
            if finishesImmediately {
                pendingTaskCount = 0
                executablePendingTaskCount = 0
            } else { isProcessing = true }
        }
    }
}
