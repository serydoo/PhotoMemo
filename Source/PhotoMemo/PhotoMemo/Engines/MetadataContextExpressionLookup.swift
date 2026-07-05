import Foundation

struct MetadataContextExpressionLookup:
    ExpressionLookup {

    let metadataContext: MetadataContext

    func value(
        for token: ExpressionToken
    ) -> ExpressionValue? {

        let resolvedText =
            metadataContext[
                token.rawValue
            ]

        guard !resolvedText.isEmpty else {
            return nil
        }

        return ExpressionValue(
            token: token,
            resolvedText: resolvedText
        )
    }
}
