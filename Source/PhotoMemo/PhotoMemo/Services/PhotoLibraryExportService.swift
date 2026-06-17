import Foundation
import Photos
import CoreLocation

struct PhotoAlbumOption: Identifiable, Hashable {

    static let automaticIdentifier = "__photomemo_auto__"

    let id: String

    let title: String

    let localIdentifier: String?

    static let automatic = PhotoAlbumOption(
        id: automaticIdentifier,
        title: "自动存入 PhotoMemo",
        localIdentifier: nil
    )
}

enum PhotoLibraryExportError: LocalizedError {

    case unauthorized

    case albumNotFound

    case albumCreateFailed

    case assetSaveFailed

    var errorDescription: String? {

        switch self {

        case .unauthorized:
            return "请先允许 PhotoMemo 访问你的系统相册。"

        case .albumNotFound:
            return "未找到你选择的相册，请刷新后重试。"

        case .albumCreateFailed:
            return "无法创建 PhotoMemo 相册。"

        case .assetSaveFailed:
            return "图片已生成，但写入系统相册失败。"
        }
    }
}

@MainActor
final class PhotoLibraryExportService {

    private let defaultAlbumTitle = "PhotoMemo"

    func fetchAlbumOptions() async throws -> [PhotoAlbumOption] {

        let status = await requestAuthorizationIfNeeded()

        guard isAuthorized(status) else {
            throw PhotoLibraryExportError.unauthorized
        }

        var albums: [PhotoAlbumOption] = []

        let fetchResult = PHAssetCollection.fetchAssetCollections(
            with: .album,
            subtype: .any,
            options: nil
        )

        fetchResult.enumerateObjects { collection, _, _ in

            guard
                let title = collection.localizedTitle?
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ),
                !title.isEmpty
            else {
                return
            }

            albums.append(
                PhotoAlbumOption(
                    id: collection.localIdentifier,
                    title: title,
                    localIdentifier: collection.localIdentifier
                )
            )
        }

        let uniqueAlbums =
            Array(
                Dictionary(
                    albums.map { ($0.id, $0) },
                    uniquingKeysWith: { first, _ in first }
                ).values
            )
            .sorted {
                $0.title.localizedStandardCompare($1.title)
                == .orderedAscending
            }

        return uniqueAlbums
    }

    func saveImage(
        at fileURL: URL,
        metadata: PhotoMetadata,
        preferredAlbumIdentifier: String?
    ) async throws -> String {

        let status = await requestAuthorizationIfNeeded()

        guard isAuthorized(status) else {
            throw PhotoLibraryExportError.unauthorized
        }

        let album =
            try await resolvedAlbum(
                preferredAlbumIdentifier
            )

        var placeholderIdentifier: String?

        try await performChanges {

            let assetRequest =
                PHAssetCreationRequest.forAsset()

            assetRequest.creationDate =
                metadata.captureDate

            if let location =
                self.preservedLocation(
                    from: metadata
                ) {

                assetRequest.location =
                    location
            }

            let resourceOptions =
                PHAssetResourceCreationOptions()

            resourceOptions.shouldMoveFile = false

            assetRequest.addResource(
                with: .photo,
                fileURL: fileURL,
                options: resourceOptions
            )

            guard let placeholder =
                assetRequest.placeholderForCreatedAsset
            else {
                return
            }

            placeholderIdentifier =
                placeholder.localIdentifier

            if let albumChangeRequest =
                PHAssetCollectionChangeRequest(
                    for: album
                ) {

                albumChangeRequest.addAssets(
                    [placeholder] as NSArray
                )
            }
        }

        guard placeholderIdentifier != nil else {
            throw PhotoLibraryExportError.assetSaveFailed
        }

        return album.localizedTitle ?? defaultAlbumTitle
    }
}

private extension PhotoLibraryExportService {

    func preservedLocation(
        from metadata: PhotoMetadata
    ) -> CLLocation? {

        guard
            let latitude = metadata.latitude,
            let longitude = metadata.longitude
        else {
            return nil
        }

        if let altitude = metadata.altitude {
            return CLLocation(
                coordinate: CLLocationCoordinate2D(
                    latitude: latitude,
                    longitude: longitude
                ),
                altitude: altitude,
                horizontalAccuracy: kCLLocationAccuracyNearestTenMeters,
                verticalAccuracy: kCLLocationAccuracyNearestTenMeters,
                timestamp: metadata.captureDate ?? Date()
            )
        }

        return CLLocation(
            latitude: latitude,
            longitude: longitude
        )
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

        return await withCheckedContinuation { continuation in

            PHPhotoLibrary.requestAuthorization(
                for: .readWrite
            ) { status in

                continuation.resume(returning: status)
            }
        }
    }

    func resolvedAlbum(
        _ localIdentifier: String?
    ) async throws -> PHAssetCollection {

        if let localIdentifier,
           let existingAlbum =
            fetchAlbum(
                with: localIdentifier
            ) {

            return existingAlbum
        }

        if let existingDefaultAlbum =
            fetchAlbum(
                withTitle: defaultAlbumTitle
            ) {

            return existingDefaultAlbum
        }

        return try await createDefaultAlbum()
    }

    func fetchAlbum(
        with localIdentifier: String
    ) -> PHAssetCollection? {

        PHAssetCollection
            .fetchAssetCollections(
                withLocalIdentifiers: [localIdentifier],
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

        fetchResult.enumerateObjects { collection, _, stop in

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

    func createDefaultAlbum() async throws -> PHAssetCollection {

        var createdIdentifier: String?

        try await performChanges {

            let request =
                PHAssetCollectionChangeRequest
                .creationRequestForAssetCollection(
                    withTitle: self.defaultAlbumTitle
                )

            createdIdentifier =
                request.placeholderForCreatedAssetCollection
                .localIdentifier
        }

        guard
            let createdIdentifier,
            let createdAlbum = fetchAlbum(
                with: createdIdentifier
            )
        else {
            throw PhotoLibraryExportError.albumCreateFailed
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
                            PhotoLibraryExportError
                            .assetSaveFailed
                    )
                    return
                }

                continuation.resume()
            }
        }
    }
}
