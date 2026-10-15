#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI
import PhotosUI

extension MemoMarkConfigurationCenterView {
    @ViewBuilder
    var rootNavigation: some View {
        GeometryReader { viewport in
            let wideArrangement = WideOverviewLayoutPolicy.arrangement(
                viewport: adaptiveWindowViewport ?? viewport.size,
                hasRegularHorizontalSizeClass: horizontalSizeClass == .regular,
                hasRegularVerticalSizeClass: verticalSizeClass == .regular,
                usesAccessibilityText: adaptiveDynamicTypeSize.isAccessibilitySize,
                minimumRegionWidth: minimumWideOverviewRegionWidth
            )
            let nativeWide = SystemPresentationRegions.supportsNativeWidePresentation(in: viewport,
                windowViewport: adaptiveWindowViewport)
            let nativeArrangement = SystemPresentationRegions.allocation(in: viewport)
            let nativeCompactRail = NativeCompactNavigationPolicy.usesFixedRail(
                hasVerticalToolbar: nativeVerticalToolbarAvailable || NativeCompactRailValidation.isEnabled,
                isPhone: UIDevice.current.userInterfaceIdiom == .phone,
                viewport: adaptiveWindowViewport ?? viewport.size,
                usesWidePresentation: nativeWide || wideArrangement != nil)
            EntryNavigationSurface(
                navigationStyle: nativeCompactRail ? .floatingRail
                    : (wideArrangement == nil && !nativeWide ? entryNavigationStyle : .wideTaskSpaces),
                selection: entryBinding(\.selectedTab),
                usesNativeRegionNavigation: nativeWide,
                usesNativeCompactRail: nativeCompactRail,
                reservesCompactTopBar: UIDevice.current.userInterfaceIdiom == .pad
                    && wideArrangement == nil && !nativeWide,
                onOpenSettingsFromRail: {
                    entryNavigationState.openSettings(presentation: entryPresentation)
                },
                overviewArrangement: nativeWide
                    ? ((nativeArrangement?.arrangement ?? WideConfigurationLayoutPolicy.arrangement(
                        viewport: adaptiveWindowViewport ?? viewport.size)) == .stacked ? .vertical : .horizontal)
                    : wideArrangement,
                overviewFooter: HomePhotoPickerFooter(
                    isConfigurationReady: hasSavedConfigurationForSelectedSubject,
                    onOpenPhotoPicker: beginPhotoProcessingFlow
                ),
                previewControl: entryFlowState.selectedTab == .editor
                    ? ConfigurationPreviewRailControl(
                        isVisible: rootPresentationState.previewVisibility.isVisible(
                            isEditingCardContent: rootPresentationState.isCardContentInspectorPresented,
                            allowsCollapseDuringEditing: verticalSizeClass == .compact
                        ),
                        toggle: {
                            dismissKeyboard()
                            rootPresentationState.previewVisibility.isCollapsed.toggle()
                        }
                    )
                    : nil,
                configurationActions: entryFlowState.selectedTab == .editor
                    && !rootPresentationState.isCardContentInspectorPresented
                    ? ConfigurationActionFooter(
                        configurationStatus: activeConfigurationStatus,
                        isSavingConfiguration: isSavingConfiguration,
                        isSelectedProcessingDefault: session.selectedMemoryPresetIsProcessingDefault,
                        onSaveCurrentConfiguration: { performConfigurationLibraryAction(.saveCurrent) },
                        onSetAsProcessingDefault: { performConfigurationLibraryAction(.setAsProcessingDefault) },
                        onCreateConfiguration: { performConfigurationLibraryAction(.create) },
                        onResetConfiguration: { performConfigurationLibraryAction(.reset) },
                        onDeleteConfiguration: deleteCurrentConfiguration,
                        isRail: true,
                        exposesCreatePresetInRail: nativeCompactRail
                    )
                    : nil
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
            .environment(\.configurationWindowViewport, adaptiveWindowViewport)
            #if DEBUG
            .onAppear {
                NativeRegionValidationProbe.record(NativeRegionValidationProbe.snapshot(viewport, window: adaptiveWindowViewport,
                    verticalToolbar: nativeVerticalToolbarAvailable))
            }
            .onChange(of: NativeRegionValidationProbe.snapshot(viewport, window: adaptiveWindowViewport,
                    verticalToolbar: nativeVerticalToolbarAvailable)) { _, value in
                NativeRegionValidationProbe.record(value)
            }
            #endif
        }
        .background {
            if #available(iOS 27.1, *) {
                NativeVerticalToolbarCapabilityReader { available in
                    if nativeVerticalToolbarAvailable != available {
                        nativeVerticalToolbarAvailable = available
                    }
                }
            }
        }
        .background(AdaptiveWindowViewportReader { size in
            if adaptiveWindowViewport != size { adaptiveWindowViewport = size }
        })
    }

    var settingsPage: some View {
        SettingsPageSurface(
            showsWorkflowGuide:
                $rootPresentationState.showsSettingsWorkflowGuide,
            commerceSnapshot: commerceStore.snapshot,
            onOpenMemoMarkPlus: {
                rootPresentationState.showsMemoMarkPlus = true
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
        case .floatingRail, .regularSidebar, .wideTaskSpaces:
            return .regular
        }
    }

    var entryNavigationStyle:
        EntryNavigationStyle {
        NavigationPresentationPolicy.style(for: AdaptivePresentationCapabilities(
            horizontalSizeClass: horizontalSizeClass,
            verticalSizeClass: verticalSizeClass
        ))
    }

    var homePage: some View {
        HomePageSurface(
            subjectSummary: homeSubjectSummaryProjection,
            subject: session.state.selectedSubject,
            activitySnapshot:
                backgroundStatusService.currentSnapshot,
            pendingShareItemCount:
                externalIntakeCenter.pendingShareItemCount,
            pendingShareSessionIDs:
                externalIntakeCenter.pendingShareSessionIDs,
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
            onResumePendingShare: {
                sessionIDs in
                resumeExternalShareSessions(sessionIDs)
                entryFlowState = EntryFlowCoordinator.openTasksTab(from: entryFlowState)
            },
            onDeleteProcessingRecord: {
                guard let sessionID = backgroundStatusService.currentExecutionSession?.id else { return }
                Task { @MainActor in
                    await backgroundStatusService.deleteExecutionSessionHistory(sessionID)
                }
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
            isEditingCardContent:
                rootPresentationState.isCardContentInspectorPresented,
            isPreviewVisible: rootPresentationState.previewVisibility.isVisible(
                isEditingCardContent: rootPresentationState.isCardContentInspectorPresented,
                allowsCollapseDuringEditing: verticalSizeClass == .compact
            ),
            onTogglePreview: {
                dismissKeyboard()
                rootPresentationState.previewVisibility.isCollapsed.toggle()
            },
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
            if rootPresentationState.isCardContentInspectorPresented {
                cardContentInspector
            } else {
                configurationOptionList
            }
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
            isPreviewVisible: !rootPresentationState.previewVisibility.isCollapsed,
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
                if presentationStyle == .filmMark,
                   filmMarkContentDraft.items.isEmpty {
                    filmMarkContentDraft = defaultFilmMarkPrimaryOutputDraft()
                }
                resetCardEditorState()
                rootPresentationState.isCardContentInspectorPresented = true
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
            onClearHistory: {
                Task { @MainActor in
                    await backgroundStatusService.clearCompletedHistory()
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
