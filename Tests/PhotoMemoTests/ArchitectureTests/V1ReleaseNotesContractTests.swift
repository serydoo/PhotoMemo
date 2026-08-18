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

        #expect(simplifiedChinese.contains("本次维护进一步明确照片交付状态"))
        #expect(simplifiedChinese.contains("没有可呈现内容的照片不会再被保存成空白的成功结果"))
        #expect(simplifiedChinese.contains("批量结果会从你交给时光记的照片数量开始说明"))
        #expect(english.contains("This maintenance update makes each photo’s delivery result easier to understand"))
        #expect(english.contains("A photo with no presentable content is no longer saved as a blank successful result"))
        #expect(english.contains("Batch results now start from the number of photos you gave MemoMark"))
        #expect(!simplifiedChinese.contains("完整 macOS 测试回归"))
        #expect(!english.contains("complete macOS test regression"))
    }

    @Test("release build settings reopen the App Store version train")
    func releaseBuildSettingsReopenTheAppStoreVersionTrain() throws {
        let projectSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo.xcodeproj/project.pbxproj"
        )

        #expect(!projectSource.contains("MARKETING_VERSION = 2.0.3;"))
        #expect(!projectSource.contains("CURRENT_PROJECT_VERSION = 75;"))
        #expect(
            projectSource.components(
                separatedBy: "MARKETING_VERSION = 2.1.2;"
            ).count == 11
        )
        #expect(
            projectSource.components(
                separatedBy: "CURRENT_PROJECT_VERSION = 86;"
            ).count == 13
        )
    }

    @Test("next release drafts keep internal TestFlight and App Store boundaries distinct")
    func nextReleaseDraftsKeepAudienceBoundariesDistinct() throws {
        let releaseNotes = try sourceText(
            "Docs/07_Releases/2026-08-08-2.1.0-release-notes.md"
        )
        let testFlightNotes = try sourceText(
            "Docs/07_Releases/2026-08-08-2.1.0-testflight-notes.md"
        )
        let appStoreNotes = try sourceText(
            "Docs/07_Releases/2026-08-08-2.1.0-app-store-whats-new.md"
        )

        #expect(releaseNotes.contains("# MemoMark 2.1.0 (76)"))
        #expect(testFlightNotes.contains("2.1.0 (76)"))
        #expect(appStoreNotes.contains("# MemoMark 2.1.0"))
        #expect(releaseNotes.contains("FAIL (Conditional)"))
        #expect(releaseNotes.contains("TX-001"))
        #expect(releaseNotes.contains("BP-001"))
        #expect(releaseNotes.contains("变更起点：2026-08-06 16:08"))
        #expect(testFlightNotes.contains("四个内容区域"))
        #expect(testFlightNotes.contains("重要日子"))
        #expect(testFlightNotes.contains("购买/恢复/兑换"))
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
