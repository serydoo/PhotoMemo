import Foundation

final class AnchorEngine {

    private let calendar = Calendar.current

    func build(
        from anchor: Anchor,
        photoDate: Date = Date()
    ) -> AnchorResult {

        if photoDate < anchor.date {

            return buildFutureResult(
                from: anchor,
                photoDate: photoDate
            )
        }

        if anchor.isCountdown {

            return buildPastCountdownResult(
                from: anchor,
                photoDate: photoDate
            )
        }

        let metrics = metrics(
            from: anchor.date,
            to: photoDate
        )

        let durationText =
            durationText(from: metrics)

        let ageText =
            ageText(from: metrics)

        switch anchor.type {

        case .birthday:

            return AnchorResult(
                title: anchor.title,
                primaryText:
                    ageText.isEmpty
                    ? durationText
                    : ageText,
                secondaryText:
                    durationText.isEmpty
                    ? formattedDateTime(anchor.date)
                    : durationText,
                summaryText:
                    anchor.title.isEmpty
                    ? ageText
                    : "\(anchor.title)今天\(ageText)",
                ageText: ageText,
                durationText: durationText,
                years: metrics.years,
                months: metrics.months,
                days: metrics.days,
                hours: metrics.hours,
                minutes: metrics.minutes,
                seconds: metrics.seconds,
                totalDays: metrics.totalDays
            )

        case .relationship,
             .marriage,
             .custom,
             .exam:

            return AnchorResult(
                title: anchor.title,
                primaryText: durationText,
                secondaryText: formattedDateTime(anchor.date),
                summaryText:
                    anchor.title.isEmpty
                    ? durationText
                    : "\(anchor.title)\(durationText)",
                ageText: ageText,
                durationText: durationText,
                years: metrics.years,
                months: metrics.months,
                days: metrics.days,
                hours: metrics.hours,
                minutes: metrics.minutes,
                seconds: metrics.seconds,
                totalDays: metrics.totalDays
            )
        }
    }
}

private extension AnchorEngine {

    func buildFutureResult(
        from anchor: Anchor,
        photoDate: Date
    ) -> AnchorResult {

        let metrics = metrics(
            from: photoDate,
            to: anchor.date
        )

        let countdownText =
            durationText(
                from: metrics,
                includeTime: anchor.isCountdown
            )

        let primary =
            countdownText.isEmpty
            ? "0天"
            : countdownText

        return AnchorResult(
            title: anchor.title,
            primaryText: primary,
            secondaryText: formattedDateTime(anchor.date),
            summaryText:
                anchor.title.isEmpty
                ? "还有\(primary)"
                : "\(anchor.title)还有\(primary)",
            ageText: "",
            durationText: primary,
            years: metrics.years,
            months: metrics.months,
            days: metrics.days,
            hours: metrics.hours,
            minutes: metrics.minutes,
            seconds: metrics.seconds,
            totalDays: metrics.totalDays
        )
    }

    func buildPastCountdownResult(
        from anchor: Anchor,
        photoDate: Date
    ) -> AnchorResult {

        let metrics = metrics(
            from: anchor.date,
            to: photoDate
        )

        let countdownText =
            durationText(
                from: metrics,
                includeTime: true
            )

        let primary =
            countdownText.isEmpty
            ? "0天"
            : countdownText

        return AnchorResult(
            title: anchor.title,
            primaryText: primary,
            secondaryText: formattedDateTime(anchor.date),
            summaryText:
                anchor.title.isEmpty
                ? "已过\(primary)"
                : "\(anchor.title)已过\(primary)",
            ageText: "",
            durationText: primary,
            years: metrics.years,
            months: metrics.months,
            days: metrics.days,
            hours: metrics.hours,
            minutes: metrics.minutes,
            seconds: metrics.seconds,
            totalDays: metrics.totalDays
        )
    }

    private func formattedDateTime(
        _ date: Date
    ) -> String {

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy.MM.dd HH:mm"

        return formatter.string(from: date)
    }

    private func metrics(
        from startDate: Date,
        to endDate: Date
    ) -> AnchorMetrics {

        guard endDate >= startDate else {
            return AnchorMetrics()
        }

        let components = calendar.dateComponents(
            [
                .year,
                .month,
                .day,
                .hour,
                .minute,
                .second
            ],
            from: startDate,
            to: endDate
        )

        let totalDays =
            calendar.dateComponents(
                [.day],
                from: startDate,
                to: endDate
            ).day ?? 0

        return AnchorMetrics(
            years: components.year ?? 0,
            months: components.month ?? 0,
            days: components.day ?? 0,
            hours: components.hour ?? 0,
            minutes: components.minute ?? 0,
            seconds: components.second ?? 0,
            totalDays: totalDays
        )
    }

    private func ageText(
        from metrics: AnchorMetrics
    ) -> String {

        let parts = [
            metrics.years > 0 ? "\(metrics.years)岁" : nil,
            metrics.months > 0 ? "\(metrics.months)个月" : nil,
            metrics.days > 0 && metrics.years == 0
                ? "\(metrics.days)天"
                : nil
        ]
        .compactMap { $0 }

        if !parts.isEmpty {
            return parts.joined()
        }

        if metrics.hours > 0 {
            return "\(metrics.hours)小时"
        }

        if metrics.minutes > 0 {
            return "\(metrics.minutes)分钟"
        }

        return "\(metrics.seconds)秒"
    }

    private func durationText(
        from metrics: AnchorMetrics,
        includeTime: Bool = false
    ) -> String {

        var parts = [
            metrics.years > 0 ? "\(metrics.years)年" : nil,
            metrics.months > 0 ? "\(metrics.months)个月" : nil,
            metrics.days > 0 ? "\(metrics.days)天" : nil
        ]
        .compactMap { $0 }

        if includeTime || parts.isEmpty {

            if metrics.hours > 0 {
                parts.append("\(metrics.hours)小时")
            }

            if metrics.minutes > 0 {
                parts.append("\(metrics.minutes)分钟")
            }

            if parts.isEmpty || metrics.seconds > 0 {
                parts.append("\(metrics.seconds)秒")
            }
        }

        return parts.joined()
    }
}

private struct AnchorMetrics {

    var years: Int = 0

    var months: Int = 0

    var days: Int = 0

    var hours: Int = 0

    var minutes: Int = 0

    var seconds: Int = 0

    var totalDays: Int = 0
}
