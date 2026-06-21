import Testing
@testable import PhotoMemo

@Suite("Template preset render layout")
struct TemplatePresetRenderLayoutTests {

    @Test("Template 1 uses the Immers white renderer layout")
    func template1UsesImmersWhiteLayout() {

        #expect(
            TemplatePreset.template1
            .renderLayout == .immersWhite
        )
    }

    @Test("Legacy template 2 and 3 keep the classic white layout")
    func legacyTemplatesKeepClassicWhiteLayout() {

        #expect(
            TemplatePreset.template2
            .renderLayout == .classicWhite
        )
        #expect(
            TemplatePreset.template3
            .renderLayout == .classicWhite
        )
    }

    @Test("Immers white preset keeps the Immers layout")
    func immersWhitePresetKeepsImmersLayout() {

        #expect(
            TemplatePreset.immersWhite
            .renderLayout == .immersWhite
        )
    }
}
