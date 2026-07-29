#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct V1ReleaseNotesSheet: View {

    let language: MemoMarkLanguage
    let version: String

    private var sections: [V1ReleaseNoteSection] {
        [
            V1ReleaseNoteSection(
                id: "reliable-recording",
                title: localized(
                    "settings.release_notes.reliable_recording.title",
                    fallback: "记录更稳定"
                ),
                bullets: [
                    localized(
                        "settings.release_notes.reliable_recording.item_one",
                        fallback: "加强 Apple Photos 分享后的保存、恢复与失败重试，让中断的记录更容易继续。"
                    ),
                    localized(
                        "settings.release_notes.reliable_recording.item_two",
                        fallback: "后台处理会区分等待、可恢复、需要权限和已完成状态，避免把暂时中断误报成失败。"
                    ),
                    localized(
                        "settings.release_notes.reliable_recording.item_three",
                        fallback: "减少大图库保存时的阻塞，并继续保护重复保存和原图不变。"
                    )
                ]
            ),
            V1ReleaseNoteSection(
                id: "configuration-center",
                title: localized(
                    "settings.release_notes.configuration_center.title",
                    fallback: "配置中心更清楚"
                ),
                bullets: [
                    localized(
                        "settings.release_notes.configuration_center.item_one",
                        fallback: "保存、切换记忆对象、重命名配置、备份与恢复之间的状态衔接更可靠。"
                    ),
                    localized(
                        "settings.release_notes.configuration_center.item_two",
                        fallback: "配置预览继续使用真实记忆卡片，新增高级模块入口，减少页面中的重复层级。"
                    ),
                    localized(
                        "settings.release_notes.configuration_center.item_three",
                        fallback: "窄屏、较大文字和紧凑设备下的行布局与主要操作更容易阅读和触达。"
                    )
                ]
            ),
            V1ReleaseNoteSection(
                id: "expression-and-language",
                title: localized(
                    "settings.release_notes.expression_and_language.title",
                    fallback: "记忆表达与文字整理"
                ),
                bullets: [
                    localized(
                        "settings.release_notes.expression_and_language.item_one",
                        fallback: "记忆对象、重要时刻和表达方式使用更自然、克制的叙事语言。"
                    ),
                    localized(
                        "settings.release_notes.expression_and_language.item_two",
                        fallback: "设置中的记忆表达说明、时间结果示例和界面语言支持中英文切换。"
                    ),
                    localized(
                        "settings.release_notes.expression_and_language.item_three",
                        fallback: "智能内容继续提供可编辑的时间结果，最终文字仍由你决定。"
                    )
                ]
            ),
            V1ReleaseNoteSection(
                id: "settings-and-safety",
                title: localized(
                    "settings.release_notes.settings_and_safety.title",
                    fallback: "设置与隐私边界"
                ),
                bullets: [
                    localized(
                        "settings.release_notes.settings_and_safety.item_one",
                        fallback: "设置页重新整理为开始使用、照片处理、数据安全、反馈、社区、界面语言和关于。"
                    ),
                    localized(
                        "settings.release_notes.settings_and_safety.item_two",
                        fallback: "更新日志现在直接显示在关于页面内，版本信息与本次变化保持一致。"
                    ),
                    localized(
                        "settings.release_notes.settings_and_safety.item_three",
                        fallback: "照片仍只在设备本地处理，不上传照片，也不修改 Apple Photos 中的原图。"
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
                                    fallback: "这一次，时光记把记录过程整理得更稳，也让每一步更容易理解。"
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
                            fallback: "感谢你把真实的生活交给时光记记录。"
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
