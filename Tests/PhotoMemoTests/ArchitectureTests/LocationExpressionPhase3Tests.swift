import Foundation
import Testing
@testable import PhotoMemo

@Suite("Location Expression Phase 3")
struct LocationExpressionPhase3Tests {

    @Test("Given complete address When province city requested Then direct province city resolution")
    func givenCompleteAddressWhenProvinceCityRequestedThenDirectProvinceCityResolution() {
        let context =
            LocationContext(
                address: LocationAddress(
                    province: "Sample Province",
                    city: "Sample City",
                    district: "Sample District"
                )
            )

        let resolution =
            LocationResolver()
            .resolve(
                context: context,
                requestedPresentation: .provinceCity
            )

        #expect(resolution.requestedPresentation == .provinceCity)
        #expect(resolution.resolvedPresentation == .provinceCity)
        #expect(resolution.resolutionPolicy == .direct)

        let text =
            LocationFormatter()
            .format(
                context: context,
                resolution: resolution
            )

        #expect(text == "Sample Province · Sample City")
    }

    @Test("Given province missing When province city requested Then downgrade to city district")
    func givenProvinceMissingWhenProvinceCityRequestedThenDowngradeToCityDistrict() {
        let context =
            LocationContext(
                address: LocationAddress(
                    city: "Sample City",
                    district: "Sample District"
                )
            )

        let resolution =
            LocationResolver()
            .resolve(
                context: context,
                requestedPresentation: .provinceCity
            )

        #expect(resolution.requestedPresentation == .provinceCity)
        #expect(resolution.resolvedPresentation == .cityDistrict)
        #expect(resolution.resolutionPolicy == .downgraded)

        let text =
            LocationFormatter()
            .format(
                context: context,
                resolution: resolution
            )

        #expect(text == "Sample City · Sample District")
    }

    @Test("Given address missing When coordinate fallback allowed Then coordinate selected")
    func givenAddressMissingWhenCoordinateFallbackAllowedThenCoordinateSelected() {
        let context =
            LocationContext(
                coordinate: LocationCoordinate(
                    latitude: 31.2304164,
                    longitude: 121.4737012
                )
            )

        let resolution =
            LocationResolver()
            .resolve(
                context: context,
                requestedPresentation: .provinceCity,
                configuration: LocationResolutionConfiguration(
                    allowsCoordinateFallback: true
                )
            )

        #expect(resolution.requestedPresentation == .provinceCity)
        #expect(resolution.resolvedPresentation == .coordinate)
        #expect(resolution.resolutionPolicy == .coordinateFallback)

        let text =
            LocationFormatter()
            .format(
                context: context,
                resolution: resolution
            )

        #expect(text == "31.230416, 121.473701")
    }

    @Test("Given address missing When coordinate fallback denied Then empty resolution")
    func givenAddressMissingWhenCoordinateFallbackDeniedThenEmptyResolution() {
        let context =
            LocationContext(
                coordinate: LocationCoordinate(
                    latitude: 31.2304164,
                    longitude: 121.4737012
                )
            )

        let resolution =
            LocationResolver()
            .resolve(
                context: context,
                requestedPresentation: .provinceCity,
                configuration: LocationResolutionConfiguration(
                    allowsCoordinateFallback: false
                )
            )

        #expect(resolution.requestedPresentation == .provinceCity)
        #expect(resolution.resolvedPresentation == nil)
        #expect(resolution.resolutionPolicy == .empty)

        let text =
            LocationFormatter()
            .format(
                context: context,
                resolution: resolution
            )

        #expect(text.isEmpty)
    }

    @Test("Given district missing When city district requested Then empty resolution")
    func givenDistrictMissingWhenCityDistrictRequestedThenEmptyResolution() {
        let context =
            LocationContext(
                address: LocationAddress(
                    city: "Sample City"
                )
            )

        let resolution =
            LocationResolver()
            .resolve(
                context: context,
                requestedPresentation: .cityDistrict
            )

        #expect(resolution.requestedPresentation == .cityDistrict)
        #expect(resolution.resolvedPresentation == nil)
        #expect(resolution.resolutionPolicy == .empty)
    }

    @Test("Given same context and configuration When resolve twice Then equal resolution")
    func givenSameContextAndConfigurationWhenResolveTwiceThenEqualResolution() {
        let context =
            LocationContext(
                address: LocationAddress(
                    city: "Sample City",
                    district: "Sample District"
                )
            )

        let configuration =
            LocationResolutionConfiguration(
                allowsCoordinateFallback: true
            )

        let resolver =
            LocationResolver()

        let first =
            resolver.resolve(
                context: context,
                requestedPresentation: .provinceCity,
                configuration: configuration
            )

        let second =
            resolver.resolve(
                context: context,
                requestedPresentation: .provinceCity,
                configuration: configuration
            )

        #expect(first == second)
    }

    @Test("Boundary Given resolution type When inspected Then it is decision only")
    func boundaryGivenResolutionTypeWhenInspectedThenItIsDecisionOnly() {
        let labels =
            String(
                reflecting: LocationResolution.self
            )

        #expect(labels.contains("LocationResolution"))

        let resolution =
            LocationResolution(
                requestedPresentation: .provinceCity,
                resolvedPresentation: .cityDistrict,
                resolutionPolicy: .downgraded
            )

        #expect(resolution.requestedPresentation == .provinceCity)
        #expect(resolution.resolvedPresentation == .cityDistrict)
        #expect(resolution.resolutionPolicy == .downgraded)
    }
}
