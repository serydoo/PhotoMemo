import Foundation
import ImageIO
import UniformTypeIdentifiers

nonisolated final class MetadataPreservingImageWriter {

    func write(
        cgImage: CGImage,
        to url: URL,
        sourceProperties: [CFString: Any],
        exportDescription: String,
        captureDate: Date?
    ) throws -> URL {

        let type =
            outputType(for: url)

        guard let destination =
            CGImageDestinationCreateWithURL(
                url as CFURL,
                type.identifier as CFString,
                1,
                nil
            )
        else {
            throw RecordCardExportError.destinationCreateFailed
        }

        let renderSize = CGSize(
            width: cgImage.width,
            height: cgImage.height
        )
        let properties =
            sanitizedMetadata(
                from: sourceProperties,
                renderSize: renderSize,
                outputType: type,
                exportDescription:
                    exportDescription
            )

        CGImageDestinationAddImage(
            destination,
            cgImage,
            properties as CFDictionary
        )

        guard CGImageDestinationFinalize(destination) else {
            throw RecordCardExportError.writeFailed
        }

        let patched = JPEGExifUserCommentPatcher.patchIfNeeded(
            at: url,
            outputType: type,
            exportDescription:
                exportDescription
        )

        if type.conforms(to: .jpeg),
           exportDescription.unicodeScalars.contains(where: { $0.value > 0x7F }),
           !patched {
            throw RecordCardExportError.writeFailed
        }

        applyFileDates(
            to: url,
            captureDate: captureDate
        )

        return url
    }

    private func outputType(
        for url: URL
    ) -> UTType {

        UTType(
            filenameExtension:
                url.pathExtension.lowercased()
        ) ?? .jpeg
    }

    private func sanitizedMetadata(
        from sourceProperties: [CFString: Any],
        renderSize: CGSize,
        outputType: UTType,
        exportDescription: String
    ) -> [CFString: Any] {

        var properties = sourceProperties
        ImageIOStillImageMetadataCleanup
            .removeInheritedLivePhotoMetadata(
                from: &properties
            )

        let pixelWidth = Int(renderSize.width)
        let pixelHeight = Int(renderSize.height)

        properties[kCGImagePropertyPixelWidth] =
            pixelWidth
        properties[kCGImagePropertyPixelHeight] =
            pixelHeight

        properties[kCGImagePropertyOrientation] = 1

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

        if !exportDescription.isEmpty {
            // Reserve enough UTF-16 storage for the in-place JPEG Unicode patch.
            // The writer reports failure if that patch cannot replace this placeholder.
            exif[
                "UserComment" as CFString
            ] = outputType.conforms(to: .jpeg)
                && exportDescription.unicodeScalars.contains(where: { $0.value > 0x7F })
                ? String(repeating: "\u{FFFD}", count: exportDescription.utf16.count)
                : exportDescription
        }

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

        if !exportDescription.isEmpty {
            tiff[
                kCGImagePropertyTIFFImageDescription
            ] = exportDescription
        }

        properties[
            kCGImagePropertyTIFFDictionary
        ] = tiff

        if !exportDescription.isEmpty {

            var iptc =
                properties[
                    kCGImagePropertyIPTCDictionary
                ] as? [CFString: Any] ?? [:]

            iptc[
                kCGImagePropertyIPTCCaptionAbstract
            ] = exportDescription

            properties[
                kCGImagePropertyIPTCDictionary
            ] = iptc
        }

        if outputType.conforms(
            to: .png
        ),
           !exportDescription.isEmpty {

            var png =
                properties[
                    kCGImagePropertyPNGDictionary
                ] as? [CFString: Any] ?? [:]

            png[
                kCGImagePropertyPNGDescription
            ] = exportDescription

            properties[
                kCGImagePropertyPNGDictionary
            ] = png
        }

        return properties
    }

    private func applyFileDates(
        to url: URL,
        captureDate: Date?
    ) {

        guard let captureDate else {
            return
        }

        try? FileManager.default.setAttributes(
            [
                .creationDate: captureDate,
                .modificationDate: captureDate
            ],
            ofItemAtPath: url.path
        )
    }
}
