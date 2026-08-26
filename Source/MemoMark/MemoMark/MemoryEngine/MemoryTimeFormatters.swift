import Foundation

struct MemoryAgeComponents: Hashable {

    let years: Int
    let months: Int
    let days: Int

    init(
        years: Int,
        months: Int,
        days: Int
    ) {
        self.years = max(years, 0)
        self.months = max(months, 0)
        self.days = max(days, 0)
    }
}

struct MemoryDurationComponents: Hashable {

    let years: Int
    let months: Int
    let days: Int
    let totalDays: Int

    init(
        years: Int,
        months: Int,
        days: Int,
        totalDays: Int
    ) {
        self.years = max(years, 0)
        self.months = max(months, 0)
        self.days = max(days, 0)
        self.totalDays = max(totalDays, 0)
    }
}

struct MemoryCountdownComponents: Hashable {

    let totalDays: Int

    init(totalDays: Int) {
        self.totalDays = max(totalDays, 0)
    }
}

enum MemoryAgeFormatter {

    static func format(
        _ components: MemoryAgeComponents,
        language: MemoMarkLanguage
    ) -> String {
        switch language {
        case .simplifiedChinese:
            return formatChinese(
                years: components.years,
                months: components.months,
                days: components.days,
                yearUnit: "岁"
            )
        case .english:
            return formatEnglish(
                years: components.years,
                months: components.months,
                days: components.days,
                yearUnit: "year"
            )
        case .japanese:
            return formatJapanese(
                years: components.years,
                months: components.months,
                days: components.days,
                yearUnit: "歳"
            )
        case .korean:
            return formatKorean(
                years: components.years,
                months: components.months,
                days: components.days,
                yearUnit: "년"
            )
        }
    }
}

enum MemoryDurationFormatter {

    static func format(
        _ components: MemoryDurationComponents,
        language: MemoMarkLanguage
    ) -> String {
        guard components.years > 0 || components.months > 0 else {
            return formatDayValue(
                components.totalDays > 0
                    ? components.totalDays
                    : components.days,
                language: language
            )
        }

        switch language {
        case .simplifiedChinese:
            return formatChinese(
                years: components.years,
                months: components.months,
                days: components.days,
                yearUnit: "年"
            )
        case .english:
            return formatEnglish(
                years: components.years,
                months: components.months,
                days: components.days,
                yearUnit: "year"
            )
        case .japanese:
            return formatJapanese(
                years: components.years,
                months: components.months,
                days: components.days,
                yearUnit: "年"
            )
        case .korean:
            return formatKorean(
                years: components.years,
                months: components.months,
                days: components.days,
                yearUnit: "년"
            )
        }
    }
}

enum MemoryCountdownFormatter {

    static func format(
        _ components: MemoryCountdownComponents,
        language: MemoMarkLanguage
    ) -> String {
        formatDayValue(components.totalDays, language: language)
    }
}

enum MemoryCountdownPhraseFormatter {

    static func format(
        totalDays: Int,
        language: MemoMarkLanguage
    ) -> String {
        let value = MemoryCountdownFormatter.format(
            MemoryCountdownComponents(totalDays: totalDays),
            language: language
        )

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
}

enum MemoryElapsedFormatter {

    static func format(
        totalDays: Int,
        language: MemoMarkLanguage
    ) -> String {
        let value = MemoryCountdownFormatter.format(
            MemoryCountdownComponents(totalDays: totalDays),
            language: language
        )

        switch language {
        case .simplifiedChinese:
            return "已过\(value)"
        case .english:
            return "\(value) elapsed"
        case .japanese:
            return "\(value)経過"
        case .korean:
            return "\(value) 경과"
        }
    }
}

enum MemoryDayIndexFormatter {

    static func format(
        totalDays: Int,
        language: MemoMarkLanguage
    ) -> String {
        let value = max(totalDays, 1)

        switch language {
        case .simplifiedChinese:
            return "第\(value)天"
        case .english:
            return "Day \(value)"
        case .japanese:
            return "\(value)日目"
        case .korean:
            return "\(value)일째"
        }
    }
}

enum MemoryWeekFormatter {

    static func format(
        totalDays: Int,
        language: MemoMarkLanguage
    ) -> String {
        let safeTotalDays = max(totalDays, 0)
        let weeks = safeTotalDays / 7
        let days = safeTotalDays % 7

        switch language {
        case .simplifiedChinese:
            if weeks == 0, days == 0 {
                return "0周"
            }
            if days == 0 {
                return "\(weeks)周"
            }
            return "\(weeks)周\(days)天"
        case .english:
            let weekValue = "\(weeks) \(weeks == 1 ? "week" : "weeks")"
            guard days > 0 else {
                return weekValue
            }
            return "\(weekValue) \(days) \(days == 1 ? "day" : "days")"
        case .japanese:
            if days == 0 {
                return "\(weeks)週間"
            }
            return "\(weeks)週間\(days)日"
        case .korean:
            if days == 0 {
                return "\(weeks)주"
            }
            return "\(weeks)주 \(days)일"
        }
    }
}

enum MemoryMonthAgeFormatter {

    static func format(
        totalMonths: Int,
        language: MemoMarkLanguage
    ) -> String {
        let value = max(totalMonths, 0)

        switch language {
        case .simplifiedChinese:
            return "\(value)个月"
        case .english:
            return "\(value) \(value == 1 ? "month" : "months")"
        case .japanese:
            return "\(value)か月"
        case .korean:
            return "\(value)개월"
        }
    }
}

enum MemoryMilestoneFormatter {

    static func birthdaySevenDays(
        language: MemoMarkLanguage
    ) -> String {
        switch language {
        case .simplifiedChinese:
            return "满7天"
        case .english:
            return "7 days old"
        case .japanese:
            return "生後7日"
        case .korean:
            return "태어난 지 7일"
        }
    }

    static func birthdayMonth(
        language: MemoMarkLanguage
    ) -> String {
        switch language {
        case .simplifiedChinese:
            return "满月"
        case .english:
            return "1 month old"
        case .japanese:
            return "生後1か月"
        case .korean:
            return "태어난 지 1개월"
        }
    }

    static func birthdayHundredDays(
        language: MemoMarkLanguage
    ) -> String {
        switch language {
        case .simplifiedChinese:
            return "百天"
        case .english:
            return "100 days old"
        case .japanese:
            return "生後100日"
        case .korean:
            return "태어난 지 100일"
        }
    }

    static func month(
        _ value: Int,
        language: MemoMarkLanguage
    ) -> String {
        switch language {
        case .simplifiedChinese:
            return "\(value)个月"
        case .english:
            return "\(value) \(value == 1 ? "month" : "months")"
        case .japanese:
            return "\(value)か月"
        case .korean:
            return "\(value)개월"
        }
    }

    static func anniversary(
        _ value: Int,
        language: MemoMarkLanguage
    ) -> String {
        switch language {
        case .simplifiedChinese:
            return "\(value)周年"
        case .english:
            return "\(value)-year anniversary"
        case .japanese:
            return "\(value)周年"
        case .korean:
            return "\(value)주년"
        }
    }

    static func day(
        _ value: Int,
        language: MemoMarkLanguage
    ) -> String {
        MemoryCountdownFormatter.format(
            MemoryCountdownComponents(totalDays: value),
            language: language
        )
    }
}

enum MemoryDateFormatter {

    static func dateText(
        _ date: Date,
        language: MemoMarkLanguage,
        timeZone: TimeZone
    ) -> String {
        formatted(
            date,
            template: "yMMMMd",
            language: language,
            timeZone: timeZone
        )
    }

    static func weekdayText(
        _ date: Date,
        language: MemoMarkLanguage,
        timeZone: TimeZone
    ) -> String {
        formatted(
            date,
            template: "EEEE",
            language: language,
            timeZone: timeZone
        )
    }

    private static func formatted(
        _ date: Date,
        template: String,
        language: MemoMarkLanguage,
        timeZone: TimeZone
    ) -> String {
        let formatter = Foundation.DateFormatter()
        formatter.locale = language.locale
        formatter.timeZone = timeZone
        formatter.setLocalizedDateFormatFromTemplate(template)
        return formatter.string(from: date)
    }
}

private func formatChinese(
    years: Int,
    months: Int,
    days: Int,
    yearUnit: String
) -> String {
    let parts = [
        years > 0 ? "\(years)\(yearUnit)" : nil,
        months > 0 ? "\(months)个月" : nil,
        days > 0 ? "\(days)天" : nil
    ]
    .compactMap { $0 }

    return parts.isEmpty ? "0天" : parts.joined()
}

private func formatEnglish(
    years: Int,
    months: Int,
    days: Int,
    yearUnit: String
) -> String {
    let parts = [
        englishComponent(years, singular: yearUnit),
        englishComponent(months, singular: "month"),
        englishComponent(days, singular: "day")
    ]
    .compactMap { $0 }

    guard !parts.isEmpty else {
        return "0 days"
    }

    switch parts.count {
    case 1:
        return parts[0]
    case 2:
        return parts.joined(separator: " and ")
    default:
        return parts.dropLast().joined(separator: ", ")
            + ", and "
            + (parts.last ?? "")
    }
}

private func formatJapanese(
    years: Int,
    months: Int,
    days: Int,
    yearUnit: String
) -> String {
    let parts = [
        years > 0 ? "\(years)\(yearUnit)" : nil,
        months > 0 ? "\(months)か月" : nil,
        days > 0 ? "\(days)日" : nil
    ]
    .compactMap { $0 }

    return parts.isEmpty ? "0日" : parts.joined()
}

private func formatKorean(
    years: Int,
    months: Int,
    days: Int,
    yearUnit: String
) -> String {
    let parts = [
        years > 0 ? "\(years)\(yearUnit)" : nil,
        months > 0 ? "\(months)개월" : nil,
        days > 0 ? "\(days)일" : nil
    ]
    .compactMap { $0 }

    return parts.isEmpty ? "0일" : parts.joined(separator: " ")
}

private func formatDayValue(
    _ value: Int,
    language: MemoMarkLanguage
) -> String {
    let value = max(value, 0)

    switch language {
    case .simplifiedChinese:
        return "\(value)天"
    case .english:
        return "\(value) \(value == 1 ? "day" : "days")"
    case .japanese:
        return "\(value)日"
    case .korean:
        return "\(value)일"
    }
}

private func englishComponent(
    _ value: Int,
    singular: String
) -> String? {
    guard value > 0 else {
        return nil
    }

    return "\(value) \(value == 1 ? singular : "\(singular)s")"
}
