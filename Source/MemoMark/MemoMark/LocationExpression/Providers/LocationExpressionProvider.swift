import Foundation

struct LocationExpressionProvider:
    ExpressionProvider {

    static let locationToken =
        ExpressionToken(rawValue: "location")

    private let resolver: LocationResolver

    private let formatter: LocationFormatter

    init(
        resolver: LocationResolver = LocationResolver(),
        formatter: LocationFormatter = LocationFormatter()
    ) {
        self.resolver =
            resolver
        self.formatter =
            formatter
    }

    var canonicalTokens: Set<ExpressionToken> {
        [
            Self.locationToken
        ]
    }

    func expressionValue(
        for token: ExpressionToken,
        context: LocationContext,
        requestedPresentation: LocationPresentationMode,
        configuration: LocationResolutionConfiguration =
            LocationResolutionConfiguration()
    ) -> ExpressionValue? {

        guard token == Self.locationToken else {
            return nil
        }

        let resolution =
            resolver
            .resolve(
                context: context,
                requestedPresentation: requestedPresentation,
                configuration: configuration
            )

        let resolvedText =
            formatter
            .format(
                context: context,
                resolution: resolution
            )

        return ExpressionValue(
            token: token,
            resolvedText: resolvedText
        )
    }
}
