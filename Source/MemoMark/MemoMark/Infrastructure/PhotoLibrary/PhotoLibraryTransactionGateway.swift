#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Photos

/// Owns only Apple Photos mechanics shared by static-photo and Live Photo
/// transactions. It deliberately does not own receipt state, Memory Engine
/// meaning, rendering, output policy, or product-specific error messages.
@MainActor
final class PhotoLibraryTransactionGateway {

    enum Error: Swift.Error {

        case transactionDidNotCommit
        case photoResourceUnavailable
    }

    static let shared = PhotoLibraryTransactionGateway()

    func requestReadWriteAuthorization() async -> PHAuthorizationStatus {
        let currentStatus = PHPhotoLibrary.authorizationStatus(
            for: .readWrite
        )
        guard currentStatus == .notDetermined else {
            return currentStatus
        }

        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(
                for: .readWrite
            ) { status in
                continuation.resume(returning: status)
            }
        }
    }

    func asset(
        with localIdentifier: String
    ) -> PHAsset? {
        PHAsset.fetchAssets(
            withLocalIdentifiers: [localIdentifier],
            options: nil
        ).firstObject
    }

    func album(
        with localIdentifier: String
    ) -> PHAssetCollection? {
        PHAssetCollection.fetchAssetCollections(
            withLocalIdentifiers: [localIdentifier],
            options: nil
        ).firstObject
    }

    func album(
        titled title: String
    ) -> PHAssetCollection? {
        albumCollections().first {
            $0.localizedTitle == title
        }
    }

    func albumCollections() -> [PHAssetCollection] {
        let fetchResult = PHAssetCollection.fetchAssetCollections(
            with: .album,
            subtype: .any,
            options: nil
        )
        var collections: [PHAssetCollection] = []
        fetchResult.enumerateObjects { collection, _, _ in
            collections.append(collection)
        }
        return collections
    }

    func createAlbum(
        named title: String
    ) async throws -> PHAssetCollection? {
        var createdIdentifier: String?
        try await performChanges {
            let request =
                PHAssetCollectionChangeRequest
                .creationRequestForAssetCollection(
                    withTitle: title
                )
            createdIdentifier =
                request.placeholderForCreatedAssetCollection
                .localIdentifier
        }
        guard let createdIdentifier else {
            return nil
        }
        return album(with: createdIdentifier)
    }

    func performChanges(
        _ changes: @escaping () -> Void
    ) async throws {
        try await withCheckedThrowingContinuation {
            (
                continuation:
                    CheckedContinuation<Void, Swift.Error>
            ) in
            PHPhotoLibrary.shared().performChanges(
                changes
            ) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard success else {
                    continuation.resume(
                        throwing: Error.transactionDidNotCommit
                    )
                    return
                }
                continuation.resume()
            }
        }
    }

    /// Exports the still resource selected by PhotoKit for an exact asset.
    /// The caller owns the resulting temporary file's lifetime and product
    /// error translation; this gateway owns only PhotoKit resource lookup and
    /// asynchronous file transfer mechanics.
    func exportPhotoResourceToTemporaryFile(
        for asset: PHAsset
    ) async throws -> URL {
        let resources = PHAssetResource.assetResources(for: asset)

        guard let resource = resources.first(where: {
            $0.type == .photo || $0.type == .fullSizePhoto
        }) ?? resources.first else {
            throw Error.photoResourceUnavailable
        }

        let temporaryFolder = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "MemoMarkPhotoLibraryValidation",
                isDirectory: true
            )
        try FileManager.default.createDirectory(
            at: temporaryFolder,
            withIntermediateDirectories: true
        )

        let baseName = PhotoKitResourceFileName.value(for: resource)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let fileName = baseName.isEmpty
            ? "\(asset.localIdentifier).jpg"
            : baseName
        let targetURL = temporaryFolder.appendingPathComponent(
            UUID().uuidString + "_" + fileName
        )

        return try await withCheckedThrowingContinuation {
            (
                continuation:
                    CheckedContinuation<URL, Swift.Error>
            ) in
            PHAssetResourceManager.default().writeData(
                for: resource,
                toFile: targetURL,
                options: nil
            ) { error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                continuation.resume(returning: targetURL)
            }
        }
    }
}
#endif
