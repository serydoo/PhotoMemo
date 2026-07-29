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
        let configurationPageSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1ConfigurationPageSurface.swift"
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
        #expect(editorSurfaceSource.contains(".safeAreaInset(edge: .bottom, spacing: 0)"))
        #expect(!editorSurfaceSource.contains(".overlay(alignment: .bottom)"))
        #expect(optionListSource.contains(".ultraThinMaterial"))
        #expect(configurationPageSource.contains("V1ConfigurationActionFooter("))
        #expect(configurationPageSource.contains("configurationStatus: configurationStatus"))
        #expect(rootSource.contains("V1ConfigurationPageSurface("))
    }

    @Test("region editor explains how personal words and photo details enter the card")
    func regionEditorExplainsPersonalWordsAndPhotoDetails() throws {
        let editorClusterSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1RegionEditorCluster.swift"
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
        #expect(editorClusterSource.contains("struct V1RegionEditorCluster: View"))
        #expect(editorClusterSource.contains("IOSCompactEntryListGroup"))
        #expect(editorClusterSource.contains("V1RegionEditorCard("))
        #expect(editorClusterSource.contains("写进卡片的内容"))
        #expect(editorClusterSource.contains("都能写下你的话"))
        #expect(editorClusterSource.contains("照片里的时间、地点和拍摄信息"))
    }

    @Test("memory display row previews one line and reveals full detail")
    func memoryDisplayRowPreviewsOneLineAndRevealsFullDetail() throws {
        let optionListSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1ConfigurationOptionList.swift"
        )

        #expect(optionListSource.contains("title: \"记忆表达\""))
        #expect(optionListSource.contains("detail: memoryDisplayDetail"))
        #expect(optionListSource.contains("onDetailTap: {\n                showsMemoryDisplayDetail = true"))
        #expect(optionListSource.contains("V1MemoryExpressionPreviewSheet("))
        #expect(optionListSource.contains(".presentationDetents([.height(320), .medium])"))
        #expect(!optionListSource.contains("memoryDisplayAlertMessage"))
        #expect(optionListSource.contains("private func interactiveConfigurationRowDetailLabel("))
        #expect(optionListSource.contains("Text(\"…\")"))
        #expect(optionListSource.contains(".foregroundStyle(Color.accentColor)"))
        #expect(optionListSource.contains(".lineLimit(1)"))
        #expect(optionListSource.contains("optionSelectionPill(title: memoryDisplayValue)"))
    }

    @Test("saved configuration uses a restrained disabled action")
    func savedConfigurationUsesRestrainedDisabledAction() throws {
        let optionListSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1ConfigurationOptionList.swift"
        )

        #expect(optionListSource.contains("private var saveActionButtonStyle:"))
        #expect(optionListSource.contains("isRestrained: configurationStatus == .saved"))
        #expect(
            optionListSource.contains(
                ".disabled(isSavingConfiguration || configurationStatus == .saved)"
            )
        )
        #expect(
            optionListSource.contains(
                "case .idle, .dirty, .saving, .saved, .subjectSynced:"
            )
        )
        #expect(!optionListSource.contains("case .dirty, .subjectSynced: return Color.orange"))
    }

    @Test("module library groups the existing ordered result by category")
    func moduleLibraryGroupsExistingOrderByCategory() throws {
        let moduleSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1ModuleLibrarySurface.swift"
        )

        #expect(moduleSource.contains("private var groupedModules: [ModuleGroup]"))
        #expect(moduleSource.contains("ForEach(groupedModules)"))
        #expect(moduleSource.contains("let categoryTitles = filteredModules.reduce"))
        #expect(moduleSource.contains("modules: filteredModules.filter"))
        #expect(!moduleSource.contains("filteredModules.sorted"))
    }

    @Test("card layout places border before logo without changing row forms")
    func cardLayoutPlacesBorderBeforeLogoWithoutChangingRowForms() throws {
        let optionListSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1ConfigurationOptionList.swift"
        )
        let sectionStart = try #require(
            optionListSource.range(
                of: "title: \"卡片布局与内容\""
            )
        )
        let sectionEnd = try #require(
            optionListSource.range(
                of: "configurationStatusCard",
                range: sectionStart.upperBound..<optionListSource.endIndex
            )
        )
        let sectionSource = optionListSource[
            sectionStart.lowerBound..<sectionEnd.upperBound
        ]
        let borderRange = try #require(
            sectionSource.range(of: "borderStyleRow")
        )
        let logoRange = try #require(
            sectionSource.range(of: "logoRow")
        )

        #expect(borderRange.lowerBound < logoRange.lowerBound)
        #expect(
            optionListSource.contains(
                "private var borderStyleRow: some View {\n        configurationTextRow("
            )
        )
        #expect(
            optionListSource.contains(
                "private var logoRow: some View {\n        configurationRow("
            )
        )
    }

    @Test("advanced modules move location display behind the card-content-style editor")
    func advancedModulesMoveLocationDisplayBehindCardContentStyleEditor() throws {
        let optionListSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1ConfigurationOptionList.swift"
        )
        let sheetSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1AdvancedModulesSheet.swift"
        )
        let contentRange = try #require(
            optionListSource.range(of: "regionContentRow")
        )
        let statusRange = try #require(
            optionListSource.range(of: "configurationStatusCard")
        )
        let advancedRange = try #require(
            optionListSource.range(of: "advancedModulesRow")
        )

        #expect(advancedRange.lowerBound > contentRange.lowerBound)
        #expect(advancedRange.lowerBound < statusRange.lowerBound)
        #expect(
            optionListSource.contains(
                "title: \"高级模块\""
            )
        )
        #expect(
            optionListSource.contains(
                "subtitle: \"部分高级模块的展示形式选择\""
            )
        )
        #expect(
            optionListSource.contains(
                "showsAdvancedModulesSheet"
            )
        )
        #expect(
            !optionListSource.contains(
                "private var locationRow"
            )
        )
        #expect(
            sheetSource.contains(
                "struct V1AdvancedModulesSheet: View"
            )
        )
        #expect(sheetSource.contains("NavigationStack"))
        #expect(sheetSource.contains(".listStyle(.insetGrouped)"))
        #expect(sheetSource.contains("Text(\"地理显示\")"))
        #expect(
            sheetSource.contains(
                ".font(.subheadline.weight(.semibold))"
            )
        )
        #expect(sheetSource.contains(".font(.caption)"))
        #expect(sheetSource.contains("spacing: 3"))
        #expect(
            sheetSource.contains(
                "@Environment(\\.dynamicTypeSize)"
            )
        )
        #expect(
            sheetSource.contains(
                "dynamicTypeSize.isAccessibilitySize"
            )
        )
        #expect(
            sheetSource.contains(
                "ViewThatFits(in: .horizontal)"
            )
        )
        #expect(
            sheetSource.contains(
                "private var verticalLocationDisplayRow"
            )
        )
        #expect(sheetSource.contains("Button(\"完成\")"))
        #expect(sheetSource.contains("Menu {"))
        #expect(sheetSource.contains("Image(systemName: \"chevron.down\")"))
        #expect(sheetSource.contains("systemImage: \"checkmark\""))
        #expect(
            sheetSource.contains(
                "ConfigurationUI.smallCornerRadius"
            )
        )
        #expect(
            sheetSource.contains(
                "ConfigurationUI.controlBackground"
            )
        )
        #expect(
            sheetSource.contains(
                "ConfigurationUI.faintHairline"
            )
        )
        #expect(!sheetSource.contains("Picker("))
        #expect(
            sheetSource.contains(
                "locationPresentation.options"
            )
        )
        #expect(
            sheetSource.contains(
                "selectedLocationOptionID"
            )
        )
    }

    @Test("memory source header keeps compact visual height")
    func memorySourceHeaderKeepsCompactVisualHeight() throws {
        let optionListSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1ConfigurationOptionList.swift"
        )

        let headerStart = try #require(
            optionListSource.range(
                of: "private var memorySourceDisclosureButton: some View"
            )
        )
        let headerEnd = try #require(
            optionListSource.range(
                of: "private var memorySourceSummaryRow: some View"
            )
        )
        let headerSource = optionListSource[
            headerStart.lowerBound..<headerEnd.lowerBound
        ]

        #expect(!headerSource.contains(".frame(minHeight: 44)"))
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
