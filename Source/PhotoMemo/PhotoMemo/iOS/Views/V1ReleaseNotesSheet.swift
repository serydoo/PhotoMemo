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
                    fallback: "卡片编辑更清楚"
                ),
                bullets: [
                    localized(
                        "settings.release_notes.time_expression.item_one",
                        fallback: "四个内容区域明确对应最终照片的位置，修改会实时出现在完整预览中。"
                    ),
                    localized(
                        "settings.release_notes.time_expression.item_two",
                        fallback: "普通文字、照片信息与记忆表达可以连续组合，右下内容也会写入照片说明。"
                    )
                ]
            ),
            V1ReleaseNoteSection(
                id: "configuration",
                title: localized(
                    "settings.release_notes.configuration.title",
                    fallback: "重要日子更容易理解"
                ),
                bullets: [
                    localized(
                        "settings.release_notes.configuration.item_one",
                        fallback: "首页和记忆对象会直接呈现今天的时间答案，重要日子的设置步骤也更清楚。"
                    ),
                    localized(
                        "settings.release_notes.configuration.item_two",
                        fallback: "配置中心、记忆对象和设置页面减少重复层级，小屏阅读与操作更从容。"
                    )
                ]
            ),
            V1ReleaseNoteSection(
                id: "saving",
                title: localized(
                    "settings.release_notes.saving.title",
                    fallback: "分享与恢复更可靠"
                ),
                bullets: [
                    localized(
                        "settings.release_notes.saving.item_one",
                        fallback: "从 Apple Photos 分享、查看处理进展和打开照片 App 的路径更明确。"
                    ),
                    localized(
                        "settings.release_notes.saving.item_two",
                        fallback: "选图、任务重试与购买操作获得更清楚的状态和失败提示；照片仍在设备本地处理，原图保持不变。"
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
                                    fallback: "根据大家的反馈，时光记迎来一次较大的体验更新。"
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
                                    fallback: "建议及时更新，体验更清楚的卡片编辑、重要日子与 Apple Photos 工作流程。"
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
                            fallback: "感谢每一条反馈。照片仍然只属于你的设备和生活。"
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
