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

        #expect(module.renderedText == "今天途途18天")
        #expect(module.sourceAnchor?.anchorType == .birthday)
        #expect(
            module.sourceAnchor?.expressionStyle
            == .birthdayAgeToday
        )
    }

    @Test("uses capture calendar when resolving birthday age across timezones")
    func usesCaptureCalendarWhenResolvingBirthdayAgeAcrossTimezones() throws {
        let originalDefaultTimeZone =
            NSTimeZone.default
        NSTimeZone.default =
            try #require(
                TimeZone(secondsFromGMT: -8 * 60 * 60)
            )
        defer {
            NSTimeZone.default =
                originalDefaultTimeZone
        }

        var captureCalendar =
            Calendar(identifier: .gregorian)
        captureCalendar.timeZone =
            try #require(
                TimeZone(secondsFromGMT: 8 * 60 * 60)
            )
        let birthday =
            try #require(
                captureCalendar.date(
                    from:
                        DateComponents(
                            year: 2026,
                            month: 1,
                            day: 31
                        )
                )
            )
        let captureDate =
            try #require(
                captureCalendar.date(
                    from:
                        DateComponents(
                            year: 2026,
                            month: 3,
                            day: 1
                        )
                )
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
        let context =
            MemoryExpressionContext(
                subject: subject,
                snapshot: snapshot,
                captureDate: captureDate,
                captureCalendar: captureCalendar
            )
        let result =
            MemoryExpressionEngine()
            .generateResult(
                context: context
            )
        let elapsed =
            try #require(
                result.primaryAnchorResult?
                    .elapsed
            )

        #expect(elapsed.months == 1)
        #expect(elapsed.days == 1)
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

        #expect(module.renderedText == "今天安安1岁2个月8天")
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

        #expect(module.renderedText == "还有18天，途途就要出生了")
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
            previewText == "今天妈妈眼里的宝宝18天"
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
            == "还有18天，途途就要出生了"
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
            == "结婚已经1年2个月3天"
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
            == "自高考以来，已有3个月12天"
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
            == "自毕业旅行起，已有2年1个月6天"
        )
    }

    @Test("birthday age wording uses 岁 after full years")
    func birthdayAgeWordingUsesSuiAfterFullYears() {
        let afterBirthday =
            MemoryAnchorRelativeSnapshot(
                years: 3,
                months: 2,
                days: 1,
                totalDays: 1157,
                isFutureRelative: false
            )

        #expect(afterBirthday.ageText == "3岁2个月1天")
        #expect(
            MemoryAnchorExpressionResolver
                .renderedText(
                    subjectText: "途途",
                    anchorTitle: "生日",
                    anchorType: .birthday,
                    expressionStyle: .birthdayWarm,
                    relativeSnapshot: afterBirthday
                )
            == "陪途途走到3岁2个月1天"
        )
    }

    @Test("marriage countdown wording says 结婚 instead of 婚礼")
    func marriageCountdownWordingSaysMarriageInsteadOfWedding() {
        let beforeMarriage =
            MemoryAnchorRelativeSnapshot(
                years: 0,
                months: 0,
                days: 0,
                totalDays: 18,
                isFutureRelative: true
            )

        #expect(
            MemoryAnchorExpressionResolver
                .renderedText(
                    subjectText: "我们",
                    anchorTitle: "结婚",
                    anchorType: .marriage,
                    expressionStyle: .marriageMinimal,
                    relativeSnapshot: beforeMarriage
                )
            == "结婚倒计时：18天"
        )
    }

    @Test("annual birthday countdown names the next birthday age")
    func annualBirthdayCountdownNamesTheNextBirthdayAge() throws {
        let calendar =
            Calendar(identifier: .gregorian)
        let birthday =
            try #require(
                calendar.date(
                    from: DateComponents(
                        year: 2022,
                        month: 8,
                        day: 10
                    )
                )
            )
        let captureDate =
            try #require(
                calendar.date(
                    from: DateComponents(
                        year: 2026,
                        month: 7,
                        day: 6
                    )
                )
            )
        let relativeSnapshot =
            MemoryAnchorRelativeSnapshot
            .resolve(
                anchorDate: birthday,
                captureDate: captureDate,
                calendar: calendar
            )
        let occurrence =
            try #require(
                MemoryAnchorAnnualOccurrence
                    .resolve(
                        anchorDate: birthday,
                        captureDate: captureDate,
                        calendar: calendar
                    )
            )

        #expect(occurrence.daysUntilOccurrence == 35)
        #expect(occurrence.yearsAtOccurrence == 4)
        #expect(
            MemoryAnchorExpressionResolver
                .renderedText(
                    subjectText: "途途",
                    anchorTitle: "生日",
                    anchorType: .birthday,
                    expressionStyle: .birthdayNatural,
                    relativeSnapshot:
                        relativeSnapshot,
                    annualOccurrence:
                        occurrence,
                    prefersAnnualOccurrence:
                        true
                )
            == "还有35天，就是途途4岁生日"
        )
    }

    @Test("annual marriage countdown names the next anniversary")
    func annualMarriageCountdownNamesTheNextAnniversary() throws {
        let calendar =
            Calendar(identifier: .gregorian)
        let marriageDate =
            try #require(
                calendar.date(
                    from: DateComponents(
                        year: 2020,
                        month: 10,
                        day: 1
                    )
                )
            )
        let captureDate =
            try #require(
                calendar.date(
                    from: DateComponents(
                        year: 2026,
                        month: 7,
                        day: 6
                    )
                )
            )
        let relativeSnapshot =
            MemoryAnchorRelativeSnapshot
            .resolve(
                anchorDate: marriageDate,
                captureDate: captureDate,
                calendar: calendar
            )
        let occurrence =
            try #require(
                MemoryAnchorAnnualOccurrence
                    .resolve(
                        anchorDate: marriageDate,
                        captureDate: captureDate,
                        calendar: calendar
                    )
            )

        #expect(occurrence.daysUntilOccurrence == 87)
        #expect(occurrence.yearsAtOccurrence == 6)
        #expect(
            MemoryAnchorExpressionResolver
                .renderedText(
                    subjectText: "我们",
                    anchorTitle: "结婚",
                    anchorType: .marriage,
                    expressionStyle: .marriageMinimal,
                    relativeSnapshot:
                        relativeSnapshot,
                    annualOccurrence:
                        occurrence,
                    prefersAnnualOccurrence:
                        true
                )
            == "结婚6周年倒计时：87天"
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
