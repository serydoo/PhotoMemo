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

        let elapsedText =
            elapsedText(from: metrics.totalDays)

        let dayIndexText =
            dayIndexText(from: metrics.totalDays)

        let weekText =
            weekText(from: metrics.totalDays)

        let monthAgeText =
            monthAgeText(from: metrics)

        let milestoneText =
            milestoneText(
                anchor: anchor,
                metrics: metrics,
                isFutureRelative: false
            )

        switch anchor.type {

        case .birthday:

            return AnchorResult(
                title: anchor.title,
                isFutureRelative: false,
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
                countdownText: "",
                elapsedText: elapsedText,
                dayIndexText: dayIndexText,
                weekText: weekText,
                monthAgeText: monthAgeText,
                milestoneText: milestoneText,
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
                isFutureRelative: false,
                primaryText: durationText,
                secondaryText: formattedDateTime(anchor.date),
                summaryText:
                    anchor.title.isEmpty
                    ? durationText
                    : "\(anchor.title)\(durationText)",
                ageText: ageText,
                durationText: durationText,
                countdownText: "",
                elapsedText: elapsedText,
                dayIndexText: dayIndexText,
                weekText: weekText,
                monthAgeText: monthAgeText,
                milestoneText: milestoneText,
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

        let countdownValue =
            rawDayText(from: metrics.totalDays)

        let primary =
            countdownValue.isEmpty
            ? "0天"
            : countdownValue

        let countdownText =
            countdownText(from: metrics.totalDays)

        return AnchorResult(
            title: anchor.title,
            isFutureRelative: true,
            primaryText: primary,
            secondaryText: formattedDateTime(anchor.date),
            summaryText:
                anchor.title.isEmpty
                ? countdownText
                : "\(anchor.title)\(countdownText)",
            ageText: "",
            durationText: primary,
            countdownText: countdownText,
            elapsedText: "",
            dayIndexText: "",
            weekText: "",
            monthAgeText: "",
            milestoneText:
                milestoneText(
                    anchor: anchor,
                    metrics: metrics,
                    isFutureRelative: true
                ),
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

        let elapsedValue =
            rawDayText(from: metrics.totalDays)

        let primary =
            elapsedValue.isEmpty
            ? "0天"
            : elapsedValue

        let durationText =
            durationText(from: metrics)

        let ageText =
            ageText(from: metrics)

        let elapsedText =
            elapsedText(from: metrics.totalDays)

        return AnchorResult(
            title: anchor.title,
            isFutureRelative: false,
            primaryText: primary,
            secondaryText: formattedDateTime(anchor.date),
            summaryText:
                anchor.title.isEmpty
                ? elapsedText
                : "\(anchor.title)\(elapsedText)",
            ageText: ageText,
            durationText: durationText.isEmpty
                ? primary
                : durationText,
            countdownText: "",
            elapsedText: elapsedText,
            dayIndexText: dayIndexText(from: metrics.totalDays),
            weekText: weekText(from: metrics.totalDays),
            monthAgeText: monthAgeText(from: metrics),
            milestoneText:
                milestoneText(
                    anchor: anchor,
                    metrics: metrics,
                    isFutureRelative: false
                ),
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

        if metrics.years > 0 {
            return [
                "\(metrics.years)岁",
                metrics.months > 0
                    ? "\(metrics.months)个月"
                    : nil,
                metrics.days > 0
                    ? "\(metrics.days)天"
                    : nil
            ]
            .compactMap { $0 }
            .joined()
        }

        if metrics.months > 0 {
            return [
                "\(metrics.months)个月",
                metrics.days > 0
                    ? "\(metrics.days)天"
                    : nil
            ]
            .compactMap { $0 }
            .joined()
        }

        return "\(max(metrics.days, 0))天"
    }

    private func monthAgeText(
        from metrics: AnchorMetrics
    ) -> String {

        "\(max(metrics.years * 12 + metrics.months, 0))个月"
    }

    private func elapsedText(
        from totalDays: Int
    ) -> String {

        "已过\(max(totalDays, 0))天"
    }

    private func countdownText(
        from totalDays: Int
    ) -> String {

        "还有\(max(totalDays, 0))天"
    }

    private func rawDayText(
        from totalDays: Int
    ) -> String {

        "\(max(totalDays, 0))天"
    }

    private func dayIndexText(
        from totalDays: Int
    ) -> String {

        "第\(max(totalDays, 1))天"
    }

    private func weekText(
        from totalDays: Int
    ) -> String {

        let safeTotalDays =
            max(totalDays, 0)

        let weeks =
            safeTotalDays / 7

        let days =
            safeTotalDays % 7

        if weeks == 0,
           days == 0 {
            return "0周"
        }

        if days == 0 {
            return "\(weeks)周"
        }

        return "\(weeks)周\(days)天"
    }

    private func milestoneText(
        anchor: Anchor,
        metrics: AnchorMetrics,
        isFutureRelative: Bool
    ) -> String {

        let totalDays =
            max(metrics.totalDays, 0)

        if isFutureRelative {

            if metrics.years > 0,
               metrics.months == 0,
               metrics.days == 0 {
                return countdownText(from: totalDays)
            }

            if metrics.years == 0,
               metrics.months > 0,
               metrics.days == 0,
               futureMonthMilestones.contains(metrics.months) {
                return countdownText(from: totalDays)
            }

            if futureDayMilestones.contains(totalDays) {
                return countdownText(from: totalDays)
            }

            return ""
        }

        if anchor.type == .birthday {

            if totalDays == 7 {
                return "满7天"
            }

            if metrics.years == 0,
               metrics.months == 1,
               metrics.days == 0 {
                return "满月"
            }

            if totalDays == 100 {
                return "百天"
            }

            if metrics.years == 0,
               metrics.days == 0,
               birthdayMonthMilestones.contains(metrics.months) {
                return "\(metrics.months)个月"
            }
        }

        if metrics.years > 0,
           metrics.months == 0,
           metrics.days == 0 {
            return "\(metrics.years)周年"
        }

        if totalDays > 0,
           genericDayMilestones.contains(totalDays) {
            return "\(totalDays)天"
        }

        if metrics.years == 0,
           metrics.days == 0,
           genericMonthMilestones.contains(metrics.months) {
            return "\(metrics.months)个月"
        }

        return ""
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

            if !includeTime {
                return "0天"
            }

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

    var futureDayMilestones: Set<Int> {
        [
            1,
            3,
            7,
            30,
            100,
            365
        ]
    }

    var futureMonthMilestones: Set<Int> {
        [
            1,
            3,
            6
        ]
    }

    var birthdayMonthMilestones: Set<Int> {
        [
            3,
            6,
            9
        ]
    }

    var genericDayMilestones: Set<Int> {
        [
            100,
            500,
            1000
        ]
    }

    var genericMonthMilestones: Set<Int> {
        [
            1,
            3,
            6,
            12
        ]
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
