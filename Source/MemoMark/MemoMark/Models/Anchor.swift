import Foundation

struct Anchor: Identifiable, Codable, Hashable {

    let id: UUID

    var type: AnchorType

    var title: String

    var date: Date

    var isCountdown: Bool

    var expressionStyle:
        MemoryAnchorExpressionStyle?

    init(
        id: UUID = UUID(),
        type: AnchorType,
        title: String,
        date: Date,
        isCountdown: Bool = false,
        expressionStyle:
            MemoryAnchorExpressionStyle? = nil
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.date = date
        self.isCountdown = isCountdown
        self.expressionStyle =
            expressionStyle
    }
}
