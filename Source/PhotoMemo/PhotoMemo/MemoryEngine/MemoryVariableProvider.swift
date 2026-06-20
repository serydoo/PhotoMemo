import Foundation

#if !PHOTOMEMO_SHARE_EXTENSION
struct MemoryVariableProvider {

    func build(
        from context: MemoryContext
    ) -> MemoryCalculationResult {

        let story =
            context.trimmedStory

        guard
            let snapshot =
                relativeSnapshot(
                    from: context
                )
        else {
            return MemoryCalculationResult(
                memorySummary: story
            )
        }

        let daysSince =
            snapshot.isFutureRelative
            ? "0"
            : "\(snapshot.totalDays)"

        let yearsSince =
            snapshot.isFutureRelative
            ? "0"
            : "\(snapshot.years)"

        let monthsSince =
            snapshot.isFutureRelative
            ? "0"
            : "\(snapshot.totalMonths)"

        let weeksSince =
            snapshot.isFutureRelative
            ? "0"
            : "\(snapshot.weeks)"

        let babyAge =
            shouldExposeBabyAge(
                for: context.anchor,
                snapshot: snapshot
            )
            ? formatBabyAge(
                from: snapshot
            )
            : ""

        let memorySummary =
            story.isEmpty
            ? memorySummary(
                from: context,
                snapshot: snapshot,
                babyAge: babyAge
            )
            : story

        return MemoryCalculationResult(
            daysSince: daysSince,
            yearsSince: yearsSince,
            monthsSince: monthsSince,
            weeksSince: weeksSince,
            babyAge: babyAge,
            memorySummary: memorySummary
        )
    }
}

private extension MemoryVariableProvider {

    struct RelativeSnapshot {

        let years: Int

        let months: Int

        let days: Int

        let totalDays: Int

        let isFutureRelative: Bool

        var totalMonths: Int {

            max(years * 12 + months, 0)
        }

        var weeks: Int {

            max(totalDays, 0) / 7
        }
    }

    func relativeSnapshot(
        from context: MemoryContext
    ) -> RelativeSnapshot? {

        if let anchorResult =
            context.anchorResult {

            return RelativeSnapshot(
                years: max(anchorResult.years, 0),
                months: max(anchorResult.months, 0),
                days: max(anchorResult.days, 0),
                totalDays: max(anchorResult.totalDays, 0),
                isFutureRelative:
                    anchorResult.isFutureRelative
            )
        }

        guard
            let anchor = context.anchor,
            let photoDate = context.photoDate
        else {
            return nil
        }

        let isFutureRelative =
            photoDate < anchor.date

        let startDate =
            isFutureRelative
            ? photoDate
            : anchor.date

        let endDate =
            isFutureRelative
            ? anchor.date
            : photoDate

        let components =
            context.calendar.dateComponents(
                [
                    .year,
                    .month,
                    .day
                ],
                from: startDate,
                to: endDate
            )

        let totalDays =
            context.calendar.dateComponents(
                [.day],
                from: startDate,
                to: endDate
            ).day ?? 0

        return RelativeSnapshot(
            years: max(
                components.year ?? 0,
                0
            ),
            months: max(
                components.month ?? 0,
                0
            ),
            days: max(
                components.day ?? 0,
                0
            ),
            totalDays: max(totalDays, 0),
            isFutureRelative: isFutureRelative
        )
    }

    func shouldExposeBabyAge(
        for anchor: Anchor?,
        snapshot: RelativeSnapshot
    ) -> Bool {

        guard let anchor else {
            return false
        }

        return anchor.type == .birthday
            && !snapshot.isFutureRelative
    }

    func formatBabyAge(
        from snapshot: RelativeSnapshot
    ) -> String {

        if snapshot.years > 0 {
            return [
                "\(snapshot.years)岁",
                snapshot.months > 0
                    ? "\(snapshot.months)个月"
                    : nil,
                snapshot.days > 0
                    ? "\(snapshot.days)天"
                    : nil
            ]
            .compactMap { $0 }
            .joined()
        }

        if snapshot.months > 0 {
            return [
                "\(snapshot.months)个月",
                snapshot.days > 0
                    ? "\(snapshot.days)天"
                    : nil
            ]
            .compactMap { $0 }
            .joined()
        }

        return "\(snapshot.days)天"
    }

    func formatDuration(
        from snapshot: RelativeSnapshot
    ) -> String {

        let parts = [
            snapshot.years > 0
                ? "\(snapshot.years)年"
                : nil,
            snapshot.months > 0
                ? "\(snapshot.months)个月"
                : nil,
            snapshot.days > 0
                ? "\(snapshot.days)天"
                : nil
        ]
        .compactMap { $0 }

        if parts.isEmpty {
            return "0天"
        }

        return parts.joined()
    }

    func memorySummary(
        from context: MemoryContext,
        snapshot: RelativeSnapshot,
        babyAge: String
    ) -> String {

        if let anchorResult =
            context.anchorResult {

            let summary =
                anchorResult.summaryText
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

            if !summary.isEmpty {
                return summary
            }
        }

        guard let anchor = context.anchor else {
            return ""
        }

        if snapshot.isFutureRelative {

            let countdown =
                "还有\(snapshot.totalDays)天"

            if anchor.title.isEmpty {
                return countdown
            }

            return "\(anchor.title)\(countdown)"
        }

        switch anchor.type {

        case .birthday:

            let ageText =
                babyAge.isEmpty
                ? formatBabyAge(
                    from: snapshot
                )
                : babyAge

            guard !ageText.isEmpty else {
                return ""
            }

            if anchor.title.isEmpty {
                return ageText
            }

            return "\(anchor.title)今天\(ageText)"

        case .relationship,
             .marriage,
             .custom,
             .exam:

            let duration =
                formatDuration(
                    from: snapshot
                )

            if anchor.title.isEmpty {
                return duration
            }

            return "\(anchor.title)\(duration)"
        }
    }
}
#endif
