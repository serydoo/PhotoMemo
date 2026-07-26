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

    @Test("settings presents installed version in user-facing fields")
    func settingsPresentsInstalledVersionFields() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1SettingsPageSurface.swift"
        )
        let simplifiedChinese = try sourceText(
            "Source/PhotoMemo/PhotoMemo/zh-Hans.lproj/Localizable.strings"
        )
        let english = try sourceText(
            "Source/PhotoMemo/PhotoMemo/en.lproj/Localizable.strings"
        )

        for key in [
            "settings.version.section_title",
            "settings.version.app_name",
            "settings.version.version_format",
            "settings.version.build_format"
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

        let testFlightPosition = try #require(
            source.range(of: "TestFlight 反馈")?.lowerBound
        )
        let emailPosition = try #require(
            source.range(of: "邮件反馈")?.lowerBound
        )
        let qqPosition = try #require(
            source.range(
                of: "settings.feedback.qq.title"
            )?.lowerBound
        )
        let socialPosition = try #require(
            source.range(
                of: "settings.feedback.social.title"
            )?.lowerBound
        )
        let githubPosition = try #require(
            source.range(of: "GitHub Issues")?.lowerBound
        )

        #expect(testFlightPosition < emailPosition)
        #expect(emailPosition < qqPosition)
        #expect(qqPosition < socialPosition)
        #expect(socialPosition < githubPosition)
        #expect(source.contains("955680366"))
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
            "settings.feedback.github.detail"
        ] {
            #expect(source.contains(key))
            #expect(simplifiedChinese.contains("\"\(key)\""))
            #expect(english.contains("\"\(key)\""))
        }
    }

    @Test("settings uses one story and concise information cards")
    func settingsUsesBoundedContentFamilies() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1SettingsPageSurface.swift"
        )

        #expect(source.contains("private var overviewSection"))
        #expect(source.contains("让照片知道，它位于谁的人生里"))
        #expect(source.contains("private func settingsPrivacyRow"))
        #expect(source.contains("\"checkmark.circle.fill\""))
        #expect(source.contains("settings.version.version_format"))
        #expect(source.contains("settings.version.build_format"))
        #expect(!source.contains("Xcode Cloud 构建"))
        #expect(!source.contains("系统扩展内存压力"))
        #expect(!source.contains("欢迎在小红书等公开渠道分享体验"))
    }

    @Test("settings disclosure headings use text without decorative icons")
    func settingsDisclosureHeadingsAreTextOnly() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1SettingsPageSurface.swift"
        )
        let disclosureStart = try #require(
            source.range(of: "private struct V1SettingsDisclosureSection")?.lowerBound
        )
        let disclosureSource = source[disclosureStart...]

        #expect(!disclosureSource.contains("V1CompactHeadingIcon"))
        #expect(!disclosureSource.contains("let systemImage"))
        #expect(!disclosureSource.contains("let tint"))
    }

    @Test("settings orders commerce, brand, control, and reference content")
    func settingsUsesIntentionalSectionOrder() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1SettingsPageSurface.swift"
        )
        let bodyStart = try #require(
            source.range(of: "var body: some View")?.lowerBound
        )
        let bodyEnd = try #require(
            source.range(of: "private var interfaceLanguageSection")?.lowerBound
        )
        let body = source[bodyStart..<bodyEnd]
        let orderedSections = [
            "memoMarkPlusSection",
            "overviewSection",
            "guideSection",
            "supportSection",
            "principleSection",
            "feedbackSection",
            "interfaceLanguageSection",
            "releaseSection"
        ]
        let positions = try orderedSections.map { section in
            try #require(body.range(of: section)?.lowerBound)
        }

        #expect(positions == positions.sorted())
    }

    @Test("workflow tutorial stays inside settings and closes back to settings")
    func workflowTutorialUsesSettingsOwnedPresentation() throws {
        let settingsSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1SettingsPageSurface.swift"
        )
        let workflowSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1WelcomePresentation.swift"
        )
        let configurationCenterSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift"
        )

        #expect(settingsSource.contains("private var showsWorkflowGuide = false"))
        #expect(settingsSource.contains("isPresented: $showsWorkflowGuide"))
        #expect(settingsSource.contains("showsWorkflowGuide = true"))
        #expect(settingsSource.contains("showsWorkflowGuide = false"))
        #expect(!settingsSource.contains("let onShowWorkflow"))
        #expect(workflowSource.contains("let onClose: (() -> Void)?"))
        #expect(workflowSource.contains("welcome.workflow.close"))

        let settingsStart = try #require(
            configurationCenterSource.range(of: "private var settingsSheet")?.lowerBound
        )
        let settingsSourceTail = configurationCenterSource[settingsStart...]
        #expect(!settingsSourceTail.contains("onShowWorkflow:"))
    }

    @Test("interface-controlled settings and tutorials resolve localized copy")
    func interfaceControlledSettingsAndTutorialsResolveLocalizedCopy() throws {
        let settingsSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1SettingsPageSurface.swift"
        )
        let welcomeSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1WelcomePresentation.swift"
        )
        let simplifiedChinese = try sourceText(
            "Source/PhotoMemo/PhotoMemo/zh-Hans.lproj/Localizable.strings"
        )
        let english = try sourceText(
            "Source/PhotoMemo/PhotoMemo/en.lproj/Localizable.strings"
        )

        let settingsKeys = [
            "settings.navigation.title",
            "settings.overview.title",
            "settings.guide.title",
            "settings.support.title",
            "settings.privacy.title",
            "settings.feedback.priority_heading",
            "settings.feedback.community_heading",
            "settings.accessibility.expanded",
            "settings.accessibility.collapsed"
        ]
        let tutorialKeys = [
            "welcome.workflow.title",
            "welcome.workflow.photos.title",
            "welcome.workflow.navigation_title",
            "welcome.workflow.close"
        ]

        for key in settingsKeys {
            #expect(settingsSource.contains(key))
            #expect(simplifiedChinese.contains("\"\(key)\""))
            #expect(english.contains("\"\(key)\""))
        }

        for key in tutorialKeys {
            #expect(welcomeSource.contains(key))
            #expect(simplifiedChinese.contains("\"\(key)\""))
            #expect(english.contains("\"\(key)\""))
        }
    }

    @Test("capability starts with the original EXIF prerequisite")
    func capabilityStartsWithOriginalEXIFPrerequisite() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1SettingsPageSurface.swift"
        )
        let supportStart = try #require(
            source.range(of: "private var supportSection")?.lowerBound
        )
        let feedbackStart = try #require(
            source.range(of: "private var feedbackSection")?.lowerBound
        )
        let supportSource = source[supportStart..<feedbackStart]
        let exifPosition = try #require(
            supportSource.range(of: "原始拍摄信息")?.lowerBound
        )
        let inputPosition = try #require(
            supportSource.range(of: "照片输入")?.lowerBound
        )

        #expect(exifPosition < inputPosition)
        #expect(supportSource.contains("保留原始 EXIF"))
        #expect(supportSource.contains("EXIF 缺失时仍可处理"))
        #expect(!supportSource.contains("完美输出"))
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
