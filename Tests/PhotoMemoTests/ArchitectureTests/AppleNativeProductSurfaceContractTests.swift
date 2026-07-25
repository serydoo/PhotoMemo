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

        #expect(options.contains("保存配置"))
        #expect(options.contains("更多配置操作"))
        #expect(options.contains("编辑卡片内容"))
        #expect(!options.contains("index: \"1.\""))
        #expect(center.contains("title: \"拍摄信息\""))
        #expect(center.contains("subtitle: \"卡片区域 C\""))
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

        #expect(detail.contains("subjectIdentityHeader"))
        #expect(detail.contains("subjectBasicInformation"))
        #expect(detail.contains("ToolbarItem(placement: .topBarLeading)"))
        #expect(detail.contains("ToolbarItem(placement: .topBarTrailing)"))
        #expect(detail.contains("Button(\"编辑\")"))
        #expect(!detail.contains("onSaveSubject"))
        #expect(!detail.contains("当前使用"))
        #expect(!detail.contains("mode: .identityOverview"))
        #expect(editor.contains("mode: .identityOverview"))
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
