#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

private enum V1SettingsSectionEmphasis {
    case primary
    case secondary
    case system
}

struct V1SettingsPageSurface: View {

    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize

    private enum SettingsSection: Hashable, CaseIterable {
        case gettingStarted
        case photoProcessing
        case dataSafety
        case feedback
        case community
        case interfaceLanguage
        case about
    }

    @Environment(\.openURL) private var openURL

    @AppStorage(
        MemoMarkLanguage.interfacePreferenceStorageKey,
        store: PhotoMemoSharedContainer.sharedUserDefaults
    )
    private var interfaceLanguagePreferenceRawValue =
        MemoMarkInterfaceLanguagePreference.system.rawValue

    @AppStorage(
        "memomark.settings.productCenter.gettingStartedExpanded",
        store: PhotoMemoSharedContainer.sharedUserDefaults
    )
    private var isGettingStartedExpanded = true

    @AppStorage(
        "memomark.settings.productCenter.photoProcessingExpanded",
        store: PhotoMemoSharedContainer.sharedUserDefaults
    )
    private var isPhotoProcessingExpanded = false

    @AppStorage(
        "memomark.settings.productCenter.dataSafetyExpanded",
        store: PhotoMemoSharedContainer.sharedUserDefaults
    )
    private var isDataSafetyExpanded = false

    @AppStorage(
        "memomark.settings.productCenter.feedbackExpanded",
        store: PhotoMemoSharedContainer.sharedUserDefaults
    )
    private var isFeedbackExpanded = false

    @AppStorage(
        "memomark.settings.productCenter.communityExpanded",
        store: PhotoMemoSharedContainer.sharedUserDefaults
    )
    private var isCommunityExpanded = false

    @AppStorage(
        "memomark.settings.productCenter.interfaceLanguageExpanded",
        store: PhotoMemoSharedContainer.sharedUserDefaults
    )
    private var isInterfaceLanguageExpanded = false

    @AppStorage(
        "memomark.settings.productCenter.aboutExpanded",
        store: PhotoMemoSharedContainer.sharedUserDefaults
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

    let commerceSnapshot:
        MemoMarkCommerceSnapshot
    let onOpenMemoMarkPlus: () -> Void

    let onShowWelcome: () -> Void
    let onDismissKeyboard: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                memoMarkPlusSection

                VStack(spacing: 12) {
                    gettingStartedSection
                    photoProcessingSection
                }
                .padding(.top, 18)

                VStack(spacing: 12) {
                    dataSafetySection
                    feedbackSection
                    communitySection
                }
                .padding(.top, 18)

                VStack(spacing: 12) {
                    interfaceLanguageSection
                    aboutSection
                }
                .padding(.top, 18)

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
                .padding(.top, 24)
                .padding(.horizontal, 24)
            }
            .padding(.top, 16)
            .padding(.bottom, 34)
            .v1AdaptiveScrollContent(
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
        .sheet(isPresented: $showsExpressionGuide) {
            expressionGuideSheet
        }
        .sheet(isPresented: $showsAboutMemoMark) {
            aboutMemoMarkSheet
        }
        .sheet(isPresented: $showsReleaseNotes) {
            V1ReleaseNotesSheet(
                language: interfaceLanguage,
                version: appVersion
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showsWorkflowGuide) {
            V1WorkflowGuideSurface(
                steps: V1WelcomePresentation.workflowSteps(
                    for: interfaceLanguage
                ),
                language: interfaceLanguage,
                onClose: {
                    showsWorkflowGuide = false
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    private var interfaceLanguageSection: some View {
        settingsDisclosureSection(
            section: .interfaceLanguage,
            title: localized(
                "settings.interface.title",
                fallback: "应用界面语言"
            ),
            trailingValue: interfaceLanguageBinding.wrappedValue.displayTitle,
            emphasis: .system
        ) {
            VStack(alignment: .leading, spacing: 12) {
                adaptiveInterfaceLanguagePicker

                Text(
                    localized(
                        "settings.interface.description",
                        fallback: "控制时光记中支持切换的菜单、设置与处理状态文字；不改变你填写的内容，也不替代配置中的输出语言。"
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private var adaptiveInterfaceLanguagePicker: some View {
        if dynamicTypeSize.isAccessibilitySize {
            interfaceLanguagePicker
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        } else {
            interfaceLanguagePicker
                .pickerStyle(.segmented)
        }
    }

    private var interfaceLanguagePicker: some View {
        Picker(
            localized(
                "settings.interface.title",
                fallback: "应用界面语言"
            ),
            selection: interfaceLanguageBinding
        ) {
            ForEach(
                MemoMarkInterfaceLanguagePreference.allCases,
                id: \.self
            ) { preference in
                Text(preference.displayTitle)
                    .tag(preference)
            }
        }
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
        Button(action: onOpenMemoMarkPlus) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 13) {
                    ZStack {
                        RoundedRectangle(
                            cornerRadius: 13,
                            style: .continuous
                        )
                        .fill(warmGold.opacity(0.11))

                        Image(
                            systemName:
                                commerceSnapshot.isPlus
                                ? "checkmark.seal.fill"
                                : "sparkles"
                        )
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(warmGold)
                    }
                    .frame(width: 46, height: 46)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("MemoMark+")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.primary)

                        Text(
                            localized(
                                "commerce.settings.hero_detail",
                                fallback: "继续保存那些未来值得回看的瞬间"
                            )
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 0)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(memoMarkPlusStatus)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(memoMarkPlusStatusDetail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: 6) {
                    Spacer(minLength: 0)

                    Text(
                        localized(
                            "commerce.settings.view_benefits",
                            fallback: "查看权益"
                        )
                    )
                    .font(.caption.weight(.semibold))

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(Color.accentColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(memoMarkPlusBackground)
        }
        .buttonStyle(.plain)
        .accessibilityHint(
            memoMarkPlusAccessibilityHint
        )
    }

    private var memoMarkPlusStatus: String {
        if isTestFlightExperienceActive {
            return localized(
                "commerce.settings.testflight_status",
                fallback: "TestFlight 体验 · 无限记录"
            )
        }

        if commerceSnapshot.firstRecorderDate != nil {
            return localized(
                "commerce.settings.first_recorder_status",
                fallback: "首批记录者 · 无限记录"
            )
        }

        if commerceSnapshot.isPlus {
            return localized(
                "commerce.settings.plus_status",
                fallback: "已解锁 · 无限记录"
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

    private var memoMarkPlusBackground: some View {
        RoundedRectangle(
            cornerRadius: 18,
            style: .continuous
        )
        .fill(ConfigurationUI.panelBackground)
        .overlay(
            RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
            .stroke(
                warmGold.opacity(0.24),
                lineWidth: 0.8
            )
        )
    }

    private var memoMarkPlusAccessibilityHint: String {
        if isTestFlightExperienceActive {
            return localized(
                "commerce.settings.accessibility.testflight",
                fallback: "查看 TestFlight 临时体验权益"
            )
        }

        if commerceSnapshot.firstRecorderDate != nil {
            return localized(
                "commerce.settings.accessibility.plus",
                fallback: "查看权益与首批记录者纪念印记"
            )
        }

        if commerceSnapshot.isPlus {
            return localized(
                "commerce.settings.accessibility.plus_standard",
                fallback: "查看 MemoMark+ 永久权益"
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

    private var warmGold: Color {
        Color(
            red: 0.58,
            green: 0.40,
            blue: 0.13
        )
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
        emphasis: V1SettingsSectionEmphasis,
        @ViewBuilder content: () -> Content
    ) -> some View {
        V1SettingsDisclosureSection(
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
        case .interfaceLanguage:
            $isInterfaceLanguageExpanded
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
            VStack(alignment: .leading, spacing: 14) {
                Text(
                    localized(
                        "settings.overview.headline",
                        fallback: "让照片记得，它在人生里的位置。"
                    )
                )
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(
                    localized(
                        "settings.getting_started.detail",
                        fallback: "照片不只记录拍摄时间，也能记下它在人生中的位置。"
                    )
                )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                gettingStartedActions
            }
        }
    }

    private var gettingStartedActions: some View {
        VStack(spacing: 0) {
            Button {
                showsAboutMemoMark = true
            } label: {
                settingsActionRow(
                    title: localized(
                        "settings.overview.title",
                        fallback: "关于时光记"
                    ),
                    detail: localized(
                        "settings.overview.action_detail",
                        fallback: "看看时光记为什么从一段人生里的时间开始。"
                    ),
                    systemImage: MemoMarkSymbol.information.name,
                    tint: .pink,
                    showsDivider: true
                )
            }
            .buttonStyle(.plain)

            Button(action: onShowWelcome) {
                settingsActionRow(
                    title: localized(
                        "settings.guide.welcome.title",
                        fallback: "重新查看欢迎说明"
                    ),
                    detail: localized(
                        "settings.guide.welcome.detail",
                        fallback: "从第一次打开时光记开始。"
                    ),
                    systemImage: MemoMarkSymbol.welcome.name,
                    tint: .orange,
                    showsDivider: true
                )
            }
            .buttonStyle(.plain)

            Button {
                showsWorkflowGuide = true
            } label: {
                settingsActionRow(
                    title: localized(
                        "settings.guide.workflow.title",
                        fallback: "看看日常怎么记录"
                    ),
                    detail: localized(
                        "settings.guide.workflow.detail",
                        fallback: "从 Apple Photos 分享，再回到相册查看。"
                    ),
                    systemImage: MemoMarkSymbol.workflow.name,
                    tint: .blue,
                    showsDivider: true
                )
            }
            .buttonStyle(.plain)

            Button {
                showsExpressionGuide = true
            } label: {
                settingsActionRow(
                    title: localized(
                        "settings.guide.expression.title",
                        fallback: "了解记忆表达"
                    ),
                    detail: localized(
                        "settings.guide.expression.detail",
                        fallback: "看看照片、记忆对象和时间锚点怎样一起留下回忆。"
                    ),
                    systemImage: MemoMarkSymbol.expressionFormula.name,
                    tint: .purple,
                    showsDivider: false
                )
            }
            .buttonStyle(.plain)
        }
        .background(settingsInsetBackground)
    }

    private var aboutMemoMarkSheet: some View {
        NavigationStack {
            ScrollView {
                V1ConfigurationCardContainer {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(
                            localized(
                                "settings.overview.headline",
                                fallback: "让照片记得，它在人生里的位置。"
                            )
                        )
                        .font(.headline.weight(.semibold))

                        ForEach(
                            aboutMemoMarkParagraphs,
                            id: \.self
                        ) { paragraph in
                            Text(paragraph)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .fixedSize(
                                    horizontal: false,
                                    vertical: true
                                )
                        }

                        Text(
                            localized(
                                "settings.overview.closing",
                                fallback: "愿大家都能享受这些被时间标记的记忆。"
                            )
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 34)
                .v1AdaptiveScrollContent(
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
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var aboutMemoMarkParagraphs: [String] {
        [
            localized(
                "settings.overview.paragraph_one",
                fallback: "陪伴孩子长大的过程中，我们留下了很多照片。时光记最初只想回答一个问题：打开照片时，能不能马上知道那一天，孩子多大？"
            ),
            localized(
                "settings.overview.paragraph_two",
                fallback: "从孩子出生的那一天开始，生日、纪念日和未来的重要日期都可以成为时间锚点。照片因此不只记录拍摄时间，也能呈现年龄、倒数，以及它位于一段人生的什么位置。"
            ),
            localized(
                "settings.overview.paragraph_three",
                fallback: "时光记不是给照片添加水印，而是把时间关系变成更容易读懂的回忆。照片只在你的设备上整理，原图始终保持不变。"
            )
        ]
    }

    private var expressionGuideSheet: some View {
        NavigationStack {
            ScrollView {
                V1SettingsExpressionGuide(language: interfaceLanguage)
                    .padding(.top, 16)
                    .padding(.bottom, 34)
                    .v1AdaptiveScrollContent(
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
                    fallback: "记忆表达说明"
                )
            )
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
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
            VStack(alignment: .leading, spacing: 10) {
                VStack(spacing: 0) {
                    settingsVersionRow

                    Button {
                        showsReleaseNotes = true
                    } label: {
                        settingsActionRow(
                            title: localized(
                                "settings.version.release_notes",
                                fallback: "更新日志"
                            ),
                            detail: localized(
                                "settings.version.release_notes_detail",
                                fallback: "看看时光记最近有哪些变化。"
                            ),
                            systemImage: "doc.text.fill",
                            tint: .blue,
                            showsDivider: false
                        )
                    }
                    .buttonStyle(.plain)
                }
                .background(settingsInsetBackground)

                Text(
                    localized(
                        "settings.version.copyright",
                        fallback: "© 2026 MemoMark"
                    )
                )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
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
            VStack(spacing: 0) {
                settingsInfoRow(
                    title: localized(
                        "settings.support.metadata.title",
                        fallback: "原始拍摄信息"
                    ),
                    headline: localized(
                        "settings.support.metadata.headline",
                        fallback: "保留日期、地点与拍摄参数；缺失时不影响照片处理。"
                    ),
                    detail: nil,
                    systemImage: MemoMarkSymbol.photoMetadata.name,
                    tint: .blue,
                    showsDivider: true
                )

                settingsInfoRow(
                    title: localized(
                        "settings.support.input.title",
                        fallback: "支持的照片"
                    ),
                    headline: localized(
                        "settings.support.input.headline",
                        fallback: "JPEG、HEIF、RAW / DNG 与 Live Photo"
                    ),
                    detail: nil,
                    systemImage: MemoMarkSymbol.originalPhoto.name,
                    tint: .pink,
                    showsDivider: true
                )

                settingsInfoRow(
                    title: localized(
                        "settings.support.batch.title",
                        fallback: "一次分享"
                    ),
                    headline: formatted(
                        "settings.support.batch.headline_format",
                        fallback: "最多 %lld 张照片",
                        Int64(commerceSnapshot.batchLimit)
                    ),
                    detail: localized(
                        "settings.support.batch.detail",
                        fallback: "更多照片请分次分享。"
                    ),
                    systemImage: MemoMarkSymbol.processing.name,
                    tint: .orange,
                    showsDivider: true
                )

                settingsInfoRow(
                    title: localized(
                        "settings.support.result.title",
                        fallback: "保存到 Apple Photos"
                    ),
                    headline: localized(
                        "settings.support.result.headline",
                        fallback: "生成一张新照片，原图保持不变"
                    ),
                    detail: nil,
                    systemImage: MemoMarkSymbol.applePhotos.name,
                    tint: .green,
                    showsDivider: false
                )
            }
            .background(settingsInsetBackground)
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
            VStack(spacing: 0) {
                settingsLinkRow(
                    title: localized(
                        "settings.feedback.email.title",
                        fallback: "邮件反馈"
                    ),
                    headline: "serydoo@gmail.com",
                    detail: localized(
                        "settings.feedback.email.detail",
                        fallback: "告诉我们你遇到的问题或想法。"
                    ),
                    systemImage: "envelope.fill",
                    tint: .blue,
                    showsDivider: true
                ) {
                    openMailFeedback()
                }

                if isTestFlightExperienceActive {
                    settingsInfoRow(
                        title: localized(
                            "settings.feedback.testflight.title",
                            fallback: "TestFlight 反馈"
                        ),
                        headline: localized(
                            "settings.feedback.testflight.headline",
                            fallback: "适合闪退、截图和录屏"
                        ),
                        detail: localized(
                            "settings.feedback.testflight.detail",
                            fallback: "优先使用系统内置反馈，方便带上设备和崩溃上下文。"
                        ),
                        systemImage: "wrench.and.screwdriver.fill",
                        tint: .orange,
                        showsDivider: true
                    )
                }

                settingsLinkRow(
                    title: localized(
                        "settings.feedback.github.title",
                        fallback: "GitHub Issues"
                    ),
                    headline: localized(
                        "settings.feedback.github.headline",
                        fallback: "公开可复现问题"
                    ),
                    detail: localized(
                        "settings.feedback.github.detail",
                        fallback: "适合记录稳定复现的缺陷和后续开发讨论。"
                    ),
                    systemImage: "chevron.left.forwardslash.chevron.right",
                    tint: .purple,
                    showsDivider: false
                ) {
                    openGitHubIssues()
                }
            }
            .background(settingsInsetBackground)
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
            VStack(spacing: 0) {
                settingsInfoRow(
                    title: localized(
                        "settings.feedback.qq.title",
                        fallback: "QQ 交流群"
                    ),
                    headline: "955680366",
                    detail: localized(
                        "settings.feedback.qq.detail",
                        fallback: "交流使用问题与产品想法。"
                    ),
                    systemImage: "person.2.fill",
                    tint: .blue,
                    showsDivider: true
                )
                .textSelection(.enabled)

                settingsInfoRow(
                    title: localized(
                        "settings.feedback.social.title",
                        fallback: "小红书、抖音"
                    ),
                    headline: localized(
                        "settings.feedback.social.headline",
                        fallback: "搜索 MemoMark"
                    ),
                    detail: localized(
                        "settings.feedback.social.detail",
                        fallback: "分享体验与建议。"
                    ),
                    systemImage: "at",
                    tint: .pink,
                    showsDivider: false
                )
                .textSelection(.enabled)
            }
            .background(settingsInsetBackground)
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
            VStack(spacing: 0) {
                settingsPrivacyRow(
                    title: localized(
                        "settings.privacy.local_processing.title",
                        fallback: "本地完成处理"
                    ),
                    detail: localized(
                        "settings.privacy.local_processing.detail",
                        fallback: "不会上传照片。"
                    ),
                    systemImage: "iphone",
                    tint: .cyan,
                    showsDivider: true
                )
                settingsPrivacyRow(
                    title: localized(
                        "settings.privacy.original.title",
                        fallback: "不修改原图"
                    ),
                    detail: localized(
                        "settings.privacy.original.detail",
                        fallback: "始终生成新的照片。"
                    ),
                    systemImage: MemoMarkSymbol.originalPhoto.name,
                    tint: .green,
                    showsDivider: true
                )
                settingsPrivacyRow(
                    title: localized(
                        "settings.privacy.local_configuration.title",
                        fallback: "配置保存在本机"
                    ),
                    detail: localized(
                        "settings.privacy.local_configuration.detail",
                        fallback: "记忆对象、时间锚点与任务记录保存在应用容器中。"
                    ),
                    systemImage: MemoMarkSymbol.localStorage.name,
                    tint: .purple,
                    showsDivider: true
                )
                settingsPrivacyRow(
                    title: localized(
                        "settings.privacy.delete_app.title",
                        fallback: "删除应用"
                    ),
                    detail: localized(
                        "settings.privacy.delete_app.detail",
                        fallback: "未单独备份的本地配置与记录会一起删除。"
                    ),
                    systemImage: MemoMarkSymbol.information.name,
                    tint: .secondary,
                    showsDivider: false
                )
            }
            .background(settingsInsetBackground)
        }
    }

    private var settingsInsetBackground: some View {
        RoundedRectangle(
            cornerRadius: 14,
            style: .continuous
        )
        .fill(ConfigurationUI.controlBackground.opacity(0.82))
        .overlay(
            RoundedRectangle(
                cornerRadius: 14,
                style: .continuous
            )
            .stroke(ConfigurationUI.faintHairline)
        )
    }

    private func settingsActionRow(
        title: String,
        detail: String,
        systemImage: String,
        tint: Color,
        showsDivider: Bool
    ) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                settingsRowIcon(
                    systemImage: systemImage,
                    tint: tint
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)

            if showsDivider {
                V1HorizontalDivider(horizontalInset: 12)
            }
        }
    }

    private func settingsRowIcon(
        systemImage: String,
        tint: Color
    ) -> some View {
        Image(systemName: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .frame(width: 32, height: 32)
            .background(
                RoundedRectangle(
                    cornerRadius: 9,
                    style: .continuous
                )
                .fill(tint.opacity(0.10))
            )
            .accessibilityHidden(true)
    }

    private func settingsPrivacyRow(
        title: String,
        detail: String,
        systemImage: String,
        tint: Color,
        showsDivider: Bool
    ) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                settingsRowIcon(
                    systemImage: systemImage,
                    tint: tint
                )

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)

            if showsDivider {
                V1HorizontalDivider(horizontalInset: 12)
            }
        }
    }

    private func settingsInfoRow(
        title: String,
        headline: String,
        detail: String?,
        systemImage: String,
        tint: Color,
        showsDivider: Bool = true
    ) -> some View {
        settingsContentRow(
            title: title,
            headline: headline,
            detail: detail,
            systemImage: systemImage,
            tint: tint,
            showsDivider: showsDivider
        )
    }

    @ViewBuilder
    private func settingsLinkRow(
        title: String,
        headline: String,
        detail: String?,
        systemImage: String,
        tint: Color,
        showsDivider: Bool = true,
        action: (() -> Void)? = nil
    ) -> some View {
        if let action {
            Button(action: action) {
                settingsContentRow(
                    title: title,
                    headline: headline,
                    detail: detail,
                    systemImage: systemImage,
                    tint: tint,
                    showsDivider: showsDivider,
                    accessory: "chevron.right"
                )
            }
            .buttonStyle(.plain)
        } else {
            settingsContentRow(
                title: title,
                headline: headline,
                detail: detail,
                systemImage: systemImage,
                tint: tint,
                showsDivider: showsDivider
            )
        }
    }

    private func settingsContentRow(
        title: String,
        headline: String,
        detail: String?,
        systemImage: String,
        tint: Color,
        showsDivider: Bool,
        accessory: String? = nil
    ) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                settingsRowIcon(
                    systemImage: systemImage,
                    tint: tint
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(headline)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    if let detail,
                       !detail.isEmpty {
                        Text(detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: 8)

                if let accessory {
                    Image(systemName: accessory)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 12)

            if showsDivider {
                V1HorizontalDivider(horizontalInset: 12)
            }
        }
    }

    private var settingsVersionRow: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                settingsRowIcon(
                    systemImage: MemoMarkSymbol.information.name,
                    tint: .secondary
                )

                Text(
                    localized(
                        "settings.version.row_title",
                        fallback: "版本"
                    )
                )
                .font(.subheadline.weight(.semibold))

                Spacer(minLength: 8)

                Text(compactVersion)
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(12)

            V1HorizontalDivider(horizontalInset: 12)
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
                    "https://github.com/serydoo/PhotoMemo/issues"
            )
        else {
            return
        }

        openURL(url)
    }

}

private struct V1SettingsDisclosureSection<Content: View>: View {

    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize

    @Environment(\.accessibilityReduceMotion)
    private var accessibilityReduceMotion

    let title: String
    let trailingValue: String?
    let language: MemoMarkLanguage
    let emphasis: V1SettingsSectionEmphasis

    @Binding
    var isExpanded: Bool

    @ViewBuilder
    let content: Content

    var body: some View {
        V1ConfigurationCardContainer(
            background: sectionBackground
        ) {
            VStack(alignment: .leading, spacing: 14) {
                Button {
                    withAnimation(disclosureAnimation) {
                        isExpanded.toggle()
                    }
                } label: {
                    adaptiveDisclosureHeader
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .frame(minHeight: 44)
                .accessibilityLabel(title)
                .accessibilityValue(
                    isExpanded
                    ? localized(
                        "settings.accessibility.expanded",
                        fallback: "已展开"
                    )
                    : localized(
                        "settings.accessibility.collapsed",
                        fallback: "已收起"
                    )
                )
                .accessibilityHint(
                    localized(
                        "settings.accessibility.toggle_hint",
                        fallback: "点击展开或收起"
                    )
                )

                if isExpanded {
                    content
                        .transition(contentTransition)
                }
            }
        }
    }

    @ViewBuilder
    private var adaptiveDisclosureHeader: some View {
        if dynamicTypeSize.isAccessibilitySize {
            verticalDisclosureHeader
        } else {
            ViewThatFits(in: .horizontal) {
                horizontalDisclosureHeader
                verticalDisclosureHeader
            }
        }
    }

    private var horizontalDisclosureHeader: some View {
        HStack(spacing: 10) {
            disclosureTitle
            Spacer(minLength: 0)
            disclosureTrailingValue
            disclosureChevron
        }
    }

    private var verticalDisclosureHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            disclosureTitle

            HStack(spacing: 10) {
                disclosureTrailingValue
                Spacer(minLength: 0)
                disclosureChevron
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var disclosureTitle: some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary)
            .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private var disclosureTrailingValue: some View {
        if let trailingValue,
           !isExpanded {
            Text(trailingValue)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 1)
        }
    }

    private var disclosureChevron: some View {
        Image(systemName: "chevron.right")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.tertiary)
            .rotationEffect(
                .degrees(isExpanded ? 90 : 0)
            )
    }

    private var disclosureAnimation: Animation? {
        accessibilityReduceMotion
            ? nil
            : .easeInOut(duration: 0.2)
    }

    private var contentTransition: AnyTransition {
        guard !accessibilityReduceMotion else {
            return .identity
        }

        return .opacity.combined(
            with: .offset(y: -4)
        )
    }

    private var sectionBackground: Color {
        switch emphasis {
        case .primary:
            ConfigurationUI.panelBackground
        case .secondary:
            ConfigurationUI.panelBackground.opacity(0.82)
        case .system:
            ConfigurationUI.controlBackground.opacity(0.36)
        }
    }

    private func localized(
        _ key: String,
        fallback: String
    ) -> String {
        language.localized(key: key, fallback: fallback)
    }
}
#endif
