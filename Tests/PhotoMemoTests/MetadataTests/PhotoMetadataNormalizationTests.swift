import Foundation
import Testing
@testable import PhotoMemo

@Suite("PhotoMetadataNormalization")
struct PhotoMetadataNormalizationTests {

    @Test("Builds stable aspect ratio, megapixels, and location display")
    func buildsDerivedDisplayFields() {

        let metadata = PhotoMetadata(
            imageWidth: 4032,
            imageHeight: 3024,
            city: "Shenzhen",
            district: "Nanshan",
            province: "Guangdong",
            country: "China"
        ).normalized()

        #expect(metadata.orientationText == "横向")
        #expect(metadata.aspectRatioText == "4:3")
        #expect(metadata.megapixelsText == "12.2MP")
        #expect(metadata.locationDisplay == "China · Guangdong · Shenzhen · Nanshan")
    }

    @Test("Falls back to coordinates when no friendly location exists")
    func fallsBackToCoordinatesForLocationDisplay() {

        let metadata = PhotoMetadata(
            latitude: 22.5430964,
            longitude: 114.0578652
        ).normalized()

        #expect(metadata.locationDisplay == "22.543096, 114.057865")
    }
}
