#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing

@Suite("Subject time-anchor presentation surface responsibility contract")
struct SubjectTimeAnchorEditorSurfaceContractTests {

    @Test("time-anchor list presentation is separate from subject draft persistence")
    func selectionCardReceivesImmutableAnchorsAndExplicitParentActions() throws {
        let editor = try String(
            contentsOfFile: MemoMarkTestPaths.path(
                "Source/MemoMark/MemoMark/ConfigurationCenter/Editors/MemorySubjectEditorView.swift"
            ),
            encoding: .utf8
        )
        let surface = try String(
            contentsOfFile: MemoMarkTestPaths.path(
                "Source/MemoMark/MemoMark/ConfigurationCenter/Editors/SubjectTimeAnchorPresentationSurfaces.swift"
            ),
            encoding: .utf8
        )

        #expect(editor.contains("SubjectTimeAnchorSelectionCard("))
        #expect(editor.contains("private func openTimeAnchorSheet("))
        #expect(editor.contains("private func syncDraftToSession("))
        #expect(surface.contains("struct SubjectTimeAnchorSelectionCard"))
        #expect(surface.contains("let anchors: [MemorySubject.TimeAnchor]"))
        #expect(surface.contains("let editingAnchorID: UUID?"))
        #expect(surface.contains("let onAdd: () -> Void"))
        #expect(surface.contains("struct SubjectTimeAnchorAddRow"))
        #expect(!surface.contains("ConfigurationSession"))
        #expect(!surface.contains("syncDraftToSession"))
        #expect(!surface.contains("SubjectAvatarAssetOptimizing"))
    }
}
#endif
