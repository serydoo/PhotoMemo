#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("Queue status migration", .serialized)
struct QueueStatusMigrationTests {

    @Test("RefreshQueueProcessingStatusIntent refreshes intake before loading diagnostics")
    func refreshQueueProcessingStatusIntentRefreshesIntakeBeforeLoadingDiagnostics() throws {

        let suiteName =
            "PhotoMemo.QueueStatusMigrationTests.refresh.\(UUID().uuidString)"
        let defaults =
            try #require(
                UserDefaults(
                    suiteName: suiteName
                )
            )
        defaults.removePersistentDomain(
            forName: suiteName
        )

        let diagnosticsRepository =
            DiagnosticsRepository(
                defaults: defaults,
                sharedQueueSnapshotService:
                    SharedBatchQueueSnapshotService(
                        defaults: defaults
                    )
            )

        let writeResult =
            PhotoMemoShareDiagnostics
            .recordResult(
                stage: .appDrain,
                message: "drainedRequests=1",
                defaults: defaults
            )

        switch writeResult {
        case .success:
            break
        case .encodingFailed(let failure):
            Issue.record(
                "Expected diagnostics seed write to succeed, got \(failure.underlyingDescription)"
            )
        }

        var refreshCount = 0
        let result =
            RefreshQueueProcessingStatusIntent(
                refreshExternalIntake: {
                    refreshCount += 1
                },
                diagnosticsRepository:
                    diagnosticsRepository
            )
            .executeSynchronously()

        switch result {
        case .success(let snapshot):
            #expect(refreshCount == 1)
            #expect(snapshot.events.count == 1)
            #expect(
                snapshot.events.first?.stage
                == .appDrain
            )
            #expect(
                snapshot.shareDiagnosticsAvailability
                == .available
            )
        case .failure(let error):
            Issue.record(
                "Expected queue status refresh to succeed, got \(error.message)"
            )
        }

        defaults.removePersistentDomain(
            forName: suiteName
        )
    }

    @MainActor
    @Test("ClearCompletedQueueHistoryIntent removes terminal external jobs through QueueCoordinator")
    func clearCompletedQueueHistoryIntentRemovesTerminalExternalJobs() throws {

        let suiteName =
            "PhotoMemo.QueueStatusMigrationTests.clear.\(UUID().uuidString)"
        let defaults =
            try #require(
                UserDefaults(
                    suiteName: suiteName
                )
            )
        defaults.removePersistentDomain(
            forName: suiteName
        )

        let completedJobID =
            UUID()
        let failedJobID =
            UUID()
        let runningJobID =
            UUID()
        let inAppJobID =
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
                id: completedJobID,
                title: "Completed Share",
                state: .completed,
                launchSource: .shareExtension,
                configuration: configuration,
                tasks: [
                    BatchTask(
                        sourceURL:
                            URL(
                                fileURLWithPath:
                                    "/tmp/completed.jpg"
                            ),
                        fileName:
                            "completed.jpg",
                        phase: .completed
                    )
                ]
            ),
            BatchJob(
                id: failedJobID,
                title: "Failed Share",
                state: .failed,
                launchSource: .shareExtension,
                configuration: configuration,
                tasks: [
                    BatchTask(
                        sourceURL:
                            URL(
                                fileURLWithPath:
                                    "/tmp/failed.jpg"
                            ),
                        fileName:
                            "failed.jpg",
                        phase: .failed,
                        failure:
                            BatchTaskFailure(
                                phase: .exporting,
                                message: "导出失败",
                                canRetry: false
                        )
                    )
                ]
            ),
            BatchJob(
                id: runningJobID,
                title: "Running Share",
                state: .running,
                launchSource: .shareExtension,
                configuration: configuration,
                tasks: [
                    BatchTask(
                        sourceURL:
                            URL(
                                fileURLWithPath:
                                    "/tmp/running.jpg"
                            ),
                        fileName:
                            "running.jpg",
                        phase: .exporting
                    )
                ]
            ),
            BatchJob(
                id: inAppJobID,
                title: "In App Preview",
                state: .completed,
                launchSource: .inAppPreview,
                configuration: configuration,
                tasks: [
                    BatchTask(
                        sourceURL:
                            URL(
                                fileURLWithPath:
                                    "/tmp/in-app.jpg"
                            ),
                        fileName:
                            "in-app.jpg",
                        phase: .completed
                    )
                ]
            )
        ]

        defaults.set(
            try JSONEncoder().encode(jobs),
            forKey:
                "photomemo.batchQueue.jobs"
        )

        let batchQueueStore =
            BatchQueueStore(
                defaults: defaults,
                settingsService:
                    SettingsService(
                        defaults: defaults
                    )
            )
        let coordinator =
            QueueCoordinator(
                queueRepository:
                    QueueRepository(
                        batchQueueStore:
                            batchQueueStore
                    )
            )

        let result =
            ClearCompletedQueueHistoryIntent(
                preservingJobID: nil,
                coordinator: coordinator
            )
            .executeSynchronously()

        switch result {
        case .success:
            #expect(batchQueueStore.jobs.count == 2)
            #expect(
                batchQueueStore.jobs.map(\.id)
                == [
                    runningJobID,
                    inAppJobID
                ]
            )
        case .failure(let error):
            Issue.record(
                "Expected clear history intent to succeed, got \(error.message)"
            )
        }

        defaults.removePersistentDomain(
            forName: suiteName
        )
    }

    @Test("LoadQueueProcessingDiagnosticsSnapshotIntent uses repository-backed diagnostics when available")
    func loadQueueProcessingDiagnosticsSnapshotIntentUsesRepositoryBackedDiagnostics() throws {

        let suiteName =
            "PhotoMemo.QueueStatusMigrationTests.load.\(UUID().uuidString)"
        let defaults =
            try #require(
                UserDefaults(
                    suiteName: suiteName
                )
            )
        defaults.removePersistentDomain(
            forName: suiteName
        )

        let diagnosticsRepository =
            DiagnosticsRepository(
                defaults: defaults,
                sharedQueueSnapshotService:
                    SharedBatchQueueSnapshotService(
                        defaults: defaults
                    )
            )

        let writeResult =
            PhotoMemoShareDiagnostics
            .recordResult(
                stage: .appEnqueueCreated,
                message: "queued",
                defaults: defaults
            )

        switch writeResult {
        case .success:
            break
        case .encodingFailed(let failure):
            Issue.record(
                "Expected diagnostics seed write to succeed, got \(failure.underlyingDescription)"
            )
        }

        var fallbackLoadCount = 0

        let result =
            LoadQueueProcessingDiagnosticsSnapshotIntent(
                diagnosticsRepository:
                    diagnosticsRepository,
                fallbackLoad: {
                    fallbackLoadCount += 1
                    return PhotoMemoiOSProcessingDiagnosticsSnapshot(
                        events: []
                    )
                }
            )
            .executeSynchronously()

        switch result {
        case .success(let snapshot):
            #expect(fallbackLoadCount == 0)
            #expect(snapshot.events.count == 1)
            #expect(
                snapshot.events.first?.stage
                == .appEnqueueCreated
            )
        case .failure(let error):
            Issue.record(
                "Expected load diagnostics intent to succeed, got \(error.message)"
            )
        }

        defaults.removePersistentDomain(
            forName: suiteName
        )
    }

    @Test("LoadQueueProcessingDiagnosticsSnapshotIntent falls back when repository read is unavailable")
    func loadQueueProcessingDiagnosticsSnapshotIntentFallsBackWhenRepositoryReadIsUnavailable() {

        let fallbackSnapshot =
            PhotoMemoiOSProcessingDiagnosticsSnapshot(
                events: [
                    PhotoMemoShareDiagnosticEvent(
                        stage: .extensionRequestPersisted,
                        message: "fallback"
                    )
                ],
                shareDiagnosticsAvailability:
                    .available
            )

        var fallbackLoadCount = 0

        let result =
            LoadQueueProcessingDiagnosticsSnapshotIntent(
                loadFromRepository: {
                    .failure(
                        PhotoMemoError(
                            code: .persistenceReadFailed,
                            message: "repository unavailable"
                        )
                    )
                },
                fallbackLoad: {
                    fallbackLoadCount += 1
                    return fallbackSnapshot
                }
            )
            .executeSynchronously()

        switch result {
        case .success(let snapshot):
            #expect(fallbackLoadCount == 1)
            #expect(snapshot == fallbackSnapshot)
        case .failure(let error):
            Issue.record(
                "Expected load diagnostics intent to fall back successfully, got \(error.message)"
            )
        }
    }
}
#endif
