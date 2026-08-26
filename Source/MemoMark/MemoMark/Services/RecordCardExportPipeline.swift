import Foundation
import SwiftUI
import ImageIO
import CoreGraphics

@MainActor
final class RecordCardExportPipeline {

    private let namingResolver: OutputFileNamingResolver

    private let imageWriter: MetadataPreservingImageWriter
    private let presentationPlanner = RecordCardPresentationPlanner()

    init(
        namingResolver: OutputFileNamingResolver
    ) {
        self.namingResolver = namingResolver
        self.imageWriter =
            MetadataPreservingImageWriter()
    }

    func export(
        photo: SelectedPhoto,
        card: RecordCard,
        to saveURL: URL
    ) throws -> URL {

        let resolvedSaveURL =
            namingResolver.uniqueOutputURL(
                for: saveURL
            )

        let renderSize =
            presentationPlanner.outputPixelSize(
                for: card,
                fallbackSize:
                    photo.image.photoMemoSize
            )

        let artifact = try presentationPlanner.artifact(
            for: card,
            canvasSize: renderSize
        )
        guard let sourceImage = sourcePhotoCGImage(for: photo) else {
            throw RecordCardExportError.renderFailed
        }
        guard let cgImage = MemoMarkRenderedImageArtifactGuard.composingSourcePhoto(
            sourceImage,
            with: artifact
        ) else {
            throw RecordCardExportError.renderFailed
        }
        let exportDescription = CardVariableProvider.exportDescription(from: card)
        return try imageWriter.write(
            cgImage: cgImage,
            to: resolvedSaveURL,
            sourceProperties: photo.sourceProperties,
            exportDescription: exportDescription,
            captureDate: photo.metadata.captureDate
        )
    }

    func renderLivePhotoOverlay(
        photo: SelectedPhoto,
        card: RecordCard
    ) throws -> FixedFooterOverlayDescriptor {
        let renderSize = presentationPlanner.outputPixelSize(
            for: card,
            fallbackSize: photo.image.photoMemoSize
        )
        return try presentationPlanner.artifact(
            for: card,
            canvasSize: renderSize
        )
    }

    private func sourcePhotoCGImage(
        for photo: SelectedPhoto
    ) -> CGImage? {

        imageIOExportImage(from: photo)
            ?? photo.image.photoMemoExportCGImage
    }

    private func imageIOExportImage(
        from photo: SelectedPhoto
    ) -> CGImage? {

        let accessGranted =
            photo.sourceURL
            .startAccessingSecurityScopedResource()
        defer {
            if accessGranted {
                photo.sourceURL
                    .stopAccessingSecurityScopedResource()
            }
        }

        guard let source =
            CGImageSourceCreateWithURL(
                photo.sourceURL as CFURL,
                [
                    kCGImageSourceShouldCache:
                        false
                ] as CFDictionary
            )
        else {
            return nil
        }

        let maxPixelSize =
            max(
                photo.metadata.imageWidth ?? 0,
                photo.metadata.imageHeight ?? 0,
                Int(photo.image.photoMemoSize.width),
                Int(photo.image.photoMemoSize.height),
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
    }

}
