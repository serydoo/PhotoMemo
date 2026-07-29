#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct V1EditorPresentationModifier<EditorContent: View>: ViewModifier {
    @Binding var isModuleSheetPresented: Bool
    @Binding var showsRegionContentSheet: Bool

    let activeModuleRegion: CardRegion?
    let editorContent: EditorContent
    let modules: (CardRegion) -> [IOSInsertableModule]
    let categoryTitle: (IOSInsertableModule) -> String
    let valueText: (IOSInsertableModule) -> String
    let onSelectModule: (IOSInsertableModule, CardRegion) -> Void
    let onCloseModuleSheet: () -> Void
    let onDismissKeyboard: () -> Void

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isModuleSheetPresented) {
                if let region = activeModuleRegion {
                    V1ModuleLibrarySurface(
                        region: region,
                        modules: modules(region),
                        categoryTitle: categoryTitle,
                        valueText: valueText,
                        onSelectModule: {
                            onSelectModule($0, region)
                        },
                        onClose: onCloseModuleSheet
                    )
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                }
            }
            .sheet(isPresented: $showsRegionContentSheet) {
                NavigationStack {
                    ScrollView {
                        editorContent
                            .padding(.top, 16)
                            .padding(.bottom, 28)
                            .v1AdaptiveScrollContent(
                                horizontalPadding:
                                    ConfigurationUI.contentColumnPadding
                            )
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .simultaneousGesture(
                        TapGesture().onEnded { _ in
                            onDismissKeyboard()
                        }
                    )
                    .background(
                        ConfigurationUI.appBackground.ignoresSafeArea()
                    )
                    .navigationTitle("区域内容设置")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("完成") {
                                onDismissKeyboard()
                                showsRegionContentSheet = false
                            }
                        }
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button(action: onDismissKeyboard) {
                                Image(
                                    systemName:
                                        "keyboard.chevron.compact.down"
                                )
                            }
                            .accessibilityLabel("收起键盘")
                        }
                    }
                }
                .presentationDetents([.fraction(0.58), .large])
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(
                    .enabled(upThrough: .fraction(0.58))
                )
            }
    }
}
#endif
