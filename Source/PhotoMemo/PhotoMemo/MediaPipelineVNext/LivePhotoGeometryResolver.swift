import Foundation
import UniformTypeIdentifiers

protocol LivePhotoGeometryResolving {

    func resolveGeometry(
        sourceStillURL: URL,
        overlay: FixedFooterOverlayDescriptor,
        outputStillType: UTType
    ) throws -> CanonicalGeometry
}

struct LivePhotoGeometryResolver:
    LivePhotoGeometryResolving,
    Sendable {

    private let mediaGeometryResolver:
        MediaGeometryResolver

    init(
        mediaGeometryResolver:
            MediaGeometryResolver = .standard
    ) {
        self.mediaGeometryResolver =
            mediaGeometryResolver
    }

    func resolveGeometry(
        sourceStillURL: URL,
        overlay: FixedFooterOverlayDescriptor,
        outputStillType: UTType
    ) throws -> CanonicalGeometry {
        let mediaGeometry =
            try mediaGeometryResolver.resolve(
            fileURL:
                sourceStillURL,
            contentType:
                outputStillType
        )
        let preparedOverlay =
            try overlay.normalizedForEncoder()

        return CanonicalGeometry(
            facts:
                mediaGeometry
                .facts,
            canvas:
                CanvasGeometry(
                    canvasSize:
                        preparedOverlay
                        .canvasSize,
                    photoFrame:
                        preparedOverlay
                        .photoFrame,
                    footerFrame:
                        preparedOverlay
                        .footerFrame
                )
        )
    }
}
