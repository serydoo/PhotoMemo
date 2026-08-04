import Foundation
import Testing

@Suite("V1 release notes")
struct V1ReleaseNotesContractTests {

    @Test("about presents the current release notes inside the app")
    func aboutPresentsCurrentReleaseNotesInsideTheApp() throws {
        let settingsSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1SettingsPageSurface.swift"
        )
        let releaseNotesSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1ReleaseNotesSheet.swift"
        )

        #expect(settingsSource.contains("V1ReleaseNotesSheet("))
        #expect(!settingsSource.contains("https://github.com/serydoo/PhotoMemo/releases"))
        #expect(releaseNotesSource.contains("let version: String"))
        #expect(releaseNotesSource.contains("settings.release_notes.header"))
        #expect(releaseNotesSource.contains("settings.release_notes.closing"))
    }

    @Test("release notes keep Chinese and English content in parity")
    func releaseNotesKeepChineseAndEnglishContentInParity() throws {
        let releaseNotesSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1ReleaseNotesSheet.swift"
        )
        let simplifiedChinese = try sourceText(
            "Source/PhotoMemo/PhotoMemo/zh-Hans.lproj/Localizable.strings"
        )
        let english = try sourceText(
            "Source/PhotoMemo/PhotoMemo/en.lproj/Localizable.strings"
        )

        for key in [
            "settings.release_notes.header",
            "settings.release_notes.version_format",
            "settings.release_notes.positioning",
            "settings.release_notes.reliable_recording.title",
            "settings.release_notes.reliable_recording.item_one",
            "settings.release_notes.reliable_recording.item_two",
            "settings.release_notes.reliable_recording.item_three",
            "settings.release_notes.reliable_recording.item_four",
            "settings.release_notes.reliable_recording.item_five",
            "settings.release_notes.configuration_center.title",
            "settings.release_notes.configuration_center.item_one",
            "settings.release_notes.configuration_center.item_two",
            "settings.release_notes.configuration_center.item_three",
            "settings.release_notes.advanced_modules.title",
            "settings.release_notes.advanced_modules.item_one",
            "settings.release_notes.advanced_modules.item_two",
            "settings.release_notes.advanced_modules.item_three",
            "settings.release_notes.advanced_modules.item_four",
            "settings.release_notes.advanced_modules.item_five",
            "settings.release_notes.iphone_and_settings.title",
            "settings.release_notes.iphone_and_settings.item_one",
            "settings.release_notes.iphone_and_settings.item_two",
            "settings.release_notes.iphone_and_settings.item_three",
            "settings.release_notes.iphone_and_settings.item_four",
            "settings.release_notes.iphone_and_settings.item_five",
            "settings.release_notes.expression_and_language.title",
            "settings.release_notes.expression_and_language.item_one",
            "settings.release_notes.expression_and_language.item_two",
            "settings.release_notes.expression_and_language.item_three",
            "settings.release_notes.expression_and_language.item_four",
            "settings.release_notes.unchanged.title",
            "settings.release_notes.unchanged.item_one",
            "settings.release_notes.unchanged.item_two",
            "settings.release_notes.unchanged.item_three",
            "settings.release_notes.unchanged.item_four",
            "settings.release_notes.unchanged.item_five",
            "settings.release_notes.verification.title",
            "settings.release_notes.verification.item_one",
            "settings.release_notes.verification.item_two",
            "settings.release_notes.verification.item_three",
            "settings.release_notes.verification.item_four",
            "settings.release_notes.verification.item_five",
            "settings.release_notes.next_stage.title",
            "settings.release_notes.next_stage.item_one",
            "settings.release_notes.next_stage.item_two",
            "settings.release_notes.next_stage.item_three",
            "settings.release_notes.closing"
        ] {
            #expect(releaseNotesSource.contains(key))
            #expect(simplifiedChinese.contains("\"\(key)\""))
            #expect(english.contains("\"\(key)\""))
        }

        #expect(
            simplifiedChinese.contains(
                "2.0.2 延续本地优先的记忆呈现方式"
            )
        )
        #expect(simplifiedChinese.contains("配置兼容、故障反馈和 Live Photo 保真问题"))
        #expect(simplifiedChinese.contains("动态资源不可用、配对失败或保存后未保真"))
        #expect(simplifiedChinese.contains("完整 macOS 测试回归通过 1,221 项"))
        #expect(
            simplifiedChinese.contains(
                "组合变量可以在恢复与预览时完整解析"
            )
        )
        #expect(simplifiedChinese.contains("模块使用稳定身份保存"))
        #expect(
            english.contains(
                "Version 2.0.2 continues MemoMark's local-first memory presentation"
            )
        )
        #expect(english.contains("configuration compatibility, actionable diagnostics, and Live Photo fidelity"))
        #expect(english.contains("Live Photos no longer silently fall back to still images"))
        #expect(english.contains("complete macOS test regression passed 1,221 tests"))
        #expect(
            english.contains(
                "Composed variables resolve completely during restore and Preview"
            )
        )
        #expect(english.contains("Modules now persist with stable identities"))
    }

    @Test("release build settings reopen the App Store version train")
    func releaseBuildSettingsReopenTheAppStoreVersionTrain() throws {
        let projectSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo.xcodeproj/project.pbxproj"
        )

        #expect(!projectSource.contains("MARKETING_VERSION = 2.0;"))
        #expect(!projectSource.contains("CURRENT_PROJECT_VERSION = 66;"))
        #expect(
            projectSource.components(
                separatedBy: "MARKETING_VERSION = 2.0.2;"
            ).count == 9
        )
        #expect(
            projectSource.components(
                separatedBy: "CURRENT_PROJECT_VERSION = 68;"
            ).count == 11
        )
    }

    private func sourceText(_ relativePath: String) throws -> String {
        let testsDirectory = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
        let repositoryRoot = testsDirectory
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        return try String(
            contentsOf: repositoryRoot.appendingPathComponent(relativePath),
            encoding: .utf8
        )
    }
}
