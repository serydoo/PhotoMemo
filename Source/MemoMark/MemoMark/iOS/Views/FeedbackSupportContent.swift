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
    let onOpenGitHubIssues: () -> Void

    var body: some View {
        VStack(spacing: 0) {
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
                    showsDivider: true
                )
            }
            .buttonStyle(.plain)
            .disabled(isPreparingDiagnosticExport)

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
                    showsDivider: true
                )
            }

            SettingsLinkRow(
                title: localized(
                    "settings.feedback.github.title",
                    fallback: "GitHub Issues"
                ),
                headline: localized(
                    "settings.feedback.github.headline",
                    fallback: "公开可复现问题"
                ),
                detail: localized(
                    "settings.feedback.github.detail",
                    fallback: "适合记录稳定复现的缺陷和后续开发讨论。"
                ),
                systemImage: "chevron.left.forwardslash.chevron.right",
                tint: .purple,
                showsDivider: false,
                action: onOpenGitHubIssues
            )
        }
        .background(Color.clear)
    }

    private func localized(_ key: String, fallback: String) -> String {
        language.localized(key: key, fallback: fallback)
    }
}
#endif
