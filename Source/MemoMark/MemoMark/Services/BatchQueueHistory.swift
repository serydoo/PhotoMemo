#if !MEMOMARK_SHARE_EXTENSION
import Foundation

final class BatchQueueHistory {

    private let maxRetainedTerminalJobs =
        120
    private let maxRetainedHistoryCovers = 60
    private let maximumHistoryCoverAge: TimeInterval = 60 * 24 * 60 * 60
    private let maximumHistoryCoverBytes: Int64 = 30 * 1_024 * 1_024

    private let externalIntakeStore:
        ExternalPhotoIntakeStore

    private let notificationAttachmentsDirectoryURL:
        URL
    private let historyCoversDirectoryURL: URL

    private var pendingNotificationAttachmentCleanupURLs:
        Set<URL> = []

    private var pendingManagedSourceCleanupURLs:
        Set<URL> = []
    private var pendingHistoryCoverCleanupURLs: Set<URL> = []
    private var previouslyUnreferencedHistoryCoverURLs: Set<URL> = []

    init(
        externalIntakeStore:
            ExternalPhotoIntakeStore? = nil,
        notificationAttachmentsDirectoryURL: URL =
            MemoMarkSharedContainer.baseDirectoryURL
            .appendingPathComponent(
                "NotificationAttachments",
                isDirectory: true
            ),
        historyCoversDirectoryURL: URL =
            MemoMarkSharedContainer.baseDirectoryURL.appendingPathComponent(
                "TaskHistoryCovers",
                isDirectory: true
            )
    ) {
        self.externalIntakeStore =
            externalIntakeStore
            ?? .shared
        self.notificationAttachmentsDirectoryURL =
            notificationAttachmentsDirectoryURL
        self.historyCoversDirectoryURL = historyCoversDirectoryURL
    }

    func usageSnapshot(
        for jobs: [BatchJob]
    ) -> BatchUsageSnapshot {

        let completedTasks =
            jobs.flatMap(\.tasks).filter {
                $0.phase == .completed
            }

        let failedTasks =
            jobs.flatMap(\.tasks).filter {
                $0.phase == .failed
            }

        let activeTasks =
            jobs.flatMap(\.tasks).filter {
                !$0.phase.isTerminal
            }

        let completedBatchCount =
            jobs.filter {
                $0.completedTaskCount > 0
            }.count

        var templateCounts:
            [String: Int] = [:]

        var anchorCounts:
            [String: Int] = [:]

        for job in jobs {
            let completedCount =
                job.tasks.filter {
                    $0.phase == .completed
                }.count

            guard completedCount > 0 else {
                continue
            }

            let templateName = job.configuration.template.displayName(
                for: job.configuration.language
            )
            templateCounts[
                templateName
            ] = (
                templateCounts[
                    templateName
                ] ?? 0
            ) + completedCount

            if let anchorTitle =
                job.configuration
                .resolvedProductionAnchorTitle {
                anchorCounts[anchorTitle] = (
                    anchorCounts[
                        anchorTitle
                    ] ?? 0
                ) + completedCount
            }
        }

        let templateChampion =
            templateCounts.max {
                $0.value < $1.value
            }
            .map {
                BatchUsageLeaderboardEntry(
                    title: $0.key,
                    count: $0.value
                )
            }

        let anchorChampion =
            anchorCounts.max {
                $0.value < $1.value
            }
            .map {
                BatchUsageLeaderboardEntry(
                    title: $0.key,
                    count: $0.value
                )
            }

        let lastCompletedAt =
            jobs.flatMap { job in
                job.tasks.compactMap { task in
                    task.phase == .completed
                    ? job.updatedAt
                    : nil
                }
            }
            .max()

        return BatchUsageSnapshot(
            completedPhotoCount:
                completedTasks.count,
            completedBatchCount:
                completedBatchCount,
            failedPhotoCount:
                failedTasks.count,
            activePhotoCount:
                activeTasks.count,
            templateChampion:
                templateChampion,
            anchorChampion:
                anchorChampion,
            lastCompletedAt:
                lastCompletedAt
        )
    }

    func latestFailureSummary(
        for jobs: [BatchJob]
    ) -> BatchFailureSummary? {

        jobs
            .filter {
                $0.failedTaskCount > 0
            }
            .sorted {
                $0.updatedAt > $1.updatedAt
            }
            .compactMap { job -> BatchFailureSummary? in

                guard let latestFailure =
                    job.latestFailure else {
                    return nil
                }

                return BatchFailureSummary(
                    jobID: job.id,
                    jobTitle: job.title,
                    failedTaskCount:
                        job.failedTaskCount,
                    completedTaskCount:
                        job.completedTaskCount,
                    totalTaskCount:
                        job.totalTaskCount,
                    hasRetryableFailures:
                        job.hasRetryableFailures,
                    latestFailure:
                        latestFailure,
                    updatedAt: job.updatedAt
                )
            }
            .first
    }

    func recentFailureRecords(
        for jobs: [BatchJob]
    ) -> [BatchFailureRecord] {

        jobs.flatMap { job in
            job.tasks.compactMap { task in

                guard let failure =
                    task.failure else {
                    return nil
                }

                return BatchFailureRecord(
                    id:
                        "\(job.id.uuidString)-\(task.id.uuidString)-\(failure.timestamp.timeIntervalSince1970)",
                    jobID: job.id,
                    jobTitle: job.title,
                    taskID: task.id,
                    fileName: task.fileName,
                    retryCount: task.retryCount,
                    failure: failure
                )
            }
        }
        .sorted {
            $0.failure.timestamp
            > $1.failure.timestamp
        }
    }

    func latestExternalIntakeSummary(
        for jobs: [BatchJob]
    ) -> ExternalIntakeSummary? {

        jobs
            .filter {
                $0.launchSource != .inAppPreview
            }
            .sorted {
                $0.updatedAt > $1.updatedAt
            }
            .first
            .map { job in

                let trimmedTemplateName =
                    job.configuration.template.displayName(
                        for: job.configuration.language
                    )
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )

                let templateName =
                    trimmedTemplateName.isEmpty
                    ? job.configuration
                        .template.displayName(
                            for: job.configuration.language
                        )
                    : trimmedTemplateName

                return ExternalIntakeSummary(
                    jobID: job.id,
                    title: job.title,
                    launchSource:
                        job.launchSource,
                    taskCount:
                        job.totalTaskCount,
                    state: job.state,
                    templateName:
                        templateName,
                    anchorTitle:
                        job.configuration
                        .resolvedProductionAnchorTitle,
                    importSummary:
                        job.intakeSummary,
                    updatedAt: job.updatedAt
                )
            }
    }

    func referencedManagedSourceURLs(
        for jobs: [BatchJob]
    ) -> Set<URL> {

        Set(
            jobs
                .flatMap(\.tasks)
                .map(\.sourceURL)
                .map {
                    $0.standardizedFileURL
                }
        )
    }

    func trimTerminalJobHistoryIfNeeded(
        _ jobs: inout [BatchJob]
    ) -> Set<String> {

        var retainedTerminalCount = 0
        var removedTaskIDStrings = Set<String>()

        if jobs.count > maxRetainedTerminalJobs {
            jobs = jobs.filter { job in

                let isTerminal =
                    job.tasks.allSatisfy {
                        $0.phase.isTerminal
                    }

                guard isTerminal else {
                    return true
                }

                retainedTerminalCount += 1

                if retainedTerminalCount
                    <= maxRetainedTerminalJobs {
                    return true
                }

                for task in job.tasks {
                    removedTaskIDStrings.insert(
                        task.id.uuidString
                    )
                    pendingManagedSourceCleanupURLs.insert(
                        task.sourceURL.standardizedFileURL
                    )
                }

                return false
            }
        }

        trimHistoryCoversIfNeeded(&jobs, now: Date())
        return removedTaskIDStrings
    }

    private func trimHistoryCoversIfNeeded(
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
                    baseDirectoryURL: historyCoversDirectoryURL.deletingLastPathComponent()
                  ) else {
                jobs[index].historyCover = nil
                continue
            }
            guard let values = try? url.resourceValues(
                forKeys: [.isRegularFileKey, .isSymbolicLinkKey, .fileSizeKey]
            ), values.isRegularFile == true,
               values.isSymbolicLink != true else {
                jobs[index].historyCover = nil
                continue
            }
            let bytes = Int64(values.fileSize ?? 0)
            let isExpired = now.timeIntervalSince(cover.createdAt) > maximumHistoryCoverAge
            let exceedsCount = retainedCount >= maxRetainedHistoryCovers
            let exceedsBytes = retainedBytes + bytes > maximumHistoryCoverBytes

            if isExpired || exceedsCount || exceedsBytes {
                jobs[index].historyCover = nil
                pendingHistoryCoverCleanupURLs.insert(url.standardizedFileURL)
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
                jobs[index].tasks[taskIndex].notificationAttachmentURL = nil
            }
        }
    }

    func commitResourceCleanup(
        retaining jobs: [BatchJob]
    ) {
        let retainedSourceURLs = Set(
            jobs.flatMap(\.tasks).map {
                $0.sourceURL.standardizedFileURL
            }
        )
        for sourceURL in pendingManagedSourceCleanupURLs
        where !retainedSourceURLs.contains(sourceURL) {
            externalIntakeStore.cleanupManagedSourceIfNeeded(
                at: sourceURL
            )
        }
        pendingManagedSourceCleanupURLs.removeAll()

        pendingNotificationAttachmentCleanupURLs =
            BatchTaskResourceLifecycle
            .cleanupUnreferencedNotificationAttachments(
                in:
                    notificationAttachmentsDirectoryURL,
                retaining:
                    Set(
                        jobs
                            .flatMap(\.tasks)
                            .compactMap(
                                \.notificationAttachmentURL
                            )
                    ),
                previouslyUnreferencedURLs:
                    pendingNotificationAttachmentCleanupURLs
            )

        let retainedCoverURLs = Set(jobs.compactMap { job in
            job.historyCover.flatMap {
                BatchTaskResourceLifecycle.historyCoverURL(for: $0)
            }?.standardizedFileURL
        })
        for url in pendingHistoryCoverCleanupURLs
        where !retainedCoverURLs.contains(url) {
            try? FileManager.default.removeItem(at: url)
        }
        pendingHistoryCoverCleanupURLs.removeAll()

        let currentUnreferencedCoverURLs = Set(
            (try? FileManager.default.contentsOfDirectory(
                at: historyCoversDirectoryURL,
                includingPropertiesForKeys: [.isRegularFileKey, .isSymbolicLinkKey],
                options: [.skipsHiddenFiles]
            ))?.compactMap { file -> URL? in
                let normalizedFile = file.standardizedFileURL
                guard !retainedCoverURLs.contains(normalizedFile),
                      let values = try? normalizedFile.resourceValues(
                        forKeys: [.isRegularFileKey, .isSymbolicLinkKey]
                      ), values.isRegularFile == true,
                      values.isSymbolicLink != true else {
                    return nil
                }
                if previouslyUnreferencedHistoryCoverURLs.contains(normalizedFile) {
                    try? FileManager.default.removeItem(at: normalizedFile)
                }
                return normalizedFile
            } ?? []
        )
        previouslyUnreferencedHistoryCoverURLs = currentUnreferencedCoverURLs
    }
}
#endif
