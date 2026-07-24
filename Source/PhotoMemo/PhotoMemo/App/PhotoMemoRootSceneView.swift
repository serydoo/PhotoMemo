import SwiftUI

struct PhotoMemoRootSceneView: View {

    @Environment(\.scenePhase)
    private var scenePhase

    @AppStorage(
        MemoMarkLanguage.interfacePreferenceStorageKey,
        store: PhotoMemoSharedContainer.sharedUserDefaults
    )
    private var interfaceLanguagePreferenceRawValue =
        MemoMarkInterfaceLanguagePreference.system.rawValue

    @ObservedObject
    var runtime: PhotoMemoAppRuntime

    var body: some View {

        rootConfigurationCenter
            .preferredColorScheme(.light)
            .environment(
                \.locale,
                interfaceLanguagePreference.resolvedLanguage.locale
            )
            .onOpenURL { url in
                if let deepLink =
                    PhotoMemoDeepLink(
                        url: url
                    ) {
                    switch deepLink {
                    case .share:
                        PhotoMemoShareDiagnostics.record(
                            stage: .appOpenURLShare,
                            message: "Received memomark://share."
                        )
                        runtime
                            .refreshExternalIntakeState()
                    }
                    return
                }

                runtime.handleExternalURLs(
                    [url],
                    source: .fileOpen
                )
                PhotoMemoShareDiagnostics.record(
                    stage: .appOpenURLFile,
                    message: url.lastPathComponent
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

    private var interfaceLanguagePreference:
        MemoMarkInterfaceLanguagePreference {
        MemoMarkInterfaceLanguagePreference(
            rawValue: interfaceLanguagePreferenceRawValue
        ) ?? .system
    }

    @ViewBuilder
    private var rootConfigurationCenter: some View {
        #if os(iOS)
        PhotoMemoiOSV1View(
            backgroundStatusService:
                runtime.backgroundStatusService,
            refreshExternalIntake: {
                runtime.refreshExternalIntakeState()
            },
            previewCoordinator:
                runtime.environment.coordinators.preview,
            exportCoordinator:
                runtime.environment.coordinators.export,
            queueCoordinator:
                runtime.environment.coordinators.queue,
            configurationCoordinator:
                runtime.environment.coordinators.configuration,
            externalIntakeCenter:
                runtime.environment.externalIntakeCenter,
            diagnosticsRepository:
                runtime.environment.repositories.diagnostics
        )
        #else
        ConfigurationCenterView()
        #endif
    }
}
