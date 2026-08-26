import Foundation
import Testing
@testable import MemoMark

@Suite("Legacy Output Localization")
struct LegacyOutputLocalizationTests {

    @Test("AnchorEngine keeps an explicit Japanese output language")
    func anchorEngineKeepsExplicitJapaneseOutputLanguage() throws {
        let calendar = utcCalendar()
        let anchorDate = try #require(
            calendar.date(
                from: DateComponents(
                    year: 2025,
                    month: 1,
                    day: 1
                )
            )
        )
        let captureDate = try #require(
            calendar.date(
                from: DateComponents(
                    year: 2026,
                    month: 4,
                    day: 3
                )
            )
        )

        let result = AnchorEngine(calendar: calendar).build(
            from: Anchor(
                type: .birthday,
                title: "Baby",
                date: anchorDate,
                expressionStyle: .birthdayNatural
            ),
            photoDate: captureDate,
            outputLanguage: .japanese
        )

        #expect(result.ageText == "1歳3か月2日")
        #expect(result.summaryText == "今日はBabyが1歳3か月2日です")
    }

    @Test("MemoryVariableProvider uses the output language from its context")
    func memoryVariableProviderUsesOutputLanguageFromContext() throws {
        let calendar = utcCalendar()
        let anchorDate = try #require(
            calendar.date(
                from: DateComponents(
                    year: 2025,
                    month: 1,
                    day: 1
                )
            )
        )
        let captureDate = try #require(
            calendar.date(
                from: DateComponents(
                    year: 2026,
                    month: 4,
                    day: 3
                )
            )
        )
        let metadata = PhotoMetadata(
            captureDate: captureDate,
            captureTimezoneOffsetSeconds: 0
        )
        let anchor = Anchor(
            type: .birthday,
            title: "Baby",
            date: anchorDate,
            expressionStyle: .birthdayNatural
        )

        let values = MemoryVariableProvider().build(
            from: MemoryContext(
                metadata: metadata,
                anchor: anchor,
                subjectText: "Baby",
                outputLanguage: .japanese
            )
        )

        #expect(values.babyAge == "1歳3か月2日")
        #expect(values.memorySummary == "今日はBabyが1歳3か月2日です")
    }

    @Test("Card variables preserve the Japanese Preset output language")
    func cardVariablesPreserveJapanesePresetOutputLanguage() throws {
        let calendar = utcCalendar()
        let anchorDate = try #require(
            calendar.date(
                from: DateComponents(
                    year: 2025,
                    month: 1,
                    day: 1
                )
            )
        )
        let captureDate = try #require(
            calendar.date(
                from: DateComponents(
                    year: 2026,
                    month: 4,
                    day: 3
                )
            )
        )
        let metadata = PhotoMetadata(
            captureDate: captureDate,
            captureTimezoneOffsetSeconds: 0
        )
        let anchor = Anchor(
            type: .birthday,
            title: "Baby",
            date: anchorDate,
            expressionStyle: .birthdayNatural
        )
        let anchorResult = AnchorEngine(calendar: calendar).build(
            from: anchor,
            photoDate: captureDate,
            outputLanguage: .japanese
        )
        let card = RecordCard(
            metadata: metadata,
            context: MetadataContext.build(from: metadata),
            language: .japanese,
            anchor: anchor,
            anchorResult: anchorResult,
            title: "Baby",
            memorySubjectText: "Baby"
        )

        let variables = CardVariableProvider.build(from: card)

        #expect(
            variables[MetadataContext.Key.babyAge] == "1歳3か月2日"
        )
        #expect(
            variables[MetadataContext.Key.memorySummary]
                == "今日はBabyが1歳3か月2日です"
        )
    }

    @Test("Legacy natural output routes all four languages through Narrative")
    func legacyNaturalOutputRoutesAllFourLanguagesThroughNarrative() {
        let languages: [MemoMarkLanguage] = [
            .simplifiedChinese,
            .english,
            .japanese,
            .korean
        ]
        let elapsedSnapshot = MemoryAnchorRelativeSnapshot(
            years: 1,
            months: 3,
            days: 2,
            totalDays: 487,
            isFutureRelative: false
        )
        let countdownSnapshot = MemoryAnchorRelativeSnapshot(
            years: 0,
            months: 0,
            days: 86,
            totalDays: 86,
            isFutureRelative: true
        )
        let annualOccurrence = MemoryAnchorAnnualOccurrence(
            date: Date(timeIntervalSince1970: 0),
            yearsAtOccurrence: 3,
            daysUntilOccurrence: 0
        )

        let expectedElapsed = [
            "今天Baby1岁3个月2天",
            "Baby is 1 year, 3 months, and 2 days old today",
            "今日はBabyが1歳3か月2日です",
            "오늘 Baby는 1년 3개월 2일입니다"
        ]
        let expectedCountdown = [
            "还有86天，Baby就要出生了",
            "86 days until Baby arrives",
            "あと86日でBabyが生まれます",
            "86일 후 Baby가 태어납니다"
        ]
        let expectedAnniversary = [
            "今天是结婚3周年",
            "Today marks 3 years of marriage",
            "今日は結婚3周年です",
            "오늘은 결혼 3주년입니다"
        ]

        for (index, language) in languages.enumerated() {
            #expect(
                MemoryAnchorExpressionResolver.renderedText(
                    subjectText: "Baby",
                    anchorTitle: "Baby",
                    anchorType: .birthday,
                    expressionStyle: .birthdayNatural,
                    relativeSnapshot: elapsedSnapshot,
                    language: language
                ) == expectedElapsed[index]
            )
            #expect(
                MemoryAnchorExpressionResolver.renderedText(
                    subjectText: "Baby",
                    anchorTitle: "Baby",
                    anchorType: .birthday,
                    expressionStyle: .birthdayNatural,
                    relativeSnapshot: countdownSnapshot,
                    language: language
                ) == expectedCountdown[index]
            )
            #expect(
                MemoryAnchorExpressionResolver.renderedText(
                    subjectText: "",
                    anchorTitle: "结婚",
                    anchorType: .marriage,
                    expressionStyle: .marriageNatural,
                    relativeSnapshot: elapsedSnapshot,
                    annualOccurrence: annualOccurrence,
                    prefersAnnualOccurrence: true,
                    language: language
                ) == expectedAnniversary[index]
            )
        }
    }

    @Test("Legacy milestone variables use the Preset output language")
    func legacyMilestonesUsePresetOutputLanguage() throws {
        let calendar = utcCalendar()
        let anchorDate = try #require(
            calendar.date(
                from: DateComponents(
                    year: 2025,
                    month: 1,
                    day: 1
                )
            )
        )
        let captureDate = try #require(
            calendar.date(
                from: DateComponents(
                    year: 2025,
                    month: 1,
                    day: 8
                )
            )
        )
        let anchor = Anchor(
            type: .birthday,
            title: "Baby",
            date: anchorDate,
            expressionStyle: .birthdayNatural
        )
        let languages: [MemoMarkLanguage] = [
            .simplifiedChinese,
            .english,
            .japanese,
            .korean
        ]
        let expected = [
            "满7天",
            "7 days old",
            "生後7日",
            "태어난 지 7일"
        ]

        for (index, language) in languages.enumerated() {
            let result = AnchorEngine(calendar: calendar).build(
                from: anchor,
                photoDate: captureDate,
                outputLanguage: language
            )

            #expect(result.milestoneText == expected[index])
        }
    }

    @Test("Non-natural Japanese and Korean legacy styles never fall back to Chinese")
    func nonNaturalJapaneseAndKoreanStylesAvoidChineseFallback() {
        let snapshot = MemoryAnchorRelativeSnapshot(
            years: 1,
            months: 3,
            days: 2,
            totalDays: 487,
            isFutureRelative: false
        )

        let japanese = MemoryAnchorExpressionResolver.renderedText(
            subjectText: "Baby",
            anchorTitle: "Birthday",
            anchorType: .birthday,
            expressionStyle: .birthdayGrowth,
            relativeSnapshot: snapshot,
            language: .japanese
        )
        let korean = MemoryAnchorExpressionResolver.renderedText(
            subjectText: "Baby",
            anchorTitle: "Birthday",
            anchorType: .birthday,
            expressionStyle: .birthdayGrowth,
            relativeSnapshot: snapshot,
            language: .korean
        )

        #expect(japanese == "今日はBabyが1歳3か月2日です")
        #expect(korean == "오늘 Baby는 1년 3개월 2일입니다")
        #expect(!japanese.contains("今天"))
        #expect(!korean.contains("今天"))
    }

    private func utcCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }
}
