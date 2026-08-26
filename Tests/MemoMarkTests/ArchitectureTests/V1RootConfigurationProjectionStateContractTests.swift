#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing

@Suite("V1 root configuration projection state contracts")
struct V1RootConfigurationProjectionStateContractTests {

    @Test("projection state owns only the root configuration projections")
    func rootKeepsConfigurationProjectionStateTogether() throws {
        let stateSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/V1RootConfigurationProjectionState.swift"
        )
        let rootSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/MemoMarkiOSV1View.swift"
        )

        #expect(
            stateSource.contains(
                "struct V1RootConfigurationProjectionState"
            )
        )
        for property in [
            "logoMode",
            "customLogoBadge",
            "birthdayDate",
            "locationDisplayConfiguration",
            "timeDisplayConfiguration"
        ] {
            #expect(
                stateSource.contains("var \(property)"),
                "Expected configuration projection property \(property) to stay in the container."
            )
        }

        #expect(
            rootSource.contains(
                "private var rootConfigurationProjectionState"
            )
        )
        #expect(
            !rootSource.contains(
                "@State\n    private var logoMode: V1LogoMode = .appleMini"
            )
        )
        #expect(
            !rootSource.contains(
                "@State\n    private var customLogoBadge: Badge?"
            )
        )
        #expect(
            !rootSource.contains(
                "@State\n    private var birthdayDate ="
            )
        )
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
