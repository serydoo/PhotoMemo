#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("V1 time anchor entry presenter")
struct V1TimeAnchorEntryPresenterTests {

    @Test("uses configured expression subject and active anchor title in compact summary")
    func usesConfiguredExpressionSubjectAndActiveAnchorTitleInCompactSummary() {
        let subject =
            MemorySubject(
                identity: .init(
                    displayName: "王途途",
                    shortName: "途途"
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
            V1TimeAnchorEntryPresenter
            .presentation(
                subject: subject,
                anchorTitle: "生日"
            )

        #expect(
            presentation.rowSubtitle
            == "主体与当前生效锚点"
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
            == "本锚点对应输出公式如下"
        )
        #expect(
            presentation.formulaPreviewText
            == "锚点前：距离妈妈眼里的宝宝出生还有倒计时天数｜锚点后：妈妈眼里的宝宝今天年龄结果啦！"
        )
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
            V1TimeAnchorEntryPresenter
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
        #expect(
            presentation.formulaPreviewText
            == "锚点前：距离记忆对象出生还有倒计时天数｜锚点后：记忆对象今天年龄结果啦！"
        )
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
                    displayName: "王途途",
                    shortName: "途途"
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
            V1TimeAnchorEntryPresenter
            .presentation(
                subject: subject,
                anchorTitle: "第一次见面"
            )

        #expect(
            presentation.formulaPreviewText
            == "锚点前：期待第一次见面，还有倒计时结果｜锚点后：关于第一次见面的故事已有时长结果"
        )
        #expect(
            presentation.anchorPickerTitle
            == "第一次见面"
        )
    }
}
#endif
