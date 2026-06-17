import Foundation

struct Template: Identifiable, Codable, Hashable {

    let id: UUID

    var name: String

    var leftArea: TemplateArea

    var centerArea: TemplateArea

    var rightArea: TemplateArea

    var badgeArea: TemplateArea

    init(
        id: UUID = UUID(),
        name: String,
        leftArea: TemplateArea,
        centerArea: TemplateArea,
        rightArea: TemplateArea,
        badgeArea: TemplateArea
    ) {
        self.id = id
        self.name = name
        self.leftArea = leftArea
        self.centerArea = centerArea
        self.rightArea = rightArea
        self.badgeArea = badgeArea
    }
}

extension Template {

    static let classicWhite = Template(
        name: "Classic White",
        leftArea: .left,
        centerArea: .center,
        rightArea: .right,
        badgeArea: .badge
    )
}
