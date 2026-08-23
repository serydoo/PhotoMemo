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

        if let floatingArtifact = try presentationPlanner.floatingArtifact(
            for: card,
            canvasSize: renderSize
        ) {
            guard let sourceImage = sourcePhotoCGImage(for: photo) else {
                throw RecordCardExportError.renderFailed
            }
            guard let cgImage = PhotoMemoRenderedImageArtifactGuard.composingSourcePhoto(
                sourceImage,
                with: floatingArtifact
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

        let content = presentationPlanner.content(
            for: card,
            image: photo.image.swiftUIImage
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
            if let sourceCGImage = sourcePhotoCGImage(for: photo) {
                PhotoMemoRenderedImageArtifactGuard
                    .replacingPhotoArea(
                        in: renderedCGImage,
                        with: sourceCGImage,
                        photoHeight: photoAreaHeight
                    )
            } else {
                renderedCGImage
            }
        let cgImage =
            PhotoMemoRenderedImageArtifactGuard
            .removingLeftPhotoEdgeArtifact(
                from: preservedPhotoCGImage,
                photoHeight: photoAreaHeight
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

    func renderLivePhotoOverlay(
        photo: SelectedPhoto,
        card: RecordCard
    ) throws -> FixedFooterOverlayDescriptor {
        let renderSize = presentationPlanner.outputPixelSize(
            for: card,
            fallbackSize: photo.image.photoMemoSize
        )
        if let floatingArtifact = try presentationPlanner.floatingArtifact(
            for: card,
            canvasSize: renderSize
        ) {
            return floatingArtifact
        }

        let renderedFileURL = try temporaryIntermediateURL(for: photo)
        defer {
            try? FileManager.default.removeItem(at: renderedFileURL)
        }

        _ = try export(
            photo: photo,
            card: card,
            to: renderedFileURL
        )
        guard let renderedImage = renderedCGImage(at: renderedFileURL) else {
            throw RecordCardExportError.renderFailed
        }

        let sourcePhotoSize = CGSize(
            width: CGFloat(
                photo.metadata.imageWidth
                ?? Int(photo.image.photoMemoSize.width)
            ),
            height: CGFloat(
                photo.metadata.imageHeight
                ?? Int(photo.image.photoMemoSize.height)
            )
        )

        return try LivePhotoRenderOutputGeometry.overlayDescriptor(
            renderedOutputImage: renderedImage,
            sourcePhotoPixelSize: sourcePhotoSize
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

    private func temporaryIntermediateURL(
        for photo: SelectedPhoto
    ) throws -> URL {
        let folderURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("MemoMarkLivePhotoOverlays", isDirectory: true)
        try FileManager.default.createDirectory(
            at: folderURL,
            withIntermediateDirectories: true
        )
        return folderURL.appendingPathComponent(
            UUID().uuidString
        ).appendingPathExtension("jpg")
    }

    private func renderedCGImage(at fileURL: URL) -> CGImage? {
        guard let source = CGImageSourceCreateWithURL(
            fileURL as CFURL,
            [kCGImageSourceShouldCache: false] as CFDictionary
        ) else {
            return nil
        }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }

}
