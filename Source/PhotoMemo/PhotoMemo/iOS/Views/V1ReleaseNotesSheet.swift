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
                        fallback: "记录更稳定，也更容易定位问题"
                ),
                bullets: [
                    localized(
                        "settings.release_notes.reliable_recording.item_one",
                        fallback: "保存失败现在会说明具体原因，并提供恢复建议与支持编号。"
                    ),
                    localized(
                        "settings.release_notes.reliable_recording.item_two",
                        fallback: "新增本地诊断记录与脱敏导出，方便定位不同设备上的保存和处理问题。"
                    ),
                    localized(
                        "settings.release_notes.reliable_recording.item_three",
                        fallback: "Live Photo 在动态资源不可用、配对失败或保存后未保真时不再静默降级为静态图片。"
                    ),
                    localized(
                        "settings.release_notes.reliable_recording.item_four",
                        fallback: "超大、超宽、无法读取或格式不兼容的图片会给出可理解的失败原因，而不是只显示处理中。"
                    ),
                    localized(
                        "settings.release_notes.reliable_recording.item_five",
                        fallback: "保留重试、通知、来源文件清理和重复保存保护，降低中断后状态不一致的风险。"
                    )
                ]
            ),
            V1ReleaseNoteSection(
                id: "configuration-center",
                title: localized(
                    "settings.release_notes.configuration_center.title",
                        fallback: "配置中心更稳定"
                ),
                bullets: [
                    localized(
                        "settings.release_notes.configuration_center.item_one",
                        fallback: "模块使用稳定身份保存，旧配置可以安全恢复，不再因内部名称变化丢失标题。"
                    ),
                    localized(
                        "settings.release_notes.configuration_center.item_two",
                        fallback: "组合变量可以在恢复与预览时完整解析，最终内容不再原样显示占位符。"
                    ),
                    localized(
                        "settings.release_notes.configuration_center.item_three",
                        fallback: "模块标题统一从本地化目录读取，中文目录不再分散在多套硬编码列表中。"
                    )
                ]
            ),
            V1ReleaseNoteSection(
                id: "advanced-modules",
                title: localized(
                    "settings.release_notes.advanced_modules.title",
                        fallback: "模块与小屏体验"
                ),
                bullets: [
                    localized(
                        "settings.release_notes.advanced_modules.item_one",
                        fallback: "记忆、时间、拍摄参数和位置模块统一使用稳定身份、展示名称和渲染令牌。"
                    ),
                    localized(
                        "settings.release_notes.advanced_modules.item_two",
                        fallback: "配置、预览与最终输出共用模块兼容规则，减少不同界面显示不一致。"
                    ),
                    localized(
                        "settings.release_notes.advanced_modules.item_three",
                        fallback: "长自定义内容仍然保存用户原文；显示适配与配置持久化保持边界分离。"
                    ),
                    localized(
                        "settings.release_notes.advanced_modules.item_four",
                        fallback: "较小 iPhone、窄屏和较大文字继续使用稳定的垂直布局与原生菜单回退。"
                    ),
                    localized(
                        "settings.release_notes.advanced_modules.item_five",
                        fallback: "保留动态字体、VoiceOver 和原生交互行为。"
                    )
                ]
            ),
            V1ReleaseNoteSection(
                id: "iphone-and-settings",
                title: localized(
                    "settings.release_notes.iphone_and_settings.title",
                        fallback: "iPhone 界面与反馈中心"
                ),
                bullets: [
                    localized(
                        "settings.release_notes.iphone_and_settings.item_one",
                        fallback: "设置中的反馈入口可以导出不含照片、文字和位置的诊断文件。"
                    ),
                    localized(
                        "settings.release_notes.iphone_and_settings.item_two",
                        fallback: "失败状态会显示阶段、具体原因、恢复建议和支持编号。"
                    ),
                    localized(
                        "settings.release_notes.iphone_and_settings.item_three",
                        fallback: "诊断记录保存在本地 App Group，不会自动上传照片或用户内容。"
                    ),
                    localized(
                        "settings.release_notes.iphone_and_settings.item_four",
                        fallback: "更新日志继续直接在应用内显示，不依赖外部网页。"
                    ),
                    localized(
                        "settings.release_notes.iphone_and_settings.item_five",
                        fallback: "Configuration Center、Memory Engine、Renderer、Layout Engine 和 Export 的职责边界保持不变。"
                    )
                ]
            ),
            V1ReleaseNoteSection(
                id: "expression-and-language",
                title: localized(
                    "settings.release_notes.expression_and_language.title",
                        fallback: "表达、兼容与隐私"
                ),
                bullets: [
                    localized(
                        "settings.release_notes.expression_and_language.item_one",
                        fallback: "模块标题面向用户显示自然的中文或英文，不再回退到内部英文名称。"
                    ),
                    localized(
                        "settings.release_notes.expression_and_language.item_two",
                        fallback: "组合变量继续只提供时间结果，最终句子仍由用户控制。"
                    ),
                    localized(
                        "settings.release_notes.expression_and_language.item_three",
                        fallback: "超出预览区域的文字不会直接导致配置保存失败。"
                    ),
                    localized(
                        "settings.release_notes.expression_and_language.item_four",
                        fallback: "权限、隐私、错误、恢复和诊断导出继续使用直接、准确的表达。"
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
                        fallback: "原始照片不被修改，Live Photo 输出现在会经过动态资源和 PhotoKit 回读确认。"
                    ),
                    localized(
                        "settings.release_notes.unchanged.item_four",
                        fallback: "日常流程仍然是 Apple Photos → 分享 → 时光记 → 处理 → 通知 → Apple Photos。"
                    ),
                    localized(
                        "settings.release_notes.unchanged.item_five",
                        fallback: "照片仍然只在设备本地处理，不上传，也不替换 Apple Photos 中的原始照片。"
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
                        fallback: "配置兼容、诊断脱敏、Live Photo 路由、保存回读和处理失败分类均有对应契约验证。"
                    ),
                    localized(
                        "settings.release_notes.verification.item_two",
                        fallback: "完整 macOS 测试回归通过 1,221 项，跳过 1 项，失败 0 项。"
                    ),
                    localized(
                        "settings.release_notes.verification.item_three",
                        fallback: "macOS、iOS、Share Extension 与 Widget Extension 构建通过，版本字段统一为 2.0.2 (68)。"
                    ),
                    localized(
                        "settings.release_notes.verification.item_four",
                        fallback: "专项测试覆盖静态降级阻断、Live Photo 回读、配置失败分类、诊断隐私和模块兼容恢复。"
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
                        fallback: "2.0.2 是 V4 阶段面向生产可靠性和兼容性的维护版本，不改变冻结的核心架构。"
                    ),
                    localized(
                        "settings.release_notes.next_stage.item_two",
                        fallback: "后续工作继续优先处理真实用户故障、Apple 平台兼容性和隐私可靠性问题。"
                    ),
                    localized(
                        "settings.release_notes.next_stage.item_three",
                        fallback: "V4 表达方式研究与后续维护仍需遵循既有产品和架构边界。"
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
                                    fallback: "这一次，时光记把真实用户故障变成可定位、可恢复的记录。"
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
                                    fallback: "2.0.2 延续本地优先的记忆呈现方式，重点修复配置兼容、故障反馈和 Live Photo 保真问题。"
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
