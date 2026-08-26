import Foundation

final class TemplatePresetEngine {

    func build(
        preset: TemplatePreset
    ) -> Template {

        .classicWhite
    }

    func allPresets() -> [TemplatePreset] {

        TemplatePreset.allCases
    }
}
