#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("V1 resolved memory write text presenter")
struct V1ResolvedMemoryWriteTextPresenterTests {

    @Test("returns trimmed custom text when standalone write text is enabled")
    func returnsTrimmedCustomTextWhenEnabled() {
        let resolvedText =
            V1ResolvedMemoryWriteTextPresenter
            .resolvedText(
                subject: nil,
                usesCustomText: true,
                customText: "  单独写入说明  "
            )

        #expect(
            resolvedText == "单独写入说明"
        )
    }

    @Test("falls back to memory expression preview text when custom text is empty")
    func fallsBackToMemoryExpressionPreviewTextWhenCustomTextIsEmpty() {
        let birthday =
            Calendar.current.date(
                from: DateComponents(
                    year: 2025,
                    month: 5,
                    day: 26
                )
            ) ?? Date()
        let captureDate =
            Calendar.current.date(
                from: DateComponents(
                    year: 2025,
                    month: 6,
                    day: 13
                )
            ) ?? Date()
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
                referenceDate: birthday,
                timeAnchors: [
                    .init(
                        title: "生日",
                        date: birthday,
                        note: "出生日期",
                        anchorType: .birthday
                    )
                ],
                activeTimeAnchorID: nil,
                expressionSubjectSource: .shortName,
                behavior: MemoryBehavior(
                    primaryAnchor: "生日",
                    iconStrategy: .autoMatch,
                    badgeStrategy: .autoMatch,
                    memoryExpression: MemoryExpression(
                        title: "生日记忆",
                        blocks: [.text("生日智能模块")]
                    )
                ),
                decorations: []
            )

        let resolvedText =
            V1ResolvedMemoryWriteTextPresenter
            .resolvedText(
                subject: subject,
                usesCustomText: true,
                customText: "   ",
                captureDate: captureDate
            )

        #expect(
            resolvedText == "今天小宝18天"
        )
    }

    @Test("returns placeholder when no memory expression can be resolved")
    func returnsPlaceholderWhenNoMemoryExpressionCanBeResolved() {
        let resolvedText =
            V1ResolvedMemoryWriteTextPresenter
            .resolvedText(
                subject: nil,
                usesCustomText: false,
                customText: ""
            )

        #expect(
            resolvedText == "当前智能模块暂无内容"
        )
    }

    @Test("legacy birthday anchor title follows selected expression subject source")
    func legacyBirthdayAnchorTitleFollowsSelectedExpressionSubjectSource() {
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
                        blocks: [.text("生日智能模块")]
                    )
                ),
                decorations: []
            )

        let resolvedTitle =
            V1ResolvedMemoryWriteTextPresenter
            .legacyBirthdayAnchorTitle(
                subject: subject
            )

        #expect(
            resolvedTitle == "妈妈眼里的宝宝"
        )
    }
}
#endif
