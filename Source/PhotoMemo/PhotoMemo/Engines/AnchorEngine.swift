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
        photoDate: Date,
        outputLanguage: MemoMarkLanguage = .simplifiedChinese
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
                photoDate: photoDate,
                outputLanguage: outputLanguage
            )
        }

        if anchor.isCountdown {

            return buildPastCountdownResult(
                from: anchor,
                photoDate: photoDate,
                outputLanguage: outputLanguage
            )
        }

        let metrics = metrics(
            from: anchor.date,
            to: photoDate
        )

        let durationText =
            durationText(
                from: metrics,
                language: outputLanguage
            )

        let ageText =
            isBirthdayAnchorDay
            ? MemoryNarrativeFormatter.birthDayLabel(
                language: outputLanguage
            )
            : ageText(
                from: metrics,
                language: outputLanguage
            )

        let elapsedText =
            isBirthdayAnchorDay
            ? MemoryNarrativeFormatter.birthDayLabel(
                language: outputLanguage
            )
            : elapsedText(
                from: metrics.totalDays,
                language: outputLanguage
            )

        let resolvedDurationText =
            isBirthdayAnchorDay
            ? MemoryNarrativeFormatter.birthDayLabel(
                language: outputLanguage
            )
            : durationText

        let dayIndexText =
            dayIndexText(
                from: metrics.totalDays,
                language: outputLanguage
            )

        let weekText =
            weekText(
                from: metrics.totalDays,
                language: outputLanguage
            )

        let monthAgeText =
            monthAgeText(
                from: metrics,
                language: outputLanguage
            )

        let milestoneText =
            milestoneText(
                anchor: anchor,
                metrics: metrics,
                isFutureRelative: false,
                language: outputLanguage
            )

        switch anchor.type {

        case .birthday:

            let resolvedSubject =
                anchor.title.trimmingCharacters(
                    in: .whitespacesAndNewlines
                ).isEmpty
                ? "记忆对象"
                : anchor.title

            let summaryText = narrativeText(
                anchor: anchor,
                metrics: metrics,
                occurrence: isBirthdayAnchorDay
                    ? .birthDay
                    : .elapsed,
                outputLanguage: outputLanguage
            )

            return AnchorResult(
                title: anchor.title,
                isFutureRelative: false,
                primaryText:
                    ageText.isEmpty
                    ? durationText
                    : ageText,
                secondaryText:
                    resolvedDurationText.isEmpty
                    ? formattedDateTime(
                        anchor.date,
                        language: outputLanguage
                    )
                    : resolvedDurationText,
                summaryText:
                    summaryText.isEmpty
                    ? resolvedSubject
                    : summaryText,
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

            let summaryText = narrativeText(
                anchor: anchor,
                metrics: metrics,
                occurrence: .elapsed,
                outputLanguage: outputLanguage
            )

            return AnchorResult(
                title: anchor.title,
                isFutureRelative: false,
                primaryText: durationText,
                secondaryText:
                    formattedDateTime(
                        anchor.date,
                        language: outputLanguage
                    ),
                summaryText:
                    summaryText.isEmpty
                    ? durationText
                    : summaryText,
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
        photoDate: Date,
        outputLanguage: MemoMarkLanguage
    ) -> AnchorResult {

        let metrics = metrics(
            from: photoDate,
            to: anchor.date
        )

        let countdownValue =
            rawDayText(
                from: metrics.totalDays,
                language: outputLanguage
            )

        let primary =
            countdownValue.isEmpty
            ? rawDayText(from: 0, language: outputLanguage)
            : countdownValue

        let countdownText =
            countdownText(
                from: metrics.totalDays,
                language: outputLanguage
            )

        let summaryText = narrativeText(
            anchor: anchor,
            metrics: metrics,
            occurrence: .countdown,
            outputLanguage: outputLanguage
        )

        return AnchorResult(
            title: anchor.title,
            isFutureRelative: true,
            primaryText: primary,
            secondaryText:
                formattedDateTime(
                    anchor.date,
                    language: outputLanguage
                ),
            summaryText:
                summaryText.isEmpty
                ? countdownText
                : summaryText,
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
                    isFutureRelative: true,
                    language: outputLanguage
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
        photoDate: Date,
        outputLanguage: MemoMarkLanguage
    ) -> AnchorResult {

        let metrics = metrics(
            from: anchor.date,
            to: photoDate
        )

        let elapsedValue =
            rawDayText(
                from: metrics.totalDays,
                language: outputLanguage
            )

        let primary =
            elapsedValue.isEmpty
            ? rawDayText(from: 0, language: outputLanguage)
            : elapsedValue

        let durationText =
            durationText(
                from: metrics,
                language: outputLanguage
            )

        let ageText =
            ageText(
                from: metrics,
                language: outputLanguage
            )

        let elapsedText =
            elapsedText(
                from: metrics.totalDays,
                language: outputLanguage
            )

        let summaryText = narrativeText(
            anchor: anchor,
            metrics: metrics,
            occurrence: .elapsed,
            outputLanguage: outputLanguage
        )

        return AnchorResult(
            title: anchor.title,
            isFutureRelative: false,
            primaryText: primary,
            secondaryText:
                formattedDateTime(
                    anchor.date,
                    language: outputLanguage
                ),
            summaryText:
                summaryText.isEmpty
                ? elapsedText
                : summaryText,
            ageText: ageText,
            durationText: durationText.isEmpty
                ? primary
                : durationText,
            countdownText: "",
            elapsedText: elapsedText,
            dayIndexText:
                dayIndexText(
                    from: metrics.totalDays,
                    language: outputLanguage
                ),
            weekText:
                weekText(
                    from: metrics.totalDays,
                    language: outputLanguage
                ),
            monthAgeText:
                monthAgeText(
                    from: metrics,
                    language: outputLanguage
                ),
            milestoneText:
                milestoneText(
                    anchor: anchor,
                    metrics: metrics,
                    isFutureRelative: false,
                    language: outputLanguage
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
        _ date: Date,
        language: MemoMarkLanguage
    ) -> String {

        let formatter = DateFormatter()
        formatter.locale = language.locale
        formatter.setLocalizedDateFormatFromTemplate(
            "yMdjm"
        )

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
        from metrics: AnchorMetrics,
        language: MemoMarkLanguage
    ) -> String {
        MemoryAgeFormatter.format(
            MemoryAgeComponents(
                years: metrics.years,
                months: metrics.months,
                days: metrics.days
            ),
            language: language
        )
    }

    private func monthAgeText(
        from metrics: AnchorMetrics,
        language: MemoMarkLanguage
    ) -> String {
        MemoryMonthAgeFormatter.format(
            totalMonths:
                metrics.years * 12 + metrics.months,
            language: language
        )
    }

    private func elapsedText(
        from totalDays: Int,
        language: MemoMarkLanguage
    ) -> String {
        MemoryElapsedFormatter.format(
            totalDays: totalDays,
            language: language
        )
    }

    private func countdownText(
        from totalDays: Int,
        language: MemoMarkLanguage
    ) -> String {
        MemoryCountdownPhraseFormatter.format(
            totalDays: totalDays,
            language: language
        )
    }

    private func rawDayText(
        from totalDays: Int,
        language: MemoMarkLanguage
    ) -> String {
        MemoryCountdownFormatter.format(
            MemoryCountdownComponents(totalDays: totalDays),
            language: language
        )
    }

    private func dayIndexText(
        from totalDays: Int,
        language: MemoMarkLanguage
    ) -> String {
        MemoryDayIndexFormatter.format(
            totalDays: totalDays,
            language: language
        )
    }

    private func weekText(
        from totalDays: Int,
        language: MemoMarkLanguage
    ) -> String {
        MemoryWeekFormatter.format(
            totalDays: totalDays,
            language: language
        )
    }

    private func milestoneText(
        anchor: Anchor,
        metrics: AnchorMetrics,
        isFutureRelative: Bool,
        language: MemoMarkLanguage
    ) -> String {

        let totalDays =
            max(metrics.totalDays, 0)

        if isFutureRelative {

            if metrics.years > 0,
               metrics.months == 0,
               metrics.days == 0 {
                return countdownText(
                    from: totalDays,
                    language: language
                )
            }

            if metrics.years == 0,
               metrics.months > 0,
               metrics.days == 0,
               futureMonthMilestones.contains(metrics.months) {
                return countdownText(
                    from: totalDays,
                    language: language
                )
            }

            if futureDayMilestones.contains(totalDays) {
                return countdownText(
                    from: totalDays,
                    language: language
                )
            }

            return ""
        }

        if anchor.type == .birthday {

            if totalDays == 7 {
                return MemoryMilestoneFormatter.birthdaySevenDays(
                    language: language
                )
            }

            if metrics.years == 0,
               metrics.months == 1,
               metrics.days == 0 {
                return MemoryMilestoneFormatter.birthdayMonth(
                    language: language
                )
            }

            if totalDays == 100 {
                return MemoryMilestoneFormatter.birthdayHundredDays(
                    language: language
                )
            }

            if metrics.years == 0,
               metrics.days == 0,
               birthdayMonthMilestones.contains(metrics.months) {
                return MemoryMilestoneFormatter.month(
                    metrics.months,
                    language: language
                )
            }
        }

        if metrics.years > 0,
           metrics.months == 0,
           metrics.days == 0 {
            return MemoryMilestoneFormatter.anniversary(
                metrics.years,
                language: language
            )
        }

        if totalDays > 0,
           genericDayMilestones.contains(totalDays) {
            return MemoryMilestoneFormatter.day(
                totalDays,
                language: language
            )
        }

        if metrics.years == 0,
           metrics.days == 0,
           genericMonthMilestones.contains(metrics.months) {
            return MemoryMilestoneFormatter.month(
                metrics.months,
                language: language
            )
        }

        return ""
    }

    private func durationText(
        from metrics: AnchorMetrics,
        includeTime: Bool = false,
        language: MemoMarkLanguage
    ) -> String {

        var value = MemoryDurationFormatter.format(
            MemoryDurationComponents(
                years: metrics.years,
                months: metrics.months,
                days: metrics.days,
                totalDays: metrics.totalDays
            ),
            language: language
        )

        if includeTime {
            var parts = [value]

            if metrics.hours > 0 {
                parts.append("\(metrics.hours)h")
            }

            if metrics.minutes > 0 {
                parts.append("\(metrics.minutes)m")
            }

            if metrics.seconds > 0 {
                parts.append("\(metrics.seconds)s")
            }

            value = parts.joined(separator: " ")
        }

        return value
    }

    private func narrativeText(
        anchor: Anchor,
        metrics: AnchorMetrics,
        occurrence: MemoryNarrativeOccurrence,
        outputLanguage: MemoMarkLanguage
    ) -> String {

        MemoryNarrativeFormatter.format(
            context: MemoryNarrativeContext(
                anchorType: anchor.type,
                subjectDisplayName:
                    anchor.title.isEmpty
                    ? "记忆对象"
                    : anchor.title,
                anchorTitle: anchor.title,
                occurrence: occurrence,
                ageComponents:
                    anchor.type == .birthday
                    ? MemoryAgeComponents(
                        years: metrics.years,
                        months: metrics.months,
                        days: metrics.days
                    )
                    : nil,
                durationComponents:
                    MemoryDurationComponents(
                        years: metrics.years,
                        months: metrics.months,
                        days: metrics.days,
                        totalDays: metrics.totalDays
                    ),
                countdownComponents:
                    occurrence == .countdown
                    ? MemoryCountdownComponents(
                        totalDays: metrics.totalDays
                    )
                    : nil,
                expressionStyle: anchor.expressionStyle,
                language: outputLanguage,
                formattingMode: .legacyCompatible
            )
        )
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
