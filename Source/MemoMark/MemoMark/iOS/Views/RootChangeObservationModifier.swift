#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import PhotosUI
import SwiftUI

struct RootChangeObservationModifier: ViewModifier {
    @ObservedObject var session: ConfigurationSession

    let scenePhase: ScenePhase
    let entryPresentation: EntryPresentation
    let isApplyingBootstrapState: Bool
    let isApplyingSavedOutputConfiguration: Bool

    @Binding var flowState: EntryFlowState
    @Binding var renamePresentation:
        ConfigurationRenamePresentationState
    var titleFieldFocus: FocusState<Bool>.Binding
    @Binding var birthdayDate: Date
    @Binding var birthdayDateChangeBehavior: BirthdayDateChangeBehavior
    @Binding var configurationDisclosureState:
        ConfigurationDisclosureState
    @Binding var mediaPickerPresentation: MediaPickerPresentationState
    @Binding var logoMode: ConfigurationLogoMode
    @Binding var presentationStyle: RecordCardPresentationStyle
    @Binding var customLogoBadge: Badge?
    @Binding var outputTarget: ConfigurationOutputTarget
    @Binding var mediaOutputMode: MediaOutputMode
    @Binding var selectedAlbumIdentifier: String
    @Binding var newAlbumName: String
    @Binding var configurationStatus: ConfigurationPersistenceStatus

    let bootstrapIfNeeded: () -> Void
    let refreshProcessingState: () -> Void
    let loadAlbumOptions: () async -> Void
    let applyConfigurationDraftProjection:
        (ConfigurationDraftProjection) -> Void
    let applySavedOutputConfiguration: (MemoryPreset) -> Void
    let bootstrapDrafts: () -> Void
    let refreshDynamicPreview: () -> Void
    let resetLogoSelectionPresentation: () -> Void
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
                UIKitPhotoPicker(
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
                guard newTab == .editor || newTab == .output else {
                    return
                }
                Task { await loadAlbumOptions() }
            }
            .onChange(of: entryPresentation) { _, presentation in
                guard presentation == .compact else { return }
                flowState = EntryFlowCoordinator
                    .prepareForCompactPresentation(from: flowState)
            }
            .onChange(of: session.state.selectedMemoryPresetID) { _, _ in
                resetLogoSelectionPresentation()
                renamePresentation.isEditing = false
                titleFieldFocus.wrappedValue = false
                if let configuration = session.selectedMemoryConfiguration {
                    applyConfigurationDraftProjection(
                        ConfigurationDraftProjection(
                            configuration: configuration
                        )
                    )
                } else if let preset = session.state.selectedMemoryPreset {
                    logoMode = preset.logoMode
                    presentationStyle = .classicWhite
                    customLogoBadge = nil
                    applySavedOutputConfiguration(preset)
                }
                bootstrapDrafts()
            }
            .onChange(of: birthdayDate) { _, _ in
                let effect = SubjectSelectionMutationCoordinator
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
                resetLogoSelectionPresentation()
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
            .onChange(of: presentationStyle) { _, _ in
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

private extension RootChangeObservationModifier {
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
        configurationDisclosureState.synchronizeSelectedSubject(
            selectedSubjectID: subject?.id
        )
        let decision = SubjectSelectionMutationCoordinator.decision(
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
        _ keyPath: WritableKeyPath<EntryFlowState, Value>
    ) -> Binding<Value> {
        Binding(
            get: { flowState[keyPath: keyPath] },
            set: { flowState[keyPath: keyPath] = $0 }
        )
    }
}
#endif
