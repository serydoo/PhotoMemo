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

    @AppStorage(
        MemoMarkAppearancePreference.storageKey,
        store: PhotoMemoSharedContainer.sharedUserDefaults
    )
    private var appearancePreferenceRawValue =
        MemoMarkAppearancePreference.system.rawValue

    @ObservedObject
    var runtime: PhotoMemoAppRuntime

    var body: some View {

        rootConfigurationCenter
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
                    message: "fileURLReceived=true"
                )
            }
            .onReceive(
                runtime.externalIntakeCenter
                .$revision
            ) { _ in
                runtime.refreshExternalIntakeState()
            }
            .task {
                await runtime.refreshPermissionsAndResume()
            }
            .onAppear {
                runtime.refreshExternalIntakeState()
            }
            .onChange(of: scenePhase) { _, newPhase in
                guard newPhase == .active else {
                    return
                }
                Task {
                    await runtime
                        .refreshPermissionsAndResume()
                }
            }
    }

    private var interfaceLanguagePreference:
        MemoMarkInterfaceLanguagePreference {
        MemoMarkInterfaceLanguagePreference(
            rawValue: interfaceLanguagePreferenceRawValue
        ) ?? .system
    }

    private var preferredColorScheme: ColorScheme? {
        switch appearancePreference {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    private var appearancePreference: MemoMarkAppearancePreference {
        MemoMarkAppearancePreference(
            rawValue: appearancePreferenceRawValue
        ) ?? .system
    }

    @ViewBuilder
    private var rootConfigurationCenter: some View {
        #if os(iOS)
        PhotoMemoiOSV1View(
            backgroundStatusService:
                runtime.backgroundStatusService,
            commerceStore: runtime.commerceStore,
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
                runtime.environment.repositories.diagnostics,
            productionDiagnosticsRepository:
                runtime.environment.repositories
                .productionDiagnostics
        )
        .preferredColorScheme(preferredColorScheme)
        #else
        ConfigurationCenterView()
        #endif
    }
}
