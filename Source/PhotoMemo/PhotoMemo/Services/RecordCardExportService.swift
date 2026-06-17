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
                from: photo.sourceURL
            )

        CGImageDestinationAddImage(
            destination,
            cgImage,
            properties as CFDictionary
        )

        guard CGImageDestinationFinalize(destination) else {
            throw RecordCardExportError.writeFailed
        }

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
        from sourceURL: URL
    ) -> [CFString: Any] {

        guard
            let source =
                CGImageSourceCreateWithURL(
                    sourceURL as CFURL,
                    nil
                ),
            let sourceProperties =
                CGImageSourceCopyPropertiesAtIndex(
                    source,
                    0,
                    nil
                ) as? [CFString: Any]
        else {
            return [:]
        }

        var properties = sourceProperties

        properties.removeValue(
            forKey: kCGImagePropertyPixelWidth
        )
        properties.removeValue(
            forKey: kCGImagePropertyPixelHeight
        )
        properties[kCGImagePropertyOrientation] = 1

        return properties
    }
}
