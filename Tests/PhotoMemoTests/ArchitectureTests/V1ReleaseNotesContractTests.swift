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

        #expect(simplifiedChinese.contains("2.0.1 标志着 V3 收尾"))
        #expect(simplifiedChinese.contains("日期会与预览一致地保留星期"))
        #expect(simplifiedChinese.contains("完整 macOS 测试回归通过 1,214 项"))
        #expect(simplifiedChinese.contains("两台 iPhone 15 Pro"))
        #expect(english.contains("Version 2.0.1 closes V3"))
        #expect(english.contains("Daily Record dates keep their weekday"))
        #expect(english.contains("complete macOS test regression passed 1,214 tests"))
        #expect(english.contains("two iPhone 15 Pro devices"))
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
