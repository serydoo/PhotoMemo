#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct V1SettingsPageSurface: View {

    @Environment(\.openURL) private var openURL

    let onShowWelcome: () -> Void
    let onShowWorkflow: () -> Void
    let onDismissKeyboard: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                overviewSection
                releaseSection
                supportSection
                developmentPlanSection
                feedbackSection
                guideSection
                principleSection
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 34)
        }
        .scrollDismissesKeyboard(.interactively)
        .simultaneousGesture(
            TapGesture()
                .onEnded {
                    onDismissKeyboard()
                }
        )
        .background(
            ConfigurationUI.appBackground
                .ignoresSafeArea()
        )
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var overviewSection: some View {
        V1CardSurface(title: "关于时光记") {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 14) {
                    settingsOverviewArtwork

                    VStack(alignment: .leading, spacing: 8) {
                        Text("这里汇总当前 TestFlight 版本、支持范围、反馈入口和下一阶段计划。任务状态与最近记录已经单独收拢到底部“任务”入口。")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        HStack(spacing: 8) {
                            settingsTag(
                                title: "本地优先",
                                systemImage: "lock.shield"
                            )

                            settingsTag(
                                title: "不改原图",
                                systemImage: "photo"
                            )
                        }
                    }
                }

                settingsOverviewStrip
            }
        }
    }

    private var guideSection: some View {
        V1CardSurface(title: "使用说明") {
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
                        systemImage: "list.bullet.rectangle.portrait",
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
            }
        }
    }

    private var releaseSection: some View {
        V1CardSurface(title: "版本与上架") {
            VStack(spacing: 0) {
                settingsInfoRow(
                    title: "当前版本",
                    headline: "时光记 1.6",
                    detail:
                        "用户可见版本更新为 1.6；TestFlight 构建号由 Xcode Cloud 与 App Store Connect 生成。",
                    systemImage: "number.circle.fill",
                    tint: .blue
                )

                settingsInfoRow(
                    title: "云端构建",
                    headline: "当前 13，下一次预计 14",
                    detail:
                        "前面的 Xcode Cloud 申请与取消已经消耗部分构建号，后续以上传成功后的 TestFlight 显示为准。",
                    systemImage: "icloud.and.arrow.up.fill",
                    tint: .teal,
                    showsDivider: false
                )
            }
            .background(settingsInsetBackground)
        }
    }

    private var supportSection: some View {
        V1CardSurface(title: "支持范围") {
            VStack(spacing: 0) {
                settingsInfoRow(
                    title: "输入",
                    headline: "Apple Photos 分享的静态照片",
                    detail:
                        "支持单张和少量多张分享；有无位置信息都可以进入本地处理。",
                    systemImage: "photo.on.rectangle.angled",
                    tint: .blue
                )

                settingsInfoRow(
                    title: "输出",
                    headline: "保存回相册的新图片",
                    detail:
                        "时光记生成一张新的记忆卡片图片，不修改系统相册里的原始照片。",
                    systemImage: "square.and.arrow.down.on.square.fill",
                    tint: .teal
                )

                settingsInfoRow(
                    title: "当前边界",
                    headline: "主程序选图已进入 Live Photo 验证，Share 仍以静态照片为主",
                    detail:
                        "当前适合验证静态照片与主程序选图的 Live Photo 路径；Share Extension 仍应按静态照片处理，不宣称完整 Live Photo 支持。",
                    systemImage: "livephoto",
                    tint: .indigo,
                    showsDivider: false
                )
            }
            .background(settingsInsetBackground)
        }
    }

    private var feedbackSection: some View {
        V1CardSurface(title: "反馈渠道") {
            VStack(spacing: 0) {
                settingsLinkRow(
                    title: "TestFlight 反馈",
                    headline: "适合闪退、截图和录屏",
                    detail:
                        "优先使用系统内置反馈，方便带上设备和崩溃上下文。",
                    systemImage: "paperplane.fill",
                    tint: .blue
                )

                settingsLinkRow(
                    title: "邮件反馈",
                    headline: "serydoo@gmail.com",
                    detail:
                        "适合描述复现步骤、预期结果、实际结果和 iOS 版本。",
                    systemImage: "envelope.fill",
                    tint: .teal
                ) {
                    openMailFeedback()
                }

                settingsLinkRow(
                    title: "小红书",
                    headline: "ID 49956456623",
                    detail:
                        "可以通过小红书联系，也可以进一步加群沟通测试反馈。",
                    systemImage: "person.2.fill",
                    tint: .pink
                )

                settingsLinkRow(
                    title: "GitHub Issues",
                    headline: "公开可复现问题",
                    detail:
                        "适合记录稳定复现的缺陷和后续开发讨论。",
                    systemImage: "curlybraces.square.fill",
                    tint: .indigo,
                    showsDivider: false
                ) {
                    openGitHubIssues()
                }
            }
            .background(settingsInsetBackground)
        }
    }

    private var developmentPlanSection: some View {
        V1CardSurface(title: "后续计划") {
            VStack(spacing: 0) {
                settingsInfoRow(
                    title: "1.6",
                    headline: "Live Photo 支持",
                    detail:
                        "下一版优先评估 Live Photo 输入、静态封面提取和输出规则，保持本地处理与不改原图。",
                    systemImage: "play.rectangle.fill",
                    tint: .blue
                )

                settingsInfoRow(
                    title: "可靠性",
                    headline: "关闭 TestFlight 反馈",
                    detail:
                        "优先处理分享入口、权限说明、失败重试、保存回相册和引导文案。",
                    systemImage: "checkmark.seal.fill",
                    tint: .teal
                )

                settingsInfoRow(
                    title: "呈现质量",
                    headline: "渲染与元数据继续加固",
                    detail:
                        "继续验证预览与导出一致性、位置回退、清晰度和特殊比例照片表现。",
                    systemImage: "camera.fill",
                    tint: .indigo,
                    showsDivider: false
                )
            }
            .background(settingsInsetBackground)
        }
    }

    private var principleSection: some View {
        V1CardSurface(title: "当前原则") {
            VStack(alignment: .leading, spacing: 10) {
                settingsPrinciple(
                    title: "时光记会生成新图，不修改系统相册里的原始照片。",
                    tint: .blue
                )

                settingsPrinciple(
                    title: "记忆对象、时间锚点与输出规则配置好之后，后续处理会直接复用。",
                    tint: .teal
                )

                settingsPrinciple(
                    title: "日常路径仍然保持在 Apple Photos -> Share -> 时光记 -> Processing -> Apple Photos。",
                    tint: .indigo
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

    private var settingsOverviewArtwork: some View {
        ZStack {
            RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
            .fill(
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.18),
                        Color.white,
                        Color.teal.opacity(0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

            VStack(spacing: 8) {
                HStack(spacing: 7) {
                    settingsMiniTile(
                        systemImage: "gearshape.2.fill",
                        tint: .blue,
                        rotation: -8
                    )

                    settingsMiniTile(
                        systemImage: "book.pages.fill",
                        tint: .teal,
                        rotation: 6
                    )
                }

                settingsMiniTile(
                    systemImage: "square.stack.3d.up.fill",
                    tint: .indigo,
                    rotation: -4
                )
            }
            .padding(10)
        }
        .frame(width: 92, height: 112)
        .overlay(
            RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
            .stroke(Color.blue.opacity(0.12))
        )
    }

    private var settingsOverviewStrip: some View {
        HStack(spacing: 10) {
            settingsOverviewStat(
                title: "版本",
                detail: "1.6",
                systemImage: "number.circle",
                tint: .blue
            )

            settingsOverviewStat(
                title: "输出",
                detail: "新图片",
                systemImage: "photo",
                tint: .teal
            )

            settingsOverviewStat(
                title: "反馈",
                detail: "TestFlight",
                systemImage: "paperplane",
                tint: .indigo
            )
        }
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
                Rectangle()
                    .fill(ConfigurationUI.faintHairline)
                    .frame(height: 0.5)
                    .padding(.leading, 60)
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
                    "mailto:serydoo@gmail.com?subject=MemoMark%201.6%20TestFlight%20Feedback"
            )
        else {
            return
        }

        openURL(url)
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

    private func settingsMiniTile(
        systemImage: String,
        tint: Color,
        rotation: Double
    ) -> some View {
        RoundedRectangle(
            cornerRadius: 14,
            style: .continuous
        )
        .fill(Color.white.opacity(0.88))
        .frame(width: 28, height: 32)
        .overlay(
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(tint)
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 14,
                style: .continuous
            )
            .stroke(tint.opacity(0.10))
        )
        .rotationEffect(.degrees(rotation))
        .shadow(
            color: tint.opacity(0.10),
            radius: 8,
            y: 4
        )
    }

    private func settingsOverviewStat(
        title: String,
        detail: String,
        systemImage: String,
        tint: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(tint)

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)

            Text(detail)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(
                cornerRadius: 14,
                style: .continuous
            )
            .fill(tint.opacity(0.08))
        )
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
#endif
