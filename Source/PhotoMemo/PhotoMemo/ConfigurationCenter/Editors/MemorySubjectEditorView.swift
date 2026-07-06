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

    @ObservedObject
    var session: ConfigurationSession

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

    var body: some View {
        VStack(alignment: .leading, spacing: 26) {
            if session.state.selectedSubject != nil {
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
        .onChange(of: timeAnchors) { _, _ in
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
            Text("这里专门维护当前记忆对象下每个时间锚点的详细参数。当前生效锚点的切换和记忆显示已经收拢到配置中心摘要区，这里只负责选择要编辑的锚点，并维护日期、名称与锚点类型。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if timeAnchors.isEmpty {
                Text("暂无时间锚点。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                currentAnchorSnapshotCard
                timeAnchorSelectionCard

                if let anchorBinding {
                    HStack {
                        Text(anchorBinding.wrappedValue.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.primary)

                        Spacer()
                    }

                    DatePicker(
                        "日期",
                        selection: anchorBinding.date,
                        displayedComponents: .date
                    )
                    .padding(10)
                    .configurationPanelChrome()

                    anchorTypeEditor(
                        anchorBinding
                    )
                }
            }
        }
    }

    private var currentAnchorSnapshotCard: some View {
        let anchor = timeAnchors.first {
            $0.id == selectedTimeAnchorID
        } ?? timeAnchors.first

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                RoundedRectangle(
                    cornerRadius: 14,
                    style: .continuous
                )
                .fill(Color.accentColor.opacity(0.10))
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: "calendar.badge.clock")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(anchor?.title ?? "时间锚点")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text("当前维护中的锚点会同步影响对象时间线与摘要区切换结果。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 8) {
                anchorMetaChip(
                    title: anchor?.date.formatted(
                        date: .abbreviated,
                        time: .omitted
                    ) ?? "未设日期",
                    systemImage: "calendar"
                )

                anchorMetaChip(
                    title: anchor?.resolvedAnchorType.displayName ?? "锚点类型",
                    systemImage: "tag"
                )

                anchorMetaChip(
                    title: "\(timeAnchors.count) 个锚点",
                    systemImage: "square.stack.3d.up"
                )
            }
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

    private var timeAnchorSelectionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text("选择要维护的时间锚点")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.primary)

                Text("在这里切换当前要维护的锚点，继续调整日期、名称和锚点类型。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 8) {
                Picker(
                    "要维护的时间锚点",
                    selection: Binding(
                        get: {
                            selectedTimeAnchorID
                            ?? timeAnchors.first?.id
                            ?? UUID()
                        },
                        set: {
                            selectedTimeAnchorID = $0
                        }
                    )
                ) {
                    ForEach(timeAnchors) { anchor in
                        Text(anchor.title)
                            .tag(anchor.id)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }

            if let anchorBinding {
                labeledTextField(
                    "自定义锚点名称",
                    text: anchorBinding.title,
                    systemImage: "tag",
                    focus: .timeTitle
                )
            }
        }
        .padding(12)
        .configurationPanelChrome(isSelected: true)
    }

    private var anchorBinding: Binding<MemorySubject.TimeAnchor>? {
        guard
            let selectedTimeAnchorID,
            let index = timeAnchors.firstIndex(
                where: { $0.id == selectedTimeAnchorID }
            )
        else {
            return nil
        }

        return $timeAnchors[index]
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
        timeAnchors = subject.timeAnchors.map {
            $0.normalizedForEditing
        }
        expressionSubjectSource =
            subject.expressionSubjectSource
        selectedTimeAnchorID =
            subject.primaryTimeAnchor?.id
            ?? subject.timeAnchors.first?.id
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
