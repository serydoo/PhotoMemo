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

        MemoryVariableProvider().build(
            from: MemoryContext(
                metadata: card.metadata,
                anchor: card.anchor,
                anchorResult: card.anchorResult,
                story: card.story
            )
        )
    }
}
