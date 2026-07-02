import Foundation

enum SharedBatchQueueSnapshotLoadResult {
    case noValue
    case jobNotFound
    case success(
        SharedBatchJobSnapshot
    )
    case decodingFailed(
        PhotoMemoSharedDefaultsReadFailure
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
        UserDefaults

    init(
        defaults: UserDefaults =
            PhotoMemoSharedContainer
            .sharedUserDefaults
    ) {
        self.defaults = defaults
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
    -> PhotoMemoSharedDefaultsReadResult<
        [BatchJob]
    > {

        defaults.synchronize()

        guard let data =
            defaults.data(
                forKey:
                    storageKey
            )
        else {
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
                PhotoMemoSharedDefaultsReadFailure(
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
                        failureMessage:
                            task.failure?
                            .message
                    )
                }
        )
    }
}
