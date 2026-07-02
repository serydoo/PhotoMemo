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

    func relativeSnapshot(
        from context: MemoryContext
    ) -> MemoryAnchorRelativeSnapshot? {

        if let anchorResult =
            context.anchorResult {

            return MemoryAnchorRelativeSnapshot(
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

        return MemoryAnchorRelativeSnapshot(
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
        snapshot:
            MemoryAnchorRelativeSnapshot
    ) -> Bool {

        guard let anchor else {
            return false
        }

        return anchor.type == .birthday
            && !snapshot.isFutureRelative
    }

    func formatBabyAge(
        from snapshot:
            MemoryAnchorRelativeSnapshot
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

    func memorySummary(
        from context: MemoryContext,
        snapshot:
            MemoryAnchorRelativeSnapshot,
        babyAge: String
    ) -> String {

        guard let anchor = context.anchor else {
            return ""
        }

        return MemoryAnchorExpressionResolver
            .renderedText(
                subjectText:
                    context.trimmedSubjectText
                    ?? anchor.title,
                anchorTitle: anchor.title,
                anchorType: anchor.type,
                expressionStyle:
                    anchor.expressionStyle,
                relativeSnapshot:
                    snapshot
            )
    }
}

private extension MemoryAnchorRelativeSnapshot {

    var totalMonths: Int {
        max(years * 12 + months, 0)
    }

    var weeks: Int {
        max(totalDays, 0) / 7
    }
}
#endif
