import Foundation

struct LivePhotoSaveRequest:
    Hashable,
    Sendable {

    let stillPhotoFileURL: URL
    let pairedVideoFileURL: URL
    let captureDate: Date?
    let preferredAlbumIdentifier: String?
    let stillPhotoOriginalFilename: String?
    let pairedVideoOriginalFilename: String?
    let idempotencyKey: String?

    init(
        stillPhotoFileURL: URL,
        pairedVideoFileURL: URL,
        captureDate: Date?,
        preferredAlbumIdentifier: String?,
        stillPhotoOriginalFilename: String?,
        pairedVideoOriginalFilename: String?,
        idempotencyKey: String? = nil
    ) {
        self.stillPhotoFileURL = stillPhotoFileURL
        self.pairedVideoFileURL = pairedVideoFileURL
        self.captureDate = captureDate
        self.preferredAlbumIdentifier = preferredAlbumIdentifier
        self.stillPhotoOriginalFilename = stillPhotoOriginalFilename
        self.pairedVideoOriginalFilename = pairedVideoOriginalFilename
        self.idempotencyKey = idempotencyKey
    }
}

enum LivePhotoAssetWritingError:
    LocalizedError,
    Equatable {
    case photoLibraryWritesDisabledByRuntimeGate
    case unauthorized
    case stillPhotoFileMissing
    case pairedVideoFileMissing
    case outputFilenameBaseMismatch
    case pairingIdentityVerificationFailed(
        LivePhotoPairingIdentityVerificationError
    )
    case albumNotFound
    case albumCreateFailed
    case assetSaveFailed

    var errorDescription: String? {
        switch self {
        case .photoLibraryWritesDisabledByRuntimeGate:
            return "Live Photo photo-library writing is disabled for this runtime."
        case .unauthorized:
            return "Please allow MemoMark to access the system photo library."
        case .stillPhotoFileMissing:
            return "The rendered still photo file is missing."
        case .pairedVideoFileMissing:
            return "The rendered paired video file is missing."
        case .outputFilenameBaseMismatch:
            return "The rendered Live Photo still image and paired video must use the same output filename."
        case .pairingIdentityVerificationFailed:
            return "The rendered Live Photo still image and paired video cannot be paired safely."
        case .albumNotFound:
            return "Unable to find the selected album."
        case .albumCreateFailed:
            return "Unable to create the destination album."
        case .assetSaveFailed:
            return "The Live Photo was prepared, but saving to the photo library failed."
        }
    }
}
