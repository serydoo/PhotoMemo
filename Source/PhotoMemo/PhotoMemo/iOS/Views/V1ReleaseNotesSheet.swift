#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct V1ReleaseNotesSheet: View {

    let language: MemoMarkLanguage
    let version: String

    private var sections: [V1ReleaseNoteSection] {
        [
            V1ReleaseNoteSection(
                id: "time-expression",
                title: localized(
                    "settings.release_notes.time_expression.title",
                    fallback: "让时间的表达更自然"
                ),
                bullets: [
                    localized(
                        "settings.release_notes.time_expression.item_one",
                        fallback: "生日当天会用自然的语言记录，不再显示“0天”。"
                    ),
                    localized(
                        "settings.release_notes.time_expression.item_two",
                        fallback: "现在可以提前看看重要时刻之前、当天和之后的表达。"
                    )
                ]
            ),
            V1ReleaseNoteSection(
                id: "configuration",
                title: localized(
                    "settings.release_notes.configuration.title",
                    fallback: "让设置更清楚、更顺手"
                ),
                bullets: [
                    localized(
                        "settings.release_notes.configuration.item_one",
                        fallback: "配置中心和照片说明的层级更清楚，小屏上也更容易阅读。"
                    ),
                    localized(
                        "settings.release_notes.configuration.item_two",
                        fallback: "可以选择跟随系统、浅色或深色界面，照片的呈现不会因此改变。"
                    )
                ]
            ),
            V1ReleaseNoteSection(
                id: "saving",
                title: localized(
                    "settings.release_notes.saving.title",
                    fallback: "让保存更安心"
                ),
                bullets: [
                    localized(
                        "settings.release_notes.saving.item_one",
                        fallback: "保存回 Apple Photos 后的恢复与重复结果保护得到改进。"
                    ),
                    localized(
                        "settings.release_notes.saving.item_two",
                        fallback: "照片始终只在设备本地处理；原始照片保持不变，时光记只保存新的结果。"
                    )
                ]
            )
        ]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    V1ConfigurationCardContainer {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(
                                localized(
                                    "settings.release_notes.header",
                                    fallback: "这一次，让回忆在时间和日常使用里更自然。"
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
                                    fallback: "我们改善了时间表达、配置体验和保存后的恢复表现。"
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
                                V1HorizontalDivider(horizontalInset: 12)
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
                            fallback: "照片仍然只属于你的设备和生活。"
                        )
                    )
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
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
                    "settings.version.release_notes",
                    fallback: "更新日志"
                )
            )
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func sectionView(
        _ section: V1ReleaseNoteSection
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

private struct V1ReleaseNoteSection: Identifiable {

    let id: String
    let title: String
    let bullets: [String]
}
#endif
