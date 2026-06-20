import Foundation
import ImageIO
import Testing
@testable import PhotoMemo

@Suite("PhotoMetadataReader")
struct PhotoMetadataReaderTests {

    @Test("Parses capture timezone from EXIF date strings")
    func parsesCaptureTimezoneFromEXIFDateString() {

        let reader = PhotoMetadataReader()

        let metadata = reader.read(
            from: [
                kCGImagePropertyPixelWidth: 4032,
                kCGImagePropertyPixelHeight: 3024,
                kCGImagePropertyTIFFDictionary: [
                    kCGImagePropertyTIFFMake: " Apple ",
                    kCGImagePropertyTIFFModel: " iPhone 17 Pro "
                ],
                kCGImagePropertyExifDictionary: [
                    kCGImagePropertyExifDateTimeOriginal:
                        "2026-06-20T10:30:00+0800",
                    kCGImagePropertyExifLensModel:
                        " iPhone 17 Pro back triple camera 24mm f/1.78 "
                ]
            ]
        )

        #expect(metadata.captureTimezoneOffsetSeconds == 8 * 3600)
        #expect(metadata.captureTimezoneText == "UTC+08:00")
        #expect(metadata.captureDateShortText == "2026.06.20")
        #expect(metadata.captureTimeShortText == "10:30")
        #expect(metadata.deviceBrand == "Apple")
        #expect(metadata.deviceModel == "iPhone 17 Pro")
    }

    @Test("Normalizes GPS signs from hemisphere references")
    func normalizesGPSSignsFromReferenceFields() {

        let reader = PhotoMetadataReader()

        let metadata = reader.read(
            from: [
                kCGImagePropertyGPSDictionary: [
                    kCGImagePropertyGPSLatitude: 22.543096,
                    kCGImagePropertyGPSLatitudeRef: "S",
                    kCGImagePropertyGPSLongitude: 114.057865,
                    kCGImagePropertyGPSLongitudeRef: "W",
                    kCGImagePropertyGPSAltitude: 15.2,
                    kCGImagePropertyGPSAltitudeRef: 1
                ]
            ]
        )

        #expect(metadata.latitude == -22.543096)
        #expect(metadata.longitude == -114.057865)
        #expect(metadata.altitude == -15.2)
    }
}
