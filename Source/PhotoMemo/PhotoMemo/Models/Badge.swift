import Foundation

struct Badge: Identifiable, Codable, Hashable {

    let id: UUID

    var name: String

    var type: BadgeType

    var imageName: String?

    var imagePath: String?

    var systemSymbol: String?

    var isSystemDefault: Bool

    init(
        id: UUID = UUID(),
        name: String,
        type: BadgeType,
        imageName: String? = nil,
        imagePath: String? = nil,
        systemSymbol: String? = nil,
        isSystemDefault: Bool = false
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.imageName = imageName
        self.imagePath = imagePath
        self.systemSymbol = systemSymbol
        self.isSystemDefault = isSystemDefault
    }
}

extension Badge {

    static let none = Badge(
        name: "None",
        type: .none,
        isSystemDefault: true
    )

    static let family = Badge(
        name: "Family",
        type: .systemSymbol,
        systemSymbol: "person.2.fill",
        isSystemDefault: true
    )

    static let travel = Badge(
        name: "Travel",
        type: .systemSymbol,
        systemSymbol: "airplane",
        isSystemDefault: true
    )

    static let memory = Badge(
        name: "Memory",
        type: .systemSymbol,
        systemSymbol: "heart.fill",
        isSystemDefault: true
    )
}
