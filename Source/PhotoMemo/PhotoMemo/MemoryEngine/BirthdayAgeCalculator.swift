import Foundation

#if !PHOTOMEMO_SHARE_EXTENSION
struct BirthdayAgeCalculator:
    MemoryCalculator {

    func calculate(
        context: MemoryExpressionContext,
        anchor: MemoryAnchor
    ) -> MemorySemanticResult? {
        guard let captureDate =
            context.captureDate
        else {
            return nil
        }

        let calendar = Calendar.current

        guard captureDate >= anchor.date else {
            return nil
        }

        let components =
            calendar.dateComponents(
                [.year, .month, .day],
                from: anchor.date,
                to: captureDate
            )

        let years = max(components.year ?? 0, 0)
        let months = max(components.month ?? 0, 0)
        let days = max(components.day ?? 0, 0)

        let displayText: String
        if years > 0 {
            displayText =
                "\(years)年\(months)个月\(days)天"
        } else if months > 0 {
            displayText =
                "\(months)个月\(days)天"
        } else {
            displayText =
                "\(days)天"
        }

        return MemorySemanticResult(
            kind: .birthdayAge,
            displayText: displayText
        )
    }
}
#endif
