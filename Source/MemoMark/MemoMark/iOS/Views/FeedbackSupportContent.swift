#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI

/// Composes Settings feedback rows from state and actions resolved by the
/// Settings page, which remains the owner of diagnostics and external links.
struct FeedbackSupportContent: View {

    let language: MemoMarkLanguage
    let isTestFlightExperienceActive: Bool
    let isPreparingDiagnosticExport: Bool
    let onPrepareDiagnosticExport: () -> Void
    let onOpenMailFeedback: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            SettingsLinkRow(
                title: localized(
                    "settings.feedback.email.title",
                    fallback: "邮件反馈"
                ),
                headline: "serydoo@gmail.com",
                detail: localized(
                    "settings.feedback.email.detail",
                    fallback: "告诉我们你遇到的问题或想法。"
                ),
                systemImage: "envelope.fill",
                tint: .blue,
                showsDivider: true,
                action: onOpenMailFeedback
            )

            SettingsInformationRow(
                title: localized("settings.feedback.xiaohongshu.title", fallback: "小红书反馈"),
                headline: localized("settings.feedback.xiaohongshu.headline", fallback: "搜索 MemoMark"),
                detail: localized("settings.feedback.xiaohongshu.detail", fallback: "找到 MemoMark 账号，直接私信反馈问题或建议。"),
                systemImage: "at",
                tint: .pink,
                showsDivider: true
            )
            .textSelection(.enabled)

            Button(action: onPrepareDiagnosticExport) {
                SettingsActionRow(
                    title: localized(
                        "settings.feedback.diagnostics.title",
                        fallback: "导出诊断信息"
                    ),
                    detail: localized(
                        "settings.feedback.diagnostics.detail",
                        fallback: "生成不含照片、文字内容和位置的故障记录，用于定位保存与处理问题。"
                    ),
                    systemImage: isPreparingDiagnosticExport
                        ? "clock"
                        : "doc.badge.gearshape",
                    tint: .orange,
                    showsDivider: isTestFlightExperienceActive
                )
            }
            .buttonStyle(.plain)
            .disabled(isPreparingDiagnosticExport)

            if isTestFlightExperienceActive {
                SettingsInformationRow(
                    title: localized(
                        "settings.feedback.testflight.title",
                        fallback: "TestFlight 反馈"
                    ),
                    headline: localized(
                        "settings.feedback.testflight.headline",
                        fallback: "适合闪退、截图和录屏"
                    ),
                    detail: localized(
                        "settings.feedback.testflight.detail",
                        fallback: "优先使用系统内置反馈，方便带上设备和崩溃上下文。"
                    ),
                    systemImage: "wrench.and.screwdriver.fill",
                    tint: .orange,
                    showsDivider: false
                )
            }
        }
        .background(Color.clear)
    }

    private func localized(_ key: String, fallback: String) -> String {
        language.localized(key: key, fallback: fallback)
    }
}
#endif
