import Foundation
import Testing
@testable import PhotoMemo

@Suite("Location Expression Phase 1")
struct LocationExpressionPhase1Tests {

    @Test("builds location context from normalized photo metadata")
    func buildsLocationContextFromPhotoMetadata() {
        let metadata =
            PhotoMetadata(
                latitude: 31.230416,
                longitude: 121.473701,
                altitude: 42.5,
                city: " Shanghai ",
                district: " Pudong ",
                province: " Shanghai ",
                country: " China ",
                locationName: " Lujiazui "
            )

        let context =
            LocationContextBuilder()
            .build(
                from: metadata
            )

        #expect(context.hasGPS == true)
        #expect(context.hasAddress == true)
        #expect(context.hasPOI == true)
        #expect(context.coordinate?.latitude == 31.230416)
        #expect(context.coordinate?.longitude == 121.473701)
        #expect(context.altitudeMeters == 42.5)
        #expect(context.address?.country == "China")
        #expect(context.address?.province == "Shanghai")
        #expect(context.address?.city == "Shanghai")
        #expect(context.address?.district == "Pudong")
        #expect(context.address?.name == "Lujiazui")
    }

    @Test("does not invent GPS when metadata has incomplete coordinates")
    func doesNotInventGPSFromIncompleteCoordinates() {
        let metadata =
            PhotoMetadata(
                latitude: 31.230416,
                city: "Shanghai"
            )

        let context =
            LocationContextBuilder()
            .build(
                from: metadata
            )

        #expect(context.hasGPS == false)
        #expect(context.hasAddress == true)
        #expect(context.hasPOI == false)
        #expect(context.coordinate == nil)
        #expect(context.altitudeMeters == nil)
        #expect(context.address?.city == "Shanghai")
    }
}
