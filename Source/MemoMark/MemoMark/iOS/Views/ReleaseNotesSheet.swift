#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI

/// Displays the in-app release history; it has no persisted V1 schema role.
struct ReleaseNotesSheet: View {

    let language: MemoMarkLanguage
    let version: String

    @Environment(\.dismiss)
    private var dismiss

    private var sections: [ReleaseNoteSection] {
        [
            ReleaseNoteSection(
                id: "time-expression",
                title: localized(
                    "settings.release_notes.time_expression.title",
                    fallback: "边写边看这张记忆卡"
                ),
                bullets: [
                    localized(
                        "settings.release_notes.time_expression.item_one",
                        fallback: "编辑卡片内容时，照片预览会留在同一页面，文字和信息的变化可以随时查看。"
                    ),
                    localized(
                        "settings.release_notes.time_expression.item_two",
                        fallback: "键盘出现时，预览会留出查看内容的空间；完成编辑后仍可继续调整配置。"
                    )
                ]
            ),
            ReleaseNoteSection(
                id: "configuration",
                title: localized(
                    "settings.release_notes.configuration.title",
                    fallback: "预览更贴近最终照片"
                ),
                bullets: [
                    localized(
                        "settings.release_notes.configuration.item_one",
                        fallback: "横竖照片都可以在配置中心查看，也可以展开检查完整画面。"
                    ),
                    localized(
                        "settings.release_notes.configuration.item_two",
                        fallback: "胶片时间的文字超出安全范围时，预览会提示调整内容或字号。"
                    )
                ]
            ),
            ReleaseNoteSection(
                id: "saving",
                title: localized(
                    "settings.release_notes.saving.title",
                    fallback: "记录仍由你掌握"
                ),
                bullets: [
                    localized(
                        "settings.release_notes.saving.item_one",
                        fallback: "首页更清楚地呈现当前预设围绕的记忆对象；熟悉分享流程后，新手选图引导会自然收起。"
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
                                    fallback: "这次更新让卡片内容编辑与照片预览留在同一视野里。"
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
                                    fallback: "在写下记忆的同时，看见它将如何呈现在照片上。"
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
                            fallback: "感谢你的反馈。让每张照片都能留下属于你的表达。"
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
            .memoMarkBrowserSheetToolbar(
                doneTitle: language.localized(
                    key: "common.done",
                    fallback: "完成"
                ),
                onDone: { dismiss() }
            )
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
