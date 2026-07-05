#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI
import PhotosUI
import UIKit

struct PhotoMemoiOSV1View: View {
    @Environment(\.scenePhase)
    private var scenePhase

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
    private var expandedEditorSections:
        Set<PhotoMemoiOSV1EntrySection> = []

    @State
    private var entryFlowState =
        V1EntryFlowState()

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
        "建议上传 2048 × 2048 的透明 PNG。"

    @State
    private var birthdayDate =
        Calendar.current.date(
            from: DateComponents(
                year: 2025,
                month: 5,
                day: 26
            )
        ) ?? Date()

    @State
    private var outputTarget: V1IOSOutputTarget = .automatic

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
    private var profileOffsetY: CGFloat = 0

    @State
    private var previewOffsetY: CGFloat = 0

    @State
    private var didBootstrap = false

    @State
    private var isApplyingBootstrapState = false

    @State
    private var shouldSaveSubjectLibrary = true

    @State
    private var activeConfigurationMessage = "尚未保存为默认配置"

    @State
    private var shareDiagnosticEvents:
        [PhotoMemoShareDiagnosticEvent] = []

    @State
    private var processingDiagnosticsSnapshot =
        PhotoMemoiOSProcessingDiagnosticsSnapshot()

    @State
    private var showsPresetActivationConfirmation = false

    @State
    private var pendingActivationPresetTitle = ""

    @State
    private var isEditingMemoryPresetTitle = false

    @State
    private var memoryPresetTitleDraft = ""

    @FocusState
    private var memoryPresetTitleFieldFocused: Bool

    @AppStorage("photomemo.v1.moduleUsageCounts")
    private var moduleUsageCountsStorage = "{}"

    @AppStorage("photomemo.v1.welcomeSeen")
    private var hasSeenWelcome = false

    private let currentBorderStyleName =
        "Classic White"

    private let currentBorderStyleDescription =
        "当前唯一公开边框，预览与生成保持同一套锁定规范。"

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
            applySelectedMemoryPreset: {
                session.applySelectedMemoryPreset()
            },
            updateStatus: { status in
                activeConfigurationMessage =
                    status.message
                isSavingConfiguration =
                    status.isSaving
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
                selectedExistingAlbumIdentifier =
                    projection
                    .selectedExistingAlbumIdentifier

                if let suggestedNewAlbumName =
                    projection
                    .suggestedNewAlbumName {
                    newAlbumName =
                        suggestedNewAlbumName
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
                selectedSubjectID in
                session.restoreSubjectLibrary(
                    subjects,
                    selectedSubjectID:
                        selectedSubjectID
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
    }

    var body: some View {
        NavigationStack {
            TabView(selection: $entryFlowState.selectedTab) {
                homePage
                    .tabItem {
                        Label("首页", systemImage: "house.fill")
                    }
                    .tag(V1EntryTab.home)

                editorPage
                    .tabItem {
                        Label("配置中心", systemImage: "slider.horizontal.3")
                    }
                    .tag(V1EntryTab.editor)

                outputPage
                    .tabItem {
                        Label("输出", systemImage: "square.and.arrow.down")
                    }
                    .tag(V1EntryTab.output)

                settingsPage
                    .tabItem {
                        Label("设置", systemImage: "gearshape")
                    }
                    .tag(V1EntryTab.settings)
            }
        }
        .preferredColorScheme(.light)
        .task {
            await loadAlbumOptions()
        }
        .sheet(
            isPresented: $entryFlowState.showsWelcomePage
        ) {
            V1WelcomePageSurface(
                presentation: .default,
                onStart: {
                    completeWelcomeFlow()
                },
                onShowWorkflow: {
                    showWorkflowGuideFromWelcome()
                }
            )
            .interactiveDismissDisabled(!hasSeenWelcome)
        }
        .sheet(
            isPresented: $entryFlowState.showsWorkflowGuide
        ) {
            V1WorkflowGuideSurface(
                steps: V1WelcomePresentation.default.workflowSteps
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
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
            isPresented: $entryFlowState.showsSubjectOverview
        ) {
            V1IOSSubjectOverviewSheet(
                presentation:
                    subjectOverviewPresentation,
                subjects: session.state.subjects,
                subject:
                    session.state.selectedSubject,
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
                onConfirmActiveAnchor: {
                    anchorID in
                    guard let patch =
                        V1SubjectOverviewActionCoordinator
                        .activateAnchor(
                            anchorID,
                            in: session,
                            shouldSaveSubjectLibrary:
                                shouldSaveSubjectLibrary,
                            configurationCoordinator:
                                configurationCoordinator
                        ) else {
                        return
                    }

                    applySubjectFlowPatch(patch)
                    entryFlowState =
                        V1EntryFlowCoordinator
                        .closeSubjectOverview(
                            from:
                                entryFlowState
                        )
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
                onOpenEditor: {
                    let flowState =
                        V1SubjectOverviewActionCoordinator
                        .makeConfigurationFlowState(
                            from: session,
                            shouldSaveSubjectLibrary:
                                shouldSaveSubjectLibrary,
                            configurationCoordinator:
                                configurationCoordinator,
                            savedMessage:
                                "有未保存修改",
                            onPersistedSubject: {
                                patch in
                                applySubjectFlowPatch(
                                    patch
                                )
                            }
                        )
                    entryFlowState =
                        V1EntryFlowCoordinator
                        .openSubjectConfiguration(
                            flowState,
                            from:
                                entryFlowState
                        )
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(
            item: $entryFlowState.subjectConfigurationFlowState
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
        .confirmationDialog(
            "将当前配置组合保存为默认配置？",
            isPresented: $showsPresetActivationConfirmation,
            titleVisibility: .visible
        ) {
            Button("保存为默认配置") {
                Task {
                    await applyCurrentV1Configuration()
                }
            }

            Button("仅切换查看", role: .cancel) {
                activeConfigurationMessage = "有未保存修改"
            }
        } message: {
            Text("已切换到「\(pendingActivationPresetTitle)」。保存后，下一次处理照片时会默认使用这套配置组合、时间锚点和输出设置。")
        }
        .onAppear {
            bootstrapIfNeeded()
            refreshProcessingState()
        }
        .photosPicker(
            isPresented:
                $entryFlowState
                .showsProcessingPhotoPicker,
            selection: $selectedProcessingItems,
            maxSelectionCount: 24,
            matching: .images
        )
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else {
                return
            }

            refreshProcessingState()
        }
        .onChange(of: session.state.selectedMemoryPresetID) { _, _ in
            isEditingMemoryPresetTitle = false
            memoryPresetTitleFieldFocused = false
            bootstrapDrafts()
        }
        .onChange(of: birthdayDate) { _, _ in
            refreshDynamicPreview()
            activeConfigurationMessage = "有未保存修改"
        }
        .onChange(of: session.state.selectedSubject) { _, subject in
            if let subjectAnchorDate =
                subject?.primaryTimeAnchor?.date
                ?? subject?.timeAnchors.first?.date {
                birthdayDate = subjectAnchorDate
            }

            refreshDynamicPreview()

            if !isApplyingBootstrapState {
                activeConfigurationMessage = "有未保存修改"
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
        .onChange(of: logoMode) { _, _ in
            activeConfigurationMessage = "有未保存修改"
        }
        .onChange(of: outputTarget) { _, _ in
            activeConfigurationMessage = "有未保存修改"
        }
        .onChange(of: selectedExistingAlbumIdentifier) { _, _ in
            activeConfigurationMessage = "有未保存修改"
        }
        .onChange(of: newAlbumName) { _, _ in
            activeConfigurationMessage = "有未保存修改"
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

    private var homePage: some View {
        V1HomePageSurface(
            subjectSummary: homeSubjectSummaryProjection,
            subject: session.state.selectedSubject,
            borderStyleName: currentBorderStyleName,
            borderStyleDescription: currentBorderStyleDescription,
            presetSummary: homePresetSummaryProjection,
            presetStatusTone: currentPresetStatusTone,
            isEditingMemoryPresetTitle: isEditingMemoryPresetTitle,
            memoryPresetTitleDraft: $memoryPresetTitleDraft,
            memoryPresetTitleFieldFocused: $memoryPresetTitleFieldFocused,
            isSavingConfiguration: isSavingConfiguration,
            recentProcessingPresentation: recentProcessingPresentation,
            onOpenSubject: {
                entryFlowState =
                    V1EntryFlowCoordinator
                    .openSubjectOverview(
                        from:
                            entryFlowState
                    )
            },
            onCommitMemoryPresetTitle: commitMemoryPresetTitle,
            onApplyCurrentConfiguration: {
                Task {
                    await applyCurrentV1Configuration()
                }
            },
            onOpenPhotoPicker: {
                entryFlowState =
                    V1EntryFlowCoordinator
                    .openProcessingPhotoPicker(
                        from:
                            entryFlowState
                    )
            },
            onOpenEditor: {
                entryFlowState =
                    V1EntryFlowCoordinator
                    .openEditorTab(
                        from:
                            entryFlowState
                    )
            },
            onOpenTimeAnchor: {
                entryFlowState =
                    V1EntryFlowCoordinator
                    .openSubjectOverview(
                        from:
                            entryFlowState
                    )
            },
            onOpenUsageGuide: {
                entryFlowState =
                    V1EntryFlowCoordinator
                    .showWelcomePage(
                        from:
                            entryFlowState
                    )
            },
            onOpenSettings: {
                entryFlowState =
                    V1EntryFlowCoordinator
                    .openSettingsTab(
                        from:
                            entryFlowState
                    )
            },
            onDismissKeyboard: dismissKeyboard,
            presetPicker: presetPicker,
            presetOperationsMenu: presetOperationsMenu,
            profileTrackingBackground: offsetReader(for: .profile)
        )
    }

    private var editorPage: some View {
        V1EditorPageSurface(
            previewPinProgress: previewPinProgress,
            editorRevealProgress: editorRevealProgress,
            onDismissKeyboard: dismissKeyboard
        ) {
            previewSection
                .background(
                    offsetReader(
                        for: .preview
                    )
                )
        } editorContent: {
            editorCluster
        } accessoryContent: {
            accessoryEntryCluster
        }
        .navigationTitle("配置中心")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var outputPage: some View {
        V1OutputPageSurface(
            outputTarget: $outputTarget,
            availableAlbums: availableAlbums,
            selectedExistingAlbumIdentifier: $selectedExistingAlbumIdentifier,
            newAlbumName: $newAlbumName,
            isLoadingAlbums: isLoadingAlbums,
            albumStatusMessage: albumStatusMessage,
            usesCustomMemoryWriteText: $session.usesCustomMemoryWriteText,
            customMemoryWriteText: $session.customMemoryWriteText,
            resolvedMemoryWriteText: resolvedMemoryWriteText,
            onDismissKeyboard: dismissKeyboard
        )
    }

    private var settingsPage: some View {
        V1SettingsPageSurface(
            header: shareDiagnosticsHeaderProjection,
            snapshot: backgroundStatusService.currentSnapshot,
            recoveryMessage: processingDiagnosticsSnapshot.recoveryMessage,
            displayEvents: shareDiagnosticDisplayEvents,
            onRefresh: refreshProcessingState,
            onClearCompletedHistory: clearCompletedQueueHistory,
            onShowWelcome: {
                entryFlowState =
                    V1EntryFlowCoordinator
                    .showWelcomePage(
                        from:
                            entryFlowState
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

    private var presetOperationsMenu: some View {
        V1PresetOperationsMenu(
            onRename: beginEditingMemoryPresetTitle,
            onRestoreDefaults: {
                session.resetSelectedMemoryPreset()
                bootstrapDrafts()
                activeConfigurationMessage = "有未保存修改"
            }
        )
    }

    private var homePresetSummaryProjection:
        V1IOSHomePresetSummaryProjection {

        V1IOSHomeProjection
            .presetSummary(
                presetTitle:
                    session.currentMemoryPresetTitle,
                configurationLabel:
                    session.currentConfigurationLabel,
                presetSummary:
                    session.currentMemoryPresetSummary,
                activeConfigurationMessage:
                    activeConfigurationMessage,
                isApplied:
                    session.selectedMemoryPresetIsApplied
            )
    }

    private var currentPresetStatusTone:
        V1IOSHomeStatusBadge.Tone {

        if homePresetSummaryProjection
            .emphasizesAppliedState {
            return .accent
        }

        if activeConfigurationMessage
            .contains("未保存") {
            return .warning
        }

        return .neutral
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
        memoryPresetTitleDraft = session.currentMemoryPresetTitle
        isEditingMemoryPresetTitle = true

        DispatchQueue.main.async {
            memoryPresetTitleFieldFocused = true
        }
    }

    private func commitMemoryPresetTitle() {
        session.updateSelectedMemoryPresetTitle(
            memoryPresetTitleDraft
        )
        activeConfigurationMessage = "有未保存修改"
        isEditingMemoryPresetTitle = false
        memoryPresetTitleFieldFocused = false
    }

    private func applySubjectFlowPatch(
        _ patch: V1SubjectFlowPatch
    ) {
        if let birthdayDate = patch.birthdayDate {
            self.birthdayDate = birthdayDate
        }

        if patch.shouldRefreshPreview {
            refreshDynamicPreview()
        }

        if patch.events.contains(
            .reopenSubjectLibraryPersistence
        ) {
            shouldSaveSubjectLibrary = true
        }

        activeConfigurationMessage =
            patch.activeConfigurationMessage

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
        V1AccessoryEntrySection(
            logoMode: $logoMode,
            selectedLogoItem: $selectedLogoItem,
            birthdayDate: $birthdayDate,
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
            timeAnchorPresentation:
                timeAnchorEntryPresentation,
            birthdaySummaryText: birthdaySummaryText,
            logoExpanded:
                expansionBinding(
                    for: .logo
                ),
            anchorExpanded:
                expansionBinding(
                    for: .anchor
                )
        )
    }

    private var logoRowDetail: String {
        switch logoMode {
        case .appleMini:
            return "使用系统默认标识"
        case .customUpload:
            return customLogoBadge == nil
                ? "点击上传自选 Logo"
                : "已准备自选 Logo"
        case .subjectAvatar:
            return resolvedSubjectAvatarLogoImagePath == nil
                ? "当前记忆对象尚未上传头像"
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
                ? "当前记忆对象还没有可用头像，先去对象配置里上传头像即可。"
                : "当前使用对象头像作为标识。"
        }
    }

    private var resolvedLogoPersistenceHint: String? {
        guard
            activeConfigurationMessage
            == V1DraftMutationCoordinator
            .dirtyStateMessage
        else {
            return nil
        }

        return "预览区已经切换，点击“保存为默认配置”后，实际输出才会同步到当前标识。"
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

        return anchorDate.formatted(
            .dateTime
                .year()
                .month()
                .day()
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
            currentTitle: session.currentMemoryPresetTitle,
            presets: session.state.memoryPresets,
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
                activeConfigurationMessage:
                    activeConfigurationMessage
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
        activeConfigurationMessage =
            state.activeConfigurationMessage
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
                        availableAlbums:
                            availableAlbums,
                        selectedExistingAlbumIdentifier:
                            selectedExistingAlbumIdentifier,
                        newAlbumName:
                            newAlbumName
                    )
            )

        return await configurationApplyRuntimeCoordinator
            .apply(
                request,
                outputTarget: outputTarget
            )
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
        isOptimizingLogo = true
        logoStatusMessage = "正在优化 Logo"

        let update =
            await V1LogoSelectionCoordinator
            .optimize(item)
        applyLogoSelectionUpdate(update)

        isOptimizingLogo = false
    }

    private func applyLogoSelectionUpdate(
        _ update: V1LogoSelectionUpdate
    ) {
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

        if let activeConfigurationMessage =
            update.activeConfigurationMessage {
            self.activeConfigurationMessage =
                activeConfigurationMessage
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
            birthdayDate: birthdayDate
        )
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

    private var shareDiagnosticDisplayEvents:
        [PhotoMemoiOSQueueDiagnosticEventProjection] {

        PhotoMemoiOSQueueDiagnosticsProjectionEngine
            .eventDisplayProjections(
                from: shareDiagnosticEvents
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

    private func clearCompletedQueueHistory() {
        diagnosticsRefreshCoordinator
            .clearCompletedQueueHistory(
                preservingJobID:
                    backgroundStatusService
                    .currentSnapshot?
                    .jobID
            )
    }

    private var editorRevealProgress: CGFloat {
        let threshold: CGFloat = 30
        let distance: CGFloat = 120
        let traveled = max(-(profileOffsetY) - threshold, 0)
        return min(traveled / distance, 1)
    }

    private var previewPinProgress: CGFloat {
        let threshold: CGFloat = 6
        let distance: CGFloat = 56
        let traveled = max(-(previewOffsetY) - threshold, 0)
        return min(traveled / distance, 1)
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
            if let profile = values[.profile] {
                profileOffsetY = profile
            }
            if let preview = values[.preview] {
                previewOffsetY = preview
            }
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
            .processPickedPhotos(
                saveCurrentConfiguration: {
                    await applyCurrentV1Configuration()
                },
                importURLs: {
                    await V1PhotoIntakeImporter
                        .importURLs(from: items)
                },
                submit: { resolvedURLs in
                    externalIntakeCenter.submit(
                        urls: resolvedURLs,
                        source: .quickAction
                    )
                }
            )

        switch result.status {
        case .configurationSaveFailed:
            return
        case .noSupportedPhotos:
            activeConfigurationMessage =
                V1PhotoIntakeUnsupportedMessagePresenter
                .message(
                    for:
                        items
                        .flatMap(
                            \.supportedContentTypes
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
                            session.state.memoryPresets
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
                            session.state.memoryPresets
                    )
                else {
                    return
                }

                session.selectMemoryPreset(
                    update.preset
                )
                bootstrapDrafts()
                pendingActivationPresetTitle =
                    update.pendingActivationPresetTitle
                activeConfigurationMessage =
                    update.activeConfigurationMessage
                showsPresetActivationConfirmation =
                    update.showsPresetActivationConfirmation
            }
        )
    }

    private func expansionBinding(
        for section: PhotoMemoiOSV1EntrySection
    ) -> Binding<Bool> {
        Binding(
            get: {
                expandedEditorSections.contains(section)
            },
            set: { isExpanded in
                if isExpanded {
                    expandedEditorSections.insert(section)
                } else {
                    expandedEditorSections.remove(section)
                }
            }
        )
    }
}

private enum PhotoMemoiOSV1EntrySection: Hashable {
    case region(CardRegion)
    case logo
    case anchor
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
