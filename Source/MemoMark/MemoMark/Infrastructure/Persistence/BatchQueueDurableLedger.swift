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

        let loaded: MemoMarkResult<[BatchJob]>
        do {
            let lock = persistence.transactionLockURL.map { ProcessingExecutionFileLock(url: $0) }
            if let lock { guard try lock.acquire(waitForAvailability: true) else { throw POSIXError(.EWOULDBLOCK) } }
            defer { lock?.release() }
            loaded = persistence.loadPersistedJobsResult()
        } catch {
            loaded = .failure(MemoMarkError.wrapped(error, code: .persistenceWriteFailed, message: "无法锁定批处理队列。"))
        }
        switch loaded {
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

    /// Hold only across synchronous disk read/modify/write; never across an await.
    private func acquireTransactionLock() throws -> ProcessingExecutionFileLock? {
        guard let url = persistence.transactionLockURL else { return nil }
        let lock = ProcessingExecutionFileLock(url: url)
        guard try lock.acquire(waitForAvailability: true) else { throw POSIXError(.EWOULDBLOCK) }
        return lock
    }

    private func refreshFileSnapshot() -> MemoMarkError? {
        if let error = currentSnapshot.persistenceError { return error }
        guard persistence.transactionLockURL != nil else { return nil }
        switch persistence.loadPersistedJobsResult() {
        case .success(let jobs):
            if jobs != currentSnapshot.jobs {
                currentSnapshot = BatchQueueDurableSnapshot(jobs: jobs, revision: currentSnapshot.revision + 1, persistenceError: nil)
            }
            return nil
        case .failure(let error):
            currentSnapshot = BatchQueueDurableSnapshot(jobs: currentSnapshot.jobs, revision: currentSnapshot.revision, persistenceError: error)
            return error
        }
    }

    private func transactionLockError(_ error: Error) -> MemoMarkError {
        MemoMarkError.wrapped(error, code: .persistenceWriteFailed, message: "无法锁定批处理队列。")
    }

    func snapshot() -> BatchQueueDurableSnapshot {
        currentSnapshot
    }

    /// Refresh under the same interprocess transaction lock used for writes.
    /// A background owner must observe cancellation from another process.
    func refreshedSnapshot() -> BatchQueueDurableSnapshot {
        switch transaction({ _ in .unchanged(()) }) {
        case .committed(_, let snapshot), .unchanged(_, let snapshot):
            return snapshot
        case .failure(let error, let snapshot):
            return .init(jobs: snapshot.jobs, revision: snapshot.revision, persistenceError: error)
        }
    }

    func commit(
        _ candidateJobs: [BatchJob],
        expectedRevision: UInt64
    ) -> BatchQueueDurableCommitResult {
        let transactionLock: ProcessingExecutionFileLock?
        do { transactionLock = try acquireTransactionLock() }
        catch { return .failure(transactionLockError(error), currentSnapshot) }
        defer { transactionLock?.release() }
        if let error = refreshFileSnapshot() { return .failure(error, currentSnapshot) }

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
        let transactionLock: ProcessingExecutionFileLock?
        do { transactionLock = try acquireTransactionLock() }
        catch { return .failure(transactionLockError(error), currentSnapshot) }
        defer { transactionLock?.release() }
        if let error = refreshFileSnapshot() { return .failure(error, currentSnapshot) }

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

    /// Capacity and reservation share the same cross-process file transaction.
    /// An already-admitted request remains idempotent even after quota changes.
    func admit(
        _ job: BatchJob,
        maximumPendingTaskCount: Int
    ) -> BatchQueueDurableTransactionResult<BatchQueueAdmission?> {
        transaction { jobs in
            if let requestID = job.intakeRequestID,
               let existing = jobs.first(where: { $0.intakeRequestID == requestID }) {
                return .unchanged(.init(job: existing, didInsert: false))
            }
            let reserved = ProcessingReservationPolicy.reservedIDs(in: jobs).count
            let required = ProcessingReservationPolicy.newReservationCount(for: job, among: jobs)
            guard required <= max(max(maximumPendingTaskCount, 0) - reserved, 0) else {
                return .unchanged(nil)
            }
            return .commit(BatchQueueTransitionPolicy().admit(job, into: &jobs))
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

    func suspendExecutionSession(_ sessionID: UUID, now: Date = Date()) -> BatchQueueDurableTransactionResult<Bool> {
        transaction { jobs in
            ExecutionSessionSuspensionPolicy.suspend(sessionID, in: &jobs, now: now)
                ? .commit(true) : .unchanged(false)
        }
    }

    func resumeExecutionSession(_ sessionID: UUID, now: Date = Date()) -> BatchQueueDurableTransactionResult<Bool> {
        transaction { jobs in
            ExecutionSessionSuspensionPolicy.resume(sessionID, in: &jobs, now: now)
                ? .commit(true) : .unchanged(false)
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

    func deleteExecutionSessionHistory(_ sessionID: UUID, now: Date = Date()) -> BatchQueueDurableTransactionResult<Bool> {
        transaction { jobs in
            let indices = jobs.indices.filter { (jobs[$0].executionSessionID ?? jobs[$0].id) == sessionID }
            guard !indices.isEmpty,
                  indices.allSatisfy({ jobs[$0].tasks.allSatisfy { $0.phase.isTerminal } }) else {
                return .unchanged(false)
            }
            let visible = indices.filter { jobs[$0].historyDeletedAt == nil }
            guard !visible.isEmpty else { return .unchanged(false) }
            for index in visible { jobs[index].historyDeletedAt = now }
            return .commit(true)
        }
    }

    func cancelExecutionSession(
        _ sessionID: UUID,
        now: Date = Date(),
        cancellableRecoveredSaveTaskIDs: Set<UUID> = []
    ) -> BatchQueueDurableTransactionResult<Bool> {
        transaction { jobs in
            let changed = BatchQueueTransitionPolicy()
                .cancelExecutionSession(
                    in: &jobs,
                    sessionID: sessionID,
                    now: now,
                    cancellableRecoveredSaveTaskIDs: cancellableRecoveredSaveTaskIDs
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
        let transactionLock: ProcessingExecutionFileLock?
        do { transactionLock = try acquireTransactionLock() }
        catch { return .failure(transactionLockError(error), currentSnapshot) }
        defer { transactionLock?.release() }

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
