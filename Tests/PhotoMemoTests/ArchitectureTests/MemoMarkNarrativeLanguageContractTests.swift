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
        let simplifiedChinese = try sourceText(
            "Source/PhotoMemo/PhotoMemo/zh-Hans.lproj/Localizable.strings"
        )

        #expect(optionList.contains("configurationTextRow("))
        #expect(optionList.contains("private func localized(_ value: String)"))
        #expect(configurationPage.contains("key: \"configuration.page.subtitle\""))
        #expect(configurationPage.contains("fallback:"))

        #expect(optionList.contains("你想围绕谁开展回忆。"))
        #expect(optionList.contains("这一刻怎样表达"))
        #expect(!optionList.contains("选择照片在这个时刻前后怎样表达。"))
        #expect(optionList.contains("表达方式"))
        #expect(optionList.contains("围绕时间锚点，可选择 %lld 种表达方式。"))
        #expect(optionList.contains("卡片样式"))
        #expect(!optionList.contains("选择照片卡片的整体视觉风格。"))
        #expect(optionList.contains("时间与地点"))
        #expect(
            optionList.contains(
                "组合自己的文字、照片信息和记忆表达。"
            )
        )
        for phrase in [
            "你想围绕谁开展回忆。",
            "这一刻怎样表达",
            "表达方式",
            "围绕时间锚点，可选择 %lld 种表达方式。",
            "卡片样式",
            "时间与地点",
            "组合自己的文字、照片信息和记忆表达。"
        ] {
            #expect(simplifiedChinese.contains("\"\(phrase)\""))
        }
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

        for key in [
            "home.presets.title", "home.presets.subtitle",
            "output.page.title", "output.page.subtitle",
            "output.result.title", "output.result.subtitle",
            "output.destination.title", "output.destination.subtitle",
            "task.page.title", "task.page.subtitle",
            "task.waiting.detail"
        ] {
            #expect(
                [home, output, task].joined().contains(key),
                "primary surface must resolve localization key \(key)"
            )
        }
        #expect(welcome.contains("key: \"welcome.workflow.title\""))
        #expect(welcome.contains("welcome.workflow."))
        #expect(welcome.contains("isFirstRunConfigurationReady"))
        #expect(regionContent.contains("Text(\"卡片内容\")"))
        #expect(subjectEditor.contains("mode: .identityOverview"))
        #expect(subjectOverview.contains("subjectBasicInformation"))
        #expect(timeAnchorEditor.contains("navigationTitle"))
        #expect(timeAnchorEditor.contains("选择一个时间起点"))
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
                "\"settings.guide.expression.title\" = \"照片怎样表达时间\";"
            )
        )
        #expect(
            english.contains(
                "\"settings.guide.expression.title\" = \"How Photos Express Time\";"
            )
        )
        #expect(
            simplifiedChinese.contains(
                "\"时间与地点\" = \"时间与地点\";"
            )
        )
        #expect(
            english.contains(
                "\"时间与地点\" = \"Time & Location\";"
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
                "\"决定照片中的时间和地点怎样呈现。\" = \"决定照片中的时间和地点怎样呈现。\";"
            )
        )
        #expect(
            simplifiedChinese.contains(
                "\"探索不同组合，也欢迎告诉我们你的自定义想法。\" = \"探索不同组合，也欢迎告诉我们你的自定义想法。\";"
            )
        )
        #expect(
            english.contains(
                "\"决定照片中的时间和地点怎样呈现。\" = \"Choose how time and location are presented on the photo.\";"
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
