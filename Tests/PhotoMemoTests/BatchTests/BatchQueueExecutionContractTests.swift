#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
import UniformTypeIdentifiers
@testable import PhotoMemo

@Suite("Batch queue execution contracts", .serialized)
struct BatchQueueExecutionContractTests {

    @MainActor
    @Test("Task processor context keeps immutable execution inputs")
    func taskProcessorContextKeepsExecutionInputs() {
        let task = BatchTask(
            sourceURL: URL(fileURLWithPath: "/tmp/context.jpg"),
            fileName: "context.jpg"
        )
        let jobID = UUID()
        let reference = BatchQueueExecution.TaskReference(
            jobID: jobID,
            taskID: task.id
        )
        let budget = BatchTaskMemoryPolicy.mediaMemoryBudget(for: task)
        let startedAt = Date(timeIntervalSince1970: 123)
        let context = BatchTaskExecutionContext(
            taskReference: reference,
            taskSnapshot: task,
            configuration: makeConfiguration(),
            memoryBudget: budget,
            usesLivePhotoProcessing: false,
            route: "staticImage",
            totalProgressUnits: 5,
            startedAt: startedAt
        )

        #expect(context.taskReference.jobID == jobID)
        #expect(context.taskReference.taskID == task.id)
        #expect(context.taskSnapshot.id == task.id)
        #expect(context.route == "staticImage")
        #expect(!context.usesLivePhotoProcessing)
        #expect(context.totalProgressUnits == 5)
        #expect(context.startedAt == startedAt)
    }

    @MainActor
    @Test("Failure policy preserves classification and terminal-state decisions")
    func failurePolicyPreservesClassificationAndTerminalStateDecisions() {
        #expect(
            BatchTaskFailurePolicy.failureClassification(
                for: PhotoImportError.imageLoadFailed
            ) == .interrupted
        )
        #expect(
            BatchTaskFailurePolicy.failureClassification(
                for: PhotoImportError.rawDisplayRenderFailed
            ) == .processingFailure
        )
        #expect(
            BatchTaskFailurePolicy.failureClassification(
                for: CocoaError(.fileReadUnknown)
            ) == .processingFailure
        )
        #expect(
            BatchTaskFailurePolicy.shouldAbortFurtherProcessing(
                currentPhase: nil
            )
        )
        #expect(
            !BatchTaskFailurePolicy.shouldAbortFurtherProcessing(
                currentPhase: .importing
            )
        )
        #expect(
            BatchTaskFailurePolicy.shouldIgnoreErrorBecauseTaskEnded(
                currentPhase: .cancelled
            )
        )
        #expect(
            !BatchTaskFailurePolicy.shouldIgnoreErrorBecauseTaskEnded(
                currentPhase: .exporting
            )
        )
    }

    @MainActor
    @Test("Failure policy disables retry only for missing managed sources")
    func failurePolicyDisablesRetryOnlyForMissingManagedSources() {
        let missingManagedSource =
            PhotoMemoSharedContainer
            .externalIntakeDirectoryURL
            .appendingPathComponent(
                "missing-\(UUID().uuidString).jpg"
            )
        let missingUnmanagedSource =
            FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "missing-\(UUID().uuidString).jpg"
            )

        #expect(
            !BatchTaskFailurePolicy.canRetryTaskAfterFailure(
                sourceURL: missingManagedSource
            )
        )
        #expect(
            BatchTaskFailurePolicy.canRetryTaskAfterFailure(
                sourceURL: missingUnmanagedSource
            )
        )
    }

    @MainActor
    @Test("Memory policy preserves RAW budget and Live Photo fallback routing")
    func memoryPolicyPreservesBudgetAndLivePhotoFallbackRouting() throws {
        let rawTask = BatchTask(
            sourceURL: URL(fileURLWithPath: "/tmp/IMG_9001.DNG"),
            contentTypeIdentifier: try #require(
                UTType(filenameExtension: "dng")
            ).identifier
        )
        let identifiedLivePhotoTask = BatchTask(
            sourceURL: URL(fileURLWithPath: "/tmp/IMG_1001.HEIC"),
            sourceIdentifier: "asset-local-1001",
            contentTypeIdentifier: try #require(
                UTType("com.apple.live-photo")
            ).identifier
        )
        let staticFallbackTask = BatchTask(
            sourceURL: URL(fileURLWithPath: "/tmp/IMG_1002.jpeg"),
            contentTypeIdentifier: try #require(
                UTType("com.apple.live-photo")
            ).identifier
        )

        let budget = BatchTaskMemoryPolicy.mediaMemoryBudget(
            for: rawTask
        )

        #expect(budget.cost.isRAW)
        #expect(budget.requiresExtendedPreviewPreparation)
        #expect(
            BatchTaskMemoryPolicy.shouldUseLivePhotoProcessing(
                for: identifiedLivePhotoTask
            )
        )
        #expect(
            !BatchTaskMemoryPolicy.shouldUseLivePhotoProcessing(
                for: staticFallbackTask
            )
        )
        #expect(
            BatchTaskMemoryPolicy.staticImportContentTypeIdentifier(
                for: staticFallbackTask,
                usesLivePhotoProcessing: false
            ) == UTType.jpeg.identifier
        )
        #expect(
            BatchTaskMemoryPolicy.staticImportContentTypeIdentifier(
                for: identifiedLivePhotoTask,
                usesLivePhotoProcessing: true
            ) == identifiedLivePhotoTask.contentTypeIdentifier
        )
    }

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
    @Test("Stable task references survive insertion of a newer job")
    func stableTaskReferenceSurvivesNewJobInsertion() throws {
        let suiteName = "PhotoMemo.BatchQueueExecutionContractTests.Reference.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
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

        let firstJob = try #require(
            store.enqueue(
                urls: [URL(fileURLWithPath: "/tmp/reference-first.jpg")]
            )
        )
        let reference = try #require(store.nextPendingTaskReference())
        let firstTaskID = try #require(firstJob.tasks.first?.id)
        _ = store.enqueue(urls: [URL(fileURLWithPath: "/tmp/reference-newer.jpg")])

        store.updateTask(at: reference) { task in
            task.progress.statusMessage = "stable-reference"
        }

        let matchedTask = store.jobs
            .first(where: { $0.id == firstJob.id })?.tasks
            .first(where: { $0.id == firstTaskID })
        #expect(matchedTask?.progress.statusMessage == "stable-reference")
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
    @Test("Render health rejection fails before export and save")
    func renderHealthRejectionFailsBeforeExportAndSave() async throws {
        let context = try makeStoreContext(
            livePhotoProcessor: FailingLivePhotoProcessor(),
            renderHealthValidator: { _, _ in
                throw RenderHealthRejection.expected
            }
        )
        defer { cleanup(context) }
        let sourceURL = try SyntheticFixtureLibrary.fixtureURL(.portraitJPEG)
        _ = context.store.enqueue(
            payloads: [BatchTaskIntakePayload(sourceURL: sourceURL)],
            configuration: makeConfiguration(),
            launchSource: .shareExtension
        )

        let task = try await terminalTask(in: context.store)
        #expect(task.phase == .failed)
        #expect(task.renderedFileURL == nil)
        #expect(task.savedAlbumName == nil)
        #expect(task.savedAssetIdentifier == nil)
        #expect(task.failure?.phase == .metadataReady)
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
    @Test("Cancelling a queued task cleans its managed source")
    func cancellationCleansManagedSource() throws {
        let context = try makeManagedSourceContext()
        defer { cleanup(context) }
        let managedSourceURL = try #require(
            context.intakeStore.createManagedCopy(
                from: SyntheticFixtureLibrary.fixtureURL(.portraitJPEG),
                requestID: UUID(),
                index: 0
            )
        )
        let jobID = UUID()
        var jobs = [
            BatchJob(
                id: jobID,
                title: "Queued",
                configuration: makeConfiguration(),
                tasks: [BatchTask(sourceURL: managedSourceURL)]
            )
        ]

        let didCancel = BatchQueueExecution(
            externalIntakeStore: context.intakeStore
        ).cancelJob(in: &jobs, jobID: jobID)

        #expect(didCancel)
        #expect(jobs[0].tasks[0].phase == .cancelled)
        #expect(!FileManager.default.fileExists(atPath: managedSourceURL.path))
    }

    @MainActor
    @Test("Resource cleanup is idempotent and preserves retryable managed sources")
    func resourceCleanupIsIdempotentAndPreservesRetryableManagedSources() throws {
        let context = try makeManagedSourceContext()
        defer { cleanup(context) }
        let temporaryFileURL = context.intakeDirectoryURL
            .deletingLastPathComponent()
            .appendingPathComponent("temporary-\(UUID().uuidString).jpg")
        try FileManager.default.createDirectory(
            at: temporaryFileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data("temporary".utf8).write(to: temporaryFileURL)
        let managedSourceURL = try #require(
            context.intakeStore.createManagedCopy(
                from: SyntheticFixtureLibrary.fixtureURL(.portraitJPEG),
                requestID: UUID(),
                index: 0
            )
        )
        let lifecycle = BatchTaskResourceLifecycle(
            coordinator: BatchProcessingCoordinator(),
            externalIntakeStore: context.intakeStore,
            managedIntakeRootURL: context.intakeDirectoryURL,
            notificationAttachmentsDirectoryURL:
                context.notificationAttachmentsDirectoryURL
        )

        lifecycle.cleanupTemporaryFiles([temporaryFileURL, temporaryFileURL])

        #expect(!FileManager.default.fileExists(atPath: temporaryFileURL.path))
        #expect(lifecycle.canPreserveManagedSourceForRetry(at: managedSourceURL))
        #expect(FileManager.default.fileExists(atPath: managedSourceURL.path))
    }

    @MainActor
    @Test("Notification attachment generation is replaceable and isolated")
    func notificationAttachmentGenerationIsReplaceableAndIsolated() throws {
        let context = try makeManagedSourceContext()
        defer { cleanup(context) }
        let lifecycle = BatchTaskResourceLifecycle(
            coordinator: BatchProcessingCoordinator(),
            externalIntakeStore: context.intakeStore,
            managedIntakeRootURL: context.intakeDirectoryURL,
            notificationAttachmentsDirectoryURL:
                context.notificationAttachmentsDirectoryURL
        )
        let taskID = UUID()

        let firstURL = try #require(
            lifecycle.makeNotificationAttachmentIfNeeded(
                from: SyntheticFixtureLibrary.fixtureURL(.portraitJPEG),
                taskID: taskID
            )
        )
        let secondURL = try #require(
            lifecycle.makeNotificationAttachmentIfNeeded(
                from: SyntheticFixtureLibrary.fixtureURL(.portraitJPEG),
                taskID: taskID
            )
        )

        #expect(firstURL == secondURL)
        #expect(firstURL.deletingLastPathComponent() == context.notificationAttachmentsDirectoryURL)
        #expect(FileManager.default.fileExists(atPath: secondURL.path))
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

    struct ManagedSourceContext {
        let intakeStore: ExternalPhotoIntakeStore
        let defaults: UserDefaults
        let defaultsSuiteName: String
        let intakeDirectoryURL: URL
        let notificationAttachmentsDirectoryURL: URL
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
        livePhotoProcessor: any LivePhotoBatchTaskProcessing,
        renderHealthValidator: @escaping
            @MainActor (RecordCard, BatchConfigurationSnapshot) throws -> [CardTextBlock] =
                ProductionRenderHealthCheck.validate
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
            livePhotoProcessor: livePhotoProcessor,
            renderHealthValidator: renderHealthValidator
        )
        return StoreContext(
            store: store,
            defaults: defaults,
            defaultsSuiteName: suiteName,
            intakeDirectoryURL: intakeDirectoryURL
        )
    }

    func makeManagedSourceContext() throws -> ManagedSourceContext {
        let suiteName =
            "PhotoMemo.BatchQueueExecutionContractTests.Resources.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(suiteName, isDirectory: true)
        let intakeDirectoryURL = rootURL
            .appendingPathComponent("ExternalIntake", isDirectory: true)
        return ManagedSourceContext(
            intakeStore: ExternalPhotoIntakeStore(
                defaults: defaults,
                intakeDirectoryURL: intakeDirectoryURL
            ),
            defaults: defaults,
            defaultsSuiteName: suiteName,
            intakeDirectoryURL: intakeDirectoryURL,
            notificationAttachmentsDirectoryURL:
                rootURL.appendingPathComponent(
                    "NotificationAttachments",
                    isDirectory: true
                )
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

    func cleanup(_ context: ManagedSourceContext) {
        context.defaults.removePersistentDomain(
            forName: context.defaultsSuiteName
        )
        try? FileManager.default.removeItem(
            at: context.intakeDirectoryURL.deletingLastPathComponent()
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

private enum RenderHealthRejection: Error {
    case expected
}
#endif
