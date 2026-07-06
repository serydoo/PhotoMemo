import Foundation

struct LocationProviderInput:
    Hashable {

    var requestedPresentation: LocationPresentationMode
    var resolutionConfiguration: LocationResolutionConfiguration
}

struct LocationConfigurationAdapter {

    private enum OptionKey {
        static let presentationMode =
            "presentationMode"
        static let allowsCoordinateFallback =
            "allowsCoordinateFallback"
    }

    func providerInput(
        from configuration: ExpressionModuleConfiguration
    ) -> LocationProviderInput? {

        guard configuration.token == LocationExpressionProvider.locationToken else {
            return nil
        }

        let requestedPresentation =
            configuration.options[OptionKey.presentationMode]
                .flatMap(LocationPresentationMode.init(rawValue:))
            ?? .provinceCity

        let allowsCoordinateFallback =
            configuration.options[OptionKey.allowsCoordinateFallback]
                .flatMap(Bool.init)
            ?? false

        return LocationProviderInput(
            requestedPresentation: requestedPresentation,
            resolutionConfiguration:
                LocationResolutionConfiguration(
                    allowsCoordinateFallback: allowsCoordinateFallback
                )
        )
    }
}
