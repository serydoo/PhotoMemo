import Foundation
import UniformTypeIdentifiers
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

#if os(iOS) && DEBUG && MEMOMARK_SHARE_EXTENSION
        MemoMarkBackgroundProbe.record("extension.export.beforeArtifact", detail: "width=\(Int(renderSize.width)) height=\(Int(renderSize.height))")
#endif
        let artifact = try presentationPlanner.artifact(
            for: card,
            canvasSize: renderSize
        )
#if os(iOS) && DEBUG && MEMOMARK_SHARE_EXTENSION
        MemoMarkBackgroundProbe.record("extension.export.artifactReady")
        if UTType(filenameExtension: resolvedSaveURL.pathExtension)?.conforms(to: .jpeg) == true {
            return try CPUStillImageExportExperiment.export(photo: photo, artifact: artifact,
                to: resolvedSaveURL, writer: imageWriter,
                exportDescription: CardVariableProvider.exportDescription(from: card))
        }
#endif
        guard let sourceImage = sourcePhotoCGImage(for: photo) else {
            throw RecordCardExportError.renderFailed
        }
#if os(iOS) && DEBUG && MEMOMARK_SHARE_EXTENSION
        MemoMarkBackgroundProbe.record("extension.export.sourceDecoded")
#endif
        guard let cgImage = MemoMarkRenderedImageArtifactGuard.composingSourcePhotoWithMaterial(
            sourceImage,
            with: artifact
        ) else {
            throw RecordCardExportError.renderFailed
        }
#if os(iOS) && DEBUG && MEMOMARK_SHARE_EXTENSION
        MemoMarkBackgroundProbe.record("extension.export.compositionReady")
#endif
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
        card: RecordCard,
        allowsNativeBackdrop: Bool = true
    ) throws -> FixedFooterOverlayDescriptor {
        let renderSize = presentationPlanner.outputPixelSize(
            for: card,
            fallbackSize: photo.image.photoMemoSize
        )
        return try presentationPlanner.artifact(
            for: card,
            canvasSize: renderSize,
            allowsNativeBackdrop: allowsNativeBackdrop
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

#if os(iOS) && DEBUG && MEMOMARK_SHARE_EXTENSION
        // The full-size thumbnail path eagerly allocates a transformed raster.
        // An upright source can remain deferred; rotated input retains the
        // established transform path until separately verified.
        let orientation = (CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any])?[kCGImagePropertyOrientation] as? Int ?? 1
        if orientation == 1,
           let image = CGImageSourceCreateImageAtIndex(source, 0,
               [kCGImageSourceShouldCache: false,
                kCGImageSourceShouldCacheImmediately: false] as CFDictionary) {
            MemoMarkBackgroundProbe.record("extension.export.deferredUprightSource")
            return image
        }
#endif
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
