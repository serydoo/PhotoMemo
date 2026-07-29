#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI
import PhotosUI
import UIKit

struct PhotoMemoiOSV1View: View {
    @Environment(\.scenePhase)
    private var scenePhase

    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass

    @ObservedObject
    private var backgroundStatusService:
        PhotoMemoBackgroundStatusService

    private let refreshExternalIntake:
        () -> Void

    private let previewCoordinator:
        PreviewCoordinator?

    private let exportCoordinator:
        ExportCoordinator?

    private let queueCoordinator:
        QueueCoordinator?

    private let configurationCoordinator:
        ConfigurationCoordinator?

    private let diagnosticsRepository:
        DiagnosticsRepository?

    private let localConfigurationLibraryCoordinator:
        LocalConfigurationLibraryCoordinator

    private let externalIntakeCenter:
        ExternalPhotoIntakeCenter

    @StateObject
    private var session = ConfigurationSession()

    @State
    private var regionDrafts: [CardRegion: V1EditorDraft] = [:]

    @State
    private var activeModuleRegion: CardRegion?

    @State
    private var activeTextItemIDs: [CardRegion: UUID] = [:]

    @State
    private var entryNavigationState =
        EntryNavigationState()

    @State
    private var memorySourceDisclosureState =
        V1MemorySourceDisclosureState()

    @State
    private var mediaPickerPresentation =
        V1MediaPickerPresentationState()

    @State
    private var logoMode: V1LogoMode = .appleMini

    @State
    private var customLogoBadge: Badge?

    @State
    private var birthdayDate =
        Calendar.current.date(
            from: DateComponents(
                year: 2024,
                month: 1,
                day: 1
            )
        ) ?? Date()

    @State
    private var locationDisplayConfiguration:
        ExpressionModuleConfiguration? =
        LocationDisplayInspectorPresenter
        .configuration(
            for: "legacyDisplay"
        )

    @State
    private var timeDisplayConfiguration =
        TimeDisplayInspectorPresenter.configuration(
            baseStyle: .daily,
            supplement: .none
        )

    @State
    private var outputTarget: V1IOSOutputTarget = .automatic

    @State
    private var mediaOutputMode:
        V1MediaOutputMode = .originalFormat

    @State
    private var shouldWritePhotosDescription = true

    @State
    private var photosDescriptionOverride = ""

    @State
    private var configurationAlbumTitle = ""

    @State
    private var livePhotoPolicy:
        MemoryConfigurationRecord.Output.LivePhotoPolicy =
        .preserveMotion

    @State
    private var availableAlbums: [PhotoAlbumOption] = []

    @State
    private var selectedExistingAlbumIdentifier = ""

    @State
    private var newAlbumName =
        PhotoMemoAlbumSelection.defaultAlbumTitle

    @State
    private var isLoadingAlbums = false

    @State
    private var albumStatusMessage = ""

    @State
    private var isSavingConfiguration = false

    @State
    private var didBootstrap = false

    @State
    private var isApplyingBootstrapState = false

    @State
    private var isApplyingSavedOutputConfiguration = false

    @State
    private var birthdayDateChangeBehavior:
        V1BirthdayDateChangeBehavior = .userInitiated

    @State
    private var shouldSaveSubjectLibrary = true

    @State
    private var isPersistingSubjectChanges = false

    @State
    private var activeConfigurationStatus:
        V1ConfigurationStatus = .idle

    @State
    private var shareDiagnosticEvents:
        [PhotoMemoShareDiagnosticEvent] = []

    @State
    private var processingDiagnosticsSnapshot =
        PhotoMemoiOSProcessingDiagnosticsSnapshot()

    @State
    private var renamePresentation =
        V1ConfigurationRenamePresentationState()

    @State
    private var showsRegionContentSheet = false

    @State
    private var showsWelcomeInformation = false

    @State
    private var switchPresentation =
        V1ConfigurationSwitchPresentationState()

    @State
    private var localLibraryPresentation =
        V1LocalConfigurationLibraryPresentationState()

    @FocusState
    private var memoryPresetTitleFieldFocused: Bool

    @AppStorage("photomemo.v1.moduleUsageCounts")
    private var moduleUsageCountsStorage = "{}"

    @AppStorage("photomemo.v1.welcomeSeen")
    private var hasSeenWelcome = false

    private let currentBorderStyleName =
        "基础白"

    private let currentBorderStyleDescription =
        "Classic White 当前唯一公开边框，预览与生成保持同一套锁定规范。"

    private let previewCompositionEngine =
        V1PreviewCompositionEngine()

    private var diagnosticsRefreshCoordinator:
        V1DiagnosticsRefreshCoordinator {
        V1DiagnosticsRefreshCoordinator(
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

    private var modulePanelState:
        V1ModulePanelCoordinator.State {
        V1ModulePanelCoordinator.State(
            activeRegion:
                activeModuleRegion,
            usageStorage:
                moduleUsageCountsStorage
        )
    }

    private var logoAssetCoordinator:
        LogoAssetCoordinator {
        LogoAssetCoordinator()
    }

    private var configurationLibraryActions:
        ConfigurationLibraryActions {
        ConfigurationLibraryActions()
    }

    private var configurationDeletionRuntimeCoordinator:
        V1ConfigurationDeletionRuntimeCoordinator? {
        guard let configurationCoordinator else {
            return nil
        }
        return V1ConfigurationDeletionRuntimeCoordinator(
            actions: configurationLibraryActions,
            currentRequest: configurationDeletionRequest(for:),
            applyCurrentConfiguration: {
                await applyCurrentV1Configuration()
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

    private var configurationSelectionPersistenceCoordinator:
        V1ConfigurationSelectionPersistenceCoordinator? {
        guard let configurationCoordinator else {
            return nil
        }
        return V1ConfigurationSelectionPersistenceCoordinator(
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

    private var localConfigurationLibraryRuntimeCoordinator:
        V1LocalConfigurationLibraryRuntimeCoordinator {
        V1LocalConfigurationLibraryRuntimeCoordinator(
            actions: configurationLibraryActions,
            backupRestoreCoordinator:
                configurationBackupRestoreCoordinator,
            snapshot: {
                V1LocalConfigurationLibraryRuntimeSnapshot(
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
                        availableAlbums.compactMap(\.localIdentifier)
                    ),
                    selectedCustomLogoPath: customLogoBadge?.imagePath
                )
            },
            presentation: { localLibraryPresentation },
            updatePresentation: { localLibraryPresentation = $0 },
            applyCurrentConfiguration: {
                await applyCurrentV1Configuration()
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

    private var configurationApplyCoordinator:
        V1ConfigurationApplyCoordinator {
        V1ConfigurationApplyCoordinator(
            configurationCoordinator:
                configurationCoordinator,
            exportCoordinator:
                exportCoordinator
        )
    }

    private var configurationApplyRuntimeCoordinator:
        V1ConfigurationApplyRuntimeCoordinator {
        V1ConfigurationApplyRuntimeCoordinator(
            coordinator:
                configurationApplyCoordinator,
            reloadAlbums: {
                await loadAlbumOptions()
            },
            setOutputTarget: {
                outputTarget = $0
            },
            setSelectedExistingAlbumIdentifier: {
                selectedExistingAlbumIdentifier in
                self.selectedExistingAlbumIdentifier =
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
                V1SubjectLibraryResolver
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
                    V1ConfigurationDraftProjection(
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
            }
        )
    }

    private var previewSyncCoordinator:
        V1PreviewSyncCoordinator {
        V1PreviewSyncCoordinator(
            session: session,
            coordinator: previewCoordinator
        )
    }

    private var draftRuntimeCoordinator:
        V1DraftRuntimeCoordinator {
        V1DraftRuntimeCoordinator(
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

    private var bootstrapFlowCoordinator:
        V1BootstrapFlowCoordinator {
        V1BootstrapFlowCoordinator(
            configurationBootstrapCoordinator:
                V1ConfigurationBootstrapCoordinator(
                    configurationCoordinator:
                        configurationCoordinator
                ),
            session: session,
                engine: previewCompositionEngine
        )
    }

    private var bootstrapRuntimeCoordinator:
        V1BootstrapRuntimeCoordinator {
        V1BootstrapRuntimeCoordinator(
            setApplyingBootstrapState: {
                isApplyingBootstrapState = $0
            },
            updateProjection: { projection in
                shouldSaveSubjectLibrary =
                    projection.shouldSaveSubjectLibrary
                customLogoBadge =
                    projection.customLogoBadge
                logoMode = projection.logoMode

                outputTarget =
                    projection.outputTarget
                mediaOutputMode =
                    projection.mediaOutputMode
                selectedExistingAlbumIdentifier =
                    projection
                    .selectedExistingAlbumIdentifier

                if let suggestedNewAlbumName =
                    projection
                    .suggestedNewAlbumName {
                    newAlbumName =
                        suggestedNewAlbumName
                }

                if let locationDisplayConfiguration =
                    projection
                    .locationDisplayConfiguration {
                    self.locationDisplayConfiguration =
                        locationDisplayConfiguration
                }

                if let birthdayDate =
                    projection.birthdayDate {
                    self.birthdayDate =
                        birthdayDate
                }

                regionDrafts =
                    projection.regionDrafts
            },
            restoreSubjectLibrary: {
                subjects,
                selectedSubjectID,
                memoryPresets,
                selectedMemoryPresetID in
                session.restoreSubjectLibrary(
                    subjects,
                    selectedSubjectID:
                        selectedSubjectID,
                    memoryPresets:
                        memoryPresets,
                    selectedMemoryPresetID:
                        selectedMemoryPresetID
                )
            },
            restoreConfigurationLibrary: { aggregate in
                session.restoreConfigurationLibrary(
                    aggregate
                )
            },
            applyConfigurationDraftProjection: {
                projection in
                applyConfigurationDraftProjection(
                    projection
                )
            },
            restoreSelectedSubject: { subject in
                session.restoreSelectedSubject(
                    subject
                )
            },
            clearSession: {
                session.clearBootstrapContent()
            },
            applyWelcomeState: applyWelcomeFlowState,
            refreshDynamicPreview:
                refreshDynamicPreview
        )
    }

    init(
        backgroundStatusService:
            PhotoMemoBackgroundStatusService,
        refreshExternalIntake:
            @escaping () -> Void = {},
        previewCoordinator:
            PreviewCoordinator? = nil,
        exportCoordinator:
            ExportCoordinator? = nil,
        queueCoordinator:
            QueueCoordinator? = nil,
        configurationCoordinator:
            ConfigurationCoordinator? = nil,
        externalIntakeCenter:
            ExternalPhotoIntakeCenter? = nil,
        diagnosticsRepository:
            DiagnosticsRepository? = nil
    ) {
        self._backgroundStatusService =
            ObservedObject(
                wrappedValue:
                    backgroundStatusService
            )
        self.refreshExternalIntake =
            refreshExternalIntake
        self.previewCoordinator =
            previewCoordinator
        self.exportCoordinator =
            exportCoordinator
        self.queueCoordinator =
            queueCoordinator
        self.configurationCoordinator =
            configurationCoordinator
        self._timeDisplayConfiguration = State(
            initialValue:
                configurationCoordinator?
                .loadTimeDisplayConfiguration()
                ?? TimeDisplayInspectorPresenter.configuration(
                    baseStyle: .daily,
                    supplement: .none
                )
        )
        self.externalIntakeCenter =
            externalIntakeCenter
            ?? .shared
        self.diagnosticsRepository =
            diagnosticsRepository
        self.localConfigurationLibraryCoordinator =
            LocalConfigurationLibraryCoordinator(
                appVersion:
                    Bundle.main.object(
                        forInfoDictionaryKey:
                            "CFBundleShortVersionString"
                    ) as? String
                    ?? "1.0"
            )
    }

    private var entryFlowState: V1EntryFlowState {
        get { entryNavigationState.flowState }
        nonmutating set { entryNavigationState.flowState = newValue }
    }

    private func entryBinding<Value>(
        _ keyPath: WritableKeyPath<V1EntryFlowState, Value>
    ) -> Binding<Value> {
        Binding(
            get: { entryNavigationState.flowState[keyPath: keyPath] },
            set: {
                entryNavigationState.flowState[keyPath: keyPath] = $0
            }
        )
    }

    var body: some View {
        rootNavigation
        .overlay(alignment: .bottom) {
            homeConfigurationStatusBanner
        }
        .modifier(
            V1LocalConfigurationLibraryPresentationModifier(
                presentation: $localLibraryPresentation,
                subjectName:
                    session.state.selectedSubject?
                    .identity.displayName
                    ?? "全部记忆对象",
                onRefresh: refreshLocalConfigurationLibrary,
                onRestore: restoreLocalConfigurationBackup,
                onDelete: deleteLocalConfigurationBackup
            )
        )
        .alert(
            "有未保存的修改",
            isPresented: $switchPresentation.showsUnsavedPresetSwitchAlert
        ) {
            Button("保存并切换") {
                saveCurrentConfigurationThenActivatePendingPreset()
            }
            Button("取消", role: .cancel) {
                switchPresentation.pendingMemoryPresetActivation = nil
            }
        } message: {
            Text("请先保存当前配置，再切换到另一条配置，避免丢失刚刚的修改。")
        }
        .task {
            await loadAlbumOptions()
        }
        .modifier(
            V1WelcomeAndSettingsPresentationModifier(
                flowState: $entryNavigationState.flowState,
                showsConfigurationRequiredAlert:
                    $switchPresentation.showsConfigurationRequiredAlert,
                hasSeenWelcome: hasSeenWelcome,
                settingsContent: settingsPage,
                initializeFirstConfiguration:
                    initializeFirstConfiguration,
                completeWelcomeFlow: completeWelcomeFlow
            )
        )
        .sheet(isPresented: $showsWelcomeInformation) {
            V1WelcomePageSurface(
                presentation:
                    V1WelcomePresentation.localized(
                        for: .interfaceStored
                    ),
                language: .interfaceStored,
                onStart: {
                    showsWelcomeInformation = false
                },
                onShowWorkflow: {
                    showsWelcomeInformation = false
                    entryFlowState =
                        V1EntryFlowCoordinator
                        .showWorkflowFromWelcome(
                            from: entryFlowState,
                            hasSeenWelcome: hasSeenWelcome
                        )
                        .flowState
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .modifier(
            V1EditorPresentationModifier(
                isModuleSheetPresented: moduleSheetPresented,
                showsRegionContentSheet: $showsRegionContentSheet,
                activeModuleRegion: activeModuleRegion,
                editorContent: editorCluster,
                modules: modules(for:),
                categoryTitle: moduleCategoryTitle,
                valueText: moduleDisplayText,
                onSelectModule: { module, region in
                    applyModulePanelState(
                        V1ModulePanelCoordinator.selectModule(
                            module,
                            state: modulePanelState
                        )
                    )
                    insert(module, into: region)
                },
                onCloseModuleSheet: {
                    applyModulePanelState(
                        V1ModulePanelCoordinator.setSheetPresented(
                            false,
                            state: modulePanelState
                        )
                    )
                },
                onDismissKeyboard: dismissKeyboard
            )
        )
        .modifier(
            V1SubjectPresentationModifier(
                session: session,
                flowState: $entryNavigationState.flowState,
                switchPresentation: $switchPresentation,
                birthdayDate: birthdayDate,
                shouldSaveSubjectLibrary: shouldSaveSubjectLibrary,
                configurationCoordinator: configurationCoordinator,
                onRequestSubjectSelection: requestSubjectSelection,
                onApplySubjectFlowPatch: applySubjectFlowPatch,
                onPersistSubjectChanges: persistCurrentSubjectChanges,
                onSaveThenSelectPendingSubject:
                    saveCurrentConfigurationThenSelectPendingSubject
            )
        )
        .modifier(
            V1RootChangeObservationModifier(
                session: session,
                scenePhase: scenePhase,
                horizontalSizeClass: horizontalSizeClass,
                isApplyingBootstrapState: isApplyingBootstrapState,
                isApplyingSavedOutputConfiguration:
                    isApplyingSavedOutputConfiguration,
                flowState: $entryNavigationState.flowState,
                renamePresentation: $renamePresentation,
                titleFieldFocus: $memoryPresetTitleFieldFocused,
                birthdayDate: $birthdayDate,
                birthdayDateChangeBehavior: $birthdayDateChangeBehavior,
                memorySourceDisclosureState: $memorySourceDisclosureState,
                mediaPickerPresentation: $mediaPickerPresentation,
                logoMode: $logoMode,
                outputTarget: $outputTarget,
                mediaOutputMode: $mediaOutputMode,
                selectedAlbumIdentifier:
                    $selectedExistingAlbumIdentifier,
                newAlbumName: $newAlbumName,
                configurationStatus: $activeConfigurationStatus,
                bootstrapIfNeeded: bootstrapIfNeeded,
                refreshProcessingState: refreshProcessingState,
                loadAlbumOptions: loadAlbumOptions,
                applyConfigurationDraftProjection:
                    applyConfigurationDraftProjection,
                applySavedOutputConfiguration:
                    applySavedOutputConfiguration,
                bootstrapDrafts: bootstrapDrafts,
                refreshDynamicPreview: refreshDynamicPreview,
                optimizeSelectedLogo: optimizeSelectedLogo,
                importPickedPhotos: importPickedPhotos,
                importPickerResults: importPickedPHPickerResults
            )
        )
    }

    @ViewBuilder
    private var rootNavigation: some View {
        V1EntryNavigationSurface(
            usesSidebarNavigation: usesSidebarNavigation,
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

    private var settingsPage: some View {
        V1SettingsPageSurface(
            commerceSnapshot: .initial,
            onOpenMemoMarkPlus: {},
            onShowWelcome: {
                entryFlowState =
                    V1EntryFlowCoordinator
                    .closeSettingsPage(
                        from: entryFlowState
                    )
                Task { @MainActor in
                    await Task.yield()
                    showsWelcomeInformation = true
                }
            },
            onDismissKeyboard: dismissKeyboard
        )
    }

    private var entryPresentation:
        V1EntryPresentation {
        usesSidebarNavigation
        ? .regular
        : .compact
    }

    private var usesSidebarNavigation: Bool {
        V1AdaptivePageLayout
            .usesSidebarNavigation(
                isPad:
                    UIDevice.current
                    .userInterfaceIdiom == .pad,
                hasRegularHorizontalSizeClass:
                    horizontalSizeClass == .regular
            )
    }

    private var homePage: some View {
        V1HomePageSurface(
            subjectSummary: homeSubjectSummaryProjection,
            subject: session.state.selectedSubject,
            activitySnapshot:
                backgroundStatusService.currentSnapshot,
            completedPhotoCount:
                backgroundStatusService
                .taskOverview
                .completedPhotoCount,
            borderStyleName: currentBorderStyleName,
            borderStyleDescription: currentBorderStyleDescription,
            memoryPresets: homeAvailablePresets,
            selectedMemoryPresetID:
                session.state.selectedMemoryPreset?.id,
            isEditingMemoryPresetTitle: renamePresentation.isEditing,
            memoryPresetTitleDraft: $renamePresentation.titleDraft,
            memoryPresetTitleFieldFocused: $memoryPresetTitleFieldFocused,
            isConfigurationReady:
                hasSavedConfigurationForSelectedSubject,
            isSavingConfiguration:
                isSavingConfiguration,
            onOpenSubject: {
                entryFlowState =
                    V1EntryFlowCoordinator
                    .openSubjectOverview(
                        from:
                            entryFlowState
                    )
            },
            onOpenProcessing: {
                entryFlowState =
                    V1EntryFlowCoordinator
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
            onSelectMemoryPreset: activateHomePreset,
            onRenameMemoryPreset: beginEditingMemoryPresetTitle,
            onSaveMemoryPreset: backupHomePreset,
            onDeleteMemoryPreset: deleteHomePreset,
            onOpenLocalConfigurationLibrary:
                openLocalConfigurationLibrary,
            onDismissKeyboard: dismissKeyboard,
            profileTrackingBackground: offsetReader(for: .profile)
        )
    }

    private var editorPage: some View {
        V1ConfigurationPageSurface(
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

    private func deleteCurrentConfiguration() {
        guard let selectedPreset =
            session.state.selectedMemoryPreset else {
            return
        }
        deleteHomePreset(selectedPreset)
    }

    private var configurationOptionList: some View {
        let locationPresentation =
            LocationDisplayInspectorPresenter.presentation

        return V1ConfigurationOptionList(
            subject:
                session.state.selectedSubject,
            isMemorySourceExpanded:
                Binding(
                    get: {
                        memorySourceDisclosureState
                            .isExpanded
                    },
                    set: { isExpanded in
                        memorySourceDisclosureState
                            .setExpanded(isExpanded)
                    }
                ),
            subjectAvatarPreviewImagePath:
                resolvedSubjectAvatarPreviewImagePath,
            logoMode: $logoMode,
            selectedLogoItem: $mediaPickerPresentation.selectedLogoItem,
            logoValue: logoMode.title,
            logoDetail: logoRowDetail,
            customLogoImagePath:
                customLogoBadge?.imagePath,
            isOptimizingLogo: mediaPickerPresentation.isOptimizingLogo,
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
            borderStyleName:
                currentBorderStyleName,
            configurationStatus:
                activeConfigurationStatus,
            onOpenRegionContent: {
                showsRegionContentSheet = true
            }
        )
    }

    private var outputPage: some View {
        V1OutputPageSurface(
            outputTarget: $outputTarget,
            mediaOutputMode:
                $mediaOutputMode,
            availableAlbums: availableAlbums,
            selectedExistingAlbumIdentifier: $selectedExistingAlbumIdentifier,
            newAlbumName: $newAlbumName,
            isLoadingAlbums: isLoadingAlbums,
            albumStatusMessage: albumStatusMessage,
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

    private var tasksPage: some View {
        V1TaskPageSurface(
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
            onDismissKeyboard: dismissKeyboard
        )
    }

    private var homeSubjectSummaryProjection:
        V1IOSHomeSubjectSummaryProjection {

        V1IOSHomeProjection
            .subjectSummary(
                subject:
                    session.state.selectedSubject,
                selectedAnchorTitle:
                    session.currentTimeAnchorTitle
            )
    }

    private func beginEditingMemoryPresetTitle() {
        performConfigurationLibraryAction(
            .beginRename(title: session.currentMemoryPresetTitle)
        )

        DispatchQueue.main.async {
            memoryPresetTitleFieldFocused = true
        }
    }

    private func commitMemoryPresetTitle() {
        performConfigurationLibraryAction(
            .commitRename(title: renamePresentation.titleDraft)
        )
    }

    private func startCurrentConfigurationSaveWithFeedback() {
        Task { @MainActor in
            let didSave =
                await applyCurrentV1Configuration()

            guard didSave,
                  activeConfigurationStatus == .saved else {
                return
            }

            UINotificationFeedbackGenerator()
                .notificationOccurred(.success)
        }
    }

    private func activateHomePreset(
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

    private func saveCurrentConfigurationThenActivatePendingPreset() {
        guard let preset = switchPresentation.pendingMemoryPresetActivation else {
            return
        }

        Task { @MainActor in
            guard await applyCurrentV1Configuration(),
                  activeConfigurationStatus == .saved else {
                switchPresentation.pendingMemoryPresetActivation = nil
                return
            }

            switchPresentation.pendingMemoryPresetActivation = nil
            performConfigurationLibraryAction(.activate(preset))
        }
    }

    private func requestSubjectSelection(
        _ subjectID: MemorySubject.ID
    ) {
        if V1SubjectSelectionMutationCoordinator
            .requiresSavingCurrentConfiguration(
                destinationSubjectID: subjectID,
                currentSubjectID:
                    session.state.selectedSubjectID,
                isCurrentConfigurationDirty:
                    activeConfigurationStatus
                    .hasUncommittedChanges
            ) {
            switchPresentation.pendingSubjectSelectionID = subjectID
            switchPresentation.showsUnsavedSubjectSwitchAlert = true
            return
        }

        performSubjectSelection(subjectID)
    }

    private func saveCurrentConfigurationThenSelectPendingSubject() {
        guard let subjectID = switchPresentation.pendingSubjectSelectionID else {
            return
        }

        Task { @MainActor in
            guard await applyCurrentV1Configuration(),
                  activeConfigurationStatus == .saved else {
                switchPresentation.pendingSubjectSelectionID = nil
                return
            }

            switchPresentation.pendingSubjectSelectionID = nil
            performSubjectSelection(subjectID)
        }
    }

    private func performSubjectSelection(
        _ subjectID: MemorySubject.ID
    ) {
        guard let patch =
            V1SubjectOverviewActionCoordinator
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

    private func deleteHomePreset(
        _ preset: MemoryPreset
    ) {
        Task {
            await deleteHomePresetNow(preset)
        }
    }

    @MainActor
    private func deleteHomePresetNow(
        _ preset: MemoryPreset
    ) async {
        guard let configurationDeletionRuntimeCoordinator else {
            presentHomeConfigurationActionFeedback(
                "当前配置库不可用，请稍后重试。"
            )
            return
        }
        switch await configurationDeletionRuntimeCoordinator
            .delete(preset) {
        case .deleted(let durableResult):
            session.restoreConfigurationLibrary(
                durableResult.candidate
            )
            renamePresentation.titleDraft = session.currentMemoryPresetTitle
            bootstrapDrafts()
            activeConfigurationStatus = .saved
            presentHomeConfigurationActionFeedback(
                "已删除“\(durableResult.deletedPreset.title)”。本地备份仍会保留。",
                isBlocking: false
            )
        case .rejected(let message):
            activeConfigurationStatus = .dirty
            presentHomeConfigurationActionFeedback(message)
        }
    }

    private func configurationDeletionRequest(
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

    private func performConfigurationLibraryAction(
        _ intent: ConfigurationLibraryActionIntent
    ) {
        switch configurationLibraryActions.decide(intent) {
        case .create:
            session.createMemoryPresetFromCurrent(
                logoMode: logoMode,
                outputConfiguration:
                    currentSavedOutputConfiguration
            )
            renamePresentation.titleDraft = session.currentMemoryPresetTitle
            renamePresentation.isEditing = true
            activeConfigurationStatus = .dirty
        case .reset:
            session.resetSelectedMemoryPreset()
            bootstrapDrafts()
            activeConfigurationStatus = .dirty
        case .beginRename(let title):
            renamePresentation.titleDraft = title
            renamePresentation.isEditing = true
        case .commitRenameAndSave(let title):
            session.updateSelectedMemoryPresetTitle(title)
            activeConfigurationStatus = .dirty
            renamePresentation.isEditing = false
            memoryPresetTitleFieldFocused = false
            startCurrentConfigurationSaveWithFeedback()
        case .confirmSaveBeforeActivation(let preset):
            switchPresentation.pendingMemoryPresetActivation = preset
            switchPresentation.showsUnsavedPresetSwitchAlert = true
        case .activate(let preset):
            logoMode = preset.logoMode
            session.selectMemoryPreset(preset)
            bootstrapDrafts()
            activeConfigurationStatus = .saving
            Task {
                await applyCurrentV1Configuration()
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

    private func openLocalConfigurationLibrary() {
        localLibraryPresentation.isPresented = true
        refreshLocalConfigurationLibrary()
    }

    private func backupHomePreset(
        _ preset: MemoryPreset
    ) {
        Task {
            await localConfigurationLibraryRuntimeCoordinator.backup(
                configurationID: preset.id
            )
        }
    }

    private func presentHomeConfigurationActionFeedback(
        _ message: String,
        isBlocking: Bool = true
    ) {
        localLibraryPresentation.statusMessage = message
        if isBlocking {
            localLibraryPresentation.homeActionFeedback = nil
            localLibraryPresentation.showsHomeActionFailureAlert = true
            return
        }

        localLibraryPresentation.homeActionFeedback = message
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            if localLibraryPresentation.homeActionFeedback == message {
                localLibraryPresentation.homeActionFeedback = nil
            }
        }
    }

    @ViewBuilder
    private var homeConfigurationStatusBanner: some View {
        if let homeConfigurationActionFeedback =
            localLibraryPresentation.homeActionFeedback {
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
            .background(
                .regularMaterial,
                in: RoundedRectangle(
                    cornerRadius: 16,
                    style: .continuous
                )
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 88)
            .accessibilityElement(children: .combine)
        }
    }

    private func refreshLocalConfigurationLibrary() {
        Task {
            await localConfigurationLibraryRuntimeCoordinator.listBackups()
        }
    }

    private func restoreLocalConfigurationBackup(
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

    private func importConfigurationBackup(
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

    private func applyRestoredCurrentConfiguration() {
        guard let configuration = session.selectedMemoryConfiguration else {
            return
        }
        applyConfigurationDraftProjection(
            V1ConfigurationDraftProjection(
                configuration: configuration
            )
        )
        renamePresentation.titleDraft = configuration.title
        bootstrapDrafts()
        refreshDynamicPreview()
        activeConfigurationStatus = .saved
    }

    private func deleteLocalConfigurationBackup(
        _ backup: LocalConfigurationBackupRecord
    ) {
        Task {
            await localConfigurationLibraryRuntimeCoordinator.delete(backup)
        }
    }

    private func applySubjectFlowPatch(
        _ patch: V1SubjectFlowPatch
    ) {
        if let birthdayDate = patch.birthdayDate {
            self.birthdayDate = birthdayDate
        }

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
                V1EntryFlowCoordinator
                .closeSubjectOverview(
                    from:
                        entryFlowState
                )
        }

        if let flowState = patch.flowState {
            entryFlowState =
                V1EntryFlowCoordinator
                .openSubjectConfiguration(
                    flowState,
                    from:
                        entryFlowState
                )
        }
    }

    private func persistActiveConfigurationSelection() {
        guard let candidate = session.state.configurationLibrary,
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
    private func persistCurrentSubjectChanges() {
        guard !isPersistingSubjectChanges,
              let subject = session.state.selectedSubject else {
            return
        }

        V1SubjectLibraryPersistenceCoordinator
            .persistSubjectLibrary(
                subjects: session.state.subjects,
                selectedSubjectID: session.state.selectedSubjectID,
                selectedSubject: subject,
                memoryPresets: session.state.memoryPresets,
                selectedMemoryPresetID:
                    session.state.selectedMemoryPresetID,
                shouldSaveSubjectLibrary: shouldSaveSubjectLibrary,
                configurationCoordinator: configurationCoordinator
            )

        if let anchor = subject.primaryTimeAnchor {
            birthdayDate = anchor.date
        }
        activeConfigurationStatus = .subjectSynced
        refreshDynamicPreview()

        guard let aggregate = session.state.configurationLibrary,
              let configurationCoordinator,
              let candidate = V1LocalConfigurationLibraryPresenter
                .updatingSubject(
                    subject: subject,
                    in: aggregate
                ),
              candidate != aggregate else {
            return
        }

        isPersistingSubjectChanges = true
        activeConfigurationStatus = .saving
        Task { @MainActor in
            defer {
                isPersistingSubjectChanges = false
            }

            do {
                let receipt = try await configurationCoordinator
                    .saveConfigurationLibrary(candidate)
                var durableCandidate = candidate
                durableCandidate.revision = receipt.revision
                session.updateConfigurationLibraryReference(
                    durableCandidate
                )
                activeConfigurationStatus = .subjectSynced
                refreshDynamicPreview()
            } catch {
                activeConfigurationStatus = .failure(
                    message: "记忆对象保存失败，请重试。"
                )
            }
        }
    }

    private var previewSection: some View {
        V1PreviewSection(
            logoMode: logoMode,
            customLogoImagePath:
                customLogoBadge?.imagePath,
            subjectAvatarLogoImagePath:
                resolvedSubjectAvatarLogoImagePath,
            regionText:
                previewText(
                    for: CardRegion.region(for: .leftPrimary)
                ),
            timeText:
                previewText(
                    for: CardRegion.region(for: .leftSecondary)
                ),
            contextText:
                previewText(
                    for: CardRegion.region(for: .rightPrimary)
                ),
            memoryText:
                previewText(
                    for: CardRegion.region(for: .rightSecondary)
                ),
            onTap: dismissKeyboard
        )
    }

    private var editorCluster: some View {
        V1RegionEditorCluster(
            expansionBinding: { region in
                expansionBinding(for: .region(region))
            },
            draft: { region in
                draft(for: region)
            },
            resolvedText: { draft in
                composedText(for: draft)
            },
            onFocus: focusRegionEditor,
            onFocusTextItem: { region, item in
                setActiveTextItem(item.id, for: region)
                focusRegionEditor()
            },
            onUpdateTextItem: { region, item, text in
                updateTextItem(item.id, text: text, for: region)
            },
            onPrependText: { region, text in
                prependText(text, to: region)
            },
            onAppendText: { region, text in
                appendText(text, to: region)
            },
            onRemoveItem: { region, item in
                removeItem(item.id, from: region)
                refreshPreview(for: region)
            },
            onShowModules: { region in
                applyModulePanelState(
                    V1ModulePanelCoordinator.showModules(
                        for: region,
                        state: modulePanelState
                    )
                )
            }
        )
    }

    private func focusRegionEditor() {
        applyModulePanelState(
            V1ModulePanelCoordinator.focusEditor(
                state: modulePanelState
            )
        )
    }

    private var logoRowDetail: String {
        switch logoMode {
        case .appleMini:
            return "使用系统默认标识"
        case .customUpload:
            return customLogoBadge == nil
                ? "点击选择自选 Logo"
                : "已准备自选 Logo"
        case .subjectAvatar:
            return resolvedSubjectAvatarLogoImagePath == nil
                ? "当前记忆对象尚未选择头像"
                : "已使用对象头像"
        }
    }

    private var resolvedSubjectAvatarLogoImagePath: String? {
        session.state.selectedSubject?
            .identity.avatarBadgeImagePath
        ?? session.state.selectedSubject?
            .identity.avatarImagePath
    }

    private var resolvedSubjectAvatarPreviewImagePath: String? {
        session.state.selectedSubject?
            .identity.avatarPreviewImagePath
        ?? session.state.selectedSubject?
            .identity.avatarImagePath
    }

    private var subjectAvatarBadge: Badge {
        Badge(
            name: OptimizedSubjectAvatarAsset.subjectAvatarBadgeName,
            type: .customUpload,
            imagePath: resolvedSubjectAvatarLogoImagePath,
            isSystemDefault: false
        )
    }

    private var resolvedMemoryWriteText: String {
        V1ResolvedMemoryWriteTextPresenter
            .resolvedText(
                subject:
                    alignedSelectedSubject()
                    ?? session.state.selectedSubject,
                usesCustomText:
                    session.usesCustomMemoryWriteText,
                customText:
                    session.customMemoryWriteText,
                smartModuleCarrierRegion:
                    session.smartModuleCarrierRegion
            )
    }

    private var moduleSheetPresented: Binding<Bool> {
        Binding(
            get: {
                V1ModuleLibraryPresenter
                    .isSheetPresented(
                        activeRegion:
                            activeModuleRegion
                    )
            },
            set: { isPresented in
                applyModulePanelState(
                    V1ModulePanelCoordinator
                        .setSheetPresented(
                            isPresented,
                            state:
                                modulePanelState
                        )
                )
            }
        )
    }

    private func draft(for region: CardRegion) -> V1EditorDraft {
        draftRuntimeCoordinator
            .draft(for: region)
    }

    private func setActiveTextItem(
        _ itemID: UUID?,
        for region: CardRegion
    ) {
        draftRuntimeCoordinator
            .setActiveTextItem(
                itemID,
                for: region
            )
    }

    private func updateTextItem(
        _ itemID: UUID,
        text: String,
        for region: CardRegion
    ) {
        draftRuntimeCoordinator
            .updateTextItem(
                itemID,
                text: text,
                for: region
            )
    }

    private func prependText(
        _ text: String,
        to region: CardRegion
    ) {
        draftRuntimeCoordinator
            .prependText(
                text,
                to: region
            )
    }

    private func appendText(
        _ text: String,
        to region: CardRegion
    ) {
        draftRuntimeCoordinator
            .appendText(
                text,
                to: region
            )
    }

    private func removeItem(
        _ itemID: UUID,
        from region: CardRegion
    ) {
        draftRuntimeCoordinator
            .removeItem(
                itemID,
                from: region
            )
    }

    private var draftOrchestrationState:
        V1DraftOrchestrationCoordinator.ViewState {
        V1DraftOrchestrationCoordinator
            .ViewState(
                regionDrafts: regionDrafts,
                activeTextItemIDs:
                    activeTextItemIDs,
                activeConfigurationStatus:
                    activeConfigurationStatus
            )
    }

    private func applyDraftOrchestrationState(
        _ state:
            V1DraftOrchestrationCoordinator.ViewState
    ) {
        regionDrafts =
            state.regionDrafts
        activeTextItemIDs =
            state.activeTextItemIDs
        activeConfigurationStatus =
            state.activeConfigurationStatus
    }

    private func refreshPreview(for region: CardRegion) {
        draftRuntimeCoordinator
            .refreshPreview(
                for: region
            )
    }

    private func refreshDynamicPreview() {
        draftRuntimeCoordinator
            .refreshDynamicPreview()
    }

    private func previewText(
        for region: CardRegion
    ) -> String {
        previewSyncCoordinator
            .previewText(
                for: region
            )
    }

    private func templateText(for draft: V1EditorDraft) -> String {
        draft.singleLineTemplateText
    }

    private func composedText(
        for draft: V1EditorDraft
    ) -> String {
        V1PreviewDraftAdapter.composedText(
            for: draft,
            context: previewCompositionContext,
            engine: previewCompositionEngine
        )
    }

    private func previewRenderModel(
        for draft: V1PreviewDraft
    ) -> V1PreviewRenderModel {
        V1PreviewDraftAdapter.renderModel(
            for: draft,
            context: previewCompositionContext,
            engine: previewCompositionEngine
        )
    }

    private func makeDefaultDraft(
        for region: CardRegion
    ) -> V1EditorDraft {
        V1PreviewDraftAdapter.defaultDraft(
            for: region,
            templateID: session.activeTemplateID(for: region),
            context: previewCompositionContext,
            engine: previewCompositionEngine
        )
    }

    private func moduleItem(
        _ module: IOSInsertableModule
    ) -> V1ContentItem {
        V1PreviewDraftAdapter.moduleItem(
            module,
            previewModule: previewModule(for: module),
            fallbackDisplayText: moduleDisplayText(module),
            context: previewCompositionContext,
            engine: previewCompositionEngine
        )
    }

    private func insert(
        _ module: IOSInsertableModule,
        into region: CardRegion
    ) {
        draftRuntimeCoordinator
            .insert(
                moduleItem(module),
                into: region
            )
    }

    @discardableResult
    @MainActor
    private func applyCurrentV1Configuration() async -> Bool {
        guard !isSavingConfiguration else {
            return false
        }

        let presetPersistenceSnapshot =
            session
            .persistenceSnapshotForCurrentConfiguration(
                logoMode: logoMode,
                outputConfiguration:
                    currentSavedOutputConfiguration
            )

        let payload = V1ConfigurationApplyPayloadBuilder.build(
            from: V1ConfigurationApplyPayloadInput(
                state: session.state,
                shouldSaveSubjectLibrary: shouldSaveSubjectLibrary,
                persistenceMemoryPresets:
                    presetPersistenceSnapshot.memoryPresets,
                persistenceSelectedMemoryPresetID:
                    presetPersistenceSnapshot.selectedMemoryPresetID,
                title: session.currentMemoryPresetTitle,
                regionDrafts: Dictionary(
                    uniqueKeysWithValues:
                        CardRegion.memoryCardRegions.map {
                            ($0, draft(for: $0))
                        }
                ),
                regionTemplateIDs: Dictionary(
                    uniqueKeysWithValues:
                        CardRegion.memoryCardRegions.compactMap {
                            region in
                            session.activeTemplateID(for: region)
                                .map { (region, $0) }
                        }
                ),
                locationConfiguration: locationDisplayConfiguration,
                logoMode: logoMode,
                badge: selectedBadgeForSaving,
                usesCustomMemoryWriteText:
                    session.usesCustomMemoryWriteText,
                customMemoryWriteText: session.customMemoryWriteText,
                shouldWritePhotosDescription:
                    shouldWritePhotosDescription,
                photosDescriptionOverride: photosDescriptionOverride,
                birthdayDate: birthdayDate,
                outputTarget: outputTarget,
                mediaOutputMode: mediaOutputMode,
                availableAlbums: availableAlbums,
                selectedAlbumIdentifier:
                    selectedExistingAlbumIdentifier,
                newAlbumName: newAlbumName,
                configurationAlbumTitle: configurationAlbumTitle,
                livePhotoPolicy: livePhotoPolicy,
                selectedTimeAnchorID: session.selectedTimeAnchorID,
                language: session.language,
                savedAt: Date()
            )
        )

        return await configurationApplyRuntimeCoordinator.apply(
            configurationLibrary:
                payload.configurationLibrary,
            aggregateDraft: payload.aggregateDraft,
            legacyRequest: payload.legacyRequest,
            outputTarget: outputTarget,
            availableAlbums: availableAlbums
        )
    }

    private var hasSavedConfigurationForSelectedSubject: Bool {
        !homeAvailablePresets.isEmpty
    }

    private var currentSavedOutputConfiguration:
        V1SavedOutputConfiguration {
        V1SavedOutputConfiguration(
            outputTarget: outputTarget,
            mediaOutputMode: mediaOutputMode,
            selectedExistingAlbumIdentifier:
                selectedExistingAlbumIdentifier,
            newAlbumName: newAlbumName
        )
    }

    private func beginPhotoProcessingFlow() {
        guard hasSavedConfigurationForSelectedSubject else {
            switchPresentation.showsConfigurationRequiredAlert = true
            return
        }

        entryFlowState =
            V1EntryFlowCoordinator
            .openProcessingPhotoPicker(
                from:
                    entryFlowState
            )
    }

    private func applySavedOutputConfiguration(
        _ preset: MemoryPreset
    ) {
        guard let savedOutputConfiguration =
            preset.savedOutputConfiguration
        else {
            return
        }

        isApplyingSavedOutputConfiguration = true
        outputTarget =
            savedOutputConfiguration.outputTarget
        mediaOutputMode =
            savedOutputConfiguration.mediaOutputMode
        selectedExistingAlbumIdentifier =
            savedOutputConfiguration
            .selectedExistingAlbumIdentifier
        newAlbumName =
            savedOutputConfiguration.newAlbumName
                .isEmpty
            ? PhotoMemoAlbumSelection
                .defaultAlbumTitle
            : savedOutputConfiguration
                .newAlbumName
        isApplyingSavedOutputConfiguration = false

        if outputTarget == .existingAlbum {
            Task {
                await loadAlbumOptions()
            }
        }
    }

    private var timeAnchorTitle: String {
        let anchorTitle =
            alignedSelectedSubject()?
            .primaryTimeAnchor?
            .title
            ?? alignedSelectedSubject()?
            .behavior.primaryAnchor
            ?? session.state.selectedSubject?
            .primaryTimeAnchor?
            .title
            ?? session.state.selectedSubject?
            .behavior.primaryAnchor
            ?? "时间锚点"

        let trimmedTitle =
            anchorTitle.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return trimmedTitle.isEmpty
            ? "时间锚点"
            : trimmedTitle
    }

    @MainActor
    private func loadAlbumOptions() async {
        guard !isLoadingAlbums else {
            return
        }

        isLoadingAlbums = true
        let projection =
            await V1ExportAlbumLoadingPresenter
            .loadProjection(
                currentAvailableAlbums:
                    availableAlbums,
                selectedExistingAlbumIdentifier:
                    selectedExistingAlbumIdentifier,
                coordinator:
                    exportCoordinator
            )

        isApplyingSavedOutputConfiguration = true
        availableAlbums = projection.availableAlbums
        selectedExistingAlbumIdentifier = projection.selectedExistingAlbumIdentifier
        albumStatusMessage =
            projection.albumStatusMessage

        isLoadingAlbums = false
        Task { @MainActor in
            await Task.yield()
            isApplyingSavedOutputConfiguration = false
        }
    }

    @MainActor
    private func optimizeSelectedLogo(
        _ item: PhotosPickerItem
    ) async {
        applyLogoAssetUpdate(
            logoAssetCoordinator
                .beginOptimization()
        )

        let update =
            await logoAssetCoordinator
            .optimize(item)
        applyLogoAssetUpdate(update)
    }

    private func applyLogoAssetUpdate(
        _ update: LogoAssetUpdate
    ) {
        mediaPickerPresentation.isOptimizingLogo =
            update.isOptimizingLogo

        if let customLogoBadge =
            update.customLogoBadge {
            self.customLogoBadge =
                customLogoBadge
        }

        if let logoMode =
            update.logoMode {
            self.logoMode = logoMode
        }

        if let activeConfigurationStatus =
            update.activeConfigurationStatus {
            self.activeConfigurationStatus =
                activeConfigurationStatus
        }
    }

    private func applyConfigurationDraftProjection(
        _ projection: V1ConfigurationDraftProjection
    ) {
        customLogoBadge = projection.badge
        logoMode = projection.logoMode
        locationDisplayConfiguration =
            projection.locationConfiguration
        session.language = projection.language
        session.restoreMemoryCopy(
            usesCustomText:
                projection.usesCustomMemoryWriteText,
            customText:
                projection.customMemoryWriteText
        )
        shouldWritePhotosDescription =
            projection.shouldWritePhotosDescription
        photosDescriptionOverride =
            projection.photosDescriptionOverride
        outputTarget = projection.outputTarget
        mediaOutputMode = projection.mediaOutputMode
        selectedExistingAlbumIdentifier =
            projection.selectedAlbumIdentifier
        configurationAlbumTitle = projection.albumTitle
        if projection.outputTarget == .newAlbum {
            newAlbumName = projection.albumTitle.isEmpty
                ? PhotoMemoAlbumSelection.defaultAlbumTitle
                : projection.albumTitle
        }
        livePhotoPolicy = projection.livePhotoPolicy
        regionDrafts = projection.regionDrafts

    }

    private func applyBootstrapFlowPatch(
        _ patch: V1BootstrapFlowPatch
    ) {
        bootstrapRuntimeCoordinator
            .apply(patch)
    }

    private var selectedBadgeForSaving: Badge {
        switch logoMode {
        case .appleMini:
            return .appleClassic
        case .customUpload:
            return customLogoBadge ?? .none
        case .subjectAvatar:
            return subjectAvatarBadge
        }
    }

    private func modules(for region: CardRegion) -> [IOSInsertableModule] {
        V1ModuleLibraryPresenter
            .modules(
                for: region,
                usageStorage:
                    moduleUsageCountsStorage
            )
    }

    private func moduleCategoryTitle(
        _ module: IOSInsertableModule
    ) -> String {
        V1ModuleLibraryPresenter
            .categoryTitle(
                for: module
            )
    }

    private func moduleDisplayText(
        _ module: IOSInsertableModule
    ) -> String {
        guard let previewModule =
            previewModule(
                for: module
            ) else {
            return module.title
        }

        return previewCompositionEngine
            .displayText(
                for: previewModule,
                context: previewCompositionContext
            )
    }

    private var previewCompositionContext:
        V1PreviewCompositionContext {

        V1PreviewCompositionContext(
            subject:
                alignedSelectedSubject()
                ?? session.state.selectedSubject,
            birthdayDate: birthdayDate,
            locationDisplayConfiguration:
                locationDisplayConfiguration,
            timeDisplayConfiguration:
                timeDisplayConfiguration
        )
    }

    private var locationDisplayOptionBinding:
        Binding<String> {
        Binding(
            get: {
                LocationDisplayInspectorPresenter
                    .selectedOptionID(
                        fromConfiguration:
                            locationDisplayConfiguration
                    )
            },
            set: { optionID in
                let configuration =
                    LocationDisplayInspectorPresenter
                    .configuration(
                        for: optionID
                    )
                locationDisplayConfiguration =
                    configuration
                _ = configurationCoordinator?
                    .saveLocationDisplayConfiguration(
                        configuration
                    )
                activeConfigurationStatus = .dirty
                refreshDynamicPreview()
            }
        )
    }

    private var timeDisplayOptionBinding: Binding<String> {
        Binding(
            get: {
                timeDisplayConfiguration.options["baseStyle"] ?? "daily"
            },
            set: { optionID in
                let style = TimeDisplayConfiguration.BaseStyle(rawValue: optionID) ?? .daily
                timeDisplayConfiguration = TimeDisplayInspectorPresenter.configuration(
                    baseStyle: style,
                    supplement: selectedTimeSupplement
                )
                _ = configurationCoordinator?.saveTimeDisplayConfiguration(timeDisplayConfiguration)
                activeConfigurationStatus = .dirty
                refreshDynamicPreview()
            }
        )
    }

    private var selectedTimeSupplement: TimeDisplayConfiguration.Supplement {
        TimeDisplayConfiguration.Supplement(
            rawValue: timeDisplayConfiguration.options["supplement"] ?? "none"
        ) ?? .none
    }

    private var timeDisplaySupplementBinding: Binding<TimeDisplayConfiguration.Supplement> {
        Binding(
            get: { selectedTimeSupplement },
            set: { supplement in
                let style = TimeDisplayConfiguration.BaseStyle(
                    rawValue: timeDisplayConfiguration.options["baseStyle"] ?? "daily"
                ) ?? .daily
                timeDisplayConfiguration = TimeDisplayInspectorPresenter.configuration(
                    baseStyle: style,
                    supplement: supplement
                )
                _ = configurationCoordinator?.saveTimeDisplayConfiguration(timeDisplayConfiguration)
                activeConfigurationStatus = .dirty
                refreshDynamicPreview()
            }
        )
    }

    private var selectedTimeAnchorBinding:
        Binding<UUID> {
        Binding(
            get: {
                session.selectedTimeAnchorID
                ?? session.availableTimeAnchors.first?.id
                ?? UUID()
            },
            set: selectConfigurationSummaryTimeAnchor
        )
    }

    private var selectedMemoryDisplayStyleBinding:
        Binding<MemoryAnchorExpressionStyle> {
        Binding(
            get: {
                ConfigurationCenterMemoryDisplaySupport
                    .selectedStyle(
                        subject: session.state.selectedSubject
                    )
                ?? .birthdayNatural
            },
            set: { style in
                session
                    .selectCurrentTimeAnchorExpressionStyle(
                        style
                    )
                activeConfigurationStatus = .dirty
                refreshDynamicPreview()
            }
        )
    }

    private func selectConfigurationSummaryTimeAnchor(
        _ anchorID: UUID
    ) {
        guard
            let anchor =
                session.availableTimeAnchors.first(
                    where: { $0.id == anchorID }
                )
        else {
            return
        }

        session.selectTimeAnchor(id: anchorID)
        birthdayDate = anchor.date
        activeConfigurationStatus = .dirty
        refreshDynamicPreview()
    }

    private func alignedSelectedSubject()
    -> MemorySubject? {
        V1ConfigurationApplyRequestBuilder
            .alignedSelectedSubject(
                from:
                    session
                    .state
                    .selectedSubject,
                birthdayDate:
                    birthdayDate
            )
    }

    private var shareDiagnosticsHeaderProjection:
        PhotoMemoiOSQueueDiagnosticsHeaderProjection {

        PhotoMemoiOSQueueDiagnosticsProjectionEngine
            .headerProjection(
                backgroundSnapshot:
                    backgroundStatusService
                    .currentSnapshot,
                processingDiagnosticsSnapshot:
                    processingDiagnosticsSnapshot,
                events:
                    shareDiagnosticEvents
            )
    }

    private func previewModule(
        for module: IOSInsertableModule
    ) -> V1PreviewCompositionModule? {

        V1PreviewCompositionModule(
            rawValue: module.rawValue
        )
    }

    private func refreshProcessingState() {
        applyDiagnosticsRefreshState(
            diagnosticsRefreshCoordinator
                .refreshedState()
        )
    }

    private func openPhotoLibrary(
        _ link: V1TaskPhotoLibraryLink
    ) {
        guard let primaryURL =
            URL(string: "photos-redirect://")
        else {
            return
        }

        UIApplication.shared.open(primaryURL) { success in
            guard !success,
                  let fallbackURL =
                    URL(string: "photos://")
            else {
                return
            }

            UIApplication.shared.open(fallbackURL)
        }
    }

    private func applyDiagnosticsRefreshState(
        _ state:
            V1DiagnosticsRefreshState
    ) {
        processingDiagnosticsSnapshot =
            state.snapshot
        shareDiagnosticEvents =
            state.events
    }

    private func applyModulePanelState(
        _ state:
            V1ModulePanelCoordinator.State
    ) {
        activeModuleRegion =
            state.activeRegion
        moduleUsageCountsStorage =
            state.usageStorage
    }

    private var editorRevealProgress: CGFloat {
        entryNavigationState.editorRevealProgress
    }

    private var previewPinProgress: CGFloat {
        entryNavigationState.previewPinProgress
    }

    private func offsetReader(
        for kind: V1ScrollOffsetKind
    ) -> some View {
        GeometryReader { proxy in
            Color.clear
                .preference(
                    key: V1ScrollOffsetPreferenceKey.self,
                    value: [
                        kind: proxy.frame(
                            in: .named("v1-scroll")
                        ).minY
                    ]
                )
        }
        .onPreferenceChange(V1ScrollOffsetPreferenceKey.self) { values in
            entryNavigationState.updateScrollOffsets(
                profile: values[.profile],
                preview: values[.preview]
            )
        }
    }

    private func bootstrapIfNeeded() {
        guard !didBootstrap else {
            return
        }

        didBootstrap = true
        applyBootstrapFlowPatch(
            bootstrapFlowCoordinator
                .bootstrap(
                    hasSeenWelcome:
                        hasSeenWelcome,
                    fallbackBirthdayDate:
                        birthdayDate,
                    makeDefaultDraft:
                        makeDefaultDraft(for:)
                )
        )
    }

    private func dismissKeyboard() {
        memoryPresetTitleFieldFocused = false
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }

    private func completeWelcomeFlow() {
        let update =
            V1EntryFlowCoordinator
            .completeWelcome(
                from: entryFlowState,
                hasSeenWelcome:
                    hasSeenWelcome
            )
        applyEntryWelcomeUpdate(update)
    }

    @MainActor
    private func initializeFirstConfiguration(
        subjectName: String,
        birthday: Date
    ) async -> Bool {
        let previousState = session.state
        let previousBirthdayDate = birthdayDate
        let previousOutputTarget = outputTarget
        let previousMediaOutputMode = mediaOutputMode
        let previousLogoMode = logoMode
        let previousPresetTitleDraft = renamePresentation.titleDraft
        let subject = V1SubjectLibraryFactory
            .makeFirstRunSubject(
                name: subjectName,
                birthday: birthday
            )
        let anchorID = subject.activeTimeAnchorID
        let existingPreset = session.state.selectedMemoryPreset
            ?? session.state.memoryPresets.first
        let preset = MemoryPreset(
            title: "生日回顾",
            summary: "以生日为时间起点，自然回顾照片拍摄时的年龄。",
            regionTemplateIDs:
                existingPreset?.regionTemplateIDs ?? [:],
            selectedSubjectID: subject.id,
            selectedTimeAnchorID: anchorID,
            outputOption: .processedImage,
            storageOption: .appFolder,
            logoMode: .appleMini,
            savedOutputConfiguration:
                V1SavedOutputConfiguration(
                    outputTarget: .automatic,
                    mediaOutputMode: .originalFormat,
                    selectedExistingAlbumIdentifier: "",
                    newAlbumName:
                        PhotoMemoAlbumSelection
                        .defaultAlbumTitle
                )
        )

        session.restoreSubjectLibrary(
            [subject],
            selectedSubjectID: subject.id,
            memoryPresets: [preset],
            selectedMemoryPresetID: preset.id
        )
        birthdayDate = birthday
        outputTarget = .automatic
        mediaOutputMode = .originalFormat
        logoMode = .appleMini
        renamePresentation.titleDraft = preset.title
        bootstrapDrafts()
        refreshDynamicPreview()

        guard await applyCurrentV1Configuration() else {
            session.state = previousState
            birthdayDate = previousBirthdayDate
            outputTarget = previousOutputTarget
            mediaOutputMode = previousMediaOutputMode
            logoMode = previousLogoMode
            renamePresentation.titleDraft = previousPresetTitleDraft
            bootstrapDrafts()
            refreshDynamicPreview()
            return false
        }

        completeWelcomeFlow()
        return true
    }

    private func applyEntryWelcomeUpdate(
        _ update: V1EntryWelcomeFlowUpdate
    ) {
        hasSeenWelcome = update.hasSeenWelcome
        entryFlowState = update.flowState
    }

    private func applyWelcomeFlowState(
        _ state: V1WelcomeFlowState
    ) {
        hasSeenWelcome = state.hasSeenWelcome
        entryFlowState =
            V1EntryFlowCoordinator
            .applyWelcomeState(
                state,
                to: entryFlowState
            )
    }

    private func bootstrapDrafts() {
        draftRuntimeCoordinator
            .bootstrapDrafts(
                using:
                    V1DraftBootstrapCoordinator(
                        session: session,
                        context:
                            previewCompositionContext,
                        engine:
                            previewCompositionEngine
                    )
            )
    }

    @MainActor
    private func importPickedPhotos(
        _ items: [PhotosPickerItem]
    ) async {
        defer {
            mediaPickerPresentation.selectedProcessingItems = []
        }
        await performPhotoQuickAction {
            await V1PhotoIntakeImporter.importItems(from: items)
        }
    }

    @MainActor
    private func importPickedPHPickerResults(
        _ results: [PHPickerResult]
    ) async {
        await performPhotoQuickAction {
            await V1PhotoIntakeImporter.importPHPickerResults(from: results)
        }
    }

    @MainActor
    private func performPhotoQuickAction(
        importItems: @escaping () async -> [ExternalPhotoIntakeItem]
    ) async {
        let result = await V1PhotoProcessingQuickActionCoordinator
            .processPickedPhotoItems(
                saveCurrentConfiguration: applyCurrentV1Configuration,
                importItems: importItems,
                submit: {
                    externalIntakeCenter.submit(
                        items: $0,
                        source: .quickAction
                    )
                }
            )

        switch result.status {
        case .configurationSaveFailed:
            return
        case .noSupportedPhotos:
            break
        case .submitted:
            refreshExternalIntake()
            refreshProcessingState()
        }

        entryFlowState =
            V1EntryFlowCoordinator
            .applyQuickActionResult(
                result,
                to: entryFlowState
            )
    }

    private var homeAvailablePresets: [MemoryPreset] {
        session.availableMemoryPresetsForSelectedSubject
    }

    private func expansionBinding(
        for section: PhotoMemoiOSV1EntrySection
    ) -> Binding<Bool> {
        Binding(
            get: {
                entryNavigationState.expandedEditorSections
                    .contains(section)
            },
            set: { isExpanded in
                entryNavigationState.setEditorSection(
                    section,
                    isExpanded: isExpanded
                )
            }
        )
    }
}

private enum V1ScrollOffsetKind:
    Hashable {

    case profile
    case preview
}

private struct V1ScrollOffsetPreferenceKey:
    PreferenceKey {

    static var defaultValue: [V1ScrollOffsetKind: CGFloat] = [:]

    static func reduce(
        value: inout [V1ScrollOffsetKind: CGFloat],
        nextValue: () -> [V1ScrollOffsetKind: CGFloat]
    ) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

#Preview("iOS V1.0 预览") {
    let runtime =
        PhotoMemoAppRuntime()

    PhotoMemoiOSV1View(
        backgroundStatusService:
            runtime.backgroundStatusService,
        previewCoordinator:
            runtime.environment
            .coordinators
            .preview,
        exportCoordinator:
            runtime.environment
            .coordinators
            .export,
        queueCoordinator:
            runtime.environment
            .coordinators
            .queue,
        configurationCoordinator:
            runtime.environment
            .coordinators
            .configuration,
        externalIntakeCenter:
            runtime.environment
            .externalIntakeCenter,
        diagnosticsRepository:
            runtime.environment
            .repositories
            .diagnostics
    )
}

#endif
