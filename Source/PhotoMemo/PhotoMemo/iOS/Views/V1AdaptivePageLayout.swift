#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

enum V1AdaptivePageLayout {

    static let maximumReadableContentWidth:
        CGFloat = 720
}

extension View {

    func v1AdaptivePageContent(
        horizontalPadding: CGFloat
    ) -> some View {
        self
            .frame(
                maxWidth:
                    V1AdaptivePageLayout
                    .maximumReadableContentWidth
            )
            .frame(maxWidth: .infinity)
            .padding(
                .horizontal,
                horizontalPadding
            )
    }

    func v1AdaptiveScrollContent(
        horizontalPadding: CGFloat
    ) -> some View {
        v1AdaptivePageContent(
            horizontalPadding:
                horizontalPadding
        )
        .containerRelativeFrame(.horizontal)
    }
}
#endif
