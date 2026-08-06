import Foundation
import Testing

@Suite("V1 settings disclosure sections")
struct V1SettingsDisclosureContractTests {

    @Test("settings persists product-center disclosure state and keeps a tappable chevron")
    func settingsPersistsProductCenterDisclosureState() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1SettingsPageSurface.swift"
        )

        #expect(source.contains("private enum SettingsSection"))
        #expect(source.contains("@AppStorage("))
        #expect(source.contains("PhotoMemoSharedContainer.sharedUserDefaults"))
        #expect(source.contains("private var isGettingStartedExpanded = true"))
        #expect(source.contains("private var isPhotoProcessingExpanded = false"))
        #expect(source.contains("private var isDataSafetyExpanded = false"))
        #expect(source.contains("private var isFeedbackExpanded = false"))
        #expect(source.contains("private var isCommunityExpanded = false"))
        #expect(source.contains("private var isInterfacePreferencesExpanded = false"))
        #expect(source.contains("private var isAboutExpanded = false"))
        #expect(!source.contains("expandedSections: Set<SettingsSection>"))
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
            "settings.about.title",
            "settings.version.row_title",
            "settings.version.compact_format",
            "settings.version.copyright",
            "settings.version.release_notes",
            "settings.version.release_notes_detail"
        ] {
            #expect(source.contains(key))
            #expect(simplifiedChinese.contains("\"\(key)\""))
            #expect(english.contains("\"\(key)\""))
        }
    }

    @Test("settings separates formal feedback from community channels")
    func settingsSeparatesFeedbackAndCommunityChannels() throws {
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
        let githubPosition = try #require(
            source.range(of: "GitHub Issues")?.lowerBound
        )
        let communityStart = try #require(
            source.range(of: "private var communitySection")?.lowerBound
        )
        let qqPosition = try #require(
            source.range(
                of: "settings.feedback.qq.title",
                range: communityStart..<source.endIndex
            )?.lowerBound
        )
        let socialPosition = try #require(
            source.range(
                of: "settings.feedback.social.title",
                range: communityStart..<source.endIndex
            )?.lowerBound
        )

        #expect(emailPosition < testFlightPosition)
        #expect(testFlightPosition < githubPosition)
        #expect(githubPosition < communityStart)
        #expect(communityStart < qqPosition)
        #expect(qqPosition < socialPosition)
        #expect(source.contains("955680366"))
        #expect(source.contains(".textSelection(.enabled)"))
        #expect(source.contains("openMailFeedback()"))
        #expect(source.contains("openGitHubIssues()"))
        #expect(source.contains("if isTestFlightExperienceActive"))
        #expect(source.contains("private var feedbackSection"))
        #expect(source.contains("private var communitySection"))

        for key in [
            "settings.feedback.section_title",
            "settings.community.section_title",
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

    @Test("getting started tells one concise MemoMark story")
    func gettingStartedUsesBoundedContentFamilies() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1SettingsPageSurface.swift"
        )

        #expect(source.contains("private var gettingStartedSection"))
        #expect(source.contains("让照片记得，它在人生里的位置。"))
        #expect(source.contains("private func settingsPrivacyRow"))
        #expect(source.contains("private func settingsRowIcon"))
        #expect(source.contains("settings.version.compact_format"))
        #expect(source.contains("private var aboutMemoMarkSheet"))
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

    @Test("settings orders product-center content from beginning to reference")
    func settingsUsesProductCenterSectionOrder() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1SettingsPageSurface.swift"
        )
        let bodyStart = try #require(
            source.range(of: "var body: some View")?.lowerBound
        )
        let bodyEnd = try #require(
            source.range(of: "private var interfacePreferencesSection")?.lowerBound
        )
        let body = source[bodyStart..<bodyEnd]
        let orderedSections = [
            "memoMarkPlusSection",
            "gettingStartedSection",
            "photoProcessingSection",
            "dataSafetySection",
            "feedbackSection",
            "communitySection",
            "interfacePreferencesSection",
            "aboutSection"
        ]
        let positions = try orderedSections.map { section in
            try #require(body.range(of: section)?.lowerBound)
        }

        #expect(positions == positions.sorted())
    }

    @Test("settings combines appearance and language with matching adaptive controls")
    func settingsCombinesAppearanceAndLanguageWithMatchingAdaptiveControls() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1SettingsPageSurface.swift"
        )
        let simplifiedChinese = try sourceText(
            "Source/PhotoMemo/PhotoMemo/zh-Hans.lproj/Localizable.strings"
        )
        let english = try sourceText(
            "Source/PhotoMemo/PhotoMemo/en.lproj/Localizable.strings"
        )

        #expect(source.contains("private var interfacePreferencesSection"))
        #expect(source.contains("private var adaptiveAppearancePicker"))
        #expect(source.contains("private var adaptiveInterfaceLanguagePicker"))
        #expect(source.contains("MemoMarkAppearancePreference.allCases"))
        #expect(source.contains("appearancePreferenceBinding"))
        #expect(source.contains("interfaceLanguageBinding"))
        #expect(source.contains("interfacePreferenceControl("))
        #expect(source.components(separatedBy: ".pickerStyle(.segmented)").count - 1 >= 2)
        #expect(source.components(separatedBy: ".pickerStyle(.menu)").count - 1 >= 2)

        for key in [
            "settings.interface_preferences.title",
            "settings.appearance.title",
            "settings.appearance.description",
            "settings.appearance.system",
            "settings.appearance.light",
            "settings.appearance.dark",
            "settings.interface.title",
            "settings.interface.description"
        ] {
            #expect(source.contains(key))
            #expect(simplifiedChinese.contains("\"\(key)\""))
            #expect(english.contains("\"\(key)\""))
        }
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
            "settings.interface.description",
            "settings.getting_started.title",
            "settings.photo_processing.title",
            "settings.data_safety.title",
            "settings.feedback.section_title",
            "settings.community.section_title",
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

        #expect(
            settingsSource.contains(
                "控制时光记中支持切换的菜单、设置与处理状态文字"
            )
        )
        #expect(!settingsSource.contains("菜单、设置、帮助与处理状态文字"))
        #expect(!simplifiedChinese.contains("菜单、设置、帮助与处理状态文字"))
        #expect(!english.contains("menus, settings, help, and processing status"))
    }

    @Test("photo processing starts with the original capture-information prerequisite")
    func photoProcessingStartsWithOriginalCaptureInformation() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1SettingsPageSurface.swift"
        )
        let photoProcessingStart = try #require(
            source.range(of: "private var photoProcessingSection")?.lowerBound
        )
        let dataSafetyStart = try #require(
            source.range(of: "private var dataSafetySection")?.lowerBound
        )
        let photoProcessingSource = source[photoProcessingStart..<dataSafetyStart]
        let exifPosition = try #require(
            photoProcessingSource.range(of: "原始拍摄信息")?.lowerBound
        )
        let inputPosition = try #require(
            photoProcessingSource.range(of: "支持的照片")?.lowerBound
        )

        #expect(exifPosition < inputPosition)
        #expect(photoProcessingSource.contains("保留日期、地点与拍摄参数"))
        #expect(photoProcessingSource.contains("缺失时不影响照片处理"))
        #expect(!photoProcessingSource.contains("完美输出"))
    }

    @Test("about includes a functional update-log entry")
    func aboutIncludesFunctionalUpdateLogEntry() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1SettingsPageSurface.swift"
        )

        #expect(source.contains("private var aboutSection"))
        #expect(source.contains("settings.version.release_notes"))
        #expect(source.contains("showsReleaseNotes = true"))
        #expect(source.contains("V1ReleaseNotesSheet("))
    }

    @Test("settings distinguishes reading chevrons from action links")
    func settingsUsesNeutralDisclosureAndAccentActionChevrons() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1SettingsPageSurface.swift"
        )
        let actionRowStart = try #require(
            source.range(of: "private func settingsActionRow")?.lowerBound
        )
        let linkRowStart = try #require(
            source.range(of: "private func settingsLinkRow")?.lowerBound
        )
        let contentRowStart = try #require(
            source.range(of: "private func settingsContentRow")?.lowerBound
        )
        let versionRowStart = try #require(
            source.range(of: "private var settingsVersionRow")?.lowerBound
        )
        let disclosureStart = try #require(
            source.range(of: "private struct V1SettingsDisclosureSection")?.lowerBound
        )
        let actionRowSource = source[actionRowStart..<linkRowStart]
        let linkRowSource = source[linkRowStart..<contentRowStart]
        let contentRowSource = source[contentRowStart..<versionRowStart]
        let disclosureSource = source[disclosureStart...]

        #expect(actionRowSource.contains(".foregroundStyle(.tertiary)"))
        #expect(linkRowSource.contains("accessory: \"chevron.right\""))
        #expect(disclosureSource.contains(".foregroundStyle(.tertiary)"))
        #expect(source.contains(".foregroundStyle(Color.accentColor)"))
        #expect(source.contains("private var memoMarkPlusStatus"))
        #expect(source.contains("commerceSnapshot.remainingRecords"))
        #expect(contentRowSource.contains(".fixedSize(horizontal: false, vertical: true)"))
        #expect(!contentRowSource.contains(".lineLimit(1)"))
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
