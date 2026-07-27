#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing

@Suite("Apple native product surface contract")
struct AppleNativeProductSurfaceContractTests {

    @Test("MemoMark Design System freezes memory-first restrained UI rules")
    func designSystemFreezesMemoryFirstRestrainedUIRules() throws {
        let designSystem = try sourceText("Docs/DesignSystem.md")

        #expect(designSystem.contains("Status: Frozen"))
        #expect(designSystem.contains("Memory First, not Photo First"))
        #expect(designSystem.contains("One screen, one responsibility"))
        #expect(designSystem.contains("One screen, one accent"))
        #expect(designSystem.contains("One card, one responsibility"))
        #expect(designSystem.contains("A page may have only one"))
        #expect(designSystem.contains("The Configuration Center edits Memory Engine Configuration Objects"))
        #expect(designSystem.contains("Renderer remains stateless"))
        #expect(designSystem.contains("Informational phrases"))
        #expect(!designSystem.contains("1. Photo first."))
        #expect(!designSystem.contains("If two cards can become one, merge them."))
    }

    @Test("configuration and processing apply subtractive visual hierarchy")
    func configurationAndProcessingApplySubtractiveVisualHierarchy() throws {
        let configuration = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1ConfigurationOptionList.swift"
        )
        let processing = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1TaskPageSurface.swift"
        )

        let textFirstRowCount =
            configuration.components(
                separatedBy: "configurationTextRow("
            ).count - 1

        #expect(textFirstRowCount == 5)
        #expect(configuration.contains("Text(detail)"))
        #expect(configuration.contains(".foregroundStyle(.secondary)"))
        #expect(!processing.contains(".fill(Color.accentColor)"))
        #expect(!processing.contains("Color.accentColor.opacity(0.16)"))
        #expect(processing.contains(".fill(ConfigurationUI.controlBackground)"))
        #expect(processing.contains(".stroke(ConfigurationUI.faintHairline)"))
    }

    @Test("processing surface separates result states from live progress")
    func processingSurfaceSeparatesResultStatesFromLiveProgress() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1TaskPageSurface.swift"
        )

        #expect(!source.contains("Circle()\n                    .fill(presentation.currentTask.tint.color)"))
        #expect(source.contains("case .waiting:"))
        #expect(source.contains("case .processing:"))
        #expect(source.contains("case .completed:"))
        #expect(source.contains("case .needsAttention:"))
        #expect(source.contains("title: \"正在处理\""))
        #expect(source.contains("title: \"刚刚完成\""))
        #expect(source.contains("title: \"需要查看\""))
        #expect(source.contains("DisclosureGroup(\"处理详情\")"))
        #expect(!source.contains("private func progressBarTint"))
    }

    @Test("output and region editors use typography before secondary icons")
    func outputAndRegionEditorsUseTypographyBeforeSecondaryIcons() throws {
        let output = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1OutputPageSurface.swift"
        )
        let root = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift"
        )
        let support = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSViewSupportComponents.swift"
        )

        #expect(output.contains("V1TitledSectionCard(\n            title: \"输出目标\""))
        #expect(output.contains("V1TitledSectionCard(\n            title: \"写入与保留\""))
        #expect(output.contains(".verticalPadding / 2"))
        #expect(output.contains("private struct V1OutputContentCard"))
        #expect(!output.contains("private struct V1OutputCompactCard"))
        #expect(!output.contains("title: \"输出目标\",\n                systemImage:"))
        #expect(!output.contains("private struct V1MemoryWriteExplanation"))
        #expect(!output.contains("let tint: Color\n    let title: String\n    let subtitle: String"))
        #expect(support.contains("systemImage: nil"))
        #expect(root.contains("Text(\"配置说明\")"))
        #expect(!root.contains("Label(\"配置说明\", systemImage: \"info.circle\")"))
        #expect(root.contains("regionConfigurationGuide\n                .padding(.horizontal, 4)"))
    }

    @Test("processing and output share titled card hierarchy")
    func processingAndOutputShareTitledCardHierarchy() throws {
        let processing = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1TaskPageSurface.swift"
        )
        let output = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1OutputPageSurface.swift"
        )
        let support = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSViewSupportComponents.swift"
        )
        let configuration = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1ConfigurationOptionList.swift"
        )

        #expect(support.contains("struct V1TitledSectionCard"))
        #expect(support.contains("HStack(alignment: .center, spacing: 8)"))
        #expect(configuration.contains(".font(.headline.weight(.semibold))"))
        #expect(configuration.contains(".font(.caption)"))
        #expect(support.contains(".font(.headline.weight(.semibold))"))
        #expect(support.contains(".font(.caption)"))
        #expect(processing.contains("title: \"最近完成\""))
        #expect(processing.contains("taskStatusPill("))
        #expect(processing.contains("isRecentTasksSheetPresented = true"))
        #expect(processing.contains("V1CardHeaderIconButton("))
        #expect(processing.contains("systemImage: \"ellipsis\""))
        #expect(processing.contains(".frame(width: 40, height: 40)"))
        #expect(processing.contains("ConfigurationUI.controlBackground"))
        #expect(processing.contains(".foregroundStyle(Color.accentColor)"))
        #expect(!processing.contains("Text(\"…\")"))
        #expect(!processing.contains("V1SectionHeading(\n                    \"最近任务\""))
        #expect(!processing.contains("systemImage: MemoMarkSymbol.processing.name,\n                    tint: .blue"))
        #expect(output.contains("private var existingAlbumControlRow"))
        #expect(output.contains(".frame(width: 36, height: 36)"))
        #expect(output.contains(".foregroundStyle(Color.accentColor)"))
        #expect(output.contains(".accessibilityLabel(\n                isLoadingAlbums\n                ? \"正在刷新相册\"\n                : \"刷新相册\""))
    }

    @Test("home summary cards follow configuration heading hierarchy")
    func homeSummaryCardsFollowConfigurationHeadingHierarchy() throws {
        let home = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1HomePageSurface.swift"
        )

        #expect(home.contains("title: \"记忆对象\",\n            subtitle: \"查看当前对象与时间锚点\""))
        #expect(home.contains("title: \"我的配置\",\n            subtitle: \"选择当前生效的记录方式\""))
        #expect(home.contains("勾选切换当前配置"))
        #expect(
            !home.contains(
                "activeConfigurationStatus =\n                    update.activeConfigurationStatus"
            )
        )
        #expect(!home.contains("private struct V1HomeConfigurationCard"))
        #expect(!home.contains("systemImage: MemoMarkSymbol.memorySubject.name"))
        #expect(!home.contains("systemImage: MemoMarkSymbol.configuration.name"))
        #expect(home.contains("HStack(spacing: 8)"))
        #expect(home.contains(".frame(width: 30, height: 30)"))
        #expect(home.contains(".frame(width: 26, height: 30)"))
    }

    @Test("functional navigation accessories use the shared accent color")
    func functionalNavigationAccessoriesUseSharedAccentColor() throws {
        let sourcePaths = [
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSHomeCardPrimitives.swift",
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1TaskPageSurface.swift",
            "Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenterSummarySection.swift",
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1ConfigurationOptionList.swift",
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1SettingsPageSurface.swift",
            "Source/PhotoMemo/PhotoMemo/iOS/Views/IOSCompactEntryRow.swift",
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectOverviewSupport.swift"
        ]

        for sourcePath in sourcePaths {
            let source = try sourceText(sourcePath)
            let chevronSegments = source.components(
                separatedBy: "Image(systemName: \"chevron.right\")"
            ).dropFirst()

            for segment in chevronSegments {
                #expect(
                    segment.prefix(240).contains(
                        ".foregroundStyle(Color.accentColor)"
                    ),
                    "Expected accent chevron in \(sourcePath)"
                )
            }
        }
    }

    @Test("memory subject cards and language settings use nested disclosure hierarchy")
    func memorySubjectCardsAndLanguageSettingsUseNestedHierarchy() throws {
        let overview = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectOverviewSheetSurface.swift"
        )
        let editorFlow = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectConfigurationFlow.swift"
        )
        let editor = try sourceText(
            "Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Editors/MemorySubjectEditorView.swift"
        )
        let settings = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1SettingsPageSurface.swift"
        )

        #expect(overview.contains("title: \"基础资料\""))
        #expect(overview.contains("title: \"时间锚点\""))
        #expect(overview.contains("subjectBasicInformation"))
        #expect(overview.contains(".v1CardChrome()"))
        #expect(overview.contains(".frame(maxWidth: .infinity, alignment: .center)"))
        #expect(overview.contains(".padding(.vertical, 7)"))
        #expect(editorFlow.contains("title: \"基础资料\""))
        #expect(editorFlow.contains("title: \"时间锚点\""))
        #expect(editor.contains("adaptiveIdentityOverviewHeader\n                .padding(12)\n                .subjectIdentityInnerCardChrome()"))
        #expect(editor.contains("compactIdentityFieldsPanel\n                .subjectIdentityInnerCardChrome()"))
        #expect(editor.contains("func subjectIdentityInnerCardChrome()"))
        #expect(settings.contains("case interfaceLanguage"))
        #expect(settings.contains("section: .interfaceLanguage"))
        #expect(settings.contains("trailingValue: interfaceLanguageBinding.wrappedValue.displayTitle"))
        #expect(settings.contains("if let trailingValue,\n                           !isExpanded"))
    }

    @Test("processing surface avoids dashboard and import-first language")
    func processingSurfaceAvoidsDashboardLanguage() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1TaskPageSurface.swift"
        )

        #expect(!source.contains("overviewStrip"))
        #expect(!source.contains("开始处理"))
        #expect(!source.contains("从首页选择照片开始"))
        #expect(source.contains("处理"))
        #expect(source.contains("从 Apple Photos 分享照片"))
    }

    @Test("output persistence copy names output settings")
    func outputPersistenceNamesOutputSettings() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1OutputPageSurface.swift"
        )

        #expect(source.contains("输出设置已保存"))
        #expect(source.contains("保存输出设置"))
        #expect(source.contains("保留拍摄信息"))
        #expect(!source.contains("保留 EXIF 信息"))
    }

    @Test("background status avoids fixed time estimates")
    func backgroundStatusAvoidsFixedTimeEstimates() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/App/PhotoMemoBackgroundStatusService.swift"
        )

        #expect(!source.contains("estimatedSeconds("))
        #expect(!source.contains("约 \\(totalEstimatedSeconds) 秒"))
        #expect(!source.contains("约 \\(minutes) 分钟"))
    }

    @Test("home keeps product objects and removes repeated promotion")
    func homeKeepsObjectsAndRemovesRepeatedPromotion() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1HomePageSurface.swift"
        )

        #expect(!source.contains("developmentBackgroundSection"))
        #expect(!source.contains("V1HomeFeedbackSection"))
        #expect(source.contains("profileSection"))
        #expect(source.contains("currentPresetSection"))
        #expect(source.contains("选择照片"))
    }

    @Test("settings starts with secondary explanations collapsed")
    func settingsStartsSecondaryExplanationsCollapsed() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1SettingsPageSurface.swift"
        )

        #expect(source.contains("expandedSections: Set<SettingsSection> = []"))
        #expect(source.contains("private var memoMarkPlusSection"))
        #expect(!source.contains("private func settingsTonalIcon"))
        #expect(!source.contains("private func settingsThumbnailStack"))
        #expect(source.contains("private func settingsPrivacyRow"))
    }

    @Test("interactive surfaces respect reduced motion")
    func interactiveSurfacesRespectReducedMotion() throws {
        let paths = [
            "Source/PhotoMemo/PhotoMemo/ConfigurationCenter/MemoryCard/InteractiveMemoryCard.swift",
            "Source/PhotoMemo/PhotoMemo/ConfigurationCenter/MemoryCard/InteractiveMemoryCardConfigurationComponentDock.swift",
            "Source/PhotoMemo/PhotoMemo/ConfigurationCenter/MemoryCard/InteractiveMemoryCardCompactPreview.swift",
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1SettingsPageSurface.swift"
        ]

        for path in paths {
            let source = try sourceText(path)
            #expect(source.contains("accessibilityReduceMotion"))
        }
    }

    @Test("configuration center presents objects instead of engineering regions")
    func configurationCenterUsesUserFacingHierarchy() throws {
        let options = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1ConfigurationOptionList.swift"
        )
        let center = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift"
        )
        let preview = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenterTopPreviewSection.swift"
        )

        #expect(options.contains("保存当前配置"))
        #expect(options.contains("更多配置操作"))
        #expect(options.contains("编辑卡片内容"))
        #expect(!options.contains("index: \"1.\""))
        #expect(center.contains("title: \"拍摄信息\""))
        #expect(center.contains("subtitle: \"卡片右上\""))
        #expect(!preview.contains("Apple Photos -> Share"))
        #expect(!preview.contains("workflowChips"))
    }

    @Test("primary product rows grow with accessibility text")
    func primaryRowsUseContentDrivenHeight() throws {
        let home = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1HomePageSurface.swift"
        )
        let processing = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1TaskPageSurface.swift"
        )

        #expect(!home.contains("CGFloat(memoryPresets.count) * 92"))
        #expect(processing.contains(".frame(minHeight: 78)"))
        #expect(!processing.contains(".frame(height: 78)"))
    }

    @Test("card row separators use one symmetric semantic hairline")
    func cardRowSeparatorsUseSharedSymmetricHairline() throws {
        let support = try sourceText(
            "Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Components/InspectorSectionView.swift"
        )
        let configuration = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1ConfigurationOptionList.swift"
        )
        let output = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1OutputPageSurface.swift"
        )

        #expect(support.contains("struct V1HorizontalDivider"))
        #expect(support.contains("ConfigurationUI.faintHairline"))
        #expect(configuration.contains("V1HorizontalDivider("))
        #expect(!configuration.contains("private var optionDivider"))
        #expect(!configuration.contains(".padding(\n                .leading,"))
        #expect(output.contains("V1HorizontalDivider()"))
        #expect(!output.contains("private struct V1OutputDivider"))
    }

    @Test("memory subject detail separates reading from basic information editing")
    func memorySubjectDetailSeparatesReadingFromEditing() throws {
        let detail = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectOverviewSheetSurface.swift"
        )
        let editor = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectConfigurationFlow.swift"
        )

        #expect(detail.contains("subjectIdentitySummary"))
        #expect(detail.contains("subjectBasicInformation"))
        #expect(detail.contains("ToolbarItem(placement: .topBarLeading)"))
        #expect(!detail.contains("ToolbarItem(placement: .topBarTrailing)"))
        #expect(detail.contains("private var editSubjectButton"))
        #expect(detail.contains("V1CardHeaderIconButton("))
        #expect(detail.contains("systemImage: \"pencil\""))
        #expect(detail.contains("accessibilityLabel: \"编辑记忆对象\""))
        #expect(detail.contains("V1TitledSectionCard("))
        #expect(!detail.contains("onSaveSubject"))
        #expect(!detail.contains("当前使用"))
        #expect(!detail.contains("mode: .identityOverview"))
        #expect(editor.contains("mode: .identityOverview"))
        #expect(editor.contains("V1TitledSectionCard("))
        #expect(editor.contains("删除记忆对象"))
    }

    @Test("memory subject detail presents anchors as ordered long press modules")
    func memorySubjectDetailPresentsAnchorModules() throws {
        let detail = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectOverviewSheetSurface.swift"
        )
        let anchors = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectAnchorDetailSection.swift"
        )
        let source = detail + anchors

        #expect(source.contains("ForEach(subject.timeAnchors)"))
        #expect(source.contains("V1IOSSubjectAnchorDetailModule"))
        #expect(source.contains("contextMenu"))
        #expect(source.contains("添加锚点"))
        #expect(source.contains("最多保留 5 个时间锚点"))
        #expect(source.contains("至少保留一个时间锚点"))
        #expect(source.contains("accessibilityAction(named: \"配置锚点\")"))
        #expect(source.contains("accessibilityAction(named: \"删除锚点\")"))
        #expect(!source.contains("时间锚点配置"))
    }

    @Test("single destructive decisions use centered alerts")
    func destructiveDecisionsUseCenteredAlerts() throws {
        let paths = [
            "Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Editors/MemorySubjectEditorView.swift",
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1ConfigurationOptionList.swift",
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1HomePageSurface.swift",
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectAnchorDetailSection.swift",
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectConfigurationFlow.swift",
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1LocalConfigurationLibrarySheet.swift"
        ]

        for path in paths {
            let source = try sourceText(path)
            #expect(source.contains(".alert("))
            #expect(!source.contains(".confirmationDialog("))
        }
    }

    @Test("destructive entry points use native red semantics")
    func destructiveEntryPointsUseNativeSemantics() throws {
        let home = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1HomePageSurface.swift"
        )
        let configuration = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1ConfigurationOptionList.swift"
        )
        let subjectEditor = try sourceText(
            "Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Editors/MemorySubjectEditorView.swift"
        )
        let anchors = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectAnchorDetailSection.swift"
        )
        let subject = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectConfigurationFlow.swift"
        )
        let backups = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1LocalConfigurationLibrarySheet.swift"
        )

        for source in [home, configuration, subjectEditor, anchors, subject, backups] {
            #expect(source.contains("role: .destructive"))
        }
        #expect(home.contains(".tint(.red)"))
        #expect(subjectEditor.contains(".tint(.red)"))
        #expect(anchors.contains(".tint(.red)"))
        #expect(backups.contains(".tint(.red)"))
        #expect(home.contains("本地配置库中的备份会保留。此操作无法撤销。"))
        #expect(configuration.contains("当前未保存的修改会被默认内容替换。此操作无法撤销。"))
        #expect(subject.contains("对象的基础资料和时间锚点都会被删除。此操作无法撤销。"))
        #expect(backups.contains("当前正在使用的配置不会被删除。此操作无法撤销。"))
    }

    @Test("every visible delete entry point declares destructive red semantics")
    func everyVisibleDeleteEntryPointDeclaresDestructiveRedSemantics() throws {
        let home = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1HomePageSurface.swift"
        )
        let subjectEditor = try sourceText(
            "Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Editors/MemorySubjectEditorView.swift"
        )
        let anchors = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectAnchorDetailSection.swift"
        )
        let backups = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1LocalConfigurationLibrarySheet.swift"
        )
        let customFields = try sourceText(
            "Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Inspector/MemoryBlockInspectorCustomFieldsSection.swift"
        )
        let systemModules = try sourceText(
            "Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Inspector/MemoryBlockInspectorSystemModulesSection.swift"
        )
        let expression = try sourceText(
            "Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Editors/ExpressionEditor.swift"
        )

        for source in [home, subjectEditor, anchors, backups] {
            #expect(source.contains("role: .destructive"))
            #expect(source.contains(".tint(.red)"))
        }

        #expect(customFields.contains("Button(role: .destructive)"))
        #expect(customFields.contains(".foregroundStyle(.red)"))
        #expect(customFields.contains("Button(role: .destructive) {"))
        #expect(systemModules.contains("Button(role: .destructive)"))
        #expect(systemModules.contains(".tint(.red)"))
        #expect(expression.contains("Button(role: .destructive)"))
        #expect(expression.contains(".foregroundStyle(.red)"))

        for source in [home, subjectEditor, anchors, backups] {
            #expect(source.contains("role: .destructive)"))
        }
    }

    @Test("bottom primary actions use a softened system tint")
    func bottomPrimaryActionsUseASoftenedSystemTint() throws {
        let sharedSupport = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSViewSupportComponents.swift"
        )
        let tokens = try sourceText(
            "Source/PhotoMemo/PhotoMemo/App/MemoMarkDesignTokens.swift"
        )
        let shareController = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionViewController.swift"
        )

        #expect(sharedSupport.contains("Color.accentColor.opacity("))
        #expect(
            sharedSupport.contains(
                "compactPrimaryActionTintOpacity"
            )
        )
        #expect(
            sharedSupport.contains(
                "compactPrimaryActionShadowOpacity"
            )
        )
        #expect(
            tokens.contains(
                "compactPrimaryActionTintOpacity: Double = 0.84"
            )
        )
        #expect(
            tokens.contains(
                "compactPrimaryActionShadowOpacity: Double = 0.08"
            )
        )
        #expect(
            shareController.contains("view.tintColor")
        )
        #expect(shareController.contains("withAlphaComponent"))
        #expect(!shareController.contains(".systemBlue"))
    }

    @Test("time anchor dialog copy names the consequence")
    func timeAnchorDialogCopyNamesTheConsequence() throws {
        let detail = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectAnchorDetailSection.swift"
        )
        let editor = try sourceText(
            "Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Editors/MemorySubjectEditorView.swift"
        )

        #expect(detail.contains("此操作无法撤销。"))
        #expect(editor.contains("此操作无法撤销。"))
        #expect(detail.contains("至少保留一个时间锚点"))
        #expect(detail.contains("新增另一个锚点后，才能删除当前锚点。"))
    }

    @Test("time anchor deletion validates the current session state")
    func timeAnchorDeletionUsesCurrentSessionState() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectAnchorDetailSection.swift"
        )

        #expect(source.contains("session.state.selectedSubject?.timeAnchors.count"))
        #expect(
            !source.contains(
                "guard (subject?.timeAnchors.count ?? 0) > 1"
            )
        )
    }

    @Test("memory subject editor separates cancel save and delete outcomes")
    func memorySubjectEditorSeparatesCompletionOutcomes() throws {
        let editor = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectConfigurationFlow.swift"
        )
        let root = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift"
        )

        #expect(editor.contains("onCancel:"))
        #expect(editor.contains("onSave:"))
        #expect(editor.contains("Button(\"取消\") {\n                        onCancel()"))
        #expect(editor.contains("flowState.saveChanges()"))
        #expect(editor.contains("onSave()"))
        #expect(root.contains("nextState.showsSubjectOverview = true"))
    }
}

private extension AppleNativeProductSurfaceContractTests {

    func sourceText(_ relativePath: String) throws -> String {
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
