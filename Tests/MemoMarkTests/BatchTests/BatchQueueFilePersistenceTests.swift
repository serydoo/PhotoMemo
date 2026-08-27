import Foundation
import Testing
@testable import MemoMark

@Suite("Batch queue file persistence", .serialized)
struct BatchQueueFilePersistenceTests {

    @Test("Legacy defaults queue is imported once into the durable file snapshot")
    func legacyDefaultsQueueIsImportedOnce() throws {
        let context = try TestContext()
        defer { context.cleanup() }

        let legacyJob = Self.makeJob(title: "Legacy")
        context.defaults.set(
            try JSONEncoder().encode([legacyJob]),
            forKey: BatchQueuePersistence.storageKey
        )

        let persistence = BatchQueuePersistence(
            fileBaseDirectoryURL: context.rootURL,
            legacyDefaults: context.defaults
        )

        #expect(
            persistence.loadPersistedJobsResult().value
            == [legacyJob]
        )
        #expect(
            FileManager.default.fileExists(
                atPath: context.snapshotURL.path
            )
        )

        context.defaults.removeObject(
            forKey: BatchQueuePersistence.storageKey
        )

        #expect(
            persistence.loadPersistedJobsResult().value
            == [legacyJob]
        )
    }

    @Test("Existing file snapshot wins over stale legacy defaults")
    func existingFileSnapshotWinsOverLegacyDefaults() throws {
        let context = try TestContext()
        defer { context.cleanup() }

        let durableJob = Self.makeJob(title: "Durable")
        let staleLegacyJob = Self.makeJob(title: "Stale")
        context.defaults.set(
            try JSONEncoder().encode([staleLegacyJob]),
            forKey: BatchQueuePersistence.storageKey
        )

        let persistence = BatchQueuePersistence(
            fileBaseDirectoryURL: context.rootURL,
            legacyDefaults: context.defaults
        )
        #expect(persistence.persistJobs([durableJob]).error == nil)

        #expect(
            persistence.loadPersistedJobsResult().value
            == [durableJob]
        )
    }

    @Test("Corrupted legacy data is not promoted into the file snapshot")
    func corruptedLegacyDataIsNotPromoted() throws {
        let context = try TestContext()
        defer { context.cleanup() }

        context.defaults.set(
            Data("corrupted-legacy-queue".utf8),
            forKey: BatchQueuePersistence.storageKey
        )

        let persistence = BatchQueuePersistence(
            fileBaseDirectoryURL: context.rootURL,
            legacyDefaults: context.defaults
        )
        let result = persistence.loadPersistedJobsResult()

        #expect(result.error?.code == .persistenceReadFailed)
        #expect(
            !FileManager.default.fileExists(
                atPath: context.snapshotURL.path
            )
        )
    }

    @Test("File backend creates its directory and verifies atomic round trip")
    func fileBackendRoundTripsData() throws {
        let context = try TestContext()
        defer { context.cleanup() }
        let backend = FileBatchQueuePersistenceBackend(
            baseDirectoryURL: context.rootURL
        )
        let payload = Data("durable-queue".utf8)

        try backend.saveData(
            payload,
            forKey: BatchQueuePersistence.storageKey
        )

        #expect(
            try backend.loadData(
                forKey: BatchQueuePersistence.storageKey
            ) == payload
        )
        #expect(
            FileManager.default.fileExists(
                atPath: context.snapshotURL.path
            )
        )
    }
}

private extension BatchQueueFilePersistenceTests {

    final class TestContext {

        let suiteName: String
        let defaults: UserDefaults
        let rootURL: URL

        init() throws {
            suiteName =
                "MemoMark.BatchQueueFilePersistenceTests.\(UUID().uuidString)"
            defaults = try #require(
                UserDefaults(suiteName: suiteName)
            )
            defaults.removePersistentDomain(forName: suiteName)
            rootURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(
                    suiteName,
                    isDirectory: true
                )
        }

        var snapshotURL: URL {
            rootURL
                .appendingPathComponent(
                    "BatchQueue",
                    isDirectory: true
                )
                .appendingPathComponent(
                    "jobs-v1.json",
                    isDirectory: false
                )
        }

        func cleanup() {
            defaults.removePersistentDomain(forName: suiteName)
            try? FileManager.default.removeItem(at: rootURL)
        }
    }

    static func makeJob(
        title: String
    ) -> BatchJob {
        let now = Date(timeIntervalSince1970: 1_787_779_200)
        return BatchJob(
            title: title,
            createdAt: now,
            updatedAt: now,
            state: .queued,
            launchSource: .shareExtension,
            configuration: BatchConfigurationSnapshot(
                template: .classicWhite,
                badge: nil,
                anchor: nil,
                shouldWritePhotoDescription: true,
                photoDescriptionOverride: "",
                selectedAlbumIdentifier: ""
            ),
            tasks: [
                BatchTask(
                    sourceURL: URL(
                        fileURLWithPath:
                            "/tmp/\(UUID().uuidString).jpg"
                    ),
                    phase: .queued
                )
            ]
        )
    }
}
