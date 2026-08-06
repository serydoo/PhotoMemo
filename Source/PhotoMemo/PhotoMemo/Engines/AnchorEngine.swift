import Foundation

final class AnchorEngine {

    private let calendar: Calendar

    init(
        calendar: Calendar = .current
    ) {
        self.calendar = calendar
    }

    func build(
        from anchor: Anchor,
        photoDate: Date
    ) -> AnchorResult {
        let isAnchorCalendarDay =
            calendar.isDate(
                photoDate,
                inSameDayAs: anchor.date
            )
        let isBirthdayAnchorDay =
            anchor.type == .birthday
            && isAnchorCalendarDay

        if photoDate < anchor.date,
           !isAnchorCalendarDay {

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
            isBirthdayAnchorDay
            ? "出生当天"
            : ageText(from: metrics)

        let elapsedText =
            isBirthdayAnchorDay
            ? "出生当天"
            : elapsedText(from: metrics.totalDays)

        let resolvedDurationText =
            isBirthdayAnchorDay
            ? "出生当天"
            : durationText

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

            let resolvedSubject =
                anchor.title.trimmingCharacters(
                    in: .whitespacesAndNewlines
                ).isEmpty
                ? "记忆对象"
                : anchor.title

            return AnchorResult(
                title: anchor.title,
                isFutureRelative: false,
                primaryText:
                    ageText.isEmpty
                    ? durationText
                    : ageText,
                secondaryText:
                    resolvedDurationText.isEmpty
                    ? formattedDateTime(anchor.date)
                    : resolvedDurationText,
                summaryText:
                    isBirthdayAnchorDay
                    ? "\(resolvedSubject)今天来到这个世界啦！"
                    : anchor.title.isEmpty
                        ? ageText
                        : "\(anchor.title)今天\(ageText)啦！",
                ageText: ageText,
                durationText: resolvedDurationText,
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
        formatter.locale = MemoMarkLanguage.stored.locale
        formatter.dateFormat =
            MemoMarkLanguage.stored == .english
            ? "MMM d, yyyy HH:mm"
            : "yyyy.MM.dd HH:mm"

        return formatter.string(from: date)
    }

    private func metrics(
        from startDate: Date,
        to endDate: Date
    ) -> AnchorMetrics {

        guard endDate >= startDate else {
            return AnchorMetrics()
        }

        let startDay = calendar.startOfDay(
            for: startDate
        )
        let endDay = calendar.startOfDay(
            for: endDate
        )
        let dayComponents = calendar.dateComponents(
            [
                .year,
                .month,
                .day
            ],
            from: startDay,
            to: endDay
        )
        let timeComponents = calendar.dateComponents(
            [
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
                from: startDay,
                to: endDay
            ).day ?? 0

        return AnchorMetrics(
            years: dayComponents.year ?? 0,
            months: dayComponents.month ?? 0,
            days: dayComponents.day ?? 0,
            hours: timeComponents.hour ?? 0,
            minutes: timeComponents.minute ?? 0,
            seconds: timeComponents.second ?? 0,
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
