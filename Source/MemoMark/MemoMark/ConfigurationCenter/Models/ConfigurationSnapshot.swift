#if !MEMOMARK_SHARE_EXTENSION
import Foundation

struct ConfigurationSnapshot:
    Identifiable,
    Codable,
    Hashable {

    let id: UUID
    let createdAt: Date
    var configurationID: UUID?
    var configurationRevision: Int?
    var subjectID: MemorySubject.ID
    var memorySubject: MemorySubject?
    var expression: MemoryExpression
    var decorations: [DecorationAsset]
    var primaryAnchor: MemoryAnchor?
    var smartModuleCarrierRegion: CardRegion
    var language: MemoMarkLanguage

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        configurationID: UUID? = nil,
        configurationRevision: Int? = nil,
        subjectID: MemorySubject.ID,
        memorySubject: MemorySubject? = nil,
        expression: MemoryExpression,
        decorations: [DecorationAsset],
        primaryAnchor: MemoryAnchor? = nil,
        smartModuleCarrierRegion: CardRegion = .slotD,
        language: MemoMarkLanguage = .simplifiedChinese
    ) {
        self.id = id
        self.createdAt = createdAt
        self.configurationID = configurationID
        self.configurationRevision =
            configurationRevision
        self.subjectID = subjectID
        self.memorySubject = memorySubject
        self.expression = expression
        self.decorations = decorations
        self.primaryAnchor = primaryAnchor
        self.smartModuleCarrierRegion =
            smartModuleCarrierRegion
        self.language = language
    }
}

extension ConfigurationSnapshot {

    private enum CodingKeys: String, CodingKey {
        case id
        case createdAt
        case configurationID
        case configurationRevision
        case subjectID
        case memorySubject
        case expression
        case decorations
        case primaryAnchor
        case smartModuleCarrierRegion
        case language
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        configurationID = try container.decodeIfPresent(UUID.self, forKey: .configurationID)
        configurationRevision = try container.decodeIfPresent(Int.self, forKey: .configurationRevision)
        subjectID = try container.decode(MemorySubject.ID.self, forKey: .subjectID)
        memorySubject = try container.decodeIfPresent(MemorySubject.self, forKey: .memorySubject)
        expression = try container.decode(MemoryExpression.self, forKey: .expression)
        decorations = try container.decode([DecorationAsset].self, forKey: .decorations)
        primaryAnchor = try container.decodeIfPresent(MemoryAnchor.self, forKey: .primaryAnchor)
        smartModuleCarrierRegion = try container.decode(CardRegion.self, forKey: .smartModuleCarrierRegion)
        language = try container.decodeIfPresent(MemoMarkLanguage.self, forKey: .language) ?? .simplifiedChinese
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(configurationID, forKey: .configurationID)
        try container.encodeIfPresent(configurationRevision, forKey: .configurationRevision)
        try container.encode(subjectID, forKey: .subjectID)
        try container.encodeIfPresent(memorySubject, forKey: .memorySubject)
        try container.encode(expression, forKey: .expression)
        try container.encode(decorations, forKey: .decorations)
        try container.encodeIfPresent(primaryAnchor, forKey: .primaryAnchor)
        try container.encode(smartModuleCarrierRegion, forKey: .smartModuleCarrierRegion)
        try container.encode(language, forKey: .language)
    }
}
#endif
