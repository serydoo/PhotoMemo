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

    @Test("profile title limits normalized names to twenty four characters")
    func profileTitleLimitsNormalizedNames() {
        let session = ConfigurationSession()

        ConfigurationCenterSessionBindingPresenter
            .setProfileTitle(
                "  123456789012345678901234567890  ",
                session: session
            )

        #expect(
            session.currentMemoryPresetTitle
            == "123456789012345678901234"
        )
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

    @Test("memory write copy explains the complete default expression")
    func memoryWriteCopyForDefaultFallback() {
        let session = ConfigurationSession()

        #expect(
            ConfigurationCenterSessionBindingPresenter
                .memoryWriteToggleTitle
            == "补充一段话"
        )
        #expect(
            ConfigurationCenterSessionBindingPresenter
                .memoryWritePreviewTitle(session: session)
            == "即将写下的内容"
        )
        #expect(
            ConfigurationCenterSessionBindingPresenter
                .memoryWriteDescription(session: session)
                .contains("记忆表达完整写进照片说明")
        )
        #expect(
            ConfigurationCenterSessionBindingPresenter
                .customMemoryWritePlaceholder
            == "写下想补充的话"
        )
    }

    @Test("memory write copy explains that custom text follows the expression")
    func memoryWriteCopyForSupplementalText() {
        let session = ConfigurationSession()
        session.usesCustomMemoryWriteText = true

        #expect(
            ConfigurationCenterSessionBindingPresenter
                .memoryWritePreviewTitle(session: session)
            == "即将写下的内容"
        )
        #expect(
            ConfigurationCenterSessionBindingPresenter
                .memoryWriteDescription(session: session)
                .contains("这段回忆和你补充的话")
        )
    }

    @Test("preset status copy reports unsaved and saved states")
    func presetStatusCopyReflectsSavedState() {
        let session = ConfigurationSession()

        #expect(
            ConfigurationCenterSessionBindingPresenter
                .presetStatusText(session: session)
            == "当前生效配置尚未保存"
        )

        session.saveCurrentMemoryPreset()

        #expect(
            ConfigurationCenterSessionBindingPresenter
                .presetStatusText(
                    session: session,
                    savedAtFormatter: { _ in
                        "2026.07.06 19:30"
                    }
                )
            == "最近保存于 2026.07.06 19:30"
        )
    }
}
#endif
