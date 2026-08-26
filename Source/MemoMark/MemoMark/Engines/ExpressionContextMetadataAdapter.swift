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

        if let locationValue =
            expressionContext
            .value(
                for: locationToken
            ) {
            metadataContext.replace(
                locationValue.resolvedText,
                for: MetadataContext.Key.locationDisplay
            )
        }

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
