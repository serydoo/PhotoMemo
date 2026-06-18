import Foundation

struct CardVariableProvider {

    static func build(
        from card: RecordCard
    ) -> MetadataContext {

        var context = card.context

        context.set(
            card.title,
            for: "title"
        )

        context.set(
            card.story,
            for: "story"
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
                for: "anchor_title"
            )

            context.set(
                anchor.primaryText,
                for: "anchor_primary"
            )

            context.set(
                anchor.secondaryText,
                for: "anchor_secondary"
            )

            context.set(
                anchor.summaryText,
                for: "anchor_summary"
            )

            context.set(
                smartText,
                for: "anchor_smart_text"
            )

            context.set(
                anchor.countdownText,
                for: "anchor_countdown_text"
            )

            context.set(
                anchor.ageText,
                for: "anchor_age_text"
            )

            context.set(
                anchor.durationText,
                for: "anchor_duration_text"
            )

            context.set(
                totalDaysText,
                for: "anchor_total_days_text"
            )

            context.set(
                anchor.elapsedText,
                for: "anchor_elapsed_text"
            )

            context.set(
                anchor.dayIndexText,
                for: "anchor_day_index_text"
            )

            context.set(
                anchor.weekText,
                for: "anchor_week_text"
            )

            context.set(
                anchor.monthAgeText,
                for: "anchor_month_age_text"
            )

            context.set(
                anchor.milestoneText,
                for: "anchor_milestone_text"
            )

            context.set(
                anchor.years,
                for: "anchor_years"
            )

            context.set(
                anchor.months,
                for: "anchor_months"
            )

            context.set(
                anchor.days,
                for: "anchor_days"
            )

            context.set(
                anchor.hours,
                for: "anchor_hours"
            )

            context.set(
                anchor.minutes,
                for: "anchor_minutes"
            )

            context.set(
                anchor.seconds,
                for: "anchor_seconds"
            )

            context.set(
                anchor.totalDays,
                for: "anchor_total_days"
            )
        }

        if !card.tags.isEmpty {

            context.set(
                card.tags.joined(separator: ", "),
                for: "tags"
            )
        }

        if let badge = card.badge {

            context.set(
                badge.name,
                for: "badge_name"
            )
        }

        context.set(
            captureDateDisplay(
                from: card.metadata.captureDate
            ),
            for: "capture_date_display"
        )

        context.set(
            cameraSummary(
                from: card.metadata
            ),
            for: "camera_summary"
        )

        context.set(
            memorySummary(
                from: card
            ),
            for: "memory_summary"
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
                from: card.metadata.captureDate
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
        from date: Date?
    ) -> String {

        guard let date else {
            return ""
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy.MM.dd HH:mm:ss"
        return formatter.string(from: date)
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
            return metadata.deviceModel
        }

        return segments.joined(separator: " ")
    }

    static func memorySummary(
        from card: RecordCard
    ) -> String {

        let trimmedStory =
            card.story.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        if !trimmedStory.isEmpty {
            return trimmedStory
        }

        guard let anchor = card.anchorResult else {
            return ""
        }

        return anchor.summaryText
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
}
