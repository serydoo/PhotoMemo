#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI

/// Displays a Settings row that leads to an in-app action while keeping its
/// presentation independent from the action's state and ownership.
struct SettingsActionRow: View {

    let title: String
    let detail: String
    let systemImage: String
    let tint: Color
    let showsDivider: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                SettingsRowIcon(systemImage: systemImage, tint: tint)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)

            if showsDivider {
                HorizontalDivider(horizontalInset: 12)
            }
        }
    }
}

/// Displays a non-interactive privacy or local-data statement in Settings.
struct SettingsPrivacyRow: View {

    let title: String
    let detail: String
    let systemImage: String
    let tint: Color
    let showsDivider: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                SettingsRowIcon(systemImage: systemImage, tint: tint)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)

            if showsDivider {
                HorizontalDivider(horizontalInset: 12)
            }
        }
    }
}

/// Displays a read-only Settings row with title, headline, and optional detail.
struct SettingsInformationRow: View {

    let title: String
    let headline: String
    let detail: String?
    let systemImage: String
    let tint: Color
    let showsDivider: Bool

    var body: some View {
        SettingsContentRow(
            title: title,
            headline: headline,
            detail: detail,
            systemImage: systemImage,
            tint: tint,
            showsDivider: showsDivider
        )
    }
}

/// Displays a Settings row that may delegate its existing action to the page.
struct SettingsLinkRow: View {

    let title: String
    let headline: String
    let detail: String?
    let systemImage: String
    let tint: Color
    let showsDivider: Bool
    let action: (() -> Void)?

    init(
        title: String,
        headline: String,
        detail: String?,
        systemImage: String,
        tint: Color,
        showsDivider: Bool = true,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.headline = headline
        self.detail = detail
        self.systemImage = systemImage
        self.tint = tint
        self.showsDivider = showsDivider
        self.action = action
    }

    @ViewBuilder
    var body: some View {
        if let action {
            Button(action: action) {
                SettingsContentRow(
                    title: title,
                    headline: headline,
                    detail: detail,
                    systemImage: systemImage,
                    tint: tint,
                    showsDivider: showsDivider,
                    accessory: "chevron.right"
                )
            }
            .buttonStyle(.plain)
        } else {
            SettingsContentRow(
                title: title,
                headline: headline,
                detail: detail,
                systemImage: systemImage,
                tint: tint,
                showsDivider: showsDivider
            )
        }
    }
}

/// Displays the installed version using values resolved by the Settings page.
struct SettingsVersionRow: View {

    let title: String
    let compactVersion: String

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                SettingsRowIcon(
                    systemImage: MemoMarkSymbol.information.name,
                    tint: .secondary
                )

                Text(title)
                    .font(.subheadline.weight(.semibold))

                Spacer(minLength: 8)

                Text(compactVersion)
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(12)

            HorizontalDivider(horizontalInset: 12)
        }
    }
}

private struct SettingsContentRow: View {

    let title: String
    let headline: String
    let detail: String?
    let systemImage: String
    let tint: Color
    let showsDivider: Bool
    let accessory: String?

    init(
        title: String,
        headline: String,
        detail: String?,
        systemImage: String,
        tint: Color,
        showsDivider: Bool,
        accessory: String? = nil
    ) {
        self.title = title
        self.headline = headline
        self.detail = detail
        self.systemImage = systemImage
        self.tint = tint
        self.showsDivider = showsDivider
        self.accessory = accessory
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                SettingsRowIcon(systemImage: systemImage, tint: tint)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(headline)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    if let detail,
                       !detail.isEmpty {
                        Text(detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: 8)

                if let accessory {
                    Image(systemName: accessory)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 12)

            if showsDivider {
                HorizontalDivider(horizontalInset: 12)
            }
        }
    }
}

private struct SettingsRowIcon: View {

    let systemImage: String
    let tint: Color

    var body: some View {
        Image(systemName: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .frame(width: 24, height: 24)
            .accessibilityHidden(true)
    }
}
#endif
