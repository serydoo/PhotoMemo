#if !MEMOMARK_SHARE_EXTENSION
import SwiftUI

struct ConfigurationCenterView: View {

    @StateObject
    private var session =
        ConfigurationSession()

    @AppStorage(
        MemoMarkLanguage.interfacePreferenceStorageKey,
        store: MemoMarkSharedContainer.sharedUserDefaults
    )
    private var interfaceLanguagePreferenceRawValue =
        MemoMarkInterfaceLanguagePreference.system.rawValue

    var body: some View {
        NavigationSplitView {
            MemorySubjectListView(
                session: session
            )
            .navigationTitle("记忆对象")
            .navigationSplitViewColumnWidth(
                min: 240,
                ideal: 280
            )
        } content: {
            ZStack {
                ConfigurationUI.appBackground
                    .ignoresSafeArea()

                InteractiveMemoryCard(
                    session: session
                )
            }
            .navigationTitle("记忆卡片")
            .navigationSplitViewColumnWidth(
                min: 560,
                ideal: 640
            )
        } detail: {
            InspectorView(
                session: session
            )
            .navigationTitle("编辑")
            .navigationSplitViewColumnWidth(
                min: 300,
                ideal: 360
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
    ConfigurationCenterView()
        .frame(width: 1180, height: 760)
}
#endif
