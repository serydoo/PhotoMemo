import Foundation

protocol LivePhotoAssetWriting {

    func saveAsset(
        _ request: LivePhotoSaveRequest
    ) async throws -> PhotoLibrarySaveResult
}

enum LivePhotoWritableResourceKind:
    Hashable,
    Sendable {
    case photo
    case pairedVideo
}

struct LivePhotoAssetResourceWriteRequest:
    Hashable,
    Sendable {

    let kind: LivePhotoWritableResourceKind
    let fileURL: URL
    let originalFilename: String
}

struct LivePhotoAssetWriteOperation:
    Hashable,
    Sendable {

    let creationDate: Date?
    let preferredAlbumIdentifier: String?
    let idempotencyKey: String?
    let resources:
        [LivePhotoAssetResourceWriteRequest]

    init(
        creationDate: Date?,
        preferredAlbumIdentifier: String?,
        resources: [LivePhotoAssetResourceWriteRequest],
        idempotencyKey: String? = nil
    ) {
        self.creationDate = creationDate
        self.preferredAlbumIdentifier = preferredAlbumIdentifier
        self.resources = resources
        self.idempotencyKey = idempotencyKey
    }
}

protocol LivePhotoAssetSavePerforming {

    func save(
        operation: LivePhotoAssetWriteOperation
    ) async throws -> PhotoLibrarySaveResult
}
