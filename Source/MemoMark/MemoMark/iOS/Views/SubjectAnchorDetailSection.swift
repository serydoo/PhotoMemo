#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI

struct SubjectAnchorDetailSection: View {

    @ObservedObject
    var session: ConfigurationSession

    let onPersistSubjectChanges: () -> Void
    let allowsSwipeDeletion: Bool

    init(
        session: ConfigurationSession,
        onPersistSubjectChanges: @escaping () -> Void,
        allowsSwipeDeletion: Bool = false
    ) {
        self.session = session
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
        if let subject = session.state.selectedSubject {
            VStack(spacing: 0) {
                ForEach(
                    Array(subject.timeAnchors.enumerated()),
                    id: \.element.id
                ) { index, anchor in
                    SubjectAnchorDetailModule(
                        anchor: anchor,
                        subjectName: subject.identity.shortName,
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

                    if index < subject.timeAnchors.count - 1 {
                        HorizontalDivider(horizontalInset: 16)
                    }
                }

                if subject.timeAnchors.count < 5 {
                    HorizontalDivider(horizontalInset: 16)
                    if subject.timeAnchors.isEmpty {
                        // Legacy records may still open with no anchors while
                        // their draft is being repaired. Expose the empty
                        // state as the same actionable row contract so the
                        // editor remains usable even before the draft
                        // projection settles.
                        addAnchorModule
                            .accessibilityIdentifier("subject-anchor-row")
                    } else {
                        addAnchorModule
                    }
                } else {
                    HorizontalDivider(horizontalInset: 16)
                    Text("最多保留 5 个时间锚点")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .v1ConfigurationSheetPanelChrome()
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("subject-anchor-group")
            .sheet(
                item: $editingDraft,
                onDismiss: commitEditingDraft
            ) { draft in
                SubjectAnchorCompactEditor(
                    initialAnchor: draft.anchor,
                    onChange: { anchor in
                        editingDraft?.anchor = anchor
                    },
                    onSave: {
                        commitEditingDraft()
                    }
                )
                .presentationDetents([.large])
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
            .accessibilityIdentifier("subject-add-anchor")
        }
        .buttonStyle(.plain)
        .accessibilityLabel("添加时间锚点")
        .accessibilityIdentifier("subject-add-anchor")
    }

    private func requestDeletion(
        _ anchor: MemorySubject.TimeAnchor
    ) {
        guard (
            session.state.selectedSubject?.timeAnchors.count
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

struct SubjectAnchorDetailModule: View {

    static let ordinaryMinimumHeight: CGFloat = 64

    let anchor: MemorySubject.TimeAnchor
    let subjectName: String
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
        .contentShape(Rectangle())
        .onTapGesture(perform: onConfigure)
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
        .accessibilityIdentifier("subject-anchor-row")
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

            TimelineView(.periodic(from: .now, by: 3_600)) { context in
                Text(
                    TimeAnchorTodayPresenter.presentation(
                        anchor: anchor,
                        subjectName: subjectName,
                        referenceDate: context.date
                    ).value
                )
                .font(.caption.weight(.medium))
                .foregroundStyle(anchorTypeTint)
                .monospacedDigit()
                .contentTransition(.numericText())
                .lineLimit(2)
            }
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
        UserFacingDateFormatter.date(anchor.date)
    }
}

private struct SubjectAnchorCompactEditor: View {

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
                    anchorSetupPanel

                    todayAnswerPreview

                    saveButton

                    usageGuidance
                }
                .padding(.horizontal, ConfigurationUI.contentColumnPadding)
                .padding(.bottom, 20)
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                ConfigurationSheetSubtitle(
                    "选择一个时间起点，让照片拥有时间答案。"
                )
            }
            .scrollDismissesKeyboard(.interactively)
            .background(ConfigurationUI.appBackground)
            .navigationTitle("时间锚点")
            .navigationBarTitleDisplayMode(.inline)
            .accessibilityIdentifier("subject-anchor-editor")
            .sensoryFeedback(
                .selection,
                trigger: anchor.resolvedAnchorType
            )
        }
    }

    private var adaptiveNameRow: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 10) {
                    nameLabel
                    nameField
                }
            } else {
                HStack(alignment: .center, spacing: 12) {
                    nameLabel

                    Rectangle()
                        .fill(ConfigurationUI.faintHairline)
                        .frame(width: 1, height: 24)

                    nameField
                }
            }
        }
        .padding(.vertical, ConfigurationUI.compactRowVerticalPadding)
        .frame(minHeight: ConfigurationUI.minimumInteractiveHeight)
    }

    private var nameLabel: some View {
        Text("名称")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(minWidth: 48, alignment: .leading)
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
        .accessibilityIdentifier("anchor-editor-name")
        .submitLabel(.done)
    }

    private var saveButton: some View {
        Button {
            onSave()
        } label: {
            Text("保存时间锚点")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.regular)
        .font(.subheadline.weight(.semibold))
        .frame(minHeight: ConfigurationUI.minimumInteractiveHeight)
        .accessibilityIdentifier("anchor-editor-save")
    }

    private var todayAnswerPreview: some View {
        TimelineView(.periodic(from: .now, by: 3_600)) { context in
            let presentation = TimeAnchorTodayPresenter.presentation(
                anchor: anchor,
                subjectName: anchor.title,
                referenceDate: context.date
            )

            VStack(alignment: .leading, spacing: 9) {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(Color.accentColor.opacity(0.1))
                        )

                    VStack(alignment: .leading, spacing: 3) {
                        Text("今天的时间答案")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(presentation.value)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.primary)
                            .monospacedDigit()
                            .contentTransition(.numericText())
                            .lineLimit(2)
                    }

                    Spacer(minLength: 0)
                }

                Text("这里先按今天预览；处理照片时，会按每张照片的拍摄时间计算。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, ConfigurationUI.sheetPanelPadding)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .v1ConfigurationSheetPanelChrome()
            .accessibilityElement(children: .combine)
            .accessibilityLabel(presentation.accessibilityText)
        }
    }

    private var anchorSetupPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("这个日子属于哪一类？")
                .font(.headline)
                .foregroundStyle(.primary)

            Text("类型决定它会表达年龄、纪念时间还是未来倒数。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            LazyVGrid(columns: typeColumns, spacing: 8) {
                ForEach(AnchorType.allCases, id: \.self) { type in
                    typeChoice(type)
                }
            }

            Text(typeHelperText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            VStack(alignment: .leading, spacing: 3) {
                Text("日期")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("设置这个重要日子发生或开始的日期。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            CompactSubjectAnchorDatePicker(
                selection: Binding(
                    get: { anchor.date },
                    set: { newDate in
                        anchor.date = newDate
                        onChange(anchor)
                    }
                )
            )
            .frame(maxWidth: .infinity)

            Divider()

            adaptiveNameRow
        }
        .padding(.horizontal, ConfigurationUI.sheetPanelPadding)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .v1ConfigurationSheetPanelChrome()
    }

    private var typeColumns: [GridItem] {
        if dynamicTypeSize.isAccessibilitySize {
            return [GridItem(.flexible(), spacing: 8)]
        }

        return [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8)
        ]
    }

    private func typeChoice(_ type: AnchorType) -> some View {
        let isSelected = type == anchor.resolvedAnchorType
        let tint = anchorTypeTint(type)

        return Button {
            updateAnchorType(type)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: anchorTypeSymbol(type))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(tint)
                    .frame(width: 18)

                Text(anchorTypeSelectionTitle(type))
                    .font(.subheadline.weight(isSelected ? .semibold : .regular))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Spacer(minLength: 4)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(tint)
                }
            }
            .padding(.horizontal, 12)
            .frame(
                maxWidth: .infinity,
                minHeight: ConfigurationUI.minimumInteractiveHeight,
                alignment: .leading
            )
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        isSelected
                        ? tint.opacity(0.1)
                        : ConfigurationUI.controlBackground
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(
                        isSelected
                        ? tint.opacity(0.32)
                        : ConfigurationUI.faintHairline
                    )
            )
        }
        .accessibilityIdentifier("anchor-type-\(type.rawValue)")
        .buttonStyle(.plain)
        .accessibilityLabel(anchorTypeSelectionTitle(type))
        .accessibilityValue(isSelected ? "已选择" : "未选择")
    }

    private var typeHelperText: String {
        switch anchor.resolvedAnchorType {
        case .birthday:
            return "用照片拍摄时间计算当时的年龄，也可以表达出生前倒数。"
        case .relationship:
            return "用照片拍摄时间表达相识或相伴了多久。"
        case .marriage:
            return "用照片拍摄时间表达共同走过的时间和纪念日。"
        case .exam:
            return "用照片拍摄时间表达距离目标还有多久。"
        case .custom:
            return "为旅行、毕业、搬家或其他人生时刻设置自己的时间起点。"
        }
    }

    private func anchorTypeSelectionTitle(_ type: AnchorType) -> String {
        switch type {
        case .birthday:
            return "生日 / 出生"
        case .relationship:
            return "恋爱纪念"
        case .marriage:
            return "结婚纪念"
        case .exam:
            return "未来目标"
        case .custom:
            return "自定义"
        }
    }

    private func anchorTypeSymbol(_ type: AnchorType) -> String {
        switch type {
        case .birthday:
            return "birthday.cake"
        case .relationship:
            return "heart"
        case .marriage:
            return "heart.circle"
        case .exam:
            return "target"
        case .custom:
            return "ellipsis"
        }
    }

    private func anchorTypeTint(_ type: AnchorType) -> Color {
        switch type {
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

    private var usageGuidance: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("设置后会怎样？")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            guidanceRow(number: 1, text: "在配置中心选择这个重要日子。")
            guidanceRow(number: 2, text: "处理照片时，会按每张照片的拍摄时间计算。")
            guidanceRow(number: 3, text: "最终怎样写在记忆卡上，仍然由你决定。")
        }
        .padding(.horizontal, ConfigurationUI.sheetPanelPadding)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func guidanceRow(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(number)")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 20, height: 20)
                .background(
                    Circle()
                        .fill(Color.accentColor.opacity(0.1))
                )

            Text(text)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
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
