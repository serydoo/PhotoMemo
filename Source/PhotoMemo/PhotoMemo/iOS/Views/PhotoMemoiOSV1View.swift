#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI
import PhotosUI
import UIKit

struct PhotoMemoiOSV1View: View {
    @Environment(\.scenePhase)
    private var scenePhase

    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass

    @Environment(\.verticalSizeClass)
    private var verticalSizeClass

    @ObservedObject
    private var backgroundStatusService:
        PhotoMemoBackgroundStatusService

    @ObservedObject
    private var commerceStore:
        MemoMarkCommerceStore

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

    private let productionDiagnosticsRepository:
        ProductionDiagnosticsRepository?

    private let notificationDeepLink:
        PhotoMemoDeepLink?

    private let onNotificationDeepLinkHandled:
        () -> Void

    private let localConfigurationLibraryCoordinator:
        LocalConfigurationLibraryCoordinator

    private let externalIntakeCenter:
        ExternalPhotoIntakeCenter

    @StateObject
    private var session = ConfigurationSession()

    @State
    private var regionDrafts: [CardRegion: V1EditorDraft] = [:]

    @State
    private var editorInteractionState =
        V1EditorInteractionState()

    @State
    private var entryNavigationState =
        EntryNavigationState()

    @State
    private var rootPresentationState =
        V1RootPresentationState()

    @State
    private var rootConfigurationProjectionState =
        V1RootConfigurationProjectionState()

    private var logoMode: V1LogoMode {
        get { rootConfigurationProjectionState.logoMode }
        nonmutating set {
            rootConfigurationProjectionState.logoMode = newValue
        }
    }

    private var customLogoBadge: Badge? {
        get { rootConfigurationProjectionState.customLogoBadge }
        nonmutating set {
            rootConfigurationProjectionState.customLogoBadge = newValue
        }
    }

    private var birthdayDate: Date {
        get { rootConfigurationProjectionState.birthdayDate }
        nonmutating set {
            rootConfigurationProjectionState.birthdayDate = newValue
        }
    }

    private var locationDisplayConfiguration:
        ExpressionModuleConfiguration? {
        get {
            rootConfigurationProjectionState
                .locationDisplayConfiguration
        }
        nonmutating set {
            rootConfigurationProjectionState
                .locationDisplayConfiguration = newValue
        }
    }

    private var timeDisplayConfiguration:
        ExpressionModuleConfiguration {
        get {
            rootConfigurationProjectionState
                .timeDisplayConfiguration
        }
        nonmutating set {
            rootConfigurationProjectionState
                .timeDisplayConfiguration = newValue
        }
    }

    @State
    private var outputDraftState =
        V1OutputDraftState()

    @State
    private var rootLifecycleState =
        V1RootLifecycleState()

    private var isSavingConfiguration: Bool {
        get { rootLifecycleState.isSavingConfiguration }
        nonmutating set {
            rootLifecycleState.isSavingConfiguration = newValue
        }
    }

    private var didBootstrap: Bool {
        get { rootLifecycleState.didBootstrap }
        nonmutating set {
            rootLifecycleState.didBootstrap = newValue
        }
    }

    private var isApplyingBootstrapState: Bool {
        get { rootLifecycleState.isApplyingBootstrapState }
        nonmutating set {
            rootLifecycleState.isApplyingBootstrapState = newValue
        }
    }

    private var isApplyingSavedOutputConfiguration: Bool {
        get {
            rootLifecycleState
                .isApplyingSavedOutputConfiguration
        }
        nonmutating set {
            rootLifecycleState
                .isApplyingSavedOutputConfiguration = newValue
        }
    }

    private var birthdayDateChangeBehavior:
        V1BirthdayDateChangeBehavior {
        get { rootLifecycleState.birthdayDateChangeBehavior }
        nonmutating set {
            rootLifecycleState.birthdayDateChangeBehavior = newValue
        }
    }

    private var shouldSaveSubjectLibrary: Bool {
        get { rootLifecycleState.shouldSaveSubjectLibrary }
        nonmutating set {
            rootLifecycleState.shouldSaveSubjectLibrary = newValue
        }
    }

    private var isPersistingSubjectChanges: Bool {
        get { rootLifecycleState.isPersistingSubjectChanges }
        nonmutating set {
            rootLifecycleState.isPersistingSubjectChanges = newValue
        }
    }

    private var activeConfigurationStatus:
        V1ConfigurationStatus {
        get { rootLifecycleState.activeConfigurationStatus }
        nonmutating set {
            rootLifecycleState.activeConfigurationStatus = newValue
        }
    }

    @State
    private var shareDiagnosticEvents:
        [PhotoMemoShareDiagnosticEvent] = []

    @State
    private var processingDiagnosticsSnapshot =
        PhotoMemoiOSProcessingDiagnosticsSnapshot()

    @FocusState
    private var memoryPresetTitleFieldFocused: Bool

    @AppStorage("photomemo.v1.moduleUsageCounts")
    private var moduleUsageCountsStorage = "{}"

    @AppStorage("photomemo.v1.welcomeSeen")
    private var hasSeenWelcome = false

    private let currentBorderStyleName =
        MemoMarkLanguage.interfaceStored.localized(
            key: "configuration.preview.basic_white",
            fallback: "基础白"
        )

    private let currentBorderStyleDescription =
        MemoMarkLanguage.interfaceStored.localized(
            key: "configuration.preview.basic_white.description",
            fallback: "Classic White 当前唯一公开边框，预览与生成保持同一套锁定规范。"
        )

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
            focusedRegion:
                editorInteractionState.focusedEditorRegion,
            activeRegion:
                editorInteractionState.activeModuleRegion,
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
            },
            recordDiagnostic: { event in
                await productionDiagnosticsRepository?
                    .record(event)
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

                outputDraftState.outputTarget =
                    projection.outputTarget
                outputDraftState.mediaOutputMode =
                    projection.mediaOutputMode
                outputDraftState.selectedExistingAlbumIdentifier =
                    projection
                    .selectedExistingAlbumIdentifier

                if let suggestedNewAlbumName =
                    projection
                    .suggestedNewAlbumName {
                    outputDraftState.newAlbumName =
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
        commerceStore:
            MemoMarkCommerceStore,
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
            DiagnosticsRepository? = nil,
        productionDiagnosticsRepository:
            ProductionDiagnosticsRepository? = nil,
        notificationDeepLink: PhotoMemoDeepLink? = nil,
        onNotificationDeepLinkHandled:
            @escaping () -> Void = {}
    ) {
        self._backgroundStatusService =
            ObservedObject(
                wrappedValue:
                    backgroundStatusService
            )
        self._commerceStore =
            ObservedObject(
                wrappedValue:
                    commerceStore
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
        self._rootConfigurationProjectionState = State(
            initialValue:
                V1RootConfigurationProjectionState(
                    timeDisplayConfiguration:
                        configurationCoordinator?
                        .loadTimeDisplayConfiguration()
                )
        )
        self.externalIntakeCenter =
            externalIntakeCenter
            ?? .shared
        self.diagnosticsRepository =
            diagnosticsRepository
        self.productionDiagnosticsRepository =
            productionDiagnosticsRepository
        self.notificationDeepLink = notificationDeepLink
        self.onNotificationDeepLinkHandled =
            onNotificationDeepLinkHandled
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
        .onAppear {
            consumeNotificationDeepLinkIfNeeded()
        }
        .onChange(of: notificationDeepLink) { _, _ in
            consumeNotificationDeepLinkIfNeeded()
        }
        .modifier(
            V1LocalConfigurationLibraryPresentationModifier(
                presentation:
                    $rootPresentationState.localLibraryPresentation,
                subjectName:
                    session.state.selectedSubject?
                    .identity.displayName
                    ?? MemoMarkLanguage.interfaceStored.localized(
                        key: "configuration.subjects.all",
                        fallback: "全部记忆对象"
                    ),
                onRefresh: refreshLocalConfigurationLibrary,
                onRestore: restoreLocalConfigurationBackup,
                onDelete: deleteLocalConfigurationBackup
            )
        )
        .alert(
            MemoMarkLanguage.interfaceStored.localized(
                key: "configuration.unsaved_switch.title",
                fallback: "有未保存的修改"
            ),
            isPresented:
                $rootPresentationState
                .switchPresentation
                .showsUnsavedPresetSwitchAlert
        ) {
            Button(
                MemoMarkLanguage.interfaceStored.localized(
                    key: "common.save_and_switch",
                    fallback: "保存并切换"
                )
            ) {
                saveCurrentConfigurationThenActivatePendingPreset()
            }
            Button(
                MemoMarkLanguage.interfaceStored.localized(
                    key: "common.cancel",
                    fallback: "取消"
                ),
                role: .cancel
            ) {
                rootPresentationState
                    .switchPresentation
                    .pendingMemoryPresetActivation = nil
            }
        } message: {
            Text(
                MemoMarkLanguage.interfaceStored.localized(
                    key: "configuration.unsaved_switch.message",
                    fallback: "请先保存当前配置，再切换到另一条配置，避免丢失刚刚的修改。"
                )
            )
        }
        .task {
            await loadAlbumOptions()
        }
        .modifier(
            V1WelcomeAndSettingsPresentationModifier(
                flowState: $entryNavigationState.flowState,
                showsConfigurationRequiredAlert:
                    $rootPresentationState
                        .switchPresentation
                        .showsConfigurationRequiredAlert,
                hasSeenWelcome: hasSeenWelcome,
                settingsContent: settingsPage,
                initializeFirstConfiguration:
                    initializeFirstConfiguration,
                completeWelcomeFlow: completeWelcomeFlow
            )
        )
        .sheet(
            isPresented:
                $rootPresentationState.showsWelcomeInformation
        ) {
            V1WelcomePageSurface(
                presentation:
                    V1WelcomePresentation.localized(
                        for: .interfaceStored
                    ),
                language: .interfaceStored,
                onStart: {
                    rootPresentationState.showsWelcomeInformation = false
                },
                onShowWorkflow: {
                    rootPresentationState.showsWelcomeInformation = false
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
                showsRegionContentSheet:
                    $rootPresentationState.showsRegionContentSheet,
                editorContent: editorCluster,
                onDismissKeyboard: dismissKeyboard,
                onToggleModuleLibrary:
                    toggleModuleLibraryFromToolbar,
                canToggleModuleLibrary:
                    editorInteractionState.focusedEditorRegion != nil
                    || editorInteractionState.activeModuleRegion != nil,
                isModuleLibraryPresented:
                    editorInteractionState.activeModuleRegion != nil,
                focusedRegionTitle:
                    editorInteractionState.focusedEditorRegion?.displayTitle,
                onDismissEditor:
                    resetCardEditorState
            )
        )
        .modifier(
            V1SubjectPresentationModifier(
                session: session,
                flowState: $entryNavigationState.flowState,
                switchPresentation:
                    $rootPresentationState.switchPresentation,
                birthdayDate: birthdayDate,
                availableConfigurationCount: homeAvailablePresets.count,
                completedPhotoCount:
                    backgroundStatusService
                    .taskOverview
                    .completedPhotoCount,
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
                entryPresentation: entryPresentation,
                isApplyingBootstrapState: isApplyingBootstrapState,
                isApplyingSavedOutputConfiguration:
                    isApplyingSavedOutputConfiguration,
                flowState: $entryNavigationState.flowState,
                renamePresentation:
                    $rootPresentationState.renamePresentation,
                titleFieldFocus: $memoryPresetTitleFieldFocused,
                birthdayDate:
                    $rootConfigurationProjectionState.birthdayDate,
                birthdayDateChangeBehavior:
                    $rootLifecycleState.birthdayDateChangeBehavior,
                memorySourceDisclosureState:
                    $rootPresentationState.memorySourceDisclosureState,
                mediaPickerPresentation:
                    $rootPresentationState.mediaPickerPresentation,
                logoMode:
                    $rootConfigurationProjectionState.logoMode,
                customLogoBadge:
                    $rootConfigurationProjectionState.customLogoBadge,
                outputTarget: $outputDraftState.outputTarget,
                mediaOutputMode: $outputDraftState.mediaOutputMode,
                selectedAlbumIdentifier:
                    $outputDraftState.selectedExistingAlbumIdentifier,
                newAlbumName: $outputDraftState.newAlbumName,
                configurationStatus:
                    $rootLifecycleState.activeConfigurationStatus,
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

    private func consumeNotificationDeepLinkIfNeeded() {
        guard let notificationDeepLink else {
            return
        }

        switch notificationDeepLink {
        case .share:
            break
        case .processing(let jobID):
            backgroundStatusService.focus(jobID: jobID)
            entryFlowState = V1EntryFlowCoordinator.openTasksTab(
                from: entryFlowState
            )
        }

        onNotificationDeepLinkHandled()
    }

    @ViewBuilder
    private var rootNavigation: some View {
        V1EntryNavigationSurface(
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

    private var settingsPage: some View {
        V1SettingsPageSurface(
            commerceSnapshot: commerceStore.snapshot,
            onOpenMemoMarkPlus: {
                rootPresentationState.showsMemoMarkPlus = true
            },
            onShowWelcome: {
                entryFlowState =
                    V1EntryFlowCoordinator
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
                    throw PhotoMemoError(
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

    private var entryPresentation:
        V1EntryPresentation {
        switch entryNavigationStyle {
        case .bottomTabBar:
            return .compact
        case .compactSidebar, .regularSidebar:
            return .regular
        }
    }

    private var entryNavigationStyle:
        V1EntryNavigationStyle {
        V1AdaptivePageLayout
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
                        rootPresentationState.memorySourceDisclosureState
                            .isExpanded
                    },
                    set: { isExpanded in
                        rootPresentationState.memorySourceDisclosureState
                            .setExpanded(isExpanded)
                    }
                ),
            subjectAvatarPreviewImagePath:
                resolvedSubjectAvatarPreviewImagePath,
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
            borderStyleName:
                currentBorderStyleName,
            configurationStatus:
                activeConfigurationStatus,
            onOpenRegionContent: {
                resetCardEditorState()
                rootPresentationState.showsRegionContentSheet = true
            }
        )
    }

    private var outputPage: some View {
        V1OutputPageSurface(
            outputTarget: $outputDraftState.outputTarget,
            mediaOutputMode:
                $outputDraftState.mediaOutputMode,
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
            onRetryFailedTasks: {
                guard let jobID =
                    backgroundStatusService
                    .currentSnapshot?.jobID else {
                    return
                }
                _ = queueCoordinator?
                    .retryFailedTasks(
                        in: jobID
                    )
            },
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
            .commitRename(
                title: rootPresentationState.renamePresentation.titleDraft
            )
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
        guard let preset = rootPresentationState
            .switchPresentation
            .pendingMemoryPresetActivation else {
            return
        }

        Task { @MainActor in
            guard await applyCurrentV1Configuration(),
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

    private func saveCurrentConfigurationThenSelectPendingSubject() {
        guard let subjectID = rootPresentationState
            .switchPresentation
            .pendingSubjectSelectionID else {
            return
        }

        Task { @MainActor in
            guard await applyCurrentV1Configuration(),
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
        rootPresentationState.localLibraryPresentation.isPresented = true
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
    private var homeConfigurationStatusBanner: some View {
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
        rootPresentationState.renamePresentation.titleDraft = configuration.title
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

    private func synchronizeSelectedSubjectConfigurationProjection() {
        isApplyingSavedOutputConfiguration = true
        defer {
            isApplyingSavedOutputConfiguration = false
        }

        if let configuration = session.selectedMemoryConfiguration {
            applyConfigurationDraftProjection(
                V1ConfigurationDraftProjection(
                    configuration: configuration
                )
            )
            return
        }

        guard let preset = session.state.selectedMemoryPreset else {
            return
        }

        logoMode = preset.logoMode
        customLogoBadge = nil
        applySavedOutputConfiguration(preset)
    }

    private func persistActiveConfigurationSelection() {
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
                if receipt.compatibilityProjectionFailure != nil,
                   let operationID = receipt.diagnosticOperationID {
                    let failure =
                        ProductionDiagnosticFailureClassifier
                        .compatibilityProjection(
                            operationID: operationID,
                            language: .interfaceStored
                        )
                    activeConfigurationStatus =
                        .savedWithWarning(
                            message: failure.userMessage
                        )
                } else {
                    activeConfigurationStatus = .subjectSynced
                }
                refreshDynamicPreview()
            } catch {
                activeConfigurationStatus = .failure(
                    message:
                        (error as? PhotoMemoError)?.message
                        ?? MemoMarkLanguage.interfaceStored.localized(
                            key: "subject.save_failed",
                            fallback: "记忆对象保存失败，请重试。"
                        )
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
            slotATextKitCommandBus:
                editorInteractionState.slotATextKitCommandBus,
            slotBTextKitCommandBus:
                editorInteractionState.slotBTextKitCommandBus,
            slotCTextKitCommandBus:
                editorInteractionState.slotCTextKitCommandBus,
            slotDTextKitCommandBus:
                editorInteractionState.slotDTextKitCommandBus,
            draft: { region in
                draft(for: region)
            },
            onFocus: { region in
                focusRegionEditor(for: region)
            },
            onFocusTextItem: { region, item in
                setActiveTextItem(item.id, for: region)
                focusRegionEditor(for: region)
            },
            onFocusTrailingText: { region in
                // A default module-only region uses a transient trailing
                // text field. Clearing a stale text anchor ensures insertion
                // appends after the visible module instead of jumping left.
                setActiveTextItem(nil, for: region)
                focusRegionEditor(for: region)
            },
            onUpdateTextItem: { region, item, text in
                updateTextItem(item.id, text: text, for: region)
            },
            onReplaceDraft: { region, draft in
                draftRuntimeCoordinator.replaceDraft(draft, for: region)
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
            onRemovePreviousComposedItem: { region, itemID in
                let removed = draftRuntimeCoordinator.removePreviousComposedItem(before: itemID, from: region)
                if removed {
                    refreshPreview(for: region)
                }
                return removed
            },
            focusedRegion:
                editorInteractionState.focusedEditorRegion,
            activeModuleRegion:
                editorInteractionState.activeModuleRegion,
            modules: modules(for:),
            categoryTitle: moduleCategoryTitle,
            valueText: moduleDisplayText,
            insertionMarkerID: { region in
                if editorInteractionState.recentInsertionRegion == region {
                    return editorInteractionState.recentInsertionItemID
                }

                // While the candidate surface is open, keep one quiet marker
                // beside the active text node so the saved insertion context
                // remains visible after the keyboard has been dismissed.
                guard editorInteractionState.activeModuleRegion == region else {
                    return nil
                }
                return editorInteractionState.activeTextItemIDs[region]
            },
            showsInsertionMarkerAtEnd: { region in
                editorInteractionState.activeModuleRegion == region
                    && editorInteractionState.activeTextItemIDs[region] == nil
            },
            onSelectModule: { module, region in
                if region == .slotA {
                    editorInteractionState.slotATextKitCommandBus
                        .insert(moduleItem(module))
                    editorInteractionState.clearInsertionContext()
                } else if region == .slotB {
                    editorInteractionState.slotBTextKitCommandBus
                        .insert(moduleItem(module))
                    editorInteractionState.clearInsertionContext()
                } else if region == .slotC {
                    editorInteractionState.slotCTextKitCommandBus
                        .insert(moduleItem(module))
                    editorInteractionState.clearInsertionContext()
                } else if region == .slotD {
                    editorInteractionState.slotDTextKitCommandBus
                        .insert(moduleItem(module))
                    editorInteractionState.clearInsertionContext()
                } else {
                    editorInteractionState.recentInsertionRegion = region
                    editorInteractionState.recentInsertionItemID =
                        insert(module, into: region)
                }
                applyModulePanelState(
                    V1ModulePanelCoordinator.selectModule(
                        module,
                        state: modulePanelState
                    )
                )
            },
            onCloseModuleLibrary: {
                applyModulePanelState(
                    V1ModulePanelCoordinator.setSheetPresented(
                        false,
                        state: modulePanelState
                    )
                )
            }
        )
    }

    private func focusRegionEditor(
        for region: CardRegion
    ) {
        editorInteractionState.clearInsertionContext()
        applyModulePanelState(
            V1ModulePanelCoordinator.focusRegion(
                region,
                state: modulePanelState
            )
        )
    }

    private func showModuleLibrary(
        for region: CardRegion
    ) {
        applyModulePanelState(
            V1ModulePanelCoordinator.showModules(
                for: region,
                state: modulePanelState
            )
        )
    }

    private func toggleModuleLibraryFromToolbar() {
        if editorInteractionState.activeModuleRegion != nil {
            applyModulePanelState(V1ModulePanelCoordinator.setSheetPresented(false, state: modulePanelState))
            return
        }
        guard let focusedEditorRegion =
            editorInteractionState.focusedEditorRegion
        else { return }
        dismissKeyboard()
        showModuleLibrary(for: focusedEditorRegion)
    }

    private func resetCardEditorState() {
        editorInteractionState.clearInsertionContext()
        dismissKeyboard()
        applyModulePanelState(V1ModulePanelCoordinator.focusEditor(state: modulePanelState))
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
                    editorInteractionState.activeTextItemIDs,
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
        editorInteractionState.activeTextItemIDs =
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
    ) -> UUID {
        let item = moduleItem(module)
        draftRuntimeCoordinator.insert(item, into: region)
        return item.id
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
                    outputDraftState.shouldWritePhotosDescription,
                photosDescriptionOverride:
                    outputDraftState.photosDescriptionOverride,
                birthdayDate: birthdayDate,
                outputTarget: outputDraftState.outputTarget,
                mediaOutputMode: outputDraftState.mediaOutputMode,
                availableAlbums: outputDraftState.availableAlbums,
                selectedAlbumIdentifier:
                    outputDraftState.selectedExistingAlbumIdentifier,
                newAlbumName: outputDraftState.newAlbumName,
                configurationAlbumTitle:
                    outputDraftState.configurationAlbumTitle,
                livePhotoPolicy: outputDraftState.livePhotoPolicy,
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
            outputTarget: outputDraftState.outputTarget,
            availableAlbums: outputDraftState.availableAlbums
        )
    }

    private var hasSavedConfigurationForSelectedSubject: Bool {
        !homeAvailablePresets.isEmpty
    }

    private var currentSavedOutputConfiguration:
        V1SavedOutputConfiguration {
        V1SavedOutputConfiguration(
            outputTarget: outputDraftState.outputTarget,
            mediaOutputMode: outputDraftState.mediaOutputMode,
            selectedExistingAlbumIdentifier:
                outputDraftState.selectedExistingAlbumIdentifier,
            newAlbumName: outputDraftState.newAlbumName
        )
    }

    private func beginPhotoProcessingFlow() {
        guard hasSavedConfigurationForSelectedSubject else {
            rootPresentationState
                .switchPresentation
                .showsConfigurationRequiredAlert = true
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
        outputDraftState.outputTarget =
            savedOutputConfiguration.outputTarget
        outputDraftState.mediaOutputMode =
            savedOutputConfiguration.mediaOutputMode
        outputDraftState.selectedExistingAlbumIdentifier =
            savedOutputConfiguration
            .selectedExistingAlbumIdentifier
        outputDraftState.newAlbumName =
            savedOutputConfiguration.newAlbumName
                .isEmpty
            ? PhotoMemoAlbumSelection
                .defaultAlbumTitle
            : savedOutputConfiguration
                .newAlbumName
        isApplyingSavedOutputConfiguration = false

        if outputDraftState.outputTarget == .existingAlbum {
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
        guard outputDraftState.activeAlbumLoadRequest == nil else {
            return
        }

        let request = V1OutputAlbumLoadRequest(
            subjectID: session.state.selectedSubject?.id,
            configurationID: session.state.selectedMemoryPresetID
        )
        outputDraftState.activeAlbumLoadRequest = request
        outputDraftState.isLoadingAlbums = true
        defer {
            if outputDraftState.activeAlbumLoadRequest == request {
                outputDraftState.activeAlbumLoadRequest = nil
                outputDraftState.isLoadingAlbums = false
            }
        }

        let projection =
            await V1ExportAlbumLoadingPresenter
            .loadProjection(
                currentAvailableAlbums:
                    outputDraftState.availableAlbums,
                selectedExistingAlbumIdentifier:
                    outputDraftState.selectedExistingAlbumIdentifier,
                coordinator:
                    exportCoordinator
            )

        guard request.matches(
            subjectID: session.state.selectedSubject?.id,
            configurationID: session.state.selectedMemoryPresetID
        ) else {
            return
        }

        isApplyingSavedOutputConfiguration = true
        outputDraftState.availableAlbums = projection.availableAlbums
        outputDraftState.selectedExistingAlbumIdentifier =
            projection.selectedExistingAlbumIdentifier
        outputDraftState.albumStatusMessage =
            projection.albumStatusMessage
        Task { @MainActor in
            await Task.yield()
            isApplyingSavedOutputConfiguration = false
        }
    }

    @MainActor
    private func optimizeSelectedLogo(
        _ item: PhotosPickerItem
    ) async {
        let request = LogoAssetOptimizationRequest(
            editingContext: currentLogoAssetEditingContext
        )
        rootPresentationState
            .mediaPickerPresentation
            .activeLogoOptimizationRequest = request
        rootPresentationState.mediaPickerPresentation.selectedLogoItem = nil
        applyLogoAssetUpdate(
            logoAssetCoordinator
                .beginOptimization()
        )

        let update =
            await logoAssetCoordinator
            .optimize(item)
        guard logoAssetCoordinator.shouldApplyCompletedOptimization(
            request,
            activeRequest:
                rootPresentationState
                    .mediaPickerPresentation
                    .activeLogoOptimizationRequest,
            currentContext: currentLogoAssetEditingContext
        ) else {
            discardUnappliedLogoAsset(update.customLogoBadge)
            if rootPresentationState
                .mediaPickerPresentation
                .activeLogoOptimizationRequest == request {
                rootPresentationState
                    .mediaPickerPresentation
                    .activeLogoOptimizationRequest = nil
                rootPresentationState.mediaPickerPresentation.isOptimizingLogo = false
            }
            return
        }
        rootPresentationState
            .mediaPickerPresentation
            .activeLogoOptimizationRequest = nil
        applyLogoAssetUpdate(update)
    }

    private var currentLogoAssetEditingContext:
        LogoAssetEditingContext {
        LogoAssetEditingContext(
            subjectID: session.state.selectedSubject?.id,
            configurationID: session.state.selectedMemoryPresetID
        )
    }

    private var logoModeSelectionBinding: Binding<V1LogoMode> {
        Binding(
            get: { logoMode },
            set: handleRequestedLogoMode
        )
    }

    private func handleRequestedLogoMode(
        _ requestedMode: V1LogoMode
    ) {
        let decision = logoAssetCoordinator.modeSelectionDecision(
            currentMode: logoMode,
            requestedMode: requestedMode
        )

        if decision.shouldCancelActiveOptimization {
            rootPresentationState.mediaPickerPresentation.selectedLogoItem = nil
            rootPresentationState.mediaPickerPresentation.isOptimizingLogo = false
            rootPresentationState
                .mediaPickerPresentation
                .activeLogoOptimizationRequest = nil
        }

        if decision.shouldPresentPhotoPicker {
            rootPresentationState
                .mediaPickerPresentation
                .isLogoPickerPresented = true
            return
        }

        guard let nextLogoMode = decision.nextLogoMode else {
            return
        }
        rootPresentationState
            .mediaPickerPresentation
            .isLogoPickerPresented = false
        logoMode = nextLogoMode
    }

    private func discardUnappliedLogoAsset(_ badge: Badge?) {
        guard let path = badge?.imagePath else { return }
        LogoAssetOptimizationService.discardUncommittedAsset(
            atPath: path
        )
    }

    private func applyLogoAssetUpdate(
        _ update: LogoAssetUpdate
    ) {
        rootPresentationState.mediaPickerPresentation.isOptimizingLogo =
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
        outputDraftState.shouldWritePhotosDescription =
            projection.shouldWritePhotosDescription
        outputDraftState.photosDescriptionOverride =
            projection.photosDescriptionOverride
        outputDraftState.outputTarget = projection.outputTarget
        outputDraftState.mediaOutputMode = projection.mediaOutputMode
        outputDraftState.selectedExistingAlbumIdentifier =
            projection.selectedAlbumIdentifier
        outputDraftState.configurationAlbumTitle = projection.albumTitle
        if projection.outputTarget == .newAlbum {
            outputDraftState.newAlbumName = projection.albumTitle.isEmpty
                ? PhotoMemoAlbumSelection.defaultAlbumTitle
                : projection.albumTitle
        }
        outputDraftState.livePhotoPolicy = projection.livePhotoPolicy
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
                timeDisplayConfiguration,
            language: session.language
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
                    shareDiagnosticEvents,
                language: .interfaceStored
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
            guard !success, let fallbackURL = URL(string: "photos://") else {
                if !success {
                    Task { @MainActor in
                        presentHomeConfigurationActionFeedback(
                            "暂时无法打开 Apple Photos，请稍后重试。"
                        )
                    }
                }
                return
            }

            UIApplication.shared.open(fallbackURL) { fallbackSuccess in
                guard !fallbackSuccess else { return }
                Task { @MainActor in
                    presentHomeConfigurationActionFeedback(
                        "暂时无法打开 Apple Photos，请稍后重试。"
                    )
                }
            }
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
        editorInteractionState.focusedEditorRegion =
            state.focusedRegion
        editorInteractionState.activeModuleRegion =
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
        let previousOutputTarget = outputDraftState.outputTarget
        let previousMediaOutputMode = outputDraftState.mediaOutputMode
        let previousLogoMode = logoMode
        let previousPresetTitleDraft =
            rootPresentationState.renamePresentation.titleDraft
        let subject = V1SubjectLibraryFactory
            .makeFirstRunSubject(
                name: subjectName,
                birthday: birthday
            )
        let anchorID = subject.activeTimeAnchorID
        let existingPreset = session.state.selectedMemoryPreset
            ?? session.state.memoryPresets.first
        let preset = MemoryPreset(
            title: MemoMarkLanguage.interfaceStored.localized(
                key: "welcome.default_preset.title",
                fallback: "生日回顾"
            ),
            summary: MemoMarkLanguage.interfaceStored.localized(
                key: "welcome.default_preset.summary",
                fallback: "以生日为时间起点，自然回顾照片拍摄时的年龄。"
            ),
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
        outputDraftState.outputTarget = .automatic
        outputDraftState.mediaOutputMode = .originalFormat
        logoMode = .appleMini
        rootPresentationState.renamePresentation.titleDraft = preset.title
        bootstrapDrafts()
        refreshDynamicPreview()

        guard await applyCurrentV1Configuration() else {
            session.state = previousState
            birthdayDate = previousBirthdayDate
            outputDraftState.outputTarget = previousOutputTarget
            outputDraftState.mediaOutputMode = previousMediaOutputMode
            logoMode = previousLogoMode
            rootPresentationState.renamePresentation.titleDraft =
                previousPresetTitleDraft
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
            rootPresentationState
                .mediaPickerPresentation
                .selectedProcessingItems = []
        }
        await performPhotoQuickAction(
            importItems: {
            await V1PhotoIntakeImporter.importItems(from: items)
            },
            requestedCount: items.count
        )
    }

    @MainActor
    private func importPickedPHPickerResults(
        _ results: [PHPickerResult]
    ) async {
        await performPhotoQuickAction(
            importItems: {
            await V1PhotoIntakeImporter.importPHPickerResults(from: results)
            },
            requestedCount: results.count
        )
    }

    @MainActor
    private func performPhotoQuickAction(
        importItems: @escaping () async -> [ExternalPhotoIntakeItem],
        requestedCount: Int
    ) async {
        let result = await V1PhotoProcessingQuickActionCoordinator
            .processPickedPhotoItems(
                saveCurrentConfiguration: applyCurrentV1Configuration,
                requestedCount: requestedCount,
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
            presentHomeConfigurationActionFeedback(
                MemoMarkLanguage.interfaceStored.localized(
                    key: "configuration.save_failed",
                    fallback: "当前配置没有保存成功，请稍后重试。"
                )
            )
            return
        case .noSupportedPhotos:
            presentHomeConfigurationActionFeedback(
                MemoMarkLanguage.interfaceStored.localized(
                    key: "photo.no_supported",
                    fallback: "没有找到可处理的照片，请确认照片已从 iCloud 下载完成。"
                )
            )
            break
        case .submitted:
            if result.failedCount > 0 {
                presentHomeConfigurationActionFeedback(
                    String(
                        format: MemoMarkLanguage.interfaceStored.localized(
                            key: "photo.submitted_format",
                            fallback: "已接收 %lld 张，另有 %lld 张无法读取，请确认原图已下载完成。"
                        ),
                        locale: MemoMarkLanguage.interfaceStored.locale,
                        result.submittedItems.count,
                        result.failedCount
                    ),
                    isBlocking: false
                )
            }
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
        commerceStore: runtime.commerceStore,
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
