import Foundation
import Testing
@testable import PhotoMemo

@Suite("V1 configuration language restoration")
struct V1ConfigurationLanguageRestorationContractTests {

    @Test("loading a saved configuration restores its output language")
    func savedConfigurationLanguageIsAppliedToTheSession() throws {
        let source = try String(
            contentsOf: repositoryRoot.appendingPathComponent(
                "Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift"
            ),
            encoding: .utf8
        )
        let methodStart = try #require(
            source.range(
                of: "private func applyConfigurationDraftProjection("
            )
        )
        let nextMethod = try #require(
            source.range(
                of: "\n    private func applyBootstrapFlowPatch(",
                range: methodStart.lowerBound..<source.endIndex
            )
        )

        #expect(
            source[methodStart.lowerBound..<nextMethod.lowerBound]
                .contains("session.language = projection.language")
        )
    }

    private var repositoryRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
