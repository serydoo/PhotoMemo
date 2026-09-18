#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI

/// Composes the getting-started narrative while delegating each action back to
/// the Settings page that owns presentation state.
struct GettingStartedSupportContent: View {
    let language: MemoMarkLanguage
    let onShowAbout: () -> Void
    let onShowWelcome: () -> Void
    let onShowWorkflow: () -> Void
    let onShowExpressionGuide: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: ConfigurationSectionCardMetrics.headerContentSpacing) {
            Text(localized("settings.overview.headline", fallback: "让照片记得，它在人生里的位置。"))
                .font(.headline.weight(.semibold)).foregroundStyle(.primary)
                .padding(.horizontal, ConfigurationUI.innerPanelPadding)
            Text(localized("settings.getting_started.detail", fallback: "照片不只记录拍摄时间，也能记下它在人生中的位置。"))
                .font(.subheadline).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, ConfigurationUI.innerPanelPadding)
            VStack(spacing: 0) {
                action("settings.guide.expression.title", "MemoMark 怎么讲述时间", "settings.guide.expression.detail", "看看时间锚点如何让照片在之前、当天和之后说出不同的话。", MemoMarkSymbol.expressionFormula.name, .purple, true, onShowExpressionGuide)
                action("settings.overview.title", "关于 MemoMark 的诞生", "settings.overview.action_detail", "了解 MemoMark 为什么从一段人生里的时间开始。", MemoMarkSymbol.information.name, .pink, true, onShowAbout)
                action("settings.guide.welcome.title", "重看欢迎介绍", "settings.guide.welcome.detail", "回顾首次使用时的主要说明。", MemoMarkSymbol.welcome.name, .orange, true, onShowWelcome)
                action("settings.guide.workflow.title", "查看日常使用流程", "settings.guide.workflow.detail", "从 Apple Photos 分享，再回到相册查看。", MemoMarkSymbol.workflow.name, .blue, false, onShowWorkflow)
            }
            .background(Color.clear)
        }
    }

    private func action(_ titleKey: String, _ titleFallback: String, _ detailKey: String, _ detailFallback: String, _ systemImage: String, _ tint: Color, _ showsDivider: Bool, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            SettingsActionRow(title: localized(titleKey, fallback: titleFallback), detail: localized(detailKey, fallback: detailFallback), systemImage: systemImage, tint: tint, showsDivider: showsDivider)
        }
        .buttonStyle(.plain)
    }

    private func localized(_ key: String, fallback: String) -> String { language.localized(key: key, fallback: fallback) }
}
#endif
