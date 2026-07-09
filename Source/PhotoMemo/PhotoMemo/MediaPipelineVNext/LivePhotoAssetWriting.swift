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
    let resources:
        [LivePhotoAssetResourceWriteRequest]
}

protocol LivePhotoAssetSavePerforming {

    func save(
        operation: LivePhotoAssetWriteOperation
    ) async throws -> PhotoLibrarySaveResult
}
