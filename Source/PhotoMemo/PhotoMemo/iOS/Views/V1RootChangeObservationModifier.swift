#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import PhotosUI
import SwiftUI

struct V1RootChangeObservationModifier: ViewModifier {
    @ObservedObject var session: ConfigurationSession

    let scenePhase: ScenePhase
    let entryPresentation: V1EntryPresentation
    let isApplyingBootstrapState: Bool
    let isApplyingSavedOutputConfiguration: Bool

    @Binding var flowState: V1EntryFlowState
    @Binding var renamePresentation:
        V1ConfigurationRenamePresentationState
    var titleFieldFocus: FocusState<Bool>.Binding
    @Binding var birthdayDate: Date
    @Binding var birthdayDateChangeBehavior: V1BirthdayDateChangeBehavior
    @Binding var memorySourceDisclosureState:
        V1MemorySourceDisclosureState
    @Binding var mediaPickerPresentation: V1MediaPickerPresentationState
    @Binding var logoMode: V1LogoMode
    @Binding var outputTarget: V1IOSOutputTarget
    @Binding var mediaOutputMode: V1MediaOutputMode
    @Binding var selectedAlbumIdentifier: String
    @Binding var newAlbumName: String
    @Binding var configurationStatus: V1ConfigurationStatus

    let bootstrapIfNeeded: () -> Void
    let refreshProcessingState: () -> Void
    let loadAlbumOptions: () async -> Void
    let applyConfigurationDraftProjection:
        (V1ConfigurationDraftProjection) -> Void
    let applySavedOutputConfiguration: (MemoryPreset) -> Void
    let bootstrapDrafts: () -> Void
    let refreshDynamicPreview: () -> Void
    let optimizeSelectedLogo: (PhotosPickerItem) async -> Void
    let importPickedPhotos: ([PhotosPickerItem]) async -> Void
    let importPickerResults: ([PHPickerResult]) async -> Void

    func body(content: Content) -> some View {
        content
            .onAppear {
                bootstrapIfNeeded()
                refreshProcessingState()
            }
            .sheet(isPresented: binding(\.showsProcessingPhotoPicker)) {
                V1UIKitPhotoPicker(
                    selectionLimit: 24,
                    onCancel: {
                        flowState.showsProcessingPhotoPicker = false
                    },
                    onSelect: { results in
                        flowState.showsProcessingPhotoPicker = false
                        Task { await importPickerResults(results) }
                    }
                )
            }
            .onChange(of: scenePhase) { _, newPhase in
                guard newPhase == .active else { return }
                refreshProcessingState()
                Task { await loadAlbumOptions() }
            }
            .onChange(of: flowState.selectedTab) { _, newTab in
                guard newTab == .output else { return }
                Task { await loadAlbumOptions() }
            }
            .onChange(of: entryPresentation) { _, presentation in
                guard presentation == .compact else { return }
                flowState = V1EntryFlowCoordinator
                    .prepareForCompactPresentation(from: flowState)
            }
            .onChange(of: session.state.selectedMemoryPresetID) { _, _ in
                renamePresentation.isEditing = false
                titleFieldFocus.wrappedValue = false
                if let configuration = session.selectedMemoryConfiguration {
                    applyConfigurationDraftProjection(
                        V1ConfigurationDraftProjection(
                            configuration: configuration
                        )
                    )
                } else if let preset = session.state.selectedMemoryPreset {
                    logoMode = preset.logoMode
                    applySavedOutputConfiguration(preset)
                }
                bootstrapDrafts()
            }
            .onChange(of: birthdayDate) { _, _ in
                let effect = V1SubjectSelectionMutationCoordinator
                    .effect(for: birthdayDateChangeBehavior)
                birthdayDateChangeBehavior = .userInitiated
                if effect.shouldRefreshPreview {
                    refreshDynamicPreview()
                }
                if effect.shouldMarkDirty {
                    configurationStatus = .dirty
                }
            }
            .onChange(of: session.state.selectedSubject) { _, subject in
                synchronizeSelectedSubject(subject)
            }
            .onChange(of: mediaPickerPresentation.selectedLogoItem) {
                _, item in
                guard let item else { return }
                Task { await optimizeSelectedLogo(item) }
            }
            .onChange(of: logoMode) { _, newMode in
                guard session.state.selectedMemoryPreset?.logoMode
                        != newMode else { return }
                configurationStatus = .dirty
            }
            .onChange(of: outputTarget) { _, _ in
                guard shouldTrackOutputChanges else { return }
                configurationStatus = .dirty
                if outputTarget == .existingAlbum {
                    Task { await loadAlbumOptions() }
                }
            }
            .onChange(of: mediaOutputMode) { _, _ in
                markOutputDirtyIfNeeded()
            }
            .onChange(of: session.usesCustomMemoryWriteText) { _, _ in
                markOutputDirtyIfNeeded()
            }
            .onChange(of: session.customMemoryWriteText) { _, _ in
                markOutputDirtyIfNeeded()
            }
            .onChange(of: selectedAlbumIdentifier) { _, _ in
                markOutputDirtyIfNeeded()
            }
            .onChange(of: newAlbumName) { _, _ in
                markOutputDirtyIfNeeded()
            }
            .onChange(of: mediaPickerPresentation.selectedProcessingItems) {
                _, items in
                guard !items.isEmpty else { return }
                Task { await importPickedPhotos(items) }
            }
    }
}

private extension V1RootChangeObservationModifier {
    var shouldTrackOutputChanges: Bool {
        !isApplyingBootstrapState
        && !isApplyingSavedOutputConfiguration
    }

    func markOutputDirtyIfNeeded() {
        guard shouldTrackOutputChanges else { return }
        configurationStatus = .dirty
    }

    func synchronizeSelectedSubject(
        _ subject: MemorySubject?
    ) {
        memorySourceDisclosureState.synchronize(
            selectedSubjectID: subject?.id
        )
        let decision = V1SubjectSelectionMutationCoordinator.decision(
            subjectAnchorDate:
                subject?.primaryTimeAnchor?.date
                ?? subject?.timeAnchors.first?.date,
            currentBirthdayDate: birthdayDate,
            isApplyingBootstrapState: isApplyingBootstrapState
        )
        if let behavior = decision.nextBirthdayDateBehavior {
            birthdayDateChangeBehavior = behavior
        }
        if let date = decision.updatedBirthdayDate {
            birthdayDate = date
        }
        if decision.shouldRefreshPreview {
            refreshDynamicPreview()
        }
        if decision.shouldMarkDirty {
            configurationStatus = .dirty
        }
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
