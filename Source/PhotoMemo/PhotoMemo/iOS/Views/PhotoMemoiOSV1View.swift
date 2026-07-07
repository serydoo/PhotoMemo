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
    private var locationDisplayConfiguration:
        ExpressionModuleConfiguration? =
        LocationDisplayInspectorPresenter
        .configuration(
            for: "legacyDisplay"
        )

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
    private var birthdayDateChangeBehavior:
        V1BirthdayDateChangeBehavior = .userInitiated

    @State
    private var shouldSaveSubjectLibrary = true

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
            saveCurrentMemoryPreset: {
                session.saveCurrentMemoryPreset()
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

                tasksPage
                    .tabItem {
                        Label("任务", systemImage: "checklist")
                    }
                    .tag(V1EntryTab.tasks)
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
            isPresented: $entryFlowState.showsSettingsPage
        ) {
            NavigationStack {
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
                            savedStatus:
                                .dirty,
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
        .onChange(of: session.state.selectedMemoryPresetID) { _, _ in
            isEditingMemoryPresetTitle = false
            memoryPresetTitleFieldFocused = false
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
        .onChange(of: logoMode) { _, _ in
            activeConfigurationStatus = .dirty
        }
        .onChange(of: outputTarget) { _, _ in
            activeConfigurationStatus = .dirty
        }
        .onChange(of: selectedExistingAlbumIdentifier) { _, _ in
            activeConfigurationStatus = .dirty
        }
        .onChange(of: newAlbumName) { _, _ in
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

    private var homePage: some View {
        V1HomePageSurface(
            subjectSummary: homeSubjectSummaryProjection,
            subject: session.state.selectedSubject,
            borderStyleName: currentBorderStyleName,
            borderStyleDescription: currentBorderStyleDescription,
            presetSummary: homePresetSummaryProjection,
            presetStatusTone: currentPresetStatusTone,
            presetSavedStatusText: homePresetSavedStatusText,
            hasHomePresetSelection: !homeAvailablePresets.isEmpty,
            isEditingMemoryPresetTitle: isEditingMemoryPresetTitle,
            memoryPresetTitleDraft: $memoryPresetTitleDraft,
            memoryPresetTitleFieldFocused: $memoryPresetTitleFieldFocused,
            onOpenSubject: {
                entryFlowState =
                    V1EntryFlowCoordinator
                    .openSubjectOverview(
                        from:
                            entryFlowState
                    )
            },
            onCommitMemoryPresetTitle: commitMemoryPresetTitle,
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
                    .openSettingsPage(
                        from:
                            entryFlowState
                    )
            },
            onOpenSettings: {
                entryFlowState =
                    V1EntryFlowCoordinator
                    .openSettingsPage(
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
            configurationOptionList
            editorCluster
        } accessoryContent: {
            configurationPresetActionPanel
        }
        .navigationTitle("配置中心")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var configurationOptionList: some View {
        let locationPresentation =
            LocationDisplayInspectorPresenter.presentation
        let selectedLocationValue =
            ConfigurationCenterLocationDisplaySupport
            .summaryValue(
                module: locationDisplayModule,
                presentation: locationPresentation
            )

        return V1ConfigurationOptionList(
            logoMode: $logoMode,
            selectedLogoItem: $selectedLogoItem,
            logoValue: logoMode.title,
            logoDetail: logoRowDetail,
            subjectAvatarPreviewImagePath:
                resolvedSubjectAvatarPreviewImagePath,
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
                currentBorderStyleName
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
                        .font(.headline.weight(.semibold))
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
                presentation: presentation
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
            isLocationSelectable:
                locationDisplayModule != nil,
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

    private var configurationPresetActionPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                RoundedRectangle(
                    cornerRadius: 12,
                    style: .continuous
                )
                .fill(Color.accentColor.opacity(0.10))
                .frame(width: 38, height: 38)
                .overlay {
                    Image(systemName: "rectangle.stack.badge.plus")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("配置操作")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(configurationPresetActionDetail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            ViewThatFits {
                HStack(spacing: 10) {
                    createConfigurationButton
                    saveCurrentConfigurationButton
                }

                VStack(spacing: 10) {
                    createConfigurationButton
                    saveCurrentConfigurationButton
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
            .fill(ConfigurationUI.controlBackground.opacity(0.72))
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
            .stroke(ConfigurationUI.faintHairline)
        )
    }

    private var createConfigurationButton: some View {
        Button {
            session.createMemoryPresetFromCurrent()
            memoryPresetTitleDraft = session.currentMemoryPresetTitle
            isEditingMemoryPresetTitle = true
            activeConfigurationStatus = .dirty
        } label: {
            Label("新建配置", systemImage: "plus")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
    }

    private var saveCurrentConfigurationButton: some View {
        Button {
            Task {
                await applyCurrentV1Configuration()
            }
        } label: {
            Label(
                isSavingConfiguration
                ? "正在保存"
                : "保存为当前配置",
                systemImage:
                    isSavingConfiguration
                    ? "hourglass"
                    : "checkmark.circle"
            )
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(isSavingConfiguration)
    }

    private var configurationPresetActionDetail: String {
        if session.selectedMemoryPresetIsApplied {
            return "当前配置已同步，后续新建配置会从现在的对象、锚点、区域和输出设置复制。"
        }

        return "保存会同步当前对象、锚点、区域内容与输出设置；新建配置只在配置中心底部创建。"
    }

    private var outputPage: some View {
        V1OutputPageSurface(
            outputTarget: $outputTarget,
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
            recoveryMessage: processingDiagnosticsSnapshot.recoveryMessage,
            events: shareDiagnosticEvents,
            onRefresh: refreshProcessingState,
            onClearCompletedHistory: clearCompletedQueueHistory,
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
                activeConfigurationStatus = .dirty
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
        activeConfigurationStatus = .dirty
        isEditingMemoryPresetTitle = false
        memoryPresetTitleFieldFocused = false
    }

    private func activateHomePreset(
        _ preset: MemoryPreset
    ) {
        session.selectMemoryPreset(preset)
        bootstrapDrafts()
        activeConfigurationStatus = .saving

        Task {
            await applyCurrentV1Configuration()
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
                systemImage: "seal.fill"
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

        if let activeConfigurationStatus =
            update.activeConfigurationStatus {
            self.activeConfigurationStatus =
                activeConfigurationStatus
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
                locationDisplayConfiguration =
                    LocationDisplayInspectorPresenter
                    .configuration(
                        for: optionID
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
        expandedEditorSections.insert(
            .region(region)
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

private struct V1ConfigurationOptionList: View {

    @Binding var logoMode: V1LogoMode
    @Binding var selectedLogoItem: PhotosPickerItem?
    let logoValue: String
    let logoDetail: String
    let subjectAvatarPreviewImagePath: String?
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

    var body: some View {
        VStack(spacing: 0) {
            logoRow

            optionDivider

            timeAnchorRow

            optionDivider

            locationRow

            optionDivider

            memoryDisplayRow

            optionDivider

            borderStyleRow
        }
        .background(
            RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
            .fill(Color.white.opacity(0.94))
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
            .stroke(ConfigurationUI.faintHairline)
        )
        .shadow(
            color: Color.black.opacity(0.045),
            radius: 14,
            y: 6
        )
    }

    private var logoRow: some View {
        configurationRow(
            icon: logoIcon,
            title: "头像与标识",
            subtitle: "设置头像、Logo 与身份标识",
            value: logoValue,
            detail: logoDetail
        ) {
            HStack(spacing: 6) {
                Menu {
                    ForEach(V1LogoMode.allCases) { mode in
                        Button {
                            logoMode = mode
                        } label: {
                            Label(
                                mode.title,
                                systemImage:
                                    mode == logoMode
                                    ? "checkmark"
                                    : "circle"
                            )
                        }
                    }
                } label: {
                    optionSelectionPill(title: logoValue)
                }

                if logoMode == .customUpload {
                    PhotosPicker(
                        selection: $selectedLogoItem,
                        matching: .images
                    ) {
                        Image(
                            systemName:
                                isOptimizingLogo
                                ? "hourglass"
                                : "photo.badge.plus"
                        )
                        .font(.caption.weight(.semibold))
                        .frame(width: 26, height: 26)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.accentColor)
                    .disabled(isOptimizingLogo)
                    .accessibilityLabel("选择 Logo")
                }
            }
        }
    }

    private var timeAnchorRow: some View {
        configurationRow(
            systemImage: "calendar.badge.clock",
            tint: .blue,
            title: "时间锚点",
            subtitle: "定义时间参考，计算年龄与天数",
            value:
                availableTimeAnchors.isEmpty
                ? "暂无"
                : timeAnchorTitle,
            detail:
                "\(timeAnchorCount) 个锚点"
        ) {
            if availableTimeAnchors.isEmpty {
                optionSelectionPill(title: "暂无")
                    .opacity(0.72)
            } else {
                Menu {
                    ForEach(availableTimeAnchors) { anchor in
                        Button {
                            selectedTimeAnchorID.wrappedValue =
                                anchor.id
                        } label: {
                            Label(
                                anchor.title,
                                systemImage:
                                    anchor.id
                                    == selectedTimeAnchorID
                                    .wrappedValue
                                    ? "checkmark"
                                    : "circle"
                            )
                        }
                    }
                } label: {
                    optionSelectionPill(title: timeAnchorTitle)
                }
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
                : "未插入位置模块"
        ) {
            Menu {
                ForEach(locationPresentation.options) { option in
                    Button {
                        selectedLocationOptionID.wrappedValue =
                            option.id
                    } label: {
                        Label(
                            option.title,
                            systemImage:
                                option.id
                                == selectedLocationOptionID
                                .wrappedValue
                                ? "checkmark"
                                : "circle"
                        )
                    }
                }
            } label: {
                optionSelectionPill(title: selectedLocationValue)
            }
            .disabled(isLocationSelectable == false)
            .opacity(isLocationSelectable ? 1 : 0.62)
        }
    }

    private var memoryDisplayRow: some View {
        configurationRow(
            systemImage: "heart",
            tint: .pink,
            title: "记忆显示",
            subtitle: "自定义表达方式与记忆内容",
            value: memoryDisplayValue,
            detail: memoryDisplayDetail
        ) {
            if availableMemoryDisplayStyles.isEmpty {
                optionSelectionPill(title: "暂无")
                    .opacity(0.72)
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
                            Label(
                                style.displayTitle,
                                systemImage:
                                    style
                                    == selectedMemoryDisplayStyle
                                    .wrappedValue
                                    ? "checkmark"
                                    : "circle"
                            )
                        }
                    }
                } label: {
                    optionSelectionPill(title: memoryDisplayValue)
                }
            }
        }
    }

    private var borderStyleRow: some View {
        configurationRow(
            systemImage: "paintpalette",
            tint: .orange,
            title: "边框样式",
            subtitle: "选择边框样式与整体风格",
            value: borderStyleName,
            detail: "当前锁定"
        ) {
            optionSelectionPill(title: borderStyleName)
        }
    }

    private var logoIcon: some View {
        ZStack {
            RoundedRectangle(
                cornerRadius: 14,
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
                            cornerRadius: 14,
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
                    .padding(8)
            } else {
                Image(systemName: "apple.logo")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.primary.opacity(0.78))
            }
        }
        .frame(width: 48, height: 48)
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
            trailing: trailing
        )
    }

    private func configurationRow<Icon: View, Trailing: View>(
        icon: Icon,
        title: String,
        subtitle: String,
        value: String,
        detail: String,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        HStack(alignment: .center, spacing: 14) {
            icon

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .layoutPriority(1)

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 6) {
                trailing()

                Text(detail)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
            .frame(
                minWidth: 92,
                maxWidth: 132,
                alignment: .trailing
            )
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 15)
        .contentShape(Rectangle())
    }

    private func optionSelectionPill(title: String) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary.opacity(0.76))
                .lineLimit(1)
                .minimumScaleFactor(0.76)

            Image(systemName: "chevron.down")
                .font(.caption2.weight(.bold))
                .foregroundStyle(Color.accentColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .background(
            Capsule(style: .continuous)
                .fill(ConfigurationUI.controlBackground.opacity(0.86))
        )
    }

    private func rowIcon(
        systemImage: String,
        tint: Color
    ) -> some View {
        ZStack {
            RoundedRectangle(
                cornerRadius: 14,
                style: .continuous
            )
            .fill(tint.opacity(0.11))

            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))
                .foregroundStyle(tint)
                .symbolRenderingMode(.hierarchical)
        }
        .frame(width: 48, height: 48)
    }

    private var optionDivider: some View {
        Rectangle()
            .fill(ConfigurationUI.faintHairline)
            .frame(height: 0.5)
            .padding(.leading, 76)
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
