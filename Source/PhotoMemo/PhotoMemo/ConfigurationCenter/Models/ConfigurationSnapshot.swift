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

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        subjectID: MemorySubject.ID,
        expression: MemoryExpression,
        decorations: [DecorationAsset]
    ) {
        self.id = id
        self.createdAt = createdAt
        self.subjectID = subjectID
        self.expression = expression
        self.decorations = decorations
    }
}
#endif
