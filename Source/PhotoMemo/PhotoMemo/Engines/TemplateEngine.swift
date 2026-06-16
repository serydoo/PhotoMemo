import Foundation

final class TemplateEngine {

    func classicWhite() -> Template {

        Template(
            name: "Classic White",
            areas: [
                .areaA,
                .areaB,
                .areaC,
                .areaD,
                .badgeSlot
            ]
        )
    }

    func defaultTemplate() -> Template {
        classicWhite()
    }

    func contains(
        _ area: TemplateArea,
        in template: Template
    ) -> Bool {

        template.areas.contains(area)
    }
}
