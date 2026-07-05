import Foundation

struct MetadataProvider:
    ExpressionProvider {

    static let modelToken =
        ExpressionToken(rawValue: "model")

    var canonicalTokens: Set<ExpressionToken> {
        [
            Self.modelToken
        ]
    }

    func expressionValue(
        for token: ExpressionToken,
        metadata: PhotoMetadata
    ) -> ExpressionValue? {

        guard token == Self.modelToken else {
            return nil
        }

        let context =
            MetadataContext.build(
                from: metadata
            )

        let resolvedText =
            context[MetadataContext.Key.model]
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !resolvedText.isEmpty else {
            return nil
        }

        return ExpressionValue(
            token: token,
            resolvedText: resolvedText
        )
    }
}
