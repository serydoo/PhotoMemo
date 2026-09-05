#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing

@Suite("MemoMark narrative product language")
struct MemoMarkNarrativeLanguageContractTests {

    @Test("active memory-configuration copy follows the approved narrative")
    func activeMemoryConfigurationCopyFollowsApprovedNarrative() throws {
        let optionList = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationOptionList.swift"
        )
        let configurationPage = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/ConfigurationPageSurface.swift"
        )
        let simplifiedChinese = try sourceText(
            "Source/MemoMark/MemoMark/zh-Hans.lproj/Localizable.strings"
        )

        #expect(optionList.contains("configurationTextRow("))
        #expect(optionList.contains("private func localized(_ value: String)"))
        #expect(configurationPage.contains("key: \"configuration.page.subtitle\""))
        #expect(configurationPage.contains("fallback:"))

        #expect(optionList.contains("configuration.memory_start.title"))
        #expect(optionList.contains("configuration.memory_start.subtitle"))
        #expect(optionList.contains("configuration.expression.title"))
        #expect(optionList.contains("configuration.expression.subtitle"))
        #expect(optionList.contains("围绕时间锚点，可选择 %lld 种表达方式。"))
        #expect(optionList.contains("configuration.card_style.title"))
        #expect(optionList.contains("configuration.card_style.subtitle"))
        #expect(optionList.contains("时间与地点"))
        #expect(optionList.contains("configuration.layout.title"))
        #expect(optionList.contains("configuration.layout.subtitle"))
        for phrase in [
            "configuration.memory_start.title",
            "configuration.memory_start.subtitle",
            "configuration.expression.title",
            "configuration.expression.subtitle",
            "configuration.card_style.title",
            "configuration.card_style.subtitle",
            "configuration.layout.title",
            "configuration.layout.subtitle",
            "时间与地点",
            "configuration.photo_description.title",
            "configuration.save_location.title"
        ] {
            #expect(simplifiedChinese.contains("\"\(phrase)\""))
        }
    }

    @Test("primary headings describe memories and saving rather than implementation")
    func primaryHeadingsDescribeMemoriesAndSaving() throws {
        let home = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/HomePageSurface.swift"
        )
        let output = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/V1OutputPageSurface.swift"
        )
        let task = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/TaskPageSurface.swift"
        )
        let welcome = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/WelcomePresentation.swift"
        )
        let regionContent = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/MemoryCardEditorPresentationModifier.swift"
        )
        let subjectEditor = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/SubjectConfigurationFlow.swift"
        )
        let subjectOverview = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/SubjectOverviewSheetSurface.swift"
        )
        let timeAnchorEditor = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/SubjectAnchorDetailSection.swift"
        )

        for key in [
            "home.presets.title", "home.presets.subtitle",
            "output.page.title", "output.page.subtitle",
            "output.destination.title", "output.destination.subtitle",
            "task.page.title", "task.page.subtitle",
            "task.waiting.detail"
        ] {
            #expect(
                [home, output, task].joined().contains(key),
                "primary surface must resolve localization key \(key)"
            )
        }
        #expect(!output.contains("output.result."))
        #expect(welcome.contains("key: \"welcome.workflow.title\""))
        #expect(welcome.contains("welcome.workflow."))
        #expect(welcome.contains("isFirstRunConfigurationReady"))
        #expect(regionContent.contains("configuration.card_editor.title"))
        #expect(subjectEditor.contains("mode: .identityOverview"))
        #expect(subjectOverview.contains("subjectBasicInformation"))
        #expect(timeAnchorEditor.contains("navigationTitle"))
        #expect(timeAnchorEditor.contains("选择一个时间锚点"))
    }

    @Test("macOS labels and localized help use the same product vocabulary")
    func macOSLabelsAndLocalizedHelpUseTheSameProductVocabulary() throws {
        let macOS = try sourceText(
            "Source/MemoMark/MemoMark/ConfigurationCenter/ConfigurationCenterView.swift"
        )
        let simplifiedChinese = try sourceText(
            "Source/MemoMark/MemoMark/zh-Hans.lproj/Localizable.strings"
        )
        let english = try sourceText(
            "Source/MemoMark/MemoMark/en.lproj/Localizable.strings"
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
                "\"回忆对象重要时刻\" = \"回忆对象时间锚点\";"
            )
        )
        #expect(
            english.contains(
                "\"回忆对象重要时刻\" = \"Time Anchors for the Memory Subject\";"
            )
        )
        #expect(
            simplifiedChinese.contains(
                "\"选择一个时间锚点，让照片拥有时间答案。\" = \"选择一个时间锚点，让照片拥有时间答案。\";"
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
