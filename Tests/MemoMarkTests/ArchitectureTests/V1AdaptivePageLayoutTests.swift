#if !MEMOMARK_SHARE_EXTENSION
import Testing
@testable import MemoMark

@Suite("V1 adaptive page layout")
struct V1AdaptivePageLayoutTests {

    @Test("regular-height iPhone keeps the bottom tab bar")
    func regularHeightIPhoneKeepsBottomTabBar() {
        #expect(
            V1AdaptivePageLayout
                .navigationStyle(
                    isPad: false,
                    hasRegularHorizontalSizeClass: false,
                    hasCompactVerticalSizeClass: false
                )
            == .bottomTabBar
        )
    }

    @Test("compact-height iPhone moves navigation to a compact sidebar")
    func compactHeightIPhoneUsesCompactSidebar() {
        #expect(
            V1AdaptivePageLayout
                .navigationStyle(
                    isPad: false,
                    hasRegularHorizontalSizeClass: true,
                    hasCompactVerticalSizeClass: true
                )
            == .compactSidebar
        )
    }

    @Test("regular-width iPad uses the full sidebar")
    func regularWidthIPadUsesRegularSidebar() {
        #expect(
            V1AdaptivePageLayout
                .navigationStyle(
                    isPad: true,
                    hasRegularHorizontalSizeClass: true,
                    hasCompactVerticalSizeClass: true
                )
            == .regularSidebar
        )
    }

    @Test("regular-height compact iPad window keeps the bottom tab bar")
    func regularHeightCompactIPadKeepsBottomTabBar() {
        #expect(
            V1AdaptivePageLayout
                .navigationStyle(
                    isPad: true,
                    hasRegularHorizontalSizeClass: false,
                    hasCompactVerticalSizeClass: false
                )
            == .bottomTabBar
        )
    }

    @Test("short compact iPad window uses the compact sidebar")
    func shortCompactIPadUsesCompactSidebar() {
        #expect(
            V1AdaptivePageLayout
                .navigationStyle(
                    isPad: true,
                    hasRegularHorizontalSizeClass: false,
                    hasCompactVerticalSizeClass: true
                )
            == .compactSidebar
        )
    }

    @Test("bottom tab bar keeps scroll content clear of navigation")
    func bottomTabBarUsesExpandedBottomPadding() {
        #expect(
            V1AdaptivePageLayout
                .scrollBottomPadding(
                    for: .bottomTabBar
                )
            == 96
        )
    }

    @Test("sidebars avoid unnecessary bottom whitespace")
    func sidebarsUseStandardBottomPadding() {
        #expect(
            V1AdaptivePageLayout
                .scrollBottomPadding(
                    for: .compactSidebar
                )
            == 26
        )
        #expect(
            V1AdaptivePageLayout
                .scrollBottomPadding(
                    for: .regularSidebar
                )
            == 26
        )
    }
}
#endif
