import Foundation
import Testing
@testable import MemoMark

@Suite("V1 configuration language restoration")
struct V1ConfigurationLanguageRestorationContractTests {

    @Test("loading a saved configuration restores its output language")
    func savedConfigurationLanguageIsAppliedToTheSession() throws {
        let source = try String(
            contentsOf: repositoryRoot.appendingPathComponent(
                "Source/MemoMark/MemoMark/iOS/Views/MemoMarkConfigurationCenterView+Runtime.swift"
            ),
            encoding: .utf8
        )
        let methodStart = try #require(
            source.range(
                of: "func applyConfigurationDraftProjection("
            )
        )
        #expect(
            source[methodStart.lowerBound..<source.endIndex]
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
