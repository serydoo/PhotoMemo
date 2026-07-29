#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct V1SubjectPresentationModifier: ViewModifier {
    @ObservedObject var session: ConfigurationSession
    @Binding var flowState: V1EntryFlowState
    @Binding var switchPresentation:
        V1ConfigurationSwitchPresentationState

    let birthdayDate: Date
    let shouldSaveSubjectLibrary: Bool
    let configurationCoordinator: ConfigurationCoordinator?
    let onRequestSubjectSelection: (MemorySubject.ID) -> Void
    let onApplySubjectFlowPatch: (V1SubjectFlowPatch) -> Void
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

private extension V1SubjectPresentationModifier {

    var subjectOverview: some View {
        V1IOSSubjectOverviewSheet(
            subjects: session.state.subjects,
            subject: session.state.selectedSubject,
            session: session,
            selectedSubjectID: session.state.selectedSubjectID,
            onSelectSubject: onRequestSubjectSelection,
            onAddSubject: addDefaultSubject,
            onEditSubject: makeConfigurationFlowState,
            onDeleteCurrentSubject: deleteCurrentSubject,
            onPersistSubjectChanges: onPersistSubjectChanges
        )
    }

    func subjectConfiguration(
        flowState: V1IOSSubjectConfigurationFlowState
    ) -> some View {
        V1IOSSubjectConfigurationFlow(
            flowState: flowState,
            onDeleteSubject: {
                deleteCurrentSubject()
                var nextState = V1EntryFlowCoordinator
                    .closeSubjectConfiguration(from: self.flowState)
                nextState.showsSubjectOverview = false
                self.flowState = nextState
            },
            onCancel: reopenSubjectOverview,
            onSave: reopenSubjectOverview
        )
    }

    func addDefaultSubject() {
        let patch = V1SubjectOverviewActionCoordinator
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
    -> V1IOSSubjectConfigurationFlowState? {
        V1SubjectOverviewActionCoordinator
            .makeConfigurationFlowState(
                from: session,
                shouldSaveSubjectLibrary: shouldSaveSubjectLibrary,
                configurationCoordinator: configurationCoordinator,
                savedStatus: .subjectSynced,
                onPersistedSubject: onApplySubjectFlowPatch
            )
    }

    func deleteCurrentSubject() {
        guard let patch = V1SubjectOverviewActionCoordinator
            .deleteCurrentSubject(
                from: session,
                shouldSaveSubjectLibrary: shouldSaveSubjectLibrary,
                configurationCoordinator: configurationCoordinator
            ) else { return }
        onApplySubjectFlowPatch(patch)
    }

    func reopenSubjectOverview() {
        var nextState = V1EntryFlowCoordinator
            .closeSubjectConfiguration(from: flowState)
        nextState.showsSubjectOverview = true
        flowState = nextState
    }

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
