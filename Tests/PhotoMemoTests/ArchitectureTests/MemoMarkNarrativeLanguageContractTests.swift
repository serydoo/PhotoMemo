#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing

@Suite("MemoMark narrative product language")
struct MemoMarkNarrativeLanguageContractTests {

    @Test("active memory-configuration copy follows the approved narrative")
    func activeMemoryConfigurationCopyFollowsApprovedNarrative() throws {
        let optionList = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1ConfigurationOptionList.swift"
        )
        let configurationPage = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1ConfigurationPageSurface.swift"
        )

        #expect(
            optionList.contains(
                "subtitle: \"你想围绕谁开展回忆。\""
            )
        )
        #expect(
            optionList.contains(
                "subtitle: \"回忆对象重要时刻\""
            )
        )
        #expect(optionList.contains("title: \"记忆表达\""))
        #expect(optionList.contains("subtitle: \"让回忆拥有属于自己的表达方式。\""))
        #expect(optionList.contains("subtitle: \"决定这段回忆最终如何呈现。\""))
        #expect(optionList.contains("subtitle: \"决定卡片里的内容与显示方式。\""))
        #expect(optionList.contains("title: \"更多信息\""))
        #expect(optionList.contains("subtitle: \"调整地点与拍摄时间的显示方式。\""))
        #expect(!optionList.contains("title: \"高级模块\""))
        #expect(
            configurationPage.contains(
                "pageSubtitle: \"围绕一个人和一个重要时刻，决定照片如何呈现。\""
            )
        )
    }

    @Test("primary headings describe memories and saving rather than implementation")
    func primaryHeadingsDescribeMemoriesAndSaving() throws {
        let home = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1HomePageSurface.swift"
        )
        let output = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1OutputPageSurface.swift"
        )
        let task = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1TaskPageSurface.swift"
        )
        let welcome = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1WelcomePresentation.swift"
        )
        let regionContent = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1EditorPresentationModifier.swift"
        )
        let subjectEditor = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectConfigurationFlow.swift"
        )
        let subjectOverview = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectOverviewSheetSurface.swift"
        )
        let timeAnchorEditor = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectAnchorDetailSection.swift"
        )

        #expect(home.contains("title: \"我的预设\""))
        #expect(home.contains("subtitle: \"下一次分享，照片会怎样呈现。\""))
        #expect(output.contains("\"保存这段回忆\""))
        #expect(output.contains("subtitle: \"决定新照片如何留下，也选择它回到哪里。\""))
        #expect(output.contains("title: \"新照片\""))
        #expect(output.contains("subtitle: \"选择照片形式与需要保留的信息。\""))
        #expect(output.contains("title: \"回到哪里\""))
        #expect(task.contains("\"进展\""))
        #expect(task.contains("Text(\"从 Apple Photos 分享照片，即可开始生成。\")"))
        #expect(welcome.contains("subtitle: \"让照片记得，它在人生里的位置。\""))
        #expect(welcome.contains("key: \"welcome.workflow.title\""))
        #expect(welcome.contains("Text(\"对象名称\")"))
        #expect(welcome.contains(".accessibilityLabel(\"对象名称，必填\")"))
        #expect(welcome.contains("Text(isSaving ? \"正在保存\" : \"完成设置\")"))
        #expect(regionContent.contains(".navigationTitle(\"卡片内容\")"))
        #expect(subjectEditor.contains("subtitle: \"维护与这个对象有关的重要时刻。\""))
        #expect(subjectOverview.contains("subtitle: \"这些重要时刻会影响照片中的时间表达。\""))
        #expect(timeAnchorEditor.contains(".navigationTitle(\"时间锚点\")"))
        #expect(
            timeAnchorEditor.contains(
                "选择一个时间起点，让照片拥有时间答案。"
            )
        )
    }

    @Test("macOS labels and localized help use the same product vocabulary")
    func macOSLabelsAndLocalizedHelpUseTheSameProductVocabulary() throws {
        let macOS = try sourceText(
            "Source/PhotoMemo/PhotoMemo/ConfigurationCenter/ConfigurationCenterView.swift"
        )
        let simplifiedChinese = try sourceText(
            "Source/PhotoMemo/PhotoMemo/zh-Hans.lproj/Localizable.strings"
        )
        let english = try sourceText(
            "Source/PhotoMemo/PhotoMemo/en.lproj/Localizable.strings"
        )

        #expect(macOS.contains(".navigationTitle(\"记忆对象\")"))
        #expect(macOS.contains(".navigationTitle(\"编辑\")"))
        #expect(
            simplifiedChinese.contains(
                "\"settings.guide.expression.title\" = \"了解记忆表达\";"
            )
        )
        #expect(
            english.contains(
                "\"settings.guide.expression.title\" = \"Explore Memory Expression\";"
            )
        )
        #expect(
            simplifiedChinese.contains(
                "\"更多信息\" = \"更多信息\";"
            )
        )
        #expect(
            english.contains(
                "\"更多信息\" = \"More Information\";"
            )
        )
        #expect(
            simplifiedChinese.contains(
                "\"回忆对象重要时刻\" = \"回忆对象重要时刻\";"
            )
        )
        #expect(
            english.contains(
                "\"回忆对象重要时刻\" = \"Important moments for the Memory Subject\";"
            )
        )
        #expect(
            simplifiedChinese.contains(
                "\"选择一个时间起点，让照片拥有时间答案。\" = \"选择一个时间起点，让照片拥有时间答案。\";"
            )
        )
        #expect(
            simplifiedChinese.contains(
                "\"更多内容会根据实际需要逐步加入。\" = \"更多内容会根据实际需要逐步加入。\";"
            )
        )
        #expect(
            simplifiedChinese.contains(
                "\"探索不同组合，也欢迎告诉我们你的自定义想法。\" = \"探索不同组合，也欢迎告诉我们你的自定义想法。\";"
            )
        )
        #expect(
            english.contains(
                "\"更多内容会根据实际需要逐步加入。\" = \"More options will be added as real needs emerge.\";"
            )
        )
        #expect(
            english.contains(
                "\"探索不同组合，也欢迎告诉我们你的自定义想法。\" = \"Explore different combinations and share the customizations you would like to see.\";"
            )
        )
    }

    @Test("the canonical guide preserves the narrative language boundary")
    func canonicalGuidePreservesNarrativeLanguageBoundary() throws {
        let guide = try sourceText(
            "Docs/Guidelines/PRODUCT_LANGUAGE_GUIDE.md"
        )

        #expect(
            guide.contains(
                "自然、克制、有温度；始终围绕人与回忆，而不是围绕功能与技术。"
            )
        )
        #expect(guide.contains("中文名称：`叙事式产品语言`"))
        #expect(guide.contains("MemoMark's language should have `生活感`"))
        #expect(guide.contains("4. 决定这段回忆最终如何呈现。"))
        #expect(guide.contains("## Precision Boundary"))
        #expect(guide.contains("## Title And Subtitle Roles"))
        #expect(guide.contains("### Compact Control Rows"))
        #expect(guide.contains("## Contextual Verb Boundary"))
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
