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

    static let template1 = Template(
        name: "模板 1",
        leftTopArea: .leftTop,
        leftBottomArea: .leftBottom,
        rightTopArea: .rightTop,
        rightBottomArea: TemplateArea(
            name: "Right Bottom",
            items: [
                TemplateItem(
                    type: .variable,
                    name: "Anchor Summary",
                    value: "{{anchor_summary}}"
                )
            ]
        ),
        badgeArea: .badge
    )

    static let template2 = Template(
        name: "模板 2",
        leftTopArea: TemplateArea(
            name: "Left Top",
            items: [
                .title
            ]
        ),
        leftBottomArea: TemplateArea(
            name: "Left Bottom",
            items: [
                .captureDateLine
            ]
        ),
        rightTopArea: TemplateArea(
            name: "Right Top",
            items: [
                TemplateItem(
                    type: .variable,
                    name: "Device Line",
                    value: "{{model}} · {{camera_summary}}"
                )
            ]
        ),
        rightBottomArea: TemplateArea(
            name: "Right Bottom",
            items: [
                .story
            ]
        ),
        badgeArea: .badge
    )

    static let template3 = Template(
        name: "模板 3",
        leftTopArea: TemplateArea(
            name: "Left Top",
            items: [
                TemplateItem(
                    type: .variable,
                    name: "Title Line",
                    value: "{{title}}"
                )
            ]
        ),
        leftBottomArea: TemplateArea(
            name: "Left Bottom",
            items: [
                TemplateItem(
                    type: .variable,
                    name: "Capture Date Compact",
                    value: "{{year}}.{{month}}.{{day}}"
                )
            ]
        ),
        rightTopArea: TemplateArea(
            name: "Right Top",
            items: [
                TemplateItem(
                    type: .variable,
                    name: "Gear Line",
                    value: "{{model}} · {{lens}}"
                )
            ]
        ),
        rightBottomArea: TemplateArea(
            name: "Right Bottom",
            items: [
                TemplateItem(
                    type: .variable,
                    name: "Exposure Line",
                    value: "{{focal_len_in_35mm_film}}mm f/{{aperture}} {{shutter}}s ISO{{iso}}"
                )
            ]
        ),
        badgeArea: .badge
    )

    static let classicWhite = template1
}
