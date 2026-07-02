#if !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct MemoryBlockInspectorView: View {

    @ObservedObject
    var session: ConfigurationSession

    @State
    private var selectedTemplateIDs: [CardRegion: String] = [:]

    @State
    private var fieldDrafts: [String: String] = [:]

    @State
    private var customFields: [String: [CustomBlockFieldDraft]] = [:]

    @State
    private var selectedCustomFieldIDs: [String: UUID] = [:]

    @State
    private var removedSystemFieldIDs: [String: Set<String>] = [:]

    @State
    private var savedConfigurationIDs: Set<String> = []

    @State
    private var customConfigurationNames: [String: String] = [:]

    @State
    private var renamingConfigurationID: String?

    @State
    private var expandedSections: Set<BlockInspectorSection> = [
        .configuration,
        .system,
        .custom
    ]

    @FocusState
    private var focusedField: BlockFocusedField?

    var body: some View {
        VStack(alignment: .leading, spacing: 26) {
            InspectorSectionView(
                "概览",
                systemImage: "rectangle.and.text.magnifyingglass"
            ) {
                overview
            }

            collapsibleSection(
                .configuration,
                title: "记忆模块",
                systemImage: "square.grid.2x2"
            ) {
                configurationPicker
            }

            collapsibleSection(
                .system,
                title: "系统模块",
                systemImage: "cpu"
            ) {
                systemModules
            }

            collapsibleSection(
                .custom,
                title: "自定义内容",
                systemImage: "text.badge.plus"
            ) {
                customFieldsEditor
            }
        }
        .onChange(of: selectedRegion) { _, _ in
            ensureTemplateSelection()
            ensureCustomFields()
        }
        .onChange(of: selectedMemoryPresetID) { _, _ in
            ensureTemplateSelection()
            ensureCustomFields()
        }
        .onChange(of: session.latestModuleInsertion?.id) { _, _ in
            guard let insertion = session.latestModuleInsertion else {
                return
            }

            insertExternalModule(insertion)
        }
        .onAppear {
            ensureTemplateSelection()
            ensureCustomFields()
        }
        .onTapGesture {
            focusedField = nil
        }
    }

    private func collapsibleSection<Content: View>(
        _ section: BlockInspectorSection,
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            Button {
                withAnimation(.easeInOut(duration: 0.16)) {
                    if expandedSections.contains(section) {
                        expandedSections.remove(section)
                    } else {
                        expandedSections.insert(section)
                    }
                }
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: systemImage)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 16)

                    Text(title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Spacer(minLength: 0)

                    Image(
                        systemName:
                            expandedSections.contains(section)
                            ? "chevron.down"
                            : "chevron.right"
                    )
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)

            if expandedSections.contains(section) {
                content()
                    .transition(
                        .opacity
                            .combined(with: .move(edge: .top))
                    )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 2)
    }

    private var overview: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(selectedRegion.semanticTitle)
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.primary)

            Text(currentTemplate.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .configurationPanelChrome()
    }

    private var configurationPicker: some View {
        MemoryBlockInspectorConfigurationPickerSection(
            options: configurationOptions,
            selectedTemplateID: selectedTemplateIDBinding,
            currentTemplateSummary: currentTemplate.summary,
            isSaved: savedConfigurationIDs.contains(selectedTemplateID),
            renamingConfigurationID: $renamingConfigurationID,
            renameText: configurationNameBinding(for: currentTemplate),
            onSaveConfiguration: {
                savedConfigurationIDs.insert(selectedTemplateID)
            }
        )
    }

    private var systemModules: some View {
        MemoryBlockInspectorSystemModulesSection(
            fields: systemFieldDisplayItems,
            onDelete: { fieldID in
                guard let field = activeSystemFields.first(where: { $0.id == fieldID }) else {
                    return
                }
                removeSystemField(field)
            }
        )
    }

    private var customFieldsEditor: some View {
        MemoryBlockInspectorCustomFieldsSection(
            fields: currentCustomFields,
            selectedFieldID:
                selectedCustomFieldIDs[selectedTemplateID],
            focusedField: $focusedField,
            textBinding: customFieldTextBinding(for:),
            indexProvider: indexOfCustomField,
            onSelectField: { fieldID in
                selectedCustomFieldIDs[selectedTemplateID] = fieldID
            },
            onMoveField: moveCustomField(_:direction:),
            onMoveBefore: moveCustomField(_:before:),
            onRemoveInsertedModule: removeInsertedModule(_:from:),
            onDeleteField: deleteCustomField,
            onAddField: addCustomField
        )
    }

    private var selectedRegion: CardRegion {
        session.state.selectedRegion
    }

    private var templates: [MemoryBlockTemplateDraft] {
        MemoryBlockTemplateDraft.templates(for: selectedRegion)
    }

    private var selectedTemplateID: String {
        session.activeTemplateID(for: selectedRegion)
        ?? selectedTemplateIDs[selectedRegion]
        ?? templates.first?.id
        ?? "empty"
    }

    private var currentTemplate: MemoryBlockTemplateDraft {
        templates.first {
            $0.id == selectedTemplateID
        }
        ?? templates.first
        ?? .empty(region: selectedRegion)
    }

    private var configurationOptions:
        [MemoryBlockInspectorConfigurationOption] {
        templates.map { template in
            MemoryBlockInspectorConfigurationOption(
                id: template.id,
                title: configurationName(for: template)
            )
        }
    }

    private var selectedTemplateIDBinding:
        Binding<String> {
        Binding(
            get: {
                selectedTemplateID
            },
            set: {
                selectedTemplateIDs[selectedRegion] = $0
                session.updateActiveTemplate(
                    for: selectedRegion,
                    templateID: $0
                )
                ensureCustomFields()
                syncRegionPreview()
            }
        )
    }

    private func configurationName(
        for template: MemoryBlockTemplateDraft
    ) -> String {
        customConfigurationNames[template.id]
        ?? template.title
    }

    private func configurationNameBinding(
        for template: MemoryBlockTemplateDraft
    ) -> Binding<String> {
        Binding(
            get: {
                configurationName(for: template)
            },
            set: {
                customConfigurationNames[template.id] =
                    $0.trimmingCharacters(in: .whitespacesAndNewlines)
                    .isEmpty
                    ? template.title
                    : $0
            }
        )
    }

    private var currentCustomFields: [CustomBlockFieldDraft] {
        customFields[selectedTemplateID] ?? []
    }

    private var activeSystemFields: [MemoryBlockFieldDraft] {
        let removed =
            removedSystemFieldIDs[selectedTemplateID]
            ?? []

        return currentTemplate.fields.filter {
            !removed.contains($0.id)
        }
    }

    private var systemFieldDisplayItems:
        [MemoryBlockInspectorSystemFieldDisplayItem] {
        activeSystemFields.map { field in
            MemoryBlockInspectorSystemFieldDisplayItem(
                id: field.id,
                label: field.label,
                symbolName: field.source.symbolName,
                value: value(for: field)
            )
        }
    }

    private func ensureTemplateSelection() {
        if selectedTemplateIDs[selectedRegion] == nil {
            selectedTemplateIDs[selectedRegion] =
                selectedTemplateID
        }
    }

    private func ensureCustomFields() {
        if customFields[selectedTemplateID] == nil {
            customFields[selectedTemplateID] =
                CustomBlockFieldDraft.defaults(
                    for: currentTemplate
                )
        }
        syncRegionPreview()
    }

    private func value(
        for field: MemoryBlockFieldDraft
    ) -> String {
        if field.source == .memorySubject {
            return selectedSubjectName
        }

        if field.source == .smartModule {
            return smartTimeResult
        }

        return fieldDrafts[field.draftKey]
        ?? field.defaultValue
    }

    private var selectedSubjectName: String {
        guard let subject = session.state.selectedSubject else {
            return "记忆对象"
        }

        if !subject.identity.shortName.isEmpty {
            return subject.identity.shortName
        }

        return subject.identity.displayName
    }

    private func addCustomField() {
        var fields = currentCustomFields
        let field =
            CustomBlockFieldDraft(
                text: ""
            )
        fields.append(field)
        customFields[selectedTemplateID] = fields
        selectedCustomFieldIDs[selectedTemplateID] = field.id
        syncRegionPreview()
    }

    private func customFieldTextBinding(
        for field: CustomBlockFieldDraft
    ) -> Binding<String> {
        Binding(
            get: {
                currentCustomFields.first {
                    $0.id == field.id
                }?.text ?? field.text
            },
            set: {
                updateCustomFieldText(
                    field.id,
                    text: $0
                )
            }
        )
    }

    private func updateCustomFieldText(
        _ id: UUID,
        text: String
    ) {
        var fields = currentCustomFields
        guard let index = fields.firstIndex(where: { $0.id == id }) else {
            return
        }

        fields[index].text = text
        customFields[selectedTemplateID] = fields
        selectedCustomFieldIDs[selectedTemplateID] = id
        syncRegionPreview()
    }

    private func insertExternalModule(
        _ insertion: MemoryModuleInsertion
    ) {
        guard insertion.region == selectedRegion else {
            return
        }

        if selectedCustomFieldIDs[selectedTemplateID] == nil {
            addCustomField()
        }

        guard let fieldID = selectedCustomFieldIDs[selectedTemplateID] else {
            return
        }

        var fields = currentCustomFields
        guard let index = fields.firstIndex(where: { $0.id == fieldID }) else {
            return
        }

        let module =
            InsertableModuleDraft(
                title: insertion.title,
                token: insertion.token,
                systemImage: insertion.systemImage,
                previewValue: insertion.value
            )

        fields[index].modules.append(
            InsertedModuleDraft(module: module)
        )
        customFields[selectedTemplateID] = fields
        selectedCustomFieldIDs[selectedTemplateID] = fieldID
        syncRegionPreview()
    }

    private func removeInsertedModule(
        _ moduleID: UUID,
        from fieldID: UUID
    ) {
        var fields = currentCustomFields
        guard let index = fields.firstIndex(where: { $0.id == fieldID }) else {
            return
        }

        fields[index].modules.removeAll {
            $0.id == moduleID
        }
        customFields[selectedTemplateID] = fields
        selectedCustomFieldIDs[selectedTemplateID] = fieldID
        syncRegionPreview()
    }

    private func deleteCustomField(
        _ id: UUID
    ) {
        var fields = currentCustomFields
        fields.removeAll {
            $0.id == id
        }
        customFields[selectedTemplateID] = fields

        if selectedCustomFieldIDs[selectedTemplateID] == id {
            selectedCustomFieldIDs[selectedTemplateID] =
                fields.first?.id
        }
        syncRegionPreview()
    }

    private func moveCustomField(
        _ id: UUID,
        direction: Int
    ) {
        var fields = currentCustomFields
        guard
            let currentIndex =
                fields.firstIndex(where: { $0.id == id })
        else {
            return
        }

        let targetIndex =
            min(
                max(currentIndex + direction, 0),
                fields.count - 1
            )

        guard currentIndex != targetIndex else {
            return
        }

        let movedField = fields.remove(at: currentIndex)
        fields.insert(movedField, at: targetIndex)
        customFields[selectedTemplateID] = fields
        selectedCustomFieldIDs[selectedTemplateID] = id
        syncRegionPreview()
    }

    private func moveCustomField(
        _ id: UUID,
        before targetID: UUID
    ) {
        guard id != targetID else {
            return
        }

        var fields = currentCustomFields
        guard
            let currentIndex =
                fields.firstIndex(where: { $0.id == id }),
            let targetIndex =
                fields.firstIndex(where: { $0.id == targetID })
        else {
            return
        }

        let movedField = fields.remove(at: currentIndex)
        let adjustedTargetIndex =
            currentIndex < targetIndex
            ? max(targetIndex - 1, 0)
            : targetIndex
        fields.insert(movedField, at: adjustedTargetIndex)
        customFields[selectedTemplateID] = fields
        selectedCustomFieldIDs[selectedTemplateID] = id
        syncRegionPreview()
    }

    private func indexOfCustomField(
        _ id: UUID
    ) -> Int? {
        currentCustomFields.firstIndex {
            $0.id == id
        }
    }

    private func removeSystemField(
        _ field: MemoryBlockFieldDraft
    ) {
        var removed =
            removedSystemFieldIDs[selectedTemplateID]
            ?? []
        removed.insert(field.id)
        removedSystemFieldIDs[selectedTemplateID] = removed
        syncRegionPreview()
    }

    private func syncRegionPreview() {
        let fieldValues =
            activeSystemFields
            .map {
                value(for: $0)
            }

        let customValues =
            currentCustomFields
            .map(\.displayText)
            .filter {
                !$0.isEmpty
            }

        let combined =
            InlineContentTextComposer.compose(
                fieldValues.map { value in
                    InlineContentTextComposer.Piece(
                        kind: .token,
                        value: value
                    )
                }
                + customValues.map { value in
                    InlineContentTextComposer.Piece(
                        kind: .text,
                        value: value
                    )
                }
            )

        let fallback =
            ConfigurationSession.defaultPreviewText(
                for: selectedRegion,
                subject: session.state.selectedSubject
            )
        let hasRemovedSystemField =
            !(removedSystemFieldIDs[selectedTemplateID] ?? [])
            .isEmpty

        session.updateRegionPreview(
            region: selectedRegion,
            text:
                combined.isEmpty
                ? (hasRemovedSystemField ? " " : fallback)
                : combined
        )
    }

    private var smartTimeResult: String {
        guard
            let subject = session.state.selectedSubject,
            let anchor =
                subject.timeAnchors.first(where: {
                    $0.title == subject.behavior.primaryAnchor
                })
                ?? subject.timeAnchors.first
        else {
            return "未设置时间"
        }

        let captureDate =
            Calendar.current.date(
                from:
                    DateComponents(
                        year: 2026,
                        month: 5,
                        day: 24
                    )
            ) ?? Date()

        let components =
            Calendar.current.dateComponents(
                [.year, .month, .day],
                from: anchor.date,
                to: captureDate
            )

        let years = max(components.year ?? 0, 0)
        let months = max(components.month ?? 0, 0)
        let days = max(components.day ?? 0, 0)

        if years > 0 {
            return "\(years)岁\(months)个月\(days)天"
        }

        if months > 0 {
            return "\(months)个月\(days)天"
        }

        return "\(days)天"
    }

    private var selectedMemoryPresetID: MemoryPreset.ID? {
        session.state.selectedMemoryPreset?.id
    }

}

enum BlockFocusedField: Hashable {
    case customField(UUID)
}

private enum BlockInspectorSection: Hashable {
    case configuration
    case system
    case custom
}

private struct MemoryBlockTemplateDraft:
    Identifiable,
    Hashable {

    let id: String
    let title: String
    let summary: String
    let fields: [MemoryBlockFieldDraft]
    let fallback: String
    let displayBehavior: String

    static func templates(
        for region: CardRegion
    ) -> [MemoryBlockTemplateDraft] {
        switch region {
        case .slotA:
            return recorderTemplates
        case .slotB:
            return timelineTemplates
        case .slotC:
            return contextTemplates
        case .slotD:
            return memoryTemplates
        default:
            return [
                .empty(region: region)
            ]
        }
    }

    static func empty(
        region: CardRegion
    ) -> MemoryBlockTemplateDraft {
        MemoryBlockTemplateDraft(
            id: "\(region.rawValue).empty",
            title: "无模块",
            summary: "这个对象暂时不使用记忆模块。",
            fields: [],
            fallback: "无",
            displayBehavior: "对象独立配置"
        )
    }
}

private extension MemoryBlockTemplateDraft {

    static let recorderTemplates = [
        MemoryBlockTemplateDraft(
            id: "recorder.configuration1",
            title: "配置 1：记录者信息",
            summary: "默认展示记录者信息与拍摄设备型号，两个模块都可以删除或替换为自定义内容。",
            fields: [
                .init(
                    templateID: "recorder.configuration1",
                    key: "recorder",
                    label: "记录者信息",
                    defaultValue: "记录",
                    source: .fixedText
                ),
                .init(
                    templateID: "recorder.configuration1",
                    key: "cameraModel",
                    label: "拍摄设备型号",
                    defaultValue: "iPhone 17 Pro Max",
                    source: .exif
                )
            ],
            fallback: "为空时隐藏",
            displayBehavior: "记录者 + 设备"
        ),
        MemoryBlockTemplateDraft(
            id: "recorder.configuration2",
            title: "配置 2：自定义记录",
            summary: "预留给用户自定义记录方式。",
            fields: [],
            fallback: "为空时隐藏",
            displayBehavior: "用户自定义"
        ),
        MemoryBlockTemplateDraft(
            id: "recorder.configuration3",
            title: "配置 3：自定义记录",
            summary: "预留给用户保存另一套记录方式。",
            fields: [],
            fallback: "为空时隐藏",
            displayBehavior: "用户自定义"
        )
    ]

    static let timelineTemplates = [
        MemoryBlockTemplateDraft(
            id: "timeline.configuration1",
            title: "配置 1：拍摄时间",
            summary: "由照片信息自动生成拍摄日期与时间，用户可在自定义字段中补充表达。",
            fields: [
                .init(
                    templateID: "timeline.configuration1",
                    key: "date",
                    label: "拍摄日期",
                    defaultValue: "2026.05.24",
                    source: .exif
                ),
                .init(
                    templateID: "timeline.configuration1",
                    key: "time",
                    label: "拍摄时间",
                    defaultValue: "14:33:13",
                    source: .exif
                )
            ],
            fallback: "缺少时间时仅显示日期",
            displayBehavior: "系统时间模块"
        ),
        MemoryBlockTemplateDraft(
            id: "timeline.configuration2",
            title: "配置 2：日期",
            summary: "仅展示拍摄日期，适合更克制的卡片表达。",
            fields: [
                .init(
                    templateID: "timeline.configuration2",
                    key: "date",
                    label: "拍摄日期",
                    defaultValue: "2026.05.24",
                    source: .exif
                )
            ],
            fallback: "缺少日期时隐藏",
            displayBehavior: "日期模块"
        ),
        MemoryBlockTemplateDraft(
            id: "timeline.configuration3",
            title: "配置 3：自定义时间线",
            summary: "预留给用户保存自定义时间线表达。",
            fields: [],
            fallback: "为空时隐藏",
            displayBehavior: "用户自定义"
        )
    ]

    static let contextTemplates = [
        MemoryBlockTemplateDraft(
            id: "context.configuration1",
            title: "配置 1：拍摄参数汇总",
            summary: "默认只展示拍摄参数汇总，其他信息由用户通过自定义字段补充。",
            fields: [
                .init(
                    templateID: "context.configuration1",
                    key: "cameraParameters",
                    label: "拍摄参数汇总",
                    defaultValue: "20mm f/1.9 1/117s ISO80",
                    source: .exif
                )
            ],
            fallback: "缺少参数时隐藏",
            displayBehavior: "单一照片信息模块"
        ),
        MemoryBlockTemplateDraft(
            id: "context.configuration2",
            title: "配置 2：备用拍摄参数",
            summary: "保留同一行四项拍摄参数，可用于另一套参数表达。",
            fields: [
                .init(
                    templateID: "context.configuration2",
                    key: "cameraParametersAlt",
                    label: "拍摄参数汇总",
                    defaultValue: "24mm f/1.78 1/100s ISO125",
                    source: .exif
                )
            ],
            fallback: "缺少参数时隐藏",
            displayBehavior: "单行四项拍摄参数"
        ),
        MemoryBlockTemplateDraft(
            id: "context.configuration3",
            title: "配置 3：自定义拍摄参数",
            summary: "预留给用户保存另一套拍摄参数表达。",
            fields: [],
            fallback: "为空时隐藏",
            displayBehavior: "用户自定义"
        )
    ]

    static let memoryTemplates = [
        MemoryBlockTemplateDraft(
            id: "memory.configuration1",
            title: ConfigurationCenterMemoryTemplateCatalog.birthdayAgeTitle,
            summary: ConfigurationCenterMemoryTemplateCatalog.birthdayAgeSummary,
            fields: [
                .init(
                    templateID: "memory.configuration1",
                    key: "subject",
                    label: "对象昵称",
                    defaultValue: ConfigurationCenterMemoryTemplateCatalog.birthdayAgeSubjectDefault,
                    source: .memorySubject
                ),
                .init(
                    templateID: "memory.configuration1",
                    key: "action",
                    label: "事件",
                    defaultValue: ConfigurationCenterMemoryTemplateCatalog.birthdayAgeActionDefault,
                    source: .fixedText
                ),
                .init(
                    templateID: "memory.configuration1",
                    key: "result",
                    label: "计算结果",
                    defaultValue: ConfigurationCenterMemoryTemplateCatalog.birthdayAgeResultDefault,
                    source: .smartModule
                )
            ],
            fallback: "计算结果不可用时保留用户文字",
            displayBehavior: "记忆表达行"
        ),
        MemoryBlockTemplateDraft(
            id: "memory.configuration2",
            title: "配置 2：自定义记忆",
            summary: "交给用户自定义记忆表达，可以插入对象、时间与照片信息模块。",
            fields: [],
            fallback: "为空时隐藏",
            displayBehavior: "用户自定义"
        ),
        MemoryBlockTemplateDraft(
            id: "memory.configuration3",
            title: "配置 3：自定义记忆",
            summary: "预留给用户保存另一套记忆表达。",
            fields: [],
            fallback: "为空时隐藏",
            displayBehavior: "用户自定义"
        )
    ]
}

private struct MemoryBlockFieldDraft:
    Identifiable,
    Hashable {

    let templateID: String
    let key: String
    let label: String
    let defaultValue: String
    let source: BlockFieldValueSourceDraft

    var id: String {
        draftKey
    }

    var draftKey: String {
        "\(templateID).\(key)"
    }

    var resultFont: Font {
        source == .smartModule
        ? .subheadline.weight(.semibold)
        : .subheadline
    }

    var resultColor: Color {
        source == .smartModule
        ? Color.primary
        : Color.secondary
    }
}

struct CustomBlockFieldDraft:
    Identifiable,
    Hashable {

    let id: UUID
    var text: String
    var modules: [InsertedModuleDraft]

    init(
        id: UUID = UUID(),
        text: String,
        modules: [InsertedModuleDraft] = []
    ) {
        self.id = id
        self.text = text
        self.modules = modules
    }

    var displayText: String {
        InlineContentTextComposer.compose(
            [
                InlineContentTextComposer.Piece(
                    kind: .text,
                    value: text
                )
            ]
            + modules.map { insertedModule in
                InlineContentTextComposer.Piece(
                    kind: .token,
                    value:
                        insertedModule.module.previewValue
                        ?? insertedModule.module.title
                )
            }
        )
    }

    fileprivate static func defaults(
        for template: MemoryBlockTemplateDraft
    ) -> [CustomBlockFieldDraft] {
        if template.fields.isEmpty {
            return [
                CustomBlockFieldDraft(
                    text: ""
                )
            ]
        }

        return []
    }
}

struct InsertableModuleDraft:
    Identifiable,
    Hashable {

    var id: String {
        token
    }

    let title: String
    let token: String
    let systemImage: String
    let previewValue: String?

    init(
        title: String,
        token: String,
        systemImage: String,
        previewValue: String? = nil
    ) {
        self.title = title
        self.token = token
        self.systemImage = systemImage
        self.previewValue = previewValue
    }
}

struct InsertedModuleDraft:
    Identifiable,
    Hashable {

    let id: UUID
    let module: InsertableModuleDraft

    init(
        id: UUID = UUID(),
        module: InsertableModuleDraft
    ) {
        self.id = id
        self.module = module
    }
}

private enum BlockFieldValueSourceDraft:
    String,
    Hashable {

    case fixedText
    case exif
    case memorySubject
    case smartModule
    case customField

    var displayTitle: String {
        switch self {
        case .fixedText:
            return "固定文本"
        case .exif:
            return "照片信息"
        case .memorySubject:
            return "记忆对象"
        case .smartModule:
            return "智能模块"
        case .customField:
            return "自定义字段"
        }
    }

    var symbolName: String {
        switch self {
        case .fixedText:
            return "textformat"
        case .exif:
            return "camera.metering.center.weighted"
        case .memorySubject:
            return "person.fill"
        case .smartModule:
            return "sparkles"
        case .customField:
            return "person.text.rectangle"
        }
    }
}
#endif
