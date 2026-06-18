import Foundation
import SwiftUI
#if os(macOS)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

enum MainFieldSlot: String, CaseIterable, Hashable {

    case leftTop

    case rightTop

    case leftBottom

    case rightBottom

    var title: String {

        switch self {

        case .leftTop:
            return "左上区域"

        case .rightTop:
            return "右上区域"

        case .leftBottom:
            return "左下区域"

        case .rightBottom:
            return "右下区域"
        }
    }

    var placeholder: String {

        switch self {

        case .leftTop:
            return "例如：他爹手持{{model}}记录"

        case .rightTop:
            return "例如：{{focal_len_in_35mm_film}}mm f/{{aperture}} {{shutter}}s ISO{{iso}}"

        case .leftBottom:
            return "例如：记录于{{capture_date_display}}"

        case .rightBottom:
            return "例如：途途到今天{{anchor_age_text}} / 距离高考{{anchor_countdown_text}}"
        }
    }
}

enum TemplateComposerSegment: Hashable {

    case variable(TemplateVariable)

    case literal(String)
}

struct TemplateComposerItem: Identifiable, Hashable {

    let id: String

    var segment: TemplateComposerSegment

    init(
        id: String,
        segment: TemplateComposerSegment
    ) {
        self.id = id
        self.segment = segment
    }
}

private struct ComposerDragModifier: ViewModifier {

    let isEnabled: Bool

    let item: TemplateComposerItem

    @ViewBuilder
    func body(
        content: Content
    ) -> some View {

        if isEnabled {

            content.draggable(item.id) {

                HStack(spacing: 8) {

                    Image(
                        systemName: previewIcon
                    )
                    .font(.caption.weight(.semibold))

                    Text(previewTitle)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(
                    Capsule()
                        .fill(Color.white)
                )
                .overlay(
                    Capsule()
                        .stroke(
                            Color.black.opacity(0.08)
                        )
                )
            }

        } else {

            content
        }
    }

    private var previewIcon: String {

        switch item.segment {

        case .variable:
            return "square.stack.3d.up"

        case .literal:
            return "character.textbox"
        }
    }

    private var previewTitle: String {

        switch item.segment {

        case .variable(let variable):
            return variable.title

        case .literal(let literal):
            return literal
        }
    }
}

struct InlineTemplateTextEditor: View {

    @Binding
    var text: String

    @Binding
    var selection: NSRange

    var onFocus: () -> Void

#if os(macOS)
    var body: some View {
        MacInlineTemplateTextEditor(
            text: $text,
            selection: $selection,
            onFocus: onFocus
        )
    }
#elseif canImport(UIKit)
    var body: some View {
        UIKitInlineTemplateTextEditor(
            text: $text,
            selection: $selection,
            onFocus: onFocus
        )
    }
#else
    var body: some View {
        TextField(
            "",
            text: $text,
            axis: .vertical
        )
        .textFieldStyle(.plain)
        .font(.system(size: 14, weight: .medium))
        .onTapGesture {
            onFocus()
            selection = NSRange(
                location: (text as NSString).length,
                length: 0
            )
        }
    }
#endif
}

#if os(macOS)
private struct MacInlineTemplateTextEditor: NSViewRepresentable {

    @Binding
    var text: String

    @Binding
    var selection: NSRange

    var onFocus: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(
        context: Context
    ) -> NSScrollView {

        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true

        let textView = NSTextView()
        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.importsGraphics = false
        textView.isEditable = true
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(
            width: 0,
            height: 6
        )
        textView.font = .systemFont(
            ofSize: 14,
            weight: .medium
        )
        textView.textColor = NSColor.labelColor
        textView.alignment = .left
        textView.string = text
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.widthTracksTextView = true
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.autoresizingMask = [.width]

        scrollView.documentView = textView
        context.coordinator.textView = textView
        context.coordinator.applySelection()
        return scrollView
    }

    func updateNSView(
        _ nsView: NSScrollView,
        context: Context
    ) {

        guard let textView =
            context.coordinator.textView
        else {
            return
        }

        context.coordinator.parent = self

        // Preserve macOS IME composition so Chinese pinyin input
        // is not interrupted by SwiftUI state synchronization.
        guard !textView.hasMarkedText() else {
            return
        }

        if textView.string != text {
            textView.string = text
        }

        context.coordinator.applySelection()
    }

    final class Coordinator:
        NSObject,
        NSTextViewDelegate
    {

        var parent: MacInlineTemplateTextEditor

        weak var textView: NSTextView?

        init(
            _ parent: MacInlineTemplateTextEditor
        ) {
            self.parent = parent
        }

        func textDidBeginEditing(
            _ notification: Notification
        ) {

            parent.onFocus()
        }

        func textDidChange(
            _ notification: Notification
        ) {

            guard let textView else {
                return
            }

            parent.text = textView.string
            parent.selection = textView.selectedRange()
        }

        func textViewDidChangeSelection(
            _ notification: Notification
        ) {

            guard let textView else {
                return
            }

            parent.selection = textView.selectedRange()
        }

        func applySelection() {

            guard let textView else {
                return
            }

            let length =
                (textView.string as NSString).length

            let clampedLocation =
                min(
                    max(parent.selection.location, 0),
                    length
                )

            let clampedLength =
                min(
                    max(parent.selection.length, 0),
                    length - clampedLocation
                )

            let safeRange = NSRange(
                location: clampedLocation,
                length: clampedLength
            )

            if textView.selectedRange() != safeRange {
                textView.setSelectedRange(safeRange)
            }
        }
    }
}
#endif

#if canImport(UIKit)
private struct UIKitInlineTemplateTextEditor: UIViewRepresentable {

    @Binding
    var text: String

    @Binding
    var selection: NSRange

    var onFocus: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(
        context: Context
    ) -> UITextView {

        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.backgroundColor = .clear
        textView.font = .systemFont(
            ofSize: 14,
            weight: .medium
        )
        textView.textColor = .label
        textView.textContainerInset = UIEdgeInsets(
            top: 6,
            left: 0,
            bottom: 6,
            right: 0
        )
        textView.textContainer.lineFragmentPadding = 0
        textView.isScrollEnabled = false
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none
        textView.text = text

        context.coordinator.textView = textView
        context.coordinator.applySelection()
        return textView
    }

    func updateUIView(
        _ uiView: UITextView,
        context: Context
    ) {

        context.coordinator.parent = self

        guard
            uiView.markedTextRange == nil
        else {
            return
        }

        if uiView.text != text {
            uiView.text = text
        }

        context.coordinator.applySelection()
    }

    final class Coordinator:
        NSObject,
        UITextViewDelegate
    {

        var parent: UIKitInlineTemplateTextEditor

        weak var textView: UITextView?

        init(
            _ parent: UIKitInlineTemplateTextEditor
        ) {
            self.parent = parent
        }

        func textViewDidBeginEditing(
            _ textView: UITextView
        ) {

            parent.onFocus()
        }

        func textViewDidChange(
            _ textView: UITextView
        ) {

            parent.text = textView.text
            parent.selection = textView.selectedRange
        }

        func textViewDidChangeSelection(
            _ textView: UITextView
        ) {

            parent.selection = textView.selectedRange
        }

        func applySelection() {

            guard let textView else {
                return
            }

            let length =
                (textView.text as NSString?)?.length ?? 0

            let clampedLocation =
                min(
                    max(parent.selection.location, 0),
                    length
                )

            let clampedLength =
                min(
                    max(parent.selection.length, 0),
                    length - clampedLocation
                )

            let safeRange = NSRange(
                location: clampedLocation,
                length: clampedLength
            )

            if textView.selectedRange != safeRange {
                textView.selectedRange = safeRange
            }
        }
    }
}
#endif

enum MinimalPalette {

    static let background =
        Color(
            red: 246 / 255,
            green: 247 / 255,
            blue: 249 / 255
        )

    static let surface = Color.white

    static let border =
        Color.black.opacity(0.05)

    static let accent =
        Color(
            red: 111 / 255,
            green: 125 / 255,
            blue: 166 / 255
        )
}

private struct MinimalCardGroupBoxStyle: GroupBoxStyle {

    func makeBody(
        configuration: Configuration
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 16
        ) {

            configuration.label
                .font(.headline)
                .foregroundStyle(.primary)

            configuration.content
        }
        .padding(18)
        .background(
            RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
            .fill(
                MinimalPalette.surface
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
            .stroke(
                MinimalPalette.border
            )
        )
        .shadow(
            color: .black.opacity(0.04),
            radius: 20,
            y: 10
        )
    }
}

struct MinimalChipStyle: ButtonStyle {

    func makeBody(
        configuration: Configuration
    ) -> some View {

        configuration.label
            .font(.subheadline.weight(.medium))
            .foregroundStyle(
                .primary.opacity(
                    configuration.isPressed ? 0.7 : 1
                )
            )
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                Capsule()
                    .fill(
                        Color.gray.opacity(
                            configuration.isPressed
                            ? 0.14
                            : 0.1
                        )
                    )
            )
    }
}

struct MinimalInsetCard<Content: View>: View {

    @ViewBuilder
    let content: Content

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 10
        ) {
            content
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
            .fill(
                Color.gray.opacity(0.08)
            )
        )
    }
}

struct MainView: View {

    @EnvironmentObject
    private var batchQueueStore:
        BatchQueueStore

    @Environment(\.scenePhase)
    private var scenePhase

    @StateObject
    private var settings = SettingsService()

    @StateObject
    private var permissionCenter =
        PermissionCenter()

    @State
    private var selectedPhoto: SelectedPhoto?

    @State
    private var selectedAnchorID: Anchor.ID?

    @State
    private var titleText = ""

    @State
    private var storyText = ""

    @State
    private var showAnchorManager = false

    @State
    private var alertTitle = ""

    @State
    private var alertMessage = ""

    @State
    private var showAlert = false

    @State
    private var availableAlbums: [PhotoAlbumOption] = []

    @State
    private var selectedAlbumIdentifier =
        PhotoAlbumOption.automaticIdentifier

    @State
    private var isLoadingAlbums = false

    @State
    private var isSavingToAlbum = false

    @State
    private var isPreparingMetadataValidation =
        false

    @State
    private var isPreparingLibraryMetadataValidation =
        false

    @State
    private var showLiteralComposerSheet = false

    @State
    private var showTemplateRenameSheet = false

    @State
    private var showPermissionSetupSheet = false

    @State
    private var metadataValidationReport:
        MetadataValidationReport?

    @State
    private var showOperationGuideSheet = false

    @State
    private var showWorkspaceConfigurationRenameSheet =
        false

    @State
    private var selectedOperationGuideTopic:
        MainOperationGuideTopic = .overview

    @State
    private var workspaceConfigurationNameDraft =
        ""

    @State
    private var templateNameDraft = ""

    @State
    private var literalComposerDraft = ""

    @State
    private var literalComposerTargetSlot:
        MainFieldSlot?

    @State
    private var arrangingComposerSlot:
        MainFieldSlot?

    @State
    private var composerWigglePhase = false

    @State
    private var templateEditorSelections:
        [MainFieldSlot: NSRange] = [:]

    @State
    private var composerItemsBySlot:
        [MainFieldSlot: [TemplateComposerItem]] = [:]

    @State
    private var activeTemplateEditorSlot:
        MainFieldSlot?

    @State
    private var selectedComposerItemIDs:
        [MainFieldSlot: String] = [:]

    @State
    private var composerViewportWidths:
        [MainFieldSlot: CGFloat] = [:]

    @State
    private var composerContentWidths:
        [MainFieldSlot: CGFloat] = [:]

    @State
    private var draggedComposerItemIDs:
        [MainFieldSlot: String] = [:]

    @State
    private var hoveredComposerItemIDs:
        [MainFieldSlot: String] = [:]

    @State
    private var insertionComposerIndices:
        [MainFieldSlot: Int] = [:]

    @State
    private var focusedField: MainFieldSlot?

    private let templatePresetEngine =
        TemplatePresetEngine()

    private let anchorEngine =
        AnchorEngine()

    private let cardBuildService =
        RecordCardBuildService()

    private let exportService =
        RecordCardExportService()

    private let photoLibraryExportService =
        PhotoLibraryExportService()

    private let metadataReader =
        PhotoMetadataReader()

    var body: some View {

        ZStack {

            MinimalPalette.background
                .ignoresSafeArea()

            rootContent
        }
        .tint(
            MinimalPalette.accent
        )
        .sheet(
            isPresented: $showAnchorManager
        ) {

            NavigationStack {

                AnchorListView(
                    anchors: $settings.anchors,
                    selectedAnchorID: $selectedAnchorID
                ) {

                    settings.saveAnchors()
                }
            }
            .frame(
                minWidth: 520,
                minHeight: 420
            )
        }
        .sheet(
            isPresented: $showLiteralComposerSheet
        ) {

            literalComposerSheet
        }
        .sheet(
            isPresented: $showTemplateRenameSheet
        ) {

            templateRenameSheet
        }
        .sheet(
            isPresented: $showPermissionSetupSheet
        ) {

            permissionSetupSheet
        }
        .sheet(
            isPresented: $showOperationGuideSheet
        ) {

            operationGuideSheet
        }
        .sheet(
            isPresented:
                $showWorkspaceConfigurationRenameSheet
        ) {

            workspaceConfigurationRenameSheet
        }
        .sheet(
            item: $metadataValidationReport
        ) { report in

            NavigationStack {
                MetadataValidationDebugView(
                    report: report
                )
            }
            .frame(
                minWidth: 720,
                minHeight: 640
            )
        }
        .onAppear {

            configureInitialState()
            migrateLegacyConfigurationIntoActiveSlotIfNeeded()
            syncBatchQueueDefaultConfiguration()

            Task {
                await preparePermissionsOnAppear()
            }
        }
        .onChange(
            of: scenePhase
        ) { _, newValue in

            guard newValue == .active else {
                return
            }

            Task {
                await refreshPermissionsForActiveScene()
            }
        }
        .onChange(
            of: settings.anchors
        ) { _, anchors in

            syncSelectedAnchor(
                with: anchors
            )
            syncBatchQueueDefaultConfiguration()
        }
        .onChange(
            of: settings.selectedTemplate
        ) { _, _ in

            guard
                shouldRefreshComposerItemsFromTemplate()
            else {
                return
            }

            syncComposerItemsFromTemplate(
                resetTransientState: true
            )
            syncBatchQueueDefaultConfiguration()
        }
        .onChange(
            of: selectedAnchorID
        ) { _, newValue in

            persistEditorDraftState(
                selectedAnchorID: newValue
            )
            syncBatchQueueDefaultConfiguration()
        }
        .onChange(
            of: titleText
        ) { _, newValue in

            persistEditorDraftState(
                draftTitleText: newValue
            )
            syncBatchQueueDefaultConfiguration()
        }
        .onChange(
            of: storyText
        ) { _, newValue in

            persistEditorDraftState(
                draftStoryText: newValue
            )
            syncBatchQueueDefaultConfiguration()
        }
        .onChange(
            of: selectedAlbumIdentifier
        ) { _, newValue in

            persistEditorDraftState(
                selectedAlbumIdentifier: newValue
            )
            syncBatchQueueDefaultConfiguration()
        }
        .onChange(
            of: settings.selectedBadge
        ) { _, _ in

            syncBatchQueueDefaultConfiguration()
        }
        .onChange(
            of: settings.shouldWritePhotoDescription
        ) { _, _ in

            settings.schedulePhotoDescriptionSettingsSave()
            syncBatchQueueDefaultConfiguration()
        }
        .onChange(
            of: settings.photoDescriptionOverride
        ) { _, _ in

            settings.schedulePhotoDescriptionSettingsSave()
            syncBatchQueueDefaultConfiguration()
        }
        .alert(
            alertTitle,
            isPresented: $showAlert
        ) {

            Button("好") {
            }

        } message: {

            Text(alertMessage)
        }
    }

    @ViewBuilder
    var rootContent: some View {

#if os(macOS)
        NavigationSplitView {

            sidebar

        } detail: {

            detail
        }
#else
        NavigationStack {

            ScrollView {

                VStack(
                    alignment: .leading,
                    spacing: 24
                ) {

                    detailContent

                    editorContent
                }
                .padding(20)
            }
            .navigationTitle("PhotoMemo")
            .navigationBarTitleDisplayMode(.inline)
        }
#endif
    }
}

// MARK: - Sidebar
private extension MainView {

    var editorContent: some View {

        VStack(
            alignment: .leading,
            spacing: 20
        ) {

            Text("PhotoMemo")
                .font(.system(
                    size: 32,
                    weight: .semibold
                ))

            Text("本地 EXIF 卡片生成")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            heroPanel

            memoryProgressPanel

            if shouldShowPermissionSection {
                GroupBox("本地权限") {
                    permissionSection
                }
            }

            GroupBox("照片") {
                photoSection
            }

            GroupBox("模板") {
                templateSection
            }

            GroupBox("时间锚点") {
                anchorSection
            }

            GroupBox("个性化区域") {
                fieldEditorSection
            }

            GroupBox("补充信息") {
                customContentSection
            }

            GroupBox("Logo 标识") {
                badgeSection
            }

            GroupBox("输出") {
                outputSection
            }

            Spacer(minLength: 0)
        }
        .groupBoxStyle(
            MinimalCardGroupBoxStyle()
        )
    }

    var sidebar: some View {

        ScrollView {

            editorContent
        }
        .padding(24)
        .frame(
            minWidth: 360,
            maxWidth: .infinity,
            alignment: .topLeading
        )
    }
}

private extension MainView {

    var photoSection: some View {
        MainPhotoSectionView(
            selectedPhotoDeviceModel: {
                guard let selectedPhoto else {
                    return nil
                }

                let deviceModel =
                    selectedPhoto.metadata.deviceModel

                return deviceModel.isEmpty
                    ? "未识别设备"
                    : deviceModel
            }(),
            selectedPhotoCaptureDateText:
                selectedPhoto?.metadata.captureDate?
                .formatted(
                    date: .abbreviated,
                    time: .shortened
                ),
            importer: {
                PhotoImporterView { photo in

                    selectedPhoto = photo

                    if titleText.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ).isEmpty {

                        titleText =
                            selectedAnchor?.title
                            ?? "PhotoMemo"
                    }
                }
            }
        )
    }

    var templateSection: some View {
        MainTemplateSectionView(
            selectedPreset: selectedTemplatePreset,
            resolvedTemplateDisplayName:
                resolvedTemplateDisplayName,
            currentPresetDisplayName:
                currentPreset.displayName,
            currentPresetDefaultOutput:
                currentPresetDefaultOutput,
            currentPresetSummary:
                currentPreset.summary,
            onPresentTemplateRename: {
                presentTemplateRenameSheet()
            },
            onResetTemplateDefaults: {
                settings.selectedTemplate =
                    templatePresetEngine.build(
                        preset: currentPreset
                    )
                syncComposerItemsFromTemplate(
                    resetTransientState: true
                )
                settings.saveTemplate()
            }
        )
    }

    var anchorSection: some View {
        MainAnchorSectionView(
            anchors: settings.anchors,
            selectedAnchorID: $selectedAnchorID,
            anchorPhotoSummary: anchorPhotoSummary,
            selectedAnchorDateText:
                selectedAnchor.map {
                    anchorDateText($0)
                },
            previewSummaryText:
                anchorPreviewResult?.summaryText,
            quickFacts:
                anchorPreviewResult.map { preview in
                    anchorQuickFacts(preview).map {
                        MainAnchorQuickFact(
                            label: $0.label,
                            value: $0.value
                        )
                    }
                } ?? [],
            emptyStateText:
                "选择一个时间点后，系统会按照片 EXIF 拍摄时间自动计算年岁、纪念时长、已过天数、未来倒计时，以及第几天、周数、月龄等时间结果模块。",
            onPresentAnchorManager: {
                showAnchorManager = true
            }
        )
    }

    var fieldEditorSection: some View {

        VStack(
            alignment: .leading,
            spacing: 18
        ) {

            composerEntryPanel

            variableLibraryPanel(
                title: "识别数据",
                variables: TemplateVariableLibrary.recognized
            )

            variableLibraryPanel(
                title: "智能数据",
                variables: TemplateVariableLibrary.intelligent
            )

            variableLibraryPanel(
                title: "用户数据",
                variables: TemplateVariableLibrary.user
            )

            templateFieldEditors
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }

    var templateFieldEditors: some View {

        ForEach(
            MainFieldSlot.allCases,
            id: \.self
        ) { slot in

            templateFieldEditor(for: slot)
        }
    }

    var customContentSection: some View {
        MainCustomContentSectionView(
            titleText: $titleText,
            storyText: $storyText,
            shouldWritePhotoDescription:
                $settings.shouldWritePhotoDescription,
            photoDescriptionOverride:
                $settings.photoDescriptionOverride,
            defaultPhotoDescriptionHint:
                defaultPhotoDescriptionHint
        )
    }

    var badgeSection: some View {
        MainBadgeSectionView(
            badgeNames:
                BadgeLibrary.defaults.map(\.name),
            selectedBadgeName: selectedBadgeName,
            selectedBadgeTitle: selectedBadgeTitle,
            selectedBadgeSummary: selectedBadgeSummary,
            preview: {
                badgePreviewIcon
            }
        )
    }

    var outputSection: some View {
        MainOutputSection(
            selectedAlbumIdentifier:
                $selectedAlbumIdentifier,
            availableAlbums: availableAlbums,
            selectedAlbumSummary:
                selectedAlbumSummary,
            isSavingToAlbum: isSavingToAlbum,
            canExportCurrentCard:
                selectedPhoto != nil
                && currentCard != nil,
            saveCurrentCardToAlbum: {
                Task {
                    await saveCurrentCardToAlbum()
                }
            }
        )
    }

    var heroPanel: some View {

        HStack(spacing: 10) {

            MainStatusPillView(
                title: "模板",
                value: resolvedTemplateDisplayName
            )

            MainStatusPillView(
                title: "时间点",
                value:
                    selectedAnchor?.title
                    ?? "未设置"
            )

            MainStatusPillView(
                title: "图库",
                value:
                    permissionCenter.canAccessPhotoLibrary
                    ? "原信息保留"
                    : "待授权"
            )
        }
    }

    var permissionSection: some View {
        MainPermissionSection(
            photoLibraryState:
                permissionCenter
                .photoLibraryState,
            notificationState:
                permissionCenter
                .notificationState,
            requestPhotoLibraryPermission: {
                Task {
                    await requestPhotoLibraryPermission()
                }
            },
            openPhotoLibrarySettings: {
                permissionCenter
                    .openSystemSettings(
                        for: .photoLibrary
                    )
            },
            requestNotificationPermission: {
                Task {
                    await requestNotificationPermission()
                }
            },
            openNotificationSettings: {
                permissionCenter
                    .openSystemSettings(
                        for: .notifications
                    )
            }
        )
    }

    var shouldShowPermissionSection: Bool {
        !permissionCenter.photoLibraryState.isGranted
            || !permissionCenter.notificationState
            .isGranted
    }

    var memoryProgressPanel: some View {
        MainMemoryProgressPanel(
            snapshot: batchQueueStore.usageSnapshot,
            defaultConfigurationSnapshot:
                batchQueueStore
                .defaultConfigurationSnapshot,
            availableAlbums: availableAlbums,
            latestExternalIntakeSummary:
                batchQueueStore
                .latestExternalIntakeSummary,
            latestFailureSummary:
                batchQueueStore
                .latestFailureSummary,
            recentFailureRecords:
                Array(
                    batchQueueStore
                    .recentFailureRecords
                    .prefix(3)
                ),
            retryFailedTasks: { jobID in
                batchQueueStore.retryFailedTasks(
                    in: jobID
                )
            }
        )
    }

    var permissionSetupSheet: some View {
        MainPermissionSetupSheet(
            dismiss: {
                showPermissionSetupSheet = false
            },
            requestInitialPermissions: {
                Task {
                    await requestInitialPermissions()
                }
            }
        )
    }

    @ViewBuilder
    var composerEntryPanel: some View {
        MainComposerEntryPanel(
            currentEditingSlotTitle:
                currentEditingSlotTitle,
            currentEditingSlot:
                currentEditingSlot,
            focusedField: focusedField,
            arrangingComposerSlot:
                arrangingComposerSlot,
            onPresentLiteralComposer: {
                presentLiteralComposer()
            },
            onDismissComposerArrangeMode: {
                dismissComposerArrangeMode()
            },
            onActivateEditingSlot: { slot in
                activateEditingSlot(
                    slot,
                    preferInlineEditor: true
                )
            }
        )
    }

    @ViewBuilder
    var literalComposerSheet: some View {
        MainLiteralComposerSheetView(
            targetSlotTitle:
                (literalComposerTargetSlot
                ?? currentEditingSlot)?
                .title ?? "未选择区域",
            draft: $literalComposerDraft,
            onCancel: {
                closeLiteralComposer()
            },
            onCommit: {
                commitLiteralComposer()
            }
        )
    }

    @ViewBuilder
    func variableLibraryPanel(
        title: String,
        variables: [TemplateVariable]
    ) -> some View {
        MainVariableLibraryPanel(
            title: title,
            variables: variables,
            isEnabled:
                currentEditingSlot != nil,
            onInsertVariable: { variable in
                dismissComposerArrangeMode()
                insertToken(variable.token)
            },
            onDismissArrangeMode: {
                dismissComposerArrangeMode()
            }
        )
    }

    @ViewBuilder
    func templateFieldEditor(
        for slot: MainFieldSlot
    ) -> some View {

        let items =
            composerItems(
                for: slot
            )

        let selectedItemID =
            selectedComposerItemIDs[slot]

        let hoveredItemID =
            hoveredComposerItemIDs[slot]

        MainTemplateFieldEditorView(
            slot: slot,
            items: items,
            selectedItemID: selectedItemID,
            hoveredItemID: hoveredItemID,
            arrangingComposerSlot:
                arrangingComposerSlot,
            focusedField: focusedField,
            shouldShowScrubber:
                shouldShowComposerScrubber(
                    for: slot
                ),
            onActivateEditingSlot: {
                activateEditingSlot(
                    slot,
                    preferInlineEditor: true
                )
            },
            onTapComposerItem: { itemID, proxy in
                if arrangingComposerSlot != slot {
                    dismissComposerArrangeMode()
                }

                focusComposerItem(
                    itemID,
                    slot: slot,
                    proxy: proxy
                )
            },
            onEnterArrangeMode: { itemID in
                enterComposerArrangeMode(
                    for: slot,
                    itemID: itemID
                )
            },
            onHoverComposerItem: {
                itemID,
                isHovered in

                if isHovered {
                    hoveredComposerItemIDs[slot] =
                        itemID
                } else if hoveredComposerItemIDs[slot]
                    == itemID {
                    hoveredComposerItemIDs[slot] =
                        nil
                }
            },
            onDropComposerItem: {
                droppedID,
                targetID,
                proxy in

                reorderComposerItems(
                    in: slot,
                    from: droppedID,
                    to: targetID
                )

                if let selectedID =
                    selectedComposerItemIDs[slot] {

                    withAnimation(
                        .easeInOut(duration: 0.2)
                    ) {
                        proxy.scrollTo(
                            selectedID,
                            anchor: .center
                        )
                    }
                }

                return true
            },
            onDropTargetingComposerItem: {
                itemID,
                isTargeted in

                if isTargeted,
                   arrangingComposerSlot == slot {
                    draggedComposerItemIDs[slot] =
                        itemID
                } else if draggedComposerItemIDs[slot]
                    == itemID {
                    draggedComposerItemIDs[slot] =
                        nil
                }
            },
            onComposerContentWidthChange: {
                newWidth in
                composerContentWidths[slot] =
                    newWidth
            },
            onComposerViewportWidthChange: {
                newWidth in
                composerViewportWidths[slot] =
                    newWidth
            },
            onSyncSelectedComposerItem: {
                proxy,
                syncedItems in

                syncSelectedComposerItem(
                    for: slot,
                    items: syncedItems,
                    proxy: proxy
                )
            },
            showInsertionHandle: {
                index,
                itemID,
                composerItems in

                shouldShowInsertionHandle(
                    slot: slot,
                    index: index,
                    itemID: itemID,
                    items: composerItems
                )
            },
            chip: {
                item,
                isSelected,
                isHovered,
                isArranging in
                MainComposerChipView(
                    title:
                        composerChipTitle(
                            for: item
                        ),
                    plainLiteralText:
                        plainLiteralText(
                            for: item
                        ),
                    style:
                        composerChipStyle(
                            for: item
                        ),
                    isSelected: isSelected,
                    isHovered: isHovered,
                    isArranging: isArranging,
                    composerWigglePhase:
                        composerWigglePhase,
                    onRemove: {
                        removeComposerItem(
                            item,
                            from: slot
                        )
                    }
                )
            },
            insertionHandle: {
                index,
                proxy in
                MainComposerInsertionHandleView(
                    isSelected:
                        insertionComposerIndices[slot]
                        == index,
                    onSelect: {
                        selectInsertionPoint(
                            index,
                            in: slot,
                            proxy: proxy
                        )
                    }
                )
            },
            scrubber: {
                proxy,
                scrubberItems in

                composerScrubber(
                    for: slot,
                    items: scrubberItems,
                    proxy: proxy
                )
            },
            inlineEditor: {
                MainInlineTemplateEditorView(
                    slot: slot,
                    isFocused:
                        focusedField == slot,
                    text:
                        templateValueBinding(
                            for: slot
                        ),
                    selection:
                        templateEditorSelectionBinding(
                            for: slot
                        ),
                    onFocus: {
                        activateEditingSlot(
                            slot,
                            preferInlineEditor: true
                        )
                    }
                )
            }
        )
    }

}

// MARK: - Detail
private extension MainView {

    @ViewBuilder
    var detail: some View {

        ScrollView {

            detailContent
                .padding()
        }
    }

    @ViewBuilder
    var detailContent: some View {

        VStack(
            alignment: .center,
            spacing: 22
        ) {

            workspaceConfigurationPanel
                .frame(
                    maxWidth: 900,
                    alignment: .leading
                )

            if let selectedPhoto,
               let card = currentCard {

                let previewWidth =
                    previewCardMaxWidth(
                        for: selectedPhoto
                    )

                MainPreviewDetailView(
                    previewImage:
                        selectedPhoto.image
                        .swiftUIImage,
                    card: card,
                    previewWidth: previewWidth
                )

            } else {

                ContentUnavailableView(
                    "还没有导入照片",
                    systemImage: "photo"
                )
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    var badgePreviewIcon: some View {

        ZStack {

            RoundedRectangle(
                cornerRadius: 16,
                style: .continuous
            )
            .fill(
                Color.white.opacity(0.92)
            )

            if let selectedBadge = settings.selectedBadge,
               selectedBadge.type != .none,
               let symbol = selectedBadge.systemSymbol {

                Image(systemName: symbol)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(MinimalPalette.accent)

            } else {

                Image(
                    systemName:
                        currentPreset == .immersWhite
                        ? "applelogo"
                        : "sparkles"
                )
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 48, height: 48)
        .overlay(
            RoundedRectangle(
                cornerRadius: 16,
                style: .continuous
            )
            .stroke(
                MinimalPalette.border
            )
        )
    }
}

private extension MainView {

    var currentCard: RecordCard? {

        guard let selectedPhoto else {
            return nil
        }

        return cardBuildService.buildCard(
            from: selectedPhoto,
            configuration:
                currentBatchConfigurationSnapshot
        )
    }

    var currentBatchConfigurationSnapshot:
        BatchConfigurationSnapshot {

        settings.buildBatchConfigurationSnapshot(
            selectedAnchorID: selectedAnchorID,
            draftTitleText: titleText,
            draftStoryText: storyText,
            selectedAlbumIdentifier:
                selectedAlbumIdentifier
        )
    }

    var activeWorkspaceConfigurationSlot:
        WorkspaceConfigurationSlot {

        settings.configurationSlot(
            for: settings.activeConfigurationSlotID
        )
        ?? WorkspaceConfigurationSlot.defaultSlots[0]
    }

    var workspaceConfigurationSummary: String {

        let slot =
            activeWorkspaceConfigurationSlot

        if slot.isCustomized {
            return "当前生效：\(slot.displayTitleWithReference)。切换到其他配置后，左侧模板、时间点、Logo 标识、补充信息和输出规则会整体刷新。"
        }

        return "当前生效：\(slot.displayTitleWithReference)。这套配置还未单独保存，暂时使用\(slot.defaultPreset.displayName)默认骨架。"
    }

    var activeTemplate: Template {

        settings.selectedTemplate
        ?? .template1
    }

    var currentPreset: TemplatePreset {

        activeTemplate.preset
    }

    var currentPresetDefaultOutput: String {

        switch currentPreset {

        case .template1:
            return "今天{{anchor_age_text}}"

        case .template2:
            return "已经{{anchor_duration_text}}"

        case .template3:
            return "{{anchor_countdown_text}}"

        case .immersWhite:
            return "{{memory_summary}}"
        }
    }

    var selectedAnchor: Anchor? {

        settings.anchors.first {
            $0.id == selectedAnchorID
        }
    }

    var anchorPreviewResult: AnchorResult? {

        guard let selectedAnchor else {
            return nil
        }

        return anchorEngine.build(
            from: selectedAnchor,
            photoDate:
                selectedPhoto?.metadata.captureDate
                ?? Date()
        )
    }

    var photoTimeDescription: String {

        guard let captureDate =
            selectedPhoto?.metadata.captureDate
        else {
            return "导入照片后，系统会用照片 EXIF 拍摄时间与锚点时间做差值计算，可生成年岁、纪念时长、已过天数、未来倒计时，以及第几天、周数、月龄等时间结果。"
        }

        return "当前照片 EXIF 时间：\(captureDate.formatted(date: .numeric, time: .standard))"
    }

    var anchorPhotoSummary: String {

        guard let captureDate =
            selectedPhoto?.metadata.captureDate
        else {
            return "导入照片后会自动读取 EXIF 拍摄时间"
        }

        return captureDate.formatted(
            date: .abbreviated,
            time: .shortened
        )
    }

    var selectedAlbumSummary: String {

        guard permissionCenter.canAccessPhotoLibrary else {
            return "请先允许访问系统相册"
        }

        if selectedAlbumIdentifier
            == PhotoAlbumOption.automaticIdentifier {
            return "自动存入 PhotoMemo"
        }

        return availableAlbums.first {
            $0.id == selectedAlbumIdentifier
        }?.title ?? "当前相册"
    }

    var selectedBadgeTitle: String {

        guard let badge = settings.selectedBadge,
              badge.type != .none else {
            if currentPreset == .immersWhite {
                return "自动 Apple 标识"
            }

            return "保持留白"
        }

        return badge.name
    }

    var selectedBadgeSummary: String {

        guard let badge = settings.selectedBadge,
              badge.type != .none else {
            if currentPreset == .immersWhite {
                return "未自定义时，Immers 白边会自动使用经典 Apple 小标识，并贴近右侧信息区显示。"
            }

            return "当前模板会保留标识区域留白，适合更极简的版式。"
        }

        if badge.isSystemDefault {
            return "使用系统标识，适合底栏白边的克制视觉风格。"
        }

        return "使用自定义标识资源。"
    }

    var defaultPhotoDescription: String {

        guard let selectedPhoto else {
            return ""
        }

        return cardBuildService
            .defaultPhotoDescription(
                from: selectedPhoto,
                configuration:
                    currentBatchConfigurationSnapshot
            )
    }

    var defaultPhotoDescriptionHint: String {

        let resolvedDefault =
            defaultPhotoDescription

        if resolvedDefault.isEmpty {
            return "默认说明会跟随右下区域内容；如果右下区域暂时为空，就不会额外写入说明。"
        }

        return "默认说明：\(resolvedDefault)"
    }

    func anchorDateText(
        _ anchor: Anchor
    ) -> String {

        anchor.date.formatted(
            date: .abbreviated,
            time: .shortened
        )
    }

    func anchorQuickFacts(
        _ preview: AnchorResult
    ) -> [(label: String, value: String)] {

        if preview.isFutureRelative {
            return [
                ("倒计时", preview.countdownText),
                ("时间点", preview.secondaryText)
            ]
        }

        if let anchor = selectedAnchor,
           anchor.type == .birthday {
            return [
                ("年岁", preview.ageText),
                ("第几天", preview.dayIndexText),
                ("月龄", preview.monthAgeText)
            ]
            .filter {
                !$0.value.isEmpty
            }
        }

        var facts: [(String, String)] = [
            ("时长", preview.durationText),
            ("已过", preview.elapsedText)
        ]

        if !preview.milestoneText.isEmpty {
            facts.append(
                ("里程碑", preview.milestoneText)
            )
        }

        return facts.filter {
            !$0.1.isEmpty
        }
    }

    var selectedTemplatePreset: Binding<TemplatePreset> {

        Binding(
            get: {

                currentPreset
            },
            set: { preset in

                settings.selectedTemplate =
                    templatePresetEngine.build(
                        preset: preset
                    )

                syncComposerItemsFromTemplate(
                    resetTransientState: true
                )
                settings.saveTemplate()
            }
        )
    }

    var resolvedTemplateDisplayName: String {

        let trimmed =
            activeTemplate.name
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        if !trimmed.isEmpty {
            return trimmed
        }

        return currentPreset.displayName
    }

    @ViewBuilder
    var operationGuideSheet: some View {
        MainOperationGuideSheetView(
            selectedTopic:
                selectedOperationGuideTopic,
            onDismiss: {
                showOperationGuideSheet = false
            }
        )
    }

    @ViewBuilder
    var workspaceConfigurationRenameSheet:
        some View {

        MainWorkspaceConfigurationRenameSheetView(
            slotReferenceTitle:
                activeWorkspaceConfigurationSlot.title,
            currentDisplayTitle:
                activeWorkspaceConfigurationSlot
                .displayTitle,
            titleDraft:
                $workspaceConfigurationNameDraft,
            onCancel: {
                showWorkspaceConfigurationRenameSheet =
                    false
            },
            onSave: {
                applyWorkspaceConfigurationRename()
            }
        )
    }

    var workspaceConfigurationPanel: some View {
        MainWorkspaceConfigurationPanelView(
            slots: settings.configurationSlots,
            activeSlotID:
                settings.activeConfigurationSlotID,
            activeSlotSummary:
                workspaceConfigurationSummary,
            activeSlotDisplayTitle:
                activeWorkspaceConfigurationSlot
                .displayTitle,
            onSelectSlot: { slotID in
                selectWorkspaceConfigurationSlot(
                    slotID
                )
            },
            onRenameActiveSlot: {
                presentWorkspaceConfigurationRenameSheet()
            },
            onSaveActiveSlot: {
                saveCurrentConfiguration()
            },
            onRestoreActiveSlotDefault: {
                restoreActiveWorkspaceConfigurationToDefault()
            },
            onOpenGuideTopic: { topic in
                selectedOperationGuideTopic =
                    topic
                showOperationGuideSheet = true
            }
        )
    }

    @ViewBuilder
    var templateRenameSheet: some View {
        MainTemplateRenameSheetView(
            templateNameDraft: $templateNameDraft,
            currentPresetDisplayName:
                currentPreset.displayName,
            resolvedTemplateDisplayName:
                resolvedTemplateDisplayName,
            onCancel: {
                showTemplateRenameSheet = false
            },
            onSave: {
                applyTemplateRename()
            }
        )
    }

    func presentTemplateRenameSheet() {

        templateNameDraft =
            resolvedTemplateDisplayName
        showTemplateRenameSheet = true
    }

    func presentWorkspaceConfigurationRenameSheet() {

        workspaceConfigurationNameDraft =
            activeWorkspaceConfigurationSlot
            .resolvedCustomTitle
            ?? ""
        showWorkspaceConfigurationRenameSheet = true
    }

    func applyTemplateRename() {

        var template = activeTemplate

        let trimmedName =
            templateNameDraft
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        template.name =
            trimmedName.isEmpty
            ? currentPreset.displayName
            : trimmedName

        settings.selectedTemplate = template
        syncComposerItemsFromTemplate(
            resetTransientState: true
        )
        settings.scheduleTemplateSave()
        showTemplateRenameSheet = false
    }

    func applyWorkspaceConfigurationRename() {

        let trimmedName =
            workspaceConfigurationNameDraft
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        settings.renameConfigurationSlot(
            settings.activeConfigurationSlotID,
            customTitle:
                trimmedName.isEmpty
                ? nil
                : trimmedName
        )

        showWorkspaceConfigurationRenameSheet = false
    }

    var selectedBadgeName: Binding<String> {

        Binding(
            get: {

                settings.selectedBadge?.name
                ?? Badge.none.name
            },
            set: { badgeName in

                settings.selectedBadge =
                    BadgeLibrary.defaults.first {
                        $0.name == badgeName
                    } ?? Badge.none

                settings.saveBadge()
            }
        )
    }

    var currentEditingSlot: MainFieldSlot? {

        activeTemplateEditorSlot
        ?? focusedField
    }

    var currentEditingSlotTitle: String {

        currentEditingSlot?.title
        ?? "请先选择区域"
    }

    func shouldRefreshComposerItemsFromTemplate()
    -> Bool {

        for slot in MainFieldSlot.allCases {

            guard
                let items =
                    composerItemsBySlot[slot]
            else {
                return true
            }

            if serializeComposerItems(items)
                != templateValue(for: slot) {
                return true
            }
        }

        return false
    }

    func templateValue(
        for slot: MainFieldSlot
    ) -> String {

        switch slot {

        case .leftTop:
            return activeTemplate.leftTopArea.items.first?.value ?? ""

        case .rightTop:
            return activeTemplate.rightTopArea.items.first?.value ?? ""

        case .leftBottom:
            return activeTemplate.leftBottomArea.items.first?.value ?? ""

        case .rightBottom:
            return activeTemplate.rightBottomArea.items.first?.value ?? ""
        }
    }

    func updateTemplateValue(
        _ value: String,
        for slot: MainFieldSlot,
        composerItemsOverride:
            [TemplateComposerItem]? = nil
    ) {

        var template = activeTemplate

        switch slot {

        case .leftTop:
            update(
                &template.leftTopArea.items,
                fallback: .title,
                value: value
            )

        case .rightTop:
            update(
                &template.rightTopArea.items,
                fallback: .cameraSummary,
                value: value
            )

        case .leftBottom:
            update(
                &template.leftBottomArea.items,
                fallback: .captureDateLine,
                value: value
            )

        case .rightBottom:
            update(
                &template.rightBottomArea.items,
                fallback: .anchorSmartText,
                value: value
            )
        }

        settings.selectedTemplate = template
        settings.scheduleTemplateSave()
        composerItemsBySlot[slot] =
            composerItemsOverride
            ?? reconciledComposerItems(
                for: slot,
                from: value
            )

        let length =
            (value as NSString).length

        if let currentSelection =
            templateEditorSelections[slot] {

            let clampedLocation =
                min(
                    currentSelection.location,
                    length
                )

            let clampedLength =
                min(
                    currentSelection.length,
                    max(length - clampedLocation, 0)
                )

            templateEditorSelections[slot] =
                NSRange(
                    location: clampedLocation,
                    length: clampedLength
                )
        } else {
            templateEditorSelections[slot] =
                NSRange(
                    location: length,
                    length: 0
                )
        }
    }

    func templateValueBinding(
        for slot: MainFieldSlot
    ) -> Binding<String> {

        Binding(
            get: {
                templateValue(for: slot)
            },
            set: { newValue in
                updateTemplateValue(
                    newValue,
                    for: slot
                )
            }
        )
    }

    func templateEditorSelectionBinding(
        for slot: MainFieldSlot
    ) -> Binding<NSRange> {

        Binding(
            get: {
                templateEditorSelections[slot]
                ?? NSRange(
                    location:
                        (templateValue(
                            for: slot
                        ) as NSString).length,
                    length: 0
                )
            },
            set: { newValue in
                templateEditorSelections[slot] =
                    newValue
            }
        )
    }

    func composerItems(
        for slot: MainFieldSlot
    ) -> [TemplateComposerItem] {

        composerItemsBySlot[slot]
        ?? reconciledComposerItems(
            for: slot,
            from: templateValue(for: slot)
        )
    }

    func parseComposerItems(
        from value: String
    ) -> [TemplateComposerItem] {

        parsedComposerSegments(from: value)
            .map { segment in
                TemplateComposerItem(
                    id: UUID().uuidString,
                    segment: segment
                )
            }
    }

    func parsedComposerSegments(
        from value: String
    ) -> [TemplateComposerSegment] {

        guard !value.isEmpty else {
            return []
        }

        let pattern = #"\{\{[^}]+\}\}"#

        guard
            let regex = try? NSRegularExpression(
                pattern: pattern
            )
        else {
            return [
                .literal(value)
            ]
        }

        let nsRange =
            NSRange(
                value.startIndex..<value.endIndex,
                in: value
            )

        let matches =
            regex.matches(
                in: value,
                range: nsRange
            )

        var items: [TemplateComposerSegment] = []
        var cursor = value.startIndex

        for match in matches {

            guard
                let range = Range(
                    match.range,
                    in: value
                )
            else {
                continue
            }

            if cursor < range.lowerBound {

                let literal =
                    String(
                        value[cursor..<range.lowerBound]
                    )

                if !literal.isEmpty {
                    items.append(
                        .literal(literal)
                    )
                }
            }

            let token =
                String(value[range])

            if let variable =
                templateVariable(
                    for: token
                ) {

                items.append(
                    .variable(variable)
                )

            } else {

                items.append(
                    .literal(token)
                )
            }

            cursor = range.upperBound
        }

        if cursor < value.endIndex {

            let trailing =
                String(value[cursor...])

            if !trailing.isEmpty {
                items.append(
                    .literal(trailing)
                )
            }
        }

        return items
    }

    func reconciledComposerItems(
        for slot: MainFieldSlot,
        from value: String
    ) -> [TemplateComposerItem] {

        let segments =
            parsedComposerSegments(from: value)

        guard !segments.isEmpty else {
            return []
        }

        let previousItems =
            composerItemsBySlot[slot] ?? []

        var nextItems: [TemplateComposerItem] = []
        var searchStartIndex = 0

        for segment in segments {

            let matchedIndex: Int?

            if searchStartIndex < previousItems.count {
                matchedIndex =
                    previousItems[searchStartIndex...]
                    .firstIndex {
                        $0.segment == segment
                    }
            } else {
                matchedIndex = nil
            }

            if let matchedIndex {
                nextItems.append(
                    TemplateComposerItem(
                        id: previousItems[matchedIndex].id,
                        segment: segment
                    )
                )
                searchStartIndex =
                    previousItems.index(
                        after: matchedIndex
                    )
            } else {
                nextItems.append(
                    TemplateComposerItem(
                        id: UUID().uuidString,
                        segment: segment
                    )
                )
            }
        }

        return nextItems
    }

    func templateVariable(
        for token: String
    ) -> TemplateVariable? {

        TemplateVariableLibrary.all.first {
            $0.token == token
        }
    }

    func serializeComposerItems(
        _ items: [TemplateComposerItem]
    ) -> String {

        items.map { item in

            switch item.segment {

            case .variable(let variable):
                return variable.token

            case .literal(let literal):
                return literal
            }
        }
        .joined()
    }

    func appendComposerItems(
        _ items: [TemplateComposerItem],
        to slot: MainFieldSlot
    ) {

        var existingItems =
            composerItems(for: slot)

        let insertionIndex =
            resolvedInsertionIndex(
                in: slot,
                items: existingItems
            )

        existingItems.insert(
            contentsOf: items,
            at: insertionIndex
        )

        updateTemplateValue(
            serializeComposerItems(
                existingItems
            ),
            for: slot,
            composerItemsOverride:
                existingItems
        )

        if !items.isEmpty {
            selectedComposerItemIDs[slot] =
                items.last?.id
            insertionComposerIndices[slot] =
                insertionIndex + items.count
        }
    }

    func removeComposerItem(
        _ item: TemplateComposerItem,
        from slot: MainFieldSlot
    ) {

        let currentItems =
            composerItems(for: slot)

        let removedItemIndex =
            removedIndex(
                for: item.id,
                in: currentItems
            ) ?? 0

        var items = currentItems

        items.removeAll {
            $0.id == item.id
        }

        let nextIndex =
            min(
                removedItemIndex,
                max(items.count - 1, 0)
            )

        updateTemplateValue(
            serializeComposerItems(
                items
            ),
            for: slot,
            composerItemsOverride: items
        )

        selectedComposerItemIDs[slot] =
            items.isEmpty
            ? nil
            : items[nextIndex].id
        insertionComposerIndices[slot] =
            min(nextIndex + 1, items.count)

        activateEditingSlot(
            slot,
            preferInlineEditor: false
        )
    }

    func selectedComposerIndex(
        in slot: MainFieldSlot,
        items: [TemplateComposerItem]
    ) -> Int? {

        guard
            let selectedID =
                selectedComposerItemIDs[slot]
        else {
            return nil
        }

        return items.firstIndex {
            $0.id == selectedID
        }
    }

    func shouldShowInsertionHandle(
        slot: MainFieldSlot,
        index: Int,
        itemID: String,
        items: [TemplateComposerItem]
    ) -> Bool {

        guard
            let selectedIndex =
                selectedComposerIndex(
                    in: slot,
                    items: items
                )
        else {
            return false
        }

        if items[selectedIndex].id != itemID {
            return false
        }

        return index == selectedIndex
            || index == selectedIndex + 1
    }

    func removedIndex(
        for itemID: String,
        in items: [TemplateComposerItem]
    ) -> Int? {

        items.firstIndex {
            $0.id == itemID
        }
    }

    func focusComposerItem(
        _ itemID: String,
        slot: MainFieldSlot,
        proxy: ScrollViewProxy
    ) {

        selectedComposerItemIDs[slot] = itemID
        activateEditingSlot(
            slot,
            preferInlineEditor: false
        )

        if let index =
            composerItems(for: slot)
            .firstIndex(where: { $0.id == itemID }) {
            insertionComposerIndices[slot] =
                index + 1
        }

        withAnimation(.easeInOut(duration: 0.2)) {
            proxy.scrollTo(
                itemID,
                anchor: .center
            )
        }
    }

    func syncSelectedComposerItem(
        for slot: MainFieldSlot,
        items: [TemplateComposerItem],
        proxy: ScrollViewProxy
    ) {

        guard !items.isEmpty else {
            selectedComposerItemIDs[slot] = nil
            return
        }

        let existingID =
            selectedComposerItemIDs[slot]

        let targetID: String

        if let existingID,
           items.contains(where: { $0.id == existingID }) {
            targetID = existingID
        } else {
            targetID = items.last?.id ?? items[0].id
            selectedComposerItemIDs[slot] = targetID
        }

        if let selectedIndex =
            items.firstIndex(
                where: { $0.id == targetID }
            ) {
            insertionComposerIndices[slot] =
                selectedIndex + 1
        }

        withAnimation(.easeInOut(duration: 0.2)) {
            proxy.scrollTo(
                targetID,
                anchor: .center
            )
        }
    }

    func reorderComposerItems(
        in slot: MainFieldSlot,
        from sourceID: String,
        to destinationID: String
    ) {

        var items =
            composerItems(for: slot)

        guard
            let sourceIndex =
                items.firstIndex(
                    where: { $0.id == sourceID }
                ),
            let destinationIndex =
                items.firstIndex(
                    where: { $0.id == destinationID }
                ),
            sourceIndex != destinationIndex
        else {
            return
        }

        let movedItem =
            items.remove(at: sourceIndex)

        let adjustedDestination =
            sourceIndex < destinationIndex
            ? max(destinationIndex - 1, 0)
            : destinationIndex

        items.insert(
            movedItem,
            at: adjustedDestination
        )

        updateTemplateValue(
            serializeComposerItems(items),
            for: slot,
            composerItemsOverride: items
        )

        selectedComposerItemIDs[slot] =
            movedItem.id
        insertionComposerIndices[slot] =
            adjustedDestination + 1
        activateEditingSlot(
            slot,
            preferInlineEditor: false
        )
    }

    func resolvedInsertionIndex(
        in slot: MainFieldSlot,
        items: [TemplateComposerItem]
    ) -> Int {

        if let explicitIndex =
            insertionComposerIndices[slot] {
            return min(
                max(explicitIndex, 0),
                items.count
            )
        }

        let selectedIndex =
            selectedComposerIndex(
                in: slot,
                items: items
            )

        return min(
            max(
                (selectedIndex ?? (items.count - 1))
                + 1,
                0
            ),
            items.count
        )
    }

    func selectInsertionPoint(
        _ index: Int,
        in slot: MainFieldSlot,
        proxy: ScrollViewProxy
    ) {

        insertionComposerIndices[slot] = index
        activateEditingSlot(
            slot,
            preferInlineEditor: false
        )

        let items =
            composerItems(for: slot)

        let targetScrollID: String?

        if items.isEmpty {
            targetScrollID = nil
        } else if index == 0 {
            targetScrollID = items.first?.id
        } else {
            targetScrollID =
                items[
                    min(index - 1, items.count - 1)
                ].id
        }

        if let targetScrollID {
            withAnimation(.easeInOut(duration: 0.2)) {
                proxy.scrollTo(
                    targetScrollID,
                    anchor: .center
                )
            }
        }
    }

    func shouldShowComposerScrubber(
        for slot: MainFieldSlot
    ) -> Bool {

        let viewportWidth =
            composerViewportWidths[slot] ?? 0

        let contentWidth =
            composerContentWidths[slot] ?? 0

        return contentWidth > viewportWidth + 6
    }

    @ViewBuilder
    func composerScrubber(
        for slot: MainFieldSlot,
        items: [TemplateComposerItem],
        proxy: ScrollViewProxy
    ) -> some View {

        GeometryReader { geometry in

            let trackWidth =
                max(geometry.size.width, 1)

            let viewportWidth =
                composerViewportWidths[slot] ?? trackWidth

            let contentWidth =
                max(
                    composerContentWidths[slot] ?? trackWidth,
                    trackWidth
                )

            let thumbWidth =
                max(
                    trackWidth
                    * min(viewportWidth / contentWidth, 1),
                    28
                )

            let progress =
                scrubberProgress(
                    for: slot,
                    items: items
                )

            let thumbOffset =
                (trackWidth - thumbWidth)
                * progress

            ZStack(alignment: .leading) {

                Capsule()
                    .fill(
                        Color.black.opacity(0.08)
                    )

                Capsule()
                    .fill(
                        MinimalPalette.accent.opacity(0.55)
                    )
                    .frame(width: thumbWidth)
                    .offset(x: thumbOffset)
            }
            .frame(height: 5)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        updateScrubberSelection(
                            at: value.location.x,
                            trackWidth: trackWidth,
                            thumbWidth: thumbWidth,
                            slot: slot,
                            items: items,
                            proxy: proxy
                        )
                    }
            )
        }
        .frame(height: 8)
    }

    func scrubberProgress(
        for slot: MainFieldSlot,
        items: [TemplateComposerItem]
    ) -> CGFloat {

        guard
            items.count > 1,
            let selectedID =
                selectedComposerItemIDs[slot],
            let index =
                items.firstIndex(
                    where: { $0.id == selectedID }
                )
        else {
            return 0
        }

        return CGFloat(index)
            / CGFloat(items.count - 1)
    }

    func updateScrubberSelection(
        at locationX: CGFloat,
        trackWidth: CGFloat,
        thumbWidth: CGFloat,
        slot: MainFieldSlot,
        items: [TemplateComposerItem],
        proxy: ScrollViewProxy
    ) {

        guard !items.isEmpty else {
            return
        }

        if items.count == 1 {
            focusComposerItem(
                items[0].id,
                slot: slot,
                proxy: proxy
            )
            return
        }

        let availableWidth =
            max(trackWidth - thumbWidth, 1)

        let clampedX =
            min(
                max(locationX - thumbWidth / 2, 0),
                availableWidth
            )

        let progress =
            clampedX / availableWidth

        let index =
            Int(
                round(
                    progress
                    * CGFloat(items.count - 1)
                )
            )

        let safeIndex =
            min(
                max(index, 0),
                items.count - 1
            )

        focusComposerItem(
            items[safeIndex].id,
            slot: slot,
            proxy: proxy
        )
    }

    func composerChipTitle(
        for item: TemplateComposerItem
    ) -> String {

        switch item.segment {

        case .variable(let variable):
            return variable.title

        case .literal(let literal):
            return separatorDisplayTitle(
                for: literal
            ) ?? literal
        }
    }

    func plainLiteralText(
        for item: TemplateComposerItem
    ) -> String? {

        guard case .literal(let literal) = item.segment else {
            return nil
        }

        if separatorDisplayTitle(
            for: literal
        ) != nil {
            return nil
        }

        return literal
    }

    func composerChipStyle(
        for item: TemplateComposerItem
    ) -> MainComposerChipStyle {

        switch item.segment {

        case .variable(let variable):

            let resolvedIcon =
                variableChipIcon(
                    for: variable
                )

            switch variable.category {

            case .recognized:
                return MainComposerChipStyle(
                    icon: resolvedIcon,
                    tint: Color(
                        red: 61 / 255,
                        green: 92 / 255,
                        blue: 168 / 255
                    ),
                    background: Color(
                        red: 61 / 255,
                        green: 92 / 255,
                        blue: 168 / 255
                    ).opacity(0.12),
                    border: Color(
                        red: 61 / 255,
                        green: 92 / 255,
                        blue: 168 / 255
                    ).opacity(0.18)
                )

            case .intelligent:
                return MainComposerChipStyle(
                    icon: resolvedIcon,
                    tint: Color(
                        red: 188 / 255,
                        green: 108 / 255,
                        blue: 37 / 255
                    ),
                    background: Color(
                        red: 188 / 255,
                        green: 108 / 255,
                        blue: 37 / 255
                    ).opacity(0.12),
                    border: Color(
                        red: 188 / 255,
                        green: 108 / 255,
                        blue: 37 / 255
                    ).opacity(0.18)
                )

            case .user:
                return MainComposerChipStyle(
                    icon: resolvedIcon,
                    tint: Color(
                        red: 80 / 255,
                        green: 102 / 255,
                        blue: 84 / 255
                    ),
                    background: Color(
                        red: 80 / 255,
                        green: 102 / 255,
                        blue: 84 / 255
                    ).opacity(0.12),
                    border: Color(
                        red: 80 / 255,
                        green: 102 / 255,
                        blue: 84 / 255
                    ).opacity(0.18)
                )
            }

        case .literal(let literal):

            let isSeparator =
                separatorDisplayTitle(
                    for: literal
                ) != nil

            return MainComposerChipStyle(
                icon:
                isSeparator
                    ? "line.3.horizontal.decrease"
                    : "character.textbox",
                tint:
                isSeparator
                    ? MinimalPalette.accent
                    : Color.secondary,
                background:
                isSeparator
                    ? MinimalPalette.accent.opacity(0.1)
                    : Color.gray.opacity(0.08),
                border:
                isSeparator
                    ? MinimalPalette.accent.opacity(0.18)
                    : Color.black.opacity(0.06)
            )
        }
    }

    func variableChipIcon(
        for variable: TemplateVariable
    ) -> String {

        switch variable.token {

        case "{{brand}}", "{{model}}":
            return "camera"

        case "{{lens}}":
            return "camera.aperture"

        case "{{iso}}":
            return "dial.medium"

        case "{{aperture}}":
            return "camera.macro"

        case "{{shutter}}":
            return "stopwatch"

        case "{{focal_length}}", "{{focal_len_in_35mm_film}}":
            return "scope"

        case "{{capture_date_display}}", "{{year}}", "{{month}}", "{{day}}",
             "{{hour}}", "{{minute}}", "{{second}}", "{{weekday_name}}":
            return "calendar"

        case "{{width}}", "{{height}}":
            return "aspectratio"

        case "{{anchor_age_text}}":
            return "figure.and.child.holdinghands"

        case "{{anchor_duration_text}}":
            return "hourglass"

        case "{{anchor_elapsed_text}}":
            return "clock.arrow.circlepath"

        case "{{anchor_countdown_text}}":
            return "flag.checkered"

        case "{{anchor_day_index_text}}":
            return "calendar.badge.plus"

        case "{{anchor_week_text}}":
            return "calendar.day.timeline.left"

        case "{{anchor_month_age_text}}":
            return "calendar.badge.person.crop"

        case "{{anchor_milestone_text}}":
            return "rosette"

        case "{{anchor_total_days_text}}", "{{anchor_total_days}}":
            return "calendar.badge.clock"

        case "{{anchor_title}}":
            return "tag"

        case "{{anchor_secondary}}":
            return "calendar.badge.exclamationmark"

        case "{{anchor_smart_text}}", "{{anchor_primary}}", "{{anchor_summary}}":
            return "sparkles"

        case "{{title}}":
            return "textformat"

        case "{{story}}":
            return "text.alignleft"

        case "{{tags}}":
            return "number"

        default:
            switch variable.category {

            case .recognized:
                return "camera.metering.matrix"

            case .intelligent:
                return "sparkles.rectangle.stack"

            case .user:
                return "text.cursor"
            }
        }
    }

    func separatorDisplayTitle(
        for literal: String
    ) -> String? {

        switch literal {

        case " ":
            return "空格"

        case " · ":
            return "·"

        case " | ":
            return "|"

        case ", ":
            return ","

        default:
            return nil
        }
    }

    func update(
        _ items: inout [TemplateItem],
        fallback: TemplateItem,
        value: String
    ) {

        var item =
            items.first ?? fallback

        item.value = value
        item.isEnabled = true
        items = [item]
    }

    func insertToken(
        _ token: String
    ) {

        insertSnippet(token)
    }

    func insertSnippet(
        _ snippet: String
    ) {

        guard let slot = currentEditingSlot else {
            presentAlert(
                title: "请先选择自定义区域",
                message: "先点左上、右上、左下或右下任意一个区域，再插入 EXIF、智能数据或自定义文字。"
            )
            return
        }

        if activeTemplateEditorSlot == slot {

            insertSnippetIntoTemplateEditor(
                snippet,
                slot: slot
            )
            return
        }

        appendComposerItems(
            parseComposerItems(
                from: snippet
            ),
            to: slot
        )

        focusedField = slot
    }

    func insertSnippetIntoTemplateEditor(
        _ snippet: String,
        slot: MainFieldSlot
    ) {

        let currentValue =
            templateValue(for: slot)

        let nsValue =
            currentValue as NSString

        let currentSelection =
            templateEditorSelections[slot]
            ?? NSRange(
                location: nsValue.length,
                length: 0
            )

        let clampedLocation =
            min(
                max(currentSelection.location, 0),
                nsValue.length
            )

        let clampedLength =
            min(
                max(currentSelection.length, 0),
                nsValue.length - clampedLocation
            )

        let safeRange =
            NSRange(
                location: clampedLocation,
                length: clampedLength
            )

        let updatedValue =
            nsValue.replacingCharacters(
                in: safeRange,
                with: snippet
            )

        updateTemplateValue(
            updatedValue,
            for: slot
        )

        templateEditorSelections[slot] =
            NSRange(
                location: clampedLocation
                    + (snippet as NSString).length,
                length: 0
            )

        activateEditingSlot(
            slot,
            preferInlineEditor: true
        )
    }

    func activateEditingSlot(
        _ slot: MainFieldSlot,
        preferInlineEditor: Bool
    ) {

        focusedField = slot
        activeTemplateEditorSlot =
            preferInlineEditor
            ? slot
            : nil

        if arrangingComposerSlot != slot {
            dismissComposerArrangeMode()
        }
    }

    func presentLiteralComposer(
        for slot: MainFieldSlot? = nil
    ) {

        let targetSlot =
            slot
            ?? currentEditingSlot

        guard let targetSlot else {
            presentAlert(
                title: "请先选择自定义区域",
                message: "先点四个自定义区域中的任意一个，再添加文字模块。"
            )
            return
        }

        literalComposerTargetSlot =
            targetSlot
        literalComposerDraft = ""
        showLiteralComposerSheet = true
        dismissComposerArrangeMode()
    }

    func closeLiteralComposer() {

        showLiteralComposerSheet = false
        literalComposerDraft = ""
        literalComposerTargetSlot = nil
    }

    func commitLiteralComposer() {

        let trimmed =
            literalComposerDraft
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !trimmed.isEmpty else {
            return
        }

        guard let slot =
            literalComposerTargetSlot
            ?? currentEditingSlot
        else {
            closeLiteralComposer()
            return
        }

        appendComposerItems(
            [
                TemplateComposerItem(
                    id: UUID().uuidString,
                    segment: .literal(trimmed)
                )
            ],
            to: slot
        )

        activateEditingSlot(
            slot,
            preferInlineEditor: true
        )
        closeLiteralComposer()
    }

    func enterComposerArrangeMode(
        for slot: MainFieldSlot,
        itemID: String
    ) {

        activateEditingSlot(
            slot,
            preferInlineEditor: false
        )
        selectedComposerItemIDs[slot] = itemID
        arrangingComposerSlot = slot

        withAnimation(
            .easeInOut(duration: 0.14)
            .repeatForever(autoreverses: true)
        ) {
            composerWigglePhase = true
        }
    }

    func dismissComposerArrangeMode() {

        arrangingComposerSlot = nil
        composerWigglePhase = false
    }

    func configureInitialState() {

        if selectedAnchorID == nil {
            let persistedAnchorID =
                UUID(uuidString: settings.selectedAnchorIDString)

            if let persistedAnchorID,
               settings.anchors.contains(
                where: { $0.id == persistedAnchorID }
               ) {
                selectedAnchorID = persistedAnchorID
            } else {
                selectedAnchorID =
                    settings.anchors.first?.id
            }
        }

        if focusedField == nil {
            activeTemplateEditorSlot = nil
        }

        if titleText.isEmpty {
            titleText = settings.draftTitleText
        }

        if storyText.isEmpty {
            storyText = settings.draftStoryText
        }

        if selectedAlbumIdentifier
            == PhotoAlbumOption.automaticIdentifier,
           !settings.selectedAlbumIdentifier.isEmpty {
            selectedAlbumIdentifier =
                settings.selectedAlbumIdentifier
        }

        syncComposerItemsFromTemplate(
            resetTransientState: true
        )
    }

    func migrateLegacyConfigurationIntoActiveSlotIfNeeded() {

        let hasNoCustomizedSlots =
            settings.configurationSlots.allSatisfy {
                !$0.isCustomized
            }

        guard hasNoCustomizedSlots else {
            return
        }

        settings.updateConfigurationSlot(
            settings.activeConfigurationSlotID,
            snapshot:
                currentBatchConfigurationSnapshot
        )
    }

    func syncComposerItemsFromTemplate(
        resetTransientState: Bool = false
    ) {

        if resetTransientState {
            dismissComposerArrangeMode()
        }

        for slot in MainFieldSlot.allCases {

            let items =
                reconciledComposerItems(
                    for: slot,
                    from: templateValue(for: slot)
                )

            composerItemsBySlot[slot] = items

            let validIDs =
                Set(items.map(\.id))

            if items.isEmpty {
                selectedComposerItemIDs[slot] = nil
                insertionComposerIndices[slot] = 0
            } else {
                if let selectedID =
                    selectedComposerItemIDs[slot],
                   !validIDs.contains(selectedID) {
                    selectedComposerItemIDs[slot] =
                        items.last?.id
                }

                let currentInsertionIndex =
                    insertionComposerIndices[slot]
                    ?? items.count

                insertionComposerIndices[slot] =
                    min(
                        max(currentInsertionIndex, 0),
                        items.count
                    )
            }

            if let draggedID =
                draggedComposerItemIDs[slot],
               !validIDs.contains(draggedID) {
                draggedComposerItemIDs[slot] = nil
            }

            if let hoveredID =
                hoveredComposerItemIDs[slot],
               !validIDs.contains(hoveredID) {
                hoveredComposerItemIDs[slot] = nil
            }
        }
    }

    func preparePermissionsOnAppear() async {

        await permissionCenter.refreshStatuses()

        if permissionCenter.shouldPresentPrimer {
            permissionCenter.markPrimerPresented()
            showPermissionSetupSheet = true
        }

        if permissionCenter.canAccessPhotoLibrary {
            await reloadAlbums()
        } else {
            availableAlbums = []
        }
    }

    func refreshPermissionsForActiveScene() async {

        let couldAccessBefore =
            permissionCenter.canAccessPhotoLibrary

        await permissionCenter.refreshStatuses()

        if permissionCenter.canAccessPhotoLibrary {
            if !couldAccessBefore
                || availableAlbums.isEmpty {
                await reloadAlbums()
            }
        } else {
            availableAlbums = []
        }
    }

    func requestInitialPermissions() async {

        _ = await permissionCenter
            .requestPhotoLibraryPermission()
        _ = await permissionCenter
            .requestNotificationPermission()

        showPermissionSetupSheet = false

        if permissionCenter.canAccessPhotoLibrary {
            await reloadAlbums()
        }
    }

    func requestPhotoLibraryPermission() async {

        let granted =
            await permissionCenter
            .requestPhotoLibraryPermission()

        if granted {
            await reloadAlbums()
            return
        }

        if permissionCenter.photoLibraryState
            == .denied {
            presentAlert(
                title: "请到系统设置开启相册权限",
                message: "macOS 在你拒绝后不会再次自动弹出相册授权框。请点击权限区里的“打开系统设置”，然后为 PhotoMemo 重新开启相册权限。"
            )
            return
        }

        presentAlert(
            title: "需要相册权限",
            message: "请允许 PhotoMemo 访问系统相册，这样才能读取照片并把处理后的图片存回图库。"
        )
    }

    func requestNotificationPermission() async {

        let granted =
            await permissionCenter
            .requestNotificationPermission()

        guard !granted else {
            return
        }

        presentAlert(
            title: "通知尚未开启",
            message: "你仍然可以继续使用 PhotoMemo，只是后台处理完成时不会自动弹出系统通知。"
        )
    }

    func syncSelectedAnchor(
        with anchors: [Anchor]
    ) {

        guard let selectedAnchorID else {

            self.selectedAnchorID =
                anchors.first?.id
            return
        }

        if !anchors.contains(
            where: {
                $0.id == selectedAnchorID
            }
        ) {

            self.selectedAnchorID =
                anchors.first?.id
        }
    }

    func previewCardMaxWidth(
        for selectedPhoto: SelectedPhoto
    ) -> CGFloat {

        let width =
            CGFloat(
                selectedPhoto.metadata.imageWidth
                ?? Int(
                    selectedPhoto.image
                        .photoMemoSize.width
                )
            )

        let height =
            CGFloat(
                selectedPhoto.metadata.imageHeight
                ?? Int(
                    selectedPhoto.image
                        .photoMemoSize.height
                )
            )

        guard height > 0 else {
            return 900
        }

        return width >= height ? 900 : 560
    }

    var selectedAlbumLocalIdentifier: String? {

        selectedAlbumIdentifier
            == PhotoAlbumOption.automaticIdentifier
            ? nil
            : selectedAlbumIdentifier
    }

    func reloadAlbums() async {

        await permissionCenter.refreshStatuses()

        guard permissionCenter.canAccessPhotoLibrary else {
            availableAlbums = []

            if permissionCenter.photoLibraryState
                == .notDetermined {
                await requestPhotoLibraryPermission()
            } else {
                presentAlert(
                    title: "需要相册权限",
                    message: "请先允许 PhotoMemo 访问系统相册，之后才能读取相册列表和保存处理结果。"
                )
            }
            return
        }

        isLoadingAlbums = true

        defer {
            isLoadingAlbums = false
        }

        do {

            availableAlbums =
                try await photoLibraryExportService
                .fetchAlbumOptions()

            if selectedAlbumIdentifier
                != PhotoAlbumOption.automaticIdentifier,
               !availableAlbums.contains(
                where: {
                    $0.id == selectedAlbumIdentifier
                }
               ) {

                selectedAlbumIdentifier =
                    PhotoAlbumOption
                    .automaticIdentifier
            }

        } catch {

            presentAlert(
                title: "无法读取相册",
                message:
                    (error as? LocalizedError)?
                    .errorDescription
                    ?? error.localizedDescription
            )
        }
    }

    func saveCurrentConfiguration() {

        settings.selectedAnchorIDString =
            selectedAnchorID?.uuidString
            ?? ""
        settings.draftTitleText = titleText
        settings.draftStoryText = storyText
        settings.selectedAlbumIdentifier =
            settings.normalizedAlbumIdentifier(
                selectedAlbumIdentifier
            )

        settings.updateConfigurationSlot(
            settings.activeConfigurationSlotID,
            snapshot:
                currentBatchConfigurationSnapshot
        )

        persistEditorDraftState(
            selectedAnchorID: selectedAnchorID,
            draftTitleText: titleText,
            draftStoryText: storyText,
            selectedAlbumIdentifier:
                selectedAlbumIdentifier
        )

        settings.saveAll()
        syncBatchQueueDefaultConfiguration()

        presentAlert(
            title: "配置已保存",
            message: "当前内容已经保存到\(activeWorkspaceConfigurationSlot.displayTitleWithReference)，之后切换这套配置时会整体恢复模板、锚点、标识、文案和输出规则。"
        )
    }

    func selectWorkspaceConfigurationSlot(
        _ slotID: WorkspaceConfigurationSlotID
    ) {

        settings.activeConfigurationSlotID = slotID
        settings.saveConfigurationSlots()

        let slot =
            settings.configurationSlot(for: slotID)
            ?? WorkspaceConfigurationSlot(
                id: slotID,
                customTitle: nil,
                snapshot: nil,
                updatedAt: nil
            )

        let snapshot =
            slot.snapshot
            ?? defaultWorkspaceConfigurationSnapshot(
                for: slotID
            )

        applyWorkspaceConfigurationSnapshot(
            snapshot
        )
    }

    func restoreActiveWorkspaceConfigurationToDefault() {

        let activeSlotID =
            settings.activeConfigurationSlotID

        settings.updateConfigurationSlot(
            activeSlotID,
            snapshot: nil
        )

        applyWorkspaceConfigurationSnapshot(
            defaultWorkspaceConfigurationSnapshot(
                for: activeSlotID
            )
        )

        presentAlert(
            title: "已恢复默认",
            message: "\(activeWorkspaceConfigurationSlot.displayTitleWithReference) 已恢复到\(activeSlotID.defaultPreset.displayName)默认骨架。"
        )
    }

    func defaultWorkspaceConfigurationSnapshot(
        for slotID: WorkspaceConfigurationSlotID
    ) -> BatchConfigurationSnapshot {

        BatchConfigurationSnapshot(
            template:
                templatePresetEngine.build(
                    preset: slotID.defaultPreset
                )
                .normalizedForEditing,
            badge: nil,
            anchor: nil,
            shouldWritePhotoDescription: false,
            photoDescriptionOverride: "",
            selectedAlbumIdentifier: "",
            titleText: "",
            storyText: ""
        )
    }

    func applyWorkspaceConfigurationSnapshot(
        _ snapshot: BatchConfigurationSnapshot
    ) {

        settings.selectedTemplate =
            snapshot.template.normalizedForEditing
        settings.selectedBadge =
            snapshot.badge ?? Badge.none
        settings.shouldWritePhotoDescription =
            snapshot.shouldWritePhotoDescription
        settings.photoDescriptionOverride =
            snapshot.photoDescriptionOverride

        if let anchor = snapshot.anchor,
           !settings.anchors.contains(
            where: { $0.id == anchor.id }
           ) {
            settings.anchors.append(anchor)
            settings.saveAnchors()
        }

        selectedAnchorID =
            snapshot.anchor?.id
        settings.selectedAnchorIDString =
            snapshot.anchor?.id.uuidString
            ?? ""

        titleText = snapshot.titleText
        storyText = snapshot.storyText
        settings.draftTitleText = snapshot.titleText
        settings.draftStoryText = snapshot.storyText

        let normalizedAlbumIdentifier =
            snapshot.selectedAlbumIdentifier
            .isEmpty
            ? PhotoAlbumOption.automaticIdentifier
            : snapshot.selectedAlbumIdentifier

        selectedAlbumIdentifier =
            normalizedAlbumIdentifier
        settings.selectedAlbumIdentifier =
            snapshot.selectedAlbumIdentifier

        settings.saveAll()
        syncComposerItemsFromTemplate(
            resetTransientState: true
        )
        syncBatchQueueDefaultConfiguration()
    }

    func persistEditorDraftState(
        selectedAnchorID: UUID? = nil,
        draftTitleText: String? = nil,
        draftStoryText: String? = nil,
        selectedAlbumIdentifier: String? = nil
    ) {

        settings.scheduleEditorStateSave(
            selectedAnchorID: selectedAnchorID,
            draftTitleText: draftTitleText,
            draftStoryText: draftStoryText,
            selectedAlbumIdentifier:
                selectedAlbumIdentifier
        )
    }

    func syncBatchQueueDefaultConfiguration() {

        batchQueueStore.updateDefaultConfiguration(
            currentBatchConfigurationSnapshot
        )
        ExternalPhotoIntakeCenter.shared
            .updateDefaultConfiguration(
                currentBatchConfigurationSnapshot
            )
    }

    func saveCurrentCardToAlbum() async {

        guard
            let selectedPhoto,
            let currentCard
        else {
            return
        }

        await permissionCenter.refreshStatuses()

        if !permissionCenter.canAccessPhotoLibrary {
            await requestPhotoLibraryPermission()
            guard permissionCenter.canAccessPhotoLibrary else {
                return
            }
        }

        isSavingToAlbum = true

        defer {
            isSavingToAlbum = false
        }

        var temporaryURL: URL?

        do {

            let url =
                try exportService.exportToTemporaryFile(
                    photo: selectedPhoto,
                    card: currentCard
                )

            temporaryURL = url

            let albumName =
                try await photoLibraryExportService
                .saveImage(
                    at: url,
                    metadata: selectedPhoto.metadata,
                    preferredAlbumIdentifier:
                        selectedAlbumLocalIdentifier
                )

            try? FileManager.default.removeItem(
                at: url
            )

            presentAlert(
                title: "已存入系统相册",
                message:
                    "图片已经写入系统图库“\(albumName)”中，拍摄时间与原图元数据会尽量保持一致。"
            )

            if availableAlbums.isEmpty {
                await reloadAlbums()
            }

        } catch {

            if let temporaryURL {
                try? FileManager.default.removeItem(
                    at: temporaryURL
                )
            }

            presentAlert(
                title: "存入相册失败",
                message:
                    (error as? LocalizedError)?
                    .errorDescription
                    ?? error.localizedDescription
            )
        }
    }

    func validateExportedMetadata() async {

        guard
            let selectedPhoto,
            let currentCard
        else {
            return
        }

        isPreparingMetadataValidation = true

        defer {
            isPreparingMetadataValidation = false
        }

        var temporaryURL: URL?

        do {

            let url =
                try exportService.exportToTemporaryFile(
                    photo: selectedPhoto,
                    card: currentCard
                )

            temporaryURL = url

            let exportedMetadata =
                metadataReader.read(
                    from: url
                )

            metadataValidationReport =
                MetadataValidationReport(
                    validatedTargetName:
                        url.lastPathComponent,
                    sourceLabel: "Source",
                    targetLabel: "Exported",
                    source: selectedPhoto.metadata,
                    exported: exportedMetadata
                )

        } catch {

            presentAlert(
                title: "无法验证导出元数据",
                message:
                    (error as? LocalizedError)?
                    .errorDescription
                    ?? error.localizedDescription
            )
        }

        if let temporaryURL {
            try? FileManager.default.removeItem(
                at: temporaryURL
            )
        }
    }

    func saveAndValidatePhotoLibraryMetadata() async {

        guard
            let selectedPhoto,
            let currentCard
        else {
            return
        }

        await permissionCenter.refreshStatuses()

        if !permissionCenter.canAccessPhotoLibrary {
            await requestPhotoLibraryPermission()
            guard permissionCenter.canAccessPhotoLibrary else {
                return
            }
        }

        isPreparingLibraryMetadataValidation = true

        defer {
            isPreparingLibraryMetadataValidation = false
        }

        var temporaryURL: URL?

        do {

            let url =
                try exportService.exportToTemporaryFile(
                    photo: selectedPhoto,
                    card: currentCard
                )

            temporaryURL = url

            let saveResult =
                try await photoLibraryExportService
                .saveImageResult(
                    at: url,
                    metadata: selectedPhoto.metadata,
                    preferredAlbumIdentifier:
                        selectedAlbumLocalIdentifier
                )

            let savedMetadata =
                try await photoLibraryExportService
                .readMetadata(
                    forSavedAsset:
                        saveResult.assetLocalIdentifier
                )

            metadataValidationReport =
                MetadataValidationReport(
                    validatedTargetName:
                        "\(saveResult.albumTitle) / \(saveResult.assetLocalIdentifier)",
                    sourceLabel: "Source",
                    targetLabel: "Library",
                    source: selectedPhoto.metadata,
                    exported: savedMetadata
                )

            presentAlert(
                title: "已完成图库验证",
                message:
                    "图片已经写入系统图库“\(saveResult.albumTitle)”，并完成了写回后元数据复核。"
            )

            if availableAlbums.isEmpty {
                await reloadAlbums()
            }

        } catch {

            presentAlert(
                title: "无法验证图库元数据",
                message:
                    (error as? LocalizedError)?
                    .errorDescription
                    ?? error.localizedDescription
            )
        }

        if let temporaryURL {
            try? FileManager.default.removeItem(
                at: temporaryURL
            )
        }
    }

    func presentAlert(
        title: String,
        message: String
    ) {

        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}

#Preview {

    MainView()
        .environmentObject(
            BatchQueueStore()
        )
}
