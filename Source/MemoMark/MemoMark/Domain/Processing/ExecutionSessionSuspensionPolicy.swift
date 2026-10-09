import Foundation

nonisolated enum ExecutionSessionSuspensionPolicy {
    static func executablePendingTaskCount(in jobs: [BatchJob]) -> Int {
        jobs.filter { $0.executionSuspendedAt == nil && $0.historyDeletedAt == nil }
            .reduce(0) { $0 + $1.tasks.filter { $0.phase.isPending }.count }
    }

    static func suspend(_ id: UUID, in jobs: inout [BatchJob], now: Date = Date()) -> Bool {
        var changed = false
        for index in jobs.indices where (jobs[index].executionSessionID ?? jobs[index].id) == id
            && jobs[index].historyDeletedAt == nil
            && jobs[index].tasks.contains(where: { !$0.phase.isTerminal }) {
            guard jobs[index].executionSuspendedAt == nil else { continue }
            jobs[index].executionSuspendedAt = now
            jobs[index].updatedAt = now
            changed = true
        }
        return changed
    }

    static func resume(_ id: UUID, in jobs: inout [BatchJob], now: Date = Date()) -> Bool {
        var changed = false
        for index in jobs.indices where (jobs[index].executionSessionID ?? jobs[index].id) == id
            && jobs[index].historyDeletedAt == nil && jobs[index].executionSuspendedAt != nil {
            jobs[index].executionSuspendedAt = nil
            for taskIndex in jobs[index].tasks.indices {
                let phase = jobs[index].tasks[taskIndex].phase
                // PhotoKit may already have submitted the external transaction.
                // Only its existing receipt reconciliation can resolve that phase.
                guard !phase.isTerminal && phase != .savingToPhotoLibrary else { continue }
                jobs[index].tasks[taskIndex].phase = .queued
                jobs[index].tasks[taskIndex].renderedFileURL = nil
                jobs[index].tasks[taskIndex].progress = .init(stage: .waitingToResume)
            }
            jobs[index].state = BatchQueueTransitionPolicy().derivedJobState(from: jobs[index].tasks.map(\.phase))
            jobs[index].updatedAt = now
            changed = true
        }
        return changed
    }
}
