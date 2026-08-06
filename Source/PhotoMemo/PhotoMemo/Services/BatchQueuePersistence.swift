#if !PHOTOMEMO_SHARE_EXTENSION
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

    private let storageKey =
        "photomemo.batchQueue.jobs"

    private let backend:
        BatchQueuePersistenceBackend

    private let encodeJobs:
        ([BatchJob]) throws -> Data

    init(
        defaults: UserDefaults? = nil,
        encodeJobs:
            @escaping ([BatchJob]) throws -> Data = {
                try JSONEncoder().encode($0)
            }
    ) {
        self.init(
            backend:
                UserDefaultsBatchQueuePersistenceBackend(
                    defaults:
                        defaults
                        ?? PhotoMemoSharedContainer
                        .sharedUserDefaults
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
        self.backend =
            backend
        self.encodeJobs =
            encodeJobs
    }

    func loadPersistedJobsResult()
    -> PhotoMemoResult<[BatchJob]> {

        let data: Data?
        do {
            data = try backend.loadData(forKey: storageKey)
        } catch {
            return .failure(
                PhotoMemoError.wrapped(
                    error,
                    code: .persistenceReadFailed,
                    message: "无法读取批处理队列。",
                    underlyingDescription: "photomemo.batchQueue.jobs: \(String(describing: error))"
                )
            )
        }

        guard let data else {
            return .success([])
        }

        do {
            return .success(
                try JSONDecoder().decode(
                    [BatchJob].self,
                    from: data
                )
            )
        } catch {
            return .failure(
                PhotoMemoError.wrapped(
                    error,
                    code: .persistenceReadFailed,
                    message: "批处理队列数据已损坏，已停止自动恢复。",
                    underlyingDescription: "photomemo.batchQueue.jobs: \(String(describing: error))"
                )
            )
        }
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
                            statusMessage:
                                failure.userMessage
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
                        statusMessage:
                            "等待恢复处理"
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
    ) -> PhotoMemoResult<Void> {

        let data: Data
        do {
            data =
                try encodeJobs(
                    jobs
                )
        } catch {
            return .failure(
                PhotoMemoError.wrapped(
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
                forKey: storageKey
            )

            guard try backend.loadData(forKey: storageKey) == data else {
                throw BatchQueuePersistenceVerificationError
                    .readBackMismatch(
                        key: storageKey
                    )
            }

            return .success(())
        } catch {
            return .failure(
                PhotoMemoError.wrapped(
                    error,
                    code: .persistenceWriteFailed,
                    message:
                        "无法保存批处理队列。"
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
        let intakeDirectoryPath =
            PhotoMemoSharedContainer
            .externalIntakeDirectoryURL
            .standardizedFileURL
            .path

        guard normalizedURL.path.hasPrefix(
            intakeDirectoryPath
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
