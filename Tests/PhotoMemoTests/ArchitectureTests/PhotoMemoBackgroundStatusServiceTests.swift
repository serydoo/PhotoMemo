#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@MainActor
@Suite("Background status service")
struct PhotoMemoBackgroundStatusServiceTests {

    @Test("Legacy jobs decode without a history cover")
    func legacyJobCompatibility() throws {
        let configuration = BatchConfigurationSnapshot(
            template: .classicWhite,
            badge: nil,
            anchor: nil,
            shouldWritePhotoDescription: true,
            photoDescriptionOverride: "",
            selectedAlbumIdentifier: ""
        )
        let job = makeJob(
            title: "Legacy",
            source: .shareExtension,
            phase: .completed,
            updatedAt: 100,
            configuration: configuration
        )
        var object = try #require(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(job))
                as? [String: Any]
        )
        object.removeValue(forKey: "historyCover")
        let decoded = try JSONDecoder().decode(
            BatchJob.self,
            from: JSONSerialization.data(withJSONObject: object)
        )
        #expect(decoded.historyCover == nil)
        #expect(decoded.id == job.id)
    }

    @Test("Current snapshot counts only unfinished subsequent external jobs")
    func currentSnapshotCountsOnlyUnfinishedSubsequentExternalJobs() throws {
        let suiteName =
            "PhotoMemo.BackgroundStatusServiceTests.queue.\(UUID().uuidString)"
        let defaults =
            try #require(
                UserDefaults(
                    suiteName: suiteName
                )
            )
        defaults.removePersistentDomain(
            forName: suiteName
        )
        defer {
            defaults.removePersistentDomain(
                forName: suiteName
            )
        }

        let activeJobID = UUID()
        let configuration =
            BatchConfigurationSnapshot(
                template: .classicWhite,
                badge: nil,
                anchor: nil,
                shouldWritePhotoDescription: true,
                photoDescriptionOverride: "",
                selectedAlbumIdentifier: ""
            )
        let jobs = [
            makeJob(
                id: activeJobID,
                title: "Active",
                source: .shareExtension,
                phase: .exporting,
                updatedAt: 500,
                configuration: configuration
            ),
            makeJob(
                title: "Queued 1",
                source: .shareExtension,
                phase: .queued,
                updatedAt: 400,
                configuration: configuration
            ),
            makeJob(
                title: "Queued 2",
                source: .quickAction,
                phase: .queued,
                updatedAt: 300,
                configuration: configuration
            ),
            makeJob(
                title: "Completed",
                source: .shareExtension,
                phase: .completed,
                updatedAt: 200,
                configuration: configuration
            ),
            makeJob(
                title: "Preview",
                source: .inAppPreview,
                phase: .queued,
                updatedAt: 100,
                configuration: configuration
            )
        ]

        defaults.set(
            try JSONEncoder().encode(jobs),
            forKey: "photomemo.batchQueue.jobs"
        )

        let store =
            BatchQueueStore(
                defaults: defaults,
                settingsService:
                    SettingsService(
                        defaults: defaults
                    )
            )
        let service =
            PhotoMemoBackgroundStatusService(
                batchQueueStore: store
            )

        #expect(service.currentSnapshot?.jobID == activeJobID)
        #expect(service.currentSnapshot?.queuedJobCount == 2)
    }

    @Test("Latest completed external job is not masked by older retryable failures")
    func latestCompletedExternalJobIsNotMaskedByOlderRetryableFailures() throws {

        let suiteName =
            "PhotoMemo.BackgroundStatusServiceTests.latest.\(UUID().uuidString)"
        let defaults =
            try #require(
                UserDefaults(
                    suiteName: suiteName
                )
            )
        defaults.removePersistentDomain(
            forName: suiteName
        )

        let olderFailureID =
            UUID()
        let latestCompletedID =
            UUID()
        let configuration =
            BatchConfigurationSnapshot(
                template: .classicWhite,
                badge: nil,
                anchor: nil,
                shouldWritePhotoDescription: true,
                photoDescriptionOverride: "",
                selectedAlbumIdentifier: ""
            )
        let jobs = [
            BatchJob(
                id: latestCompletedID,
                title: "10:22（11张）",
                createdAt:
                    Date(
                        timeIntervalSince1970: 200
                    ),
                updatedAt:
                    Date(
                        timeIntervalSince1970: 220
                    ),
                state: .completed,
                launchSource: .quickAction,
                configuration: configuration,
                tasks: [
                    BatchTask(
                        sourceURL:
                            URL(
                                fileURLWithPath:
                                    "/tmp/latest.heic"
                            ),
                        fileName: "latest.heic",
                        phase: .completed
                    )
                ]
            ),
            BatchJob(
                id: olderFailureID,
                title: "10:13（5张）",
                createdAt:
                    Date(
                        timeIntervalSince1970: 100
                    ),
                updatedAt:
                    Date(
                        timeIntervalSince1970: 120
                    ),
                state: .failed,
                launchSource: .quickAction,
                configuration: configuration,
                tasks: [
                    BatchTask(
                        sourceURL:
                            URL(
                                fileURLWithPath:
                                    "/tmp/older.heic"
                            ),
                        fileName: "older.heic",
                        phase: .failed,
                        failure:
                            BatchTaskFailure(
                                phase: .exporting,
                                message:
                                    "PHPhotosErrorDomain error 3164",
                                canRetry: true
                            )
                    )
                ]
            )
        ]

        defaults.set(
            try JSONEncoder().encode(jobs),
            forKey:
                "photomemo.batchQueue.jobs"
        )

        let store =
            BatchQueueStore(
                defaults: defaults,
                settingsService:
                    SettingsService(
                        defaults: defaults
                    )
            )
        let service =
            PhotoMemoBackgroundStatusService(
                batchQueueStore: store
            )

        #expect(
            service.currentSnapshot?.jobID
            == latestCompletedID
        )
        #expect(
            service.currentSnapshot?.presentationState
            == .completed
        )
        #expect(
            service.currentSnapshot?.feedbackState
            == .completed
        )

        defaults.removePersistentDomain(
            forName: suiteName
        )
    }

    @Test("Recent external job summaries keep the latest ten jobs")
    func recentExternalJobSummariesKeepLatestTenJobs() throws {

        let suiteName =
            "PhotoMemo.BackgroundStatusServiceTests.recent.\(UUID().uuidString)"
        let defaults =
            try #require(
                UserDefaults(
                    suiteName: suiteName
                )
            )
        defaults.removePersistentDomain(
            forName: suiteName
        )

        let configuration =
            BatchConfigurationSnapshot(
                template: .classicWhite,
                badge: nil,
                anchor: nil,
                shouldWritePhotoDescription: true,
                photoDescriptionOverride: "",
                selectedAlbumIdentifier: ""
            )
        let jobs =
            (0..<12).map { index in
                BatchJob(
                    id: UUID(),
                    title: "任务 \(index)",
                    createdAt:
                        Date(
                            timeIntervalSince1970:
                                Double(index)
                        ),
                    updatedAt:
                        Date(
                            timeIntervalSince1970:
                                Double(index)
                        ),
                    state: .completed,
                    launchSource: .quickAction,
                    configuration: configuration,
                    tasks: [
                        BatchTask(
                            sourceURL:
                                URL(
                                    fileURLWithPath:
                                        "/tmp/recent-\(index).heic"
                                ),
                            fileName:
                                "recent-\(index).heic",
                            phase: .completed
                        )
                    ]
                )
            }

        defaults.set(
            try JSONEncoder().encode(jobs),
            forKey:
                "photomemo.batchQueue.jobs"
        )

        let store =
            BatchQueueStore(
                defaults: defaults,
                settingsService:
                    SettingsService(
                        defaults: defaults
                    )
            )
        let service =
            PhotoMemoBackgroundStatusService(
                batchQueueStore: store
            )

        #expect(
            service.recentJobSummaries.count
            == 10
        )
        #expect(
            service.recentJobSummaries.first?.jobID
            == jobs[11].id
        )
        #expect(
            service.recentJobSummaries.last?.jobID
            == jobs[2].id
        )

        defaults.removePersistentDomain(
            forName: suiteName
        )
    }

    @Test("Terminal intake failure exposes its concrete reason and failed step")
    func terminalIntakeFailureExposesConcreteReason() throws {
        let suiteName =
            "PhotoMemo.BackgroundStatusServiceTests.failure.\(UUID().uuidString)"
        let defaults = try #require(
            UserDefaults(suiteName: suiteName)
        )
        defaults.removePersistentDomain(forName: suiteName)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }
        let supportID = "JOB-1234567890AB"
        let failureMessage =
            "接收的照片副本已不可用，请从 Apple Photos 重新分享。（故障编号：\(supportID)）"
        let configuration = BatchConfigurationSnapshot(
            template: .classicWhite,
            badge: nil,
            anchor: nil,
            shouldWritePhotoDescription: true,
            photoDescriptionOverride: "",
            selectedAlbumIdentifier: ""
        )
        let failedJob = BatchJob(
            title: "恢复失败",
            state: .failed,
            launchSource: .shareExtension,
            configuration: configuration,
            tasks: [
                BatchTask(
                    sourceURL: URL(fileURLWithPath: "/tmp/missing.heic"),
                    phase: .failed,
                    failure: BatchTaskFailure(
                        phase: .queued,
                        message: failureMessage,
                        classification: .interrupted,
                        canRetry: false,
                        diagnosticCode:
                            ProductionDiagnosticErrorCode
                            .processingSourceMissing
                            .rawValue,
                        supportID: supportID
                    )
                )
            ]
        )
        defaults.set(
            try JSONEncoder().encode([failedJob]),
            forKey: "photomemo.batchQueue.jobs"
        )

        let store = BatchQueueStore(
            defaults: defaults,
            settingsService: SettingsService(defaults: defaults),
            automaticallyStartsProcessing: false
        )
        let snapshot = try #require(
            PhotoMemoBackgroundStatusService(
                batchQueueStore: store
            ).currentSnapshot
        )

        #expect(snapshot.statusMessage == failureMessage)
        #expect(snapshot.currentFileName == "missing.heic")
        #expect(snapshot.pipelineSteps.first?.state == .needsAttention)
        #expect(snapshot.activePipelineStepIndex == 0)
    }

    private func makeJob(
        id: UUID = UUID(),
        title: String,
        source: BatchJobLaunchSource,
        phase: BatchTaskPhase,
        updatedAt: TimeInterval,
        configuration: BatchConfigurationSnapshot
    ) -> BatchJob {
        BatchJob(
            id: id,
            title: title,
            createdAt:
                Date(
                    timeIntervalSince1970: updatedAt
                ),
            updatedAt:
                Date(
                    timeIntervalSince1970: updatedAt
                ),
            state:
                phase.isTerminal
                ? .completed
                : .queued,
            launchSource: source,
            configuration: configuration,
            tasks: [
                BatchTask(
                    sourceURL:
                        URL(
                            fileURLWithPath:
                                "/tmp/\(id.uuidString).heic"
                        ),
                    fileName: "\(id.uuidString).heic",
                    phase: phase
                )
            ]
        )
    }
}
#endif
