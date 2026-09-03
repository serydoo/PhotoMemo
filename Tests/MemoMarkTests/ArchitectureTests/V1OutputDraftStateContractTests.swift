#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing

@Suite("V1 output draft state contract")
struct V1OutputDraftStateContractTests {

    @Test("root keeps output draft and album loading state together")
    func rootKeepsOutputDraftAndAlbumLoadingStateTogether() throws {
        let stateSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/V1OutputDraftState.swift"
        )
        let rootSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/MemoMarkConfigurationCenterView.swift"
        )

        #expect(stateSource.contains("struct OutputDraftState"))
        for property in [
            "outputTarget",
            "mediaOutputMode",
            "shouldWritePhotosDescription",
            "photosDescriptionOverride",
            "configurationAlbumTitle",
            "livePhotoPolicy",
            "availableAlbums",
            "selectedExistingAlbumIdentifier",
            "newAlbumName",
            "isLoadingAlbums",
            "albumStatusMessage"
        ] {
            #expect(
                stateSource.contains("var \(property)"),
                "Expected output state property \(property) to stay in the output boundary."
            )
        }

        #expect(rootSource.contains("var outputDraftState"))
        #expect(!rootSource.contains("private var outputTarget"))
        #expect(!rootSource.contains("private var availableAlbums"))
        #expect(!rootSource.contains("private var isLoadingAlbums"))
    }

    private func sourceText(_ relativePath: String) throws -> String {
        let testsDirectory = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
        let repositoryRoot = testsDirectory
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        return try String(
            contentsOf: repositoryRoot.appendingPathComponent(relativePath),
            encoding: .utf8
        )
    }
}
#endif
