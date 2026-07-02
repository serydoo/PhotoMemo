#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI
import PhotosUI
import UIKit

struct PhotoMemoiOSV1View: View {

    private enum V1Tab: Hashable {
        case home
        case editor
        case output
        case settings
    }

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
    private var selectedTab: V1Tab = .home

    @State
    private var showsSubjectOverview = false

    @State
    private var subjectConfigurationFlowState:
        V1IOSSubjectConfigurationFlowState?

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

    private let currentBorderStyleName =
        "Classic White"

    private let currentBorderStyleDescription =
        "当前唯一公开边框，预览与生成保持同一套锁定规范。"

    private let logoOptimizer =
        LogoAssetOptimizationService()

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

    private var configurationBootstrapCoordinator:
        V1ConfigurationBootstrapCoordinator {
        V1ConfigurationBootstrapCoordinator(
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

    private var previewSyncCoordinator:
        V1PreviewSyncCoordinator {
        V1PreviewSyncCoordinator(
            session: session,
            coordinator: previewCoordinator,
            context: previewCompositionContext,
            engine: previewCompositionEngine
        )
    }

    private var draftBootstrapCoordinator:
        V1DraftBootstrapCoordinator {
        V1DraftBootstrapCoordinator(
            session: session,
            context: previewCompositionContext,
            engine: previewCompositionEngine
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
        self.diagnosticsRepository =
            diagnosticsRepository
    }

    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                homePage
                    .tabItem {
                        Label("首页", systemImage: "house.fill")
                    }
                    .tag(V1Tab.home)

                editorPage
                    .tabItem {
                        Label("配置中心", systemImage: "slider.horizontal.3")
                    }
                    .tag(V1Tab.editor)

                outputPage
                    .tabItem {
                        Label("输出", systemImage: "square.and.arrow.down")
                    }
                    .tag(V1Tab.output)

                settingsPage
                    .tabItem {
                        Label("设置", systemImage: "gearshape")
                    }
                    .tag(V1Tab.settings)
            }
        }
        .preferredColorScheme(.light)
        .task {
            await loadAlbumOptions()
        }
        .sheet(
            isPresented: moduleSheetPresented
        ) {
            if let region = activeModuleRegion {
                moduleLibrarySheet(region: region)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
        .sheet(
            isPresented: $showsSubjectOverview
        ) {
            V1IOSSubjectOverviewSheet(
                presentation:
                    subjectOverviewPresentation,
                subject:
                    session.state.selectedSubject,
                onConfirmActiveAnchor: {
                    anchorID in
                    applyActiveSubjectAnchor(anchorID)
                    showsSubjectOverview = false
                },
                onOpenEditor: {
                    showsSubjectOverview = false
                    subjectConfigurationFlowState =
                        V1IOSSubjectConfigurationFlowPresenter
                        .makeFlowState(from: session)
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(
            item: $subjectConfigurationFlowState
        ) { flowState in
            V1IOSSubjectConfigurationFlow(
                flowState: flowState,
                onClose: {
                    subjectConfigurationFlowState = nil
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
                subject?.primaryTimeAnchor?.date {
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
            outputSummary: currentOutputSummaryProjection,
            recentProcessingPresentation: recentProcessingPresentation,
            onOpenSubject: {
                showsSubjectOverview = true
            },
            onCommitMemoryPresetTitle: commitMemoryPresetTitle,
            onApplyCurrentConfiguration: {
                Task {
                    await applyCurrentV1Configuration()
                }
            },
            onOpenOutput: {
                selectedTab = .output
            },
            onOpenEditor: {
                selectedTab = .editor
            },
            onOpenSettings: {
                selectedTab = .settings
            },
            onDismissKeyboard: dismissKeyboard,
            presetPicker: presetPicker,
            presetOperationsMenu: presetOperationsMenu,
            profileTrackingBackground: offsetReader(for: .profile)
        )
    }

    private var editorPage: some View {
        GeometryReader { _ in
            ZStack(alignment: .top) {
                ScrollView {
                    VStack(spacing: 18) {
                        previewSection
                            .background(
                                offsetReader(
                                    for: .preview
                                )
                            )
                            .opacity(
                                max(
                                    1 - previewPinProgress,
                                    0
                                )
                            )

                        editorCluster
                            .opacity(
                                max(editorRevealProgress, 0.26)
                            )
                            .offset(
                                y: (1 - editorRevealProgress) * 12
                            )

                        accessoryEntryCluster
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 16)
                    .padding(.bottom, 34)
                }
                .scrollDismissesKeyboard(.interactively)
                .simultaneousGesture(
                    TapGesture()
                        .onEnded {
                            dismissKeyboard()
                        }
                )

                if previewPinProgress > 0.01 {
                    previewSection
                        .padding(.horizontal, 18)
                        .padding(.top, 12)
                        .opacity(previewPinProgress)
                        .allowsHitTesting(false)
                }
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .top
            )
            .background(ConfigurationUI.appBackground.ignoresSafeArea())
            .coordinateSpace(name: "v1-scroll")
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
            resolvedMemoryWriteText: session.resolvedMemoryWriteText,
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
        Menu {
            Button("重命名配置组合") {
                beginEditingMemoryPresetTitle()
            }

            Button("恢复默认内容") {
                session.resetSelectedMemoryPreset()
                bootstrapDrafts()
                activeConfigurationMessage = "有未保存修改"
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.body.weight(.semibold))
                .frame(width: 28, height: 28)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .accessibilityLabel("更多配置操作")
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

    private func applyActiveSubjectAnchor(
        _ anchorID: UUID
    ) {
        guard
            var subject =
                session.state.selectedSubject,
            let anchor =
                subject.timeAnchor(id: anchorID)
        else {
            return
        }

        subject.activeTimeAnchorID = anchor.id
        subject.behavior.primaryAnchor = anchor.title
        subject.referenceDate = anchor.date
        session.updateSelectedSubject(subject)
        birthdayDate = anchor.date
        activeConfigurationMessage = "有未保存修改"
    }

    private var previewSection: some View {
        V1PreviewCard(
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
                )
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
        IOSCompactEntryListGroup {
            IOSCompactEntryDisclosureRow(
                title: "Logo 标识",
                subtitle: "Apple 标识 / 自选标识 / 使用对象头像",
                value: logoMode.title,
                detail: logoRowDetail,
                systemImage: "seal.fill",
                isExpanded:
                    expansionBinding(
                        for: .logo
                    )
            ) {
                logoEditorContent
            }

            IOSCompactEntryDisclosureRow(
                title: "时间锚点",
                subtitle: timeAnchorTitle,
                value: moduleValue(.smartTime),
                detail: birthdaySummaryText,
                systemImage: "calendar.badge.clock",
                showsDivider: false,
                isExpanded:
                    expansionBinding(
                        for: .anchor
                    )
            ) {
                anchorEditorContent
            }
        }
    }

    private var logoEditorContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Logo 标识", selection: $logoMode) {
                ForEach(V1LogoMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            HStack(alignment: .center, spacing: 12) {
                logoPreview

                VStack(alignment: .leading, spacing: 3) {
                    Text("当前状态")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Text(logoMode.title)
                        .font(.subheadline.weight(.semibold))

                    Text(resolvedLogoStatusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            if logoMode == .customUpload {
                PhotosPicker(
                    selection: $selectedLogoItem,
                    matching: .images
                ) {
                    Label(
                        isOptimizingLogo
                        ? "正在优化"
                        : "选择 Logo",
                        systemImage:
                            isOptimizingLogo
                            ? "hourglass"
                            : "photo.badge.plus"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .disabled(isOptimizingLogo)
            } else if logoMode == .subjectAvatar {
                Text("对象头像来自当前记忆对象配置，会自动按头像、标识和预览三种用途准备资源。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var anchorEditorContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            DatePicker(
                "途途生日",
                selection: $birthdayDate,
                displayedComponents: [.date]
            )
            .datePickerStyle(.compact)

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 16)

                VStack(alignment: .leading, spacing: 3) {
                    Text("时间结果")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Text(
                        moduleValue(
                            .smartTime
                        )
                    )
                        .font(.subheadline.weight(.semibold))
                }
            }
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
        birthdayDate.formatted(
            .dateTime
                .year()
                .month()
                .day()
        )
    }

    private var currentOutputSummaryProjection:
        V1IOSHomeOutputSummaryProjection {

        V1IOSHomeProjection
            .outputSummary(
                outputTarget: outputTarget,
                selectedExistingAlbumTitle:
                    selectedExistingAlbumTitle,
                newAlbumName: newAlbumName,
                writesMemoryDescription:
                    session.usesCustomMemoryWriteText
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
        Menu {
            Picker("当前配置组合", selection: selectedPresetBinding) {
                ForEach(session.state.memoryPresets) { preset in
                    Text(preset.title).tag(preset.id)
                }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.stack.fill")
                    .font(.caption.weight(.semibold))
                Text(session.currentMemoryPresetTitle)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.accentColor.opacity(0.10))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.accentColor.opacity(0.18))
            )
        }
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

    private var logoPreview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .frame(width: 74, height: 54)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
                        .foregroundStyle(Color.black.opacity(0.10))
                )

            switch logoMode {
            case .appleMini:
                Image(systemName: "apple.logo")
                    .font(.title2.weight(.semibold))
            case .customUpload:
                if let imagePath = customLogoBadge?.imagePath,
                   let image = UIImage(contentsOfFile: imagePath) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding(8)
                } else {
                    VStack(spacing: 4) {
                    Image(systemName: "photo.badge.plus")
                        .font(.title3.weight(.semibold))
                    Text("上传")
                        .font(.caption2.weight(.semibold))
                    }
                    .foregroundStyle(.secondary)
                }
            case .subjectAvatar:
                if let imagePath = resolvedSubjectAvatarPreviewImagePath,
                   let image = UIImage(contentsOfFile: imagePath) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                        .frame(width: 38, height: 38)
                } else {
                    VStack(spacing: 4) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.title3.weight(.semibold))
                        Text("头像")
                            .font(.caption2.weight(.semibold))
                    }
                    .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func moduleLibrarySheet(
        region: CardRegion
    ) -> some View {
        NavigationStack {
            List {
                Section {
                    ForEach(modules(for: region)) { module in
                        Button {
                            applyModulePanelState(
                                V1ModulePanelCoordinator
                                    .selectModule(
                                        module,
                                        state:
                                            modulePanelState
                                    )
                            )
                            insert(module, into: region)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: module.systemImage)
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 24)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(module.title)
                                        .font(.body)
                                        .foregroundStyle(.primary)

                                    HStack(spacing: 6) {
                                        Text(moduleCategoryTitle(module))
                                            .font(.caption2.weight(.semibold))
                                            .foregroundStyle(.tertiary)
                                            .textCase(.uppercase)

                                        Text(moduleValue(module))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                }

                                Spacer(minLength: 0)
                            }
                        }
                    }
                } header: {
                    Text("常用与模块")
                }
            }
            .navigationTitle(region.semanticTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") {
                        applyModulePanelState(
                            V1ModulePanelCoordinator
                                .setSheetPresented(
                                    false,
                                    state:
                                        modulePanelState
                                )
                        )
                    }
                }
            }
        }
    }

    private func draft(for region: CardRegion) -> V1EditorDraft {
        V1DraftOrchestrationCoordinator
            .draft(
                for: region,
                viewState:
                    draftOrchestrationState,
                makeDefaultDraft:
                    makeDefaultDraft
            )
    }

    private func updateDraft(
        for region: CardRegion,
        transform: (inout V1EditorDraft) -> Void
    ) {
        let update =
            V1DraftMutationCoordinator
            .updateDraft(
                for: region,
                in: draftMutationState,
                makeDefaultDraft:
                    makeDefaultMutationDraft
            ) { draft in
                var editorDraft =
                    V1DraftBridge
                    .editorDraft(from: draft)
                transform(&editorDraft)
                draft =
                    V1DraftBridge
                    .mutationDraft(
                        from: editorDraft
                    )
            }

        applyDraftMutationUpdate(update)
    }

    private func setActiveTextItem(
        _ itemID: UUID?,
        for region: CardRegion
    ) {
        applyDraftMutationState(
            V1DraftMutationCoordinator
            .setActiveTextItem(
                itemID,
                for: region,
                in: draftMutationState
            )
        )
    }

    private func updateTextItem(
        _ itemID: UUID,
        text: String,
        for region: CardRegion
    ) {
        applyDraftMutationUpdate(
            V1DraftMutationCoordinator
            .updateTextItem(
                id: itemID,
                text: text,
                for: region,
                in: draftMutationState,
                makeDefaultDraft:
                    makeDefaultMutationDraft
            )
        )
    }

    private func prependText(
        _ text: String,
        to region: CardRegion
    ) {
        applyDraftMutationUpdate(
            V1DraftMutationCoordinator
            .prependText(
                text,
                for: region,
                in: draftMutationState,
                makeDefaultDraft:
                    makeDefaultMutationDraft
            )
        )
    }

    private func appendText(
        _ text: String,
        to region: CardRegion
    ) {
        applyDraftMutationUpdate(
            V1DraftMutationCoordinator
            .appendText(
                text,
                for: region,
                in: draftMutationState,
                makeDefaultDraft:
                    makeDefaultMutationDraft
            )
        )
    }

    private func removeItem(
        _ itemID: UUID,
        from region: CardRegion
    ) {
        applyDraftMutationUpdate(
            V1DraftMutationCoordinator
            .removeItem(
                id: itemID,
                from: region,
                in: draftMutationState,
                makeDefaultDraft:
                    makeDefaultMutationDraft
            )
        )
    }

    private var draftMutationState:
        V1DraftMutationCoordinator.State {
        V1DraftOrchestrationCoordinator
            .mutationState(
                from:
                    draftOrchestrationState
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

    private func applyDraftMutationState(
        _ state:
            V1DraftMutationCoordinator.State
    ) {
        let viewState =
            V1DraftOrchestrationCoordinator
            .viewState(from: state)
        applyDraftOrchestrationState(
            viewState
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

    private func applyDraftMutationUpdate(
        _ update:
            V1DraftMutationCoordinator.Update
    ) {
        let application =
            V1DraftOrchestrationCoordinator
            .applyMutationUpdate(update)
        applyDraftOrchestrationState(
            application.viewState
        )
        if !application
            .previewDraftsByRegion
            .isEmpty {
            previewSyncCoordinator
                .refreshDynamicPreview(
                    draftsByRegion:
                        application
                        .previewDraftsByRegion
                )
        }
    }

    private func refreshPreview(for region: CardRegion) {
        previewSyncCoordinator
            .refreshPreview(
                for: region,
                draft:
                    V1DraftBridge
                    .previewDraft(
                        from: draft(
                            for: region
                        )
                    )
            )
    }

    private func refreshDynamicPreview() {
        previewSyncCoordinator
            .refreshDynamicPreview(
                draftsByRegion:
                    V1DraftOrchestrationCoordinator
                    .dynamicPreviewDrafts(
                        for:
                            CardRegion
                            .memoryCardRegions,
                        viewState:
                            draftOrchestrationState,
                        makeDefaultDraft:
                            makeDefaultDraft
                    )
            )
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
        draft.singleLineText
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

    private func makeDefaultMutationDraft(
        for region: CardRegion
    ) -> V1DraftMutationDraft {
        V1DraftBridge.mutationDraft(
            from:
                makeDefaultDraft(
                    for: region
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
                value: moduleValue(module),
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
        applyDraftMutationUpdate(
            V1DraftMutationCoordinator
            .insert(
                V1DraftBridge
                .mutationItem(
                    from: moduleItem(module)
                ),
                into: region,
                in: draftMutationState,
                makeDefaultDraft:
                    makeDefaultMutationDraft
            )
        )
    }

    @MainActor
    private func applyCurrentV1Configuration() async {
        guard !isSavingConfiguration else {
            return
        }

        isSavingConfiguration = true
        activeConfigurationMessage = "正在保存"

        let template =
            Template(
                preset: .immersWhite,
                name: session.currentMemoryPresetTitle,
                leftTopArea: templateArea(
                    name: "Recorder",
                    region: .slotA
                ),
                leftBottomArea: templateArea(
                    name: "Timeline",
                    region: .slotB
                ),
                rightTopArea: templateArea(
                    name: "Capture Summary",
                    region: .slotC
                ),
                rightBottomArea: templateArea(
                    name: "Memory",
                    region: .slotD
                ),
                badgeArea: .badge
            )
        let subjectForSaving =
            alignedSelectedSubject()

        let result =
            await configurationApplyCoordinator
            .apply(
                V1ConfigurationApplyRequest(
                    subject: subjectForSaving,
                    template: template,
                    badge:
                        selectedBadgeForSaving,
                    shouldWritePhotoDescription:
                        session
                        .usesCustomMemoryWriteText,
                    photoDescriptionOverride:
                        session
                        .usesCustomMemoryWriteText
                        ? session
                        .customMemoryWriteText
                        : "",
                    timeAnchorTitle:
                        timeAnchorTitle,
                    timeAnchorDate:
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

        let receipt: V1ConfigurationApplyReceipt

        switch result {
        case .success(let applyReceipt):
            receipt = applyReceipt
        case .failure(let error):
            activeConfigurationMessage =
                error.message
            isSavingConfiguration = false
            return
        }

        if outputTarget == .newAlbum,
           let pickerSelectionIdentifier =
            receipt.albumSelection
            .pickerSelectionIdentifier {
            await loadAlbumOptions()
            selectedExistingAlbumIdentifier =
                pickerSelectionIdentifier
        }

        if let subjectForSaving {
            session.restoreSelectedSubject(
                subjectForSaving
            )
        }

        session.applySelectedMemoryPreset()
        activeConfigurationMessage = "已保存为分享配置"
        isSavingConfiguration = false
    }

    private var timeAnchorTitle: String {
        let subjectName =
            alignedSelectedSubject()?
            .resolvedExpressionSubjectText
            ?? session.state.selectedSubject?
            .resolvedExpressionSubjectText
            ?? "记忆对象"

        let trimmedName =
            subjectName.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return trimmedName.isEmpty
            ? "记忆对象"
            : trimmedName
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

        do {
            guard
                let data =
                    try await item.loadTransferable(
                        type: Data.self
                    )
            else {
                throw LogoAssetOptimizationError.invalidImage
            }

            let optimizedAsset =
                try await logoOptimizer.optimize(
                    data: data
                )

            customLogoBadge = optimizedAsset.badge
            logoMode = .customUpload
            logoStatusMessage =
                "\(optimizedAsset.pixelSize) × \(optimizedAsset.pixelSize) PNG 已优化"
            activeConfigurationMessage = "有未保存修改"
        } catch {
            logoStatusMessage =
                error.localizedDescription
        }

        isOptimizingLogo = false
    }

    private func bootstrapSavedSettings() {
        applyBootstrapState(
            configurationBootstrapCoordinator
                .loadState()
        )
    }

    private func applyBootstrapState(
        _ state:
            V1ConfigurationBootstrapState
    ) {
        isApplyingBootstrapState = true
        let projection =
            V1ConfigurationBootstrapPresenter
            .projection(from: state)

        customLogoBadge =
            projection.customLogoBadge
        logoMode = projection.logoMode

        if projection.logoMode == .customUpload,
           projection.customLogoBadge != nil {
            logoStatusMessage = "已使用自选 Logo。"
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

        if let selectedSubject =
            state.selectedSubject {
            session.restoreSelectedSubject(
                selectedSubject
            )

            if let anchorDate =
                selectedSubject.primaryTimeAnchor?.date {
                birthdayDate = anchorDate
            }
        }

        isApplyingBootstrapState = false
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

    private func templateArea(
        name: String,
        region: CardRegion
    ) -> TemplateArea {
        let text =
            templateText(
                for: draft(for: region)
            )
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return TemplateArea(
            name: name,
            items: [
                TemplateItem(
                    type: .variable,
                    name: name,
                    value: text,
                    isEnabled: !text.isEmpty
                )
            ]
        )
    }

    private func resolvedDisplayValue(
        for item: V1ContentItem
    ) -> String {
        switch ResolveV1PreviewDisplayValueIntent(
            item:
                V1DraftBridge
                .previewItem(
                    from: item
                ),
            context:
                previewCompositionContext,
            engine:
                previewCompositionEngine
        )
        .executeSynchronously() {
        case .success(let value):
            return value
        case .failure:
            return item.displayValue
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

    private func moduleValue(
        _ module: IOSInsertableModule
    ) -> String {
        guard let previewModule =
            previewModule(
                for: module
            ) else {
            return module.title
        }

        return previewCompositionEngine
            .moduleValue(
                previewModule,
                context:
                    previewCompositionContext
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
        guard
            var subject =
                session.state.selectedSubject
        else {
            return nil
        }

        if let activeAnchorID =
            subject.activeTimeAnchorID,
           let activeAnchorIndex =
            subject.timeAnchors.firstIndex(
                where: {
                    $0.id == activeAnchorID
                }
            ) {
            subject.timeAnchors[activeAnchorIndex].date =
                birthdayDate
            subject.behavior.primaryAnchor =
                subject.timeAnchors[activeAnchorIndex]
                .title
            subject.referenceDate = birthdayDate
            return subject
        }

        if let primaryAnchorIndex =
            subject.timeAnchors.firstIndex(
                where: {
                    $0.title == subject.behavior.primaryAnchor
                }
            ) {
            subject.timeAnchors[primaryAnchorIndex].date =
                birthdayDate
            subject.referenceDate = birthdayDate
            return subject
        }

        subject.referenceDate = birthdayDate
        return subject
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

    private var selectedExistingAlbumTitle: String {

        availableAlbums.first(where: {
            $0.id == selectedExistingAlbumIdentifier
        })?
        .title
        ?? ""
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
        bootstrapSavedSettings()
        bootstrapDrafts()
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

    private func bootstrapDrafts() {
        regionDrafts =
            draftBootstrapCoordinator
            .bootstrapDrafts(
                makeDefaultDraft:
                    makeDefaultDraft(for:)
            )

        refreshDynamicPreview()
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
        diagnosticsRepository:
            runtime.environment
            .repositories
            .diagnostics
    )
}

#endif
