#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing

@Suite("V1 root presentation state contract")
struct V1RootPresentationStateContractTests {

    @Test("root keeps transient presentation state in one local container")
    func rootKeepsTransientPresentationStateInOneLocalContainer() throws {
        let stateSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1RootPresentationState.swift"
        )
        let rootSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift"
        )

        #expect(stateSource.contains("struct V1RootPresentationState"))
        for property in [
            "memorySourceDisclosureState",
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
            rootSource.contains("private var rootPresentationState")
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
