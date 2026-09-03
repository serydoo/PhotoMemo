#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI
import PhotosUI
import UIKit

extension MemoMarkConfigurationCenterView {
    @ViewBuilder
    var rootNavigation: some View {
        EntryNavigationSurface(
            navigationStyle: entryNavigationStyle,
            selection: entryBinding(\.selectedTab)
        ) {
            homePage
        } editorContent: {
            editorPage
        } outputContent: {
            outputPage
        } taskContent: {
            tasksPage
        } settingsContent: {
            settingsPage
        }
    }

    var settingsPage: some View {
        SettingsPageSurface(
            commerceSnapshot: commerceStore.snapshot,
            onOpenMemoMarkPlus: {
                rootPresentationState.showsMemoMarkPlus = true
            },
            onShowWelcome: {
                entryFlowState =
                    EntryFlowCoordinator
                    .closeSettingsPage(
                        from: entryFlowState
                    )
                Task { @MainActor in
                    await Task.yield()
                    rootPresentationState.showsWelcomeInformation = true
                }
            },
            onDismissKeyboard: dismissKeyboard,
            onExportDiagnostics: {
                guard let productionDiagnosticsRepository else {
                    throw MemoMarkError(
                        code: .configurationUnavailable,
                        message: "Diagnostics unavailable."
                    )
                }
                return try await productionDiagnosticsRepository
                    .makeExport()
            }
        )
        .sheet(
            isPresented: $rootPresentationState.showsMemoMarkPlus
        ) {
            MemoMarkPlusPurchaseView(
                store: commerceStore,
                onDismiss: {
                    rootPresentationState.showsMemoMarkPlus = false
                }
            )
        }
    }

    var entryPresentation:
        EntryPresentation {
        switch entryNavigationStyle {
        case .bottomTabBar:
            return .compact
        case .compactSidebar, .regularSidebar:
            return .regular
        }
    }

    var entryNavigationStyle:
        EntryNavigationStyle {
        AdaptivePageLayout
            .navigationStyle(
                isPad:
                    UIDevice.current
                    .userInterfaceIdiom == .pad,
                hasRegularHorizontalSizeClass:
                    horizontalSizeClass == .regular,
                hasCompactVerticalSizeClass:
                    verticalSizeClass == .compact
            )
    }

    var homePage: some View {
        HomePageSurface(
            runtimeEnvironment: runtimeEnvironment,
            subjectSummary: homeSubjectSummaryProjection,
            subject: session.state.selectedSubject,
            activitySnapshot:
                backgroundStatusService.currentSnapshot,
            completedPhotoCount:
                backgroundStatusService
                .taskOverview
                .completedPhotoCount,
            hasProcessingRecord:
                backgroundStatusService.hasProcessingRecord,
            borderStyleName: currentBorderStyleName,
            borderStyleDescription: currentBorderStyleDescription,
            memoryPresets: homeAvailablePresets,
            selectedMemoryPresetID:
                session.state.selectedMemoryPreset?.id,
            isEditingMemoryPresetTitle:
                rootPresentationState.renamePresentation.isEditing,
            memoryPresetTitleDraft:
                $rootPresentationState.renamePresentation.titleDraft,
            memoryPresetTitleFieldFocused: $memoryPresetTitleFieldFocused,
            isConfigurationReady:
                hasSavedConfigurationForSelectedSubject,
            isSavingConfiguration:
                isSavingConfiguration,
            showsMemoMarkPlusBadge:
                commerceStore.hasVerifiedPlusEntitlement,
            isFirstRecorder:
                commerceStore.hasFirstRecorderIdentity,
            onOpenSubject: {
                entryFlowState =
                    EntryFlowCoordinator
                    .openSubjectOverview(
                        from:
                            entryFlowState
                    )
            },
            onOpenProcessing: {
                entryFlowState =
                    EntryFlowCoordinator
                    .openTasksTab(
                        from:
                            entryFlowState
                    )
            },
            onCommitMemoryPresetTitle: commitMemoryPresetTitle,
            onOpenWorkflowGuide: {
                entryFlowState.showsWorkflowGuide = true
            },
            onOpenPhotoPicker:
                beginPhotoProcessingFlow,
            onOpenSettings: {
                entryNavigationState.openSettings(
                    presentation: entryPresentation
                )
            },
            onOpenMemoMarkPlus: {
                rootPresentationState.showsHomeMemoMarkPlus = true
            },
            onSelectMemoryPreset: activateHomePreset,
            onRenameMemoryPreset: beginEditingMemoryPresetTitle,
            onSaveMemoryPreset: backupHomePreset,
            onDeleteMemoryPreset: deleteHomePreset,
            onOpenLocalConfigurationLibrary:
                openLocalConfigurationLibrary,
            onDismissKeyboard: dismissKeyboard,
            profileTrackingBackground: offsetReader(for: .profile)
        )
        .sheet(
            isPresented: $rootPresentationState.showsHomeMemoMarkPlus
        ) {
            MemoMarkPlusPurchaseView(
                store: commerceStore,
                onDismiss: {
                    rootPresentationState.showsHomeMemoMarkPlus = false
                }
            )
        }
    }

    var editorPage: some View {
        ConfigurationPageSurface(
            previewPinProgress: previewPinProgress,
            editorRevealProgress: editorRevealProgress,
            configurationStatus: activeConfigurationStatus,
            isSavingConfiguration: isSavingConfiguration,
            onDismissKeyboard: dismissKeyboard,
            onSaveCurrentConfiguration: {
                performConfigurationLibraryAction(.saveCurrent)
            },
            onCreateConfiguration: {
                performConfigurationLibraryAction(.create)
            },
            onResetConfiguration: {
                performConfigurationLibraryAction(.reset)
            },
            onDeleteConfiguration: deleteCurrentConfiguration
        ) {
            previewSection
                .background(offsetReader(for: .preview))
        } editorContent: {
            configurationOptionList
        }
    }

    func deleteCurrentConfiguration() {
        guard let selectedPreset =
            session.state.selectedMemoryPreset else {
            return
        }
        deleteHomePreset(selectedPreset)
    }

    var configurationOptionList: some View {
        let locationPresentation =
            LocationDisplayInspectorPresenter.presentation

        return ConfigurationOptionList(
            subject:
                session.state.selectedSubject,
            disclosureState:
                $rootPresentationState.configurationDisclosureState,
            subjectAvatarPreviewImagePath:
                resolvedSubjectAvatarPreviewImagePath,
            presentationStyle:
                presentationStyleBinding,
            logoMode: logoModeSelectionBinding,
            selectedLogoItem:
                $rootPresentationState.mediaPickerPresentation.selectedLogoItem,
            isLogoPickerPresented:
                $rootPresentationState.mediaPickerPresentation
                    .isLogoPickerPresented,
            logoValue: logoMode.title,
            customLogoImagePath:
                customLogoBadge?.imagePath,
            isOptimizingLogo:
                rootPresentationState.mediaPickerPresentation.isOptimizingLogo,
            timeAnchorTitle:
                session.currentTimeAnchorTitle,
            timeAnchorCount:
                session.availableTimeAnchors.count,
            availableTimeAnchors:
                session.availableTimeAnchors,
            selectedTimeAnchorID:
                selectedTimeAnchorBinding,
            locationPresentation:
                locationPresentation,
            selectedLocationOptionID:
                locationDisplayOptionBinding,
            timePresentation:
                TimeDisplayInspectorPresenter.presentation,
            selectedTimeOptionID:
                timeDisplayOptionBinding,
            selectedTimeSupplement:
                timeDisplaySupplementBinding,
            memoryDisplayValue:
                ConfigurationCenterMemoryDisplaySupport
                .summaryValue(
                    subject: session.state.selectedSubject
                ),
            memoryDisplayDetail:
                ConfigurationCenterMemoryDisplaySupport
                .summaryDetail(
                    subject: session.state.selectedSubject
                ),
            availableMemoryDisplayStyles:
                ConfigurationCenterMemoryDisplaySupport
                .availableStyles(
                    subject: session.state.selectedSubject
                ),
            selectedMemoryDisplayStyle:
                selectedMemoryDisplayStyleBinding,
            output: ConfigurationOutputBindings(
                outputTarget:
                    $outputDraftState.outputTarget,
                availableAlbums:
                    outputDraftState.availableAlbums,
                selectedExistingAlbumIdentifier:
                    $outputDraftState.selectedExistingAlbumIdentifier,
                newAlbumName:
                    $outputDraftState.newAlbumName,
                isLoadingAlbums:
                    outputDraftState.isLoadingAlbums,
                albumStatusMessage:
                    outputDraftState.albumStatusMessage,
                onReloadAlbums: {
                    Task {
                        await loadAlbumOptions()
                    }
                },
                usesCustomMemoryWriteText:
                    $session.usesCustomMemoryWriteText,
                customMemoryWriteText:
                    $session.customMemoryWriteText,
                shouldWritePhotosDescription:
                    outputDraftState.shouldWritePhotosDescription,
                resolvedMemoryWriteText:
                    resolvedMemoryWriteText
            ),
            configurationStatus:
                activeConfigurationStatus,
            onOpenRegionContent: {
                resetCardEditorState()
                rootPresentationState.showsRegionContentSheet = true
            }
        )
    }

    var outputPage: some View {
        ConfigurationOutputPageSurface(
            outputTarget: $outputDraftState.outputTarget,
            availableAlbums: outputDraftState.availableAlbums,
            selectedExistingAlbumIdentifier:
                $outputDraftState.selectedExistingAlbumIdentifier,
            newAlbumName: $outputDraftState.newAlbumName,
            isLoadingAlbums: outputDraftState.isLoadingAlbums,
            albumStatusMessage: outputDraftState.albumStatusMessage,
            onReloadAlbums: {
                Task {
                    await loadAlbumOptions()
                }
            },
            isSavingConfiguration: isSavingConfiguration,
            configurationStatus: activeConfigurationStatus,
            onSaveConfiguration:
                {
                    performConfigurationLibraryAction(.saveCurrent)
                },
            usesCustomMemoryWriteText: $session.usesCustomMemoryWriteText,
            customMemoryWriteText: $session.customMemoryWriteText,
            resolvedMemoryWriteText: resolvedMemoryWriteText,
            onDismissKeyboard: dismissKeyboard
        )
    }

    var tasksPage: some View {
        TaskPageSurface(
            header: shareDiagnosticsHeaderProjection,
            snapshot: backgroundStatusService.currentSnapshot,
            taskOverview:
                backgroundStatusService
                .taskOverview,
            recentJobSummaries:
                backgroundStatusService
                .recentJobSummaries,
            recoveryMessage: processingDiagnosticsSnapshot.recoveryMessage,
            events: shareDiagnosticEvents,
            fallbackConfigurationName:
                session.currentMemoryPresetTitle,
            onOpenPhotoLibrary:
                openPhotoLibrary,
            onRetryFailedTasks: {
                guard let jobID =
                    backgroundStatusService
                    .currentSnapshot?.jobID else {
                    return
                }
                Task { @MainActor in
                    _ = await queueCoordinator?
                        .retryFailedTasks(
                            in: jobID
                        )
                }
            },
            onDismissKeyboard: dismissKeyboard
        )
    }

    var homeSubjectSummaryProjection:
        HomeSubjectSummaryProjection {

        HomeProjection
            .subjectSummary(
                subject:
                    session.state.selectedSubject,
                selectedAnchorTitle:
                    session.currentTimeAnchorTitle
            )
    }
}
#endif
