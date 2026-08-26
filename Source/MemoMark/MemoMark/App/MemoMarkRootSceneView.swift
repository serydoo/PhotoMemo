import SwiftUI

struct MemoMarkRootSceneView: View {

    @State
    private var pendingNotificationDeepLink: MemoMarkDeepLink?

    @Environment(\.scenePhase)
    private var scenePhase

    @AppStorage(
        MemoMarkLanguage.interfacePreferenceStorageKey,
        store: MemoMarkSharedContainer.sharedUserDefaults
    )
    private var interfaceLanguagePreferenceRawValue =
        MemoMarkInterfaceLanguagePreference.system.rawValue

    @AppStorage(
        MemoMarkAppearancePreference.storageKey,
        store: MemoMarkSharedContainer.sharedUserDefaults
    )
    private var appearancePreferenceRawValue =
        MemoMarkAppearancePreference.system.rawValue

    @ObservedObject
    var runtime: MemoMarkAppRuntime

    var body: some View {

        rootConfigurationCenter
            .environment(
                \.locale,
                interfaceLanguagePreference.resolvedLanguage.locale
            )
            .onOpenURL { url in
                if let deepLink =
                    MemoMarkDeepLink(
                        url: url
                    ) {
                    switch deepLink {
                    case .share:
                        MemoMarkShareDiagnostics.record(
                            stage: .appOpenURLShare,
                            message: "Received memomark://share."
                        )
                        runtime
                            .refreshExternalIntakeState()
                    case .processing:
                        pendingNotificationDeepLink = deepLink
                    }
                    return
                }

                runtime.handleExternalURLs(
                    [url],
                    source: .fileOpen
                )
                MemoMarkShareDiagnostics.record(
                    stage: .appOpenURLFile,
                    message: "fileURLReceived=true"
                )
            }
            .onReceive(
                NotificationCenter.default.publisher(
                    for: .photoMemoNotificationOpened
                )
            ) { notification in
                guard
                    let rawURL = notification.userInfo?[MemoMarkNotificationUserInfo.deepLinkURL]
                        as? String,
                    let url = URL(string: rawURL),
                    let deepLink = MemoMarkDeepLink(url: url)
                else {
                    return
                }
                pendingNotificationDeepLink = deepLink
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
        MemoMarkiOSV1View(
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
                .productionDiagnostics,
            notificationDeepLink:
                pendingNotificationDeepLink,
            onNotificationDeepLinkHandled: {
                pendingNotificationDeepLink = nil
            }
        )
        .preferredColorScheme(preferredColorScheme)
        #else
        ConfigurationCenterView()
        #endif
    }
}
