#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
import UniformTypeIdentifiers
@testable import PhotoMemo

@Suite("ExternalPhotoIntakeCenter")
struct ExternalPhotoIntakeCenterTests {

    @MainActor
    @Test("accepts RAW URLs through the shared intake policy")
    func acceptsRAWURLsThroughSharedIntakePolicy() throws {
        let suiteName =
            "PhotoMemo.ExternalPhotoIntakeCenterTests.\(UUID().uuidString)"
        let defaults =
            try #require(
                UserDefaults(
                    suiteName: suiteName
                )
            )
        defaults.removePersistentDomain(
            forName: suiteName
        )

        let intakeDirectoryURL =
            FileManager.default.temporaryDirectory
            .appendingPathComponent(
                suiteName,
                isDirectory: true
            )
        defer {
            try? FileManager.default.removeItem(
                at: intakeDirectoryURL
            )
            defaults.removePersistentDomain(
                forName: suiteName
            )
        }

        let center =
            ExternalPhotoIntakeCenter(
                intakeStore:
                    ExternalPhotoIntakeStore(
                        defaults: defaults,
                        intakeDirectoryURL:
                            intakeDirectoryURL
                    ),
                settingsService:
                    SettingsService(
                        defaults: defaults
                    )
            )
        let rawURL =
            URL(fileURLWithPath: "/tmp/IMG_0001.dng")
        let unsupportedURL =
            URL(fileURLWithPath: "/tmp/notes.txt")

        center.submit(
            urls: [
                rawURL,
                rawURL,
                unsupportedURL
            ],
            source: .quickAction
        )

        let request =
            try #require(
                center.drainPendingRequests().first
            )

        #expect(
            request.urls.map(\.lastPathComponent)
            == ["IMG_0001.dng"]
        )
    }

    @MainActor
    @Test("accepts Live Photo intake items with source asset identity")
    func acceptsLivePhotoIntakeItemsWithSourceAssetIdentity() throws {
        let suiteName =
            "PhotoMemo.ExternalPhotoIntakeCenterTests.LivePhoto.\(UUID().uuidString)"
        let defaults =
            try #require(
                UserDefaults(
                    suiteName: suiteName
                )
            )
        defaults.removePersistentDomain(
            forName: suiteName
        )

        let intakeDirectoryURL =
            FileManager.default.temporaryDirectory
            .appendingPathComponent(
                suiteName,
                isDirectory: true
            )
        defer {
            try? FileManager.default.removeItem(
                at: intakeDirectoryURL
            )
            defaults.removePersistentDomain(
                forName: suiteName
            )
        }

        let center =
            ExternalPhotoIntakeCenter(
                intakeStore:
                    ExternalPhotoIntakeStore(
                        defaults: defaults,
                        intakeDirectoryURL:
                            intakeDirectoryURL
                    ),
                settingsService:
                    SettingsService(
                        defaults: defaults
                    )
            )
        let livePhotoType =
            try #require(
                UTType(
                    "com.apple.live-photo"
                )
            )
        let livePhotoItem =
            ExternalPhotoIntakeItem(
                managedURL:
                    URL(
                        fileURLWithPath:
                            "/tmp/IMG_6093.HEIC"
                    ),
                originalFileName:
                    "IMG_6093.HEIC",
                sourceIdentifier:
                    "live-photo-local-identifier",
                contentTypeIdentifier:
                    livePhotoType.identifier
            )
        let unsupportedItem =
            ExternalPhotoIntakeItem(
                managedURL:
                    URL(
                        fileURLWithPath:
                            "/tmp/notes.txt"
                    ),
                contentTypeIdentifier:
                    UTType.plainText.identifier
            )

        center.submit(
            items: [
                livePhotoItem,
                livePhotoItem,
                unsupportedItem
            ],
            source: .quickAction
        )

        let request =
            try #require(
                center.drainPendingRequests().first
            )
        let payload =
            try #require(
                request.intakePayloads.first
            )

        #expect(request.urls.count == 1)
        #expect(payload.fileName == "IMG_6093.HEIC")
        #expect(
            payload.sourceIdentifier
            == "live-photo-local-identifier"
        )
        #expect(
            payload.contentTypeIdentifier
            == livePhotoType.identifier
        )
    }

    @MainActor
    @Test("In-memory fallback requests remain until processing is acknowledged")
    func inMemoryFallbackRequestsRemainUntilAcknowledged() throws {
        let suiteName =
            "PhotoMemo.ExternalPhotoIntakeCenterTests.PendingFallback.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }
        let intakeDirectoryURL =
            FileManager.default.temporaryDirectory
            .appendingPathComponent(suiteName, isDirectory: true)
        defer {
            try? FileManager.default.removeItem(at: intakeDirectoryURL)
        }

        defaults.set(
            Data("corrupted-intake".utf8),
            forKey: ExternalIntakeRequestStore.storageKey
        )
        let center = ExternalPhotoIntakeCenter(
            intakeStore:
                ExternalPhotoIntakeStore(
                    defaults: defaults,
                    intakeDirectoryURL: intakeDirectoryURL
                ),
            settingsService:
                SettingsService(defaults: defaults)
        )
        center.submit(
            urls: [URL(fileURLWithPath: "/tmp/fallback.jpg")],
            source: .quickAction
        )

        let firstDrain = try #require(
            center.drainPendingRequests().first
        )
        let retryDrain = try #require(
            center.drainPendingRequests().first
        )

        #expect(retryDrain.id == firstDrain.id)
        switch center.acknowledgeProcessedRequests([firstDrain]) {
        case .success:
            break
        case .encodingFailed:
            Issue.record("Expected fallback acknowledgement to succeed")
        }
        #expect(center.drainPendingRequests().isEmpty)
    }

    @MainActor
    @Test("Unacknowledged requests keep their managed source files referenced")
    func unacknowledgedRequestsKeepManagedSourcesReferenced() throws {
        let suiteName =
            "PhotoMemo.ExternalPhotoIntakeCenterTests.ManagedReferences.\(UUID().uuidString)"
        let defaults = try #require(
            UserDefaults(suiteName: suiteName)
        )
        let intakeDirectoryURL =
            FileManager.default.temporaryDirectory
            .appendingPathComponent(
                suiteName,
                isDirectory: true
            )
        defer {
            defaults.removePersistentDomain(
                forName: suiteName
            )
            try? FileManager.default.removeItem(
                at: intakeDirectoryURL
            )
        }

        let sourceURL =
            FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "PhotoMemo-source-\(UUID().uuidString).jpg"
            )
        try Data([1]).write(to: sourceURL)
        defer {
            try? FileManager.default.removeItem(
                at: sourceURL
            )
        }

        let store = ExternalPhotoIntakeStore(
            defaults: defaults,
            intakeDirectoryURL: intakeDirectoryURL
        )
        let center = ExternalPhotoIntakeCenter(
            intakeStore: store,
            settingsService:
                SettingsService(defaults: defaults)
        )
        center.submit(
            urls: [sourceURL],
            source: .shareExtension
        )

        let managedURL = try #require(
            center.drainPendingRequests()
                .first?.intakePayloads
                .first?.sourceURL
        )
        let references = try #require(
            center.referencedManagedSourceURLs()
        )

        store.cleanupOrphanedManagedContent(
            keepingReferencedURLs: references
        )

        #expect(references.contains(managedURL))
        #expect(
            FileManager.default.fileExists(
                atPath: managedURL.path
            )
        )
    }
}
#endif
