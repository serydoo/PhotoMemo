#if os(macOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI

struct ConfigurationCenterView: View {

    @ObservedObject
    private var runtime: MemoMarkAppRuntime

    @StateObject
    private var session =
        ConfigurationSession()

    @ObservedObject
    private var commerceStore:
        MemoMarkCommerceStore

    @ObservedObject
    private var backgroundStatusService:
        MemoMarkBackgroundStatusService

    init(
        runtime: MemoMarkAppRuntime
    ) {
        _runtime = ObservedObject(wrappedValue: runtime)
        _commerceStore = ObservedObject(
            wrappedValue: runtime.commerceStore
        )
        _backgroundStatusService = ObservedObject(
            wrappedValue: runtime.backgroundStatusService
        )
    }

    @AppStorage(
        MemoMarkLanguage.interfacePreferenceStorageKey,
        store: MemoMarkSharedContainer.sharedUserDefaults
    )
    private var interfaceLanguagePreferenceRawValue =
        MemoMarkInterfaceLanguagePreference.system.rawValue

    var body: some View {
        NavigationStack {
            MacConfigurationCenterPage(
                session: session,
                commerceStore: commerceStore,
                backgroundStatusService: backgroundStatusService,
                loadConfigurationBootstrap:
                    runtime.environment.transactions
                    .loadConfigurationBootstrap,
                loadPhotoLibraryAlbums:
                    runtime.environment.transactions
                    .loadPhotoLibraryAlbums,
                saveConfiguration:
                    runtime.environment.transactions
                    .saveConfiguration,
                configurationCoordinator:
                    runtime.environment.coordinators.configuration
            )
        }
        .background(ConfigurationUI.appBackground)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Picker(
                    "应用界面语言",
                    selection: interfaceLanguageBinding
                ) {
                    ForEach(
                        MemoMarkInterfaceLanguagePreference.allCases,
                        id: \.self
                    ) { preference in
                        Text(preference.displayTitle)
                            .tag(preference)
                    }
                }
                .frame(width: 210)
            }
        }
    }

    private var interfaceLanguageBinding:
        Binding<MemoMarkInterfaceLanguagePreference> {
        Binding(
            get: {
                MemoMarkInterfaceLanguagePreference(
                    rawValue: interfaceLanguagePreferenceRawValue
                ) ?? .system
            },
            set: { preference in
                interfaceLanguagePreferenceRawValue = preference.rawValue
            }
        )
    }

}

#Preview {
    ConfigurationCenterView(runtime: MemoMarkAppRuntime())
        .frame(width: 1180, height: 760)
}
#endif
