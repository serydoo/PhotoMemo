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
    private let fileManager: FileManager
    private let runtimeGate:
        MediaPipelineRuntimeGate

    init(
        savePerformer:
            (any LivePhotoAssetSavePerforming)? = nil,
        pairingIdentityVerifier:
            (any LivePhotoPairingIdentityVerifying)? = nil,
        fileManager: FileManager = .default,
        runtimeGate:
            MediaPipelineRuntimeGate = .defaultOff
    ) {
        self.savePerformer =
            savePerformer
            ?? PhotoKitLivePhotoAssetSavePerformer()
        self.pairingIdentityVerifier =
            pairingIdentityVerifier
            ?? LivePhotoPairingIdentityVerifier()
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
        let resolvedResourceFilenames =
            idempotentResourceFilenames(
                idempotencyKey:
                    request.idempotencyKey,
                stillFilename:
                    stillPhotoOriginalFilename,
                pairedVideoFilename:
                    pairedVideoOriginalFilename
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

        return try await savePerformer
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
                                    resolvedResourceFilenames.still
                            ),
                            LivePhotoAssetResourceWriteRequest(
                                kind: .pairedVideo,
                                fileURL:
                                    request
                                    .pairedVideoFileURL,
                                originalFilename:
                                    resolvedResourceFilenames.pairedVideo
                            )
                        ],
                        idempotencyKey:
                            request.idempotencyKey
                    )
            )
    }
}

private extension PhotoKitLivePhotoAssetWriter {

    func idempotentResourceFilenames(
        idempotencyKey: String?,
        stillFilename: String,
        pairedVideoFilename: String
    ) -> (still: String, pairedVideo: String) {

        guard let key = idempotencyKey?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !key.isEmpty else {
            return (stillFilename, pairedVideoFilename)
        }

        let baseName =
            "MemoMarkTask-\(key.replacingOccurrences(of: "/", with: "-"))"
        let stillExtension =
            URL(fileURLWithPath: stillFilename).pathExtension
        let pairedVideoExtension =
            URL(fileURLWithPath: pairedVideoFilename).pathExtension

        return (
            still: stillExtension.isEmpty
                ? baseName
                : "\(baseName).\(stillExtension)",
            pairedVideo: pairedVideoExtension.isEmpty
                ? baseName
                : "\(baseName).\(pairedVideoExtension)"
        )
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
               let existingAsset = existingAsset(for: idempotencyKey) {
                return PhotoLibrarySaveResult(
                    albumTitle: album?.localizedTitle ?? "",
                    assetLocalIdentifier: existingAsset.localIdentifier
                )
            }

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
    ) -> PHAsset? {

        let token =
            "MemoMarkTask-\(idempotencyKey.replacingOccurrences(of: "/", with: "-"))"
        let options = PHFetchOptions()
        options.sortDescriptors = [
            NSSortDescriptor(
                key: "creationDate",
                ascending: false
            )
        ]
        let assets = PHAsset.fetchAssets(with: options)
        var matchedAsset: PHAsset?
        assets.enumerateObjects { asset, _, stop in
            guard PHAssetResource
                .assetResources(for: asset)
                .contains(where: {
                    $0.originalFilename.contains(token)
                }) else {
                return
            }
            matchedAsset = asset
            stop.pointee = true
        }
        return matchedAsset
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
