import Foundation

#if !PHOTOMEMO_SHARE_EXTENSION
extension MemoryAnchorRelativeSnapshot {

    func ageText(
        language: MemoMarkLanguage
    ) -> String {
        switch language {
        case .simplifiedChinese:
            return ageText
        case .english:
            return englishComponents(
                includeZeroValues: false,
                emptyValue: "0 days"
            )
        }
    }

    func durationText(
        language: MemoMarkLanguage
    ) -> String {
        switch language {
        case .simplifiedChinese:
            return durationText
        case .english:
            return englishComponents(
                includeZeroValues: false,
                emptyValue: "0 days"
            )
        }
    }

    func countdownText(
        language: MemoMarkLanguage
    ) -> String {
        switch language {
        case .simplifiedChinese:
            return countdownText
        case .english:
            let unit = englishUnit("day", value: totalDays)
            return "\(totalDays) \(unit) left"
        }
    }

    func countdownValueText(
        language: MemoMarkLanguage
    ) -> String {
        switch language {
        case .simplifiedChinese:
            return countdownValueText
        case .english:
            let unit = englishUnit("day", value: totalDays)
            return "\(totalDays) \(unit)"
        }
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

private extension MemoryAnchorRelativeSnapshot {

    func englishComponents(
        includeZeroValues: Bool,
        emptyValue: String
    ) -> String {
        let components = [
            englishComponent(
                years,
                singular: "year",
                includeZeroValues: includeZeroValues
            ),
            englishComponent(
                months,
                singular: "month",
                includeZeroValues: includeZeroValues
            ),
            englishComponent(
                days,
                singular: "day",
                includeZeroValues: includeZeroValues
            )
        ]
        .compactMap { $0 }

        guard !components.isEmpty else {
            return emptyValue
        }

        if components.count == 1 {
            return components[0]
        }

        if components.count == 2 {
            return components.joined(separator: " and ")
        }

        return components.dropLast().joined(separator: ", ")
            + ", and "
            + (components.last ?? "")
    }

    func englishComponent(
        _ value: Int,
        singular: String,
        includeZeroValues: Bool
    ) -> String? {
        guard includeZeroValues || value > 0 else {
            return nil
        }

        return "\(value) \(englishUnit(singular, value: value))"
    }

    func englishUnit(
        _ singular: String,
        value: Int
    ) -> String {
        value == 1
            ? singular
            : "\(singular)s"
    }
}
#endif
