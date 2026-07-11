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
        let exportedImage =
            try ImageEdgeAssertionSupport.image(
                at: exportURL
            )
        let expectedOutputSize =
            ClassicWhiteRenderer.outputPixelSize(
                for: importedPhoto.metadata,
                fallbackSize:
                    importedPhoto.image.photoMemoSize
            )
        let bottomRows =
            try ImageEdgeAssertionSupport.bottomRows(
                in: exportedImage,
                count: 1
            )
        let hasExpectedBottomEdge =
            bottomRows.allSatisfy { row in
                row.isApproximatelySolid(
                    red: 244,
                    green: 244,
                    blue: 242,
                    rgbTolerance: 4
                )
            }

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
        #expect(
            expectedOutputSize.width.rounded()
            == expectedOutputSize.width
        )
        #expect(
            expectedOutputSize.height.rounded()
            == expectedOutputSize.height
        )
        #expect(
            exportedImage.width
            == Int(expectedOutputSize.width)
        )
        #expect(
            exportedImage.height
            == Int(expectedOutputSize.height)
        )
        #expect(hasExpectedBottomEdge)
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
            ) == "MemoMark"
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
        let expectedExportDescription =
            card.exportDescriptionOverride ?? ""

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
            ) != "Should stay absent"
        )
        #expect(
            stringValue(
                tiff[
                    kCGImagePropertyTIFFImageDescription
                ]
            ) != "Should stay absent"
        )
        #expect(
            stringValue(
                iptc[
                    kCGImagePropertyIPTCCaptionAbstract
                ]
            ) != "Should stay absent"
        )

        if expectedExportDescription.isEmpty {
            return
        } else {
            #expect(
                stringValue(
                    exif["UserComment" as CFString]
                ) == expectedExportDescription
            )
            #expect(
                stringValue(
                    tiff[
                        kCGImagePropertyTIFFImageDescription
                    ]
                ) == expectedExportDescription
            )
            #expect(
                stringValue(
                    iptc[
                        kCGImagePropertyIPTCCaptionAbstract
                    ]
                ) == expectedExportDescription
            )
        }
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
        let exportedPixelWidth =
            try #require(
                intValue(
                    exportedProperties[
                        kCGImagePropertyPixelWidth
                    ]
                )
            )
        let exportedPixelHeight =
            try #require(
                intValue(
                    exportedProperties[
                        kCGImagePropertyPixelHeight
                    ]
                )
            )

        #expect(
            intValue(
                sourceProperties[
                    kCGImagePropertyOrientation
                ]
            ) == 6
        )
        #expect(
            intValue(
                sourceProperties[
                    kCGImagePropertyPixelWidth
                ]
            ) == 1600
        )
        #expect(
            intValue(
                sourceProperties[
                    kCGImagePropertyPixelHeight
                ]
            ) == 1200
        )
        #expect(
            importedPhoto.metadata.imageWidth == 1200
        )
        #expect(
            importedPhoto.metadata.imageHeight == 1600
        )
        #expect(
            importedPhoto.metadata.orientation == .portrait
        )
        #expect(
            importedPhoto.image.photoMemoSize.width
            == 1200
        )
        #expect(
            importedPhoto.image.photoMemoSize.height
            == 1600
        )
        #expect(
            intValue(
                exportedProperties[
                    kCGImagePropertyOrientation
                ]
            ) == 1
        )
        #expect(
            exportedPixelHeight > exportedPixelWidth
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
            == exportedPixelWidth
        )
        #expect(
            readback.imageHeight
            == exportedPixelHeight
        )
    }

    @MainActor
    @Test("Static export removes inherited Live Photo pairing metadata")
    func staticExportRemovesInheritedLivePhotoPairingMetadata() async throws {
        let sourceURL =
            try SyntheticFixtureLibrary.fixtureURL(
                .gpsJPEG
            )
        var importedPhoto =
            try await PhotoImportService()
            .importPhoto(from: sourceURL)
        importedPhoto.sourceProperties[
            kCGImagePropertyMakerAppleDictionary
        ] = [
            "17" as CFString:
                "stale-live-photo-pair"
        ]
        importedPhoto.sourceProperties[
            ImageIOStillImageMetadataPropertyReviser
                .quickTimeMetadataKey
        ] = [
            "com.apple.quicktime.content.identifier":
                "stale-live-photo-pair"
        ]

        let card =
            RecordCardBuildService().buildCard(
                from: importedPhoto,
                configuration:
                    makeConfiguration(
                        shouldWriteDescription: true,
                        description:
                            "Static export pairing cleanup"
                    )
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

        let exportedProperties =
            try SyntheticFixtureLibrary
            .properties(at: exportURL)
        let makerApple =
            exportedProperties[
                kCGImagePropertyMakerAppleDictionary
            ] as? [CFString: Any] ?? [:]

        #expect(
            makerApple[
                "17" as CFString
            ] == nil
        )
        #expect(
            exportedProperties[
                ImageIOStillImageMetadataPropertyReviser
                    .quickTimeMetadataKey
            ] == nil
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
                .classicWhite
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
