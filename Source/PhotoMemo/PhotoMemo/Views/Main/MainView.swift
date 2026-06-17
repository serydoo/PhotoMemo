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
            return "例如：{{anchor_title}}今天{{anchor_age_text}}啦"
        }
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

    @FocusState
    private var focusedField: MainFieldSlot?

    private let templatePresetEngine =
        TemplatePresetEngine()

    private let anchorEngine =
        AnchorEngine()

    private let exportService =
        RecordCardExportService()

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

                Button("导出") {
                    exportCurrentCard()
                }
                .disabled(
                    selectedPhoto == nil
                    || currentCard == nil
                )
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
                                "选择一个时间点后，系统会按照片 EXIF 拍摄时间自动计算年龄、月数、天数等字段。"
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

                        Text(
                            "先点下面任意一项，再点上方变量按钮插入。字段前后都可以直接输入自定义文案。"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)

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
                title: "导出",
                value: "保留EXIF"
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

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            Text(slot.title)
                .font(.headline)

            HStack(spacing: 8) {

                HStack(spacing: 10) {

                    TextField(
                        slot.placeholder,
                        text: fieldBinding(
                            for: slot
                        )
                    )
                    .textFieldStyle(.plain)
                    .font(.system(
                        size: 15
                    ))
                    .focused(
                        $focusedField,
                        equals: slot
                    )

                    Button {

                        updateTemplateValue(
                            "",
                            for: slot
                        )

                    } label: {

                        Image(systemName: "xmark")
                            .foregroundStyle(.secondary)
                            .frame(width: 18)
                    }
                    .buttonStyle(.plain)
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
            }
        }
    }
}

// MARK: - Detail
private extension MainView {

    @ViewBuilder
    var detail: some View {

        if let selectedPhoto,
           let card = currentCard {

            ScrollView {

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
                        maxWidth: previewCardMaxWidth(
                            for: selectedPhoto
                        )
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
            anchorResult: selectedAnchor.map {
                anchorEngine.build(
                    from: $0,
                    referenceDate:
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
            referenceDate:
                selectedPhoto?.metadata.captureDate
                ?? Date()
        )
    }

    var photoTimeDescription: String {

        guard let captureDate =
            selectedPhoto?.metadata.captureDate
        else {
            return "导入照片后，会优先使用 EXIF 拍摄时间来计算纪念字段。"
        }

        return "当前基准时间：\(captureDate.formatted(date: .numeric, time: .standard))"
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

    func fieldBinding(
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
                fallback: .memorySummary,
                value: value
            )
        }

        settings.selectedTemplate = template
        settings.saveTemplate()
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

        let slot =
            focusedField
            ?? .rightBottom

        let currentValue =
            templateValue(for: slot)

        if currentValue.isEmpty {

            updateTemplateValue(
                token,
                for: slot
            )

        } else {

            updateTemplateValue(
                currentValue + token,
                for: slot
            )
        }

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

    func saveCurrentConfiguration() {

        settings.saveAll()

        presentAlert(
            title: "配置已保存",
            message: "当前模板、徽标和时间锚点已经保存到本地。"
        )
    }

    func exportCurrentCard() {

        guard
            let selectedPhoto,
            let currentCard
        else {
            return
        }

        do {

            let url =
                try exportService.export(
                    photo: selectedPhoto,
                    card: currentCard
                )

            presentAlert(
                title: "导出完成",
                message:
                    "图片已导出到：\(url.path)"
            )

        } catch RecordCardExportError.saveCancelled {

            return

        } catch {

            presentAlert(
                title: "导出失败",
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
