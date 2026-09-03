#if !MEMOMARK_SHARE_EXTENSION
import Foundation

final class BatchQueueHistory {

    private let externalIntakeStore:
        ExternalPhotoIntakeStore

    private let notificationAttachmentsDirectoryURL:
        URL
    private let historyCoversDirectoryURL: URL
    private let retentionPolicy:
        BatchQueueRetentionPolicy

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
        retentionPolicy = BatchQueueRetentionPolicy(
            historyCoversDirectoryURL:
                historyCoversDirectoryURL
        )
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

        let previousJobs = jobs
        retentionPolicy.apply(to: &jobs)
        recordRemovedResources(
            from: previousJobs,
            retaining: jobs
        )
        let retainedTaskIDs = Set(
            jobs.flatMap(\.tasks).map(\.id)
        )
        let removedTaskIDStrings = Set(
            previousJobs
                .flatMap(\.tasks)
                .filter { !retainedTaskIDs.contains($0.id) }
                .map { $0.id.uuidString }
        )
        return removedTaskIDStrings
    }

    func commitResourceCleanup(
        from previousJobs: [BatchJob],
        retaining jobs: [BatchJob]
    ) {
        recordRemovedResources(
            from: previousJobs,
            retaining: jobs
        )
        commitResourceCleanup(retaining: jobs)
    }

    private func recordRemovedResources(
        from previousJobs: [BatchJob],
        retaining jobs: [BatchJob]
    ) {
        let retainedTaskIDs = Set(
            jobs.flatMap(\.tasks).map(\.id)
        )
        for task in previousJobs.flatMap(\.tasks)
        where !retainedTaskIDs.contains(task.id) {
            pendingManagedSourceCleanupURLs.insert(
                task.sourceURL.standardizedFileURL
            )
        }

        let retainedCoverURLs = Set(jobs.compactMap { job in
            job.historyCover.flatMap {
                BatchTaskResourceLifecycle.historyCoverURL(
                    for: $0,
                    baseDirectoryURL:
                        historyCoversDirectoryURL
                        .deletingLastPathComponent()
                )
            }?.standardizedFileURL
        })
        for coverURL in previousJobs.compactMap({ job in
            job.historyCover.flatMap {
                BatchTaskResourceLifecycle.historyCoverURL(
                    for: $0,
                    baseDirectoryURL:
                        historyCoversDirectoryURL
                        .deletingLastPathComponent()
                )
            }?.standardizedFileURL
        })
        where !retainedCoverURLs.contains(coverURL) {
            pendingHistoryCoverCleanupURLs.insert(coverURL)
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
                BatchTaskResourceLifecycle.historyCoverURL(
                    for: $0,
                    baseDirectoryURL:
                        historyCoversDirectoryURL
                        .deletingLastPathComponent()
                )
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
