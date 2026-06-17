import Foundation

final class TemplateVariableEngine {

    func render(
        _ template: String,
        context: MetadataContext
    ) -> String {

        var result = template

        let pattern = #"\{\{([a-zA-Z0-9_\-]+)\}\}"#

        guard let regex = try? NSRegularExpression(
            pattern: pattern
        ) else {
            return template
        }

        let matches = regex.matches(
            in: template,
            range: NSRange(
                template.startIndex...,
                in: template
            )
        )

        for match in matches.reversed() {

            guard
                let range = Range(
                    match.range(at: 1),
                    in: template
                )
            else {
                continue
            }

            let key = String(
                template[range]
            )

            let replacement =
                context[key]

            guard
                let fullRange = Range(
                    match.range(at: 0),
                    in: result
                )
            else {
                continue
            }

            result.replaceSubrange(
                fullRange,
                with: replacement
            )
        }

        return result
    }
}
