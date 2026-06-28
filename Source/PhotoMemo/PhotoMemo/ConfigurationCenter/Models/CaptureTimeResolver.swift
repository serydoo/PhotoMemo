#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct CaptureTimeResolver {

    func resolve(
        captureDate: Date,
        referenceDate: Date,
        calendar: Calendar = .current
    ) -> DateComponents {
        let startDate =
            min(referenceDate, captureDate)

        let endDate =
            max(referenceDate, captureDate)

        return calendar.dateComponents(
            [.year, .month, .day],
            from: startDate,
            to: endDate
        )
    }

    func resolveText(
        captureDate: Date,
        referenceDate: Date,
        calendar: Calendar = .current
    ) -> String {
        let components =
            resolve(
                captureDate: captureDate,
                referenceDate: referenceDate,
                calendar: calendar
            )

        let years =
            max(components.year ?? 0, 0)
        let months =
            max(components.month ?? 0, 0)
        let days =
            max(components.day ?? 0, 0)

        if years > 0 {
            return "\(years)年\(months)个月\(days)天"
        }

        if months > 0 {
            return "\(months)个月\(days)天"
        }

        return "\(days)天"
    }
}
#endif
