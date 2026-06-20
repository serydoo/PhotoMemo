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

    static let empty = TemplateArea(
        name: "Empty",
        items: []
    )

    static let leftTop = TemplateArea(
        name: "Left Top",
        items: [
            .relationshipDeviceLine
        ]
    )

    static let leftBottom = TemplateArea(
        name: "Left Bottom",
        items: [
            .captureDateLine
        ]
    )

    static let rightTop = TemplateArea(
        name: "Right Top",
        items: [
            .cameraSummary
        ]
    )

    static let rightBottom = TemplateArea(
        name: "Right Bottom",
        items: [
            .memorySummary
        ]
    )

    static let badge = TemplateArea(
        name: "Badge",
        items: [
            .badge
        ]
    )
}
