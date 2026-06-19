#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct BatchQueuePersistence {

    private let storageKey =
        "photomemo.batchQueue.jobs"

    private let defaults:
        UserDefaults

    init(
        defaults: UserDefaults? = nil
    ) {
        self.defaults =
            defaults
            ?? PhotoMemoSharedContainer
            .sharedUserDefaults
    }

    func loadPersistedJobs() -> [BatchJob] {

        guard
            let data = defaults.data(
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

    func persistJobs(
        _ jobs: [BatchJob]
    ) {

        guard let data =
            try? JSONEncoder().encode(
                jobs
            ) else {
            return
        }

        defaults.set(
            data,
            forKey: storageKey
        )
    }
}
#endif
