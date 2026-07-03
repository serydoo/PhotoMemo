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

    func loadPersistedJobs() -> [BatchJob] {

        guard
            let data =
                try? backend.loadData(
                forKey: storageKey
            ),
            let decodedJobs =
                try? JSONDecoder().decode(
                    [BatchJob].self,
                    from: data
                )
        else {
            return []
        }

        return decodedJobs
    }

    func normalizeJobsForResume(
        _ jobs: inout [BatchJob],
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

                if isMissingManagedIntakeSource(
                    jobs[jobIndex]
                        .tasks[taskIndex]
                        .sourceURL
                ) {
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
                            message: "原始临时文件已不可用",
                            canRetry: false
                        )
                    jobs[jobIndex]
                        .tasks[taskIndex]
                        .progress =
                        BatchTaskProgress(
                            currentUnit: 0,
                            totalUnits: 1,
                            statusMessage:
                                "原始临时文件已不可用"
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

            jobs[jobIndex].state =
                deriveJobState(
                    jobs[jobIndex].tasks
                )
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
