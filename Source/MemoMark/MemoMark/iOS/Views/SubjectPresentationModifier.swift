#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI

struct SubjectPresentationModifier: ViewModifier {
    @ObservedObject var session: ConfigurationSession
    @Binding var flowState: EntryFlowState
    @Binding var switchPresentation:
        ConfigurationSwitchPresentationState

    let birthdayDate: Date
    let availableConfigurationCount: Int
    let completedPhotoCount: Int
    let shouldSaveSubjectLibrary: Bool
    let configurationCoordinator: ConfigurationCoordinator?
    let onRequestSubjectSelection: (MemorySubject.ID) -> Void
    let onApplySubjectFlowPatch: (SubjectFlowPatch) -> Void
    let onPersistSubjectChanges: () -> Void
    let onSaveThenSelectPendingSubject: () -> Void

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: binding(\.showsSubjectOverview)) {
                subjectOverview
                    .alert(
                        "有未保存的修改",
                        isPresented:
                            $switchPresentation
                            .showsUnsavedSubjectSwitchAlert
                    ) {
                        Button("保存并切换") {
                            onSaveThenSelectPendingSubject()
                        }
                        Button("取消", role: .cancel) {
                            switchPresentation
                                .pendingSubjectSelectionID = nil
                        }
                    } message: {
                        Text("请先保存当前配置，再切换记忆对象，避免丢失刚刚的修改。")
                    }
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(item: binding(\.subjectConfigurationFlowState)) {
                subjectConfiguration(flowState: $0)
            }
    }
}

private extension SubjectPresentationModifier {

    var subjectOverview: some View {
        SubjectOverviewSheet(
            availableConfigurationCount:
                availableConfigurationCount,
            completedPhotoCount:
                completedPhotoCount,
            session: session,
            onSelectSubject: onRequestSubjectSelection,
            onAddSubject: addDefaultSubject,
            onEditSubject: makeConfigurationFlowState,
            onDeleteCurrentSubject: deleteCurrentSubject,
            onPersistSubjectChanges: onPersistSubjectChanges
        )
    }

    func subjectConfiguration(
        flowState: SubjectConfigurationFlowState
    ) -> some View {
        SubjectConfigurationFlow(
            flowState: flowState,
            onDeleteSubject: {
                deleteCurrentSubject()
                var nextState = EntryFlowCoordinator
                    .closeSubjectConfiguration(from: self.flowState)
                nextState.showsSubjectOverview = false
                self.flowState = nextState
            },
            onCancel: reopenSubjectOverview,
            onSave: reopenSubjectOverview
        )
    }

    func addDefaultSubject() {
        let patch = SubjectOverviewActionCoordinator
            .addDefaultSubject(
                referenceDate: birthdayDate,
                to: session,
                shouldSaveSubjectLibrary: shouldSaveSubjectLibrary,
                configurationCoordinator: configurationCoordinator,
                onPersistedSubject: onApplySubjectFlowPatch
            )
        onApplySubjectFlowPatch(patch)
    }

    func makeConfigurationFlowState()
    -> SubjectConfigurationFlowState? {
        SubjectOverviewActionCoordinator
            .makeConfigurationFlowState(
                from: session,
                shouldSaveSubjectLibrary: shouldSaveSubjectLibrary,
                configurationCoordinator: configurationCoordinator,
                savedStatus: .subjectSynced,
                onPersistedSubject: onApplySubjectFlowPatch
            )
    }

    func deleteCurrentSubject() {
        guard let patch = SubjectOverviewActionCoordinator
            .deleteCurrentSubject(
                from: session,
                shouldSaveSubjectLibrary: shouldSaveSubjectLibrary,
                configurationCoordinator: configurationCoordinator
            ) else { return }
        onApplySubjectFlowPatch(patch)
    }

    func reopenSubjectOverview() {
        var nextState = EntryFlowCoordinator
            .closeSubjectConfiguration(from: flowState)
        nextState.showsSubjectOverview = true
        flowState = nextState
    }

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
