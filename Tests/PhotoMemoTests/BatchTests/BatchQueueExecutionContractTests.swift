#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
import UniformTypeIdentifiers
@testable import PhotoMemo

@Suite("Batch queue execution contracts", .serialized)
struct BatchQueueExecutionContractTests {

    @MainActor
    @Test("Retry clears terminal output fields")
    func retryResetsRenderedAndSavedState() {
        let jobID = UUID()
        var jobs = [
            BatchJob(
                id: jobID,
                title: "Failed",
                state: .failed,
                configuration: makeConfiguration(),
                tasks: [
                    BatchTask(
                        sourceURL: URL(fileURLWithPath: "/tmp/input.jpg"),
                        phase: .failed,
                        savedAlbumName: "MemoMark",
                        savedAssetIdentifier: "asset-id",
                        renderedFileURL: URL(fileURLWithPath: "/tmp/output.jpg"),
                        notificationAttachmentURL: URL(fileURLWithPath: "/tmp/attachment.jpg"),
                        failure: BatchTaskFailure(
                            phase: .exporting,
                            message: "failed"
                        )
                    )
                ],
                finalNotificationSentAt: Date()
            )
        ]

        let didRetry = BatchQueueExecution().retryFailedTasks(
            in: &jobs,
            jobID: jobID
        )

        #expect(didRetry)
        #expect(jobs[0].tasks[0].phase == .queued)
        #expect(jobs[0].tasks[0].renderedFileURL == nil)
        #expect(jobs[0].tasks[0].notificationAttachmentURL == nil)
        #expect(jobs[0].tasks[0].savedAlbumName == nil)
        #expect(jobs[0].tasks[0].savedAssetIdentifier == nil)
        #expect(jobs[0].tasks[0].failure == nil)
        #expect(jobs[0].tasks[0].retryCount == 1)
        #expect(jobs[0].finalNotificationSentAt == nil)
    }

    @MainActor
    @Test("Live Photo processor failure leaves no rendered or saved output")
    func livePhotoProcessorFailureLeavesNoOutput() async throws {
        let context = try makeStoreContext(
            livePhotoProcessor: FailingLivePhotoProcessor()
        )
        defer { cleanup(context) }
        let sourceURL = context.intakeDirectoryURL
            .appendingPathComponent("health-check.HEIC")
        try FileManager.default.createDirectory(
            at: context.intakeDirectoryURL,
            withIntermediateDirectories: true
        )
        try Data("source".utf8).write(to: sourceURL)

        _ = context.store.enqueue(
            payloads: [
                BatchTaskIntakePayload(
                    sourceURL: sourceURL,
                    sourceIdentifier: "live-photo-identifier",
                    contentTypeIdentifier: try #require(
                        UTType("com.apple.live-photo")
                    ).identifier
                )
            ],
            configuration: makeConfiguration(),
            launchSource: .shareExtension
        )

        let task = try await terminalTask(
            in: context.store
        )

        #expect(task.phase == .failed)
        #expect(task.renderedFileURL == nil)
        #expect(task.notificationAttachmentURL == nil)
        #expect(task.savedAlbumName == nil)
        #expect(task.savedAssetIdentifier == nil)
    }

    @MainActor
    @Test("Retryable managed-source failure preserves its source file")
    func retryableManagedSourceFailurePreservesSource() throws {
        let suiteName =
            "PhotoMemo.BatchQueueExecutionContractTests.Managed.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        let intakeDirectoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(suiteName, isDirectory: true)
        let intakeStore = ExternalPhotoIntakeStore(
            defaults: defaults,
            intakeDirectoryURL: intakeDirectoryURL
        )
        defer {
            defaults.removePersistentDomain(forName: suiteName)
            try? FileManager.default.removeItem(at: intakeDirectoryURL)
        }
        let managedSourceURL = try #require(
            intakeStore.createManagedCopy(
                from: SyntheticFixtureLibrary.fixtureURL(.portraitJPEG),
                requestID: UUID(),
                index: 0
            )
        )
        let jobID = UUID()
        var jobs = [
            BatchJob(
                id: jobID,
                title: "Retryable managed failure",
                state: .failed,
                configuration: makeConfiguration(),
                tasks: [
                    BatchTask(
                        sourceURL: managedSourceURL,
                        phase: .failed,
                        failure: BatchTaskFailure(
                            phase: .exporting,
                            message: "temporary failure",
                            canRetry: true
                        )
                    )
                ]
            )
        ]

        let didRetry = BatchQueueExecution(
            externalIntakeStore: intakeStore
        ).retryFailedTasks(in: &jobs, jobID: jobID)

        #expect(didRetry)
        #expect(jobs[0].tasks[0].phase == .queued)
        #expect(
            FileManager.default.fileExists(
                atPath: managedSourceURL.path
            )
        )
    }

    @MainActor
    @Test("Successful final delivery marker gates repeated delivery attempts")
    func finalNotificationMarkerGatesRepeatedDeliveryAttempts() async throws {
        // This locks BatchQueueStore's successful-delivery marker and repeat
        // gate; the concrete notification service cannot expose system send counts.
        let suiteName =
            "PhotoMemo.BatchQueueExecutionContractTests.Final.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        let job = BatchJob(
            title: "Completed",
            state: .completed,
            configuration: makeConfiguration(),
            tasks: [
                BatchTask(
                    sourceURL: URL(fileURLWithPath: "/tmp/completed.jpg"),
                    phase: .completed
                )
            ],
            finalNotificationSentAt: nil
        )
        defaults.set(
            try JSONEncoder().encode([job]),
            forKey: "photomemo.batchQueue.jobs"
        )
        let intakeDirectoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(suiteName, isDirectory: true)
        let store = BatchQueueStore(
            defaults: defaults,
            settingsService: SettingsService(defaults: defaults),
            externalIntakeStore: ExternalPhotoIntakeStore(
                defaults: defaults,
                intakeDirectoryURL: intakeDirectoryURL
            )
        )
        defer {
            defaults.removePersistentDomain(forName: suiteName)
            try? FileManager.default.removeItem(at: intakeDirectoryURL)
        }

        store.markFinalNotificationSent(at: 0)
        let firstDeliverySentAt = try #require(
            store.jobs.first?.finalNotificationSentAt
        )
        await store.deliverFinalNotificationIfNeeded(for: job.id)
        await store.deliverFinalNotificationIfNeeded(for: job.id)

        #expect(store.jobs.first?.finalNotificationSentAt != nil)
        #expect(
            store.jobs.first?.finalNotificationSentAt
            == firstDeliverySentAt
        )
    }
}

private extension BatchQueueExecutionContractTests {

    @MainActor
    struct StoreContext {
        let store: BatchQueueStore
        let defaults: UserDefaults
        let defaultsSuiteName: String
        let intakeDirectoryURL: URL
    }

    @MainActor
    func makeConfiguration() -> BatchConfigurationSnapshot {
        BatchConfigurationSnapshot(
            template: .classicWhite.normalizedForEditing,
            badge: nil,
            anchor: nil,
            shouldWritePhotoDescription: true,
            photoDescriptionOverride: "",
            selectedAlbumIdentifier: ""
        )
    }

    @MainActor
    func makeStoreContext(
        livePhotoProcessor: any LivePhotoBatchTaskProcessing
    ) throws -> StoreContext {
        let suiteName =
            "PhotoMemo.BatchQueueExecutionContractTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        let intakeDirectoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(suiteName, isDirectory: true)
        let store = BatchQueueStore(
            defaults: defaults,
            settingsService: SettingsService(defaults: defaults),
            externalIntakeStore: ExternalPhotoIntakeStore(
                defaults: defaults,
                intakeDirectoryURL: intakeDirectoryURL
            ),
            livePhotoProcessor: livePhotoProcessor
        )
        return StoreContext(
            store: store,
            defaults: defaults,
            defaultsSuiteName: suiteName,
            intakeDirectoryURL: intakeDirectoryURL
        )
    }

    @MainActor
    func terminalTask(in store: BatchQueueStore) async throws -> BatchTask {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: .seconds(5))

        while clock.now < deadline {
            if let task = store.jobs.first?.tasks.first,
               task.phase.isTerminal {
                return task
            }
            try await Task.sleep(nanoseconds: 20_000_000)
        }

        Issue.record("Timed out waiting five seconds for a terminal batch task")
        throw ContractTestTimeout.terminalTask
    }

    @MainActor
    func cleanup(_ context: StoreContext) {
        context.defaults.removePersistentDomain(
            forName: context.defaultsSuiteName
        )
        try? FileManager.default.removeItem(
            at: context.intakeDirectoryURL
        )
    }

}

@MainActor
private final class FailingLivePhotoProcessor:
    LivePhotoBatchTaskProcessing {

    func process(
        task: BatchTask,
        configuration: BatchConfigurationSnapshot
    ) async throws -> LivePhotoBatchTaskResult {
        throw ProcessorFailure.expected
    }

    private enum ProcessorFailure: Error {
        case expected
    }
}

private enum ContractTestTimeout: Error {
    case terminalTask
}
#endif
