#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing
@testable import MemoMark

@Suite("Configuration center memory display support")
struct ConfigurationCenterMemoryDisplaySupportTests {

    @Test("summary uses the active anchor expression style and resolved preview")
    func summaryUsesActiveAnchorExpressionStyle() {
        let subject = MemorySubject(
            identity: .init(
                displayName: "示例昵称",
                shortName: "示例昵称"
            ),
            relationship: .init(
                role: "家庭",
                label: "宝宝"
            ),
            definition: "",
            referenceDate: Date(timeIntervalSince1970: 0),
            timeAnchors: [
                .init(
                    id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
                    title: "出生",
                    date: Date(timeIntervalSince1970: 0),
                    note: "宝宝出生日期",
                    anchorType: .birthday,
                    expressionStyle: .birthdayWarm
                )
            ],
            activeTimeAnchorID: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            behavior: .init(
                primaryAnchor: "出生",
                iconStrategy: .autoMatch,
                badgeStrategy: .fixed,
                memoryExpression: .init(
                    title: "默认表达",
                    blocks: []
                )
            ),
            decorations: []
        )

        #expect(
            ConfigurationCenterMemoryDisplaySupport
                .summaryValue(subject: subject)
            == "温馨"
        )
        let detail = ConfigurationCenterMemoryDisplaySupport
            .summaryDetail(subject: subject)
        #expect(!detail.contains("年龄结果"))
        #expect(!detail.contains("倒计时天数"))
        #expect(detail.contains("示例昵称"))
        #expect(
            ConfigurationCenterMemoryDisplaySupport
                .availableStyles(subject: subject)
            == MemoryAnchorExpressionStyle.availableStyles(for: .birthday)
        )
    }

    @Test("summary detail uses a resolved memory result instead of formula placeholders")
    func summaryDetailUsesResolvedMemoryResultInsteadOfFormulaPlaceholders() {
        let subject = MemorySubject(
            identity: .init(
                displayName: "示例昵称",
                shortName: "示例昵称"
            ),
            relationship: .init(
                role: "家庭",
                label: "宝宝"
            ),
            definition: "",
            referenceDate: Date(timeIntervalSince1970: 0),
            timeAnchors: [
                .init(
                    id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
                    title: "出生",
                    date: Date(timeIntervalSince1970: 0),
                    note: "宝宝出生日期",
                    anchorType: .birthday,
                    expressionStyle: .birthdayNatural
                )
            ],
            activeTimeAnchorID: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            behavior: .init(
                primaryAnchor: "出生",
                iconStrategy: .autoMatch,
                badgeStrategy: .fixed,
                memoryExpression: .init(
                    title: "默认表达",
                    blocks: []
                )
            ),
            decorations: []
        )

        let detail = ConfigurationCenterMemoryDisplaySupport
            .summaryDetail(subject: subject)

        #expect(!detail.contains("年龄结果"))
        #expect(!detail.contains("倒计时天数"))
        #expect(detail.contains("示例昵称"))
    }

    @Test("summary falls back cleanly when there is no active subject anchor")
    func summaryFallsBackWithoutActiveAnchor() {
        #expect(
            ConfigurationCenterMemoryDisplaySupport
                .summaryValue(subject: nil)
            == "未设置"
        )
        #expect(
            ConfigurationCenterMemoryDisplaySupport
                .summaryDetail(subject: nil)
            == "先选择记忆对象和当前生效时间锚点，再决定这张卡片要用哪一种表达方式。"
        )
        #expect(
            ConfigurationCenterMemoryDisplaySupport
                .availableStyles(subject: nil)
                .isEmpty
        )
    }
}
#endif
