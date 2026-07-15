import Foundation
import SwiftUI
import ImageIO

@MainActor
final class RecordCardExportPipeline {

    private let namingResolver: OutputFileNamingResolver

    private let imageWriter: MetadataPreservingImageWriter

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

        guard let renderedCGImage = renderer.cgImage else {
            throw RecordCardExportError.renderFailed
        }

        let photoAreaHeight =
            Int(
                photo.metadata.imageHeight
                ?? renderedCGImage.height
            )
        let preservedPhotoCGImage =
            if let sourceCGImage =
                sourcePhotoCGImage(for: photo) {
                PhotoMemoRenderedImageArtifactGuard
                    .replacingPhotoArea(
                        in: renderedCGImage,
                        with: sourceCGImage,
                        photoHeight:
                            photoAreaHeight
                    )
            } else {
                renderedCGImage
            }
        let cgImage =
            PhotoMemoRenderedImageArtifactGuard
            .removingLeftPhotoEdgeArtifact(
                from: preservedPhotoCGImage,
                photoHeight:
                    photoAreaHeight
            )

        let exportDescription =
            CardVariableProvider
            .exportDescription(
                from: card
            )

        return try imageWriter.write(
            cgImage: cgImage,
            to: resolvedSaveURL,
            sourceProperties:
                photo.sourceProperties,
            exportDescription:
                exportDescription,
            captureDate:
                photo.metadata.captureDate
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

    private func outputPixelSize(
        for photo: SelectedPhoto,
        template: Template
    ) -> CGSize {

        ClassicWhiteRenderer
            .outputPixelSize(
                for: photo.metadata,
                fallbackSize:
                    photo.image.photoMemoSize
            )
    }
}
