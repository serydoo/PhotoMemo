import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

struct MediaPixelSize: Hashable, Codable {

    let width: Int
    let height: Int

    init(
        width: Int,
        height: Int
    ) {
        self.width = max(width, 0)
        self.height = max(height, 0)
    }

    init?(
        sourceProperties: [CFString: Any]
    ) {
        guard
            let width =
                sourceProperties[
                    kCGImagePropertyPixelWidth
                ] as? Int,
            let height =
                sourceProperties[
                    kCGImagePropertyPixelHeight
                ] as? Int,
            width > 0,
            height > 0
        else {
            return nil
        }

        self.init(
            width: width,
            height: height
        )
    }

    init(
        size: CGSize
    ) {
        self.init(
            width:
                Int(
                    size.width.rounded()
                ),
            height:
                Int(
                    size.height.rounded()
                )
        )
    }

    var longSide: Int {
        max(width, height)
    }
}

struct MediaAsset {

    let fileURL: URL
    let contentType: UTType?
    let pixelSize: MediaPixelSize?
    let metadata: [CFString: Any]
    let isRAW: Bool
    let isLivePhoto: Bool
    let sourceIdentifier: String?

    init(
        fileURL: URL,
        sourceInfo: PhotoSourceInfo,
        sourceProperties: [CFString: Any],
        contentType: UTType?
    ) {
        self.fileURL = fileURL
        self.contentType = contentType
        self.pixelSize =
            MediaPixelSize(
                sourceProperties:
                    sourceProperties
            )
        self.metadata = sourceProperties
        self.isRAW =
            PhotoProcessingInputPolicy
            .isRawContentType(contentType)
            || PhotoProcessingInputPolicy
            .isRawFileURL(fileURL)
        self.isLivePhoto =
            PhotoProcessingInputPolicy
            .isLivePhotoContentType(contentType)
        self.sourceIdentifier =
            sourceInfo.assetLocalIdentifier
    }
}

enum DecodePurpose: Hashable, Codable {
    case preview
    case processing
    case export
}

struct MediaRepresentation {

    enum Kind: Hashable, Codable {
        case thumbnail
        case preview
        case processing
        case exportSource
    }

    let kind: Kind
    let decodePurpose: DecodePurpose
    let asset: MediaAsset
    let pixelSize: MediaPixelSize?
    let maxPixelDimension: Int?

    var isDownsampled: Bool {
        guard
            let sourceLongSide =
                asset.pixelSize?.longSide,
            let representationLongSide =
                pixelSize?.longSide
        else {
            return false
        }

        return representationLongSide < sourceLongSide
    }

    static func preview(
        asset: MediaAsset,
        pixelSize: MediaPixelSize?,
        maxPixelDimension: Int
    ) -> MediaRepresentation {

        MediaRepresentation(
            kind: .preview,
            decodePurpose: .preview,
            asset: asset,
            pixelSize: pixelSize,
            maxPixelDimension: maxPixelDimension
        )
    }
}
