import Foundation
import Testing
@testable import PhotoMemo

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
                        nil
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
