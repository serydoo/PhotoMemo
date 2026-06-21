import CoreGraphics
import SwiftUI

#if !PHOTOMEMO_SHARE_EXTENSION
enum ClassicWhiteRenderer {

    static let theme =
        ClassicWhiteTheme.theme

    static func outputPixelSize(
        for metadata: PhotoMetadata,
        fallbackSize: CGSize
    ) -> CGSize {

        let resolvedWidth =
            max(
                CGFloat(
                    metadata.imageWidth
                    ?? Int(fallbackSize.width)
                ),
                1
            )

        let resolvedHeight =
            max(
                CGFloat(
                    metadata.imageHeight
                    ?? Int(fallbackSize.height)
                ),
                1
            )

        return CGSize(
            width: resolvedWidth,
            height:
                resolvedHeight
                + theme.bottomBar.height
        )
    }
}
#endif
