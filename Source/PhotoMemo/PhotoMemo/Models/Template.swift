import Foundation

struct Template: Identifiable, Codable, Hashable {

    let id: UUID

    var preset: TemplatePreset

    var name: String

    var leftTopArea: TemplateArea

    var leftBottomArea: TemplateArea

    var rightTopArea: TemplateArea

    var rightBottomArea: TemplateArea

    var badgeArea: TemplateArea

    init(
        id: UUID = UUID(),
        preset: TemplatePreset,
        name: String,
        leftTopArea: TemplateArea,
        leftBottomArea: TemplateArea,
        rightTopArea: TemplateArea,
        rightBottomArea: TemplateArea,
        badgeArea: TemplateArea
    ) {
        self.id = id
        self.preset = preset
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
        preset: .template1,
        name: "模板 1",
        leftTopArea: .leftTop,
        leftBottomArea: .leftBottom,
        rightTopArea: TemplateArea(
            name: "Right Top",
            items: [
                .deviceCameraLine
            ]
        ),
        rightBottomArea: TemplateArea(
            name: "Right Bottom",
            items: [
                .anchorAgeSentence
            ]
        ),
        badgeArea: .badge
    )

    static let template2 = Template(
        preset: .template2,
        name: "模板 2",
        leftTopArea: .leftTop,
        leftBottomArea: .leftBottom,
        rightTopArea: TemplateArea(
            name: "Right Top",
            items: [
                .deviceCameraLine
            ]
        ),
        rightBottomArea: TemplateArea(
            name: "Right Bottom",
            items: [
                .anchorDurationSentence
            ]
        ),
        badgeArea: .badge
    )

    static let template3 = Template(
        preset: .template3,
        name: "模板 3",
        leftTopArea: .leftTop,
        leftBottomArea: TemplateArea(
            name: "Left Bottom",
            items: [
                .captureDateCompact
            ]
        ),
        rightTopArea: TemplateArea(
            name: "Right Top",
            items: [
                .gearLine
            ]
        ),
        rightBottomArea: TemplateArea(
            name: "Right Bottom",
            items: [
                .anchorCountdownSentence
            ]
        ),
        badgeArea: .badge
    )

    static let classicWhite = template1

    var normalizedForEditing: Template {

        var normalized = self
        normalized.leftTopArea.items =
            normalizedItems(
                from: normalized.leftTopArea.items
            )
        normalized.leftBottomArea.items =
            normalizedItems(
                from: normalized.leftBottomArea.items
            )
        normalized.rightTopArea.items =
            normalizedItems(
                from: normalized.rightTopArea.items
            )
        normalized.rightBottomArea.items =
            normalizedItems(
                from: normalized.rightBottomArea.items
            )
        normalized.badgeArea.items =
            normalizedItems(
                from: normalized.badgeArea.items
            )
        return normalized
    }

    private func normalizedItems(
        from items: [TemplateItem]
    ) -> [TemplateItem] {

        items.first.map { [$0] } ?? []
    }
}

extension Template {

    private enum CodingKeys: String, CodingKey {

        case id

        case preset

        case name

        case leftTopArea

        case leftBottomArea

        case rightTopArea

        case rightBottomArea

        case badgeArea
    }

    init(
        from decoder: Decoder
    ) throws {

        let container =
            try decoder.container(
                keyedBy: CodingKeys.self
            )

        id = try container.decode(
            UUID.self,
            forKey: .id
        )

        name = try container.decode(
            String.self,
            forKey: .name
        )

        preset =
            try container.decodeIfPresent(
                TemplatePreset.self,
                forKey: .preset
            )
            ?? TemplatePreset.infer(
                from: name
            )

        leftTopArea = try container.decode(
            TemplateArea.self,
            forKey: .leftTopArea
        )

        leftBottomArea = try container.decode(
            TemplateArea.self,
            forKey: .leftBottomArea
        )

        rightTopArea = try container.decode(
            TemplateArea.self,
            forKey: .rightTopArea
        )

        rightBottomArea = try container.decode(
            TemplateArea.self,
            forKey: .rightBottomArea
        )

        badgeArea = try container.decode(
            TemplateArea.self,
            forKey: .badgeArea
        )
    }

    func encode(
        to encoder: Encoder
    ) throws {

        var container =
            encoder.container(
                keyedBy: CodingKeys.self
            )

        try container.encode(
            id,
            forKey: .id
        )

        try container.encode(
            preset,
            forKey: .preset
        )

        try container.encode(
            name,
            forKey: .name
        )

        try container.encode(
            leftTopArea,
            forKey: .leftTopArea
        )

        try container.encode(
            leftBottomArea,
            forKey: .leftBottomArea
        )

        try container.encode(
            rightTopArea,
            forKey: .rightTopArea
        )

        try container.encode(
            rightBottomArea,
            forKey: .rightBottomArea
        )

        try container.encode(
            badgeArea,
            forKey: .badgeArea
        )
    }
}
