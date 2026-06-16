import Foundation

final class AnchorEngine {

    private let calendar = Calendar.current

    func build(from anchor: Anchor) -> AnchorResult {

        if anchor.isCountdown {

            return AnchorResult(
                title: anchor.title,
                primaryText: "\(daysUntil(from: anchor)) Days Left",
                secondaryText: formattedDate(anchor.date)
            )
        }

        switch anchor.type {

        case .birthday:

            return AnchorResult(
                title: anchor.title,
                primaryText: "\(age(from: anchor) ?? 0) Years",
                secondaryText: "\(daysSince(from: anchor)) Days"
            )

        case .relationship, .marriage, .custom:

            let years = completedYears(from: anchor)

            return AnchorResult(
                title: anchor.title,
                primaryText: "\(years) Years",
                secondaryText: "\(daysSince(from: anchor)) Days"
            )
        }
    }

    func age(from anchor: Anchor) -> Int? {

        guard anchor.type == .birthday else {
            return nil
        }

        return calendar.dateComponents(
            [.year],
            from: anchor.date,
            to: Date()
        ).year
    }

    func completedYears(from anchor: Anchor) -> Int {

        calendar.dateComponents(
            [.year],
            from: anchor.date,
            to: Date()
        ).year ?? 0
    }

    func daysSince(from anchor: Anchor) -> Int {

        max(
            0,
            calendar.dateComponents(
                [.day],
                from: anchor.date,
                to: Date()
            ).day ?? 0
        )
    }

    func daysUntil(from anchor: Anchor) -> Int {

        max(
            0,
            calendar.dateComponents(
                [.day],
                from: Date(),
                to: anchor.date
            ).day ?? 0
        )
    }

    private func formattedDate(_ date: Date) -> String {

        let formatter = DateFormatter()

        formatter.dateStyle = .medium

        return formatter.string(from: date)
    }
}
