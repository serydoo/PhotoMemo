#if !MEMOMARK_SHARE_EXTENSION
import Testing
@testable import MemoMark

@Suite("V1 adaptive page layout")
struct AdaptivePageLayoutTests {

    @Test("large landscape columns require both a large window and readable safe columns")
    func homeColumnsRequireReadableWidth() {
        for width in [723.0, 773, 834] {
            #expect(CompactOverviewLayoutPolicy.usesTwoColumns(contentWidth: width, windowWidth: 956,
                minimumColumnWidth: 350, columnSpacing: 12, hasCompactHeight: true, usesAccessibilityText: false))
        }
        for windowWidth in [0.0, 667, 852, 896, 932] {
            #expect(!CompactOverviewLayoutPolicy.usesTwoColumns(contentWidth: 834, windowWidth: windowWidth,
                minimumColumnWidth: 350, columnSpacing: 12, hasCompactHeight: true, usesAccessibilityText: false))
        }
        #expect(!CompactOverviewLayoutPolicy.usesTwoColumns(contentWidth: 700, windowWidth: 956,
            minimumColumnWidth: 350, columnSpacing: 12, hasCompactHeight: true, usesAccessibilityText: false))
        #expect(!CompactOverviewLayoutPolicy.usesTwoColumns(contentWidth: 773, windowWidth: 956,
            minimumColumnWidth: 400, columnSpacing: 12, hasCompactHeight: true, usesAccessibilityText: false))
        #expect(!CompactOverviewLayoutPolicy.usesTwoColumns(contentWidth: 834, windowWidth: 956,
            minimumColumnWidth: 350, columnSpacing: 12, hasCompactHeight: true, usesAccessibilityText: true))
        #expect(!CompactOverviewLayoutPolicy.usesTwoColumns(contentWidth: 1100, windowWidth: 1200,
            minimumColumnWidth: 350, columnSpacing: 12, hasCompactHeight: false, usesAccessibilityText: false))
    }

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
            NavigationPresentationPolicy.style(for: AdaptivePresentationCapabilities(
                    horizontal: .compact,
                    vertical: .regular
                ))
            == .bottomTabBar
        )
    }

    @Test("regular width and compact height uses a floating rail")
    func regularWidthAndCompactHeightUsesFloatingRail() {
        #expect(
            NavigationPresentationPolicy.style(for: AdaptivePresentationCapabilities(
                    horizontal: .regular,
                    vertical: .compact
                ))
            == .floatingRail
        )
    }

    @Test("regular width and regular height keeps the right-side floating rail")
    func regularWidthAndRegularHeightUsesFloatingRail() {
        #expect(
            NavigationPresentationPolicy.style(for: AdaptivePresentationCapabilities(
                    horizontal: .regular,
                    vertical: .regular
                ))
            == .floatingRail
        )
    }

    @Test("compact width and compact height uses a floating rail")
    func compactWidthAndCompactHeightUsesFloatingRail() {
        #expect(
            NavigationPresentationPolicy.style(for: AdaptivePresentationCapabilities(
                    horizontal: .compact,
                    vertical: .compact
                ))
            == .floatingRail
        )
    }

    @Test("bottom tab bar keeps scroll content clear of navigation")
    func bottomTabBarUsesExpandedBottomPadding() {
        #expect(
            NavigationPresentationPolicy.scrollBottomPadding(
                    for: .bottomTabBar
                )
            == 96
        )
    }

    @Test("side presentations avoid unnecessary bottom whitespace")
    func sidePresentationsUseStandardBottomPadding() {
        #expect(
            NavigationPresentationPolicy.scrollBottomPadding(
                    for: .floatingRail
                )
            == 26
        )
        #expect(
            NavigationPresentationPolicy.scrollBottomPadding(
                    for: .regularSidebar
                )
            == 26
        )
    }

    @Test("side-by-side configuration requires regular width and height")
    func sideBySideConfigurationRequiresRegularWidthAndHeight() {
        #expect(
            ConfigurationContentArrangementPolicy.arrangement(for: AdaptivePresentationCapabilities(
                horizontal: .regular,
                vertical: .regular
            )) == .sideBySide
        )
        #expect(
            ConfigurationContentArrangementPolicy.arrangement(for: AdaptivePresentationCapabilities(
                horizontal: .compact,
                vertical: .regular
            )) != .sideBySide
        )
        #expect(
            ConfigurationContentArrangementPolicy.arrangement(for: AdaptivePresentationCapabilities(
                horizontal: .regular,
                vertical: .compact
            )) != .sideBySide
        )
    }
}
#endif
