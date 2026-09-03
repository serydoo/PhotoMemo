#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI

struct WelcomeAndSettingsPresentationModifier<SettingsContent: View>:
    ViewModifier {
    @Binding var flowState: EntryFlowState
    @Binding var showsConfigurationRequiredAlert: Bool

    let hasSeenWelcome: Bool
    let settingsContent: SettingsContent
    let initializeFirstConfiguration: (String, Date) async -> Bool
    let completeWelcomeFlow: () -> Void

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: binding(\.showsWelcomePage)) {
                FirstRunConfigurationSheet(
                    language: .interfaceStored,
                    onSave: initializeFirstConfiguration,
                    onDefer: completeWelcomeFlow
                )
                .interactiveDismissDisabled(!hasSeenWelcome)
            }
            .sheet(isPresented: binding(\.showsWorkflowGuide)) {
                WorkflowGuideSurface(
                    steps: WelcomePresentation.workflowSteps(
                        for: .interfaceStored
                    ),
                    language: .interfaceStored,
                    onClose: nil
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: binding(\.showsSettingsPage)) {
                NavigationStack {
                    settingsContent
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button(MemoMarkLanguage.interfaceStored.localized(
                                    key: "common.done",
                                    fallback: "完成"
                                )) {
                                    flowState = EntryFlowCoordinator
                                        .closeSettingsPage(from: flowState)
                                }
                                .font(.caption.weight(.semibold))
                            }
                        }
                }
            }
            .alert(
                MemoMarkLanguage.interfaceStored.localized(
                    key: "welcome.configuration_required.title",
                    fallback: "请先完成配置"
                ),
                isPresented: $showsConfigurationRequiredAlert
            ) {
                Button(MemoMarkLanguage.interfaceStored.localized(
                    key: "welcome.configuration_required.open",
                    fallback: "去配置中心"
                )) {
                    flowState = EntryFlowCoordinator
                        .openEditorTab(from: flowState)
                }
                Button(MemoMarkLanguage.interfaceStored.localized(
                    key: "welcome.configuration_required.later",
                    fallback: "稍后"
                ), role: .cancel) {}
            } message: {
                Text(MemoMarkLanguage.interfaceStored.localized(
                    key: "welcome.configuration_required.message",
                    fallback: "首次处理前，请先在配置中心保存当前记忆对象的配置。输出部分默认会按系统推荐走；如果你改了输出设置，保存后也会一并写回当前配置。"
                ))
            }
    }
}

private extension WelcomeAndSettingsPresentationModifier {
    func binding<Value>(
        _ keyPath: WritableKeyPath<EntryFlowState, Value>
    ) -> Binding<Value> {
        Binding(
            get: { flowState[keyPath: keyPath] },
            set: { flowState[keyPath: keyPath] = $0 }
        )
    }
}
#endif
