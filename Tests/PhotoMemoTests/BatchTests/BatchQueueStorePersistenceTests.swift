import Foundation
import Testing
@testable import PhotoMemo

@Suite("Batch queue store persistence")
struct BatchQueueStorePersistenceTests {

    @Test("Corrupted queue payload is surfaced instead of becoming an empty successful load")
    func corruptedQueuePayloadIsSurfaced() throws {
        let suiteName =
            "PhotoMemo.BatchQueueStorePersistenceTests.CorruptedLoad.\(UUID().uuidString)"
        let defaults =
            try #require(UserDefaults(suiteName: suiteName))
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        defaults.set(
            Data("corrupted-queue".utf8),
            forKey: "photomemo.batchQueue.jobs"
        )

        let result = BatchQueuePersistence(defaults: defaults)
            .loadPersistedJobsResult()

        switch result {
        case .success:
            Issue.record("Expected corrupted queue payload to fail loading")
        case .failure(let error):
            #expect(error.code == .persistenceReadFailed)
            #expect(error.underlyingDescription?.contains("photomemo.batchQueue.jobs") == true)
        }
    }

    @MainActor
    @Test("Batch queue startup surfaces corrupted persistence and does not start processing")
    func startupSurfacesCorruptedPersistence() throws {
        let suiteName =
            "PhotoMemo.BatchQueueStorePersistenceTests.CorruptedStartup.\(UUID().uuidString)"
        let defaults =
            try #require(UserDefaults(suiteName: suiteName))
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        defaults.set(
            Data("corrupted-queue".utf8),
            forKey: "photomemo.batchQueue.jobs"
        )

        let store = BatchQueueStore(
            defaults: defaults,
            settingsService: SettingsService(defaults: defaults)
        )

        #expect(store.jobs.isEmpty)
        #expect(store.isProcessing == false)
        #expect(store.lastErrorMessage.isEmpty == false)
    }

    @MainActor
    @Test("Queue startup preserves persisted task receipts while pruning orphaned receipts")
    func startupReconcilesReceiptsAgainstLoadedQueueTasks() throws {
        let suiteName =
            "PhotoMemo.BatchQueueStorePersistenceTests.ReceiptStartup.\(UUID().uuidString)"
        let defaults = try #require(
            UserDefaults(suiteName: suiteName)
        )
        defaults.removePersistentDomain(forName: suiteName)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let taskID = UUID()
        defaults.set(
            try JSONEncoder().encode(
                [terminalExternalJob(taskID: taskID)]
            ),
            forKey: "photomemo.batchQueue.jobs"
        )
        let receiptStore = PhotoLibrarySaveReceiptStore(
            defaults: defaults
        )
        let orphanedTaskID = UUID().uuidString
        receiptStore.record(
            assetIdentifier: "asset-retained",
            for: taskID.uuidString
        )
        receiptStore.record(
            assetIdentifier: "asset-orphaned",
            for: orphanedTaskID
        )

        let store = BatchQueueStore(
            defaults: defaults,
            settingsService: SettingsService(defaults: defaults),
            saveReceiptStore: receiptStore
        )

        #expect(store.jobs.count == 1)
        #expect(
            receiptStore.assetIdentifier(for: taskID.uuidString)
            == "asset-retained"
        )
        #expect(
            receiptStore.assetIdentifier(for: orphanedTaskID)
            == nil
        )
    }

    @MainActor
    @Test("Startup completes a saving task when its receipt-backed Photos asset is visible")
    func startupCompletesVisibleReceiptBackedSavingTask() throws {
        let suiteName =
            "PhotoMemo.BatchQueueStorePersistenceTests.ReceiptCompletion.\(UUID().uuidString)"
        let defaults = try #require(
            UserDefaults(suiteName: suiteName)
        )
        defaults.removePersistentDomain(forName: suiteName)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let taskID = UUID()
        let job = savingJob(taskID: taskID)
        defaults.set(
            try JSONEncoder().encode([job]),
            forKey: "photomemo.batchQueue.jobs"
        )
        let receiptStore = PhotoLibrarySaveReceiptStore(
            defaults: defaults
        )
        receiptStore.record(
            assetIdentifier: "receipt-backed-asset",
            for: taskID.uuidString
        )

        let store = BatchQueueStore(
            defaults: defaults,
            settingsService: SettingsService(defaults: defaults),
            saveReceiptStore: receiptStore,
            photoLibraryReceiptAssetLocator:
                StubPhotoLibraryReceiptAssetLocator(
                    visibleAssetIdentifiers: [
                        taskID.uuidString:
                            "receipt-backed-asset"
                    ]
                ),
            automaticallyStartsProcessing: false
        )

        let task = try #require(store.jobs.first?.tasks.first)
        #expect(task.phase == .completed)
        #expect(
            task.savedAssetIdentifier
            == "receipt-backed-asset"
        )
        #expect(task.renderedFileURL == nil)
        #expect(task.failure == nil)
        #expect(task.progress.fractionCompleted == 1)

        let persistedTask = try #require(
            BatchQueuePersistence(defaults: defaults)
            .loadPersistedJobsResult()
            .value?
            .first?
            .tasks
            .first
        )
        #expect(persistedTask.phase == .completed)
        #expect(
            persistedTask.savedAssetIdentifier
            == "receipt-backed-asset"
        )
    }

    @MainActor
    @Test("Startup receipt completion cleans rendered output and managed source after persistence")
    func startupReceiptCompletionCleansDurableResources() throws {
        let suiteName =
            "PhotoMemo.BatchQueueStorePersistenceTests.ReceiptCleanup.\(UUID().uuidString)"
        let defaults = try #require(
            UserDefaults(suiteName: suiteName)
        )
        let rootURL = FileManager.default
            .temporaryDirectory
            .appendingPathComponent(
                suiteName,
                isDirectory: true
            )
        let intakeDirectoryURL = rootURL
            .appendingPathComponent(
                "ExternalIntake",
                isDirectory: true
            )
        let renderedDirectoryURL = rootURL
            .appendingPathComponent(
                "Rendered",
                isDirectory: true
            )
        defer {
            defaults.removePersistentDomain(forName: suiteName)
            try? FileManager.default.removeItem(at: rootURL)
        }
        try FileManager.default.createDirectory(
            at: intakeDirectoryURL,
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: renderedDirectoryURL,
            withIntermediateDirectories: true
        )
        let sourceURL = intakeDirectoryURL
            .appendingPathComponent("source.jpg")
        let renderedURL = renderedDirectoryURL
            .appendingPathComponent("rendered.jpg")
        try Data("source".utf8).write(to: sourceURL)
        try Data("rendered".utf8).write(to: renderedURL)

        let taskID = UUID()
        defaults.set(
            try JSONEncoder().encode([
                savingJob(
                    taskID: taskID,
                    sourceURL: sourceURL,
                    renderedFileURL: renderedURL
                )
            ]),
            forKey: "photomemo.batchQueue.jobs"
        )
        let receiptStore = PhotoLibrarySaveReceiptStore(
            defaults: defaults
        )
        receiptStore.record(
            assetIdentifier: "receipt-backed-asset",
            for: taskID.uuidString
        )

        let store = BatchQueueStore(
            defaults: defaults,
            settingsService: SettingsService(defaults: defaults),
            externalIntakeStore: ExternalPhotoIntakeStore(
                defaults: defaults,
                intakeDirectoryURL: intakeDirectoryURL
            ),
            saveReceiptStore: receiptStore,
            photoLibraryReceiptAssetLocator:
                StubPhotoLibraryReceiptAssetLocator(
                    visibleAssetIdentifiers: [
                        taskID.uuidString:
                            "receipt-backed-asset"
                    ]
                ),
            automaticallyStartsProcessing: false
        )

        #expect(store.jobs.first?.tasks.first?.phase == .completed)
        #expect(
            !FileManager.default.fileExists(
                atPath: renderedURL.path
            )
        )
        #expect(
            !FileManager.default.fileExists(
                atPath: sourceURL.path
            )
        )
    }

    @MainActor
    @Test("Startup receipt completion keeps files when terminal persistence fails")
    func startupReceiptCompletionDefersCleanupUntilPersistence() throws {
        let suiteName =
            "PhotoMemo.BatchQueueStorePersistenceTests.ReceiptCleanupFailure.\(UUID().uuidString)"
        let defaults = try #require(
            UserDefaults(suiteName: suiteName)
        )
        let rootURL = FileManager.default
            .temporaryDirectory
            .appendingPathComponent(
                suiteName,
                isDirectory: true
            )
        let intakeDirectoryURL = rootURL
            .appendingPathComponent(
                "ExternalIntake",
                isDirectory: true
            )
        defer {
            defaults.removePersistentDomain(forName: suiteName)
            try? FileManager.default.removeItem(at: rootURL)
        }
        try FileManager.default.createDirectory(
            at: intakeDirectoryURL,
            withIntermediateDirectories: true
        )
        let sourceURL = intakeDirectoryURL
            .appendingPathComponent("source.jpg")
        let renderedURL = rootURL
            .appendingPathComponent("rendered.jpg")
        try Data("source".utf8).write(to: sourceURL)
        try Data("rendered".utf8).write(to: renderedURL)

        let taskID = UUID()
        let persistedData = try JSONEncoder().encode([
            savingJob(
                taskID: taskID,
                sourceURL: sourceURL,
                renderedFileURL: renderedURL
            )
        ])
        let receiptStore = PhotoLibrarySaveReceiptStore(
            defaults: defaults
        )
        receiptStore.record(
            assetIdentifier: "receipt-backed-asset",
            for: taskID.uuidString
        )

        let store = BatchQueueStore(
            defaults: defaults,
            settingsService: SettingsService(defaults: defaults),
            externalIntakeStore: ExternalPhotoIntakeStore(
                defaults: defaults,
                intakeDirectoryURL: intakeDirectoryURL
            ),
            persistence: BatchQueuePersistence(
                backend: SaveRejectingBackend(
                    persistedData: persistedData
                )
            ),
            saveReceiptStore: receiptStore,
            photoLibraryReceiptAssetLocator:
                StubPhotoLibraryReceiptAssetLocator(
                    visibleAssetIdentifiers: [
                        taskID.uuidString:
                            "receipt-backed-asset"
                    ]
                ),
            automaticallyStartsProcessing: false
        )

        #expect(store.startupPersistenceError == nil)
        #expect(!store.lastErrorMessage.isEmpty)
        let task = try #require(store.jobs.first?.tasks.first)
        #expect(task.phase == .savingToPhotoLibrary)
        #expect(task.savedAssetIdentifier == nil)
        #expect(task.renderedFileURL == renderedURL)
        #expect(
            FileManager.default.fileExists(
                atPath: renderedURL.path
            )
        )
        #expect(
            FileManager.default.fileExists(
                atPath: sourceURL.path
            )
        )
    }

    @MainActor
    @Test("Startup preserves an unresolved receipt-backed saving task without requeueing")
    func startupPreservesMissingReceiptBackedSavingTask() throws {
        let suiteName =
            "PhotoMemo.BatchQueueStorePersistenceTests.ReceiptMissing.\(UUID().uuidString)"
        let defaults = try #require(
            UserDefaults(suiteName: suiteName)
        )
        defaults.removePersistentDomain(forName: suiteName)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let taskID = UUID()
        defaults.set(
            try JSONEncoder().encode([
                savingJob(taskID: taskID)
            ]),
            forKey: "photomemo.batchQueue.jobs"
        )
        let receiptStore = PhotoLibrarySaveReceiptStore(
            defaults: defaults
        )
        receiptStore.record(
            assetIdentifier: "missing-asset",
            for: taskID.uuidString
        )

        let store = BatchQueueStore(
            defaults: defaults,
            settingsService: SettingsService(defaults: defaults),
            saveReceiptStore: receiptStore,
            photoLibraryReceiptAssetLocator:
                StubPhotoLibraryReceiptAssetLocator(
                    visibleAssetIdentifiers: [:]
                ),
            automaticallyStartsProcessing: false
        )

        let task = try #require(store.jobs.first?.tasks.first)
        #expect(task.phase == .savingToPhotoLibrary)
        #expect(task.savedAssetIdentifier == nil)
        #expect(
            task.renderedFileURL
            == URL(
                fileURLWithPath:
                    "/tmp/rendered-receipt-recovery.jpg"
            )
        )
        #expect(
            receiptStore.assetIdentifier(for: taskID.uuidString)
            == "missing-asset"
        )
    }

    @MainActor
    @Test("Automatic startup does not rerender an unresolved receipt-backed saving task")
    func automaticStartupDoesNotRerenderMissingReceiptBackedSavingTask() throws {
        let suiteName =
            "PhotoMemo.BatchQueueStorePersistenceTests.ReceiptMissingAutomatic.\(UUID().uuidString)"
        let defaults = try #require(
            UserDefaults(suiteName: suiteName)
        )
        let rootURL = FileManager.default
            .temporaryDirectory
            .appendingPathComponent(
                suiteName,
                isDirectory: true
            )
        let intakeDirectoryURL = rootURL
            .appendingPathComponent(
                "ExternalIntake",
                isDirectory: true
            )
        let renderedDirectoryURL = rootURL
            .appendingPathComponent(
                "Rendered",
                isDirectory: true
            )
        defer {
            defaults.removePersistentDomain(forName: suiteName)
            try? FileManager.default.removeItem(at: rootURL)
        }
        try FileManager.default.createDirectory(
            at: intakeDirectoryURL,
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: renderedDirectoryURL,
            withIntermediateDirectories: true
        )
        let sourceURL = intakeDirectoryURL
            .appendingPathComponent("source.jpg")
        let renderedURL = renderedDirectoryURL
            .appendingPathComponent("rendered.jpg")
        try Data("source".utf8).write(to: sourceURL)
        try Data("rendered".utf8).write(to: renderedURL)

        let taskID = UUID()
        defaults.set(
            try JSONEncoder().encode([
                savingJob(
                    taskID: taskID,
                    sourceURL: sourceURL,
                    renderedFileURL: renderedURL
                )
            ]),
            forKey: "photomemo.batchQueue.jobs"
        )
        let receiptStore = PhotoLibrarySaveReceiptStore(
            defaults: defaults
        )
        receiptStore.record(
            assetIdentifier: "missing-asset",
            for: taskID.uuidString
        )

        let store = BatchQueueStore(
            defaults: defaults,
            settingsService: SettingsService(defaults: defaults),
            externalIntakeStore: ExternalPhotoIntakeStore(
                defaults: defaults,
                intakeDirectoryURL: intakeDirectoryURL
            ),
            saveReceiptStore: receiptStore,
            photoLibraryReceiptAssetLocator:
                StubPhotoLibraryReceiptAssetLocator(
                    visibleAssetIdentifiers: [:]
                )
        )

        let task = try #require(store.jobs.first?.tasks.first)
        #expect(task.phase == .savingToPhotoLibrary)
        #expect(task.renderedFileURL == renderedURL)
        #expect(task.savedAssetIdentifier == nil)
        #expect(store.isProcessing == false)
        #expect(
            FileManager.default.fileExists(
                atPath: sourceURL.path
            )
        )
        #expect(
            FileManager.default.fileExists(
                atPath: renderedURL.path
            )
        )
        #expect(
            receiptStore.assetIdentifier(for: taskID.uuidString)
            == "missing-asset"
        )
    }

    @MainActor
    @Test("A later exact Photos readback completes a protected saving task without requeueing")
    func laterReceiptVisibilityCompletesProtectedSavingTask() throws {
        let suiteName =
            "PhotoMemo.BatchQueueStorePersistenceTests.ReceiptLaterVisibility.\(UUID().uuidString)"
        let defaults = try #require(
            UserDefaults(suiteName: suiteName)
        )
        defaults.removePersistentDomain(forName: suiteName)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let taskID = UUID()
        defaults.set(
            try JSONEncoder().encode([
                savingJob(taskID: taskID)
            ]),
            forKey: "photomemo.batchQueue.jobs"
        )
        let receiptStore = PhotoLibrarySaveReceiptStore(
            defaults: defaults
        )
        receiptStore.record(
            assetIdentifier: "receipt-backed-asset",
            for: taskID.uuidString
        )
        let assetLocator =
            MutablePhotoLibraryReceiptAssetLocator()
        let store = BatchQueueStore(
            defaults: defaults,
            settingsService: SettingsService(defaults: defaults),
            saveReceiptStore: receiptStore,
            photoLibraryReceiptAssetLocator: assetLocator,
            automaticallyStartsProcessing: false
        )

        #expect(
            store.jobs.first?.tasks.first?.phase
            == .savingToPhotoLibrary
        )
        assetLocator.visibleAssetIdentifiers[
            taskID.uuidString
        ] = "receipt-backed-asset"

        store.startProcessingIfNeeded()

        let task = try #require(store.jobs.first?.tasks.first)
        #expect(task.phase == .completed)
        #expect(
            task.savedAssetIdentifier
            == "receipt-backed-asset"
        )
        #expect(task.renderedFileURL == nil)
    }

    @MainActor
    @Test("Clearing persisted terminal history removes only its durable receipt")
    func clearingTerminalHistoryRemovesReceiptAfterQueuePersistence() throws {
        let suiteName =
            "PhotoMemo.BatchQueueStorePersistenceTests.ReceiptClear.\(UUID().uuidString)"
        let defaults = try #require(
            UserDefaults(suiteName: suiteName)
        )
        defaults.removePersistentDomain(forName: suiteName)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let taskID = UUID()
        defaults.set(
            try JSONEncoder().encode(
                [terminalExternalJob(taskID: taskID)]
            ),
            forKey: "photomemo.batchQueue.jobs"
        )
        let receiptStore = PhotoLibrarySaveReceiptStore(
            defaults: defaults
        )
        receiptStore.record(
            assetIdentifier: "asset-cleared",
            for: taskID.uuidString
        )
        let store = BatchQueueStore(
            defaults: defaults,
            settingsService: SettingsService(defaults: defaults),
            saveReceiptStore: receiptStore
        )

        store.clearTerminalExternalJobHistory(
            preserving: nil
        )

        #expect(store.jobs.isEmpty)
        #expect(
            receiptStore.assetIdentifier(for: taskID.uuidString)
            == nil
        )
    }

    @MainActor
    @Test("Failed queue persistence retains receipts for removed terminal history")
    func failedTerminalHistoryPersistenceRetainsReceipt() throws {
        let suiteName =
            "PhotoMemo.BatchQueueStorePersistenceTests.ReceiptFailure.\(UUID().uuidString)"
        let defaults = try #require(
            UserDefaults(suiteName: suiteName)
        )
        defaults.removePersistentDomain(forName: suiteName)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let taskID = UUID()
        let payload = try JSONEncoder().encode(
            [terminalExternalJob(taskID: taskID)]
        )
        let receiptStore = PhotoLibrarySaveReceiptStore(
            defaults: defaults
        )
        receiptStore.record(
            assetIdentifier: "asset-retained-after-failure",
            for: taskID.uuidString
        )
        let store = BatchQueueStore(
            defaults: defaults,
            settingsService: SettingsService(defaults: defaults),
            persistence: BatchQueuePersistence(
                backend: SaveRejectingBackend(
                    persistedData: payload
                )
            ),
            saveReceiptStore: receiptStore
        )

        store.clearTerminalExternalJobHistory(
            preserving: nil
        )

        #expect(
            receiptStore.assetIdentifier(for: taskID.uuidString)
            == "asset-retained-after-failure"
        )
    }

    @MainActor
    @Test("Corrupted queue data never triggers receipt pruning")
    func corruptedQueueDataRetainsReceipts() throws {
        let suiteName =
            "PhotoMemo.BatchQueueStorePersistenceTests.ReceiptCorruption.\(UUID().uuidString)"
        let defaults = try #require(
            UserDefaults(suiteName: suiteName)
        )
        defaults.removePersistentDomain(forName: suiteName)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        defaults.set(
            Data("corrupted-queue".utf8),
            forKey: "photomemo.batchQueue.jobs"
        )
        let taskID = UUID().uuidString
        let receiptStore = PhotoLibrarySaveReceiptStore(
            defaults: defaults
        )
        receiptStore.record(
            assetIdentifier: "asset-preserved",
            for: taskID
        )

        _ = BatchQueueStore(
            defaults: defaults,
            settingsService: SettingsService(defaults: defaults),
            saveReceiptStore: receiptStore
        )

        #expect(
            receiptStore.assetIdentifier(for: taskID)
            == "asset-preserved"
        )
    }

    @Test("encoded batch job keeps frozen configuration after aggregate update and deletion")
    func encodedBatchJobKeepsFrozenConfigurationIdentityAndContent() throws {
        let subject = try #require(
            ConfigurationCenterState.mock.selectedSubject
        )
        let originalConfigurationID = UUID(
            uuidString: "95959595-9595-9595-9595-959595959595"
        )!
        var canonical = ConfigurationSnapshotBuilder.build(
            from: subject
        )
        canonical.expression = MemoryExpression(
            title: "Frozen Memory",
            blocks: [.text("Original content")]
        )
        let originalSnapshot = BatchConfigurationSnapshot(
            template: .classicWhite.renamed("Frozen Preset"),
            badge: nil,
            anchor: nil,
            shouldWritePhotoDescription: true,
            photoDescriptionOverride: "Frozen description",
            selectedAlbumIdentifier: "frozen-album"
        )
        .withCanonicalProductionSnapshot(canonical)
        .withConfigurationIdentity(
            id: originalConfigurationID,
            revision: 4
        )
        let encodedJob = try JSONEncoder().encode(
            BatchJob(
                title: "Frozen job",
                configuration: originalSnapshot,
                tasks: []
            )
        )

        var currentSnapshot: BatchConfigurationSnapshot? =
            BatchConfigurationSnapshot(
                template: .classicWhite.renamed("Updated Preset"),
                badge: .family,
                anchor: nil,
                shouldWritePhotoDescription: false,
                photoDescriptionOverride: "Updated description",
                selectedAlbumIdentifier: "updated-album"
            )
            .withConfigurationIdentity(
                id: UUID(),
                revision: 5
            )
        currentSnapshot = nil

        let decodedJob = try JSONDecoder().decode(
            BatchJob.self,
            from: encodedJob
        )

        #expect(currentSnapshot == nil)
        #expect(
            decodedJob.configuration.configurationID
            == originalConfigurationID
        )
        #expect(decodedJob.configuration.configurationRevision == 4)
        #expect(decodedJob.configuration.template.name == "Frozen Preset")
        #expect(
            decodedJob.configuration.photoDescriptionOverride
            == "Frozen description"
        )
        #expect(
            decodedJob.configuration.canonicalProductionSnapshot?
                .configurationID
            == originalConfigurationID
        )
        #expect(
            decodedJob.configuration.canonicalProductionSnapshot?
                .configurationRevision
            == 4
        )
        #expect(
            decodedJob.configuration.canonicalProductionSnapshot?
                .expression.title
            == "Frozen Memory"
        )
    }

    private struct EncodingFailure:
        Error {}

    private struct SaveFailure:
        Error {}

    private struct ReadBackMismatchBackend:
        BatchQueuePersistenceBackend {

        func loadData(
            forKey key: String
        ) throws -> Data? {

            nil
        }

        func saveData(
            _ data: Data,
            forKey key: String
        ) throws {

            // Simulates a backend that reports success without retaining the payload.
        }
    }

    private struct FailingSaveBackend:
        BatchQueuePersistenceBackend {

        func loadData(
            forKey key: String
        ) throws -> Data? {

            nil
        }

        func saveData(
            _ data: Data,
            forKey key: String
        ) throws {

            throw SaveFailure()
        }
    }

    private struct SaveRejectingBackend:
        BatchQueuePersistenceBackend {

        let persistedData: Data

        func loadData(
            forKey key: String
        ) throws -> Data? {
            persistedData
        }

        func saveData(
            _ data: Data,
            forKey key: String
        ) throws {
            throw SaveFailure()
        }
    }

    private final class SwitchableSaveBackend:
        BatchQueuePersistenceBackend {

        var rejectsWrites = false
        private var persistedData: Data?

        func loadData(
            forKey key: String
        ) throws -> Data? {
            persistedData
        }

        func saveData(
            _ data: Data,
            forKey key: String
        ) throws {
            guard !rejectsWrites else {
                throw SaveFailure()
            }
            persistedData = data
        }
    }

    private func terminalExternalJob(
        taskID: UUID
    ) -> BatchJob {
        BatchJob(
            title: "Receipt history",
            launchSource: .shareExtension,
            configuration: BatchConfigurationSnapshot(
                template: .classicWhite,
                badge: nil,
                anchor: nil,
                shouldWritePhotoDescription: false,
                photoDescriptionOverride: "",
                selectedAlbumIdentifier: ""
            ),
            tasks: [
                BatchTask(
                    id: taskID,
                    sourceURL: URL(
                        fileURLWithPath: "/tmp/receipt-history.jpg"
                    ),
                    phase: .completed
                )
            ]
        )
    }

    private func savingJob(
        taskID: UUID,
        sourceURL: URL = URL(
            fileURLWithPath: "/tmp/receipt-recovery.jpg"
        ),
        renderedFileURL: URL = URL(
            fileURLWithPath: "/tmp/rendered-receipt-recovery.jpg"
        )
    ) -> BatchJob {
        BatchJob(
            title: "Receipt recovery",
            launchSource: .shareExtension,
            configuration: BatchConfigurationSnapshot(
                template: .classicWhite,
                badge: nil,
                anchor: nil,
                shouldWritePhotoDescription: false,
                photoDescriptionOverride: "",
                selectedAlbumIdentifier: ""
            ),
            tasks: [
                BatchTask(
                    id: taskID,
                    sourceURL: sourceURL,
                    phase: .savingToPhotoLibrary,
                    renderedFileURL: renderedFileURL,
                    progress: BatchTaskProgress(
                        currentUnit: 5,
                        totalUnits: 6,
                        statusMessage: "正在写入系统图库"
                    )
                )
            ]
        )
    }

    private struct StubPhotoLibraryReceiptAssetLocator:
        PhotoLibraryReceiptAssetLocating {

        let visibleAssetIdentifiers: [String: String]

        func visibleAssetIdentifier(
            for idempotencyKey: String
        ) -> String? {
            visibleAssetIdentifiers[idempotencyKey]
        }
    }

    private final class MutablePhotoLibraryReceiptAssetLocator:
        PhotoLibraryReceiptAssetLocating {

        var visibleAssetIdentifiers: [String: String] = [:]

        func visibleAssetIdentifier(
            for idempotencyKey: String
        ) -> String? {
            visibleAssetIdentifiers[idempotencyKey]
        }
    }

    @MainActor
    @Test("Deferred task updates do not rewrite persisted jobs until flush")
    func deferredTaskUpdatesDoNotRewritePersistedJobsUntilFlush() throws {

        let suiteName =
            "PhotoMemo.BatchQueueStorePersistenceTests.\(UUID().uuidString)"
        let defaults =
            try #require(
                UserDefaults(
                    suiteName: suiteName
                )
            )
        defaults.removePersistentDomain(
            forName: suiteName
        )

        let store =
            BatchQueueStore(
                defaults: defaults,
                settingsService:
                    SettingsService(
                        defaults: defaults
                    )
            )

        let job =
            try #require(
                store.enqueue(
                    urls: [
                        URL(
                            fileURLWithPath:
                                "/tmp/deferred-persist.jpg"
                        )
                    ]
                )
            )

        let initialPersistedData =
            try #require(
                defaults.data(
                    forKey:
                        "photomemo.batchQueue.jobs"
                )
            )
        let reference =
            try #require(
                store.nextPendingTaskReference()
            )

        store.updateTask(
            at: reference,
            persist: false
        ) { task in
            task.phase = .importing
            task.progress = BatchTaskProgress(
                currentUnit: 1,
                totalUnits: 5,
                statusMessage: "正在读取原图"
            )
        }

        let deferredPersistedData =
            try #require(
                defaults.data(
                    forKey:
                        "photomemo.batchQueue.jobs"
                )
            )

        #expect(
            deferredPersistedData
            == initialPersistedData
        )
        #expect(
            store.currentTask(
                at: reference
            )?.phase == .importing
        )

        store.persistJobs()

        let flushedPersistedData =
            try #require(
                defaults.data(
                    forKey:
                        "photomemo.batchQueue.jobs"
                )
            )
        let decodedJobs =
            try JSONDecoder()
            .decode(
                [BatchJob].self,
                from: flushedPersistedData
            )

        #expect(
            flushedPersistedData
            != initialPersistedData
        )
        #expect(decodedJobs.count == 1)
        #expect(decodedJobs[0].id == job.id)
        #expect(decodedJobs[0].tasks[0].phase == .importing)

        defaults.removePersistentDomain(
            forName: suiteName
        )
    }

    @MainActor
    @Test("Multiple deferred task updates flush the latest state once")
    func multipleDeferredTaskUpdatesFlushTheLatestStateOnce() throws {

        let suiteName =
            "PhotoMemo.BatchQueueStorePersistenceTests.Multiple.\(UUID().uuidString)"
        let defaults =
            try #require(
                UserDefaults(
                    suiteName: suiteName
                )
            )
        defaults.removePersistentDomain(
            forName: suiteName
        )

        let store =
            BatchQueueStore(
                defaults: defaults,
                settingsService:
                    SettingsService(
                        defaults: defaults
                    )
            )

        _ =
            try #require(
                store.enqueue(
                    urls: [
                        URL(
                            fileURLWithPath:
                                "/tmp/multiple-deferred-persist.jpg"
                        )
                    ]
                )
            )

        let initialPersistedData =
            try #require(
                defaults.data(
                    forKey:
                        "photomemo.batchQueue.jobs"
                )
            )
        let reference =
            try #require(
                store.nextPendingTaskReference()
            )

        store.updateTask(
            at: reference,
            persist: false
        ) { task in
            task.phase = .metadataReady
            task.progress = BatchTaskProgress(
                currentUnit: 2,
                totalUnits: 5,
                statusMessage: "已读取 EXIF 和拍摄时间"
            )
        }

        store.updateTask(
            at: reference,
            persist: false
        ) { task in
            task.phase = .exporting
            task.progress = BatchTaskProgress(
                currentUnit: 4,
                totalUnits: 5,
                statusMessage: "正在生成图片"
            )
        }

        let deferredPersistedData =
            try #require(
                defaults.data(
                    forKey:
                        "photomemo.batchQueue.jobs"
                )
            )

        #expect(
            deferredPersistedData
            == initialPersistedData
        )
        #expect(
            store.currentTask(
                at: reference
            )?.phase == .exporting
        )

        store.persistJobs()

        let flushedPersistedData =
            try #require(
                defaults.data(
                    forKey:
                        "photomemo.batchQueue.jobs"
                )
            )
        let decodedJobs =
            try JSONDecoder()
            .decode(
                [BatchJob].self,
                from: flushedPersistedData
            )

        #expect(
            flushedPersistedData
            != initialPersistedData
        )
        #expect(decodedJobs[0].tasks[0].phase == .exporting)
        #expect(
            decodedJobs[0].tasks[0].progress.statusMessage
            == "正在生成图片"
        )

        defaults.removePersistentDomain(
            forName: suiteName
        )
    }

    @MainActor
    @Test("Batch queue persistence reports encoding failures without overwriting existing payload")
    func batchQueuePersistenceReportsEncodingFailuresWithoutOverwritingExistingPayload() throws {

        let suiteName =
            "PhotoMemo.BatchQueueStorePersistenceTests.EncodingFailure.\(UUID().uuidString)"
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

        let store =
            BatchQueueStore(
                defaults: defaults,
                settingsService:
                    SettingsService(
                        defaults: defaults
                    )
            )
        let job =
            try #require(
                store.enqueue(
                    urls: [
                        URL(
                            fileURLWithPath:
                                "/tmp/encoding-failure-persist.jpg"
                        )
                    ]
                )
            )
        let existingPayload =
            Data("previous-payload".utf8)
        defaults.set(
            existingPayload,
            forKey:
                "photomemo.batchQueue.jobs"
        )

        let persistence =
            BatchQueuePersistence(
                defaults: defaults,
                encodeJobs: { _ in
                    throw EncodingFailure()
                }
            )
        let result =
            persistence
            .persistJobs(
                [job]
            )

        switch result {
        case .success:
            Issue.record("Expected persistence write failure")
        case .failure(let error):
            #expect(error.code == .persistenceWriteFailed)
            #expect(
                error.underlyingDescription?
                .contains("EncodingFailure") == true
            )
        }

        #expect(
            defaults.data(
                forKey:
                    "photomemo.batchQueue.jobs"
            )
            == existingPayload
        )
    }

    @MainActor
    @Test("Queue admission rolls back when durable persistence fails")
    func queueAdmissionRollsBackWhenDurablePersistenceFails() throws {
        let suiteName =
            "PhotoMemo.BatchQueueStorePersistenceTests.AdmissionFailure.\(UUID().uuidString)"
        let defaults = try #require(
            UserDefaults(suiteName: suiteName)
        )
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }
        let store = BatchQueueStore(
            defaults: defaults,
            settingsService: SettingsService(defaults: defaults),
            persistence: BatchQueuePersistence(
                backend: FailingSaveBackend()
            )
        )

        let job = store.enqueue(
            urls: [
                URL(
                    fileURLWithPath:
                        "/tmp/admission-persistence-failure.jpg"
                )
            ]
        )

        #expect(job == nil)
        #expect(store.jobs.isEmpty)
    }

    @MainActor
    @Test("Cancelling a queued task retains its managed source when persistence fails")
    func cancellationPersistenceFailureRetainsManagedSource() throws {
        let suiteName =
            "PhotoMemo.BatchQueueStorePersistenceTests.CancellationFailure.\(UUID().uuidString)"
        let defaults = try #require(
            UserDefaults(suiteName: suiteName)
        )
        let intakeDirectoryURL = FileManager.default
            .temporaryDirectory
            .appendingPathComponent(
                suiteName,
                isDirectory: true
            )
        defer {
            defaults.removePersistentDomain(forName: suiteName)
            try? FileManager.default.removeItem(
                at: intakeDirectoryURL
            )
        }
        try FileManager.default.createDirectory(
            at: intakeDirectoryURL,
            withIntermediateDirectories: true
        )
        let managedSourceURL = intakeDirectoryURL
            .appendingPathComponent("managed-source.jpg")
        try Data("managed-source".utf8).write(
            to: managedSourceURL
        )
        let backend = SwitchableSaveBackend()
        let store = BatchQueueStore(
            defaults: defaults,
            settingsService: SettingsService(defaults: defaults),
            externalIntakeStore: ExternalPhotoIntakeStore(
                defaults: defaults,
                intakeDirectoryURL: intakeDirectoryURL
            ),
            persistence: BatchQueuePersistence(
                backend: backend
            )
        )
        let job = try #require(
            store.enqueue(urls: [managedSourceURL])
        )

        backend.rejectsWrites = true
        store.cancelJob(job.id)

        #expect(store.jobs[0].tasks[0].phase == .cancelled)
        #expect(
            FileManager.default.fileExists(
                atPath: managedSourceURL.path
            )
        )
    }

    @MainActor
    @Test("Terminal task cleanup retains its managed source when persistence fails")
    func terminalCleanupPersistenceFailureRetainsManagedSource() throws {
        let suiteName =
            "PhotoMemo.BatchQueueStorePersistenceTests.TerminalCleanupFailure.\(UUID().uuidString)"
        let defaults = try #require(
            UserDefaults(suiteName: suiteName)
        )
        let intakeDirectoryURL = FileManager.default
            .temporaryDirectory
            .appendingPathComponent(
                suiteName,
                isDirectory: true
            )
        defer {
            defaults.removePersistentDomain(forName: suiteName)
            try? FileManager.default.removeItem(
                at: intakeDirectoryURL
            )
        }
        try FileManager.default.createDirectory(
            at: intakeDirectoryURL,
            withIntermediateDirectories: true
        )
        let managedSourceURL = intakeDirectoryURL
            .appendingPathComponent("terminal-managed-source.jpg")
        try Data("managed-source".utf8).write(
            to: managedSourceURL
        )
        let backend = SwitchableSaveBackend()
        let store = BatchQueueStore(
            defaults: defaults,
            settingsService: SettingsService(defaults: defaults),
            externalIntakeStore: ExternalPhotoIntakeStore(
                defaults: defaults,
                intakeDirectoryURL: intakeDirectoryURL
            ),
            persistence: BatchQueuePersistence(
                backend: backend
            )
        )
        _ = try #require(
            store.enqueue(urls: [managedSourceURL])
        )
        let reference = try #require(
            store.nextPendingTaskReference()
        )
        store.updateTask(
            at: reference,
            persist: false
        ) { task in
            task.phase = .completed
        }

        backend.rejectsWrites = true
        let didCleanup = store
            .cleanupManagedSourceForDurablyTerminalTask(
                at: reference
            )

        #expect(!didCleanup)
        #expect(
            FileManager.default.fileExists(
                atPath: managedSourceURL.path
            )
        )
    }

    @MainActor
    @Test("Batch queue persistence reports backend save failures")
    func batchQueuePersistenceReportsBackendSaveFailures() throws {

        let suiteName =
            "PhotoMemo.BatchQueueStorePersistenceTests.SaveFailure.\(UUID().uuidString)"
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

        let store =
            BatchQueueStore(
                defaults: defaults,
                settingsService:
                    SettingsService(
                        defaults: defaults
                    )
            )
        let job =
            try #require(
                store.enqueue(
                    urls: [
                        URL(
                            fileURLWithPath:
                                "/tmp/save-failure-persist.jpg"
                        )
                    ]
                )
            )
        let persistence =
            BatchQueuePersistence(
                backend: FailingSaveBackend()
            )

        let result =
            persistence
            .persistJobs(
                [job]
            )

        switch result {
        case .success:
            Issue.record("Expected backend save failure")
        case .failure(let error):
            #expect(error.code == .persistenceWriteFailed)
            #expect(
                error.underlyingDescription?
                .contains("SaveFailure") == true
            )
        }
    }

    @Test("Batch queue persistence reports a successful write that fails read-back verification")
    func batchQueuePersistenceReportsReadBackVerificationFailures() throws {

        let persistence = BatchQueuePersistence(
            backend: ReadBackMismatchBackend()
        )

        let result = persistence.persistJobs([])

        switch result {
        case .success:
            Issue.record("Expected read-back verification failure")
        case .failure(let error):
            #expect(error.code == .persistenceWriteFailed)
            #expect(
                error.underlyingDescription?
                    .contains("readBack") == true
            )
        }
    }

    @Test("UserDefaults persistence trusts verified read-back when synchronize reports false")
    func userDefaultsPersistenceUsesReadBackAsCommitEvidence() throws {
        let suiteName =
            "PhotoMemo.BatchQueueStorePersistenceTests.SynchronizeFalse.\(UUID().uuidString)"
        let defaults = try #require(
            UserDefaults(suiteName: suiteName)
        )
        defaults.removePersistentDomain(forName: suiteName)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }
        let backend =
            UserDefaultsBatchQueuePersistenceBackend(
                defaults: defaults,
                synchronize: { false }
            )
        let payload = Data("verified-write".utf8)

        try backend.saveData(
            payload,
            forKey: "verified-key"
        )

        #expect(
            try backend.loadData(forKey: "verified-key")
            == payload
        )
    }
}

private extension Template {
    func renamed(_ name: String) -> Template {
        var copy = self
        copy.name = name
        return copy
    }
}
