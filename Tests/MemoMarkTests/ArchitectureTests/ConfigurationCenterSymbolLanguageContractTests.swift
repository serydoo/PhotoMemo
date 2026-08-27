#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing

@Suite("Configuration Center symbol language contract")
struct ConfigurationCenterSymbolLanguageContractTests {

    @Test("detail titles use MemoMark semantic symbols")
    func detailTitlesUseSemanticSymbols() throws {
        let source = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationCenterDetailPresenter.swift"
        )

        #expect(source.contains("MemoMarkSymbol.memorySubject.name"))
        #expect(source.contains("MemoMarkSymbol.module.name"))
        #expect(source.contains("MemoMarkSymbol.output.name"))
        #expect(source.contains("MemoMarkSymbol.help.name"))
        #expect(source.contains("MemoMarkSymbol.photoMetadata.name"))
        #expect(source.contains("MemoMarkSymbol.timeAnchor.name"))
        #expect(source.contains("MemoMarkSymbol.memoryContent.name"))
    }

    @Test("summary and preview use the same semantic symbols")
    func summaryAndPreviewUseSameSemanticSymbols() throws {
        let combined = try [
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationCenterSummarySection.swift",
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationCenterTopPreviewSection.swift"
        ]
        .map(sourceText)
        .joined(separator: "\n")

        #expect(combined.contains("MemoMarkSymbol.configuration.name"))
        #expect(combined.contains("MemoMarkSymbol.memorySubject.name"))
        #expect(combined.contains("MemoMarkSymbol.timeAnchor.name"))
        #expect(combined.contains("MemoMarkSymbol.photoMetadata.name"))
        #expect(combined.contains("MemoMarkSymbol.memoryContent.name"))
    }

    @Test("standard action buttons keep Apple action symbols")
    func standardActionsKeepAppleSymbols() throws {
        let combined = try [
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationCenterSidebarView.swift",
            "Source/MemoMark/MemoMark/iOS/Views/V1HomePageSurface.swift",
            "Source/MemoMark/MemoMark/iOS/Views/V1ConfigurationOptionList.swift"
        ]
        .map(sourceText)
        .joined(separator: "\n")

        #expect(combined.contains("Image(systemName: \"plus\")"))
        #expect(combined.contains("systemImage: \"pencil\""))
        #expect(combined.contains("systemImage: \"arrow.counterclockwise\""))
    }
}

private extension ConfigurationCenterSymbolLanguageContractTests {

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
