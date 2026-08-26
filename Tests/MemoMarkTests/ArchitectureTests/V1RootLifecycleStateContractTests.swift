#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing

@Suite("V1 root lifecycle state contracts")
struct V1RootLifecycleStateContractTests {

    @Test("root keeps lifecycle flags and status in one local container")
    func rootKeepsLifecycleStateTogether() throws {
        let stateSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/V1RootLifecycleState.swift"
        )
        let rootSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/MemoMarkiOSV1View.swift"
        )

        #expect(
            stateSource.contains("struct V1RootLifecycleState")
        )
        for property in [
            "isSavingConfiguration",
            "didBootstrap",
            "isApplyingBootstrapState",
            "isApplyingSavedOutputConfiguration",
            "birthdayDateChangeBehavior",
            "shouldSaveSubjectLibrary",
            "isPersistingSubjectChanges",
            "activeConfigurationStatus"
        ] {
            #expect(
                stateSource.contains("var \(property)"),
                "Expected lifecycle property \(property) to stay in the container."
            )
        }

        #expect(
            rootSource.contains("private var rootLifecycleState")
        )
        #expect(
            !rootSource.contains(
                "@State\n    private var isSavingConfiguration = false"
            )
        )
        #expect(
            !rootSource.contains(
                "@State\n    private var activeConfigurationStatus:"
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
