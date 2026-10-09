import Foundation

/// Research bridge from the current RecordCard text engine into GlassCard's
/// positional projection. Production resolution must consume a frozen context
/// before Layout and Renderer, with explicit missing-value behavior.
enum GlassCardContentResolver {

    static func resolve(from card: RecordCard) -> GlassCardContentProjection {
        let blocks = CardTextBlockEngine().build(from: card)

        func value(for area: CardTextArea) -> String {
            blocks.first(where: { $0.area == area })?
                .value
                .trimmingCharacters(in: .whitespacesAndNewlines)
                ?? ""
        }

        return GlassCardContentProjection(
            leftTop: value(for: .leftTop),
            leftBottom: value(for: .leftBottom),
            rightTop: value(for: .rightTop),
            rightBottom: value(for: .rightBottom)
        )
    }
}
