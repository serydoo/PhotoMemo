import Foundation
import Testing
@testable import MemoMark

@Suite("Batch queue history")
struct BatchQueueHistoryTests {

    @Test("Does not trim terminal history within the retention limit")
    func doesNotTrimTerminalHistoryWithinTheRetentionLimit() {

        let history =
            BatchQueueHistory()
        var jobs =
            (0..<120).map {
                makeTerminalJob(
                    title: "Job \($0)"
                )
            }
        let originalJobs = jobs

        _ = history.trimTerminalJobHistoryIfNeeded(
            &jobs
        )

        #expect(jobs == originalJobs)
    }

    @Test("Trims only the oldest terminal jobs beyond the retention limit")
    func trimsOnlyTheOldestTerminalJobsBeyondTheRetentionLimit() {

        let history =
            BatchQueueHistory()
        var jobs =
            (0..<121).map {
                makeTerminalJob(
                    title: "Job \($0)"
                )
            }
        let expectedRemovedTaskIDs = Set(
            jobs.last?.tasks.map {
                $0.id.uuidString
            } ?? []
        )

        let removedTaskIDs = history.trimTerminalJobHistoryIfNeeded(
            &jobs
        )

        #expect(jobs.count == 120)
        #expect(jobs.map(\.title).first == "Job 0")
        #expect(jobs.map(\.title).last == "Job 119")
        #expect(removedTaskIDs == expectedRemovedTaskIDs)
    }

    @Test("Managed source cleanup waits for durable history commit")
    func managedSourceCleanupWaitsForCommit() throws {
        let intakeDirectoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: intakeDirectoryURL,
            withIntermediateDirectories: true
        )
        defer { try? FileManager.default.removeItem(at: intakeDirectoryURL) }
        let managedSourceURL = intakeDirectoryURL
            .appendingPathComponent("managed-source.jpg")
        try Data("source".utf8).write(to: managedSourceURL)
        let history = BatchQueueHistory(
            externalIntakeStore: ExternalPhotoIntakeStore(
                defaults: UserDefaults.standard,
                intakeDirectoryURL: intakeDirectoryURL
            )
        )
        var jobs = (0..<120).map {
            makeTerminalJob(title: "Retained \($0)")
        }
        jobs.append(
            makeTerminalJob(
                title: "Removed",
                sourceURL: managedSourceURL
            )
        )

        _ = history.trimTerminalJobHistoryIfNeeded(&jobs)

        #expect(
            FileManager.default.fileExists(
                atPath: managedSourceURL.path
            )
        )

        history.commitResourceCleanup(retaining: jobs)

        #expect(
            !FileManager.default.fileExists(
                atPath: managedSourceURL.path
            )
        )
    }

    @Test("Reconciliation removes orphaned notification attachments and preserves referenced files")
    func reconciliationRemovesOnlyUnreferencedNotificationAttachments() throws {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "MemoMark.BatchQueueHistory.Attachments.\(UUID().uuidString)",
                isDirectory: true
            )
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
        defer { try? FileManager.default.removeItem(at: directoryURL) }

        let referencedURL = directoryURL.appendingPathComponent("referenced.jpg")
        let orphanedURL = directoryURL.appendingPathComponent("orphaned.jpg")
        try Data("referenced".utf8).write(to: referencedURL)
        try Data("orphaned".utf8).write(to: orphanedURL)
        let history = BatchQueueHistory(
            notificationAttachmentsDirectoryURL: directoryURL
        )
        var jobs = [
            makeTerminalJob(
                title: "Retained",
                notificationAttachmentURL: referencedURL
            )
        ]

        _ = history.trimTerminalJobHistoryIfNeeded(&jobs)
        history.commitResourceCleanup(retaining: jobs)

        #expect(FileManager.default.fileExists(atPath: referencedURL.path))
        #expect(FileManager.default.fileExists(atPath: orphanedURL.path))

        _ = history.trimTerminalJobHistoryIfNeeded(&jobs)
        history.commitResourceCleanup(retaining: jobs)

        #expect(!FileManager.default.fileExists(atPath: orphanedURL.path))
    }

    @Test("Cleared failure and cancellation references release their notification attachments")
    func clearedTerminalReferencesReleaseNotificationAttachments() throws {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "MemoMark.BatchQueueHistory.TerminalAttachments.\(UUID().uuidString)",
                isDirectory: true
            )
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
        defer { try? FileManager.default.removeItem(at: directoryURL) }

        let failedURL = directoryURL.appendingPathComponent("failed.jpg")
        let cancelledURL = directoryURL.appendingPathComponent("cancelled.jpg")
        try Data("failed".utf8).write(to: failedURL)
        try Data("cancelled".utf8).write(to: cancelledURL)
        let history = BatchQueueHistory(
            notificationAttachmentsDirectoryURL: directoryURL
        )
        var jobs = [
            BatchJob(
                title: "Terminal",
                state: .failed,
                configuration:
                    BatchConfigurationSnapshot(
                        template: .classicWhite,
                        badge: nil,
                        anchor: nil,
                        shouldWritePhotoDescription: true,
                        photoDescriptionOverride: "",
                        selectedAlbumIdentifier: ""
                    ),
                tasks: [
                    BatchTask(
                        sourceURL: URL(fileURLWithPath: "/tmp/failed.jpg"),
                        phase: .failed,
                        notificationAttachmentURL: nil
                    ),
                    BatchTask(
                        sourceURL: URL(fileURLWithPath: "/tmp/cancelled.jpg"),
                        phase: .cancelled,
                        notificationAttachmentURL: nil
                    )
                ]
            )
        ]

        _ = history.trimTerminalJobHistoryIfNeeded(&jobs)
        history.commitResourceCleanup(retaining: jobs)

        #expect(FileManager.default.fileExists(atPath: failedURL.path))
        #expect(FileManager.default.fileExists(atPath: cancelledURL.path))

        _ = history.trimTerminalJobHistoryIfNeeded(&jobs)
        history.commitResourceCleanup(retaining: jobs)

        #expect(!FileManager.default.fileExists(atPath: failedURL.path))
        #expect(!FileManager.default.fileExists(atPath: cancelledURL.path))
    }

    @Test("Missing history cover references heal back to nil")
    func missingHistoryCoverReferenceHeals() throws {
        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("MemoMark.HistoryCover.Missing.\(UUID().uuidString)")
        let coversURL = rootURL.appendingPathComponent("TaskHistoryCovers", isDirectory: true)
        try FileManager.default.createDirectory(
            at: coversURL,
            withIntermediateDirectories: true
        )
        defer { try? FileManager.default.removeItem(at: rootURL) }

        var job = makeTerminalJob(title: "Missing cover")
        job.historyCover = BatchJobHistoryCover(
            sourceTaskID: job.tasks[0].id,
            relativePath: "TaskHistoryCovers/\(job.id.uuidString).jpg"
        )
        var jobs = [job]
        let history = BatchQueueHistory(historyCoversDirectoryURL: coversURL)

        _ = history.trimTerminalJobHistoryIfNeeded(&jobs)

        #expect(jobs[0].historyCover == nil)
    }

    @Test("Delivered final notification attachments are released after a durable cover exists")
    func deliveredNotificationAttachmentsAreReleased() throws {
        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("MemoMark.HistoryCover.Release.\(UUID().uuidString)")
        let coversURL = rootURL.appendingPathComponent("TaskHistoryCovers", isDirectory: true)
        let attachmentsURL = rootURL.appendingPathComponent("NotificationAttachments", isDirectory: true)
        try FileManager.default.createDirectory(at: coversURL, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: attachmentsURL, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: rootURL) }

        var job = makeTerminalJob(
            title: "Covered",
            notificationAttachmentURL: attachmentsURL.appendingPathComponent("task.jpg")
        )
        let cover = try #require(BatchJobHistoryCover(
            sourceTaskID: job.tasks[0].id,
            relativePath: "TaskHistoryCovers/\(job.id.uuidString).jpg"
        ))
        job.historyCover = cover
        job.finalNotificationSentAt = Date()
        try Data("cover".utf8).write(
            to: coversURL.appendingPathComponent("\(job.id.uuidString).jpg")
        )
        try Data("attachment".utf8).write(
            to: try #require(job.tasks[0].notificationAttachmentURL)
        )
        var jobs = [job]
        let history = BatchQueueHistory(
            notificationAttachmentsDirectoryURL: attachmentsURL,
            historyCoversDirectoryURL: coversURL
        )

        _ = history.trimTerminalJobHistoryIfNeeded(&jobs)

        #expect(jobs[0].historyCover == cover)
        #expect(jobs[0].tasks[0].notificationAttachmentURL == nil)
    }

    @Test("Pending final notification keeps its attachment")
    func pendingNotificationKeepsAttachment() throws {
        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("MemoMark.HistoryCover.Pending.\(UUID().uuidString)")
        let coversURL = rootURL.appendingPathComponent("TaskHistoryCovers", isDirectory: true)
        try FileManager.default.createDirectory(at: coversURL, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: rootURL) }

        let attachmentURL = rootURL.appendingPathComponent("task.jpg")
        var job = makeTerminalJob(
            title: "Pending",
            notificationAttachmentURL: attachmentURL
        )
        job.historyCover = BatchJobHistoryCover(
            sourceTaskID: job.tasks[0].id,
            relativePath: "TaskHistoryCovers/\(job.id.uuidString).jpg"
        )
        try Data("cover".utf8).write(
            to: coversURL.appendingPathComponent("\(job.id.uuidString).jpg")
        )
        var jobs = [job]
        let history = BatchQueueHistory(historyCoversDirectoryURL: coversURL)

        _ = history.trimTerminalJobHistoryIfNeeded(&jobs)

        #expect(jobs[0].tasks[0].notificationAttachmentURL == attachmentURL)
    }

    @Test("Orphaned covers require two durable reconciliation passes before deletion")
    func orphanedCoversUseTwoPassCleanup() throws {
        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("MemoMark.HistoryCover.Orphan.\(UUID().uuidString)")
        let coversURL = rootURL.appendingPathComponent("TaskHistoryCovers", isDirectory: true)
        try FileManager.default.createDirectory(at: coversURL, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: rootURL) }
        let orphanURL = coversURL.appendingPathComponent("orphan.jpg")
        let inProgressURL = coversURL.appendingPathComponent(".in-progress.tmp")
        try Data("orphan".utf8).write(to: orphanURL)
        try Data("temporary".utf8).write(to: inProgressURL)
        let history = BatchQueueHistory(historyCoversDirectoryURL: coversURL)

        history.commitResourceCleanup(retaining: [])
        #expect(FileManager.default.fileExists(atPath: orphanURL.path))
        #expect(FileManager.default.fileExists(atPath: inProgressURL.path))

        history.commitResourceCleanup(retaining: [])
        #expect(!FileManager.default.fileExists(atPath: orphanURL.path))
        #expect(FileManager.default.fileExists(atPath: inProgressURL.path))
    }

    @Test("History trimming does not delete an attachment still referenced by a retained task")
    func historyTrimmingPreservesSharedReferencedAttachment() throws {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "MemoMark.BatchQueueHistory.SharedAttachment.\(UUID().uuidString)",
                isDirectory: true
            )
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
        defer { try? FileManager.default.removeItem(at: directoryURL) }

        let sharedURL = directoryURL.appendingPathComponent("shared.jpg")
        let removedOnlyURL = directoryURL.appendingPathComponent("removed.jpg")
        try Data("shared".utf8).write(to: sharedURL)
        try Data("removed".utf8).write(to: removedOnlyURL)
        let history = BatchQueueHistory(
            notificationAttachmentsDirectoryURL: directoryURL
        )
        var jobs = (0..<119).map {
            makeTerminalJob(title: "Job \($0)")
        }
        jobs.append(
            makeTerminalJob(
                title: "Retained shared",
                notificationAttachmentURL: sharedURL
            )
        )
        jobs.append(
            makeTerminalJob(
                title: "Removed shared",
                notificationAttachmentURL: sharedURL
            )
        )
        jobs.append(
            makeTerminalJob(
                title: "Removed only",
                notificationAttachmentURL: removedOnlyURL
            )
        )

        _ = history.trimTerminalJobHistoryIfNeeded(&jobs)
        history.commitResourceCleanup(retaining: jobs)

        #expect(FileManager.default.fileExists(atPath: sharedURL.path))
        #expect(FileManager.default.fileExists(atPath: removedOnlyURL.path))

        _ = history.trimTerminalJobHistoryIfNeeded(&jobs)
        history.commitResourceCleanup(retaining: jobs)

        #expect(!FileManager.default.fileExists(atPath: removedOnlyURL.path))
    }

    @Test("Usage snapshot prefers frozen configuration anchor over legacy batch anchor")
    func usageSnapshotPrefersFrozenConfigurationAnchorOverLegacyBatchAnchor() throws {
        let history =
            BatchQueueHistory()
        let job =
            makeTerminalJob(
                title: "Frozen anchor job",
                configuration:
                    try frozenAnchorConfiguration()
            )

        let snapshot =
            history.usageSnapshot(
                for: [
                    job
                ]
            )

        #expect(
            snapshot.anchorChampion?.title
            == "冻结生日"
        )
        #expect(
            snapshot.anchorChampion?.count
            == 1
        )
    }

    @Test("External intake summary prefers frozen configuration anchor over legacy batch anchor")
    func externalIntakeSummaryPrefersFrozenConfigurationAnchorOverLegacyBatchAnchor() throws {
        let history =
            BatchQueueHistory()
        let job =
            makeTerminalJob(
                title: "External frozen anchor job",
                launchSource: .shareExtension,
                configuration:
                    try frozenAnchorConfiguration()
            )

        let summary =
            try #require(
                history.latestExternalIntakeSummary(
                    for: [
                        job
                    ]
                )
            )

        #expect(
            summary.anchorTitle
            == "冻结生日"
        )
    }

    @Test("Usage snapshot treats frozen missing anchor as authoritative")
    func usageSnapshotTreatsFrozenMissingAnchorAsAuthoritative() throws {
        let history =
            BatchQueueHistory()
        let job =
            makeTerminalJob(
                title: "Frozen no anchor job",
                configuration:
                    try frozenNoAnchorConfiguration()
            )

        let snapshot =
            history.usageSnapshot(
                for: [
                    job
                ]
            )

        #expect(
            snapshot.anchorChampion
            == nil
        )
    }

    @Test("External intake summary treats frozen missing anchor as authoritative")
    func externalIntakeSummaryTreatsFrozenMissingAnchorAsAuthoritative() throws {
        let history =
            BatchQueueHistory()
        let job =
            makeTerminalJob(
                title: "External frozen no anchor job",
                launchSource: .shareExtension,
                configuration:
                    try frozenNoAnchorConfiguration()
            )

        let summary =
            try #require(
                history.latestExternalIntakeSummary(
                    for: [
                        job
                    ]
                )
            )

        #expect(
            summary.anchorTitle
            == nil
        )
    }

    @Test("Completed frozen configuration snapshot embeds paired frozen subject")
    func completedFrozenConfigurationSnapshotEmbedsPairedFrozenSubject() throws {
        let subject =
            try #require(
                ConfigurationCenterState
                    .mock
                    .selectedSubject
            )
        var frozenSnapshot =
            ConfigurationSnapshotBuilder.build(
                from: subject
            )
        frozenSnapshot.memorySubject = nil
        let configuration =
            BatchConfigurationSnapshot(
                template: .classicWhite,
                badge: nil,
                anchor: nil,
                shouldWritePhotoDescription: true,
                photoDescriptionOverride: "",
                selectedAlbumIdentifier: ""
            )
            .withLegacyPairedFrozenMemoryConfiguration(
                subject: subject,
                snapshot: frozenSnapshot
            )

        let completedSnapshot =
            try #require(
                configuration
                    .completedFrozenConfigurationSnapshot
            )

        #expect(
            completedSnapshot.memorySubject
            == subject
        )
    }

    @Test("Completed frozen configuration snapshot requires embedded subject")
    func completedFrozenConfigurationSnapshotRequiresEmbeddedSubject() throws {
        let subject =
            try #require(
                ConfigurationCenterState
                    .mock
                    .selectedSubject
            )
        var frozenSnapshot =
            ConfigurationSnapshotBuilder.build(
                from: subject
            )
        frozenSnapshot.memorySubject = nil
        let configuration =
            BatchConfigurationSnapshot(
                template: .classicWhite,
                badge: nil,
                anchor: nil,
                shouldWritePhotoDescription: true,
                photoDescriptionOverride: "",
                selectedAlbumIdentifier: ""
            )
            .withCanonicalProductionSnapshot(
                frozenSnapshot
            )

        #expect(
            configuration
                .completedFrozenConfigurationSnapshot
            == nil
        )
    }

    @Test("Production anchor title ignores incomplete frozen snapshot")
    func productionAnchorTitleIgnoresIncompleteFrozenSnapshot() throws {
        let subject =
            try #require(
                ConfigurationCenterState
                    .mock
                    .selectedSubject
            )
        var frozenSnapshot =
            ConfigurationSnapshotBuilder.build(
                from: subject
            )
        frozenSnapshot.memorySubject = nil
        let legacyAnchor =
            Anchor(
                type: .birthday,
                title: "Legacy Birthday",
                date: Date(),
                isCountdown: false
            )
        let configuration =
            BatchConfigurationSnapshot(
                template: .classicWhite,
                badge: nil,
                anchor: legacyAnchor,
                shouldWritePhotoDescription: true,
                photoDescriptionOverride: "",
                selectedAlbumIdentifier: ""
            )
            .withCanonicalProductionSnapshot(
                frozenSnapshot
            )

        #expect(
            configuration.resolvedProductionAnchorTitle
            == "Legacy Birthday"
        )
    }
}

private extension BatchQueueHistoryTests {

    func makeTerminalJob(
        title: String,
        launchSource: BatchJobLaunchSource =
            .inAppPreview,
        sourceURL: URL? = nil,
        notificationAttachmentURL: URL? = nil,
        configuration:
            BatchConfigurationSnapshot? = nil
    ) -> BatchJob {

        BatchJob(
            title: title,
            state: .completed,
            launchSource:
                launchSource,
            configuration:
                configuration
                ?? BatchConfigurationSnapshot(
                    template: .classicWhite,
                    badge: nil,
                    anchor: nil,
                    shouldWritePhotoDescription: true,
                    photoDescriptionOverride: "",
                    selectedAlbumIdentifier: ""
                ),
            tasks: [
                BatchTask(
                    sourceURL:
                        sourceURL
                        ?? URL(
                            fileURLWithPath:
                                "/tmp/\(title).jpg"
                        ),
                    phase: .completed,
                    notificationAttachmentURL:
                        notificationAttachmentURL
                )
            ]
        )
    }

    func frozenAnchorConfiguration() throws
    -> BatchConfigurationSnapshot {
        let anchorDate =
            Date(
                timeIntervalSince1970:
                    1_725_206_400
            )
        let legacyAnchor =
            Anchor(
                type: .birthday,
                title: "旧生日",
                date: anchorDate
            )
        let frozenAnchor =
            MemoryAnchor(
                title: "冻结生日",
                date: anchorDate,
                anchorType: .birthday
            )
        let configuration =
            BatchConfigurationSnapshot(
                template: .classicWhite,
                badge: nil,
                anchor: legacyAnchor,
                shouldWritePhotoDescription: true,
                photoDescriptionOverride: "",
                selectedAlbumIdentifier: ""
            )
        let subject =
            try #require(
                ConfigurationCenterState
                    .mock
                    .selectedSubject
            )
        var frozenSnapshot =
            ConfigurationSnapshotBuilder.build(
                from: subject
            )
        frozenSnapshot.primaryAnchor =
            frozenAnchor
        return configuration
            .withCanonicalProductionSnapshot(
                frozenSnapshot
            )
    }

    func frozenNoAnchorConfiguration() throws
    -> BatchConfigurationSnapshot {
        let anchorDate =
            Date(
                timeIntervalSince1970:
                    1_725_206_400
            )
        let legacyAnchor =
            Anchor(
                type: .birthday,
                title: "旧生日",
                date: anchorDate
            )
        let configuration =
            BatchConfigurationSnapshot(
                template: .classicWhite,
                badge: nil,
                anchor: legacyAnchor,
                shouldWritePhotoDescription: true,
                photoDescriptionOverride: "",
                selectedAlbumIdentifier: ""
            )
        let subject =
            try #require(
                ConfigurationCenterState
                    .mock
                    .selectedSubject
            )
        var frozenSnapshot =
            ConfigurationSnapshotBuilder.build(
                from: subject
            )
        frozenSnapshot.primaryAnchor = nil
        return configuration
            .withCanonicalProductionSnapshot(
                frozenSnapshot
            )
    }
}
