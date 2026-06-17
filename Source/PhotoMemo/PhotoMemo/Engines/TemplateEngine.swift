import Foundation

final class TemplateEngine {

    func defaultTemplate() -> Template {

        .classicWhite
    }

    func leftItems(
        from template: Template
    ) -> [TemplateItem] {

        template.leftArea.items
            .filter(\.isEnabled)
    }

    func centerItems(
        from template: Template
    ) -> [TemplateItem] {

        template.centerArea.items
            .filter(\.isEnabled)
    }

    func rightItems(
        from template: Template
    ) -> [TemplateItem] {

        template.rightArea.items
            .filter(\.isEnabled)
    }

    func badgeItems(
        from template: Template
    ) -> [TemplateItem] {

        template.badgeArea.items
            .filter(\.isEnabled)
    }

    func allItems(
        from template: Template
    ) -> [TemplateItem] {

        leftItems(from: template)
        +
        centerItems(from: template)
        +
        rightItems(from: template)
        +
        badgeItems(from: template)
    }
}
