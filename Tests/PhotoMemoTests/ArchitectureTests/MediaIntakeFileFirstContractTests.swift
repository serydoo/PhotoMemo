#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("Media intake file-first contract")
struct MediaIntakeFileFirstContractTests {

    @Test("Main App PhotosPicker attempts file representation before Data fallback")
    func mainAppPhotosPickerAttemptsFileRepresentationBeforeDataFallback() throws {
        let source =
            try sourceText(
                relativePath:
                    "Source/PhotoMemo/PhotoMemo/Views/Main/PhotoImporterView.swift"
            )

        try expectOrdered(
            source: source,
            earlier: "PhotoImporterPickedFileRepresentation",
            later: "Data.self"
        )
    }

    @Test("Main App intake surfaces policy diagnostics instead of generic unsupported text")
    func mainAppIntakeSurfacesPolicyDiagnosticsInsteadOfGenericUnsupportedText() throws {
        let source =
            try sourceText(
                relativePath:
                    "Source/PhotoMemo/PhotoMemo/Views/Main/PhotoImporterView.swift"
            )

        #expect(
            !source.contains(
                "\"Unsupported image format\""
            )
        )
        #expect(
            source.contains(
                "unsupportedInputMessage"
            )
        )
        #expect(
            source.contains(
                "PhotoProcessingInputPolicy"
            )
        )
    }

    @Test("V1 Quick Action PhotosPicker attempts file representation before Data fallback")
    func v1QuickActionPhotosPickerAttemptsFileRepresentationBeforeDataFallback() throws {
        let source =
            try sourceText(
                relativePath:
                    "Source/PhotoMemo/PhotoMemo/iOS/Views/V1PhotoIntakeSupport.swift"
            )

        try expectOrdered(
            source: source,
            earlier: "V1PickedPhotoFileRepresentation",
            later: "Data.self"
        )
    }

    @Test("Share Extension attempts file representation before item fallback")
    func shareExtensionAttemptsFileRepresentationBeforeItemFallback() throws {
        let source =
            try sourceText(
                relativePath:
                    "Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionIntakeService.swift"
            )

        try expectOrdered(
            source: source,
            earlier: "loadFileRepresentationResult",
            later: "loadItem("
        )
    }
}

private extension MediaIntakeFileFirstContractTests {

    func expectOrdered(
        source: String,
        earlier: String,
        later: String
    ) throws {
        let earlierIndex =
            try #require(
                source.range(of: earlier)?.lowerBound
            )
        let laterIndex =
            try #require(
                source.range(of: later)?.lowerBound
            )

        #expect(
            earlierIndex < laterIndex
        )
    }

    func sourceText(
        relativePath: String
    ) throws -> String {
        try String(
            contentsOf:
                sourceURL(relativePath: relativePath),
            encoding: .utf8
        )
    }

    func sourceURL(
        relativePath: String
    ) -> URL {
        let testsDirectory =
            URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
        let repositoryRoot =
            testsDirectory
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()

        return repositoryRoot
            .appendingPathComponent(relativePath)
    }
}
#endif
