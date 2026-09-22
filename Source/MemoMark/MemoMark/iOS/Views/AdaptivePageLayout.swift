import CoreGraphics

enum EntryNavigationStyle {
    case bottomTabBar
    case compactSidebar
    case regularSidebar
}

enum ConfigurationPreviewWidthPolicy: Equatable {
    case readable
    case fullWidthInCompactLandscape
}

enum AdaptivePageLayout {

    static let maximumReadableContentWidth:
        CGFloat = 720

    static func navigationStyle(
        hasRegularHorizontalSizeClass: Bool,
        hasCompactVerticalSizeClass: Bool
    ) -> EntryNavigationStyle {
        if hasCompactVerticalSizeClass {
            return .compactSidebar
        }

        if hasRegularHorizontalSizeClass {
            return .regularSidebar
        }

        return .bottomTabBar
    }

    static func usesRegularWorkspace(
        hasRegularHorizontalSizeClass: Bool,
        hasRegularVerticalSizeClass: Bool
    ) -> Bool {
        hasRegularHorizontalSizeClass && hasRegularVerticalSizeClass
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

private struct AdaptiveScrollContentViewportModifier: ViewModifier {

    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass

    @ViewBuilder
    func body(content: Content) -> some View {
        if horizontalSizeClass == .regular {
            content
        } else {
            content
                .containerRelativeFrame(.horizontal)
        }
    }
}

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
        .modifier(AdaptiveScrollContentViewportModifier())
    }
}
#endif
