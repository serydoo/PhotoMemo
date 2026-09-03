#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing

@Suite("UIKit photo picker presentation responsibility contract")
struct UIKitPhotoPickerContractTests {

    @Test("UIKit picker surface stays separate from foreground intake and output owners")
    func pickerSurfaceOnlyPresentsAndForwardsPickerResults() throws {
        let picker = try String(
            contentsOfFile: MemoMarkTestPaths.path(
                "Source/MemoMark/MemoMark/iOS/Views/UIKitPhotoPicker.swift"
            ),
            encoding: .utf8
        )
        let support = try String(
            contentsOfFile: MemoMarkTestPaths.path(
                "Source/MemoMark/MemoMark/iOS/Views/PhotoIntakeImporter.swift"
            ),
            encoding: .utf8
        )

        #expect(picker.contains("struct UIKitPhotoPicker"))
        #expect(picker.contains(".images"))
        #expect(picker.contains(".livePhotos"))
        #expect(picker.contains("preferredAssetRepresentationMode"))
        #expect(picker.contains("parent.onCancel()"))
        #expect(picker.contains("parent.onSelect(results)"))
        #expect(!picker.contains("PhotoIntakeURLResolver"))
        #expect(!picker.contains("BatchQueueStore"))
        #expect(!picker.contains("PhotoLibraryExportService"))
        #expect(!support.contains("struct UIKitPhotoPicker"))
    }
}
#endif
