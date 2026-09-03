#if !MEMOMARK_SHARE_EXTENSION
import SwiftUI

/// The Home-only presentation of an immutable queue-status projection.
/// Queue ownership, background scheduling, and navigation stay outside this
/// surface; it only manages the short visual lifetime of a received projection.
struct HomeActivityCard: View {

    private var interfaceLanguage: MemoMarkLanguage {
        .interfaceStored
    }

    @Environment(\.accessibilityReduceMotion)
    private var accessibilityReduceMotion

    let projection: HomeActivityProjection
    let onOpenProcessing: () -> Void

    @State
    private var isMounted =
        HomeActivityPresentationState()
        .isMounted

    @State
    private var isVisible =
        HomeActivityPresentationState()
        .isVisible

    var body: some View {
        Group {
            if isMounted {
                VStack(alignment: .leading, spacing: 8) {
                    Text(localized("home.activity.title"))
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Button(action: onOpenProcessing) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .center, spacing: 12) {
                                Text(projection.countText)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                    .monospacedDigit()
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.82)

                                Spacer(minLength: 8)

                                Text(projection.statusText)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(statusColor)
                                    .lineLimit(1)
                            }

                            activityProgressBar
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, ConfigurationUI.innerPanelPadding)
                        .padding(.vertical, ConfigurationUI.innerPanelPadding)
                        .background(
                            RoundedRectangle(
                                cornerRadius: ConfigurationUI.innerPanelCornerRadius,
                                style: .continuous
                            )
                            .fill(ConfigurationUI.controlBackground)
                        )
                        .overlay(
                            RoundedRectangle(
                                cornerRadius: ConfigurationUI.innerPanelCornerRadius,
                                style: .continuous
                            )
                            .stroke(ConfigurationUI.faintHairline)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(
                        "\(projection.countText)，\(projection.statusText)"
                    )
                    .accessibilityValue(
                        String(
                            format: localized("home.activity.progress"),
                            locale: interfaceLanguage.locale,
                            progressPercentText
                        )
                    )
                }
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible || accessibilityReduceMotion ? 0 : -6)
            }
        }
        .task(id: projection.lifecycleID) {
            await present(projection)
        }
    }

    private var activityProgressBar: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(Color.accentColor.opacity(0.16))

                Capsule(style: .continuous)
                    .fill(Color.accentColor)
                    .frame(
                        width: proxy.size.width
                            * projection.progressFraction
                    )
            }
        }
        .frame(height: 4)
        .accessibilityHidden(true)
    }

    private var statusColor: Color {
        switch projection.state {
        case .processing:
            return .accentColor
        case .completed:
            return .green
        case .failed:
            return .red
        }
    }

    private var progressPercentText: String {
        "\(Int((projection.progressFraction * 100).rounded()))%"
    }

    private func localized(_ key: String) -> String {
        interfaceLanguage.localized(key: key, fallback: key)
    }

    @MainActor
    private func present(
        _ projection: HomeActivityProjection
    ) async {
        let wasVisible = isVisible
        guard HomeActivityPresenter.shouldShow(projection) else {
            await dismiss()
            return
        }

        isMounted = true

        if !wasVisible {
            isVisible = false
            await Task.yield()
            withAnimation(
                accessibilityReduceMotion
                ? nil
                : .easeOut(duration: 0.25)
            ) {
                isVisible = true
            }
        } else {
            isVisible = true
        }

        guard projection.state == .completed else {
            return
        }

        let elapsed =
            Date().timeIntervalSince(projection.updatedAt)
        let remaining =
            max(
                HomeActivityPresenter
                    .completionDisplayDuration
                    - elapsed,
                0
            )

        if remaining > 0 {
            try? await Task.sleep(
                nanoseconds: UInt64(remaining * 1_000_000_000)
            )
        }

        guard !Task.isCancelled else {
            return
        }

        await dismiss()
    }

    @MainActor
    private func dismiss() async {
        withAnimation(
            accessibilityReduceMotion
            ? nil
            : .easeOut(duration: 0.2)
        ) {
            isVisible = false
        }

        if !accessibilityReduceMotion {
            try? await Task.sleep(
                nanoseconds: 200_000_000
            )
        }

        guard !Task.isCancelled else {
            return
        }

        isMounted = false
    }
}
#endif
