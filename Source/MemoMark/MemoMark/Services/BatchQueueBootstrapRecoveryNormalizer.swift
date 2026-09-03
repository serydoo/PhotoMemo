#if !MEMOMARK_SHARE_EXTENSION
import Foundation

/// Normalizes persisted work before the actor-backed queue begins runtime
/// processing. It only decides which interrupted tasks are recoverable and
/// which receipt-backed saves must remain protected; the queue facade owns
/// persistence, diagnostics, commerce accounting, and resource cleanup.
@MainActor
struct BatchQueueBootstrapRecoveryNormalizer {

    struct Result {

        let didChange: Bool
        let recoveredFailures: [BatchQueueRecoveredFailure]
    }

    private let persistence: BatchQueuePersistence
    private let receiptReconciler: BatchQueueBootstrapReceiptReconciler
    private let deriveJobState: ([BatchTask]) -> BatchJobState

    init(
        persistence: BatchQueuePersistence,
        receiptReconciler: BatchQueueBootstrapReceiptReconciler,
        deriveJobState: @escaping ([BatchTask]) -> BatchJobState
    ) {
        self.persistence = persistence
        self.receiptReconciler = receiptReconciler
        self.deriveJobState = deriveJobState
    }

    func normalize(
        _ jobs: inout [BatchJob]
    ) -> Result {

        let existingFailureTaskIDs = Set(
            jobs.flatMap(\.tasks)
                .filter { $0.failure != nil }
                .map(\.id)
        )
        let protectedTaskIDs =
            receiptReconciler.unresolvedSavingTaskIDs(
                in: jobs
            )
        guard persistence.normalizeJobsForResume(
            &jobs,
            protectedTaskIDs: protectedTaskIDs,
            deriveJobState: deriveJobState
        ) else {
            return Result(
                didChange: false,
                recoveredFailures: []
            )
        }

        let recoveredFailures: [BatchQueueRecoveredFailure] = jobs.flatMap { job in
            job.tasks.compactMap { task in
                guard !existingFailureTaskIDs.contains(task.id),
                      let failure = task.failure else {
                    return nil
                }
                return BatchQueueRecoveredFailure(
                    jobID: job.id,
                    task: task,
                    failure: failure
                )
            }
        }
        return Result(
            didChange: true,
            recoveredFailures: recoveredFailures
        )
    }
}
#endif
