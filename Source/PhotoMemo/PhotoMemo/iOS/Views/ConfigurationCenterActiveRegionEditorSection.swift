#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct ConfigurationCenterActiveRegionEditorSection<Content: View>: View {

    let title: String
    let systemImage: String
    let selectedRegion: CardRegion
    @ViewBuilder var content: Content

    init(
        title: String,
        systemImage: String,
        selectedRegion: CardRegion,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.selectedRegion = selectedRegion
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Label(
                    title,
                    systemImage: systemImage
                )
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

                Spacer(minLength: 0)

                Text("随预览实时刷新")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            content
                .id(selectedRegion)
        }
        .padding(.top, 2)
    }
}
#endif
