#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing

@Suite("MemoMark symbol catalog contract")
struct MemoMarkSymbolCatalogContractTests {

    @Test("catalog defines stable product semantics")
    func catalogDefinesStableProductSemantics() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/MemoMarkSymbol.swift"
        )

        for semantic in [
            "memorySubject", "timeAnchor", "memoryContent",
            "photoMetadata", "location", "configuration",
            "module", "output", "applePhotos", "localStorage",
            "processing", "completed", "privacy", "help", "settings"
        ] {
            #expect(source.contains("case \(semantic)"))
        }
    }

    @Test("non-configuration surfaces use semantic symbols")
    func nonConfigurationSurfacesUseSemanticSymbols() throws {
        let paths = [
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1HomePageSurface.swift",
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1OutputPageSurface.swift",
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1TaskPageSurface.swift",
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1SettingsPageSurface.swift",
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1LocalConfigurationLibrarySheet.swift"
        ]
        let combined = try paths.map(sourceText).joined(separator: "\n")

        #expect(combined.contains("MemoMarkSymbol.memorySubject.name"))
        #expect(combined.contains("MemoMarkSymbol.output.name"))
        #expect(combined.contains("MemoMarkSymbol.applePhotos.name"))
        #expect(combined.contains("MemoMarkSymbol.localStorage.name"))
        #expect(combined.contains("MemoMarkSymbol.processing.name"))
        #expect(combined.contains("MemoMarkSymbol.privacy.name"))
    }
}

private extension MemoMarkSymbolCatalogContractTests {

    func sourceText(_ relativePath: String) throws -> String {
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
