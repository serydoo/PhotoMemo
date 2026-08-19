#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI
import UIKit

struct ConfigurationCenteriOSView: View {

    @AppStorage(
        MemoMarkLanguage.interfacePreferenceStorageKey,
        store: PhotoMemoSharedContainer.sharedUserDefaults
    )
    private var interfaceLanguagePreferenceRawValue =
        MemoMarkInterfaceLanguagePreference.system.rawValue

    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass

    @ObservedObject
    var runtime: PhotoMemoAppRuntime

    @ObservedObject
    private var commerceStore:
        MemoMarkCommerceStore

    @StateObject
    private var session: ConfigurationSession

    @State
    private var selectedPanel:
        IOSConfigurationPanel = .card(.slotD)

    @State
    private var isRenamingProfile = false

    @State
    private var regionDraftStore =
        ConfigurationCenterRegionDraftStore()

    @State
    private var selectedLocationDisplayConfiguration:
        ExpressionModuleConfiguration?

    @State
    private var showsSettingsSheet = false

    @State
    private var showsMemoMarkPlus = false

    @State
    private var commerceMilestone:
        MemoMarkCommerceMilestone = .none

    @State
    private var showsWelcomePage = false

    @State
    private var showsWorkflowGuide = false

    @State
    private var showsCompactNavigator = false

    @State
    private var detailScrollOffsetY: CGFloat = 0

    @State
    private var processingDiagnosticsSnapshot:
        PhotoMemoiOSProcessingDiagnosticsSnapshot

    @State
    private var shareDiagnosticEvents:
        [PhotoMemoShareDiagnosticEvent]

    @ObservedObject
    private var backgroundStatusService:
        PhotoMemoBackgroundStatusService

    private let diagnosticsRefreshCoordinator:
        V1DiagnosticsRefreshCoordinator

    private var currentBorderStyleName: String {
        MemoMarkLanguage.interfaceStored.localized(
            key: "configuration.preview.basic_white",
            fallback: "基础白"
        )
    }

    init(
        runtime: PhotoMemoAppRuntime
    ) {
        self.runtime = runtime
        _commerceStore =
            ObservedObject(
                wrappedValue:
                    runtime.commerceStore
            )
        _selectedLocationDisplayConfiguration =
            State(
                initialValue:
                    Self
                    .loadLocationDisplayConfiguration(
                        from: runtime
                    )
            )
        _session = StateObject(
            wrappedValue:
                ConfigurationSession()
        )
        _backgroundStatusService =
            ObservedObject(
                wrappedValue:
                    runtime
                    .backgroundStatusService
            )

        let refreshCoordinator =
            V1DiagnosticsRefreshCoordinator(
                refreshExternalIntake:
                    runtime.refreshExternalIntakeState,
                diagnosticsRepository:
                    runtime
                    .environment
                    .repositories
                    .diagnostics,
                backgroundStatusService:
                    runtime
                    .backgroundStatusService,
                queueCoordinator:
                    runtime
                    .environment
                    .coordinators
                    .queue
            )
        self.diagnosticsRefreshCoordinator =
            refreshCoordinator

        let initialDiagnosticsState =
            refreshCoordinator
            .shareDiagnosticsState()
        _processingDiagnosticsSnapshot =
            State(
                initialValue:
                    initialDiagnosticsState
                    .snapshot
            )
        _shareDiagnosticEvents =
            State(
                initialValue:
                    initialDiagnosticsState
                    .events
            )
    }

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let usesCompactLayout =
                    usesCompactLayout(
                        for: proxy.size.width
                    )
                let sidebarWidth =
                    min(
                        max(proxy.size.width * 0.28, 148),
                        204
                    )

                VStack(spacing: 0) {
                    topConfigurationPreview(
                        usesCompactLayout:
                            usesCompactLayout
                    )

                    if usesCompactLayout {
                        detailSurface
                    } else {
                        HStack(spacing: 0) {
                            sidebar
                                .frame(width: sidebarWidth)

                            Rectangle()
                                .fill(ConfigurationUI.faintHairline)
                                .frame(width: 0.5)

                            detailSurface
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
                .background(
                    ConfigurationUI.appBackground
                        .ignoresSafeArea()
                )
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .onAppear {
            selectedLocationDisplayConfiguration =
                Self.loadLocationDisplayConfiguration(
                    from: runtime
                )
        }
        .sheet(
            isPresented:
                $showsSettingsSheet
        ) {
            settingsSheet
        }
        .sheet(
            isPresented:
                $showsMemoMarkPlus
        ) {
            MemoMarkPlusPurchaseView(
                store: commerceStore,
                onDismiss: {
                    showsMemoMarkPlus = false
                }
            )
        }
        .alert(
            commerceMilestoneTitle,
            isPresented:
                commerceMilestoneBinding
        ) {
            Button(
                commerceLocalized(
                    "commerce.milestone.learn_plus",
                    fallback: "了解 MemoMark+"
                )
            ) {
                showsMemoMarkPlus = true
            }
            Button(
                commerceLocalized(
                    "commerce.milestone.continue",
                    fallback: "继续记录"
                ),
                role: .cancel
            ) {}
        } message: {
            Text(commerceMilestoneMessage)
        }
        .onChange(
            of:
                commerceStore.snapshot
                .successfulRecordCount
        ) { _, count in
            let policy =
                commerceStore.isPlus
                ? MemoMarkCommercePolicy.plus
                : MemoMarkCommercePolicy(
                    isPlus: false,
                    totalAllowance:
                        commerceStore.snapshot
                        .totalAllowance,
                    batchLimit:
                        commerceStore.snapshot
                        .batchLimit
                )
            commerceMilestone =
                policy.milestone(after: count)
        }
        .sheet(
            isPresented:
                $showsWelcomePage
        ) {
            V1WelcomePageSurface(
                presentation:
                    V1WelcomePresentation
                    .localized(
                        for: .interfaceStored
                    ),
                language: .interfaceStored,
                onStart: {
                    showsWelcomePage = false
                },
                onShowWorkflow: {
                    showsWelcomePage = false
                    showsWorkflowGuide = true
                }
            )
        }
        .sheet(
            isPresented:
                $showsWorkflowGuide
        ) {
            V1WorkflowGuideSurface(
                steps: V1WelcomePresentation.workflowSteps(
                    for: .interfaceStored
                ),
                language: .interfaceStored,
                onClose: nil
            )
        }
        .sheet(
            isPresented:
                $showsCompactNavigator
        ) {
            compactNavigatorSheet
        }
    }

    private var commerceMilestoneBinding:
        Binding<Bool> {
        Binding(
            get: {
                commerceMilestone != .none
            },
            set: { isPresented in
                if !isPresented {
                    commerceMilestone = .none
                }
            }
        )
    }

    private var commerceMilestoneTitle: String {
        switch commerceMilestone {
        case .none:
            return commerceLocalized(
                "commerce.milestone.title",
                fallback: "成长记录"
            )
        case .approaching:
            return commerceFormatted(
                "commerce.milestone.approaching_title_format",
                fallback: "你已经留下 %lld 张成长记录",
                Int64(
                    commerceStore.snapshot
                        .successfulRecordCount
                )
            )
        case .allowanceCompleted:
            return commerceFormatted(
                "commerce.milestone.completed_title_format",
                fallback: "第 %lld 张成长记录已保存",
                Int64(
                    commerceStore.snapshot
                        .successfulRecordCount
                )
            )
        }
    }

    private var commerceMilestoneMessage: String {
        switch commerceMilestone {
        case .none:
            return ""
        case .approaching(let remaining):
            return commerceFormatted(
                "commerce.milestone.approaching_message_format",
                fallback: "还有 %lld 张免费成长记录。解锁 MemoMark+，继续记录此后的每一个瞬间。",
                Int64(remaining)
            )
        case .allowanceCompleted:
            return commerceLocalized(
                "commerce.milestone.completed_message",
                fallback: "照片已完整保存到 Apple Photos。解锁 MemoMark+，无限记录未来的时光。"
            )
        }
    }

    private var interfaceLanguage: MemoMarkLanguage {
        MemoMarkInterfaceLanguagePreference(
            rawValue: interfaceLanguagePreferenceRawValue
        )?.resolvedLanguage
        ?? MemoMarkLanguage.interfaceStored
    }

    private func commerceLocalized(
        _ key: String,
        fallback: String
    ) -> String {
        interfaceLanguage.localized(
            key: key,
            fallback: fallback
        )
    }

    private func commerceFormatted(
        _ key: String,
        fallback: String,
        _ arguments: CVarArg...
    ) -> String {
        String(
            format: commerceLocalized(
                key,
                fallback: fallback
            ),
            locale: interfaceLanguage.locale,
            arguments: arguments
        )
    }

    private var sidebar: some View {
        ConfigurationCenterSidebarView(
            language: interfaceLanguage,
            subjectGroups: sidebarSubjectGroups,
            cardItems: sidebarCardItems,
            memoryModuleItems: sidebarMemoryModuleItems,
            outputItems: sidebarOutputItems,
            guideItems: sidebarGuideItems,
            onBackgroundTap: dismissKeyboard
        )
    }

    private var detailSurface: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                detailScrollOffsetReader
                configurationSummarySection
                languageSection
                detailContent
            }
            .padding(.vertical, 16)
            .v1AdaptiveScrollContent(
                horizontalPadding: ConfigurationUI.contentColumnPadding
            )
        }
        .scrollDismissesKeyboard(.interactively)
        .background(ConfigurationUI.panelBackground)
        .coordinateSpace(name: "configuration-center-detail-scroll")
        .simultaneousGesture(
            TapGesture()
                .onEnded {
                    dismissKeyboard()
                }
        )
    }

    private var configurationSummarySection: some View {
        let slotCLocationModule =
            currentLocationModule(for: .slotC)
        let locationPresentation =
            LocationDisplayInspectorPresenter
            .presentation
        let selectedLocationValue =
            ConfigurationCenterLocationDisplaySupport
            .summaryValue(
                module: slotCLocationModule,
                presentation: locationPresentation,
                selectedConfiguration:
                    savedLocationDisplayConfiguration
            )

        return ConfigurationCenterSummarySection(
            language: interfaceLanguage,
            subject: session.state.selectedSubject,
            selectedRegion: session.state.selectedRegion,
            currentBorderStyleName: currentBorderStyleName,
            locationPresentation: locationPresentation,
            selectedLocationValue: selectedLocationValue,
            locationDetail:
                ConfigurationCenterLocationDisplaySupport
                .summaryDetail(
                    module: slotCLocationModule,
                    selectedValue: selectedLocationValue
                ),
            selectedLocationOptionID:
                locationDisplayOptionBinding(
                    for: .slotC
                ),
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
                applySelectionUpdate(
                    ConfigurationCenterSelectionCoordinator
                        .showSubjectPanel()
                )
            },
            onSelectRegion: { region in
                applySelectionUpdate(
                    ConfigurationCenterSelectionCoordinator
                        .showCard(region: region)
                )
            }
        )
    }

    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(localized(
                "configuration.output.language_title",
                fallback: "输出语言"
            ))
                .font(.headline.weight(.semibold))

            Picker(
                localized(
                    "configuration.output.language_picker",
                    fallback: "智能模块与输出语言"
                ),
                selection: Binding(
                    get: { session.presetOutputLanguage },
                    set: { session.presetOutputLanguage = $0 }
                )
            ) {
                ForEach(MemoMarkLanguage.allCases, id: \.self) { language in
                    Text(language.displayTitle)
                        .tag(language)
                }
            }
            .pickerStyle(.segmented)

            Text(localized(
                "configuration.output.language_detail",
                fallback: "只影响系统生成的智能模块和日期表达；你填写的名称、句子与照片原始信息不会被翻译。"
            ))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(ConfigurationUI.controlBackground.opacity(0.72))
        )
    }

    private var savedLocationDisplayConfiguration:
        ExpressionModuleConfiguration? {
        selectedLocationDisplayConfiguration
    }

    private func topConfigurationPreview(
        usesCompactLayout: Bool
    ) -> some View {
        ConfigurationCenterTopPreviewSection(
            session: session,
            isCurrentPresetApplied:
                session.selectedMemoryPresetIsApplied,
            currentBorderStyleName: currentBorderStyleName,
            currentPresetStatusText:
                ConfigurationCenterSessionBindingPresenter
                .presetStatusText(session: session),
            previewPinProgress:
                detailPreviewPinProgress,
            showsNavigatorButton:
                usesCompactLayout,
            showsMemoMarkPlusBadge:
                commerceStore.isPlus,
            isRenamingProfile: $isRenamingProfile,
            profileTitle: profileTitleBinding,
            onDismissKeyboard: dismissKeyboard,
            onBeginRename: {
                dismissKeyboard()
                isRenamingProfile.toggle()
            },
            onResetPreset: {
                session.resetSelectedMemoryPreset()
            },
            onOpenSettings: {
                dismissKeyboard()
                refreshProcessingState()
                showsSettingsSheet = true
            },
            onOpenMemoMarkPlus: {
                dismissKeyboard()
                showsMemoMarkPlus = true
            },
            onOpenNavigator: {
                dismissKeyboard()
                showsCompactNavigator = true
            },
            onRegionSelection: { region in
                applySelectionUpdate(
                    ConfigurationCenterSelectionCoordinator
                        .showCard(region: region)
                )
            }
        ) {
            profilePresetMenu
        }
    }

    private var compactNavigatorSheet: some View {
        NavigationStack {
            sidebar
                .navigationTitle(localized(
                    "configuration.navigation.title",
                    fallback: "配置导航"
                ))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(
                        placement: .topBarTrailing
                    ) {
                        Button(localized(
                            "configuration.navigation.done",
                            fallback: "完成"
                        )) {
                            showsCompactNavigator = false
                        }
                        .font(.caption.weight(.semibold))
                    }
                }
        }
        .presentationDetents([.medium, .large])
    }

    private var detailScrollOffsetReader: some View {
        GeometryReader { proxy in
            Color.clear
                .preference(
                    key:
                        ConfigurationCenterDetailScrollOffsetPreferenceKey.self,
                    value:
                        proxy.frame(
                            in: .named(
                                "configuration-center-detail-scroll"
                            )
                        ).minY
                )
        }
        .frame(height: 0)
        .onPreferenceChange(
            ConfigurationCenterDetailScrollOffsetPreferenceKey.self
        ) { value in
            detailScrollOffsetY = value
        }
    }

    private var detailPreviewPinProgress: CGFloat {
        let threshold: CGFloat = 10
        let distance: CGFloat = 72
        let traveled =
            max(
                -(detailScrollOffsetY) - threshold,
                0
            )
        return min(traveled / distance, 1)
    }

    private var settingsSheet: some View {
        NavigationStack {
            V1SettingsPageSurface(
                commerceSnapshot:
                    commerceStore.snapshot,
                onOpenMemoMarkPlus: {
                    showsSettingsSheet = false
                    Task { @MainActor in
                        await Task.yield()
                        showsMemoMarkPlus = true
                    }
                },
                onShowWelcome: {
                    showsSettingsSheet = false
                    showsWelcomePage = true
                },
                onDismissKeyboard: dismissKeyboard,
                onExportDiagnostics: {
                    try await runtime.environment
                        .repositories
                        .productionDiagnostics
                        .makeExport()
                }
            )
            .toolbar {
                ToolbarItem(
                    placement: .topBarTrailing
                ) {
                    Button(
                        localized(
                            "common.done",
                            fallback: "完成"
                        )
                    ) {
                        showsSettingsSheet = false
                    }
                    .font(.caption.weight(.semibold))
                }
            }
        }
    }

    private var profilePresetMenu: some View {
        ConfigurationCenterPresetMenu(
            language: interfaceLanguage,
            presets: session.state.memoryPresets,
            selectedPreset: session.state.selectedMemoryPreset,
            currentTitle: session.currentMemoryPresetTitle,
            onSelectPreset: { preset in
                session.selectMemoryPreset(preset)
            }
        )
    }

    @ViewBuilder
    private var detailContent: some View {
        let presentation =
            ConfigurationCenterDetailPresenter
            .panelPresentation(
                for: selectedPanel
            )

        switch presentation.content {
        case .subject:
            subjectDetail(
                using: presentation
            )

        case .card:
            cardDetail

        case .memoryModule:
            ConfigurationCenterDetailPanelSection(
                language: interfaceLanguage,
                title: presentation.title ?? "",
                systemImage:
                    presentation.systemImage ?? "",
                content: .memoryModule(
                    model: memoryWritePanelModel,
                    usesCustomText:
                        memoryWriteToggleBinding,
                    customText:
                        memoryWriteTextBinding
                )
            )

        case .output:
            ConfigurationCenterDetailPanelSection(
                language: interfaceLanguage,
                title: presentation.title ?? "",
                systemImage:
                    presentation.systemImage ?? "",
                content: .output(
                    model:
                        outputSelectionPanelModel,
                    storageOption:
                        storageOptionBinding,
                    onOpenMemoryModule: {
                        applySelectionUpdate(
                            ConfigurationCenterSelectionCoordinator
                                .showPanel(.memoryModule)
                        )
                    }
                )
            )

        case .configurationGuide:
            ConfigurationCenterDetailPanelSection(
                language: interfaceLanguage,
                title: presentation.title ?? "",
                systemImage:
                    presentation.systemImage ?? "",
                content: .configurationGuide(
                    items:
                        configurationGuideCards
                )
            )
        }
    }

    private func subjectDetail(
        using presentation:
            ConfigurationCenterDetailPanelPresentation
    ) -> some View {
        IOSDetailPanel(
            title: presentation.title ?? "",
            systemImage: presentation.systemImage ?? "",
            subtitle: presentation.subtitle
        ) {
            MemorySubjectEditorView(session: session)
        }
    }

    private var cardDetail: some View {
        VStack(alignment: .leading, spacing: 14) {
            activeRegionEditor

            locationDisplayInspector

            if shouldShowInsertableModules {
                fixedInsertableModuleLibrary
            }
        }
    }

    private var locationDisplayInspector: some View {
        ConfigurationCenterLocationDisplayPanel(
            presentation:
                LocationDisplayInspectorPresenter
                .presentation,
            locationModule:
                currentLocationModule,
            selectedOptionID:
                locationDisplayOptionBinding
        )
    }

    private var activeRegionEditor: some View {
        let presentation =
            ConfigurationCenterDetailPresenter
            .regionEditorPresentation(
                for:
                    session.state.selectedRegion
            )

        return ConfigurationCenterActiveRegionEditorSection(
            language: interfaceLanguage,
            title: presentation.title,
            systemImage: presentation.systemImage,
            selectedRegion: session.state.selectedRegion
        ) {
            activeRegionEditorContent
        }
    }

    @ViewBuilder
    private var activeRegionEditorContent: some View {
        let presentation =
            ConfigurationCenterDetailPresenter
            .regionEditorPresentation(
                for:
                    session.state.selectedRegion
            )

        switch presentation.content {
        case .iconLibrary:
            IconLibraryView(session: session)
                .padding(8)
                .configurationPanelChrome()
        case .badgeLibrary:
            BadgeLibraryView(session: session)
                .padding(8)
                .configurationPanelChrome()
        case .regionComposer:
            ConfigurationCenterRegionComposerSection(
                language: interfaceLanguage,
                region: session.state.selectedRegion,
                configurationOptions:
                    regionDraftStore.configurationOptions(
                        for: session.state.selectedRegion
                    ),
                selectedConfigurationID:
                    selectedRegionConfigurationBinding(
                        for: session.state.selectedRegion
                    ),
                configurationName:
                    regionConfigurationNameBinding(
                        for: session.state.selectedRegion
                    ),
                isRenamingConfiguration:
                    renamingRegionConfigurationBinding(
                        for: session.state.selectedRegion
                    ),
                isSaved:
                    regionDraftStore.isSaved(
                        for: session.state.selectedRegion
                    ),
                text: regionTextBinding(
                    for: session.state.selectedRegion
                ),
                continuationText:
                    regionContinuationTextBinding(
                        for: session.state.selectedRegion
                    ),
                modules: regionModulesBinding(
                    for: session.state.selectedRegion
                ),
                showsMemorySystemModules:
                    CardRegion.memoryCardRegions.contains(
                        session.state.selectedRegion
                    ),
                onSaveConfiguration: {
                    regionDraftStore.markSaved(
                        for: session.state.selectedRegion
                    )
                },
                onDeleteModule: {
                    removeInsertedModule(
                        $0,
                        from: session.state.selectedRegion
                    )
                }
            )
        case .subject:
            MemorySubjectEditorView(session: session)
        }
    }

    private var memoryWritePanelModel:
        ConfigurationCenterMemoryWritePanelModel {
        ConfigurationCenterMemoryWritePanelModel(
            description:
                ConfigurationCenterSessionBindingPresenter
                .memoryWriteDescription(session: session),
            toggleTitle:
                ConfigurationCenterSessionBindingPresenter
                .memoryWriteToggleTitle,
            inputPlaceholder:
                ConfigurationCenterSessionBindingPresenter
                .customMemoryWritePlaceholder,
            resolvedTitle:
                ConfigurationCenterSessionBindingPresenter
                .memoryWritePreviewTitle(session: session),
            resolvedText:
                session.resolvedMemoryWriteText,
            showsCustomTextField:
                session.usesCustomMemoryWriteText
        )
    }

    private var fixedInsertableModuleLibrary: some View {
        ConfigurationCenterInsertableModuleLibrarySection(
            language: interfaceLanguage,
            visibleModules: visibleInsertableModules,
            additionalModules: additionalInsertableModules,
            onInsertModule: insertModuleIntoCurrentRegion
        )
    }

    private var outputSelectionPanelModel:
        ConfigurationCenterOutputSelectionPanelModel {
        let memoryWritePresentation =
            MemoryWriteOptionPresenter
            .presentation(
                usesCustomText:
                    session.usesCustomMemoryWriteText,
                resolvedText:
                    session.resolvedMemoryWriteText
            )

        return ConfigurationCenterOutputSelectionPanelModel(
            presentation:
                ConfigurationCenterOutputPanelPresenter
                .presentation(
                    outputOption:
                        session.selectedOutputOption,
                    storageOption:
                        session.selectedStorageOption,
                    memoryWritePresentation:
                        memoryWritePresentation
                )
        )
    }

    private var configurationGuideCards:
        [ConfigurationCenterGuideCardModel] {
        [
            ConfigurationCenterGuideCardModel(
                title: localized(
                    "configuration.guide.regions.title",
                    fallback: "四个自定义区域"
                ),
                note:
                    localized(
                        "configuration.guide.regions.note",
                        fallback: "插入内容进入当前选中的区域，不走隐式兜底。"
                    ),
                systemImage:
                    "rectangle.and.pencil.and.ellipsis"
            ),
            ConfigurationCenterGuideCardModel(
                title: localized(
                    "configuration.guide.anchor.title",
                    fallback: "当前生效锚点与智能结果"
                ),
                note:
                    localized(
                        "configuration.guide.anchor.note",
                        fallback: "当前生效锚点和照片时间会组合成 1 个智能结果，并可插入任意区域。"
                    ),
                systemImage:
                    "calendar.badge.clock"
            ),
            ConfigurationCenterGuideCardModel(
                title: localized(
                    "configuration.guide.output.title",
                    fallback: "输出与相册保存"
                ),
                note:
                    localized(
                        "configuration.guide.output.note",
                        fallback: "默认生成处理过的新图片，原图保持不变。"
                    ),
                systemImage:
                    "square.and.arrow.down"
            ),
            ConfigurationCenterGuideCardModel(
                title: localized(
                    "configuration.guide.about.title",
                    fallback: "关于时光记"
                ),
                note:
                    localized(
                        "configuration.guide.about.note",
                        fallback: "帮助用户阅读回忆，而不只是保存照片。"
                    ),
                systemImage: "info.circle"
            )
        ]
    }

    private func subjectIconName(
        _ subject: MemorySubject
    ) -> String {
        subject.decorations
            .first(where: { $0.kind == .icon })?
            .systemSymbolName ?? "person.fill"
    }

    private var shouldShowInsertableModules: Bool {
        ConfigurationCenterInsertableModulePolicy
            .shouldShowModules(
                for: session.state.selectedRegion
            )
    }

    private var visibleInsertableModules: [IOSInsertableModule] {
        ConfigurationCenterInsertableModulePolicy
            .visibleModules(
                for: session.state.selectedRegion
            )
    }

    private var additionalInsertableModules: [IOSInsertableModule] {
        ConfigurationCenterInsertableModulePolicy
            .additionalModules(
                for: session.state.selectedRegion
            )
    }

    private var sidebarSubjectGroups:
        [ConfigurationCenterSidebarSubjectGroup] {
        [
            ConfigurationCenterSidebarSubjectGroup(
                title: localized(
                    "configuration.sidebar.people",
                    fallback: "人物对象"
                ),
                addTitle: localized(
                    "configuration.sidebar.add_people",
                    fallback: "新增人物对象"
                ),
                items:
                    session.state.subjects
                    .filter {
                        $0.relationship.role == "家庭"
                    }
                    .map(sidebarItem(for:)),
                addAction: {
                    applySelectionUpdate(
                        ConfigurationCenterSelectionCoordinator
                            .showSubjectPanel()
                    )
                }
            ),
            ConfigurationCenterSidebarSubjectGroup(
                title: localized(
                    "configuration.sidebar.events",
                    fallback: "事件对象"
                ),
                addTitle: localized(
                    "configuration.sidebar.add_event",
                    fallback: "新增事件对象"
                ),
                items:
                    session.state.subjects
                    .filter {
                        $0.relationship.role == "事件"
                        || $0.relationship.role == "旅行"
                    }
                    .map(sidebarItem(for:)),
                addAction: {
                    applySelectionUpdate(
                        ConfigurationCenterSelectionCoordinator
                            .showSubjectPanel()
                    )
                }
            )
        ]
    }

    private var sidebarCardItems:
        [ConfigurationCenterSidebarItem] {
        [
            sidebarCardItem(
                title: localized("configuration.sidebar.icon", fallback: "图标"),
                subtitle: localized("configuration.sidebar.icon_detail", fallback: "图标装饰"),
                systemImage: "person.crop.circle",
                region: .icon
            ),
            sidebarCardItem(
                title: localized("configuration.sidebar.record", fallback: "记录"),
                subtitle: localized("configuration.sidebar.record_detail", fallback: "卡片左上"),
                systemImage: "camera.fill",
                region: .slotA
            ),
            sidebarCardItem(
                title: localized("configuration.sidebar.time", fallback: "时间"),
                subtitle: localized("configuration.sidebar.time_detail", fallback: "卡片左下"),
                systemImage: "calendar",
                region: .slotB
            ),
            sidebarCardItem(
                title: localized("configuration.sidebar.capture", fallback: "拍摄信息"),
                subtitle: localized("configuration.sidebar.capture_detail", fallback: "卡片右上"),
                systemImage: "scope",
                region: .slotC
            ),
            sidebarCardItem(
                title: localized("configuration.sidebar.memory", fallback: "记忆内容"),
                subtitle: localized("configuration.sidebar.memory_detail", fallback: "卡片右下 · 默认承载"),
                systemImage: "text.quote",
                region: .slotD
            )
        ]
    }

    private var sidebarMemoryModuleItems:
        [ConfigurationCenterSidebarItem] {
        [
            ConfigurationCenterSidebarItem(
                title: localized("configuration.sidebar.smart", fallback: "智能模块"),
                subtitle: localized("configuration.sidebar.smart_detail", fallback: "生成、承载与智能写入"),
                systemImage: "text.badge.checkmark",
                isSelected:
                    selectedPanel == .memoryModule,
                action: {
                    applySelectionUpdate(
                        ConfigurationCenterSelectionCoordinator
                            .showPanel(.memoryModule)
                    )
                }
            )
        ]
    }

    private var sidebarOutputItems:
        [ConfigurationCenterSidebarItem] {
        [
            ConfigurationCenterSidebarItem(
                title: localized("configuration.sidebar.output", fallback: "输出"),
                subtitle: localized("configuration.sidebar.output_detail", fallback: "处理过的图片"),
                systemImage: MemoMarkSymbol.output.name,
                isSelected:
                    selectedPanel == .output,
                action: {
                    applySelectionUpdate(
                        ConfigurationCenterSelectionCoordinator
                            .showPanel(.output)
                    )
                }
            )
        ]
    }

    private var sidebarGuideItems:
        [ConfigurationCenterSidebarItem] {
        [
            ConfigurationCenterSidebarItem(
                title: localized("configuration.sidebar.guide", fallback: "配置说明"),
                subtitle: localized("configuration.sidebar.guide_detail", fallback: "对象、锚点与输出原则"),
                systemImage: MemoMarkSymbol.help.name,
                isSelected:
                    selectedPanel == .configurationGuide,
                action: {
                    applySelectionUpdate(
                        ConfigurationCenterSelectionCoordinator
                            .showPanel(.configurationGuide)
                    )
                }
            )
        ]
    }

    private func sidebarItem(
        for subject: MemorySubject
    ) -> ConfigurationCenterSidebarItem {
        ConfigurationCenterSidebarItem(
            title: subject.identity.displayName,
            subtitle: subject.relationship.label,
            systemImage: subjectIconName(subject),
            isSelected:
                ConfigurationCenterSelectionCoordinator
                .isSelectedSubject(
                    panel: selectedPanel,
                    selectedSubjectID:
                        session.state.selectedSubject?.id,
                    candidateSubjectID: subject.id
                ),
            action: {
                applySelectionUpdate(
                    ConfigurationCenterSelectionCoordinator
                        .showSubject(subject)
                )
            }
        )
    }

    private func localized(
        _ key: String,
        fallback: String
    ) -> String {
        interfaceLanguage.localized(key: key, fallback: fallback)
    }

    private func sidebarCardItem(
        title: String,
        subtitle: String,
        systemImage: String,
        region: CardRegion
    ) -> ConfigurationCenterSidebarItem {
        ConfigurationCenterSidebarItem(
            title: title,
            subtitle: subtitle,
            systemImage: systemImage,
            isSelected:
                selectedPanel == .card(region),
            action: {
                applySelectionUpdate(
                    ConfigurationCenterSelectionCoordinator
                        .showCard(region: region)
                )
            }
        )
    }

    private func regionTextBinding(
        for region: CardRegion
    ) -> Binding<String> {
        Binding(
            get: {
                regionBindingAdapter(for: region)
                    .text()
            },
            set: { newValue in
                applyRegionBindingMutation(
                    regionBindingAdapter(for: region)
                        .setText(newValue),
                    for: region
                )
            }
        )
    }

    private func regionModulesBinding(
        for region: CardRegion
    ) -> Binding<[IOSInsertedModule]> {
        Binding(
            get: {
                regionBindingAdapter(for: region)
                    .modules()
            },
            set: {
                applyRegionBindingMutation(
                    regionBindingAdapter(for: region)
                        .setModules($0),
                    for: region
                )
            }
        )
    }

    private func regionContinuationTextBinding(
        for region: CardRegion
    ) -> Binding<String> {
        Binding(
            get: {
                regionBindingAdapter(for: region)
                    .continuationText()
            },
            set: {
                applyRegionBindingMutation(
                    regionBindingAdapter(for: region)
                        .setContinuationText($0),
                    for: region
                )
            }
        )
    }

    private func selectedRegionConfigurationBinding(
        for region: CardRegion
    ) -> Binding<String> {
        Binding(
            get: {
                regionBindingAdapter(for: region)
                    .selectedConfigurationID()
            },
            set: { newValue in
                applyRegionBindingMutation(
                    regionBindingAdapter(for: region)
                        .setSelectedConfigurationID(
                            newValue
                        ),
                    for: region
                )
            }
        )
    }

    private func regionConfigurationNameBinding(
        for region: CardRegion
    ) -> Binding<String> {
        Binding(
            get: {
                regionBindingAdapter(for: region)
                    .configurationName()
            },
            set: { newValue in
                applyRegionBindingMutation(
                    regionBindingAdapter(for: region)
                        .setConfigurationName(
                            newValue
                        ),
                    for: region
                )
            }
        )
    }

    private func renamingRegionConfigurationBinding(
        for region: CardRegion
    ) -> Binding<Bool> {
        Binding(
            get: {
                regionBindingAdapter(for: region)
                    .isRenamingConfiguration()
            },
            set: { isRenaming in
                applyRegionBindingMutation(
                    regionBindingAdapter(for: region)
                        .setRenamingConfiguration(
                            isRenaming
                        ),
                    for: region
                )
            }
        )
    }

    private func insertModuleIntoCurrentRegion(
        _ module: IOSInsertableModule
    ) {
        let region = session.state.selectedRegion
        let expressionConfiguration =
            defaultExpressionConfiguration(
                for: module
            )

        guard let mutation =
            regionBindingAdapter(for: region)
            .insertModule(
                module,
                expressionConfiguration:
                    expressionConfiguration
            )
        else {
            return
        }

        applyRegionBindingMutation(
            mutation,
            for: region
        )
    }

    private func currentLocationModule(
        for region: CardRegion
    ) -> IOSInsertedModule? {
        regionBindingAdapter(
            for: region
        )
        .modules()
        .first {
            $0.moduleID == .location
            || (
                $0.moduleID == nil
                && $0.systemImage
                    == IOSInsertableModule.location.systemImage
                && [
                    IOSInsertableModule.location.title(
                        for: .simplifiedChinese
                    ),
                    IOSInsertableModule.location.title(
                        for: .english
                    )
                ].contains($0.title)
            )
        }
    }

    private var currentLocationModule:
        IOSInsertedModule? {
        currentLocationModule(
            for: session.state.selectedRegion
        )
    }

    private func locationDisplayOptionBinding(
        for region: CardRegion
    ) -> Binding<String> {
        Binding(
            get: {
                if let module =
                    currentLocationModule(
                        for: region
                    ) {
                    return LocationDisplayInspectorPresenter
                        .selectedOptionID(
                            from: module
                        )
                }

                return LocationDisplayInspectorPresenter
                    .selectedOptionID(
                        fromConfiguration:
                            selectedLocationDisplayConfiguration
                    )
            },
            set: { optionID in
                let change =
                    ConfigurationCenterLocationDisplaySupport
                    .selectionChange(
                        optionID: optionID,
                        region: region,
                        module:
                            currentLocationModule(
                                for: region
                            ),
                        adapter:
                            regionBindingAdapter(
                                for: region
                            )
                    )
                selectedLocationDisplayConfiguration =
                    change.configuration
                _ = runtime
                    .environment
                    .coordinators
                    .configuration
                    .saveLocationDisplayConfiguration(
                        change.configuration
                    )

                if let mutation = change.mutation {
                    applyRegionBindingMutation(
                        mutation,
                        for: change.region
                    )
                }
            }
        )
    }

    private var locationDisplayOptionBinding:
        Binding<String> {
        locationDisplayOptionBinding(
            for: session.state.selectedRegion
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
            set: { session.selectTimeAnchor(id: $0) }
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
            set: {
                session.selectCurrentTimeAnchorExpressionStyle($0)
            }
        )
    }

    private func defaultExpressionConfiguration(
        for module: IOSInsertableModule
    ) -> ExpressionModuleConfiguration? {
        guard module == .location else {
            return nil
        }

        return selectedLocationDisplayConfiguration
        ?? LocationDisplayInspectorPresenter
            .configuration(for: "legacyDisplay")
    }

    private func removeInsertedModule(
        _ module: IOSInsertedModule,
        from region: CardRegion
    ) {
        applyRegionBindingMutation(
            regionBindingAdapter(for: region)
                .removeInsertedModule(module),
            for: region
        )
    }

    private func applyRegionBindingMutation(
        _ mutation:
            ConfigurationCenterRegionBindingMutation,
        for region: CardRegion
    ) {
        regionDraftStore = mutation.store

        if let previewText = mutation.previewText {
            session.updateRegionPreview(
                region: region,
                text: previewText
            )
        }
    }

    private func applySelectionUpdate(
        _ update:
            ConfigurationCenterSelectionUpdate
    ) {
        if ConfigurationCenterSelectionCoordinator
            .shouldDismissKeyboard(
                for: update,
                currentPanel: selectedPanel,
                currentRegion: session.state.selectedRegion
            ) {
            dismissKeyboard()
        }

        ConfigurationCenterSelectionApplier
            .apply(
                update,
                session: session,
                selectedPanel: &selectedPanel
            )

        if showsCompactNavigator {
            showsCompactNavigator = false
        }
    }

    private func usesCompactLayout(
        for width: CGFloat
    ) -> Bool {
        horizontalSizeClass == .compact
        || width < 860
    }

    private var storageOptionBinding:
        Binding<ConfigurationStorageOption> {
        Binding(
            get: {
                ConfigurationCenterSessionBindingPresenter
                    .selectedStorageOption(session: session)
            },
            set: {
                ConfigurationCenterSessionBindingPresenter
                    .setSelectedStorageOption(
                        $0,
                        session: session
                    )
            }
        )
    }

    private var profileTitleBinding:
        Binding<String> {
        Binding(
            get: {
                ConfigurationCenterSessionBindingPresenter
                    .profileTitle(session: session)
            },
            set: {
                ConfigurationCenterSessionBindingPresenter
                    .setProfileTitle(
                        $0,
                        session: session
                    )
            }
        )
    }

    private var memoryWriteToggleBinding:
        Binding<Bool> {
        Binding(
            get: {
                ConfigurationCenterSessionBindingPresenter
                    .usesCustomMemoryWriteText(session: session)
            },
            set: {
                ConfigurationCenterSessionBindingPresenter
                    .setUsesCustomMemoryWriteText(
                        $0,
                        session: session
                    )
            }
        )
    }

    private var memoryWriteTextBinding:
        Binding<String> {
        Binding(
            get: {
                ConfigurationCenterSessionBindingPresenter
                    .customMemoryWriteText(session: session)
            },
            set: {
                ConfigurationCenterSessionBindingPresenter
                    .setCustomMemoryWriteText(
                        $0,
                        session: session
                    )
            }
        )
    }

    private var previewCompositionHelper:
        ConfigurationCenterPreviewCompositionHelper {

        ConfigurationCenterPreviewCompositionHelper(
            context:
                .init(
                    subject:
                        session.state.selectedSubject
                )
        )
    }

    private var regionEditCoordinator:
        ConfigurationCenterRegionEditCoordinator {
        ConfigurationCenterRegionEditCoordinator(
            previewHelper:
                previewCompositionHelper
        )
    }

    private func regionBindingAdapter(
        for region: CardRegion
    ) -> ConfigurationCenterRegionBindingAdapter {
        ConfigurationCenterRegionBindingAdapter(
            region: region,
            subject:
                session.state.selectedSubject,
            store: regionDraftStore,
            coordinator: regionEditCoordinator
        )
    }

    private var pageChromePresentation:
        ConfigurationCenterPageChromePresentation {
        ConfigurationCenterPageChromePresenter
            .presentation(
                selectedPanel: selectedPanel,
                session: session
            )
    }

    @ToolbarContentBuilder
    private var configurationToolbar: some ToolbarContent {
        ConfigurationCenterToolbarContent(
            presentation: pageChromePresentation,
            onReset: {
                dismissKeyboard()
                session.resetSelectedMemoryPreset()
            },
            onApply: {
                dismissKeyboard()
                session.applySelectedMemoryPreset()
            }
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

    private func clearCompletedQueueHistory() {
        diagnosticsRefreshCoordinator
            .clearCompletedQueueHistory(
                preservingJobID:
                    backgroundStatusService
                    .currentSnapshot?
                    .presentationState == .active
                    ?
                    backgroundStatusService
                    .currentSnapshot?
                    .jobID
                    : nil
            )
        refreshProcessingState()
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }

    private static func loadLocationDisplayConfiguration(
        from runtime: PhotoMemoAppRuntime
    ) -> ExpressionModuleConfiguration? {
        switch runtime
            .environment
            .coordinators
            .configuration
            .loadV1ConfigurationBootstrapState() {
        case .success(let state):
            return state.locationDisplayConfiguration
        case .failure:
            return nil
        }
    }
}

#Preview("iOS 配置中心") {
    ConfigurationCenteriOSView(
        runtime: PhotoMemoAppRuntime()
    )
}

private struct ConfigurationCenterDetailScrollOffsetPreferenceKey:
    PreferenceKey {

    static var defaultValue: CGFloat = 0

    static func reduce(
        value: inout CGFloat,
        nextValue: () -> CGFloat
    ) {
        value = nextValue()
    }
}
#endif
