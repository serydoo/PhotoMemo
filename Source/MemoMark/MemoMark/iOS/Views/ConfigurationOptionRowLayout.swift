#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI

/// Owns the adaptive layout grammar shared by Configuration Center inspector rows.
///
/// The inspector provides memory/configuration-specific values and controls; this
/// surface owns only their stable horizontal and accessibility-size arrangement.
struct ConfigurationOptionRowLayout<Icon: View, Trailing: View>: View {

    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize

    let icon: Icon?
    let title: String
    let subtitle: String
    let detail: String
    let showsTrailingChevron: Bool
    let horizontalTrailingWidth: CGFloat
    let trailing: Trailing

    var body: some View {
        let trailingSpacing: CGFloat =
            detail.isEmpty && showsTrailingChevron == false
            ? 0
            : 4

        adaptiveConfigurationRow(trailingSpacing: trailingSpacing)
            .padding(
                .horizontal,
                CompactInformationRowMetrics.horizontalPadding
            )
            .padding(
                .vertical,
                CompactInformationRowMetrics.verticalPadding
            )
            .contentShape(Rectangle())
    }

    @ViewBuilder
    private func adaptiveConfigurationRow(
        trailingSpacing: CGFloat
    ) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            verticalConfigurationRow(trailingSpacing: trailingSpacing)
        } else {
            horizontalConfigurationRow(trailingSpacing: trailingSpacing)
        }
    }

    private func horizontalConfigurationRow(
        trailingSpacing: CGFloat
    ) -> some View {
        HStack(
            alignment: .center,
            spacing: CompactInformationRowMetrics.contentSpacing
        ) {
            configurationRowHeading()

            Spacer(minLength: 8)

            configurationRowTrailing(trailingSpacing: trailingSpacing)
                .frame(
                    minWidth: 72,
                    maxWidth: horizontalTrailingWidth,
                    alignment: .trailing
                )
        }
    }

    private func verticalConfigurationRow(
        trailingSpacing: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            configurationRowHeading()

            configurationRowTrailing(trailingSpacing: trailingSpacing)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private func configurationRowHeading() -> some View {
        HStack(
            alignment: .center,
            spacing: CompactInformationRowMetrics.contentSpacing
        ) {
            if let icon {
                icon
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(localized(title))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text(localized(subtitle))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .layoutPriority(1)
        }
    }

    private func configurationRowTrailing(
        trailingSpacing: CGFloat
    ) -> some View {
        VStack(alignment: .trailing, spacing: trailingSpacing) {
            trailing

            if !detail.isEmpty {
                configurationRowDetailLabel(detail)
            }

            if showsTrailingChevron {
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color.accentColor)
            }
        }
    }

    private func configurationRowDetailLabel(
        _ detail: String
    ) -> some View {
        Text(localized(detail))
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .truncationMode(.tail)
    }

    private func localized(_ value: String) -> String {
        MemoMarkLanguage.interfaceStored.localized(
            key: value,
            fallback: value
        )
    }
}
#endif
