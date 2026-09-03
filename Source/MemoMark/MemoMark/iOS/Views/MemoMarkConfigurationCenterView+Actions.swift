#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI
import PhotosUI
import UIKit

extension MemoMarkConfigurationCenterView {
    func beginEditingMemoryPresetTitle() {
        performConfigurationLibraryAction(
            .beginRename(title: session.currentMemoryPresetTitle)
        )

        DispatchQueue.main.async {
            memoryPresetTitleFieldFocused = true
        }
    }

    func commitMemoryPresetTitle() {
        performConfigurationLibraryAction(
            .commitRename(
                title: rootPresentationState.renamePresentation.titleDraft
            )
        )
    }

    func startCurrentConfigurationSaveWithFeedback() {
        Task { @MainActor in
            let didSave =
                await applyCurrentConfiguration()

            guard didSave,
                  activeConfigurationStatus == .saved else {
                return
            }

            UINotificationFeedbackGenerator()
                .notificationOccurred(.success)
        }
    }

    func activateHomePreset(
        _ preset: MemoryPreset
    ) {
        performConfigurationLibraryAction(
            .requestActivation(
                ConfigurationLibraryActivationRequest(
                    preset: preset,
                    selectedConfigurationID:
                        session.state.selectedMemoryPresetID,
                    isCurrentConfigurationDirty:
                        activeConfigurationStatus
                        .hasUncommittedChanges
                )
            )
        )
    }

    func saveCurrentConfigurationThenActivatePendingPreset() {
        guard let preset = rootPresentationState
            .switchPresentation
            .pendingMemoryPresetActivation else {
            return
        }

        Task { @MainActor in
            guard await applyCurrentConfiguration(),
                  activeConfigurationStatus == .saved else {
                rootPresentationState
                    .switchPresentation
                    .pendingMemoryPresetActivation = nil
                return
            }

            rootPresentationState
                .switchPresentation
                .pendingMemoryPresetActivation = nil
            performConfigurationLibraryAction(.activate(preset))
        }
    }

    func requestSubjectSelection(
        _ subjectID: MemorySubject.ID
    ) {
        if SubjectSelectionMutationCoordinator
            .requiresSavingCurrentConfiguration(
                destinationSubjectID: subjectID,
                currentSubjectID:
                    session.state.selectedSubjectID,
                isCurrentConfigurationDirty:
                    activeConfigurationStatus
                    .hasUncommittedChanges
            ) {
            rootPresentationState
                .switchPresentation
                .pendingSubjectSelectionID = subjectID
            rootPresentationState
                .switchPresentation
                .showsUnsavedSubjectSwitchAlert = true
            return
        }

        performSubjectSelection(subjectID)
    }

    func saveCurrentConfigurationThenSelectPendingSubject() {
        guard let subjectID = rootPresentationState
            .switchPresentation
            .pendingSubjectSelectionID else {
            return
        }

        Task { @MainActor in
            guard await applyCurrentConfiguration(),
                  activeConfigurationStatus == .saved else {
                rootPresentationState
                    .switchPresentation
                    .pendingSubjectSelectionID = nil
                return
            }

            rootPresentationState
                .switchPresentation
                .pendingSubjectSelectionID = nil
            performSubjectSelection(subjectID)
        }
    }

    func performSubjectSelection(
        _ subjectID: MemorySubject.ID
    ) {
        guard let patch =
            SubjectOverviewActionCoordinator
            .selectSubject(
                subjectID,
                in: session,
                shouldSaveSubjectLibrary:
                    shouldSaveSubjectLibrary,
                configurationCoordinator:
                    configurationCoordinator
            ) else {
            return
        }

        applySubjectFlowPatch(patch)
    }

    func deleteHomePreset(
        _ preset: MemoryPreset
    ) {
        Task {
            await deleteHomePresetNow(preset)
        }
    }

    @MainActor
    func deleteHomePresetNow(
        _ preset: MemoryPreset
    ) async {
        guard let configurationDeletionRuntimeCoordinator else {
            presentHomeConfigurationActionFeedback(
                MemoMarkLanguage.interfaceStored.localized(
                    key: "configuration.library.unavailable",
                    fallback: "当前配置库不可用，请稍后重试。"
                )
            )
            return
        }
        switch await configurationDeletionRuntimeCoordinator
            .delete(preset) {
        case .deleted(let durableResult):
            session.restoreConfigurationLibrary(
                durableResult.candidate
            )
            rootPresentationState.renamePresentation.titleDraft =
                session.currentMemoryPresetTitle
            bootstrapDrafts()
            activeConfigurationStatus = .saved
            presentHomeConfigurationActionFeedback(
                String(
                    format: MemoMarkLanguage.interfaceStored.localized(
                        key: "configuration.deleted_format",
                        fallback: "已删除“%@”。本地备份仍会保留。"
                    ),
                    locale: MemoMarkLanguage.interfaceStored.locale,
                    durableResult.deletedPreset.title
                ),
                isBlocking: false
            )
        case .rejected(let message):
            activeConfigurationStatus = .dirty
            presentHomeConfigurationActionFeedback(message)
        }
    }

    func configurationDeletionRequest(
        for preset: MemoryPreset
    ) -> ConfigurationLibraryDeletionRequest {
        ConfigurationLibraryDeletionRequest(
            preset: preset,
            aggregate: session.state.configurationLibrary,
            subjectID: session.state.selectedSubject?.id,
            selectedConfigurationID:
                session.state.selectedMemoryPresetID,
            isCurrentConfigurationDirty:
                activeConfigurationStatus == .dirty,
            visibleConfigurationIDs:
                homeAvailablePresets.map(\.id),
            isPersistenceAvailable:
                configurationCoordinator != nil,
            isSavingConfiguration:
                isSavingConfiguration
        )
    }

    func performConfigurationLibraryAction(
        _ intent: ConfigurationLibraryActionIntent
    ) {
        switch configurationLibraryActions.decide(intent) {
        case .create:
            session.createMemoryPresetFromCurrent(
                logoMode: logoMode,
                outputConfiguration:
                    currentSavedOutputConfiguration
            )
            rootPresentationState.renamePresentation.titleDraft =
                session.currentMemoryPresetTitle
            rootPresentationState.renamePresentation.isEditing = true
            activeConfigurationStatus = .dirty
        case .reset:
            session.resetSelectedMemoryPreset()
            bootstrapDrafts()
            activeConfigurationStatus = .dirty
        case .beginRename(let title):
            rootPresentationState.renamePresentation.titleDraft = title
            rootPresentationState.renamePresentation.isEditing = true
        case .commitRenameAndSave(let title):
            session.updateSelectedMemoryPresetTitle(title)
            activeConfigurationStatus = .dirty
            rootPresentationState.renamePresentation.isEditing = false
            memoryPresetTitleFieldFocused = false
            startCurrentConfigurationSaveWithFeedback()
        case .confirmSaveBeforeActivation(let preset):
            rootPresentationState
                .switchPresentation
                .pendingMemoryPresetActivation = preset
            rootPresentationState
                .switchPresentation
                .showsUnsavedPresetSwitchAlert = true
        case .activate(let preset):
            session.selectMemoryPreset(preset)
            synchronizeSelectedSubjectConfigurationProjection()
            bootstrapDrafts()
            activeConfigurationStatus = .saving
            Task {
                await applyCurrentConfiguration()
            }
        case .saveCurrent:
            startCurrentConfigurationSaveWithFeedback()
        case .applyCurrentThenDelete,
             .applyCurrentThenSave,
             .saveDurableConfiguration,
             .persistDeletion,
             .unavailable:
            return
        }
    }

    func openLocalConfigurationLibrary() {
        rootPresentationState.localLibraryPresentation.isPresented = true
        refreshLocalConfigurationLibrary()
    }

    func backupHomePreset(
        _ preset: MemoryPreset
    ) {
        Task {
            await localConfigurationLibraryRuntimeCoordinator.backup(
                configurationID: preset.id
            )
        }
    }

    func presentHomeConfigurationActionFeedback(
        _ message: String,
        isBlocking: Bool = true
    ) {
        rootPresentationState.localLibraryPresentation.statusMessage = message
        if isBlocking {
            rootPresentationState.localLibraryPresentation.homeActionFeedback = nil
            rootPresentationState
                .localLibraryPresentation
                .showsHomeActionFailureAlert = true
            return
        }

        rootPresentationState.localLibraryPresentation.homeActionFeedback = message
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            if rootPresentationState.localLibraryPresentation.homeActionFeedback == message {
                rootPresentationState.localLibraryPresentation.homeActionFeedback = nil
            }
        }
    }

    @ViewBuilder
    var homeConfigurationStatusBanner: some View {
        if let homeConfigurationActionFeedback =
            rootPresentationState.localLibraryPresentation.homeActionFeedback {
            Label(
                homeConfigurationActionFeedback,
                systemImage: "checkmark.circle.fill"
            )
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.primary)
            .multilineTextAlignment(.leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: 420, alignment: .leading)
            .background {
                RoundedRectangle(
                    cornerRadius: 16,
                    style: .continuous
                )
                .fill(
                    reduceTransparency
                    ? ConfigurationUI.panelBackground
                    : Color.clear
                )
                .background {
                    if !reduceTransparency {
                        RoundedRectangle(
                            cornerRadius: 16,
                            style: .continuous
                        )
                        .fill(.regularMaterial)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 88)
            .accessibilityElement(children: .combine)
        }
    }

    func refreshLocalConfigurationLibrary() {
        Task {
            await localConfigurationLibraryRuntimeCoordinator.listBackups()
        }
    }

    func restoreLocalConfigurationBackup(
        _ backup: LocalConfigurationBackupRecord,
        makeCurrent: Bool
    ) {
        importConfigurationBackup(
            at: backup.fileURL,
            assetRootURL:
                backup.fileURL
                .deletingLastPathComponent()
                .deletingLastPathComponent(),
            makeCurrent: makeCurrent
        )
    }

    func importConfigurationBackup(
        at url: URL,
        assetRootURL: URL,
        makeCurrent: Bool
    ) {
        Task {
            await localConfigurationLibraryRuntimeCoordinator.restore(
                fileURL: url,
                assetRootURL: assetRootURL,
                makeCurrent: makeCurrent
            )
        }
    }

    func applyRestoredCurrentConfiguration() {
        guard let configuration = session.selectedMemoryConfiguration else {
            return
        }
        applyConfigurationDraftProjection(
            ConfigurationDraftProjection(
                configuration: configuration
            )
        )
        rootPresentationState.renamePresentation.titleDraft = configuration.title
        bootstrapDrafts()
        refreshDynamicPreview()
        activeConfigurationStatus = .saved
    }

    func deleteLocalConfigurationBackup(
        _ backup: LocalConfigurationBackupRecord
    ) {
        Task {
            await localConfigurationLibraryRuntimeCoordinator.delete(backup)
        }
    }

    func applySubjectFlowPatch(
        _ patch: SubjectFlowPatch
    ) {
        if let birthdayDate = patch.birthdayDate {
            self.birthdayDate = birthdayDate
        }

        // Subject selection changes the active configuration context as one
        // transaction. Refresh every root-owned projection here instead of
        // relying on independent onChange callbacks to arrive in a stable
        // order. This keeps Home, Output, logo, and the editor drafts bound
        // to the same selected subject/configuration.
        synchronizeSelectedSubjectConfigurationProjection()

        if patch.events.contains(.rebootstrapPreviewDrafts) {
            bootstrapDrafts()
        } else if patch.shouldRefreshPreview {
            refreshDynamicPreview()
        }

        if patch.events.contains(
            .reopenSubjectLibraryPersistence
        ) {
            shouldSaveSubjectLibrary = true
        }

        if patch.events.contains(
            .persistActiveConfigurationSelection
        ) {
            persistActiveConfigurationSelection()
        }

        activeConfigurationStatus =
            patch.activeConfigurationStatus

        if patch.shouldCloseOverview {
            entryFlowState =
                EntryFlowCoordinator
                .closeSubjectOverview(
                    from:
                        entryFlowState
                )
        }

        if let flowState = patch.flowState {
            entryFlowState =
                EntryFlowCoordinator
                .openSubjectConfiguration(
                    flowState,
                    from:
                        entryFlowState
                )
        }
    }

    func synchronizeSelectedSubjectConfigurationProjection() {
        isApplyingSavedOutputConfiguration = true
        defer {
            isApplyingSavedOutputConfiguration = false
        }

        if let configuration = session.selectedMemoryConfiguration {
            applyConfigurationDraftProjection(
                ConfigurationDraftProjection(
                    configuration: configuration
                )
            )
            return
        }

        guard let preset = session.state.selectedMemoryPreset else {
            return
        }

        logoMode = preset.logoMode
        presentationStyle = .classicWhite
        customLogoBadge = nil
        applySavedOutputConfiguration(preset)
    }

    func persistActiveConfigurationSelection() {
        guard session.selectedMemoryPresetIsDurable,
              let candidate = session.state.configurationLibrary,
              let configurationSelectionPersistenceCoordinator else {
            return
        }

        Task { @MainActor in
            switch await configurationSelectionPersistenceCoordinator
                .persist(candidate) {
            case .saved(let patch):
                guard let current = patch.reconcile(
                    current: session.state.configurationLibrary
                ) else { return }
                session.updateConfigurationLibraryReference(current)
            case .failed(let message):
                activeConfigurationStatus = .failure(message: message)
            }
        }
    }

    @MainActor
    func persistCurrentSubjectChanges() {
        guard let subject = session.state.selectedSubject else { return }

        SubjectLibraryPersistenceCoordinator
            .persistSubjectLibrary(subjects: session.state.subjects,
                                  selectedSubjectID: session.state.selectedSubjectID,
                                  selectedSubject: subject,
                                  memoryPresets: session.state.memoryPresets,
                                  selectedMemoryPresetID: session.state.selectedMemoryPresetID,
                                  shouldSaveSubjectLibrary: shouldSaveSubjectLibrary,
                                  configurationCoordinator: configurationCoordinator)

        if let anchor = subject.primaryTimeAnchor {
            birthdayDate = anchor.date
        }
        refreshDynamicPreview()

        let candidate: ConfigurationLibraryRecord?
        let requiresWrite: Bool
        if let aggregate = session.state.configurationLibrary,
           configurationCoordinator != nil,
           let updatedAggregate =
                LocalConfigurationLibraryPresenter
                .updatingSubject(
                    subject: subject,
                    in: aggregate
                ) {
            candidate = updatedAggregate
            requiresWrite = updatedAggregate != aggregate
        } else {
            candidate = nil
            requiresWrite = false
        }

        subjectPersistenceRuntimeCoordinator.submit(
            candidate: candidate,
            requiresWrite: requiresWrite,
            update: applySubjectPersistenceRuntimeUpdate
        )
    }

    func applySubjectPersistenceRuntimeUpdate(
        _ update: SubjectPersistenceUpdate
    ) {
        switch update {
        case .queued:
            activeConfigurationStatus = .dirty

        case .saving:
            isPersistingSubjectChanges = true
            activeConfigurationStatus = .saving

        case .completed(let completion):
            isPersistingSubjectChanges = false
            if let durableCandidate = completion.durableCandidate {
                session.updateConfigurationLibraryReference(
                    durableCandidate
                )
                refreshDynamicPreview()
            }
            activeConfigurationStatus = completion.status
        }
    }

}
#endif
