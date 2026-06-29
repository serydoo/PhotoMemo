#if !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

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
    private var definition = ""

    @State
    private var timeAnchors: [MemorySubject.TimeAnchor] = []

    @State
    private var selectedTimeAnchorID: UUID?

    @State
    private var isEditingTimeAnchor = false

    @FocusState
    private var focusedField: SubjectFocusedField?

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
                    "定义",
                    systemImage: "text.alignleft"
                ) {
                    definitionEditor
                }

                InspectorSectionView(
                    "时间锚点",
                    systemImage: "calendar.badge.clock"
                ) {
                    timeWindowEditor
                }

                InspectorSectionView(
                    "行为映射",
                    systemImage: "switch.2"
                ) {
                    InspectorPropertyRow(
                        title: "主要时间",
                        value: subject.behavior.primaryAnchor,
                        systemImage: "flag.fill"
                    )
                    InspectorPropertyRow(
                        title: "图标策略",
                        value: subject.behavior.iconStrategy.displayTitle,
                        systemImage: "person.crop.circle.fill"
                    )
                    InspectorPropertyRow(
                        title: "徽标策略",
                        value: subject.behavior.badgeStrategy.displayTitle,
                        systemImage: "camera.fill"
                    )
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
        .onChange(of: definition) { _, _ in
            syncDraftToSession()
        }
        .onChange(of: timeAnchors) { _, _ in
            syncDraftToSession()
        }
        .onChange(of: selectedTimeAnchorID) { _, _ in
            syncDraftToSession()
        }
    }

    private var identityEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            labeledTextField(
                "显示名称",
                text: $displayName,
                systemImage: "person.text.rectangle",
                focus: .displayName
            )

            labeledTextField(
                "昵称",
                text: $shortName,
                systemImage: "person.crop.circle",
                focus: .shortName
            )

            labeledTextField(
                "关系类型",
                text: $relationshipRole,
                systemImage: "person.2",
                focus: .relationshipRole
            )

            labeledTextField(
                "关系备注",
                text: $relationshipLabel,
                systemImage: "heart.text.square",
                focus: .relationshipLabel
            )
        }
    }

    private var definitionEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("对象定义")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            TextField(
                "补充这个记忆对象的定义",
                text: $definition,
                axis: .vertical
            )
                .font(.subheadline)
                .textFieldStyle(.plain)
                .lineLimit(1...4)
                .focused($focusedField, equals: .definition)
                .configurationFieldChrome(
                    isActive: focusedField == .definition
                )
        }
    }

    private var timeWindowEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            if timeAnchors.isEmpty {
                Text("暂无时间锚点。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("时间锚点")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.primary)

                    Text("定义记忆对象的关键日期，用于理解回忆的位置。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .configurationPanelChrome(isSelected: true)

                HStack(spacing: 8) {
                    Picker(
                        "时间锚点",
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
                        "名称",
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
        focus: SubjectFocusedField
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
        definition = subject.definition
        timeAnchors = subject.timeAnchors
        selectedTimeAnchorID =
            subject.timeAnchors.first(where: {
                $0.title == subject.behavior.primaryAnchor
            })?.id
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
        updated.relationship.role = relationshipRole
        updated.relationship.label = relationshipLabel
        updated.definition = definition
        updated.timeAnchors = timeAnchors

        if let selectedAnchor =
            timeAnchors.first(where: {
                $0.id == selectedTimeAnchorID
            }) {
            updated.behavior.primaryAnchor = selectedAnchor.title
            updated.referenceDate = selectedAnchor.date
        }

        session.updateSelectedSubject(updated)
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
