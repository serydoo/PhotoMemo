import Foundation
import Testing

@Suite("V1 release notes")
struct V1ReleaseNotesContractTests {

    @Test("about presents the current release notes inside the app")
    func aboutPresentsCurrentReleaseNotesInsideTheApp() throws {
        let settingsSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/SettingsPageSurface.swift"
        )
        let releaseNotesSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/ReleaseNotesSheet.swift"
        )

        #expect(settingsSource.contains("ReleaseNotesSheet("))
        #expect(!settingsSource.contains("https://github.com/serydoo/MemoMark/releases"))
        #expect(releaseNotesSource.contains("let version: String"))
        #expect(releaseNotesSource.contains("settings.release_notes.header"))
        #expect(releaseNotesSource.contains("settings.release_notes.closing"))
    }

    @Test("release notes keep Chinese and English content in parity")
    func releaseNotesKeepChineseAndEnglishContentInParity() throws {
        let releaseNotesSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/ReleaseNotesSheet.swift"
        )
        let simplifiedChinese = try sourceText(
            "Source/MemoMark/MemoMark/zh-Hans.lproj/Localizable.strings"
        )
        let english = try sourceText(
            "Source/MemoMark/MemoMark/en.lproj/Localizable.strings"
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

        #expect(simplifiedChinese.contains("从 2.3.0 开始"))
        #expect(simplifiedChinese.contains("经典白、极简与胶片时间"))
        #expect(simplifiedChinese.contains("更丰富的自定义空间"))
        #expect(simplifiedChinese.contains("重新整理了记忆对象的编辑与时间锚点"))
        #expect(simplifiedChinese.contains("每次处理都会生成新的记忆照片，不覆盖原图"))
        #expect(english.contains("Since 2.3.0"))
        #expect(english.contains("Classic White, Minimal, and FilmMark"))
        #expect(english.contains("more room to decide"))
        #expect(english.contains("reorganized Memory Object editing and Time Anchors"))
        #expect(english.contains("each process creates a new memory photo without replacing the original"))
        #expect(!simplifiedChinese.contains("完整 macOS 测试回归"))
        #expect(!english.contains("complete macOS test regression"))
    }

    @Test("release build settings reopen the App Store version train")
    func releaseBuildSettingsReopenTheAppStoreVersionTrain() throws {
        let projectSource = try sourceText(
            "Source/MemoMark/MemoMark.xcodeproj/project.pbxproj"
        )
        let releaseManifest = try sourceText(
            "Docs/07_Releases/2026-09-22-2.3.3-sync-manifest.md"
        )
        #expect(releaseManifest.contains("当前 marketing version：`2.3.3`"))
        #expect(releaseManifest.contains("当前 build number：`111`"))

        #expect(!projectSource.contains("MARKETING_VERSION = 2.0.3;"))
        #expect(!projectSource.contains("CURRENT_PROJECT_VERSION = 75;"))
        let marketingVersions = Set(
            projectSource
                .split(whereSeparator: { $0 == "\n" })
                .compactMap { line -> String? in
                    guard line.contains("MARKETING_VERSION =") else {
                        return nil
                    }
                    return line
                        .split(separator: "=")
                        .last?
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .replacingOccurrences(of: ";", with: "")
                }
        )
        let projectBuilds = Set(
            projectSource
                .split(whereSeparator: { $0 == "\n" })
                .compactMap { line -> String? in
                    guard line.contains("CURRENT_PROJECT_VERSION =") else {
                        return nil
                    }
                    return line
                        .split(separator: "=")
                        .last?
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .replacingOccurrences(of: ";", with: "")
                }
        )
        #expect(marketingVersions == ["2.3.3"])
        #expect(projectBuilds == ["111"])
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
