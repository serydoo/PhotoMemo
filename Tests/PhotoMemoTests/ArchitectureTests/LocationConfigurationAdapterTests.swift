import Foundation
import Testing
@testable import PhotoMemo

@Suite("Location Configuration Adapter")
struct LocationConfigurationAdapterTests {

    @Test("Given location module configuration When adapted Then typed provider input is returned")
    func givenLocationModuleConfigurationWhenAdaptedThenTypedProviderInputIsReturned() throws {
        let configuration =
            ExpressionModuleConfiguration(
                token: LocationExpressionProvider.locationToken,
                options: [
                    "presentationMode": "provinceCityDistrict",
                    "allowsCoordinateFallback": "true"
                ]
            )

        let input =
            try #require(
                LocationConfigurationAdapter()
                    .providerInput(
                        from: configuration
                    )
            )

        #expect(input.requestedPresentation == .provinceCityDistrict)
        #expect(input.resolutionConfiguration.allowsCoordinateFallback)
    }

    @Test("Given invalid configuration values When adapted Then defaults are deterministic")
    func givenInvalidConfigurationValuesWhenAdaptedThenDefaultsAreDeterministic() throws {
        let configuration =
            ExpressionModuleConfiguration(
                token: LocationExpressionProvider.locationToken,
                options: [
                    "presentationMode": "nearbyPlanet",
                    "allowsCoordinateFallback": "maybe"
                ]
            )

        let input =
            try #require(
                LocationConfigurationAdapter()
                    .providerInput(
                        from: configuration
                    )
            )

        #expect(input.requestedPresentation == .provinceCity)
        #expect(!input.resolutionConfiguration.allowsCoordinateFallback)
    }

    @Test("Given non location token When adapted Then adapter returns nil")
    func givenNonLocationTokenWhenAdaptedThenAdapterReturnsNil() {
        let configuration =
            ExpressionModuleConfiguration(
                token: "memory",
                options: [
                    "presentationMode": "provinceCity"
                ]
            )

        let input =
            LocationConfigurationAdapter()
            .providerInput(
                from: configuration
            )

        #expect(input == nil)
    }

    @Test("Boundary Given adapter source When inspected Then it does not change provider or platform contracts")
    func boundaryGivenAdapterSourceWhenInspectedThenItDoesNotChangeProviderOrPlatformContracts() throws {
        let source =
            try String(
                contentsOfFile: "/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/LocationExpression/Providers/LocationConfigurationAdapter.swift",
                encoding: .utf8
            )

        #expect(source.contains("ExpressionModuleConfiguration"))
        #expect(source.contains("LocationPresentationMode"))
        #expect(source.contains("LocationResolutionConfiguration"))
        #expect(!source.contains("ExpressionContext"))
        #expect(!source.contains("ExpressionLookup"))
        #expect(!source.contains("ExpressionValue"))
        #expect(!source.contains("LocationFormatter"))
        #expect(!source.contains("LocationResolver"))
    }
}
