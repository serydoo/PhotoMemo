import CoreGraphics
import Testing
@testable import PhotoMemo

@Suite("Template preset render layout")
struct TemplatePresetRenderLayoutTests {

    @Test("Classic White uses the current compact information bar layout")
    func classicWhiteUsesCurrentLayout() {

        #expect(
            TemplatePreset.classicWhite
            .renderLayout == .classicWhite
        )
        #expect(
            ClassicWhiteRenderer.layout(for: .portrait)
            .borderToImageHeightRatio
            == CGFloat(753) / CGFloat(8064)
        )
    }
}
