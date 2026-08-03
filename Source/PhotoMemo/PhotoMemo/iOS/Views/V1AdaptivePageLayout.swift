import CoreGraphics

enum V1EntryNavigationStyle {
    case bottomTabBar
    case compactSidebar
    case regularSidebar
}

enum V1AdaptivePageLayout {

    static let maximumReadableContentWidth:
        CGFloat = 720

    static func navigationStyle(
        isPad: Bool,
        hasRegularHorizontalSizeClass: Bool,
        hasCompactVerticalSizeClass: Bool
    ) -> V1EntryNavigationStyle {
        if isPad && hasRegularHorizontalSizeClass {
            return .regularSidebar
        }

        if hasCompactVerticalSizeClass {
            return .compactSidebar
        }

        return .bottomTabBar
    }

    static func scrollBottomPadding(
        for navigationStyle: V1EntryNavigationStyle
    ) -> CGFloat {
        switch navigationStyle {
        case .bottomTabBar:
            return 96
        case .compactSidebar, .regularSidebar:
            return 26
        }
    }

}

#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

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
            .frame(
                maxWidth: .infinity,
                alignment: .center
            )
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
