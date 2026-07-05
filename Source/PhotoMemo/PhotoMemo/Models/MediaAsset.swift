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

    init?(
        fileURL: URL
    ) {
        guard
            let source =
                CGImageSourceCreateWithURL(
                    fileURL as CFURL,
                    [
                        kCGImageSourceShouldCache:
                            false
                    ] as CFDictionary
                ),
            let properties =
                CGImageSourceCopyPropertiesAtIndex(
                    source,
                    0,
                    nil
                ) as? [CFString: Any]
        else {
            return nil
        }

        self.init(
            sourceProperties:
                properties
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

struct MediaCost: Hashable, Codable {

    let pixelSize: MediaPixelSize?
    let isRAW: Bool

    init(
        pixelSize: MediaPixelSize?,
        isRAW: Bool
    ) {
        self.pixelSize = pixelSize
        self.isRAW = isRAW
    }

    init(
        asset: MediaAsset
    ) {
        self.init(
            pixelSize: asset.pixelSize,
            isRAW: asset.isRAW
        )
    }

    init(
        fileURL: URL,
        contentTypeIdentifier: String?
    ) {
        let contentType =
            contentTypeIdentifier
            .flatMap(UTType.init)

        self.init(
            pixelSize:
                MediaPixelSize(
                    fileURL: fileURL
                ),
            isRAW:
                PhotoProcessingInputPolicy
                .isRawContentType(contentType)
                || PhotoProcessingInputPolicy
                .isRawFileURL(fileURL)
        )
    }

    var pixelCount: Int {
        guard let pixelSize else {
            return 0
        }

        return pixelSize.width * pixelSize.height
    }

    var estimatedDecodedByteCount: Int {
        pixelCount * 4
    }
}

struct MediaMemoryBudget: Hashable, Codable {

    enum Tier: String, Hashable, Codable {
        case normal
        case high
        case critical
    }

    let cost: MediaCost

    init(
        cost: MediaCost
    ) {
        self.cost = cost
    }

    var tier: Tier {
        if cost.isRAW,
           cost.pixelCount >= Self.highPixelCountThreshold {
            return .critical
        }

        if cost.pixelCount >= Self.criticalPixelCountThreshold {
            return .critical
        }

        if cost.pixelCount >= Self.highPixelCountThreshold {
            return .high
        }

        return .normal
    }

    var maxConcurrentDecodes: Int {
        switch tier {
        case .normal:
            return 2

        case .high,
             .critical:
            return 1
        }
    }

    var maxConcurrentRenders: Int {
        switch tier {
        case .normal:
            return 2

        case .high,
             .critical:
            return 1
        }
    }

    var maxConcurrentExports: Int {
        1
    }

    var requiresExtendedPreviewPreparation: Bool {
        tier == .critical
            || cost.isRAW
    }

    private static let highPixelCountThreshold =
        24_000_000

    private static let criticalPixelCountThreshold =
        48_000_000
}

struct MediaImportReport: Hashable, Codable {

    let fileName: String
    let sourceIdentifier: String?
    let contentTypeIdentifier: String?
    let pixelSize: MediaPixelSize?
    let isRAW: Bool
    let isLivePhoto: Bool
    let memoryTier: MediaMemoryBudget.Tier
    let requiresExtendedPreviewPreparation: Bool
    let estimatedDecodedByteCount: Int
    let representationKind: MediaRepresentation.Kind?
    let decodePurpose: DecodePurpose?
    let representationPixelSize: MediaPixelSize?
    let representationMaxPixelDimension: Int?
    let isRepresentationDownsampled: Bool

    init(
        asset: MediaAsset,
        representation: MediaRepresentation?
    ) {
        let cost =
            MediaCost(
                asset: asset
            )
        let budget =
            MediaMemoryBudget(
                cost: cost
            )

        self.fileName =
            asset.fileURL.lastPathComponent
        self.sourceIdentifier =
            asset.sourceIdentifier
        self.contentTypeIdentifier =
            asset.contentType?.identifier
        self.pixelSize =
            asset.pixelSize
        self.isRAW =
            asset.isRAW
        self.isLivePhoto =
            asset.isLivePhoto
        self.memoryTier =
            budget.tier
        self.requiresExtendedPreviewPreparation =
            budget.requiresExtendedPreviewPreparation
        self.estimatedDecodedByteCount =
            cost.estimatedDecodedByteCount
        self.representationKind =
            representation?.kind
        self.decodePurpose =
            representation?.decodePurpose
        self.representationPixelSize =
            representation?.pixelSize
        self.representationMaxPixelDimension =
            representation?.maxPixelDimension
        self.isRepresentationDownsampled =
            representation?.isDownsampled ?? false
    }
}
