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
                        Task {
                            await runtime
                                .refreshExternalIntakeState()
                        }
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
                Task {
                    await runtime
                        .refreshExternalIntakeState()
                }
            }
            .task {
                await runtime.refreshPermissionsAndResume()
            }
            .onAppear {
                Task {
                    await runtime
                        .refreshExternalIntakeState()
                }
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
            .onChange(of: interfaceLanguagePreferenceRawValue) { _, _ in
                runtime.backgroundStatusService
                    .refreshPresentation()
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
        MemoMarkConfigurationCenterView(
            dependencies:
                MemoMarkConfigurationCenterDependencies(
                    runtime: runtime,
                    refreshExternalIntake: {
                        Task {
                            await runtime
                                .refreshExternalIntakeState()
                        }
                    },
                    notificationDeepLink:
                        pendingNotificationDeepLink,
                    onNotificationDeepLinkHandled: {
                        pendingNotificationDeepLink = nil
                    }
                )
        )
        .preferredColorScheme(preferredColorScheme)
        #else
        ConfigurationCenterView()
        #endif
    }
}
