#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI

/// Displays the in-app release history; it has no persisted V1 schema role.
struct ReleaseNotesSheet: View {

    let language: MemoMarkLanguage
    let version: String

    private var sections: [ReleaseNoteSection] {
        [
            ReleaseNoteSection(
                id: "time-expression",
                title: localized(
                    "settings.release_notes.time_expression.title",
                    fallback: "配置中心更连贯"
                ),
                bullets: [
                    localized(
                        "settings.release_notes.time_expression.item_one",
                        fallback: "切换记忆对象、配置和编辑页面时，当前卡片内容会继续跟随正在处理的记忆。"
                    ),
                    localized(
                        "settings.release_notes.time_expression.item_two",
                        fallback: "卡片编辑与输出设置的状态边界更清楚，减少旧页面状态覆盖当前编辑的机会。"
                    )
                ]
            ),
            ReleaseNoteSection(
                id: "configuration",
                title: localized(
                    "settings.release_notes.configuration.title",
                    fallback: "切换与恢复更稳定"
                ),
                bullets: [
                    localized(
                        "settings.release_notes.configuration.item_one",
                        fallback: "重新进入配置中心或切换记忆对象后，预览、对象信息和配置选择会保持在同一上下文。"
                    ),
                    localized(
                        "settings.release_notes.configuration.item_two",
                        fallback: "相册选项等异步内容只会应用到仍然对应的记忆对象和配置，避免过期结果混入当前页面。"
                    )
                ]
            ),
            ReleaseNoteSection(
                id: "saving",
                title: localized(
                    "settings.release_notes.saving.title",
                    fallback: "本地记忆继续由你掌握"
                ),
                bullets: [
                    localized(
                        "settings.release_notes.saving.item_one",
                        fallback: "这次更新集中整理配置中心的状态边界，不新增云端处理，也不改变 Apple Photos 的使用方式。"
                    ),
                    localized(
                        "settings.release_notes.saving.item_two",
                        fallback: "照片仍在设备本地处理，原图保持不变；完成后生成新的记忆照片。"
                    )
                ]
            )
        ]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ConfigurationCardContainer {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(
                                localized(
                                    "settings.release_notes.header",
                                    fallback: "这次更新主要完善了配置中心在切换与恢复时的状态连续性。"
                                )
                            )
                            .font(.subheadline.weight(.semibold))

                            Text(
                                localized(
                                    "settings.release_notes.version_format",
                                    fallback: "版本 %@",
                                    version
                                )
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)

                            Text(
                                localized(
                                    "settings.release_notes.positioning",
                                    fallback: "建议更新，获得更连贯的配置中心、卡片编辑和本地处理体验。"
                                )
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(sections.enumerated()), id: \.element.id) { index, section in
                            sectionView(section)

                            if index < sections.count - 1 {
                                HorizontalDivider(horizontalInset: 12)
                            }
                        }
                    }
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
                        .stroke(ConfigurationUI.faintHairline)
                    )

                    Text(
                        localized(
                            "settings.release_notes.closing",
                            fallback: "感谢每一条反馈。照片仍然只属于你的设备和生活。"
                        )
                    )
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
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
                    "settings.version.release_notes",
                    fallback: "更新日志"
                )
            )
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func sectionView(
        _ section: ReleaseNoteSection
    ) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(section.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: 7) {
                ForEach(section.bullets, id: \.self) { bullet in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 5, height: 5)
                            .padding(.top, 6)

                        Text(bullet)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
    }

    private func localized(
        _ key: String,
        fallback: String,
        _ arguments: CVarArg...
    ) -> String {
        let value = language.localized(key: key, fallback: fallback)
        guard !arguments.isEmpty else {
            return value
        }
        return String(format: value, locale: language.locale, arguments: arguments)
    }
}

private struct ReleaseNoteSection: Identifiable {

    let id: String
    let title: String
    let bullets: [String]
}
#endif
