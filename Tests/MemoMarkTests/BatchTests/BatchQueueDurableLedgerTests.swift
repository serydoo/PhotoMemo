import Foundation
import Testing
@testable import MemoMark

@Suite("Batch queue durable ledger", .serialized)
struct BatchQueueDurableLedgerTests {

    @Test("Bootstrap exposes the persisted queue as revision zero")
    func bootstrapLoadsPersistedQueue() async throws {
        let job = makeJob(title: "Persisted")
        let backend = LedgerPersistenceBackend(
            data: try JSONEncoder().encode([job])
        )

        let bootstrap = BatchQueueDurableLedger.bootstrap(
            persistence: BatchQueuePersistence(backend: backend)
        )

        #expect(bootstrap.error == nil)
        #expect(bootstrap.snapshot.jobs == [job])
        #expect(bootstrap.snapshot.revision == 0)
        #expect(bootstrap.snapshot.isPersistenceBlocked == false)
        let actorSnapshot = await bootstrap.ledger.snapshot()
        #expect(actorSnapshot.jobs == bootstrap.snapshot.jobs)
        #expect(actorSnapshot.revision == bootstrap.snapshot.revision)
        #expect(
            actorSnapshot.persistenceError
            == bootstrap.snapshot.persistenceError
        )
    }

    @Test("Commit persists the candidate and advances the durable revision")
    func commitPersistsCandidate() async throws {
        let firstJob = makeJob(title: "First")
        let secondJob = makeJob(title: "Second")
        let backend = LedgerPersistenceBackend(
            data: try JSONEncoder().encode([firstJob])
        )
        let bootstrap = BatchQueueDurableLedger.bootstrap(
            persistence: BatchQueuePersistence(backend: backend)
        )

        let result = await bootstrap.ledger.commit(
            [secondJob, firstJob],
            expectedRevision: bootstrap.snapshot.revision
        )

        let committed = try #require(result.committedSnapshot)
        #expect(committed.jobs == [secondJob, firstJob])
        #expect(committed.revision == 1)
        #expect(committed.isPersistenceBlocked == false)
        #expect(
            BatchQueuePersistence(backend: backend)
                .loadPersistedJobsResult().value
            == [secondJob, firstJob]
        )
    }

    @Test("A stale commit cannot overwrite a newer durable snapshot")
    func staleCommitIsRejected() async throws {
        let firstJob = makeJob(title: "First")
        let secondJob = makeJob(title: "Second")
        let staleJob = makeJob(title: "Stale")
        let backend = LedgerPersistenceBackend()
        let bootstrap = BatchQueueDurableLedger.bootstrap(
            persistence: BatchQueuePersistence(backend: backend)
        )

        _ = await bootstrap.ledger.commit(
            [firstJob, secondJob],
            expectedRevision: 0
        )
        let result = await bootstrap.ledger.commit(
            [staleJob],
            expectedRevision: 0
        )

        let conflict = try #require(result.conflictingSnapshot)
        #expect(conflict.jobs == [firstJob, secondJob])
        #expect(conflict.revision == 1)
        #expect(
            BatchQueuePersistence(backend: backend)
                .loadPersistedJobsResult().value
            == [firstJob, secondJob]
        )
    }

    @Test("A failed write retains the last durable snapshot and blocks later commits")
    func failedWriteRetainsDurableSnapshot() async throws {
        let durableJob = makeJob(title: "Durable")
        let rejectedJob = makeJob(title: "Rejected")
        let backend = LedgerPersistenceBackend(
            data: try JSONEncoder().encode([durableJob])
        )
        let bootstrap = BatchQueueDurableLedger.bootstrap(
            persistence: BatchQueuePersistence(backend: backend)
        )
        backend.rejectsWrites = true

        let failedResult = await bootstrap.ledger.commit(
            [rejectedJob],
            expectedRevision: 0
        )
        let failed = try #require(failedResult.failedSnapshot)
        #expect(failed.snapshot.jobs == [durableJob])
        #expect(failed.snapshot.revision == 0)
        #expect(failed.snapshot.isPersistenceBlocked)
        #expect(failed.error.code == .persistenceWriteFailed)

        backend.rejectsWrites = false
        let blockedResult = await bootstrap.ledger.commit(
            [rejectedJob],
            expectedRevision: 0
        )
        let blocked = try #require(blockedResult.failedSnapshot)
        #expect(blocked.snapshot.jobs == [durableJob])
        #expect(blocked.snapshot.isPersistenceBlocked)
        #expect(
            BatchQueuePersistence(backend: backend)
                .loadPersistedJobsResult().value
            == [durableJob]
        )
    }

    @Test("Concurrent transactions serialize without losing committed jobs")
    func concurrentTransactionsDoNotLoseUpdates() async throws {
        let backend = LedgerPersistenceBackend()
        let bootstrap = BatchQueueDurableLedger.bootstrap(
            persistence: BatchQueuePersistence(backend: backend)
        )
        let jobs = (0..<20).map {
            makeJob(title: "Job \($0)")
        }

        await withTaskGroup(of: Void.self) { group in
            for job in jobs {
                group.addTask {
                    _ = await bootstrap.ledger.transaction { currentJobs in
                        currentJobs.append(job)
                        return .commit(())
                    }
                }
            }
        }

        let snapshot = await bootstrap.ledger.snapshot()
        #expect(snapshot.jobs.count == jobs.count)
        #expect(Set(snapshot.jobs.map(\.id)) == Set(jobs.map(\.id)))
        #expect(snapshot.revision == UInt64(jobs.count))
        #expect(
            Set(
                BatchQueuePersistence(backend: backend)
                    .loadPersistedJobsResult().value?
                    .map(\.id)
                ?? []
            )
            == Set(jobs.map(\.id))
        )
    }

    @Test("Recovery reloads durable jobs before accepting new transactions")
    func recoveryReloadsBeforeUnblocking() async throws {
        let recoveredJob = makeJob(title: "Recovered")
        let admittedJob = makeJob(title: "Admitted after recovery")
        let backend = LedgerPersistenceBackend(
            data: Data("corrupted-queue".utf8)
        )
        let bootstrap = BatchQueueDurableLedger.bootstrap(
            persistence: BatchQueuePersistence(backend: backend)
        )
        #expect(bootstrap.snapshot.isPersistenceBlocked)

        backend.data = try JSONEncoder().encode([recoveredJob])
        let recovery = await bootstrap.ledger.recover()
        let recovered = try #require(recovery.recoveredSnapshot)
        #expect(recovered.jobs == [recoveredJob])
        #expect(recovered.isPersistenceBlocked == false)

        _ = await bootstrap.ledger.transaction { jobs in
            jobs.append(admittedJob)
            return .commit(())
        }
        let finalSnapshot = await bootstrap.ledger.snapshot()
        #expect(finalSnapshot.jobs == [recoveredJob, admittedJob])
    }

    @Test("Typed admission is durable and idempotent")
    func typedAdmissionIsDurableAndIdempotent() async throws {
        let requestID = UUID()
        var job = makeJob(title: "Share")
        job.intakeRequestID = requestID
        var duplicate = makeJob(title: "Duplicate")
        duplicate.intakeRequestID = requestID
        let backend = LedgerPersistenceBackend()
        let ledger = BatchQueueDurableLedger.bootstrap(
            persistence: BatchQueuePersistence(backend: backend)
        ).ledger

        let first = await ledger.admit(job)
        let second = await ledger.admit(duplicate)

        let admitted = try #require(first.committedValue)
        #expect(admitted.didInsert)
        #expect(admitted.job == job)
        let existing = try #require(second.unchangedValue)
        #expect(!existing.didInsert)
        #expect(existing.job == job)
        let snapshot = await ledger.snapshot()
        #expect(snapshot.jobs == [job])
        #expect(snapshot.revision == 1)
    }

    @Test("Typed execution event persists before returning its projection")
    func typedExecutionEventPersistsProjection() async throws {
        let job = makeJob(title: "Execution")
        let backend = LedgerPersistenceBackend(
            data: try JSONEncoder().encode([job])
        )
        let ledger = BatchQueueDurableLedger.bootstrap(
            persistence: BatchQueuePersistence(backend: backend)
        ).ledger
        let reference = BatchTaskReference(
            jobID: job.id,
            taskID: job.tasks[0].id
        )

        let result = await ledger.apply(
            .processingStarted(
                progress: BatchTaskProgress(
                    currentUnit: 1,
                    totalUnits: 5,
                    stage: .readingOriginal
                )
            ),
            at: reference,
            now: Date(timeIntervalSince1970: 2_000)
        )

        let optionalMutation: BatchQueueTaskMutation?
        switch result {
        case .committed(let value, _):
            optionalMutation = value
        case .unchanged, .failure:
            optionalMutation = nil
        }
        let mutation = try #require(optionalMutation)
        #expect(mutation.previous.phase == .queued)
        #expect(mutation.updated.phase == .importing)
        let persisted = try #require(
            BatchQueuePersistence(backend: backend)
                .loadPersistedJobsResult().value
        )
        #expect(persisted[0].tasks[0].phase == .importing)
    }

    @Test("Every durable commit applies terminal history retention")
    func durableCommitAppliesTerminalHistoryRetention() async throws {
        var terminalJobs = (0..<121).map {
            makeJob(title: "Terminal \($0)")
        }
        for index in terminalJobs.indices {
            terminalJobs[index].state = .completed
            terminalJobs[index].tasks[0].phase = .completed
        }
        let removedJobID = try #require(terminalJobs.last?.id)
        let backend = LedgerPersistenceBackend()
        let ledger = BatchQueueDurableLedger.bootstrap(
            persistence: BatchQueuePersistence(backend: backend)
        ).ledger

        _ = await ledger.commit(
            terminalJobs,
            expectedRevision: 0
        )

        let snapshot = await ledger.snapshot()
        let persisted = try #require(
            BatchQueuePersistence(backend: backend)
                .loadPersistedJobsResult().value
        )
        #expect(snapshot.jobs.count == 120)
        #expect(!snapshot.jobs.map(\.id).contains(removedJobID))
        #expect(persisted == snapshot.jobs)
    }

    private func makeJob(title: String) -> BatchJob {
        BatchJob(
            title: title,
            state: .queued,
            configuration: BatchConfigurationSnapshot(
                template: .classicWhite,
                badge: nil,
                anchor: nil,
                shouldWritePhotoDescription: false,
                photoDescriptionOverride: "",
                selectedAlbumIdentifier: ""
            ),
            tasks: [
                BatchTask(
                    sourceURL: URL(
                        fileURLWithPath: "/tmp/\(UUID().uuidString).jpg"
                    )
                )
            ]
        )
    }
}

private extension BatchQueueDurableTransactionResult {

    var committedValue: Value? {
        guard case .committed(let value, _) = self else {
            return nil
        }
        return value
    }

    var unchangedValue: Value? {
        guard case .unchanged(let value, _) = self else {
            return nil
        }
        return value
    }
}

private extension BatchQueueDurableCommitResult {

    var committedSnapshot: BatchQueueDurableSnapshot? {
        guard case .committed(let snapshot) = self else {
            return nil
        }
        return snapshot
    }

    var conflictingSnapshot: BatchQueueDurableSnapshot? {
        guard case .conflict(let snapshot) = self else {
            return nil
        }
        return snapshot
    }

    var failedSnapshot:
        (error: MemoMarkError, snapshot: BatchQueueDurableSnapshot)? {
        guard case .failure(let error, let snapshot) = self else {
            return nil
        }
        return (error, snapshot)
    }
}

private extension BatchQueueDurableRecoveryResult {

    var recoveredSnapshot: BatchQueueDurableSnapshot? {
        guard case .recovered(let snapshot) = self else {
            return nil
        }
        return snapshot
    }
}

private final class LedgerPersistenceBackend:
    BatchQueuePersistenceBackend {

    private let lock = NSLock()
    private var storedData: Data?
    private var shouldRejectWrites = false

    init(data: Data? = nil) {
        storedData = data
    }

    var rejectsWrites: Bool {
        get {
            lock.withLock { shouldRejectWrites }
        }
        set {
            lock.withLock {
                shouldRejectWrites = newValue
            }
        }
    }

    var data: Data? {
        get {
            lock.withLock { storedData }
        }
        set {
            lock.withLock {
                storedData = newValue
            }
        }
    }

    func loadData(forKey key: String) throws -> Data? {
        lock.withLock { storedData }
    }

    func saveData(_ data: Data, forKey key: String) throws {
        try lock.withLock {
            guard !shouldRejectWrites else {
                throw LedgerPersistenceFailure.rejected
            }
            storedData = data
        }
    }
}

private enum LedgerPersistenceFailure: Error {
    case rejected
}
