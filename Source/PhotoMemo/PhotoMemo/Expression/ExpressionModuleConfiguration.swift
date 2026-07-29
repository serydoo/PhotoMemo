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
    static func compose(base: String, lunar: String?, solarTerm: String?, holiday: String?, statutoryHoliday: String?, separator: String = " · ") -> String {
        [base, lunar, solarTerm, holiday, statutoryHoliday].compactMap { value in
            guard let value, !value.isEmpty else { return nil }
            return value
        }.joined(separator: separator)
    }

    static func supplementText(
        for date: Date,
        supplement: TimeDisplayConfiguration.Supplement,
        calendar: Calendar = .current
    ) -> [String] {
        var values: [String] = []
        if supplement == .lunar || supplement == .lunarAndSolarTerm {
            var chinese = Calendar(identifier: .chinese)
            chinese.locale = Locale(identifier: "zh_CN")
            let components = chinese.dateComponents([.month, .day], from: date)
            if let month = components.month, let day = components.day {
                values.append("农历\(chineseMonthName(month))月\(chineseDayName(day))")
            }
        }
        if supplement == .lunarAndSolarTerm, let term = solarTerm(for: date, calendar: calendar) {
            values.append(term)
        }
        if supplement == .holiday, let holiday = holidayName(for: date, calendar: calendar) {
            values.append(holiday)
        }
        if supplement == .statutoryHoliday, let holiday = statutoryHolidayName(for: date, calendar: calendar) {
            values.append(holiday)
        }
        return values
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
