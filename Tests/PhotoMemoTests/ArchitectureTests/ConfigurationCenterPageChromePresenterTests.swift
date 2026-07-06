#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@MainActor
@Suite("Configuration center page chrome presenter")
struct ConfigurationCenterPageChromePresenterTests {

    @Test("card panel presentation surfaces the active region title and an apply action when the preset is pending")
    func cardPanelPresentationWithPendingPreset() {
        let session = ConfigurationSession()
        session.resetSelectedMemoryPreset()

        let presentation =
            ConfigurationCenterPageChromePresenter
            .presentation(
                selectedPanel: .card(.slotD),
                session: session
            )

        #expect(presentation.sectionTitle == "区域 D 配置")
        #expect(
            presentation.statusText
            == "当前配置改动尚未生效"
        )
        #expect(
            presentation.primaryActionTitle
            == "保存并生效"
        )
        #expect(
            presentation.primaryActionSystemImage
            == "checkmark.circle"
        )
        #expect(presentation.canApplyChanges)
    }

    @Test("applied preset presentation reports the current page and disables the primary apply action")
    func appliedPresetPresentation() {
        let session = ConfigurationSession()
        session.applySelectedMemoryPreset()

        let presentation =
            ConfigurationCenterPageChromePresenter
            .presentation(
                selectedPanel: .memoryModule,
                session: session
            )

        #expect(presentation.sectionTitle == "智能模块")
        #expect(
            presentation.statusText
            == "当前生效配置已同步"
        )
        #expect(
            presentation.primaryActionTitle
            == "已生效"
        )
        #expect(
            presentation.primaryActionSystemImage
            == "checkmark.circle.fill"
        )
        #expect(!presentation.canApplyChanges)
    }

    @Test("subject presentation keeps the root-page semantics without introducing back navigation copy")
    func subjectPresentationRemainsRootScoped() {
        let session = ConfigurationSession()

        let presentation =
            ConfigurationCenterPageChromePresenter
            .presentation(
                selectedPanel: .subject,
                session: session
            )

        #expect(presentation.sectionTitle == "记忆对象")
        #expect(
            presentation.resetActionTitle
            == "重置"
        )
    }
}
#endif
