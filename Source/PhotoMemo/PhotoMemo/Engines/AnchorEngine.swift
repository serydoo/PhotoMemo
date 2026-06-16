import Foundation

struct AnchorEngine {

    static func daysSince(_ date: Date) -> Int {
        Calendar.current.dateComponents(
            [.day],
            from: date,
            to: Date()
        ).day ?? 0
    }

    static func ageString(from birthday: Date) -> String {

        let components = Calendar.current.dateComponents(
            [.year, .month, .day],
            from: birthday,
            to: Date()
        )

        let year = components.year ?? 0
        let month = components.month ?? 0

        return "\(year)岁\(month)个月"
    }
}
