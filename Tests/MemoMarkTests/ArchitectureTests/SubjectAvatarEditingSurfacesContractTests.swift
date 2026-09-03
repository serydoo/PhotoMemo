#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing

@Suite("Subject avatar editing surface contract")
struct SubjectAvatarEditingSurfacesContractTests {

    @Test("editor retains avatar lifecycle ownership while surfaces render controls")
    func editorRetainsAvatarLifecycleOwnership() throws {
        let editor = try String(
            contentsOfFile: MemoMarkTestPaths.path(
                "Source/MemoMark/MemoMark/ConfigurationCenter/Editors/MemorySubjectEditorView.swift"
            ),
            encoding: .utf8
        )
        let surfaces = try String(
            contentsOfFile: MemoMarkTestPaths.path(
                "Source/MemoMark/MemoMark/ConfigurationCenter/Editors/SubjectAvatarEditingSurfaces.swift"
            ),
            encoding: .utf8
        )

        #expect(editor.contains("SubjectAvatarDetailedEditorSurface("))
        #expect(editor.contains("SubjectAvatarContactEditorSurface("))
        #expect(editor.contains("private func prepareSelectedAvatar("))
        #expect(editor.contains("private func applyAvatarCrop("))
        #expect(editor.contains("private func syncDraftToSession("))
        #expect(surfaces.contains("struct SubjectAvatarDetailedEditorSurface"))
        #expect(surfaces.contains("struct SubjectAvatarContactEditorSurface"))
        #expect(surfaces.contains("let onRemove: () -> Void"))
        #expect(!surfaces.contains("SubjectAvatarAssetOptimizing"))
        #expect(!surfaces.contains("updateSelectedSubject"))
    }
}
#endif
