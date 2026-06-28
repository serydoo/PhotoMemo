import SwiftUI

struct PhotoMemoRootSceneView: View {

    @Environment(\.scenePhase)
    private var scenePhase

    @ObservedObject
    var runtime: PhotoMemoAppRuntime

    private let temporaryEntryStorageKey: String

    private let temporaryEntryDefault: String

    init(
        runtime: PhotoMemoAppRuntime,
        temporaryEntryStorageKey: String =
            "photomemo.ios.temporaryEntry",
        temporaryEntryDefault: String =
            "configurationCenter"
    ) {
        self.runtime = runtime
        self.temporaryEntryStorageKey =
            temporaryEntryStorageKey
        self.temporaryEntryDefault =
            temporaryEntryDefault
    }

    var body: some View {

        rootConfigurationCenter
            .preferredColorScheme(.light)
            .onOpenURL { url in
                if let deepLink =
                    PhotoMemoDeepLink(
                        url: url
                    ) {
                    switch deepLink {
                    case .share:
                        runtime
                            .refreshExternalIntakeState()
                    }
                    return
                }

                runtime.handleExternalURLs(
                    [url],
                    source: .fileOpen
                )
            }
            .onReceive(
                runtime.externalIntakeCenter
                .$revision
            ) { _ in
                runtime.flushExternalRequests()
            }
            .task {
                runtime.refreshExternalIntakeState()
            }
            .onAppear {
                runtime.refreshExternalIntakeState()
            }
            .onChange(of: scenePhase) { _, newPhase in
                guard newPhase == .active else {
                    return
                }

                runtime.refreshExternalIntakeState()
            }
    }

    @ViewBuilder
    private var rootConfigurationCenter: some View {
        #if os(iOS)
        PhotoMemoiOSTemporaryEntryView(
            storageKey: temporaryEntryStorageKey,
            defaultEntry: temporaryEntryDefault
        )
        #else
        ConfigurationCenterView()
        #endif
    }
}
