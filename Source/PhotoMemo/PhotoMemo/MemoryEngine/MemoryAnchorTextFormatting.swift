import Foundation

#if !PHOTOMEMO_SHARE_EXTENSION
extension MemoryAnchorRelativeSnapshot {

    func ageText(
        language: MemoMarkLanguage
    ) -> String {
        MemoryAgeFormatter.format(
            MemoryAgeComponents(
                years: years,
                months: months,
                days: days
            ),
            language: language
        )
    }

    func durationText(
        language: MemoMarkLanguage
    ) -> String {
        MemoryDurationFormatter.format(
            MemoryDurationComponents(
                years: years,
                months: months,
                days: days,
                totalDays: totalDays
            ),
            language: language
        )
    }

    func countdownText(
        language: MemoMarkLanguage
    ) -> String {
        let value = countdownValueText(language: language)

        switch language {
        case .simplifiedChinese:
            return "还有\(value)"
        case .english:
            return "\(value) left"
        case .japanese:
            return "あと\(value)"
        case .korean:
            return "\(value) 남음"
        }
    }

    func countdownValueText(
        language: MemoMarkLanguage
    ) -> String {
        MemoryCountdownFormatter.format(
            MemoryCountdownComponents(totalDays: totalDays),
            language: language
        )
    }
}

extension MemoryAnchorAnnualOccurrence {

    var englishCountdownValueText: String {
        let unit = daysUntilOccurrence == 1 ? "day" : "days"
        return "\(daysUntilOccurrence) \(unit)"
    }

    var englishBirthdayText: String {
        "\(englishOrdinal(yearsAtOccurrence)) birthday"
    }

    var englishAnniversaryText: String {
        "\(englishOrdinal(yearsAtOccurrence)) anniversary"
    }
}

private func englishOrdinal(_ value: Int) -> String {
    let suffix: String
    switch value % 100 {
    case 11, 12, 13:
        suffix = "th"
    default:
        switch value % 10 {
        case 1:
            suffix = "st"
        case 2:
            suffix = "nd"
        case 3:
            suffix = "rd"
        default:
            suffix = "th"
        }
    }
    return "\(value)\(suffix)"
}

#endif
