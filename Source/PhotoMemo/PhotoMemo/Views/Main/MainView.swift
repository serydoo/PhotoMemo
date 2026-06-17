import SwiftUI
import AppKit

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
            return "例如：途途宝宝到今天{{anchor_age_text}} / 距离毕业还有{{anchor_countdown_text}}"
        }
    }
}

private struct SmartSentencePreset: Identifiable, Hashable {

    let title: String

    let value: String

    var id: String {
        title + value
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

struct MainView: View {

    @StateObject
    private var settings = SettingsService()

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
    private var customTextDrafts:
        [MainFieldSlot: String] = [:]

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
    private var editingComposerItemIDs:
        [MainFieldSlot: String] = [:]

    @State
    private var editingComposerDrafts:
        [MainFieldSlot: String] = [:]

    @State
    private var insertionComposerIndices:
        [MainFieldSlot: Int] = [:]

    @FocusState
    private var focusedField: MainFieldSlot?

    @FocusState
    private var focusedComposerEditorID: String?

    private let templatePresetEngine =
        TemplatePresetEngine()

    private let anchorEngine =
        AnchorEngine()

    private let exportService =
        RecordCardExportService()

    private let photoLibraryExportService =
        PhotoLibraryExportService()

    var body: some View {

        ZStack {

            MinimalPalette.background
                .ignoresSafeArea()

            NavigationSplitView {

                sidebar

            } detail: {

                detail
            }
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
        .onAppear {

            configureInitialState()
        }
        .onChange(
            of: settings.anchors
        ) { _, anchors in

            syncSelectedAnchor(
                with: anchors
            )
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
}

// MARK: - Sidebar
private extension MainView {

    var sidebar: some View {

        ScrollView {

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

                GroupBox("照片") {

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

                GroupBox("模板") {

                    VStack(
                        alignment: .leading,
                        spacing: 12
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
                        .frame(
                            maxWidth: .infinity,
                            alignment: .leading
                        )

                        Text(currentPreset.summary)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Button("恢复模板默认字段") {

                            settings.selectedTemplate =
                                templatePresetEngine.build(
                                    preset: currentPreset
                                )
                            settings.saveTemplate()
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                }

                GroupBox("时间锚点") {

                    VStack(
                        alignment: .leading,
                        spacing: 12
                    ) {

                        Picker(
                            "选择时间点",
                            selection: $selectedAnchorID
                        ) {

                            Text("未选择")
                                .tag(
                                    Optional<Anchor.ID>.none
                                )

                            ForEach(
                                settings.anchors
                            ) { anchor in

                                Text(anchor.title)
                                    .tag(
                                        Optional(anchor.id)
                                    )
                            }
                        }
                        .pickerStyle(.menu)

                        Button {

                            showAnchorManager = true

                        } label: {

                            Label(
                                "设置时间点",
                                systemImage: "calendar.badge.plus"
                            )
                        }

                        Text(
                            photoTimeDescription
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)

                        if let preview = anchorPreviewResult {

                            VStack(
                                alignment: .leading,
                                spacing: 4
                            ) {

                                Text(preview.summaryText)
                                    .font(.headline)

                                Text(
                                    "\(preview.primaryText) · \(preview.secondaryText)"
                                )
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                        } else {

                            Text(
                                "选择一个时间点后，系统会按照片 EXIF 拍摄时间自动计算宝宝年龄、纪念时长、纪念天数或未来倒计时。"
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                }

                GroupBox("字段编辑") {

                    VStack(
                        alignment: .leading,
                        spacing: 18
                    ) {

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

                        templateFieldEditor(
                            for: .leftTop
                        )

                        templateFieldEditor(
                            for: .rightTop
                        )

                        templateFieldEditor(
                            for: .leftBottom
                        )

                        templateFieldEditor(
                            for: .rightBottom
                        )
                    }
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                }

                GroupBox("自定义内容") {

                    VStack(
                        alignment: .leading,
                        spacing: 12
                    ) {

                        TextField(
                            "标题",
                            text: $titleText
                        )

                        TextField(
                            "记忆文案",
                            text: $storyText,
                            axis: .vertical
                        )
                        .lineLimit(3...6)
                    }
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                }

                GroupBox("图标") {

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
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                }

                GroupBox("输出") {

                    VStack(
                        alignment: .leading,
                        spacing: 10
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

                        Text(
                            "处理后的图片会直接写入系统图库；不选现有相册时，会自动创建或复用 PhotoMemo 相册。除分辨率变化外，会尽量保留原图 EXIF、拍摄时间与元数据。"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)

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
                
                Spacer(minLength: 0)
            }
        }
        .groupBoxStyle(
            MinimalCardGroupBoxStyle()
        )
        .padding(24)
        .frame(
            minWidth: 360,
            maxWidth: .infinity,
            alignment: .topLeading
        )
    }
}

private extension MainView {

    var heroPanel: some View {

        HStack(spacing: 10) {

            statusPill(
                title: "模板",
                value: currentPreset.displayName
            )

            statusPill(
                title: "时间点",
                value:
                    selectedAnchor?.title
                    ?? "未设置"
            )

            statusPill(
                title: "图库",
                value: "原信息保留"
            )
        }
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
                    "宝宝成长推荐插入 {{anchor_age_text}}；恋爱、结婚、纪念日推荐插入 {{anchor_smart_text}}、{{anchor_duration_text}} 或 {{anchor_total_days_text}}；高考、毕业、入学、旅行、演唱会等未来目标推荐插入 {{anchor_countdown_text}}。普通文字和智能数据可以自由混写。"
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                Text(
                    "点下面的句式，可直接插入到当前选中的区域，再把主体、目标名称、鼓励语改成你自己的表达。"
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                ScrollView(
                    .horizontal,
                    showsIndicators: false
                ) {

                    HStack(spacing: 10) {

                        ForEach(
                            smartSentencePresets
                        ) { preset in

                            Button(preset.title) {
                                insertSnippet(
                                    preset.value
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

            ScrollView(
                .horizontal,
                showsIndicators: false
            ) {

                HStack(spacing: 10) {

                    ForEach(variables) { variable in

                        Button(variable.title) {
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

        let editingItemID =
            editingComposerItemIDs[slot]

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            HStack {

                Text(slot.title)
                    .font(.headline)

                Spacer()

                if focusedField == slot {

                    Text("当前编辑")
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

                                Text(slot.placeholder)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .frame(
                                        maxWidth: .infinity,
                                        alignment: .leading
                                    )
                            } else {

                                ScrollView(
                                    .horizontal,
                                    showsIndicators: false
                                ) {

                                    HStack(spacing: 10) {

                                        composerInsertionHandle(
                                            for: slot,
                                            index: 0,
                                            proxy: proxy
                                        )

                                        ForEach(
                                            Array(
                                                items.enumerated()
                                            ),
                                            id: \.element.id
                                        ) { index, item in

                                            composerChip(
                                                item,
                                                slot: slot,
                                                isSelected:
                                                    selectedItemID
                                                    == item.id,
                                                isHovered:
                                                    hoveredItemID
                                                    == item.id,
                                                isEditing:
                                                    editingItemID
                                                    == item.id
                                            )
                                            .id(item.id)
                                            .onTapGesture {
                                                focusComposerItem(
                                                    item.id,
                                                    slot: slot,
                                                    proxy: proxy
                                                )
                                            }
                                            .onTapGesture(count: 2) {
                                                beginEditingComposerItem(
                                                    item,
                                                    in: slot,
                                                    proxy: proxy
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
                                            .draggable(item.id) {
                                                composerChip(
                                                    item,
                                                    slot: slot,
                                                    isSelected: true,
                                                    isHovered: false,
                                                    isEditing: false
                                                )
                                            }
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

                                                if isTargeted {
                                                    draggedComposerItemIDs[slot] =
                                                        item.id
                                                } else if draggedComposerItemIDs[slot] == item.id {
                                                    draggedComposerItemIDs[slot] =
                                                        nil
                                                }
                                            }

                                            composerInsertionHandle(
                                                for: slot,
                                                index: index + 1,
                                                proxy: proxy
                                            )
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

                        if !items.isEmpty {

                            composerToolbar(
                                for: slot,
                                items: items,
                                proxy: proxy
                            )
                        }
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
                    focusedField = slot
                }

                HStack(
                    alignment: .center,
                    spacing: 10
                ) {

                    TextField(
                        "输入普通文字后加入当前区域",
                        text: customTextBinding(
                            for: slot
                        )
                    )
                    .textFieldStyle(.roundedBorder)
                    .focused(
                        $focusedField,
                        equals: slot
                    )

                    Button("加入文字") {
                        appendCustomText(
                            for: slot
                        )
                    }
                    .buttonStyle(.bordered)
                    .disabled(
                        customTextBinding(
                            for: slot
                        ).wrappedValue
                        .trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ).isEmpty
                    )

                    Button("清空") {
                        updateTemplateValue(
                            "",
                            for: slot
                        )
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
                    .disabled(items.isEmpty)
                }
            }
        }
    }

    @ViewBuilder
    func composerChip(
        _ item: TemplateComposerItem,
        slot: MainFieldSlot,
        isSelected: Bool,
        isHovered: Bool,
        isEditing: Bool
    ) -> some View {

        let style =
            composerChipStyle(
                for: item
            )

        let focusID =
            composerEditorFocusID(
                for: slot,
                itemID: item.id
            )

        HStack(spacing: 8) {

            Image(
                systemName: style.icon
            )
            .font(.caption.weight(.semibold))
            .foregroundStyle(
                style.tint
            )

            if isEditing,
               case .literal = item.segment {

                TextField(
                    "编辑文字",
                    text: editingComposerDraftBinding(
                        for: slot
                    )
                )
                .textFieldStyle(.plain)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
                .frame(minWidth: 42)
                .focused(
                    $focusedComposerEditorID,
                    equals: focusID
                )
                .onSubmit {
                    commitEditingComposerItem(
                        in: slot
                    )
                }

                Button {
                    commitEditingComposerItem(
                        in: slot
                    )
                } label: {

                    Image(
                        systemName: "checkmark.circle.fill"
                    )
                    .font(.caption)
                    .foregroundStyle(
                        MinimalPalette.accent
                    )
                }
                .buttonStyle(.plain)

                Button {
                    cancelEditingComposerItem(
                        in: slot
                    )
                } label: {

                    Image(
                        systemName: "xmark.circle.fill"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

            } else {

                Text(
                    composerChipTitle(
                        for: item
                    )
                )
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
                .lineLimit(1)

                Button {
                    removeComposerItem(
                        item,
                        from: slot
                    )
                } label: {

                    Image(
                        systemName: "xmark.circle.fill"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            Capsule()
                .fill(
                    style.background
                )
        )
        .overlay(
            Capsule()
                .stroke(
                    isSelected
                        ? MinimalPalette.accent
                        : style.border,
                    lineWidth:
                        isSelected ? 1.5 : 1
                )
        )
        .shadow(
            color:
                isSelected
                ? MinimalPalette.accent.opacity(0.22)
                : .black.opacity(
                    isHovered ? 0.06 : 0
                ),
            radius: isSelected ? 10 : 6,
            y: isSelected ? 4 : 2
        )
        .scaleEffect(
            isSelected ? 1.015 : (isHovered ? 1.01 : 1)
        )
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

            VStack(spacing: 4) {

                RoundedRectangle(
                    cornerRadius: 999,
                    style: .continuous
                )
                .fill(
                    isSelected
                        ? MinimalPalette.accent
                        : Color.black.opacity(0.08)
                )
                .frame(
                    width: isSelected ? 18 : 14,
                    height: isSelected ? 4 : 3
                )

                if isSelected {

                    Image(
                        systemName: "plus.circle.fill"
                    )
                    .font(.caption2)
                    .foregroundStyle(
                        MinimalPalette.accent
                    )
                }
            }
            .frame(width: 18, height: 24)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("插入到这里")
    }

    @ViewBuilder
    func composerToolbar(
        for slot: MainFieldSlot,
        items: [TemplateComposerItem],
        proxy: ScrollViewProxy
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            HStack(spacing: 8) {

                toolbarIconButton(
                    title: "左移",
                    systemImage: "arrow.left"
                ) {
                    moveSelectedComposerItem(
                        in: slot,
                        direction: -1
                    )

                    scrollSelectedComposerItem(
                        in: slot,
                        proxy: proxy
                    )
                }
                .disabled(
                    !canMoveSelectedComposerItem(
                        in: slot,
                        direction: -1
                    )
                )

                toolbarIconButton(
                    title: "右移",
                    systemImage: "arrow.right"
                ) {
                    moveSelectedComposerItem(
                        in: slot,
                        direction: 1
                    )

                    scrollSelectedComposerItem(
                        in: slot,
                        proxy: proxy
                    )
                }
                .disabled(
                    !canMoveSelectedComposerItem(
                        in: slot,
                        direction: 1
                    )
                )

                Spacer()

                Text("可拖动排序")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ScrollView(
                .horizontal,
                showsIndicators: false
            ) {

                HStack(spacing: 8) {

                    separatorButton(
                        title: "空格",
                        value: " "
                    )

                    separatorButton(
                        title: "·",
                        value: " · "
                    )

                    separatorButton(
                        title: "|",
                        value: " | "
                    )

                    separatorButton(
                        title: ",",
                        value: ", "
                    )
                }
            }
        }
    }

    @ViewBuilder
    func toolbarIconButton(
        title: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {

        Button(action: action) {

            Label(title, systemImage: systemImage)
                .font(.caption.weight(.medium))
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }

    @ViewBuilder
    func separatorButton(
        title: String,
        value: String
    ) -> some View {

        Button(title) {
            insertSeparator(value)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }
}

// MARK: - Detail
private extension MainView {

    @ViewBuilder
    var detail: some View {

        if let selectedPhoto,
           let card = currentCard {

            ScrollView {

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

                        RecordCardRenderer(
                            image: Image(
                                nsImage: selectedPhoto.image
                            ),
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
                .padding()
            }

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
}

private extension MainView {

    var currentCard: RecordCard? {

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
            story: resolvedStory
        )
    }

    var activeTemplate: Template {

        settings.selectedTemplate
        ?? .template1
    }

    var currentPreset: TemplatePreset {

        switch activeTemplate.name {

        case TemplatePreset.template1.displayName,
             "Classic White":
            return .template1

        case TemplatePreset.template2.displayName:
            return .template2

        case TemplatePreset.template3.displayName:
            return .template3

        default:
            return .template1
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
            return "导入照片后，系统会用照片 EXIF 拍摄时间与锚点时间做差值计算，可生成宝宝年龄、纪念时长或未来倒计时。"
        }

        return "当前照片 EXIF 时间：\(captureDate.formatted(date: .numeric, time: .standard))"
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
        settings.saveTemplate()
    }

    func customTextBinding(
        for slot: MainFieldSlot
    ) -> Binding<String> {

        Binding(
            get: {
                customTextDrafts[slot] ?? ""
            },
            set: { newValue in
                customTextDrafts[slot] = newValue
            }
        )
    }

    func editingComposerDraftBinding(
        for slot: MainFieldSlot
    ) -> Binding<String> {

        Binding(
            get: {
                editingComposerDrafts[slot] ?? ""
            },
            set: { newValue in
                editingComposerDrafts[slot] = newValue
            }
        )
    }

    func composerEditorFocusID(
        for slot: MainFieldSlot,
        itemID: String
    ) -> String {

        slot.rawValue + "-" + itemID
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

    func appendCustomText(
        for slot: MainFieldSlot
    ) {

        let trimmed =
            customTextBinding(
                for: slot
            ).wrappedValue
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !trimmed.isEmpty else {
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

        customTextDrafts[slot] = ""
        focusedField = slot
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

        focusedField = slot
    }

    func beginEditingComposerItem(
        _ item: TemplateComposerItem,
        in slot: MainFieldSlot,
        proxy: ScrollViewProxy
    ) {

        guard case .literal(let literal) = item.segment else {
            return
        }

        editingComposerItemIDs[slot] = item.id
        editingComposerDrafts[slot] = literal
        focusedField = slot
        selectedComposerItemIDs[slot] = item.id

        let focusID =
            composerEditorFocusID(
                for: slot,
                itemID: item.id
            )

        DispatchQueue.main.async {
            focusedComposerEditorID = focusID
        }

        withAnimation(.easeInOut(duration: 0.2)) {
            proxy.scrollTo(
                item.id,
                anchor: .center
            )
        }
    }

    func commitEditingComposerItem(
        in slot: MainFieldSlot
    ) {

        guard
            let itemID =
                editingComposerItemIDs[slot]
        else {
            return
        }

        let trimmed =
            editingComposerDrafts[slot]?
            .trimmingCharacters(
                in: .newlines
            ) ?? ""

        var items =
            composerItems(for: slot)

        guard
            let itemIndex =
                items.firstIndex(
                    where: { $0.id == itemID }
                )
        else {
            cancelEditingComposerItem(
                in: slot
            )
            return
        }

        if trimmed.isEmpty {
            items.remove(at: itemIndex)
        } else {
            items[itemIndex].segment =
                .literal(trimmed)
        }

        updateTemplateValue(
            serializeComposerItems(items),
            for: slot
        )

        editingComposerItemIDs[slot] = nil
        editingComposerDrafts[slot] = nil
        focusedComposerEditorID = nil
        selectedComposerItemIDs[slot] =
            items.isEmpty
            ? nil
            : "item-\(min(itemIndex, items.count - 1))"
        insertionComposerIndices[slot] =
            items.isEmpty
            ? 0
            : min(itemIndex + 1, items.count)
    }

    func cancelEditingComposerItem(
        in slot: MainFieldSlot
    ) {

        editingComposerItemIDs[slot] = nil
        editingComposerDrafts[slot] = nil
        focusedComposerEditorID = nil
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
        focusedField = slot

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
        focusedField = slot
    }

    func canMoveSelectedComposerItem(
        in slot: MainFieldSlot,
        direction: Int
    ) -> Bool {

        let items =
            composerItems(for: slot)

        guard
            let currentIndex =
                selectedComposerIndex(
                    in: slot,
                    items: items
                )
        else {
            return false
        }

        let targetIndex =
            currentIndex + direction

        return targetIndex >= 0
            && targetIndex < items.count
    }

    func moveSelectedComposerItem(
        in slot: MainFieldSlot,
        direction: Int
    ) {

        let items =
            composerItems(for: slot)

        guard
            let currentIndex =
                selectedComposerIndex(
                    in: slot,
                    items: items
                )
        else {
            return
        }

        let targetIndex =
            currentIndex + direction

        guard
            targetIndex >= 0,
            targetIndex < items.count
        else {
            return
        }

        reorderComposerItems(
            in: slot,
            from: "item-\(currentIndex)",
            to: "item-\(targetIndex)"
        )
    }

    func scrollSelectedComposerItem(
        in slot: MainFieldSlot,
        proxy: ScrollViewProxy
    ) {

        guard let selectedID =
            selectedComposerItemIDs[slot]
        else {
            return
        }

        withAnimation(.easeInOut(duration: 0.2)) {
            proxy.scrollTo(
                selectedID,
                anchor: .center
            )
        }
    }

    func insertSeparator(
        _ value: String
    ) {

        let slot =
            focusedField
            ?? .rightBottom

        appendComposerItems(
            [
                TemplateComposerItem(
                    id: UUID().uuidString,
                    segment: .literal(value)
                )
            ],
            to: slot
        )

        focusedField = slot
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
        focusedField = slot

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

        case "{{anchor_countdown_text}}":
            return "flag.checkered"

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

        if items.isEmpty {

            var item = fallback
            item.value = value
            items = [item]

        } else {

            items[0].value = value
            items[0].isEnabled = true
        }
    }

    func insertToken(
        _ token: String
    ) {

        insertSnippet(token)
    }

    func insertSnippet(
        _ snippet: String
    ) {

        let slot =
            focusedField
            ?? .rightBottom

        appendComposerItems(
            parseComposerItems(
                from: snippet
            ),
            to: slot
        )

        focusedField = slot
    }

    func configureInitialState() {

        if selectedAnchorID == nil {
            selectedAnchorID =
                settings.anchors.first?.id
        }

        if focusedField == nil {
            focusedField = .rightBottom
        }
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

    var smartSentencePresets: [SmartSentencePreset] {

        let genericTitle =
            "{{anchor_title}}"

        let anchorName =
            selectedAnchor?.title.trimmingCharacters(
                in: .whitespacesAndNewlines
            ) ?? ""

        let resolvedTitle =
            anchorName.isEmpty
            ? genericTitle
            : anchorName

        let basePresets = [
            SmartSentencePreset(
                title: "宝宝年龄",
                value: "宝宝到今天{{anchor_age_text}}"
            ),
            SmartSentencePreset(
                title: "纪念时长",
                value: "\(resolvedTitle){{anchor_duration_text}}"
            ),
            SmartSentencePreset(
                title: "纪念天数",
                value: "今天是\(resolvedTitle)第{{anchor_total_days_text}}"
            ),
            SmartSentencePreset(
                title: "未来倒计时",
                value: "距离\(resolvedTitle)还有{{anchor_countdown_text}}"
            ),
            SmartSentencePreset(
                title: "加油文案",
                value: "距离\(resolvedTitle)还有{{anchor_countdown_text}}，加油呀"
            ),
            SmartSentencePreset(
                title: "主体 + 目标",
                value: "XX距离\(resolvedTitle)还有{{anchor_countdown_text}}"
            )
        ]

        guard let selectedAnchor else {
            return basePresets
        }

        switch (selectedAnchor.type, selectedAnchor.isCountdown) {

        case (.birthday, _):
            return [
                SmartSentencePreset(
                    title: "成长记录",
                    value: "宝宝到今天{{anchor_age_text}}"
                ),
                SmartSentencePreset(
                    title: "名字版",
                    value: "XX宝宝到今天{{anchor_age_text}}"
                ),
                SmartSentencePreset(
                    title: "成长天数",
                    value: "宝宝已经{{anchor_total_days_text}}"
                )
            ]

        case (.exam, true):
            return [
                SmartSentencePreset(
                    title: "毕业倒计时",
                    value: "距离\(resolvedTitle)还有{{anchor_countdown_text}}"
                ),
                SmartSentencePreset(
                    title: "鼓励版",
                    value: "距离\(resolvedTitle)还有{{anchor_countdown_text}}，加油呀"
                ),
                SmartSentencePreset(
                    title: "主体版",
                    value: "XX距离\(resolvedTitle)还有{{anchor_countdown_text}}"
                ),
                SmartSentencePreset(
                    title: "目标提醒",
                    value: "\(resolvedTitle)倒计时{{anchor_countdown_text}}"
                )
            ]

        case (.exam, false):
            return [
                SmartSentencePreset(
                    title: "毕业纪念",
                    value: "\(resolvedTitle){{anchor_duration_text}}"
                ),
                SmartSentencePreset(
                    title: "毕业天数",
                    value: "今天是\(resolvedTitle)第{{anchor_total_days_text}}"
                ),
                SmartSentencePreset(
                    title: "主体版",
                    value: "XX在\(resolvedTitle)这一天{{anchor_duration_text}}"
                )
            ]

        default:
            return basePresets
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
                ?? Int(selectedPhoto.image.size.width)
            )

        let height =
            CGFloat(
                selectedPhoto.metadata.imageHeight
                ?? Int(selectedPhoto.image.size.height)
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

        settings.saveAll()

        presentAlert(
            title: "配置已保存",
            message: "当前模板、徽标和时间锚点已经保存到本地。"
        )
    }

    func saveCurrentCardToAlbum() async {

        guard
            let selectedPhoto,
            let currentCard
        else {
            return
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
}
