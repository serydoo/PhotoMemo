import Foundation
import Testing

@Suite("Model layer dependency direction")
struct ModelLayerDependencyDirectionTests {

    @Test("Photo processing input policy owns Live Photo type identifiers without App-layer coupling")
    func photoProcessingInputPolicyOwnsLivePhotoTypeIdentifiersWithoutAppLayerCoupling() throws {
        let source =
            try sourceText(
                relativePath:
                    "Source/PhotoMemo/PhotoMemo/Models/PhotoProcessingInputPolicy.swift"
            )

        #expect(
            source.contains("livePhotoTypeIdentifiers")
        )
        #expect(
            !source.contains("PhotoMemoShareProviderTypeSelection")
        )
    }
}

private extension ModelLayerDependencyDirectionTests {

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
