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
            generatedModule(
                subject: subject,
                snapshot: snapshot
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
                        anchorType: .birthday,
                        expressionStyle:
                            .birthdayAgeToday
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
            generatedModule(
                subject: subject,
                snapshot: snapshot,
                captureDate: captureDate
            )

        #expect(module.renderedText == "途途今天18天啦！")
        #expect(module.sourceAnchor?.anchorType == .birthday)
        #expect(
            module.sourceAnchor?.expressionStyle
            == .birthdayAgeToday
        )
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
            generatedModule(
                subject: subject,
                snapshot: snapshot,
                captureDate: captureDate
            )

        #expect(module.renderedText == "安安今天1年2个月8天啦！")
    }

    @Test("uses countdown branch when birthday capture time is before the anchor date")
    func usesCountdownBranchBeforeBirthday() {
        let birthday =
            Calendar.current.date(
                from: DateComponents(
                    year: 2025,
                    month: 6,
                    day: 13
                )
            ) ?? Date()
        let captureDate =
            Calendar.current.date(
                from: DateComponents(
                    year: 2025,
                    month: 5,
                    day: 26
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
                        anchorType: .birthday,
                        expressionStyle:
                            .birthdayAgeToday
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
                        blocks: [.text("出生前预览")]
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
            generatedModule(
                subject: subject,
                snapshot: snapshot,
                captureDate: captureDate
            )

        #expect(module.renderedText == "距离途途出生还有18天")
        #expect(module.sourceAnchor?.anchorType == .birthday)
        #expect(
            module.sourceAnchor?.expressionStyle
            == .birthdayAgeToday
        )
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

    @Test("anchor expression library exposes five styles per anchor type with the documented defaults")
    func anchorExpressionLibraryExposesFiveStylesPerAnchorTypeWithDocumentedDefaults() {
        #expect(
            MemoryAnchorExpressionStyle
                .availableStyles(for: .birthday)
            == [
                .birthdayNatural,
                .birthdayCeremonial,
                .birthdayGrowth,
                .birthdayWarm,
                .birthdayMinimal
            ]
        )
        #expect(
            MemoryAnchorExpressionStyle
                .defaultStyle(for: .birthday)
            == .birthdayNatural
        )
        #expect(
            MemoryAnchorExpressionStyle
                .availableStyles(for: .marriage)
            == [
                .marriageNatural,
                .marriageCeremonial,
                .marriageWarm,
                .marriageMinimal,
                .marriageMemory
            ]
        )
        #expect(
            MemoryAnchorExpressionStyle
                .defaultStyle(for: .custom)
            == .customNatural
        )
    }

    @Test("rendered text uses before and after formulas for the documented anchor styles")
    func renderedTextUsesBeforeAndAfterFormulasForDocumentedAnchorStyles() {
        let beforeBirthday =
            MemoryAnchorRelativeSnapshot(
                years: 0,
                months: 0,
                days: 0,
                totalDays: 18,
                isFutureRelative: true
            )
        let afterMarriage =
            MemoryAnchorRelativeSnapshot(
                years: 1,
                months: 2,
                days: 3,
                totalDays: 428,
                isFutureRelative: false
            )
        let beforeRelationship =
            MemoryAnchorRelativeSnapshot(
                years: 0,
                months: 0,
                days: 0,
                totalDays: 86,
                isFutureRelative: true
            )
        let afterExam =
            MemoryAnchorRelativeSnapshot(
                years: 0,
                months: 3,
                days: 12,
                totalDays: 104,
                isFutureRelative: false
            )
        let afterCustom =
            MemoryAnchorRelativeSnapshot(
                years: 2,
                months: 1,
                days: 6,
                totalDays: 767,
                isFutureRelative: false
            )

        #expect(
            MemoryAnchorExpressionResolver
                .renderedText(
                    subjectText: "途途",
                    anchorTitle: "生日",
                    anchorType: .birthday,
                    expressionStyle: .birthdayNatural,
                    relativeSnapshot: beforeBirthday
                )
            == "距离途途出生还有18天"
        )
        #expect(
            MemoryAnchorExpressionResolver
                .renderedText(
                    subjectText: "我们",
                    anchorTitle: "结婚纪念日",
                    anchorType: .marriage,
                    expressionStyle: .marriageNatural,
                    relativeSnapshot: afterMarriage
                )
            == "我们婚后1年2个月3天"
        )
        #expect(
            MemoryAnchorExpressionResolver
                .renderedText(
                    subjectText: "我和Lucky",
                    anchorTitle: "第一次见面",
                    anchorType: .relationship,
                    expressionStyle: .relationshipWarm,
                    relativeSnapshot: beforeRelationship
                )
            == "期待第一次见面，还有86天"
        )
        #expect(
            MemoryAnchorExpressionResolver
                .renderedText(
                    subjectText: "考生",
                    anchorTitle: "高考",
                    anchorType: .exam,
                    expressionStyle: .examRecord,
                    relativeSnapshot: afterExam
                )
            == "自高考以来已有3个月12天"
        )
        #expect(
            MemoryAnchorExpressionResolver
                .renderedText(
                    subjectText: "我们",
                    anchorTitle: "毕业旅行",
                    anchorType: .custom,
                    expressionStyle: .customNatural,
                    relativeSnapshot: afterCustom
                )
            == "自毕业旅行起已有2年1个月6天"
        )
    }
}

private extension MemoryExpressionEngineTests {

    func generatedModule(
        subject: MemorySubject,
        snapshot: ConfigurationSnapshot,
        captureDate: Date? = nil
    ) -> MemoryModule {
        let context =
            MemoryExpressionContext(
                subject: subject,
                snapshot: snapshot,
                captureDate: captureDate
            )
        let result =
            MemoryExpressionEngine()
            .generateResult(
                context: context
            )

        return MemoryResultPresentationAdapter()
            .makeModule(
                result: result,
                context: context
            )
    }
}
#endif
