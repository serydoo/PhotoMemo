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
        VStack(alignment: .leading, spacing: 10) {
            Picker(
                "配置",
                selection: Binding(
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
            ) {
                ForEach(templates) { template in
                    Text(configurationName(for: template))
                        .tag(template.id)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(currentTemplate.summary)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption2.weight(.semibold))

                Text("当前记忆预设使用中")
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(Color.accentColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(Color.accentColor.opacity(0.08))
            )

            HStack(spacing: 8) {
                Button {
                    savedConfigurationIDs.insert(selectedTemplateID)
                } label: {
                    Label(
                        savedConfigurationIDs.contains(selectedTemplateID)
                        ? "已保存"
                        : "保存配置",
                        systemImage:
                            savedConfigurationIDs.contains(selectedTemplateID)
                            ? "checkmark.circle.fill"
                            : "tray.and.arrow.down"
                    )
                }
                .buttonStyle(.borderless)

                Button {
                    renamingConfigurationID =
                        renamingConfigurationID == selectedTemplateID
                        ? nil
                        : selectedTemplateID
                } label: {
                    Label("重命名", systemImage: "pencil")
                }
                .buttonStyle(.borderless)
            }
            .font(.caption.weight(.medium))

            if renamingConfigurationID == selectedTemplateID {
                TextField(
                    "配置名称",
                    text: configurationNameBinding(for: currentTemplate)
                )
                .textFieldStyle(.plain)
                .font(.subheadline)
                .configurationFieldChrome(isActive: true)
            }
        }
        .padding(12)
        .configurationPanelChrome(isSelected: true)
    }

    private var systemModules: some View {
        VStack(alignment: .leading, spacing: 12) {
            if activeSystemFields.isEmpty {
                Text("此区域由用户自定义。可以在下方添加字段，并插入照片信息、记忆或系统模块。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(12)
                    .configurationPanelChrome()
            } else {
                ForEach(activeSystemFields) { field in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: field.source.symbolName)
                            .font(.body.weight(.medium))
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 22)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(field.label)
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(value(for: field))
                                .font(.subheadline)
                                .foregroundStyle(Color.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer(minLength: 0)

                        Button(role: .destructive) {
                            removeSystemField(field)
                        } label: {
                            Label("删除", systemImage: "trash")
                                .labelStyle(.iconOnly)
                        }
                        .buttonStyle(.borderless)
                        .help("删除默认模块")
                    }
                    .padding(10)
                    .configurationPanelChrome()
                }
            }
        }
    }

    private var customFieldsEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(currentCustomFields) { field in
                customFieldCard(field)
            }

            Button {
                addCustomField()
            } label: {
                Label("新增内容", systemImage: "plus.circle")
                    .font(.caption.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            .configurationPanelChrome()
        }
    }

    private func customFieldCard(
        _ field: CustomBlockFieldDraft
    ) -> some View {
        let index = indexOfCustomField(field.id)

        return VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 8) {
                Image(systemName: "line.3.horizontal")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text("自定义内容 \(index.map { $0 + 1 } ?? 1)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Button {
                    moveCustomField(
                        field.id,
                        direction: -1
                    )
                } label: {
                    Label("上移", systemImage: "chevron.up")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
                .disabled(index == nil || index == 0)
                .help("上移")

                Button {
                    moveCustomField(
                        field.id,
                        direction: 1
                    )
                } label: {
                    Label("下移", systemImage: "chevron.down")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
                .disabled(
                    index == nil
                    || index == currentCustomFields.count - 1
                )
                .help("下移")
            }

            customFieldContentEditor(for: field)
        }
        .padding(10)
        .configurationPanelChrome(
            isSelected: selectedCustomFieldIDs[selectedTemplateID] == field.id
        )
        .contentShape(RoundedRectangle(cornerRadius: 8))
        .onTapGesture {
            selectedCustomFieldIDs[selectedTemplateID] = field.id
        }
        .draggable(field.id.uuidString)
        .dropDestination(for: String.self) { items, _ in
            guard
                let dragged = items.first,
                let draggedID = UUID(uuidString: dragged)
            else {
                return false
            }

            moveCustomField(
                draggedID,
                before: field.id
            )
            return true
        }
    }

    private func customFieldContentEditor(
        for field: CustomBlockFieldDraft
    ) -> some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 8) {
                TextField(
                    "输入自定义内容，或从下方插入模块",
                    text: customFieldTextBinding(for: field),
                    axis: .vertical
                )
                .textFieldStyle(.plain)
                .font(.subheadline)
                .lineLimit(1...3)
                .focused($focusedField, equals: .customField(field.id))

                if !field.displayText.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("组合预览")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)

                        if !field.text.isEmpty {
                            Text(field.text)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(Color.primary.opacity(0.82))
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        if !field.modules.isEmpty {
                            LazyVGrid(
                                columns: [
                                    GridItem(.adaptive(minimum: 96), spacing: 6)
                                ],
                                alignment: .leading,
                                spacing: 6
                            ) {
                                ForEach(field.modules) { insertedModule in
                                    InsertedTokenChip(
                                        insertedModule: insertedModule
                                    ) {
                                        removeInsertedModule(
                                            insertedModule.id,
                                            from: field.id
                                        )
                                    }
                                }
                            }
                        }
                    }
                    .padding(8)
                    .configurationPanelChrome()
                }
            }

            Button(role: .destructive) {
                deleteCustomField(field.id)
            } label: {
                Image(systemName: "trash.fill")
                    .font(.body.weight(.semibold))
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.borderless)
            .help("删除自定义内容")
        }
        .padding(10)
        .configurationFieldChrome(
            isActive:
                focusedField == .customField(field.id)
        )
    }

    private var moduleInsertionLibrary: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(ModuleChipGroup.allCases) { group in
                VStack(alignment: .leading, spacing: 8) {
                    Text(group.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    LazyVGrid(
                        columns: [
                            GridItem(
                                .adaptive(minimum: 108),
                                spacing: 7
                            )
                        ],
                        alignment: .leading,
                        spacing: 7
                    ) {
                        ForEach(modules(for: group)) { module in
                            Button {
                                insert(module)
                            } label: {
                                ModuleChip(module: module)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var resolvedResult: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(activeSystemFields) { field in
                Text(value(for: field))
                    .font(field.resultFont)
                    .foregroundStyle(field.resultColor)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)
            }

            ForEach(currentCustomFields) { field in
                if !field.displayText.isEmpty {
                    Text(field.displayText)
                        .font(.subheadline)
                        .foregroundStyle(Color.primary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.78)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .configurationPanelChrome()
    }

    private var behaviorSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            InspectorPropertyRow(
                title: "缺省行为",
                value: currentTemplate.fallback,
                systemImage: "arrow.triangle.2.circlepath"
            )

            InspectorPropertyRow(
                title: "显示方式",
                value: currentTemplate.displayBehavior,
                systemImage: "rectangle.compress.vertical"
            )
        }
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

    private func binding(
        for field: MemoryBlockFieldDraft
    ) -> Binding<String> {
        Binding(
            get: {
                value(for: field)
            },
            set: {
                fieldDrafts[field.draftKey] = $0
            }
        )
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

    private func insert(
        _ module: InsertableModuleDraft
    ) {
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

        fields[index].modules.append(
            InsertedModuleDraft(module: module)
        )
        customFields[selectedTemplateID] = fields
        selectedCustomFieldIDs[selectedTemplateID] = fieldID
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
            (fieldValues + customValues)
            .filter {
                !$0.isEmpty
            }
            .joined(separator: " ")

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

    private func modules(
        for group: ModuleChipGroup
    ) -> [InsertableModuleDraft] {
        var modules = group.modules

        if group == .memory {
            modules.append(
                InsertableModuleDraft(
                    title: "智能时间结果",
                    token: "{{smart_time_result}}",
                    systemImage: "calendar.badge.clock",
                    previewValue: smartTimeResult
                )
            )
        }

        return modules
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

private enum BlockFocusedField: Hashable {
    case customField(UUID)
}

private enum BlockInspectorSection: Hashable {
    case configuration
    case system
    case custom
    case library
    case output
    case behavior
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
            title: "配置 1：拍摄参数概要",
            summary: "默认只展示拍摄参数概要，其他信息由用户通过自定义字段补充。",
            fields: [
                .init(
                    templateID: "context.configuration1",
                    key: "cameraParameters",
                    label: "拍摄参数概要",
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
                    label: "拍摄参数概要",
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
            title: "配置 1：当天多大",
            summary: "默认表达记忆对象在照片当天的生命时间，底层保留智能时间计算模块。",
            fields: [
                .init(
                    templateID: "memory.configuration1",
                    key: "subject",
                    label: "对象昵称",
                    defaultValue: "Tutu",
                    source: .memorySubject
                ),
                .init(
                    templateID: "memory.configuration1",
                    key: "action",
                    label: "事件",
                    defaultValue: "当天",
                    source: .fixedText
                ),
                .init(
                    templateID: "memory.configuration1",
                    key: "result",
                    label: "计算结果",
                    defaultValue: "11个月28天",
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

private struct CustomBlockFieldDraft:
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
        let moduleTitles =
            modules
            .map {
                $0.module.previewValue ?? $0.module.title
            }
            .joined(separator: " ")

        if text.isEmpty {
            return moduleTitles
        }

        if moduleTitles.isEmpty {
            return text
        }

        return "\(text) \(moduleTitles)"
    }

    static func defaults(
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

private enum ModuleChipGroup:
    String,
    CaseIterable,
    Identifiable {

    case exif
    case memory
    case system

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .exif:
            return "照片信息"
        case .memory:
            return "记忆"
        case .system:
            return "系统"
        }
    }

    var modules: [InsertableModuleDraft] {
        switch self {
        case .exif:
            return [
                .init(
                    title: "拍摄参数概要",
                    token: "{{capture_parameters_summary}}",
                    systemImage: "camera.metering.center.weighted"
                ),
                .init(
                    title: "设备型号",
                    token: "{{camera_model}}",
                    systemImage: "camera.fill"
                ),
                .init(
                    title: "焦距",
                    token: "{{focal_length}}",
                    systemImage: "scope"
                ),
                .init(
                    title: "光圈",
                    token: "{{aperture}}",
                    systemImage: "camera.aperture"
                ),
                .init(
                    title: "快门速度",
                    token: "{{shutter_speed}}",
                    systemImage: "timer"
                ),
                .init(
                    title: "ISO",
                    token: "{{iso}}",
                    systemImage: "dial.low"
                ),
                .init(
                    title: "拍摄日期",
                    token: "{{capture_date}}",
                    systemImage: "calendar"
                ),
                .init(
                    title: "拍摄时间",
                    token: "{{capture_time}}",
                    systemImage: "clock"
                ),
                .init(
                    title: "位置",
                    token: "{{location}}",
                    systemImage: "location.fill"
                )
            ]
        case .memory:
            return [
                .init(
                    title: "对象昵称",
                    token: "{{subject_nickname}}",
                    systemImage: "person.fill"
                ),
                .init(
                    title: "主要时间",
                    token: "{{primary_anchor}}",
                    systemImage: "flag.fill"
                ),
                .init(
                    title: "年龄结果",
                    token: "{{age_result}}",
                    systemImage: "sparkles"
                ),
                .init(
                    title: "已经过去",
                    token: "{{days_since}}",
                    systemImage: "calendar.badge.clock"
                )
            ]
        case .system:
            return [
                .init(
                    title: "当前日期",
                    token: "{{system_current_date}}",
                    systemImage: "calendar.circle"
                ),
                .init(
                    title: "当前预设",
                    token: "{{preset_name}}",
                    systemImage: "slider.horizontal.3"
                )
            ]
        }
    }
}

private struct InsertableModuleDraft:
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

private struct InsertedModuleDraft:
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

private struct ModuleChip: View {

    let module: InsertableModuleDraft

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: module.systemImage)
                .font(.caption2.weight(.semibold))

            Text(module.title)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(Color.accentColor)
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.accentColor.opacity(0.085))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.accentColor.opacity(0.16))
        )
    }
}

private struct InsertedTokenChip: View {

    let insertedModule: InsertedModuleDraft
    let onDelete: () -> Void

    var body: some View {
        let module = insertedModule.module

        HStack(spacing: 5) {
            Image(systemName: module.systemImage)
                .font(.caption2.weight(.semibold))

            Text(module.title)
                .font(.caption.weight(.medium))
                .lineLimit(1)

            if let previewValue = module.previewValue {
                Text(previewValue)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Button {
                onDelete()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("移除此模块")
        }
        .foregroundStyle(Color.primary.opacity(0.78))
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(ConfigurationUI.controlBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(ConfigurationUI.hairline)
        )
        .accessibilityLabel(module.title)
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
