#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI

/// Renders the Settings entry point for MemoMark+ from an already-resolved
/// commerce projection. Entitlement and allowance policy remain outside this view.
struct MemoMarkPlusSettingsCard: View {

    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize

    let isPlus: Bool
    let language: MemoMarkLanguage
    let status: String
    let statusDetail: String
    let accessibilityHint: String
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 13) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .fill(warmGold.opacity(0.11))

                        Image(systemName: isPlus ? "checkmark.seal.fill" : "sparkles")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(warmGold)
                    }
                    .frame(width: 46, height: 46)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("MemoMark+")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.primary)

                        Text(localized("commerce.settings.hero_detail", fallback: "继续保存那些未来值得回看的瞬间"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 0)
                }

                memoMarkPlusStatusRow
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(memoMarkPlusBackground)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("MemoMark+")
        .accessibilityValue(Text(verbatim: "\(status). " + statusDetail))
        .accessibilityHint(accessibilityHint)
    }

    @ViewBuilder
    private var memoMarkPlusStatusRow: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 8) {
                memoMarkPlusStatusText
                memoMarkPlusBenefitsLabel
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        } else {
            HStack(alignment: .top, spacing: 12) {
                memoMarkPlusStatusText
                Spacer(minLength: 0)
                memoMarkPlusBenefitsLabel
            }
        }
    }

    private var memoMarkPlusStatusText: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(status)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
            Text(statusDetail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var memoMarkPlusBenefitsLabel: some View {
        HStack(spacing: 6) {
            Text(localized("commerce.settings.view_benefits", fallback: "查看权益"))
                .font(.caption.weight(.semibold))
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(Color.accentColor)
        .frame(minHeight: ConfigurationUI.minimumInteractiveHeight, alignment: .top)
    }

    private var memoMarkPlusBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(ConfigurationUI.panelBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(warmGold.opacity(0.24), lineWidth: 0.8)
            )
    }

    private var warmGold: Color {
        Color(red: 0.58, green: 0.40, blue: 0.13)
    }

    private func localized(_ key: String, fallback: String) -> String {
        language.localized(key: key, fallback: fallback)
    }
}
#endif
