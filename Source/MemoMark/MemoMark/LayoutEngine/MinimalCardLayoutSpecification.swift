import CoreGraphics
import Foundation

enum MinimalCardLayoutSpecification {

    enum Orientation {
        case landscape
        case portrait
    }

    struct Layout {
        let barHeightToImageWidth: CGFloat
        let trailingAnchorX: CGFloat
        let maximumModuleWidth: CGFloat
        let capsuleHorizontalInset: CGFloat
        let capsuleHeightToBarHeight: CGFloat
        let capsuleHorizontalPaddingToBarHeight: CGFloat
        let capsuleVerticalPaddingToBarHeight: CGFloat
        let overlayBottomInsetToImageWidth: CGFloat
        let textLineLimit: Int
        let textSizeToBarHeight: CGFloat
        let logoSizeToBarHeight: CGFloat
        let moduleSpacingToBarHeight: CGFloat
        let avatarLeadingInsetToBarHeight: CGFloat
        let avatarAreaWidthToBarHeight: CGFloat
        let avatarSizeToBarHeight: CGFloat
        let avatarTextSpacingToBarHeight: CGFloat

        /// Minimal preserves the complete source photo and places an opaque
        /// information capsule inside the same canvas. The former appended
        /// bottom-bar representation is no longer the Minimal contract.
        var outputAddsBottomBar: Bool { false }
    }

    struct CompactPreview {
        let imageSliceHeightToWidth: CGFloat
        let moduleWidthToWidth: CGFloat
    }

    static let compactPreview = CompactPreview(
        imageSliceHeightToWidth: 0.20625,
        moduleWidthToWidth: 0.68
    )

    static func orientation(
        imageWidth: Int,
        imageHeight: Int
    ) -> Orientation {
        imageWidth >= imageHeight ? .landscape : .portrait
    }

    static func layout(for orientation: Orientation) -> Layout {
        switch orientation {
        case .landscape:
            return Layout(
                barHeightToImageWidth: 0.075,
                trailingAnchorX: 0.95,
                maximumModuleWidth: 0.62,
                capsuleHorizontalInset: 0.028,
                capsuleHeightToBarHeight: 0.90,
                capsuleHorizontalPaddingToBarHeight: 0.50,
                capsuleVerticalPaddingToBarHeight: 0.00,
                overlayBottomInsetToImageWidth: 0.014,
                textLineLimit: 1,
                textSizeToBarHeight: 0.38,
                logoSizeToBarHeight: 0.32,
                moduleSpacingToBarHeight: 0.18,
                avatarLeadingInsetToBarHeight: 0.08,
                avatarAreaWidthToBarHeight: 0.92,
                avatarSizeToBarHeight: 0.78,
                avatarTextSpacingToBarHeight: 0.20
            )
        case .portrait:
            return Layout(
                barHeightToImageWidth: 0.095,
                trailingAnchorX: 0.94,
                maximumModuleWidth: 0.82,
                capsuleHorizontalInset: 0.032,
                capsuleHeightToBarHeight: 0.92,
                capsuleHorizontalPaddingToBarHeight: 0.50,
                capsuleVerticalPaddingToBarHeight: 0.00,
                overlayBottomInsetToImageWidth: 0.014,
                textLineLimit: 2,
                textSizeToBarHeight: 0.31,
                logoSizeToBarHeight: 0.34,
                moduleSpacingToBarHeight: 0.16,
                avatarLeadingInsetToBarHeight: 0.08,
                avatarAreaWidthToBarHeight: 0.92,
                avatarSizeToBarHeight: 0.78,
                avatarTextSpacingToBarHeight: 0.20
            )
        }
    }

    static func outputPixelSize(
        imageWidth: Int,
        imageHeight: Int
    ) -> CGSize {
        let geometry = outputGeometry(
            imageWidth: imageWidth,
            imageHeight: imageHeight
        )
        return geometry.canvasSize
    }

    static func outputGeometry(
        imageWidth: Int,
        imageHeight: Int
    ) -> (canvasSize: CGSize, photoFrame: CGRect, footerFrame: CGRect) {
        let sourceSize = CGSize(
            width: max(imageWidth, 1),
            height: max(imageHeight, 1)
        )
        let canvasSize = PresentationPixelGeometry.encoderSafeSize(sourceSize)
        return (
            canvasSize: canvasSize,
            photoFrame: CGRect(origin: .zero, size: canvasSize),
            footerFrame: .zero
        )
    }

    static func floatingModuleFrame(
        imageWidth: Int,
        imageHeight: Int
    ) -> CGRect {
        let geometry = outputGeometry(
            imageWidth: imageWidth,
            imageHeight: imageHeight
        )
        let layout = layout(
            for: orientation(
                imageWidth: imageWidth,
                imageHeight: imageHeight
            )
        )
        let moduleWidth = min(
            PresentationPixelGeometry.encoderSafeDimension(
                geometry.canvasSize.width * layout.maximumModuleWidth
            ),
            geometry.canvasSize.width
        )
        let moduleHeight = min(
            CGFloat(
                barHeightPixels(
                    imageWidth: imageWidth,
                    imageHeight: imageHeight
                )
            ),
            geometry.canvasSize.height
        )
        let targetTrailingEdge = min(
            max(
                round(geometry.canvasSize.width * layout.trailingAnchorX),
                moduleWidth
            ),
            geometry.canvasSize.width
        )
        let x = min(
            max(targetTrailingEdge - moduleWidth, 0),
            geometry.canvasSize.width - moduleWidth
        )
        let bottomInset = min(
            max(
                round(
                    geometry.canvasSize.width
                    * layout.overlayBottomInsetToImageWidth
                ),
                0
            ),
            geometry.canvasSize.height - moduleHeight
        )

        return CGRect(
            x: x,
            y: bottomInset,
            width: moduleWidth,
            height: moduleHeight
        )
    }

    static func barHeightPixels(
        imageWidth: Int,
        imageHeight: Int
    ) -> Int {
        let width = max(
            Int(
                PresentationPixelGeometry.encoderSafeDimension(
                    CGFloat(max(imageWidth, 1))
                )
            ),
            1
        )
        let height = max(imageHeight, 1)
        let layout = layout(
            for: orientation(
                imageWidth: width,
                imageHeight: height
            )
        )
        let measuredHeight = max(
            Int(round(CGFloat(width) * layout.barHeightToImageWidth)),
            2
        )
        return Int(
            PresentationPixelGeometry.encoderSafeDimension(
                CGFloat(measuredHeight)
            )
        )
    }
}
