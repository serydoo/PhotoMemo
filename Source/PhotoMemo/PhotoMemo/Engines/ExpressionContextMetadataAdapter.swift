import Foundation

struct ExpressionContextMetadataAdapter {

    private let locationToken =
        ExpressionToken(rawValue: "location")

    private let modelToken =
        ExpressionToken(rawValue: "model")

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

        metadataContext.set(
            expressionContext
                .value(
                    for: modelToken
                )?
                .resolvedText,
            for: MetadataContext.Key.model
        )

        return metadataContext
    }
}
