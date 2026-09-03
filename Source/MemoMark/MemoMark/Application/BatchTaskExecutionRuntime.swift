#if !MEMOMARK_SHARE_EXTENSION
import Foundation

nonisolated struct BatchTaskExecutionState:
    Sendable {

    let task: BatchTask

    let jobID: UUID

    let launchSource:
        BatchJobLaunchSource

    let hasHistoryCover: Bool
}

/// Actor-ready application boundary between media execution and the durable
/// queue owner. Implementations validate and persist accepted events.
nonisolated protocol BatchTaskExecutionRuntime:
    Sendable {

    func executionState(
        at reference: BatchTaskReference
    ) async -> BatchTaskExecutionState?

    func activate(
        _ reference: BatchTaskReference
    ) async

    @discardableResult
    func accept(
        _ event: BatchTaskExecutionEvent,
        at reference: BatchTaskReference,
        historyCoverCandidate:
            BatchJobHistoryCover?
    ) async -> Bool

    @discardableResult
    func cleanupDurablyTerminalSource(
        at reference: BatchTaskReference
    ) async -> Bool

    func stopForCancellation() async

    func publishLastError(
        _ message: String
    ) async

    func deliverFinalNotification(
        for jobID: UUID
    ) async
}

nonisolated extension BatchTaskExecutionRuntime {

    func accept(
        _ event: BatchTaskExecutionEvent,
        at reference: BatchTaskReference
    ) async -> Bool {

        await accept(
            event,
            at: reference,
            historyCoverCandidate: nil
        )
    }

}

extension BatchQueueStore {

    func executionState(
        at reference: BatchTaskReference
    ) async -> BatchTaskExecutionState? {

        guard let task = currentTask(
            at: reference
        ),
        let job = currentJob(
            at: reference
        ) else {
            return nil
        }

        return BatchTaskExecutionState(
            task: task,
            jobID: job.id,
            launchSource: job.launchSource,
            hasHistoryCover:
                job.historyCover != nil
        )
    }

    func activate(
        _ reference: BatchTaskReference
    ) async {
        setActiveProcessingReference(reference)
    }

    func accept(
        _ event: BatchTaskExecutionEvent,
        at reference: BatchTaskReference,
        historyCoverCandidate:
            BatchJobHistoryCover?
    ) async -> Bool {

        await applyExecutionEvent(
            event,
            at: reference,
            historyCoverCandidate:
                historyCoverCandidate
        )
    }

    func cleanupDurablyTerminalSource(
        at reference: BatchTaskReference
    ) async -> Bool {
        await cleanupManagedSourceForDurablyTerminalTask(
            at: reference
        )
    }

    func stopForCancellation() async {
        stopProcessingForCancellation()
    }

    func publishLastError(
        _ message: String
    ) async {
        setLastErrorMessage(message)
    }

    func deliverFinalNotification(
        for jobID: UUID
    ) async {
        await deliverFinalNotificationIfNeeded(
            for: jobID
        )
    }
}
#endif
