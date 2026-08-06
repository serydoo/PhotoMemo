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
                            .padding(.top, 0)
                            .padding(.bottom, 28)
                            .v1AdaptiveScrollContent(
                                horizontalPadding:
                                    ConfigurationUI.contentColumnPadding
                            )
                    }
                    .safeAreaInset(edge: .top, spacing: 0) {
                        V1ConfigurationSheetSubtitle(
                            "探索不同组合，也欢迎告诉我们你的自定义想法。"
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
                    .navigationTitle("卡片内容")
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
                .presentationDetents([
                    .fraction(ConfigurationUI.contentSheetFraction),
                    .large
                ])
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(
                    .enabled(
                        upThrough: .fraction(
                            ConfigurationUI.contentSheetFraction
                        )
                    )
                )
            }
    }
}
#endif
