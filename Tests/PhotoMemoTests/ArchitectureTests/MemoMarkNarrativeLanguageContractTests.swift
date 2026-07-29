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

        #expect(optionList.contains("subtitle: \"你想围绕谁开展回忆。\""))
        #expect(optionList.contains("subtitle: \"从哪个重要时刻开始记录。\""))
        #expect(optionList.contains("title: \"记忆表达\""))
        #expect(optionList.contains("subtitle: \"让回忆拥有属于自己的表达方式。\""))
        #expect(optionList.contains("subtitle: \"决定这段回忆最终如何呈现。\""))
        #expect(
            configurationPage.contains(
                "pageSubtitle: \"从一个人和一个重要时刻开始，让回忆慢慢成形。\""
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

        #expect(home.contains("title: \"我的预设\""))
        #expect(home.contains("subtitle: \"下一次分享，要用哪种方式记录。\""))
        #expect(output.contains("\"保存这段回忆\""))
        #expect(output.contains("title: \"最终结果\""))
        #expect(output.contains("title: \"回到哪里\""))
        #expect(task.contains("\"进展\""))
        #expect(welcome.contains("subtitle: \"让照片记得，它在人生里的位置。\""))
        #expect(welcome.contains("key: \"welcome.workflow.title\""))
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
