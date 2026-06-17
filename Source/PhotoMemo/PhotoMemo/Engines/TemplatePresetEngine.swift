import Foundation

final class TemplatePresetEngine {

    func build(
        preset: TemplatePreset
    ) -> Template {

        switch preset {

        case .classicWhite:

            return .classicWhite

        case .dark:

            return Template(
                name: "Dark",
                leftTopArea: .leftTop,
                leftBottomArea: .leftBottom,
                rightTopArea: .rightTop,
                rightBottomArea: .rightBottom,
                badgeArea: .badge
            )

        case .travel:

            return Template(
                name: "Travel",
                leftTopArea: .leftTop,
                leftBottomArea: .leftBottom,
                rightTopArea: .rightTop,
                rightBottomArea: .rightBottom,
                badgeArea: .badge
            )

        case .film:

            return Template(
                name: "Film",
                leftTopArea: .leftTop,
                leftBottomArea: .leftBottom,
                rightTopArea: .rightTop,
                rightBottomArea: .rightBottom,
                badgeArea: .badge
            )

        case .family:

            return Template(
                name: "Family",
                leftTopArea: .leftTop,
                leftBottomArea: .leftBottom,
                rightTopArea: .rightTop,
                rightBottomArea: .rightBottom,
                badgeArea: .badge
            )
        }
    }

    func allPresets() -> [TemplatePreset] {

        TemplatePreset.allCases
    }
}
