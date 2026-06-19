import SwiftUI

struct PhotoMemoRootSceneView: View {

    @Environment(\.scenePhase)
    private var scenePhase

    @ObservedObject
    var runtime: PhotoMemoAppRuntime

    var body: some View {

        MainView()
            .environmentObject(
                runtime.batchQueueStore
            )
            .preferredColorScheme(.light)
            .onOpenURL { url in
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
}
