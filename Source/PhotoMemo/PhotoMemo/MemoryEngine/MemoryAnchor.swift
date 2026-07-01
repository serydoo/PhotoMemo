import Foundation

#if !PHOTOMEMO_SHARE_EXTENSION
struct MemoryAnchor:
    Identifiable,
    Codable,
    Hashable {

    let id: UUID
    var title: String
    var date: Date
    var anchorType: AnchorType?
    var isEnabled: Bool

    init(
        id: UUID = UUID(),
        title: String,
        date: Date,
        anchorType: AnchorType? = nil,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.anchorType = anchorType
        self.isEnabled = isEnabled
    }
}
#endif
