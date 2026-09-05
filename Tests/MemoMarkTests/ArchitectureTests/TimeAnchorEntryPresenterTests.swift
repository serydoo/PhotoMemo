#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing
@testable import MemoMark

@Suite("V1 time anchor entry presenter")
struct TimeAnchorEntryPresenterTests {

    @Test("uses configured expression subject and active anchor title in compact summary")
    func usesConfiguredExpressionSubjectAndActiveAnchorTitleInCompactSummary() {
        let subject =
            MemorySubject(
                identity: .init(
                    displayName: "示例对象",
                    shortName: "小宝"
                ),
                relationship: .init(
                    role: "宝宝",
                    label: "妈妈眼里的宝宝"
                ),
                definition: "测试对象",
                referenceDate: Date(),
                timeAnchors: [],
                activeTimeAnchorID: nil,
                expressionSubjectSource: .relationshipLabel,
                behavior: MemoryBehavior(
                    primaryAnchor: "生日",
                    iconStrategy: .autoMatch,
                    badgeStrategy: .autoMatch,
                    memoryExpression: MemoryExpression(
                        title: "生日记忆",
                        blocks: []
                    )
                ),
                decorations: []
            )

        let presentation =
            TimeAnchorEntryPresenter
            .presentation(
                subject: subject,
                anchorTitle: "生日"
            )

        #expect(
            presentation.rowSubtitle
            == "主体与当前生效时间锚点"
        )
        #expect(
            presentation.rowValue
            == "妈妈眼里的宝宝 · 生日"
        )
        #expect(
            presentation.anchorPickerTitle
            == "生日"
        )
        #expect(
            presentation.formulaTitle
            == "按照片时间生成的真实预览"
        )
        #expect(!presentation.formulaPreviewText.contains("年龄结果"))
        #expect(!presentation.formulaPreviewText.contains("倒计时天数"))
        #expect(presentation.formulaPreviewText.contains("妈妈眼里的宝宝"))
    }

    @Test("falls back to generic labels when subject or anchor title is empty")
    func fallsBackToGenericLabelsWhenSubjectOrAnchorTitleIsEmpty() {
        let subject =
            MemorySubject(
                identity: .init(
                    displayName: "   ",
                    shortName: "   "
                ),
                relationship: .init(
                    role: "   ",
                    label: "   "
                ),
                definition: "测试对象",
                referenceDate: Date(),
                timeAnchors: [],
                activeTimeAnchorID: nil,
                expressionSubjectSource: .displayName,
                behavior: MemoryBehavior(
                    primaryAnchor: "生日",
                    iconStrategy: .autoMatch,
                    badgeStrategy: .autoMatch,
                    memoryExpression: MemoryExpression(
                        title: "生日记忆",
                        blocks: []
                    )
                ),
                decorations: []
            )

        let presentation =
            TimeAnchorEntryPresenter
            .presentation(
                subject: subject,
                anchorTitle: "   "
            )

        #expect(
            presentation.rowValue
            == "记忆对象 · 时间锚点"
        )
        #expect(
            presentation.anchorPickerTitle
            == "时间锚点"
        )
        #expect(!presentation.formulaPreviewText.contains("年龄结果"))
        #expect(!presentation.formulaPreviewText.contains("倒计时天数"))
    }

    @Test("uses selected relationship formula preview when anchor style changes")
    func usesSelectedRelationshipFormulaPreviewWhenAnchorStyleChanges() {
        let anchor =
            MemorySubject.TimeAnchor(
                title: "第一次见面",
                date: Date(),
                note: "关系起点",
                anchorType: .relationship,
                expressionStyle: .relationshipWarm
            )
        let subject =
            MemorySubject(
                identity: .init(
                    displayName: "示例对象",
                    shortName: "小宝"
                ),
                relationship: .init(
                    role: "宝宝",
                    label: "妈妈眼里的宝宝"
                ),
                definition: "测试对象",
                referenceDate: Date(),
                timeAnchors: [anchor],
                activeTimeAnchorID: anchor.id,
                expressionSubjectSource: .shortName,
                behavior: MemoryBehavior(
                    primaryAnchor: "第一次见面",
                    iconStrategy: .autoMatch,
                    badgeStrategy: .autoMatch,
                    memoryExpression: MemoryExpression(
                        title: "关系记忆",
                        blocks: []
                    )
                ),
                decorations: []
            )

        let presentation =
            TimeAnchorEntryPresenter
            .presentation(
                subject: subject,
                anchorTitle: "第一次见面"
            )

        #expect(!presentation.formulaPreviewText.contains("倒计时结果"))
        #expect(!presentation.formulaPreviewText.contains("时长结果"))
        #expect(presentation.formulaPreviewText.contains("第一次见面"))
        #expect(
            presentation.anchorPickerTitle
            == "第一次见面"
        )
    }
}
#endif
