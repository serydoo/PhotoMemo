#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing

@Suite("Subject avatar crop sheet contract")
struct SubjectAvatarCropSheetContractTests {

    @Test("crop editor owns an opaque full-screen surface")
    func cropEditorOwnsOpaqueFullScreenSurface() throws {
        let source = try String(
            contentsOfFile: MemoMarkTestPaths.path(
                "Source/MemoMark/MemoMark/ConfigurationCenter/Editors/SubjectAvatarCropSheet.swift"
            ),
            encoding: .utf8
        )

        #expect(source.contains("ConfigurationUI.appBackground.ignoresSafeArea()"))
        #expect(source.contains(".presentationBackground(ConfigurationUI.appBackground)"))
        #expect(source.contains(".toolbarBackground(.visible, for: .navigationBar)"))
    }

    @Test("crop editor keeps the primary action as completion")
    func cropEditorKeepsPrimaryActionAsCompletion() throws {
        let source = try String(
            contentsOfFile: MemoMarkTestPaths.path(
                "Source/MemoMark/MemoMark/ConfigurationCenter/Editors/SubjectAvatarCropSheet.swift"
            ),
            encoding: .utf8
        )

        #expect(source.contains("key: \"avatar.crop.done\""))
        #expect(!source.contains("Button(\"应用\")"))
        #expect(!source.contains("private func statPill("))
    }
}
#endif
