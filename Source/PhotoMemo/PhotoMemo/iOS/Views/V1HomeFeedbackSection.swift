#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct V1HomeFeedbackSection: View {

    private var interfaceLanguage: MemoMarkLanguage {
        .interfaceStored
    }

    @AppStorage("photomemo.v1.homeFeedbackExpanded")
    private var isExpanded = true

    var body: some View {
        V1CardSurface(
            title: "home.feedback.title",
            systemImage: MemoMarkSymbol.feedback.name,
            tint: .pink
        ) {
            VStack(alignment: .leading, spacing: 12) {
                disclosureControl

                if isExpanded {
                    expandedChannels
                        .transition(
                            .opacity.combined(
                                with: .move(edge: .top)
                            )
                        )
                }
            }
        }
    }

    private var disclosureControl: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.20)) {
                isExpanded.toggle()
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(localized("home.feedback.contact_developer"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(
                        localized(
                            isExpanded
                            ? "home.feedback.collapse"
                            : "home.feedback.expand"
                        )
                    )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                Image(
                    systemName: isExpanded
                    ? "chevron.up"
                    : "chevron.down"
                )
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(localized("home.feedback.accessibility.label"))
        .accessibilityValue(
            localized(
                isExpanded
                ? "home.feedback.accessibility.expanded"
                : "home.feedback.accessibility.collapsed"
            )
        )
        .accessibilityHint(localized("home.feedback.accessibility.hint"))
    }

    private var expandedChannels: some View {
        VStack(alignment: .leading, spacing: 12) {
            V1HorizontalDivider()

            feedbackRow(
                title: localized("home.feedback.social.title"),
                detail: localized("home.feedback.social.detail"),
                systemImage: "magnifyingglass",
                tint: .red
            )

            feedbackRow(
                title: localized("home.feedback.qq.title"),
                detail: localized("home.feedback.qq.detail"),
                systemImage: "person.3.fill",
                tint: .teal
            )

            Label(
                localized("home.feedback.welcome"),
                systemImage: "text.bubble.fill"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)

            Text(localized("home.feedback.testflight"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func feedbackRow(
        title: String,
        detail: String,
        systemImage: String,
        tint: Color
    ) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)

                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
            }
        }
    }

    private func localized(_ key: String) -> String {
        interfaceLanguage.localized(key: key, fallback: key)
    }
}
#endif
