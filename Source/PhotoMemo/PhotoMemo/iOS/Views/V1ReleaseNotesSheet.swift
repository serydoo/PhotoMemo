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
                    ),
                    localized(
                        "settings.release_notes.reliable_recording.item_four",
                        fallback: "收紧队列启动、恢复、重试、通知附件和来源文件清理边界，降低请求丢失与恢复状态被覆盖的风险。"
                    ),
                    localized(
                        "settings.release_notes.reliable_recording.item_five",
                        fallback: "分享半屏交接界面改为四个原生说明行，补齐主要操作触达区域、VoiceOver 语义和中英文内容。"
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
                        fallback: "保存的时间显示现在会进入最终结果；选择日常记录时，日期会与预览一致地保留星期。"
                    ),
                    localized(
                        "settings.release_notes.configuration_center.item_three",
                        fallback: "配置预览继续使用真实 Memory Card，并与最终输出共享同一时间格式化路径。"
                    )
                ]
            ),
            V1ReleaseNoteSection(
                id: "advanced-modules",
                title: localized(
                    "settings.release_notes.advanced_modules.title",
                    fallback: "高级模块与小屏体验"
                ),
                bullets: [
                    localized(
                        "settings.release_notes.advanced_modules.item_one",
                        fallback: "高级模块继续集中地理显示和时间显示，没有扩展新的功能表面。"
                    ),
                    localized(
                        "settings.release_notes.advanced_modules.item_two",
                        fallback: "弹窗使用紧凑的默认高度并支持继续展开，地理显示和时间显示整理为两个原生列表行。"
                    ),
                    localized(
                        "settings.release_notes.advanced_modules.item_three",
                        fallback: "两个高级模块获得更充足的垂直留白，同时保留原生菜单、动态字体和辅助功能行为。"
                    ),
                    localized(
                        "settings.release_notes.advanced_modules.item_four",
                        fallback: "记忆表达在较小 iPhone 的正常文字尺寸下尽量保持标题与选择项同一行。"
                    ),
                    localized(
                        "settings.release_notes.advanced_modules.item_five",
                        fallback: "空间不足或使用辅助功能字号时自动回退为垂直布局，选择项按内容宽度呈现。"
                    )
                ]
            ),
            V1ReleaseNoteSection(
                id: "iphone-and-settings",
                title: localized(
                    "settings.release_notes.iphone_and_settings.title",
                    fallback: "iPhone 界面与设置中心"
                ),
                bullets: [
                    localized(
                        "settings.release_notes.iphone_and_settings.item_one",
                        fallback: "优化首页、配置、保存、处理、输出、记忆对象和时间锚点的层级、行布局和主要操作。"
                    ),
                    localized(
                        "settings.release_notes.iphone_and_settings.item_two",
                        fallback: "紧凑设备、窄屏、较大文字和辅助功能字号拥有更稳定的垂直布局与原生菜单回退。"
                    ),
                    localized(
                        "settings.release_notes.iphone_and_settings.item_three",
                        fallback: "设置页整理为开始使用、照片处理、数据安全、反馈、社区、界面语言和关于。"
                    ),
                    localized(
                        "settings.release_notes.iphone_and_settings.item_four",
                        fallback: "更新日志现在直接在应用内显示，不再跳转到 GitHub Releases。"
                    ),
                    localized(
                        "settings.release_notes.iphone_and_settings.item_five",
                        fallback: "界面拆分继续保留 ConfigurationSession 作为编辑真相，没有重新设计冻结的配置中心架构。"
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
                    ),
                    localized(
                        "settings.release_notes.expression_and_language.item_four",
                        fallback: "权限、隐私、错误、恢复、购买和删除等状态继续使用直接、准确的表达。"
                    )
                ]
            ),
            V1ReleaseNoteSection(
                id: "unchanged",
                title: localized(
                    "settings.release_notes.unchanged.title",
                    fallback: "保持不变"
                ),
                bullets: [
                    localized(
                        "settings.release_notes.unchanged.item_one",
                        fallback: "照片只在设备本地处理，不上传。"
                    ),
                    localized(
                        "settings.release_notes.unchanged.item_two",
                        fallback: "Apple Photos 中的原始照片保持不变，时光记只生成新的输出照片。"
                    ),
                    localized(
                        "settings.release_notes.unchanged.item_three",
                        fallback: "Live Photo 的既有处理与输出策略没有降级或重构。"
                    ),
                    localized(
                        "settings.release_notes.unchanged.item_four",
                        fallback: "日常流程仍然是 Apple Photos → 分享 → 时光记 → 处理 → 通知 → Apple Photos。"
                    ),
                    localized(
                        "settings.release_notes.unchanged.item_five",
                        fallback: "配置中心、记忆引擎、呈现、布局、渲染和输出的既有职责边界保持不变。"
                    )
                ]
            ),
            V1ReleaseNoteSection(
                id: "verification",
                title: localized(
                    "settings.release_notes.verification.title",
                    fallback: "验证与发布边界"
                ),
                bullets: [
                    localized(
                        "settings.release_notes.verification.item_one",
                        fallback: "设置、后台处理、响应式布局、叙事语言、配置生命周期、分享界面、时间显示和媒体输出均有对应契约验证。"
                    ),
                    localized(
                        "settings.release_notes.verification.item_two",
                        fallback: "完整 macOS 测试回归通过 1,214 项，跳过 1 项，失败 0 项。"
                    ),
                    localized(
                        "settings.release_notes.verification.item_three",
                        fallback: "macOS、通用 iOS 和签名 iOS Debug 构建通过，主应用及扩展的嵌入签名通过校验。"
                    ),
                    localized(
                        "settings.release_notes.verification.item_four",
                        fallback: "2.0 (65) 在提交审核前完成 MemoMark+ 购买入口修复：购买会请求 Apple 的 StoreKit 服务；服务暂时不可用时会给出说明并可重新尝试。"
                    ),
                    localized(
                        "settings.release_notes.verification.item_five",
                        fallback: "完整 Apple Photos 分享、系统后台调度、VoiceOver、动态字体、Live Photo 与最终视觉仍以发布候选包的实体机验收为准。"
                    )
                ]
            ),
            V1ReleaseNoteSection(
                id: "next-stage",
                title: localized(
                    "settings.release_notes.next_stage.title",
                    fallback: "接下来的版本节奏"
                ),
                bullets: [
                    localized(
                        "settings.release_notes.next_stage.item_one",
                        fallback: "2.0 标志着 V3 的产品质量收口。V4 从表达方式研究开始，继续打磨主界面、既有功能、操作逻辑和设备适配，不做大规模核心流程或架构重构。"
                    ),
                    localized(
                        "settings.release_notes.next_stage.item_two",
                        fallback: "V4 完成且没有影响正常使用的重大问题后，时光记将停止常规版本更新，只保留必要维护。"
                    ),
                    localized(
                        "settings.release_notes.next_stage.item_three",
                        fallback: "后续维护只面向必要兼容性、Apple 系统变化和影响正常使用的重大问题。"
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
                                    fallback: "这一次，时光记完成 V3 收尾，让记录、设置与最终结果更加一致。"
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
                                    fallback: "2.0 延续本地优先的记忆呈现方式，重点让既有流程更可靠，让预览、保存和最终结果保持一致，并修复 MemoMark+ 的购买入口。"
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
