#if !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct ConfigurationCenterView: View {

    @StateObject
    private var session =
        ConfigurationSession()

    var body: some View {
        NavigationSplitView {
            MemorySubjectListView(
                session: session
            )
            .navigationTitle("Library")
            .navigationSplitViewColumnWidth(
                min: 240,
                ideal: 280
            )
        } content: {
            InteractiveMemoryCard(
                session: session
            )
            .navigationTitle("Memory Card")
            .navigationSplitViewColumnWidth(
                min: 420,
                ideal: 560
            )
        } detail: {
            InspectorView(
                session: session
            )
            .navigationTitle("Inspector")
            .navigationSplitViewColumnWidth(
                min: 300,
                ideal: 360
            )
        }
        .background(Color.white)
    }
}

#Preview {
    ConfigurationCenterView()
        .frame(width: 1180, height: 760)
}
#endif
