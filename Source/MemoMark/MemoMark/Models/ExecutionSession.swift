import Foundation

/// Durable membership lives on each BatchJob; this value projects a continuous
/// user intent without introducing another independently persisted queue.
nonisolated struct ExecutionSession: Identifiable, Hashable, Sendable {
    let id: UUID
    let jobIDs: [UUID]
    let totalCount: Int
    let completedCount: Int
    let failedCount: Int
    let pendingCount: Int
    let totalProgressUnits: Int
    let completedProgressUnits: Int
    let currentStage: BatchTaskProgressStage?

    init(id: UUID, jobs: [BatchJob], pendingIntakeTaskCount: Int = 0) {
        self.id = id
        let members = jobs.filter { ($0.executionSessionID ?? $0.id) == id }
        jobIDs = members.map(\.id)
        let tasks = members.flatMap(\.tasks)
        let awaitingAdmission = max(pendingIntakeTaskCount, 0)
        totalCount = tasks.count + awaitingAdmission
        completedCount = tasks.filter { $0.phase == .completed }.count
        failedCount = tasks.filter { $0.phase == .failed }.count
        pendingCount = tasks.filter { !$0.phase.isTerminal }.count + awaitingAdmission
        totalProgressUnits = max(totalCount, 1) * 100
        completedProgressUnits = tasks.reduce(0) { units, task in
            units + (task.phase == .completed ? 100 : Int(min(task.progress.fractionCompleted, 0.95) * 100))
        }
        currentStage = tasks.first(where: { !$0.phase.isTerminal && $0.phase != .queued })?.progress.stage
    }
}
