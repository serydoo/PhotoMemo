import Foundation

struct CardVariableProvider {

    static func build(
        from card: RecordCard
    ) -> MetadataContext {

        var context = card.context

        context.set(
            card.title,
            for: MetadataContext.Key.title
        )

        context.set(
            card.story,
            for: MetadataContext.Key.story
        )

        if let anchor = card.anchorResult {

            let totalDaysText =
                "\(anchor.totalDays)天"

            let smartText =
                smartAnchorText(
                    anchor: card.anchor,
                    result: anchor
                )

            context.set(
                anchor.title,
                for: MetadataContext.Key.anchorTitle
            )

            context.set(
                anchor.primaryText,
                for: MetadataContext.Key.anchorPrimary
            )

            context.set(
                anchor.secondaryText,
                for: MetadataContext.Key.anchorSecondary
            )

            context.set(
                anchor.summaryText,
                for: MetadataContext.Key.anchorSummary
            )

            context.set(
                smartText,
                for: MetadataContext.Key.anchorSmartText
            )

            context.set(
                anchor.countdownText,
                for: MetadataContext.Key.anchorCountdownText
            )

            context.set(
                anchor.ageText,
                for: MetadataContext.Key.anchorAgeText
            )

            context.set(
                anchor.durationText,
                for: MetadataContext.Key.anchorDurationText
            )

            context.set(
                totalDaysText,
                for: MetadataContext.Key.anchorTotalDaysText
            )

            context.set(
                anchor.elapsedText,
                for: MetadataContext.Key.anchorElapsedText
            )

            context.set(
                anchor.dayIndexText,
                for: MetadataContext.Key.anchorDayIndexText
            )

            context.set(
                anchor.weekText,
                for: MetadataContext.Key.anchorWeekText
            )

            context.set(
                anchor.monthAgeText,
                for: MetadataContext.Key.anchorMonthAgeText
            )

            context.set(
                anchor.milestoneText,
                for: MetadataContext.Key.anchorMilestoneText
            )

            context.set(
                anchor.years,
                for: MetadataContext.Key.anchorYears
            )

            context.set(
                anchor.months,
                for: MetadataContext.Key.anchorMonths
            )

            context.set(
                anchor.days,
                for: MetadataContext.Key.anchorDays
            )

            context.set(
                anchor.hours,
                for: MetadataContext.Key.anchorHours
            )

            context.set(
                anchor.minutes,
                for: MetadataContext.Key.anchorMinutes
            )

            context.set(
                anchor.seconds,
                for: MetadataContext.Key.anchorSeconds
            )

            context.set(
                anchor.totalDays,
                for: MetadataContext.Key.anchorTotalDays
            )
        }

#if !PHOTOMEMO_SHARE_EXTENSION
        projectMemoryResultAnchorValues(
            from: card,
            into: &context
        )
#endif

        if !card.tags.isEmpty {

            context.set(
                card.tags.joined(separator: ", "),
                for: MetadataContext.Key.tags
            )
        }

        if let badge = card.badge {

            context.set(
                badge.name,
                for: MetadataContext.Key.badgeName
            )
        }

        let memoryValues =
            memoryValues(from: card)

        context.set(
            captureDateDisplay(
                from: card.metadata
            ),
            for: MetadataContext.Key.captureDateDisplay
        )

        context.set(
            cameraSummary(
                from: card.metadata
            ),
            for: MetadataContext.Key.cameraSummary
        )

        context.set(
            memoryValues.daysSince,
            for: MetadataContext.Key.daysSince
        )

        context.set(
            memoryValues.yearsSince,
            for: MetadataContext.Key.yearsSince
        )

        context.set(
            memoryValues.monthsSince,
            for: MetadataContext.Key.monthsSince
        )

        context.set(
            memoryValues.weeksSince,
            for: MetadataContext.Key.weeksSince
        )

        context.set(
            memoryValues.babyAge,
            for: MetadataContext.Key.babyAge
        )

        context.set(
            memoryValues.memorySummary,
            for: MetadataContext.Key.memorySummary
        )

        return context
    }

    static func exportDescription(
        from card: RecordCard
    ) -> String {

        if let explicitDescription =
            card.exportDescriptionOverride {

            return explicitDescription
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
        }

        let title =
            card.title.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        let memory =
            memorySummary(from: card)
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        let captureDate =
            captureDateDisplay(
                from: card.metadata
            )

        let camera =
            cameraSummary(
                from: card.metadata
            )

        var lines: [String] = []

        if !title.isEmpty {
            lines.append(title)
        }

        if !memory.isEmpty,
           memory != title {
            lines.append(memory)
        }

        if !captureDate.isEmpty {
            lines.append("Captured: \(captureDate)")
        }

        if !camera.isEmpty {
            lines.append(camera)
        }

        return lines.joined(separator: "\n")
    }
}

private extension CardVariableProvider {

    static func captureDateDisplay(
        from metadata: PhotoMetadata
    ) -> String {

        metadata.captureDateDisplayText
    }

    static func cameraSummary(
        from metadata: PhotoMetadata
    ) -> String {

        var segments: [String] = []

        let focalText =
            metadata.focalLength35mm.isEmpty
            ? metadata.focalLength
            : metadata.focalLength35mm

        if !focalText.isEmpty {
            segments.append("\(focalText)mm")
        }

        if !metadata.aperture.isEmpty {
            segments.append("f/\(metadata.aperture)")
        }

        if !metadata.shutterSpeed.isEmpty {
            let shutter =
                metadata.shutterSpeed.hasSuffix("s")
                ? metadata.shutterSpeed
                : metadata.shutterSpeed + "s"

            segments.append(shutter)
        }

        if !metadata.iso.isEmpty {
            segments.append("ISO\(metadata.iso)")
        }

        if segments.isEmpty {
            return firstNonEmpty(
                metadata.normalizedDeviceModel,
                metadata.normalizedDeviceBrand,
                metadata.normalizedLensModel
            )
        }

        return segments.joined(separator: " ")
    }

    static func memorySummary(
        from card: RecordCard
    ) -> String {

        memoryValues(from: card)
            .memorySummary
    }

    static func smartAnchorText(
        anchor: Anchor?,
        result: AnchorResult
    ) -> String {

        guard let anchor else {
            return result.primaryText
        }

        if !result.milestoneText.isEmpty {
            return result.milestoneText
        }

        if result.isFutureRelative {
            return firstNonEmpty(
                result.countdownText,
                result.primaryText
            )
        }

        switch anchor.type {

        case .birthday:
            return firstNonEmpty(
                result.ageText,
                result.monthAgeText,
                result.durationText
            )

        case .relationship:
            return result.totalDays < 365
                ? firstNonEmpty(
                    result.elapsedText,
                    rawDayText(result)
                )
                : result.durationText

        case .marriage:
            return result.durationText

        case .exam:
            return result.totalDays < 100
                ? firstNonEmpty(
                    result.elapsedText,
                    rawDayText(result)
                )
                : result.durationText

        case .custom:
            if result.totalDays < 100 {
                return firstNonEmpty(
                    result.elapsedText,
                    rawDayText(result)
                )
            }

            return result.durationText
        }
    }

    static func firstNonEmpty(
        _ candidates: String...
    ) -> String {

        candidates.first {
            !$0.trimmingCharacters(
                in: .whitespacesAndNewlines
            ).isEmpty
        } ?? ""
    }

    static func rawDayText(
        _ result: AnchorResult
    ) -> String {

        "\(result.totalDays)天"
    }

    static func memoryValues(
        from card: RecordCard
    ) -> MemoryCalculationResult {

        let legacyValues =
            MemoryVariableProvider().build(
            from: MemoryContext(
                metadata: card.metadata,
                anchor: card.anchor,
                anchorResult: card.anchorResult,
                story: card.story,
                subjectText:
                    card.memorySubjectText
            )
        )

#if !PHOTOMEMO_SHARE_EXTENSION
        let hasMemoryResult =
            card.memoryResult != nil
        let memoryResultStatus =
            card.memoryResult?
            .primaryAnchorResult?
            .status
        let semanticValues =
            memoryResultValues(
                from: card
            )
        let projectedSummary =
            card.memoryModule?
            .renderedText
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            ) ?? ""

        if !projectedSummary.isEmpty {
            if hasMemoryResult {
                if memoryResultStatus != .resolved {
                    return MemoryCalculationResult(
                        memorySummary:
                            projectedSummary
                    )
                }

                return MemoryCalculationResult(
                    daysSince:
                        semanticValues.daysSince,
                    yearsSince:
                        semanticValues.yearsSince,
                    monthsSince:
                        semanticValues.monthsSince,
                    weeksSince:
                        semanticValues.weeksSince,
                    babyAge:
                        semanticValues.babyAge,
                    memorySummary:
                        projectedSummary
                )
            }

            return MemoryCalculationResult(
                daysSince:
                    legacyValues.daysSince,
                yearsSince:
                    legacyValues.yearsSince,
                monthsSince:
                    legacyValues.monthsSince,
                weeksSince:
                    legacyValues.weeksSince,
                babyAge:
                    legacyValues.babyAge,
                memorySummary: projectedSummary
            )
        }

        if hasMemoryResult,
           memoryResultStatus != .resolved {
            return MemoryCalculationResult()
        }

        if semanticValues != MemoryCalculationResult() {
            return semanticValues
        }
#endif

        return legacyValues
    }

#if !PHOTOMEMO_SHARE_EXTENSION
    static func projectMemoryResultAnchorValues(
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

        let elapsed =
            anchorResult.elapsed
        let totalDaysText =
            rawDayText(
                from: elapsed.totalDays
            )

        context.set(
            smartAnchorText(
                from: anchorResult
            ),
            for: MetadataContext.Key.anchorSmartText
        )
        context.set(
            elapsed.isFutureRelative
            ? totalDaysText
            : durationText(
                from: elapsed
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

        if elapsed.isFutureRelative {
            removePastAnchorResultValues(
                from: &context
            )
            context.set(
                countdownText(
                    from: elapsed.totalDays
                ),
                for:
                    MetadataContext
                    .Key
                    .anchorCountdownText
            )
            return
        }

        removeFutureAnchorResultValues(
            from: &context
        )
        context.set(
            babyAgeText(
                from: elapsed
            ),
            for:
                MetadataContext
                .Key
                .anchorAgeText
        )
        context.set(
            elapsedText(
                from: elapsed.totalDays
            ),
            for:
                MetadataContext
                .Key
                .anchorElapsedText
        )
        context.set(
            dayIndexText(
                from: elapsed.totalDays
            ),
            for:
                MetadataContext
                .Key
                .anchorDayIndexText
        )
        context.set(
            weekText(
                from: elapsed.totalDays
            ),
            for:
                MetadataContext
                .Key
                .anchorWeekText
        )
        context.set(
            "\(elapsed.totalMonths)个月",
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

    static func memoryResultValues(
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
            ? babyAgeText(from: elapsed)
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

    static func babyAgeText(
        from elapsed: MemoryElapsedTime
    ) -> String {

        if elapsed.years > 0 {
            return [
                "\(elapsed.years)岁",
                elapsed.months > 0
                    ? "\(elapsed.months)个月"
                    : nil,
                elapsed.days > 0
                    ? "\(elapsed.days)天"
                    : nil
            ]
            .compactMap { $0 }
            .joined()
        }

        if elapsed.months > 0 {
            return [
                "\(elapsed.months)个月",
                elapsed.days > 0
                    ? "\(elapsed.days)天"
                    : nil
            ]
            .compactMap { $0 }
            .joined()
        }

        return "\(elapsed.days)天"
    }

    static func smartAnchorText(
        from anchorResult:
            MemoryAnchorResult
    ) -> String {

        let elapsed =
            anchorResult.elapsed

        if elapsed.isFutureRelative {
            return countdownText(
                from: elapsed.totalDays
            )
        }

        switch anchorResult.anchorType {

        case .birthday:
            return firstNonEmpty(
                babyAgeText(from: elapsed),
                durationText(from: elapsed)
            )

        case .marriage:
            return durationText(from: elapsed)

        case .relationship,
             .exam,
             .custom:
            return elapsed.totalDays < 100
                ? elapsedText(
                    from: elapsed.totalDays
                )
                : durationText(from: elapsed)

        case nil:
            return durationText(from: elapsed)
        }
    }

    static func durationText(
        from elapsed: MemoryElapsedTime
    ) -> String {

        let parts =
            [
                elapsed.years > 0
                    ? "\(elapsed.years)年"
                    : nil,
                elapsed.months > 0
                    ? "\(elapsed.months)个月"
                    : nil,
                elapsed.days > 0
                    ? "\(elapsed.days)天"
                    : nil
            ]
            .compactMap { $0 }

        if parts.isEmpty {
            return rawDayText(
                from: elapsed.totalDays
            )
        }

        return parts.joined()
    }

    static func rawDayText(
        from totalDays: Int
    ) -> String {

        "\(max(totalDays, 0))天"
    }

    static func elapsedText(
        from totalDays: Int
    ) -> String {

        "已过\(max(totalDays, 0))天"
    }

    static func countdownText(
        from totalDays: Int
    ) -> String {

        "还有\(max(totalDays, 0))天"
    }

    static func dayIndexText(
        from totalDays: Int
    ) -> String {

        "第\(max(totalDays, 1))天"
    }

    static func weekText(
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
#endif
}
