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
            "settings.release_notes.time_expression.title",
            "settings.release_notes.time_expression.item_one",
            "settings.release_notes.time_expression.item_two",
            "settings.release_notes.configuration.title",
            "settings.release_notes.configuration.item_one",
            "settings.release_notes.configuration.item_two",
            "settings.release_notes.saving.title",
            "settings.release_notes.saving.item_one",
            "settings.release_notes.saving.item_two",
            "settings.release_notes.closing"
        ] {
            #expect(releaseNotesSource.contains(key))
            #expect(simplifiedChinese.contains("\"\(key)\""))
            #expect(english.contains("\"\(key)\""))
        }

        #expect(simplifiedChinese.contains("生日当天会用自然的语言记录"))
        #expect(simplifiedChinese.contains("可以选择跟随系统、浅色或深色界面"))
        #expect(simplifiedChinese.contains("保存回 Apple Photos 后的恢复与重复结果保护得到改进"))
        #expect(english.contains("Photos from a birthday use a natural expression"))
        #expect(english.contains("Choose System, Light, or Dark appearance"))
        #expect(english.contains("Improved recovery and duplicate-result protection"))
        #expect(!simplifiedChinese.contains("完整 macOS 测试回归"))
        #expect(!english.contains("complete macOS test regression"))
    }

    @Test("release build settings reopen the App Store version train")
    func releaseBuildSettingsReopenTheAppStoreVersionTrain() throws {
        let projectSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo.xcodeproj/project.pbxproj"
        )

        #expect(!projectSource.contains("MARKETING_VERSION = 2.0.2;"))
        #expect(!projectSource.contains("CURRENT_PROJECT_VERSION = 69;"))
        #expect(
            projectSource.components(
                separatedBy: "MARKETING_VERSION = 2.0.3;"
            ).count == 9
        )
        #expect(
            projectSource.components(
                separatedBy: "CURRENT_PROJECT_VERSION = 70;"
            ).count == 11
        )
    }

    @Test("next release drafts keep internal TestFlight and App Store boundaries distinct")
    func nextReleaseDraftsKeepAudienceBoundariesDistinct() throws {
        let internalNotes = try sourceText(
            "Docs/07_Releases/2026-08-06-2.0.3-internal-changelog.md"
        )
        let testFlightNotes = try sourceText(
            "Docs/07_Releases/2026-08-06-2.0.3-testflight-notes.md"
        )
        let appStoreNotes = try sourceText(
            "Docs/07_Releases/2026-08-06-2.0.3-app-store-whats-new.md"
        )

        #expect(internalNotes.contains("目标版本与构建号：`2.0.3 (70)`"))
        #expect(testFlightNotes.contains("目标版本与构建号：`2.0.3 (70)`"))
        #expect(appStoreNotes.contains("目标版本：`2.0.3`"))
        #expect(internalNotes.contains("FAIL (Conditional)"))
        #expect(internalNotes.contains("TX-001"))
        #expect(internalNotes.contains("BP-001"))
        #expect(internalNotes.contains("所有生产时间锚点路径统一按拍摄时区中的日历日判断关系"))
        #expect(internalNotes.contains("2026-08-06 之前，非生日锚点按精确时刻比较"))
        #expect(internalNotes.contains("该规则仅作为历史记录保留"))
        #expect(testFlightNotes.contains("照片拍摄时区中的日历日"))
        #expect(testFlightNotes.contains("同一日内早晚不同的时刻"))
        #expect(testFlightNotes.contains("不会仅因时分先后变成倒计时"))
        #expect(testFlightNotes.contains("补充文字会在下一行显示"))
        #expect(testFlightNotes.contains("不替换表达"))
        #expect(testFlightNotes.contains("强制终止、Apple Photos 延迟显示和恢复后的结果数量"))
        #expect(!testFlightNotes.contains("TX-001"))
        #expect(!testFlightNotes.contains("BP-001"))
        #expect(!appStoreNotes.contains("TX-001"))
        #expect(!appStoreNotes.contains("BP-001"))
        #expect(!appStoreNotes.contains("FAIL (Conditional)"))
        #expect(!appStoreNotes.contains("测试"))
        #expect(!appStoreNotes.contains("认证"))
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
