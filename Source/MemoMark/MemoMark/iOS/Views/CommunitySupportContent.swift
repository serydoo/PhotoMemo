#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI

/// Displays MemoMark's read-only community contact details without owning
/// external links, diagnostics, or Settings disclosure state.
struct CommunitySupportContent: View {

    let language: MemoMarkLanguage

    var body: some View {
        VStack(spacing: 0) {
            SettingsInformationRow(
                title: localized(
                    "settings.feedback.qq.title",
                    fallback: "QQ 交流群"
                ),
                headline: "955680366",
                detail: localized(
                    "settings.feedback.qq.detail",
                    fallback: "交流使用问题与产品想法。"
                ),
                systemImage: "person.2.fill",
                tint: .blue,
                showsDivider: true
            )
            .textSelection(.enabled)

            SettingsInformationRow(
                title: localized(
                    "settings.feedback.social.title",
                    fallback: "小红书、抖音"
                ),
                headline: localized(
                    "settings.feedback.social.headline",
                    fallback: "搜索 MemoMark"
                ),
                detail: localized(
                    "settings.feedback.social.detail",
                    fallback: "分享体验与建议。"
                ),
                systemImage: "at",
                tint: .pink,
                showsDivider: false
            )
            .textSelection(.enabled)
        }
        .background(Color.clear)
    }

    private func localized(_ key: String, fallback: String) -> String {
        language.localized(key: key, fallback: fallback)
    }
}
#endif
