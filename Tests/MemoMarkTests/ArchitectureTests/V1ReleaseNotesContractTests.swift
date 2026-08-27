import Foundation
import Testing

@Suite("V1 release notes")
struct V1ReleaseNotesContractTests {

    @Test("about presents the current release notes inside the app")
    func aboutPresentsCurrentReleaseNotesInsideTheApp() throws {
        let settingsSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/V1SettingsPageSurface.swift"
        )
        let releaseNotesSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/V1ReleaseNotesSheet.swift"
        )

        #expect(settingsSource.contains("V1ReleaseNotesSheet("))
        #expect(!settingsSource.contains("https://github.com/serydoo/MemoMark/releases"))
        #expect(releaseNotesSource.contains("let version: String"))
        #expect(releaseNotesSource.contains("settings.release_notes.header"))
        #expect(releaseNotesSource.contains("settings.release_notes.closing"))
    }

    @Test("release notes keep Chinese and English content in parity")
    func releaseNotesKeepChineseAndEnglishContentInParity() throws {
        let releaseNotesSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/V1ReleaseNotesSheet.swift"
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

        #expect(simplifiedChinese.contains("这次更新让配置、照片交接和本地恢复更连贯"))
        #expect(simplifiedChinese.contains("照片说明和保存位置现在与记忆卡设置放在一起"))
        #expect(simplifiedChinese.contains("完整动态照片会在验证配对后作为新的动态照片保存"))
        #expect(english.contains("This update makes Configuration Center continuity clearer"))
        #expect(english.contains("Photo Description and save destination now live with Memory Card settings"))
        #expect(english.contains("A complete Live Photo is returned to Photos as a new Live Photo only after its pairing is verified"))
        #expect(!simplifiedChinese.contains("完整 macOS 测试回归"))
        #expect(!english.contains("complete macOS test regression"))
    }

    @Test("release build settings reopen the App Store version train")
    func releaseBuildSettingsReopenTheAppStoreVersionTrain() throws {
        let projectSource = try sourceText(
            "Source/MemoMark/MemoMark.xcodeproj/project.pbxproj"
        )
        let releaseManifest = try sourceText(
            "Docs/07_Releases/2026-08-27-2.2.2-sync-manifest.md"
        )
        let releaseIdentity = try #require(
            releaseManifest
                .split(whereSeparator: { $0 == "\n" })
                .first(where: { $0.hasPrefix("# MemoMark ") })
        )
        let identityParts = releaseIdentity.split(separator: " ")
        let version = String(try #require(identityParts.dropFirst(2).first))
        let build = String(
            try #require(identityParts.dropFirst(3).first)
        )
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")

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
        #expect(marketingVersions == [version])
        #expect(projectBuilds == [build])
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
