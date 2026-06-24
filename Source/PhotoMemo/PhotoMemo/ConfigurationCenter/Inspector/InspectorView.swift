#if !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct InspectorView: View {

    @ObservedObject
    var session: ConfigurationSession

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                inspectorHeader

                Divider()

                inspectorContent
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.gray.opacity(0.03))
    }

    private var inspectorHeader: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Object Inspector")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.primary)

            Text("\(session.state.selectedRegion.displayTitle) · \(session.state.selectedRegion.semanticTitle)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var inspectorContent: some View {
        provider
            .view(session: session)
            .id(provider.id)
            .transition(
                .opacity
                    .combined(
                        with: .move(edge: .trailing)
                    )
            )
            .animation(
                .easeInOut(duration: 0.16),
                value: provider
            )
    }

    private var provider: InspectorProvider {
        CardRegionBehavior(
            region: session.state.selectedRegion
        )
        .inspectorProvider
    }
}
#endif
