import Foundation

final class TemplatePresetEngine {

    func build(
        preset: TemplatePreset
    ) -> Template {

        switch preset {

        case .template1:

            return .template1

        case .template2:

            return .template2

        case .template3:

            return .template3
        }
    }

    func allPresets() -> [TemplatePreset] {

        TemplatePreset.allCases
    }
}
