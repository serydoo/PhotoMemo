#if !MEMOMARK_SHARE_EXTENSION
import SwiftUI
#if canImport(PhotosUI)
import PhotosUI
#endif
#if os(macOS)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

@MainActor
struct MemorySubjectEditorView: View {

    enum Mode {
        case full
        case identityOverview
        case timeAnchors
    }

    @ObservedObject
    var session: ConfigurationSession

    private let mode: Mode

    private let identityOverviewAccessory: AnyView?

    @State
    private var editingDraft = MemorySubjectEditingDraft()

    @State
    private var avatarDraft = SubjectAvatarEditingDraft()

    @State
    private var editingTimeAnchorID: UUID?

    @State
    private var timeAnchorEditingTransaction:
        TimeAnchorEditingTransaction?

    @State
    private var avatarOptimizationState = SubjectAvatarOptimizationState()

#if canImport(PhotosUI)
    @State
    private var selectedAvatarItem: PhotosPickerItem?
#endif

#if canImport(UIKit)
    @State
    private var pendingAvatarCropDraft: SubjectAvatarCropDraft?
#endif

    @FocusState
    private var focusedField: SubjectFocusedField?

    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize

    private let avatarOptimizer:
        any SubjectAvatarAssetOptimizing

    init(
        session: ConfigurationSession,
        mode: Mode = .full,
        avatarOptimizer:
            any SubjectAvatarAssetOptimizing =
                SubjectAvatarAssetOptimizationService()
    ) {
        self.session = session
        self.mode = mode
        self.identityOverviewAccessory = nil
        self.avatarOptimizer = avatarOptimizer
    }

    init<IdentityOverviewAccessory: View>(
        session: ConfigurationSession,
        mode: Mode = .identityOverview,
        avatarOptimizer:
            any SubjectAvatarAssetOptimizing =
                SubjectAvatarAssetOptimizationService(),
        @ViewBuilder identityOverviewAccessory: () -> IdentityOverviewAccessory
    ) {
        self.session = session
        self.mode = mode
        self.identityOverviewAccessory =
            AnyView(identityOverviewAccessory())
        self.avatarOptimizer = avatarOptimizer
    }

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: mode == .full ? 26 : 14
        ) {
            if session.state.selectedSubject != nil {
                switch mode {
                case .full:
                    InspectorSectionView(
                        "记忆对象资料",
                        systemImage: "person.fill"
                    ) {
                        identityEditor
                    }

                    InspectorSectionView(
                        "锚点维护",
                        systemImage: "calendar.badge.clock"
                    ) {
                        timeWindowEditor
                    }

                case .identityOverview:
                    identityOverviewEditor

                case .timeAnchors:
                    timeAnchorListEditor
                }
            }
        }
        .onAppear {
            loadDrafts()
        }
        .onTapGesture {
            focusedField = nil
        }
        .onChange(
            of: session.state.selectedSubject?.id
        ) { _, _ in
            invalidateAvatarOptimization()
            loadDrafts()
        }
        .onChange(of: editingDraft.displayName) { _, _ in
            syncDraftToSession()
        }
        .onChange(of: editingDraft.shortName) { _, _ in
            syncDraftToSession()
        }
        .onChange(of: editingDraft.relationshipRole) { _, _ in
            syncDraftToSession()
        }
        .onChange(of: editingDraft.relationshipLabel) { _, _ in
            syncDraftToSession()
        }
        .onChange(of: editingDraft.expressionSubjectSource) { _, _ in
            syncDraftToSession()
        }
        .onChange(of: editingDraft.definition) { _, _ in
            syncDraftToSession()
        }
        .onChange(of: editingDraft.selectedTimeAnchorID) { _, _ in
            syncDraftToSession()
        }
        .onChange(of: editingDraft.timeAnchors) { _, _ in
            syncDraftToSession()
        }
#if canImport(PhotosUI)
        .onChange(of: selectedAvatarItem) { _, item in
            guard let item else {
                return
            }

            guard let subjectID = session.state.selectedSubject?.id else {
                selectedAvatarItem = nil
                return
            }

            let context = avatarOptimizationState.begin(
                subjectID: subjectID
            )

            Task {
                await prepareSelectedAvatar(
                    item,
                    context: context
                )
            }
        }
#endif
#if canImport(UIKit)
        .fullScreenCover(item: $pendingAvatarCropDraft) { draft in
            SubjectAvatarCropSheet(
                image: draft.image,
                onCancel: {
                    pendingAvatarCropDraft = nil
                    guard avatarOptimizationState.activeRequest != nil else {
                        return
                    }
                    avatarOptimizationState.invalidate()
                    avatarDraft.restore(
                        displayImagePath: avatarDraft.displayImagePath,
                        badgeImagePath: avatarDraft.badgeImagePath,
                        previewImagePath: avatarDraft.previewImagePath
                    )
                },
                onConfirm: { configuration in
                    pendingAvatarCropDraft = nil

                    guard let context = avatarOptimizationState.activeRequest else {
                        return
                    }

                    Task {
                        await applyAvatarCrop(
                            data: draft.data,
                            configuration: configuration,
                            context: context
                        )
                    }
                }
            )
        }
#endif
    }

    private var identityEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("在这里维护记忆对象的头像、名称和关系资料。这些内容会同步影响配置中心摘要、对象入口和锚点表达主体。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            identitySnapshotCard
            avatarEditor
            identityFieldsPanel

            if !hasValidObjectName {
                Text("对象名称不能为空")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .accessibilityLabel(Text(
                        MemoMarkLanguage.interfaceStored.localized(
                            key: "accessibility.object_name_required",
                            fallback: "Object name is required"
                        )
                    ))
            }
        }
    }

    private var identityOverviewEditor: some View {
        VStack(alignment: .leading, spacing: 14) {
            contactAvatarEditor
                .frame(maxWidth: .infinity, alignment: .center)

            if let identityOverviewAccessory {
                identityOverviewAccessory
            }

            identityOverviewFieldsGroup
        }
    }

    private var identityOverviewFieldsGroup: some View {
        VStack(spacing: 0) {
            expressionSubjectCard

            HorizontalDivider(horizontalInset: 12)

            compactIdentityFieldsPanel
        }
        .groupedSurface()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("subject-identity-fields-group")
    }

    @ViewBuilder
    private var contactAvatarEditor: some View {
#if canImport(PhotosUI)
        SubjectAvatarContactEditorSurface(
            draft: avatarDraft,
            isOptimizing: isOptimizingAvatar,
            selectedAvatarItem: $selectedAvatarItem,
            onRemove: removeAvatarFromDraft
        )
#else
        subjectAvatarPreview(size: 112)
#endif
    }

    private var expressionSubjectCard: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 6) {
                    expressionSubjectTitle
                    expressionSubjectMenu
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                HStack(alignment: .center, spacing: 12) {
                    expressionSubjectTitle

                    Spacer(minLength: 12)

                    expressionSubjectMenu
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .frame(
            maxWidth: .infinity,
            minHeight: ConfigurationUI.minimumInteractiveHeight,
            alignment: .leading
        )
    }

    private var expressionSubjectTitle: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("照片中的称呼")
                .font(.body)
                .foregroundStyle(.primary)

            Text("选择照片里怎样称呼这个人。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var expressionSubjectMenu: some View {
        Menu {
            ForEach(
                MemorySubjectExpressionSubjectSource.allCases
            ) { source in
                Button {
                    editingDraft.expressionSubjectSource = source
                } label: {
                    Label(
                        expressionSubjectMenuOptionTitle(for: source),
                        systemImage:
                            source == expressionSubjectResolution.source
                            ? "checkmark"
                            : expressionSubjectSourceIcon(for: source)
                    )
                    .accessibilityLabel(
                        "\(source.displayTitle)，\(expressionSubjectSourceValue(for: source) ?? "未填写")"
                    )
                }
                .disabled(expressionSubjectSourceValue(for: source) == nil)
            }
        } label: {
            expressionSubjectSelectionLabel
        }
        .buttonStyle(.plain)
        .accessibilityLabel("选择照片中的称呼")
        .accessibilityValue(expressionSubjectSelectionTitle)
    }

    private var expressionSubjectSelectionLabel: some View {
        HStack(spacing: 6) {
            Text(expressionSubjectSelectionTitle)
                .font(.subheadline)
                .foregroundStyle(Color.accentColor)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                .multilineTextAlignment(.trailing)

            Image(systemName: "chevron.up.chevron.down")
                .font(.caption2.weight(.bold))
                .foregroundStyle(Color.accentColor)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .frame(minHeight: ConfigurationUI.minimumInteractiveHeight)
        .contentShape(Rectangle())
    }

    private var expressionSubjectSelectionTitle: String {
        guard let source = expressionSubjectResolution.source else {
            return "默认 · 对象名称"
        }

        if source == .displayName {
            return "默认 · 对象名称"
        }

        return source.displayTitle
    }

    private var compactIdentityFieldsPanel: some View {
        VStack(spacing: 0) {
            contactTextField(
                "对象名称",
                text: $editingDraft.displayName,
                focus: .displayName,
                placeholder: "请输入对象名称",
                isRequired: true
            )

            contactDivider

            contactTextField(
                "昵称",
                text: $editingDraft.shortName,
                focus: .shortName,
                placeholder: "选填"
            )

            contactDivider

            contactTextField(
                "与我的关系",
                text: $editingDraft.relationshipRole,
                focus: .relationshipRole,
                placeholder: "选填"
            )

            contactDivider

            contactTextField(
                "专属称呼",
                text: $editingDraft.relationshipLabel,
                focus: .relationshipLabel,
                placeholder: "选填"
            )
        }
    }

    private func contactTextField(
        _ title: String,
        text: Binding<String>,
        focus: SubjectFocusedField,
        placeholder: String,
        isRequired: Bool = false
    ) -> some View {
        HStack(spacing: 8) {
            contactFieldPrompt(
                title: title,
                isRequired: isRequired
            )
            .frame(width: 104, alignment: .leading)

            TextField(placeholder, text: text)
                .textFieldStyle(.plain)
                .font(.body)
                .focused($focusedField, equals: focus)
                .submitLabel(
                    focus == .relationshipLabel
                    ? .done
                    : .next
                )
                .onSubmit {
                    advanceIdentityFocus(from: focus)
                }
                .accessibilityLabel(
                    isRequired ? "\(title)，必填" : title
                )
                .accessibilityIdentifier(
                    identityFieldAccessibilityIdentifier(for: title)
                )

            if !text.wrappedValue.isEmpty {
                Button {
                    text.wrappedValue = ""
                    focusedField = focus
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(
                            width: ConfigurationUI.minimumInteractiveHeight,
                            height: ConfigurationUI.minimumInteractiveHeight
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(
                    String(
                        format: MemoMarkLanguage.interfaceStored.localized(
                            key: "accessibility.clear_format",
                            fallback: "Clear %@"
                        ),
                        title
                    )
                ))
            }
        }
        .padding(.horizontal, 12)
        .frame(minHeight: SubjectIdentityMetrics.contactFieldRowHeight)
        .contentShape(Rectangle())
    }

    private func contactFieldPrompt(
        title: String,
        isRequired: Bool
    ) -> some View {
        HStack(spacing: 2) {
            Text(title)
                .font(.body)
                .foregroundStyle(.secondary)

            if isRequired {
                Text("*")
                    .foregroundStyle(.red)
            }
        }
    }

    private func identityFieldAccessibilityIdentifier(
        for title: String
    ) -> String {
        switch title {
        case "对象名称", "显示名称":
            return "subject-field-display-name"
        case "昵称":
            return "subject-field-short-name"
        case "与我的关系", "关系":
            return "subject-field-relationship-role"
        case "专属称呼", "关系备注":
            return "subject-field-relationship-label"
        default:
            return "subject-field-\(title)"
        }
    }

    private var expressionSubjectDisplayValue: String {
        expressionSubjectResolution.text
    }

    private var expressionSubjectDisplaySourceTitle: String {
        expressionSubjectResolution.source?.displayTitle
        ?? "默认称呼"
    }

    private var expressionSubjectResolution:
        MemorySubjectExpressionSubjectResolution {
        MemorySubject.resolveExpressionSubject(
            source: editingDraft.expressionSubjectSource,
            displayName: editingDraft.displayName,
            shortName: editingDraft.shortName,
            relationshipRole: editingDraft.relationshipRole,
            relationshipLabel: editingDraft.relationshipLabel
        )
    }

    private func expressionSubjectSourceValue(
        for source: MemorySubjectExpressionSubjectSource
    ) -> String? {
        switch source {
        case .displayName:
            return normalizedInlineValue(editingDraft.displayName)
        case .shortName:
            return normalizedInlineValue(editingDraft.shortName)
        case .relationshipRole:
            return normalizedInlineValue(editingDraft.relationshipRole)
        case .relationshipLabel:
            return normalizedInlineValue(editingDraft.relationshipLabel)
        }
    }

    private func expressionSubjectMenuOptionTitle(
        for source: MemorySubjectExpressionSubjectSource
    ) -> String {
        let value = expressionSubjectSourceValue(for: source) ?? "未填写"
        return "\(source.displayTitle)    \(value)"
    }

    private func expressionSubjectSourceIcon(
        for source: MemorySubjectExpressionSubjectSource
    ) -> String {
        switch source {
        case .displayName:
            return "person"
        case .shortName:
            return "text.quote"
        case .relationshipRole:
            return "person.2"
        case .relationshipLabel:
            return "heart.text.square"
        }
    }

    private func normalizedInlineValue(
        _ text: String
    ) -> String? {
        let trimmed =
            text.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return trimmed.isEmpty ? nil : trimmed
    }

    private func advanceIdentityFocus(
        from focus: SubjectFocusedField
    ) {
        switch focus {
        case .displayName:
            focusedField = .shortName
        case .shortName:
            focusedField = .relationshipRole
        case .relationshipRole:
            focusedField = .relationshipLabel
        case .relationshipLabel:
            focusedField = nil
        default:
            focusedField = nil
        }
    }

    private var identitySnapshotCard: some View {
        HStack(alignment: .center, spacing: 14) {
            subjectAvatarPreview
                .frame(width: 72, height: 72)

            VStack(alignment: .leading, spacing: 8) {
                Text(editingDraft.displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "记忆对象" : editingDraft.displayName)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)

                identitySummaryChips
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(
                cornerRadius: 16,
                style: .continuous
            )
            .fill(ConfigurationUI.controlBackground.opacity(0.72))
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 16,
                style: .continuous
            )
            .stroke(ConfigurationUI.faintHairline)
        )
    }

    private var identitySummaryChips: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                shortNameSummaryChip
                relationshipSummaryChip
            }

            VStack(alignment: .leading, spacing: 8) {
                shortNameSummaryChip
                relationshipSummaryChip
            }
        }
    }

    private var shortNameSummaryChip: some View {
        identitySummaryChip(
            title:
                editingDraft.shortName
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .isEmpty
                ? "未设昵称"
                : editingDraft.shortName,
            systemImage: "person.text.rectangle"
        )
    }

    private var relationshipSummaryChip: some View {
        identitySummaryChip(
            title:
                editingDraft.relationshipLabel
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .isEmpty
                ? "未设关系"
                : editingDraft.relationshipLabel,
            systemImage: "person.2.fill"
        )
    }

    private var avatarEditor: some View {
#if canImport(PhotosUI)
        SubjectAvatarDetailedEditorSurface(
            draft: avatarDraft,
            isOptimizing: isOptimizingAvatar,
            selectedAvatarItem: $selectedAvatarItem
        )
#else
        SubjectAvatarDetailedEditorSurface(
            draft: avatarDraft,
            isOptimizing: isOptimizingAvatar
        )
#endif
    }

    private var identityFieldsPanel: some View {
        VStack(spacing: 0) {
            labeledTextField(
                "显示名称",
                text: $editingDraft.displayName,
                systemImage: "person.text.rectangle",
                focus: .displayName,
                subjectSource: .displayName
            )

            fieldDivider

            labeledTextField(
                "昵称",
                text: $editingDraft.shortName,
                systemImage: "person.crop.circle",
                focus: .shortName,
                subjectSource: .shortName
            )

            fieldDivider

            labeledTextField(
                "关系",
                text: $editingDraft.relationshipRole,
                systemImage: "person.2.fill",
                focus: .relationshipRole,
                subjectSource: .relationshipRole
            )

            fieldDivider

            labeledTextField(
                "关系备注",
                text: $editingDraft.relationshipLabel,
                systemImage: "heart.text.square",
                focus: .relationshipLabel,
                subjectSource: .relationshipLabel
            )
        }
        .padding(.vertical, 4)
        .background(ConfigurationUI.controlBackground)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
            .stroke(ConfigurationUI.faintHairline)
        )
    }

    private var timeWindowEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            if editingDraft.timeAnchors.isEmpty {
                Text("暂无时间锚点。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                SubjectTimeAnchorSelectionCard(
                    anchors: editingDraft.timeAnchors,
                    editingAnchorID: editingTimeAnchorID,
                    onConfigure: openTimeAnchorSheet,
                    onDelete: deleteTimeAnchor,
                    onAdd: addTimeAnchor
                )
            }

            Text("点击操作按钮，或左滑可配置或删除；最多 5 个，至少保留 1 个。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .sheet(
            isPresented:
                Binding(
                    get: {
                        editingTimeAnchorID != nil
                    },
                    set: { isPresented in
                        if !isPresented {
                            cancelEditingTimeAnchor()
                        }
                    }
                )
        ) {
            timeAnchorConfigurationSheet
        }
    }

    private var timeAnchorListEditor: some View {
        List {
            Section {
                ForEach(editingDraft.timeAnchors) { anchor in
                    SubjectTimeAnchorRow(
                        anchor: anchor,
                        isEditing:
                            anchor.id == editingTimeAnchorID,
                        canDelete:
                            editingDraft.timeAnchors.count
                                > MemorySubjectEditingDraft.minimumTimeAnchorCount,
                        onConfigure: {
                            openTimeAnchorSheet(anchor.id)
                        },
                        onDelete: {
                            deleteTimeAnchor(anchor.id)
                        }
                    )
                    .listRowInsets(
                        EdgeInsets(
                            top: 0,
                            leading: 0,
                            bottom: 0,
                            trailing: 0
                        )
                    )
                }

                if editingDraft.timeAnchors.count
                    < MemorySubjectEditingDraft.maximumTimeAnchorCount {
                    SubjectTimeAnchorAddRow(
                        onAdd: addTimeAnchor
                    )
                        .listRowInsets(
                            EdgeInsets(
                                top: 0,
                                leading: 0,
                                bottom: 0,
                                trailing: 0
                            )
                        )
                }
            } footer: {
                Text("左滑可配置或删除；最多 5 个，至少保留 1 个。")
            }
        }
#if os(iOS)
        .listStyle(.insetGrouped)
#else
        .listStyle(.inset)
#endif
        .scrollContentBackground(.hidden)
        .background(ConfigurationUI.appBackground)
        .sheet(
            isPresented:
                Binding(
                    get: {
                        editingTimeAnchorID != nil
                    },
                    set: { isPresented in
                        if !isPresented {
                            cancelEditingTimeAnchor()
                        }
                    }
                )
        ) {
            timeAnchorConfigurationSheet
        }
    }

    private var anchorBinding: Binding<MemorySubject.TimeAnchor>? {
        guard
            let editingAnchorID,
            let index = editingDraft.timeAnchors.firstIndex(
                where: { $0.id == editingAnchorID }
            )
        else {
            return nil
        }

        return $editingDraft.timeAnchors[index]
    }

    private var editingAnchorID: UUID? {
        editingTimeAnchorID
    }

    @ViewBuilder
    private var timeAnchorConfigurationSheet: some View {
        if let anchorBinding {
            NavigationStack {
                Form {
                    Section("锚点日期") {
                        CompactAnchorDatePicker(
                            selection: anchorBinding.date
                        )
                    }

                    Section {
                        Picker(
                            "锚点类型",
                            selection: Binding(
                                get: {
                                    anchorBinding.wrappedValue.resolvedAnchorType
                                },
                                set: { newType in
                                    anchorBinding.wrappedValue.anchorType = newType
                                    anchorBinding.wrappedValue.expressionStyle =
                                        .defaultStyle(for: newType)
                                }
                            )
                        ) {
                            ForEach(AnchorType.allCases, id: \.self) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                    }

                    Section {
                        TextField(
                            "输入锚点名称",
                            text: anchorBinding.title
                        )
                        .focused($focusedField, equals: .timeTitle)
                        .submitLabel(.done)
                    } header: {
                        Text("自定义锚点名称")
                    } footer: {
                        Text("修改会实时显示在预览中；完成后保留，取消则恢复原值。")
                    }
                }
                .navigationTitle(timeAnchorSheetTitle)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("取消") {
                            cancelEditingTimeAnchor()
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("完成") {
                            saveEditingTimeAnchor()
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
            .presentationDetents([.fraction(0.70), .large])
            .presentationDragIndicator(.visible)
            .presentationBackgroundInteraction(.disabled)
        } else {
            EmptyView()
        }
    }

    private var timeAnchorSheetTitle: String {
        timeAnchorEditingTransaction?.isNewAnchor == true
        ? "新增时间锚点"
        : "编辑时间锚点"
    }

    private func openTimeAnchorSheet(
        _ anchorID: UUID
    ) {
        guard let anchor = editingDraft.timeAnchors.first(where: { $0.id == anchorID }) else {
            return
        }
        timeAnchorEditingTransaction =
            TimeAnchorEditingTransaction(
                anchorID: anchorID,
                originalAnchor: anchor,
                originalSelectedAnchorID: editingDraft.selectedTimeAnchorID
            )
        editingTimeAnchorID = anchorID
    }

    private func addTimeAnchor() {
        guard let anchorID = editingDraft.appendTimeAnchor() else {
            return
        }
        let anchor = editingDraft.timeAnchors.first {
            $0.id == anchorID
        }
        guard let anchor else {
            return
        }
        timeAnchorEditingTransaction =
            TimeAnchorEditingTransaction(
                anchorID: anchor.id,
                originalAnchor: nil,
                originalSelectedAnchorID: editingDraft.selectedTimeAnchorID
            )
        editingTimeAnchorID = anchor.id
        syncDraftToSession()
    }

    private func deleteTimeAnchor(
        _ anchorID: UUID
    ) {
        guard editingDraft.removeTimeAnchor(id: anchorID) else {
            return
        }

        if editingTimeAnchorID == anchorID {
            editingTimeAnchorID = nil
        }

        syncDraftToSession()
    }

    private func saveEditingTimeAnchor() {
        syncDraftToSession()
        timeAnchorEditingTransaction = nil
        editingTimeAnchorID = nil
        focusedField = nil
    }

    private func cancelEditingTimeAnchor() {
        guard let transaction = timeAnchorEditingTransaction else {
            editingTimeAnchorID = nil
            focusedField = nil
            return
        }

        let rollback = transaction.rollback(
            anchors: editingDraft.timeAnchors,
            selectedAnchorID: editingDraft.selectedTimeAnchorID
        )
        editingDraft.timeAnchors = rollback.anchors
        editingDraft.selectedTimeAnchorID = rollback.selectedAnchorID

        timeAnchorEditingTransaction = nil
        editingTimeAnchorID = nil
        focusedField = nil
        syncDraftToSession()
    }

    private func labeledTextField(
        _ title: String,
        text: Binding<String>,
        systemImage: String,
        focus: SubjectFocusedField,
        subjectSource: MemorySubjectExpressionSubjectSource? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 7) {
                Image(systemName: systemImage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 15)

                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)

                if let subjectSource {
                    Button {
                        editingDraft.expressionSubjectSource =
                            subjectSource
                    } label: {
                        Label(
                            editingDraft.expressionSubjectSource
                                == subjectSource
                            ? "主体已生效"
                            : "设为主体",
                            systemImage:
                                editingDraft.expressionSubjectSource
                                == subjectSource
                                ? "checkmark.circle.fill"
                                : "circle"
                        )
                        .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(
                        editingDraft.expressionSubjectSource
                            == subjectSource
                        ? Color.accentColor
                        : .secondary
                    )
                }
            }

            TextField(title, text: text)
                .textFieldStyle(.plain)
                .font(.subheadline)
                .focused($focusedField, equals: focus)
                .accessibilityLabel(title)
                .accessibilityIdentifier(
                    identityFieldAccessibilityIdentifier(for: title)
                )
                .configurationFieldChrome(
                    isActive: focusedField == focus
                )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private func loadDrafts() {
        guard let subject = session.state.selectedSubject else {
            return
        }

        let normalizedTimeAnchors = MemorySubjectEditingDraft.defaultedTimeAnchors(
            for: subject
        ).map {
            $0.normalizedForEditing
        }
        editingDraft = MemorySubjectEditingDraft(
            subject: subject,
            timeAnchors: normalizedTimeAnchors
        )
        avatarDraft.restore(
            displayImagePath: subject.identity.avatarImagePath,
            badgeImagePath: subject.identity.avatarBadgeImagePath,
            previewImagePath: subject.identity.avatarPreviewImagePath
        )
        editingTimeAnchorID = nil
    }

    @MainActor
    private func invalidateAvatarOptimization() {
        avatarOptimizationState.invalidate()
#if canImport(UIKit)
        pendingAvatarCropDraft = nil
#endif
#if canImport(PhotosUI)
        selectedAvatarItem = nil
#endif
    }

    @MainActor
    private func isCurrentAvatarOptimization(
        _ context: SubjectAvatarOptimizationRequest
    ) -> Bool {
        guard let subjectID = session.state.selectedSubject?.id else {
            return false
        }
        return avatarOptimizationState.isCurrent(
            context,
            subjectID: subjectID
        )
    }

    private func syncDraftToSession(
        _ subject: MemorySubject? = nil
    ) {
        guard
            var updated = subject ?? session.state.selectedSubject
        else {
            return
        }

        // The full Configuration Center writes directly to the live session.
        // Keep its last valid identity intact while the user replaces the name.
        guard mode != .full || hasValidObjectName else {
            return
        }

        avatarDraft.applying(to: &updated.identity)
        editingDraft.applyingCoreFields(to: &updated)

        session.updateSelectedSubject(updated)
    }

    private var hasValidObjectName: Bool {
        !editingDraft.displayName
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .isEmpty
    }

    private var isOptimizingAvatar: Bool {
        avatarOptimizationState.isOptimizing
    }

    private var hasAvatar: Bool { avatarDraft.hasAvatar }

    private func removeAvatarFromDraft() {
        invalidateAvatarOptimization()
        guard var identity = session.state.selectedSubject?.identity else {
            return
        }

        identity.removeAvatarAssets()
        avatarDraft.restore(
            displayImagePath: identity.avatarImagePath,
            badgeImagePath: identity.avatarBadgeImagePath,
            previewImagePath: identity.avatarPreviewImagePath
        )
#if canImport(PhotosUI)
        selectedAvatarItem = nil
#endif
        syncDraftToSession()
    }

    private var subjectAvatarPreview: some View {
        subjectAvatarPreview(size: 64)
    }

    private func subjectAvatarPreview(
        size: CGFloat
    ) -> some View {
        SubjectAvatarPreview(
            path: avatarDraft.previewPath,
            size: size
        )
    }

    private func identitySummaryChip(
        title: String,
        systemImage: String
    ) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.primary.opacity(0.82))
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                Capsule(style: .continuous)
                    .fill(ConfigurationUI.controlBackground)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(ConfigurationUI.faintHairline)
            )
    }

    private func anchorMetaChip(
        title: String,
        systemImage: String
    ) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.primary.opacity(0.82))
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                Capsule(style: .continuous)
                    .fill(ConfigurationUI.controlBackground)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(ConfigurationUI.faintHairline)
            )
    }

    private func iconName(
        for anchorType: AnchorType
    ) -> String {
        switch anchorType {
        case .birthday:
            return "birthday.cake.fill"
        case .relationship:
            return "heart.fill"
        case .marriage:
            return "sparkles"
        case .exam:
            return "flag.checkered"
        case .custom:
            return "calendar"
        }
    }

    private var fieldDivider: some View {
        Rectangle()
            .fill(ConfigurationUI.faintHairline)
            .frame(height: 0.5)
            .padding(.leading, 54)
    }

    private var contactDivider: some View {
        Rectangle()
            .fill(ConfigurationUI.faintHairline)
            .frame(height: 0.5)
            .padding(.leading, 12)
    }

#if canImport(PhotosUI)
    @MainActor
    private func prepareSelectedAvatar(
        _ item: PhotosPickerItem,
        context: SubjectAvatarOptimizationRequest
    ) async {
        guard isCurrentAvatarOptimization(context) else {
            return
        }
        avatarOptimizationState.markOptimizing(context)
        avatarDraft.statusMessage = "正在载入对象头像"

        do {
            guard
                let data =
                    try await item.loadTransferable(
                        type: Data.self
                    )
            else {
                throw SubjectAvatarAssetOptimizationError.invalidImage
            }

            guard isCurrentAvatarOptimization(context) else {
                return
            }

#if canImport(UIKit)
            guard let image = UIImage(data: data) else {
                throw SubjectAvatarAssetOptimizationError.invalidImage
            }

            pendingAvatarCropDraft =
                SubjectAvatarCropDraft(
                    data: data,
                    image: image
                )
            avatarDraft.statusMessage = "调整头像位置后再应用。"
            selectedAvatarItem = nil
            avatarOptimizationState.markReadyForCrop(context)
#else
            await applyAvatarCrop(
                data: data,
                configuration: .init(),
                context: context
            )
#endif
        } catch {
            guard isCurrentAvatarOptimization(context) else {
                return
            }
            selectedAvatarItem = nil
            avatarOptimizationState.finish(context)
            avatarDraft.statusMessage = error.localizedDescription
        }
    }
#endif

    @MainActor
    private func applyAvatarCrop(
        data: Data,
        configuration: SubjectAvatarCropConfiguration,
        context: SubjectAvatarOptimizationRequest
    ) async {
        guard isCurrentAvatarOptimization(context) else {
            return
        }
        avatarOptimizationState.markOptimizing(context)
        avatarDraft.statusMessage = "正在优化对象头像"

        do {
            let optimizedAsset =
                try await avatarOptimizer.optimize(
                    data: data,
                    cropConfiguration: configuration
                )

            guard isCurrentAvatarOptimization(context) else {
                SubjectAvatarAssetOptimizationService
                    .discardUncommittedAssets(
                        atPaths: [
                            optimizedAsset.displayImagePath,
                            optimizedAsset.badgeImagePath,
                            optimizedAsset.previewImagePath
                        ]
                    )
                return
            }

            avatarDraft.applyOptimizedPaths(
                displayImagePath: optimizedAsset.displayImagePath,
                badgeImagePath: optimizedAsset.badgeImagePath,
                previewImagePath: optimizedAsset.previewImagePath
            )
            syncDraftToSession()
        } catch {
            guard isCurrentAvatarOptimization(context) else {
                return
            }
            avatarDraft.statusMessage =
                error.localizedDescription
        }

        guard isCurrentAvatarOptimization(context) else {
            return
        }
        avatarOptimizationState.finish(context)
    }
}

private enum SubjectIdentityMetrics {

    static let contactFieldRowHeight =
        ConfigurationUI.compactInputRowMinimumHeight
}

private enum SubjectFocusedField: Hashable {
    case displayName
    case shortName
    case relationshipRole
    case relationshipLabel
    case definition
    case timeTitle
    case timeNote
}

#endif
