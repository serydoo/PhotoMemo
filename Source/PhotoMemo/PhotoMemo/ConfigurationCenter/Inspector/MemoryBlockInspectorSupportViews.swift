#if !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct MemoryBlockInspectorCollapsibleSection<Content: View>: View {

    let title: String
    let systemImage: String
    @Binding
    var isExpanded: Bool
    @ViewBuilder
    let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            Button {
                withAnimation(.easeInOut(duration: 0.16)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: systemImage)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 16)

                    Text(title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Spacer(minLength: 0)

                    Image(
                        systemName:
                            isExpanded
                            ? "chevron.down"
                            : "chevron.right"
                    )
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                content()
                    .transition(
                        .opacity
                            .combined(with: .move(edge: .top))
                    )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 2)
    }
}

struct MemoryBlockInspectorOverviewSection: View {

    let title: String
    let summary: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.primary)

            Text(summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .configurationPanelChrome()
    }
}
#endif
