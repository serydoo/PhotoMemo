#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct MemorySubject:
    Identifiable,
    Codable,
    Hashable {

    struct Identity:
        Codable,
        Hashable {

        var displayName: String
        var shortName: String
    }

    struct Relationship:
        Codable,
        Hashable {

        var role: String
        var label: String
    }

    let id: UUID
    var identity: Identity
    var relationship: Relationship
    var referenceDate: Date
    var behavior: MemoryBehavior
    var decorations: [DecorationAsset]

    init(
        id: UUID = UUID(),
        identity: Identity,
        relationship: Relationship,
        referenceDate: Date,
        behavior: MemoryBehavior,
        decorations: [DecorationAsset]
    ) {
        self.id = id
        self.identity = identity
        self.relationship = relationship
        self.referenceDate = referenceDate
        self.behavior = behavior
        self.decorations = decorations
    }
}
#endif
