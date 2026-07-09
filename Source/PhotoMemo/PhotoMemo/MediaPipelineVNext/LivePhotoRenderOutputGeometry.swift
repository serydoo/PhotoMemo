import CoreGraphics
import Foundation

struct LivePhotoRenderOutputGeometry:
    Equatable,
    Sendable {

    let canvasSize: CGSize
    let photoFrame: CGRect
    let footerFrame: CGRect

    static func resolved(
        renderedPixelSize: CGSize,
        sourcePhotoPixelSize: CGSize
    ) throws -> LivePhotoRenderOutputGeometry {
        guard
            renderedPixelSize.width > 0,
            renderedPixelSize.height > 0,
            sourcePhotoPixelSize.width > 0,
            sourcePhotoPixelSize.height > 0,
            renderedPixelSize.height
                > sourcePhotoPixelSize.height
        else {
            throw LivePhotoRenderOutputGeometryError
                .invalidRenderedOutputGeometry
        }

        return try resolved(
            renderedPixelSize: renderedPixelSize,
            footerHeight:
                renderedPixelSize.height
                - sourcePhotoPixelSize.height
        )
    }

    static func resolved(
        renderedPixelSize: CGSize,
        footerHeight: CGFloat
    ) throws -> LivePhotoRenderOutputGeometry {
        guard
            renderedPixelSize.width > 0,
            renderedPixelSize.height > 0,
            footerHeight > 0,
            footerHeight < renderedPixelSize.height
        else {
            throw LivePhotoRenderOutputGeometryError
                .invalidRenderedOutputGeometry
        }

        let photoHeight =
            renderedPixelSize.height
            - footerHeight

        return LivePhotoRenderOutputGeometry(
            canvasSize: renderedPixelSize,
            photoFrame: CGRect(
                x: 0,
                y: footerHeight,
                width: renderedPixelSize.width,
                height: photoHeight
            ),
            footerFrame: CGRect(
                x: 0,
                y: 0,
                width: renderedPixelSize.width,
                height: footerHeight
            )
        )
    }

    static func overlayDescriptor(
        renderedOutputImage: CGImage,
        footerHeight: CGFloat
    ) throws -> FixedFooterOverlayDescriptor {
        let geometry =
            try resolved(
                renderedPixelSize: CGSize(
                    width: renderedOutputImage.width,
                    height: renderedOutputImage.height
                ),
                footerHeight:
                    footerHeight
            )
        let cropRect =
            CGRect(
                x: 0,
                y: geometry.photoFrame.height,
                width: geometry.footerFrame.width,
                height: geometry.footerFrame.height
            )

        guard
            let footerImage =
                renderedOutputImage.cropping(
                    to: cropRect
                )
        else {
            throw LivePhotoRenderOutputGeometryError
                .footerCropFailed
        }

        return try FixedFooterOverlayDescriptor(
            canvasSize: geometry.canvasSize,
            photoFrame: geometry.photoFrame,
            footerFrame: geometry.footerFrame,
            footerImage: footerImage
        )
    }

    static func overlayDescriptor(
        renderedOutputImage: CGImage,
        sourcePhotoPixelSize: CGSize
    ) throws -> FixedFooterOverlayDescriptor {
        try overlayDescriptor(
            renderedOutputImage: renderedOutputImage,
            footerHeight:
                CGFloat(renderedOutputImage.height)
                - sourcePhotoPixelSize.height
        )
    }
}

enum LivePhotoRenderOutputGeometryError:
    LocalizedError,
    Equatable {
    case invalidRenderedOutputGeometry
    case footerCropFailed

    var errorDescription: String? {
        switch self {
        case .invalidRenderedOutputGeometry:
            return "The rendered MemoMark output does not contain a valid photo area plus footer area."
        case .footerCropFailed:
            return "Unable to extract the rendered MemoMark footer from the output image."
        }
    }
}
