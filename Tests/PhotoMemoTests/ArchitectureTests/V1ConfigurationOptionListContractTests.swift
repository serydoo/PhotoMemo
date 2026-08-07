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
        #expect(editorClusterSource.contains("自由录入文字"))
        #expect(editorClusterSource.contains("组合进文字之间"))
        #expect(editorClusterSource.contains("照片里的时间、地点和拍摄信息"))
    }

    @Test("memory display keeps a compact trailing control and previews every phase below")
    func memoryDisplayKeepsCompactControlAndPreviewsEveryPhaseBelow() throws {
        let optionListSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1ConfigurationOptionList.swift"
        )
        let supportSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSViewSupportComponents.swift"
        )
        let selectorStart = try #require(
            supportSource.range(of: "struct V1CompactSelectionLabel")
        )
        let selectorEnd = try #require(
            supportSource.range(
                of: "enum V1CompactInformationRowMetrics",
                range: selectorStart.upperBound..<supportSource.endIndex
            )
        )
        let selectorSource = supportSource[
            selectorStart.lowerBound..<selectorEnd.lowerBound
        ]

        #expect(optionListSource.contains("title: \"记忆表达\""))
        #expect(optionListSource.contains("detail: \"\""))
        #expect(!optionListSource.contains("detail: memoryDisplayDetail"))
        #expect(!optionListSource.contains("showsMemoryDisplayDetail"))
        #expect(!optionListSource.contains("V1MemoryExpressionPreviewSheet"))
        #expect(!optionListSource.contains("interactiveConfigurationRowDetailLabel"))
        #expect(!optionListSource.contains("compactConfigurationDetail"))
        #expect(optionListSource.contains("memoryExpressionPreview"))
        #expect(
            optionListSource.contains(
                ".split(separator: \"｜\", omittingEmptySubsequences: true)"
            )
        )
        #expect(optionListSource.contains("ForEach("))
        #expect(optionListSource.contains("Text(line)"))
        #expect(optionListSource.contains(".font(.caption2)"))
        #expect(optionListSource.contains("Text(\"智能模块表达预览\")"))
        #expect(optionListSource.contains("ConfigurationUI.controlBackground"))
        #expect(optionListSource.contains("ConfigurationUI.faintHairline"))
        #expect(
            optionListSource.contains(
                ".accessibilityLabel(localized(\"智能模块表达预览\"))"
            )
        )
        #expect(
            optionListSource.contains(
                "V1CompactSelectionLabel(\n                        title: localized(memoryDisplayValue)"
            )
        )
        #expect(!optionListSource.contains("horizontalTrailingWidth: 112"))
        #expect(!optionListSource.contains(".frame(width: 112)"))
        #expect(!optionListSource.contains("optionSelectionPill"))
        #expect(
            optionListSource.contains(
                "horizontalTrailingWidth: CGFloat =\n            ConfigurationUI.compactTrailingControlWidth"
            )
        )
        #expect(selectorSource.contains(".font(.caption.weight(.semibold))"))
        #expect(selectorSource.contains(".padding(.horizontal, 9)"))
        #expect(selectorSource.contains(".padding(.vertical, 6)"))
        #expect(!selectorSource.contains("maxWidth: .infinity"))
        let selectorBackground = try #require(
            selectorSource.range(of: ".background(")
        )
        let selectorTouchTarget = try #require(
            selectorSource.range(
                of: ".frame(minHeight: ConfigurationUI.minimumInteractiveHeight)"
            )
        )
        #expect(selectorBackground.lowerBound < selectorTouchTarget.lowerBound)
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

    @Test("logo row keeps one concise subtitle without selection detail")
    func logoRowKeepsOneConciseSubtitleWithoutSelectionDetail() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1ConfigurationOptionList.swift"
        )
        let logoSubtitle = try #require(
            source.range(of: "private var logoSubtitle")
        )
        let nextProperty = try #require(
            source.range(
                of: "private var subjectDisplayName",
                range: logoSubtitle.upperBound..<source.endIndex
            )
        )
        let section = source[logoSubtitle.lowerBound..<nextProperty.lowerBound]

        #expect(section.contains("localized(\"让卡片留下你的标识。\")"))
        #expect(!section.contains("logoDetail"))
        #expect(!section.contains(" · %@"))
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
        let supportSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSViewSupportComponents.swift"
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
                "title: \"更多信息\""
            )
        )
        #expect(
            optionListSource.contains(
                "subtitle: \"调整地点与拍摄时间的显示方式。\""
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
        #expect(sheetSource.contains("ScrollView"))
        #expect(sheetSource.contains("IOSCompactEntryListGroup"))
        #expect(!sheetSource.contains("List {"))
        #expect(!sheetSource.contains(".listStyle(.insetGrouped)"))
        #expect(sheetSource.contains("ConfigurationUI.sheetPanelPadding"))
        #expect(sheetSource.contains("Text(localized(\"地理显示\"))"))
        #expect(
            sheetSource.contains(
                ".font(.subheadline.weight(.semibold))"
            )
        )
        #expect(sheetSource.contains(".font(.caption)"))
        #expect(
            sheetSource.contains(
                "spacing: MemoMarkDesignTokens.Spacing.extraSmall"
            )
        )
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
        #expect(!sheetSource.contains("ViewThatFits(in: .horizontal)"))
        #expect(
            sheetSource.contains(
                "private var verticalLocationDisplayRow"
            )
        )
        #expect(sheetSource.contains("private var timeSupplementRow"))
        #expect(
            sheetSource.components(
                separatedBy: "V1HorizontalDivider("
            ).count >= 3
        )
        #expect(sheetSource.contains("Button(\"完成\")"))
        #expect(sheetSource.contains("Menu {"))
        #expect(sheetSource.contains("V1CompactSelectionLabel"))
        #expect(sheetSource.contains("systemImage: \"checkmark\""))
        #expect(
            supportSource.contains(
                "ConfigurationUI.smallCornerRadius"
            )
        )
        #expect(
            supportSource.contains(
                "ConfigurationUI.controlBackground"
            )
        )
        #expect(
            supportSource.contains(
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
                of: "private var memorySourceSectionHeader: some View"
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

        #expect(headerSource.contains("dynamicTypeSize.isAccessibilitySize"))
        #expect(headerSource.contains("HStack(alignment: .center"))
        #expect(
            headerSource.contains(
                ".frame(maxWidth: .infinity, alignment: .trailing)"
            )
        )
        #expect(!headerSource.contains("ViewThatFits(in: .horizontal)"))
        #expect(!headerSource.contains(".frame(minHeight: 44)"))
        #expect(
            headerSource.contains(
                "minHeight: ConfigurationUI.minimumInteractiveHeight"
            )
        )
        #expect(headerSource.contains(".contentShape(Rectangle())"))
    }

    @Test("custom Logo picker keeps compact chrome with a minimum hit target")
    func customLogoPickerKeepsCompactChromeWithMinimumHitTarget() throws {
        let optionListSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1ConfigurationOptionList.swift"
        )
        let logoStart = try #require(
            optionListSource.range(of: "if logoMode == .customUpload")
        )
        let logoEnd = try #require(
            optionListSource.range(
                of: "private var timeAnchorRow",
                range: logoStart.upperBound..<optionListSource.endIndex
            )
        )
        let logoSource = optionListSource[
            logoStart.lowerBound..<logoEnd.lowerBound
        ]

        #expect(logoSource.contains(".frame(width: 24, height: 24)"))
        #expect(
            logoSource.contains(
                "minWidth: ConfigurationUI.minimumInteractiveHeight"
            )
        )
        #expect(
            logoSource.contains(
                "minHeight: ConfigurationUI.minimumInteractiveHeight"
            )
        )
        #expect(logoSource.contains(".contentShape(Rectangle())"))
    }

    @Test("advanced modules sheet uses a compact default detent and one heading")
    func advancedModulesSheetUsesCompactDefaultDetentAndOneHeading() throws {
        let sheetSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1AdvancedModulesSheet.swift"
        )

        #expect(
            sheetSource.contains(
                ".presentationDetents([\n            .height(ConfigurationUI.compactSheetHeight),\n            .large\n        ])"
            )
        )
        #expect(
            !sheetSource.contains(
                "} header: {\n                    Text(\"高级模块\")"
            )
        )
        #expect(sheetSource.contains(".navigationTitle(\"更多信息\")"))
        #expect(sheetSource.contains(".safeAreaInset(edge: .top, spacing: 0)"))
        #expect(
            sheetSource.contains(
                "VStack(\n            alignment: .leading,\n            spacing: MemoMarkDesignTokens.Spacing.extraSmall\n        )"
            )
        )
        #expect(sheetSource.contains("ConfigurationUI.compactTrailingControlWidth"))
        #expect(sheetSource.contains("ConfigurationUI.compactRowVerticalPadding"))
        #expect(!sheetSource.contains("minHeight: ConfigurationUI.minimumInteractiveHeight"))
    }

    @Test("card content sheet uses the shared compact title-to-content rhythm")
    func cardContentSheetUsesCompactTitleToContentRhythm() throws {
        let editorSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1EditorPresentationModifier.swift"
        )
        let entryRowSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/IOSCompactEntryRow.swift"
        )

        #expect(editorSource.contains(".navigationTitle(\"卡片内容\")"))
        #expect(editorSource.contains(".safeAreaInset(edge: .top, spacing: 0)"))
        #expect(
            editorSource.contains(
                "探索不同组合，也欢迎告诉我们你的自定义想法。"
            )
        )
        #expect(!editorSource.contains(".padding(.top, 4)"))
        #expect(!editorSource.contains(".padding(.bottom, 8)"))
        #expect(!editorSource.contains(".padding(.top, 16)"))
        #expect(entryRowSource.contains("dynamicTypeSize.isAccessibilitySize"))
        #expect(entryRowSource.contains("horizontalDisclosureLabel"))
        #expect(entryRowSource.contains("verticalDisclosureLabel"))
        #expect(!entryRowSource.contains("ViewThatFits(in: .horizontal)"))
        #expect(
            entryRowSource.components(
                separatedBy: ".fixedSize(horizontal: false, vertical: true)"
            ).count >= 5
        )
        #expect(
            entryRowSource.components(
                separatedBy: ".lineLimit(1)"
            ).count >= 5
        )
    }

    @Test("configuration sheets share a native centered subtitle treatment")
    func configurationSheetsShareNativeCenteredSubtitleTreatment() throws {
        let supportSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSViewSupportComponents.swift"
        )
        let anchorSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectAnchorDetailSection.swift"
        )
        let informationSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1AdvancedModulesSheet.swift"
        )
        let cardSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1EditorPresentationModifier.swift"
        )

        #expect(
            supportSource.contains(
                "struct V1ConfigurationSheetSubtitle: View"
            )
        )
        #expect(supportSource.contains(".font(.footnote)"))
        #expect(supportSource.contains(".foregroundStyle(.secondary)"))
        #expect(supportSource.contains(".multilineTextAlignment(.center)"))
        #expect(
            supportSource.contains(
                ".padding(.top, ConfigurationUI.sheetSubtitleTopPadding)"
            )
        )
        #expect(
            supportSource.contains(
                ".padding(.bottom, ConfigurationUI.sheetSubtitleBottomPadding)"
            )
        )
        #expect(anchorSource.contains("V1ConfigurationSheetSubtitle("))
        #expect(anchorSource.contains(".safeAreaInset(edge: .top, spacing: 0)"))
        #expect(
            anchorSource.contains(
                "选择一个时间起点，让照片拥有时间答案。"
            )
        )
        #expect(informationSource.contains("V1ConfigurationSheetSubtitle("))
        #expect(
            informationSource.contains(
                ".safeAreaInset(edge: .top, spacing: 0)"
            )
        )
        #expect(
            informationSource.contains(
                "更多内容会根据实际需要逐步加入。"
            )
        )
        #expect(cardSource.contains("V1ConfigurationSheetSubtitle("))
        #expect(
            cardSource.contains(
                "探索不同组合，也欢迎告诉我们你的自定义想法。"
            )
        )
    }

    @Test("vertical configuration rows keep compact controls trailing aligned")
    func verticalConfigurationRowsKeepCompactControlsTrailingAligned() throws {
        let optionListSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1ConfigurationOptionList.swift"
        )
        let verticalRowStart = try #require(
            optionListSource.range(
                of: "private func verticalConfigurationRow"
            )
        )
        let verticalRowEnd = try #require(
            optionListSource.range(
                of: "private func configurationRowHeading",
                range: verticalRowStart.upperBound..<optionListSource.endIndex
            )
        )
        let verticalRowSource = optionListSource[
            verticalRowStart.lowerBound..<verticalRowEnd.lowerBound
        ]

        #expect(
            verticalRowSource.contains(
                ".frame(maxWidth: .infinity, alignment: .trailing)"
            )
        )
    }

    @Test("ordinary configuration rows keep compact controls on the right")
    func ordinaryConfigurationRowsKeepCompactControlsOnTheRight() throws {
        let optionListSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1ConfigurationOptionList.swift"
        )
        let adaptiveStart = try #require(
            optionListSource.range(
                of: "private func adaptiveConfigurationRow"
            )
        )
        let horizontalStart = try #require(
            optionListSource.range(
                of: "private func horizontalConfigurationRow",
                range: adaptiveStart.upperBound..<optionListSource.endIndex
            )
        )
        let adaptiveSource = optionListSource[
            adaptiveStart.lowerBound..<horizontalStart.lowerBound
        ]
        let verticalStart = try #require(
            optionListSource.range(
                of: "private func verticalConfigurationRow",
                range: horizontalStart.upperBound..<optionListSource.endIndex
            )
        )
        let horizontalSource = optionListSource[
            horizontalStart.lowerBound..<verticalStart.lowerBound
        ]

        #expect(adaptiveSource.contains("dynamicTypeSize.isAccessibilitySize"))
        #expect(adaptiveSource.contains("horizontalConfigurationRow("))
        #expect(!adaptiveSource.contains("ViewThatFits(in: .horizontal)"))
        #expect(
            horizontalSource.contains(
                ".frame(\n                minWidth: 72,\n                maxWidth: horizontalTrailingWidth"
            )
        )
        #expect(horizontalSource.contains("HStack(\n            alignment: .center"))
    }

    @Test("configuration controls and sheets use one shared metric system")
    func configurationControlsAndSheetsUseOneMetricSystem() throws {
        let tokenSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/App/MemoMarkDesignTokens.swift"
        )
        let configurationUISource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Components/InspectorSectionView.swift"
        )
        let optionListSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1ConfigurationOptionList.swift"
        )
        let supportSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSViewSupportComponents.swift"
        )
        let anchorSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectAnchorDetailSection.swift"
        )
        let informationSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1AdvancedModulesSheet.swift"
        )
        let editorSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1EditorPresentationModifier.swift"
        )
        let entryRowSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/IOSCompactEntryRow.swift"
        )
        let regionSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1RegionEditorCluster.swift"
        )

        #expect(
            tokenSource.contains(
                "static let compactTrailingControlWidth: CGFloat = 128"
            )
        )
        #expect(
            configurationUISource.contains(
                "static let compactTrailingControlWidth =\n        MemoMarkDesignTokens.Layout.compactTrailingControlWidth"
            )
        )
        #expect(
            configurationUISource.contains(
                "static let minimumInteractiveHeight =\n        MemoMarkDesignTokens.ControlState.minimumTouchTarget"
            )
        )
        #expect(
            supportSource.contains(
                "struct V1ConfigurationSheetPanelChrome: ViewModifier"
            )
        )
        #expect(
            optionListSource.contains(
                "ConfigurationUI.compactTrailingControlWidth"
            )
        )
        #expect(!optionListSource.contains("horizontalTrailingWidth: 112"))
        #expect(!optionListSource.contains(".frame(width: 112)"))
        #expect(
            anchorSource.components(
                separatedBy: ".v1ConfigurationSheetPanelChrome()"
            ).count >= 3
        )
        #expect(!anchorSource.contains("cornerRadius: 14"))
        #expect(informationSource.contains("ScrollView"))
        #expect(informationSource.contains("IOSCompactEntryListGroup"))
        #expect(
            informationSource.contains(
                "ConfigurationUI.appBackground.ignoresSafeArea()"
            )
        )
        #expect(!informationSource.contains(".listStyle(.insetGrouped)"))
        #expect(
            informationSource.contains(
                "ConfigurationUI.compactTrailingControlWidth"
            )
        )
        #expect(
            informationSource.contains(
                "ConfigurationUI.compactRowVerticalPadding"
            )
        )
        #expect(
            editorSource.contains(
                "ConfigurationUI.contentSheetFraction"
            )
        )
        #expect(
            entryRowSource.contains(
                ".v1ConfigurationSheetPanelChrome("
            )
        )
        #expect(entryRowSource.contains("@Environment(\\.dynamicTypeSize)"))
        #expect(!entryRowSource.contains("ViewThatFits(in: .horizontal)"))
        #expect(
            regionSource.contains(
                "cornerRadius: ConfigurationUI.sheetPanelCornerRadius"
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
