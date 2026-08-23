import CoreGraphics

/// Pixel rules shared by every presentation style and every media route.
///
/// Layout decides the final canvas once. Still-image and paired-video
/// composers only validate and consume that result; they must not round or
/// otherwise rewrite it.
enum PresentationPixelGeometry {

    static func encoderSafeDimension(_ value: CGFloat) -> CGFloat {
        let integerValue = max(Int(ceil(value)), 2)
        return CGFloat(integerValue + (integerValue % 2))
    }

    static func encoderSafeSize(_ size: CGSize) -> CGSize {
        CGSize(
            width: encoderSafeDimension(size.width),
            height: encoderSafeDimension(size.height)
        )
    }

    static func appendedCanvas(
        sourceSize: CGSize,
        requestedFooterHeight: CGFloat
    ) -> (canvasSize: CGSize, photoFrame: CGRect, footerFrame: CGRect) {
        let sourceWidth = encoderSafeDimension(sourceSize.width)
        let sourceHeight = max(ceil(sourceSize.height), 1)
        let footerHeight = max(ceil(requestedFooterHeight), 2)
        let canvasHeight = encoderSafeDimension(sourceHeight + footerHeight)
        let resolvedFooterHeight = canvasHeight - sourceHeight
        let canvasSize = CGSize(width: sourceWidth, height: canvasHeight)

        return (
            canvasSize: canvasSize,
            photoFrame: CGRect(
                x: 0,
                y: resolvedFooterHeight,
                width: sourceWidth,
                height: sourceHeight
            ),
            footerFrame: CGRect(
                x: 0,
                y: 0,
                width: sourceWidth,
                height: resolvedFooterHeight
            )
        )
    }
}
