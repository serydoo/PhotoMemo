import Foundation
import Testing
@testable import PhotoMemo

@Suite("Batch queue store persistence")
struct BatchQueueStorePersistenceTests {

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
}
