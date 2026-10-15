import Foundation
import Testing

@Suite("Settings hierarchy and presentation ownership")
struct SettingsPresentationContractTests {
    private let pagePath = "Source/MemoMark/MemoMark/iOS/Views/SettingsPageSurface.swift"

    @Test("root prioritizes expression and preferences while long content stays in children")
    func rootHierarchy() throws {
        let source = try read(pagePath)
        let start = try #require(source.range(of: "var body: some View")?.lowerBound)
        let end = try #require(source.range(of: ".scrollDismissesKeyboard")?.lowerBound)
        let root = source[start..<end]
        let positions = try ["memoMarkPlusSection", "expressionFeatureSection", "interfacePreferencesSection",
                             "usageAndDataSection", "feedbackSection", "aboutSection"].map {
            try #require(root.range(of: $0)?.lowerBound)
        }
        #expect(positions == positions.sorted())
        for child in ["GettingStartedSupportContent(", "PhotoProcessingSupportContent(",
                      "DataSafetySupportContent(", "FeedbackSupportContent("] {
            #expect(!root.contains(child))
            #expect(source.contains(child))
        }
        #expect(!source.contains("SettingsDisclosureSection("))
        #expect(!source.contains("productCenter.gettingStartedExpanded"))
    }

    @Test("interface controls retain the existing preference owners and adaptive native pickers")
    func preferenceOwnership() throws {
        let source = try read(pagePath)
        let preferences = try read("Source/MemoMark/MemoMark/iOS/Views/InterfacePreferencesContent.swift")
        #expect(source.contains("MemoMarkLanguage.interfacePreferenceStorageKey"))
        #expect(source.contains("MemoMarkAppearancePreference.storageKey"))
        #expect(source.contains("MemoMarkSharedContainer.sharedUserDefaults"))
        #expect(source.contains("appearance: appearancePreferenceBinding"))
        #expect(source.contains("interfaceLanguage: interfaceLanguageBinding"))
        #expect(!source.contains("isInterfacePreferencesExpanded"))
        #expect(preferences.contains(".pickerStyle(.segmented)"))
        #expect(preferences.components(separatedBy: ".pickerStyle(.menu)").count - 1 >= 2)
        #expect(preferences.contains("不改变填写内容与照片输出语言"))
    }

    @Test("feature is a bounded route into the existing expression guide")
    func expressionRoute() throws {
        let source = try read(pagePath)
        #expect(source.contains("settings.structure.expression.title"))
        #expect(source.contains("settings.structure.expression.detail"))
        #expect(source.contains("settings.expression-feature"))
        #expect(source.contains("showsExpressionGuide = true"))
        #expect(source.contains(".navigationDestination(isPresented: $showsExpressionGuide)"))
        #expect(source.contains("SettingsExpressionGuide("))
        #expect(!source.contains("MemoryEngine("))
        #expect(!source.contains("ConfigurationSession("))
    }

    @Test("usage data and feedback use settings-owned child destinations")
    func childNavigation() throws {
        let source = try read(pagePath)
        for state in ["showsUsageGuide", "showsPhotoData", "showsFeedback", "showsAboutMemoMark", "showsReleaseNotes"] {
            #expect(source.contains(".navigationDestination(isPresented: $\(state))"))
        }
        #expect(source.contains("settings.usage-guide"))
        #expect(source.contains("settings.photo-data"))
        #expect(source.contains("settings.feedback-contact"))
        #expect(source.contains("embedsNavigationStack: false"))
        #expect(!source.contains("NavigationStack {"))
        #expect(source.contains(".adaptiveScrollContent("))
        #expect(source.contains("batchLimit: commerceSnapshot.batchLimit"))
    }

    @Test("workflow stays in Settings and still uses the existing binding")
    func workflowOwnership() throws {
        let source = try read(pagePath)
        #expect(source.contains("var showsWorkflowGuide: Bool"))
        #expect(source.contains(".navigationDestination(isPresented: $showsWorkflowGuide)"))
        #expect(source.contains("usageGuideDestination = .workflow"))
        #expect(source.contains("WorkflowGuideSurface("))
        #expect(!source.contains(".sheet(isPresented: $showsWorkflowGuide)"))
    }

    @Test("section presentation wraps text and exposes semantic headers without local state")
    func accessibleSections() throws {
        let section = try read("Source/MemoMark/MemoMark/iOS/Views/SettingsSectionSurface.swift")
        #expect(section.contains("accessibilityAddTraits(.isHeader)"))
        #expect(section.contains(".fixedSize(horizontal: false, vertical: true)"))
        #expect(!section.contains("@State"))
        #expect(!section.contains("lineLimit"))
        #expect(!section.contains(".animation("))
    }

    @Test("resolved commerce projection retains the original card and status owner")
    func commerceProjection() throws {
        let source = try read(pagePath)
        for line in ["MemoMarkPlusSettingsCard(", "isPlus: commerceSnapshot.isPlus", "status: memoMarkPlusStatus",
                     "statusDetail: memoMarkPlusStatusDetail", "onOpen: onOpenMemoMarkPlus"] { #expect(source.contains(line)) }
        let card = try read("Source/MemoMark/MemoMark/iOS/Views/MemoMarkPlusSettingsCard.swift")
        #expect(!card.contains("remainingRecords"))
        #expect(!card.contains("firstRecorderDate"))
    }

    @Test("Store actions are available and release notes remain internal")
    func storeRoutes() throws {
        let source = try read(pagePath)
        let about = try read("Source/MemoMark/MemoMark/iOS/Views/AboutSettingsContent.swift")
        #expect(source.contains("openAppStore(.review)"))
        #expect(source.contains("onCheckForUpdates: { openAppStore(.updates) }"))
        #expect(source.contains("showsReleaseNotes = true"))
        #expect(source.contains("ReleaseNotesSheet("))
        #expect(source.contains("showsAppStoreOpenError = !accepted"))
        #expect(!source.contains("requestReview"))
        #expect(source.contains("settings.rate-app"))
        #expect(about.contains("settings.check-updates"))
        #expect(about.contains("settings.about-story"))
        #expect(about.contains("SettingsVersionRow("))
        #expect(source.contains("CFBundleShortVersionString"))
        #expect(source.contains("CFBundleVersion"))
    }

    @Test("direct feedback survives without community and diagnostic ownership stays in Settings")
    func feedbackChannels() throws {
        let source = try read(pagePath)
        let feedback = try read("Source/MemoMark/MemoMark/iOS/Views/FeedbackSupportContent.swift")
        #expect(feedback.contains("serydoo@gmail.com"))
        #expect(feedback.contains("settings.feedback.xiaohongshu.title"))
        #expect(feedback.contains("直接私信反馈问题或建议"))
        #expect(feedback.contains(".textSelection(.enabled)"))
        #expect(!feedback.contains("GitHub"))
        #expect(!source.contains("CommunitySupportContent("))
        #expect(!source.contains("openGitHubIssues"))
        #expect(source.contains("onPrepareDiagnosticExport: prepareDiagnosticExport"))
        #expect(source.contains("onOpenMailFeedback: openMailFeedback"))
        #expect(feedback.contains("if isTestFlightExperienceActive"))
    }

    @Test("settings action and contact rows include the full padded hit region")
    func fullRowHitRegions() throws {
        let source = try read("Source/MemoMark/MemoMark/iOS/Views/SettingsSupportRowComponents.swift")
        let actionStart = try #require(source.range(of: "struct SettingsActionRow:")?.lowerBound)
        let actionEnd = try #require(source.range(of: "struct SettingsPrivacyRow:")?.lowerBound)
        let contactStart = try #require(source.range(of: "private struct SettingsContentRow:")?.lowerBound)
        let contactEnd = try #require(source.range(of: "private struct SettingsRowIcon:")?.lowerBound)
        #expect(source[actionStart..<actionEnd].contains(".padding(12)\n            .contentShape(Rectangle())"))
        #expect(source[contactStart..<contactEnd].contains(".padding(.vertical, 12)\n            .contentShape(Rectangle())"))
    }

    @Test("usage guide destinations push from the usage page so Back preserves context")
    func usageDestinationsRemainWithinUsageGuide() throws {
        let source = try read(pagePath)
        let start = try #require(source.range(of: "private var usageGuidePage:")?.lowerBound)
        let end = try #require(source.range(of: "private var photoDataPage:")?.lowerBound)
        let usagePage = source[start..<end]
        #expect(usagePage.contains(".navigationDestination(item: $usageGuideDestination)"))
        for route in ["expression", "story", "welcome", "workflow"] {
            #expect(source.contains("usageGuideDestination = .\(route)"))
            #expect(usagePage.contains("case .\(route):"))
        }
        #expect(source.contains(".navigationDestination(isPresented: $showsWorkflowGuide)"))
        #expect(!source.contains("NavigationStack {"))
    }

    private func read(_ relative: String) throws -> String {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        return try String(contentsOf: root.appendingPathComponent(relative), encoding: .utf8)
    }
}
