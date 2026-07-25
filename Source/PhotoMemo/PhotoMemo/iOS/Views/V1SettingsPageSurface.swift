#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct V1SettingsPageSurface: View {

    private enum SettingsSection: Hashable, CaseIterable {
        case overview
        case guide
        case support
        case principle
        case feedback
        case release
    }

    @Environment(\.openURL) private var openURL

    @AppStorage(
        MemoMarkLanguage.interfacePreferenceStorageKey,
        store: PhotoMemoSharedContainer.sharedUserDefaults
    )
    private var interfaceLanguagePreferenceRawValue =
        MemoMarkInterfaceLanguagePreference.system.rawValue

    @State
    private var showsExpressionGuide = false

    @State
    private var expandedSections: Set<SettingsSection> = []

    let commerceSnapshot:
        MemoMarkCommerceSnapshot
    let onOpenMemoMarkPlus: () -> Void

    let onShowWelcome: () -> Void
    let onShowWorkflow: () -> Void
    let onDismissKeyboard: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                memoMarkPlusSection
                overviewSection
                guideSection
                supportSection
                principleSection
                feedbackSection
                interfaceLanguageSection
                releaseSection
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
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showsExpressionGuide) {
            expressionGuideSheet
        }
    }

    private var interfaceLanguageSection: some View {
        V1ConfigurationCardContainer {
            VStack(alignment: .leading, spacing: 12) {
                Label(
                    localized(
                        "应用界面语言",
                        fallback: "应用界面语言"
                    ),
                    systemImage: "character"
                )
                .font(.headline.weight(.semibold))

                Picker(
                    localized(
                        "应用界面语言",
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
                .pickerStyle(.segmented)

                Text(
                    localized(
                        "控制时光记的菜单、设置、帮助与处理状态文字；不改变你填写的内容，也不替代配置中的输出语言。",
                        fallback: "控制时光记的菜单、设置、帮助与处理状态文字；不改变你填写的内容，也不替代配置中的输出语言。"
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
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
            HStack(spacing: 13) {
                ZStack {
                    RoundedRectangle(
                        cornerRadius: 13,
                        style: .continuous
                    )
                    .fill(
                        Color(
                            red: 0.98,
                            green: 0.94,
                            blue: 0.82
                        )
                    )

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

                VStack(alignment: .leading, spacing: 4) {
                    Text("MemoMark+")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.primary)

                    Text(memoMarkPlusDetail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(
                            horizontal: false,
                            vertical: true
                        )
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(14)
            .background(
                RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
                .fill(ConfigurationUI.panelBackground)
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
                .stroke(
                    warmGold.opacity(0.18),
                    lineWidth: 0.75
                )
            )
        }
        .buttonStyle(.plain)
        .accessibilityHint(
            memoMarkPlusAccessibilityHint
        )
    }

    private var memoMarkPlusDetail: String {
        if isTestFlightExperienceActive {
            return localized(
                "commerce.settings.testflight",
                fallback: "TestFlight 体验 · 无限记录\n正式版权益仍由 Apple 购买或兑换决定。"
            )
        }

        if commerceSnapshot.firstRecorderDate != nil {
            return localized(
                "commerce.settings.first_recorder",
                fallback: "首批记录者 · 无限记录\n愿今天留下的时光，在未来仍然清晰而温暖。"
            )
        }

        if commerceSnapshot.isPlus {
            return localized(
                "commerce.settings.plus",
                fallback: "MemoMark+ · 无限记录\n永久权益由 Apple 管理并可恢复购买。"
            )
        }

        if let remaining =
                commerceSnapshot.remainingRecords,
           remaining <= 10 {
            return formatted(
                "commerce.settings.remaining",
                fallback: "还有 %lld 张免费成长记录 · 了解 MemoMark+",
                Int64(remaining)
            )
        }

        return localized(
            "commerce.settings.continuity",
            fallback: "继续保存那些未来值得回看的瞬间"
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
        systemImage: String,
        tint: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        V1SettingsDisclosureSection(
            title: title,
            systemImage: systemImage,
            tint: tint,
            isExpanded: expansionBinding(for: section),
            content: content
        )
    }

    private func expansionBinding(
        for section: SettingsSection
    ) -> Binding<Bool> {
        Binding(
            get: {
                expandedSections.contains(section)
            },
            set: { isExpanded in
                if isExpanded {
                    expandedSections.insert(section)
                } else {
                    expandedSections.remove(section)
                }
            }
        )
    }

    private var overviewSection: some View {
        settingsDisclosureSection(
            section: .overview,
            title: "为什么是时光记",
            systemImage: MemoMarkSymbol.memoryContent.name,
            tint: .pink
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text("让照片知道，它位于谁的人生里")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text("陪伴孩子长大的过程中，我们留下了很多很多照片。时光记最初只是想回答一个问题：打开照片时，能不能马上知道那一天，孩子多大？")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("最初的时间锚点，是儿子出生的那一天。后来我们逐渐发现，纪念日和未来的重要日期，也都可以成为时间锚点。一张照片不只有时间、地点和相机参数，还可以呈现年龄、距离重要日子多久，以及它位于一段人生的什么位置。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("因此，时光记想做的不是简单添加水印，而是把照片变成更容易读懂的记忆记录。不同预设和表达，可以让同一段时间关系以更自然、更温暖或更简洁的方式出现。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("所有核心计算都在设备本地完成：不上传照片、不依赖云端 AI、不修改原图，并尽可能保留原始照片信息。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("希望它能陪大家长期记录生活、享受记忆。欢迎在日常使用中提出反馈和建议，也欢迎在小红书等公开渠道分享体验，邀请更多人一起参与。")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Label(
                    "愿大家都能享受这些被时间标记的记忆。",
                    systemImage: "sparkles"
                )
                .font(.caption)
                .foregroundStyle(Color.accentColor)
                .fixedSize(horizontal: false, vertical: true)

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8) {
                        privacyTag
                        memoryTag
                        originalPhotoTag
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        privacyTag
                        memoryTag
                        originalPhotoTag
                    }
                }
            }
        }
    }

    private var guideSection: some View {
        settingsDisclosureSection(
            section: .guide,
            title: "使用与帮助",
            systemImage: MemoMarkSymbol.help.name,
            tint: .blue
        ) {
            VStack(spacing: 12) {
                Button(action: onShowWelcome) {
                    settingsActionRow(
                        title: "重新查看欢迎说明",
                        detail: "回看首次使用说明、核心能力与基础引导。",
                        systemImage: "sparkles",
                        accent: .blue,
                        thumbnail: {
                            settingsThumbnailStack(
                                accent: .blue,
                                symbols: [
                                    "sparkles.rectangle.stack",
                                    "hand.wave.fill",
                                    "text.badge.star"
                                ]
                            )
                        }
                    )
                }
                .buttonStyle(.plain)

                Button(action: onShowWorkflow) {
                    settingsActionRow(
                        title: "查看使用流程",
                        detail: "按 Apple Photos -> Share -> 时光记的真实路径回看处理方式。",
                        systemImage: MemoMarkSymbol.help.name,
                        accent: .teal,
                        thumbnail: {
                            settingsThumbnailStack(
                                accent: .teal,
                                symbols: [
                                    "photo.on.rectangle.angled",
                                    "square.and.arrow.up",
                                    "checkmark.rectangle.stack.fill"
                                ]
                            )
                        }
                    )
                }
                .buttonStyle(.plain)

                Button {
                    showsExpressionGuide = true
                } label: {
                    settingsActionRow(
                        title: "查看表达公式说明",
                        detail: "按时间锚点查看主体、智能输出和锚点结果的组合方式。",
                        systemImage:
                            MemoMarkSymbol.expressionFormula.name,
                        accent: .orange,
                        thumbnail: {
                            settingsThumbnailStack(
                                accent: .orange,
                                symbols: [
                                    MemoMarkSymbol.expressionFormula.name,
                                    "calendar.badge.clock",
                                    "paintpalette.fill"
                                ]
                            )
                        }
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var expressionGuideSheet: some View {
        NavigationStack {
            ScrollView {
                V1SettingsExpressionGuide()
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
            .navigationTitle("表达公式说明")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var releaseSection: some View {
        settingsDisclosureSection(
            section: .release,
            title: localized(
                "settings.version.section_title",
                fallback: "版本信息"
            ),
            systemImage: MemoMarkSymbol.information.name,
            tint: .blue
        ) {
            VStack(spacing: 0) {
                settingsInfoRow(
                    title: localized(
                        "settings.version.row_title",
                        fallback: "当前版本"
                    ),
                    headline: formatted(
                        "settings.version.headline_format",
                        fallback: "时光记 %@",
                        combinedAppVersion
                    ),
                    detail: formatted(
                        "settings.version.detail_format",
                        fallback: "产品版本 %@ · Xcode Cloud 构建 %@。信息来自当前安装包。",
                        appVersion,
                        appBuild
                    ),
                    systemImage: "number.circle.fill",
                    tint: .blue,
                    showsDivider: false
                )
            }
            .background(settingsInsetBackground)
        }
    }

    private var supportSection: some View {
        settingsDisclosureSection(
            section: .support,
            title: "能力与边界",
            systemImage: MemoMarkSymbol.capability.name,
            tint: .orange
        ) {
            VStack(spacing: 0) {
                settingsInfoRow(
                    title: "照片输入",
                    headline: "静态照片、Live Photo 与 RAW / DNG",
                    detail: "可从主程序或 Apple Photos 分享进入；Live Photo 与 RAW / DNG 路径仍会持续进行真机兼容性验证。",
                    systemImage: MemoMarkSymbol.applePhotos.name,
                    tint: .blue
                )

                settingsInfoRow(
                    title: "每次处理",
                    headline:
                        "最多 \(commerceSnapshot.batchLimit) 张照片",
                    detail: "较大的分享请分批进行，减少系统扩展内存压力并提高回存稳定性。",
                    systemImage: MemoMarkSymbol.originalPhoto.name,
                    tint: .teal
                )

                settingsInfoRow(
                    title: "处理结果",
                    headline: "生成新文件并保存回 Apple Photos",
                    detail: "时光记不会覆盖原图。Live Photo 是否保留动态效果由当前输出配置与实际输入决定。",
                    systemImage: MemoMarkSymbol.output.name,
                    tint: .indigo,
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
                fallback: "反馈渠道"
            ),
            systemImage: MemoMarkSymbol.feedback.name,
            tint: .pink
        ) {
            VStack(alignment: .leading, spacing: 8) {
                VStack(spacing: 0) {
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
                            fallback: "欢迎通过公开账号联系开发者，分享使用体验与建议。"
                        ),
                        systemImage: "magnifyingglass.circle.fill",
                        tint: .pink
                    )
                    .textSelection(.enabled)

                    settingsInfoRow(
                        title: localized(
                            "settings.feedback.qq.title",
                            fallback: "QQ 交流群"
                        ),
                        headline: "955680366",
                        detail: localized(
                            "settings.feedback.qq.detail",
                            fallback: "适合交流使用问题、产品想法与个性化需求。"
                        ),
                        systemImage: "person.2.fill",
                        tint: .cyan
                    )
                    .textSelection(.enabled)

                    settingsLinkRow(
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
                        systemImage: "paperplane.fill",
                        tint: .blue
                    )

                    settingsLinkRow(
                        title: localized(
                            "settings.feedback.email.title",
                            fallback: "邮件反馈"
                        ),
                        headline: "serydoo@gmail.com",
                        detail: localized(
                            "settings.feedback.email.detail",
                            fallback: "适合描述复现步骤、预期结果、实际结果和 iOS 版本。"
                        ),
                        systemImage: "envelope.fill",
                        tint: .teal
                    ) {
                        openMailFeedback()
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
                        systemImage: "curlybraces.square.fill",
                        tint: .indigo,
                        showsDivider: false
                    ) {
                        openGitHubIssues()
                    }
                }
                .background(settingsInsetBackground)

                Text(
                    localized(
                        "settings.feedback.closing",
                        fallback: "欢迎告诉我们你的真实体验、遇到的问题，以及希望加入的个性化能力。"
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 4)
            }
        }
    }

    private var principleSection: some View {
        settingsDisclosureSection(
            section: .principle,
            title: "隐私与数据",
            systemImage: MemoMarkSymbol.privacy.name,
            tint: .green
        ) {
            VStack(alignment: .leading, spacing: 10) {
                settingsPrinciple(
                    title: "照片处理在设备本地完成，不会上传照片。",
                    tint: .blue
                )

                settingsPrinciple(
                    title: "时光记生成新文件，不修改 Apple Photos 中的原始照片。",
                    tint: .teal
                )

                settingsPrinciple(
                    title: "记忆对象、时间锚点、配置与任务记录保存在本机应用容器中。",
                    tint: .indigo
                )

                settingsPrinciple(
                    title: "删除应用可能同时移除尚未单独备份的本地配置与记录。",
                    tint: .orange
                )
            }
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

    private func settingsActionRow<Thumbnail: View>(
        title: String,
        detail: String,
        systemImage: String,
        accent: Color,
        @ViewBuilder thumbnail: () -> Thumbnail
    ) -> some View {
        HStack(alignment: .center, spacing: 12) {
            thumbnail()

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Image(systemName: systemImage)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(accent)
                }

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
        .background(
            RoundedRectangle(
                cornerRadius: 14,
                style: .continuous
            )
            .fill(ConfigurationUI.controlBackground.opacity(0.82))
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 14,
                style: .continuous
            )
            .stroke(accent.opacity(0.10))
        )
    }

    private func settingsTag(
        title: String,
        systemImage: String
    ) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.blue)
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.blue.opacity(0.08))
            )
    }

    private var privacyTag: some View {
        settingsTag(
            title: "本地优先",
            systemImage: MemoMarkSymbol.privacy.name
        )
    }

    private var memoryTag: some View {
        settingsTag(
            title: "保存记忆",
            systemImage: MemoMarkSymbol.memoryContent.name
        )
    }

    private var originalPhotoTag: some View {
        settingsTag(
            title: "不改原图",
            systemImage: MemoMarkSymbol.applePhotos.name
        )
    }

    private func settingsPrinciple(
        title: String,
        tint: Color
    ) -> some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                RoundedRectangle(
                    cornerRadius: 10,
                    style: .continuous
                )
                .fill(tint.opacity(0.10))

                Image(systemName: "checkmark.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(tint)
            }
            .frame(width: 28, height: 28)

            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 2)
    }

    private func settingsInfoRow(
        title: String,
        headline: String,
        detail: String,
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
        detail: String,
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
        detail: String,
        systemImage: String,
        tint: Color,
        showsDivider: Bool,
        accessory: String? = nil
    ) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                settingsTonalIcon(
                    systemImage: systemImage,
                    tint: tint
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(tint)
                        .lineLimit(1)

                    Text(headline)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                if let accessory {
                    Image(systemName: accessory)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .padding(.top, 12)
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

    private func settingsTonalIcon(
        systemImage: String,
        tint: Color
    ) -> some View {
        ZStack {
            RoundedRectangle(
                cornerRadius: 10,
                style: .continuous
            )
            .fill(tint.opacity(0.10))

            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint)
                .symbolRenderingMode(.hierarchical)
        }
        .frame(width: 36, height: 36)
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

    private var combinedAppVersion: String {
        "\(appVersion).\(appBuild)"
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

    private func settingsThumbnailStack(
        accent: Color,
        symbols: [String]
    ) -> some View {
        ZStack {
            ForEach(Array(symbols.enumerated()), id: \.offset) { index, symbol in
                RoundedRectangle(
                    cornerRadius: 12,
                    style: .continuous
                )
                .fill(Color.white.opacity(0.92))
                .frame(width: 44, height: 54)
                .overlay(
                    RoundedRectangle(
                        cornerRadius: 12,
                        style: .continuous
                    )
                    .stroke(accent.opacity(0.10))
                )
                .overlay(
                    Image(systemName: symbol)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(accent)
                )
                .offset(
                    x: CGFloat(index) * 7,
                    y: CGFloat(index) * 4
                )
            }
        }
        .frame(width: 58, height: 62)
    }
}

private struct V1SettingsDisclosureSection<Content: View>: View {

    @Environment(\.accessibilityReduceMotion)
    private var accessibilityReduceMotion

    let title: String
    let systemImage: String
    let tint: Color

    @Binding
    var isExpanded: Bool

    @ViewBuilder
    let content: Content

    var body: some View {
        V1ConfigurationCardContainer {
            VStack(alignment: .leading, spacing: 14) {
                Button {
                    withAnimation(disclosureAnimation) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 10) {
                        V1CompactHeadingIcon(
                            systemImage: systemImage,
                            tint: tint
                        )

                        Text(title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)

                        Spacer(minLength: 0)

                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .rotationEffect(
                                .degrees(isExpanded ? 90 : 0)
                            )
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(title)
                .accessibilityValue(
                    isExpanded ? "已展开" : "已收起"
                )
                .accessibilityHint("点击展开或收起")

                if isExpanded {
                    content
                }
            }
        }
    }

    private var disclosureAnimation: Animation? {
        accessibilityReduceMotion
            ? nil
            : .easeInOut(duration: 0.2)
    }
}
#endif
