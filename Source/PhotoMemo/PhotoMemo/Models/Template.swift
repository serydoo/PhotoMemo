import Foundation

struct Template: Identifiable, Codable, Hashable {

    let id: UUID

    var name: String

    var leftTopArea: TemplateArea

    var leftBottomArea: TemplateArea

    var rightTopArea: TemplateArea

    var rightBottomArea: TemplateArea

    var badgeArea: TemplateArea

    init(
        id: UUID = UUID(),
        name: String,
        leftTopArea: TemplateArea,
        leftBottomArea: TemplateArea,
        rightTopArea: TemplateArea,
        rightBottomArea: TemplateArea,
        badgeArea: TemplateArea
    ) {
        self.id = id
        self.name = name
        self.leftTopArea = leftTopArea
        self.leftBottomArea = leftBottomArea
        self.rightTopArea = rightTopArea
        self.rightBottomArea = rightBottomArea
        self.badgeArea = badgeArea
    }
}

extension Template {

    static let classicWhite = Template(
        name: "Classic White",
        leftTopArea: .leftTop,
        leftBottomArea: .leftBottom,
        rightTopArea: .rightTop,
        rightBottomArea: .rightBottom,
        badgeArea: .badge
    )
}
