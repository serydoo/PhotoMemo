#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct V1IOSSubjectAnchorDetailSection: View {

    @ObservedObject
    var session: ConfigurationSession

    let subject: MemorySubject?
    let onPersistSubjectChanges: () -> Void
    let allowsSwipeDeletion: Bool

    init(
        session: ConfigurationSession,
        subject: MemorySubject?,
        onPersistSubjectChanges: @escaping () -> Void,
        allowsSwipeDeletion: Bool = false
    ) {
        self.session = session
        self.subject = subject
        self.onPersistSubjectChanges = onPersistSubjectChanges
        self.allowsSwipeDeletion = allowsSwipeDeletion
    }

    @State
    private var editingDraft: AnchorDraft?

    @State
    private var pendingDeleteAnchor: MemorySubject.TimeAnchor?

    @State
    private var showsLastAnchorWarning = false

    var body: some View {
        if let subject = session.state.selectedSubject ?? subject {
            VStack(spacing: 12) {
                ForEach(subject.timeAnchors) { anchor in
                    V1IOSSubjectAnchorDetailModule(
                        anchor: anchor,
                        onConfigure: {
                            editingDraft = AnchorDraft(
                                originalID: anchor.id,
                                anchor: anchor
                            )
                        },
                        onDelete: {
                            requestDeletion(anchor)
                        },
                        leadingContentInset:
                            allowsSwipeDeletion ? 30 : 0
                    )
                    .overlay(alignment: .leading) {
                        if allowsSwipeDeletion {
                            Button(role: .destructive) {
                                requestDeletion(anchor)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                            .padding(.leading, 12)
                            .contentShape(Rectangle())
                            .zIndex(2)
                            .accessibilityLabel("删除时间锚点")
                        }
                    }
                    .swipeActions(
                        edge: .leading,
                        allowsFullSwipe: false
                    ) {
                        if allowsSwipeDeletion {
                            Button("删除", role: .destructive) {
                                requestDeletion(anchor)
                            }
                            .tint(.red)
                        }
                    }
                }

                if subject.timeAnchors.count < 5 {
                    addAnchorModule
                } else {
                    Text("最多保留 5 个时间锚点")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .sheet(
                item: $editingDraft,
                onDismiss: commitEditingDraft
            ) { draft in
                V1IOSSubjectAnchorCompactEditor(
                    initialAnchor: draft.anchor,
                    onChange: { anchor in
                        editingDraft?.anchor = anchor
                    },
                    onSave: {
                        commitEditingDraft()
                    }
                )
                .presentationDetents([
                    .height(ConfigurationUI.compactSheetHeight),
                    .large
                ])
                .presentationDragIndicator(.visible)
            }
            .alert(
                pendingDeleteAnchor.map { "删除“\($0.title)”？" }
                    ?? "删除时间锚点？",
                isPresented: Binding(
                    get: { pendingDeleteAnchor != nil },
                    set: { isPresented in
                        if !isPresented {
                            pendingDeleteAnchor = nil
                        }
                    }
                )
            ) {
                Button("取消", role: .cancel) {
                    pendingDeleteAnchor = nil
                }
                Button("删除锚点", role: .destructive) {
                    deletePendingAnchor()
                }
            } message: {
                Text("使用这个锚点的配置需要重新选择锚点。此操作无法撤销。")
            }
            .alert(
                "至少保留一个时间锚点",
                isPresented: $showsLastAnchorWarning
            ) {
                Button("好", role: .cancel) {}
            } message: {
                Text("新增另一个锚点后，才能删除当前锚点。")
            }
        }
    }

    private var addAnchorModule: some View {
        Button {
            let anchor = MemorySubject.TimeAnchor(
                title: AnchorType.custom.suggestedTitle,
                date: Date(),
                note: "自定义时间锚点",
                anchorType: .custom,
                expressionStyle: .defaultStyle(for: .custom)
            )
            editingDraft = AnchorDraft(
                originalID: nil,
                anchor: anchor
            )
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.green)

                Text("添加锚点")
                    .font(.body)
                    .foregroundStyle(.primary)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .frame(minHeight: ConfigurationUI.minimumInteractiveHeight)
            .background(moduleBackground)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("添加时间锚点")
    }

    private var moduleBackground: some View {
        RoundedRectangle(
            cornerRadius: ConfigurationUI.cardCornerRadius,
            style: .continuous
        )
        .fill(ConfigurationUI.panelBackground)
        .overlay(
            RoundedRectangle(
                cornerRadius: ConfigurationUI.cardCornerRadius,
                style: .continuous
            )
            .stroke(ConfigurationUI.faintHairline)
        )
    }

    private func requestDeletion(
        _ anchor: MemorySubject.TimeAnchor
    ) {
        guard (
            session.state.selectedSubject?.timeAnchors.count
            ?? subject?.timeAnchors.count
            ?? 0
        ) > 1 else {
            showsLastAnchorWarning = true
            return
        }

        pendingDeleteAnchor = anchor
    }

    private func deletePendingAnchor() {
        guard let anchor = pendingDeleteAnchor,
              let updatedSubject =
                session.state.selectedSubject?
                .removingTimeAnchor(id: anchor.id) else {
            pendingDeleteAnchor = nil
            return
        }

        session.updateSelectedSubject(updatedSubject)
        pendingDeleteAnchor = nil
        onPersistSubjectChanges()
    }

    private func commitEditingDraft() {
        guard let editingDraft,
              var updatedSubject = session.state.selectedSubject else {
            return
        }

        var anchor = editingDraft.anchor
        let trimmedTitle = anchor.title.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        anchor.title = trimmedTitle.isEmpty
            ? anchor.resolvedAnchorType.suggestedTitle
            : trimmedTitle

        if editingDraft.originalID != nil,
           let replacementSubject =
            updatedSubject.replacingTimeAnchor(anchor) {
            updatedSubject = replacementSubject
        } else if updatedSubject.timeAnchors.count < 5 {
            updatedSubject.timeAnchors.append(anchor)
        }

        session.updateSelectedSubject(updatedSubject)
        onPersistSubjectChanges()
        self.editingDraft = nil
    }
}

private struct AnchorDraft: Identifiable {

    let id = UUID()
    let originalID: MemorySubject.TimeAnchor.ID?
    var anchor: MemorySubject.TimeAnchor
}

struct V1IOSSubjectAnchorDetailModule: View {

    static let ordinaryMinimumHeight: CGFloat = 64

    let anchor: MemorySubject.TimeAnchor
    let onConfigure: () -> Void
    let onDelete: () -> Void
    let leadingContentInset: CGFloat

    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 8) {
                    anchorFacts
                    anchorTypeMarker
                }
            } else {
                HStack(alignment: .center, spacing: 16) {
                    anchorFacts
                    Spacer(minLength: 8)
                    anchorTypeMarker
                }
            }
        }
        .padding(.leading, 16 + leadingContentInset)
        .padding(.trailing, 16)
        .padding(.vertical, 9)
        .frame(
            maxWidth: .infinity,
            minHeight: Self.ordinaryMinimumHeight,
            alignment: .leading
        )
        .background(
            RoundedRectangle(
                cornerRadius: ConfigurationUI.cardCornerRadius,
                style: .continuous
            )
            .fill(ConfigurationUI.panelBackground)
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: ConfigurationUI.cardCornerRadius,
                style: .continuous
            )
            .stroke(ConfigurationUI.faintHairline)
        )
        .contentShape(Rectangle())
        .contextMenu {
            Button("配置", action: onConfigure)
            Button("删除", role: .destructive, action: onDelete)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(anchor.title)，\(dateText)，\(anchorTypeAccessibilityLabel)"
        )
        .accessibilityAction(named: "配置锚点") {
            onConfigure()
        }
        .accessibilityAction(named: "删除锚点") {
            onDelete()
        }
    }

    private var anchorFacts: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(anchor.title)
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)

            Text(dateText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var anchorTypeMarker: some View {
        Text(anchor.resolvedAnchorType.compactDisplayName)
            .font(.caption.weight(.semibold))
            .foregroundStyle(anchorTypeTint)
            .multilineTextAlignment(
                dynamicTypeSize.isAccessibilitySize
                ? .leading
                : .trailing
            )
            .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(anchorTypeAccessibilityLabel)
    }

    private var anchorTypeAccessibilityLabel: String {
        let typeName = anchor.resolvedAnchorType.localizedDisplayName(
            for: .interfaceStored
        )
        return MemoMarkLanguage.interfaceStored == .simplifiedChinese
            ? "类型，\(typeName)"
            : "Type, \(typeName)"
    }

    private var anchorTypeTint: Color {
        switch anchor.resolvedAnchorType {
        case .birthday:
            return .orange
        case .relationship:
            return .pink
        case .marriage:
            return .purple
        case .exam:
            return .green
        case .custom:
            return .blue
        }
    }

    private var dateText: String {
        V1UserFacingDateFormatter.date(anchor.date)
    }
}

private struct V1IOSSubjectAnchorCompactEditor: View {

    @State
    private var anchor: MemorySubject.TimeAnchor

    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize

    let onChange: (MemorySubject.TimeAnchor) -> Void
    let onSave: () -> Void

    init(
        initialAnchor: MemorySubject.TimeAnchor,
        onChange: @escaping (MemorySubject.TimeAnchor) -> Void,
        onSave: @escaping () -> Void
    ) {
        _anchor = State(initialValue: initialAnchor)
        self.onChange = onChange
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    categoryRow

                    CompactSubjectAnchorDatePicker(
                        selection: Binding(
                            get: { anchor.date },
                            set: { newDate in
                                anchor.date = newDate
                                onChange(anchor)
                            }
                        )
                    )

                    adaptiveNameRow
                }
                .padding(.horizontal, ConfigurationUI.contentColumnPadding)
                .padding(.bottom, 20)
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                V1ConfigurationSheetSubtitle(
                    "选择一个时间起点，让照片拥有时间答案。"
                )
            }
            .scrollDismissesKeyboard(.interactively)
            .background(ConfigurationUI.appBackground)
            .navigationTitle("时间锚点")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var adaptiveNameRow: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 10) {
                    nameLabel
                    nameField
                    saveButton
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            } else {
                HStack(alignment: .center, spacing: 12) {
                    nameLabel

                    Rectangle()
                        .fill(ConfigurationUI.faintHairline)
                        .frame(width: 1, height: 24)

                    nameField

                    saveButton
                }
            }
        }
        .padding(.horizontal, ConfigurationUI.sheetPanelPadding)
        .padding(.vertical, ConfigurationUI.compactRowVerticalPadding)
        .frame(minHeight: ConfigurationUI.minimumInteractiveHeight)
        .v1ConfigurationSheetPanelChrome()
    }

    private var nameLabel: some View {
        Text("自定义名称")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(minWidth: 76, alignment: .leading)
    }

    private var nameField: some View {
        TextField(
            anchor.resolvedAnchorType.suggestedTitle,
            text: Binding(
                get: { anchor.title },
                set: { newTitle in
                    anchor.title = newTitle
                    onChange(anchor)
                }
            )
        )
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity)
        .submitLabel(.done)
    }

    private var saveButton: some View {
        Button("保存") {
            onSave()
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.regular)
        .font(.subheadline.weight(.semibold))
        .frame(
            minWidth: ConfigurationUI.minimumInteractiveHeight,
            minHeight: ConfigurationUI.minimumInteractiveHeight
        )
    }

    private var categoryRow: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 8) {
                    categoryLabel
                    categorySelection
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            } else {
                HStack(alignment: .center, spacing: 12) {
                    categoryLabel
                    Spacer(minLength: 12)
                    categorySelection
                }
            }
        }
        .padding(.horizontal, ConfigurationUI.sheetPanelPadding)
        .padding(.vertical, ConfigurationUI.compactRowVerticalPadding)
        .frame(
            maxWidth: .infinity,
            minHeight: ConfigurationUI.minimumInteractiveHeight,
            alignment: .leading
        )
        .v1ConfigurationSheetPanelChrome()
    }

    private var categorySelection: some View {
        HStack(alignment: .center, spacing: 12) {
            categoryMenu

            Rectangle()
                .fill(ConfigurationUI.faintHairline)
                .frame(width: 1, height: 24)

            selectedDateText
        }
    }

    private var categoryLabel: some View {
        Text("锚点类别")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(minWidth: 76, alignment: .leading)
    }

    private var categoryMenu: some View {
        Menu {
            ForEach(AnchorType.allCases, id: \.self) { type in
                Button {
                    updateAnchorType(type)
                } label: {
                    HStack {
                        Text(type.displayName)
                        if type == anchor.resolvedAnchorType {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            V1CompactSelectionLabel(
                title: anchor.resolvedAnchorType.displayName
            )
        }
        .tint(.secondary)
    }

    private var selectedDateText: some View {
        Text(V1UserFacingDateFormatter.date(anchor.date))
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.primary)
            .lineLimit(2)
            .accessibilityLabel("已选日期")
    }

    private func updateAnchorType(_ newType: AnchorType) {
        let previousType = anchor.resolvedAnchorType
        let previousGeneratedTitle = previousType.suggestedTitle
        anchor.anchorType = newType
        anchor.expressionStyle = .defaultStyle(for: newType)
        if anchor.title.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty || anchor.title == previousGeneratedTitle {
            anchor.title = newType.suggestedTitle
        }
        onChange(anchor)
    }
}

private struct CompactSubjectAnchorDatePicker: View {

    @Binding
    var selection: Date

    var body: some View {
        DatePicker(
            "时间",
            selection: $selection,
            displayedComponents: .date
        )
        .datePickerStyle(.wheel)
        .labelsHidden()
        .frame(height: 154)
        .clipped()
        .accessibilityLabel("锚点时间")
    }
}
#endif
