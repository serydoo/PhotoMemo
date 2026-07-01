#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@MainActor
@Suite("Configuration center session binding presenter")
struct ConfigurationCenterSessionBindingPresenterTests {

    @Test("profile title reads from the selected memory preset and preserves session normalization on write")
    func profileTitleReadWrite() {
        let session = ConfigurationSession()

        #expect(
            ConfigurationCenterSessionBindingPresenter
                .profileTitle(session: session)
            == session.currentMemoryPresetTitle
        )

        ConfigurationCenterSessionBindingPresenter
            .setProfileTitle(
                "  宝宝记忆  ",
                session: session
            )

        #expect(session.currentMemoryPresetTitle == "宝宝记忆")

        ConfigurationCenterSessionBindingPresenter
            .setProfileTitle(
                "   ",
                session: session
            )

        #expect(session.currentMemoryPresetTitle == "记忆预设")
    }

    @Test("storage option reads and writes through the session")
    func storageOptionReadWrite() {
        let session = ConfigurationSession()

        #expect(
            ConfigurationCenterSessionBindingPresenter
                .selectedStorageOption(session: session)
            == .appFolder
        )

        ConfigurationCenterSessionBindingPresenter
            .setSelectedStorageOption(
                .targetAlbum,
                session: session
            )

        #expect(session.selectedStorageOption == .targetAlbum)
    }

    @Test("custom memory write toggle reads and writes through the session")
    func customMemoryWriteToggleReadWrite() {
        let session = ConfigurationSession()

        #expect(
            ConfigurationCenterSessionBindingPresenter
                .usesCustomMemoryWriteText(session: session)
            == false
        )

        ConfigurationCenterSessionBindingPresenter
            .setUsesCustomMemoryWriteText(
                true,
                session: session
            )

        #expect(session.usesCustomMemoryWriteText == true)
    }

    @Test("custom memory write text reads and writes through the session")
    func customMemoryWriteTextReadWrite() {
        let session = ConfigurationSession()

        #expect(
            ConfigurationCenterSessionBindingPresenter
                .customMemoryWriteText(session: session)
            == ""
        )

        ConfigurationCenterSessionBindingPresenter
            .setCustomMemoryWriteText(
                "写入 Apple Photos 的说明",
                session: session
            )

        #expect(
            session.customMemoryWriteText
            == "写入 Apple Photos 的说明"
        )
    }

    @Test("memory write copy explains the default smart-module fallback when separate text is off")
    func memoryWriteCopyForDefaultFallback() {
        let session = ConfigurationSession()

        #expect(
            ConfigurationCenterSessionBindingPresenter
                .memoryWriteToggleTitle
            == "单独录入相册说明"
        )
        #expect(
            ConfigurationCenterSessionBindingPresenter
                .memoryWritePreviewTitle(session: session)
            == "默认写入（当前智能模块）"
        )
        #expect(
            ConfigurationCenterSessionBindingPresenter
                .memoryWriteDescription(session: session)
                .contains("当前生成的智能模块完整结果")
        )
        #expect(
            ConfigurationCenterSessionBindingPresenter
                .customMemoryWritePlaceholder
            == "输入要单独写入图库说明的文字"
        )
    }

    @Test("memory write copy switches to custom-entry wording when separate text is on")
    func memoryWriteCopyForSeparateText() {
        let session = ConfigurationSession()
        session.usesCustomMemoryWriteText = true

        #expect(
            ConfigurationCenterSessionBindingPresenter
                .memoryWritePreviewTitle(session: session)
            == "实际写入"
        )
        #expect(
            ConfigurationCenterSessionBindingPresenter
                .memoryWriteDescription(session: session)
                .contains("单独录入的文字")
        )
    }
}
#endif
