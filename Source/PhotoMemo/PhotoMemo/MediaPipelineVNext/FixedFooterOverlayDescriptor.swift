import CoreGraphics

struct FixedFooterOverlayDescriptor {

    let canvasSize: CGSize
    let photoFrame: CGRect
    let footerFrame: CGRect
    let footerImage: CGImage

    init(
        canvasSize: CGSize,
        photoFrame: CGRect,
        footerFrame: CGRect,
        footerImage: CGImage
    ) throws {
        guard
            canvasSize.width > 0,
            canvasSize.height > 0,
            photoFrame.width > 0,
            photoFrame.height > 0,
            footerFrame.width > 0,
            footerFrame.height > 0
        else {
            throw LivePhotoVideoCompositionError.invalidOverlayGeometry
        }

        let canvasBounds = CGRect(origin: .zero, size: canvasSize)

        guard
            canvasBounds.contains(photoFrame),
            canvasBounds.contains(footerFrame),
            photoFrame.minY >= footerFrame.maxY
        else {
            throw LivePhotoVideoCompositionError.invalidOverlayGeometry
        }

        self.canvasSize = canvasSize
        self.photoFrame = photoFrame
        self.footerFrame = footerFrame
        self.footerImage = footerImage
    }
}

extension FixedFooterOverlayDescriptor {

    func normalizedForEncoder() throws -> FixedFooterOverlayDescriptor {
        let normalizedCanvasWidth =
            Self.normalizedEncoderDimension(
                canvasSize.width
            )
        let normalizedCanvasHeight =
            Self.normalizedEncoderDimension(
                canvasSize.height
            )
        let normalizedPhotoWidth =
            min(
                Self.normalizedEncoderDimension(
                    photoFrame.width
                ),
                normalizedCanvasWidth
            )
        let normalizedPhotoHeight =
            min(
                Self.normalizedEncoderDimension(
                    photoFrame.height
                ),
                normalizedCanvasHeight
            )
        let normalizedFooterHeight =
            max(
                normalizedCanvasHeight
                - normalizedPhotoHeight,
                2
            )

        return try FixedFooterOverlayDescriptor(
            canvasSize: CGSize(
                width: normalizedCanvasWidth,
                height: normalizedCanvasHeight
            ),
            photoFrame: CGRect(
                x: 0,
                y: normalizedFooterHeight,
                width: normalizedPhotoWidth,
                height: normalizedPhotoHeight
            ),
            footerFrame: CGRect(
                x: 0,
                y: 0,
                width: normalizedCanvasWidth,
                height: normalizedFooterHeight
            ),
            footerImage: footerImage
        )
    }

    static func normalizedEncoderDimension(
        _ value: CGFloat
    ) -> CGFloat {
        let integerValue =
            max(
                Int(floor(value)),
                2
            )

        return CGFloat(
            integerValue - (integerValue % 2)
        )
    }
}
