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

    struct TimeAnchor:
        Identifiable,
        Codable,
        Hashable {

        let id: UUID
        var title: String
        var date: Date
        var note: String

        init(
            id: UUID = UUID(),
            title: String,
            date: Date,
            note: String
        ) {
            self.id = id
            self.title = title
            self.date = date
            self.note = note
        }
    }

    let id: UUID
    var identity: Identity
    var relationship: Relationship
    var definition: String
    var referenceDate: Date
    var timeAnchors: [TimeAnchor]
    var behavior: MemoryBehavior
    var decorations: [DecorationAsset]

    init(
        id: UUID = UUID(),
        identity: Identity,
        relationship: Relationship,
        definition: String = "",
        referenceDate: Date,
        timeAnchors: [TimeAnchor] = [],
        behavior: MemoryBehavior,
        decorations: [DecorationAsset]
    ) {
        self.id = id
        self.identity = identity
        self.relationship = relationship
        self.definition = definition
        self.referenceDate = referenceDate
        self.timeAnchors = timeAnchors
        self.behavior = behavior
        self.decorations = decorations
    }
}
#endif
