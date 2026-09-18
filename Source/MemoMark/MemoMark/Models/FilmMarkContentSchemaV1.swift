import Foundation

/// Authored FM content, owned by the configuration editor rather than the
/// renderer. The durable representation is layout-independent; TemplateArea
/// is created only by the compatibility adapter used by the existing text
/// block engine.
struct FilmMarkContentSchemaV2: Codable, Hashable {
    let schemaVersion: Int
    var primaryOutputItems: [TemplateItem]

    init(primaryOutput: TemplateArea) {
        self.schemaVersion = 2
        self.primaryOutputItems = primaryOutput.items
    }

    init(primaryOutputItems: [TemplateItem]) {
        self.schemaVersion = 2
        self.primaryOutputItems = primaryOutputItems
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, primaryOutputItems, primaryOutput
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let version = try container.decode(Int.self, forKey: .schemaVersion)
        switch version {
        case 1:
            // V1 stored a TemplateArea. Read it once and immediately move
            // the authored items into the layout-independent V2 carrier.
            self.init(
                primaryOutputItems: try container.decode(
                    TemplateArea.self,
                    forKey: .primaryOutput
                ).items
            )
        case 2:
            self.init(
                primaryOutputItems: try container.decode(
                    [TemplateItem].self,
                    forKey: .primaryOutputItems
                )
            )
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .schemaVersion, in: container,
                debugDescription: "Unsupported FilmMark content schema: \(version)"
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(2, forKey: .schemaVersion)
        try container.encode(primaryOutputItems, forKey: .primaryOutputItems)
    }

    /// Compatibility view for editor and test code that still needs a
    /// TemplateArea-shaped value. It is never encoded as the FM truth.
    var primaryOutput: TemplateArea {
        TemplateArea(name: "FilmMark", items: primaryOutputItems)
    }

    /// Runtime adapter for the established editor/composition pipeline only.
    /// Its legacy layout regions are never persisted as FM layout decisions.
    func compositionTemplate(basedOn template: Template) -> Template {
        var result = template
        result.leftTopArea = primaryOutput
        result.leftBottomArea.items = []
        result.rightTopArea.items = []
        result.rightBottomArea.items = []
        result.badgeArea.items = []
        return result
    }
}

/// Source compatibility for the first FM prototype. New code should name the
/// current schema explicitly so a future migration remains visible.
typealias FilmMarkContentSchemaV1 = FilmMarkContentSchemaV2
