import SwiftUI

struct PhotoMemoRootSceneView: View {

    @Environment(\.scenePhase)
    private var scenePhase

    @StateObject
    private var personalProfileStore =
        PersonalProfileStore()

    @ObservedObject
    var runtime: PhotoMemoAppRuntime

    var body: some View {

        Group {
            if personalProfileStore.requiresFirstRun {
                FirstRunWizardView(
                    initialProfile:
                        personalProfileStore.profile
                ) { profile in
                    personalProfileStore
                        .completeFirstRun(
                            with: profile
                        )
                }
            } else {
                MainView()
                    .environmentObject(
                        personalProfileStore
                    )
                    .environmentObject(
                        runtime.batchQueueStore
                    )
            }
        }
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
}
