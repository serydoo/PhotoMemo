import CoreGraphics

enum EntryNavigationStyle {
    case bottomTabBar
    case compactSidebar
    case regularSidebar
}

enum AdaptivePageLayout {

    static let maximumReadableContentWidth:
        CGFloat = 720

    static func navigationStyle(
        isPad: Bool,
        hasRegularHorizontalSizeClass: Bool,
        hasCompactVerticalSizeClass: Bool
    ) -> EntryNavigationStyle {
        if isPad && hasRegularHorizontalSizeClass {
            return .regularSidebar
        }

        if hasCompactVerticalSizeClass {
            return .compactSidebar
        }

        return .bottomTabBar
    }

    static func scrollBottomPadding(
        for navigationStyle: EntryNavigationStyle
    ) -> CGFloat {
        switch navigationStyle {
        case .bottomTabBar:
            return 96
        case .compactSidebar, .regularSidebar:
            return 26
        }
    }

}

#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI

extension View {

    func adaptivePageContent(
        horizontalPadding: CGFloat
    ) -> some View {
        self
            .frame(
                maxWidth:
                    AdaptivePageLayout
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

    func adaptiveScrollContent(
        horizontalPadding: CGFloat
    ) -> some View {
        adaptivePageContent(
            horizontalPadding:
                horizontalPadding
        )
        .containerRelativeFrame(.horizontal)
    }
}
#endif
