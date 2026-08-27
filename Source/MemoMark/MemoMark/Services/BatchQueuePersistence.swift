#if !MEMOMARK_SHARE_EXTENSION
import Foundation

protocol BatchQueuePersistenceBackend {

    func loadData(
        forKey key: String
    ) throws -> Data?

    func saveData(
        _ data: Data,
        forKey key: String
    ) throws
}

struct UserDefaultsBatchQueuePersistenceBackend:
    BatchQueuePersistenceBackend {

    let defaults: UserDefaults
    let synchronize: () -> Bool

    init(
        defaults: UserDefaults,
        synchronize: (() -> Bool)? = nil
    ) {
        self.defaults = defaults
        self.synchronize =
            synchronize
            ?? { defaults.synchronize() }
    }

    func loadData(
        forKey key: String
    ) throws -> Data? {

        defaults.data(
            forKey: key
        )
    }

    func saveData(
        _ data: Data,
        forKey key: String
    ) throws {

        defaults.set(
            data,
            forKey: key
        )

        _ = synchronize()

        guard defaults.data(forKey: key) == data else {
            throw UserDefaultsBatchQueuePersistenceError
                .readBackMismatch(
                    key: key
                )
        }
    }
}

struct FileBatchQueuePersistenceBackend:
    BatchQueuePersistenceBackend {

    private let baseDirectoryURL: URL

    init(
        baseDirectoryURL: URL
    ) {
        self.baseDirectoryURL =
            baseDirectoryURL.standardizedFileURL
    }

    func loadData(
        forKey key: String
    ) throws -> Data? {
        let fileURL = try snapshotURL(forKey: key)
        guard FileManager.default.fileExists(
            atPath: fileURL.path
        ) else {
            return nil
        }

        return try Data(contentsOf: fileURL)
    }

    func saveData(
        _ data: Data,
        forKey key: String
    ) throws {
        let fileURL = try snapshotURL(forKey: key)
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(
            to: fileURL,
            options: .atomic
        )

        guard try Data(contentsOf: fileURL) == data else {
            throw FileBatchQueuePersistenceError
                .readBackMismatch(
                    fileURL
                )
        }
    }

    private func snapshotURL(
        forKey key: String
    ) throws -> URL {
        guard key == BatchQueuePersistence.storageKey else {
            throw FileBatchQueuePersistenceError
                .unsupportedStorageKey(
                    key
                )
        }

        return baseDirectoryURL
            .appendingPathComponent(
                "BatchQueue",
                isDirectory: true
            )
            .appendingPathComponent(
                "jobs-v1.json",
                isDirectory: false
            )
    }
}

private enum FileBatchQueuePersistenceError:
    LocalizedError {

    case unsupportedStorageKey(String)
    case readBackMismatch(URL)

    var errorDescription: String? {
        switch self {
        case .unsupportedStorageKey(let key):
            return "Unsupported batch queue storage key: \(key)."
        case .readBackMismatch(let url):
            return "Batch queue file read-back verification failed at \(url.path)."
        }
    }
}

private enum UserDefaultsBatchQueuePersistenceError:
    LocalizedError {

    case readBackMismatch(key: String)

    var errorDescription: String? {
        switch self {
        case .readBackMismatch(let key):
            return "UserDefaults read-back verification failed for key \(key)."
        }
    }
}

private enum BatchQueuePersistenceVerificationError:
    LocalizedError {

    case readBackMismatch(key: String)

    var errorDescription: String? {
        switch self {
        case .readBackMismatch(let key):
            return "Batch queue persistence read-back verification failed for key \(key)."
        }
    }
}

struct BatchQueuePersistence {

    static let storageKey =
        "photomemo.batchQueue.jobs"

    private let backend:
        BatchQueuePersistenceBackend

    private let legacyBackend:
        BatchQueuePersistenceBackend?

    private let encodeJobs:
        ([BatchJob]) throws -> Data

    init(
        defaults: UserDefaults? = nil,
        encodeJobs:
            @escaping ([BatchJob]) throws -> Data = {
                try JSONEncoder().encode($0)
            }
    ) {
        // The production queue is file-backed in the shared App Group. The
        // explicit defaults initializer remains available for compatibility
        // and focused tests.
        if let defaults {
            self.init(
                backend:
                    UserDefaultsBatchQueuePersistenceBackend(
                        defaults: defaults
                    ),
                legacyBackend: nil,
                encodeJobs: encodeJobs
            )
            return
        }

        self.init(
            backend: FileBatchQueuePersistenceBackend(
                baseDirectoryURL: MemoMarkSharedContainer.baseDirectoryURL
            ),
            legacyBackend: UserDefaultsBatchQueuePersistenceBackend(
                defaults: MemoMarkSharedContainer.sharedUserDefaults
            ),
            encodeJobs: encodeJobs
        )
    }

    init(
        fileBaseDirectoryURL: URL,
        legacyDefaults: UserDefaults,
        encodeJobs:
            @escaping ([BatchJob]) throws -> Data = {
                try JSONEncoder().encode($0)
            }
    ) {
        self.init(
            backend:
                FileBatchQueuePersistenceBackend(
                    baseDirectoryURL:
                        fileBaseDirectoryURL
                ),
            legacyBackend:
                UserDefaultsBatchQueuePersistenceBackend(
                    defaults:
                        legacyDefaults
                ),
            encodeJobs: encodeJobs
        )
    }

    init(
        backend: BatchQueuePersistenceBackend,
        encodeJobs:
            @escaping ([BatchJob]) throws -> Data = {
                try JSONEncoder().encode($0)
            }
    ) {
        self.init(
            backend: backend,
            legacyBackend: nil,
            encodeJobs: encodeJobs
        )
    }

    private init(
        backend: BatchQueuePersistenceBackend,
        legacyBackend: BatchQueuePersistenceBackend?,
        encodeJobs:
            @escaping ([BatchJob]) throws -> Data
    ) {
        self.backend = backend
        self.legacyBackend = legacyBackend
        self.encodeJobs = encodeJobs
    }

    func loadPersistedJobsResult()
    -> MemoMarkResult<[BatchJob]> {

        let primaryData: Data?
        do {
            primaryData = try backend.loadData(
                forKey: Self.storageKey
            )
        } catch {
            return .failure(
                MemoMarkError.wrapped(
                    error,
                    code: .persistenceReadFailed,
                    message: "无法读取批处理队列。",
                    underlyingDescription: "photomemo.batchQueue.jobs: \(String(describing: error))"
                )
            )
        }

        if let primaryData {
            return decodeJobs(
                from: primaryData
            )
        }

        guard let legacyBackend else {
            return .success([])
        }

        let legacyData: Data?
        do {
            legacyData = try legacyBackend.loadData(
                forKey: Self.storageKey
            )
        } catch {
            return .failure(
                MemoMarkError.wrapped(
                    error,
                    code: .persistenceReadFailed,
                    message: "无法读取旧版批处理队列。",
                    underlyingDescription: "photomemo.batchQueue.jobs: \(String(describing: error))"
                )
            )
        }

        guard let legacyData else {
            return .success([])
        }

        let decodedLegacyJobs = decodeJobs(
            from: legacyData
        )
        guard let jobs = decodedLegacyJobs.value else {
            return decodedLegacyJobs
        }

        do {
            try backend.saveData(
                legacyData,
                forKey: Self.storageKey
            )
            guard try backend.loadData(
                forKey: Self.storageKey
            ) == legacyData else {
                throw BatchQueuePersistenceVerificationError
                    .readBackMismatch(
                        key: Self.storageKey
                    )
            }
        } catch {
            return .failure(
                MemoMarkError.wrapped(
                    error,
                    code: .persistenceWriteFailed,
                    message:
                        "无法迁移批处理队列。"
                )
            )
        }

        return .success(jobs)
    }

    func loadPersistedJobs() -> [BatchJob] {
        loadPersistedJobsResult().value ?? []
    }

    func normalizeJobsForResume(
        _ jobs: inout [BatchJob],
        protectedTaskIDs: Set<UUID> = [],
        deriveJobState:
            ([BatchTask]) -> BatchJobState
    ) -> Bool {

        var changed = false

        for jobIndex in jobs.indices {
            for taskIndex in jobs[jobIndex]
                .tasks.indices {

                let phase =
                    jobs[jobIndex]
                    .tasks[taskIndex]
                    .phase

                guard !phase.isTerminal else {
                    continue
                }

                // A durable receipt means Apple Photos may already own the
                // output even when direct readback is temporarily unavailable.
                guard !protectedTaskIDs.contains(
                    jobs[jobIndex].tasks[taskIndex].id
                ) else {
                    continue
                }

                if isMissingManagedIntakeSource(
                    jobs[jobIndex]
                        .tasks[taskIndex]
                        .sourceURL
                ) {
                    let taskID = jobs[jobIndex]
                        .tasks[taskIndex].id
                    let failure =
                        ProductionDiagnosticFailureClassifier
                        .processing(
                            phase: phase.rawValue,
                            classification:
                                BatchTaskFailure
                                .Classification
                                .interrupted.rawValue,
                            operationID: taskID,
                            error:
                                CocoaError(.fileNoSuchFile),
                            language: .interfaceStored
                        )
                    jobs[jobIndex]
                        .tasks[taskIndex]
                        .phase = .failed
                    jobs[jobIndex]
                        .tasks[taskIndex]
                        .renderedFileURL = nil
                    jobs[jobIndex]
                        .tasks[taskIndex]
                        .failure =
                        BatchTaskFailure(
                            phase: phase,
                            message: failure.userMessage,
                            classification: .interrupted,
                            canRetry: false,
                            diagnosticCode:
                                failure.code.rawValue,
                            supportID:
                                failure.supportID
                        )
                    jobs[jobIndex]
                        .tasks[taskIndex]
                        .progress =
                        BatchTaskProgress(
                            currentUnit: 0,
                            totalUnits: 1,
                            stage: .failed
                        )
                    changed = true
                    continue
                }

                jobs[jobIndex]
                    .tasks[taskIndex]
                    .phase = .queued
                jobs[jobIndex]
                    .tasks[taskIndex]
                    .renderedFileURL = nil
                jobs[jobIndex]
                    .tasks[taskIndex]
                    .progress =
                    BatchTaskProgress(
                        currentUnit: 0,
                        totalUnits: 1,
                        stage: .waitingToResume
                    )
                changed = true
            }

            let derivedState =
                deriveJobState(
                    jobs[jobIndex].tasks
                )
            if jobs[jobIndex].state != derivedState {
                jobs[jobIndex].state = derivedState
                changed = true
            }
        }

        return changed
    }

    @discardableResult
    func persistJobs(
        _ jobs: [BatchJob]
    ) -> MemoMarkResult<Void> {

        let data: Data
        do {
            data =
                try encodeJobs(
                    jobs
                )
        } catch {
            return .failure(
                MemoMarkError.wrapped(
                    error,
                    code: .persistenceWriteFailed,
                    message:
                        "无法保存批处理队列。"
                )
            )
        }

        do {
            try backend.saveData(
                data,
                forKey: Self.storageKey
            )

            guard try backend.loadData(forKey: Self.storageKey) == data else {
                throw BatchQueuePersistenceVerificationError
                    .readBackMismatch(
                        key: Self.storageKey
                    )
            }

            return .success(())
        } catch {
            return .failure(
                MemoMarkError.wrapped(
                    error,
                    code: .persistenceWriteFailed,
                    message:
                        "无法保存批处理队列。"
                )
            )
        }
    }

    private func decodeJobs(
        from data: Data
    ) -> MemoMarkResult<[BatchJob]> {
        do {
            return .success(
                try JSONDecoder().decode(
                    [BatchJob].self,
                    from: data
                )
            )
        } catch {
            return .failure(
                MemoMarkError.wrapped(
                    error,
                    code: .persistenceReadFailed,
                    message: "批处理队列数据已损坏，已停止自动恢复。",
                    underlyingDescription: "photomemo.batchQueue.jobs: \(String(describing: error))"
                )
            )
        }
    }
}

private extension BatchQueuePersistence {

    func isMissingManagedIntakeSource(
        _ url: URL
    ) -> Bool {

        let normalizedURL =
            url.standardizedFileURL
        guard MemoMarkPathContainment.contains(
            normalizedURL,
            root: MemoMarkSharedContainer.externalIntakeDirectoryURL
        ) else {
            return false
        }

        return !FileManager.default.fileExists(
            atPath:
                normalizedURL.path
        )
    }
}

#endif
