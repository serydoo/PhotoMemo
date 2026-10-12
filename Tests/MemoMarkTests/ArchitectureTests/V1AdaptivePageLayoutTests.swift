#if !MEMOMARK_SHARE_EXTENSION
import Testing
@testable import MemoMark

@Suite("V1 adaptive page layout")
struct AdaptivePageLayoutTests {

    @Test("unobstructed landscape edge releases unused inset while preserving ordinary spacing")
    func unobstructedLandscapeEdgeReleasesOnlyExcessInset() {
        let expansion = AdaptiveFloatingRailMetrics.trailingEdgeExpansion(systemInset: 62,
            isUnobstructedLandscapeEdge: true)
        let expectedExpansion = 62.0 - AdaptiveFloatingRailMetrics.contentSpacing
        #expect(abs(expansion - expectedExpansion) < 0.001)
        #expect(AdaptiveFloatingRailMetrics.trailingEdgeExpansion(systemInset: 62,
            isUnobstructedLandscapeEdge: false) == 0)
        #expect(AdaptiveFloatingRailMetrics.trailingEdgeExpansion(systemInset: 0,
            isUnobstructedLandscapeEdge: true) == 0)
        #expect(AdaptiveFloatingRailMetrics.trailingEdgeExpansion(systemInset: 8,
            isUnobstructedLandscapeEdge: true) == 0)
    }

    @Test("compact-height content fills only the safe viewport left by the shell")
    func compactHeightFillsSafeViewportWithoutDoubleReservation() {
        #expect(AdaptivePageLayout.scrollContentWidth(viewportWidth: 850, horizontalPadding: 16,
                                                     fillsAvailableWidth: true) == 818)
        #expect(AdaptivePageLayout.scrollContentWidth(viewportWidth: 770, horizontalPadding: 16,
                                                     fillsAvailableWidth: true) == 738)
        #expect(AdaptivePageLayout.scrollContentWidth(viewportWidth: 850, horizontalPadding: 16) == 720)
        #expect(AdaptivePageLayout.scrollContentWidth(viewportWidth: 20, horizontalPadding: 16,
                                                     fillsAvailableWidth: true) == 0)
    }

    @Test("compact width and regular height keeps the bottom tab bar")
    func compactWidthAndRegularHeightKeepsBottomTabBar() {
        #expect(
            AdaptivePageLayout
                .navigationStyle(
                    hasRegularHorizontalSizeClass: false,
                    hasCompactVerticalSizeClass: false
                )
            == .bottomTabBar
        )
    }

    @Test("regular width and compact height uses a floating rail")
    func regularWidthAndCompactHeightUsesFloatingRail() {
        #expect(
            AdaptivePageLayout
                .navigationStyle(
                    hasRegularHorizontalSizeClass: true,
                    hasCompactVerticalSizeClass: true
                )
            == .floatingRail
        )
    }

    @Test("regular width and regular height keeps the right-side floating rail")
    func regularWidthAndRegularHeightUsesFloatingRail() {
        #expect(
            AdaptivePageLayout
                .navigationStyle(
                    hasRegularHorizontalSizeClass: true,
                    hasCompactVerticalSizeClass: false
                )
            == .floatingRail
        )
    }

    @Test("compact width and compact height uses a floating rail")
    func compactWidthAndCompactHeightUsesFloatingRail() {
        #expect(
            AdaptivePageLayout
                .navigationStyle(
                    hasRegularHorizontalSizeClass: false,
                    hasCompactVerticalSizeClass: true
                )
            == .floatingRail
        )
    }

    @Test("bottom tab bar keeps scroll content clear of navigation")
    func bottomTabBarUsesExpandedBottomPadding() {
        #expect(
            AdaptivePageLayout
                .scrollBottomPadding(
                    for: .bottomTabBar
                )
            == 96
        )
    }

    @Test("side presentations avoid unnecessary bottom whitespace")
    func sidePresentationsUseStandardBottomPadding() {
        #expect(
            AdaptivePageLayout
                .scrollBottomPadding(
                    for: .floatingRail
                )
            == 26
        )
        #expect(
            AdaptivePageLayout
                .scrollBottomPadding(
                    for: .regularSidebar
                )
            == 26
        )
    }

    @Test("regular workspace requires regular width and height")
    func regularWorkspaceRequiresRegularWidthAndHeight() {
        #expect(
            AdaptivePageLayout.usesRegularWorkspace(
                hasRegularHorizontalSizeClass: true,
                hasRegularVerticalSizeClass: true
            )
        )
        #expect(
            !AdaptivePageLayout.usesRegularWorkspace(
                hasRegularHorizontalSizeClass: false,
                hasRegularVerticalSizeClass: true
            )
        )
        #expect(
            !AdaptivePageLayout.usesRegularWorkspace(
                hasRegularHorizontalSizeClass: true,
                hasRegularVerticalSizeClass: false
            )
        )
    }
}
#endif
