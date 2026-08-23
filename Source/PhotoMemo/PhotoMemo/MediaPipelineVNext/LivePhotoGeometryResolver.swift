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
            try overlay.validatedForEncoder()

        // The prepared artifact is the canonical presentation geometry. In
        // particular, same-canvas renderers own the complete canvas; do not
        // ask the legacy media resolver to append a footer a second time.
        let canvas = CanvasGeometry(
            canvasSize: preparedOverlay.canvasSize,
            photoFrame: preparedOverlay.photoFrame,
            footerFrame: preparedOverlay.footerFrame
        )

        return CanonicalGeometry(
            facts:
                mediaGeometry
                .facts,
                canvas: canvas
        )
    }
}
