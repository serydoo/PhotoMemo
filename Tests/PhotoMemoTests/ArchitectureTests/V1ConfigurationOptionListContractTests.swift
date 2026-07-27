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

    @Test("configuration card owns status while a translucent footer floats above the editor")
    func configurationCardOwnsStatusWhileFooterFloatsAboveEditor() throws {
        let optionListSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1ConfigurationOptionList.swift"
        )
        let editorSurfaceSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1EditorPageSurface.swift"
        )
        let rootSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift"
        )

        #expect(optionListSource.contains("struct V1ConfigurationActionFooter"))
        #expect(optionListSource.contains("let configurationStatus: V1ConfigurationStatus"))
        #expect(optionListSource.contains("private var configurationStatusCard"))
        #expect(optionListSource.contains("configurationStatusCard"))
        #expect(optionListSource.contains("private var configurationActionRow"))
        #expect(optionListSource.contains("private var centeredPrimaryAction"))
        #expect(optionListSource.contains("ZStack(alignment: .bottom)"))
        #expect(optionListSource.contains("Image(systemName: \"ellipsis\")"))
        #expect(!optionListSource.contains("private var configurationStatusLabel"))
        #expect(!optionListSource.contains("Image(systemName: \"ellipsis.circle\")"))
        #expect(editorSurfaceSource.contains(".overlay(alignment: .bottom)"))
        #expect(!editorSurfaceSource.contains(".safeAreaInset(edge: .bottom)"))
        #expect(optionListSource.contains(".ultraThinMaterial"))
        #expect(rootSource.contains("V1ConfigurationActionFooter("))
        #expect(rootSource.contains("configurationStatus:\n                activeConfigurationStatus"))
    }

    @Test("region editor explains customizable phrase and module composition")
    func regionEditorExplainsCustomizablePhraseAndModuleComposition() throws {
        let rootSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift"
        )
        let supportSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSViewSupportComponents.swift"
        )
        let regionSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Models/CardRegion.swift"
        )

        #expect(supportSource.contains("subtitle: region.defaultContentSummary"))
        #expect(regionSource.contains("return \"左上\""))
        #expect(regionSource.contains("return \"左下\""))
        #expect(regionSource.contains("return \"右上\""))
        #expect(regionSource.contains("return \"右下\""))
        #expect(regionSource.contains("return \"默认动作 + 设备信息\""))
        #expect(regionSource.contains("return \"默认智能模块输出信息\""))
        #expect(rootSource.contains("private var regionConfigurationGuide"))
        #expect(rootSource.contains("自定义短语与智能模块"))
        #expect(rootSource.contains("Apple Photos"))
        #expect(rootSource.contains("开启说明写入后"))
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
