import Foundation
import Testing
@testable import PhotoMemo

@Suite("Location Expression Phase 2")
struct LocationExpressionPhase2Tests {

    @Test("formats address presentation modes")
    func formatsAddressPresentationModes() {
        let context =
            LocationContext(
                address: LocationAddress(
                    country: "China",
                    province: "Sample Province",
                    city: "Sample City",
                    district: "Sample District"
                )
            )

        let formatter =
            LocationFormatter()

        #expect(
            formatter.format(
                context: context,
                mode: .provinceCity
            ) == "Sample Province · Sample City"
        )

        #expect(
            formatter.format(
                context: context,
                mode: .cityDistrict
            ) == "Sample City · Sample District"
        )

        #expect(
            formatter.format(
                context: context,
                mode: .provinceCityDistrict
            ) == "Sample Province · Sample City · Sample District"
        )
    }

    @Test("formats coordinate mode without depending on fallback strategy")
    func formatsCoordinateMode() {
        let context =
            LocationContext(
                coordinate: LocationCoordinate(
                    latitude: 31.2304164,
                    longitude: 121.4737012
                )
            )

        let formatted =
            LocationFormatter()
            .format(
                context: context,
                mode: .coordinate
            )

        #expect(formatted == "31.230416, 121.473701")
    }

    @Test("deduplicates repeated hierarchy values")
    func deduplicatesRepeatedHierarchyValues() {
        let context =
            LocationContext(
                address: LocationAddress(
                    province: "Shanghai",
                    city: "Shanghai",
                    district: "Pudong"
                )
            )

        let formatted =
            LocationFormatter()
            .format(
                context: context,
                mode: .provinceCityDistrict
            )

        #expect(formatted == "Shanghai · Pudong")
    }

    @Test("does not fallback to coordinate for address modes")
    func doesNotFallbackToCoordinateForAddressModes() {
        let context =
            LocationContext(
                coordinate: LocationCoordinate(
                    latitude: 31.2304164,
                    longitude: 121.4737012
                )
            )

        let formatted =
            LocationFormatter()
            .format(
                context: context,
                mode: .provinceCity
            )

        #expect(formatted.isEmpty)
    }
}
