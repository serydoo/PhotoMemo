#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI
import PhotosUI
import UIKit

struct PhotoMemoiOSMVPTestView: View {

    @Environment(\.scenePhase)
    private var scenePhase

    @StateObject
    private var session = ConfigurationSession()

    @State
    private var regionDrafts: [CardRegion: MVPEditorDraft] = [:]

    @State
    private var activeModuleRegion: CardRegion?

    @State
    private var activeTextItemIDs: [CardRegion: UUID] = [:]

    @State
    private var selectedModule: IOSInsertableModule?

    @State
    private var logoMode: MVPLogoMode = .appleMini

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
    private var outputTarget: MVPIOSOutputTarget = .automatic

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
    private var activeConfigurationMessage = "尚未保存为分享配置"

    @State
    private var shareDiagnosticEvents:
        [PhotoMemoShareDiagnosticEvent] = []

    @State
    private var showsPresetActivationConfirmation = false

    @State
    private var pendingActivationPresetTitle = ""

    @AppStorage("photomemo.mvp.moduleUsageCounts")
    private var moduleUsageCountsStorage = "{}"

    private let captureTimeResolver = CaptureTimeResolver()

    private let logoOptimizer =
        LogoAssetOptimizationService()

    var body: some View {
        NavigationStack {
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

                            shareDiagnosticsSection

                            profileSection
                                .background(
                                    offsetReader(
                                        for: .profile
                                    )
                                )

                            editorCluster
                                .opacity(
                                    max(editorRevealProgress, 0.26)
                                )
                                .offset(
                                    y: (1 - editorRevealProgress) * 12
                                )

                            logoSection
                            birthdaySection
                            outputSection
                            memoryWriteSection
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 16)
                        .padding(.bottom, 34)
                    }

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
                .coordinateSpace(name: "mvp-scroll")
            }
            .navigationTitle("PhotoMemo")
            .navigationBarTitleDisplayMode(.inline)
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
        .confirmationDialog(
            "将当前 Preset 保存为生效配置？",
            isPresented: $showsPresetActivationConfirmation,
            titleVisibility: .visible
        ) {
            Button("保存为生效配置") {
                Task {
                    await applyCurrentMVPConfiguration()
                }
            }

            Button("仅切换查看", role: .cancel) {
                activeConfigurationMessage = "有未保存修改"
            }
        } message: {
            Text("已切换到「\(pendingActivationPresetTitle)」。保存后，下一次从照片分享进入 PhotoMemo 时会使用这套配置和时间锚点。")
        }
        .onAppear {
            bootstrapIfNeeded()
            refreshShareDiagnostics()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else {
                return
            }

            refreshShareDiagnostics()
        }
        .onChange(of: session.state.selectedMemoryPresetID) { _, _ in
            bootstrapDrafts()
        }
        .onChange(of: birthdayDate) { _, _ in
            refreshDynamicPreview()
            activeConfigurationMessage = "有未保存修改"
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

    private var profileSection: some View {
        MVPCardSurface(title: "记忆档案") {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    presetPicker

                    Spacer(minLength: 0)

                    Button {
                        Task {
                            await applyCurrentMVPConfiguration()
                        }
                    } label: {
                        if isSavingConfiguration {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Text("保存")
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(isSavingConfiguration)

                    Button {
                        session.resetSelectedMemoryPreset()
                        bootstrapDrafts()
                        activeConfigurationMessage = "有未保存修改"
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .accessibilityLabel("重置默认配置")
                }

                Text(activeConfigurationMessage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                VStack(alignment: .leading, spacing: 6) {
                    Text("当前记忆对象摘要")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Text(session.currentConfigurationLabel)
                        .font(.headline.weight(.semibold))

                    Text(session.state.selectedSubject?.definition ?? "用于生成照片底部信息卡。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var previewSection: some View {
        MVPPreviewCard(
            logoMode: logoMode,
            customLogoImagePath:
                customLogoBadge?.imagePath,
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

    private var shareDiagnosticsSection: some View {
        MVPCardSurface(title: "最近分享") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 10) {
                    Image(systemName: shareDiagnosticsSymbolName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(shareDiagnosticsTint)
                        .frame(width: 20)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(shareDiagnosticsHeadline)
                            .font(.subheadline.weight(.semibold))

                        Text(shareDiagnosticsSubheadline)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(
                                horizontal: false,
                                vertical: true
                            )
                    }

                    Spacer(minLength: 0)

                    Button {
                        refreshShareDiagnostics()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .accessibilityLabel("刷新最近分享状态")
                }

                if !shareDiagnosticEvents.isEmpty {
                    VStack(alignment: .leading, spacing: 7) {
                        ForEach(
                            Array(
                                shareDiagnosticEvents
                                    .suffix(6)
                                    .reversed()
                            )
                        ) { event in
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text(
                                    event.timestamp.formatted(
                                        date: .omitted,
                                        time: .standard
                                    )
                                )
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.secondary)
                                .frame(width: 72, alignment: .leading)

                                VStack(alignment: .leading, spacing: 1) {
                                    Text(event.stage)
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(.secondary)

                                    Text(event.message)
                                        .font(.caption)
                                        .lineLimit(2)
                                        .fixedSize(
                                            horizontal: false,
                                            vertical: true
                                        )
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var editorCluster: some View {
        VStack(spacing: 14) {
            ForEach(CardRegion.memoryCardRegions, id: \.self) { region in
                MVPRegionEditorCard(
                    region: region,
                    draft: draft(for: region),
                    resolvedText:
                        composedText(
                            for: draft(for: region)
                        ),
                    onFocus: {
                        activeModuleRegion = nil
                        selectedModule = nil
                    },
                    onFocusTextItem: { item in
                        activeTextItemIDs[region] = item.id
                        activeModuleRegion = nil
                        selectedModule = nil
                    },
                    onUpdateTextItem: { item, text in
                        activeTextItemIDs[region] = item.id
                        updateDraft(for: region) { draft in
                            draft.updateTextItem(
                                item,
                                text: text
                            )
                            draft.normalizeTrailingTextInput()
                        }
                    },
                    onPrependText: { text in
                        var prependedID: UUID?
                        updateDraft(for: region) { draft in
                            prependedID = draft.prependText(text)
                            draft.normalizeTrailingTextInput()
                        }
                        if let prependedID {
                            activeTextItemIDs[region] = prependedID
                        }
                    },
                    onAppendText: { text in
                        var appendedID: UUID?
                        updateDraft(for: region) { draft in
                            appendedID = draft.appendText(text)
                            draft.normalizeTrailingTextInput()
                        }
                        if let appendedID {
                            activeTextItemIDs[region] = appendedID
                        }
                    },
                    onRemoveItem: { item in
                        updateDraft(for: region) { draft in
                            draft.items.removeAll { $0.id == item.id }
                            draft.normalizeTrailingTextInput()
                        }
                        refreshPreview(for: region)
                    },
                    onAddSeparator: { separator in
                        updateDraft(for: region) { draft in
                            draft.appendComposedItem(
                                .separator(separator)
                            )
                        }
                    },
                    onShowModules: {
                        activeModuleRegion = region
                    }
                )
            }
        }
    }

    private var logoSection: some View {
        MVPCardSurface(title: "Logo 标识") {
            VStack(alignment: .leading, spacing: 12) {
                Picker("Logo 标识", selection: $logoMode) {
                    ForEach(MVPLogoMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                HStack(alignment: .center, spacing: 12) {
                    logoPreview

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Logo 标识")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)

                        Text(logoMode.title)
                            .font(.subheadline.weight(.semibold))

                        Text(logoStatusMessage)
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
                }
            }
        }
    }

    private var birthdaySection: some View {
        MVPCardSurface(title: "时间锚点") {
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

                        Text(smartTimeResult)
                            .font(.subheadline.weight(.semibold))
                    }
                }
            }
        }
    }

    private var outputSection: some View {
        MVPCardSurface(title: "输出") {
            VStack(alignment: .leading, spacing: 12) {
                Picker("保存位置", selection: $outputTarget) {
                    ForEach(MVPIOSOutputTarget.allCases) { target in
                        Text(target.title).tag(target)
                    }
                }
                .pickerStyle(.menu)

                switch outputTarget {
                case .automatic,
                     .applePhotos:
                    EmptyView()

                case .existingAlbum:
                    Picker(
                        "相册",
                        selection: $selectedExistingAlbumIdentifier
                    ) {
                        if availableAlbums.isEmpty {
                            Text("暂无可用相册").tag("")
                        } else {
                            ForEach(availableAlbums) { album in
                                Text(album.title).tag(album.id)
                            }
                        }
                    }
                    .pickerStyle(.menu)
                    .disabled(availableAlbums.isEmpty)

                case .newAlbum:
                    TextField("相册名称", text: $newAlbumName)
                        .textFieldStyle(.roundedBorder)
                }

                Text(outputTarget.note)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if isLoadingAlbums {
                    Label("正在读取相册", systemImage: "photo.on.rectangle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if !albumStatusMessage.isEmpty {
                    Text(albumStatusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var memoryWriteSection: some View {
        MVPCardSurface(title: "写入记忆") {
            VStack(alignment: .leading, spacing: 12) {
                Toggle(
                    "是否写入记忆说明",
                    isOn: $session.usesCustomMemoryWriteText
                )

                if session.usesCustomMemoryWriteText {
                    TextField(
                        "自定义写入内容",
                        text: $session.customMemoryWriteText,
                        axis: .vertical
                    )
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(2...4)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("预览")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Text(session.resolvedMemoryWriteText)
                        .font(.subheadline.weight(.semibold))
                }
            }
        }
    }

    private var presetPicker: some View {
        Menu {
            Picker("当前 Preset", selection: selectedPresetBinding) {
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
                activeModuleRegion != nil
            },
            set: { isPresented in
                if !isPresented {
                    activeModuleRegion = nil
                    selectedModule = nil
                }
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
                            recordModuleUsage(module)
                            insert(module, into: region)
                            activeModuleRegion = nil
                            selectedModule = nil
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
                        activeModuleRegion = nil
                        selectedModule = nil
                    }
                }
            }
        }
    }

    private func draft(for region: CardRegion) -> MVPEditorDraft {
        regionDrafts[region]
        ?? makeDefaultDraft(for: region)
    }

    private func updateDraft(
        for region: CardRegion,
        transform: (inout MVPEditorDraft) -> Void
    ) {
        var draft = draft(for: region)
        transform(&draft)
        regionDrafts[region] = draft
        refreshPreview(for: region)
        activeConfigurationMessage = "有未保存修改"
    }

    private func refreshPreview(for region: CardRegion) {
        let draft = draft(for: region)
        let composed = composedText(for: draft)
        session.updateRegionPreview(region: region, text: composed)
    }

    private func refreshDynamicPreview() {
        for region in CardRegion.memoryCardRegions {
            refreshPreview(for: region)
        }
    }

    private func previewText(
        for region: CardRegion
    ) -> String {
        session.previewText(for: region)
    }

    private func composedText(for draft: MVPEditorDraft) -> String {
        InlineContentTextComposer.compose(
            draft.items.map { item in
                InlineContentTextComposer.Piece(
                    kind: item.kind.inlineComposerKind,
                    value: resolvedDisplayValue(for: item)
                )
            }
        )
    }

    private func templateText(for draft: MVPEditorDraft) -> String {
        draft.singleLineTemplateText
    }

    private func makeDefaultDraft(
        for region: CardRegion
    ) -> MVPEditorDraft {
        switch region {
        case .slotA:
            return MVPEditorDraft(
                items: [
                    .text("记录"),
                    moduleItem(.cameraModel)
                ]
            )

        case .slotB:
            return MVPEditorDraft(
                items: [
                    moduleItem(.captureDate),
                    moduleItem(.captureTime)
                ]
            )

        case .slotC:
            return MVPEditorDraft(
                items: [
                    moduleItem(.captureSummary)
                ]
            )

        case .slotD:
            return MVPEditorDraft(
                items: [
                    moduleItem(.subjectNickname),
                    .text("当天"),
                    moduleItem(.smartTime)
                ]
            )

        default:
            let subject = session.state.selectedSubject
            let templateID = session.activeTemplateID(for: region)

            return MVPEditorDraft(
                items: [
                    .text(
                        ConfigurationSession.defaultPreviewText(
                            for: region,
                            templateID: templateID,
                            subject: subject
                        )
                    )
                ]
            )
        }
    }

    private func moduleItem(
        _ module: IOSInsertableModule
    ) -> MVPContentItem {
        .token(
            module.title,
            value: moduleValue(module),
            templateValue: templateToken(
                for: module
            ),
            systemImage: module.systemImage
        )
    }

    private func insert(
        _ module: IOSInsertableModule,
        into region: CardRegion
    ) {
        updateDraft(for: region) { draft in
            draft.insertComposedItem(
                moduleItem(module),
                after: activeTextItemIDs[region]
            )
        }
    }

    @MainActor
    private func applyCurrentMVPConfiguration() async {
        guard !isSavingConfiguration else {
            return
        }

        isSavingConfiguration = true
        activeConfigurationMessage = "正在保存"

        let albumSelection: MVPResolvedAlbumSelection

        do {
            albumSelection =
                try await resolvedOutputAlbumSelection()
        } catch {
            activeConfigurationMessage =
                error.localizedDescription
            isSavingConfiguration = false
            return
        }

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

        let settings = SettingsService()
        let anchor = persistTimeAnchor(
            settings: settings
        )
        settings.selectedTemplate =
            template.normalizedForEditing
        settings.selectedBadge =
            selectedBadgeForSaving
        settings.shouldWritePhotoDescription =
            session.usesCustomMemoryWriteText
        settings.photoDescriptionOverride =
            session.usesCustomMemoryWriteText
            ? session.customMemoryWriteText
            : ""
        settings.saveTemplate()
        settings.saveBadge()
        settings.savePhotoDescriptionSettings()
        settings.saveEditorState(
            selectedAnchorID: anchor.id,
            selectedAlbumIdentifier:
                albumSelection.identifier,
            selectedAlbumTitle:
                albumSelection.title
        )

        session.applySelectedMemoryPreset()
        activeConfigurationMessage = "已保存为分享配置"
        isSavingConfiguration = false
    }

    private func persistTimeAnchor(
        settings: SettingsService
    ) -> Anchor {
        let title = timeAnchorTitle
        let date = birthdayDate

        if let index = settings.anchors.firstIndex(where: {
            $0.type == .birthday
        }) {
            settings.anchors[index].title = title
            settings.anchors[index].date = date
            settings.anchors[index].isCountdown = false
            settings.saveAnchors()
            return settings.anchors[index]
        }

        let anchor =
            Anchor(
                type: .birthday,
                title: title,
                date: date
            )
        settings.anchors.append(anchor)
        settings.saveAnchors()
        return anchor
    }

    private var timeAnchorTitle: String {
        let subjectName =
            session.state.selectedSubject?.identity.shortName
            ?? session.state.selectedSubject?.identity.displayName
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

        do {
            let albums =
                try await PhotoLibraryExportService()
                .fetchAlbumOptions()
            availableAlbums = albums

            if selectedExistingAlbumIdentifier.isEmpty,
               let firstAlbum = albums.first {
                selectedExistingAlbumIdentifier = firstAlbum.id
            }

            albumStatusMessage =
                albums.isEmpty
                ? "没有找到可选择的自建相册。"
                : ""
        } catch {
            albumStatusMessage =
                error.localizedDescription
        }

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
        let settings = SettingsService()

        if let savedBadge = settings.selectedBadge,
           savedBadge.type == .customUpload,
           savedBadge.imagePath != nil {
            customLogoBadge = savedBadge
            logoMode = .customUpload
            logoStatusMessage = "已使用自选 Logo。"
        } else {
            logoMode = .appleMini
        }

        switch settings.selectedAlbumIdentifier {
        case PhotoMemoAlbumSelection.systemLibraryIdentifier:
            outputTarget = .applePhotos

        case "", PhotoMemoAlbumSelection.automaticIdentifier:
            outputTarget = .automatic

        default:
            outputTarget = .existingAlbum
            selectedExistingAlbumIdentifier =
                settings.selectedAlbumIdentifier
        }

        let savedAlbumTitle =
            settings.selectedAlbumTitle
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        if !savedAlbumTitle.isEmpty,
           savedAlbumTitle != "系统图库",
           savedAlbumTitle != "系统相册" {
            newAlbumName = savedAlbumTitle
        }
    }

    private var selectedBadgeForSaving: Badge {
        switch logoMode {
        case .appleMini:
            return .appleClassic
        case .customUpload:
            return customLogoBadge ?? .none
        }
    }

    @MainActor
    private func resolvedOutputAlbumSelection()
        async throws -> MVPResolvedAlbumSelection {

        switch outputTarget {
        case .automatic:
            return MVPResolvedAlbumSelection(
                identifier:
                    PhotoMemoAlbumSelection
                    .automaticIdentifier,
                title:
                    PhotoMemoAlbumSelection
                    .defaultAlbumTitle
            )

        case .applePhotos:
            return MVPResolvedAlbumSelection(
                identifier:
                    PhotoMemoAlbumSelection
                    .systemLibraryIdentifier,
                title: "系统图库"
            )

        case .existingAlbum:
            guard
                !selectedExistingAlbumIdentifier.isEmpty,
                let selectedAlbum =
                    availableAlbums.first(where: {
                        $0.id == selectedExistingAlbumIdentifier
                    })
            else {
                return MVPResolvedAlbumSelection(
                    identifier:
                        PhotoMemoAlbumSelection
                        .automaticIdentifier,
                    title:
                        PhotoMemoAlbumSelection
                        .defaultAlbumTitle
                )
            }

            return MVPResolvedAlbumSelection(
                identifier:
                    selectedAlbum.localIdentifier
                    ?? selectedAlbum.id,
                title: selectedAlbum.title
            )

        case .newAlbum:
            let album =
                try await PhotoLibraryExportService()
                .ensureAlbum(named: newAlbumName)

            await loadAlbumOptions()

            selectedExistingAlbumIdentifier = album.id

            return MVPResolvedAlbumSelection(
                identifier:
                    album.localIdentifier
                    ?? album.id,
                title: album.title
            )
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

    private func templateToken(
        for module: IOSInsertableModule
    ) -> String {
        let token = module.rendererToken
        return token == module.token
            ? moduleValue(module)
            : token
    }

    private func resolvedDisplayValue(
        for item: MVPContentItem
    ) -> String {
        guard item.kind == .token else {
            return item.displayValue
        }

        guard let module =
            IOSInsertableModule.allCases.first(where: {
                $0.rendererToken == item.savedValue
                || $0.token == item.savedValue
            })
        else {
            return item.displayValue
        }

        return moduleValue(module)
    }

    private func modules(for region: CardRegion) -> [IOSInsertableModule] {
        guard CardRegion.memoryCardRegions.contains(region) else {
            return []
        }

        let defaults: [IOSInsertableModule] = [
            .subjectNickname,
            .smartTime,
            .captureSummary,
            .captureDate,
            .captureTime,
            .cameraModel,
            .location,
            .imageSize,
            .fileFormat
        ]

        let usageCounts = moduleUsageCounts()

        return defaults.sorted { left, right in
            let leftCount = usageCounts[left.rawValue] ?? 0
            let rightCount = usageCounts[right.rawValue] ?? 0

            if leftCount != rightCount {
                return leftCount > rightCount
            }

            let leftIndex =
                defaults.firstIndex(of: left) ?? 0
            let rightIndex =
                defaults.firstIndex(of: right) ?? 0

            return leftIndex < rightIndex
        }
    }

    private func moduleUsageCounts() -> [String: Int] {
        guard let data =
            moduleUsageCountsStorage.data(
                using: .utf8
            ),
              let decoded =
            try? JSONDecoder().decode(
                [String: Int].self,
                from: data
            )
        else {
            return [:]
        }

        return decoded
    }

    private func moduleCategoryTitle(
        _ module: IOSInsertableModule
    ) -> String {
        switch module {
        case .subjectNickname,
             .smartTime,
             .captureSummary:
            return "PhotoMemo"

        default:
            return "EXIF"
        }
    }

    private func recordModuleUsage(
        _ module: IOSInsertableModule
    ) {
        var counts = moduleUsageCounts()
        counts[module.rawValue, default: 0] += 1

        guard let data =
            try? JSONEncoder().encode(counts),
              let encoded =
            String(data: data, encoding: .utf8)
        else {
            return
        }

        moduleUsageCountsStorage = encoded
    }

    private func moduleValue(
        _ module: IOSInsertableModule
    ) -> String {
        switch module {
        case .subjectNickname:
            return session.state.selectedSubject?.identity.shortName
            ?? session.state.selectedSubject?.identity.displayName
            ?? "途途"
        case .smartTime:
            return smartTimeResult
        case .captureDate:
            return captureDateFormatter.string(from: mockCaptureDate)
        case .captureTime:
            return captureTimeFormatter.string(from: mockCaptureDate)
        case .cameraMaker:
            return "Apple"
        case .cameraModel:
            return "iPhone 17 Pro Max"
        case .lensModel:
            return ""
        case .focalLength:
            return "20mm"
        case .aperture:
            return "f/1.9"
        case .shutterSpeed:
            return "1/117s"
        case .iso:
            return "ISO80"
        case .exposureBias:
            return "0 EV"
        case .meteringMode:
            return "Pattern"
        case .flash:
            return "未开启"
        case .whiteBalance:
            return "自动"
        case .captureSummary:
            return "20mm f/1.9 1/117s ISO80"
        case .location:
            return "河南 · 商丘"
        case .altitude:
            return "42m"
        case .imageSize:
            return "4032 × 3024"
        case .orientation:
            return "横向"
        case .fileFormat:
            return "HEIC"
        case .custom:
            return "自定义内容"
        }
    }

    private var smartTimeResult: String {
        captureTimeResolver.resolveText(
            captureDate: mockCaptureDate,
            referenceDate: birthdayDate,
            calendar: smartTimeCalendar
        )
    }

    private var mockCaptureDate: Date {
        Calendar.current.date(
            from: DateComponents(
                year: 2026,
                month: 5,
                day: 24,
                hour: 14,
                minute: 33
            )
        ) ?? Date()
    }

    private var captureDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter
    }

    private var captureTimeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }

    private var smartTimeCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 8 * 3600) ?? .current
        return calendar
    }

    private var latestShareDiagnosticEvent:
        PhotoMemoShareDiagnosticEvent? {

        shareDiagnosticEvents.last
    }

    private var shareDiagnosticsHeadline: String {
        guard let event =
            latestShareDiagnosticEvent else {
            return "等待下一次分享"
        }

        if shareDiagnosticEvents.contains(where: {
            $0.stage == "liveActivity.request.created"
        }) {
            return "进度已交给系统"
        }

        if shareDiagnosticEvents.contains(where: {
            $0.stage == "app.enqueue.created"
        }) {
            return "照片已进入处理队列"
        }

        if shareDiagnosticEvents.contains(where: {
            $0.stage == "app.openURL.share"
        }) {
            return "PhotoMemo 已被唤起"
        }

        if event.stage.contains("failed")
            || event.stage.contains("error") {
            return "这次分享需要查看"
        }

        return "正在交给 PhotoMemo"
    }

    private var shareDiagnosticsSubheadline: String {
        guard let event =
            latestShareDiagnosticEvent else {
            return "分享一次照片后，这里会显示接收、入队和进度创建结果。"
        }

        return "\(event.stage) · \(event.message)"
    }

    private var shareDiagnosticsSymbolName: String {
        if shareDiagnosticEvents.contains(where: {
            $0.stage == "liveActivity.request.created"
        }) {
            return "checkmark.circle.fill"
        }

        if latestShareDiagnosticEvent?.stage.contains("failed") == true
            || latestShareDiagnosticEvent?.stage.contains("error") == true {
            return "exclamationmark.triangle.fill"
        }

        if shareDiagnosticEvents.isEmpty {
            return "square.stack.3d.down.forward"
        }

        return "arrow.trianglehead.2.clockwise.circle.fill"
    }

    private var shareDiagnosticsTint: Color {
        if shareDiagnosticEvents.contains(where: {
            $0.stage == "liveActivity.request.created"
        }) {
            return .green
        }

        if latestShareDiagnosticEvent?.stage.contains("failed") == true
            || latestShareDiagnosticEvent?.stage.contains("error") == true {
            return .orange
        }

        if shareDiagnosticEvents.isEmpty {
            return .secondary
        }

        return .blue
    }

    private func refreshShareDiagnostics() {
        shareDiagnosticEvents =
            PhotoMemoShareDiagnostics
            .loadEvents()
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
        for kind: MVPScrollOffsetKind
    ) -> some View {
        GeometryReader { proxy in
            Color.clear
                .preference(
                    key: MVPScrollOffsetPreferenceKey.self,
                    value: [
                        kind: proxy.frame(
                            in: .named("mvp-scroll")
                        ).minY
                    ]
                )
        }
        .onPreferenceChange(MVPScrollOffsetPreferenceKey.self) { values in
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

    private func bootstrapDrafts() {
        var drafts: [CardRegion: MVPEditorDraft] = [:]

        for region in CardRegion.memoryCardRegions {
            drafts[region] = makeDefaultDraft(for: region)
        }

        regionDrafts = drafts
        refreshDynamicPreview()
    }

    private var selectedPresetBinding: Binding<MemoryPreset.ID> {
        Binding(
            get: {
                session.state.selectedMemoryPreset?.id
                ?? session.state.memoryPresets.first?.id
                ?? UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
            },
            set: { newValue in
                let currentID =
                    session.state.selectedMemoryPreset?.id

                guard newValue != currentID else {
                    return
                }

                guard let preset = session.state.memoryPresets.first(where: {
                    $0.id == newValue
                }) else {
                    return
                }
                session.selectMemoryPreset(preset)
                bootstrapDrafts()
                pendingActivationPresetTitle = preset.title
                activeConfigurationMessage = "有未保存修改"
                showsPresetActivationConfirmation = true
            }
        )
    }
}

private struct MVPEditorDraft: Hashable {
    var items: [MVPContentItem]

    var modules: [MVPContentItem] {
        items.filter { $0.kind != .text }
    }

    var singleLineText: String {
        InlineContentTextComposer.compose(
            items.map { item in
                InlineContentTextComposer.Piece(
                    kind: item.kind.inlineComposerKind,
                    value: item.displayValue
                )
            }
        )
    }

    var singleLineTemplateText: String {
        InlineContentTextComposer.compose(
            items.map { item in
                InlineContentTextComposer.Piece(
                    kind: item.kind.inlineComposerKind,
                    value: item.templateValue
                )
            }
        )
    }

    mutating func updateTextItem(
        _ item: MVPContentItem,
        text: String
    ) {
        guard let index =
            items.firstIndex(where: { $0.id == item.id })
        else {
            return
        }

        items[index].value = text
        items[index].savedValue = text
    }

    @discardableResult
    mutating func prependText(_ text: String) -> UUID? {
        let trimmed =
            text.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !trimmed.isEmpty else {
            return nil
        }

        let item = MVPContentItem.text(text)
        items.insert(item, at: 0)
        return item.id
    }

    @discardableResult
    mutating func appendText(_ text: String) -> UUID? {
        let trimmed =
            text.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !trimmed.isEmpty else {
            return nil
        }

        let item = MVPContentItem.text(text)
        items.append(item)
        return item.id
    }

    mutating func appendComposedItem(
        _ item: MVPContentItem
    ) {
        if let last = items.last,
           last.kind == .text,
           last.value
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .isEmpty {
            items.insert(
                item,
                at: max(items.count - 1, 0)
            )
        } else {
            items.append(item)
        }

        normalizeTrailingTextInput()
    }

    mutating func insertComposedItem(
        _ item: MVPContentItem,
        after anchorID: UUID?
    ) {
        guard let anchorID,
              let anchorIndex =
                items.firstIndex(where: { $0.id == anchorID })
        else {
            appendComposedItem(item)
            return
        }

        let anchor = items[anchorIndex]
        let insertionIndex: Int

        if anchor.kind == .text,
           anchor.value
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .isEmpty {
            insertionIndex = anchorIndex
        } else {
            insertionIndex = min(anchorIndex + 1, items.count)
        }

        items.insert(item, at: insertionIndex)
        normalizeTrailingTextInput()
    }

    mutating func normalizeTrailingTextInput() {
        while items.count > 1,
              let last = items.last,
              let previous = items.dropLast().last,
              last.kind == .text,
              previous.kind == .text,
              last.value
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .isEmpty {
            items.removeLast()
        }

        if let last = items.last,
           last.kind != .text {
            items.append(.text(""))
        }
    }
}

private struct MVPContentItem: Identifiable, Hashable {

    enum Kind: Hashable {
        case text
        case token
        case separator
        case lineBreak
    }

    let id: UUID
    let kind: Kind
    var title: String
    var value: String
    var savedValue: String
    var systemImage: String

    var displayValue: String {
        switch kind {
        case .text, .token, .separator:
            return value
        case .lineBreak:
            return " "
        }
    }

    var templateValue: String {
        switch kind {
        case .text, .separator:
            return value
        case .token:
            return savedValue
        case .lineBreak:
            return " "
        }
    }

    static func text(_ value: String) -> MVPContentItem {
        MVPContentItem(
            id: UUID(),
            kind: .text,
            title: "文字",
            value: value,
            savedValue: value,
            systemImage: "textformat"
        )
    }

    static func token(
        _ title: String,
        value: String,
        templateValue: String,
        systemImage: String
    ) -> MVPContentItem {
        MVPContentItem(
            id: UUID(),
            kind: .token,
            title: title,
            value: value,
            savedValue: templateValue,
            systemImage: systemImage
        )
    }

    static func separator(_ value: String) -> MVPContentItem {
        MVPContentItem(
            id: UUID(),
            kind: .separator,
            title: "分隔符",
            value: value,
            savedValue: value,
            systemImage: "circle.fill"
        )
    }
}

private extension MVPContentItem.Kind {

    var inlineComposerKind: InlineContentTextComposer.PieceKind {
        switch self {
        case .text:
            return .text
        case .token:
            return .token
        case .separator:
            return .separator
        case .lineBreak:
            return .lineBreak
        }
    }
}

private struct MVPCardSurface<Content: View>: View {

    let title: String
    @ViewBuilder var content: Content

    init(
        title: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(
                cornerRadius: ConfigurationUI.cornerRadius,
                style: .continuous
            )
            .fill(ConfigurationUI.panelBackground)
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: ConfigurationUI.cornerRadius,
                style: .continuous
            )
                .stroke(ConfigurationUI.faintHairline)
        )
        .shadow(color: ConfigurationUI.cardShadow, radius: 8, y: 3)
    }
}

private struct MVPPreviewCard: View {

    let logoMode: MVPLogoMode
    let customLogoImagePath: String?
    let regionText: String
    let timeText: String
    let contextText: String
    let memoryText: String

    var body: some View {
        MVPCardSurface(title: "预览") {
            Color.clear
            .aspectRatio(compactPreviewAspectRatio, contentMode: .fit)
            .overlay {
                GeometryReader { proxy in
                    compactPreviewCard(size: proxy.size)
                }
            }
            .clipShape(
                RoundedRectangle(
                    cornerRadius: ConfigurationUI.cornerRadius,
                    style: .continuous
                )
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius: ConfigurationUI.cornerRadius,
                    style: .continuous
                )
                    .stroke(ConfigurationUI.faintHairline)
            )
        }
    }

    private var compactSpec: CompactInformationBarSpec {
        RendererConstants.CompactInformationBar.landscape
    }

    private var compactPreviewAspectRatio: CGFloat {
        1 / compactSpec.barHeightToWidth
    }

    private func compactPreviewCard(size: CGSize) -> some View {
        let barHeight =
            size.width
            * compactSpec.barHeightToWidth

        return compactInformationBar(
            width: size.width,
            height: barHeight
        )
        .frame(height: barHeight)
    }

    private func compactInformationBar(
        width: CGFloat,
        height: CGFloat
    ) -> some View {
        let spec = compactSpec

        return ZStack(alignment: .topLeading) {
            RendererConstants.CompactInformationBar.background

            compactTextPair(
                primary: regionText,
                secondary: timeText,
                spec: spec,
                barHeight: height,
                emphasizesPrimary: true,
                primaryMinimumScaleFactor: 0.94,
                secondaryMinimumScaleFactor: 0.90
            )
            .frame(
                width:
                    width
                    * compactPreviewLeftTextWidth(
                        spec: spec
                    ),
                height: height * 0.62,
                alignment: .leading
            )
            .position(
                x:
                    width * spec.leftX
                    + width
                    * compactPreviewLeftTextWidth(
                        spec: spec
                    ) / 2,
                y: height * spec.contentCenterY
            )

            compactLogo(
                spec: spec,
                barHeight: height
            )
            .position(
                x: width * spec.logoCenterX,
                y: height * spec.contentCenterY
            )

            Rectangle()
                .fill(RendererConstants.CompactInformationBar.divider)
                .frame(
                    width:
                        min(
                            max(
                                height
                                * spec.dividerWidthToBarHeight,
                                1
                            ),
                            4
                        ),
                    height: height * spec.dividerHeight
                )
                .position(
                    x: width * spec.dividerCenterX,
                    y:
                        height * spec.dividerTopY
                        + height * spec.dividerHeight / 2
                )

            compactTextPair(
                primary: formattedCaptureSummaryText,
                secondary: memoryText,
                spec: spec,
                barHeight: height,
                primaryMinimumScaleFactor: 0.72,
                secondaryMinimumScaleFactor: 0.82
            )
            .frame(
                width: width * spec.rightWidth,
                height: height * 0.62,
                alignment: .leading
            )
            .position(
                x:
                    width * spec.rightX
                    + width * spec.rightWidth / 2,
                y: height * spec.contentCenterY
            )
        }
    }

    private func compactPreviewLeftTextWidth(
        spec: CompactInformationBarSpec
    ) -> CGFloat {

        min(
            max(
                spec.leftWidth,
                0.46
            ),
            spec.logoCenterX
            - spec.leftX
            - 0.10
        )
    }

    private func compactTextPair(
        primary: String,
        secondary: String,
        spec: CompactInformationBarSpec,
        barHeight: CGFloat,
        emphasizesPrimary: Bool = false,
        primaryMinimumScaleFactor: CGFloat = 0.84,
        secondaryMinimumScaleFactor: CGFloat = 0.84
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: barHeight * spec.groupSpacingToBarHeight
        ) {
            compactTextLine(
                primary,
                fontSize:
                    barHeight
                    * spec.primaryFontToBarHeight
                    * (emphasizesPrimary ? 1.08 : 1),
                weight: emphasizesPrimary ? .heavy : .bold,
                tracking: spec.primaryTracking,
                color:
                    emphasizesPrimary
                    ? Color.black.opacity(0.98)
                    :
                    RendererConstants
                    .CompactInformationBar
                    .primaryText,
                minimumScaleFactor: primaryMinimumScaleFactor
            )

            compactTextLine(
                secondary,
                fontSize:
                    barHeight
                    * spec.secondaryFontToBarHeight,
                weight: .regular,
                tracking: spec.secondaryTracking,
                color:
                    emphasizesPrimary
                    ? Color.black.opacity(0.70)
                    :
                    RendererConstants
                    .CompactInformationBar
                    .secondaryText,
                minimumScaleFactor: secondaryMinimumScaleFactor
            )
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .center
        )
    }

    private func compactTextLine(
        _ value: String,
        fontSize: CGFloat,
        weight: Font.Weight,
        tracking: CGFloat,
        color: Color,
        minimumScaleFactor: CGFloat
    ) -> some View {
        Text(value.isEmpty ? " " : value)
            .font(
                .system(
                    size: fontSize,
                    weight: weight
                )
            )
            .kerning(tracking)
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(minimumScaleFactor)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func compactLogo(
        spec: CompactInformationBarSpec,
        barHeight: CGFloat
    ) -> some View {
        let logoSize =
            barHeight
            * spec.logoSizeToBarHeight

        return Group {
            switch logoMode {
            case .appleMini:
                Image(systemName: "apple.logo")
                    .font(.system(size: logoSize, weight: .semibold))
            case .customUpload:
                if let customLogoImagePath,
                   let image = UIImage(contentsOfFile: customLogoImagePath) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                } else {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: logoSize * 0.78, weight: .semibold))
                }
            }
        }
        .symbolRenderingMode(.hierarchical)
        .foregroundStyle(RendererConstants.CompactInformationBar.logoTint)
        .frame(width: logoSize * 1.25, height: logoSize * 1.25)
    }

    private var formattedCaptureSummaryText: String {
        let facts =
            contextText
            .split(separator: " ")
            .map(String.init)
            .prefix(RendererConstants.CaptureSummary.allowedFactCount)

        guard !facts.isEmpty else {
            return contextText
        }

        return facts.joined(separator: " ")
    }
}

private struct MVPRegionEditorCard: View {

    let region: CardRegion
    let draft: MVPEditorDraft
    let resolvedText: String
    let onFocus: () -> Void
    let onFocusTextItem: (MVPContentItem) -> Void
    let onUpdateTextItem: (MVPContentItem, String) -> Void
    let onPrependText: (String) -> Void
    let onAppendText: (String) -> Void
    let onRemoveItem: (MVPContentItem) -> Void
    let onAddSeparator: (String) -> Void
    let onShowModules: () -> Void

    var body: some View {
        MVPCardSurface(title: region.semanticTitle) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Text(region.displayTitle)
                        .font(.headline.weight(.semibold))
                    Spacer()
                    Button("添加模块") {
                        onShowModules()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 3) {
                        if draft.items.first?.kind != .text {
                            transientTextField(
                                placeholder: "短语",
                                minWidth: 46,
                                onChange: onPrependText
                            )
                            .onTapGesture(perform: onFocus)
                        }

                        ForEach(draft.items) { item in
                            switch item.kind {
                            case .text:
                                editableTextField(item)

                            case .token,
                                 .separator,
                                 .lineBreak:
                                HStack(spacing: 4) {
                                    Image(systemName: item.systemImage)
                                    Text(item.title)
                                    Button {
                                        onRemoveItem(item)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundStyle(.secondary)
                                }
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 5)
                                .background(
                                    Capsule()
                                        .fill(Color.accentColor.opacity(0.09))
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(Color.accentColor.opacity(0.16))
                                )
                            }
                        }

                        if draft.items.last?.kind != .text {
                            transientTextField(
                                placeholder: "短语",
                                minWidth: 58,
                                onChange: onAppendText
                            )
                            .onTapGesture(perform: onFocus)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 7)
                }
                .background(
                    RoundedRectangle(
                        cornerRadius: 10,
                        style: .continuous
                    )
                    .fill(Color(uiColor: .secondarySystemBackground))
                )
                .overlay(
                    RoundedRectangle(
                        cornerRadius: 10,
                        style: .continuous
                    )
                    .stroke(Color.primary.opacity(0.08))
                )

                HStack(spacing: 8) {
                    Text("分隔符")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    ForEach(["·", "|", "/"], id: \.self) { separator in
                        Button(separator) {
                            onAddSeparator(separator)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.mini)
                    }

                    Spacer(minLength: 0)
                }

                if !resolvedText.isEmpty {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("组合结果")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)

                        Text(resolvedText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
    }

    private func editableTextField(
        _ item: MVPContentItem
    ) -> some View {
        TextField(
            "短语",
            text: Binding(
                get: { item.value },
                set: {
                    onUpdateTextItem(
                        item,
                        $0
                    )
                }
            ),
            axis: .horizontal
        )
        .textFieldStyle(.plain)
        .font(.subheadline)
        .frame(minWidth: textFieldWidth(for: item.value))
        .lineLimit(1)
        .onTapGesture {
            onFocusTextItem(item)
        }
    }

    private func transientTextField(
        placeholder: String,
        minWidth: CGFloat,
        onChange: @escaping (String) -> Void
    ) -> some View {
        TextField(
            placeholder,
            text: Binding(
                get: { "" },
                set: onChange
            ),
            axis: .horizontal
        )
        .textFieldStyle(.plain)
        .font(.subheadline)
        .frame(minWidth: minWidth)
        .lineLimit(1)
    }

    private func textFieldWidth(
        for value: String
    ) -> CGFloat {
        let trimmed =
            value.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !trimmed.isEmpty else {
            return 52
        }

        return min(
            max(CGFloat(trimmed.count) * 18, 42),
            180
        )
    }
}

private enum MVPLogoMode:
    String,
    CaseIterable,
    Identifiable {

    case appleMini
    case customUpload

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .appleMini:
            return "Apple 标识"
        case .customUpload:
            return "自选标识"
        }
    }
}

private enum MVPIOSOutputTarget:
    String,
    CaseIterable,
    Identifiable {

    case automatic
    case applePhotos
    case existingAlbum
    case newAlbum

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .automatic:
            return "自动"
        case .applePhotos:
            return "系统图库"
        case .existingAlbum:
            return "已有相册"
        case .newAlbum:
            return "新建相册"
        }
    }

    var note: String {
        switch self {
        case .automatic:
            return "不选择时，生成照片会进入系统图库，并自动归入 photomemo 相册。"
        case .applePhotos:
            return "生成照片只写入系统图库，不额外加入 PhotoMemo 指定相册。"
        case .existingAlbum:
            return "生成照片会写入系统图库，并加入选中的相册。"
        case .newAlbum:
            return "保存配置时会创建或复用这个相册。"
        }
    }
}

private struct MVPResolvedAlbumSelection {

    let identifier: String

    let title: String
}

private enum MVPScrollOffsetKind:
    Hashable {

    case profile
    case preview
}

private struct MVPScrollOffsetPreferenceKey:
    PreferenceKey {

    static var defaultValue: [MVPScrollOffsetKind: CGFloat] = [:]

    static func reduce(
        value: inout [MVPScrollOffsetKind: CGFloat],
        nextValue: () -> [MVPScrollOffsetKind: CGFloat]
    ) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

#Preview("iOS MVP 测试") {
    PhotoMemoiOSMVPTestView()
}
#endif
