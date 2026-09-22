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

    @Test("regular width and compact height uses a compact sidebar")
    func regularWidthAndCompactHeightUsesCompactSidebar() {
        #expect(
            AdaptivePageLayout
                .navigationStyle(
                    hasRegularHorizontalSizeClass: true,
                    hasCompactVerticalSizeClass: true
                )
            == .compactSidebar
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

    @Test("compact width and compact height uses a compact sidebar")
    func compactWidthAndCompactHeightUsesCompactSidebar() {
        #expect(
            AdaptivePageLayout
                .navigationStyle(
                    hasRegularHorizontalSizeClass: false,
                    hasCompactVerticalSizeClass: true
                )
            == .compactSidebar
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

    @Test("sidebars avoid unnecessary bottom whitespace")
    func sidebarsUseStandardBottomPadding() {
        #expect(
            AdaptivePageLayout
                .scrollBottomPadding(
                    for: .compactSidebar
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
