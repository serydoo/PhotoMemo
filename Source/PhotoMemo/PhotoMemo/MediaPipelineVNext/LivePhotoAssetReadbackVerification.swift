import AVFoundation
import CoreGraphics
import Foundation
import ImageIO
#if canImport(Photos)
import Photos
#endif

struct LivePhotoFileReadbackReport:
    Hashable,
    Sendable {

    let stillPhotoURL: URL
    let pairedVideoURL: URL
    let stillPixelWidth: Int
    let stillPixelHeight: Int
    let pairedVideoPixelWidth: Int
    let pairedVideoPixelHeight: Int
    let pairedVideoDuration: TimeInterval
    let stillContentIdentifier: String?
    let pairedVideoContentIdentifier: String?
    let stillCaptureDateOriginal: String?
    let stillGPSLatitude: Double?
    let stillGPSLongitude: Double?
    let quickTimeCreationDate: String?

    var isPairingIdentifierMatched: Bool {
        guard
            let stillContentIdentifier,
            let pairedVideoContentIdentifier
        else {
            return false
        }

        return stillContentIdentifier
            == pairedVideoContentIdentifier
    }

    var hasMatchingStillAndVideoDimensions: Bool {
        stillPixelWidth == pairedVideoPixelWidth
            && stillPixelHeight == pairedVideoPixelHeight
    }

    var hasCaptureDate: Bool {
        stillCaptureDateOriginal?
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .isEmpty == false
    }

    var hasGPSLocation: Bool {
        stillGPSLatitude != nil
            && stillGPSLongitude != nil
    }

    var hasQuickTimeCreationDate: Bool {
        quickTimeCreationDate?
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .isEmpty == false
    }

    var satisfiesGeneratedLivePhotoFileContract: Bool {
        isPairingIdentifierMatched
            && hasMatchingStillAndVideoDimensions
            && pairedVideoDuration > 0
            && hasCaptureDate
            && hasGPSLocation
            && hasQuickTimeCreationDate
    }
}

protocol LivePhotoFileReadbackReporting {

    func report(
        stillPhotoURL: URL,
        pairedVideoURL: URL
    ) async throws -> LivePhotoFileReadbackReport
}

enum LivePhotoFileReadbackReportingError:
    LocalizedError,
    Equatable,
    Sendable {

    case stillPhotoUnreadable(URL)
    case pairedVideoUnreadable(URL)
    case pairedVideoTrackMissing(URL)

    var errorDescription: String? {
        switch self {
        case .stillPhotoUnreadable:
            return "Unable to read the generated Live Photo still file."
        case .pairedVideoUnreadable:
            return "Unable to read the generated Live Photo paired video file."
        case .pairedVideoTrackMissing:
            return "The generated Live Photo paired video does not contain a video track."
        }
    }
}

struct LivePhotoFileReadbackReporter:
    LivePhotoFileReadbackReporting {

    func report(
        stillPhotoURL: URL,
        pairedVideoURL: URL
    ) async throws -> LivePhotoFileReadbackReport {
        guard
            let source =
                CGImageSourceCreateWithURL(
                    stillPhotoURL as CFURL,
                    nil
                ),
            let properties =
                CGImageSourceCopyPropertiesAtIndex(
                    source,
                    0,
                    nil
                ) as? [CFString: Any]
        else {
            throw LivePhotoFileReadbackReportingError
                .stillPhotoUnreadable(stillPhotoURL)
        }

        let asset =
            AVURLAsset(url: pairedVideoURL)
        let videoTracks: [AVAssetTrack]

        do {
            videoTracks =
                try await asset.loadTracks(
                    withMediaType: .video
                )
        } catch {
            throw LivePhotoFileReadbackReportingError
                .pairedVideoUnreadable(pairedVideoURL)
        }

        guard let videoTrack =
            videoTracks.first
        else {
            throw LivePhotoFileReadbackReportingError
                .pairedVideoTrackMissing(pairedVideoURL)
        }

        let duration =
            try await asset.load(.duration)
        let videoSize =
            try await videoTrack.load(.naturalSize)
        let videoMetadata =
            try await asset.load(.metadata)
        let stringProperties =
            properties.reduce(into: [String: Any]()) {
                result,
                element in
                result[element.key as String] =
                    element.value
            }

        return LivePhotoFileReadbackReport(
            stillPhotoURL:
                stillPhotoURL,
            pairedVideoURL:
                pairedVideoURL,
            stillPixelWidth:
                properties[
                    kCGImagePropertyPixelWidth
                ] as? Int ?? 0,
            stillPixelHeight:
                properties[
                    kCGImagePropertyPixelHeight
                ] as? Int ?? 0,
            pairedVideoPixelWidth:
                Int(abs(videoSize.width)),
            pairedVideoPixelHeight:
                Int(abs(videoSize.height)),
            pairedVideoDuration:
                CMTimeGetSeconds(duration),
            stillContentIdentifier:
                LivePhotoPairingIdentityVerifier
                .stillContentIdentifier(
                    from: stringProperties
                ),
            pairedVideoContentIdentifier:
                try await LivePhotoPairingIdentityVerifier
                .videoContentIdentifier(
                    from: videoMetadata
                ),
            stillCaptureDateOriginal:
                stillCaptureDateOriginal(
                    from: properties
                ),
            stillGPSLatitude:
                stillGPSLatitude(
                    from: properties
                ),
            stillGPSLongitude:
                stillGPSLongitude(
                    from: properties
                ),
            quickTimeCreationDate:
                try await quickTimeCreationDate(
                    from: videoMetadata
                )
        )
    }
}

private extension LivePhotoFileReadbackReporter {

    func stillCaptureDateOriginal(
        from properties: [CFString: Any]
    ) -> String? {
        let exif =
            properties[
                kCGImagePropertyExifDictionary
            ] as? [CFString: Any]

        return exif?[
            kCGImagePropertyExifDateTimeOriginal
        ] as? String
    }

    func stillGPSLatitude(
        from properties: [CFString: Any]
    ) -> Double? {
        let gps =
            properties[
                kCGImagePropertyGPSDictionary
            ] as? [CFString: Any]

        return gps?[
            kCGImagePropertyGPSLatitude
        ] as? Double
    }

    func stillGPSLongitude(
        from properties: [CFString: Any]
    ) -> Double? {
        let gps =
            properties[
                kCGImagePropertyGPSDictionary
            ] as? [CFString: Any]

        return gps?[
            kCGImagePropertyGPSLongitude
        ] as? Double
    }

    func quickTimeCreationDate(
        from metadata: [AVMetadataItem]
    ) async throws -> String? {
        try await metadata
            .first {
                $0.identifier
                    == .quickTimeMetadataCreationDate
            }?
            .load(.stringValue)?
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
    }
}

struct LivePhotoAssetReadbackResource:
    Hashable,
    Sendable {

    enum Kind:
        String,
        Hashable,
        Sendable {
        case photo
        case fullSizePhoto
        case pairedVideo
        case alternatePhoto
        case other
    }

    let kind: Kind
    let originalFilename: String
    let uniformTypeIdentifier: String
}

struct LivePhotoAssetReadbackReport:
    Hashable,
    Sendable {

    let localIdentifier: String
    let pixelWidth: Int
    let pixelHeight: Int
    let duration: TimeInterval
    let isImageAsset: Bool
    let isLivePhoto: Bool
    let resources: [LivePhotoAssetReadbackResource]

    var hasStillPhotoResource: Bool {
        resources.contains {
            $0.kind == .photo
                || $0.kind == .fullSizePhoto
        }
    }

    var hasPairedVideoResource: Bool {
        resources.contains {
            $0.kind == .pairedVideo
        }
    }

    var satisfiesLivePhotoPairingContract: Bool {
        isImageAsset
            && isLivePhoto
            && hasStillPhotoResource
            && hasPairedVideoResource
    }
}

protocol LivePhotoAssetReadbackVerifying {

    func verifyAsset(
        localIdentifier: String
    ) throws -> LivePhotoAssetReadbackReport
}

enum LivePhotoAssetReadbackVerificationError:
    LocalizedError,
    Equatable {
    case photoKitUnavailable
    case assetNotFound

    var errorDescription: String? {
        switch self {
        case .photoKitUnavailable:
            return "PhotoKit is unavailable in this environment."
        case .assetNotFound:
            return "The saved Live Photo asset could not be found in the photo library."
        }
    }
}

struct PhotoKitLivePhotoAssetReadbackVerifier:
    LivePhotoAssetReadbackVerifying {

    func verifyAsset(
        localIdentifier: String
    ) throws -> LivePhotoAssetReadbackReport {
#if canImport(Photos)
        let fetchResult =
            PHAsset.fetchAssets(
                withLocalIdentifiers: [
                    localIdentifier
                ],
                options: nil
            )

        guard let asset =
            fetchResult.firstObject
        else {
            throw LivePhotoAssetReadbackVerificationError
                .assetNotFound
        }

        let resources =
            PHAssetResource.assetResources(
                for: asset
            )
            .map {
                resource in
                LivePhotoAssetReadbackResource(
                    kind:
                        resource.type
                        .livePhotoReadbackKind,
                    originalFilename:
                        resource.originalFilename,
                    uniformTypeIdentifier:
                        resource
                        .uniformTypeIdentifier
                )
            }

        return LivePhotoAssetReadbackReport(
            localIdentifier:
                asset.localIdentifier,
            pixelWidth:
                asset.pixelWidth,
            pixelHeight:
                asset.pixelHeight,
            duration:
                asset.duration,
            isImageAsset:
                asset.mediaType == .image,
            isLivePhoto:
                asset.mediaSubtypes
                .contains(.photoLive),
            resources:
                resources
        )
#else
        throw LivePhotoAssetReadbackVerificationError
            .photoKitUnavailable
#endif
    }
}

#if canImport(Photos)
private extension PHAssetResourceType {

    var livePhotoReadbackKind:
        LivePhotoAssetReadbackResource.Kind {

        switch self {
        case .photo:
            return .photo
        case .fullSizePhoto:
            return .fullSizePhoto
        case .pairedVideo:
            return .pairedVideo
        case .alternatePhoto:
            return .alternatePhoto
        default:
            return .other
        }
    }
}
#endif
