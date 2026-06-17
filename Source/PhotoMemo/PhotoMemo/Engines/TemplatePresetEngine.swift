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
                leftArea: .left,
                centerArea: .center,
                rightArea: .right,
                badgeArea: .badge
            )

        case .travel:

            return Template(
                name: "Travel",
                leftArea: .left,
                centerArea: .center,
                rightArea: .right,
                badgeArea: .badge
            )

        case .film:

            return Template(
                name: "Film",
                leftArea: .left,
                centerArea: .center,
                rightArea: .right,
                badgeArea: .badge
            )

        case .family:

            return Template(
                name: "Family",
                leftArea: .left,
                centerArea: .center,
                rightArea: .right,
                badgeArea: .badge
            )
        }
    }

    func allPresets() -> [TemplatePreset] {

        TemplatePreset.allCases
    }
}
