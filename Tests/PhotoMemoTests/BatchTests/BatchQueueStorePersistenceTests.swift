import Foundation
import Testing
@testable import PhotoMemo

@Suite("Batch queue store persistence")
struct BatchQueueStorePersistenceTests {

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
}

private extension Template {
    func renamed(_ name: String) -> Template {
        var copy = self
        copy.name = name
        return copy
    }
}
