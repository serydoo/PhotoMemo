import Foundation
import Testing
@testable import MemoMark

@MainActor
@Suite("Live Photo asset writer contract")
struct LivePhotoAssetWriterContractTests {

    @Test("Builds a save operation that includes both photo and paired-video resources")
    func buildsSaveOperationWithPhotoAndPairedVideoResources() async throws {
        let savePerformer =
            StubLivePhotoAssetSavePerformer()
        let writer = PhotoKitLivePhotoAssetWriter(
            savePerformer: savePerformer,
            pairingIdentityVerifier:
                StubLivePhotoPairingIdentityVerifier(
                    outcome: .success
                ),
            assetReadbackVerifier:
                SequenceLivePhotoAssetReadbackVerifier(
                    outcomes: [
                        .success(.validLivePhoto)
                    ]
                ),
            runtimeGate:
                .internalTesting(
                    allowedRoutes: [.livePhoto],
                    permitsPhotoLibraryWrites: true
                )
        )
        let temporaryFolder =
            FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "LivePhotoAssetWriterContractTests-\(UUID().uuidString)",
                isDirectory: true
            )
        try FileManager.default.createDirectory(
            at: temporaryFolder,
            withIntermediateDirectories: true
        )
        defer {
            try? FileManager.default.removeItem(
                at: temporaryFolder
            )
        }

        let stillPhotoURL =
            temporaryFolder.appendingPathComponent(
                "LIVE.HEIC"
            )
        let pairedVideoURL =
            temporaryFolder.appendingPathComponent(
                "LIVE.MOV"
            )
        try Data("still".utf8).write(
            to: stillPhotoURL,
            options: .atomic
        )
        try Data("video".utf8).write(
            to: pairedVideoURL,
            options: .atomic
        )

        let captureDate =
            Date(timeIntervalSince1970: 1_725_000_000)
        let result =
            try await writer.saveAsset(
                LivePhotoSaveRequest(
                    stillPhotoFileURL:
                        stillPhotoURL,
                    pairedVideoFileURL:
                        pairedVideoURL,
                    captureDate: captureDate,
                    preferredAlbumIdentifier:
                        "album-1",
                    stillPhotoOriginalFilename:
                        nil,
                    pairedVideoOriginalFilename:
                        nil,
                    idempotencyKey:
                        "task-123"
                )
            )

        #expect(
            result.assetLocalIdentifier
            == "live-photo-1"
        )
        #expect(
            result.albumTitle
            == "photomemo"
        )

        let operation =
            try #require(
                savePerformer.savedOperations.first
            )
        #expect(
            operation.creationDate
            == captureDate
        )
        #expect(
            operation.preferredAlbumIdentifier
            == "album-1"
        )
        #expect(
            operation.resources.map(\.kind)
            == [
                .photo,
                .pairedVideo
            ]
        )
        #expect(
            operation.resources.map(\.originalFilename)
            == [
                "LIVE.HEIC",
                "LIVE.MOV"
            ]
        )
    }

    @Test("Rejects save requests before PhotoKit when runtime gate disables library writes")
    func rejectsSaveRequestsWhenRuntimeGateDisablesLibraryWrites() async throws {
        let savePerformer =
            StubLivePhotoAssetSavePerformer()
        let writer = PhotoKitLivePhotoAssetWriter(
            savePerformer: savePerformer,
            pairingIdentityVerifier:
                StubLivePhotoPairingIdentityVerifier(
                    outcome: .success
                )
        )
        let temporaryFolder =
            FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "LivePhotoAssetWriterContractTests-\(UUID().uuidString)",
                isDirectory: true
            )
        try FileManager.default.createDirectory(
            at: temporaryFolder,
            withIntermediateDirectories: true
        )
        defer {
            try? FileManager.default.removeItem(
                at: temporaryFolder
            )
        }

        let stillPhotoURL =
            temporaryFolder.appendingPathComponent(
                "LIVE.HEIC"
            )
        let pairedVideoURL =
            temporaryFolder.appendingPathComponent(
                "LIVE.MOV"
            )
        try Data("still".utf8).write(
            to: stillPhotoURL,
            options: .atomic
        )
        try Data("video".utf8).write(
            to: pairedVideoURL,
            options: .atomic
        )

        do {
            _ = try await writer.saveAsset(
                LivePhotoSaveRequest(
                    stillPhotoFileURL:
                        stillPhotoURL,
                    pairedVideoFileURL:
                        pairedVideoURL,
                    captureDate: nil,
                    preferredAlbumIdentifier:
                        nil,
                    stillPhotoOriginalFilename:
                        nil,
                    pairedVideoOriginalFilename:
                        nil
                )
            )
            Issue.record(
                "Expected runtime gate to reject Photo Library writes"
            )
        } catch let error as LivePhotoAssetWritingError {
            #expect(
                error == .photoLibraryWritesDisabledByRuntimeGate
            )
        } catch {
            Issue.record(
                "Received unexpected error: \(error)"
            )
        }

        #expect(
            savePerformer.savedOperations
                .isEmpty
        )
    }

    @Test("Rejects a save request when the paired video file is missing")
    func rejectsSaveRequestsMissingPairedVideoFile() async throws {
        let savePerformer =
            StubLivePhotoAssetSavePerformer()
        let writer = PhotoKitLivePhotoAssetWriter(
            savePerformer: savePerformer,
            pairingIdentityVerifier:
                StubLivePhotoPairingIdentityVerifier(
                    outcome: .success
                )
        )
        let temporaryFolder =
            FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "LivePhotoAssetWriterContractTests-\(UUID().uuidString)",
                isDirectory: true
            )
        try FileManager.default.createDirectory(
            at: temporaryFolder,
            withIntermediateDirectories: true
        )
        defer {
            try? FileManager.default.removeItem(
                at: temporaryFolder
            )
        }

        let stillPhotoURL =
            temporaryFolder.appendingPathComponent(
                "LIVE.HEIC"
            )
        let missingPairedVideoURL =
            temporaryFolder.appendingPathComponent(
                "MISSING.MOV"
            )
        try Data("still".utf8).write(
            to: stillPhotoURL,
            options: .atomic
        )

        do {
            _ = try await writer.saveAsset(
                LivePhotoSaveRequest(
                    stillPhotoFileURL:
                        stillPhotoURL,
                    pairedVideoFileURL:
                        missingPairedVideoURL,
                    captureDate: nil,
                    preferredAlbumIdentifier:
                        nil,
                    stillPhotoOriginalFilename:
                        nil,
                    pairedVideoOriginalFilename:
                        nil
                )
            )
            Issue.record(
                "Expected missing paired video file to be rejected"
            )
        } catch let error as LivePhotoAssetWritingError {
            #expect(
                error == .pairedVideoFileMissing
            )
        } catch {
            Issue.record(
                "Received unexpected error: \(error)"
            )
        }

        #expect(
            savePerformer.savedOperations
            .isEmpty
        )
    }

    @Test("Rejects still and paired-video filenames with different bases")
    func rejectsMismatchedOutputFilenameBases() async throws {
        let savePerformer =
            StubLivePhotoAssetSavePerformer()
        let writer = PhotoKitLivePhotoAssetWriter(
            savePerformer: savePerformer,
            pairingIdentityVerifier:
                StubLivePhotoPairingIdentityVerifier(
                    outcome: .success
                ),
            runtimeGate:
                .internalTesting(
                    allowedRoutes: [.livePhoto],
                    permitsPhotoLibraryWrites: true
                )
        )
        let temporaryFolder =
            FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "LivePhotoAssetWriterContractTests-\(UUID().uuidString)",
                isDirectory: true
            )
        try FileManager.default.createDirectory(
            at: temporaryFolder,
            withIntermediateDirectories: true
        )
        defer {
            try? FileManager.default.removeItem(at: temporaryFolder)
        }

        let stillPhotoURL =
            temporaryFolder.appendingPathComponent("LIVE.HEIC")
        let pairedVideoURL =
            temporaryFolder.appendingPathComponent("LIVE.MOV")
        try Data("still".utf8).write(to: stillPhotoURL)
        try Data("video".utf8).write(to: pairedVideoURL)

        do {
            _ = try await writer.saveAsset(
                LivePhotoSaveRequest(
                    stillPhotoFileURL: stillPhotoURL,
                    pairedVideoFileURL: pairedVideoURL,
                    captureDate: nil,
                    preferredAlbumIdentifier: nil,
                    stillPhotoOriginalFilename: "IMG_1164(1).heic",
                    pairedVideoOriginalFilename: "FullSizeRender.mov"
                )
            )
            Issue.record("Expected mismatched filename bases to fail")
        } catch let error as LivePhotoAssetWritingError {
            #expect(error == .outputFilenameBaseMismatch)
        }

        #expect(savePerformer.savedOperations.isEmpty)
    }

    @Test("Rejects a save request before PhotoKit when pairing identifiers fail verification")
    func rejectsSaveRequestWhenPairingIdentityVerificationFails() async throws {
        let savePerformer =
            StubLivePhotoAssetSavePerformer()
        let verifierError =
            LivePhotoPairingIdentityVerificationError
            .contentIdentifierMismatch(
                still: "still-id",
                pairedVideo: "video-id"
            )
        let writer =
            PhotoKitLivePhotoAssetWriter(
                savePerformer:
                    savePerformer,
                pairingIdentityVerifier:
                    StubLivePhotoPairingIdentityVerifier(
                        outcome: .failure(
                            verifierError
                        )
                    ),
                runtimeGate:
                    .internalTesting(
                        allowedRoutes: [.livePhoto],
                        permitsPhotoLibraryWrites: true
                    )
            )
        let temporaryFolder =
            FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "LivePhotoAssetWriterContractTests-\(UUID().uuidString)",
                isDirectory: true
            )
        try FileManager.default.createDirectory(
            at: temporaryFolder,
            withIntermediateDirectories: true
        )
        defer {
            try? FileManager.default.removeItem(
                at: temporaryFolder
            )
        }

        let stillPhotoURL =
            temporaryFolder.appendingPathComponent(
                "LIVE.HEIC"
            )
        let pairedVideoURL =
            temporaryFolder.appendingPathComponent(
                "LIVE.MOV"
            )
        try Data("still".utf8).write(
            to: stillPhotoURL,
            options: .atomic
        )
        try Data("video".utf8).write(
            to: pairedVideoURL,
            options: .atomic
        )

        do {
            _ = try await writer.saveAsset(
                LivePhotoSaveRequest(
                    stillPhotoFileURL:
                        stillPhotoURL,
                    pairedVideoFileURL:
                        pairedVideoURL,
                    captureDate: nil,
                    preferredAlbumIdentifier:
                        nil,
                    stillPhotoOriginalFilename:
                        nil,
                    pairedVideoOriginalFilename:
                        nil
                )
            )
            Issue.record(
                "Expected pairing identity verification to reject the save request"
            )
        } catch let error as LivePhotoAssetWritingError {
            #expect(
                error
                    == .pairingIdentityVerificationFailed(
                        verifierError
                    )
            )
        } catch {
            Issue.record(
                "Received unexpected error: \(error)"
            )
        }

        #expect(
            savePerformer.savedOperations
                .isEmpty
        )
    }

    @Test("Rejects a saved asset that Photos exposes as static and retains its idempotency receipt")
    func rejectsStaticPhotoKitReadbackAndRetainsReceipt() async throws {
        let suiteName =
            "MemoMark.LivePhotoAssetWriterContractTests.\(UUID().uuidString)"
        let defaults =
            try #require(
                UserDefaults(suiteName: suiteName)
            )
        defer {
            defaults.removePersistentDomain(
                forName: suiteName
            )
        }
        let receiptStore =
            PhotoLibrarySaveReceiptStore(
                defaults: defaults
            )
        receiptStore.record(
            assetIdentifier: "live-photo-1",
            for: "task-static-readback"
        )
        let readbackVerifier =
            SequenceLivePhotoAssetReadbackVerifier(
                outcomes: [
                    .success(.staticAsset),
                    .success(.staticAsset)
                ]
            )
        let writer =
            PhotoKitLivePhotoAssetWriter(
                savePerformer:
                    StubLivePhotoAssetSavePerformer(),
                pairingIdentityVerifier:
                    StubLivePhotoPairingIdentityVerifier(
                        outcome: .success
                    ),
                assetReadbackVerifier:
                    readbackVerifier,
                receiptStore:
                    receiptStore,
                readbackAttemptCount: 2,
                readbackRetryDelayNanoseconds: 0,
                runtimeGate:
                    .internalTesting(
                        allowedRoutes: [.livePhoto],
                        permitsPhotoLibraryWrites: true
                    )
            )
        let pair = try makeTemporaryPair()
        defer {
            try? FileManager.default.removeItem(
                at: pair.folderURL
            )
        }

        do {
            _ = try await writer.saveAsset(
                makeSaveRequest(
                    pair: pair,
                    idempotencyKey:
                        "task-static-readback"
                )
            )
            Issue.record(
                "Expected static PhotoKit readback to fail"
            )
        } catch let error as LivePhotoAssetWritingError {
            #expect(
                error == .savedAssetNotLivePhoto
            )
        }

        #expect(readbackVerifier.callCount == 2)
        #expect(
            receiptStore.assetIdentifier(
                for: "task-static-readback"
            ) == "live-photo-1"
        )
    }

    @Test("Retries PhotoKit readback while the new Live Photo is being indexed")
    func retriesPhotoKitReadbackUntilLivePhotoAppears() async throws {
        let readbackVerifier =
            SequenceLivePhotoAssetReadbackVerifier(
                outcomes: [
                    .failure(.assetNotFound),
                    .success(.validLivePhoto)
                ]
            )
        let writer =
            PhotoKitLivePhotoAssetWriter(
                savePerformer:
                    StubLivePhotoAssetSavePerformer(),
                pairingIdentityVerifier:
                    StubLivePhotoPairingIdentityVerifier(
                        outcome: .success
                    ),
                assetReadbackVerifier:
                    readbackVerifier,
                readbackAttemptCount: 2,
                readbackRetryDelayNanoseconds: 0,
                runtimeGate:
                    .internalTesting(
                        allowedRoutes: [.livePhoto],
                        permitsPhotoLibraryWrites: true
                    )
            )
        let pair = try makeTemporaryPair()
        defer {
            try? FileManager.default.removeItem(
                at: pair.folderURL
            )
        }

        let result =
            try await writer.saveAsset(
                makeSaveRequest(
                    pair: pair,
                    idempotencyKey:
                        "task-indexing-delay"
                )
            )

        #expect(
            result.assetLocalIdentifier
            == "live-photo-1"
        )
        #expect(readbackVerifier.callCount == 2)
    }
}

private extension LivePhotoAssetWriterContractTests {

    struct TemporaryPair {
        let folderURL: URL
        let stillPhotoURL: URL
        let pairedVideoURL: URL
    }

    func makeTemporaryPair() throws -> TemporaryPair {
        let folderURL =
            FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "LivePhotoAssetWriterReadbackTests-\(UUID().uuidString)",
                isDirectory: true
            )
        try FileManager.default.createDirectory(
            at: folderURL,
            withIntermediateDirectories: true
        )
        let stillPhotoURL =
            folderURL.appendingPathComponent("LIVE.HEIC")
        let pairedVideoURL =
            folderURL.appendingPathComponent("LIVE.MOV")
        try Data("still".utf8).write(to: stillPhotoURL)
        try Data("video".utf8).write(to: pairedVideoURL)
        return TemporaryPair(
            folderURL: folderURL,
            stillPhotoURL: stillPhotoURL,
            pairedVideoURL: pairedVideoURL
        )
    }

    func makeSaveRequest(
        pair: TemporaryPair,
        idempotencyKey: String
    ) -> LivePhotoSaveRequest {
        LivePhotoSaveRequest(
            stillPhotoFileURL: pair.stillPhotoURL,
            pairedVideoFileURL: pair.pairedVideoURL,
            captureDate: nil,
            preferredAlbumIdentifier: nil,
            stillPhotoOriginalFilename: "LIVE.HEIC",
            pairedVideoOriginalFilename: "LIVE.MOV",
            idempotencyKey: idempotencyKey
        )
    }
}

@MainActor
private final class StubLivePhotoAssetSavePerformer:
    LivePhotoAssetSavePerforming {

    private(set) var savedOperations:
        [LivePhotoAssetWriteOperation] = []

    func save(
        operation: LivePhotoAssetWriteOperation
    ) async throws -> PhotoLibrarySaveResult {

        savedOperations.append(operation)

        return PhotoLibrarySaveResult(
            albumTitle: "photomemo",
            assetLocalIdentifier: "live-photo-1"
        )
    }
}

private struct StubLivePhotoPairingIdentityVerifier:
    LivePhotoPairingIdentityVerifying {

    enum Outcome:
        Sendable {
        case success
        case failure(
            LivePhotoPairingIdentityVerificationError
        )
    }

    let outcome: Outcome

    func verifyPair(
        stillPhotoURL: URL,
        pairedVideoURL: URL
    ) async throws -> LivePhotoPairingIdentityReport {

        switch outcome {
        case .success:
            return LivePhotoPairingIdentityReport(
                stillContentIdentifier:
                    "pair-id",
                pairedVideoContentIdentifier:
                    "pair-id"
            )
        case .failure(let error):
            throw error
        }
    }
}

@MainActor
private final class SequenceLivePhotoAssetReadbackVerifier:
    LivePhotoAssetReadbackVerifying {

    enum Outcome {
        case success(LivePhotoAssetReadbackReport)
        case failure(LivePhotoAssetReadbackVerificationError)
    }

    private var outcomes: [Outcome]
    private(set) var callCount = 0

    init(outcomes: [Outcome]) {
        self.outcomes = outcomes
    }

    func verifyAsset(
        localIdentifier: String
    ) throws -> LivePhotoAssetReadbackReport {
        callCount += 1
        guard !outcomes.isEmpty else {
            throw LivePhotoAssetReadbackVerificationError
                .assetNotFound
        }
        switch outcomes.removeFirst() {
        case .success(let report):
            return report
        case .failure(let error):
            throw error
        }
    }
}

private extension LivePhotoAssetReadbackReport {

    static let staticAsset =
        LivePhotoAssetReadbackReport(
            localIdentifier: "live-photo-1",
            pixelWidth: 4032,
            pixelHeight: 3024,
            duration: 0,
            isImageAsset: true,
            isLivePhoto: false,
            resources: [
                LivePhotoAssetReadbackResource(
                    kind: .photo,
                    originalFilename: "LIVE.HEIC",
                    uniformTypeIdentifier: "public.heic"
                )
            ]
        )

    static let validLivePhoto =
        LivePhotoAssetReadbackReport(
            localIdentifier: "live-photo-1",
            pixelWidth: 4032,
            pixelHeight: 3024,
            duration: 2.7,
            isImageAsset: true,
            isLivePhoto: true,
            resources: [
                LivePhotoAssetReadbackResource(
                    kind: .photo,
                    originalFilename: "LIVE.HEIC",
                    uniformTypeIdentifier: "public.heic"
                ),
                LivePhotoAssetReadbackResource(
                    kind: .pairedVideo,
                    originalFilename: "LIVE.MOV",
                    uniformTypeIdentifier:
                        "com.apple.quicktime-movie"
                )
            ]
        )
}
