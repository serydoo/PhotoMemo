import Foundation
import Testing
@testable import PhotoMemo

@Suite("MemoryEngineTests")
struct MemoryEngineTests {

    @Test("Formats baby age without zero-year wording and exposes numeric since values")
    func formatsBabyAgeAndSinceValues() throws {

        let anchor = Anchor(
            type: .birthday,
            title: "宝宝",
            date: try date(
                year: 2026,
                month: 1,
                day: 1,
                hour: 9,
                minute: 0,
                timeZoneOffsetSeconds: 8 * 3600
            )
        )

        let metadata = PhotoMetadata(
            captureDate: try date(
                year: 2026,
                month: 9,
                day: 1,
                hour: 9,
                minute: 0,
                timeZoneOffsetSeconds: 8 * 3600
            ),
            captureTimezoneOffsetSeconds: 8 * 3600
        )

        let result = MemoryVariableProvider().build(
            from: MemoryContext(
                metadata: metadata,
                anchor: anchor
            )
        )

        #expect(result.daysSince == "243")
        #expect(result.yearsSince == "0")
        #expect(result.monthsSince == "8")
        #expect(result.weeksSince == "34")
        #expect(result.babyAge == "8个月")
        #expect(result.memorySummary == "这一天，宝宝8个月")
    }

    @Test("Handles leap-year birthdays deterministically")
    func handlesLeapYearBirthdays() throws {

        let anchor = Anchor(
            type: .birthday,
            title: "Leap Baby",
            date: try date(
                year: 2024,
                month: 2,
                day: 29,
                hour: 8,
                minute: 0,
                timeZoneOffsetSeconds: 0
            )
        )

        let metadata = PhotoMetadata(
            captureDate: try date(
                year: 2025,
                month: 3,
                day: 1,
                hour: 8,
                minute: 0,
                timeZoneOffsetSeconds: 0
            ),
            captureTimezoneOffsetSeconds: 0
        )

        let result = MemoryVariableProvider().build(
            from: MemoryContext(
                metadata: metadata,
                anchor: anchor
            )
        )

        #expect(result.daysSince == "366")
        #expect(result.yearsSince == "1")
        #expect(result.monthsSince == "12")
        #expect(result.weeksSince == "52")
        #expect(result.babyAge == "1岁1天")
    }

    @Test("Clamps future anchors and preserves explicit story text")
    func clampsFutureAnchorsAndPreservesStory() throws {

        let anchor = Anchor(
            type: .birthday,
            title: "宝宝",
            date: try date(
                year: 2026,
                month: 7,
                day: 1,
                hour: 12,
                minute: 0,
                timeZoneOffsetSeconds: 8 * 3600
            )
        )

        let metadata = PhotoMetadata(
            captureDate: try date(
                year: 2026,
                month: 6,
                day: 20,
                hour: 12,
                minute: 0,
                timeZoneOffsetSeconds: 8 * 3600
            ),
            captureTimezoneOffsetSeconds: 8 * 3600
        )

        let result = MemoryVariableProvider().build(
            from: MemoryContext(
                metadata: metadata,
                anchor: anchor,
                story: "夏天之前"
            )
        )

        #expect(result.daysSince == "0")
        #expect(result.yearsSince == "0")
        #expect(result.monthsSince == "0")
        #expect(result.weeksSince == "0")
        #expect(result.babyAge.isEmpty)
        #expect(result.memorySummary == "夏天之前")
    }

    @Test("Publishes memory values into card context and keeps existing anchor summary behavior")
    func publishesMemoryValuesIntoCardContext() throws {

        let anchor = Anchor(
            type: .birthday,
            title: "宝宝",
            date: try date(
                year: 2026,
                month: 6,
                day: 1,
                hour: 23,
                minute: 30,
                timeZoneOffsetSeconds: 8 * 3600
            )
        )

        let metadata = PhotoMetadata(
            captureDate: try date(
                year: 2026,
                month: 6,
                day: 2,
                hour: 0,
                minute: 15,
                timeZoneOffsetSeconds: 8 * 3600
            ),
            captureTimezoneOffsetSeconds: 8 * 3600
        )

        let anchorResult = AnchorEngine().build(
            from: anchor,
            photoDate: try #require(metadata.captureDate)
        )

        let card = RecordCard(
            metadata: metadata,
            context: MetadataContext.build(from: metadata),
            anchor: anchor,
            anchorResult: anchorResult
        )

        let context = CardVariableProvider.build(
            from: card
        )

        #expect(context[MetadataContext.Key.daysSince] == "0")
        #expect(context[MetadataContext.Key.weeksSince] == "0")
        #expect(context[MetadataContext.Key.babyAge] == "0天")
        #expect(context[MetadataContext.Key.memorySummary] == "这一天，宝宝0天")
    }

    @Test("Projects explicit memory module into variable and template flow when legacy memory inputs are absent")
    func projectsExplicitMemoryModuleIntoVariableAndTemplateFlow() throws {

        let metadata = PhotoMetadata(
            captureDate: try date(
                year: 2026,
                month: 7,
                day: 2,
                hour: 8,
                minute: 30,
                timeZoneOffsetSeconds: 8 * 3600
            ),
            captureTimezoneOffsetSeconds: 8 * 3600
        )
        var card = RecordCard(
            template: memorySummaryTemplate(),
            metadata: metadata,
            context: MetadataContext.build(from: metadata)
        )
        card.memoryModule =
            MemoryModule(
                title: "Memory",
                blocks: [
                    .text("乐乐")
                ],
                renderedText: "乐乐",
                sourceAnchor: nil,
                preferredRegion: .slotD
            )

        let context = CardVariableProvider.build(
            from: card
        )
        let blocks =
            CardTextBlockEngine()
            .build(from: card)

        #expect(context[MetadataContext.Key.memorySummary] == "乐乐")
        #expect(
            blocks.first(where: { $0.area == .rightBottom })?.value
            == "乐乐"
        )
    }

    @Test("Projects resolved MemoryResult elapsed values into variable flow")
    func projectsResolvedMemoryResultElapsedValuesIntoVariableFlow() throws {

        let metadata = PhotoMetadata(
            captureDate: try date(
                year: 2026,
                month: 7,
                day: 2,
                hour: 8,
                minute: 30,
                timeZoneOffsetSeconds: 8 * 3600
            ),
            captureTimezoneOffsetSeconds: 8 * 3600
        )
        let resultID =
            UUID()
        var card = RecordCard(
            template: memorySummaryTemplate(),
            metadata: metadata,
            context: MetadataContext.build(from: metadata)
        )
        card.memoryResult =
            MemoryResult(
                subjectID: UUID(),
                captureDate: metadata.captureDate,
                primaryAnchorResultID: resultID,
                anchorResults: [
                    MemoryAnchorResult(
                        id: resultID,
                        anchorID: UUID(),
                        anchorType: .birthday,
                        anchorTitle: "生日",
                        anchorDate:
                            try date(
                                year: 2026,
                                month: 6,
                                day: 1,
                                hour: 8,
                                minute: 30,
                                timeZoneOffsetSeconds:
                                    8 * 3600
                            ),
                        direction: .afterAnchor,
                        elapsed:
                            MemoryElapsedTime(
                                years: 0,
                                months: 1,
                                days: 1,
                                totalDays: 31,
                                weeks: 4,
                                totalMonths: 1,
                                isFutureRelative: false
                            ),
                        precision: .day,
                        status: .resolved,
                        source:
                            .frozenConfiguration
                    )
                ]
            )
        card.memoryModule =
            MemoryModule(
                title: "Memory",
                blocks: [
                    .text("乐乐")
                ],
                renderedText: "乐乐",
                sourceAnchor: nil,
                preferredRegion: .slotD
            )

        let context = CardVariableProvider.build(
            from: card
        )

        #expect(context[MetadataContext.Key.daysSince] == "31")
        #expect(context[MetadataContext.Key.monthsSince] == "1")
        #expect(context[MetadataContext.Key.weeksSince] == "4")
        #expect(context[MetadataContext.Key.babyAge] == "1个月1天")
        #expect(context[MetadataContext.Key.memorySummary] == "乐乐")
    }

    @Test("Projects future-relative MemoryResult elapsed values as clamped variables")
    func projectsFutureRelativeMemoryResultElapsedValuesAsClampedVariables() throws {

        let metadata = PhotoMetadata(
            captureDate: try date(
                year: 2026,
                month: 7,
                day: 2,
                hour: 8,
                minute: 30,
                timeZoneOffsetSeconds: 8 * 3600
            ),
            captureTimezoneOffsetSeconds: 8 * 3600
        )
        let resultID =
            UUID()
        var card = RecordCard(
            template: memorySummaryTemplate(),
            metadata: metadata,
            context: MetadataContext.build(from: metadata)
        )
        card.memoryResult =
            MemoryResult(
                subjectID: UUID(),
                captureDate: metadata.captureDate,
                primaryAnchorResultID: resultID,
                anchorResults: [
                    MemoryAnchorResult(
                        id: resultID,
                        anchorID: UUID(),
                        anchorType: .birthday,
                        anchorTitle: "生日",
                        anchorDate:
                            try date(
                                year: 2026,
                                month: 9,
                                day: 26,
                                hour: 8,
                                minute: 30,
                                timeZoneOffsetSeconds:
                                    8 * 3600
                            ),
                        direction: .beforeAnchor,
                        elapsed:
                            MemoryElapsedTime(
                                years: 0,
                                months: 2,
                                days: 24,
                                totalDays: 86,
                                weeks: 12,
                                totalMonths: 2,
                                isFutureRelative: true
                            ),
                        precision: .day,
                        status: .resolved,
                        source:
                            .frozenConfiguration
                    )
                ]
            )
        card.memoryModule =
            MemoryModule(
                title: "Memory",
                blocks: [
                    .text("乐乐")
                ],
                renderedText: "乐乐",
                sourceAnchor: nil,
                preferredRegion: .slotD
            )

        let context = CardVariableProvider.build(
            from: card
        )

        #expect(context[MetadataContext.Key.daysSince] == "0")
        #expect(context[MetadataContext.Key.yearsSince] == "0")
        #expect(context[MetadataContext.Key.monthsSince] == "0")
        #expect(context[MetadataContext.Key.weeksSince] == "0")
        #expect(context[MetadataContext.Key.babyAge].isEmpty)
        #expect(context[MetadataContext.Key.memorySummary] == "乐乐")
    }

    @Test("Does not project unresolved MemoryResult elapsed values into variable flow")
    func doesNotProjectUnresolvedMemoryResultElapsedValuesIntoVariableFlow() throws {

        let metadata = PhotoMetadata(
            captureDate: try date(
                year: 2026,
                month: 7,
                day: 2,
                hour: 8,
                minute: 30,
                timeZoneOffsetSeconds: 8 * 3600
            ),
            captureTimezoneOffsetSeconds: 8 * 3600
        )
        let resultID =
            UUID()
        var card = RecordCard(
            template: memorySummaryTemplate(),
            metadata: metadata,
            context: MetadataContext.build(from: metadata)
        )
        card.memoryResult =
            MemoryResult(
                subjectID: UUID(),
                captureDate: metadata.captureDate,
                primaryAnchorResultID: resultID,
                anchorResults: [
                    MemoryAnchorResult(
                        id: resultID,
                        anchorID: UUID(),
                        anchorType: .birthday,
                        anchorTitle: "生日",
                        anchorDate:
                            try date(
                                year: 2026,
                                month: 6,
                                day: 1,
                                hour: 8,
                                minute: 30,
                                timeZoneOffsetSeconds:
                                    8 * 3600
                            ),
                        direction: .afterAnchor,
                        elapsed:
                            MemoryElapsedTime(
                                years: 0,
                                months: 1,
                                days: 1,
                                totalDays: 31,
                                weeks: 4,
                                totalMonths: 1,
                                isFutureRelative: false
                            ),
                        precision: .day,
                        status: .disabledAnchor,
                        source:
                            .frozenConfiguration
                    )
                ]
            )
        card.memoryModule =
            MemoryModule(
                title: "Memory",
                blocks: [
                    .text("乐乐")
                ],
                renderedText: "乐乐",
                sourceAnchor: nil,
                preferredRegion: .slotD
            )

        let context = CardVariableProvider.build(
            from: card
        )

        #expect(context[MetadataContext.Key.daysSince].isEmpty)
        #expect(context[MetadataContext.Key.yearsSince].isEmpty)
        #expect(context[MetadataContext.Key.monthsSince].isEmpty)
        #expect(context[MetadataContext.Key.weeksSince].isEmpty)
        #expect(context[MetadataContext.Key.babyAge].isEmpty)
        #expect(context[MetadataContext.Key.memorySummary] == "乐乐")
    }

    @Test("Does not fall back to legacy elapsed values when MemoryResult is unresolved")
    func doesNotFallBackToLegacyElapsedValuesWhenMemoryResultIsUnresolved() throws {

        let metadata = PhotoMetadata(
            captureDate: try date(
                year: 2026,
                month: 7,
                day: 2,
                hour: 8,
                minute: 30,
                timeZoneOffsetSeconds: 8 * 3600
            ),
            captureTimezoneOffsetSeconds: 8 * 3600
        )
        let resultID =
            UUID()
        let legacyAnchor =
            Anchor(
                type: .birthday,
                title: "生日",
                date:
                    try date(
                        year: 2026,
                        month: 6,
                        day: 1,
                        hour: 8,
                        minute: 30,
                        timeZoneOffsetSeconds:
                            8 * 3600
                    )
            )
        let legacyResult =
            AnchorEngine().build(
                from: legacyAnchor,
                photoDate:
                    try #require(
                        metadata.captureDate
                    )
            )
        var card = RecordCard(
            template: memorySummaryTemplate(),
            metadata: metadata,
            context: MetadataContext.build(from: metadata),
            anchor: legacyAnchor,
            anchorResult: legacyResult
        )
        card.memoryResult =
            MemoryResult(
                subjectID: UUID(),
                captureDate: metadata.captureDate,
                primaryAnchorResultID: resultID,
                anchorResults: [
                    MemoryAnchorResult(
                        id: resultID,
                        anchorID: UUID(),
                        anchorType: .birthday,
                        anchorTitle: "生日",
                        anchorDate: legacyAnchor.date,
                        direction: .onAnchor,
                        elapsed:
                            MemoryElapsedTime(
                                years: 0,
                                months: 0,
                                days: 0,
                                totalDays: 0,
                                weeks: 0,
                                totalMonths: 0,
                                isFutureRelative: false
                            ),
                        precision: .day,
                        status: .disabledAnchor,
                        source:
                            .frozenConfiguration
                    )
                ]
            )
        card.memoryModule =
            MemoryModule(
                title: "Memory",
                blocks: [
                    .text("生日智能模块")
                ],
                renderedText: "生日智能模块",
                sourceAnchor: nil,
                preferredRegion: .slotD
            )

        let context = CardVariableProvider.build(
            from: card
        )

        #expect(context[MetadataContext.Key.daysSince].isEmpty)
        #expect(context[MetadataContext.Key.yearsSince].isEmpty)
        #expect(context[MetadataContext.Key.monthsSince].isEmpty)
        #expect(context[MetadataContext.Key.weeksSince].isEmpty)
        #expect(context[MetadataContext.Key.babyAge].isEmpty)
        #expect(context[MetadataContext.Key.memorySummary] == "生日智能模块")
    }

    @Test("Projects resolved MemoryResult into anchor time-result variables")
    func projectsResolvedMemoryResultIntoAnchorTimeResultVariables() throws {

        let metadata = PhotoMetadata(
            captureDate: try date(
                year: 2026,
                month: 7,
                day: 2,
                hour: 8,
                minute: 30,
                timeZoneOffsetSeconds: 8 * 3600
            ),
            captureTimezoneOffsetSeconds: 8 * 3600
        )
        let resultID =
            UUID()
        var card = RecordCard(
            template: memorySummaryTemplate(),
            metadata: metadata,
            context: MetadataContext.build(from: metadata)
        )
        card.memoryResult =
            MemoryResult(
                subjectID: UUID(),
                captureDate: metadata.captureDate,
                primaryAnchorResultID: resultID,
                anchorResults: [
                    MemoryAnchorResult(
                        id: resultID,
                        anchorID: UUID(),
                        anchorType: .birthday,
                        anchorTitle: "生日",
                        anchorDate:
                            try date(
                                year: 2026,
                                month: 6,
                                day: 1,
                                hour: 8,
                                minute: 30,
                                timeZoneOffsetSeconds:
                                    8 * 3600
                            ),
                        direction: .afterAnchor,
                        elapsed:
                            MemoryElapsedTime(
                                years: 0,
                                months: 1,
                                days: 1,
                                totalDays: 31,
                                weeks: 4,
                                totalMonths: 1,
                                isFutureRelative: false
                            ),
                        precision: .day,
                        status: .resolved,
                        source:
                            .frozenConfiguration
                    )
                ]
            )

        let context = CardVariableProvider.build(
            from: card
        )

        #expect(context[MetadataContext.Key.anchorTitle] == "生日")
        #expect(context[MetadataContext.Key.anchorAgeText] == "1个月1天")
        #expect(context[MetadataContext.Key.anchorDurationText] == "1个月1天")
        #expect(context[MetadataContext.Key.anchorTotalDaysText] == "31天")
        #expect(context[MetadataContext.Key.anchorElapsedText] == "已过31天")
        #expect(context[MetadataContext.Key.anchorDayIndexText] == "第31天")
        #expect(context[MetadataContext.Key.anchorWeekText] == "4周3天")
        #expect(context[MetadataContext.Key.anchorMonthAgeText] == "1个月")
        #expect(context[MetadataContext.Key.anchorYears] == "0")
        #expect(context[MetadataContext.Key.anchorMonths] == "1")
        #expect(context[MetadataContext.Key.anchorDays] == "1")
        #expect(context[MetadataContext.Key.anchorSummary].isEmpty)
    }

    @Test("Projects future MemoryResult into countdown anchor variables only")
    func projectsFutureMemoryResultIntoCountdownAnchorVariablesOnly() throws {

        let metadata = PhotoMetadata(
            captureDate: try date(
                year: 2026,
                month: 7,
                day: 2,
                hour: 8,
                minute: 30,
                timeZoneOffsetSeconds: 8 * 3600
            ),
            captureTimezoneOffsetSeconds: 8 * 3600
        )
        let resultID =
            UUID()
        var card = RecordCard(
            template: memorySummaryTemplate(),
            metadata: metadata,
            context: MetadataContext.build(from: metadata)
        )
        card.memoryResult =
            MemoryResult(
                subjectID: UUID(),
                captureDate: metadata.captureDate,
                primaryAnchorResultID: resultID,
                anchorResults: [
                    MemoryAnchorResult(
                        id: resultID,
                        anchorID: UUID(),
                        anchorType: .birthday,
                        anchorTitle: "生日",
                        anchorDate:
                            try date(
                                year: 2026,
                                month: 9,
                                day: 26,
                                hour: 8,
                                minute: 30,
                                timeZoneOffsetSeconds:
                                    8 * 3600
                            ),
                        direction: .beforeAnchor,
                        elapsed:
                            MemoryElapsedTime(
                                years: 0,
                                months: 2,
                                days: 24,
                                totalDays: 86,
                                weeks: 12,
                                totalMonths: 2,
                                isFutureRelative: true
                            ),
                        precision: .day,
                        status: .resolved,
                        source:
                            .frozenConfiguration
                    )
                ]
            )

        let context = CardVariableProvider.build(
            from: card
        )

        #expect(context[MetadataContext.Key.anchorTitle] == "生日")
        #expect(context[MetadataContext.Key.anchorTotalDaysText] == "86天")
        #expect(context[MetadataContext.Key.anchorCountdownText] == "还有86天")
        #expect(context[MetadataContext.Key.anchorDurationText] == "86天")
        #expect(context[MetadataContext.Key.anchorAgeText].isEmpty)
        #expect(context[MetadataContext.Key.anchorElapsedText].isEmpty)
        #expect(context[MetadataContext.Key.anchorDayIndexText].isEmpty)
        #expect(context[MetadataContext.Key.anchorWeekText].isEmpty)
        #expect(context[MetadataContext.Key.anchorMonthAgeText].isEmpty)
        #expect(context[MetadataContext.Key.anchorSummary].isEmpty)
    }

    @Test("Prefers MemoryResult over legacy AnchorResult for anchor time-result variables")
    func prefersMemoryResultOverLegacyAnchorResultForAnchorTimeResultVariables() throws {

        let metadata = PhotoMetadata(
            captureDate: try date(
                year: 2026,
                month: 7,
                day: 2,
                hour: 8,
                minute: 30,
                timeZoneOffsetSeconds: 8 * 3600
            ),
            captureTimezoneOffsetSeconds: 8 * 3600
        )
        let resultID =
            UUID()
        let legacyAnchor =
            Anchor(
                type: .birthday,
                title: "生日",
                date:
                    try date(
                        year: 2025,
                        month: 1,
                        day: 1,
                        hour: 8,
                        minute: 30,
                        timeZoneOffsetSeconds:
                            8 * 3600
                    )
            )
        let legacyResult =
            AnchorEngine().build(
                from: legacyAnchor,
                photoDate:
                    try #require(
                        metadata.captureDate
                    )
            )
        var card = RecordCard(
            template: memorySummaryTemplate(),
            metadata: metadata,
            context: MetadataContext.build(from: metadata),
            anchor: legacyAnchor,
            anchorResult: legacyResult
        )
        card.memoryResult =
            MemoryResult(
                subjectID: UUID(),
                captureDate: metadata.captureDate,
                primaryAnchorResultID: resultID,
                anchorResults: [
                    MemoryAnchorResult(
                        id: resultID,
                        anchorID: UUID(),
                        anchorType: .birthday,
                        anchorTitle: "生日",
                        anchorDate:
                            try date(
                                year: 2026,
                                month: 6,
                                day: 1,
                                hour: 8,
                                minute: 30,
                                timeZoneOffsetSeconds:
                                    8 * 3600
                            ),
                        direction: .afterAnchor,
                        elapsed:
                            MemoryElapsedTime(
                                years: 0,
                                months: 1,
                                days: 1,
                                totalDays: 31,
                                weeks: 4,
                                totalMonths: 1,
                                isFutureRelative: false
                            ),
                        precision: .day,
                        status: .resolved,
                        source:
                            .frozenConfiguration
                    )
                ]
            )

        let context = CardVariableProvider.build(
            from: card
        )

        #expect(context[MetadataContext.Key.anchorTotalDaysText] == "31天")
        #expect(context[MetadataContext.Key.anchorAgeText] == "1个月1天")
        #expect(context[MetadataContext.Key.anchorWeekText] == "4周3天")
        #expect(context[MetadataContext.Key.anchorYears] == "0")
        #expect(context[MetadataContext.Key.anchorMonths] == "1")
        #expect(context[MetadataContext.Key.anchorDays] == "1")
        #expect(context[MetadataContext.Key.anchorSummary].isEmpty)
    }

    @Test("Clears legacy anchor display-copy variables when MemoryResult is authoritative")
    func clearsLegacyAnchorDisplayCopyVariablesWhenMemoryResultIsAuthoritative() throws {

        let metadata = PhotoMetadata(
            captureDate: try date(
                year: 2026,
                month: 7,
                day: 2,
                hour: 8,
                minute: 30,
                timeZoneOffsetSeconds: 8 * 3600
            ),
            captureTimezoneOffsetSeconds: 8 * 3600
        )
        let resultID =
            UUID()
        let legacyAnchor =
            Anchor(
                type: .birthday,
                title: "旧生日",
                date:
                    try date(
                        year: 2025,
                        month: 1,
                        day: 1,
                        hour: 8,
                        minute: 30,
                        timeZoneOffsetSeconds:
                            8 * 3600
                    )
            )
        let legacyResult =
            AnchorEngine().build(
                from: legacyAnchor,
                photoDate:
                    try #require(
                        metadata.captureDate
                    )
            )
        var card = RecordCard(
            template: memorySummaryTemplate(),
            metadata: metadata,
            context: MetadataContext.build(from: metadata),
            anchor: legacyAnchor,
            anchorResult: legacyResult
        )
        card.memoryResult =
            MemoryResult(
                subjectID: UUID(),
                captureDate: metadata.captureDate,
                primaryAnchorResultID: resultID,
                anchorResults: [
                    MemoryAnchorResult(
                        id: resultID,
                        anchorID: UUID(),
                        anchorType: .relationship,
                        anchorTitle: "相识",
                        anchorDate:
                            try date(
                                year: 2026,
                                month: 6,
                                day: 1,
                                hour: 8,
                                minute: 30,
                                timeZoneOffsetSeconds:
                                    8 * 3600
                            ),
                        direction: .afterAnchor,
                        elapsed:
                            MemoryElapsedTime(
                                years: 0,
                                months: 1,
                                days: 1,
                                totalDays: 31,
                                weeks: 4,
                                totalMonths: 1,
                                isFutureRelative: false
                            ),
                        precision: .day,
                        status: .resolved,
                        source:
                            .frozenConfiguration
                    )
                ]
            )

        let context = CardVariableProvider.build(
            from: card
        )

        #expect(context[MetadataContext.Key.anchorTitle] == "相识")
        #expect(context[MetadataContext.Key.anchorPrimary].isEmpty)
        #expect(context[MetadataContext.Key.anchorSecondary].isEmpty)
        #expect(context[MetadataContext.Key.anchorSummary].isEmpty)
        #expect(context[MetadataContext.Key.anchorElapsedText] == "已过31天")
    }

    @Test("Keeps anchor title authoritative when MemoryResult is unresolved")
    func keepsAnchorTitleAuthoritativeWhenMemoryResultIsUnresolved() throws {

        let metadata = PhotoMetadata(
            captureDate: try date(
                year: 2026,
                month: 7,
                day: 2,
                hour: 8,
                minute: 30,
                timeZoneOffsetSeconds: 8 * 3600
            ),
            captureTimezoneOffsetSeconds: 8 * 3600
        )
        let resultID =
            UUID()
        let legacyAnchor =
            Anchor(
                type: .birthday,
                title: "旧生日",
                date:
                    try date(
                        year: 2026,
                        month: 6,
                        day: 1,
                        hour: 8,
                        minute: 30,
                        timeZoneOffsetSeconds:
                            8 * 3600
                    )
            )
        let legacyResult =
            AnchorEngine().build(
                from: legacyAnchor,
                photoDate:
                    try #require(
                        metadata.captureDate
                    )
            )
        var card = RecordCard(
            template: memorySummaryTemplate(),
            metadata: metadata,
            context: MetadataContext.build(from: metadata),
            anchor: legacyAnchor,
            anchorResult: legacyResult
        )
        card.memoryResult =
            MemoryResult(
                subjectID: UUID(),
                captureDate: metadata.captureDate,
                primaryAnchorResultID: resultID,
                anchorResults: [
                    MemoryAnchorResult(
                        id: resultID,
                        anchorID: UUID(),
                        anchorType: .birthday,
                        anchorTitle: "冻结生日",
                        anchorDate: legacyAnchor.date,
                        direction: .onAnchor,
                        elapsed:
                            MemoryElapsedTime(
                                years: 0,
                                months: 0,
                                days: 0,
                                totalDays: 0,
                                weeks: 0,
                                totalMonths: 0,
                                isFutureRelative: false
                            ),
                        precision: .day,
                        status: .disabledAnchor,
                        source:
                            .frozenConfiguration
                    )
                ]
            )

        let context = CardVariableProvider.build(
            from: card
        )

        #expect(context[MetadataContext.Key.anchorTitle] == "冻结生日")
        #expect(context[MetadataContext.Key.anchorAgeText].isEmpty)
        #expect(context[MetadataContext.Key.anchorSummary].isEmpty)
    }

    @Test("Clears legacy sub-day anchor components when MemoryResult is authoritative")
    func clearsLegacySubDayAnchorComponentsWhenMemoryResultIsAuthoritative() throws {

        let metadata = PhotoMetadata(
            captureDate: try date(
                year: 2026,
                month: 7,
                day: 2,
                hour: 8,
                minute: 30,
                timeZoneOffsetSeconds: 8 * 3600
            ),
            captureTimezoneOffsetSeconds: 8 * 3600
        )
        let resultID =
            UUID()
        let legacyAnchor =
            Anchor(
                type: .birthday,
                title: "旧生日",
                date:
                    try date(
                        year: 2026,
                        month: 6,
                        day: 1,
                        hour: 1,
                        minute: 2,
                        timeZoneOffsetSeconds:
                            8 * 3600
                    )
            )
        let legacyResult =
            AnchorResult(
                title: "旧生日",
                isFutureRelative: false,
                primaryText: "旧主文案",
                secondaryText: "旧副文案",
                summaryText: "旧完整文案",
                ageText: "旧年龄",
                durationText: "旧时长",
                countdownText: "",
                elapsedText: "旧已过",
                dayIndexText: "旧第几天",
                weekText: "旧周数",
                monthAgeText: "旧月数",
                milestoneText: "",
                years: 9,
                months: 8,
                days: 7,
                hours: 6,
                minutes: 5,
                seconds: 4,
                totalDays: 999
            )
        var card = RecordCard(
            template: memorySummaryTemplate(),
            metadata: metadata,
            context: MetadataContext.build(from: metadata),
            anchor: legacyAnchor,
            anchorResult: legacyResult
        )
        card.memoryResult =
            MemoryResult(
                subjectID: UUID(),
                captureDate: metadata.captureDate,
                primaryAnchorResultID: resultID,
                anchorResults: [
                    MemoryAnchorResult(
                        id: resultID,
                        anchorID: UUID(),
                        anchorType: .birthday,
                        anchorTitle: "冻结生日",
                        anchorDate:
                            try date(
                                year: 2026,
                                month: 6,
                                day: 1,
                                hour: 8,
                                minute: 30,
                                timeZoneOffsetSeconds:
                                    8 * 3600
                            ),
                        direction: .afterAnchor,
                        elapsed:
                            MemoryElapsedTime(
                                years: 0,
                                months: 1,
                                days: 1,
                                totalDays: 31,
                                weeks: 4,
                                totalMonths: 1,
                                isFutureRelative: false
                            ),
                        precision: .day,
                        status: .resolved,
                        source:
                            .frozenConfiguration
                    )
                ]
            )

        let context = CardVariableProvider.build(
            from: card
        )

        #expect(context[MetadataContext.Key.anchorYears] == "0")
        #expect(context[MetadataContext.Key.anchorMonths] == "1")
        #expect(context[MetadataContext.Key.anchorDays] == "1")
        #expect(context[MetadataContext.Key.anchorTotalDays] == "31")
        #expect(context[MetadataContext.Key.anchorHours].isEmpty)
        #expect(context[MetadataContext.Key.anchorMinutes].isEmpty)
        #expect(context[MetadataContext.Key.anchorSeconds].isEmpty)
    }

    @Test("Clears legacy milestone text when MemoryResult has no milestone semantic")
    func clearsLegacyMilestoneTextWhenMemoryResultHasNoMilestoneSemantic() throws {

        let metadata = PhotoMetadata(
            captureDate: try date(
                year: 2026,
                month: 7,
                day: 2,
                hour: 8,
                minute: 30,
                timeZoneOffsetSeconds: 8 * 3600
            ),
            captureTimezoneOffsetSeconds: 8 * 3600
        )
        let resultID =
            UUID()
        let legacyAnchor =
            Anchor(
                type: .birthday,
                title: "旧生日",
                date:
                    try date(
                        year: 2026,
                        month: 3,
                        day: 24,
                        hour: 8,
                        minute: 30,
                        timeZoneOffsetSeconds:
                            8 * 3600
                    )
            )
        let legacyResult =
            AnchorResult(
                title: "旧生日",
                isFutureRelative: false,
                primaryText: "旧主文案",
                secondaryText: "旧副文案",
                summaryText: "旧完整文案",
                ageText: "旧年龄",
                durationText: "旧时长",
                countdownText: "",
                elapsedText: "旧已过",
                dayIndexText: "旧第几天",
                weekText: "旧周数",
                monthAgeText: "旧月数",
                milestoneText: "100天纪念日",
                years: 0,
                months: 3,
                days: 8,
                hours: 0,
                minutes: 0,
                seconds: 0,
                totalDays: 100
            )
        var card = RecordCard(
            template: memorySummaryTemplate(),
            metadata: metadata,
            context: MetadataContext.build(from: metadata),
            anchor: legacyAnchor,
            anchorResult: legacyResult
        )
        card.memoryResult =
            MemoryResult(
                subjectID: UUID(),
                captureDate: metadata.captureDate,
                primaryAnchorResultID: resultID,
                anchorResults: [
                    MemoryAnchorResult(
                        id: resultID,
                        anchorID: UUID(),
                        anchorType: .birthday,
                        anchorTitle: "冻结生日",
                        anchorDate:
                            try date(
                                year: 2026,
                                month: 6,
                                day: 1,
                                hour: 8,
                                minute: 30,
                                timeZoneOffsetSeconds:
                                    8 * 3600
                            ),
                        direction: .afterAnchor,
                        elapsed:
                            MemoryElapsedTime(
                                years: 0,
                                months: 1,
                                days: 1,
                                totalDays: 31,
                                weeks: 4,
                                totalMonths: 1,
                                isFutureRelative: false
                            ),
                        precision: .day,
                        status: .resolved,
                        source:
                            .frozenConfiguration
                    )
                ]
            )

        let context = CardVariableProvider.build(
            from: card
        )

        #expect(context[MetadataContext.Key.anchorMilestoneText].isEmpty)
        #expect(context[MetadataContext.Key.anchorTotalDays] == "31")
    }

    @Test("Does not refill baby age from legacy when MemoryResult has no baby age")
    func doesNotRefillBabyAgeFromLegacyWhenMemoryResultHasNoBabyAge() throws {

        let metadata = PhotoMetadata(
            captureDate: try date(
                year: 2026,
                month: 7,
                day: 2,
                hour: 8,
                minute: 30,
                timeZoneOffsetSeconds: 8 * 3600
            ),
            captureTimezoneOffsetSeconds: 8 * 3600
        )
        let resultID =
            UUID()
        let legacyAnchor =
            Anchor(
                type: .birthday,
                title: "旧生日",
                date:
                    try date(
                        year: 2025,
                        month: 1,
                        day: 1,
                        hour: 8,
                        minute: 30,
                        timeZoneOffsetSeconds:
                            8 * 3600
                    )
            )
        let legacyResult =
            AnchorEngine().build(
                from: legacyAnchor,
                photoDate:
                    try #require(
                        metadata.captureDate
                    )
            )
        var card = RecordCard(
            template: memorySummaryTemplate(),
            metadata: metadata,
            context: MetadataContext.build(from: metadata),
            anchor: legacyAnchor,
            anchorResult: legacyResult
        )
        card.memoryResult =
            MemoryResult(
                subjectID: UUID(),
                captureDate: metadata.captureDate,
                primaryAnchorResultID: resultID,
                anchorResults: [
                    MemoryAnchorResult(
                        id: resultID,
                        anchorID: UUID(),
                        anchorType: .relationship,
                        anchorTitle: "相识",
                        anchorDate:
                            try date(
                                year: 2026,
                                month: 6,
                                day: 1,
                                hour: 8,
                                minute: 30,
                                timeZoneOffsetSeconds:
                                    8 * 3600
                            ),
                        direction: .afterAnchor,
                        elapsed:
                            MemoryElapsedTime(
                                years: 0,
                                months: 1,
                                days: 1,
                                totalDays: 31,
                                weeks: 4,
                                totalMonths: 1,
                                isFutureRelative: false
                            ),
                        precision: .day,
                        status: .resolved,
                        source:
                            .frozenConfiguration
                    )
                ]
            )
        card.memoryModule =
            MemoryModule(
                title: "Memory",
                blocks: [
                    .text("相识智能模块")
                ],
                renderedText: "相识智能模块",
                sourceAnchor: nil,
                preferredRegion: .slotD
            )

        let context = CardVariableProvider.build(
            from: card
        )

        #expect(context[MetadataContext.Key.daysSince] == "31")
        #expect(context[MetadataContext.Key.monthsSince] == "1")
        #expect(context[MetadataContext.Key.weeksSince] == "4")
        #expect(context[MetadataContext.Key.babyAge].isEmpty)
        #expect(context[MetadataContext.Key.memorySummary] == "相识智能模块")
    }

    @Test("Clears legacy past anchor variables when MemoryResult is future-relative")
    func clearsLegacyPastAnchorVariablesWhenMemoryResultIsFutureRelative() throws {

        let metadata = PhotoMetadata(
            captureDate: try date(
                year: 2026,
                month: 7,
                day: 2,
                hour: 8,
                minute: 30,
                timeZoneOffsetSeconds: 8 * 3600
            ),
            captureTimezoneOffsetSeconds: 8 * 3600
        )
        let resultID =
            UUID()
        let legacyAnchor =
            Anchor(
                type: .birthday,
                title: "生日",
                date:
                    try date(
                        year: 2026,
                        month: 6,
                        day: 1,
                        hour: 8,
                        minute: 30,
                        timeZoneOffsetSeconds:
                            8 * 3600
                    )
            )
        let legacyResult =
            AnchorEngine().build(
                from: legacyAnchor,
                photoDate:
                    try #require(
                        metadata.captureDate
                    )
            )
        var card = RecordCard(
            template: memorySummaryTemplate(),
            metadata: metadata,
            context: MetadataContext.build(from: metadata),
            anchor: legacyAnchor,
            anchorResult: legacyResult
        )
        card.memoryResult =
            MemoryResult(
                subjectID: UUID(),
                captureDate: metadata.captureDate,
                primaryAnchorResultID: resultID,
                anchorResults: [
                    MemoryAnchorResult(
                        id: resultID,
                        anchorID: UUID(),
                        anchorType: .birthday,
                        anchorTitle: "生日",
                        anchorDate:
                            try date(
                                year: 2026,
                                month: 9,
                                day: 26,
                                hour: 8,
                                minute: 30,
                                timeZoneOffsetSeconds:
                                    8 * 3600
                            ),
                        direction: .beforeAnchor,
                        elapsed:
                            MemoryElapsedTime(
                                years: 0,
                                months: 2,
                                days: 24,
                                totalDays: 86,
                                weeks: 12,
                                totalMonths: 2,
                                isFutureRelative: true
                            ),
                        precision: .day,
                        status: .resolved,
                        source:
                            .frozenConfiguration
                    )
                ]
            )

        let context = CardVariableProvider.build(
            from: card
        )

        #expect(context[MetadataContext.Key.anchorCountdownText] == "还有86天")
        #expect(context[MetadataContext.Key.anchorDurationText] == "86天")
        #expect(context[MetadataContext.Key.anchorAgeText].isEmpty)
        #expect(context[MetadataContext.Key.anchorElapsedText].isEmpty)
        #expect(context[MetadataContext.Key.anchorDayIndexText].isEmpty)
        #expect(context[MetadataContext.Key.anchorWeekText].isEmpty)
        #expect(context[MetadataContext.Key.anchorMonthAgeText].isEmpty)
    }

    @Test("Clears legacy future anchor variables when MemoryResult is past-relative")
    func clearsLegacyFutureAnchorVariablesWhenMemoryResultIsPastRelative() throws {

        let metadata = PhotoMetadata(
            captureDate: try date(
                year: 2026,
                month: 7,
                day: 2,
                hour: 8,
                minute: 30,
                timeZoneOffsetSeconds: 8 * 3600
            ),
            captureTimezoneOffsetSeconds: 8 * 3600
        )
        let resultID =
            UUID()
        let legacyAnchor =
            Anchor(
                type: .birthday,
                title: "生日",
                date:
                    try date(
                        year: 2026,
                        month: 9,
                        day: 26,
                        hour: 8,
                        minute: 30,
                        timeZoneOffsetSeconds:
                            8 * 3600
                    )
            )
        let legacyResult =
            AnchorEngine().build(
                from: legacyAnchor,
                photoDate:
                    try #require(
                        metadata.captureDate
                    )
            )
        var card = RecordCard(
            template: memorySummaryTemplate(),
            metadata: metadata,
            context: MetadataContext.build(from: metadata),
            anchor: legacyAnchor,
            anchorResult: legacyResult
        )
        card.memoryResult =
            MemoryResult(
                subjectID: UUID(),
                captureDate: metadata.captureDate,
                primaryAnchorResultID: resultID,
                anchorResults: [
                    MemoryAnchorResult(
                        id: resultID,
                        anchorID: UUID(),
                        anchorType: .birthday,
                        anchorTitle: "生日",
                        anchorDate:
                            try date(
                                year: 2026,
                                month: 6,
                                day: 1,
                                hour: 8,
                                minute: 30,
                                timeZoneOffsetSeconds:
                                    8 * 3600
                            ),
                        direction: .afterAnchor,
                        elapsed:
                            MemoryElapsedTime(
                                years: 0,
                                months: 1,
                                days: 1,
                                totalDays: 31,
                                weeks: 4,
                                totalMonths: 1,
                                isFutureRelative: false
                            ),
                        precision: .day,
                        status: .resolved,
                        source:
                            .frozenConfiguration
                    )
                ]
            )

        let context = CardVariableProvider.build(
            from: card
        )

        #expect(context[MetadataContext.Key.anchorCountdownText].isEmpty)
        #expect(context[MetadataContext.Key.anchorDurationText] == "1个月1天")
        #expect(context[MetadataContext.Key.anchorAgeText] == "1个月1天")
        #expect(context[MetadataContext.Key.anchorElapsedText] == "已过31天")
        #expect(context[MetadataContext.Key.anchorDayIndexText] == "第31天")
        #expect(context[MetadataContext.Key.anchorWeekText] == "4周3天")
    }

    @Test("Clears legacy anchor time-result variables when MemoryResult is unresolved")
    func clearsLegacyAnchorTimeResultVariablesWhenMemoryResultIsUnresolved() throws {

        let metadata = PhotoMetadata(
            captureDate: try date(
                year: 2026,
                month: 7,
                day: 2,
                hour: 8,
                minute: 30,
                timeZoneOffsetSeconds: 8 * 3600
            ),
            captureTimezoneOffsetSeconds: 8 * 3600
        )
        let resultID =
            UUID()
        let legacyAnchor =
            Anchor(
                type: .birthday,
                title: "生日",
                date:
                    try date(
                        year: 2026,
                        month: 6,
                        day: 1,
                        hour: 8,
                        minute: 30,
                        timeZoneOffsetSeconds:
                            8 * 3600
                    )
            )
        let legacyResult =
            AnchorEngine().build(
                from: legacyAnchor,
                photoDate:
                    try #require(
                        metadata.captureDate
                    )
            )
        var card = RecordCard(
            template: memorySummaryTemplate(),
            metadata: metadata,
            context: MetadataContext.build(from: metadata),
            anchor: legacyAnchor,
            anchorResult: legacyResult
        )
        card.memoryResult =
            MemoryResult(
                subjectID: UUID(),
                captureDate: metadata.captureDate,
                primaryAnchorResultID: resultID,
                anchorResults: [
                    MemoryAnchorResult(
                        id: resultID,
                        anchorID: UUID(),
                        anchorType: .birthday,
                        anchorTitle: "生日",
                        anchorDate: legacyAnchor.date,
                        direction: .onAnchor,
                        elapsed:
                            MemoryElapsedTime(
                                years: 0,
                                months: 0,
                                days: 0,
                                totalDays: 0,
                                weeks: 0,
                                totalMonths: 0,
                                isFutureRelative: false
                            ),
                        precision: .day,
                        status: .disabledAnchor,
                        source:
                            .frozenConfiguration
                    )
                ]
            )

        let context = CardVariableProvider.build(
            from: card
        )

        #expect(context[MetadataContext.Key.anchorAgeText].isEmpty)
        #expect(context[MetadataContext.Key.anchorSmartText].isEmpty)
        #expect(context[MetadataContext.Key.anchorDurationText].isEmpty)
        #expect(context[MetadataContext.Key.anchorTotalDaysText].isEmpty)
        #expect(context[MetadataContext.Key.anchorElapsedText].isEmpty)
        #expect(context[MetadataContext.Key.anchorDayIndexText].isEmpty)
        #expect(context[MetadataContext.Key.anchorWeekText].isEmpty)
        #expect(context[MetadataContext.Key.anchorMonthAgeText].isEmpty)
        #expect(context[MetadataContext.Key.anchorMilestoneText].isEmpty)
        #expect(context[MetadataContext.Key.anchorCountdownText].isEmpty)
        #expect(context[MetadataContext.Key.anchorYears].isEmpty)
        #expect(context[MetadataContext.Key.anchorMonths].isEmpty)
        #expect(context[MetadataContext.Key.anchorDays].isEmpty)
        #expect(context[MetadataContext.Key.anchorTotalDays].isEmpty)
        #expect(context[MetadataContext.Key.anchorSummary].isEmpty)
    }

    @Test("Clears legacy values when MemoryResult has no primary anchor")
    func clearsLegacyValuesWhenMemoryResultHasNoPrimaryAnchor() throws {

        let metadata = PhotoMetadata(
            captureDate: try date(
                year: 2026,
                month: 7,
                day: 2,
                hour: 8,
                minute: 30,
                timeZoneOffsetSeconds: 8 * 3600
            ),
            captureTimezoneOffsetSeconds: 8 * 3600
        )
        let legacyAnchor =
            Anchor(
                type: .birthday,
                title: "生日",
                date:
                    try date(
                        year: 2026,
                        month: 6,
                        day: 1,
                        hour: 8,
                        minute: 30,
                        timeZoneOffsetSeconds:
                            8 * 3600
                    )
            )
        let legacyResult =
            AnchorEngine().build(
                from: legacyAnchor,
                photoDate:
                    try #require(
                        metadata.captureDate
                    )
            )
        var card = RecordCard(
            template: memorySummaryTemplate(),
            metadata: metadata,
            context: MetadataContext.build(from: metadata),
            anchor: legacyAnchor,
            anchorResult: legacyResult
        )
        card.memoryResult =
            MemoryResult(
                subjectID: UUID(),
                captureDate: metadata.captureDate,
                primaryAnchorResultID: nil,
                anchorResults: []
            )
        card.memoryModule =
            MemoryModule(
                title: "Memory",
                blocks: [
                    .text("生日智能模块")
                ],
                renderedText: "生日智能模块",
                sourceAnchor: nil,
                preferredRegion: .slotD
            )

        let context = CardVariableProvider.build(
            from: card
        )

        #expect(context[MetadataContext.Key.daysSince].isEmpty)
        #expect(context[MetadataContext.Key.yearsSince].isEmpty)
        #expect(context[MetadataContext.Key.monthsSince].isEmpty)
        #expect(context[MetadataContext.Key.weeksSince].isEmpty)
        #expect(context[MetadataContext.Key.babyAge].isEmpty)
        #expect(context[MetadataContext.Key.memorySummary] == "生日智能模块")
        #expect(context[MetadataContext.Key.anchorTitle].isEmpty)
        #expect(context[MetadataContext.Key.anchorAgeText].isEmpty)
        #expect(context[MetadataContext.Key.anchorSmartText].isEmpty)
        #expect(context[MetadataContext.Key.anchorDurationText].isEmpty)
        #expect(context[MetadataContext.Key.anchorTotalDaysText].isEmpty)
        #expect(context[MetadataContext.Key.anchorElapsedText].isEmpty)
        #expect(context[MetadataContext.Key.anchorDayIndexText].isEmpty)
        #expect(context[MetadataContext.Key.anchorWeekText].isEmpty)
        #expect(context[MetadataContext.Key.anchorMonthAgeText].isEmpty)
        #expect(context[MetadataContext.Key.anchorMilestoneText].isEmpty)
        #expect(context[MetadataContext.Key.anchorCountdownText].isEmpty)
        #expect(context[MetadataContext.Key.anchorYears].isEmpty)
        #expect(context[MetadataContext.Key.anchorMonths].isEmpty)
        #expect(context[MetadataContext.Key.anchorDays].isEmpty)
        #expect(context[MetadataContext.Key.anchorTotalDays].isEmpty)
        #expect(context[MetadataContext.Key.anchorSummary].isEmpty)
    }

    @Test("Exposes new memory variables through the public catalog")
    func exposesNewMemoryVariablesThroughPublicCatalog() {

        let tokens = Set(
            TemplateVariableLibrary.intelligent.map(\.token)
        )

        #expect(tokens.contains("{{days_since}}"))
        #expect(tokens.contains("{{years_since}}"))
        #expect(tokens.contains("{{months_since}}"))
        #expect(tokens.contains("{{weeks_since}}"))
        #expect(tokens.contains("{{baby_age}}"))
        #expect(tokens.contains("{{memory_summary}}"))

        #expect(!tokens.contains("{{anchor_primary}}"))
        #expect(!tokens.contains("{{anchor_summary}}"))
        #expect(!tokens.contains("{{anchor_smart_text}}"))
        #expect(!tokens.contains("{{anchor_age_text}}"))
        #expect(!tokens.contains("{{anchor_duration_text}}"))
        #expect(!tokens.contains("{{anchor_countdown_text}}"))
    }

    private func date(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int,
        timeZoneOffsetSeconds: Int
    ) throws -> Date {

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(
            secondsFromGMT: timeZoneOffsetSeconds
        ) ?? .gmt

        let components = DateComponents(
            timeZone: calendar.timeZone,
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        )

        return try #require(
            calendar.date(from: components)
        )
    }

    private func memorySummaryTemplate() -> Template {

        Template(
            preset: .template1,
            name: "Memory Summary",
            leftTopArea: .leftTop,
            leftBottomArea: .leftBottom,
            rightTopArea: TemplateArea(
                name: "Right Top",
                items: [.cameraSummary]
            ),
            rightBottomArea: TemplateArea(
                name: "Right Bottom",
                items: [
                    TemplateItem(
                        type: .text,
                        name: "Memory Summary",
                        value: "{{memory_summary}}"
                    )
                ]
            ),
            badgeArea: .badge
        ).normalizedForEditing
    }
}
