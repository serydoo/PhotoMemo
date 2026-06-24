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
            .navigationTitle("资料库")
            .navigationSplitViewColumnWidth(
                min: 240,
                ideal: 280
            )
        } content: {
            ZStack {
                ConfigurationUI.appBackground
                    .ignoresSafeArea()

                InteractiveMemoryCard(
                    session: session
                )
            }
            .navigationTitle("记忆卡片")
            .navigationSplitViewColumnWidth(
                min: 560,
                ideal: 640
            )
        } detail: {
            InspectorView(
                session: session
            )
            .navigationTitle("检查器")
            .navigationSplitViewColumnWidth(
                min: 300,
                ideal: 360
            )
        }
        .background(ConfigurationUI.appBackground)
    }
}

#Preview {
    ConfigurationCenterView()
        .frame(width: 1180, height: 760)
}
#endif
