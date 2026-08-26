import Foundation
import Testing
@testable import MemoMark

@Suite("Memory narrative formatter")
struct MemoryNarrativeFormatterTests {

    @Test("Formats birth day as an explicit narrative occurrence")
    func formatsBirthDayOccurrence() {
        #expect(
            MemoryNarrativeFormatter.birthDayLabel(
                language: .simplifiedChinese
            ) == "出生当天"
        )
        #expect(
            MemoryNarrativeFormatter.birthDayLabel(
                language: .english
            ) == "Day of birth"
        )
        #expect(
            MemoryNarrativeFormatter.birthDayLabel(
                language: .japanese
            ) == "生まれた日"
        )
        #expect(
            MemoryNarrativeFormatter.birthDayLabel(
                language: .korean
            ) == "태어난 날"
        )

        #expect(
            MemoryNarrativeFormatter.format(
                context: context(
                    language: .simplifiedChinese,
                    anchorType: .birthday,
                    occurrence: .birthDay,
                    subject: "宝宝"
                )
            ) == "宝宝今天来到这个世界啦！"
        )
        #expect(
            MemoryNarrativeFormatter.format(
                context: context(
                    language: .english,
                    anchorType: .birthday,
                    occurrence: .birthDay,
                    subject: "Baby"
                )
            ) == "Baby arrived in the world today"
        )
        #expect(
            MemoryNarrativeFormatter.format(
                context: context(
                    language: .japanese,
                    anchorType: .birthday,
                    occurrence: .birthDay,
                    subject: "Baby"
                )
            ) == "Babyが生まれた日"
        )
        #expect(
            MemoryNarrativeFormatter.format(
                context: context(
                    language: .korean,
                    anchorType: .birthday,
                    occurrence: .birthDay,
                    subject: "Baby"
                )
            ) == "Baby가 태어난 날"
        )
    }

    @Test("Formats elapsed birthday time by reusing age components")
    func formatsElapsedBirthdayTime() {
        let age = MemoryAgeComponents(years: 1, months: 3, days: 2)

        #expect(
            MemoryNarrativeFormatter.format(
                context: context(
                    language: .simplifiedChinese,
                    anchorType: .birthday,
                    occurrence: .elapsed,
                    subject: "宝宝",
                    ageComponents: age
                )
            ) == "今天宝宝1岁3个月2天啦！"
        )
        #expect(
            MemoryNarrativeFormatter.format(
                context: context(
                    language: .english,
                    anchorType: .birthday,
                    occurrence: .elapsed,
                    subject: "Baby",
                    ageComponents: age
                )
            ) == "Baby is 1 year, 3 months, and 2 days old today"
        )
        #expect(
            MemoryNarrativeFormatter.format(
                context: context(
                    language: .japanese,
                    anchorType: .birthday,
                    occurrence: .elapsed,
                    subject: "Baby",
                    ageComponents: age
                )
            ) == "今日はBabyが1歳3か月2日です"
        )
        #expect(
            MemoryNarrativeFormatter.format(
                context: context(
                    language: .korean,
                    anchorType: .birthday,
                    occurrence: .elapsed,
                    subject: "Baby",
                    ageComponents: age
                )
            ) == "오늘 Baby는 1년 3개월 2일입니다"
        )
    }

    @Test("Formats future birthday countdown without recalculating days")
    func formatsFutureBirthdayCountdown() {
        let countdown = MemoryCountdownComponents(totalDays: 86)

        #expect(
            MemoryNarrativeFormatter.format(
                context: context(
                    language: .simplifiedChinese,
                    anchorType: .birthday,
                    occurrence: .countdown,
                    subject: "宝宝",
                    countdownComponents: countdown
                )
            ) == "还有86天，宝宝就要出生了"
        )
        #expect(
            MemoryNarrativeFormatter.format(
                context: context(
                    language: .english,
                    anchorType: .birthday,
                    occurrence: .countdown,
                    subject: "Baby",
                    countdownComponents: countdown
                )
            ) == "86 days until Baby arrives"
        )
        #expect(
            MemoryNarrativeFormatter.format(
                context: context(
                    language: .japanese,
                    anchorType: .birthday,
                    occurrence: .countdown,
                    subject: "Baby",
                    countdownComponents: countdown
                )
            ) == "あと86日でBabyが生まれます"
        )
        #expect(
            MemoryNarrativeFormatter.format(
                context: context(
                    language: .korean,
                    anchorType: .birthday,
                    occurrence: .countdown,
                    subject: "Baby",
                    countdownComponents: countdown
                )
            ) == "86일 후 Baby가 태어납니다"
        )
    }

    @Test("Formats an anchor day without treating it as a zero-day duration")
    func formatsAnchorDayOccurrence() {
        #expect(
            MemoryNarrativeFormatter.format(
                context: context(
                    language: .simplifiedChinese,
                    anchorType: .relationship,
                    occurrence: .anchorDay,
                    subject: "我们",
                    anchorTitle: "第一次见面"
                )
            ) == "今天是第一次见面"
        )
        #expect(
            MemoryNarrativeFormatter.format(
                context: context(
                    language: .english,
                    anchorType: .relationship,
                    occurrence: .anchorDay,
                    subject: "us",
                    anchorTitle: "Our first meeting"
                )
            ) == "Today is Our first meeting"
        )
        #expect(
            MemoryNarrativeFormatter.format(
                context: context(
                    language: .japanese,
                    anchorType: .relationship,
                    occurrence: .anchorDay,
                    subject: "私たち",
                    anchorTitle: "初めて会った日"
                )
            ) == "今日は初めて会った日"
        )
        #expect(
            MemoryNarrativeFormatter.format(
                context: context(
                    language: .korean,
                    anchorType: .relationship,
                    occurrence: .anchorDay,
                    subject: "우리",
                    anchorTitle: "처음 만난 날"
                )
            ) == "오늘은 처음 만난 날"
        )
    }

    @Test("Formats an anniversary occurrence explicitly")
    func formatsAnniversaryOccurrence() {
        let occurrence = MemoryAnchorAnnualOccurrence(
            date: Date(timeIntervalSince1970: 0),
            yearsAtOccurrence: 3,
            daysUntilOccurrence: 0
        )

        #expect(
            MemoryNarrativeFormatter.format(
                context: context(
                    language: .simplifiedChinese,
                    anchorType: .marriage,
                    occurrence: .anniversary,
                    subject: "我们",
                    anchorTitle: "结婚",
                    annualOccurrence: occurrence
                )
            ) == "今天是结婚3周年"
        )
        #expect(
            MemoryNarrativeFormatter.format(
                context: context(
                    language: .english,
                    anchorType: .marriage,
                    occurrence: .anniversary,
                    subject: "us",
                    anchorTitle: "our wedding",
                    annualOccurrence: occurrence
                )
            ) == "Today marks 3 years of marriage"
        )
        #expect(
            MemoryNarrativeFormatter.format(
                context: context(
                    language: .japanese,
                    anchorType: .marriage,
                    occurrence: .anniversary,
                    subject: "私たち",
                    anchorTitle: "結婚",
                    annualOccurrence: occurrence
                )
            ) == "今日は結婚3周年です"
        )
        #expect(
            MemoryNarrativeFormatter.format(
                context: context(
                    language: .korean,
                    anchorType: .marriage,
                    occurrence: .anniversary,
                    subject: "우리",
                    anchorTitle: "결혼",
                    annualOccurrence: occurrence
                )
        ) == "오늘은 결혼 3주년입니다"
        )
    }

    @MainActor
    @Test("Uses explicit output language independently from interface language")
    func usesExplicitOutputLanguageIndependentlyFromInterfaceLanguage() {
        let defaults = MemoMarkSharedContainer.sharedUserDefaults
        let key = MemoMarkLanguage.interfacePreferenceStorageKey
        let previousValue = defaults.object(forKey: key)
        defer {
            if let previousValue {
                defaults.set(previousValue, forKey: key)
            } else {
                defaults.removeObject(forKey: key)
            }
        }

        MemoMarkLanguage.persistInterfacePreference(.simplifiedChinese)
        let japaneseOutput = MemoryNarrativeFormatter.format(
            context: context(
                language: .japanese,
                anchorType: .birthday,
                occurrence: .elapsed,
                subject: "Baby",
                ageComponents: MemoryAgeComponents(
                    years: 1,
                    months: 3,
                    days: 2
                )
            )
        )

        MemoMarkLanguage.persistInterfacePreference(.english)
        #expect(
            japaneseOutput == "今日はBabyが1歳3か月2日です"
        )
    }

    private func context(
        language: MemoMarkLanguage,
        anchorType: AnchorType,
        occurrence: MemoryNarrativeOccurrence,
        subject: String,
        anchorTitle: String = "出生",
        ageComponents: MemoryAgeComponents? = nil,
        durationComponents: MemoryDurationComponents? = nil,
        countdownComponents: MemoryCountdownComponents? = nil,
        annualOccurrence: MemoryAnchorAnnualOccurrence? = nil
    ) -> MemoryNarrativeContext {
        MemoryNarrativeContext(
            anchorType: anchorType,
            subjectDisplayName: subject,
            anchorTitle: anchorTitle,
            occurrence: occurrence,
            ageComponents: ageComponents,
            durationComponents: durationComponents,
            countdownComponents: countdownComponents,
            annualOccurrence: annualOccurrence,
            expressionStyle: nil,
            captureDate: nil,
            language: language
        )
    }
}
