#if !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct InspectorView: View {

    @ObservedObject
    var session: ConfigurationSession

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                inspectorHeader

                Divider()

                inspectorContent
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.white)
    }

    private var inspectorHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(session.state.selectedRegion.displayTitle)
                .font(.title3.weight(.semibold))

            Text(session.state.selectedRegion.semanticTitle)
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
