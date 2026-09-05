#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI

enum SettingsSectionEmphasis {
    case primary
    case secondary
    case system
}

struct SettingsPageSurface: View {

    private struct DiagnosticExportItem:
        Identifiable {

        let id = UUID()
        let fileURL: URL
    }

    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize

    private enum SettingsSection: Hashable, CaseIterable {
        case gettingStarted
        case photoProcessing
        case dataSafety
        case feedback
        case community
        case interfacePreferences
        case about
    }

    @Environment(\.openURL) private var openURL

    @AppStorage(
        MemoMarkLanguage.interfacePreferenceStorageKey,
        store: MemoMarkSharedContainer.sharedUserDefaults
    )
    private var interfaceLanguagePreferenceRawValue =
        MemoMarkInterfaceLanguagePreference.system.rawValue

    @AppStorage(
        MemoMarkAppearancePreference.storageKey,
        store: MemoMarkSharedContainer.sharedUserDefaults
    )
    private var appearancePreferenceRawValue =
        MemoMarkAppearancePreference.system.rawValue

    @AppStorage(
        "memomark.settings.productCenter.gettingStartedExpanded",
        store: MemoMarkSharedContainer.sharedUserDefaults
    )
    private var isGettingStartedExpanded = true

    @AppStorage(
        "memomark.settings.productCenter.photoProcessingExpanded",
        store: MemoMarkSharedContainer.sharedUserDefaults
    )
    private var isPhotoProcessingExpanded = false

    @AppStorage(
        "memomark.settings.productCenter.dataSafetyExpanded",
        store: MemoMarkSharedContainer.sharedUserDefaults
    )
    private var isDataSafetyExpanded = false

    @AppStorage(
        "memomark.settings.productCenter.feedbackExpanded",
        store: MemoMarkSharedContainer.sharedUserDefaults
    )
    private var isFeedbackExpanded = false

    @AppStorage(
        "memomark.settings.productCenter.communityExpanded",
        store: MemoMarkSharedContainer.sharedUserDefaults
    )
    private var isCommunityExpanded = false

    @AppStorage(
        "memomark.settings.productCenter.interfaceLanguageExpanded",
        store: MemoMarkSharedContainer.sharedUserDefaults
    )
    private var isInterfacePreferencesExpanded = false

    @AppStorage(
        "memomark.settings.productCenter.aboutExpanded",
        store: MemoMarkSharedContainer.sharedUserDefaults
    )
    private var isAboutExpanded = false

    @State
    private var showsExpressionGuide = false

    @State
    private var showsWorkflowGuide = false

    @State
    private var showsAboutMemoMark = false

    @State
    private var showsReleaseNotes = false

    @State
    private var diagnosticExportItem:
        DiagnosticExportItem?

    @State
    private var diagnosticExportErrorMessage: String?

    @State
    private var isPreparingDiagnosticExport = false

    let commerceSnapshot:
        MemoMarkCommerceSnapshot
    let onOpenMemoMarkPlus: () -> Void

    let onShowWelcome: () -> Void
    let onDismissKeyboard: () -> Void
    var onExportDiagnostics:
        () async throws -> URL = {
            throw MemoMarkError(
                code: .configurationUnavailable,
                message: "Diagnostics unavailable."
            )
        }

    var body: some View {
        ScrollView {
            VStack(spacing: ConfigurationSectionCardMetrics.sectionSpacing) {
                memoMarkPlusSection

                gettingStartedSection
                photoProcessingSection
                dataSafetySection
                feedbackSection
                communitySection
                interfacePreferencesSection
                aboutSection

                Text(
                    localized(
                        "settings.footer.closing",
                        fallback: "愿这些被时间标记的记忆，陪伴未来的你。"
                    )
                )
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
                .padding(.top, 12)
                .padding(.horizontal, 24)
            }
            .padding(.top, 16)
            .padding(.bottom, 34)
            .adaptiveScrollContent(
                horizontalPadding: ConfigurationUI.contentColumnPadding
            )
        }
        .scrollDismissesKeyboard(.interactively)
        .background(
            ConfigurationUI.appBackground
                .ignoresSafeArea()
        )
        .navigationTitle(
            localized(
                "settings.navigation.title",
                fallback: "设置"
            )
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(
            ConfigurationUI.panelBackground,
            for: .navigationBar
        )
        .toolbarBackground(
            .visible,
            for: .navigationBar
        )
        .sheet(isPresented: $showsExpressionGuide) {
            expressionGuideSheet
        }
        .sheet(isPresented: $showsAboutMemoMark) {
            aboutMemoMarkSheet
        }
        .sheet(isPresented: $showsReleaseNotes) {
            ReleaseNotesSheet(
                language: interfaceLanguage,
                version: appVersion
            )
            .memoMarkSheet(.browser)
        }
        .sheet(isPresented: $showsWorkflowGuide) {
            WorkflowGuideSurface(
                steps: WelcomePresentation.workflowSteps(
                    for: interfaceLanguage
                ),
                language: interfaceLanguage,
                onClose: {
                    showsWorkflowGuide = false
                }
            )
            .memoMarkSheet(.browser)
        }
        .sheet(item: $diagnosticExportItem) { item in
            DiagnosticsShareSheet(
                fileURL: item.fileURL
            )
        }
        .alert(
            localized(
                "settings.feedback.diagnostics.error_title",
                fallback: "无法导出诊断信息"
            ),
            isPresented: Binding(
                get: {
                    diagnosticExportErrorMessage != nil
                },
                set: { isPresented in
                    if !isPresented {
                        diagnosticExportErrorMessage = nil
                    }
                }
            )
        ) {
            Button(
                localized(
                    "common.ok",
                    fallback: "好"
                ),
                role: .cancel
            ) {}
        } message: {
            Text(
                diagnosticExportErrorMessage ?? ""
            )
        }
    }

    private var interfacePreferencesSection: some View {
        settingsDisclosureSection(
            section: .interfacePreferences,
            title: localized(
                "settings.interface_preferences.title",
                fallback: "界面"
            ),
            trailingValue: InterfacePreferencesContent.summary(
                language: interfaceLanguage,
                appearance: appearancePreferenceBinding.wrappedValue,
                interfaceLanguage: interfaceLanguageBinding.wrappedValue
            ),
            emphasis: .system
        ) {
            InterfacePreferencesContent(
                language: interfaceLanguage,
                usesAccessibilityPickerStyle: dynamicTypeSize.isAccessibilitySize,
                appearance: appearancePreferenceBinding,
                interfaceLanguage: interfaceLanguageBinding
            )
        }
    }

    private var appearancePreferenceBinding:
        Binding<MemoMarkAppearancePreference> {
        Binding(
            get: {
                MemoMarkAppearancePreference(
                    rawValue: appearancePreferenceRawValue
                ) ?? .system
            },
            set: { preference in
                appearancePreferenceRawValue = preference.rawValue
            }
        )
    }

    private var interfaceLanguageBinding:
        Binding<MemoMarkInterfaceLanguagePreference> {
        Binding(
            get: {
                MemoMarkInterfaceLanguagePreference(
                    rawValue: interfaceLanguagePreferenceRawValue
                ) ?? .system
            },
            set: { preference in
                interfaceLanguagePreferenceRawValue = preference.rawValue
            }
        )
    }


    private var memoMarkPlusSection: some View {
        MemoMarkPlusSettingsCard(
            isPlus: commerceSnapshot.isPlus,
            language: interfaceLanguage,
            status: memoMarkPlusStatus,
            statusDetail: memoMarkPlusStatusDetail,
            accessibilityHint: memoMarkPlusAccessibilityHint,
            onOpen: onOpenMemoMarkPlus
        )
    }

    private var memoMarkPlusStatus: String {
        if isTestFlightExperienceActive {
            return localized(
                "commerce.settings.testflight_status",
                fallback: "TestFlight 体验 · 无限记录"
            )
        }

        if commerceSnapshot.isPlus {
            if commerceSnapshot.firstRecorderDate != nil {
                return localized(
                    "commerce.settings.first_recorder_status",
                    fallback: "首批记录者 · 无限记录"
                )
            }

            if commerceSnapshot.isSubscription {
                return localized(
                    "commerce.settings.subscription_status",
                    fallback: "MemoMark+ 订阅会员 · 无限记录"
                )
            }

            return localized(
                "commerce.settings.plus_status",
                fallback: "已解锁 · 无限记录"
            )
        }

        if let firstRecorderDate =
                commerceSnapshot.firstRecorderDate {
            let dateText = firstRecorderDate.formatted(
                .dateTime
                    .year()
                    .month(.twoDigits)
                    .day(.twoDigits)
                    .locale(interfaceLanguage.locale)
            )
            return formatted(
                "commerce.settings.first_recorder_commemoration_status_format",
                fallback: "首批记录纪念 · %@",
                dateText
            )
        }

        if let remaining = commerceSnapshot.remainingRecords {
            return formatted(
                "commerce.settings.remaining_status",
                fallback: "免费剩余：%lld 张",
                Int64(remaining)
            )
        }

        return localized(
            "commerce.settings.free_status",
            fallback: "当前为免费体验"
        )
    }

    private var memoMarkPlusStatusDetail: String {
        if isTestFlightExperienceActive {
            return localized(
                "commerce.settings.testflight_detail",
                fallback: "正式版权益仍由 Apple 购买或兑换决定。"
            )
        }

        if commerceSnapshot.isPlus {
            if commerceSnapshot.isSubscription {
                return localized(
                    "commerce.settings.subscription_detail",
                    fallback: "订阅由 Apple 管理，可在设置中管理或恢复。"
                )
            }
            return localized(
                "commerce.settings.plus_detail",
                fallback: "权益由 Apple 管理，并可恢复购买。"
            )
        }

        return localized(
            "commerce.settings.upgrade_detail",
            fallback: "升级后可以继续无限记录。"
        )
    }

    private var memoMarkPlusAccessibilityHint: String {
        if isTestFlightExperienceActive {
            return localized(
                "commerce.settings.accessibility.testflight",
                fallback: "查看 TestFlight 临时体验权益"
            )
        }

        if commerceSnapshot.isPlus {
            if commerceSnapshot.firstRecorderDate != nil {
                return localized(
                    "commerce.settings.accessibility.plus",
                    fallback: "查看权益与首批记录者纪念印记"
                )
            }

            return localized(
                "commerce.settings.accessibility.plus_standard",
                fallback: "查看 MemoMark+ 永久权益"
            )
        }

        if commerceSnapshot.firstRecorderDate != nil {
            return localized(
                "commerce.settings.accessibility.first_recorder_commemoration",
                fallback: "查看首批记录纪念，并了解 MemoMark+"
            )
        }

        return localized(
            "commerce.settings.accessibility.free",
            fallback: "了解 MemoMark+ 完整记录能力"
        )
    }

    private var isTestFlightExperienceActive: Bool {
        commerceSnapshot.accessSource
            == .testFlightTemporary
    }

    private var interfaceLanguage: MemoMarkLanguage {
        MemoMarkInterfaceLanguagePreference(
            rawValue:
                interfaceLanguagePreferenceRawValue
        )?
        .resolvedLanguage
        ?? MemoMarkLanguage.interfaceStored
    }

    private func localized(
        _ key: String,
        fallback: String
    ) -> String {
        interfaceLanguage.localized(
            key: key,
            fallback: fallback
        )
    }

    private func formatted(
        _ key: String,
        fallback: String,
        _ arguments: CVarArg...
    ) -> String {
        String(
            format: localized(
                key,
                fallback: fallback
            ),
            locale: interfaceLanguage.locale,
            arguments: arguments
        )
    }

    private func settingsDisclosureSection<Content: View>(
        section: SettingsSection,
        title: String,
        trailingValue: String? = nil,
        emphasis: SettingsSectionEmphasis,
        @ViewBuilder content: () -> Content
    ) -> some View {
        SettingsDisclosureSection(
            title: title,
            trailingValue: trailingValue,
            language: interfaceLanguage,
            emphasis: emphasis,
            isExpanded: expansionBinding(for: section),
            content: content
        )
    }

    private func expansionBinding(
        for section: SettingsSection
    ) -> Binding<Bool> {
        switch section {
        case .gettingStarted:
            $isGettingStartedExpanded
        case .photoProcessing:
            $isPhotoProcessingExpanded
        case .dataSafety:
            $isDataSafetyExpanded
        case .feedback:
            $isFeedbackExpanded
        case .community:
            $isCommunityExpanded
        case .interfacePreferences:
            $isInterfacePreferencesExpanded
        case .about:
            $isAboutExpanded
        }
    }

    private var gettingStartedSection: some View {
        settingsDisclosureSection(
            section: .gettingStarted,
            title: localized(
                "settings.getting_started.title",
                fallback: "开始使用"
            ),
            emphasis: .primary
        ) {
            GettingStartedSupportContent(
                language: interfaceLanguage,
                onShowAbout: { showsAboutMemoMark = true },
                onShowWelcome: onShowWelcome,
                onShowWorkflow: { showsWorkflowGuide = true },
                onShowExpressionGuide: { showsExpressionGuide = true }
            )
        }
    }

    private var aboutMemoMarkSheet: some View {
        NavigationStack {
            ScrollView {
                ConfigurationCardContainer {
                    AboutMemoMarkNarrativeContent(language: interfaceLanguage)
                }
                .padding(.top, 16)
                .padding(.bottom, 34)
                .adaptiveScrollContent(
                    horizontalPadding: ConfigurationUI.contentColumnPadding
                )
            }
            .background(
                ConfigurationUI.appBackground
                    .ignoresSafeArea()
            )
            .navigationTitle(
                localized(
                    "settings.overview.title",
                    fallback: "关于时光记"
                )
            )
            .navigationBarTitleDisplayMode(.inline)
            .memoMarkBrowserSheetToolbar(
                doneTitle: interfaceLanguage.localized(
                    key: "common.done",
                    fallback: "完成"
                ),
                onDone: { showsAboutMemoMark = false }
            )
        }
        .memoMarkSheet(.browser)
    }

    private var expressionGuideSheet: some View {
        NavigationStack {
            ScrollView {
                SettingsExpressionGuide(language: interfaceLanguage)
                    .padding(.top, 16)
                    .padding(.bottom, 34)
                    .adaptiveScrollContent(
                        horizontalPadding: ConfigurationUI.contentColumnPadding
                    )
            }
            .background(
                ConfigurationUI.appBackground
                    .ignoresSafeArea()
            )
            .navigationTitle(
                localized(
                    "settings.expression_guide.title",
                    fallback: "照片怎样讲述这一刻"
                )
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(
                        interfaceLanguage.localized(
                            key: "common.done",
                            fallback: "完成"
                        )
                    ) {
                        showsExpressionGuide = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .memoMarkSheet(.browser)
    }

    private var aboutSection: some View {
        settingsDisclosureSection(
            section: .about,
            title: localized(
                "settings.about.title",
                fallback: "关于"
            ),
            trailingValue: compactVersion,
            emphasis: .system
        ) {
            AboutSettingsContent(
                language: interfaceLanguage,
                compactVersion: compactVersion,
                onShowReleaseNotes: { showsReleaseNotes = true }
            )
        }
    }

    private var photoProcessingSection: some View {
        settingsDisclosureSection(
            section: .photoProcessing,
            title: localized(
                "settings.photo_processing.title",
                fallback: "照片处理"
            ),
            emphasis: .primary
        ) {
            PhotoProcessingSupportContent(
                language: interfaceLanguage,
                batchLimit: commerceSnapshot.batchLimit
            )
        }
    }

    private var feedbackSection: some View {
        settingsDisclosureSection(
            section: .feedback,
            title: localized(
                "settings.feedback.section_title",
                fallback: "反馈"
            ),
            emphasis: .secondary
        ) {
            FeedbackSupportContent(
                language: interfaceLanguage,
                isTestFlightExperienceActive: isTestFlightExperienceActive,
                isPreparingDiagnosticExport: isPreparingDiagnosticExport,
                onPrepareDiagnosticExport: prepareDiagnosticExport,
                onOpenMailFeedback: openMailFeedback,
                onOpenGitHubIssues: openGitHubIssues
            )
        }
    }

    private func prepareDiagnosticExport() {
        guard !isPreparingDiagnosticExport else {
            return
        }
        isPreparingDiagnosticExport = true
        Task { @MainActor in
            defer {
                isPreparingDiagnosticExport = false
            }
            do {
                diagnosticExportItem =
                    DiagnosticExportItem(
                        fileURL:
                            try await onExportDiagnostics()
                    )
            } catch {
                if let error = error as? MemoMarkError {
                    diagnosticExportErrorMessage = error.message
                } else {
                    let supportID =
                        ProductionDiagnosticSupportID.make(
                            prefix: "DIA",
                            operationID: UUID()
                        )
                    diagnosticExportErrorMessage = formatted(
                        "settings.feedback.diagnostics.error_detail",
                        fallback: "诊断文件暂时无法准备，请重新打开 MemoMark 后重试。（故障编号：%@）",
                        supportID
                    )
                }
            }
        }
    }

    private var communitySection: some View {
        settingsDisclosureSection(
            section: .community,
            title: localized(
                "settings.community.section_title",
                fallback: "社区"
            ),
            emphasis: .secondary
        ) {
            CommunitySupportContent(language: interfaceLanguage)
        }
    }

    private var dataSafetySection: some View {
        settingsDisclosureSection(
            section: .dataSafety,
            title: localized(
                "settings.data_safety.title",
                fallback: "数据安全"
            ),
            emphasis: .secondary
        ) {
            DataSafetySupportContent(language: interfaceLanguage)
        }
    }

    private var compactVersion: String {
        formatted(
            "settings.version.compact_format",
            fallback: "%@ (%@)",
            appVersion,
            appBuild
        )
    }

    private func openMailFeedback() {
        guard let url =
            URL(
                string:
                    "mailto:serydoo@gmail.com?subject=MemoMark%20\(appVersion)%20Feedback"
            )
        else {
            return
        }

        openURL(url)
    }

    private var appVersion: String {
        Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String ?? "—"
    }

    private var appBuild: String {
        Bundle.main.object(
            forInfoDictionaryKey: "CFBundleVersion"
        ) as? String ?? "—"
    }

    private func openGitHubIssues() {
        guard let url =
            URL(
                string:
                    "https://github.com/serydoo/MemoMark/issues"
            )
        else {
            return
        }

        openURL(url)
    }

}
#endif
