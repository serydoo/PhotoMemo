import Foundation
import Testing
@testable import MemoMark

@Suite("Memory time formatter")
struct MemoryTimeFormatterTests {

    @Test("Formats age components without narrative text")
    func formatsAgeComponentsWithoutNarrativeText() {
        let age = MemoryAgeComponents(
            years: 1,
            months: 3,
            days: 2
        )

        #expect(
            MemoryAgeFormatter.format(
                age,
                language: .simplifiedChinese
            ) == "1岁3个月2天"
        )
        #expect(
            MemoryAgeFormatter.format(
                age,
                language: .english
            ) == "1 year, 3 months, and 2 days"
        )
        #expect(
            MemoryAgeFormatter.format(
                age,
                language: .japanese
            ) == "1歳3か月2日"
        )
        #expect(
            MemoryAgeFormatter.format(
                age,
                language: .korean
            ) == "1년 3개월 2일"
        )
    }

    @Test("Age formatter clamps negative components and formats zero")
    func ageFormatterClampsNegativeComponentsAndFormatsZero() {
        let age = MemoryAgeComponents(
            years: -1,
            months: -2,
            days: -3
        )

        #expect(
            MemoryAgeFormatter.format(
                age,
                language: .simplifiedChinese
            ) == "0天"
        )
        #expect(
            MemoryAgeFormatter.format(
                age,
                language: .english
            ) == "0 days"
        )
        #expect(
            MemoryAgeFormatter.format(
                age,
                language: .japanese
            ) == "0日"
        )
        #expect(
            MemoryAgeFormatter.format(
                age,
                language: .korean
            ) == "0일"
        )
    }

    @Test("Formats duration components independently from narrative")
    func formatsDurationComponentsIndependentlyFromNarrative() {
        let duration = MemoryDurationComponents(
            years: 0,
            months: 0,
            days: 365,
            totalDays: 365
        )

        #expect(
            MemoryDurationFormatter.format(
                duration,
                language: .simplifiedChinese
            ) == "365天"
        )
        #expect(
            MemoryDurationFormatter.format(
                duration,
                language: .english
            ) == "365 days"
        )
        #expect(
            MemoryDurationFormatter.format(
                duration,
                language: .japanese
            ) == "365日"
        )
        #expect(
            MemoryDurationFormatter.format(
                duration,
                language: .korean
            ) == "365일"
        )
    }

    @Test("Formats countdown as a value fragment")
    func formatsCountdownAsAValueFragment() {
        let countdown = MemoryCountdownComponents(totalDays: 86)

        #expect(
            MemoryCountdownFormatter.format(
                countdown,
                language: .simplifiedChinese
            ) == "86天"
        )
        #expect(
            MemoryCountdownFormatter.format(
                countdown,
                language: .english
            ) == "86 days"
        )
        #expect(
            MemoryCountdownFormatter.format(
                countdown,
                language: .japanese
            ) == "86日"
        )
        #expect(
            MemoryCountdownFormatter.format(
                countdown,
                language: .korean
            ) == "86일"
        )
    }

    @Test("Date formatter uses the explicit output language locale")
    func dateFormatterUsesExplicitOutputLanguageLocale() throws {
        let timeZone = try #require(
            TimeZone(secondsFromGMT: 8 * 60 * 60)
        )
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let date = try #require(
            calendar.date(
                from: DateComponents(
                    timeZone: timeZone,
                    year: 2026,
                    month: 8,
                    day: 18,
                    hour: 9,
                    minute: 30
                )
            )
        )

        let englishDate = MemoryDateFormatter.dateText(
            date,
            language: .english,
            timeZone: timeZone
        )
        let japaneseDate = MemoryDateFormatter.dateText(
            date,
            language: .japanese,
            timeZone: timeZone
        )
        let englishWeekday = MemoryDateFormatter.weekdayText(
            date,
            language: .english,
            timeZone: timeZone
        )
        let japaneseWeekday = MemoryDateFormatter.weekdayText(
            date,
            language: .japanese,
            timeZone: timeZone
        )

        #expect(!englishDate.isEmpty)
        #expect(!japaneseDate.isEmpty)
        #expect(englishDate != japaneseDate)
        #expect(englishWeekday == "Tuesday")
        #expect(japaneseWeekday == "火曜日")
    }
}
