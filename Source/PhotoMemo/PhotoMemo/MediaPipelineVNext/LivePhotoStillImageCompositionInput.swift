import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

struct LivePhotoPreparedStillImage {

    let image: CGImage
    let properties: [CFString: Any]
}

protocol LivePhotoStillImageSourcePreparing {

    func preparedStillImage(
        sourceStillURL: URL,
        targetFrame: CGRect
    ) throws -> LivePhotoPreparedStillImage
}

protocol LivePhotoStillImageWriting {

    func writeComposedStillImage(
        _ image: CGImage,
        sourceProperties: [CFString: Any],
        outputURL: URL,
        outputType: UTType,
        outputDescription: String?,
        pairingIdentifier: String?
    ) throws -> URL
}

struct ImageIOLivePhotoStillImageSourcePreparer:
    LivePhotoStillImageSourcePreparing {

    func preparedStillImage(
        sourceStillURL: URL,
        targetFrame: CGRect
    ) throws -> LivePhotoPreparedStillImage {
        guard
            let source =
                CGImageSourceCreateWithURL(
                    sourceStillURL as CFURL,
                    nil
                )
        else {
            throw LivePhotoStillImageCompositionError
                .sourceStillUnreadable
        }

        guard
            let image =
                transformedSourceImage(
                    source,
                    targetFrame: targetFrame
                )
        else {
            throw LivePhotoStillImageCompositionError
                .sourceStillImageMissing
        }

        let properties =
            CGImageSourceCopyPropertiesAtIndex(
                source,
                0,
                nil
            ) as? [CFString: Any] ?? [:]

        return LivePhotoPreparedStillImage(
            image: image,
            properties: properties
        )
    }
}

struct ImageIOLivePhotoStillImageWriter:
    LivePhotoStillImageWriting {

    func writeComposedStillImage(
        _ image: CGImage,
        sourceProperties: [CFString: Any],
        outputURL: URL,
        outputType: UTType,
        outputDescription: String?,
        pairingIdentifier: String?
    ) throws -> URL {
        let outputFolder =
            outputURL.deletingLastPathComponent()

        do {
            try FileManager.default.createDirectory(
                at: outputFolder,
                withIntermediateDirectories: true
            )
        } catch {
            throw LivePhotoStillImageCompositionError
                .destinationPrepareFailed
        }

        try? FileManager.default.removeItem(
            at: outputURL
        )

        guard
            let destination =
                CGImageDestinationCreateWithURL(
                    outputURL as CFURL,
                    outputType.identifier as CFString,
                    1,
                    nil
                )
        else {
            throw LivePhotoStillImageCompositionError
                .destinationCreateFailed
        }

        let properties =
            revisedMetadata(
                from: sourceProperties,
                outputType:
                    outputType,
                pixelSize: CGSize(
                    width: image.width,
                    height: image.height
                ),
                outputDescription:
                    outputDescription,
                pairingIdentifier:
                    pairingIdentifier
            )

        CGImageDestinationAddImage(
            destination,
            image,
            properties as CFDictionary
        )

        guard CGImageDestinationFinalize(destination) else {
            throw LivePhotoStillImageCompositionError
                .writeFailed
        }

        return outputURL
    }
}

private extension ImageIOLivePhotoStillImageSourcePreparer {

    func transformedSourceImage(
        _ source: CGImageSource,
        targetFrame: CGRect
    ) -> CGImage? {
        let maxPixelSize =
            max(
                Int(
                    ceil(
                        max(
                            targetFrame.width,
                            targetFrame.height
                        )
                    )
                ),
                1
            )
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways:
                true,
            kCGImageSourceCreateThumbnailWithTransform:
                true,
            kCGImageSourceShouldCacheImmediately:
                true,
            kCGImageSourceThumbnailMaxPixelSize:
                maxPixelSize
        ]

        return CGImageSourceCreateThumbnailAtIndex(
            source,
            0,
            options as CFDictionary
        )
        ?? CGImageSourceCreateImageAtIndex(
            source,
            0,
            nil
        )
    }
}

private extension ImageIOLivePhotoStillImageWriter {

    func revisedMetadata(
        from sourceProperties: [CFString: Any],
        outputType: UTType,
        pixelSize: CGSize,
        outputDescription: String? = nil,
        pairingIdentifier: String? = nil
    ) -> [CFString: Any] {
        var properties =
            sourceProperties

        let pixelWidth =
            Int(pixelSize.width)
        let pixelHeight =
            Int(pixelSize.height)

        properties[
            kCGImagePropertyPixelWidth
        ] = pixelWidth
        properties[
            kCGImagePropertyPixelHeight
        ] = pixelHeight
        properties[
            kCGImagePropertyOrientation
        ] = 1

        var exif =
            properties[
                kCGImagePropertyExifDictionary
            ] as? [CFString: Any] ?? [:]

        exif[
            kCGImagePropertyExifPixelXDimension
        ] = pixelWidth
        exif[
            kCGImagePropertyExifPixelYDimension
        ] = pixelHeight

        applyOutputDescription(
            outputDescription,
            outputType:
                outputType,
            toExif: &exif
        )

        properties[
            kCGImagePropertyExifDictionary
        ] = exif

        var tiff =
            properties[
                kCGImagePropertyTIFFDictionary
            ] as? [CFString: Any] ?? [:]

        tiff[
            kCGImagePropertyTIFFSoftware
        ] = "MemoMark"

        applyOutputDescription(
            outputDescription,
            toTiff: &tiff
        )

        properties[
            kCGImagePropertyTIFFDictionary
        ] = tiff

        applyOutputDescription(
            outputDescription,
            to: &properties
        )

        applyLivePhotoPairingMetadata(
            pairingIdentifier,
            to: &properties
        )

        return properties
    }

    func applyOutputDescription(
        _ outputDescription: String?,
        to properties: inout [CFString: Any]
    ) {
        guard let description =
            normalizedOutputDescription(
                outputDescription
            )
        else {
            return
        }

        var iptc =
            properties[
                kCGImagePropertyIPTCDictionary
            ] as? [CFString: Any] ?? [:]

        iptc[
            kCGImagePropertyIPTCCaptionAbstract
        ] = description

        properties[
            kCGImagePropertyIPTCDictionary
        ] = iptc
    }

    func applyOutputDescription(
        _ outputDescription: String?,
        outputType: UTType,
        toExif exif: inout [CFString: Any]
    ) {
        guard let description =
            normalizedOutputDescription(
                outputDescription
            )
        else {
            return
        }

        if outputType.conforms(to: .heic),
           !description.canBeConverted(to: .ascii) {
            return
        }

        exif[
            "UserComment" as CFString
        ] = description
    }

    func applyOutputDescription(
        _ outputDescription: String?,
        toTiff tiff: inout [CFString: Any]
    ) {
        guard let description =
            normalizedOutputDescription(
                outputDescription
            )
        else {
            return
        }

        tiff[
            kCGImagePropertyTIFFImageDescription
        ] = description
    }

    func normalizedOutputDescription(
        _ outputDescription: String?
    ) -> String? {
        let description =
            outputDescription?
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            ) ?? ""

        return description.isEmpty
            ? nil
            : description
    }

    func applyLivePhotoPairingMetadata(
        _ pairingIdentifier: String?,
        to properties: inout [CFString: Any]
    ) {
        guard
            let pairingIdentifier =
                pairingIdentifier?
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                ),
            !pairingIdentifier.isEmpty
        else {
            return
        }

        var makerApple =
            properties[
                kCGImagePropertyMakerAppleDictionary
            ] as? [String: Any] ?? [:]

        makerApple[
            "17"
        ] = pairingIdentifier

        properties[
            kCGImagePropertyMakerAppleDictionary
        ] = makerApple
    }
}
