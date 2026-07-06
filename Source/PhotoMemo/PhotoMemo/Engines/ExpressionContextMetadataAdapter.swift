import Foundation

struct ExpressionContextMetadataAdapter {

    private let locationToken =
        ExpressionToken(rawValue: "location")

    private let modelToken =
        ExpressionToken(rawValue: "model")

    private let memoryToken =
        ExpressionToken(rawValue: "memory")

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

        metadataContext.set(
            expressionContext
                .value(
                    for: memoryToken
                )?
                .resolvedText,
            for: MetadataContext.Key.memorySummary
        )

        return metadataContext
    }
}
