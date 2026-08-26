import Foundation

#if !MEMOMARK_SHARE_EXTENSION
enum MemoryResultVariableProjector {

    static func project(
        from card: RecordCard,
        into context: inout MetadataContext
    ) {

        guard
            let memoryResult =
                card.memoryResult
        else {
            return
        }

        removeAnchorDisplayCopyValues(
            from: &context
        )

        guard
            let anchorResult =
                memoryResult
                .primaryAnchorResult
        else {
            removeAnchorTitle(
                from: &context
            )
            removeAnchorTimeResultValues(
                from: &context
            )
            return
        }

        context.set(
            anchorResult.anchorTitle,
            for: MetadataContext.Key.anchorTitle
        )

        guard anchorResult.status == .resolved else {
            removeAnchorTimeResultValues(
                from: &context
            )
            return
        }

        projectResolvedAnchor(
            anchorResult,
            language: card.language,
            into: &context
        )
    }

    static func memoryValues(
        from card: RecordCard
    ) -> MemoryCalculationResult {

        guard
            let anchorResult =
                card.memoryResult?
                .primaryAnchorResult,
            anchorResult.status == .resolved
        else {
            return MemoryCalculationResult()
        }

        let elapsed =
            anchorResult.elapsed
        let isFutureRelative =
            elapsed.isFutureRelative
        let babyAge =
            anchorResult.anchorType == .birthday
            && !isFutureRelative
            ? MemoryAnchorVariableTextFormatter.babyAgeText(
                from: elapsed,
                language: card.language
            )
            : ""

        return MemoryCalculationResult(
            daysSince:
                isFutureRelative
                ? "0"
                : "\(elapsed.totalDays)",
            yearsSince:
                isFutureRelative
                ? "0"
                : "\(elapsed.years)",
            monthsSince:
                isFutureRelative
                ? "0"
                : "\(elapsed.totalMonths)",
            weeksSince:
                isFutureRelative
                ? "0"
                : "\(elapsed.weeks)",
            babyAge: babyAge,
            memorySummary: ""
        )
    }
}

private extension MemoryResultVariableProjector {

    static func projectResolvedAnchor(
        _ anchorResult: MemoryAnchorResult,
        language: MemoMarkLanguage,
        into context: inout MetadataContext
    ) {

        let elapsed =
            anchorResult.elapsed

        projectSharedAnchorValues(
            anchorResult,
            elapsed: elapsed,
            language: language,
            into: &context
        )

        if elapsed.isFutureRelative {
            projectFutureAnchorValues(
                elapsed: elapsed,
                language: language,
                into: &context
            )
            return
        }

        projectPastAnchorValues(
            anchorResult: anchorResult,
            elapsed: elapsed,
            language: language,
            into: &context
        )
    }

    static func projectSharedAnchorValues(
        _ anchorResult: MemoryAnchorResult,
        elapsed: MemoryElapsedTime,
        language: MemoMarkLanguage,
        into context: inout MetadataContext
    ) {

        let totalDaysText =
            MemoryAnchorVariableTextFormatter.rawDayText(
                from: elapsed.totalDays,
                language: language
            )

        context.set(
            MemoryAnchorVariableTextFormatter.smartAnchorText(
                from: anchorResult,
                language: language
            ),
            for: MetadataContext.Key.anchorSmartText
        )
        context.set(
            elapsed.isFutureRelative
            ? totalDaysText
            : MemoryAnchorVariableTextFormatter.durationText(
                from: elapsed,
                language: language
            ),
            for:
                MetadataContext
                .Key
                .anchorDurationText
        )
        context.set(
            totalDaysText,
            for:
                MetadataContext
                .Key
                .anchorTotalDaysText
        )
        context.set(
            elapsed.years,
            for: MetadataContext.Key.anchorYears
        )
        context.set(
            elapsed.months,
            for: MetadataContext.Key.anchorMonths
        )
        context.set(
            elapsed.days,
            for: MetadataContext.Key.anchorDays
        )
        context.set(
            elapsed.totalDays,
            for: MetadataContext.Key.anchorTotalDays
        )
        removeAnchorMilestoneText(
            from: &context
        )
        removeAnchorSubDayValues(
            from: &context
        )
    }

    static func projectFutureAnchorValues(
        elapsed: MemoryElapsedTime,
        language: MemoMarkLanguage,
        into context: inout MetadataContext
    ) {

        removePastAnchorResultValues(
            from: &context
        )
        context.set(
            elapsed.relativeSnapshot.countdownText(
                language: language
            ),
            for:
                MetadataContext
                .Key
                .anchorCountdownText
        )
    }

    static func projectPastAnchorValues(
        anchorResult: MemoryAnchorResult,
        elapsed: MemoryElapsedTime,
        language: MemoMarkLanguage,
        into context: inout MetadataContext
    ) {

        removeFutureAnchorResultValues(
            from: &context
        )
        context.set(
            anchorResult.anchorType == .birthday
            ? MemoryAnchorVariableTextFormatter.babyAgeText(
                from: elapsed,
                language: language
            )
            : elapsed.relativeSnapshot.ageText(
                language: language
            ),
            for:
                MetadataContext
                .Key
                .anchorAgeText
        )
        context.set(
            MemoryAnchorVariableTextFormatter.elapsedText(
                from: elapsed.totalDays,
                language: language
            ),
            for:
                MetadataContext
                .Key
                .anchorElapsedText
        )
        context.set(
            MemoryAnchorVariableTextFormatter.dayIndexText(
                from: elapsed.totalDays,
                language: language
            ),
            for:
                MetadataContext
                .Key
                .anchorDayIndexText
        )
        context.set(
            MemoryAnchorVariableTextFormatter.weekText(
                from: elapsed.totalDays,
                language: language
            ),
            for:
                MetadataContext
                .Key
                .anchorWeekText
        )
        context.set(
            MemoryAnchorVariableTextFormatter.monthAgeText(
                from: elapsed.totalMonths,
                language: language
            ),
            for:
                MetadataContext
                .Key
                .anchorMonthAgeText
        )
    }

    static func removeAnchorTimeResultValues(
        from context: inout MetadataContext
    ) {

        [
            MetadataContext.Key.anchorSmartText,
            MetadataContext.Key.anchorCountdownText,
            MetadataContext.Key.anchorAgeText,
            MetadataContext.Key.anchorDurationText,
            MetadataContext.Key.anchorTotalDaysText,
            MetadataContext.Key.anchorElapsedText,
            MetadataContext.Key.anchorDayIndexText,
            MetadataContext.Key.anchorWeekText,
            MetadataContext.Key.anchorMonthAgeText,
            MetadataContext.Key.anchorMilestoneText,
            MetadataContext.Key.anchorYears,
            MetadataContext.Key.anchorMonths,
            MetadataContext.Key.anchorDays,
            MetadataContext.Key.anchorHours,
            MetadataContext.Key.anchorMinutes,
            MetadataContext.Key.anchorSeconds,
            MetadataContext.Key.anchorTotalDays
        ]
        .forEach {
            context.removeValue(
                for: $0
            )
        }
    }

    static func removeAnchorDisplayCopyValues(
        from context: inout MetadataContext
    ) {

        [
            MetadataContext.Key.anchorPrimary,
            MetadataContext.Key.anchorSecondary,
            MetadataContext.Key.anchorSummary
        ]
        .forEach {
            context.removeValue(
                for: $0
            )
        }
    }

    static func removeAnchorTitle(
        from context: inout MetadataContext
    ) {

        context.removeValue(
            for: MetadataContext.Key.anchorTitle
        )
    }

    static func removeAnchorSubDayValues(
        from context: inout MetadataContext
    ) {

        [
            MetadataContext.Key.anchorHours,
            MetadataContext.Key.anchorMinutes,
            MetadataContext.Key.anchorSeconds
        ]
        .forEach {
            context.removeValue(
                for: $0
            )
        }
    }

    static func removeAnchorMilestoneText(
        from context: inout MetadataContext
    ) {

        context.removeValue(
            for:
                MetadataContext
                .Key
                .anchorMilestoneText
        )
    }

    static func removeFutureAnchorResultValues(
        from context: inout MetadataContext
    ) {

        context.removeValue(
            for:
                MetadataContext
                .Key
                .anchorCountdownText
        )
    }

    static func removePastAnchorResultValues(
        from context: inout MetadataContext
    ) {

        [
            MetadataContext.Key.anchorAgeText,
            MetadataContext.Key.anchorElapsedText,
            MetadataContext.Key.anchorDayIndexText,
            MetadataContext.Key.anchorWeekText,
            MetadataContext.Key.anchorMonthAgeText,
            MetadataContext.Key.anchorMilestoneText
        ]
        .forEach {
            context.removeValue(
                for: $0
            )
        }
    }
}
#endif
