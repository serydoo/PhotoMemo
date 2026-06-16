import Foundation

struct Badge: Identifiable, Codable, Hashable {

    let id: UUID

    var name: String

    var imageName: String?

    var isSystemDefault: Bool

    init(
        id: UUID = UUID(),
        name: String,
        imageName: String? = nil,
        isSystemDefault: Bool = false
    ) {
        self.id = id
        self.name = name
        self.imageName = imageName
        self.isSystemDefault = isSystemDefault
    }
}
