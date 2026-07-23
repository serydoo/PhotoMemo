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
    private var selectedProcessingItems: [PhotosPickerItem] = []

    @State
    private var logoMode: V1LogoMode = .appleMini

    @State
    private var selectedLogoItem: PhotosPickerItem?

    @State
    private var customLogoBadge: Badge?

    @State
    private var isOptimizingLogo = false

    @State
    private var logoStatusMessage =
        "建议选择 2048 × 2048 的透明 PNG。"

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
    private var isEditingMemoryPresetTitle = false

    @State
    private var showsRegionContentSheet = false

    @State
    private var memoryPresetTitleDraft = ""

    @State
    private var showsConfigurationRequiredAlert = false

    @State
    private var showsLocalConfigurationLibrary = false

    @State
    private var localConfigurationBackups:
        [LocalConfigurationBackupRecord] = []

    @State
    private var localConfigurationLibraryStatus: String?

    @State
    private var isWorkingWithLocalConfigurationLibrary = false

    @State
    private var showsHomeConfigurationActionFeedback = false

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

    private var configurationBackupRestoreCoordinator:
        ConfigurationBackupRestoreCoordinator {
        ConfigurationBackupRestoreCoordinator(
            localConfigurationLibraryCoordinator:
                localConfigurationLibraryCoordinator,
            configurationCoordinator:
                configurationCoordinator
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

                if let logoStatusMessage =
                    projection.logoStatusMessage {
                    self.logoStatusMessage =
                        logoStatusMessage
                }

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
                        memoryPresets.isEmpty
                        ? nil
                        : memoryPresets,
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
        .preferredColorScheme(.light)
        .alert(
            "配置操作",
            isPresented: $showsHomeConfigurationActionFeedback
        ) {
            Button("知道了", role: .cancel) {}
        } message: {
            Text(localConfigurationLibraryStatus ?? "操作已完成。")
        }
        .task {
            await loadAlbumOptions()
        }
        .sheet(
            isPresented: $showsLocalConfigurationLibrary
        ) {
            V1LocalConfigurationLibrarySheet(
                subjectName:
                    session.state.selectedSubject?
                    .identity.displayName
                    ?? "当前记忆对象",
                backups: localConfigurationBackups,
                isWorking:
                    isWorkingWithLocalConfigurationLibrary,
                statusMessage:
                    localConfigurationLibraryStatus,
                onRefresh: {
                    refreshLocalConfigurationLibrary()
                },
                onRestore: { backup in
                    restoreLocalConfigurationBackup(
                        backup,
                        makeCurrent: false
                    )
                },
                onRestoreAndMakeCurrent: { backup in
                    restoreLocalConfigurationBackup(
                        backup,
                        makeCurrent: true
                    )
                },
                onDelete: deleteLocalConfigurationBackup
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(
            isPresented: entryBinding(\.showsWelcomePage)
        ) {
            V1FirstRunConfigurationSheet(
                onSave: initializeFirstConfiguration,
                onDefer: completeWelcomeFlow
            )
            .interactiveDismissDisabled(!hasSeenWelcome)
        }
        .sheet(
            isPresented: entryBinding(\.showsWorkflowGuide)
        ) {
            V1WorkflowGuideSurface(
                steps: V1WelcomePresentation.default.workflowSteps
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(
            isPresented: entryBinding(\.showsSettingsPage)
        ) {
            NavigationStack {
                settingsPage
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("完成") {
                            entryFlowState =
                                V1EntryFlowCoordinator
                                .closeSettingsPage(
                                    from: entryFlowState
                                )
                        }
                        .font(.caption.weight(.semibold))
                    }
                }
            }
        }
        .sheet(
            isPresented: moduleSheetPresented
        ) {
            if let region = activeModuleRegion {
                V1ModuleLibrarySurface(
                    region: region,
                    modules: modules(for: region),
                    categoryTitle: moduleCategoryTitle,
                    valueText: moduleDisplayText,
                    onSelectModule: { module in
                        applyModulePanelState(
                            V1ModulePanelCoordinator
                                .selectModule(
                                    module,
                                    state:
                                        modulePanelState
                                )
                        )
                        insert(module, into: region)
                    },
                    onClose: {
                        applyModulePanelState(
                            V1ModulePanelCoordinator
                                .setSheetPresented(
                                    false,
                                    state:
                                        modulePanelState
                                )
                        )
                    }
                )
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
        .sheet(
            isPresented: $showsRegionContentSheet
        ) {
            NavigationStack {
                ScrollView {
                    editorCluster
                        .padding(.top, 16)
                        .padding(.bottom, 28)
                        .v1AdaptiveScrollContent(
                            horizontalPadding: ConfigurationUI.contentColumnPadding
                        )
                }
                .scrollDismissesKeyboard(.interactively)
                .simultaneousGesture(
                    TapGesture()
                        .onEnded {
                            dismissKeyboard()
                        }
                )
                .background(
                    ConfigurationUI.appBackground
                        .ignoresSafeArea()
                )
                .navigationTitle("区域内容设置")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("完成") {
                            dismissKeyboard()
                            showsRegionContentSheet = false
                        }
                    }

                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()

                        Button {
                            dismissKeyboard()
                        } label: {
                            Image(
                                systemName:
                                    "keyboard.chevron.compact.down"
                            )
                        }
                        .accessibilityLabel("收起键盘")
                    }
                }
            }
            .presentationDetents([
                .fraction(0.58),
                .large
            ])
            .presentationDragIndicator(.visible)
            .presentationBackgroundInteraction(
                .enabled(upThrough: .fraction(0.58))
            )
        }
        .sheet(
            isPresented: entryBinding(\.showsSubjectOverview)
        ) {
            V1IOSSubjectOverviewSheet(
                presentation:
                    subjectOverviewPresentation,
                subjects: session.state.subjects,
                subject:
                    session.state.selectedSubject,
                session: session,
                selectedSubjectID:
                    session.state.selectedSubjectID,
                onSelectSubject: {
                    subjectID in
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
                },
                onAddSubject: {
                    let patch =
                        V1SubjectOverviewActionCoordinator
                        .addDefaultSubject(
                            referenceDate:
                                birthdayDate,
                            to: session,
                            shouldSaveSubjectLibrary:
                                shouldSaveSubjectLibrary,
                            configurationCoordinator:
                                configurationCoordinator,
                            onPersistedSubject: {
                                patch in
                                applySubjectFlowPatch(
                                    patch
                                )
                            }
                        )
                    applySubjectFlowPatch(patch)
                },
                onDeleteCurrentSubject: {
                    guard let patch =
                        V1SubjectOverviewActionCoordinator
                        .deleteCurrentSubject(
                            from: session,
                            shouldSaveSubjectLibrary:
                                shouldSaveSubjectLibrary,
                            configurationCoordinator:
                                configurationCoordinator
                        ) else {
                        return
                    }

                    applySubjectFlowPatch(patch)
                },
                onPersistSubjectChanges: persistCurrentSubjectChanges
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(
            item: entryBinding(\.subjectConfigurationFlowState)
        ) { flowState in
            V1IOSSubjectConfigurationFlow(
                flowState: flowState,
                onClose: {
                    entryFlowState =
                        V1EntryFlowCoordinator
                        .closeSubjectConfiguration(
                            from:
                                entryFlowState
                        )
                }
            )
        }
        .alert(
            "请先完成配置",
            isPresented:
                $showsConfigurationRequiredAlert
        ) {
            Button("去配置中心") {
                entryFlowState =
                    V1EntryFlowCoordinator
                    .openEditorTab(
                        from: entryFlowState
                    )
            }
            Button("稍后", role: .cancel) {}
        } message: {
            Text("首次处理前，请先在配置中心保存当前记忆对象的配置。输出部分默认会按系统推荐走；如果你改了输出设置，保存后也会一并写回当前配置。")
        }
        .onAppear {
            bootstrapIfNeeded()
            refreshProcessingState()
        }
        .sheet(
            isPresented:
                entryBinding(\.showsProcessingPhotoPicker)
        ) {
            V1UIKitPhotoPicker(
                selectionLimit: 24,
                onCancel: {
                    entryNavigationState.flowState
                        .showsProcessingPhotoPicker = false
                },
                onSelect: { results in
                    entryNavigationState.flowState
                        .showsProcessingPhotoPicker = false

                    Task {
                        await importPickedPHPickerResults(
                            results
                        )
                    }
                }
            )
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else {
                return
            }

            refreshProcessingState()

            Task {
                await loadAlbumOptions()
            }
        }
        .onChange(of: entryFlowState.selectedTab) { _, newTab in
            guard newTab == .output else {
                return
            }

            Task {
                await loadAlbumOptions()
            }
        }
        .onChange(of: horizontalSizeClass) { _, newSizeClass in
            guard newSizeClass == .compact else {
                return
            }

            entryFlowState =
                V1EntryFlowCoordinator
                .prepareForCompactPresentation(
                    from: entryFlowState
                )
        }
        .onChange(of: session.state.selectedMemoryPresetID) { _, _ in
            isEditingMemoryPresetTitle = false
            memoryPresetTitleFieldFocused = false
            if let selectedConfiguration =
                session.selectedMemoryConfiguration {
                applyConfigurationDraftProjection(
                    V1ConfigurationDraftProjection(
                        configuration:
                            selectedConfiguration
                    )
                )
            } else if let selectedPreset =
                session.state.selectedMemoryPreset {
                logoMode = selectedPreset.logoMode
                applySavedOutputConfiguration(
                    selectedPreset
                )
            }
            bootstrapDrafts()
        }
        .onChange(of: birthdayDate) { _, _ in
            let effect =
                V1SubjectSelectionMutationCoordinator
                .effect(
                    for:
                        birthdayDateChangeBehavior
                )

            birthdayDateChangeBehavior =
                .userInitiated

            if effect.shouldRefreshPreview {
                refreshDynamicPreview()
            }

            if effect.shouldMarkDirty {
                activeConfigurationStatus = .dirty
            }
        }
        .onChange(of: session.state.selectedSubject) { _, subject in
            memorySourceDisclosureState.synchronize(
                selectedSubjectID: subject?.id
            )
            let decision =
                V1SubjectSelectionMutationCoordinator
                .decision(
                    subjectAnchorDate:
                        subject?.primaryTimeAnchor?.date
                        ?? subject?.timeAnchors.first?.date,
                    currentBirthdayDate:
                        birthdayDate,
                    isApplyingBootstrapState:
                        isApplyingBootstrapState
                )

            if let nextBirthdayDateBehavior =
                decision.nextBirthdayDateBehavior {
                birthdayDateChangeBehavior =
                    nextBirthdayDateBehavior
            }

            if let updatedBirthdayDate =
                decision.updatedBirthdayDate {
                birthdayDate =
                    updatedBirthdayDate
            }

            if decision.shouldRefreshPreview {
                refreshDynamicPreview()
            }

            if decision.shouldMarkDirty {
                activeConfigurationStatus = .dirty
            }
        }
        .onChange(of: selectedLogoItem) { _, item in
            guard let item else {
                return
            }

            Task {
                await optimizeSelectedLogo(item)
            }
        }
        .onChange(of: logoMode) { _, newMode in
            guard
                session.state
                .selectedMemoryPreset?
                .logoMode != newMode
            else {
                return
            }

            activeConfigurationStatus = .dirty
        }
        .onChange(of: outputTarget) { _, _ in
            guard
                !isApplyingBootstrapState,
                !isApplyingSavedOutputConfiguration
            else {
                return
            }
            activeConfigurationStatus = .dirty

            if outputTarget == .existingAlbum {
                Task {
                    await loadAlbumOptions()
                }
            }
        }
        .onChange(of: mediaOutputMode) { _, _ in
            guard
                !isApplyingBootstrapState,
                !isApplyingSavedOutputConfiguration
            else {
                return
            }
            activeConfigurationStatus = .dirty
        }
        .onChange(of: selectedExistingAlbumIdentifier) { _, _ in
            guard
                !isApplyingBootstrapState,
                !isApplyingSavedOutputConfiguration
            else {
                return
            }
            activeConfigurationStatus = .dirty
        }
        .onChange(of: newAlbumName) { _, _ in
            guard
                !isApplyingBootstrapState,
                !isApplyingSavedOutputConfiguration
            else {
                return
            }
            activeConfigurationStatus = .dirty
        }
        .onChange(of: selectedProcessingItems) { _, items in
            guard !items.isEmpty else {
                return
            }

            Task {
                await importPickedPhotos(items)
            }
        }
    }

    @ViewBuilder
    private var rootNavigation: some View {
        if usesSidebarNavigation {
            regularNavigation
        } else {
            compactNavigation
        }
    }

    private var compactNavigation: some View {
        NavigationStack {
            TabView(selection: entryBinding(\.selectedTab)) {
                homePage
                    .tabItem {
                        Label("首页", systemImage: MemoMarkSymbol.home.name)
                    }
                    .tag(V1EntryTab.home)

                editorPage
                    .tabItem {
                        Label(
                            "配置中心",
                            systemImage: MemoMarkSymbol.configurationCenter.name
                        )
                    }
                    .tag(V1EntryTab.editor)

                outputPage
                    .tabItem {
                        Label("输出", systemImage: MemoMarkSymbol.output.name)
                    }
                    .tag(V1EntryTab.output)

                tasksPage
                    .tabItem {
                        Label("任务", systemImage: MemoMarkSymbol.task.name)
                    }
                    .tag(V1EntryTab.tasks)
            }
        }
    }

    private var regularNavigation: some View {
        HStack(spacing: 0) {
            V1EntrySidebar(
                selection: entryBinding(\.selectedTab)
            )
            .frame(width: 220)

            Rectangle()
                .fill(ConfigurationUI.faintHairline)
                .frame(width: 0.5)

            NavigationStack {
                regularDestination
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )
        }
        .background(
            ConfigurationUI.appBackground
                .ignoresSafeArea()
        )
    }

    @ViewBuilder
    private var regularDestination: some View {
        switch entryFlowState.selectedTab {
        case .home:
            homePage
        case .editor:
            editorPage
        case .output:
            outputPage
        case .tasks:
            tasksPage
        case .settings:
            settingsPage
        }
    }

    private var settingsPage: some View {
        V1SettingsPageSurface(
            onShowWelcome: {
                entryFlowState =
                    V1EntryFlowCoordinator
                    .closeSettingsPage(
                        from: entryFlowState
                    )
                entryFlowState =
                    V1EntryFlowCoordinator
                    .showWelcomePage(
                        from: entryFlowState
                    )
            },
            onShowWorkflow: {
                entryFlowState =
                    V1EntryFlowCoordinator
                    .closeSettingsPage(
                        from: entryFlowState
                    )
                entryFlowState.showsWorkflowGuide = true
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
            completedPhotoCount:
                backgroundStatusService
                .taskOverview
                .completedPhotoCount,
            borderStyleName: currentBorderStyleName,
            borderStyleDescription: currentBorderStyleDescription,
            memoryPresets: homeAvailablePresets,
            selectedMemoryPresetID:
                session.state.selectedMemoryPreset?.id,
            isEditingMemoryPresetTitle: isEditingMemoryPresetTitle,
            memoryPresetTitleDraft: $memoryPresetTitleDraft,
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
            onCommitMemoryPresetTitle: commitMemoryPresetTitle,
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
        V1EditorPageSurface(
            previewPinProgress: previewPinProgress,
            editorRevealProgress: editorRevealProgress,
            pageTitle: "配置中心",
            pageSubtitle:
                "当前配置：\(session.currentMemoryPresetTitle)",
            onDismissKeyboard: dismissKeyboard
        ) {
            previewSection
                .background(
                    offsetReader(
                        for: .preview
                    )
                )
        } editorContent: {
            configurationOptionList
        } accessoryContent: {
            EmptyView()
        }
        .navigationTitle("")
        .toolbar(.hidden, for: .navigationBar)
    }

    private var configurationOptionList: some View {
        let locationPresentation =
            LocationDisplayInspectorPresenter.presentation
        let selectedLocationValue =
            ConfigurationCenterLocationDisplaySupport
            .summaryValue(
                module: locationDisplayModule,
                presentation: locationPresentation,
                selectedConfiguration:
                    locationDisplayConfiguration
            )

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
            selectedLogoItem: $selectedLogoItem,
            logoValue: logoMode.title,
            logoDetail: logoRowDetail,
            customLogoImagePath:
                customLogoBadge?.imagePath,
            isOptimizingLogo: isOptimizingLogo,
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
            selectedLocationValue:
                selectedLocationValue,
            selectedLocationOptionID:
                locationDisplayOptionBinding,
            isLocationSelectable:
                locationDisplayModule != nil,
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
            isSavingConfiguration:
                isSavingConfiguration,
            onOpenRegionContent: {
                showsRegionContentSheet = true
            },
            onSaveCurrentConfiguration:
                {
                    performConfigurationLibraryAction(.saveCurrent)
                },
            onCreateConfiguration: {
                performConfigurationLibraryAction(.create)
            },
            onResetConfiguration: {
                performConfigurationLibraryAction(.reset)
            },
            onDeleteConfiguration: {
                guard let selectedPreset =
                    session.state.selectedMemoryPreset else {
                    return
                }
                deleteHomePreset(selectedPreset)
            }
        )
    }

    private var configurationCenterIntroSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                RoundedRectangle(
                    cornerRadius: 14,
                    style: .continuous
                )
                .fill(Color.accentColor.opacity(0.11))
                .frame(width: 42, height: 42)
                .overlay {
                    Image(systemName: "rectangle.3.group.bubble.left")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("配置中心")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)

                    Text("这里负责把当前记忆对象、时间锚点、显示方式和四个区域整理成一套可保存的当前配置。对象资料继续在对象页维护，配置页只负责选择与生效。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
            .fill(Color.white.opacity(0.92))
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
            .stroke(ConfigurationUI.faintHairline)
        )
    }

    private var configurationSummarySection: some View {
        let presentation =
            LocationDisplayInspectorPresenter.presentation
        let selectedLocationValue =
            ConfigurationCenterLocationDisplaySupport
            .summaryValue(
                module: locationDisplayModule,
                presentation: presentation,
                selectedConfiguration:
                    locationDisplayConfiguration
            )

        return ConfigurationCenterSummarySection(
            subject:
                session.state.selectedSubject,
            selectedRegion:
                session.state.selectedRegion,
            currentBorderStyleName:
                currentBorderStyleName,
            locationPresentation:
                presentation,
            selectedLocationValue:
                selectedLocationValue,
            locationDetail:
                ConfigurationCenterLocationDisplaySupport
                .summaryDetail(
                    module: locationDisplayModule,
                    selectedValue: selectedLocationValue
                ),
            selectedLocationOptionID:
                locationDisplayOptionBinding,
            selectedMemoryDisplayStyle:
                selectedMemoryDisplayStyleBinding,
            availableMemoryDisplayStyles:
                ConfigurationCenterMemoryDisplaySupport
                .availableStyles(
                    subject: session.state.selectedSubject
                ),
            availableTimeAnchors:
                session.availableTimeAnchors,
            selectedTimeAnchorID:
                selectedTimeAnchorBinding,
            onOpenSubject: {
                entryFlowState =
                    V1EntryFlowCoordinator
                    .openSubjectOverview(
                        from: entryFlowState
                    )
            },
            onSelectRegion: selectConfigurationSummaryRegion
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
            onStartProcessing: {
                beginPhotoProcessingFlow()
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

    private var presetOperationsMenu: some View {
        V1PresetOperationsMenu(
            onRename: beginEditingMemoryPresetTitle,
            onRestoreDefaults: {
                performConfigurationLibraryAction(.reset)
            }
        )
    }

    private var homePresetSummaryProjection:
        V1IOSHomePresetSummaryProjection {

        guard !homeAvailablePresets.isEmpty else {
            return V1IOSHomeProjection
                .emptyPresetSummary(
                    configurationLabel:
                        session.currentConfigurationLabel
                )
        }

        return V1IOSHomeProjection
            .presetSummary(
                presetTitle:
                    session.currentMemoryPresetTitle,
                configurationLabel:
                    session.currentConfigurationLabel,
                presetSummary:
                    session.currentMemoryPresetSummary,
                activeConfigurationStatus:
                    activeConfigurationStatus,
                isApplied:
                    session.selectedMemoryPresetIsApplied
            )
    }

    private var homePresetSavedStatusText: String {
        V1IOSHomeProjection
            .savedStatusValue(
                savedAt:
                    session.state
                    .selectedMemoryPreset?
                    .savedAt
            )
    }

    private var currentPresetStatusTone:
        V1IOSHomeStatusBadge.Tone {

        guard !homeAvailablePresets.isEmpty else {
            return .neutral
        }

        if homePresetSummaryProjection
            .emphasizesAppliedState {
            return .accent
        }

        return activeConfigurationStatus.tone
    }

    private var subjectOverviewPresentation:
        V1IOSSubjectOverviewPresentation {

        V1IOSSubjectOverviewPresenter
            .presentation(
                subject:
                    session.state.selectedSubject,
                currentTimeAnchorTitle:
                    session.currentTimeAnchorTitle,
                currentTimeAnchorDescription:
                    session.currentTimeAnchorDescription
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
            .commitRename(title: memoryPresetTitleDraft)
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
        performConfigurationLibraryAction(.activate(preset))
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
        _ preset: MemoryPreset,
        mayApplyCurrentConfiguration: Bool = true
    ) async {
        let decision = configurationLibraryActions.decide(
            .delete(configurationDeletionRequest(for: preset))
        )
        switch decision {
        case .applyCurrentThenDelete:
            guard mayApplyCurrentConfiguration else {
                presentHomeConfigurationActionFeedback(
                    "删除配置失败，原配置仍然保留。"
                )
                return
            }
            guard await applyCurrentV1Configuration(),
                  activeConfigurationStatus == .saved else {
                presentHomeConfigurationActionFeedback(
                    "当前新增配置保存失败，未删除原配置。"
                )
                return
            }
            await deleteHomePresetNow(
                preset,
                mayApplyCurrentConfiguration: false
            )
        case .persistDeletion(let result):
            await persistConfigurationDeletion(result)
        case .unavailable(let message):
            presentHomeConfigurationActionFeedback(message)
        default:
            return
        }
    }

    @MainActor
    private func persistConfigurationDeletion(
        _ result: ConfigurationLibraryDeletionResult
    ) async {
        guard let configurationCoordinator else {
            presentHomeConfigurationActionFeedback(
                "当前配置库不可用，请稍后重试。"
            )
            return
        }
        isSavingConfiguration = true
        activeConfigurationStatus = .saving
        defer { isSavingConfiguration = false }
        do {
            let receipt = try await configurationCoordinator
                .saveConfigurationLibrary(result.candidate)
            let durableResult = result.reconcilingRevision(
                receipt.revision
            )
            session.restoreConfigurationLibrary(
                durableResult.candidate
            )
            memoryPresetTitleDraft = session.currentMemoryPresetTitle
            bootstrapDrafts()
            activeConfigurationStatus = .saved
            presentHomeConfigurationActionFeedback(
                "已删除“\(result.deletedPreset.title)”。本地备份仍会保留。"
            )
        } catch {
            activeConfigurationStatus = .dirty
            presentHomeConfigurationActionFeedback(
                "删除配置失败，原配置仍然保留。"
            )
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
            memoryPresetTitleDraft = session.currentMemoryPresetTitle
            isEditingMemoryPresetTitle = true
            activeConfigurationStatus = .dirty
        case .reset:
            session.resetSelectedMemoryPreset()
            bootstrapDrafts()
            activeConfigurationStatus = .dirty
        case .beginRename(let title):
            memoryPresetTitleDraft = title
            isEditingMemoryPresetTitle = true
        case .commitRename(let title):
            session.updateSelectedMemoryPresetTitle(title)
            activeConfigurationStatus = .dirty
            isEditingMemoryPresetTitle = false
            memoryPresetTitleFieldFocused = false
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
        guard session.state.selectedSubject != nil else {
            localConfigurationLibraryStatus =
                "请先选择一个记忆对象。"
            return
        }
        showsLocalConfigurationLibrary = true
        refreshLocalConfigurationLibrary()
    }

    private func backupHomePreset(
        _ preset: MemoryPreset
    ) {
        Task {
            await backupConfigurationToLocalLibrary(
                configurationID: preset.id
            )
        }
    }

    @MainActor
    private func backupConfigurationToLocalLibrary(
        configurationID: UUID
    ) async {
        guard !isWorkingWithLocalConfigurationLibrary,
              let aggregate = session.state.configurationLibrary,
              let subjectID = session.state.selectedSubject?.id,
              let subjectRecord = aggregate.subjects.first(
                  where: { $0.subject.id == subjectID }
              ) else {
            presentHomeConfigurationActionFeedback(
                "当前配置还没有可备份的持久化记录。"
            )
            return
        }

        guard let preset = homeAvailablePresets.first(
            where: { $0.id == configurationID }
        ) else {
            presentHomeConfigurationActionFeedback(
                "找不到这条配置的持久化版本。"
            )
            return
        }
        let action = configurationLibraryActions.decide(
            .saveToLocalLibrary(
                ConfigurationLibrarySaveRequest(
                    preset: preset,
                    selectedConfigurationID:
                        session.state.selectedMemoryPresetID,
                    isCurrentConfigurationDirty:
                        activeConfigurationStatus == .dirty,
                    isSavingConfiguration:
                        isSavingConfiguration,
                    durableConfigurationIDs:
                        subjectRecord.configurations.map(\.id)
                )
            )
        )
        if case .unavailable(let message) = action {
            presentHomeConfigurationActionFeedback(message)
            return
        }

        if case .applyCurrentThenSave = action,
           (!(await applyCurrentV1Configuration())
            || activeConfigurationStatus != .saved) {
            presentHomeConfigurationActionFeedback(
                "当前修改保存失败，未创建本地备份。"
            )
            return
        }

        isWorkingWithLocalConfigurationLibrary = true
        defer {
            isWorkingWithLocalConfigurationLibrary = false
        }

        guard let durableAggregate = session.state.configurationLibrary,
              let durableSubjectRecord = durableAggregate.subjects.first(
                  where: { $0.subject.id == subjectID }
              ),
              let configuration = durableSubjectRecord.configurations.first(
                  where: { $0.id == configurationID }
              ) else {
            presentHomeConfigurationActionFeedback(
                "保存后未找到对应的持久化配置。"
            )
            return
        }

        let result = await configurationBackupRestoreCoordinator
            .backup(
                ConfigurationBackupRequest(
                    subject: durableSubjectRecord.subject,
                    configuration: configuration,
                    sourceURLs:
                        ConfigurationBackupRestoreCoordinator
                        .assetURLs(
                            subject: durableSubjectRecord.subject,
                            configuration: configuration,
                            selectedConfigurationID:
                                session.state.selectedMemoryPresetID,
                            selectedCustomLogoPath:
                                customLogoBadge?.imagePath
                        ),
                    previousBackups:
                        localConfigurationBackups
                )
            )
        localConfigurationBackups = result.backups
        if case .replace(let message) = result.status {
            presentHomeConfigurationActionFeedback(message)
        }
    }

    private func presentHomeConfigurationActionFeedback(
        _ message: String
    ) {
        localConfigurationLibraryStatus = message
        showsHomeConfigurationActionFeedback = true
    }

    private func refreshLocalConfigurationLibrary() {
        guard let subjectID = session.state.selectedSubject?.id else {
            localConfigurationLibraryStatus =
                "请先选择一个记忆对象。"
            return
        }
        Task {
            await loadLocalConfigurationBackups(
                subjectID: subjectID
            )
        }
    }

    @MainActor
    private func loadLocalConfigurationBackups(
        subjectID: UUID
    ) async {
        guard !isWorkingWithLocalConfigurationLibrary else {
            return
        }
        isWorkingWithLocalConfigurationLibrary = true
        defer {
            isWorkingWithLocalConfigurationLibrary = false
        }
        let result = await configurationBackupRestoreCoordinator
            .listBackups(
                ConfigurationBackupListRequest(
                    subjectID: subjectID,
                    previousBackups:
                        localConfigurationBackups
                )
            )
        localConfigurationBackups = result.backups
        if case .replace(let message) = result.status {
            localConfigurationLibraryStatus = message
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
            await importConfigurationBackupNow(
                at: url,
                assetRootURL: assetRootURL,
                makeCurrent: makeCurrent
            )
        }
    }

    @MainActor
    private func importConfigurationBackupNow(
        at url: URL,
        assetRootURL: URL,
        makeCurrent: Bool
    ) async {
        guard !isWorkingWithLocalConfigurationLibrary,
              let aggregate = session.state.configurationLibrary else {
            localConfigurationLibraryStatus =
                "当前配置库不可用，无法恢复。"
            return
        }

        isWorkingWithLocalConfigurationLibrary = true
        defer {
            isWorkingWithLocalConfigurationLibrary = false
        }

        let result = await configurationBackupRestoreCoordinator
            .restore(
                ConfigurationRestoreRequest(
                    fileURL: url,
                    assetRootURL: assetRootURL,
                    makeCurrent: makeCurrent,
                    aggregate: aggregate,
                    availableAlbumIdentifiers: Set(
                        availableAlbums.compactMap(\.localIdentifier)
                    ),
                    currentSubjectID:
                        session.state.selectedSubject?.id,
                    previousBackups:
                        localConfigurationBackups
                )
            )
        if let durableAggregate = result.aggregate {
            session.restoreConfigurationLibrary(
                durableAggregate
            )
            if result.shouldApplyCurrentConfiguration {
                applyRestoredCurrentConfiguration()
            }
        }
        localConfigurationBackups = result.backups
        if case .replace(let message) = result.status {
            localConfigurationLibraryStatus = message
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
        memoryPresetTitleDraft = configuration.title
        bootstrapDrafts()
        refreshDynamicPreview()
        activeConfigurationStatus = .saved
    }

    private func deleteLocalConfigurationBackup(
        _ backup: LocalConfigurationBackupRecord
    ) {
        Task {
            guard !isWorkingWithLocalConfigurationLibrary else {
                return
            }
            isWorkingWithLocalConfigurationLibrary = true
            defer {
                isWorkingWithLocalConfigurationLibrary = false
            }
            let result = await configurationBackupRestoreCoordinator
                .deleteBackup(
                    ConfigurationBackupDeletionRequest(
                        backup: backup,
                        previousBackups:
                            localConfigurationBackups
                    )
                )
            localConfigurationBackups = result.backups
            if case .replace(let message) = result.status {
                localConfigurationLibraryStatus = message
            }
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
              let configurationCoordinator else {
            return
        }
        let expectedRevision = candidate.revision
        let expectedSubjectID = candidate.activeSubjectID
        let expectedConfigurationID = candidate.activeConfigurationID

        Task { @MainActor in
            do {
                let receipt = try await configurationCoordinator
                    .saveConfigurationLibrary(candidate)
                guard var current = session.state.configurationLibrary,
                      current.revision == expectedRevision,
                      current.activeSubjectID == expectedSubjectID,
                      current.activeConfigurationID
                        == expectedConfigurationID else {
                    return
                }
                current.revision = receipt.revision
                session.updateConfigurationLibraryReference(current)
            } catch {
                activeConfigurationStatus = .failure(
                    message: "当前配置切换保存失败，请重试。"
                )
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
        IOSCompactEntryListGroup {
            ForEach(CardRegion.memoryCardRegions, id: \.self) { region in
                V1RegionEditorCard(
                    region: region,
                    isExpanded:
                        expansionBinding(
                            for: .region(region)
                        ),
                    showsDivider:
                        region != CardRegion.memoryCardRegions.last,
                    draft: draft(for: region),
                    resolvedText:
                        composedText(
                            for: draft(for: region)
                        ),
                    onFocus: {
                        applyModulePanelState(
                            V1ModulePanelCoordinator
                                .focusEditor(
                                    state:
                                        modulePanelState
                                )
                        )
                    },
                    onFocusTextItem: { item in
                        setActiveTextItem(
                            item.id,
                            for: region
                        )
                        applyModulePanelState(
                            V1ModulePanelCoordinator
                                .focusEditor(
                                    state:
                                        modulePanelState
                                )
                        )
                    },
                    onUpdateTextItem: { item, text in
                        updateTextItem(
                            item.id,
                            text: text,
                            for: region
                        )
                    },
                    onPrependText: { text in
                        prependText(
                            text,
                            to: region
                        )
                    },
                    onAppendText: { text in
                        appendText(
                            text,
                            to: region
                        )
                    },
                    onRemoveItem: { item in
                        removeItem(
                            item.id,
                            from: region
                        )
                        refreshPreview(for: region)
                    },
                    onShowModules: {
                        applyModulePanelState(
                            V1ModulePanelCoordinator
                                .showModules(
                                    for: region,
                                    state:
                                        modulePanelState
                                )
                        )
                    }
                )
            }
        }
    }

    private var accessoryEntryCluster: some View {
        VStack(alignment: .leading, spacing: 12) {
            configurationSectionHeader(
                title: "头像与标识",
                subtitle: "配置输出卡片左侧 Logo 标识，可使用系统标识、自选图片或当前对象头像。",
                systemImage: MemoMarkSymbol.memorySubject.name
            )

            V1AccessoryEntrySection(
                logoMode: $logoMode,
                selectedLogoItem: $selectedLogoItem,
                logoStatusMessage: resolvedLogoStatusMessage,
                logoRowDetail: logoRowDetail,
                logoPersistenceHint:
                    resolvedLogoPersistenceHint,
                subjectAvatarLogoImagePath:
                    resolvedSubjectAvatarLogoImagePath,
                subjectAvatarPreviewImagePath:
                    resolvedSubjectAvatarPreviewImagePath,
                customLogoImagePath:
                    customLogoBadge?.imagePath,
                isOptimizingLogo: isOptimizingLogo,
                logoExpanded:
                    expansionBinding(
                        for: .logo
                    )
                )
        }
        .padding(14)
        .background(
            RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
            .fill(ConfigurationUI.controlBackground.opacity(0.56))
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
            .stroke(ConfigurationUI.faintHairline)
        )
    }

    private func configurationSectionHeader(
        title: String,
        subtitle: String,
        systemImage: String
    ) -> some View {
        HStack(alignment: .top, spacing: 10) {
            RoundedRectangle(
                cornerRadius: 12,
                style: .continuous
            )
            .fill(Color.white.opacity(0.92))
            .frame(width: 36, height: 36)
            .overlay {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
            }
            .overlay(
                RoundedRectangle(
                    cornerRadius: 12,
                    style: .continuous
                )
                .stroke(ConfigurationUI.faintHairline)
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
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

    private var resolvedLogoStatusMessage: String {
        switch logoMode {
        case .appleMini:
            return "当前使用系统默认标识。"
        case .customUpload:
            return logoStatusMessage
        case .subjectAvatar:
            return resolvedSubjectAvatarLogoImagePath == nil
                ? "当前记忆对象还没有可用头像，先去对象配置里选择头像即可。"
                : "当前使用对象头像作为标识。"
        }
    }

    private var resolvedLogoPersistenceHint: String? {
        guard
            activeConfigurationStatus
            .isDirty
        else {
            return nil
        }

        return "预览区已经切换，点击“保存为当前配置”后，实际输出才会同步到当前标识。"
    }

    private var timeAnchorEntryPresentation:
        V1TimeAnchorEntryPresentation {

        V1TimeAnchorEntryPresenter
            .presentation(
                subject:
                    alignedSelectedSubject()
                    ?? session.state.selectedSubject,
                anchorTitle: timeAnchorTitle
            )
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

    private var birthdaySummaryText: String {
        let anchorDate =
            alignedSelectedSubject()?
            .primaryTimeAnchor?
            .date
            ?? session.state.selectedSubject?
            .primaryTimeAnchor?
            .date
            ?? session.state.selectedSubject?
            .timeAnchors.first?
            .date
            ?? birthdayDate

        return V1UserFacingDateFormatter.date(anchorDate)
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

    private var recentProcessingPresentation:
        V1IOSHomeRecentProcessingPresentation {

        V1IOSHomeRecentProcessingPresenter
            .presentation(
                header:
                    shareDiagnosticsHeaderProjection,
                snapshot:
                    backgroundStatusService
                    .currentSnapshot,
                recoveryMessage:
                    processingDiagnosticsSnapshot
                    .recoveryMessage
            )
    }

    private var presetPicker: some View {
        V1PresetPicker(
            currentTitle:
                homeAvailablePresets.isEmpty
                ? "当前对象还没有配置"
                : session.currentMemoryPresetTitle,
            presets: homeAvailablePresets,
            selectedPresetID: selectedPresetBinding
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
        previewRenderModel(
            for:
                V1DraftBridge
                .previewDraft(from: draft)
        )
        .displayText
    }

    private func previewRenderModel(
        for draft: V1PreviewDraft
    ) -> V1PreviewRenderModel {
        switch BuildV1PreviewRenderModelIntent(
            draft: draft,
            context: previewCompositionContext,
            engine: previewCompositionEngine
        )
        .executeSynchronously() {
        case .success(let model):
            return model
        case .failure:
            return V1PreviewRenderModel(
                templateSourceText:
                    draft.singleLineTemplateText,
                displayText:
                    draft.resolvedSingleLineText
            )
        }
    }

    private func makeDefaultDraft(
        for region: CardRegion
    ) -> V1EditorDraft {
        V1DraftBridge.editorDraft(
            from:
                previewCompositionEngine
                .defaultDraft(
                    for: region,
                    templateID:
                        session
                        .activeTemplateID(
                            for: region
                        ),
                    context:
                        previewCompositionContext
                )
        )
    }

    private func moduleItem(
        _ module: IOSInsertableModule
    ) -> V1ContentItem {
        guard let previewModule =
            previewModule(
                for: module
            ) else {
            return .token(
                module.title,
                value: moduleDisplayText(module),
                templateValue:
                    module.rendererToken,
                systemImage:
                    module.systemImage
            )
        }

        return V1DraftBridge.editorItem(
            from:
                previewCompositionEngine
                .makeModuleItem(
                    previewModule,
                    context:
                        previewCompositionContext
                )
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

        let request =
            V1ConfigurationApplyRequestBuilder
            .buildRequest(
                from:
                    V1ConfigurationApplyBuildInput(
                        selectedSubject:
                            session
                            .state
                            .selectedSubject,
                        subjects:
                            session
                            .state
                            .subjects,
                        selectedSubjectID:
                            session
                            .state
                            .selectedSubjectID,
                        shouldSaveSubjectLibrary:
                            shouldSaveSubjectLibrary,
                        memoryPresets:
                            presetPersistenceSnapshot
                            .memoryPresets,
                        selectedMemoryPresetID:
                            presetPersistenceSnapshot
                            .selectedMemoryPresetID,
                        presetTitle:
                            session
                            .currentMemoryPresetTitle,
                        templateTextsByRegion:
                            Dictionary(
                                uniqueKeysWithValues:
                                    CardRegion
                                    .memoryCardRegions
                                    .map { region in
                                        (
                                            region,
                                            templateText(
                                                for: draft(
                                                    for: region
                                                )
                                            )
                                        )
                                    }
                            ),
                        locationDisplayConfiguration:
                            locationDisplayConfiguration,
                        badge:
                            selectedBadgeForSaving,
                        usesCustomMemoryWriteText:
                            session
                            .usesCustomMemoryWriteText,
                        customMemoryWriteText:
                            session
                            .customMemoryWriteText,
                        birthdayDate:
                            birthdayDate,
                        outputTarget:
                            outputTarget,
                        mediaOutputMode:
                            mediaOutputMode,
                        availableAlbums:
                            availableAlbums,
                        selectedExistingAlbumIdentifier:
                            selectedExistingAlbumIdentifier,
                        newAlbumName:
                            newAlbumName
                    )
            )

        let aggregateDraft = V1ConfigurationAggregateDraft(
                title: session.currentMemoryPresetTitle,
                regionDrafts: Dictionary(
                    uniqueKeysWithValues:
                        CardRegion.memoryCardRegions.map {
                            region in
                            (region, draft(for: region))
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
                locationConfiguration:
                    locationDisplayConfiguration,
                logoMode: logoMode,
                badge: selectedBadgeForSaving,
                usesCustomMemoryWriteText:
                    session.usesCustomMemoryWriteText,
                customMemoryWriteText:
                    session.customMemoryWriteText,
                shouldWritePhotosDescription:
                    shouldWritePhotosDescription,
                photosDescriptionOverride:
                    photosDescriptionOverride,
                outputTarget: outputTarget,
                selectedAlbumIdentifier:
                    selectedExistingAlbumIdentifier,
                albumTitle: outputTarget == .newAlbum
                    ? newAlbumName
                    : configurationAlbumTitle,
                mediaOutputMode: mediaOutputMode,
                livePhotoPolicy: livePhotoPolicy,
                selectedTimeAnchorID:
                    session.selectedTimeAnchorID,
                savedAt: Date()
            )
        let configurationLibraryForApply: ConfigurationLibraryRecord?
        if let configurationID = session.state.selectedMemoryPresetID,
           let subject = session.state.selectedSubject {
            configurationLibraryForApply =
                V1LocalConfigurationLibraryPresenter
                .preparingCurrentConfiguration(
                    configurationID,
                    subject: subject,
                    seedConfiguration:
                        V1ConfigurationAggregateCandidateBuilder
                        .seedConfiguration(
                            id: configurationID,
                            draft: aggregateDraft
                        ),
                    in: session.state.configurationLibrary
                )
        } else {
            configurationLibraryForApply =
                session.state.configurationLibrary
        }

        return await configurationApplyRuntimeCoordinator.apply(
            configurationLibrary:
                configurationLibraryForApply,
            aggregateDraft: aggregateDraft,
            legacyRequest: request,
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
            showsConfigurationRequiredAlert = true
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

        availableAlbums =
            projection.availableAlbums
        selectedExistingAlbumIdentifier =
            projection
            .selectedExistingAlbumIdentifier
        albumStatusMessage =
            projection.albumStatusMessage

        isLoadingAlbums = false
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
        isOptimizingLogo =
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

        logoStatusMessage =
            update.logoStatusMessage

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

        if projection.logoMode == .customUpload,
           projection.badge != nil {
            logoStatusMessage = "已使用自选 Logo。"
        }
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
                locationDisplayConfiguration
        )
    }

    private var locationDisplayModule:
        IOSInsertedModule? {
        guard
            regionDrafts
            .values
            .flatMap(\.items)
            .contains(where: {
                $0.title == IOSInsertableModule.location.title
                && $0.systemImage
                == IOSInsertableModule.location.systemImage
            })
        else {
            return nil
        }

        return IOSInsertedModule(
            title:
                IOSInsertableModule.location.title,
            value:
                LocationDisplayInspectorPresenter
                .selectedValue(
                    fromConfiguration:
                        locationDisplayConfiguration
                ),
            systemImage:
                IOSInsertableModule.location.systemImage,
            expressionConfiguration:
                locationDisplayConfiguration
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

    private func selectConfigurationSummaryRegion(
        _ region: CardRegion
    ) {
        session.select(
            CardRegionBehavior(region: region)
        )
        entryNavigationState.setEditorSection(
            .region(region),
            isExpanded: true
        )
        activeModuleRegion = region
        dismissKeyboard()
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
        let previousPresetTitleDraft = memoryPresetTitleDraft
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
        memoryPresetTitleDraft = preset.title
        bootstrapDrafts()
        refreshDynamicPreview()

        guard await applyCurrentV1Configuration() else {
            session.state = previousState
            birthdayDate = previousBirthdayDate
            outputTarget = previousOutputTarget
            mediaOutputMode = previousMediaOutputMode
            logoMode = previousLogoMode
            memoryPresetTitleDraft = previousPresetTitleDraft
            bootstrapDrafts()
            refreshDynamicPreview()
            return false
        }

        completeWelcomeFlow()
        return true
    }

    private func showWorkflowGuideFromWelcome() {
        let update =
            V1EntryFlowCoordinator
            .showWorkflowFromWelcome(
                from: entryFlowState,
                hasSeenWelcome:
                    hasSeenWelcome
            )
        applyEntryWelcomeUpdate(update)
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
            selectedProcessingItems = []
        }

        let result =
            await V1PhotoProcessingQuickActionCoordinator
            .processPickedPhotoItems(
                saveCurrentConfiguration: {
                    await applyCurrentV1Configuration()
                },
                importItems: {
                    await V1PhotoIntakeImporter
                        .importItems(from: items)
                },
                submit: { resolvedItems in
                    externalIntakeCenter.submit(
                        items: resolvedItems,
                        source: .quickAction
                    )
                }
            )

        switch result.status {
        case .configurationSaveFailed:
            return
        case .noSupportedPhotos:
            activeConfigurationStatus =
                .failure(
                    message:
                        V1PhotoIntakeUnsupportedMessagePresenter
                        .message(
                            for:
                                items
                                .flatMap(
                                    \.supportedContentTypes
                                )
                        )
                )
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

    @MainActor
    private func importPickedPHPickerResults(
        _ results: [PHPickerResult]
    ) async {
        let result =
            await V1PhotoProcessingQuickActionCoordinator
            .processPickedPhotoItems(
                saveCurrentConfiguration: {
                    await applyCurrentV1Configuration()
                },
                importItems: {
                    await V1PhotoIntakeImporter
                        .importPHPickerResults(
                            from: results
                        )
                },
                submit: { resolvedItems in
                    externalIntakeCenter.submit(
                        items: resolvedItems,
                        source: .quickAction
                    )
                }
            )

        switch result.status {
        case .configurationSaveFailed:
            return
        case .noSupportedPhotos:
            activeConfigurationStatus =
                .failure(
                    message:
                        V1PhotoIntakeUnsupportedMessagePresenter
                        .message(
                            for:
                                results
                                .flatMap {
                                    $0
                                        .itemProvider
                                        .registeredTypeIdentifiers
                                        .compactMap(
                                            UTType.init
                                        )
                                }
                        )
                )
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

    private var selectedPresetBinding: Binding<MemoryPreset.ID> {
        Binding(
            get: {
                V1PresetSelectionCoordinator
                    .selectedPresetID(
                        selectedPreset:
                            session.state.selectedMemoryPreset,
                        presets:
                            homeAvailablePresets
                    )
            },
            set: { newValue in
                guard let update =
                    V1PresetSelectionCoordinator
                    .selectionUpdate(
                        for: newValue,
                        currentPreset:
                            session.state.selectedMemoryPreset,
                        presets:
                            homeAvailablePresets
                    )
                else {
                    return
                }

                activateHomePreset(
                    update.preset
                )
                activeConfigurationStatus =
                    update.activeConfigurationStatus
            }
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

private struct V1ConfigurationOptionList: View {

    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize

    @State
    private var showsResetConfigurationConfirmation = false

    @State
    private var showsDeleteConfigurationConfirmation = false

    let subject: MemorySubject?
    @Binding var isMemorySourceExpanded: Bool
    let subjectAvatarPreviewImagePath: String?
    @Binding var logoMode: V1LogoMode
    @Binding var selectedLogoItem: PhotosPickerItem?
    let logoValue: String
    let logoDetail: String
    let customLogoImagePath: String?
    let isOptimizingLogo: Bool
    let timeAnchorTitle: String
    let timeAnchorCount: Int
    let availableTimeAnchors:
        [MemorySubject.TimeAnchor]
    let selectedTimeAnchorID: Binding<UUID>
    let locationPresentation:
        LocationDisplayInspectorPresentation
    let selectedLocationValue: String
    let selectedLocationOptionID: Binding<String>
    let isLocationSelectable: Bool
    let memoryDisplayValue: String
    let memoryDisplayDetail: String
    let availableMemoryDisplayStyles:
        [MemoryAnchorExpressionStyle]
    let selectedMemoryDisplayStyle:
        Binding<MemoryAnchorExpressionStyle>
    let borderStyleName: String
    let configurationStatus: V1ConfigurationStatus
    let isSavingConfiguration: Bool
    let onOpenRegionContent: () -> Void
    let onSaveCurrentConfiguration: () -> Void
    let onCreateConfiguration: () -> Void
    let onResetConfiguration: () -> Void
    let onDeleteConfiguration: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            memorySourceSection

            groupedSection(
                index: "2.",
                title: "卡片布局与内容",
                subtitle: "决定卡片各区域的内容与显示形式"
            ) {
                logoRow
                optionDivider
                borderStyleRow
                optionDivider
                locationRow
                optionDivider
                regionContentRow
            }

            groupedSection(
                index: "3.",
                title: "配置操作",
                subtitle: "保存或管理当前配置"
            ) {
                configurationActionGrid

                Label(
                    configurationStatusMessage,
                    systemImage:
                        configurationStatusSystemImage
                )
                .font(.caption)
                .foregroundStyle(configurationStatusColor)
                .padding(.top, 2)
            }
        }
        .confirmationDialog(
            "恢复默认配置？",
            isPresented:
                $showsResetConfigurationConfirmation,
            titleVisibility: .visible
        ) {
            Button("恢复默认", role: .destructive) {
                onResetConfiguration()
            }

            Button("取消", role: .cancel) {}
        } message: {
            Text("当前未保存的配置修改会被默认内容替换。")
        }
        .confirmationDialog(
            "删除当前配置？",
            isPresented:
                $showsDeleteConfigurationConfirmation,
            titleVisibility: .visible
        ) {
            Button("删除配置", role: .destructive) {
                onDeleteConfiguration()
            }

            Button("取消", role: .cancel) {}
        } message: {
            Text("删除当前配置不会删除已经保留在本地配置库中的备份。")
        }
    }

    private var memorySourceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            memorySourceSectionHeader

            VStack(spacing: 0) {
                if isMemorySourceExpanded {
                    subjectRow
                    optionDivider
                    timeAnchorRow
                    optionDivider
                    memoryDisplayRow
                } else {
                    memorySourceSummaryRow
                }
            }
            .background(
                RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
                .fill(ConfigurationUI.panelBackground)
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
                .stroke(ConfigurationUI.faintHairline)
            )
        }
        .padding(14)
        .v1CardChrome()
    }

    private var memorySourceSectionHeader: some View {
        HStack(alignment: .center, spacing: 10) {
            adaptiveSectionHeader(
                index: "1.",
                title: "记忆来源",
                subtitle: "决定智能模块生成的内容"
            )

            Spacer(minLength: 8)

            Button {
                isMemorySourceExpanded.toggle()
            } label: {
                Label(
                    isMemorySourceExpanded ? "收起" : "展开",
                    systemImage:
                        isMemorySourceExpanded
                        ? "chevron.up"
                        : "chevron.down"
                )
                .font(.caption.weight(.semibold))
            }
            .buttonStyle(.borderless)
            .foregroundStyle(Color.accentColor)
            .padding(.trailing, 8)
            .accessibilityLabel(
                isMemorySourceExpanded
                ? "收起记忆来源"
                : "展开记忆来源"
            )
        }
    }

    private var memorySourceSummaryRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.accentColor)

            Text(memorySourceSummary)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
                .lineLimit(2)

            Spacer(minLength: 8)

            Text("已生效")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.accentColor)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("当前记忆来源")
        .accessibilityValue(memorySourceSummary)
    }

    private var memorySourceSummary: String {
        [
            subjectDisplayName,
            availableTimeAnchors.isEmpty
                ? "暂无时间锚点"
                : timeAnchorTitle,
            memoryDisplayValue
        ]
        .joined(separator: " · ")
    }

    private var subjectRow: some View {
        configurationRow(
            icon: subjectIcon,
            title: "记忆对象",
            subtitle: "当前生效主体",
            value: subjectDisplayName,
            detail: "随首页同步",
            showsTrailingChevron: false
        ) {
            Text(subjectDisplayName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
    }

    private var logoRow: some View {
        configurationRow(
            icon: logoIcon,
            title: "Logo 标识",
            subtitle: "设置输出卡片左侧标识",
            value: logoValue,
            detail: logoDetail,
            showsTrailingChevron: false
        ) {
            HStack(spacing: 6) {
                Menu {
                    ForEach(V1LogoMode.allCases) { mode in
                        Button {
                            logoMode = mode
                        } label: {
                            menuOptionLabel(
                                mode.title,
                                isSelected: mode == logoMode
                            )
                        }
                    }
                } label: {
                    optionSelectionPill(title: logoValue)
                }
                .accessibilityLabel("Logo 标识")
                .accessibilityValue(logoValue)

                if logoMode == .customUpload {
                    PhotosPicker(
                        selection: $selectedLogoItem,
                        matching: .images
                    ) {
                        Group {
                            if isOptimizingLogo {
                                ProgressView()
                                    .controlSize(.mini)
                            } else {
                                Image(
                                    systemName:
                                        "photo.badge.plus"
                                )
                                .font(
                                    .caption.weight(.semibold)
                                )
                            }
                        }
                        .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(Color.accentColor)
                    .disabled(isOptimizingLogo)
                    .accessibilityLabel(
                        isOptimizingLogo
                        ? "正在优化 Logo"
                        : "选择 Logo"
                    )
                }
            }
        }
    }

    private var timeAnchorRow: some View {
        configurationRow(
                systemImage: MemoMarkSymbol.timeAnchor.name,
            tint: .blue,
            title: "时间锚点",
            subtitle: "定义时间参考，计算年龄与天数",
            value:
                availableTimeAnchors.isEmpty
                ? "暂无"
                : timeAnchorTitle,
            detail:
                "\(timeAnchorCount) 个锚点",
            showsTrailingChevron: false
        ) {
            if availableTimeAnchors.isEmpty {
                optionSelectionPill(title: "暂无")
                    .opacity(0.56)
                    .accessibilityLabel("时间锚点")
                    .accessibilityValue("暂无")
            } else {
                Menu {
                    ForEach(availableTimeAnchors) { anchor in
                        Button {
                            selectedTimeAnchorID.wrappedValue =
                                anchor.id
                        } label: {
                            menuOptionLabel(
                                anchor.title,
                                isSelected:
                                    anchor.id
                                    == selectedTimeAnchorID
                                    .wrappedValue
                            )
                        }
                    }
                } label: {
                    optionSelectionPill(title: timeAnchorTitle)
                }
                .accessibilityLabel("时间锚点")
                .accessibilityValue(timeAnchorTitle)
            }
        }
    }

    private var locationRow: some View {
        configurationRow(
            systemImage: locationPresentation.systemImage,
            tint: .cyan,
            title: locationPresentation.title,
            subtitle: "控制位置信息的显示内容",
            value: selectedLocationValue,
            detail:
                isLocationSelectable
                ? locationValueDetail
                : "未插入位置模块",
            showsTrailingChevron: false
        ) {
            Menu {
                ForEach(locationPresentation.options) { option in
                    Button {
                        selectedLocationOptionID.wrappedValue =
                            option.id
                    } label: {
                        menuOptionLabel(
                            option.title,
                            isSelected:
                                option.id
                                == selectedLocationOptionID
                                .wrappedValue
                        )
                    }
                }
            } label: {
                optionSelectionPill(title: selectedLocationValue)
            }
            .accessibilityLabel(locationPresentation.title)
            .accessibilityValue(selectedLocationValue)
        }
    }

    private var memoryDisplayRow: some View {
        configurationRow(
            systemImage: MemoMarkSymbol.memoryContent.name,
            tint: .pink,
            title: "记忆显示",
            subtitle: "自定义表达方式与记忆内容",
            value: memoryDisplayValue,
            detail: memoryDisplayDetail,
            showsTrailingChevron: false
        ) {
            if availableMemoryDisplayStyles.isEmpty {
                optionSelectionPill(title: "暂无")
                    .opacity(0.56)
                    .accessibilityLabel("记忆显示")
                    .accessibilityValue("暂无")
            } else {
                Menu {
                    ForEach(
                        availableMemoryDisplayStyles,
                        id: \.self
                    ) { style in
                        Button {
                            selectedMemoryDisplayStyle.wrappedValue =
                                style
                        } label: {
                            menuOptionLabel(
                                style.displayTitle,
                                isSelected:
                                    style
                                    == selectedMemoryDisplayStyle
                                    .wrappedValue
                            )
                        }
                    }
                } label: {
                    optionSelectionPill(title: memoryDisplayValue)
                }
                .accessibilityLabel("记忆显示")
                .accessibilityValue(memoryDisplayValue)
            }
        }
    }

    private var borderStyleRow: some View {
        configurationRow(
            systemImage: MemoMarkSymbol.borderStyle.name,
            tint: .orange,
            title: "边框样式",
            subtitle: "当前公开边框样式",
            value: borderStyleName,
            detail: "当前锁定",
            showsTrailingChevron: false
        ) {
            rowValueText(borderStyleName)
        }
    }

    private var regionContentRow: some View {
        Button(action: onOpenRegionContent) {
            configurationRow(
                systemImage: MemoMarkSymbol.module.name,
                tint: .blue,
                title: "区域内容设置",
                subtitle: "编辑卡片四个区域的模块与文字",
                value: "进入设置",
                detail: "",
                showsTrailingChevron: false
            ) {
                HStack(spacing: 5) {
                    Text("进入设置")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.accentColor)

                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.tertiary)
                        .accessibilityHidden(true)
                }
                .lineLimit(1)
                .frame(
                    maxWidth: .infinity,
                    alignment: .trailing
                )
            }
        }
        .buttonStyle(
            V1ConfigurationNavigationRowButtonStyle()
        )
        .accessibilityLabel("区域内容设置")
        .accessibilityHint("编辑卡片四个区域的模块与文字")
    }

    private var configurationActionGrid: some View {
        LazyVGrid(
            columns: configurationActionColumns,
            spacing: 10
        ) {
            actionButton(
                title: saveActionTitle,
                systemImage: saveActionSystemImage,
                tint: .blue,
                isProminent: true,
                action: onSaveCurrentConfiguration
            )

            actionButton(
                title: "另存为新配置",
                systemImage: "plus.square.fill",
                tint: .green,
                action: onCreateConfiguration
            )

            actionButton(
                title: "恢复默认",
                systemImage: "arrow.counterclockwise.circle.fill",
                tint: .orange,
                role: .destructive,
                action: {
                    showsResetConfigurationConfirmation = true
                }
            )

            actionButton(
                title: "删除当前配置",
                systemImage: "trash.fill",
                tint: .red,
                role: .destructive,
                action: {
                    showsDeleteConfigurationConfirmation = true
                }
            )
        }
        .disabled(isSavingConfiguration)
    }

    private var configurationActionColumns: [GridItem] {
        if dynamicTypeSize.isAccessibilitySize {
            return [GridItem(.flexible())]
        }

        return [
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10)
        ]
    }

    private var saveActionTitle: String {
        if isSavingConfiguration {
            return "正在保存"
        }

        switch configurationStatus {
        case .saved:
            return "已保存"
        case .failure:
            return "重新保存"
        case .idle,
             .dirty,
             .saving,
             .subjectSynced:
            return "保存当前配置"
        }
    }

    private var saveActionSystemImage: String {
        if isSavingConfiguration {
            return "hourglass"
        }

        switch configurationStatus {
        case .saved:
            return "checkmark.circle.fill"
        case .failure:
            return "arrow.clockwise.circle.fill"
        case .idle,
             .dirty,
             .saving,
             .subjectSynced:
            return "tray.and.arrow.down"
        }
    }

    private var configurationStatusMessage: String {
        switch configurationStatus {
        case .idle:
            return "保存后，配置会应用于后续所有处理任务。"
        case .dirty:
            return "有未保存修改。"
        case .saving:
            return "正在保存当前配置。"
        case .saved:
            return "已保存，将应用于后续处理任务。"
        case .subjectSynced:
            return "记忆对象已同步，保存后应用于后续任务。"
        case .failure(let message):
            return message
        }
    }

    private var configurationStatusSystemImage: String {
        switch configurationStatus {
        case .idle:
            return "info.circle"
        case .dirty:
            return "pencil.circle.fill"
        case .saving:
            return "hourglass"
        case .saved:
            return "checkmark.circle.fill"
        case .subjectSynced:
            return "person.crop.circle.badge.checkmark"
        case .failure:
            return "exclamationmark.triangle.fill"
        }
    }

    private var configurationStatusColor: Color {
        switch configurationStatus {
        case .saved,
             .subjectSynced:
            return Color.accentColor
        case .dirty,
             .failure:
            return Color.orange
        case .idle,
             .saving:
            return Color.secondary
        }
    }

    private func actionButton(
        title: String,
        systemImage: String,
        tint: Color,
        isProminent: Bool = false,
        role: ButtonRole? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(role: role, action: action) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .foregroundStyle(
                    isProminent
                    ? Color.white
                    : tint
                )
                .background(
                    RoundedRectangle(
                        cornerRadius: 12,
                        style: .continuous
                    )
                    .fill(
                        isProminent
                        ? tint
                        : ConfigurationUI.controlBackground
                    )
                )
                .overlay(
                    RoundedRectangle(
                        cornerRadius: 12,
                        style: .continuous
                    )
                    .stroke(
                        isProminent
                        ? tint
                        : ConfigurationUI.faintHairline
                    )
                )
        }
        .buttonStyle(V1ConfigurationActionButtonStyle())
    }

    private func groupedSection<Content: View>(
        index: String,
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            adaptiveSectionHeader(
                index: index,
                title: title,
                subtitle: subtitle
            )

            VStack(spacing: 0) {
                content()
            }
            .background(
                RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
                .fill(ConfigurationUI.panelBackground)
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
                .stroke(ConfigurationUI.faintHairline)
            )
        }
        .padding(14)
        .v1CardChrome()
    }

    @ViewBuilder
    private func adaptiveSectionHeader(
        index: String,
        title: String,
        subtitle: String
    ) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 4) {
                HStack(
                    alignment: .firstTextBaseline,
                    spacing: 8
                ) {
                    Text(index)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(title)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                }

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
            }
        } else {
            HStack(
                alignment: .firstTextBaseline,
                spacing: 8
            ) {
                Text(index)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: true, vertical: false)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                    .fixedSize(horizontal: false, vertical: true)
                    .layoutPriority(1)
            }
        }
    }

    private var subjectDisplayName: String {
        let name =
            subject?
            .identity
            .displayName
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard let name,
              !name.isEmpty else {
            return "记忆对象"
        }

        return name
    }

    private var subjectIcon: some View {
        ZStack {
            Circle()
                .fill(Color.purple.opacity(0.11))

            if let subjectAvatarPreviewImagePath,
               let image = UIImage(
                contentsOfFile:
                    subjectAvatarPreviewImagePath
               ) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.purple)
            }
        }
        .frame(
            width: V1CompactInformationRowMetrics.iconSize,
            height: V1CompactInformationRowMetrics.iconSize
        )
    }


    private var logoIcon: some View {
        ZStack {
            RoundedRectangle(
                cornerRadius:
                    V1CompactInformationRowMetrics.iconCornerRadius,
                style: .continuous
            )
            .fill(Color.blue.opacity(0.10))

            if logoMode == .subjectAvatar,
               let subjectAvatarPreviewImagePath,
               let image = UIImage(
                contentsOfFile:
                    subjectAvatarPreviewImagePath
               ) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius:
                                V1CompactInformationRowMetrics
                                .iconCornerRadius,
                            style: .continuous
                        )
                    )
            } else if logoMode == .customUpload,
                      let customLogoImagePath,
                      let image = UIImage(
                        contentsOfFile:
                            customLogoImagePath
                      ) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(7)
            } else {
                Image(systemName: "apple.logo")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.primary.opacity(0.78))
            }
        }
        .frame(
            width: V1CompactInformationRowMetrics.iconSize,
            height: V1CompactInformationRowMetrics.iconSize
        )
    }

    private var locationValueDetail: String {
        locationPresentation.options
            .first { option in
                option.title == selectedLocationValue
            }?
            .note
        ?? "当前展示方式"
    }

    private func configurationRow<Trailing: View>(
        systemImage: String,
        tint: Color,
        title: String,
        subtitle: String,
        value: String,
        detail: String,
        showsTrailingChevron: Bool = true,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        configurationRow(
            icon:
                rowIcon(
                    systemImage: systemImage,
                    tint: tint
                ),
            title: title,
            subtitle: subtitle,
            value: value,
            detail: detail,
            showsTrailingChevron:
                showsTrailingChevron,
            trailing: trailing
        )
    }

    private func configurationRow<Icon: View, Trailing: View>(
        icon: Icon,
        title: String,
        subtitle: String,
        value: String,
        detail: String,
        showsTrailingChevron: Bool = true,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        let trailingSpacing: CGFloat =
            detail.isEmpty && showsTrailingChevron == false
            ? 0
            : 4

        return HStack(
            alignment: .center,
            spacing: V1CompactInformationRowMetrics.contentSpacing
        ) {
            icon

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .layoutPriority(1)

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: trailingSpacing) {
                trailing()

                if !detail.isEmpty {
                    Text(detail)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }

                if showsTrailingChevron {
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(
                minWidth: 72,
                maxWidth: 128,
                alignment: .trailing
            )
        }
        .padding(
            .horizontal,
            V1CompactInformationRowMetrics.horizontalPadding
        )
        .padding(
            .vertical,
            V1CompactInformationRowMetrics.verticalPadding
        )
        .contentShape(Rectangle())
    }

    private func rowValueText(
        _ title: String,
        isAction: Bool = false
    ) -> some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(
                isAction
                ? Color.accentColor
                : Color.primary.opacity(0.72)
            )
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private func optionSelectionPill(title: String) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.76)
                .allowsTightening(true)
                .truncationMode(.tail)

            Image(systemName: "chevron.down")
                .font(.caption2.weight(.bold))
                .foregroundStyle(Color.accentColor)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .background(
            RoundedRectangle(
                cornerRadius:
                    ConfigurationUI.smallCornerRadius,
                style: .continuous
            )
            .fill(ConfigurationUI.controlBackground)
        )
        .overlay(
            RoundedRectangle(
                cornerRadius:
                    ConfigurationUI.smallCornerRadius,
                style: .continuous
            )
            .stroke(ConfigurationUI.faintHairline)
        )
    }

    @ViewBuilder
    private func menuOptionLabel(
        _ title: String,
        isSelected: Bool
    ) -> some View {
        if isSelected {
            Label(title, systemImage: "checkmark")
        } else {
            Text(title)
        }
    }

    private func rowIcon(
        systemImage: String,
        tint: Color
    ) -> some View {
        ZStack {
            RoundedRectangle(
                cornerRadius:
                    V1CompactInformationRowMetrics.iconCornerRadius,
                style: .continuous
            )
            .fill(tint.opacity(0.11))

            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(tint)
                .symbolRenderingMode(.hierarchical)
        }
        .frame(
            width: V1CompactInformationRowMetrics.iconSize,
            height: V1CompactInformationRowMetrics.iconSize
        )
    }

    private var optionDivider: some View {
        Rectangle()
            .fill(ConfigurationUI.faintHairline)
            .frame(height: 0.5)
            .padding(
                .leading,
                V1CompactInformationRowMetrics.horizontalPadding
                + V1CompactInformationRowMetrics.iconSize
                + V1CompactInformationRowMetrics.contentSpacing
            )
    }
}

private struct V1ConfigurationActionButtonStyle:
    ButtonStyle {

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @Environment(\.isEnabled)
    private var isEnabled

    func makeBody(
        configuration: Configuration
    ) -> some View {
        configuration.label
            .opacity(
                isEnabled
                ? (configuration.isPressed ? 0.72 : 1)
                : 0.56
            )
            .scaleEffect(
                configuration.isPressed && !reduceMotion
                ? 0.97
                : 1
            )
            .animation(
                reduceMotion
                ? nil
                : .easeOut(duration: 0.12),
                value: configuration.isPressed
            )
    }
}

private struct V1ConfigurationNavigationRowButtonStyle:
    ButtonStyle {

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    func makeBody(
        configuration: Configuration
    ) -> some View {
        configuration.label
            .background(
                ConfigurationUI.selectedBackground
                    .opacity(
                        configuration.isPressed
                        ? 1
                        : 0
                    )
            )
            .opacity(
                configuration.isPressed
                ? 0.76
                : 1
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
            )
            .animation(
                reduceMotion
                ? nil
                : .easeOut(duration: 0.1),
                value: configuration.isPressed
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
