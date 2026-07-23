import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import PhotoMemo

@Suite("External intake responsibility layers")
struct ExternalIntakeResponsibilityLayerTests {

    @Test("Request store preserves the existing JSON request contract when persisting and draining")
    func requestStorePreservesJSONContract() throws {

        let suiteName =
            "PhotoMemo.ExternalIntakeResponsibilityLayerTests.Requests.\(UUID().uuidString)"
        let defaults =
            try #require(
                UserDefaults(
                    suiteName: suiteName
                )
            )
        defaults.removePersistentDomain(
            forName: suiteName
        )

        let request =
            ExternalPhotoIntakeRequest(
                id: UUID(),
                launchSource: .shareExtension,
                urls: [
                    URL(fileURLWithPath: "/tmp/ExternalIntake/managed.heic")
                ],
                configurationSnapshot:
                    Self.configurationSnapshot,
                importSummary:
                    ExternalPhotoImportSummary(
                        importedCount: 1,
                        skippedCount: 0,
                        failedCount: 0
                    )
            )
        let store =
            ExternalIntakeRequestStore(
                defaults: defaults
            )

        let failure =
            store.persistRequest(
                request,
                diagnosticsSeed: .init()
            )

        #expect(failure == nil)
        let persistedData =
            try #require(
                defaults.data(
                    forKey:
                        ExternalIntakeRequestStore
                        .storageKey
                )
            )
        #expect(
            try JSONDecoder().decode(
                [ExternalPhotoIntakeRequest].self,
                from: persistedData
            )
            == [request]
        )

        let drainResult =
            store.drainRequestsResult()

        #expect(drainResult.requests == [request])
        switch drainResult.clearPersistedRequestsResult {
        case .success:
            break
        case .encodingFailed:
            Issue.record(
                "Expected draining persisted requests to clear request storage."
            )
        case nil:
            Issue.record(
                "Expected a persistence result when draining a stored request."
            )
        }
        #expect(
            try JSONDecoder().decode(
                [ExternalPhotoIntakeRequest].self,
                from: try #require(
                    defaults.data(
                        forKey:
                            ExternalIntakeRequestStore
                            .storageKey
                    )
                )
            )
            .isEmpty
        )

        defaults.removePersistentDomain(
            forName: suiteName
        )
    }

    @Test("Acknowledging one request preserves requests appended after the drain")
    func acknowledgingOneRequestPreservesLaterRequests() throws {

        let suiteName =
            "PhotoMemo.ExternalIntakeResponsibilityLayerTests.Ack.\(UUID().uuidString)"
        let defaults =
            try #require(UserDefaults(suiteName: suiteName))
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let store = ExternalIntakeRequestStore(defaults: defaults)
        let firstRequest = ExternalPhotoIntakeRequest(
            id: UUID(),
            launchSource: .shareExtension,
            urls: [URL(fileURLWithPath: "/tmp/first.jpg")],
            configurationSnapshot: Self.configurationSnapshot
        )
        let laterRequest = ExternalPhotoIntakeRequest(
            id: UUID(),
            launchSource: .shareExtension,
            urls: [URL(fileURLWithPath: "/tmp/later.jpg")],
            configurationSnapshot: Self.configurationSnapshot
        )

        #expect(
            store.persistRequest(firstRequest, diagnosticsSeed: .init()) == nil
        )
        _ = store.loadRequestsForProcessing()
        #expect(
            store.persistRequest(laterRequest, diagnosticsSeed: .init()) == nil
        )

        switch store.acknowledgeRequests(Set([firstRequest.id])) {
        case .success:
            break
        case .encodingFailed:
            Issue.record("Expected request acknowledgement to persist")
        }

        switch store.loadRequestsResult() {
        case .success(let requests):
            #expect(requests == [laterRequest])
        case .noValue, .decodingFailed:
            Issue.record("Expected the later request to remain persisted")
        }
    }

    @Test("Persisting a new request does not overwrite a corrupted request payload")
    func persistingRequestPreservesCorruptedPayload() throws {

        let suiteName =
            "PhotoMemo.ExternalIntakeResponsibilityLayerTests.CorruptedAppend.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let corruptedPayload = Data("corrupted-intake".utf8)
        defaults.set(
            corruptedPayload,
            forKey: ExternalIntakeRequestStore.storageKey
        )
        let store = ExternalIntakeRequestStore(defaults: defaults)
        let request = ExternalPhotoIntakeRequest(
            launchSource: .shareExtension,
            urls: [URL(fileURLWithPath: "/tmp/new-request.jpg")],
            configurationSnapshot: Self.configurationSnapshot
        )

        let failure = store.persistRequest(
            request,
            diagnosticsSeed: .init()
        )

        #expect(failure != nil)
        #expect(
            defaults.data(
                forKey: ExternalIntakeRequestStore.storageKey
            ) == corruptedPayload
        )
    }

    @Test("Managed file store keeps already-managed identity and deduplicates normalized inputs")
    func managedFileStorePreservesManagedIdentityAndDeduplication() throws {

        let rootDirectoryURL =
            FileManager.default
            .temporaryDirectory
            .appendingPathComponent(
                "PhotoMemo.ExternalIntakeResponsibilityLayerTests.Managed.\(UUID().uuidString)",
                isDirectory: true
            )
        let intakeDirectoryURL =
            rootDirectoryURL
            .appendingPathComponent(
                "ExternalIntake",
                isDirectory: true
            )
        let requestDirectoryURL =
            intakeDirectoryURL
            .appendingPathComponent(
                UUID().uuidString,
                isDirectory: true
            )
        let managedURL =
            requestDirectoryURL
            .appendingPathComponent(
                "IMG_9558.HEIC"
            )

        try FileManager.default.createDirectory(
            at: requestDirectoryURL,
            withIntermediateDirectories: true
        )
        try Self.smallJPEGData().write(
            to: managedURL
        )

        let store =
            ManagedIntakeFileStore(
                intakeDirectoryURL:
                    intakeDirectoryURL
            )
        let result =
            store.createManagedCopyDetailed(
                from: managedURL,
                requestID: UUID(),
                index: 0
            )

        #expect(
            result.managedURL
            == managedURL.standardizedFileURL
        )
        #expect(
            result.temporaryCopyResult
            == "already-managed"
        )
        #expect(
            store.uniqueStandardizedURLs(
                from: [managedURL, managedURL]
            )
            == [managedURL.standardizedFileURL]
        )

        try? FileManager.default.removeItem(
            at: rootDirectoryURL
        )
    }

    @Test("Cleanup service removes only unreferenced managed content")
    func cleanupServicePreservesReferencesAndExternalFiles() throws {

        let rootDirectoryURL =
            FileManager.default
            .temporaryDirectory
            .appendingPathComponent(
                "PhotoMemo.ExternalIntakeResponsibilityLayerTests.Cleanup.\(UUID().uuidString)",
                isDirectory: true
            )
        let intakeDirectoryURL =
            rootDirectoryURL
            .appendingPathComponent(
                "ExternalIntake",
                isDirectory: true
            )
        let retainedDirectoryURL =
            intakeDirectoryURL
            .appendingPathComponent(
                "retained-request",
                isDirectory: true
            )
        let orphanDirectoryURL =
            intakeDirectoryURL
            .appendingPathComponent(
                "orphan-request",
                isDirectory: true
            )
        let retainedURL =
            retainedDirectoryURL
            .appendingPathComponent("retained.jpg")
        let orphanSiblingURL =
            retainedDirectoryURL
            .appendingPathComponent("orphan.jpg")
        let orphanRequestURL =
            orphanDirectoryURL
            .appendingPathComponent("orphan.jpg")
        let prefixSiblingDirectoryURL =
            rootDirectoryURL
            .appendingPathComponent(
                "ExternalIntake-Originals",
                isDirectory: true
            )
        let externalURL =
            prefixSiblingDirectoryURL
            .appendingPathComponent("original.jpg")

        for directoryURL in [
            retainedDirectoryURL,
            orphanDirectoryURL,
            prefixSiblingDirectoryURL
        ] {
            try FileManager.default.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true
            )
        }
        for fileURL in [
            retainedURL,
            orphanSiblingURL,
            orphanRequestURL,
            externalURL
        ] {
            try Data([1]).write(
                to: fileURL
            )
        }

        let service =
            IntakeCleanupService(
                intakeDirectoryURL:
                    intakeDirectoryURL
            )

        service.cleanupOrphanedManagedContent(
            keepingReferencedURLs: [
                retainedURL
            ]
        )
        service.cleanupManagedSourceIfNeeded(
            at: externalURL
        )

        #expect(
            FileManager.default.fileExists(
                atPath: retainedURL.path
            )
        )
        #expect(
            !FileManager.default.fileExists(
                atPath: orphanSiblingURL.path
            )
        )
        #expect(
            !FileManager.default.fileExists(
                atPath: orphanDirectoryURL.path
            )
        )
        #expect(
            FileManager.default.fileExists(
                atPath: externalURL.path
            )
        )

        service.cleanupManagedSourceIfNeeded(
            at: retainedURL
        )

        #expect(
            !FileManager.default.fileExists(
                atPath: retainedURL.path
            )
        )
        #expect(
            !FileManager.default.fileExists(
                atPath: retainedDirectoryURL.path
            )
        )
        #expect(
            FileManager.default.fileExists(
                atPath: externalURL.path
            )
        )

        try? FileManager.default.removeItem(
            at: rootDirectoryURL
        )
    }

    @Test("Request store keeps intake unacknowledged when the shared lock cannot be acquired")
    func requestStoreReportsLockFailureWithoutPersistingOrDroppingTheRequest() throws {

        let suiteName =
            "PhotoMemo.ExternalIntakeResponsibilityLayerTests.LockFailure.\(UUID().uuidString)"
        let defaults =
            try #require(UserDefaults(suiteName: suiteName))
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let blockerURL =
            FileManager.default.temporaryDirectory
                .appendingPathComponent(suiteName)
        try Data("lock-parent-is-a-file".utf8).write(to: blockerURL)
        defer {
            try? FileManager.default.removeItem(at: blockerURL)
        }

        let request = ExternalPhotoIntakeRequest(
            id: UUID(),
            launchSource: .shareExtension,
            urls: [URL(fileURLWithPath: "/tmp/managed-lock-failure.jpg")],
            configurationSnapshot: Self.configurationSnapshot
        )
        let store = ExternalIntakeRequestStore(
            defaults: defaults,
            lockURL: blockerURL.appendingPathComponent("requests.lock")
        )

        let failure = store.persistRequest(request, diagnosticsSeed: .init())

        #expect(failure != nil)
        #expect(
            defaults.data(forKey: ExternalIntakeRequestStore.storageKey)
            == nil
        )
    }
}

private extension ExternalIntakeResponsibilityLayerTests {

    static var configurationSnapshot:
        BatchConfigurationSnapshot {

        BatchConfigurationSnapshot(
            template:
                .classicWhite.normalizedForEditing,
            badge: nil,
            anchor: nil,
            shouldWritePhotoDescription: false,
            photoDescriptionOverride: "",
            selectedAlbumIdentifier: ""
        )
    }

    static func smallJPEGData() throws -> Data {

        let colorSpace =
            try #require(
                CGColorSpace(
                    name:
                        CGColorSpace.sRGB
                )
            )
        let context =
            try #require(
                CGContext(
                    data: nil,
                    width: 1,
                    height: 1,
                    bitsPerComponent: 8,
                    bytesPerRow: 4,
                    space: colorSpace,
                    bitmapInfo:
                        CGImageAlphaInfo
                        .premultipliedLast
                        .rawValue
                )
            )
        context.setFillColor(
            CGColor(
                red: 0.4,
                green: 0.5,
                blue: 0.6,
                alpha: 1
            )
        )
        context.fill(
            CGRect(
                x: 0,
                y: 0,
                width: 1,
                height: 1
            )
        )

        let image =
            try #require(
                context.makeImage()
            )
        let data =
            NSMutableData()
        let destination =
            try #require(
                CGImageDestinationCreateWithData(
                    data,
                    UTType.jpeg.identifier
                        as CFString,
                    1,
                    nil
                )
            )
        CGImageDestinationAddImage(
            destination,
            image,
            nil
        )
        #expect(
            CGImageDestinationFinalize(
                destination
            )
        )
        return data as Data
    }
}
