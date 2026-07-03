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
    private var isEditingTimeAnchor = false

    @State
    private var isOptimizingAvatar = false

#if canImport(PhotosUI)
    @State
    private var selectedAvatarItem: PhotosPickerItem?
#endif

    @FocusState
    private var focusedField: SubjectFocusedField?

    private let avatarOptimizer =
        SubjectAvatarAssetOptimizationService()

    var body: some View {
        VStack(alignment: .leading, spacing: 26) {
            if let subject = session.state.selectedSubject {
                InspectorSectionView(
                    "身份",
                    systemImage: "person.fill"
                ) {
                    identityEditor
                }

                InspectorSectionView(
                    "时间锚点",
                    systemImage: "calendar.badge.clock"
                ) {
                    timeWindowEditor
                }

                Button {
                    saveSubject(subject)
                } label: {
                    Label("保存记忆对象", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
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
                await optimizeSelectedAvatar(item)
            }
        }
#endif
    }

    private var identityEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            avatarEditor

            labeledTextField(
                "显示名称",
                text: $displayName,
                systemImage: "person.text.rectangle",
                focus: .displayName,
                subjectSource: .displayName
            )

            labeledTextField(
                "昵称",
                text: $shortName,
                systemImage: "person.crop.circle",
                focus: .shortName,
                subjectSource: .shortName
            )

            labeledTextField(
                "关系备注",
                text: $relationshipLabel,
                systemImage: "heart.text.square",
                focus: .relationshipLabel,
                subjectSource: .relationshipLabel
            )
        }
    }

    private var avatarEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 14) {
                subjectAvatarPreview

                VStack(alignment: .leading, spacing: 4) {
                    Text("对象头像")
                        .font(.subheadline.weight(.semibold))

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

#if canImport(PhotosUI)
            PhotosPicker(
                selection: $selectedAvatarItem,
                matching: .images
            ) {
                Label(
                    isOptimizingAvatar
                    ? "正在优化头像"
                    : "上传对象头像",
                    systemImage:
                        isOptimizingAvatar
                        ? "hourglass"
                        : "person.crop.circle.badge.plus"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .disabled(isOptimizingAvatar)
#endif
        }
        .padding(12)
        .configurationPanelChrome(isSelected: true)
    }

    private var timeWindowEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            if timeAnchors.isEmpty {
                Text("暂无时间锚点。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                HStack(spacing: 8) {
                    Picker(
                        "当前生效时间锚点",
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

                    Button {
                        isEditingTimeAnchor.toggle()
                    } label: {
                        Label(
                            isEditingTimeAnchor ? "完成" : "编辑",
                            systemImage:
                                isEditingTimeAnchor
                                ? "checkmark.circle"
                                : "pencil"
                        )
                    }
                    .buttonStyle(.borderless)
                }

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
                    .disabled(!isEditingTimeAnchor)
                    .padding(10)
                    .configurationPanelChrome()

                    labeledTextField(
                        "自定义锚点名称",
                        text: anchorBinding.title,
                        systemImage: "tag",
                        focus: .timeTitle
                    )
                    .disabled(!isEditingTimeAnchor)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("锚点说明")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        TextField(
                            "例如：途途出生日期",
                            text: anchorBinding.note,
                            axis: .vertical
                        )
                            .font(.subheadline)
                            .textFieldStyle(.plain)
                            .lineLimit(1...3)
                            .focused($focusedField, equals: .timeNote)
                            .disabled(!isEditingTimeAnchor)
                            .configurationFieldChrome(
                                isActive: focusedField == .timeNote
                            )
                    }
                }
            }
        }
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
        timeAnchors = subject.timeAnchors
        expressionSubjectSource =
            subject.expressionSubjectSource
        selectedTimeAnchorID =
            subject.primaryTimeAnchor?.id
            ?? subject.timeAnchors.first?.id
        isEditingTimeAnchor = false
    }

    private func saveSubject(
        _ subject: MemorySubject
    ) {
        syncDraftToSession(subject)
        isEditingTimeAnchor = false
        focusedField = nil
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
    private func optimizeSelectedAvatar(
        _ item: PhotosPickerItem
    ) async {
        isOptimizingAvatar = true
        avatarStatusMessage = "正在优化对象头像"

        do {
            guard
                let data =
                    try await item.loadTransferable(
                        type: Data.self
                    )
            else {
                throw SubjectAvatarAssetOptimizationError.invalidImage
            }

            let optimizedAsset =
                try await avatarOptimizer.optimize(
                    data: data
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
#endif
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
