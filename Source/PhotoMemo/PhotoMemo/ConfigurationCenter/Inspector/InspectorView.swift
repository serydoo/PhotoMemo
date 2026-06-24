#if !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct InspectorView: View {

    @ObservedObject
    var session: ConfigurationSession

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                inspectorHeader

                inspectorContent
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 22)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(ConfigurationUI.appBackground)
    }

    private var inspectorHeader: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: headerSymbol)
                .font(.headline.weight(.semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.accentColor)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(Color.accentColor.opacity(0.10))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("对象检查器")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.primary)

                Text("\(session.state.selectedRegion.displayTitle) · \(session.state.selectedRegion.semanticTitle)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .configurationPanelChrome(isSelected: true)
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

    private var headerSymbol: String {
        switch session.state.selectedRegion {
        case .subject:
            return "person.fill"
        case .icon:
            return "person.crop.circle"
        case .badge:
            return "camera.fill"
        case .slotA:
            return "camera.fill"
        case .slotB:
            return "calendar"
        case .slotC:
            return "scope"
        case .slotD:
            return "text.quote"
        }
    }
}
#endif
