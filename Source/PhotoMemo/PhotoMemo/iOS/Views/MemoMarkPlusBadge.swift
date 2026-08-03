#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct MemoMarkPlusBadge: View {

    @AppStorage(
        MemoMarkLanguage.interfacePreferenceStorageKey,
        store: PhotoMemoSharedContainer.sharedUserDefaults
    )
    private var interfaceLanguagePreferenceRawValue =
        MemoMarkInterfaceLanguagePreference.system.rawValue

    let isFirstRecorder: Bool
    let action: () -> Void

    init(
        isFirstRecorder: Bool = false,
        action: @escaping () -> Void
    ) {
        self.isFirstRecorder = isFirstRecorder
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: "sparkles")
                    .font(.caption2.weight(.bold))

                Text("MemoMark+")
                    .font(.caption.weight(.bold))
            }
            .foregroundStyle(
                Color(
                    red: 0.55,
                    green: 0.38,
                    blue: 0.12
                )
            )
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(
                        Color(
                            red: 0.98,
                            green: 0.94,
                            blue: 0.82
                        )
                    )
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(
                        Color(
                            red: 0.72,
                            green: 0.53,
                            blue: 0.20
                        )
                        .opacity(0.32),
                        lineWidth: 0.75
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(
            localized(
                "commerce.badge.accessibility.hint",
                fallback: "查看 MemoMark+ 权益"
            )
        )
    }

    private var accessibilityLabel: String {
        if isFirstRecorder {
            return localized(
                "commerce.badge.accessibility.first_recorder_label",
                fallback: "MemoMark+ 已解锁，首批记录者"
            )
        }

        return localized(
            "commerce.badge.accessibility.label",
            fallback: "MemoMark+ 已解锁"
        )
    }

    private func localized(
        _ key: String,
        fallback: String
    ) -> String {
        let language = MemoMarkInterfaceLanguagePreference(
            rawValue: interfaceLanguagePreferenceRawValue
        )?.resolvedLanguage
        ?? MemoMarkLanguage.interfaceStored
        return language.localized(
            key: key,
            fallback: fallback
        )
    }
}
#endif
