import Foundation

struct ExpressionContextMetadataAdapter {

    private let locationToken =
        ExpressionToken(rawValue: "location")

    func metadataContext(
        from expressionContext: ExpressionContext,
        base: MetadataContext = MetadataContext()
    ) -> MetadataContext {

        var metadataContext =
            base

        metadataContext.set(
            expressionContext
                .value(
                    for: locationToken
                )?
                .resolvedText,
            for: MetadataContext.Key.locationDisplay
        )

        return metadataContext
    }
}
