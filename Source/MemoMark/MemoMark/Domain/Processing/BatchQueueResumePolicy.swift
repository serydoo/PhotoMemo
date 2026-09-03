#if !MEMOMARK_SHARE_EXTENSION
import Foundation

/// Deterministic recovery of non-terminal queue work after process restart.
///
/// Infrastructure supplies source availability and diagnostic construction;
/// this policy owns only the queue-state semantics.
nonisolated struct BatchQueueResumePolicy:
    Sendable {

    func normalize(
        _ jobs: inout [BatchJob],
        protectedTaskIDs: Set<UUID> = [],
        isMissingManagedSource: (URL) -> Bool,
        missingSourceFailure:
            (BatchTaskPhase, UUID) -> BatchTaskFailure
    ) -> Bool {
        var changed = false
        let transitionPolicy =
            BatchQueueTransitionPolicy()

        for jobIndex in jobs.indices {
            for taskIndex in jobs[jobIndex].tasks.indices {
                let phase =
                    jobs[jobIndex]
                    .tasks[taskIndex]
                    .phase
                guard !phase.isTerminal else {
                    continue
                }

                let taskID =
                    jobs[jobIndex]
                    .tasks[taskIndex]
                    .id
                guard !protectedTaskIDs.contains(taskID) else {
                    continue
                }

                if isMissingManagedSource(
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
                        missingSourceFailure(
                            phase,
                            taskID
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
                transitionPolicy.derivedJobState(
                    from:
                        jobs[jobIndex]
                        .tasks
                        .map(\.phase)
                )
            if jobs[jobIndex].state != derivedState {
                jobs[jobIndex].state = derivedState
                changed = true
            }
        }

        return changed
    }
}
#endif
