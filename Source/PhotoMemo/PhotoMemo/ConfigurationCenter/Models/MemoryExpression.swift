#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct MemoryExpression:
    Identifiable,
    Codable,
    Hashable {

    let id: UUID
    var title: String
    var blocks: [MemoryBlock]

    init(
        id: UUID = UUID(),
        title: String,
        blocks: [MemoryBlock]
    ) {
        self.id = id
        self.title = title
        self.blocks = blocks
    }

    var displayText: String {
        blocks.map(\.value).joined()
    }
}
#endif
