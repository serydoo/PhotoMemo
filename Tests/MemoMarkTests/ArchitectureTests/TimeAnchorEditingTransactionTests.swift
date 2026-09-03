#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing
@testable import MemoMark

@Suite("Time Anchor editing transaction")
struct TimeAnchorEditingTransactionTests {

    @Test("iOS add and edit share a titled compact Time Anchor editor")
    func iosAddAndEditShareTitledCompactEditor() throws {
        let source = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/SubjectAnchorDetailSection.swift"
        )

        #expect(source.contains("private struct SubjectAnchorCompactEditor: View"))
        #expect(
            source.components(
                separatedBy: "editingDraft = AnchorDraft("
            ).count >= 3
        )
        #expect(
            source.components(
                separatedBy: "SubjectAnchorCompactEditor("
            ).count == 2
        )
        #expect(source.contains("NavigationStack {"))
        #expect(source.contains(".navigationTitle(\"时间锚点\")"))
        #expect(source.contains(".navigationBarTitleDisplayMode(.inline)"))
        #expect(source.contains("ConfigurationSheetSubtitle("))
        #expect(source.contains(".safeAreaInset(edge: .top, spacing: 0)"))
        #expect(
            source.contains(
                "选择一个时间起点，让照片拥有时间答案。"
            )
        )
        let nameRow = try sourceSection(
            in: source,
            from: "private var adaptiveNameRow",
            to: "private var nameLabel"
        )
        let anchorSetupPanel = try sourceSection(
            in: source,
            from: "private var anchorSetupPanel",
            to: "private var typeColumns"
        )
        #expect(nameRow.contains("dynamicTypeSize.isAccessibilitySize"))
        #expect(nameRow.contains("HStack(alignment: .center"))
        #expect(!nameRow.contains("ViewThatFits(in: .horizontal)"))
        #expect(anchorSetupPanel.contains("LazyVGrid(columns: typeColumns"))
        #expect(anchorSetupPanel.contains("这个日子属于哪一类？"))
        #expect(!anchorSetupPanel.contains("ViewThatFits(in: .horizontal)"))
    }

    @Test("Time Anchor rows expose native configure and delete swipe actions")
    func timeAnchorRowsExposeConfigureAndDeleteSwipeActions() throws {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let sourceURL = repositoryRoot.appendingPathComponent(
            "Source/MemoMark/MemoMark/ConfigurationCenter/Editors/MemorySubjectEditorView.swift"
        )
        let source = try String(contentsOf: sourceURL, encoding: .utf8)
        let rowSource = try sourceText(
            "Source/MemoMark/MemoMark/ConfigurationCenter/Editors/SubjectTimeAnchorRow.swift"
        )
        let nativeListSource = try sourceSection(
            in: source,
            from: "private var timeAnchorListEditor",
            to: "private var anchorBinding"
        )
        let presentationSource = source + rowSource
        let disablesFullSwipe = presentationSource.contains("allowsFullSwipe: false")
        let usesRootNativeList = nativeListSource.contains("List {")
            && !nativeListSource.contains("ScrollView")
        let usesNativeConfigureAction = presentationSource.contains(
            "Label(\"配置\", systemImage: \"slider.horizontal.3\")"
        )
        let usesNativeDeleteAction = presentationSource.contains(
            "Label(\"删除\", systemImage: \"trash\")"
        )
        let usesReadableRowHeight =
            rowSource.contains("SubjectTimeAnchorMetrics.rowHeight")
            && rowSource.contains("static let rowHeight: CGFloat = 52")
            && rowSource.contains(
                ".frame(minHeight: SubjectTimeAnchorMetrics.rowHeight)"
            )
        let usesExplicitCustomNameLabel = source.contains(
            "Text(\"自定义锚点名称\")"
        )

        #expect(disablesFullSwipe)
        #expect(usesRootNativeList)
        #expect(usesNativeConfigureAction)
        #expect(presentationSource.contains(".tint(.blue)"))
        #expect(usesNativeDeleteAction)
        #expect(usesReadableRowHeight)
        #expect(!source.contains("Text(\"配置\")"))
        #expect(!source.contains(".onTapGesture {\n            onConfigure()\n        }"))
        #expect(source.contains("左滑可配置或删除"))
        #expect(usesExplicitCustomNameLabel)
        #expect(source.contains("取消则恢复原值"))
    }

    @Test("anchor date wheel exposes surrounding choices at native readable height")
    func anchorDateWheelExposesSurroundingChoicesAtReadableHeight() throws {
        let pickerSource = try sourceText(
            "Source/MemoMark/MemoMark/ConfigurationCenter/Editors/CompactAnchorDatePicker.swift"
        )

        #expect(pickerSource.contains("static let wheelHeight: CGFloat = 144"))
        #expect(
            pickerSource.contains(".frame(height: Self.wheelHeight)")
            || pickerSource.contains(".frame(height: 144)")
        )
        #expect(!pickerSource.contains(".frame(height: 52)"))
        #expect(pickerSource.contains(".pickerStyle(.wheel)"))
    }

    @Test("anchor editor distinguishes add and edit and uses explicit field labels")
    func anchorEditorDistinguishesAddAndEditAndUsesExplicitFieldLabels() throws {
        let source = try sourceText(
            "Source/MemoMark/MemoMark/ConfigurationCenter/Editors/MemorySubjectEditorView.swift"
        )
        let sheetSource = try sourceSection(
            in: source,
            from: "private var timeAnchorConfigurationSheet",
            to: "private func openTimeAnchorSheet"
        )

        #expect(sheetSource.contains("\"新增时间锚点\""))
        #expect(sheetSource.contains("\"编辑时间锚点\""))
        #expect(sheetSource.contains("\"锚点日期\""))
        #expect(sheetSource.contains("\"锚点类型\""))
        #expect(sheetSource.contains("\"自定义锚点名称\""))
        #expect(!sheetSource.contains("Section(\"时间与类别\")"))
        #expect(!sheetSource.contains("Picker(\n                            \"类型\""))
        #expect(!sheetSource.contains("Text(\"锚点名称\")"))
        #expect(!sheetSource.contains(".navigationTitle(anchorBinding.wrappedValue.title)"))
    }

    @Test("anchor list uses neutral chrome and semantic-color compact type labels")
    func anchorListUsesSemanticColorCompactTypeLabels() throws {
        let rowSource = try sourceText(
            "Source/MemoMark/MemoMark/ConfigurationCenter/Editors/SubjectTimeAnchorRow.swift"
        )
        let listSource = try sourceText(
            "Source/MemoMark/MemoMark/ConfigurationCenter/Editors/SubjectTimeAnchorPresentationSurfaces.swift"
        )
        #expect(!listSource.contains(".configurationPanelChrome(isSelected: true)"))
        #expect(!listSource.contains(".frame(height: SubjectTimeAnchorMetrics"))
        #expect(rowSource.contains("anchor.resolvedAnchorType.compactDisplayName"))
        #expect(rowSource.contains(".foregroundStyle(anchorTypeTint)"))
        #expect(rowSource.contains("switch anchor.resolvedAnchorType"))
        #expect(rowSource.contains("Menu {"))
        #expect(rowSource.contains("accessibility.anchor_actions"))
        #expect(rowSource.contains("accessibilityLabel"))
        #expect(!rowSource.contains("anchorTypeIconName"))
        #expect(!rowSource.contains("Capsule(style: .continuous)"))
        #expect(!rowSource.contains("Text(\"\\(index)\")"))
    }

    @Test("anchor swipe delete opens confirmation without claiming immediate destruction")
    func anchorSwipeDeleteOpensConfirmationWithoutClaimingImmediateDestruction() throws {
        let source = try sourceText(
            "Source/MemoMark/MemoMark/ConfigurationCenter/Editors/SubjectTimeAnchorRow.swift"
        )
        let normalizedSource = source.replacingOccurrences(
            of: "\\s+",
            with: " ",
            options: .regularExpression
        )
        let normalizedSwipeSource = source
            .components(separatedBy: ".alert(")
            .first?
            .replacingOccurrences(
                of: "\\s+",
                with: " ",
                options: .regularExpression
            ) ?? ""

        #expect(
            normalizedSwipeSource.contains(
                "Button(role: .destructive) { showsDeleteConfirmation = true"
            )
        )
        #expect(normalizedSwipeSource.contains(".tint(.red)"))
        #expect(
            normalizedSource.contains(
                "Button(role: .destructive) { showsDeleteConfirmation = true"
            )
        )
        #expect(
            normalizedSource.contains(
                "Button(\"删除锚点\", role: .destructive)"
            )
        )
    }

    @Test("existing anchor transaction preserves the original value and selection")
    func existingAnchorTransactionPreservesOriginalState() {
        let anchor = MemorySubject.TimeAnchor(
            title: "生日",
            date: Date(timeIntervalSince1970: 1_000),
            note: "出生时间",
            anchorType: .birthday,
            expressionStyle: .defaultStyle(for: .birthday)
        )
        let transaction = TimeAnchorEditingTransaction(
            anchorID: anchor.id,
            originalAnchor: anchor,
            originalSelectedAnchorID: anchor.id
        )

        #expect(transaction.originalAnchor == anchor)
        #expect(transaction.originalSelectedAnchorID == anchor.id)
        #expect(!transaction.isNewAnchor)
    }

    @Test("new anchor transaction is identified by its missing original value")
    func newAnchorTransactionIsIdentified() {
        let anchorID = UUID()
        let selectedAnchorID = UUID()
        let transaction = TimeAnchorEditingTransaction(
            anchorID: anchorID,
            originalAnchor: nil,
            originalSelectedAnchorID: selectedAnchorID
        )

        #expect(transaction.anchorID == anchorID)
        #expect(transaction.originalSelectedAnchorID == selectedAnchorID)
        #expect(transaction.isNewAnchor)
    }

    @Test("cancelling an existing anchor restores its value and original selection")
    func existingAnchorRollbackRestoresValueAndSelection() {
        let original = MemorySubject.TimeAnchor(
            title: "生日",
            date: Date(timeIntervalSince1970: 1_000),
            note: "出生时间",
            anchorType: .birthday,
            expressionStyle: .defaultStyle(for: .birthday)
        )
        let other = MemorySubject.TimeAnchor(
            title: "重要日子",
            date: Date(timeIntervalSince1970: 2_000),
            note: "",
            anchorType: .custom,
            expressionStyle: .defaultStyle(for: .custom)
        )
        var edited = original
        edited.title = "已修改"
        edited.date = Date(timeIntervalSince1970: 3_000)
        edited.anchorType = .exam

        let rollback = TimeAnchorEditingTransaction(
            anchorID: original.id,
            originalAnchor: original,
            originalSelectedAnchorID: other.id
        ).rollback(
            anchors: [edited, other],
            selectedAnchorID: original.id
        )

        #expect(rollback.anchors == [original, other])
        #expect(rollback.selectedAnchorID == other.id)
    }

    @Test("cancelling a new anchor removes it and restores the original selection")
    func newAnchorRollbackRemovesTemporaryAnchor() {
        let existing = MemorySubject.TimeAnchor(
            title: "生日",
            date: Date(timeIntervalSince1970: 1_000),
            note: "",
            anchorType: .birthday,
            expressionStyle: .defaultStyle(for: .birthday)
        )
        let temporary = MemorySubject.TimeAnchor(
            title: "新锚点",
            date: Date(timeIntervalSince1970: 2_000),
            note: "",
            anchorType: .custom,
            expressionStyle: .defaultStyle(for: .custom)
        )

        let rollback = TimeAnchorEditingTransaction(
            anchorID: temporary.id,
            originalAnchor: nil,
            originalSelectedAnchorID: existing.id
        ).rollback(
            anchors: [existing, temporary],
            selectedAnchorID: temporary.id
        )

        #expect(rollback.anchors == [existing])
        #expect(rollback.selectedAnchorID == existing.id)
    }
}

private extension TimeAnchorEditingTransactionTests {

    func sourceText(_ relativePath: String) throws -> String {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        return try String(
            contentsOf: repositoryRoot.appendingPathComponent(relativePath),
            encoding: .utf8
        )
    }

    func sourceSection(
        in source: String,
        from startMarker: String,
        to endMarker: String
    ) throws -> String {
        let start = try #require(source.range(of: startMarker))
        let end = try #require(
            source.range(
                of: endMarker,
                range: start.upperBound..<source.endIndex
            )
        )
        return String(source[start.lowerBound..<end.lowerBound])
    }
}
#endif
