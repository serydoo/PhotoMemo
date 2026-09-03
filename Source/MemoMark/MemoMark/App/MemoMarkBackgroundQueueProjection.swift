#if !MEMOMARK_SHARE_EXTENSION
import Foundation

struct MemoMarkBackgroundQueueProjection {
    let textCatalog: MemoMarkBackgroundStatusTextCatalog

    func queueLines(jobs: [BatchJob], activeJobID: UUID, activeTaskID: UUID?) -> [String] {
        let displayable = displayableJobs(jobs, activeJobID: activeJobID)
        let activeOrWaiting = displayable.filter { !$0.tasks.allSatisfy { $0.phase.isTerminal } }
        if activeOrWaiting.count >= 4 { return [aggregateLine(displayable)] }
        return displayable.prefix(3).map { job in
            "\(textCatalog.queueDisplayTitle(for: job)) · \(textCatalog.queueLineBody(for: job, activeTaskID: job.id == activeJobID ? activeTaskID : nil))"
        }
    }

    func overflowQueueCount(jobs: [BatchJob], activeJobID: UUID) -> Int {
        max(displayableJobs(jobs, activeJobID: activeJobID).count - 3, 0)
    }

    func queuedJobCount(in jobs: [BatchJob], excluding activeJobID: UUID) -> Int {
        jobs.filter { $0.id != activeJobID && $0.launchSource != .inAppPreview && $0.tasks.contains { !$0.phase.isTerminal } }.count
    }

    private func aggregateLine(_ jobs: [BatchJob]) -> String {
        textCatalog.aggregateQueueLine(
            runningCount: jobs.reduce(0) { $0 + $1.tasks.filter { !$0.phase.isTerminal && $0.phase != .queued }.count },
            waitingCount: jobs.reduce(0) { $0 + $1.tasks.filter { $0.phase == .queued }.count },
            completedCount: jobs.reduce(0) { $0 + $1.completedTaskCount },
            failedCount: jobs.reduce(0) { $0 + $1.failedTaskCount }
        )
    }

    private func displayableJobs(_ jobs: [BatchJob], activeJobID: UUID) -> [BatchJob] {
        jobs.filter { $0.launchSource != .inAppPreview }.sorted {
            priority($0, activeJobID: activeJobID) < priority($1, activeJobID: activeJobID)
        }
    }

    private func priority(_ job: BatchJob, activeJobID: UUID) -> Int {
        if job.id == activeJobID { return 0 }
        if job.hasRetryableFailures || job.failedTaskCount > 0 { return 1 }
        return job.tasks.allSatisfy { $0.phase.isTerminal } ? 3 : 2
    }
}
#endif
