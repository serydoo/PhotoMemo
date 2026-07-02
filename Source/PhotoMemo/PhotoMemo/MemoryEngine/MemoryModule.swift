import Foundation

#if !PHOTOMEMO_SHARE_EXTENSION
struct MemoryModule:
    Identifiable,
    Codable,
    Hashable {

    let id: UUID
    var title: String
    var blocks: [MemoryBlock]
    var renderedText: String
    var sourceAnchor: MemoryAnchor?
    var preferredRegion: CardRegion?

    init(
        id: UUID = UUID(),
        title: String,
        blocks: [MemoryBlock],
        renderedText: String,
        sourceAnchor: MemoryAnchor? = nil,
        preferredRegion: CardRegion? = nil
    ) {
        self.id = id
        self.title = title
        self.blocks = blocks
        self.renderedText = renderedText
        self.sourceAnchor = sourceAnchor
        self.preferredRegion = preferredRegion
    }
}
#endif
