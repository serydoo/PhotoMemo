import SwiftUI
import AppKit
import ImageIO
import UniformTypeIdentifiers

enum RecordCardExportError: LocalizedError {

    case saveCancelled

    case renderFailed

    case destinationCreateFailed

    case writeFailed

    var errorDescription: String? {

        switch self {

        case .saveCancelled:
            return "Export was cancelled."

        case .renderFailed:
            return "Unable to render the final image."

        case .destinationCreateFailed:
            return "Unable to create the export file."

        case .writeFailed:
            return "Unable to save the exported image."
        }
    }
}

@MainActor
final class RecordCardExportService {

    func export(
        photo: SelectedPhoto,
        card: RecordCard
    ) throws -> URL {

        let saveURL = try chooseSaveURL(
            for: photo
        )

        let renderSize =
            outputPixelSize(for: photo)

        let content = RecordCardRenderer(
            image: Image(nsImage: photo.image),
            card: card
        )
        .frame(
            width: renderSize.width,
            height: renderSize.height
        )

        let renderer =
            ImageRenderer(content: content)

        renderer.scale = 1
        renderer.proposedSize = .init(renderSize)
        renderer.isOpaque = true

        guard let cgImage = renderer.cgImage else {
            throw RecordCardExportError.renderFailed
        }

        let type =
            outputType(for: saveURL)

        guard let destination =
            CGImageDestinationCreateWithURL(
                saveURL as CFURL,
                type.identifier as CFString,
                1,
                nil
            )
        else {
            throw RecordCardExportError.destinationCreateFailed
        }

        let properties =
            sanitizedMetadata(
                from: photo.sourceProperties,
                renderSize: renderSize,
                outputType: type,
                card: card
            )

        CGImageDestinationAddImage(
            destination,
            cgImage,
            properties as CFDictionary
        )

        guard CGImageDestinationFinalize(destination) else {
            throw RecordCardExportError.writeFailed
        }

        applyFileDates(
            to: saveURL,
            captureDate: photo.metadata.captureDate
        )

        return saveURL
    }
}

private extension RecordCardExportService {

    func chooseSaveURL(
        for photo: SelectedPhoto
    ) throws -> URL {

        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false
        panel.allowedContentTypes = [
            .jpeg,
            .png,
            .heic
        ]
        panel.nameFieldStringValue =
            defaultFileName(for: photo)

        let response = panel.runModal()

        guard response == .OK,
              let url = panel.url else {
            throw RecordCardExportError.saveCancelled
        }

        return url
    }

    func defaultFileName(
        for photo: SelectedPhoto
    ) -> String {

        let baseName =
            photo.sourceURL.deletingPathExtension()
            .lastPathComponent

        return baseName + "_PhotoMemo.jpg"
    }

    func outputType(
        for url: URL
    ) -> UTType {

        UTType(
            filenameExtension:
                url.pathExtension.lowercased()
        ) ?? .jpeg
    }

    func outputPixelSize(
        for photo: SelectedPhoto
    ) -> CGSize {

        let width =
            CGFloat(
                photo.metadata.imageWidth
                ?? Int(photo.image.size.width)
            )

        let imageHeight =
            CGFloat(
                photo.metadata.imageHeight
                ?? Int(photo.image.size.height)
            )

        let orientation:
            ClassicWhiteRenderer.CardOrientation =
            width >= imageHeight
            ? .landscape
            : .portrait

        let layout =
            ClassicWhiteRenderer.layout(
                for: orientation
            )

        return CGSize(
            width: width,
            height:
                imageHeight
                * (1 + layout.borderToImageHeightRatio)
        )
    }

    func sanitizedMetadata(
        from sourceProperties: [CFString: Any],
        renderSize: CGSize,
        outputType: UTType,
        card: RecordCard
    ) -> [CFString: Any] {

        var properties = sourceProperties

        let pixelWidth = Int(renderSize.width)
        let pixelHeight = Int(renderSize.height)
        let exportDescription =
            CardVariableProvider.exportDescription(
                from: card
            )

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
            exif[
                "UserComment" as CFString
            ] = exportDescription
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
        ] = "PhotoMemo"

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

    func applyFileDates(
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
