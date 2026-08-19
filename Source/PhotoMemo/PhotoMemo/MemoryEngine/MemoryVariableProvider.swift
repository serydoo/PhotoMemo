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
                from: snapshot,
                language: context.outputLanguage
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

        return MemoryAnchorRelativeSnapshot.resolve(
            anchorDate: anchor.date,
            captureDate: photoDate,
            calendar: context.calendar,
            comparesByCalendarDay:
                true
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
        from snapshot: MemoryAnchorRelativeSnapshot,
        language: MemoMarkLanguage
    ) -> String {
        if snapshot.isOnAnchorDay {
            return MemoryNarrativeFormatter.birthDayLabel(
                language: language
            )
        }

        return MemoryAgeFormatter.format(
            MemoryAgeComponents(
                years: snapshot.years,
                months: snapshot.months,
                days: snapshot.days
            ),
            language: language
        )
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
                    snapshot,
                language:
                    context.outputLanguage
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
