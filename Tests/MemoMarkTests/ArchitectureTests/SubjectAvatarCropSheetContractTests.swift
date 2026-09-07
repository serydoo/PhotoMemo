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

    @Test("crop stage uses the native scroll view crop interaction")
    func cropStageUsesNativeScrollViewCropInteraction() throws {
        let source = try String(
            contentsOfFile: MemoMarkTestPaths.path(
                "Source/MemoMark/MemoMark/ConfigurationCenter/Editors/SubjectAvatarCropSheet.swift"
            ),
            encoding: .utf8
        )

        #expect(source.contains("SubjectAvatarCropViewport"))
        #expect(source.contains("UIScrollViewDelegate"))
        #expect(source.contains("scrollView.bouncesZoom = true"))
        #expect(source.contains("scrollView.contentSize = scaledSize"))
        #expect(source.contains("let cropInset = min("))
        #expect(source.contains("imageView.superview?.convert"))
        #expect(source.contains("scrollView.isDecelerating"))
        #expect(source.contains("setBaseImageViewFrame"))
        #expect(
            source.contains(
                "x: scaledMidX - canvasMidX - translation.width"
            )
        )
        #expect(
            source.contains(
                "x: scaledSize.width / 2"
            )
        )
        #expect(!source.contains("MagnificationGesture"))
        #expect(source.contains("configurationPreservingCropCenter"))
    }

    @Test("crop stage replays the configuration after canvas geometry changes")
    func cropStageReplaysConfigurationAfterCanvasGeometryChanges() throws {
        let source = try String(
            contentsOfFile: MemoMarkTestPaths.path(
                "Source/MemoMark/MemoMark/ConfigurationCenter/Editors/SubjectAvatarCropSheet.swift"
            ),
            encoding: .utf8
        )

        #expect(source.contains("let configurationToRestore = parent.configuration"))
        #expect(source.contains("isApplying = true\n                lastApplied = nil"))
        #expect(source.contains("preservingTranslation: .zero"))
        #expect(
            source.contains(
                "apply(\n                    configurationToRestore,\n                    to: scrollView,\n                    animated: false\n                )"
            )
        )
    }

    @Test("crop stage establishes a square layout before measuring the image")
    func cropStageEstablishesSquareLayoutBeforeMeasuringImage() throws {
        let source = try String(
            contentsOfFile: MemoMarkTestPaths.path(
                "Source/MemoMark/MemoMark/ConfigurationCenter/Editors/SubjectAvatarCropSheet.swift"
            ),
            encoding: .utf8
        )

        #expect(
            source.contains(
                "Color.clear\n            .aspectRatio(1, contentMode: .fit)\n            .overlay"
            )
        )
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
