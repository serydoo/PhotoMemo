import Foundation
import Testing

@Suite("Repository path support")
struct RepositoryPathSupportTests {

    @Test("resolves source contracts from the active checkout")
    func resolvesSourceContractsFromTheActiveCheckout() {
        let rootScenePath = MemoMarkTestPaths.path(
            "Source/MemoMark/MemoMark/App/MemoMarkRootSceneView.swift"
        )

        #expect(
            FileManager.default.fileExists(atPath: rootScenePath),
            "Source-contract tests must resolve files from the active checkout instead of a developer-specific absolute path."
        )
    }
}
