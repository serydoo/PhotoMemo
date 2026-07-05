import Foundation

final class TemplateVariableEngine {

    private static let tokenRegex =
        try? NSRegularExpression(
            pattern: #"\{\{([a-zA-Z0-9_\-]+)\}\}"#
        )

    func render(
        _ template: String,
        context: MetadataContext
    ) -> String {

        render(
            template,
            lookup: MetadataContextExpressionLookup(
                metadataContext: context
            )
        )
    }

    func render(
        _ template: String,
        lookup: any ExpressionLookup
    ) -> String {

        guard template.contains("{{") else {
            return template
        }

        var result = template

        guard let regex = Self.tokenRegex else {
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
                lookup
                .value(
                    for: ExpressionToken(
                        rawValue: key
                    )
                )?
                .resolvedText
                ?? ""

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
