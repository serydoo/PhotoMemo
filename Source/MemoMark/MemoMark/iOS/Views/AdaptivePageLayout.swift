import CoreGraphics

enum ConfigurationPreviewWidthPolicy: Equatable {
    case readable
    case fullWidthInCompactLandscape
}

enum AdaptivePageLayout {

    static let maximumReadableContentWidth:
        CGFloat = 720

    static func scrollContentWidth(
        viewportWidth: CGFloat,
        horizontalPadding: CGFloat,
        trailingReservedWidth: CGFloat = 0,
        fillsAvailableWidth: Bool = false
    ) -> CGFloat {
        let availableWidth = max(0, viewportWidth - trailingReservedWidth - horizontalPadding * 2)
        return fillsAvailableWidth ? availableWidth : min(maximumReadableContentWidth, availableWidth)
    }
}

/// Compact overview capacity, independent of device model or configuration state.
/// Compact-height large phones need two readable columns; regular-height/iPad
/// expansion remains a separate product slice.
enum CompactOverviewLayoutPolicy {
    static let minimumColumnWidth: CGFloat = 350
    static let minimumLargeWindowWidth: CGFloat = 940

    static func usesTwoColumns(
        contentWidth: CGFloat,
        windowWidth: CGFloat,
        minimumColumnWidth: CGFloat,
        columnSpacing: CGFloat,
        hasCompactHeight: Bool,
        usesAccessibilityText: Bool
    ) -> Bool {
        hasCompactHeight && !usesAccessibilityText
            && windowWidth >= minimumLargeWindowWidth
            && contentWidth.isFinite && minimumColumnWidth > 0
            && contentWidth >= minimumColumnWidth * 2 + columnSpacing
    }
}

enum AdaptiveFloatingRailMetrics {
    static let width: CGFloat = 56
    static let trailingMargin: CGFloat = 10

    static var contentSpacing: CGFloat {
        ConfigurationUI.innerPanelPadding
    }

    static var reservedWidth: CGFloat {
        width + trailingMargin + contentSpacing
    }

    static func trailingEdgeExpansion(
        systemInset: CGFloat,
        isUnobstructedLandscapeEdge: Bool
    ) -> CGFloat {
        guard isUnobstructedLandscapeEdge else { return 0 }
        return max(0, systemInset - contentSpacing)
    }
}

#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI

private struct EntryWindowWidthKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

extension EnvironmentValues {
    var entryWindowWidth: CGFloat {
        get { self[EntryWindowWidthKey.self] }
        set { self[EntryWindowWidthKey.self] = newValue }
    }
}

extension View {

    func adaptivePageContent(
        horizontalPadding: CGFloat
    ) -> some View {
        return self
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
        adaptivePageContent(horizontalPadding: horizontalPadding)
    }

    func adaptiveScrollContent(
        horizontalPadding: CGFloat,
        viewportWidth: CGFloat,
        trailingReservedWidth: CGFloat = 0,
        fillsAvailableWidth: Bool = false
    ) -> some View {
        let contentViewportWidth = max(
            0,
            viewportWidth - trailingReservedWidth
        )
        return self
            .frame(
                width: AdaptivePageLayout.scrollContentWidth(
                    viewportWidth: viewportWidth,
                    horizontalPadding: horizontalPadding,
                    trailingReservedWidth: trailingReservedWidth,
                    fillsAvailableWidth: fillsAvailableWidth
                )
            )
            .frame(
                width: contentViewportWidth,
                alignment: .center
            )
            .frame(
                width: viewportWidth,
                alignment: .leading
            )
    }

}
#endif
