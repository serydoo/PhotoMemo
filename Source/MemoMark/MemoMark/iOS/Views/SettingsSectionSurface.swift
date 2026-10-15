#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI

/// A semantic section heading and grouped content. State and actions belong to Settings.
struct SettingsSectionSurface<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 12)
                .accessibilityAddTraits(.isHeader)
            VStack(spacing: 0) { content }
                .groupedSurface()
        }
    }
}
#endif
