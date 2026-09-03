#if !MEMOMARK_SHARE_EXTENSION
import Foundation

/// Applies the durable queue's bounded-history contract before a candidate
/// snapshot is written. File deletion is deliberately excluded: callers may
/// reclaim resources only after the retained snapshot commits successfully.
nonisolated struct BatchQueueRetentionPolicy:
    Sendable {

    private let maxRetainedTerminalJobs: Int
    private let maxRetainedHistoryCovers: Int
    private let maximumHistoryCoverAge: TimeInterval
    private let maximumHistoryCoverBytes: Int64
    private let historyCoversBaseDirectoryURL: URL

    init(
        maxRetainedTerminalJobs: Int = 120,
        maxRetainedHistoryCovers: Int = 60,
        maximumHistoryCoverAge: TimeInterval = 60 * 24 * 60 * 60,
        maximumHistoryCoverBytes: Int64 = 30 * 1_024 * 1_024,
        historyCoversDirectoryURL: URL =
            MemoMarkSharedContainer.baseDirectoryURL
            .appendingPathComponent(
                "TaskHistoryCovers",
                isDirectory: true
            )
    ) {
        self.maxRetainedTerminalJobs = maxRetainedTerminalJobs
        self.maxRetainedHistoryCovers = maxRetainedHistoryCovers
        self.maximumHistoryCoverAge = maximumHistoryCoverAge
        self.maximumHistoryCoverBytes = maximumHistoryCoverBytes
        historyCoversBaseDirectoryURL =
            historyCoversDirectoryURL.deletingLastPathComponent()
    }

    func apply(
        to jobs: inout [BatchJob],
        now: Date = Date()
    ) {
        trimTerminalJobs(&jobs)
        trimHistoryCovers(&jobs, now: now)
    }

    private func trimTerminalJobs(
        _ jobs: inout [BatchJob]
    ) {
        guard jobs.count > maxRetainedTerminalJobs else {
            return
        }

        var retainedTerminalCount = 0
        jobs = jobs.filter { job in
            guard job.tasks.allSatisfy(\.phase.isTerminal) else {
                return true
            }

            retainedTerminalCount += 1
            return retainedTerminalCount
                <= maxRetainedTerminalJobs
        }
    }

    private func trimHistoryCovers(
        _ jobs: inout [BatchJob],
        now: Date
    ) {
        var retainedCount = 0
        var retainedBytes: Int64 = 0
        let orderedIndices = jobs.indices.sorted {
            (jobs[$0].historyCover?.createdAt ?? .distantPast)
                > (jobs[$1].historyCover?.createdAt ?? .distantPast)
        }

        for index in orderedIndices {
            guard let cover = jobs[index].historyCover,
                  let url = BatchTaskResourceLifecycle.historyCoverURL(
                    for: cover,
                    baseDirectoryURL:
                        historyCoversBaseDirectoryURL
                  ) else {
                jobs[index].historyCover = nil
                continue
            }
            guard let values = try? url.resourceValues(
                forKeys: [
                    .isRegularFileKey,
                    .isSymbolicLinkKey,
                    .fileSizeKey
                ]
            ), values.isRegularFile == true,
               values.isSymbolicLink != true else {
                jobs[index].historyCover = nil
                continue
            }

            let bytes = Int64(values.fileSize ?? 0)
            let isExpired =
                now.timeIntervalSince(cover.createdAt)
                > maximumHistoryCoverAge
            let exceedsCount =
                retainedCount >= maxRetainedHistoryCovers
            let exceedsBytes =
                retainedBytes + bytes
                > maximumHistoryCoverBytes

            if isExpired || exceedsCount || exceedsBytes {
                jobs[index].historyCover = nil
            } else {
                retainedCount += 1
                retainedBytes += bytes
            }
        }

        for index in jobs.indices
        where jobs[index].historyCover != nil
            && jobs[index].finalNotificationSentAt != nil
            && jobs[index].tasks.allSatisfy({ $0.phase.isTerminal }) {
            for taskIndex in jobs[index].tasks.indices {
                jobs[index].tasks[taskIndex]
                    .notificationAttachmentURL = nil
            }
        }
    }
}
#endif
