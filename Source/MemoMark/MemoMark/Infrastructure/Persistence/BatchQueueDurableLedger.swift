#if !MEMOMARK_SHARE_EXTENSION
import Foundation

nonisolated struct BatchQueueDurableSnapshot:
    Sendable {

    let jobs: [BatchJob]
    let revision: UInt64
    let persistenceError: MemoMarkError?

    var isPersistenceBlocked: Bool {
        persistenceError != nil
    }
}

nonisolated struct BatchQueueDurableLedgerBootstrap:
    Sendable {

    let ledger: BatchQueueDurableLedger
    let snapshot: BatchQueueDurableSnapshot
    let error: MemoMarkError?
}

nonisolated enum BatchQueueDurableCommitResult:
    Sendable {

    case committed(BatchQueueDurableSnapshot)
    case conflict(BatchQueueDurableSnapshot)
    case failure(
        MemoMarkError,
        BatchQueueDurableSnapshot
    )
}

nonisolated enum BatchQueueDurableMutation<Value: Sendable>:
    Sendable {

    case commit(Value)
    case unchanged(Value)
}

nonisolated enum BatchQueueDurableTransactionResult<Value: Sendable>:
    Sendable {

    case committed(
        value: Value,
        snapshot: BatchQueueDurableSnapshot
    )
    case unchanged(
        value: Value,
        snapshot: BatchQueueDurableSnapshot
    )
    case failure(
        MemoMarkError,
        BatchQueueDurableSnapshot
    )
}

nonisolated enum BatchQueueDurableRecoveryResult:
    Sendable {

    case recovered(BatchQueueDurableSnapshot)
    case failure(
        MemoMarkError,
        BatchQueueDurableSnapshot
    )
}

/// Keeps the main-actor projection ordered with actor-owned durable commands.
/// The ledger serializes disk commits; this gate additionally prevents a
/// later UI command from evaluating policy against a projection whose prior
/// durable command has not returned yet.
actor BatchQueueCommandGate {

    private var isHeld = false
    private var waiters:
        [CheckedContinuation<Void, Never>] = []

    func acquire() async {
        guard isHeld else {
            isHeld = true
            return
        }
        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }

    func release() {
        guard !waiters.isEmpty else {
            isHeld = false
            return
        }
        waiters.removeFirst().resume()
    }
}

/// Serializes ownership of the durable batch-queue snapshot and every disk commit.
///
/// UI-facing state remains a read-only projection on `BatchQueueStore`. The
/// revision check prevents a suspended caller from replacing a newer durable
/// queue after an actor hop.
actor BatchQueueDurableLedger {

    private let persistence: BatchQueuePersistence
    private let retentionPolicy: BatchQueueRetentionPolicy
    private var currentSnapshot: BatchQueueDurableSnapshot

    private init(
        persistence: BatchQueuePersistence,
        retentionPolicy: BatchQueueRetentionPolicy,
        snapshot: BatchQueueDurableSnapshot
    ) {
        self.persistence = persistence
        self.retentionPolicy = retentionPolicy
        currentSnapshot = snapshot
    }

    nonisolated static func bootstrap(
        persistence: BatchQueuePersistence,
        retentionPolicy: BatchQueueRetentionPolicy = .init()
    ) -> BatchQueueDurableLedgerBootstrap {
        let snapshot: BatchQueueDurableSnapshot
        let error: MemoMarkError?

        switch persistence.loadPersistedJobsResult() {
        case .success(let jobs):
            snapshot = BatchQueueDurableSnapshot(
                jobs: jobs,
                revision: 0,
                persistenceError: nil
            )
            error = nil
        case .failure(let persistenceError):
            snapshot = BatchQueueDurableSnapshot(
                jobs: [],
                revision: 0,
                persistenceError: persistenceError
            )
            error = persistenceError
        }

        return BatchQueueDurableLedgerBootstrap(
            ledger: BatchQueueDurableLedger(
                persistence: persistence,
                retentionPolicy: retentionPolicy,
                snapshot: snapshot
            ),
            snapshot: snapshot,
            error: error
        )
    }

    func snapshot() -> BatchQueueDurableSnapshot {
        currentSnapshot
    }

    func commit(
        _ candidateJobs: [BatchJob],
        expectedRevision: UInt64
    ) -> BatchQueueDurableCommitResult {
        if let persistenceError = currentSnapshot.persistenceError {
            return .failure(
                persistenceError,
                currentSnapshot
            )
        }

        guard expectedRevision == currentSnapshot.revision else {
            return .conflict(currentSnapshot)
        }

        var retainedCandidateJobs = candidateJobs
        retentionPolicy.apply(to: &retainedCandidateJobs)

        if let error = persistence.persistJobs(retainedCandidateJobs).error {
            currentSnapshot = BatchQueueDurableSnapshot(
                jobs: currentSnapshot.jobs,
                revision: currentSnapshot.revision,
                persistenceError: error
            )
            return .failure(error, currentSnapshot)
        }

        currentSnapshot = BatchQueueDurableSnapshot(
            jobs: retainedCandidateJobs,
            revision: currentSnapshot.revision + 1,
            persistenceError: nil
        )
        return .committed(currentSnapshot)
    }

    /// Runs a pure queue mutation against the latest actor-owned snapshot.
    /// The candidate becomes observable only after persistence succeeds.
    func transaction<Value: Sendable>(
        _ mutation: @Sendable
            (inout [BatchJob]) -> BatchQueueDurableMutation<Value>
    ) -> BatchQueueDurableTransactionResult<Value> {
        if let persistenceError = currentSnapshot.persistenceError {
            return .failure(
                persistenceError,
                currentSnapshot
            )
        }

        var candidateJobs = currentSnapshot.jobs
        switch mutation(&candidateJobs) {
        case .unchanged(let value):
            return .unchanged(
                value: value,
                snapshot: currentSnapshot
            )

        case .commit(let value):
            retentionPolicy.apply(to: &candidateJobs)
            if let error = persistence.persistJobs(candidateJobs).error {
                currentSnapshot = BatchQueueDurableSnapshot(
                    jobs: currentSnapshot.jobs,
                    revision: currentSnapshot.revision,
                    persistenceError: error
                )
                return .failure(error, currentSnapshot)
            }

            currentSnapshot = BatchQueueDurableSnapshot(
                jobs: candidateJobs,
                revision: currentSnapshot.revision + 1,
                persistenceError: nil
            )
            return .committed(
                value: value,
                snapshot: currentSnapshot
            )
        }
    }

    func admit(
        _ job: BatchJob
    ) -> BatchQueueDurableTransactionResult<BatchQueueAdmission> {
        transaction { jobs in
            let admission =
                BatchQueueTransitionPolicy()
                .admit(job, into: &jobs)
            return admission.didInsert
                ? .commit(admission)
                : .unchanged(admission)
        }
    }

    func retryFailedTasks(
        in jobID: UUID,
        now: Date = Date()
    ) -> BatchQueueDurableTransactionResult<Bool> {
        transaction { jobs in
            let changed =
                BatchQueueTransitionPolicy()
                .retryFailedTasks(
                    in: &jobs,
                    jobID: jobID,
                    now: now
                )
            return changed
                ? .commit(true)
                : .unchanged(false)
        }
    }

    func cancelJob(
        _ jobID: UUID,
        now: Date = Date()
    ) -> BatchQueueDurableTransactionResult<Bool> {
        transaction { jobs in
            let changed =
                BatchQueueTransitionPolicy()
                .cancelJob(
                    in: &jobs,
                    jobID: jobID,
                    now: now
                )
            return changed
                ? .commit(true)
                : .unchanged(false)
        }
    }

    func apply(
        _ event: BatchTaskExecutionEvent,
        at reference: BatchTaskReference,
        now: Date = Date(),
        historyCoverCandidate:
            BatchJobHistoryCover? = nil
    ) -> BatchQueueDurableTransactionResult<BatchQueueTaskMutation?> {
        transaction { jobs in
            guard let mutation =
                BatchQueueTransitionPolicy()
                .apply(
                    event,
                    at: reference,
                    in: &jobs,
                    now: now,
                    historyCoverCandidate:
                        historyCoverCandidate
                ) else {
                return .unchanged(nil)
            }
            return .commit(mutation)
        }
    }

    func expireActiveTask(
        at reference: BatchTaskReference,
        failure: BatchTaskFailure,
        now: Date = Date()
    ) -> BatchQueueDurableTransactionResult<Bool> {
        transaction { jobs in
            let changed =
                BatchQueueTransitionPolicy()
                .expireActiveTask(
                    at: reference,
                    in: &jobs,
                    failure: failure,
                    now: now
                )
            return changed
                ? .commit(true)
                : .unchanged(false)
        }
    }

    func clearTerminalExternalHistory(
        preserving preservedJobID: UUID?
    ) -> BatchQueueDurableTransactionResult<BatchQueueHistoryRemoval> {
        transaction { jobs in
            let removal =
                BatchQueueTransitionPolicy()
                .clearTerminalExternalHistory(
                    in: &jobs,
                    preserving: preservedJobID
                )
            return removal.didChange
                ? .commit(removal)
                : .unchanged(removal)
        }
    }

    func markStartNotificationSent(
        for jobID: UUID,
        at date: Date = Date()
    ) -> BatchQueueDurableTransactionResult<Bool> {
        transaction { jobs in
            let changed =
                BatchQueueTransitionPolicy()
                .markStartNotificationSent(
                    for: jobID,
                    in: &jobs,
                    at: date
                )
            return changed
                ? .commit(true)
                : .unchanged(false)
        }
    }

    func markFinalNotificationSent(
        for jobID: UUID,
        at date: Date = Date()
    ) -> BatchQueueDurableTransactionResult<Bool> {
        transaction { jobs in
            let changed =
                BatchQueueTransitionPolicy()
                .markFinalNotificationSent(
                    for: jobID,
                    in: &jobs,
                    at: date
                )
            return changed
                ? .commit(true)
                : .unchanged(false)
        }
    }

    func releaseNotificationAttachmentsIfCovered(
        for jobID: UUID
    ) -> BatchQueueDurableTransactionResult<Bool> {
        transaction { jobs in
            let changed =
                BatchQueueTransitionPolicy()
                .releaseNotificationAttachmentsIfCovered(
                    for: jobID,
                    in: &jobs
                )
            return changed
                ? .commit(true)
                : .unchanged(false)
        }
    }

    /// Reloads the durable payload before clearing a persistence block. This
    /// prevents an empty startup fallback from overwriting a queue that later
    /// becomes readable.
    func recover() -> BatchQueueDurableRecoveryResult {
        let loadedJobs: [BatchJob]
        switch persistence.loadPersistedJobsResult() {
        case .success(let jobs):
            loadedJobs = jobs
        case .failure(let error):
            currentSnapshot = BatchQueueDurableSnapshot(
                jobs: currentSnapshot.jobs,
                revision: currentSnapshot.revision,
                persistenceError: error
            )
            return .failure(error, currentSnapshot)
        }

        var retainedJobs = loadedJobs
        retentionPolicy.apply(to: &retainedJobs)
        if let error = persistence.persistJobs(retainedJobs).error {
            currentSnapshot = BatchQueueDurableSnapshot(
                jobs: currentSnapshot.jobs,
                revision: currentSnapshot.revision,
                persistenceError: error
            )
            return .failure(error, currentSnapshot)
        }

        currentSnapshot = BatchQueueDurableSnapshot(
            jobs: retainedJobs,
            revision: currentSnapshot.revision + 1,
            persistenceError: nil
        )
        return .recovered(currentSnapshot)
    }
}
#endif
