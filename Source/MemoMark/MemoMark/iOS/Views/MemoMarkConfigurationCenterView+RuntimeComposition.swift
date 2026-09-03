#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import Foundation

extension MemoMarkConfigurationCenterView {

    // This extension assembles existing runtime coordinators from the root's
    // owned state and injected capabilities. It deliberately owns no state,
    // persistence, or product behavior.
    var diagnosticsRefreshCoordinator:
        DiagnosticsRefreshCoordinator {
        DiagnosticsRefreshCoordinator(
            refreshExternalIntake:
                refreshExternalIntake,
            diagnosticsRepository:
                diagnosticsRepository,
            backgroundStatusService:
                backgroundStatusService,
            queueCoordinator:
                queueCoordinator
        )
    }

    var modulePanelState:
        ModulePanelCoordinator.State {
        ModulePanelCoordinator.State(
            focusedRegion:
                editorInteractionState.focusedEditorRegion,
            activeRegion:
                editorInteractionState.activeModuleRegion,
            usageStorage:
                moduleUsageCountsStorage
        )
    }

    var logoAssetCoordinator:
        LogoAssetCoordinator {
        LogoAssetCoordinator()
    }

    var configurationLibraryActions:
        ConfigurationLibraryActions {
        ConfigurationLibraryActions()
    }

    var configurationDeletionRuntimeCoordinator:
        ConfigurationDeletionRuntimeCoordinator? {
        guard let configurationCoordinator else {
            return nil
        }
        return ConfigurationDeletionRuntimeCoordinator(
            actions: configurationLibraryActions,
            currentRequest: configurationDeletionRequest(for:),
            applyCurrentConfiguration: {
                await applyCurrentConfiguration()
                && activeConfigurationStatus == .saved
            },
            persistConfigurationLibrary: {
                try await configurationCoordinator
                    .saveConfigurationLibrary($0)
            },
            setPersistenceInProgress: { isPersisting in
                isSavingConfiguration = isPersisting
                if isPersisting {
                    activeConfigurationStatus = .saving
                }
            }
        )
    }

    var configurationSelectionPersistenceCoordinator:
        ConfigurationSelectionPersistenceCoordinator? {
        guard let configurationCoordinator else {
            return nil
        }
        return ConfigurationSelectionPersistenceCoordinator(
            saveConfigurationLibrary: {
                try await configurationCoordinator
                    .saveConfigurationLibrary($0)
            }
        )
    }

    private var configurationBackupRestoreCoordinator:
        ConfigurationBackupRestoreCoordinator {
        ConfigurationBackupRestoreCoordinator(
            localConfigurationLibraryCoordinator:
                localConfigurationLibraryCoordinator,
            configurationCoordinator:
                configurationCoordinator
        )
    }

    var localConfigurationLibraryRuntimeCoordinator:
        LocalConfigurationLibraryRuntimeCoordinator {
        LocalConfigurationLibraryRuntimeCoordinator(
            actions: configurationLibraryActions,
            backupRestoreCoordinator:
                configurationBackupRestoreCoordinator,
            snapshot: {
                LocalConfigurationLibraryRuntimeSnapshot(
                    aggregate: session.state.configurationLibrary,
                    selectedSubjectID:
                        session.state.selectedSubject?.id,
                    availablePresets: homeAvailablePresets,
                    selectedPresetID:
                        session.state.selectedMemoryPresetID,
                    isCurrentConfigurationDirty:
                        activeConfigurationStatus == .dirty,
                    isSavingConfiguration: isSavingConfiguration,
                    availableAlbumIdentifiers: Set(
                        outputDraftState.availableAlbums
                            .compactMap(\.localIdentifier)
                    ),
                    selectedCustomLogoPath: customLogoBadge?.imagePath
                )
            },
            presentation: {
                rootPresentationState.localLibraryPresentation
            },
            updatePresentation: {
                rootPresentationState.localLibraryPresentation = $0
            },
            applyCurrentConfiguration: {
                await applyCurrentConfiguration()
                && activeConfigurationStatus == .saved
            },
            restoreAggregate: {
                session.restoreConfigurationLibrary($0)
            },
            applyRestoredCurrentConfiguration:
                applyRestoredCurrentConfiguration,
            presentFeedback: {
                presentHomeConfigurationActionFeedback(
                    $0,
                    isBlocking: $1
                )
            }
        )
    }

    var configurationApplyRuntimeCoordinator:
        ConfigurationSaveRuntimeCoordinator {
        ConfigurationSaveRuntimeCoordinator(
            coordinator:
                saveConfiguration,
            reloadAlbums: {
                await loadAlbumOptions()
            },
            setOutputTarget: {
                outputDraftState.outputTarget = $0
            },
            setSelectedExistingAlbumIdentifier: {
                selectedExistingAlbumIdentifier in
                self.outputDraftState.selectedExistingAlbumIdentifier =
                    selectedExistingAlbumIdentifier
            },
            restoreSubject: { subject in
                session.restoreSelectedSubject(
                    subject
                )
            },
            saveCurrentMemoryPreset: {
                session.saveCurrentMemoryPreset(
                    logoMode: logoMode,
                    outputConfiguration:
                        currentSavedOutputConfiguration
                )
                SubjectLibraryResolver
                    .persist(
                        subjects:
                            session.state.subjects,
                        selectedSubjectID:
                            session.state.selectedSubjectID,
                        coordinator:
                            configurationCoordinator,
                        memoryPresets:
                            session.state.memoryPresets,
                        selectedMemoryPresetID:
                            session.state.selectedMemoryPresetID
                    )
            },
            reconcileCurrentMemoryPreset: { request in
                session.reconcilePersistenceSnapshot(
                    memoryPresets:
                        request.memoryPresets,
                    selectedMemoryPresetID:
                        request.selectedMemoryPresetID
                )
            },
            reconcileSavedConfiguration: {
                request,
                configurationID,
                configurationRevision in
                session.reconcilePersistenceSnapshot(
                    memoryPresets:
                        request.memoryPresets,
                    selectedMemoryPresetID:
                        request.selectedMemoryPresetID,
                    configurationID:
                        configurationID,
                    configurationRevision:
                        configurationRevision
                )
            },
            reconcileConfigurationLibrary: {
                candidate,
                receipt in
                session.reconcileConfigurationLibrarySave(
                    candidate: candidate,
                    receipt: receipt
                )
            },
            applySavedConfigurationProjection: {
                configuration in
                applyConfigurationDraftProjection(
                    ConfigurationDraftProjection(
                        configuration: configuration
                    )
                )
                refreshDynamicPreview()
            },
            applySelectedMemoryPreset: {
                session.applySelectedMemoryPreset()
            },
            updateStatus: { status in
                activeConfigurationStatus =
                    status.status
                isSavingConfiguration =
                    status.status.isSaving
            },
            recordDiagnostic: { event in
                await productionDiagnosticsRepository?
                    .record(event)
            }
        )
    }

    var previewSyncCoordinator:
        PreviewSyncCoordinator {
        PreviewSyncCoordinator(
            session: session,
            coordinator: previewCoordinator
        )
    }

    var draftRuntimeCoordinator:
        DraftRuntimeCoordinator {
        DraftRuntimeCoordinator(
            loadViewState: {
                draftOrchestrationState
            },
            updateViewState: {
                applyDraftOrchestrationState(
                    $0
                )
            },
            makeDefaultDraft:
                makeDefaultDraft(for:),
            previewSyncCoordinator:
                previewSyncCoordinator,
            renderModel:
                previewRenderModel(for:)
        )
    }
}
#endif
