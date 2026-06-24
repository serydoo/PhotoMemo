#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct MemoryBehavior:
    Codable,
    Hashable {

    var primaryAnchor: String
    var iconStrategy: DecorationStrategy
    var badgeStrategy: DecorationStrategy
    var memoryExpression: MemoryExpression

    init(
        primaryAnchor: String,
        iconStrategy: DecorationStrategy,
        badgeStrategy: DecorationStrategy,
        memoryExpression: MemoryExpression
    ) {
        self.primaryAnchor = primaryAnchor
        self.iconStrategy = iconStrategy
        self.badgeStrategy = badgeStrategy
        self.memoryExpression = memoryExpression
    }
}
#endif
