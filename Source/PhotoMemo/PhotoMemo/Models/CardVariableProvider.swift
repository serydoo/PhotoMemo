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

        return context
    }
}
