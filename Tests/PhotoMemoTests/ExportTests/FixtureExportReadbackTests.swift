import Foundation
import ImageIO
import Testing
@testable import PhotoMemo

@Suite("FixtureExportReadback", .serialized)
struct FixtureExportReadbackTests {

    @MainActor
    @Test("Exports GPS fixture and preserves read-back metadata while writing description fields")
    func exportsGPSFixtureAndPreservesReadbackMetadata() async throws {

        let sourceURL =
            try SyntheticFixtureLibrary.fixtureURL(
                .gpsJPEG
            )

        let importedPhoto =
            try await PhotoImportService()
            .importPhoto(from: sourceURL)

        let configuration =
            makeConfiguration(
                shouldWriteDescription: true,
                description:
                    "Fixture export note"
            )

        let card =
            RecordCardBuildService().buildCard(
                from: importedPhoto,
                configuration: configuration
            )

        let exportURL =
            try RecordCardExportService()
            .exportToTemporaryFile(
                photo: importedPhoto,
                card: card
            )

        defer {
            try? FileManager.default.removeItem(
                at: exportURL
            )
        }

        let readback =
            PhotoMetadataReader().read(
                from: exportURL
            )

        let exportedProperties =
            try SyntheticFixtureLibrary
            .properties(at: exportURL)

        let pixelWidth =
            intValue(
                exportedProperties[
                    kCGImagePropertyPixelWidth
                ]
            )
        let pixelHeight =
            intValue(
                exportedProperties[
                    kCGImagePropertyPixelHeight
                ]
            )
        let orientation =
            intValue(
                exportedProperties[
                    kCGImagePropertyOrientation
                ]
            )

        let exif =
            exportedProperties[
                kCGImagePropertyExifDictionary
            ] as? [CFString: Any] ?? [:]
        let tiff =
            exportedProperties[
                kCGImagePropertyTIFFDictionary
            ] as? [CFString: Any] ?? [:]
        let gps =
            exportedProperties[
                kCGImagePropertyGPSDictionary
            ] as? [CFString: Any] ?? [:]
        let iptc =
            exportedProperties[
                kCGImagePropertyIPTCDictionary
            ] as? [CFString: Any] ?? [:]

        #expect(
            importedPhoto.metadata.captureDate
            == readback.captureDate
        )
        #expect(
            importedPhoto.metadata
            .captureTimezoneOffsetSeconds
            == readback
            .captureTimezoneOffsetSeconds
        )
        #expect(
            importedPhoto.metadata.deviceBrand
            == readback.deviceBrand
        )
        #expect(
            importedPhoto.metadata.deviceModel
            == readback.deviceModel
        )
        #expect(
            importedPhoto.metadata.lensModel
            == readback.lensModel
        )
        #expect(
            readback.imageWidth == pixelWidth
        )
        #expect(
            readback.imageHeight == pixelHeight
        )
        #expect(orientation == 1)
        #expect(
            intValue(
                exif[
                    kCGImagePropertyExifPixelXDimension
                ]
            ) == pixelWidth
        )
        #expect(
            intValue(
                exif[
                    kCGImagePropertyExifPixelYDimension
                ]
            ) == pixelHeight
        )
        #expect(
            stringValue(
                exif["UserComment" as CFString]
            ) == "Fixture export note"
        )
        #expect(
            stringValue(
                tiff[
                    kCGImagePropertyTIFFImageDescription
                ]
            ) == "Fixture export note"
        )
        #expect(
            stringValue(
                tiff[
                    kCGImagePropertyTIFFSoftware
                ]
            ) == "PhotoMemo"
        )
        #expect(
            stringValue(
                iptc[
                    kCGImagePropertyIPTCCaptionAbstract
                ]
            ) == "Fixture export note"
        )
        #expect(
            isApproximatelyEqual(
                readback.latitude,
                importedPhoto.metadata.latitude
            )
        )
        #expect(
            isApproximatelyEqual(
                readback.longitude,
                importedPhoto.metadata.longitude
            )
        )
        #expect(
            isApproximatelyEqual(
                readback.altitude,
                importedPhoto.metadata.altitude
            )
        )
        #expect(
            stringValue(
                gps[
                    kCGImagePropertyGPSLatitudeRef
                ]
            ) == "S"
        )
        #expect(
            stringValue(
                gps[
                    kCGImagePropertyGPSLongitudeRef
                ]
            ) == "W"
        )
    }

    @MainActor
    @Test("Suppresses export description fields for low-metadata fixtures when writing is disabled")
    func suppressesDescriptionFieldsForLowMetadataFixture() async throws {

        let sourceURL =
            try SyntheticFixtureLibrary.fixtureURL(
                .lowMetadataJPEG
            )

        let importedPhoto =
            try await PhotoImportService()
            .importPhoto(from: sourceURL)

        let configuration =
            makeConfiguration(
                shouldWriteDescription: false,
                description:
                    "Should stay absent"
            )

        let card =
            RecordCardBuildService().buildCard(
                from: importedPhoto,
                configuration: configuration
            )

        let exportURL =
            try RecordCardExportService()
            .exportToTemporaryFile(
                photo: importedPhoto,
                card: card
            )

        defer {
            try? FileManager.default.removeItem(
                at: exportURL
            )
        }

        let readback =
            PhotoMetadataReader().read(
                from: exportURL
            )

        let exportedProperties =
            try SyntheticFixtureLibrary
            .properties(at: exportURL)
        let exif =
            exportedProperties[
                kCGImagePropertyExifDictionary
            ] as? [CFString: Any] ?? [:]
        let tiff =
            exportedProperties[
                kCGImagePropertyTIFFDictionary
            ] as? [CFString: Any] ?? [:]
        let iptc =
            exportedProperties[
                kCGImagePropertyIPTCDictionary
            ] as? [CFString: Any] ?? [:]

        #expect(readback.captureDate == nil)
        #expect(readback.captureTimezoneOffsetSeconds == nil)
        #expect(readback.deviceBrand == "")
        #expect(readback.deviceModel == "")
        #expect(readback.lensModel == "")
        #expect(readback.latitude == nil)
        #expect(readback.longitude == nil)
        #expect(readback.altitude == nil)
        #expect(
            stringValue(
                exif["UserComment" as CFString]
            ) == nil
        )
        #expect(
            stringValue(
                tiff[
                    kCGImagePropertyTIFFImageDescription
                ]
            ) == nil
        )
        #expect(
            stringValue(
                iptc[
                    kCGImagePropertyIPTCCaptionAbstract
                ]
            ) == nil
        )
    }

    @MainActor
    @Test("Imports HEIC fixtures and exports readable normalized output")
    func importsHEICFixtureAndExportsReadableOutput() async throws {

        let sourceURL =
            try SyntheticFixtureLibrary.fixtureURL(
                .iphoneHEIC
            )
        let sourceProperties =
            try SyntheticFixtureLibrary
            .properties(at: sourceURL)

        let importedPhoto =
            try await PhotoImportService()
            .importPhoto(from: sourceURL)

        let configuration =
            makeConfiguration(
                shouldWriteDescription: true,
                description:
                    "HEIC fixture note"
            )

        let card =
            RecordCardBuildService().buildCard(
                from: importedPhoto,
                configuration: configuration
            )

        let exportURL =
            try RecordCardExportService()
            .exportToTemporaryFile(
                photo: importedPhoto,
                card: card
            )

        defer {
            try? FileManager.default.removeItem(
                at: exportURL
            )
        }

        let readback =
            PhotoMetadataReader().read(
                from: exportURL
            )

        let exportedProperties =
            try SyntheticFixtureLibrary
            .properties(at: exportURL)

        #expect(
            intValue(
                sourceProperties[
                    kCGImagePropertyOrientation
                ]
            ) == 6
        )
        #expect(
            intValue(
                exportedProperties[
                    kCGImagePropertyOrientation
                ]
            ) == 1
        )
        #expect(
            importedPhoto.metadata.captureDate
            == readback.captureDate
        )
        #expect(
            importedPhoto.metadata
            .captureTimezoneOffsetSeconds
            == readback
            .captureTimezoneOffsetSeconds
        )
        #expect(
            importedPhoto.metadata.deviceBrand
            == readback.deviceBrand
        )
        #expect(
            importedPhoto.metadata.deviceModel
            == readback.deviceModel
        )
        #expect(
            importedPhoto.metadata.lensModel
            == readback.lensModel
        )
        #expect(
            readback.imageWidth
            == intValue(
                exportedProperties[
                    kCGImagePropertyPixelWidth
                ]
            )
        )
        #expect(
            readback.imageHeight
            == intValue(
                exportedProperties[
                    kCGImagePropertyPixelHeight
                ]
            )
        )
    }
}

private extension FixtureExportReadbackTests {

    func makeConfiguration(
        shouldWriteDescription: Bool,
        description: String
    ) -> BatchConfigurationSnapshot {

        BatchConfigurationSnapshot(
            template:
                .template1
                .normalizedForEditing,
            badge: nil,
            anchor: nil,
            shouldWritePhotoDescription:
                shouldWriteDescription,
            photoDescriptionOverride:
                description,
            selectedAlbumIdentifier: ""
        )
    }

    func intValue(
        _ value: Any?
    ) -> Int? {

        if let value = value as? Int {
            return value
        }

        if let value = value as? NSNumber {
            return value.intValue
        }

        return nil
    }

    func stringValue(
        _ value: Any?
    ) -> String? {

        value as? String
    }

    func isApproximatelyEqual(
        _ lhs: Double?,
        _ rhs: Double?,
        tolerance: Double = 0.000001
    ) -> Bool {

        switch (lhs, rhs) {

        case (nil, nil):
            return true

        case let (lhs?, rhs?):
            return abs(lhs - rhs) <= tolerance

        default:
            return false
        }
    }
}
