#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing

@Suite("Photo intake unsupported-message responsibility contract")
struct PhotoIntakeUnsupportedMessagePresenterContractTests {

    @Test("unsupported-input presentation is separate from media import and production owners")
    func presenterOnlyProjectsInputPolicyDiagnostics() throws {
        let presenter = try String(
            contentsOfFile: MemoMarkTestPaths.path(
                "Source/MemoMark/MemoMark/iOS/Views/PhotoIntakeUnsupportedMessagePresenter.swift"
            ),
            encoding: .utf8
        )

        #expect(presenter.contains("enum PhotoIntakeUnsupportedMessagePresenter"))
        #expect(presenter.contains("PhotoProcessingInputPolicy.standard"))
        #expect(presenter.contains("fallbackMessage"))
        #expect(!presenter.contains("PhotosPickerItem"))
        #expect(!presenter.contains("PhotoIntakeURLResolver"))
        #expect(!presenter.contains("BatchQueueStore"))
        #expect(!presenter.contains("PhotoLibraryExportService"))
    }
}
#endif
