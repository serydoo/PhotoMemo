import Foundation

enum SharedBatchQueueSnapshotLoadResult {
    case noValue
    case jobNotFound
    case success(
        SharedBatchJobSnapshot
    )
    case decodingFailed(
        MemoMarkSharedDefaultsReadFailure
    )
}

struct SharedBatchTaskSnapshot:
    Identifiable,
    Hashable {

    let id: UUID

    let fileName: String

    let phase: BatchTaskPhase

    let progressFraction: Double

    let statusMessage: String

    let progressStage: BatchTaskProgressStage?

    let failureMessage: String?
}

struct SharedBatchJobSnapshot:
    Identifiable,
    Hashable {

    let id: UUID

    let state: BatchJobState

    let tasks: [SharedBatchTaskSnapshot]

    var totalCount: Int {
        tasks.count
    }

    var completedCount: Int {
        tasks.filter {
            $0.phase == .completed
        }.count
    }

    var failedCount: Int {
        tasks.filter {
            $0.phase == .failed
        }.count
    }

    var runningCount: Int {
        tasks.filter {
            !$0.phase.isTerminal
        }.count
    }

    var isTerminal: Bool {
        !tasks.isEmpty
        && tasks.allSatisfy {
            $0.phase.isTerminal
        }
    }

    var firstActiveTaskIndex: Int? {
        tasks.firstIndex {
            !$0.phase.isTerminal
        }
    }
}

struct SharedBatchQueueSnapshotService {

    private let storageKey =
        "photomemo.batchQueue.jobs"

    private let defaults:
        UserDefaults?

    private let fileURL:
        URL?

    init(
        defaults: UserDefaults =
            MemoMarkSharedContainer
            .sharedUserDefaults
    ) {
        self.defaults = defaults
        self.fileURL = nil
    }

    init(
        fileBaseDirectoryURL: URL,
        legacyDefaults: UserDefaults
    ) {
        self.defaults = legacyDefaults
        self.fileURL = fileBaseDirectoryURL
            .standardizedFileURL
            .appendingPathComponent(
                "BatchQueue",
                isDirectory: true
            )
            .appendingPathComponent(
                "jobs-v1.json",
                isDirectory: false
            )
    }

    func loadSnapshot(
        for jobID: UUID
    ) -> SharedBatchJobSnapshot? {

        switch loadSnapshotResult(
            for: jobID
        ) {
        case .success(let snapshot):
            return snapshot
        case .noValue,
             .jobNotFound,
             .decodingFailed:
            return nil
        }
    }

    func loadSnapshotResult(
        for jobID: UUID
    ) -> SharedBatchQueueSnapshotLoadResult {

        switch loadJobsResult() {
        case .noValue:
            return .noValue
        case .decodingFailed(let failure):
            return .decodingFailed(
                failure
            )
        case .success(let jobs):
            guard
                let job =
                    jobs.first(where: {
                        $0.id == jobID
                    })
            else {
                return .jobNotFound
            }

            return .success(
                makeSnapshot(from: job)
            )
        }
    }

    func loadJobs() -> [BatchJob] {

        switch loadJobsResult() {
        case .success(let jobs):
            return jobs
        case .noValue,
             .decodingFailed:
            return []
        }
    }

    func loadJobsResult()
    -> MemoMarkSharedDefaultsReadResult<
        [BatchJob]
    > {

        let data: Data?
        do {
            if let fileURL,
               FileManager.default.fileExists(
                   atPath: fileURL.path
               ) {
                data = try Data(contentsOf: fileURL)
            } else {
                defaults?.synchronize()
                data = defaults?.data(
                    forKey:
                        storageKey
                )
            }
        } catch {
            return .decodingFailed(
                MemoMarkSharedDefaultsReadFailure(
                    storageKey:
                        storageKey,
                    payloadByteCount: 0,
                    underlyingDescription:
                        String(
                            describing: error
                        )
                )
            )
        }

        guard let data else {
            return .noValue
        }

        do {
            let jobs =
                try JSONDecoder()
                .decode(
                    [BatchJob].self,
                    from: data
                )
            return .success(jobs)
        } catch {
            return .decodingFailed(
                MemoMarkSharedDefaultsReadFailure(
                    storageKey:
                        storageKey,
                    payloadByteCount:
                        data.count,
                    underlyingDescription:
                        String(
                            describing: error
                        )
                )
            )
        }
    }

    private func makeSnapshot(
        from job: BatchJob
    ) -> SharedBatchJobSnapshot {

        SharedBatchJobSnapshot(
            id: job.id,
            state: job.state,
            tasks:
                job.tasks.map { task in
                    SharedBatchTaskSnapshot(
                        id: task.id,
                        fileName:
                            task.fileName,
                        phase:
                            task.phase,
                        progressFraction:
                            task.progress
                            .fractionCompleted,
                        statusMessage:
                            task.progress
                            .statusMessage,
                        progressStage:
                            task.progress
                            .stage,
                        failureMessage:
                            task.failure?
                            .message
                    )
                }
        )
    }
}
