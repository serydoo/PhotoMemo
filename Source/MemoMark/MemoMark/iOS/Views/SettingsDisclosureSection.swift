#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI

/// Presents one Settings section while the Settings page retains its expansion
/// state, preferences, and action ownership.
struct SettingsDisclosureSection<Content: View>: View {

    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize

    @Environment(\.accessibilityReduceMotion)
    private var accessibilityReduceMotion

    let title: String
    let trailingValue: String?
    let language: MemoMarkLanguage
    let emphasis: SettingsSectionEmphasis

    @Binding
    var isExpanded: Bool

    @ViewBuilder
    let content: Content

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: ConfigurationSectionCardMetrics.headerContentSpacing
        ) {
            Button {
                withAnimation(disclosureAnimation) {
                    isExpanded.toggle()
                }
            } label: {
                adaptiveDisclosureHeader
                    .frame(
                        maxWidth: .infinity,
                        minHeight: 44,
                        alignment: .leading
                    )
                    .padding(
                        .horizontal,
                        ConfigurationUI.innerPanelPadding
                    )
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .frame(
                maxWidth: .infinity,
                minHeight: 44,
                alignment: .leading
            )
            .accessibilityLabel(title)
            .accessibilityValue(
                isExpanded
                ? localized(
                    "settings.accessibility.expanded",
                    fallback: "已展开"
                )
                : localized(
                    "settings.accessibility.collapsed",
                    fallback: "已收起"
                )
            )
            .accessibilityHint(
                localized(
                    "settings.accessibility.toggle_hint",
                    fallback: "点击展开或收起"
                )
            )

            if isExpanded {
                content
                    .transition(contentTransition)
            }
        }
        .v1SectionSurfaceLayout()
        .groupedSurface()
    }

    @ViewBuilder
    private var adaptiveDisclosureHeader: some View {
        if dynamicTypeSize.isAccessibilitySize {
            verticalDisclosureHeader
        } else {
            ViewThatFits(in: .horizontal) {
                horizontalDisclosureHeader
                verticalDisclosureHeader
            }
        }
    }

    private var horizontalDisclosureHeader: some View {
        HStack(spacing: 10) {
            disclosureTitle
            Spacer(minLength: 0)
            disclosureTrailingValue
            disclosureChevron
        }
    }

    private var verticalDisclosureHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            disclosureTitle

            HStack(spacing: 10) {
                disclosureTrailingValue
                Spacer(minLength: 0)
                disclosureChevron
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var disclosureTitle: some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary)
            .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private var disclosureTrailingValue: some View {
        if let trailingValue,
           !isExpanded {
            Text(trailingValue)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 1)
        }
    }

    private var disclosureChevron: some View {
        Image(systemName: "chevron.right")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.tertiary)
            .rotationEffect(
                .degrees(isExpanded ? 90 : 0)
            )
    }

    private var disclosureAnimation: Animation? {
        accessibilityReduceMotion
            ? nil
            : .easeInOut(duration: 0.2)
    }

    private var contentTransition: AnyTransition {
        guard !accessibilityReduceMotion else {
            return .identity
        }

        return .opacity.combined(
            with: .offset(y: -4)
        )
    }

    private func localized(
        _ key: String,
        fallback: String
    ) -> String {
        language.localized(key: key, fallback: fallback)
    }
}
#endif
