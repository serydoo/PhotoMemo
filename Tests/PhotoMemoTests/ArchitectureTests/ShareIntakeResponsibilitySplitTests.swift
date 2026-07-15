import Foundation
import Testing

@Suite("Share intake responsibility split")
struct ShareIntakeResponsibilitySplitTests {

    @Test("Share intake declares four focused collaborators")
    func shareIntakeDeclaresFourFocusedCollaborators() throws {
        let expectations = [
            (
                "Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/ShareItemProviderLoader.swift",
                "struct ShareItemProviderLoader"
            ),
            (
                "Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/ShareManagedFileImporter.swift",
                "struct ShareManagedFileImporter"
            ),
            (
                "Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/ShareLivePhotoRecovery.swift",
                "struct ShareLivePhotoRecovery"
            ),
            (
                "Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/ShareIntakeDiagnostics.swift",
                "struct ShareIntakeDiagnostics"
            )
        ]

        for (relativePath, declaration) in expectations {
            let url = sourceURL(relativePath: relativePath)
            try #require(
                FileManager.default.fileExists(
                    atPath: url.path
                )
            )
            let source = try String(
                contentsOf: url,
                encoding: .utf8
            )
            #expect(source.contains(declaration))
        }
    }

    @Test("Share intake facade delegates extracted responsibilities")
    func shareIntakeFacadeDelegatesExtractedResponsibilities() throws {
        let source = try sourceText(
            relativePath:
                "Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionIntakeService.swift"
        )

        #expect(source.contains("ShareItemProviderLoader"))
        #expect(source.contains("ShareManagedFileImporter"))
        #expect(source.contains("ShareLivePhotoRecovery"))
        #expect(source.contains("ShareIntakeDiagnostics"))
        #expect(!source.contains("func loadFileRepresentationResult("))
        #expect(!source.contains("func loadFallbackItem("))
        #expect(!source.contains("func livePhotoBundleReadiness("))
        #expect(!source.contains("func recordProviderDiagnostics("))
    }

    @Test("Managed importer preserves file-first fallback order")
    func managedImporterPreservesFileFirstFallbackOrder() throws {
        let source = try sourceText(
            relativePath:
                "Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/ShareManagedFileImporter.swift"
        )

        let fileRepresentationIndex = try #require(
            source.range(
                of: "loadFileRepresentationResult"
            )?.lowerBound
        )
        let itemFallbackIndex = try #require(
            source.range(
                of: "loadFallbackItem"
            )?.lowerBound
        )

        #expect(
            fileRepresentationIndex
            < itemFallbackIndex
        )
    }

    private func sourceText(
        relativePath: String
    ) throws -> String {
        try String(
            contentsOf:
                sourceURL(
                    relativePath: relativePath
                ),
            encoding: .utf8
        )
    }

    private func sourceURL(
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
            .appendingPathComponent(
                relativePath
            )
    }
}
