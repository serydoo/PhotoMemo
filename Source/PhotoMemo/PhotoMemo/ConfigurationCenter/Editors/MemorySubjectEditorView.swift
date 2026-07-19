#if !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI
#if canImport(PhotosUI)
import PhotosUI
#endif
#if os(macOS)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

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
    private var displayName = ""

    @State
    private var shortName = ""

    @State
    private var relationshipRole = ""

    @State
    private var relationshipLabel = ""

    @State
    private var avatarImagePath: String?

    @State
    private var avatarBadgeImagePath: String?

    @State
    private var avatarPreviewImagePath: String?

    @State
    private var avatarStatusMessage = "可选择对象头像，用于头像、标识与预览。"

    @State
    private var definition = ""

    @State
    private var timeAnchors: [MemorySubject.TimeAnchor] = []

    @State
    private var expressionSubjectSource:
        MemorySubjectExpressionSubjectSource = .displayName

    @State
    private var selectedTimeAnchorID: UUID?

    @State
    private var editingTimeAnchorID: UUID?

    @State
    private var timeAnchorEditingTransaction:
        TimeAnchorEditingTransaction?

    @State
    private var isOptimizingAvatar = false

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

    private let avatarOptimizer =
        SubjectAvatarAssetOptimizationService()

    init(
        session: ConfigurationSession,
        mode: Mode = .full
    ) {
        self.session = session
        self.mode = mode
        self.identityOverviewAccessory = nil
    }

    init<IdentityOverviewAccessory: View>(
        session: ConfigurationSession,
        mode: Mode = .identityOverview,
        @ViewBuilder identityOverviewAccessory: () -> IdentityOverviewAccessory
    ) {
        self.session = session
        self.mode = mode
        self.identityOverviewAccessory =
            AnyView(identityOverviewAccessory())
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
            loadDrafts()
        }
        .onChange(of: displayName) { _, _ in
            syncDraftToSession()
        }
        .onChange(of: shortName) { _, _ in
            syncDraftToSession()
        }
        .onChange(of: relationshipRole) { _, _ in
            syncDraftToSession()
        }
        .onChange(of: relationshipLabel) { _, _ in
            syncDraftToSession()
        }
        .onChange(of: expressionSubjectSource) { _, _ in
            syncDraftToSession()
        }
        .onChange(of: definition) { _, _ in
            syncDraftToSession()
        }
        .onChange(of: selectedTimeAnchorID) { _, _ in
            syncDraftToSession()
        }
        .onChange(of: timeAnchors) { _, _ in
            syncDraftToSession()
        }
#if canImport(PhotosUI)
        .onChange(of: selectedAvatarItem) { _, item in
            guard let item else {
                return
            }

            Task {
                await prepareSelectedAvatar(item)
            }
        }
#endif
#if canImport(UIKit)
        .sheet(item: $pendingAvatarCropDraft) { draft in
            SubjectAvatarCropSheet(
                image: draft.image,
                onCancel: {
                    pendingAvatarCropDraft = nil
                    avatarStatusMessage = normalizedAvatarStatusMessage(
                        from: avatarImagePath
                    )
                },
                onConfirm: { configuration in
                    pendingAvatarCropDraft = nil

                    Task {
                        await applyAvatarCrop(
                            data: draft.data,
                            configuration: configuration
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
        }
    }

    private var identityOverviewEditor: some View {
        VStack(alignment: .leading, spacing: 10) {
            adaptiveIdentityOverviewHeader

            if let identityOverviewAccessory {
                identityOverviewAccessory
            }

            compactIdentityFieldsPanel
        }
    }

    private var adaptiveIdentityOverviewHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: 14) {
                    identityOverviewText
                    compactAvatarPicker
                }

                VStack(alignment: .leading, spacing: 12) {
                    identityOverviewText
                    compactAvatarPicker
                }
            }

            expressionSubjectMenuRow
        }
    }

    private var identityOverviewText: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(
                displayName
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                    .isEmpty
                ? "记忆对象"
                : displayName
            )
            .font(.title2.weight(.semibold))
            .foregroundStyle(.primary)
            .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var expressionSubjectMenuRow: some View {
        Menu {
            ForEach(
                MemorySubjectExpressionSubjectSource.allCases
            ) { source in
                Button {
                    expressionSubjectSource = source
                } label: {
                    Label(
                        expressionSubjectMenuOptionTitle(for: source),
                        systemImage:
                            source == expressionSubjectResolution.source
                            ? "checkmark"
                            : expressionSubjectSourceIcon(for: source)
                    )
                }
                .disabled(expressionSubjectSourceValue(for: source) == nil)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "person.text.rectangle")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(Color.accentColor.opacity(0.11))
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text("表达称呼")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)

                    if dynamicTypeSize.isAccessibilitySize {
                        VStack(alignment: .leading, spacing: 2) {
                            expressionSubjectValueText
                            expressionSubjectSourceText
                        }
                    } else {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            expressionSubjectValueText
                            expressionSubjectSourceText
                        }
                        .lineLimit(1)
                        .truncationMode(.tail)
                    }
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, minHeight: 62)
            .background(
                RoundedRectangle(
                    cornerRadius: 12,
                    style: .continuous
                )
                .fill(ConfigurationUI.selectedBackground)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("选择表达称呼")
        .accessibilityValue(
            "\(expressionSubjectDisplayValue)，来自\(expressionSubjectDisplaySourceTitle)"
        )
    }

    private var expressionSubjectValueText: some View {
        Text(expressionSubjectDisplayValue)
            .font(.body.weight(.semibold))
            .foregroundStyle(.primary)
            .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
    }

    private var expressionSubjectSourceText: some View {
        Text("· 来自“\(expressionSubjectDisplaySourceTitle)”")
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
    }

    private var compactIdentityFieldsPanel: some View {
        VStack(spacing: 0) {
            compactLabeledTextField(
                "对象名称",
                text: $displayName,
                focus: .displayName
            )

            compactDivider

            compactLabeledTextField(
                "昵称",
                text: $shortName,
                focus: .shortName
            )

            compactDivider

            compactLabeledTextField(
                "与我的关系",
                text: $relationshipRole,
                focus: .relationshipRole
            )

            compactDivider

            compactLabeledTextField(
                "专属称呼",
                text: $relationshipLabel,
                focus: .relationshipLabel
            )
        }
        .padding(.vertical, 2)
    }

    private func compactLabeledTextField(
        _ title: String,
        text: Binding<String>,
        focus: SubjectFocusedField
    ) -> some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.body)
                        .foregroundStyle(.primary)

                    compactIdentityTextField(
                        title,
                        text: text,
                        focus: focus,
                        alignment: .leading
                    )
                }
                .padding(.vertical, 9)
            } else {
                HStack(spacing: 10) {
                    Text(title)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .frame(width: 88, alignment: .leading)

                    compactIdentityTextField(
                        title,
                        text: text,
                        focus: focus,
                        alignment: .trailing
                    )
                }
            }
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 48)
        .background(
            focusedField == focus
            ? Color.accentColor.opacity(0.055)
            : Color.clear
        )
    }

    private func compactIdentityTextField(
        _ title: String,
        text: Binding<String>,
        focus: SubjectFocusedField,
        alignment: TextAlignment
    ) -> some View {
        TextField(title, text: text)
            .textFieldStyle(.plain)
            .font(.body)
            .multilineTextAlignment(alignment)
            .focused($focusedField, equals: focus)
            .submitLabel(
                focus == .relationshipLabel
                ? .done
                : .next
            )
            .onSubmit {
                advanceIdentityFocus(from: focus)
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
            source: expressionSubjectSource,
            displayName: displayName,
            shortName: shortName,
            relationshipRole: relationshipRole,
            relationshipLabel: relationshipLabel
        )
    }

    private func expressionSubjectSourceValue(
        for source: MemorySubjectExpressionSubjectSource
    ) -> String? {
        switch source {
        case .displayName:
            return normalizedInlineValue(displayName)
        case .shortName:
            return normalizedInlineValue(shortName)
        case .relationshipRole:
            return normalizedInlineValue(relationshipRole)
        case .relationshipLabel:
            return normalizedInlineValue(relationshipLabel)
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

    @ViewBuilder
    private var compactAvatarPicker: some View {
#if canImport(PhotosUI)
        PhotosPicker(
            selection: $selectedAvatarItem,
            matching: .images
        ) {
            compactAvatarContent
        }
        .buttonStyle(.plain)
        .disabled(isOptimizingAvatar)
        .accessibilityLabel("选择对象头像")
#else
        compactAvatarContent
#endif
    }

    private var compactAvatarContent: some View {
        subjectAvatarPreview
            .frame(width: 96, height: 96)
            .overlay(alignment: .bottomTrailing) {
                Image(
                    systemName:
                        isOptimizingAvatar
                        ? "hourglass"
                        : "camera.fill"
                )
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(Color.black.opacity(0.82))
                )
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
                .offset(x: 4, y: 4)
            }
    }

    private var identitySnapshotCard: some View {
        HStack(alignment: .center, spacing: 14) {
            subjectAvatarPreview
                .frame(width: 72, height: 72)

            VStack(alignment: .leading, spacing: 8) {
                Text(displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "记忆对象" : displayName)
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
                shortName
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .isEmpty
                ? "未设昵称"
                : shortName,
            systemImage: "person.text.rectangle"
        )
    }

    private var relationshipSummaryChip: some View {
        identitySummaryChip(
            title:
                relationshipLabel
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .isEmpty
                ? "未设关系"
                : relationshipLabel,
            systemImage: "person.2.fill"
        )
    }

    private var avatarEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 14) {
                subjectAvatarPreview

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("对象头像")
                            .font(.subheadline.weight(.semibold))

                        if isOptimizingAvatar {
                            statusCapsule(
                                title: "处理中",
                                tint: .orange
                            )
                        }
                    }

                    Text(avatarStatusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(
                            horizontal: false,
                            vertical: true
                        )
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 8) {
                avatarResourceChip(
                    title: "头像",
                    isReady: avatarImagePath?.isEmpty == false
                )

                avatarResourceChip(
                    title: "标识",
                    isReady: avatarBadgeImagePath?.isEmpty == false
                )

                avatarResourceChip(
                    title: "预览",
                    isReady: avatarPreviewImagePath?.isEmpty == false
                )
            }

#if canImport(PhotosUI)
            PhotosPicker(
                selection: $selectedAvatarItem,
                matching: .images
            ) {
                HStack(spacing: 8) {
                    Image(
                        systemName:
                            isOptimizingAvatar
                            ? "hourglass"
                            : "person.crop.circle.badge.plus"
                    )
                    .font(.subheadline.weight(.semibold))

                    Text(
                        isOptimizingAvatar
                        ? "正在处理头像"
                        : "选择对象头像"
                    )
                    .font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .disabled(isOptimizingAvatar)

            Text("选择后可像联系人头像一样拖动、放大和调整位置，再生成对象头像资源。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
#endif
        }
        .padding(12)
        .configurationPanelChrome(isSelected: true)
    }

    private var identityFieldsPanel: some View {
        VStack(spacing: 0) {
            labeledTextField(
                "显示名称",
                text: $displayName,
                systemImage: "person.text.rectangle",
                focus: .displayName,
                subjectSource: .displayName
            )

            fieldDivider

            labeledTextField(
                "昵称",
                text: $shortName,
                systemImage: "person.crop.circle",
                focus: .shortName,
                subjectSource: .shortName
            )

            fieldDivider

            labeledTextField(
                "关系",
                text: $relationshipRole,
                systemImage: "person.2.fill",
                focus: .relationshipRole,
                subjectSource: .relationshipRole
            )

            fieldDivider

            labeledTextField(
                "关系备注",
                text: $relationshipLabel,
                systemImage: "heart.text.square",
                focus: .relationshipLabel,
                subjectSource: .relationshipLabel
            )
        }
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.94))
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
            if timeAnchors.isEmpty {
                Text("暂无时间锚点。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                timeAnchorSelectionCard
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
                ForEach(timeAnchors) { anchor in
                    SubjectTimeAnchorRow(
                        anchor: anchor,
                        isEditing:
                            anchor.id == editingTimeAnchorID,
                        canDelete:
                            timeAnchors.count > 1,
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

                if timeAnchors.count < 5 {
                    addTimeAnchorRow
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

    private var timeAnchorSelectionCard: some View {
        VStack(spacing: 0) {
            ForEach(
                Array(timeAnchors.enumerated()),
                id: \.element.id
            ) { index, anchor in
                SubjectTimeAnchorRow(
                    anchor: anchor,
                    isEditing:
                        anchor.id == editingTimeAnchorID,
                    canDelete:
                        timeAnchors.count > 1,
                    onConfigure: {
                        openTimeAnchorSheet(anchor.id)
                    },
                    onDelete: {
                        deleteTimeAnchor(anchor.id)
                    }
                )

                if index < timeAnchors.count - 1
                    || timeAnchors.count < 5 {
                    compactDivider
                }
            }

            if timeAnchors.count < 5 {
                addTimeAnchorRow
            }
        }
    }

    private var addTimeAnchorRow: some View {
        Button {
            addTimeAnchor()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 34)

                VStack(alignment: .leading, spacing: 3) {
                    Text("新增时间锚点")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text("最多可维护 5 个时间锚点")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var anchorBinding: Binding<MemorySubject.TimeAnchor>? {
        guard
            let editingAnchorID,
            let index = timeAnchors.firstIndex(
                where: { $0.id == editingAnchorID }
            )
        else {
            return nil
        }

        return $timeAnchors[index]
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
        guard let anchor = timeAnchors.first(where: { $0.id == anchorID }) else {
            return
        }
        timeAnchorEditingTransaction =
            TimeAnchorEditingTransaction(
                anchorID: anchorID,
                originalAnchor: anchor,
                originalSelectedAnchorID: selectedTimeAnchorID
            )
        editingTimeAnchorID = anchorID
    }

    private func addTimeAnchor() {
        guard timeAnchors.count < 5 else {
            return
        }

        let anchor =
            MemorySubject.TimeAnchor(
                title: "新锚点 \(timeAnchors.count + 1)",
                date: Date(),
                note: "自定义时间锚点",
                anchorType: .custom,
                expressionStyle:
                    .defaultStyle(for: .custom)
            )
        let normalizedAnchor = anchor.normalizedForEditing
        timeAnchorEditingTransaction =
            TimeAnchorEditingTransaction(
                anchorID: normalizedAnchor.id,
                originalAnchor: nil,
                originalSelectedAnchorID: selectedTimeAnchorID
            )
        timeAnchors.append(normalizedAnchor)
        editingTimeAnchorID = anchor.id
        syncDraftToSession()
    }

    private func deleteTimeAnchor(
        _ anchorID: UUID
    ) {
        guard timeAnchors.count > 1 else {
            return
        }

        timeAnchors.removeAll {
            $0.id == anchorID
        }

        if selectedTimeAnchorID == anchorID {
            selectedTimeAnchorID = timeAnchors.first?.id
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
            anchors: timeAnchors,
            selectedAnchorID: selectedTimeAnchorID
        )
        timeAnchors = rollback.anchors
        selectedTimeAnchorID = rollback.selectedAnchorID

        timeAnchorEditingTransaction = nil
        editingTimeAnchorID = nil
        focusedField = nil
        syncDraftToSession()
    }

    private func anchorTypeEditor(
        _ anchorBinding: Binding<MemorySubject.TimeAnchor>
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("锚点类型")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Picker(
                "锚点类型",
                selection: Binding(
                    get: {
                        anchorBinding
                            .wrappedValue
                            .resolvedAnchorType
                    },
                    set: { newType in
                        anchorBinding
                            .wrappedValue
                            .anchorType = newType
                        anchorBinding
                            .wrappedValue
                            .expressionStyle =
                            .defaultStyle(
                                for: newType
                            )
                    }
                )
            ) {
                ForEach(AnchorType.allCases, id: \.self) { type in
                    Text(type.displayName)
                        .tag(type)
                }
            }
            .pickerStyle(.menu)
            .padding(10)
            .configurationPanelChrome(isSelected: true)
        }
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
                        expressionSubjectSource =
                            subjectSource
                    } label: {
                        Label(
                            expressionSubjectSource
                                == subjectSource
                            ? "主体已生效"
                            : "设为主体",
                            systemImage:
                                expressionSubjectSource
                                == subjectSource
                                ? "checkmark.circle.fill"
                                : "circle"
                        )
                        .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(
                        expressionSubjectSource
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

        displayName = subject.identity.displayName
        shortName = subject.identity.shortName
        relationshipRole = subject.relationship.role
        relationshipLabel = subject.relationship.label
        avatarImagePath = subject.identity.avatarImagePath
        avatarBadgeImagePath =
            subject.identity.avatarBadgeImagePath
        avatarPreviewImagePath =
            subject.identity.avatarPreviewImagePath
        avatarStatusMessage =
            normalizedAvatarStatusMessage(
                from: subject.identity.avatarImagePath
            )
        definition = subject.definition
        timeAnchors = defaultedTimeAnchors(
            for: subject
        ).map {
            $0.normalizedForEditing
        }
        expressionSubjectSource =
            subject.expressionSubjectSource
        selectedTimeAnchorID =
            subject.primaryTimeAnchor?.id
            ?? subject.timeAnchors.first?.id
            ?? timeAnchors.first?.id
        editingTimeAnchorID = nil
    }

    private func defaultedTimeAnchors(
        for subject: MemorySubject
    ) -> [MemorySubject.TimeAnchor] {
        var anchors = subject.timeAnchors
        guard anchors.isEmpty else {
            return anchors
        }

        let referenceDate =
            subject.primaryTimeAnchor?.date
            ?? subject.referenceDate

        appendDefaultAnchorIfNeeded(
            title: "生日",
            date: referenceDate,
            note: "对象最重要的起点时间。",
            type: .birthday,
            anchors: &anchors
        )
        appendDefaultAnchorIfNeeded(
            title: "百天",
            date:
                Calendar.current.date(
                    byAdding: .day,
                    value: 99,
                    to: referenceDate
                ) ?? referenceDate,
            note: "对象出生后的第 100 天。",
            type: .birthday,
            anchors: &anchors
        )
        appendDefaultAnchorIfNeeded(
            title: "重要日子",
            date:
                Calendar.current.date(
                    byAdding: .month,
                    value: 6,
                    to: referenceDate
                ) ?? referenceDate,
            note: "自定义纪念日或重要时间点。",
            type: .custom,
            anchors: &anchors
        )

        return anchors
    }

    private func appendDefaultAnchorIfNeeded(
        title: String,
        date: Date,
        note: String,
        type: AnchorType,
        anchors: inout [MemorySubject.TimeAnchor]
    ) {
        guard !anchors.contains(
            where: { $0.title == title }
        ) else {
            return
        }

        anchors.append(
            MemorySubject.TimeAnchor(
                title: title,
                date: date,
                note: note,
                anchorType: type,
                expressionStyle:
                    .defaultStyle(for: type)
            )
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

        updated.identity.displayName = displayName
        updated.identity.shortName = shortName
        updated.identity.avatarImagePath = avatarImagePath
        updated.identity.avatarBadgeImagePath =
            avatarBadgeImagePath
        updated.identity.avatarPreviewImagePath =
            avatarPreviewImagePath
        updated.relationship.role = relationshipRole
        updated.relationship.label = relationshipLabel
        updated.definition = definition
        updated.timeAnchors = timeAnchors
        updated.expressionSubjectSource =
            expressionSubjectSource

        if let selectedAnchor =
            timeAnchors.first(where: {
                $0.id == selectedTimeAnchorID
            }) {
            updated.activeTimeAnchorID = selectedAnchor.id
            updated.behavior.primaryAnchor = selectedAnchor.title
            updated.referenceDate = selectedAnchor.date
        }

        session.updateSelectedSubject(updated)
    }

    private var subjectAvatarPreview: some View {
        ZStack {
            Circle()
                .fill(Color.accentColor.opacity(0.10))

            if let previewPath =
                avatarPreviewImagePath
                ?? avatarImagePath {
                PlatformAvatarImage(path: previewPath)
                    .scaledToFill()
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .font(.title2.weight(.medium))
                    .foregroundStyle(Color.accentColor)
            }
        }
        .frame(width: 64, height: 64)
        .overlay(
            Circle()
                .stroke(ConfigurationUI.faintHairline)
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
                    .fill(Color.white.opacity(0.88))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(ConfigurationUI.faintHairline)
            )
    }

    private func avatarResourceChip(
        title: String,
        isReady: Bool
    ) -> some View {
        Label(
            title,
            systemImage: isReady
            ? "checkmark.circle.fill"
            : "circle.dashed"
        )
        .font(.caption.weight(.semibold))
        .foregroundStyle(
            isReady
            ? Color.accentColor
            : Color.secondary
        )
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            Capsule(style: .continuous)
                .fill(
                    isReady
                    ? Color.accentColor.opacity(0.10)
                    : Color.white.opacity(0.88)
                )
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(
                    isReady
                    ? Color.accentColor.opacity(0.18)
                    : ConfigurationUI.faintHairline
                )
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
                    .fill(Color.white.opacity(0.88))
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

    private func statusCapsule(
        title: String,
        tint: Color
    ) -> some View {
        Text(title)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                Capsule(style: .continuous)
                    .fill(tint.opacity(0.10))
            )
    }

    private var fieldDivider: some View {
        Rectangle()
            .fill(ConfigurationUI.faintHairline)
            .frame(height: 0.5)
            .padding(.leading, 54)
    }

    private var compactDivider: some View {
        Rectangle()
            .fill(ConfigurationUI.faintHairline)
            .frame(height: 0.5)
            .padding(.leading, 82)
    }

    private func normalizedAvatarStatusMessage(
        from avatarPath: String?
    ) -> String {
        if let avatarPath,
           !avatarPath.isEmpty {
            return "已准备头像衍生资源，可用于头像、标识与预览。"
        }

        return "可选择对象头像，用于头像、标识与预览。"
    }

#if canImport(PhotosUI)
    @MainActor
    private func prepareSelectedAvatar(
        _ item: PhotosPickerItem
    ) async {
        isOptimizingAvatar = true
        avatarStatusMessage = "正在载入对象头像"

        do {
            guard
                let data =
                    try await item.loadTransferable(
                        type: Data.self
                    )
            else {
                throw SubjectAvatarAssetOptimizationError.invalidImage
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
            avatarStatusMessage = "调整头像位置后再应用。"
#else
            await applyAvatarCrop(
                data: data,
                configuration: .init()
            )
#endif
        } catch {
            avatarStatusMessage =
                error.localizedDescription
        }

        isOptimizingAvatar = false
    }
#endif

    @MainActor
    private func applyAvatarCrop(
        data: Data,
        configuration: SubjectAvatarCropConfiguration
    ) async {
        isOptimizingAvatar = true
        avatarStatusMessage = "正在优化对象头像"

        do {
            let optimizedAsset =
                try await avatarOptimizer.optimize(
                    data: data,
                    cropConfiguration: configuration
                )

            avatarImagePath =
                optimizedAsset.displayImagePath
            avatarBadgeImagePath =
                optimizedAsset.badgeImagePath
            avatarPreviewImagePath =
                optimizedAsset.previewImagePath
            avatarStatusMessage = "头像已优化并同步到头像、标识与预览资源。"
            syncDraftToSession()
        } catch {
            avatarStatusMessage =
                error.localizedDescription
        }

        isOptimizingAvatar = false
    }
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

private struct CompactAnchorDatePicker: View {

    @Binding var selection: Date

    private static let wheelHeight: CGFloat = 144

    private let calendar = Calendar(identifier: .gregorian)
    private let years = Array(1900...2100)

    private var selectedYear: Int {
        calendar.component(.year, from: selection)
    }

    private var selectedMonth: Int {
        calendar.component(.month, from: selection)
    }

    private var selectedDay: Int {
        calendar.component(.day, from: selection)
    }

    private var availableDays: ClosedRange<Int> {
        let components = DateComponents(
            year: selectedYear,
            month: selectedMonth
        )
        guard
            let monthDate = calendar.date(from: components),
            let range = calendar.range(of: .day, in: .month, for: monthDate)
        else {
            return 1...31
        }
        return range.lowerBound...range.upperBound
    }

    var body: some View {
#if os(iOS)
        HStack(spacing: 2) {
            compactWheel(
                values: years,
                selection: selectedYear,
                suffix: "年"
            ) { update(year: $0) }
            .frame(maxWidth: .infinity)

            compactWheel(
                values: Array(1...12),
                selection: selectedMonth,
                suffix: "月"
            ) { update(month: $0) }
            .frame(width: 84)

            compactWheel(
                values: Array(availableDays),
                selection: min(selectedDay, availableDays.upperBound),
                suffix: "日"
            ) { update(day: $0) }
            .frame(width: 84)
        }
        .frame(height: Self.wheelHeight)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("锚点日期")
#else
        DatePicker(
            "日期",
            selection: $selection,
            displayedComponents: .date
        )
#endif
    }

#if os(iOS)
    private func compactWheel(
        values: [Int],
        selection: Int,
        suffix: String,
        onChange: @escaping (Int) -> Void
    ) -> some View {
        Picker(
            suffix,
            selection: Binding(
                get: { selection },
                set: onChange
            )
        ) {
            ForEach(values, id: \.self) { value in
                Text("\(value)\(suffix)")
                    .tag(value)
            }
        }
        .pickerStyle(.wheel)
        .labelsHidden()
    }
#endif

    private func update(
        year: Int? = nil,
        month: Int? = nil,
        day: Int? = nil
    ) {
        var components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: selection
        )
        components.year = year ?? selectedYear
        components.month = month ?? selectedMonth

        let requestedDay = day ?? selectedDay
        components.day = 1
        guard let targetMonth = calendar.date(from: components) else {
            return
        }
        let dayRange = calendar.range(
            of: .day,
            in: .month,
            for: targetMonth
        ) ?? 1..<32
        components.day = min(requestedDay, dayRange.count)

        if let date = calendar.date(from: components) {
            selection = date
        }
    }
}

private enum SubjectTimeAnchorMetrics {

    static let rowHeight: CGFloat = 64
}

private struct SubjectTimeAnchorRow: View {

    let anchor: MemorySubject.TimeAnchor
    let isEditing: Bool
    let canDelete: Bool
    let onConfigure: () -> Void
    let onDelete: () -> Void

    @State private var showsDeleteConfirmation = false

    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize

    var body: some View {
        rowContent
            .swipeActions(
                edge: .trailing,
                allowsFullSwipe: false
            ) {
                if canDelete {
                    Button {
                        showsDeleteConfirmation = true
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                    .tint(.red)
                }

                Button(action: onConfigure) {
                    Label("配置", systemImage: "slider.horizontal.3")
                }
                .tint(.blue)
            }
            .confirmationDialog(
                "删除这个时间锚点？",
                isPresented: $showsDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("删除时间锚点", role: .destructive) {
                    onDelete()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("删除后会立即切换到仍然保留的时间锚点，并同步刷新配置中心预览。")
            }
    }

    private var rowContent: some View {
        HStack(spacing: 12) {
            RoundedRectangle(
                cornerRadius: 11,
                style: .continuous
            )
            .fill(
                isEditing
                ? Color.accentColor.opacity(0.12)
                : Color.primary.opacity(0.045)
            )
            .frame(width: 36, height: 36)
            .overlay {
                Image(systemName: anchorTypeIconName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(
                        isEditing
                        ? Color.accentColor
                        : Color.secondary
                    )
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(anchor.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)

                Text(anchorDateText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if dynamicTypeSize.isAccessibilitySize {
                    Text(anchor.resolvedAnchorType.displayName)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 0)

            if !dynamicTypeSize.isAccessibilitySize {
                Text(anchor.resolvedAnchorType.displayName)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.primary.opacity(0.045))
                    )
            }

            Menu {
                Button(action: onConfigure) {
                    Label("配置", systemImage: "slider.horizontal.3")
                }

                if canDelete {
                    Button {
                        showsDeleteConfirmation = true
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 32)
            }
            .accessibilityLabel("时间锚点操作")

        }
        .padding(.horizontal, 12)
        .padding(.vertical, dynamicTypeSize.isAccessibilitySize ? 8 : 0)
        .frame(minHeight: SubjectTimeAnchorMetrics.rowHeight)
        .background(Color.white.opacity(0.94))
    }

    private var anchorDateText: String {
        anchor.date.formatted(
            .dateTime
                .year(.defaultDigits)
                .month(.defaultDigits)
                .day(.defaultDigits)
                .locale(Locale(identifier: "zh_CN"))
        )
    }

    private var anchorTypeIconName: String {
        switch anchor.resolvedAnchorType {
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

}

private struct PlatformAvatarImage: View {

    let path: String

    var body: some View {
#if os(macOS)
        if let image = NSImage(contentsOfFile: path) {
            Image(nsImage: image)
                .resizable()
        } else {
            Color.clear
        }
#elseif canImport(UIKit)
        if let image = UIImage(contentsOfFile: path) {
            Image(uiImage: image)
                .resizable()
        } else {
            Color.clear
        }
#endif
    }
}

private extension Binding where Value == MemorySubject.TimeAnchor {

    var title: Binding<String> {
        Binding<String>(
            get: {
                wrappedValue.title
            },
            set: {
                wrappedValue.title = $0
            }
        )
    }

    var date: Binding<Date> {
        Binding<Date>(
            get: {
                wrappedValue.date
            },
            set: {
                wrappedValue.date = $0
            }
        )
    }

    var note: Binding<String> {
        Binding<String>(
            get: {
                wrappedValue.note
            },
            set: {
                wrappedValue.note = $0
            }
        )
    }

    var anchorType: Binding<AnchorType> {
        Binding<AnchorType>(
            get: {
                wrappedValue.resolvedAnchorType
            },
            set: {
                wrappedValue.anchorType = $0
                wrappedValue.expressionStyle =
                    MemoryAnchorExpressionStyle
                    .defaultStyle(
                        for: $0
                    )
            }
        )
    }
}

private extension DecorationStrategy {

    var displayTitle: String {
        switch self {
        case .autoMatch:
            return "自动匹配"
        case .fixed:
            return "固定"
        case .none:
            return "无"
        case .overrideCurrentExport:
            return "覆盖当前输出"
        }
    }
}
#endif
