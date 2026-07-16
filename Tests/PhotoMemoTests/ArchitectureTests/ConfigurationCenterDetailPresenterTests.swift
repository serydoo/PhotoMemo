#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("Configuration center detail presenter")
struct ConfigurationCenterDetailPresenterTests {

    @Test("card panel preserves the unwrapped detail surface route")
    func cardPanelPreservesUnwrappedDetailSurfaceRoute() {
        let presentation =
            ConfigurationCenterDetailPresenter
            .panelPresentation(
                for: .card(.slotD)
            )

        #expect(presentation.content == .card)
        #expect(presentation.title == nil)
        #expect(presentation.systemImage == nil)
        #expect(presentation.subtitle == nil)
    }

    @Test("subject panel reflects the current object maintenance surface")
    func subjectPanelReflectsCurrentObjectMaintenanceSurface() {
        let presentation =
            ConfigurationCenterDetailPresenter
            .panelPresentation(
                for: .subject
            )

        #expect(presentation.content == .subject)
        #expect(presentation.title == "记忆对象")
        #expect(
            presentation.systemImage
            == MemoMarkSymbol.memorySubject.name
        )
        #expect(
            presentation.subtitle
            == "对象资料与锚点维护"
        )
    }

    @Test("badge editor uses the configuration symbol")
    func badgeEditorUsesConfigurationSymbol() {
        let presentation =
            ConfigurationCenterDetailPresenter
            .regionEditorPresentation(
                for: .badge
            )

        #expect(presentation.content == .badgeLibrary)
        #expect(presentation.title == "徽标配置")
        #expect(
            presentation.systemImage
            == MemoMarkSymbol.configuration.name
        )
    }

    @Test("slotD region editor remains the memory composer route")
    func slotDRegionEditorRemainsMemoryComposerRoute() {
        let presentation =
            ConfigurationCenterDetailPresenter
            .regionEditorPresentation(
                for: .slotD
            )

        #expect(presentation.content == .regionComposer)
        #expect(presentation.title == "区域 D 配置")
        #expect(
            presentation.systemImage
            == MemoMarkSymbol.memoryContent.name
        )
    }

    @Test("memory module panel is presented as an independent secondary menu")
    func memoryModulePanelPresentation() {
        let presentation =
            ConfigurationCenterDetailPresenter
            .panelPresentation(
                for: .memoryModule
            )

        #expect(presentation.content == .memoryModule)
        #expect(presentation.title == "智能模块")
        #expect(
            presentation.subtitle
            == "先生成 1 个智能结果，再决定承载与写入方式"
        )
    }
}
#endif
