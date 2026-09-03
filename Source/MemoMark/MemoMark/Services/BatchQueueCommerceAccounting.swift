#if !MEMOMARK_SHARE_EXTENSION
import Foundation

/// Owns the commerce facts attached to durable queue work. The queue facade
/// remains responsible for publishing snapshots and deciding how a failed
/// commerce write blocks processing; this collaborator never changes queue
/// state or performs UI work.
@MainActor
struct BatchQueueCommerceAccounting {

    struct RetryAdmission: Equatable {

        let retryableTaskCount: Int

        let maximumAdmissionCount: Int
    }

    struct Outcome {

        let updatedSnapshot: MemoMarkCommerceSnapshot?

        let requiresRecovery: Bool
    }

    private let persistence: MemoMarkCommercePersistence

    init(
        persistence: MemoMarkCommercePersistence
    ) {
        self.persistence = persistence
    }

    func loadSharedSnapshot(
        compatibleWith environment: MemoMarkCommerceEnvironment
    ) -> MemoMarkCommerceSnapshot {
        persistence.loadSharedSnapshot(
            compatibleWith: environment
        )
    }

    func saveSharedSnapshot(
        _ snapshot: MemoMarkCommerceSnapshot
    ) -> Bool {
        persistence.saveSharedSnapshot(snapshot)
    }

    func retryAdmission(
        for job: BatchJob,
        among jobs: [BatchJob],
        current snapshot: MemoMarkCommerceSnapshot
    ) -> RetryAdmission {
        let retryableTaskCount = job.tasks.count {
            $0.phase == .failed
            && ($0.failure?.canRetry ?? true)
        }
        let maximumAdmissionCount = admissionCapacity(
            among: jobs,
            current: snapshot
        )

        return RetryAdmission(
            retryableTaskCount: retryableTaskCount,
            maximumAdmissionCount: maximumAdmissionCount
        )
    }

    func admissionCapacity(
        among jobs: [BatchJob],
        current snapshot: MemoMarkCommerceSnapshot
    ) -> Int {
        let reservedRecordCount = jobs.reduce(into: 0) { count, job in
            count += job.tasks.count { !$0.phase.isTerminal }
        }
        return MemoMarkCommercePolicy(
            isPlus: snapshot.isPlus,
            totalAllowance: snapshot.totalAllowance,
            batchLimit: snapshot.batchLimit
        )
        .maximumAdmissionCount(
            after: snapshot.successfulRecordCount,
            reservedRecordCount: reservedRecordCount
        )
    }

    func recordSuccessfulSave(
        for task: BatchTask,
        current snapshot: MemoMarkCommerceSnapshot
    ) -> Outcome {
        guard task.savedAssetIdentifier != nil,
              !snapshot.isPlus else {
            return Outcome(
                updatedSnapshot: nil,
                requiresRecovery: false
            )
        }

        if persistence.hasRecordedSuccessfulSave(
            taskID: task.id,
            environment: snapshot.environment
        ) {
            return Outcome(
                updatedSnapshot: nil,
                requiresRecovery: false
            )
        }

        if !persistence.recordSuccessfulSave(
            taskID: task.id,
            environment: snapshot.environment
        ), !persistence.hasRecordedSuccessfulSave(
            taskID: task.id,
            environment: snapshot.environment
        ) {
            return Outcome(
                updatedSnapshot: nil,
                requiresRecovery: true
            )
        }

        return Outcome(
            updatedSnapshot: recordedFreeSnapshot(
                from: snapshot
            ),
            requiresRecovery: false
        )
    }

    func reconcile(
        completedJobs jobs: [BatchJob],
        current snapshot: MemoMarkCommerceSnapshot
    ) -> Outcome {
        guard !snapshot.isPlus else {
            return Outcome(
                updatedSnapshot: nil,
                requiresRecovery: false
            )
        }

        let completedTaskIDs = Set(
            jobs.flatMap(\.tasks)
                .filter {
                    $0.phase == .completed
                    && $0.savedAssetIdentifier != nil
                }
                .map(\.id)
        )
        guard persistence.reconcileSuccessfulSaves(
            taskIDs: completedTaskIDs,
            environment: snapshot.environment
        ) else {
            return Outcome(
                updatedSnapshot: nil,
                requiresRecovery: true
            )
        }

        let successfulRecordCount = persistence.successfulRecordCount(
            environment: snapshot.environment
        )
        guard successfulRecordCount != snapshot.successfulRecordCount else {
            return Outcome(
                updatedSnapshot: nil,
                requiresRecovery: false
            )
        }

        return Outcome(
            updatedSnapshot: reconciledFreeSnapshot(
                from: snapshot
            ),
            requiresRecovery: false
        )
    }

    private func recordedFreeSnapshot(
        from snapshot: MemoMarkCommerceSnapshot
    ) -> MemoMarkCommerceSnapshot {
        let bonusAllowance = persistence.bonusAllowance(
            environment: snapshot.environment
        )
        return MemoMarkCommerceSnapshot(
            environment: snapshot.environment,
            accessSource: .free,
            successfulRecordCount: persistence.successfulRecordCount(
                environment: snapshot.environment
            ),
            totalAllowance: MemoMarkCommercePolicy.baseFreeAllowance
                + bonusAllowance,
            batchLimit: MemoMarkCommercePolicy.freeBatchLimit,
            firstRecorderDate: nil,
            updatedAt: Date()
        )
    }

    private func reconciledFreeSnapshot(
        from snapshot: MemoMarkCommerceSnapshot
    ) -> MemoMarkCommerceSnapshot {
        let bonusAllowance = persistence.bonusAllowance(
            environment: snapshot.environment
        )
        let policy = MemoMarkCommercePolicy.resolved(
            for: snapshot.environment,
            bonusAllowance: bonusAllowance
        )
        return MemoMarkCommerceSnapshot(
            environment: snapshot.environment,
            accessSource: .free,
            successfulRecordCount: persistence.successfulRecordCount(
                environment: snapshot.environment
            ),
            totalAllowance: policy.totalAllowance,
            batchLimit: policy.batchLimit,
            firstRecorderDate: nil,
            updatedAt: Date()
        )
    }
}
#endif
