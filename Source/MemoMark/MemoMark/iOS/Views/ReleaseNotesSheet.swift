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
                id: "home",
                title: localized("settings.release_notes.home.title", fallback: "横屏里，把常用内容放在一起"),
                bullets: [
                    localized("settings.release_notes.home.item_one", fallback: "空间充足的大屏 iPhone 横屏中，记忆对象和我的预设并排呈现，标题与卡片顶部更整齐。"),
                    localized("settings.release_notes.home.item_two", fallback: "多个预设可以在右侧独立上下滑动，标题和管理入口留在上方；竖屏及较小屏幕保持熟悉的布局。")
                ]
            ),
            ReleaseNoteSection(
                id: "progress",
                title: localized("settings.release_notes.progress.title", fallback: "刚完成的回忆，更容易找到"),
                bullets: [
                    localized("settings.release_notes.progress.item_one", fallback: "大屏横屏中，刚刚完成的结果与最近保存并排显示，方便查看新照片与历史记录。"),
                    localized("settings.release_notes.progress.item_two", fallback: "最近保存列表支持独立上下滑动，标题和操作入口保持可见。")
                ]
            ),
            ReleaseNoteSection(
                id: "time-expression",
                title: localized("settings.release_notes.time_expression.title", fallback: "同一个时间起点，换一种语气"),
                bullets: [
                    localized("settings.release_notes.time_expression.item_one", fallback: "精简时间表达的说明，围绕设定的时间锚点，选择自然、仪式感、成长、温馨或极简语气。"),
                    localized("settings.release_notes.time_expression.item_two", fallback: "表达示例继续帮助你比较说法，是否在照片上加入时间表达，由卡片内容决定。")
                ]
            ),
            ReleaseNoteSection(
                id: "configuration",
                title: localized("settings.release_notes.configuration.title", fallback: "调整之后，更清楚地确认保存"),
                bullets: [
                    localized("settings.release_notes.configuration.item_one", fallback: "改善配置修改与保存状态的衔接，让当前预设与已保存内容保持一致。"),
                    localized("settings.release_notes.configuration.item_two", fallback: "完善日期和称呼的显示；横屏配置页的预览开关放在主导航上方，保存和更多操作放在下方，切换页面时主导航保持原位。")
                ]
            ),
            ReleaseNoteSection(
                id: "saving",
                title: localized("settings.release_notes.saving.title", fallback: "从照片出发，再回到照片"),
                bullets: [
                    localized("settings.release_notes.saving.item_one", fallback: "改善从 Apple Photos 分享后的处理接续和状态显示；后台体验仍取决于系统版本、照片权限与运行状态。"),
                    localized("settings.release_notes.saving.item_two", fallback: "照片继续在本地处理，原图保持不变；完成后的新记忆照片保存回 Apple Photos。")
                ]
            )
        ]
    }

    var embedsNavigationStack = true

    @ViewBuilder
    var body: some View {
        if embedsNavigationStack {
            NavigationStack {
                pageContent.memoMarkBrowserSheetToolbar(
                    doneTitle: language.localized(key: "common.done", fallback: "完成"),
                    onDone: { dismiss() }
                )
            }
        } else {
            pageContent
        }
    }

    private var pageContent: some View {
        Group {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ConfigurationCardContainer {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(
                                localized(
                                    "settings.release_notes.header",
                                    fallback: "让常用内容更顺手，让每次回看更从容。"
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
                                    fallback: "这次我们整理了横屏首页与进展，也让时间表达和保存状态更清楚。"
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
                            fallback: "谢谢你把日常使用中的细节告诉我们。愿下一次打开照片时，那段回忆依然清晰。"
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
