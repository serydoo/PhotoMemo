import Foundation
import SwiftUI
#if os(macOS)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

private enum MainFieldSlot: String, CaseIterable, Hashable {

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

private enum TemplateComposerSegment: Hashable {

    case variable(TemplateVariable)

    case literal(String)
}

private struct TemplateComposerItem: Identifiable, Hashable {

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

private struct InlineTemplateTextEditor: View {

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

private enum MinimalPalette {

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

private struct MinimalChipStyle: ButtonStyle {

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

private struct MinimalInsetCard<Content: View>: View {

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
    private var showLiteralComposerSheet = false

    @State
    private var showTemplateRenameSheet = false

    @State
    private var showPermissionSetupSheet = false

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

    private let templateVariableEngine =
        TemplateVariableEngine()

    private let exportService =
        RecordCardExportService()

    private let photoLibraryExportService =
        PhotoLibraryExportService()

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
        .onAppear {

            configureInitialState()

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
        }
        .onChange(
            of: selectedAnchorID
        ) { _, newValue in

            persistEditorDraftState(
                selectedAnchorID: newValue
            )
        }
        .onChange(
            of: titleText
        ) { _, newValue in

            persistEditorDraftState(
                draftTitleText: newValue
            )
        }
        .onChange(
            of: storyText
        ) { _, newValue in

            persistEditorDraftState(
                draftStoryText: newValue
            )
        }
        .onChange(
            of: selectedAlbumIdentifier
        ) { _, newValue in

            persistEditorDraftState(
                selectedAlbumIdentifier: newValue
            )
        }
        .onChange(
            of: settings.shouldWritePhotoDescription
        ) { _, _ in

            settings.schedulePhotoDescriptionSettingsSave()
        }
        .onChange(
            of: settings.photoDescriptionOverride
        ) { _, _ in

            settings.schedulePhotoDescriptionSettingsSave()
        }
        .toolbar {

            ToolbarItemGroup(
                placement: .primaryAction
            ) {

                Button("保存配置") {
                    saveCurrentConfiguration()
                }
            }
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

            GroupBox("本地权限") {
                permissionSection
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

            GroupBox("图标") {
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

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

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

            if let selectedPhoto {

                metadataSummary(
                    for: selectedPhoto
                )
            }
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }

    var templateSection: some View {

            VStack(
                alignment: .leading,
                spacing: 14
            ) {

            HStack(
                alignment: .center,
                spacing: 10
            ) {

                Picker(
                    "模板",
                    selection: selectedTemplatePreset
                ) {

                    ForEach(
                        TemplatePreset.allCases,
                        id: \.self
                    ) { preset in

                        Text(
                            preset.displayName
                        )
                        .tag(preset)
                    }
                }
                .pickerStyle(.menu)
                .controlSize(.small)
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )

                Button {
                    presentTemplateRenameSheet()
                } label: {
                    Label(
                        "自定义名称",
                        systemImage: "pencil"
                    )
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            MinimalInsetCard {
                LabeledContent("当前定位") {
                    Text(resolvedTemplateDisplayName)
                        .font(.subheadline.weight(.medium))
                }

                Divider()

                LabeledContent("预设骨架") {
                    Text(currentPreset.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider()

                LabeledContent("默认右下") {
                    Text(currentPresetDefaultOutput)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 10) {
                Button("恢复模板默认字段") {

                    settings.selectedTemplate =
                        templatePresetEngine.build(
                            preset: currentPreset
                        )
                    settings.saveTemplate()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Text(currentPreset.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }

    var anchorSection: some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            HStack(spacing: 10) {
                Picker(
                    "选择时间点",
                    selection: $selectedAnchorID
                ) {

                    Text("未选择")
                        .tag(Optional<Anchor.ID>.none)

                    ForEach(settings.anchors) { anchor in

                        Text(anchor.title)
                            .tag(Optional(anchor.id))
                    }
                }
                .pickerStyle(.menu)
                .controlSize(.small)

                Button {

                    showAnchorManager = true

                } label: {

                    Label(
                        "设置时间点",
                        systemImage: "calendar.badge.plus"
                    )
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            MinimalInsetCard {
                LabeledContent("照片时间") {
                    Text(anchorPhotoSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                }

                if let anchor = selectedAnchor {

                    Divider()

                    LabeledContent("基准时间") {
                        Text(anchorDateText(anchor))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let preview = anchorPreviewResult {

                        Divider()

                        VStack(
                            alignment: .leading,
                            spacing: 8
                        ) {

                            Text(preview.summaryText)
                                .font(.subheadline.weight(.medium))

                            ScrollView(
                                .horizontal,
                                showsIndicators: false
                            ) {

                                HStack(spacing: 8) {

                                    ForEach(
                                        anchorQuickFacts(
                                            preview
                                        ),
                                        id: \.label
                                    ) { fact in

                                        compactFactPill(
                                            title: fact.label,
                                            value: fact.value
                                        )
                                    }
                                }
                                .padding(.vertical, 1)
                            }
                        }
                    }

                } else {

                    Divider()

                    Text(
                        "选择一个时间点后，系统会按照片 EXIF 拍摄时间自动计算年岁、纪念时长、已过天数、未来倒计时，以及第几天、周数、月龄等时间结果模块。"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
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

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            MinimalInsetCard {
                Text("内容")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)

                TextField(
                    "标题",
                    text: $titleText
                )
                .textFieldStyle(.roundedBorder)

                TextField(
                    "记忆文案",
                    text: $storyText,
                    axis: .vertical
                )
                .lineLimit(3...5)
                .textFieldStyle(.roundedBorder)
            }

            MinimalInsetCard {
                Toggle(
                    "同步到苹果相册说明",
                    isOn: $settings.shouldWritePhotoDescription
                )

                if settings.shouldWritePhotoDescription {

                    Divider()

                    TextField(
                        "说明内容留空时，默认写入右下区域完整内容",
                        text: $settings.photoDescriptionOverride,
                        axis: .vertical
                    )
                    .lineLimit(2...4)
                    .textFieldStyle(.roundedBorder)
                }

                Divider()

                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {

                    Text("说明预览")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)

                    Text(defaultPhotoDescriptionHint)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }

    var badgeSection: some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            Picker(
                "图标",
                selection: selectedBadgeName
            ) {

                ForEach(
                    BadgeLibrary.defaults,
                    id: \.name
                ) { badge in

                    Text(badge.name)
                        .tag(badge.name)
                }
            }
            .pickerStyle(.menu)
            .controlSize(.small)

            MinimalInsetCard {
                HStack(spacing: 12) {

                    badgePreviewIcon

                    VStack(
                        alignment: .leading,
                        spacing: 4
                    ) {

                        Text(selectedBadgeTitle)
                            .font(.subheadline.weight(.medium))

                        Text(selectedBadgeSummary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)
                }
            }
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }

    var outputSection: some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            HStack(
                alignment: .center,
                spacing: 8
            ) {

                Picker(
                    "系统相册",
                    selection: $selectedAlbumIdentifier
                ) {

                    Text("自动存入 PhotoMemo")
                        .tag(
                            PhotoAlbumOption
                                .automaticIdentifier
                        )

                    ForEach(availableAlbums) { album in

                        Text(album.title)
                            .tag(album.id)
                    }
                }
                .pickerStyle(.menu)
                .controlSize(.small)

                Button {

                    Task {
                        await reloadAlbums()
                    }

                } label: {

                    Image(
                        systemName:
                            isLoadingAlbums
                            ? "arrow.trianglehead.2.clockwise.rotate.90"
                            : "arrow.clockwise"
                    )
                }
                .buttonStyle(.borderless)
                .disabled(isLoadingAlbums)
            }

            MinimalInsetCard {
                LabeledContent("写入位置") {
                    Text(selectedAlbumSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider()

                Text(
                    "处理后的图片会直接写入系统图库；不选现有相册时，会自动创建或复用 PhotoMemo 相册。除分辨率变化外，会尽量保留原图 EXIF、拍摄时间与元数据。"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }

            Button(
                isSavingToAlbum
                    ? "正在存入系统相册..."
                    : "存入系统相册"
            ) {

                Task {
                    await saveCurrentCardToAlbum()
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .disabled(
                selectedPhoto == nil
                || currentCard == nil
                || isSavingToAlbum
            )
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }

    var heroPanel: some View {

        HStack(spacing: 10) {

            statusPill(
                title: "模板",
                value: resolvedTemplateDisplayName
            )

            statusPill(
                title: "时间点",
                value:
                    selectedAnchor?.title
                    ?? "未设置"
            )

            statusPill(
                title: "图库",
                value:
                    permissionCenter.canAccessPhotoLibrary
                    ? "原信息保留"
                    : "待授权"
            )
        }
    }

    var permissionSection: some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            MinimalInsetCard {
                permissionRow(
                    title: "系统相册",
                    icon: "photo.on.rectangle.angled",
                    state:
                        permissionCenter
                        .photoLibraryState,
                    description:
                        "用于读取你选择的照片，并把处理后的新图直接写回系统图库。"
                ) {
                    Task {
                        await requestPhotoLibraryPermission()
                    }
                } openSettingsAction: {
                    permissionCenter
                        .openSystemSettings(
                            for: .photoLibrary
                        )
                }

                Divider()

                permissionRow(
                    title: "系统通知",
                    icon: "bell.badge",
                    state:
                        permissionCenter
                        .notificationState,
                    description:
                        "用于在后台处理开始、完成或失败时给你明确反馈。"
                ) {
                    Task {
                        await requestNotificationPermission()
                    }
                } openSettingsAction: {
                    permissionCenter
                        .openSystemSettings(
                            for: .notifications
                        )
                }
            }

            Text(
                "PhotoMemo 完全本地运行，不依赖联网；这里只会请求相册与通知两项必要能力。"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }

    var memoryProgressPanel: some View {

        let snapshot =
            batchQueueStore.usageSnapshot

        return MinimalInsetCard {
            HStack(
                alignment: .top,
                spacing: 14
            ) {

                VStack(
                    alignment: .leading,
                    spacing: 6
                ) {

                    Text("记忆进度")
                        .font(.subheadline.weight(.medium))

                    Text(memoryProgressHeadline(snapshot))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                VStack(
                    alignment: .trailing,
                    spacing: 6
                ) {

                    progressStatLine(
                        title: "累计盖章",
                        value: "\(snapshot.completedPhotoCount) 张"
                    )

                    progressStatLine(
                        title: "完成批次",
                        value: "\(snapshot.completedBatchCount) 次"
                    )

                    progressStatLine(
                        title: "后台状态",
                        value:
                            snapshot.activePhotoCount > 0
                            ? "处理中 \(snapshot.activePhotoCount) 张"
                            : "当前空闲"
                    )
                }
            }

            if snapshot.templateChampion != nil
                || snapshot.anchorChampion != nil
                || snapshot.lastCompletedAt != nil
                || snapshot.failedPhotoCount > 0 {

                Divider()

                VStack(
                    alignment: .leading,
                    spacing: 8
                ) {

                    if let templateChampion =
                        snapshot.templateChampion {

                        Text("最常用模板“\(templateChampion.title)”已经陪你处理了 \(templateChampion.count) 张照片。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if let anchorChampion =
                        snapshot.anchorChampion {

                        Text("最常出现的时间点是“\(anchorChampion.title)”，目前已经用了 \(anchorChampion.count) 次。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if let lastCompletedAt =
                        snapshot.lastCompletedAt {

                        Text("最近一次完成：\(lastCompletedAt.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if snapshot.failedPhotoCount > 0 {

                        Text("还有 \(snapshot.failedPhotoCount) 张图片处理失败，后续可以做重试入口。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    var permissionSetupSheet: some View {

        VStack(
            alignment: .leading,
            spacing: 18
        ) {

            Text("启用本地权限")
                .font(.system(
                    size: 26,
                    weight: .semibold
                ))

            Text("PhotoMemo 完全本地运行，不需要联网。为了读取照片 EXIF、把处理后的图片存回系统图库，以及在后台任务完成时提醒你，需要先允许相册和通知权限。")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            MinimalInsetCard {
                permissionPrimerLine(
                    icon: "photo.on.rectangle.angled",
                    title: "系统相册",
                    description:
                        "用于读取你挑选的照片，并把处理结果写回图库或指定相册。"
                )

                Divider()

                permissionPrimerLine(
                    icon: "bell.badge",
                    title: "系统通知",
                    description:
                        "用于在后台处理开始、完成或失败时提醒你。"
                )
            }

            HStack(spacing: 10) {
                Button("稍后再说") {
                    showPermissionSetupSheet = false
                }
                .buttonStyle(.bordered)

                Button("现在授权") {
                    Task {
                        await requestInitialPermissions()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.top, 4)
        }
        .padding(24)
        .frame(
            minWidth: 460,
            idealWidth: 520
        )
        .background(
            MinimalPalette.background
        )
    }

    @ViewBuilder
    func permissionRow(
        title: String,
        icon: String,
        state: PermissionState,
        description: String,
        requestAction: @escaping () -> Void,
        openSettingsAction: @escaping () -> Void
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            HStack(
                alignment: .top,
                spacing: 12
            ) {

                Image(systemName: icon)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(
                        MinimalPalette.accent
                    )
                    .frame(width: 24)

                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {

                    HStack(spacing: 8) {
                        Text(title)
                            .font(.subheadline.weight(.medium))

                        Text(state.statusText)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(
                                state.isGranted
                                ? Color.green
                                : Color.secondary
                            )
                    }

                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {

                if state.isGranted {

                    Label(
                        "已就绪",
                        systemImage: "checkmark.circle.fill"
                    )
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.green)

                } else {

                    Button(
                        state == .notDetermined
                            ? "允许访问"
                            : "重新授权"
                    ) {
                        requestAction()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }

                if state == .denied {

                    Button("打开系统设置") {
                        openSettingsAction()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
    }

    @ViewBuilder
    func permissionPrimerLine(
        icon: String,
        title: String,
        description: String
    ) -> some View {

        HStack(
            alignment: .top,
            spacing: 12
        ) {

            Image(systemName: icon)
                .font(.title3.weight(.semibold))
                .foregroundStyle(
                    MinimalPalette.accent
                )
                .frame(width: 24)

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text(title)
                    .font(.subheadline.weight(.medium))

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    var composerEntryPanel: some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            HStack(
                alignment: .center,
                spacing: 10
            ) {

                Label(
                    "当前自定义区域",
                    systemImage: "rectangle.3.group"
                )
                .font(.subheadline.weight(.medium))

                Text(
                    currentEditingSlot.title
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)

                Spacer()

                Button("添加文字") {
                    presentLiteralComposer()
                }
                .buttonStyle(.bordered)

                Button("退出整理") {
                    dismissComposerArrangeMode()
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
                .opacity(
                    arrangingComposerSlot == nil
                    ? 0
                    : 1
                )
                .disabled(
                    arrangingComposerSlot == nil
                )
            }

            ScrollView(
                .horizontal,
                showsIndicators: false
            ) {

                HStack(spacing: 8) {

                    ForEach(
                        MainFieldSlot.allCases,
                        id: \.self
                    ) { slot in

                        Button {
                            activateEditingSlot(
                                slot,
                                preferInlineEditor: true
                            )
                        } label: {
                            Text(slot.title)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(
                                    focusedField == slot
                                        ? .white
                                        : .primary
                                )
                                .padding(.horizontal, 14)
                                .padding(.vertical, 9)
                                .background(
                                    Capsule()
                                        .fill(
                                            focusedField == slot
                                                ? MinimalPalette.accent
                                                : Color.gray.opacity(0.1)
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 1)
            }

            Text(
                "下方左上、右上、左下、右下 4 个自定义区域都可以独立编辑。你可以直接点区域本身，也可以先点这里的四区切换条；选中后再点上方 EXIF、智能数据或用户数据，就会插入到当前区域。长按已选中的模块可进入整理状态，并显示删除按钮与拖动排序。"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            dismissComposerArrangeMode()
        }
    }

    @ViewBuilder
    var literalComposerSheet: some View {

        NavigationStack {

            VStack(
                alignment: .leading,
                spacing: 16
            ) {

                Text(
                    "为\((literalComposerTargetSlot ?? currentEditingSlot).title)添加文字"
                )
                .font(.headline)

                TextField(
                    "例如：儿子到今天 / 高考冲刺 / 旅行第",
                    text: $literalComposerDraft,
                    axis: .vertical
                )
                .lineLimit(3...5)
                .textFieldStyle(.roundedBorder)

                Text(
                    "保存后会作为一个独立模块加入当前区域，可继续和 EXIF、智能数据自由组合。"
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                Spacer(minLength: 0)
            }
            .padding(24)
            .navigationTitle("添加文字")
            .toolbar {

                ToolbarItem(
                    placement: .cancellationAction
                ) {

                    Button("取消") {
                        closeLiteralComposer()
                    }
                }

                ToolbarItem(
                    placement: .confirmationAction
                ) {

                    Button("加入") {
                        commitLiteralComposer()
                    }
                    .disabled(
                        literalComposerDraft
                        .trimmingCharacters(
                            in: .whitespacesAndNewlines
                        )
                        .isEmpty
                    )
                }
            }
        }
        .frame(
            minWidth: 360,
            minHeight: 220
        )
    }

    @ViewBuilder
    func variableLibraryPanel(
        title: String,
        variables: [TemplateVariable]
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            Text(title)
                .font(.headline)

            if title == "智能数据" {

                Text(
                    "过去时间点常用：{{anchor_age_text}} 表示年岁，{{anchor_duration_text}} 表示纪念时长，{{anchor_elapsed_text}} 表示已过天数，{{anchor_day_index_text}} 表示第几天；未来目标常用：{{anchor_countdown_text}} 表示倒计时；扩展结果可用 {{anchor_week_text}}、{{anchor_month_age_text}}、{{anchor_milestone_text}}，想让系统自动判断时可用 {{anchor_smart_text}}。"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            ScrollView(
                .horizontal,
                showsIndicators: false
            ) {

                HStack(spacing: 10) {

                    ForEach(variables) { variable in

                        Button(variable.title) {
                            dismissComposerArrangeMode()
                            insertToken(
                                variable.token
                            )
                        }
                        .buttonStyle(
                            MinimalChipStyle()
                        )
                    }
                }
                .padding(.vertical, 1)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            dismissComposerArrangeMode()
        }
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

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            HStack {

                Text(slot.title)
                    .font(.headline)

                Spacer()

                if focusedField == slot {

                    Text(
                        arrangingComposerSlot == slot
                        ? "整理中"
                        : "当前区域"
                    )
                        .font(.caption.weight(.medium))
                        .foregroundStyle(
                            MinimalPalette.accent
                        )
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(
                                    MinimalPalette
                                    .accent.opacity(0.12)
                                )
                        )
                }
            }

            VStack(
                alignment: .leading,
                spacing: 12
            ) {

                ScrollViewReader { proxy in

                    VStack(
                        alignment: .leading,
                        spacing: 10
                    ) {

                        Group {

                            if items.isEmpty {

                                EmptyView()
                            } else {

                                ScrollView(
                                    .horizontal,
                                    showsIndicators: false
                                ) {

                                    HStack(spacing: 10) {

                                        ForEach(
                                            Array(
                                                items.enumerated()
                                            ),
                                            id: \.element.id
                                        ) { index, item in

                                            if arrangingComposerSlot != slot,
                                               shouldShowInsertionHandle(
                                                slot: slot,
                                                index: index,
                                                itemID: item.id,
                                                items: items
                                               ) {

                                                composerInsertionHandle(
                                                    for: slot,
                                                    index: index,
                                                    proxy: proxy
                                                )
                                            }

                                            composerChip(
                                                item,
                                                slot: slot,
                                                isSelected:
                                                    selectedItemID
                                                    == item.id,
                                                isHovered:
                                                    hoveredItemID
                                                    == item.id,
                                                isArranging:
                                                    arrangingComposerSlot
                                                    == slot
                                            )
                                            .id(item.id)
                                            .onTapGesture {
                                                if arrangingComposerSlot != slot {
                                                    dismissComposerArrangeMode()
                                                }
                                                focusComposerItem(
                                                    item.id,
                                                    slot: slot,
                                                    proxy: proxy
                                                )
                                            }
                                            .onLongPressGesture(
                                                minimumDuration: 0.4
                                            ) {
                                                enterComposerArrangeMode(
                                                    for: slot,
                                                    itemID: item.id
                                                )
                                            }
                                            .onHover { isHovered in
                                                if isHovered {
                                                    hoveredComposerItemIDs[slot] =
                                                        item.id
                                                } else if hoveredComposerItemIDs[slot] == item.id {
                                                    hoveredComposerItemIDs[slot] =
                                                        nil
                                                }
                                            }
                                            .modifier(
                                                ComposerDragModifier(
                                                    isEnabled:
                                                        arrangingComposerSlot
                                                        == slot,
                                                    item: item
                                                )
                                            )
                                            .dropDestination(
                                                for: String.self
                                            ) { droppedIDs, _ in

                                                guard
                                                    let droppedID =
                                                        droppedIDs.first
                                                else {
                                                    return false
                                                }

                                                reorderComposerItems(
                                                    in: slot,
                                                    from: droppedID,
                                                    to: item.id
                                                )

                                                if let selectedID =
                                                    selectedComposerItemIDs[slot] {

                                                    withAnimation(.easeInOut(duration: 0.2)) {
                                                        proxy.scrollTo(
                                                            selectedID,
                                                            anchor: .center
                                                        )
                                                    }
                                                }

                                                return true
                                            } isTargeted: { isTargeted in

                                                if isTargeted,
                                                   arrangingComposerSlot == slot {
                                                    draggedComposerItemIDs[slot] =
                                                        item.id
                                                } else if draggedComposerItemIDs[slot] == item.id {
                                                    draggedComposerItemIDs[slot] =
                                                        nil
                                                }
                                            }

                                            if arrangingComposerSlot != slot,
                                               shouldShowInsertionHandle(
                                                slot: slot,
                                                index: index + 1,
                                                itemID: item.id,
                                                items: items
                                               ) {

                                                composerInsertionHandle(
                                                    for: slot,
                                                    index: index + 1,
                                                    proxy: proxy
                                                )
                                            }
                                        }
                                    }
                                    .background(
                                        GeometryReader { geometry in

                                            Color.clear
                                                .onAppear {
                                                    composerContentWidths[slot] =
                                                        geometry.size.width
                                                }
                                                .onChange(
                                                    of: geometry.size.width
                                                ) { _, newWidth in
                                                    composerContentWidths[slot] =
                                                        newWidth
                                                }
                                        }
                                    )
                                    .padding(.vertical, 1)
                                }
                                .background(
                                    GeometryReader { geometry in

                                        Color.clear
                                            .onAppear {
                                                composerViewportWidths[slot] =
                                                    geometry.size.width
                                            }
                                            .onChange(
                                                of: geometry.size.width
                                            ) { _, newWidth in
                                                composerViewportWidths[slot] =
                                                    newWidth
                                            }
                                    }
                                )
                                .frame(height: 44)
                                .onAppear {
                                    syncSelectedComposerItem(
                                        for: slot,
                                        items: items,
                                        proxy: proxy
                                    )
                                }
                                .onChange(
                                    of: items.map(\.id)
                                ) { _, _ in
                                    syncSelectedComposerItem(
                                        for: slot,
                                        items: items,
                                        proxy: proxy
                                    )
                                }
                                .onChange(
                                    of: selectedComposerItemIDs[slot]
                                ) { _, newID in
                                    guard let newID else {
                                        return
                                    }

                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        proxy.scrollTo(
                                            newID,
                                            anchor: .center
                                        )
                                    }
                                }
                            }
                        }
                        .frame(
                            maxWidth: .infinity,
                            alignment: .leading
                        )

                        if shouldShowComposerScrubber(
                            for: slot
                        ),
                           !items.isEmpty {

                            composerScrubber(
                                for: slot,
                                items: items,
                                proxy: proxy
                            )
                        }

                        inlineTemplateEditor(
                            for: slot
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(
                        cornerRadius: 18,
                        style: .continuous
                    )
                    .fill(
                        Color.gray.opacity(0.08)
                    )
                )
                .contentShape(
                    RoundedRectangle(
                        cornerRadius: 18,
                        style: .continuous
                    )
                )
                .onTapGesture {
                    activateEditingSlot(
                        slot,
                        preferInlineEditor: true
                    )
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            activateEditingSlot(
                slot,
                preferInlineEditor: true
            )
        }
    }

    @ViewBuilder
    func composerChip(
        _ item: TemplateComposerItem,
        slot: MainFieldSlot,
        isSelected: Bool,
        isHovered: Bool,
        isArranging: Bool
    ) -> some View {

        let style =
            composerChipStyle(
                for: item
            )

        let isPlainLiteral =
            plainLiteralText(
                for: item
            ) != nil

        HStack(spacing: 8) {

            if !isPlainLiteral {

                Image(
                    systemName: style.icon
                )
                .font(.caption.weight(.semibold))
                .foregroundStyle(
                    style.tint
                )
            }

            Text(
                composerChipTitle(
                    for: item
                )
            )
            .font(
                isPlainLiteral
                ? .subheadline
                : .subheadline.weight(.medium)
            )
            .foregroundStyle(
                isPlainLiteral
                ? Color.primary.opacity(0.88)
                : .primary
            )
            .lineLimit(1)

            if isArranging {

                Image(
                    systemName: "line.3.horizontal"
                )
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, isPlainLiteral ? 2 : 12)
        .padding(.vertical, 9)
        .background(
            Group {

                if isPlainLiteral {
                    Color.clear
                } else {
                    Capsule()
                        .fill(
                            style.background
                        )
                }
            }
        )
        .overlay(
            Group {

                if isPlainLiteral {
                    Rectangle()
                        .fill(
                            isSelected
                                ? MinimalPalette.accent.opacity(0.16)
                                : Color.clear
                        )
                        .frame(height: 2)
                        .offset(y: 15)
                } else {
                    Capsule()
                        .stroke(
                            isSelected
                                ? MinimalPalette.accent
                                : style.border,
                            lineWidth:
                                isSelected ? 1.5 : 1
                        )
                }
            }
        )
        .shadow(
            color:
                isPlainLiteral
                ? .clear
                : (isSelected
                ? MinimalPalette.accent.opacity(0.22)
                : .black.opacity(
                    isHovered ? 0.06 : 0
                )),
            radius: isSelected ? 10 : 6,
            y: isSelected ? 4 : 2
        )
        .scaleEffect(
            isPlainLiteral
            ? 1
            : (isSelected ? 1.015 : (isHovered ? 1.01 : 1))
        )
        .rotationEffect(
            isArranging
            ? .degrees(
                composerWigglePhase ? 1.2 : -1.2
            )
            : .zero
        )
        .offset(
            y:
                isArranging
                ? (composerWigglePhase ? -0.8 : 0.8)
                : 0
        )
        .overlay(
            alignment: .topTrailing
        ) {

            if isArranging {

                Button {
                    removeComposerItem(
                        item,
                        from: slot
                    )
                } label: {

                    Image(
                        systemName: "minus.circle.fill"
                    )
                    .font(.caption)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(
                        .white,
                        Color.red.opacity(0.9)
                    )
                }
                .buttonStyle(.plain)
                .offset(x: 5, y: -5)
            }
        }
        .animation(
            .spring(
                response: 0.22,
                dampingFraction: 0.9
            ),
            value: isSelected
        )
        .animation(
            .easeInOut(duration: 0.16),
            value: isHovered
        )
        .animation(
            .easeInOut(duration: 0.14),
            value: composerWigglePhase
        )
    }

    @ViewBuilder
    func composerInsertionHandle(
        for slot: MainFieldSlot,
        index: Int,
        proxy: ScrollViewProxy
    ) -> some View {

        let isSelected =
            insertionComposerIndices[slot] == index

        Button {
            selectInsertionPoint(
                index,
                in: slot,
                proxy: proxy
            )
        } label: {

            ZStack {

                Capsule()
                    .fill(
                        Color.black.opacity(
                            isSelected ? 0.08 : 0.04
                        )
                    )
                    .frame(
                        width: isSelected ? 18 : 12,
                        height: isSelected ? 34 : 24
                    )

                RoundedRectangle(
                    cornerRadius: 999,
                    style: .continuous
                )
                .fill(
                    isSelected
                        ? MinimalPalette.accent
                        : Color.black.opacity(0.16)
                )
                .frame(
                    width: isSelected ? 3 : 2,
                    height: isSelected ? 24 : 16
                )

                if isSelected {

                    Image(
                        systemName: "plus.circle.fill"
                    )
                    .font(.caption2)
                    .foregroundStyle(
                        MinimalPalette.accent
                    )
                    .offset(y: 18)
                }
            }
            .frame(width: 20, height: 42)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("插入到这里")
    }

    @ViewBuilder
    func inlineTemplateEditor(
        for slot: MainFieldSlot
    ) -> some View {

        ZStack(
            alignment: .topLeading
        ) {

            RoundedRectangle(
                cornerRadius: 14,
                style: .continuous
            )
            .fill(Color.white.opacity(0.84))
            .overlay(
                RoundedRectangle(
                    cornerRadius: 14,
                    style: .continuous
                )
                .stroke(
                    focusedField == slot
                        ? MinimalPalette
                        .accent.opacity(0.28)
                        : Color.black.opacity(0.04)
                )
            )

            if templateValue(
                for: slot
            ).isEmpty {

                Text(slot.placeholder)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 11)
                    .allowsHitTesting(false)
            }

            InlineTemplateTextEditor(
                text: templateValueBinding(
                    for: slot
                ),
                selection: templateEditorSelectionBinding(
                    for: slot
                )
            ) {

                activateEditingSlot(
                    slot,
                    preferInlineEditor: true
                )
            }
            .padding(.horizontal, 12)
            .frame(
                minHeight: 48,
                maxHeight: 72,
                alignment: .topLeading
            )
        }
        .contentShape(
            RoundedRectangle(
                cornerRadius: 14,
                style: .continuous
            )
        )
        .onTapGesture {
            activateEditingSlot(
                slot,
                preferInlineEditor: true
            )
        }
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

        if let selectedPhoto,
           let card = currentCard {

            previewDetailContent(
                selectedPhoto: selectedPhoto,
                card: card
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

    @ViewBuilder
    func previewDetailContent(
        selectedPhoto: SelectedPhoto,
        card: RecordCard
    ) -> some View {

        let previewWidth =
            previewCardMaxWidth(
                for: selectedPhoto
            )

        VStack(
            alignment: .center,
            spacing: 22
        ) {

            VStack(
                alignment: .leading,
                spacing: 22
            ) {

                previewHeader

                previewCanvas(
                    selectedPhoto: selectedPhoto,
                    card: card,
                    previewWidth: previewWidth
                )

                previewSummary(
                    for: card
                )
            }
            .frame(
                maxWidth: previewWidth,
                alignment: .leading
            )
        }
        .frame(maxWidth: .infinity)
    }

    var previewHeader: some View {

        HStack {

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text("实时预览")
                    .font(.title3.weight(.semibold))

                Text("按当前模板、时间点与 EXIF 数据即时生成")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    @ViewBuilder
    func previewCanvas(
        selectedPhoto: SelectedPhoto,
        card: RecordCard,
        previewWidth: CGFloat
    ) -> some View {

        RecordCardRenderer(
            image: selectedPhoto.image
                .swiftUIImage,
            card: card
        )
        .frame(
            maxWidth: previewWidth
        )
        .padding(18)
        .background(
            RoundedRectangle(
                cornerRadius: 30,
                style: .continuous
            )
            .fill(
                MinimalPalette.surface
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 30,
                style: .continuous
            )
            .stroke(
                MinimalPalette.border
            )
        )
        .shadow(
            color: .black.opacity(0.05),
            radius: 24,
            y: 12
        )
    }

    @ViewBuilder
    func statusPill(
        title: String,
        value: String
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 3
        ) {

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
            .fill(
                MinimalPalette.surface
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
            .stroke(
                MinimalPalette.border
            )
        )
    }

    @ViewBuilder
    func compactFactPill(
        title: String,
        value: String
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 2
        ) {

            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.caption.weight(.medium))
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(
                    Color.white.opacity(0.92)
                )
        )
        .overlay(
            Capsule()
                .stroke(
                    MinimalPalette.border
                )
        )
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

                Image(systemName: "sparkles")
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

        buildCurrentCard(
            exportDescriptionOverride:
                settings.shouldWritePhotoDescription
                ? resolvedPhotoDescription
                : ""
        )
    }

    func buildCurrentCard(
        exportDescriptionOverride: String?
    ) -> RecordCard? {

        guard let selectedPhoto else {
            return nil
        }

        return RecordCard(
            template: activeTemplate,
            metadata: selectedPhoto.metadata,
            context: MetadataContext.build(
                from: selectedPhoto.metadata
            ),
            anchor: selectedAnchor,
            anchorResult: selectedAnchor.map {
                anchorEngine.build(
                    from: $0,
                    photoDate:
                        selectedPhoto.metadata.captureDate
                        ?? Date()
                )
            },
            badge: activeBadge,
            title: resolvedTitle,
            story: resolvedStory,
            exportDescriptionOverride:
                exportDescriptionOverride
        )
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
        }
    }

    var activeBadge: Badge? {

        guard
            let selectedBadge = settings.selectedBadge,
            selectedBadge.type != .none
        else {
            return nil
        }

        return selectedBadge
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
            return "不显示图标"
        }

        return badge.name
    }

    var selectedBadgeSummary: String {

        guard let badge = settings.selectedBadge,
              badge.type != .none else {
            return "当前模板会保留右侧图标区域留白，适合更极简的版式。"
        }

        if badge.isSystemDefault {
            return "使用系统符号图标，适合和当前极简白色界面保持一致。"
        }

        return "使用自定义图标资源。"
    }

    var resolvedPhotoDescription: String {

        let override =
            settings.photoDescriptionOverride
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        if !override.isEmpty {
            return override
        }

        return defaultPhotoDescription
    }

    var defaultPhotoDescription: String {

        guard
            let card = buildCurrentCard(
                exportDescriptionOverride: nil
            )
        else {
            return ""
        }

        let context =
            CardVariableProvider.build(
                from: card
            )

        return templateVariableEngine
            .render(
                templateValue(
                    for: .rightBottom
                ),
                context: context
            )
            .trimmingCharacters(
                in: .whitespacesAndNewlines
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

    var resolvedTitle: String {

        let trimmed =
            titleText.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        if !trimmed.isEmpty {
            return trimmed
        }

        return selectedAnchor?.title ?? ""
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

    var resolvedStory: String {

        let trimmed =
            storyText.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        if !trimmed.isEmpty {
            return trimmed
        }

        return ""
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

    func memoryProgressHeadline(
        _ snapshot: BatchUsageSnapshot
    ) -> String {

        if snapshot.completedPhotoCount == 0 {
            return "等你第一次处理完成后，这里会慢慢积累属于 PhotoMemo 的小记录。"
        }

        return "PhotoMemo 已经帮你把 \(snapshot.completedPhotoCount) 张照片整理成带记忆注脚的样子。"
    }

    @ViewBuilder
    func progressStatLine(
        title: String,
        value: String
    ) -> some View {

        HStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.caption.weight(.medium))
                .multilineTextAlignment(.trailing)
        }
    }

    @ViewBuilder
    var templateRenameSheet: some View {

        NavigationStack {

            VStack(
                alignment: .leading,
                spacing: 16
            ) {

                Text("为当前模板设置一个更贴近你使用场景的名字。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                TextField(
                    "例如：途途成长版",
                    text: $templateNameDraft
                )
                .textFieldStyle(.roundedBorder)

                MinimalInsetCard {
                    LabeledContent("当前预设") {
                        Text(currentPreset.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Divider()

                    LabeledContent("当前显示") {
                        Text(resolvedTemplateDisplayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(20)
            .navigationTitle("模板名称")
            .toolbar {
                ToolbarItem(
                    placement: .cancellationAction
                ) {
                    Button("取消") {
                        showTemplateRenameSheet = false
                    }
                }

                ToolbarItem(
                    placement: .primaryAction
                ) {
                    Button("保存") {
                        applyTemplateRename()
                    }
                }
            }
            .frame(
                minWidth: 360,
                minHeight: 220
            )
        }
    }

    func presentTemplateRenameSheet() {

        templateNameDraft =
            resolvedTemplateDisplayName
        showTemplateRenameSheet = true
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
        settings.scheduleTemplateSave()
        showTemplateRenameSheet = false
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

    var currentEditingSlot: MainFieldSlot {

        activeTemplateEditorSlot
        ?? focusedField
        ?? .rightBottom
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
        for slot: MainFieldSlot
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

        parseComposerItems(
            from: templateValue(for: slot)
        )
    }

    func parseComposerItems(
        from value: String
    ) -> [TemplateComposerItem] {

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
                TemplateComposerItem(
                    id: "literal-0",
                    segment: .literal(value)
                )
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

        var items: [TemplateComposerItem] = []
        var cursor = value.startIndex
        var runningIndex = 0

        func makeItem(
            segment: TemplateComposerSegment
        ) -> TemplateComposerItem {

            defer {
                runningIndex += 1
            }

            return TemplateComposerItem(
                id: "item-\(runningIndex)",
                segment: segment
            )
        }

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
                        makeItem(
                            segment: .literal(literal)
                        )
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
                    makeItem(
                        segment: .variable(variable)
                    )
                )

            } else {

                items.append(
                    makeItem(
                        segment: .literal(token)
                    )
                )
            }

            cursor = range.upperBound
        }

        if cursor < value.endIndex {

            let trailing =
                String(value[cursor...])

            if !trailing.isEmpty {
                items.append(
                    makeItem(
                        segment: .literal(trailing)
                    )
                )
            }
        }

        return items
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
            for: slot
        )

        if !items.isEmpty {
            selectedComposerItemIDs[slot] =
                "item-\(insertionIndex + items.count - 1)"
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
            for: slot
        )

        selectedComposerItemIDs[slot] =
            items.isEmpty
            ? nil
            : "item-\(nextIndex)"
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
            ? destinationIndex
            : destinationIndex

        items.insert(
            movedItem,
            at: adjustedDestination
        )

        updateTemplateValue(
            serializeComposerItems(items),
            for: slot
        )

        selectedComposerItemIDs[slot] =
            "item-\(adjustedDestination)"
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
    ) -> (
        icon: String,
        tint: Color,
        background: Color,
        border: Color
    ) {

        switch item.segment {

        case .variable(let variable):

            let resolvedIcon =
                variableChipIcon(
                    for: variable
                )

            switch variable.category {

            case .recognized:
                return (
                    resolvedIcon,
                    Color(
                        red: 61 / 255,
                        green: 92 / 255,
                        blue: 168 / 255
                    ),
                    Color(
                        red: 61 / 255,
                        green: 92 / 255,
                        blue: 168 / 255
                    ).opacity(0.12),
                    Color(
                        red: 61 / 255,
                        green: 92 / 255,
                        blue: 168 / 255
                    ).opacity(0.18)
                )

            case .intelligent:
                return (
                    resolvedIcon,
                    Color(
                        red: 188 / 255,
                        green: 108 / 255,
                        blue: 37 / 255
                    ),
                    Color(
                        red: 188 / 255,
                        green: 108 / 255,
                        blue: 37 / 255
                    ).opacity(0.12),
                    Color(
                        red: 188 / 255,
                        green: 108 / 255,
                        blue: 37 / 255
                    ).opacity(0.18)
                )

            case .user:
                return (
                    resolvedIcon,
                    Color(
                        red: 80 / 255,
                        green: 102 / 255,
                        blue: 84 / 255
                    ),
                    Color(
                        red: 80 / 255,
                        green: 102 / 255,
                        blue: 84 / 255
                    ).opacity(0.12),
                    Color(
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

            return (
                isSeparator
                    ? "line.3.horizontal.decrease"
                    : "character.textbox",
                isSeparator
                    ? MinimalPalette.accent
                    : Color.secondary,
                isSeparator
                    ? MinimalPalette.accent.opacity(0.1)
                    : Color.gray.opacity(0.08),
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

        let slot = currentEditingSlot

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

        literalComposerTargetSlot =
            slot
            ?? currentEditingSlot
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

        let slot =
            literalComposerTargetSlot
            ?? currentEditingSlot

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
            focusedField = .rightBottom
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

    @ViewBuilder
    func metadataSummary(
        for selectedPhoto: SelectedPhoto
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 4
        ) {

            Text(
                selectedPhoto.metadata.deviceModel
                .isEmpty
                ? "未识别设备"
                : selectedPhoto.metadata.deviceModel
            )
            .font(.headline)

            if let captureDate =
                selectedPhoto.metadata.captureDate {

                Text(
                    captureDate.formatted(
                        date: .abbreviated,
                        time: .shortened
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

        }
    }

    @ViewBuilder
    func previewSummary(
        for card: RecordCard
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            Text("Live Context")
                .font(.headline)

            Text(
                "Template: \(card.template.name)"
            )
            .font(.caption)
            .foregroundStyle(.secondary)

            if let anchorResult =
                card.anchorResult {

                Text(anchorResult.summaryText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
            .fill(
                MinimalPalette.surface
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
            .stroke(
                MinimalPalette.border
            )
        )
        .frame(
            maxWidth: 900,
            alignment: .leading
        )
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

        persistEditorDraftState(
            selectedAnchorID: selectedAnchorID,
            draftTitleText: titleText,
            draftStoryText: storyText,
            selectedAlbumIdentifier:
                selectedAlbumIdentifier
        )

        settings.saveAll()

        presentAlert(
            title: "配置已保存",
            message: "当前模板、徽标、时间锚点、文案草稿和相册去向已经保存到本地。"
        )
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
