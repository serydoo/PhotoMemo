import Foundation

/// Media-executor adapter for owners without the observable App UI store.
/// Admission, execution lease, commerce and notification delivery remain the
/// caller's responsibilities. This adapter only accepts durable task events.
@MainActor
final class DurableBatchTaskExecutionRuntime: BatchTaskExecutionRuntime {
    private let ledger: BatchQueueDurableLedger
    private let jobIDs: Set<UUID>
    private let cleanupSource: (URL) -> Void
    private let didCommit: (BatchTask, BatchJob) async -> Void
    private let finalNotification: (UUID) async -> Void
    private let cancellation: () -> Void
    private let publishError: (String) -> Void

    init(
        ledger: BatchQueueDurableLedger,
        jobIDs: Set<UUID>,
        cleanupSource: @escaping (URL) -> Void = { _ in },
        didCommit: @escaping (BatchTask, BatchJob) async -> Void = { _, _ in },
        finalNotification: @escaping (UUID) async -> Void = { _ in },
        cancellation: @escaping () -> Void = {},
        publishError: @escaping (String) -> Void = { _ in }
    ) {
        self.ledger = ledger
        self.jobIDs = jobIDs
        self.cleanupSource = cleanupSource
        self.didCommit = didCommit
        self.finalNotification = finalNotification
        self.cancellation = cancellation
        self.publishError = publishError
    }

    @MainActor
    func executionState(at reference: BatchTaskReference) async -> BatchTaskExecutionState? {
        guard jobIDs.contains(reference.jobID) else { return nil }
        let snapshot = await ledger.refreshedSnapshot()
        guard !snapshot.isPersistenceBlocked,
              let job = snapshot.jobs.first(where: { $0.id == reference.jobID }),
              let task = job.tasks.first(where: { $0.id == reference.taskID }) else { return nil }
        return .init(task: task, jobID: job.id, launchSource: job.launchSource,
                     hasHistoryCover: job.historyCover != nil)
    }

    @MainActor
    func activate(_ reference: BatchTaskReference) async {}

    @discardableResult
    @MainActor
    func accept(_ event: BatchTaskExecutionEvent, at reference: BatchTaskReference,
                historyCoverCandidate: BatchJobHistoryCover?) async -> Bool {
        guard jobIDs.contains(reference.jobID) else { return false }
        let result = await ledger.apply(event, at: reference, historyCoverCandidate: historyCoverCandidate)
        switch result {
        case .committed(let mutation, let snapshot):
            guard let mutation,
                  let job = snapshot.jobs.first(where: { $0.id == reference.jobID }) else { return false }
            await didCommit(mutation.updated, job)
            return true
        case .unchanged:
            return false
        case .failure(let error, _):
            publishError(error.message)
            return false
        }
    }

    @discardableResult
    @MainActor
    func cleanupDurablyTerminalSource(at reference: BatchTaskReference) async -> Bool {
        guard jobIDs.contains(reference.jobID) else { return false }
        let snapshot = await ledger.refreshedSnapshot()
        guard !snapshot.isPersistenceBlocked,
              let task = snapshot.jobs.first(where: { $0.id == reference.jobID })?
                .tasks.first(where: { $0.id == reference.taskID }),
              task.phase.isTerminal else { return false }
        // Another admitted task can legitimately use the same managed source.
        guard !snapshot.jobs.flatMap(\.tasks).contains(where: {
            $0.id != task.id && !$0.phase.isTerminal && $0.sourceURL == task.sourceURL
        }) else { return false }
        cleanupSource(task.sourceURL)
        return true
    }

    @MainActor
    func stopForCancellation() async { cancellation() }
    @MainActor
    func publishLastError(_ message: String) async { publishError(message) }
    @MainActor
    func deliverFinalNotification(for jobID: UUID) async {
        guard jobIDs.contains(jobID) else { return }
        await finalNotification(jobID)
    }
}
