import Foundation

struct Template: Identifiable, Codable, Hashable {

    let id: UUID

    var name: String

    var areas: [TemplateArea]

    init(
        id: UUID = UUID(),
        name: String,
        areas: [TemplateArea]
    ) {
        self.id = id
        self.name = name
        self.areas = areas
    }
}
