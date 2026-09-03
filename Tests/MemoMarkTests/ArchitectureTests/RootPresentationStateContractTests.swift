#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing

@Suite("root presentation state contract")
struct RootPresentationStateContractTests {

    @Test("root keeps transient presentation state in one local container")
    func rootKeepsTransientPresentationStateInOneLocalContainer() throws {
        let stateSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/RootPresentationState.swift"
        )
        let rootSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/MemoMarkConfigurationCenterView.swift"
        )

        #expect(stateSource.contains("struct RootPresentationState"))
        #expect(!stateSource.contains("typealias V1RootPresentationState"))
        for property in [
            "configurationDisclosureState",
            "mediaPickerPresentation",
            "renamePresentation",
            "showsRegionContentSheet",
            "showsWelcomeInformation",
            "showsMemoMarkPlus",
            "showsHomeMemoMarkPlus",
            "switchPresentation",
            "localLibraryPresentation"
        ] {
            #expect(
                stateSource.contains("var \(property)"),
                "Expected transient presentation property \(property) to stay in the container."
            )
        }

        #expect(
            rootSource.contains("var rootPresentationState")
        )
        #expect(
            !rootSource.contains("private var memorySourceDisclosureState")
        )
        #expect(
            !rootSource.contains("private var mediaPickerPresentation")
        )
        #expect(
            !rootSource.contains("private var switchPresentation")
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
