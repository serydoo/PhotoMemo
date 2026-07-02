#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct ConfigurationSnapshot:
    Identifiable,
    Codable,
    Hashable {

    let id: UUID
    let createdAt: Date
    var subjectID: MemorySubject.ID
    var expression: MemoryExpression
    var decorations: [DecorationAsset]
    var primaryAnchor: MemoryAnchor?
    var smartModuleCarrierRegion: CardRegion

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        subjectID: MemorySubject.ID,
        expression: MemoryExpression,
        decorations: [DecorationAsset],
        primaryAnchor: MemoryAnchor? = nil,
        smartModuleCarrierRegion: CardRegion = .slotD
    ) {
        self.id = id
        self.createdAt = createdAt
        self.subjectID = subjectID
        self.expression = expression
        self.decorations = decorations
        self.primaryAnchor = primaryAnchor
        self.smartModuleCarrierRegion =
            smartModuleCarrierRegion
    }
}
#endif
