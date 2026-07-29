#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct V1WelcomeAndSettingsPresentationModifier<SettingsContent: View>:
    ViewModifier {
    @Binding var flowState: V1EntryFlowState
    @Binding var showsConfigurationRequiredAlert: Bool

    let hasSeenWelcome: Bool
    let settingsContent: SettingsContent
    let initializeFirstConfiguration: (String, Date) async -> Bool
    let completeWelcomeFlow: () -> Void

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: binding(\.showsWelcomePage)) {
                V1FirstRunConfigurationSheet(
                    onSave: initializeFirstConfiguration,
                    onDefer: completeWelcomeFlow
                )
                .interactiveDismissDisabled(!hasSeenWelcome)
            }
            .sheet(isPresented: binding(\.showsWorkflowGuide)) {
                V1WorkflowGuideSurface(
                    steps: V1WelcomePresentation.workflowSteps(
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
                                Button("完成") {
                                    flowState = V1EntryFlowCoordinator
                                        .closeSettingsPage(from: flowState)
                                }
                                .font(.caption.weight(.semibold))
                            }
                        }
                }
            }
            .alert(
                "请先完成配置",
                isPresented: $showsConfigurationRequiredAlert
            ) {
                Button("去配置中心") {
                    flowState = V1EntryFlowCoordinator
                        .openEditorTab(from: flowState)
                }
                Button("稍后", role: .cancel) {}
            } message: {
                Text("首次处理前，请先在配置中心保存当前记忆对象的配置。输出部分默认会按系统推荐走；如果你改了输出设置，保存后也会一并写回当前配置。")
            }
    }
}

private extension V1WelcomeAndSettingsPresentationModifier {
    func binding<Value>(
        _ keyPath: WritableKeyPath<V1EntryFlowState, Value>
    ) -> Binding<Value> {
        Binding(
            get: { flowState[keyPath: keyPath] },
            set: { flowState[keyPath: keyPath] = $0 }
        )
    }
}
#endif
