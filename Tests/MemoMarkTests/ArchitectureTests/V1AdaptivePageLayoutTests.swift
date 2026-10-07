#if !MEMOMARK_SHARE_EXTENSION
import Testing
@testable import MemoMark

@Suite("V1 adaptive page layout")
struct AdaptivePageLayoutTests {

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

    @Test("regular width and regular height uses the full sidebar")
    func regularWidthAndRegularHeightUsesRegularSidebar() {
        #expect(
            AdaptivePageLayout
                .navigationStyle(
                    hasRegularHorizontalSizeClass: true,
                    hasCompactVerticalSizeClass: false
                )
            == .regularSidebar
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
