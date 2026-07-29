import Foundation
import Testing
@testable import PhotoMemo

@Suite("V1 settings expression guide")
struct V1SettingsExpressionGuideContractTests {

    @Test("settings help exposes a beginner expression formula guide")
    func settingsHelpExposesExpressionFormulaGuide() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1SettingsExpressionGuide.swift"
        )

        #expect(source.contains("let language: MemoMarkLanguage"))
        #expect(source.contains("private func localized"))
        #expect(source.contains("formulaToken("))
        #expect(source.contains("settings.expression.guide.subject"))
        #expect(source.contains("AnchorType.allCases"))
        #expect(source.contains("availableStyles"))
        #expect(source.contains("localizedStyleTitle"))
        #expect(source.contains("role: .subject"))
        #expect(source.contains("role: .smartOutput"))
        #expect(source.contains("role: .anchorResult"))
        #expect(source.contains("formula.before"))
        #expect(source.contains("formula.onAnchor"))
        #expect(source.contains("formula.after"))
        #expect(source.contains("private func localizedFormula"))
        #expect(source.contains("settings.expression.formula.\\(style.rawValue)"))
    }

    @Test("settings expression guide resolves interface language copy")
    func settingsExpressionGuideUsesLocalizedCopy() throws {
        let guideSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1SettingsExpressionGuide.swift"
        )
        let settingsSource = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1SettingsPageSurface.swift"
        )
        let simplifiedChinese = try sourceText(
            "Source/PhotoMemo/PhotoMemo/zh-Hans.lproj/Localizable.strings"
        )
        let english = try sourceText(
            "Source/PhotoMemo/PhotoMemo/en.lproj/Localizable.strings"
        )

        #expect(
            settingsSource.contains(
                "V1SettingsExpressionGuide(language: interfaceLanguage)"
            )
        )
        #expect(!guideSource.contains("Text(\"按时间锚点看看每一种表达方式"))

        for key in [
            "settings.expression.guide.introduction",
            "settings.expression.guide.original_note",
            "settings.expression.guide.header",
            "settings.expression.guide.formula_title",
            "settings.expression.guide.subject",
            "settings.expression.guide.expression",
            "settings.expression.guide.time_result",
            "settings.expression.guide.style_title",
            "settings.expression.guide.phase.before",
            "settings.expression.guide.phase.on_anchor",
            "settings.expression.guide.phase.after"
        ] {
            #expect(guideSource.contains("\"\(key)\""))
            #expect(simplifiedChinese.contains("\"\(key)\""))
            #expect(english.contains("\"\(key)\""))
        }

        for style in MemoryAnchorExpressionStyle.allCases {
            for phase in ["before", "on_anchor", "after"] {
                let key =
                    "settings.expression.formula.\(style.rawValue).\(phase)"
                #expect(simplifiedChinese.contains("\"\(key)\""))
                #expect(english.contains("\"\(key)\""))
            }
        }
    }

    @Test("settings help opens the expression guide in a secondary sheet")
    func settingsHelpOpensGuideInSecondarySheet() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1SettingsPageSurface.swift"
        )

        #expect(source.contains("private var gettingStartedSection"))
        #expect(source.contains("private var gettingStartedActions"))
        #expect(source.contains("showsExpressionGuide"))
        #expect(source.contains("了解记忆表达"))
        #expect(source.contains("Button {"))
        #expect(source.contains(".sheet(isPresented: $showsExpressionGuide)"))
        #expect(source.contains("private var expressionGuideSheet"))
        #expect(source.contains("V1SettingsExpressionGuide(language: interfaceLanguage)"))
        #expect(source.contains(".presentationDetents([.medium, .large])"))
    }

    @Test("settings keeps the concise local-first story after Home dismissal")
    func settingsKeepsConciseLocalFirstStory() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1SettingsPageSurface.swift"
        )

        for key in [
            "settings.overview.title",
            "settings.overview.paragraph_one",
            "settings.overview.paragraph_two",
            "settings.overview.paragraph_three",
            "settings.getting_started.detail",
            "settings.privacy.local_processing.title",
            "settings.feedback.section_title"
        ] {
            #expect(source.contains(key))
        }
        #expect(!source.contains("很多很多照片"))
        #expect(!source.contains("邀请更多人一起参与"))
    }

    @Test("settings welcome help opens the read-only localized explanation")
    func settingsWelcomeHelpUsesReadOnlyWelcomeSurface() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift"
        )
        let presentation = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1WelcomePresentation.swift"
        )

        #expect(source.contains("showsWelcomeInformation"))
        #expect(source.contains("V1WelcomePresentation.localized"))
        #expect(source.contains("V1WelcomePageSurface("))
        #expect(presentation.contains("let language: MemoMarkLanguage"))
        #expect(presentation.contains("welcome.navigation_title"))
        #expect(presentation.contains("welcome.workflow.pipeline"))
    }
}

private extension V1SettingsExpressionGuideContractTests {

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
