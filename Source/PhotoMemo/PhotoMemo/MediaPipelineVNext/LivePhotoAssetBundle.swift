import Foundation

enum LivePhotoAssetResourceKind:
    Hashable,
    Codable {
    case photo
    case fullSizePhoto
    case alternatePhoto
    case pairedVideo
    case fullSizePairedVideo
    case other(String)
}

struct LivePhotoAssetResourceDescriptor:
    Hashable,
    Codable,
    Identifiable,
    Sendable {

    let id: String
    let kind: LivePhotoAssetResourceKind
    let originalFilename: String
    let uniformTypeIdentifier: String?
}

struct LivePhotoAssetBundle:
    Hashable,
    Sendable {

    let assetLocalIdentifier: String
    let stillPhotoResource:
        LivePhotoAssetResourceDescriptor
    let pairedVideoResource:
        LivePhotoAssetResourceDescriptor
    let pairedVideoResourceCandidates:
        [LivePhotoAssetResourceDescriptor]
}

struct LivePhotoPreparedAssetBundle:
    Hashable,
    Sendable {

    let assetLocalIdentifier: String
    let stillPhotoResource:
        LivePhotoAssetResourceDescriptor
    let pairedVideoResource:
        LivePhotoAssetResourceDescriptor
    let stillPhotoFileURL: URL
    let pairedVideoFileURL: URL
}

enum LivePhotoAssetLoadingError:
    LocalizedError,
    Equatable {
    case assetNotFound
    case stillPhotoResourceMissing
    case pairedVideoResourceMissing
    case temporaryDirectoryCreateFailed

    var errorDescription: String? {
        switch self {
        case .assetNotFound:
            return "Unable to find the selected Live Photo asset."
        case .stillPhotoResourceMissing:
            return "The Live Photo still image resource is missing."
        case .pairedVideoResourceMissing:
            return "The Live Photo paired video resource is missing."
        case .temporaryDirectoryCreateFailed:
            return "Unable to prepare temporary files for the Live Photo asset."
        }
    }
}
