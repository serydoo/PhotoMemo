#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct PhotoMemoiOSTemporaryEntryView: View {

    @ObservedObject
    var backgroundStatusService:
        PhotoMemoBackgroundStatusService

    let refreshExternalIntake:
        () -> Void

    @AppStorage
    private var selectedEntry: String

    init(
        backgroundStatusService:
            PhotoMemoBackgroundStatusService,
        refreshExternalIntake:
            @escaping () -> Void = {},
        storageKey: String = "photomemo.ios.temporaryEntry",
        defaultEntry: String = "configurationCenter"
    ) {
        self.backgroundStatusService =
            backgroundStatusService
        self.refreshExternalIntake =
            refreshExternalIntake
        _selectedEntry =
            AppStorage(
                wrappedValue: defaultEntry,
                storageKey
            )
    }

    var body: some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Picker("临时入口", selection: $selectedEntry) {
                            Text("当前配置中心")
                                .tag("configurationCenter")
                            Text("MVP 测试页")
                                .tag("mvpTest")
                        }
                    } label: {
                        Label("临时入口", systemImage: "square.grid.2x2")
                    }
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        switch selectedEntry {
        case "mvpTest":
            PhotoMemoiOSMVPTestView(
                backgroundStatusService:
                    backgroundStatusService,
                refreshExternalIntake:
                    refreshExternalIntake
            )
        default:
            ConfigurationCenteriOSView()
        }
    }
}
#endif
