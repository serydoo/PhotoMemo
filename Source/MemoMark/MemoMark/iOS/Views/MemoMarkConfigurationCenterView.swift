#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI
import PhotosUI
import UIKit

struct MemoMarkConfigurationCenterView: View {
    /// Process-scoped capabilities are injected from the app composition
    /// root; they never become part of Configuration Center persistence.
    let runtimeEnvironment:
        MemoMarkRuntimeEnvironment

    @Environment(\.accessibilityReduceTransparency)
    var reduceTransparency

    @Environment(\.scenePhase)
    private var scenePhase

    @Environment(\.horizontalSizeClass)
    var horizontalSizeClass

    @Environment(\.verticalSizeClass)
    var verticalSizeClass

    @ObservedObject
    var backgroundStatusService:
        MemoMarkBackgroundStatusService

    @ObservedObject
    var commerceStore:
        MemoMarkCommerceStore

    let refreshExternalIntake:
        () -> Void

    let previewCoordinator:
        PreviewCoordinator?

    private let exportCoordinator:
        ExportCoordinator?

    let loadPhotoLibraryAlbums:
        LoadPhotoLibraryAlbumsTransaction

    private let loadConfigurationBootstrap:
        LoadConfigurationBootstrapTransaction

    let saveConfiguration: SaveConfigurationTransaction
    let loadProductionConfigurationSnapshot: LoadProductionConfigurationSnapshotTransaction

    let queueCoordinator:
        QueueCoordinator?

    let configurationCoordinator:
        ConfigurationCoordinator?

    let diagnosticsRepository:
        DiagnosticsRepository?

    let productionDiagnosticsRepository:
        ProductionDiagnosticsRepository?

    let notificationDeepLink:
        MemoMarkDeepLink?

    let onNotificationDeepLinkHandled:
        () -> Void

    let localConfigurationLibraryCoordinator:
        LocalConfigurationLibraryCoordinator

    let externalIntakeCenter:
        ExternalPhotoIntakeCenter

    @StateObject
    var session = ConfigurationSession()

    @State
    var editorDraftState = ConfigurationEditorDraftState()

    @State
    var editorInteractionState =
        MemoryCardEditorInteractionState()

    @State
    var entryNavigationState =
        EntryNavigationState()

    @State
    var rootPresentationState =
        RootPresentationState()

    @State
    private var rootConfigurationProjectionState =
        RootConfigurationProjectionState()

    var logoMode: ConfigurationLogoMode {
        get { rootConfigurationProjectionState.logoMode }
        nonmutating set {
            rootConfigurationProjectionState.logoMode = newValue
        }
    }

    var presentationStyle: RecordCardPresentationStyle {
        get { rootConfigurationProjectionState.presentationStyle }
        nonmutating set {
            rootConfigurationProjectionState.presentationStyle = newValue
        }
    }

    var presentationStyleBinding:
        Binding<RecordCardPresentationStyle> {
        Binding(
            get: { presentationStyle },
            set: { switchPresentationStyle(to: $0) }
        )
    }

    private func switchPresentationStyle(
        to newStyle: RecordCardPresentationStyle
    ) {
        guard newStyle != presentationStyle else {
            return
        }

        // Commit the active editor buffer before changing the route. The
        // editor is one live view, but its content belongs to a style-specific
        // configuration and must never be overwritten by another style.
        editorDraftState.commitActive(for: presentationStyle)
        presentationStyle = newStyle
        editorDraftState.activate(
            newStyle,
            fallback: defaultRegionDrafts()
        )
        editorInteractionState.activeTextItemIDs = [:]
        editorInteractionState.clearInsertionContext()
        refreshDynamicPreview()
    }

    private func defaultRegionDrafts() ->
        [CardRegion: MemoryCardEditorDraft] {
        Dictionary(
            uniqueKeysWithValues:
                CardRegion.memoryCardRegions.map { region in
                    (region, makeDefaultDraft(for: region))
                }
        )
    }

    var regionDraftsForSaving:
        [RecordCardPresentationStyle: [CardRegion: MemoryCardEditorDraft]] {
        editorDraftState.draftsForSaving
    }

    var regionDrafts: [CardRegion: MemoryCardEditorDraft] {
        editorDraftState.active
    }

    private var regionDraftsByPresentationStyle:
        [RecordCardPresentationStyle: [CardRegion: MemoryCardEditorDraft]] {
        editorDraftState.byPresentationStyle
    }

    var customLogoBadge: Badge? {
        get { rootConfigurationProjectionState.customLogoBadge }
        nonmutating set {
            rootConfigurationProjectionState.customLogoBadge = newValue
        }
    }

    var birthdayDate: Date {
        get { rootConfigurationProjectionState.birthdayDate }
        nonmutating set {
            rootConfigurationProjectionState.birthdayDate = newValue
        }
    }

    var locationDisplayConfiguration:
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

    var timeDisplayConfiguration:
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
    var outputDraftState =
        OutputDraftState()

    @State
    private var rootLifecycleState =
        RootLifecycleState()

    @State
    var subjectPersistenceRuntimeCoordinator:
        SubjectPersistenceTransactionScheduler

    @State
    var photoIntakeRuntimeCoordinator =
        PhotoIntakeRuntimeCoordinator()

    @State
    var logoAssetRuntimeCoordinator =
        LogoAssetRuntimeCoordinator()

    @State
    var outputAlbumRuntimeCoordinator =
        OutputAlbumRuntimeCoordinator()

    var isSavingConfiguration: Bool {
        get { rootLifecycleState.isSavingConfiguration }
        nonmutating set {
            rootLifecycleState.isSavingConfiguration = newValue
        }
    }

    var didBootstrap: Bool {
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

    var isApplyingSavedOutputConfiguration: Bool {
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
        BirthdayDateChangeBehavior {
        get { rootLifecycleState.birthdayDateChangeBehavior }
        nonmutating set {
            rootLifecycleState.birthdayDateChangeBehavior = newValue
        }
    }

    var shouldSaveSubjectLibrary: Bool {
        get { rootLifecycleState.shouldSaveSubjectLibrary }
        nonmutating set {
            rootLifecycleState.shouldSaveSubjectLibrary = newValue
        }
    }

    var isPersistingSubjectChanges: Bool {
        get { rootLifecycleState.isPersistingSubjectChanges }
        nonmutating set {
            rootLifecycleState.isPersistingSubjectChanges = newValue
        }
    }

    var activeConfigurationStatus:
        ConfigurationPersistenceStatus {
        get { rootLifecycleState.activeConfigurationStatus }
        nonmutating set {
            rootLifecycleState.activeConfigurationStatus = newValue
        }
    }

    @State
    var shareDiagnosticEvents:
        [MemoMarkShareDiagnosticEvent] = []

    @State
    var processingDiagnosticsSnapshot =
        MemoMarkiOSProcessingDiagnosticsSnapshot()

    @FocusState
    var memoryPresetTitleFieldFocused: Bool

    @AppStorage("photomemo.v1.moduleUsageCounts")
    var moduleUsageCountsStorage = "{}"

    @AppStorage("photomemo.v1.welcomeSeen")
    var hasSeenWelcome = false

    var currentBorderStyleName: String {
        switch presentationStyle {
        case .classicWhite:
            TemplatePreset.classicWhite.displayName(
                for: .interfaceStored
            )
        case .minimal:
            MemoMarkLanguage.interfaceStored.localized(
                key: "极简",
                fallback: "极简"
            )
        }
    }

    var currentBorderStyleDescription: String {
        switch presentationStyle {
        case .classicWhite:
            MemoMarkLanguage.interfaceStored.localized(
                key: "四处内容，适合完整记录照片信息。",
                fallback: "四处内容，适合完整记录照片信息。"
            )
        case .minimal:
            MemoMarkLanguage.interfaceStored.localized(
                key: "一处组合内容，安静地补充这张照片的时间答案。",
                fallback: "一处组合内容，安静地补充这张照片的时间答案。"
            )
        }
    }

    let previewCompositionEngine =
        MemoryCardPreviewCompositionEngine()

    var bootstrapFlowCoordinator:
        ConfigurationBootstrapFlowCoordinator {
        ConfigurationBootstrapFlowCoordinator(
            configurationBootstrapCoordinator:
                ConfigurationBootstrapCoordinator(
                    loadTransaction:
                        loadConfigurationBootstrap
                ),
            session: session,
                engine: previewCompositionEngine
        )
    }

    var bootstrapRuntimeCoordinator:
        ConfigurationBootstrapRuntimeCoordinator {
        ConfigurationBootstrapRuntimeCoordinator(
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

                editorDraftState.replace(
                    active: projection.regionDrafts,
                    byPresentationStyle: [
                        presentationStyle: projection.regionDrafts
                    ],
                    activeStyle: presentationStyle
                )
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
        dependencies: MemoMarkConfigurationCenterDependencies
    ) {
        runtimeEnvironment = dependencies.runtimeEnvironment
        self._backgroundStatusService =
            ObservedObject(
                wrappedValue:
                    dependencies.backgroundStatusService
            )
        self._commerceStore =
            ObservedObject(
                wrappedValue:
                    dependencies.commerceStore
            )
        self.refreshExternalIntake =
            dependencies.refreshExternalIntake
        self.previewCoordinator =
            dependencies.previewCoordinator
        self.exportCoordinator =
            dependencies.exportCoordinator
        self.loadPhotoLibraryAlbums =
            dependencies.loadPhotoLibraryAlbums
        self.loadConfigurationBootstrap =
            dependencies.loadConfigurationBootstrap
        self.saveConfiguration =
            dependencies.saveConfiguration
        self.loadProductionConfigurationSnapshot =
            dependencies.loadProductionConfigurationSnapshot
        self.queueCoordinator =
            dependencies.queueCoordinator
        self.configurationCoordinator =
            dependencies.configurationCoordinator
        self._subjectPersistenceRuntimeCoordinator = State(
            initialValue:
                SubjectPersistenceTransactionScheduler {
                    candidate in
                    guard let configurationCoordinator =
                        dependencies.configurationCoordinator else {
                        throw MemoMarkError(
                            code: .invalidState,
                            message:
                                "Configuration persistence is unavailable."
                        )
                    }
                    return try await configurationCoordinator
                        .saveConfigurationLibrary(candidate)
                }
        )
        self._rootConfigurationProjectionState = State(
            initialValue:
            RootConfigurationProjectionState(
                    timeDisplayConfiguration:
                        dependencies.configurationCoordinator?
                        .loadTimeDisplayConfiguration()
                )
        )
        self.externalIntakeCenter =
            dependencies.externalIntakeCenter
        self.diagnosticsRepository =
            dependencies.diagnosticsRepository
        self.productionDiagnosticsRepository =
            dependencies.productionDiagnosticsRepository
        self.notificationDeepLink = dependencies.notificationDeepLink
        self.onNotificationDeepLinkHandled =
            dependencies.onNotificationDeepLinkHandled
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

    var entryFlowState: EntryFlowState {
        get { entryNavigationState.flowState }
        nonmutating set { entryNavigationState.flowState = newValue }
    }

    func entryBinding<Value>(
        _ keyPath: WritableKeyPath<EntryFlowState, Value>
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
        .accessibilityIdentifier("configuration-center-root")
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
            LocalConfigurationLibraryPresentationModifier(
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
            WelcomeAndSettingsPresentationModifier(
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
            WelcomePageSurface(
                presentation:
                    WelcomePresentation.localized(
                        for: .interfaceStored
                    ),
                language: .interfaceStored,
                onStart: {
                    rootPresentationState.showsWelcomeInformation = false
                },
                onShowWorkflow: {
                    rootPresentationState.showsWelcomeInformation = false
                    entryFlowState =
                        EntryFlowCoordinator
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
            MemoryCardEditorPresentationModifier(
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
                onDismissEditor:
                    resetCardEditorState
            )
        )
        .modifier(
            SubjectPresentationModifier(
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
            RootChangeObservationModifier(
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
                configurationDisclosureState:
                    $rootPresentationState.configurationDisclosureState,
                mediaPickerPresentation:
                    $rootPresentationState.mediaPickerPresentation,
                logoMode:
                    $rootConfigurationProjectionState.logoMode,
                presentationStyle:
                    $rootConfigurationProjectionState.presentationStyle,
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
                resetLogoSelectionPresentation:
                    resetLogoSelectionPresentation,
                optimizeSelectedLogo: optimizeSelectedLogo,
                importPickedPhotos: importPickedPhotos,
                importPickerResults: importPickedPHPickerResults
            )
        )
    }

}

#endif
