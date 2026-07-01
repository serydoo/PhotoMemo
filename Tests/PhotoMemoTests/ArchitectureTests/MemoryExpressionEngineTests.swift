#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("Memory expression engine")
struct MemoryExpressionEngineTests {

    @Test("generates one smart module first and leaves the carrier region to configuration")
    func generatesOneModuleWithIndependentCarrier() throws {
        let subject =
            try #require(
                ConfigurationCenterState.mock.selectedSubject
            )
        let snapshot =
            ConfigurationSnapshotBuilder.build(
                from: subject,
                smartModuleCarrierRegion: .slotB
            )

        let module =
            MemoryExpressionEngine()
            .generateModule(
                context:
                    MemoryExpressionContext(
                        subject: subject,
                        snapshot: snapshot
                    )
            )

        #expect(module.title == "生日记忆")
        #expect(module.preferredRegion == .slotB)
        #expect(module.sourceAnchor?.title == "生日")
        #expect(
            module.renderedText
            == subject.behavior.memoryExpression.displayText
        )
        #expect(module.blocks == subject.behavior.memoryExpression.blocks)
    }

    @Test("uses photo capture time for birthday age smart text")
    func usesCaptureTimeForBirthdayAgeModule() {
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
                    displayName: "王途途",
                    shortName: "途途"
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

        let snapshot =
            ConfigurationSnapshotBuilder.build(
                from: subject,
                smartModuleCarrierRegion: .slotD
            )
        let module =
            MemoryExpressionEngine()
            .generateModule(
                context:
                    MemoryExpressionContext(
                        subject: subject,
                        snapshot: snapshot,
                        captureDate: captureDate
                    )
            )

        #expect(module.renderedText == "途途今天18天啦！")
        #expect(module.sourceAnchor?.anchorType == .birthday)
    }

    @Test("falls back to display name when selected expression subject text is empty")
    func fallsBackToDisplayNameWhenExpressionSubjectIsEmpty() {
        let birthday =
            Calendar.current.date(
                from: DateComponents(
                    year: 2024,
                    month: 1,
                    day: 1
                )
            ) ?? Date()
        let captureDate =
            Calendar.current.date(
                from: DateComponents(
                    year: 2025,
                    month: 3,
                    day: 9
                )
            ) ?? Date()
        let subject =
            MemorySubject(
                identity: .init(
                    displayName: "安安",
                    shortName: ""
                ),
                relationship: .init(
                    role: "孩子",
                    label: ""
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

        let snapshot =
            ConfigurationSnapshotBuilder.build(
                from: subject
            )
        let module =
            MemoryExpressionEngine()
            .generateModule(
                context:
                    MemoryExpressionContext(
                        subject: subject,
                        snapshot: snapshot,
                        captureDate: captureDate
                    )
            )

        #expect(module.renderedText == "安安今天1年2个月8天啦！")
    }

    @Test("preview resolver uses selected expression subject source in generated text")
    func previewResolverUsesSelectedExpressionSubjectSourceInGeneratedText() {
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
                    displayName: "王途途",
                    shortName: "途途"
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

        let previewText =
            MemoryExpressionPreviewResolver
            .previewText(
                subject: subject,
                captureDate: captureDate
            )

        #expect(
            previewText == "妈妈眼里的宝宝今天18天啦！"
        )
    }
}
#endif
