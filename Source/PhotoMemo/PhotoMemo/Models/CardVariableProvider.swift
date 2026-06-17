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
                anchor.ageText,
                for: "anchor_age_text"
            )

            context.set(
                anchor.durationText,
                for: "anchor_duration_text"
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
}
