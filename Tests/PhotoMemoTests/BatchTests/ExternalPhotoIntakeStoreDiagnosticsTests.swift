import Foundation
import ImageIO
import UniformTypeIdentifiers
import Testing
@testable import PhotoMemo

@Suite("ExternalPhotoIntakeStore Diagnostics")
struct ExternalPhotoIntakeStoreDiagnosticsTests {

    @Test("Detailed drain preserves returned requests while surfacing clear-persistence failures")
    func detailedDrainSurfacesClearPersistenceFailures() throws {

        let suiteName =
            "PhotoMemo.ExternalPhotoIntakeStoreDiagnosticsTests.Drain.\(UUID().uuidString)"

        let defaults =
            try #require(
                UserDefaults(
                    suiteName: suiteName
                )
            )
        defaults.removePersistentDomain(
            forName: suiteName
        )

        let directoryURL =
            FileManager.default
            .temporaryDirectory
            .appendingPathComponent(
                suiteName,
                isDirectory: true
            )

        let store =
            ExternalPhotoIntakeStore(
                defaults: defaults,
                intakeDirectoryURL: directoryURL
            )

        let request =
            try #require(
                store.persistManagedRequest(
                    urls: [
                        directoryURL
                        .appendingPathComponent(
                            "managed.jpg"
                        )
                    ],
                    source: .shareExtension,
                    configurationSnapshot:
                        BatchConfigurationSnapshot(
                            template: .template1,
                            badge: nil,
                            anchor: nil,
                            shouldWritePhotoDescription: true,
                            photoDescriptionOverride: "",
                            selectedAlbumIdentifier: ""
                        )
                )
            )

        enum ExpectedFailure: Error {
            case encodeFailed
        }

        let drainResult =
            store.drainRequestsResult(
                encode: { _ in
                    throw ExpectedFailure.encodeFailed
                }
            )

        #expect(
            drainResult.requests
            == [request]
        )

        switch drainResult.clearPersistedRequestsResult {
        case .encodingFailed(let failure):
            #expect(
                failure.storageKey
                == "photomemo.externalIntake.requests"
            )
            #expect(
                failure.underlyingDescription
                .contains("encodeFailed")
            )
        case .success:
            Issue.record(
                "Expected .encodingFailed when clearing persisted requests cannot encode."
            )
        case nil:
            Issue.record(
                "Expected a clear-persistence result when draining stored requests."
            )
        }

        switch store.loadRequestsResult() {
        case .success(let requests):
            #expect(requests == [request])
        case .noValue,
             .decodingFailed:
            Issue.record(
                "Expected the original persisted request to remain when clear persistence fails."
            )
        }

        try? FileManager.default.removeItem(
            at: directoryURL
        )
        defaults.removePersistentDomain(
            forName: suiteName
        )
    }

    @Test("Distinguishes missing persisted intake requests from corrupted payloads")
    func distinguishesMissingPersistedRequestsFromCorruptedPayloads() throws {

        let suiteName =
            "PhotoMemo.ExternalPhotoIntakeStoreDiagnosticsTests.Persistence.\(UUID().uuidString)"

        let defaults =
            try #require(
                UserDefaults(
                    suiteName: suiteName
                )
            )
        defaults.removePersistentDomain(
            forName: suiteName
        )

        let directoryURL =
            FileManager.default
            .temporaryDirectory
            .appendingPathComponent(
                suiteName,
                isDirectory: true
            )

        let store =
            ExternalPhotoIntakeStore(
                defaults: defaults,
                intakeDirectoryURL: directoryURL
            )

        switch store.loadRequestsResult() {
        case .noValue:
            break
        case .success,
             .decodingFailed:
            Issue.record(
                "Expected .noValue for empty intake-request storage."
            )
        }

        defaults.set(
            Data("bad-intake".utf8),
            forKey:
                "photomemo.externalIntake.requests"
        )

        switch store.loadRequestsResult() {
        case .decodingFailed(let failure):
            #expect(
                failure.storageKey
                == "photomemo.externalIntake.requests"
            )
            #expect(
                failure.payloadByteCount
                == Data("bad-intake".utf8).count
            )
            #expect(
                !failure.underlyingDescription.isEmpty
            )
        case .noValue,
             .success:
            Issue.record(
                "Expected .decodingFailed for corrupted intake-request payload."
            )
        }

        try? FileManager.default.removeItem(
            at: directoryURL
        )
        defaults.removePersistentDomain(
            forName: suiteName
        )
    }

    @Test("Detailed managed copy reports copy-stage failure for non-file URLs")
    func reportsCopyStageFailureForNonFileURLs() {

        let suiteName =
            "PhotoMemo.ExternalPhotoIntakeStoreDiagnosticsTests.\(UUID().uuidString)"

        guard let defaults =
            UserDefaults(suiteName: suiteName) else {
            Issue.record("Unable to create isolated UserDefaults suite")
            return
        }

        defaults.removePersistentDomain(
            forName: suiteName
        )

        let directoryURL =
            FileManager.default
            .temporaryDirectory
            .appendingPathComponent(
                suiteName,
                isDirectory: true
            )

        let store =
            ExternalPhotoIntakeStore(
                defaults: defaults,
                intakeDirectoryURL: directoryURL
            )

        let seed =
            PhotoMemoShareIntakeOperationSeed(
                itemProviderCount: 3,
                supportedProviderCount: 2,
                providerIndex: 1,
                requestedTypeIdentifier: "public.image",
                preferredRegisteredTypeIdentifier: "public.heic"
            )

        let result =
            store.createManagedCopyDetailed(
                from: URL(string: "https://example.com/test.heic")!,
                requestID: UUID(),
                index: 0,
                diagnosticsSeed: seed
            )

        #expect(result.managedURL == nil)
        #expect(result.failureContext?.stage == .copy)
        #expect(result.failureContext?.itemProviderCount == 3)
        #expect(result.failureContext?.supportedProviderCount == 2)
        #expect(result.failureContext?.providerIndex == 1)
        #expect(result.failureContext?.requestedTypeIdentifier == "public.image")
        #expect(result.failureContext?.preferredRegisteredTypeIdentifier == "public.heic")
        #expect(result.failureContext?.errorSummary?.domain == "PhotoMemoShareIntake")

        try? FileManager.default.removeItem(
            at: directoryURL
        )
        defaults.removePersistentDomain(
            forName: suiteName
        )
    }

    @Test("Detailed managed copy succeeds for readable local files")
    func createsManagedCopyForReadableLocalFiles() throws {

        let suiteName =
            "PhotoMemo.ExternalPhotoIntakeStoreDiagnosticsTests.LocalFile.\(UUID().uuidString)"

        guard let defaults =
            UserDefaults(suiteName: suiteName) else {
            Issue.record("Unable to create isolated UserDefaults suite")
            return
        }

        defaults.removePersistentDomain(
            forName: suiteName
        )

        let rootDirectoryURL =
            FileManager.default
            .temporaryDirectory
            .appendingPathComponent(
                suiteName,
                isDirectory: true
            )

        let sourceURL =
            rootDirectoryURL
            .appendingPathComponent("source.heic")

        try FileManager.default.createDirectory(
            at: rootDirectoryURL,
            withIntermediateDirectories: true
        )
        try Self.writeSmallJPEG(
            to: sourceURL
        )

        let store =
            ExternalPhotoIntakeStore(
                defaults: defaults,
                intakeDirectoryURL: rootDirectoryURL
                    .appendingPathComponent(
                        "Intake",
                        isDirectory: true
                    )
            )

        let result =
            store.createManagedCopyDetailed(
                from: sourceURL,
                requestID: UUID(),
                index: 0
            )

        let managedURL =
            try #require(result.managedURL)

        #expect(result.failureContext == nil)
        #expect(
            FileManager.default.fileExists(
                atPath: managedURL.path
            )
        )
        #expect(CGImageSourceCreateWithURL(managedURL as CFURL, nil) != nil)
    }

    @Test("Detailed managed copy rejects files that exist but are not readable images")
    func rejectsFilesThatExistButAreNotReadableImages() throws {

        let suiteName =
            "PhotoMemo.ExternalPhotoIntakeStoreDiagnosticsTests.InvalidImage.\(UUID().uuidString)"

        guard let defaults =
            UserDefaults(suiteName: suiteName) else {
            Issue.record("Unable to create isolated UserDefaults suite")
            return
        }

        defaults.removePersistentDomain(
            forName: suiteName
        )

        let rootDirectoryURL =
            FileManager.default
            .temporaryDirectory
            .appendingPathComponent(
                suiteName,
                isDirectory: true
            )

        let sourceURL =
            rootDirectoryURL
            .appendingPathComponent("source.jpg")

        try FileManager.default.createDirectory(
            at: rootDirectoryURL,
            withIntermediateDirectories: true
        )
        try Data([1, 2, 3, 4]).write(
            to: sourceURL
        )

        let store =
            ExternalPhotoIntakeStore(
                defaults: defaults,
                intakeDirectoryURL: rootDirectoryURL
                    .appendingPathComponent(
                        "Intake",
                        isDirectory: true
                    )
            )

        let result =
            store.createManagedCopyDetailed(
                from: sourceURL,
                requestID: UUID(),
                index: 0
            )

        #expect(result.managedURL == nil)
        #expect(result.failureContext?.stage == .copy)
        #expect(
            result.failureContext?
                .temporaryCopyResult == "source-unreadable-before-copy"
        )

        try? FileManager.default.removeItem(
            at: rootDirectoryURL
        )
        defaults.removePersistentDomain(
            forName: suiteName
        )
    }

    @Test("Managed copy preserves the original file name and appends copy suffixes")
    func preservesOriginalManagedCopyFileNameAndCopySuffixes() throws {

        let suiteName =
            "PhotoMemo.ExternalPhotoIntakeStoreDiagnosticsTests.CopySuffix.\(UUID().uuidString)"

        guard let defaults =
            UserDefaults(suiteName: suiteName) else {
            Issue.record("Unable to create isolated UserDefaults suite")
            return
        }

        defaults.removePersistentDomain(
            forName: suiteName
        )

        let rootDirectoryURL =
            FileManager.default
            .temporaryDirectory
            .appendingPathComponent(
                suiteName,
                isDirectory: true
            )

        let sourceDirectoryURL =
            rootDirectoryURL
            .appendingPathComponent(
                "Source",
                isDirectory: true
            )

        try FileManager.default.createDirectory(
            at: sourceDirectoryURL,
            withIntermediateDirectories: true
        )

        let sourceURL =
            sourceDirectoryURL
            .appendingPathComponent(
                "IMG_7065.JPEG"
            )

        try Self.writeSmallJPEG(
            to: sourceURL
        )

        let store =
            ExternalPhotoIntakeStore(
                defaults: defaults,
                intakeDirectoryURL:
                    rootDirectoryURL
                    .appendingPathComponent(
                        "Intake",
                        isDirectory: true
                    )
            )

        let requestID = UUID()

        let firstResult =
            store.createManagedCopyDetailed(
                from: sourceURL,
                requestID: requestID,
                index: 0
            )

        let secondResult =
            store.createManagedCopyDetailed(
                fromData: try Self.smallJPEGData(),
                requestID: requestID,
                index: 1,
                preferredFileExtension:
                    "JPEG",
                preferredBaseName:
                    "IMG_7065"
            )

        let firstManagedURL =
            try #require(firstResult.managedURL)
        let secondManagedURL =
            try #require(secondResult.managedURL)

        #expect(
            firstManagedURL.lastPathComponent
            == "IMG_7065.JPEG"
        )
        #expect(
            secondManagedURL.lastPathComponent
            == "IMG_7065 (1).JPEG"
        )

        try? FileManager.default.removeItem(
            at: rootDirectoryURL
        )
        defaults.removePersistentDomain(
            forName: suiteName
        )
    }

    @Test("Managed copy prefers the original shared file name over a temporary provider file name")
    func prefersOriginalSharedFileNameOverTemporaryProviderFileName() throws {

        let suiteName =
            "PhotoMemo.ExternalPhotoIntakeStoreDiagnosticsTests.PreferredOriginalName.\(UUID().uuidString)"

        guard let defaults =
            UserDefaults(suiteName: suiteName) else {
            Issue.record("Unable to create isolated UserDefaults suite")
            return
        }

        defaults.removePersistentDomain(
            forName: suiteName
        )

        let rootDirectoryURL =
            FileManager.default
            .temporaryDirectory
            .appendingPathComponent(
                suiteName,
                isDirectory: true
            )

        let sourceDirectoryURL =
            rootDirectoryURL
            .appendingPathComponent(
                "Source",
                isDirectory: true
            )

        try FileManager.default.createDirectory(
            at: sourceDirectoryURL,
            withIntermediateDirectories: true
        )

        let sourceURL =
            sourceDirectoryURL
            .appendingPathComponent(
                "share-provider-temp-file"
            )

        try Self.writeSmallJPEG(
            to: sourceURL
        )

        let store =
            ExternalPhotoIntakeStore(
                defaults: defaults,
                intakeDirectoryURL:
                    rootDirectoryURL
                    .appendingPathComponent(
                        "Intake",
                        isDirectory: true
                    )
            )

        let result =
            store.createManagedCopyDetailed(
                from: sourceURL,
                requestID: UUID(),
                index: 0,
                preferredOriginalFileName:
                    "IMG_9558.HEIC"
            )

        let managedURL =
            try #require(result.managedURL)

        #expect(
            managedURL.lastPathComponent
            == "IMG_9558.HEIC"
        )

        try? FileManager.default.removeItem(
            at: rootDirectoryURL
        )
        defaults.removePersistentDomain(
            forName: suiteName
        )
    }

    @Test("Persisted intake requests retain structured item provenance")
    func persistedIntakeRequestsRetainStructuredItemProvenance() throws {

        let suiteName =
            "PhotoMemo.ExternalPhotoIntakeStoreDiagnosticsTests.PersistItems.\(UUID().uuidString)"

        guard let defaults =
            UserDefaults(suiteName: suiteName) else {
            Issue.record("Unable to create isolated UserDefaults suite")
            return
        }

        defaults.removePersistentDomain(
            forName: suiteName
        )

        let directoryURL =
            FileManager.default
            .temporaryDirectory
            .appendingPathComponent(
                suiteName,
                isDirectory: true
            )

        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )

        let managedURL =
            directoryURL
            .appendingPathComponent(
                "IMG_9558.HEIC"
            )

        try Self.smallJPEGData().write(
            to: managedURL
        )

        let store =
            ExternalPhotoIntakeStore(
                defaults: defaults,
                intakeDirectoryURL: directoryURL
            )

        let result =
            store.persistManagedRequestDetailed(
                urls: [managedURL],
                items: [
                    ExternalPhotoIntakeItem(
                        managedURL: managedURL,
                        originalFileName: "IMG_9558.HEIC",
                        sourceIdentifier: "asset-local-9558",
                        contentTypeIdentifier: "public.heic"
                    )
                ],
                source: .shareExtension,
                configurationSnapshot:
                    BatchConfigurationSnapshot(
                        template: .template1.normalizedForEditing,
                        badge: nil,
                        anchor: nil,
                        shouldWritePhotoDescription: false,
                        photoDescriptionOverride: "",
                        selectedAlbumIdentifier: ""
                    )
            )

        let request =
            try #require(result.request)
        let intakeItem =
            try #require(request.items?.first)
        let payload =
            try #require(request.intakePayloads.first)

        #expect(result.failureContext == nil)
        #expect(intakeItem.originalFileName == "IMG_9558.HEIC")
        #expect(intakeItem.sourceIdentifier == "asset-local-9558")
        #expect(intakeItem.contentTypeIdentifier == "public.heic")
        #expect(payload.fileName == "IMG_9558.HEIC")
        #expect(payload.sourceIdentifier == "asset-local-9558")
        #expect(payload.contentTypeIdentifier == "public.heic")

        try? FileManager.default.removeItem(
            at: directoryURL
        )
        defaults.removePersistentDomain(
            forName: suiteName
        )
    }
}

private extension ExternalPhotoIntakeStoreDiagnosticsTests {

    static func writeSmallJPEG(
        to url: URL
    ) throws {
        try smallJPEGData()
            .write(
                to: url
            )
    }

    static func smallJPEGData() throws -> Data {
        var pixels: [UInt8] = [
            255, 0, 0, 255,
            0, 255, 0, 255,
            0, 0, 255, 255,
            255, 255, 255, 255
        ]

        let context =
            try #require(
                CGContext(
                    data: &pixels,
                    width: 2,
                    height: 2,
                    bitsPerComponent: 8,
                    bytesPerRow: 8,
                    space:
                        CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo:
                        CGImageAlphaInfo
                        .premultipliedLast
                        .rawValue
                )
            )
        let image =
            try #require(
                context.makeImage()
            )
        let data = NSMutableData()
        let destination =
            try #require(
                CGImageDestinationCreateWithData(
                    data,
                    UTType.jpeg.identifier as CFString,
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
