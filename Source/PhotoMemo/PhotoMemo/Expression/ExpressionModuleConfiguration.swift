import Foundation

nonisolated struct ExpressionModuleConfiguration:
    Codable,
    Hashable {

    var token: ExpressionToken
    var options: [String: String]

    init(
        token: ExpressionToken,
        options: [String: String] = [:]
    ) {
        self.token = token
        self.options = options
    }
}

nonisolated struct TimeDisplayConfiguration: Codable, Hashable {
    enum BaseStyle: String, Codable, CaseIterable { case daily, precise, minimal, photography, weekdayContext }
    enum Supplement: String, Codable, CaseIterable { case none, lunar, lunarAndSolarTerm, holiday, statutoryHoliday }
    var baseStyle: BaseStyle
    var supplement: Supplement
    init(baseStyle: BaseStyle = .daily, supplement: Supplement = .none) {
        self.baseStyle = baseStyle
        self.supplement = supplement
    }
}

struct TimeExpressionProvider {
    static let timeToken = ExpressionToken(rawValue: "capture_time")

    static func dateText(
        for date: Date,
        configuration: TimeDisplayConfiguration,
        timeZone: TimeZone? = nil,
        language: MemoMarkLanguage = .stored
    ) -> String {
        let format: String
        switch configuration.baseStyle {
        case .daily:
            format = language == .simplifiedChinese
                ? "yyyy年M月d日 EEEE"
                : "MMM d, yyyy EEEE"
        case .precise, .minimal:
            format = "yyyy.MM.dd"
        case .photography:
            format = "dd MMM yyyy"
        case .weekdayContext:
            format = language == .simplifiedChinese
                ? "yyyy年M月d日"
                : "MMM d, yyyy"
        }

        let base = formattedDate(
            date,
            format: format,
            timeZone: timeZone,
            language: language
        )
        let additions = supplementText(
            for: date,
            supplement: configuration.supplement,
            calendar: calendar(timeZone: timeZone),
            language: language
        )

        return ([base] + additions).joined(separator: " · ")
    }

    static func timeText(
        for date: Date,
        configuration: TimeDisplayConfiguration,
        timeZone: TimeZone? = nil,
        language: MemoMarkLanguage = .stored
    ) -> String {
        let format: String
        switch configuration.baseStyle {
        case .daily:
            format = "a h:mm"
        case .precise:
            format = "HH:mm:ss"
        case .minimal, .photography:
            format = "HH:mm"
        case .weekdayContext:
            format = "EEE"
        }

        return formattedDate(
            date,
            format: format,
            timeZone: timeZone,
            language: language
        )
    }

    private static func formattedDate(
        _ date: Date,
        format: String,
        timeZone: TimeZone?,
        language: MemoMarkLanguage
    ) -> String {
        let formatter = DateFormatter()
        formatter.locale = language.locale
        formatter.timeZone = timeZone
        formatter.dateFormat = format
        return formatter.string(from: date)
    }

    private static func calendar(timeZone: TimeZone?) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        if let timeZone {
            calendar.timeZone = timeZone
        }
        return calendar
    }

    static func compose(base: String, lunar: String?, solarTerm: String?, holiday: String?, statutoryHoliday: String?, separator: String = " · ") -> String {
        [base, lunar, solarTerm, holiday, statutoryHoliday].compactMap { value in
            guard let value, !value.isEmpty else { return nil }
            return value
        }.joined(separator: separator)
    }

    static func supplementText(
        for date: Date,
        supplement: TimeDisplayConfiguration.Supplement,
        calendar: Calendar = .current,
        language: MemoMarkLanguage = .stored
    ) -> [String] {
        var values: [String] = []
        if supplement == .lunar || supplement == .lunarAndSolarTerm {
            var chinese = Calendar(identifier: .chinese)
            chinese.locale = Locale(identifier: "zh_CN")
            let components = chinese.dateComponents([.month, .day], from: date)
            if let month = components.month, let day = components.day {
                values.append(
                    language == .simplifiedChinese
                    ? "农历\(chineseMonthName(month))月\(chineseDayName(day))"
                    : "Lunar \(month)/\(day)"
                )
            }
        }
        if supplement == .lunarAndSolarTerm, let term = solarTerm(for: date, calendar: calendar) {
            values.append(localizedSupplement(term, language: language))
        }
        if supplement == .holiday, let holiday = holidayName(for: date, calendar: calendar) {
            values.append(localizedSupplement(holiday, language: language))
        }
        if supplement == .statutoryHoliday, let holiday = statutoryHolidayName(for: date, calendar: calendar) {
            values.append(localizedSupplement(holiday, language: language))
        }
        return values
    }

    private static func localizedSupplement(
        _ value: String,
        language: MemoMarkLanguage
    ) -> String {
        guard language == .english else {
            return value
        }
        let translations = [
            "元旦": "New Year's Day",
            "春节": "Spring Festival",
            "清明节": "Qingming Festival",
            "端午节": "Dragon Boat Festival",
            "中秋节": "Mid-Autumn Festival",
            "劳动节": "Labor Day",
            "国庆节": "National Day",
            "元旦假期": "New Year holiday",
            "清明假期": "Qingming holiday",
            "端午假期": "Dragon Boat holiday",
            "中秋假期": "Mid-Autumn holiday",
            "劳动节假期": "Labor Day holiday",
            "国庆节假期": "National Day holiday",
            "国庆假期": "National Day holiday",
            "小寒": "Minor Cold", "大寒": "Major Cold",
            "立春": "Start of Spring", "雨水": "Rain Water",
            "惊蛰": "Awakening of Insects", "春分": "Spring Equinox",
            "清明": "Clear and Bright", "谷雨": "Grain Rain",
            "立夏": "Start of Summer", "小满": "Grain Buds",
            "芒种": "Grain in Ear", "夏至": "Summer Solstice",
            "小暑": "Minor Heat", "大暑": "Major Heat",
            "立秋": "Start of Autumn", "处暑": "End of Heat",
            "白露": "White Dew", "秋分": "Autumn Equinox",
            "寒露": "Cold Dew", "霜降": "Frost's Descent",
            "立冬": "Start of Winter", "小雪": "Minor Snow",
            "大雪": "Major Snow", "冬至": "Winter Solstice"
        ]
        return translations[value] ?? value
    }

    private static func chineseMonthName(_ month: Int) -> String {
        ["正", "二", "三", "四", "五", "六", "七", "八", "九", "十", "十一", "十二"][max(1, min(month, 12)) - 1]
    }

    private static func chineseDayName(_ day: Int) -> String {
        let digits = ["初一", "初二", "初三", "初四", "初五", "初六", "初七", "初八", "初九", "初十", "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十", "廿一", "廿二", "廿三", "廿四", "廿五", "廿六", "廿七", "廿八", "廿九", "三十"]
        return digits[max(1, min(day, digits.count)) - 1]
    }

    private static func solarTerm(for date: Date, calendar: Calendar) -> String? {
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        let known: [String: String] = [
            "2026-1-5": "小寒", "2026-1-20": "大寒", "2026-2-4": "立春", "2026-2-19": "雨水",
            "2026-3-5": "惊蛰", "2026-3-20": "春分", "2026-4-5": "清明", "2026-4-20": "谷雨",
            "2026-5-5": "立夏", "2026-5-21": "小满", "2026-6-5": "芒种", "2026-6-21": "夏至",
            "2026-7-7": "小暑", "2026-7-23": "大暑", "2026-8-7": "立秋", "2026-8-23": "处暑",
            "2026-9-7": "白露", "2026-9-23": "秋分", "2026-10-8": "寒露", "2026-10-23": "霜降",
            "2026-11-7": "立冬", "2026-11-22": "小雪", "2026-12-7": "大雪", "2026-12-21": "冬至"
        ]
        return known["\(year)-\(month)-\(day)"]
    }

    private static func holidayName(for date: Date, calendar: Calendar) -> String? {
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        let chinese = Calendar(identifier: .chinese)
        let lunarMonth = chinese.component(.month, from: date)
        let lunarDay = chinese.component(.day, from: date)
        if lunarMonth == 1 && lunarDay == 1 { return "春节" }
        if lunarMonth == 5 && lunarDay == 5 { return "端午节" }
        if lunarMonth == 8 && lunarDay == 15 { return "中秋节" }
        if month == 1 && day == 1 { return "元旦" }
        if month == 5 && day == 1 { return "劳动节" }
        if month == 10 && day == 1 { return "国庆节" }
        return nil
    }

    private static func statutoryHolidayName(for date: Date, calendar: Calendar) -> String? {
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        if year == 2026 && month == 1 && (1...3).contains(day) { return "元旦假期" }
        if year == 2026 && month == 4 && (4...6).contains(day) { return "清明假期" }
        if year == 2026 && month == 5 && (1...5).contains(day) { return "劳动节假期" }
        if year == 2026 && month == 6 && (19...21).contains(day) { return "端午假期" }
        if year == 2026 && month == 9 && (25...27).contains(day) { return "中秋假期" }
        if year == 2026 && month == 10 && (1...7).contains(day) { return "国庆假期" }
        return nil
    }
}
