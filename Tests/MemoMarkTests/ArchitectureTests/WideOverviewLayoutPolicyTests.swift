#if !MEMOMARK_SHARE_EXTENSION
import CoreGraphics
import Testing
@testable import MemoMark

@Suite("Wide Overview capacity and route projection")
struct WideOverviewLayoutPolicyTests {
    private func arrangement(_ width: CGFloat, _ height: CGFloat,
        regularWidth: Bool = true, regularHeight: Bool = true,
        accessibilityText: Bool = false, minimumRegionWidth: CGFloat = 350) -> OverviewContentArrangement? {
        WideOverviewLayoutPolicy.arrangement(viewport: CGSize(width: width, height: height),
            hasRegularHorizontalSizeClass: regularWidth, hasRegularVerticalSizeClass: regularHeight,
            usesAccessibilityText: accessibilityText, minimumRegionWidth: minimumRegionWidth)
    }

    @Test("iPad landscape uses peers, portrait stacks, narrow windows fall back")
    func spatialMatrix() {
        #expect(arrangement(1180, 820) == .horizontal)
        #expect(arrangement(820, 1180) == .vertical)
        #expect(arrangement(1024, 768) == .horizontal)
        #expect(arrangement(768, 1024) == .vertical)
        #expect(arrangement(600, 820) == nil)
        #expect(arrangement(1024, 500) == nil)
        #expect(arrangement(700, 640) == .vertical)
    }

    @Test("all frozen phone capacities reject Overview even with regular horizontal traits")
    func frozenPhoneMatrix() {
        for (width, height) in [(440.0, 956.0), (402, 874), (956, 440), (874, 402), (667, 375)] {
            #expect(arrangement(width, height) == nil)
        }
        #expect(arrangement(1200, 900, regularHeight: false) == nil)
        #expect(arrangement(1200, 900, regularWidth: false) == nil)
    }

    @Test("two readable columns and larger fonts govern horizontal arrangement")
    func regionCapacity() {
        #expect(arrangement(800, 700) == .horizontal)
        #expect(arrangement(775, 700) == .vertical)
        #expect(arrangement(1024, 768, minimumRegionWidth: 500) == .vertical)
        #expect(arrangement(700, 1000, minimumRegionWidth: 760) == nil)
        #expect(arrangement(1400, 1000, accessibilityText: true) == nil)
    }

    @Test("invalid or unavailable geometry conservatively falls back")
    func invalidCapacity() {
        for value in [CGFloat.nan, .infinity, -1, 0] {
            #expect(arrangement(value, 900) == nil)
            #expect(arrangement(1200, value) == nil)
            #expect(arrangement(1200, 900, minimumRegionWidth: value) == nil)
        }
    }

    @Test("Configuration portrait stacks and landscape needs two readable regions")
    func configurationWindowCapacity() {
        #expect(WideConfigurationLayoutPolicy.arrangement(viewport: CGSize(width: 1032, height: 1376)) == .stacked)
        #expect(WideConfigurationLayoutPolicy.arrangement(viewport: CGSize(width: 1376, height: 1032)) == .sideBySide)
        #expect(WideConfigurationLayoutPolicy.arrangement(viewport: CGSize(width: 760, height: 700)) == .stacked)
        #expect(WideConfigurationLayoutPolicy.arrangement(viewport: CGSize(width: 1024, height: 768), minimumRegionWidth: 500) == .stacked)
        #expect(WideConfigurationLayoutPolicy.arrangement(viewport: CGSize(width: CGFloat.nan, height: 900)) == .stacked)
    }

    @Test("Wide preview leaves readable editing capacity even when a keyboard reduces height")
    func configurationRegionBudget() {
        #expect(WideConfigurationRegionPolicy.previewMaximumHeight(viewportHeight: 1200, arrangement: .stacked) == 516)
        #expect(WideConfigurationRegionPolicy.previewMaximumHeight(viewportHeight: 600, arrangement: .stacked) == 216)
        #expect(WideConfigurationRegionPolicy.previewMaximumHeight(viewportHeight: 400, arrangement: .stacked) == 56)
        #expect(WideConfigurationRegionPolicy.previewMaximumHeight(viewportHeight: 600, arrangement: .sideBySide) == 516)
        #expect(WideConfigurationRegionPolicy.previewMaximumHeight(viewportHeight: 200, arrangement: .stacked) == 0)
        #expect(WideConfigurationRegionPolicy.previewMaximumHeight(viewportHeight: 600, arrangement: .stacked,
            minimumEditorHeight: 390, previewChromeHeight: 126) == 84)
        #expect(WideConfigurationRegionPolicy.editorHeight(viewportHeight: 600, previewPaneHeight: 300, arrangement: .stacked) == 300)
        #expect(WideConfigurationRegionPolicy.editorHeight(viewportHeight: 600, previewPaneHeight: 900, arrangement: .stacked) == 44)
        #expect(WideConfigurationRegionPolicy.editorHeight(viewportHeight: 600, previewPaneHeight: 300, arrangement: .sideBySide) == 600)
        for invalid in [CGFloat.nan, .infinity, -1, 0] {
            #expect(WideConfigurationRegionPolicy.previewMaximumHeight(viewportHeight: invalid, arrangement: .stacked) == 0)
            #expect(WideConfigurationRegionPolicy.editorHeight(viewportHeight: invalid, previewPaneHeight: 200, arrangement: .stacked) == 0)
        }
    }

    @Test("Overview groups home and tasks without changing canonical task deep links")
    func routesRemainCanonical() {
        #expect(WideTaskSpaceProjection.space(for: .home) == .overview)
        #expect(WideTaskSpaceProjection.space(for: .tasks) == .overview)
        #expect(WideTaskSpaceProjection.space(for: .editor) == .configuration)
        #expect(WideTaskSpaceProjection.space(for: .settings) == nil)
        #expect(WideTaskSpaceProjection.space(for: .output) == nil)
        #expect(WideTaskSpaceProjection.primaryTab(for: .tasks, usesWidePresentation: true) == .home)
        #expect(WideTaskSpaceProjection.primaryTab(for: .tasks, usesWidePresentation: false) == .tasks)
        #expect(WideTaskSpaceProjection.primaryTab(for: .editor, usesWidePresentation: true) == .editor)
        #expect(WideTaskSpaceProjection.destination(for: .overview) == .home)
        #expect(WideTaskSpaceProjection.destination(for: .configuration) == .editor)
    }
}
#endif
