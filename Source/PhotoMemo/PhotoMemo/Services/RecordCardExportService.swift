import SwiftUI
import ImageIO
import UniformTypeIdentifiers
#if os(macOS)
import AppKit
#endif

enum RecordCardExportError: LocalizedError {

    case saveCancelled

    case renderFailed

    case destinationCreateFailed

    case writeFailed

    case temporaryFileCreateFailed

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

        case .temporaryFileCreateFailed:
            return "Unable to prepare the temporary export file."
        }
    }
}

@MainActor
final class RecordCardExportService {

    func export(
        photo: SelectedPhoto,
        card: RecordCard
    ) throws -> URL {

#if os(macOS)
        let saveURL = try chooseSaveURL(
            for: photo
        )

        return try export(
            photo: photo,
            card: card,
            to: saveURL
        )
#else
        return try exportToTemporaryFile(
            photo: photo,
            card: card
        )
#endif
    }

    func exportToTemporaryFile(
        photo: SelectedPhoto,
        card: RecordCard
    ) throws -> URL {

        let folderURL =
            FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "PhotoMemoExports",
                isDirectory: true
            )

        do {

            try FileManager.default.createDirectory(
                at: folderURL,
                withIntermediateDirectories: true
            )

        } catch {

            throw RecordCardExportError
                .temporaryFileCreateFailed
        }

        let fileURL =
            uniqueTemporaryURL(
                in: folderURL,
                for: photo
            )

        return try export(
            photo: photo,
            card: card,
            to: fileURL
        )
    }
}

private extension RecordCardExportService {

    func export(
        photo: SelectedPhoto,
        card: RecordCard,
        to saveURL: URL
    ) throws -> URL {

        let resolvedSaveURL =
            uniqueOutputURL(for: saveURL)

        let renderSize =
            outputPixelSize(
                for: photo,
                template: card.template
            )

        let content = RecordCardRenderer(
            image: photo.image.swiftUIImage,
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

        let actualRenderSize = CGSize(
            width: cgImage.width,
            height: cgImage.height
        )

        let type =
            outputType(for: resolvedSaveURL)

        guard let destination =
            CGImageDestinationCreateWithURL(
                resolvedSaveURL as CFURL,
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
                renderSize: actualRenderSize,
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
            to: resolvedSaveURL,
            captureDate: photo.metadata.captureDate
        )

        return resolvedSaveURL
    }

#if os(macOS)
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
#endif

    func defaultFileName(
        for photo: SelectedPhoto
    ) -> String {

        let baseName =
            photo.sourceURL.deletingPathExtension()
            .lastPathComponent

        return baseName + "_PhotoMemo.jpg"
    }

    func uniqueTemporaryURL(
        in folderURL: URL,
        for photo: SelectedPhoto
    ) -> URL {

        let baseName =
            photo.sourceURL
            .deletingPathExtension()
            .lastPathComponent

        let formatter =
            ISO8601DateFormatter()

        formatter.formatOptions = [
            .withInternetDateTime,
            .withDashSeparatorInDate,
            .withColonSeparatorInTime,
            .withFractionalSeconds
        ]

        let timestamp =
            formatter.string(from: Date())
            .replacingOccurrences(
                of: ":",
                with: "-"
            )

        return folderURL.appendingPathComponent(
            "\(baseName)_PhotoMemo_\(timestamp).jpg"
        )
    }

    func uniqueOutputURL(
        for url: URL
    ) -> URL {

        guard FileManager.default.fileExists(
            atPath: url.path
        ) else {
            return url
        }

        let folderURL =
            url.deletingLastPathComponent()
        let baseName =
            url.deletingPathExtension()
            .lastPathComponent
        let pathExtension =
            url.pathExtension

        var index = 1

        while true {

            let candidateURL =
                folderURL.appendingPathComponent(
                    "\(baseName) (\(index))"
                )
                .appendingPathExtension(
                    pathExtension
                )

            if !FileManager.default.fileExists(
                atPath: candidateURL.path
            ) {
                return candidateURL
            }

            index += 1
        }
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
        for photo: SelectedPhoto,
        template: Template
    ) -> CGSize {

        if template.preset == .immersWhite {

            return ImmersWhiteRenderer
                .outputPixelSize(
                    for: photo.metadata,
                    fallbackSize:
                        photo.image.photoMemoSize
                )
        }

        let width =
            CGFloat(
                photo.metadata.imageWidth
                ?? Int(photo.image.photoMemoSize.width)
            )

        let imageHeight =
            CGFloat(
                photo.metadata.imageHeight
                ?? Int(photo.image.photoMemoSize.height)
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
