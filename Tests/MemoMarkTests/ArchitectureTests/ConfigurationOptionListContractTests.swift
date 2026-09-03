#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing

@Suite("V1 configuration option list boundary")
struct ConfigurationOptionListContractTests {

    @Test("adaptive option-row layout is isolated from inspector ownership")
    func adaptiveOptionRowLayoutIsIsolatedFromInspectorOwnership() throws {
        let optionListSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationOptionList.swift"
        )
        let rowLayoutSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationOptionRowLayout.swift"
        )

        #expect(optionListSource.contains("ConfigurationOptionRowLayout("))
        #expect(rowLayoutSource.contains("struct ConfigurationOptionRowLayout"))
        #expect(rowLayoutSource.contains("dynamicTypeSize.isAccessibilitySize"))
        #expect(rowLayoutSource.contains("horizontalConfigurationRow("))
        #expect(rowLayoutSource.contains("verticalConfigurationRow("))
        #expect(!rowLayoutSource.contains("ViewThatFits(in: .horizontal)"))
    }

    @Test("custom Logo mode waits for native photo selection before changing")
    func customLogoModeWaitsForNativePhotoSelectionBeforeChanging() throws {
        let optionListSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationOptionList.swift"
        )
        let footerSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationActionFooter.swift"
        )
        let rootSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/MemoMarkConfigurationCenterView.swift"
        )
        let pagesSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/MemoMarkConfigurationCenterView+Pages.swift"
        )
        let runtimeSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/MemoMarkConfigurationCenterView+Runtime.swift"
        )

        #expect(
            optionListSource.contains(
                ".photosPicker(\n            isPresented: $isLogoPickerPresented"
            )
        )
        #expect(pagesSource.contains("logoMode: logoModeSelectionBinding"))
        #expect((rootSource + runtimeSource).contains("handleRequestedLogoMode"))
        #expect((rootSource + runtimeSource).contains("logoAssetRuntimeCoordinator.optimize"))
    }

    @Test("configuration option list stays outside the runtime root")
    func configurationOptionListStaysOutsideRuntimeRoot() throws {
        let optionListSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationOptionList.swift"
        )
        let footerSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationActionFooter.swift"
        )
        let rootSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/MemoMarkConfigurationCenterView.swift"
        )
        let pagesSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/MemoMarkConfigurationCenterView+Pages.swift"
        )

        #expect(optionListSource.contains("struct ConfigurationOptionList: View"))
        #expect(!optionListSource.contains("private struct ConfigurationOptionList: View"))
        #expect(footerSource.contains("private struct ConfigurationActionButtonStyle"))
        #expect(optionListSource.contains("private struct ConfigurationNavigationRowButtonStyle"))
        #expect(pagesSource.contains("return ConfigurationOptionList("))
        #expect(!rootSource.contains("private struct ConfigurationOptionList: View"))
        #expect(!rootSource.contains("private struct ConfigurationActionButtonStyle"))
        #expect(!rootSource.contains("private struct ConfigurationNavigationRowButtonStyle"))
    }

    @Test("configuration center owns output headings and embeds content only")
    func configurationCenterOwnsOutputHeadingsAndEmbedsContentOnly() throws {
        let source = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationOptionList.swift"
        )
        let outputSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/V1OutputPageSurface.swift"
        )
        let rootSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/MemoMarkConfigurationCenterView.swift"
        )
        let pagesSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/MemoMarkConfigurationCenterView+Pages.swift"
        )

        #expect(source.contains("private var photoDescriptionSection: some View"))
        #expect(
            source.contains(
                "title: \"configuration.photo_description.title\""
            )
        )
        #expect(source.contains("private var outputDestinationSection: some View"))
        #expect(
            source.contains(
                "title: \"configuration.save_location.title\""
            )
        )
        #expect(source.contains("OutputPhotoDescriptionContent("))
        #expect(source.contains("OutputDestinationContent("))
        #expect(!source.contains("OutputPhotoDescriptionSection("))
        #expect(!source.contains("OutputDestinationSection("))
        #expect(source.contains("output.$usesCustomMemoryWriteText"))
        #expect(source.contains("output.$outputTarget"))
        #expect(source.contains("output.$selectedExistingAlbumIdentifier"))
        #expect(outputSource.contains("OutputPhotoDescriptionSection("))
        #expect(outputSource.contains("OutputDestinationSection("))
        #expect(outputSource.contains("struct OutputPhotoDescriptionContent: View"))
        #expect(outputSource.contains("struct OutputDestinationContent: View"))
        #expect(pagesSource.contains("outputTarget: $outputDraftState.outputTarget"))
        #expect(pagesSource.contains("usesCustomMemoryWriteText:\n                    $session.usesCustomMemoryWriteText"))
    }

    @Test("standalone output page keeps complete titled section wrappers")
    func standaloneOutputPageKeepsCompleteTitledSectionWrappers() throws {
        let source = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/V1OutputPageSurface.swift"
        )
        let photoSectionStart = try #require(
            source.range(of: "struct OutputPhotoDescriptionSection: View")
        )
        let photoSectionEnd = try #require(
            source.range(
                of: "struct OutputPhotoDescriptionContent: View",
                range: photoSectionStart.upperBound..<source.endIndex
            )
        )
        let destinationSectionStart = try #require(
            source.range(of: "struct OutputDestinationSection: View")
        )
        let destinationSectionEnd = try #require(
            source.range(
                of: "struct OutputDestinationContent: View",
                range: destinationSectionStart.upperBound..<source.endIndex
            )
        )
        let photoSection = source[
            photoSectionStart.lowerBound..<photoSectionEnd.lowerBound
        ]
        let destinationSection = source[
            destinationSectionStart.lowerBound..<destinationSectionEnd.lowerBound
        ]

        #expect(photoSection.contains("ConfigurationTitledSectionCard("))
        #expect(photoSection.contains("OutputPhotoDescriptionContent("))
        #expect(destinationSection.contains("ConfigurationTitledSectionCard("))
        #expect(destinationSection.contains("OutputDestinationContent("))
    }

    @Test("configuration disclosure respects reduced motion")
    func configurationDisclosureRespectsReducedMotion() throws {
        let source = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationOptionList.swift"
        )

        #expect(
            source.contains(
                "@Environment(\\.accessibilityReduceMotion)"
            )
        )
        #expect(
            source.contains(
                "reduceMotion ? nil : .easeInOut(duration: 0.2)"
            )
        )
    }

    @Test("configuration center copy separates titles, descriptions, and current values")
    func configurationCenterCopySeparatesTitlesDescriptionsAndCurrentValues() throws {
        let optionListSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationOptionList.swift"
        )
        let footerSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationActionFooter.swift"
        )
        let pageSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationPageSurface.swift"
        )

        #expect(pageSource.contains("fallback: \"记忆配置\""))
        #expect(
            pageSource.contains(
                "fallback: \"决定记忆围绕谁、如何呈现，以及保存到哪里。\""
            )
        )
        #expect(optionListSource.contains("configuration.memory_start.title"))
        #expect(optionListSource.contains("configuration.memory_start.subtitle"))
        #expect(optionListSource.contains("configuration.expression.subtitle"))
        #expect(optionListSource.contains("configuration.card_style.subtitle"))
        #expect(optionListSource.contains("configuration.layout.title"))
        #expect(optionListSource.contains("configuration.layout.result.preview"))
        #expect(!optionListSource.contains("currentValue: nil"))
        #expect(optionListSource.contains("configuration.photo_description.subtitle"))
        #expect(optionListSource.contains("configuration.save_location.title"))
        #expect(optionListSource.contains("resultTitle:"))
        #expect(optionListSource.contains("output.shouldWritePhotosDescription"))
        #expect(optionListSource.contains("ConfigurationCompactSectionRow("))
        #expect(!optionListSource.contains("subtitle: memoryExpressionSummary"))
        #expect(!optionListSource.contains("subtitle: localized(presentationStyleTitle)"))
        #expect(!optionListSource.contains("title: \"记忆来源\""))
        #expect(!optionListSource.contains("title: \"卡片布局与内容\""))
    }

    @Test("configuration output state stays grouped at the configuration boundary")
    func configurationOutputStateStaysGrouped() throws {
        let source = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationOptionList.swift"
        )
        let rootSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/MemoMarkConfigurationCenterView.swift"
        )
        let pagesSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/MemoMarkConfigurationCenterView+Pages.swift"
        )

        #expect(source.contains("struct ConfigurationOutputBindings"))
        #expect(source.contains("let output: ConfigurationOutputBindings"))
        #expect(source.contains("output.$usesCustomMemoryWriteText"))
        #expect(source.contains("output.$outputTarget"))
        #expect(pagesSource.contains("output: ConfigurationOutputBindings("))
        #expect(!pagesSource.contains("usesCustomMemoryWriteText:\n                $session.usesCustomMemoryWriteText"))
    }

    @Test("all configuration sections share persisted disclosure controls")
    func allConfigurationSectionsSharePersistedDisclosureControls() throws {
        let source = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationOptionList.swift"
        )
        let outputSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/V1OutputPageSurface.swift"
        )

        for section in [
            ".memorySource",
            ".memoryExpression",
            ".presentationStyle"
        ] {
            #expect(source.contains("disclosureState.isExpanded(for: \(section))"))
        }
        #expect(source.contains("disclosureBinding(for: .cardLayout)"))
        #expect(source.contains("disclosureBinding(for: .photoDescription)"))
        #expect(source.contains("disclosureBinding(for: .outputDestination)"))
        #expect(source.contains("OutputPhotoDescriptionContent("))
        #expect(source.contains("OutputDestinationContent("))
        #expect(source.contains("automaticallyFocusesNewAlbumName: false"))
        #expect(
            outputSource.contains(
                "var automaticallyFocusesNewAlbumName = true"
            )
        )
        #expect(
            outputSource.contains(
                "guard automaticallyFocusesNewAlbumName else { return }"
            )
        )
        #expect(
            source.contains(
                "collapsedAccessibilityLabel: \"configuration.memory_start.accessibility.expand\""
            )
        )
        #expect(!source.contains("collapsedTitle: \"展开\""))
        #expect(source.contains("ConfigurationCompactSectionRow("))
        #expect(!outputSource.contains("var isExpanded: Binding<Bool>?"))
        #expect(!outputSource.contains("V1ConfigurationDisclosureButton("))
    }

    @Test("configuration action copy resolves through interface localization")
    func configurationActionCopyResolvesThroughInterfaceLocalization() throws {
        let source = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationActionFooter.swift"
        )

        #expect(source.contains("configuration.action.reset.title"))
        #expect(source.contains("configuration.action.delete.title"))
        #expect(source.contains("localized(\"更多配置操作\")"))
        #expect(source.contains("localized(\"configuration.editor.save\")"))
        #expect(!source.contains("Button(\"恢复默认配置？\""))
        #expect(!source.contains("Button(\"删除当前配置？\""))
    }

    @Test("configuration card owns status while a translucent footer floats above the editor")
    func configurationCardOwnsStatusWhileFooterFloatsAboveEditor() throws {
        let optionListSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationOptionList.swift"
        )
        let footerSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationActionFooter.swift"
        )
        let editorSurfaceSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/MemoryCardEditorPageSurface.swift"
        )
        let configurationPageSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationPageSurface.swift"
        )
        let rootSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/MemoMarkConfigurationCenterView.swift"
        )
        let pagesSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/MemoMarkConfigurationCenterView+Pages.swift"
        )

        #expect(footerSource.contains("struct ConfigurationActionFooter"))
        #expect(optionListSource.contains("let configurationStatus: ConfigurationPersistenceStatus"))
        #expect(optionListSource.contains("private var configurationStatusCard"))
        #expect(optionListSource.contains("configurationStatusCard"))
        #expect(footerSource.contains("private var configurationActionRow"))
        #expect(footerSource.contains("private var centeredPrimaryAction"))
        #expect(footerSource.contains("ZStack(alignment: .bottom)"))
        #expect(footerSource.contains("Image(systemName: \"ellipsis\")"))
        #expect(!footerSource.contains("private var configurationStatusLabel"))
        #expect(!footerSource.contains("Image(systemName: \"ellipsis.circle\")"))
        #expect(editorSurfaceSource.contains(".safeAreaInset(edge: .bottom, spacing: 0)"))
        #expect(!editorSurfaceSource.contains(".overlay(alignment: .bottom)"))
        #expect(footerSource.contains("@Environment(\\.accessibilityReduceTransparency)"))
        #expect(footerSource.contains(".fill(.regularMaterial)"))
        #expect(footerSource.contains(".fill(ConfigurationUI.panelBackground)"))
        #expect(configurationPageSource.contains("ConfigurationActionFooter("))
        #expect(configurationPageSource.contains("configurationStatus: configurationStatus"))
        #expect(pagesSource.contains("ConfigurationPageSurface("))
    }

    @Test("region editor explains how personal words and photo details enter the card")
    func regionEditorExplainsPersonalWordsAndPhotoDetails() throws {
        let editorClusterSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/MemoryCardRegionEditorCluster.swift"
        )
        let regionSource = try sourceText(
            "Source/MemoMark/MemoMark/ConfigurationCenter/Models/CardRegion.swift"
        )

        #expect(!editorClusterSource.contains("正在编辑输出内容"))
        #expect(!editorClusterSource.contains("正在编辑\\(activeRegion.displayTitle)"))
        #expect(regionSource.contains("return \"左上\""))
        #expect(regionSource.contains("return \"左下\""))
        #expect(regionSource.contains("return \"右上\""))
        #expect(regionSource.contains("return \"右下\""))
        #expect(regionSource.contains("return \"默认动作 + 设备信息\""))
        #expect(regionSource.contains("return \"默认智能模块输出信息\""))
        #expect(editorClusterSource.contains("struct MemoryCardRegionEditorCluster: View"))
        #expect(editorClusterSource.contains("ForEach(visibleRegions"))
        #expect(editorClusterSource.contains("MemoryCardTextKitSessionEditor("))
        #expect(editorClusterSource.contains("这里的内容会怎样使用？"))
        #expect(editorClusterSource.contains("修改会实时出现在上方完整卡片预览中。"))
        #expect(editorClusterSource.contains("处理照片时，模块会替换为每张照片自己的信息。"))
        #expect(editorClusterSource.contains("这里的内容还会写入 Apple Photos 的照片说明"))
    }

    @Test("memory expression is an on-demand section outside memory source")
    func memoryExpressionIsOnDemandSectionOutsideMemorySource() throws {
        let optionListSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationOptionList.swift"
        )
        let supportSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationCenterViewSupportComponents.swift"
        )
        let selectorStart = try #require(
            supportSource.range(of: "struct CompactSelectionLabel")
        )
        let selectorEnd = try #require(
            supportSource.range(
                of: "struct ConfigurationResultLabel",
                range: selectorStart.upperBound..<supportSource.endIndex
            )
        )
        let selectorSource = supportSource[
            selectorStart.lowerBound..<selectorEnd.lowerBound
        ]

        let sourceSectionStart = try #require(
            optionListSource.range(of: "private var memorySourceSection: some View")
        )
        let sourceSectionEnd = try #require(
            optionListSource.range(
                of: "private var memoryExpressionSection: some View",
                range: sourceSectionStart.upperBound..<optionListSource.endIndex
            )
        )
        let memorySourceSection = optionListSource[
            sourceSectionStart.lowerBound..<sourceSectionEnd.lowerBound
        ]

        #expect(!memorySourceSection.contains("memoryDisplayRow"))
        #expect(!memorySourceSection.contains("memoryExpressionPreview"))
        #expect(optionListSource.contains("private var memoryExpressionSection: some View"))
        #expect(optionListSource.contains("@Binding var disclosureState: ConfigurationDisclosureState"))
        #expect(optionListSource.contains("disclosureState.isExpanded(for: .memoryExpression)"))
        #expect(optionListSource.contains("ConfigurationCompactSectionRow("))
        #expect(!optionListSource.contains("MemoryExpressionDisclosureState()"))
        #expect(!optionListSource.contains("private var isPresentationStyleExpanded"))
        #expect(supportSource.contains(".buttonStyle(.plain)"))
        #expect(!supportSource.contains(".buttonBorderShape(.capsule)"))
        #expect(supportSource.contains("expandedAccessibilityLabel"))
        #expect(supportSource.contains("collapsedAccessibilityLabel"))
        #expect(supportSource.contains("accessibilityValue"))
        #expect(supportSource.contains("struct ConfigurationResultLabel: View"))
        #expect(supportSource.contains("compactConfigurationRowMinimumHeight"))
        #expect(optionListSource.contains("title: \"configuration.expression.title\""))
        #expect(!optionListSource.contains("选择照片在这个时刻前后怎样表达。"))
        #expect(!optionListSource.contains("memoryExpressionGuide"))
        #expect(optionListSource.contains("memoryDisplayRow"))
        #expect(
            optionListSource.contains(
                "subtitle: \"configuration.expression.subtitle\""
            )
        )
        #expect(optionListSource.contains("ConfigurationCompactSectionRow("))
        #expect(
            !optionListSource.contains(
                "localized(\"拍摄前、当天和之后，会使用不同说法。\")"
            )
        )
        #expect(optionListSource.contains("title: \"表达方式\""))
        #expect(!optionListSource.contains("title: \"表达风格\""))
        #expect(!optionListSource.contains("title: \"表达样式\""))
        #expect(optionListSource.contains("subtitle: memoryDisplaySubtitle"))
        #expect(
            optionListSource.contains(
                "围绕时间锚点，可选择 %lld 种表达方式。"
            )
        )
        #expect(
            optionListSource.contains(
                ".accessibilityLabel(localized(\"表达方式\"))"
            )
        )
        #expect(
            optionListSource.contains(
                "Int64(availableMemoryDisplayStyles.count)"
            )
        )
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
        #expect(optionListSource.contains(".font(.footnote.weight(.semibold))"))
        #expect(optionListSource.contains("Text(localized(\"这张照片会这样表达\"))"))
        #expect(optionListSource.contains("ConfigurationUI.controlBackground"))
        #expect(optionListSource.contains("ConfigurationUI.faintHairline"))
        #expect(
            optionListSource.contains(
                ".accessibilityLabel(localized(\"这张照片会这样表达\"))"
            )
        )
        #expect(
            optionListSource.contains(
                "CompactSelectionLabel(\n                        title: localized(memoryDisplayValue)"
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
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationOptionList.swift"
        )
        let footerSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationActionFooter.swift"
        )

        #expect(footerSource.contains("private var saveActionButtonStyle:"))
        #expect(footerSource.contains("isRestrained: configurationStatus == .saved"))
        #expect(
            footerSource.contains(
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
            "Source/MemoMark/MemoMark/iOS/Views/ModuleLibrarySurface.swift"
        )

        #expect(moduleSource.contains("private var groupedModules: [ModuleGroup]"))
        #expect(moduleSource.contains("ForEach(groupedModules)"))
        #expect(moduleSource.contains("let categoryTitles = modules.reduce"))
        #expect(moduleSource.contains("modules: modules.filter"))
        #expect(!moduleSource.contains("filteredModules.sorted"))
    }

    @Test("logo row keeps one concise subtitle without selection detail")
    func logoRowKeepsOneConciseSubtitleWithoutSelectionDetail() throws {
        let source = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationOptionList.swift"
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

    @Test("card style is promoted before card layout and drives one-region editing")
    func cardStylePrecedesCardLayoutAndDrivesEditing() throws {
        let optionListSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationOptionList.swift"
        )
        let rootSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/MemoMarkConfigurationCenterView.swift"
        )
        let regionSource = try sourceText(
            "Source/MemoMark/MemoMark/ConfigurationCenter/Models/CardRegion.swift"
        )
        let editorSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/MemoMarkConfigurationCenterView+Editor.swift"
        )
        let styleRange = try #require(
            optionListSource.range(of: "expressionStyleSection")
        )
        let layoutRange = try #require(
            optionListSource.range(of: "title: \"configuration.layout.title\"")
        )

        #expect(styleRange.lowerBound < layoutRange.lowerBound)
        #expect(optionListSource.contains("title: \"configuration.card_style.title\""))
        #expect(!optionListSource.contains("title: \"回忆怎样呈现\""))
        #expect(
            optionListSource.contains(
                "configurationSectionHeader(\n            title: \"configuration.card_style.title\","
            )
        )
        #expect(
            !optionListSource.contains(
                "configurationTextRow(\n                        title: \"卡片样式\","
            )
        )
        #expect(
            optionListSource.contains(
                "subtitle: \"configuration.card_style.subtitle\""
            )
        )
        #expect(!optionListSource.contains("预览与内容编辑会一起变化"))
        #expect(optionListSource.contains("RecordCardPresentationStyle.allCases"))
        #expect(optionListSource.contains("private var presentationStyleSectionHeader"))
        #expect(optionListSource.contains("private var presentationStyleSectionHeader"))
        #expect(
            optionListSource.contains(
                "disclosureState.isExpanded(for: .presentationStyle)"
            )
        )
        #expect(!optionListSource.contains("isPresentationStyleExpanded = true"))
        #expect(optionListSource.contains("title: \"当前样式\""))
        #expect(
            optionListSource.contains(
                "configuration.card_style.accessibility.collapse"
            )
        )
        #expect(
            optionListSource.contains(
                "configuration.card_style.accessibility.expand"
            )
        )
        #expect(!optionListSource.contains("private var borderStyleRow"))
        #expect(optionListSource.contains("private var logoRow: some View"))
        #expect(
            optionListSource.contains(
                "subtitle: \"configuration.layout.subtitle\""
            )
        )
        #expect(editorSource.contains("CardRegion.editableRegions("))
        #expect(editorSource.contains("for: presentationStyle"))
        #expect(regionSource.contains("presentationStyle.contentContract.editableTextAreas"))
    }

    @Test("advanced modules move location display behind the card-content-style editor")
    func advancedModulesMoveLocationDisplayBehindCardContentStyleEditor() throws {
        let optionListSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationOptionList.swift"
        )
        let sheetSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/AdvancedModulesSheet.swift"
        )
        let supportSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationCenterViewSupportComponents.swift"
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
                "title: \"时间与地点\""
            )
        )
        #expect(
            optionListSource.contains(
                "subtitle: \"configuration.time_place.subtitle\""
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
                "struct AdvancedModulesSheet: View"
            )
        )
        #expect(sheetSource.contains("NavigationStack"))
        #expect(sheetSource.contains("ScrollView"))
        #expect(sheetSource.contains("IOSCompactEntryListGroup"))
        #expect(!sheetSource.contains("List {"))
        #expect(!sheetSource.contains(".listStyle(.insetGrouped)"))
        #expect(sheetSource.contains("ConfigurationUI.sheetPanelPadding"))
        #expect(sheetSource.contains("Text(localized(\"地点显示\"))"))
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
                separatedBy: "HorizontalDivider("
            ).count >= 3
        )
        #expect(sheetSource.contains("Button(\"完成\")"))
        #expect(sheetSource.contains("Menu {"))
        #expect(sheetSource.contains("CompactSelectionLabel"))
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
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationOptionList.swift"
        )
        let supportSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationCenterViewSupportComponents.swift"
        )

        let headerStart = try #require(
            optionListSource.range(
                of: "private var memorySourceSectionHeader: some View"
            )
        )
        let headerEnd = try #require(
            optionListSource.range(
                of: "private var memoryExpressionSection: some View"
            )
        )
        let headerSource = optionListSource[
            headerStart.lowerBound..<headerEnd.lowerBound
        ]

        #expect(headerSource.contains("configurationSectionHeader("))
        #expect(!headerSource.contains("ViewThatFits(in: .horizontal)"))
        #expect(!headerSource.contains(".frame(minHeight: 44)"))
        #expect(headerSource.contains("configurationSectionHeader("))
        #expect(optionListSource.contains("ConfigurationCompactSectionRow("))
        #expect(
            supportSource.contains(
                "minHeight: ConfigurationUI.minimumInteractiveHeight"
            )
        )
        #expect(
            supportSource.contains(
                "ConfigurationSectionCardMetrics.compactConfigurationRowMinimumHeight"
            )
        )
        #expect(supportSource.contains("dynamicTypeSize.isAccessibilitySize"))
        #expect(supportSource.contains(".contentShape(Rectangle())"))
    }

    @Test("custom Logo picker keeps compact chrome with a minimum hit target")
    func customLogoPickerKeepsCompactChromeWithMinimumHitTarget() throws {
        let optionListSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationOptionList.swift"
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
            "Source/MemoMark/MemoMark/iOS/Views/AdvancedModulesSheet.swift"
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
        #expect(sheetSource.contains(".navigationTitle(\"时间与地点\")"))
        #expect(
            sheetSource.contains(
                "决定照片中的时间和地点怎样呈现。"
            )
        )
        #expect(sheetSource.contains("Text(localized(\"地点显示\"))"))
        #expect(sheetSource.contains("Text(localized(\"日期补充\"))"))
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
            "Source/MemoMark/MemoMark/iOS/Views/MemoryCardEditorPresentationModifier.swift"
        )
        let entryRowSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/IOSCompactEntryRow.swift"
        )

        #expect(editorSource.contains("configuration.card_editor.title"))
        #expect(editorSource.contains("MemoryCardEditorOverlay"))
        #expect(editorSource.contains("contentEditorTopBoundaryFraction"))
        #expect(editorSource.contains("contentEditorMinimumTopBoundary"))
        #expect(!editorSource.contains(".presentationDetents"))
        #expect(
            editorSource.contains(
                "configuration.card_editor.subtitle"
            )
        )
        #expect(editorSource.contains(".padding(.top, 8)"))
        #expect(editorSource.contains(".padding(.bottom, 10)"))
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
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationCenterViewSupportComponents.swift"
        )
        let anchorSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/SubjectAnchorDetailSection.swift"
        )
        let informationSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/AdvancedModulesSheet.swift"
        )
        let cardSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/MemoryCardEditorPresentationModifier.swift"
        )

        #expect(
            supportSource.contains(
                "struct ConfigurationSheetSubtitle: View"
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
        #expect(anchorSource.contains("ConfigurationSheetSubtitle("))
        #expect(anchorSource.contains(".safeAreaInset(edge: .top, spacing: 0)"))
        #expect(
            anchorSource.contains(
                "选择一个时间起点，让照片拥有时间答案。"
            )
        )
        #expect(informationSource.contains("ConfigurationSheetSubtitle("))
        #expect(
            informationSource.contains(
                ".safeAreaInset(edge: .top, spacing: 0)"
            )
        )
        #expect(
            informationSource.contains(
                "决定照片中的时间和地点怎样呈现。"
            )
        )
        #expect(cardSource.contains("MemoryCardEditorOverlay"))
        #expect(cardSource.contains("keyboardWillChangeFrameNotification"))
        #expect(cardSource.contains(".ignoresSafeArea(.keyboard)"))
        #expect(
            cardSource.contains(
                "组合文字、照片信息与记忆表达。"
            )
        )
    }

    @Test("vertical configuration rows keep compact controls trailing aligned")
    func verticalConfigurationRowsKeepCompactControlsTrailingAligned() throws {
        let rowLayoutSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationOptionRowLayout.swift"
        )
        let verticalRowStart = try #require(
            rowLayoutSource.range(
                of: "private func verticalConfigurationRow"
            )
        )
        let verticalRowEnd = try #require(
            rowLayoutSource.range(
                of: "private func configurationRowHeading",
                range: verticalRowStart.upperBound..<rowLayoutSource.endIndex
            )
        )
        let verticalRowSource = rowLayoutSource[
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
        let rowLayoutSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationOptionRowLayout.swift"
        )
        let adaptiveStart = try #require(
            rowLayoutSource.range(
                of: "private func adaptiveConfigurationRow"
            )
        )
        let horizontalStart = try #require(
            rowLayoutSource.range(
                of: "private func horizontalConfigurationRow",
                range: adaptiveStart.upperBound..<rowLayoutSource.endIndex
            )
        )
        let adaptiveSource = rowLayoutSource[
            adaptiveStart.lowerBound..<horizontalStart.lowerBound
        ]
        let verticalStart = try #require(
            rowLayoutSource.range(
                of: "private func verticalConfigurationRow",
                range: horizontalStart.upperBound..<rowLayoutSource.endIndex
            )
        )
        let horizontalSource = rowLayoutSource[
            horizontalStart.lowerBound..<verticalStart.lowerBound
        ]

        #expect(adaptiveSource.contains("dynamicTypeSize.isAccessibilitySize"))
        #expect(adaptiveSource.contains("horizontalConfigurationRow("))
        #expect(!adaptiveSource.contains("ViewThatFits(in: .horizontal)"))
        #expect(horizontalSource.contains("minWidth: 72,"))
        #expect(horizontalSource.contains("maxWidth: horizontalTrailingWidth"))
        #expect(horizontalSource.contains("HStack(\n            alignment: .center"))
    }

    @Test("configuration controls and sheets use one shared metric system")
    func configurationControlsAndSheetsUseOneMetricSystem() throws {
        let tokenSource = try sourceText(
            "Source/MemoMark/MemoMark/App/MemoMarkDesignTokens.swift"
        )
        let configurationUISource = try sourceText(
            "Source/MemoMark/MemoMark/ConfigurationCenter/Components/InspectorSectionView.swift"
        )
        let optionListSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationOptionList.swift"
        )
        let supportSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationCenterViewSupportComponents.swift"
        )
        let anchorSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/SubjectAnchorDetailSection.swift"
        )
        let informationSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/AdvancedModulesSheet.swift"
        )
        let editorSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/MemoryCardEditorPresentationModifier.swift"
        )
        let entryRowSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/IOSCompactEntryRow.swift"
        )
        let regionSource = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/MemoryCardRegionEditorCluster.swift"
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
                "struct ConfigurationSheetPanelChrome: ViewModifier"
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
        #expect(editorSource.contains("MemoryCardEditorOverlay"))
        #expect(editorSource.contains("contentEditorMinimumTopBoundary"))
        #expect(editorSource.contains(".safeAreaPadding(.bottom"))
        #expect(!editorSource.contains(".presentationContentInteraction(.scrolls)"))
        #expect(
            entryRowSource.contains(
                ".v1ConfigurationSheetPanelChrome("
            )
        )
        #expect(entryRowSource.contains("@Environment(\\.dynamicTypeSize)"))
        #expect(!entryRowSource.contains("ViewThatFits(in: .horizontal)"))
        #expect(regionSource.contains("cornerRadius: ConfigurationUI.cardCornerRadius"))
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
