import Foundation
import Testing

@Suite("V1 settings expression guide")
struct V1SettingsExpressionGuideContractTests {

    @Test("settings help exposes a beginner expression formula guide")
    func settingsHelpExposesExpressionFormulaGuide() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1SettingsExpressionGuide.swift"
        )

        #expect(source.contains("表达公式说明"))
        #expect(source.contains("formulaToken(\"主体\""))
        #expect(source.contains("formulaToken(\"智能输出\""))
        #expect(source.contains("formulaToken(\"锚点结果\""))
        #expect(source.contains("AnchorType.allCases"))
        #expect(source.contains("availableStyles"))
        #expect(source.contains("style.displayTitle"))
        #expect(source.contains("role: .subject"))
        #expect(source.contains("role: .smartOutput"))
        #expect(source.contains("role: .anchorResult"))
        #expect(source.contains("formula.before"))
        #expect(source.contains("formula.onAnchor"))
        #expect(source.contains("formula.after"))
    }

    @Test("settings help opens the expression guide in a secondary sheet")
    func settingsHelpOpensGuideInSecondarySheet() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1SettingsPageSurface.swift"
        )

        #expect(source.contains("private var guideSection"))
        #expect(source.contains("showsExpressionGuide"))
        #expect(source.contains("查看表达公式说明"))
        #expect(source.contains("Button {"))
        #expect(source.contains(".sheet(isPresented: $showsExpressionGuide)"))
        #expect(source.contains("private var expressionGuideSheet"))
        #expect(source.contains("V1SettingsExpressionGuide()"))
        #expect(source.contains(".presentationDetents([.medium, .large])"))
    }

    @Test("settings keeps the complete product story after Home dismissal")
    func settingsKeepsCompleteProductStory() throws {
        let source = try sourceText(
            "Source/PhotoMemo/PhotoMemo/iOS/Views/V1SettingsPageSurface.swift"
        )

        #expect(source.contains("为什么是时光记"))
        #expect(source.contains("很多很多照片"))
        #expect(source.contains("那一天，孩子多大"))
        #expect(source.contains("儿子出生"))
        #expect(source.contains("纪念日和未来的重要日期"))
        #expect(source.contains("时间锚点"))
        #expect(source.contains("本地完成"))
        #expect(source.contains("反馈和建议"))
        #expect(source.contains("小红书等公开渠道"))
        #expect(source.contains("邀请更多人一起参与"))
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
