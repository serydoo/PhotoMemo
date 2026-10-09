import Foundation
import ImageIO
import UniformTypeIdentifiers
#if DEBUG
import CoreImage
#endif

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

        return try finishWrittenImage(at: url, type: type,
                                      exportDescription: exportDescription, captureDate: captureDate)
    }

#if DEBUG
    // Experimental CPU file path; full-size pixels are file-backed, with only strip buffers owned in memory.
    // This is not selected by the normal app export pipeline.
    @MainActor private lazy var cpuJPEGContext = CIContext(options: [.useSoftwareRenderer: true, .cacheIntermediates: false, .memoryTarget: 32])

    @MainActor
    func renderCPURegion(image: CIImage, bounds: CGRect) -> CGImage? {
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }
        let result = cpuJPEGContext.createCGImage(image, from: bounds, format: .RGBA8, colorSpace: colorSpace)
        cpuJPEGContext.clearCaches()
        return result
    }

    @MainActor
    func withCPUMappedRaster(image: CIImage, to url: URL,
                            encode: (CGImage) throws -> URL) throws -> URL {
        try CPUFileRasterExport.withMappedRaster(image: image, context: cpuJPEGContext,
            to: url, encode: encode)
    }

    @MainActor
    func writeCPUJPEG(image: CIImage, to url: URL, sourceProperties: [CFString: Any],
                      exportDescription: String, captureDate: Date?) throws -> URL {
        guard outputType(for: url).conforms(to: .jpeg),
              image.extent.width > 0, image.extent.height > 0,
              image.extent.width.isFinite, image.extent.height.isFinite,
              CGColorSpace(name: CGColorSpace.sRGB) != nil else {
            throw RecordCardExportError.writeFailed
        }
        return try CPUFileRasterExport.writeJPEG(image: image, context: cpuJPEGContext, to: url,
            sourceProperties: sourceProperties, exportDescription: exportDescription,
            captureDate: captureDate, writer: self)
    }
#endif

    private func finishWrittenImage(at url: URL, type: UTType,
                                    exportDescription: String, captureDate: Date?) throws -> URL {
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
