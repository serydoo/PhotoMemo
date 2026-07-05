#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct ConfigurationSnapshot:
    Identifiable,
    Codable,
    Hashable {

    let id: UUID
    let createdAt: Date
    var subjectID: MemorySubject.ID
    var memorySubject: MemorySubject?
    var expression: MemoryExpression
    var decorations: [DecorationAsset]
    var primaryAnchor: MemoryAnchor?
    var smartModuleCarrierRegion: CardRegion

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        subjectID: MemorySubject.ID,
        memorySubject: MemorySubject? = nil,
        expression: MemoryExpression,
        decorations: [DecorationAsset],
        primaryAnchor: MemoryAnchor? = nil,
        smartModuleCarrierRegion: CardRegion = .slotD
    ) {
        self.id = id
        self.createdAt = createdAt
        self.subjectID = subjectID
        self.memorySubject = memorySubject
        self.expression = expression
        self.decorations = decorations
        self.primaryAnchor = primaryAnchor
        self.smartModuleCarrierRegion =
            smartModuleCarrierRegion
    }
}
#endif
