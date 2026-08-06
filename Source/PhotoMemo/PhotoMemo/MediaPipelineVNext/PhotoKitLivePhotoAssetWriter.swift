import Foundation
#if canImport(Photos)
import Photos
#endif

@MainActor
final class PhotoKitLivePhotoAssetWriter:
    LivePhotoAssetWriting {

    private let savePerformer:
        any LivePhotoAssetSavePerforming
    private let pairingIdentityVerifier:
        any LivePhotoPairingIdentityVerifying
    private let assetReadbackVerifier:
        any LivePhotoAssetReadbackVerifying
    private let readbackAttemptCount: Int
    private let readbackRetryDelayNanoseconds:
        UInt64
    private let fileManager: FileManager
    private let runtimeGate:
        MediaPipelineRuntimeGate

    init(
        savePerformer:
            (any LivePhotoAssetSavePerforming)? = nil,
        pairingIdentityVerifier:
            (any LivePhotoPairingIdentityVerifying)? = nil,
        assetReadbackVerifier:
            (any LivePhotoAssetReadbackVerifying)? = nil,
        receiptStore:
            PhotoLibrarySaveReceiptStore =
                PhotoLibrarySaveReceiptStore(),
        readbackAttemptCount: Int = 8,
        readbackRetryDelayNanoseconds:
            UInt64 = 250_000_000,
        fileManager: FileManager = .default,
        runtimeGate:
            MediaPipelineRuntimeGate = .defaultOff
    ) {
        self.savePerformer =
            savePerformer
            ?? PhotoKitLivePhotoAssetSavePerformer(
                receiptStore: receiptStore
            )
        self.pairingIdentityVerifier =
            pairingIdentityVerifier
            ?? LivePhotoPairingIdentityVerifier()
        self.assetReadbackVerifier =
            assetReadbackVerifier
            ?? PhotoKitLivePhotoAssetReadbackVerifier()
        self.readbackAttemptCount =
            max(readbackAttemptCount, 1)
        self.readbackRetryDelayNanoseconds =
            readbackRetryDelayNanoseconds
        self.fileManager = fileManager
        self.runtimeGate =
            runtimeGate
    }

    func saveAsset(
        _ request: LivePhotoSaveRequest
    ) async throws -> PhotoLibrarySaveResult {

        guard fileManager.fileExists(
            atPath: request.stillPhotoFileURL.path
        ) else {
            throw LivePhotoAssetWritingError
                .stillPhotoFileMissing
        }

        guard fileManager.fileExists(
            atPath: request.pairedVideoFileURL.path
        ) else {
            throw LivePhotoAssetWritingError
                .pairedVideoFileMissing
        }

        let stillPhotoOriginalFilename =
            resolvedOriginalFilename(
                preferred:
                    request.stillPhotoOriginalFilename,
                fallbackURL:
                    request.stillPhotoFileURL,
                defaultName:
                    "MemoMark.heic"
            )
        let pairedVideoOriginalFilename =
            resolvedOriginalFilename(
                preferred:
                    request.pairedVideoOriginalFilename,
                fallbackURL:
                    request.pairedVideoFileURL,
                defaultName:
                    "MemoMark.mov"
            )
        guard outputBaseName(
            stillPhotoOriginalFilename
        ) == outputBaseName(
            pairedVideoOriginalFilename
        ) else {
            throw LivePhotoAssetWritingError
                .outputFilenameBaseMismatch
        }

        do {
            _ = try await pairingIdentityVerifier
                .verifyPair(
                    stillPhotoURL:
                        request.stillPhotoFileURL,
                    pairedVideoURL:
                        request.pairedVideoFileURL
                )
        } catch let error as LivePhotoPairingIdentityVerificationError {
            throw LivePhotoAssetWritingError
                .pairingIdentityVerificationFailed(
                    error
                )
        }

        guard runtimeGate.permitsPhotoLibraryWrites else {
            throw LivePhotoAssetWritingError
                .photoLibraryWritesDisabledByRuntimeGate
        }

        try Task.checkCancellation()

        let saveResult = try await savePerformer
            .save(
                operation:
                    LivePhotoAssetWriteOperation(
                        creationDate:
                            request.captureDate,
                        preferredAlbumIdentifier:
                            request.preferredAlbumIdentifier,
                        resources: [
                            LivePhotoAssetResourceWriteRequest(
                                kind: .photo,
                                fileURL:
                                    request
                                    .stillPhotoFileURL,
                                originalFilename:
                                    stillPhotoOriginalFilename
                            ),
                            LivePhotoAssetResourceWriteRequest(
                                kind: .pairedVideo,
                                fileURL:
                                    request
                                    .pairedVideoFileURL,
                                originalFilename:
                                    pairedVideoOriginalFilename
                            )
                        ],
                        idempotencyKey:
                            request.idempotencyKey
                    )
            )

        try await verifySavedLivePhoto(
            saveResult
        )
        return saveResult
    }
}

private extension PhotoKitLivePhotoAssetWriter {

    func verifySavedLivePhoto(
        _ saveResult: PhotoLibrarySaveResult
    ) async throws {

        var didReadInvalidAsset = false

        for attempt in 0..<readbackAttemptCount {
            try Task.checkCancellation()
            do {
                let report =
                    try assetReadbackVerifier
                    .verifyAsset(
                        localIdentifier:
                            saveResult
                            .assetLocalIdentifier
                    )
                if report
                    .satisfiesLivePhotoPairingContract {
                    PhotoMemoShareDiagnostics.record(
                        stage: .livePhotoAssetReadback,
                        message:
                            "result=verified, attempt=\(attempt + 1), livePhoto=true, stillResource=true, pairedVideoResource=true, positiveDuration=true, positivePixelSize=true"
                    )
                    return
                }
                didReadInvalidAsset = true
                PhotoMemoShareDiagnostics.record(
                    stage: .livePhotoAssetReadback,
                    message:
                        "result=invalid, attempt=\(attempt + 1), livePhoto=\(report.isLivePhoto), stillResource=\(report.hasStillPhotoResource), pairedVideoResource=\(report.hasPairedVideoResource), positiveDuration=\(report.duration > 0), positivePixelSize=\(report.pixelWidth > 0 && report.pixelHeight > 0)"
                )
            } catch {
                if Task.isCancelled {
                    throw CancellationError()
                }
                let systemError = error as NSError
                PhotoMemoShareDiagnostics.record(
                    stage: .livePhotoAssetReadback,
                    message:
                        "result=unavailable, attempt=\(attempt + 1), errorDomain=\(systemError.domain), errorCode=\(systemError.code)"
                )
            }

            if attempt < readbackAttemptCount - 1,
               readbackRetryDelayNanoseconds > 0 {
                try await Task.sleep(
                    nanoseconds:
                        readbackRetryDelayNanoseconds
                )
            }
        }

        PhotoMemoShareDiagnostics.record(
            stage: .livePhotoAssetReadback,
            message:
                "result=failed, attempts=\(readbackAttemptCount), reason=\(didReadInvalidAsset ? "invalidLivePhotoContract" : "assetUnavailable")"
        )
        throw didReadInvalidAsset
            ? LivePhotoAssetWritingError
                .savedAssetNotLivePhoto
            : LivePhotoAssetWritingError
                .savedAssetReadbackFailed
    }

    func resolvedOriginalFilename(
        preferred: String?,
        fallbackURL: URL,
        defaultName: String
    ) -> String {

        if let resolved =
            PhotoFileNameResolver
            .sanitizedOriginalFileName(
                preferred
            ) {
            return resolved
        }

        let fallbackName =
            fallbackURL.lastPathComponent
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        if !fallbackName.isEmpty {
            return fallbackName
        }

        return defaultName
    }

    func outputBaseName(
        _ fileName: String
    ) -> String {
        URL(fileURLWithPath: fileName)
            .deletingPathExtension()
            .lastPathComponent
            .lowercased()
    }
}

#if canImport(Photos)
@MainActor
private final class PhotoKitLivePhotoAssetSavePerformer:
    LivePhotoAssetSavePerforming {

    private let defaultAlbumTitle =
        PhotoMemoAlbumSelection
        .defaultAlbumTitle
    private let receiptStore:
        PhotoLibrarySaveReceiptStore
    private let receiptReconciliationPolicy =
        PhotoLibrarySaveReceiptReconciliationPolicy()

    init(
        receiptStore:
            PhotoLibrarySaveReceiptStore
    ) {
        self.receiptStore = receiptStore
    }

    func save(
        operation: LivePhotoAssetWriteOperation
    ) async throws -> PhotoLibrarySaveResult {

        let status =
            await requestAuthorizationIfNeeded()

        guard isAuthorized(status) else {
            throw LivePhotoAssetWritingError
                .unauthorized
        }

        return try await PhotoLibrarySaveGate.shared.run { [self] in
            let album =
                try await resolvedAlbum(
                    operation
                    .preferredAlbumIdentifier
                )

            if let idempotencyKey = operation.idempotencyKey,
               let existingAsset = try existingAsset(
                   for: idempotencyKey
               ) {
                return PhotoLibrarySaveResult(
                    albumTitle: album?.localizedTitle ?? "",
                    assetLocalIdentifier: existingAsset.localIdentifier
                )
            }

            try Task.checkCancellation()

            var placeholderIdentifier: String?

            try await performChanges {
                let assetRequest =
                    PHAssetCreationRequest.forAsset()

                assetRequest.creationDate =
                    operation.creationDate

                for resource in operation.resources {
                    let options =
                        PHAssetResourceCreationOptions()
                    options.shouldMoveFile = false
                    options.originalFilename =
                        resource.originalFilename

                    assetRequest.addResource(
                        with:
                            resource.kind
                            .photoKitResourceType,
                        fileURL:
                            resource.fileURL,
                        options: options
                    )
                }

                guard let placeholder =
                    assetRequest.placeholderForCreatedAsset
                else {
                    return
                }

                placeholderIdentifier =
                    placeholder.localIdentifier

                if let idempotencyKey =
                    operation.idempotencyKey {
                    self.receiptStore.record(
                        assetIdentifier:
                            placeholder.localIdentifier,
                        for: idempotencyKey
                    )
                }

                if let album,
                   let albumChangeRequest =
                    PHAssetCollectionChangeRequest(
                        for: album
                    ) {
                    albumChangeRequest.addAssets(
                        [placeholder] as NSArray
                    )
                }
            }

            guard let placeholderIdentifier else {
                throw LivePhotoAssetWritingError
                    .assetSaveFailed
            }

            return PhotoLibrarySaveResult(
                albumTitle:
                    album?.localizedTitle
                    ?? "",
                assetLocalIdentifier:
                    placeholderIdentifier
            )
        }
    }
}

private extension PhotoKitLivePhotoAssetSavePerformer {

    func existingAsset(
        for idempotencyKey: String
    ) throws -> PHAsset? {
        guard let assetIdentifier =
                receiptStore.assetIdentifier(
                    for: idempotencyKey
                ) else {
            return nil
        }

        let asset =
            PHAsset.fetchAssets(
                withLocalIdentifiers: [
                    assetIdentifier
                ],
                options: nil
            )
            .firstObject

        switch receiptReconciliationPolicy
            .decision(
                assetExists: asset != nil,
                recordedAt:
                    receiptStore.recordedAt(
                        for: idempotencyKey
                    )
            ) {
        case .reuseAsset:
            return asset

        case .awaitVisibility:
            throw LivePhotoAssetWritingError
                .savedAssetReadbackPending
        }
    }

    func isAuthorized(
        _ status: PHAuthorizationStatus
    ) -> Bool {

        status == .authorized
            || status == .limited
    }

    func requestAuthorizationIfNeeded() async -> PHAuthorizationStatus {

        let currentStatus =
            PHPhotoLibrary.authorizationStatus(
                for: .readWrite
            )

        if currentStatus != .notDetermined {
            return currentStatus
        }

        return await withCheckedContinuation {
            continuation in
            PHPhotoLibrary.requestAuthorization(
                for: .readWrite
            ) { status in
                continuation.resume(
                    returning: status
                )
            }
        }
    }

    func resolvedAlbum(
        _ localIdentifier: String?
    ) async throws -> PHAssetCollection? {

        let normalizedIdentifier =
            PhotoMemoAlbumSelection
            .normalizedIdentifier(
                localIdentifier ?? ""
            )

        if normalizedIdentifier
            == PhotoMemoAlbumSelection
            .systemLibraryIdentifier {
            return nil
        }

        if !normalizedIdentifier.isEmpty {
            guard
                let existingAlbum =
                    fetchAlbum(
                        with: normalizedIdentifier
                    )
            else {
                throw LivePhotoAssetWritingError
                    .albumNotFound
            }

            return existingAlbum
        }

        if let existingDefaultAlbum =
            fetchAlbum(
                withTitle: defaultAlbumTitle
            ) {
            return existingDefaultAlbum
        }

        return try await createAlbum(
            named: defaultAlbumTitle
        )
    }

    func fetchAlbum(
        with localIdentifier: String
    ) -> PHAssetCollection? {

        PHAssetCollection
            .fetchAssetCollections(
                withLocalIdentifiers: [
                    localIdentifier
                ],
                options: nil
            )
            .firstObject
    }

    func fetchAlbum(
        withTitle title: String
    ) -> PHAssetCollection? {

        let fetchResult =
            PHAssetCollection.fetchAssetCollections(
                with: .album,
                subtype: .any,
                options: nil
            )

        var matchedAlbum: PHAssetCollection?

        fetchResult.enumerateObjects {
            collection,
            _,
            stop in
            guard
                collection.localizedTitle == title
            else {
                return
            }

            matchedAlbum = collection
            stop.pointee = true
        }

        return matchedAlbum
    }

    func createAlbum(
        named title: String
    ) async throws -> PHAssetCollection {

        var createdIdentifier: String?

        try await performChanges {
            let request =
                PHAssetCollectionChangeRequest
                .creationRequestForAssetCollection(
                    withTitle: title
                )

            createdIdentifier =
                request
                .placeholderForCreatedAssetCollection
                .localIdentifier
        }

        guard
            let createdIdentifier,
            let createdAlbum =
                fetchAlbum(
                    with: createdIdentifier
                )
        else {
            throw LivePhotoAssetWritingError
                .albumCreateFailed
        }

        return createdAlbum
    }

    func performChanges(
        _ changes: @escaping () -> Void
    ) async throws {

        try await withCheckedThrowingContinuation {
            (
                continuation:
                    CheckedContinuation<Void, Error>
            ) in
            PHPhotoLibrary.shared().performChanges(
                changes
            ) { success, error in
                if let error {
                    continuation.resume(
                        throwing: error
                    )
                    return
                }

                guard success else {
                    continuation.resume(
                        throwing:
                            LivePhotoAssetWritingError
                            .assetSaveFailed
                    )
                    return
                }

                continuation.resume()
            }
        }
    }
}

private extension LivePhotoWritableResourceKind {

    var photoKitResourceType:
        PHAssetResourceType {

        switch self {
        case .photo:
            return .photo
        case .pairedVideo:
            return .pairedVideo
        }
    }
}
#endif
