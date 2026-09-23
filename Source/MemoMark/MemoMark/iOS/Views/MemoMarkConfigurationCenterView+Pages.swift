#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI
import PhotosUI

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
            showsWorkflowGuide:
                $rootPresentationState.showsSettingsWorkflowGuide,
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
            onOpenTimeExpression: {
                rootPresentationState.configurationDisclosureState.setExpanded(
                    true,
                    for: .memoryExpression
                )
                entryFlowState = EntryFlowCoordinator.openEditorTab(
                    from: EntryFlowCoordinator.closeSettingsPage(
                        from: entryFlowState
                    )
                )
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
                hasRegularHorizontalSizeClass:
                    horizontalSizeClass == .regular,
                hasCompactVerticalSizeClass:
                    verticalSizeClass == .compact
            )
    }

    var homePage: some View {
        HomePageSurface(
            subjectSummary: homeSubjectSummaryProjection,
            subject: session.state.selectedSubject,
            activitySnapshot:
                backgroundStatusService.currentSnapshot,
            completedPhotoCount:
                backgroundStatusService
                .taskOverview
                .completedPhotoCount,
            borderStyleNameForPreset: { preset in
                borderStyleName(for: preset)
            },
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
            onOpenSettingsWorkflowGuide: {
                entryNavigationState.openSettings(
                    presentation: entryPresentation
                )
                DispatchQueue.main.async {
                    rootPresentationState.showsSettingsWorkflowGuide = true
                }
            },
            onOpenPhotoPicker: beginPhotoProcessingFlow,
            onOpenSettings: {
                entryNavigationState.openSettings(
                    presentation: entryPresentation
                )
            },
            onOpenMemoMarkPlus: {
                rootPresentationState.showsHomeMemoMarkPlus = true
            },
            onOpenPresetManagement: {
                entryFlowState = EntryFlowCoordinator.openEditorTab(
                    from: entryFlowState
                )
            },
            onSelectMemoryPreset: activateHomePreset,
            onCreateMemoryPreset: {
                performConfigurationLibraryAction(.create)
            },
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
            isSelectedProcessingDefault:
                session.selectedMemoryPresetIsProcessingDefault,
            previewWidthPolicy:
                presentationStyle == .minimal
                ? .fullWidthInCompactLandscape
                : .readable,
            editorScrollRequest:
                rootPresentationState.filmMarkGeometryScrollRequest,
            onDismissKeyboard: dismissKeyboard,
            onSaveCurrentConfiguration: {
                performConfigurationLibraryAction(.saveCurrent)
            },
            onSetAsProcessingDefault: {
                performConfigurationLibraryAction(.setAsProcessingDefault)
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
        .onChange(of: rootPresentationState.isFilmMarkGeometryExpanded) {
            _, isExpanded in
            guard isExpanded, presentationStyle == .filmMark else { return }
            rootPresentationState.filmMarkGeometryScrollRequest =
                ConfigurationEditorScrollRequest(
                    targetID: ConfigurationEditorScrollTarget.filmMarkGeometry,
                    revision: UUID()
                )
        }
        .sheet(
            isPresented:
                $rootPresentationState
                .showsMemoMarkPlusForPendingExpression
        ) {
            MemoMarkPlusPurchaseView(
                store: commerceStore,
                onDismiss: {
                    rootPresentationState
                        .showsMemoMarkPlusForPendingExpression = false
                    if commerceStore.isPlus {
                        commitPendingExpressionStyleAfterCommerce()
                        startCurrentConfigurationSaveWithFeedback()
                    }
                }
            )
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
            disclosureState:
                $rootPresentationState.configurationDisclosureState,
            subjectAvatarLogoImagePath:
                resolvedSubjectAvatarLogoImagePath,
            presentationStyle:
                presentationStyleBinding,
            filmMarkConfiguration:
                filmMarkConfigurationBinding,
            filmMarkOutputText:
                filmMarkPreviewText,
            isFilmMarkGeometryExpanded:
                $rootPresentationState.isFilmMarkGeometryExpanded,
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
                pendingMemoryDisplayStyle
                    .map(\.displayTitle)
                    ?? ConfigurationCenterMemoryDisplaySupport
                    .summaryValue(
                        subject: session.state.selectedSubject,
                        language: .interfaceStored
                    ),
            memoryDisplayDetail:
                ConfigurationCenterMemoryDisplaySupport
                .summaryDetail(
                    subject: session.state.selectedSubject,
                    style: pendingMemoryDisplayStyle,
                    language: .interfaceStored
                ),
            availableMemoryDisplayStyles:
                ConfigurationCenterMemoryDisplaySupport
                .availableStyles(
                    subject: session.state.selectedSubject,
                    accessSource: commerceStore.snapshot.accessSource
                ),
            selectedMemoryDisplayStyle:
                selectedMemoryDisplayStyleBinding,
            pendingMemoryDisplayStyle:
                pendingMemoryDisplayStyleBinding,
            commerceStore: commerceStore,
            isMemoryDisplayStyleLocked: { style in
                !MemoMarkCommerceCapability
                    .allowsFirstPartyExpressionStyle(
                        style,
                        snapshot: commerceStore.snapshot
                    )
            },
            onRequestMemoryDisplayCommerce: { _ in },
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
                rootPresentationState.isEditingFilmMarkContent =
                    presentationStyle == .filmMark
                if rootPresentationState.isEditingFilmMarkContent,
                   filmMarkContentDraft.items.isEmpty {
                    filmMarkContentDraft = defaultFilmMarkPrimaryOutputDraft()
                }
                resetCardEditorState()
                rootPresentationState.showsRegionContentSheet = true
            },
            onOpenAdvancedModules: nil,
            onOpenFilmMarkDetails: nil
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
