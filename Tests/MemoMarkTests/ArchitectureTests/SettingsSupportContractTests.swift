import Foundation
import Testing

@Suite("Settings support and native controls")
struct SettingsSupportContractTests {

    @Test("settings presents installed version in user-facing fields")
    func settingsPresentsInstalledVersionFields() throws {
        let source = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/SettingsPageSurface.swift"
        )
        let aboutContent = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/AboutSettingsContent.swift"
        )
        let simplifiedChinese = try sourceText(
            "Source/MemoMark/MemoMark/zh-Hans.lproj/Localizable.strings"
        )
        let english = try sourceText(
            "Source/MemoMark/MemoMark/en.lproj/Localizable.strings"
        )

        #expect(source.contains("settings.structure.about.title"))
        #expect(source.contains("settings.version.compact_format"))
        #expect(simplifiedChinese.contains("\"settings.about.title\""))
        #expect(english.contains("\"settings.about.title\""))

        for key in [
            "settings.version.row_title",
            "settings.version.copyright",
            "settings.version.release_notes",
            "settings.version.release_notes_detail"
        ] {
            #expect(aboutContent.contains(key))
            #expect(simplifiedChinese.contains("\"\(key)\""))
            #expect(english.contains("\"\(key)\""))
        }
    }

    @Test("settings keeps email and direct Xiaohongshu feedback without GitHub")
    func settingsSeparatesFeedbackAndCommunityChannels() throws {
        let source = try sourceText("Source/MemoMark/MemoMark/iOS/Views/SettingsPageSurface.swift")
        let feedback = try sourceText("Source/MemoMark/MemoMark/iOS/Views/FeedbackSupportContent.swift")
        #expect(feedback.contains("serydoo@gmail.com"))
        #expect(feedback.contains("onOpenMailFeedback"))
        #expect(feedback.contains("直接私信反馈问题或建议"))
        #expect(feedback.contains(".textSelection(.enabled)"))
        #expect(!feedback.contains("GitHub"))
        #expect(!source.contains("openGitHubIssues"))
        #expect(!source.contains("github.com/serydoo/MemoMark/issues"))
        #expect(source.contains("FeedbackSupportContent("))
        #expect(!source.contains("CommunitySupportContent("))
        #expect(source.contains("isTestFlightExperienceActive: isTestFlightExperienceActive"))
        #expect(source.contains("onPrepareDiagnosticExport: prepareDiagnosticExport"))
        #expect(source.contains("onOpenMailFeedback: openMailFeedback"))
        #expect(!source.contains("communitySection"))
        #expect(!source.contains("settings.community.section_title"))

        let email = try #require(feedback.range(of: "settings.feedback.email.title")?.lowerBound)
        let social = try #require(feedback.range(of: "settings.feedback.xiaohongshu.title")?.lowerBound)
        let diagnostics = try #require(feedback.range(of: "settings.feedback.diagnostics.title")?.lowerBound)
        #expect(email < social)
        #expect(social < diagnostics)
        #expect(feedback.contains("if isTestFlightExperienceActive"))
        #expect(feedback.contains(".disabled(isPreparingDiagnosticExport)"))
        for locale in ["zh-Hans", "en", "ja", "ko"] {
            let resources = try sourceText("Source/MemoMark/MemoMark/\(locale).lproj/Localizable.strings")
            for key in ["settings.feedback.email.title", "settings.feedback.xiaohongshu.title",
                        "settings.feedback.xiaohongshu.headline", "settings.feedback.xiaohongshu.detail",
                        "settings.feedback.diagnostics.title", "settings.feedback.testflight.title"] {
                #expect(feedback.contains(key))
                #expect(resources.contains("\"\(key)\""))
            }
        }
    }

    @Test("getting started tells one concise MemoMark story")
    func gettingStartedUsesBoundedContentFamilies() throws {
        let source = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/SettingsPageSurface.swift"
        )
        let supportRows = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/SettingsSupportRowComponents.swift"
        )
        let gettingStarted = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/GettingStartedSupportContent.swift"
        )

        #expect(source.contains("private var gettingStartedSection"))
        #expect(source.contains("GettingStartedSupportContent("))
        #expect(gettingStarted.contains("让照片记得，它在人生里的位置。"))
        #expect(source.contains("DataSafetySupportContent("))
        #expect(supportRows.contains("struct SettingsPrivacyRow"))
        #expect(supportRows.contains("private struct SettingsRowIcon"))
        #expect(source.contains("settings.version.compact_format"))
        #expect(source.contains("private var aboutMemoMarkPage"))
        #expect(!source.contains("Xcode Cloud 构建"))
        #expect(!source.contains("系统扩展内存压力"))
        #expect(!source.contains("欢迎在小红书等公开渠道分享体验"))
    }

    @Test("settings disclosure headings use text without decorative icons")
    func settingsDisclosureHeadingsAreTextOnly() throws {
        let disclosureSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/SettingsSectionSurface.swift"
        )

        #expect(!disclosureSource.contains("CompactHeadingIcon"))
        #expect(!disclosureSource.contains("let systemImage"))
        #expect(!disclosureSource.contains("let tint"))
    }

    @Test("settings modules and expanded content share compact spacing")
    func settingsUsesOneCompactModuleRhythm() throws {
        let source = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/SettingsPageSurface.swift"
        )
        let bodyStart = try #require(
            source.range(of: "var body: some View")?.lowerBound
        )
        let bodyEnd = try #require(
            source.range(of: "private var interfacePreferencesSection")?.lowerBound
        )
        let body = source[bodyStart..<bodyEnd]
        let disclosure = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/SettingsSectionSurface.swift"
        )
        let memoMarkPlusCard = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/MemoMarkPlusSettingsCard.swift"
        )

        #expect(body.contains("VStack(spacing: ConfigurationSectionCardMetrics.sectionSpacing)"))
        #expect(!body.contains(".padding(.top, 18)"))
        #expect(disclosure.contains("VStack(alignment: .leading, spacing: 8)"))
        #expect(source.contains("MemoMarkPlusSettingsCard("))
        #expect(memoMarkPlusCard.contains("private var memoMarkPlusStatusRow"))
        #expect(memoMarkPlusCard.contains("private var memoMarkPlusBenefitsLabel"))
        #expect(memoMarkPlusCard.contains("HStack(alignment: .top, spacing: 12)"))
    }

    @Test("settings passes a resolved commerce projection into its MemoMark+ card")
    func settingsPassesResolvedCommerceProjectionIntoMemoMarkPlusCard() throws {
        let source = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/SettingsPageSurface.swift"
        )
        let memoMarkPlusCard = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/MemoMarkPlusSettingsCard.swift"
        )

        #expect(source.contains("MemoMarkPlusSettingsCard("))
        #expect(source.contains("isPlus: commerceSnapshot.isPlus"))
        #expect(source.contains("status: memoMarkPlusStatus"))
        #expect(source.contains("statusDetail: memoMarkPlusStatusDetail"))
        #expect(source.contains("accessibilityHint: memoMarkPlusAccessibilityHint"))
        #expect(memoMarkPlusCard.contains("let isPlus: Bool"))
        #expect(memoMarkPlusCard.contains("let status: String"))
        #expect(memoMarkPlusCard.contains("let statusDetail: String"))
        #expect(!memoMarkPlusCard.contains("remainingRecords"))
        #expect(!memoMarkPlusCard.contains("firstRecorderDate"))
    }

    @Test("settings keeps adaptive appearance and native language menu")
    func settingsCombinesAppearanceAndLanguageWithMatchingAdaptiveControls() throws {
        let source = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/SettingsPageSurface.swift"
        )
        let preferencesContent = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/InterfacePreferencesContent.swift"
        )
        let simplifiedChinese = try sourceText(
            "Source/MemoMark/MemoMark/zh-Hans.lproj/Localizable.strings"
        )
        let english = try sourceText(
            "Source/MemoMark/MemoMark/en.lproj/Localizable.strings"
        )

        #expect(source.contains("private var interfacePreferencesSection"))
        #expect(source.contains("InterfacePreferencesContent("))
        #expect(source.contains("appearancePreferenceBinding"))
        #expect(source.contains("interfaceLanguageBinding"))
        #expect(!source.contains("InterfacePreferencesContent.summary("))
        #expect(preferencesContent.contains("MemoMarkAppearancePreference.allCases"))
        #expect(preferencesContent.components(separatedBy: ".pickerStyle(.segmented)").count - 1 >= 1)
        #expect(preferencesContent.components(separatedBy: ".pickerStyle(.menu)").count - 1 >= 2)

        #expect(source.contains("settings.structure.preferences.title"))

        for key in [
            "settings.appearance.title",
            "settings.appearance.description",
            "settings.appearance.system",
            "settings.appearance.light",
            "settings.appearance.dark",
            "settings.interface.title",
            "settings.interface.description"
        ] {
            #expect(preferencesContent.contains(key))
            #expect(simplifiedChinese.contains("\"\(key)\""))
            #expect(english.contains("\"\(key)\""))
        }
    }

    @Test("workflow tutorial stays inside settings and closes back to settings")
    func workflowTutorialUsesSettingsOwnedPresentation() throws {
        let settingsSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/SettingsPageSurface.swift"
        )
        let workflowSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/WelcomePresentation.swift"
        )

        #expect(settingsSource.contains("var showsWorkflowGuide: Bool"))
        #expect(settingsSource.contains("isPresented: $showsWorkflowGuide"))
        #expect(settingsSource.contains("usageGuideDestination = .workflow"))
        #expect(settingsSource.contains(".navigationDestination(isPresented: $showsWorkflowGuide)"))
        #expect(settingsSource.contains("embedsNavigationStack: false"))
        #expect(!settingsSource.contains(".sheet(isPresented: $showsWorkflowGuide)"))
        #expect(!settingsSource.contains("let onShowWorkflow"))
        #expect(workflowSource.contains("let onClose: (() -> Void)?"))
        #expect(workflowSource.contains("welcome.workflow.close"))
    }

    @Test("interface-controlled settings and tutorials resolve localized copy")
    func interfaceControlledSettingsAndTutorialsResolveLocalizedCopy() throws {
        let settingsSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/SettingsPageSurface.swift"
        )
        let welcomeSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/WelcomePresentation.swift"
        )
        let preferencesSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/InterfacePreferencesContent.swift"
        )
        let simplifiedChinese = try sourceText(
            "Source/MemoMark/MemoMark/zh-Hans.lproj/Localizable.strings"
        )
        let english = try sourceText(
            "Source/MemoMark/MemoMark/en.lproj/Localizable.strings"
        )

        let settingsPageKeys = [
            "settings.navigation.title",
            "settings.interface.description",
            "settings.structure.usage.title",
            "settings.photo_processing.title",
            "settings.data_safety.title",
            "settings.structure.feedback.title",
            "settings.about.store_unavailable.detail"
        ]
        let tutorialKeys = [
            "welcome.workflow.title",
            "welcome.workflow.photos.title",
            "welcome.workflow.navigation_title",
            "welcome.workflow.close"
        ]

        for key in settingsPageKeys {
            #expect(
                settingsSource.contains(key)
                    || preferencesSource.contains(key)
            )
            #expect(simplifiedChinese.contains("\"\(key)\""))
            #expect(english.contains("\"\(key)\""))
        }

        for key in tutorialKeys {
            #expect(welcomeSource.contains(key))
            #expect(simplifiedChinese.contains("\"\(key)\""))
            #expect(english.contains("\"\(key)\""))
        }

        #expect(
            preferencesSource.contains(
                "仅影响界面文字；不改变填写内容与照片输出语言"
            )
        )
        #expect(!settingsSource.contains("菜单、设置、帮助与处理状态文字"))
        #expect(!simplifiedChinese.contains("菜单、设置、帮助与处理状态文字"))
        #expect(!english.contains("menus, settings, help, and processing status"))
    }

    @Test("photo processing starts with the original capture-information prerequisite")
    func photoProcessingStartsWithOriginalCaptureInformation() throws {
        let source = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/SettingsPageSurface.swift"
        )
        let photoProcessingSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/PhotoProcessingSupportContent.swift"
        )
        #expect(source.contains("PhotoProcessingSupportContent("))
        #expect(source.contains("batchLimit: commerceSnapshot.batchLimit"))
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
            "Source/MemoMark/MemoMark/iOS/Views/SettingsPageSurface.swift"
        )
        let aboutContent = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/AboutSettingsContent.swift"
        )

        #expect(source.contains("private var aboutSection"))
        #expect(source.contains("AboutSettingsContent("))
        #expect(aboutContent.contains("settings.version.release_notes"))
        #expect(source.contains("showsReleaseNotes = true"))
        #expect(source.contains("ReleaseNotesSheet("))
        #expect(source.contains("onCheckForUpdates: { openAppStore(.updates) }"))
        #expect(source.contains("Button { openAppStore(.review) } label:"))
        #expect(aboutContent.contains("settings.about.check_updates.title"))
        #expect(source.contains("settings.about.rate.title"))
        #expect(aboutContent.contains("settings.check-updates"))
        #expect(source.contains("settings.rate-app"))
        #expect(!source.contains("requestReview"))
        #expect(source.contains("showsAppStoreOpenError = !accepted"))
    }

    @Test("settings distinguishes reading chevrons from action links")
    func settingsUsesNeutralDisclosureAndAccentActionChevrons() throws {
        let source = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/SettingsPageSurface.swift"
        )
        let supportRows = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/SettingsSupportRowComponents.swift"
        )
        let actionRowStart = try #require(
            supportRows.range(of: "struct SettingsActionRow")?.lowerBound
        )
        let linkRowStart = try #require(
            supportRows.range(of: "struct SettingsLinkRow")?.lowerBound
        )
        let contentRowStart = try #require(
            supportRows.range(of: "private struct SettingsContentRow")?.lowerBound
        )
        let rowIconStart = try #require(
            supportRows.range(of: "private struct SettingsRowIcon")?.lowerBound
        )
        let actionRowSource = supportRows[actionRowStart..<linkRowStart]
        let linkRowSource = supportRows[linkRowStart..<contentRowStart]
        let contentRowSource = supportRows[contentRowStart..<rowIconStart]
        let disclosureSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/SettingsSectionSurface.swift"
        )

        #expect(actionRowSource.contains(".foregroundStyle(.tertiary)"))
        #expect(linkRowSource.contains("accessory: \"chevron.right\""))
        #expect(disclosureSource.contains("accessibilityAddTraits(.isHeader)"))
        #expect(contentRowSource.contains(".foregroundStyle(.secondary)"))
        #expect(!contentRowSource.contains(".foregroundStyle(Color.accentColor)"))
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
