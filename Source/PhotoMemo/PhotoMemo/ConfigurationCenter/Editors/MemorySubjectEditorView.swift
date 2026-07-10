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
    private var avatarStatusMessage = "可上传对象头像，用于头像、标识与预览。"

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
    private var revealedDeleteTimeAnchorID: UUID?

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
                    timeWindowEditor
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
            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
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

                    expressionSubjectMenuRow

                    Text(
                        relationshipLabel
                            .trimmingCharacters(
                                in: .whitespacesAndNewlines
                            )
                            .isEmpty
                        ? "补充关系备注"
                        : relationshipLabel
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 0)

                compactAvatarPicker
            }

            if let identityOverviewAccessory {
                identityOverviewAccessory
            }

            compactIdentityFieldsPanel
        }
    }

    private var expressionSubjectMenuRow: some View {
        HStack(spacing: 10) {
            Menu {
                ForEach(
                    MemorySubjectExpressionSubjectSource.allCases
                ) { source in
                    Button {
                        expressionSubjectSource = source
                    } label: {
                        Label(
                            source.displayTitle,
                            systemImage:
                                source == expressionSubjectSource
                                ? "checkmark"
                                : "circle"
                        )
                    }
                }
            } label: {
                Label(
                    "主体名称",
                    systemImage: "person.text.rectangle"
                )
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.accentColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.accentColor.opacity(0.10))
                )
            }
            .buttonStyle(.plain)

            Text(expressionSubjectDisplayValue)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
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
        .fixedSize(horizontal: true, vertical: false)
    }

    private var compactIdentityFieldsPanel: some View {
        VStack(spacing: 0) {
            compactLabeledTextField(
                "显示名称",
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
                "关系",
                text: $relationshipRole,
                focus: .relationshipRole
            )

            compactDivider

            compactLabeledTextField(
                "关系备注",
                text: $relationshipLabel,
                focus: .relationshipLabel
            )
        }
        .background(Color.white.opacity(0.94))
        .clipShape(
            RoundedRectangle(
                cornerRadius: 16,
                style: .continuous
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 16,
                style: .continuous
            )
            .stroke(ConfigurationUI.faintHairline)
        )
    }

    private func compactLabeledTextField(
        _ title: String,
        text: Binding<String>,
        focus: SubjectFocusedField
    ) -> some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 72, alignment: .leading)

            TextField(title, text: text)
                .textFieldStyle(.plain)
                .font(.subheadline)
                .multilineTextAlignment(.trailing)
                .focused($focusedField, equals: focus)
                .padding(.horizontal, 10)
                .frame(height: 34)
                .background(
                    RoundedRectangle(
                        cornerRadius: 10,
                        style: .continuous
                    )
                    .fill(ConfigurationUI.panelBackground)
                )
                .overlay(
                    RoundedRectangle(
                        cornerRadius: 10,
                        style: .continuous
                    )
                    .stroke(
                        focusedField == focus
                        ? Color.accentColor.opacity(0.28)
                        : ConfigurationUI.faintHairline,
                        lineWidth:
                            focusedField == focus ? 1 : 0.75
                    )
                )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
    }

    private var expressionSubjectDisplayValue: String {
        switch expressionSubjectSource {
        case .displayName:
            return normalizedInlineValue(
                displayName,
                fallback: "显示名称"
            )
        case .shortName:
            return normalizedInlineValue(
                shortName,
                fallback: "昵称"
            )
        case .relationshipRole:
            return normalizedInlineValue(
                relationshipRole,
                fallback: "关系"
            )
        case .relationshipLabel:
            return normalizedInlineValue(
                relationshipLabel,
                fallback: "关系备注"
            )
        }
    }

    private func normalizedInlineValue(
        _ text: String,
        fallback: String
    ) -> String {
        let trimmed =
            text.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return trimmed.isEmpty
            ? fallback
            : trimmed
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

                HStack(spacing: 8) {
                    identitySummaryChip(
                        title: shortName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "未设昵称" : shortName,
                        systemImage: "person.text.rectangle"
                    )

                    identitySummaryChip(
                        title: relationshipLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "未设关系" : relationshipLabel,
                        systemImage: "person.2.fill"
                    )
                }
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
                        : "上传对象头像"
                    )
                    .font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .disabled(isOptimizingAvatar)

            Text("上传后可像联系人头像一样拖动、放大和调整位置，再生成对象头像资源。")
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
            Text("时间锚点用于定义照片与记忆对象之间的时间关系。预设时间、锚点类型和自定义名称会共同决定年龄、纪念日、倒计时等智能结果的计算方式。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if timeAnchors.isEmpty {
                Text("暂无时间锚点。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                timeAnchorSelectionCard
            }
        }
        .sheet(
            isPresented:
                Binding(
                    get: {
                        editingTimeAnchorID != nil
                    },
                    set: { isPresented in
                        if !isPresented {
                            editingTimeAnchorID = nil
                            focusedField = nil
                        }
                    }
                )
        ) {
            timeAnchorConfigurationSheet
        }
    }

    private var timeAnchorSelectionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text("锚点列表")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.primary)

                Text("默认 3 个，可新增到最多 5 个。左滑删除，至少保留 1 个。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 0) {
                ForEach(
                    Array(timeAnchors.enumerated()),
                    id: \.element.id
                ) { index, anchor in
                    SubjectTimeAnchorRow(
                        index: index + 1,
                        anchor: anchor,
                        isEditing:
                            anchor.id == editingTimeAnchorID,
                        canDelete:
                            timeAnchors.count > 1,
                        isDeleteRevealed:
                            revealedDeleteTimeAnchorID
                            == anchor.id,
                        onConfigure: {
                            openTimeAnchorSheet(anchor.id)
                        },
                        onRevealDelete: {
                            revealedDeleteTimeAnchorID =
                                anchor.id
                        },
                        onHideDelete: {
                            if revealedDeleteTimeAnchorID
                                == anchor.id {
                                revealedDeleteTimeAnchorID = nil
                            }
                        },
                        onDelete: {
                            deleteTimeAnchor(anchor.id)
                        }
                    )

                    if anchor.id != timeAnchors.last?.id {
                        fieldDivider
                    }
                }

                if timeAnchors.count < 5 {
                    fieldDivider
                    addTimeAnchorRow
                }
            }
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
        .padding(12)
        .configurationPanelChrome(isSelected: true)
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
            VStack(alignment: .leading, spacing: 14) {
                Text(anchorBinding.wrappedValue.title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                timeAnchorConfigurationPanel(
                    anchorBinding
                )
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 24)
            .presentationDetents([.fraction(0.42)])
            .presentationDragIndicator(.visible)
            .presentationBackgroundInteraction(.enabled)
        } else {
            EmptyView()
        }
    }

    private func timeAnchorConfigurationPanel(
        _ anchorBinding: Binding<MemorySubject.TimeAnchor>
    ) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Label(
                    "锚点时间",
                    systemImage: "calendar"
                )
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

                Spacer(minLength: 0)

                DatePicker(
                    "锚点时间",
                    selection: anchorBinding.date,
                    displayedComponents: .date
                )
                .labelsHidden()
                .controlSize(.small)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            fieldDivider

            HStack(spacing: 10) {
                Label(
                    "锚点类型",
                    systemImage: "tag"
                )
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

                Spacer(minLength: 0)

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
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            fieldDivider

            VStack(alignment: .leading, spacing: 6) {
                Label(
                    "锚点名称",
                    systemImage: "textformat"
                )
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

                TextField(
                    "例如：生日 / 百天 / 重要日子",
                    text: anchorBinding.title
                )
                .textFieldStyle(.plain)
                .font(.subheadline)
                .focused($focusedField, equals: .timeTitle)
                .configurationFieldChrome(
                    isActive: focusedField == .timeTitle
                )
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            fieldDivider

            Button {
                saveEditingTimeAnchor()
            } label: {
                Label(
                    "保存当前锚点",
                    systemImage: "checkmark"
                )
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 5)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            .padding(12)
        }
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

    private func openTimeAnchorSheet(
        _ anchorID: UUID
    ) {
        revealedDeleteTimeAnchorID = nil
        editingTimeAnchorID =
            editingTimeAnchorID == anchorID
            ? nil
            : anchorID
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
        timeAnchors.append(anchor.normalizedForEditing)
        editingTimeAnchorID = anchor.id
        revealedDeleteTimeAnchorID = nil
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

        revealedDeleteTimeAnchorID = nil
        syncDraftToSession()
    }

    private func saveEditingTimeAnchor() {
        revealedDeleteTimeAnchorID = nil
        syncDraftToSession()
        editingTimeAnchorID = nil
        focusedField = nil
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

        return "可上传对象头像，用于头像、标识与预览。"
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

private struct SubjectTimeAnchorRow: View {

    let index: Int
    let anchor: MemorySubject.TimeAnchor
    let isEditing: Bool
    let canDelete: Bool
    let isDeleteRevealed: Bool
    let onConfigure: () -> Void
    let onRevealDelete: () -> Void
    let onHideDelete: () -> Void
    let onDelete: () -> Void

    @GestureState
    private var horizontalDragOffset: CGFloat = 0

    var body: some View {
        ZStack(alignment: .trailing) {
            if canDelete {
                Button(role: .destructive, action: onDelete) {
                    Text("删除")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 70)
                        .frame(maxHeight: .infinity)
                        .background(Color.red)
                }
                .offset(x: rowHorizontalOffset == 0 ? 78 : 0)
                .opacity(deleteButtonOpacity)
                .allowsHitTesting(rowHorizontalOffset < -38)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 14,
                        style: .continuous
                    )
                )
            }

            rowContent
                .offset(x: rowHorizontalOffset)
                .gesture(
                    DragGesture(minimumDistance: 12)
                        .updating($horizontalDragOffset) {
                            value,
                            state,
                            _ in

                            guard canDelete,
                                  abs(value.translation.width)
                                  > abs(value.translation.height)
                            else {
                                state = 0
                                return
                            }

                            if isDeleteRevealed {
                                state = min(
                                    76,
                                    max(0, value.translation.width)
                                )
                            } else {
                                state = max(
                                    -76,
                                    min(0, value.translation.width)
                                )
                            }
                        }
                        .onEnded { value in
                            guard canDelete,
                                  abs(value.translation.width)
                                  > abs(value.translation.height)
                            else {
                                return
                            }

                            if isDeleteRevealed {
                                if value.translation.width > 32 {
                                    onHideDelete()
                                } else {
                                    onRevealDelete()
                                }
                            } else {
                                if value.translation.width < -36 {
                                    onRevealDelete()
                                } else {
                                    onHideDelete()
                                }
                            }
                        }
                )
                .animation(
                    .snappy(duration: 0.18),
                    value: rowHorizontalOffset
                )
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
                Text("\(index)")
                    .font(.caption.weight(.semibold))
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
                    .lineLimit(1)

                Text(anchorDateText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

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

            Button(action: onConfigure) {
                Text("配置")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.accentColor.opacity(0.10))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .background(Color.white.opacity(0.94))
        .contentShape(Rectangle())
        .onTapGesture {
            if isDeleteRevealed {
                onHideDelete()
            } else {
                onConfigure()
            }
        }
    }

    private var anchorDateText: String {
        anchor.date.formatted(
            date: .abbreviated,
            time: .omitted
        )
    }

    private var rowHorizontalOffset: CGFloat {
        guard canDelete else {
            return 0
        }

        let base: CGFloat =
            isDeleteRevealed ? -76 : 0

        return min(
            0,
            max(-76, base + horizontalDragOffset)
        )
    }

    private var deleteButtonOpacity: Double {
        guard canDelete else {
            return 0
        }

        return min(
            1,
            Double(abs(rowHorizontalOffset) / 56)
        )
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
