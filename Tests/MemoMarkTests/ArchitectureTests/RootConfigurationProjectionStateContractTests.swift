#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing

@Suite("root configuration projection state contracts")
struct RootConfigurationProjectionStateContractTests {

    @Test("projection state owns only the root configuration projections")
    func rootKeepsConfigurationProjectionStateTogether() throws {
        let stateSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/RootConfigurationProjectionState.swift"
        )
        let rootSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/MemoMarkConfigurationCenterView.swift"
        )

        #expect(
            stateSource.contains(
                "struct RootConfigurationProjectionState"
            )
        )
        #expect(
            !stateSource.contains(
                "typealias V1RootConfigurationProjectionState"
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
                "@State\n    private var logoMode: ConfigurationLogoMode = .appleMini"
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
