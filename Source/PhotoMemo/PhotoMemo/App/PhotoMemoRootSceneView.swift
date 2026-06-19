import SwiftUI

struct PhotoMemoRootSceneView: View {

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
    }
}
