#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct V1SettingsPageSurface: View {

    let onShowWelcome: () -> Void
    let onShowWorkflow: () -> Void
    let onDismissKeyboard: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                overviewSection
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
        V1CardSurface(title: "说明入口") {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 14) {
                    settingsOverviewArtwork

                    VStack(alignment: .leading, spacing: 8) {
                        Text("这里承接欢迎说明、使用流程与产品原则。任务状态与最近记录已经单独收拢到底部“任务”入口。")
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
        V1CardSurface(title: "使用与欢迎") {
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
                title: "欢迎说明",
                detail: "首次引导",
                systemImage: "sparkles",
                tint: .blue
            )

            settingsOverviewStat(
                title: "使用流程",
                detail: "真实路径",
                systemImage: "arrow.triangle.branch",
                tint: .teal
            )

            settingsOverviewStat(
                title: "产品原则",
                detail: "当前共识",
                systemImage: "checkmark.shield",
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
