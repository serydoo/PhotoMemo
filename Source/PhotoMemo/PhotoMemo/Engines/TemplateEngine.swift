import Foundation

final class TemplateEngine {

    func defaultTemplate() -> Template {

        .classicWhite
    }

    func leftTopItems(
        from template: Template
    ) -> [TemplateItem] {

        template.leftTopArea.items
            .filter(\.isEnabled)
    }

    func leftBottomItems(
        from template: Template
    ) -> [TemplateItem] {

        template.leftBottomArea.items
            .filter(\.isEnabled)
    }

    func rightTopItems(
        from template: Template
    ) -> [TemplateItem] {

        template.rightTopArea.items
            .filter(\.isEnabled)
    }

    func rightBottomItems(
        from template: Template
    ) -> [TemplateItem] {

        template.rightBottomArea.items
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

        leftTopItems(from: template)
        +
        leftBottomItems(from: template)
        +
        rightTopItems(from: template)
        +
        rightBottomItems(from: template)
        +
        badgeItems(from: template)
    }
}
