#if !PHOTOMEMO_SHARE_EXTENSION
import Testing
@testable import PhotoMemo

@Suite("V1 adaptive page layout")
struct V1AdaptivePageLayoutTests {

    @Test("regular detail width uses side by side editor composition")
    func regularWidthUsesSideBySideComposition() {
        #expect(
            V1AdaptivePageLayout
                .editorComposition(for: 900)
            == .sideBySide
        )
    }

    @Test("narrow split view uses stacked editor composition")
    func narrowWidthUsesStackedComposition() {
        #expect(
            V1AdaptivePageLayout
                .editorComposition(for: 640)
            == .stacked
        )
    }

    @Test("editor threshold remains stacked at its lower edge")
    func thresholdLowerEdgeRemainsStacked() {
        #expect(
            V1AdaptivePageLayout
                .editorComposition(for: 759)
            == .stacked
        )
    }

    @Test("editor threshold becomes side by side at its upper edge")
    func thresholdUpperEdgeBecomesSideBySide() {
        #expect(
            V1AdaptivePageLayout
                .editorComposition(for: 760)
            == .sideBySide
        )
    }

    @Test("regular width iPhone keeps compact navigation")
    func regularWidthIPhoneKeepsCompactNavigation() {
        #expect(
            V1AdaptivePageLayout
                .usesSidebarNavigation(
                    isPad: false,
                    hasRegularHorizontalSizeClass: true
                )
            == false
        )
    }

    @Test("regular width iPad uses sidebar navigation")
    func regularWidthIPadUsesSidebarNavigation() {
        #expect(
            V1AdaptivePageLayout
                .usesSidebarNavigation(
                    isPad: true,
                    hasRegularHorizontalSizeClass: true
                )
            == true
        )
    }

    @Test("compact split view iPad keeps compact navigation")
    func compactIPadKeepsCompactNavigation() {
        #expect(
            V1AdaptivePageLayout
                .usesSidebarNavigation(
                    isPad: true,
                    hasRegularHorizontalSizeClass: false
                )
            == false
        )
    }
}
#endif
