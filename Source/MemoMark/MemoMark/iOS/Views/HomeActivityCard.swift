#if !MEMOMARK_SHARE_EXTENSION
import SwiftUI

/// The Home-only presentation of an immutable queue-status projection.
/// Queue ownership and scheduling stay outside this surface; it renders the
/// current projection and emits cancel and history deletion actions.
struct HomeActivityCard: View {

    private var interfaceLanguage: MemoMarkLanguage {
        .interfaceStored
    }

    @Environment(\.accessibilityReduceMotion)
    private var accessibilityReduceMotion

    let projection: HomeActivityProjection
    let onOpenProcessing: () -> Void
    let isPaused: Bool
    let onCancel: () -> Void
    let onDeleteRecord: () -> Void

    @State private var showsCancelConfirmation = false
    @State private var showsDeleteConfirmation = false

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

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Button(action: onOpenProcessing) {
                                HStack(alignment: .center, spacing: 12) {
                                    Text(projection.countText)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.primary)
                                        .monospacedDigit()
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.82)

                                    Spacer(minLength: 8)

                                    Text(isPaused
                                        ? localized("home.activity.status.interrupted")
                                        : projection.statusText)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(statusColor)
                                        .lineLimit(1)
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(projection.countText)，\(isPaused ? localized("home.activity.status.interrupted") : projection.statusText)")
                            .accessibilityValue(
                                String(
                                    format: localized("home.activity.progress"),
                                    locale: interfaceLanguage.locale,
                                    progressPercentText
                                )
                            )

                            if projection.state == .processing && !isPaused {
                                Button { showsCancelConfirmation = true } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 12, weight: .semibold))
                                        .frame(width: 44, height: 44)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.borderless)
                                .tint(.red)
                                .accessibilityLabel(localized("home.activity.cancel"))
                            } else {
                                Button { showsDeleteConfirmation = true } label: {
                                    Image(systemName: "trash")
                                        .font(.system(size: 12, weight: .semibold))
                                        .frame(width: 44, height: 44)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.borderless)
                                .tint(.red)
                                .accessibilityLabel(localized("home.activity.delete"))
                                .accessibilityIdentifier("home-activity-delete-record")
                            }
                        }
                        activityProgressBar
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, ConfigurationUI.innerPanelPadding)
                    .padding(.vertical, 8)
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
                    .alert(localized("home.activity.cancel.title"), isPresented: $showsCancelConfirmation) {
                        Button(localized("home.activity.cancel.confirm"), role: .destructive, action: onCancel)
                        Button(localized("home.activity.cancel.keep"), role: .cancel) {}
                    } message: {
                        Text(localized("home.activity.cancel.message"))
                    }
                    .alert(localized("home.activity.delete"), isPresented: $showsDeleteConfirmation) {
                        Button(localized("home.activity.delete"), role: .destructive, action: onDeleteRecord)
                        Button(localized("home.activity.cancel.keep"), role: .cancel) {}
                    } message: {
                        Text(localized("home.activity.delete.message"))
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("home-activity-record-\(projection.jobID.uuidString)")
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
        if isPaused { return .secondary }
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
