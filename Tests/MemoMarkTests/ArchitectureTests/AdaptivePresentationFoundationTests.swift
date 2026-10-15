#if !MEMOMARK_SHARE_EXTENSION
import Testing
@testable import MemoMark

@Suite("Adaptive presentation foundation")
struct AdaptivePresentationFoundationTests {
    @Test("system spatial traits preserve every frozen phone and unknown-class decision")
    func frozenSpatialMatrix() {
        let cases: [(AdaptivePresentationSizeClass, AdaptivePresentationSizeClass,
                     EntryNavigationStyle, ConfigurationContentArrangement)] = [
            (.compact, .regular, .bottomTabBar, .stacked),
            (.compact, .compact, .floatingRail, .stacked),
            (.regular, .compact, .floatingRail, .stacked),
            (.regular, .regular, .floatingRail, .sideBySide),
            (.unspecified, .unspecified, .bottomTabBar, .stacked),
            (.unspecified, .regular, .bottomTabBar, .stacked),
            (.unspecified, .compact, .floatingRail, .stacked),
            (.compact, .unspecified, .bottomTabBar, .stacked),
            (.regular, .unspecified, .floatingRail, .stacked)
        ]
        for (horizontal, vertical, navigation, arrangement) in cases {
            let capabilities = AdaptivePresentationCapabilities(horizontal: horizontal, vertical: vertical)
            #expect(NavigationPresentationPolicy.style(for: capabilities) == navigation)
            #expect(ConfigurationContentArrangementPolicy.arrangement(for: capabilities) == arrangement)
        }
    }

    @Test("the same rail supports both stacked and side-by-side content")
    func arrangementIsIndependentOfNavigation() {
        let landscape = AdaptivePresentationCapabilities(horizontal: .regular, vertical: .compact)
        let wide = AdaptivePresentationCapabilities(horizontal: .regular, vertical: .regular)
        #expect(NavigationPresentationPolicy.style(for: landscape) == .floatingRail)
        #expect(NavigationPresentationPolicy.style(for: wide) == .floatingRail)
        #expect(ConfigurationContentArrangementPolicy.arrangement(for: landscape) == .stacked)
        #expect(ConfigurationContentArrangementPolicy.arrangement(for: wide) == .sideBySide)
    }

    @Test("resize projections do not retain a preceding wide capability")
    func resizeFallsBackToFrozenPhonePresentation() {
        let sequence: [(AdaptivePresentationSizeClass, AdaptivePresentationSizeClass)] = [
            (.regular, .regular), (.compact, .regular), (.regular, .compact), (.unspecified, .unspecified)
        ]
        let navigation = sequence.map { NavigationPresentationPolicy.style(for:
            AdaptivePresentationCapabilities(horizontal: $0.0, vertical: $0.1)) }
        let arrangement = sequence.map { ConfigurationContentArrangementPolicy.arrangement(for:
            AdaptivePresentationCapabilities(horizontal: $0.0, vertical: $0.1)) }
        #expect(navigation == [.floatingRail, .bottomTabBar, .floatingRail, .bottomTabBar])
        #expect(arrangement == [.sideBySide, .stacked, .stacked, .stacked])
    }

    @Test("chrome clearance preserves the accepted scrolling contract")
    func navigationClearance() {
        #expect(NavigationPresentationPolicy.scrollBottomPadding(for: .bottomTabBar) == 96)
        #expect(NavigationPresentationPolicy.scrollBottomPadding(for: .floatingRail) == 26)
        #expect(NavigationPresentationPolicy.scrollBottomPadding(for: .regularSidebar) == 26)
    }
}
#endif
