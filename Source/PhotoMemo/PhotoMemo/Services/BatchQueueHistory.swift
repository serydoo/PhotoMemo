#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

final class BatchQueueHistory {

    private let maxRetainedTerminalJobs =
        120

    private let externalIntakeStore:
        ExternalPhotoIntakeStore

    private let notificationAttachmentsDirectoryURL:
        URL

    private var pendingNotificationAttachmentCleanupURLs:
        Set<URL> = []

    private var pendingManagedSourceCleanupURLs:
        Set<URL> = []

    init(
        externalIntakeStore:
            ExternalPhotoIntakeStore? = nil,
        notificationAttachmentsDirectoryURL: URL =
            PhotoMemoSharedContainer.baseDirectoryURL
            .appendingPathComponent(
                "NotificationAttachments",
                isDirectory: true
            )
    ) {
        self.externalIntakeStore =
            externalIntakeStore
            ?? .shared
        self.notificationAttachmentsDirectoryURL =
            notificationAttachmentsDirectoryURL
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

        return removedTaskIDStrings
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
    }
}
#endif
