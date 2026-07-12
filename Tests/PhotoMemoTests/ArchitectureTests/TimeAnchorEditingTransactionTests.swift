#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("Time Anchor editing transaction")
struct TimeAnchorEditingTransactionTests {

    @Test("Time Anchor rows expose native configure and delete swipe actions")
    func timeAnchorRowsExposeConfigureAndDeleteSwipeActions() throws {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let sourceURL = repositoryRoot.appendingPathComponent(
            "Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Editors/MemorySubjectEditorView.swift"
        )
        let source = try String(contentsOf: sourceURL, encoding: .utf8)

        #expect(source.contains("allowsFullSwipe: true"))
        #expect(source.contains("Label(\"配置\", systemImage: \"slider.horizontal.3\")"))
        #expect(source.contains(".tint(.blue)"))
        #expect(source.contains("Label(\"删除\", systemImage: \"trash\")"))
        #expect(!source.contains("Text(\"配置\")"))
        #expect(!source.contains(".onTapGesture {\n            onConfigure()\n        }"))
        #expect(source.contains("左滑锚点可配置或删除"))
        #expect(source.contains("Text(\"锚点名称\")"))
        #expect(source.contains("可保留预设名称，也可输入自定义名称"))
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
}
#endif
