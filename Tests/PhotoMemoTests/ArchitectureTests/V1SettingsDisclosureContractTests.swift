import Foundation
import Testing

@Suite("V1 settings disclosure sections")
struct V1SettingsDisclosureContractTests {

    @Test("settings sections expose local disclosure state and a tappable chevron")
    func settingsSectionsExposeDisclosureContract() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1SettingsPageSurface.swift"
        )

        #expect(source.contains("private enum SettingsSection"))
        #expect(source.contains("@State\n    private var expandedSections"))
        #expect(source.contains("expandedSections: Set<SettingsSection> = []"))
        #expect(source.contains("private func settingsDisclosureSection"))
        #expect(source.contains("chevron.right"))
        #expect(source.contains("accessibilityValue"))
        #expect(source.contains("isExpanded.toggle()"))
    }

    @Test("settings combines product version and Xcode Cloud build")
    func settingsCombinesInstalledVersionFields() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1SettingsPageSurface.swift"
        )
        let simplifiedChinese = try sourceText(
            "Source/PhotoMemo/PhotoMemo/zh-Hans.lproj/Localizable.strings"
        )
        let english = try sourceText(
            "Source/PhotoMemo/PhotoMemo/en.lproj/Localizable.strings"
        )

        #expect(source.contains("private var combinedAppVersion"))
        #expect(
            source.contains(
                "\"\\(appVersion).\\(appBuild)\""
            )
        )
        for key in [
            "settings.version.section_title",
            "settings.version.row_title",
            "settings.version.headline_format",
            "settings.version.detail_format"
        ] {
            #expect(source.contains(key))
            #expect(simplifiedChinese.contains("\"\(key)\""))
            #expect(english.contains("\"\(key)\""))
        }
    }

    @Test("settings feedback combines community and formal channels")
    func settingsFeedbackCombinesAllChannels() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1SettingsPageSurface.swift"
        )
        let simplifiedChinese = try sourceText(
            "Source/PhotoMemo/PhotoMemo/zh-Hans.lproj/Localizable.strings"
        )
        let english = try sourceText(
            "Source/PhotoMemo/PhotoMemo/en.lproj/Localizable.strings"
        )

        let socialPosition = try #require(
            source.range(
                of: "settings.feedback.social.title"
            )?.lowerBound
        )
        let qqPosition = try #require(
            source.range(
                of: "settings.feedback.qq.title"
            )?.lowerBound
        )
        let testFlightPosition = try #require(
            source.range(of: "TestFlight 反馈")?.lowerBound
        )
        let emailPosition = try #require(
            source.range(of: "邮件反馈")?.lowerBound
        )
        let githubPosition = try #require(
            source.range(of: "GitHub Issues")?.lowerBound
        )

        #expect(socialPosition < qqPosition)
        #expect(qqPosition < testFlightPosition)
        #expect(testFlightPosition < emailPosition)
        #expect(emailPosition < githubPosition)
        #expect(source.contains("955680366"))
        #expect(source.contains("settings.feedback.closing"))
        #expect(source.contains(".textSelection(.enabled)"))
        #expect(source.contains("openMailFeedback()"))
        #expect(source.contains("openGitHubIssues()"))

        for key in [
            "settings.feedback.section_title",
            "settings.feedback.social.title",
            "settings.feedback.social.headline",
            "settings.feedback.social.detail",
            "settings.feedback.qq.title",
            "settings.feedback.qq.detail",
            "settings.feedback.testflight.title",
            "settings.feedback.testflight.headline",
            "settings.feedback.testflight.detail",
            "settings.feedback.email.title",
            "settings.feedback.email.detail",
            "settings.feedback.github.title",
            "settings.feedback.github.headline",
            "settings.feedback.github.detail",
            "settings.feedback.closing"
        ] {
            #expect(source.contains(key))
            #expect(simplifiedChinese.contains("\"\(key)\""))
            #expect(english.contains("\"\(key)\""))
        }
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
