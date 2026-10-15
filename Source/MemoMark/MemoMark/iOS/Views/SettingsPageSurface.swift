#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI

struct SettingsPageSurface: View {

    private struct DiagnosticExportItem:
        Identifiable {

        let id = UUID()
        let fileURL: URL
    }

    private enum UsageGuideDestination: Hashable {
        case expression
        case story
        case welcome
        case workflow
    }

    @State private var usageGuideDestination: UsageGuideDestination?

    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize

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

    @State private var showsUsageGuide = false
    @State private var showsPhotoData = false
    @State private var showsFeedback = false

    @State
    private var showsExpressionGuide = false

    @Binding
    var showsWorkflowGuide: Bool

    @State
    private var showsWelcomeWorkflowGuide = false

    @State
    private var showsAboutMemoMark = false

    @State
    private var showsReleaseNotes = false

    @State
    private var showsAppStoreOpenError = false

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

    let onOpenTimeExpression: () -> Void
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

                expressionFeatureSection
                interfacePreferencesSection
                usageAndDataSection
                feedbackSection
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
        .navigationDestination(isPresented: $showsUsageGuide) {
            usageGuidePage
        }
        .navigationDestination(isPresented: $showsPhotoData) {
            photoDataPage
        }
        .navigationDestination(isPresented: $showsFeedback) {
            feedbackPage
        }
        .navigationDestination(isPresented: $showsExpressionGuide) {
            expressionGuidePage
        }
        .navigationDestination(isPresented: $showsAboutMemoMark) {
            aboutMemoMarkPage
        }
        .navigationDestination(isPresented: $showsReleaseNotes) {
            ReleaseNotesSheet(
                language: interfaceLanguage,
                version: appVersion,
                embedsNavigationStack: false
            )
        }
        .navigationDestination(isPresented: $showsWorkflowGuide) {
            workflowGuidePage
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
        .alert(
            localized("settings.about.store_unavailable.title", fallback: "暂时无法打开 App Store"),
            isPresented: $showsAppStoreOpenError
        ) {
            Button(localized("common.ok", fallback: "好"), role: .cancel) {}
        } message: {
            Text(localized("settings.about.store_unavailable.detail", fallback: "请稍后重试，或在 App Store 中搜索 MemoMark。"))
        }
    }

    private var expressionFeatureSection: some View {
        Button {
            showsExpressionGuide = true
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                Text(localized("settings.structure.expression.title", fallback: "时间锚点，让照片有了前后"))
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(localized("settings.structure.expression.detail", fallback: "生日看成长，纪念日看陪伴，未来日期看倒数。"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    Text(localized("settings.structure.expression.action", fallback: "看看照片会怎么说"))
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .accessibilityHidden(true)
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.accentColor)
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(ConfigurationUI.innerPanelPadding)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .groupedSurface()
        .accessibilityIdentifier("settings.expression-feature")
    }

    private var interfacePreferencesSection: some View {
        SettingsSectionSurface(title: localized("settings.structure.preferences.title", fallback: "界面偏好")) {
            InterfacePreferencesContent(
                language: interfaceLanguage,
                usesAccessibilityPickerStyle: dynamicTypeSize.isAccessibilitySize,
                appearance: appearancePreferenceBinding,
                interfaceLanguage: interfaceLanguageBinding
            )
            .padding(.vertical, 12)
        }
    }

    private var usageAndDataSection: some View {
        SettingsSectionSurface(title: localized("settings.structure.usage_data.title", fallback: "使用与数据")) {
            Button { showsUsageGuide = true } label: {
                SettingsActionRow(
                    title: localized("settings.structure.usage.title", fallback: "使用指南"),
                    detail: localized("settings.structure.usage.detail", fallback: "从 Apple Photos 开始，回到相册查看。"),
                    systemImage: "book.closed", tint: .blue, showsDivider: true
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("settings.usage-guide")
            Button { showsPhotoData = true } label: {
                SettingsActionRow(
                    title: localized("settings.structure.photo_data.title", fallback: "照片与数据"),
                    detail: localized("settings.structure.photo_data.detail", fallback: "支持的照片、保存方式与本地数据。"),
                    systemImage: "photo.on.rectangle", tint: .green, showsDivider: false
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("settings.photo-data")
        }
    }

    private var feedbackSection: some View {
        SettingsSectionSurface(title: localized("settings.structure.support.title", fallback: "一起把时光记做好")) {
            Button { showsFeedback = true } label: {
                SettingsActionRow(
                    title: localized("settings.structure.feedback.title", fallback: "问题与建议"),
                    detail: localized("settings.structure.feedback.detail", fallback: "邮件与小红书私信，都能直接找到开发者。"),
                    systemImage: "bubble.left.and.bubble.right", tint: .blue, showsDivider: true
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("settings.feedback-contact")
            Button { openAppStore(.review) } label: {
                SettingsActionRow(
                    title: localized("settings.about.rate.title", fallback: "给时光记打个分"),
                    detail: localized("settings.about.rate.detail", fallback: "去 App Store，聊聊你的使用感受。"),
                    systemImage: "star", tint: .orange, showsDivider: false
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("settings.rate-app")
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
                withTransaction(appearancePreferenceTransaction) {
                    appearancePreferenceRawValue = preference.rawValue
                }
            }
        )
    }

    private var appearancePreferenceTransaction: Transaction {
        var transaction = Transaction()
        transaction.animation = nil
        transaction.disablesAnimations = true
        return transaction
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

    private var gettingStartedSection: some View {
        GettingStartedSupportContent(
            language: interfaceLanguage,
            onShowAbout: { usageGuideDestination = .story },
            onShowWelcome: { usageGuideDestination = .welcome },
            onShowWorkflow: { usageGuideDestination = .workflow },
            onShowExpressionGuide: { usageGuideDestination = .expression }
        )
        .padding(.vertical, 12)
        .groupedSurface()
    }

    private var usageGuidePage: some View {
        settingsDetailPage(title: localized("settings.structure.usage.title", fallback: "使用指南")) {
            gettingStartedSection
        }
        .navigationDestination(item: $usageGuideDestination) { destination in
            switch destination {
            case .expression:
                expressionGuidePage
            case .story:
                aboutMemoMarkPage
            case .welcome:
                welcomeInformationPage
            case .workflow:
                workflowGuidePage
            }
        }
    }

    private var workflowGuidePage: some View {
        WorkflowGuideSurface(
            steps: WelcomePresentation.workflowSteps(for: interfaceLanguage),
            language: interfaceLanguage,
            onClose: nil,
            embedsNavigationStack: false
        )
    }

    private var welcomeInformationPage: some View {
        WelcomePageSurface(
            presentation: WelcomePresentation.localized(for: interfaceLanguage),
            language: interfaceLanguage,
            onStart: { usageGuideDestination = nil },
            onShowWorkflow: { showsWelcomeWorkflowGuide = true },
            embedsNavigationStack: false
        )
        .navigationDestination(isPresented: $showsWelcomeWorkflowGuide) {
            workflowGuidePage
        }
    }

    private var photoDataPage: some View {
        settingsDetailPage(title: localized("settings.structure.photo_data.title", fallback: "照片与数据")) {
            SettingsSectionSurface(title: localized("settings.photo_processing.title", fallback: "照片处理")) {
                PhotoProcessingSupportContent(
                    language: interfaceLanguage,
                    batchLimit: commerceSnapshot.batchLimit
                )
            }
            SettingsSectionSurface(title: localized("settings.data_safety.title", fallback: "数据安全")) {
                DataSafetySupportContent(language: interfaceLanguage)
            }
        }
    }

    private var feedbackPage: some View {
        settingsDetailPage(title: localized("settings.structure.feedback.title", fallback: "问题与建议")) {
            FeedbackSupportContent(
                language: interfaceLanguage,
                isTestFlightExperienceActive: isTestFlightExperienceActive,
                isPreparingDiagnosticExport: isPreparingDiagnosticExport,
                onPrepareDiagnosticExport: prepareDiagnosticExport,
                onOpenMailFeedback: openMailFeedback
            )
            .padding(.vertical, 12)
            .groupedSurface()
        }
    }

    private func settingsDetailPage<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ScrollView {
            VStack(spacing: ConfigurationSectionCardMetrics.sectionSpacing, content: content)
                .padding(.top, 16)
                .padding(.bottom, 34)
                .adaptiveScrollContent(horizontalPadding: ConfigurationUI.contentColumnPadding)
        }
        .background(ConfigurationUI.appBackground.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var aboutMemoMarkPage: some View {
        Group {
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
                    fallback: "关于 MemoMark 的诞生"
                )
            )
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var expressionGuidePage: some View {
        Group {
            ScrollView {
                SettingsExpressionGuide(
                    language: interfaceLanguage,
                    onOpenTimeExpression: {
                        showsExpressionGuide = false
                        usageGuideDestination = nil
                        Task { @MainActor in
                            await Task.yield()
                            onOpenTimeExpression()
                        }
                    }
                )
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
                    "settings.guide.expression.title",
                    fallback: "MemoMark 怎么讲述时间"
                )
            )
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var aboutSection: some View {
        SettingsSectionSurface(title: localized("settings.structure.about.title", fallback: "版本与关于")) {
            AboutSettingsContent(
                language: interfaceLanguage,
                compactVersion: compactVersion,
                onShowReleaseNotes: { showsReleaseNotes = true },
                onCheckForUpdates: { openAppStore(.updates) },
                onShowStory: { showsAboutMemoMark = true }
            )
            .padding(.bottom, 12)
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

    private func openAppStore(_ destination: MemoMarkAppStoreDestination) {
        openURL(destination.url) { accepted in
            showsAppStoreOpenError = !accepted
        }
    }

}
#endif
