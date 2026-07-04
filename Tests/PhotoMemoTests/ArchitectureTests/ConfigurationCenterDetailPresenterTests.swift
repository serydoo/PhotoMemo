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

    @Test("subject panel subtitle reflects the simplified V1 subject surface")
    func subjectPanelSubtitleReflectsSimplifiedV1SubjectSurface() {
        let presentation =
            ConfigurationCenterDetailPresenter
            .panelPresentation(
                for: .subject
            )

        #expect(presentation.content == .subject)
        #expect(presentation.title == "记忆对象")
        #expect(presentation.systemImage == "person.fill")
        #expect(
            presentation.subtitle
            == "身份与时间锚点"
        )
    }

    @Test("region editor presentation keeps the badge icon quirk")
    func regionEditorPresentationKeepsBadgeIconQuirk() {
        let presentation =
            ConfigurationCenterDetailPresenter
            .regionEditorPresentation(
                for: .badge
            )

        #expect(presentation.content == .badgeLibrary)
        #expect(presentation.title == "徽标配置")
        #expect(presentation.systemImage == "camera.fill")
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
        #expect(presentation.systemImage == "text.quote")
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
            == "先生成 1 个智能模块，再决定承载与写入方式"
        )
    }
}
#endif
