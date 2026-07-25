#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing

@Suite("V1 configuration option list boundary")
struct V1ConfigurationOptionListContractTests {

    @Test("configuration option list stays outside the runtime root")
    func configurationOptionListStaysOutsideRuntimeRoot() throws {
        let optionListSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1ConfigurationOptionList.swift"
        )
        let rootSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift"
        )

        #expect(optionListSource.contains("struct V1ConfigurationOptionList: View"))
        #expect(!optionListSource.contains("private struct V1ConfigurationOptionList: View"))
        #expect(optionListSource.contains("private struct V1ConfigurationActionButtonStyle"))
        #expect(optionListSource.contains("private struct V1ConfigurationNavigationRowButtonStyle"))
        #expect(rootSource.contains("return V1ConfigurationOptionList("))
        #expect(!rootSource.contains("private struct V1ConfigurationOptionList: View"))
        #expect(!rootSource.contains("private struct V1ConfigurationActionButtonStyle"))
        #expect(!rootSource.contains("private struct V1ConfigurationNavigationRowButtonStyle"))
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
