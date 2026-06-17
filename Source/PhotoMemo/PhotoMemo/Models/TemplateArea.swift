import Foundation

struct TemplateArea: Identifiable, Codable, Hashable {

    let id: UUID

    var name: String

    var items: [TemplateItem]

    init(
        id: UUID = UUID(),
        name: String,
        items: [TemplateItem] = []
    ) {
        self.id = id
        self.name = name
        self.items = items
    }
}

extension TemplateArea {

    static let left = TemplateArea(
        name: "Left",
        items: [
            .title,
            .story
        ]
    )

    static let center = TemplateArea(
        name: "Center",
        items: [
            .badge
        ]
    )

    static let right = TemplateArea(
        name: "Right",
        items: [
            .model,
            .lens,
            .aperture,
            .shutter,
            .iso,
            .location
        ]
    )

    static let badge = TemplateArea(
        name: "Badge",
        items: [
            .badge
        ]
    )
}
