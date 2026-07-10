import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import PhotoMemo

@Suite("Still image metadata writer contract")
struct StillImageMetadataWriterContractTests {

    @Test("Builds a still-image metadata write plan without touching files")
    func buildsStillImageMetadataWritePlanWithoutTouchingFiles() throws {
        let sourceURL =
            URL(fileURLWithPath: "/tmp/source.HEIC")
        let renderedURL =
            URL(fileURLWithPath: "/tmp/rendered.HEIC")
        let destinationURL =
            URL(fileURLWithPath: "/tmp/output.HEIC")

        let policy =
            MetadataPolicyResolver.standard.plan(
                for:
                    MediaProcessingPlan(
                        route: .stillImage,
                        sourceContentType: .heic,
                        outputPlan:
                            .stillImage(
                                imageType: .heic
                            ),
                        preservesLivePhotoMotion: false,
                        requiresLivePhotoPairedResources: false
                    )
            )
        let planner =
            StillImageMetadataWritePlanner.standard

        let plan =
            try planner.plan(
                StillImageMetadataWriteRequest(
                    sourceImageURL: sourceURL,
                    renderedImageURL: renderedURL,
                    destinationImageURL: destinationURL,
                    outputImageType: .heic,
                    outputPixelWidth: 4032,
                    outputPixelHeight: 3300,
                    policyPlan: policy
                )
            )

        #expect(plan.sourceImageURL == sourceURL)
        #expect(plan.renderedImageURL == renderedURL)
        #expect(plan.destinationImageURL == destinationURL)
        #expect(plan.outputImageType == .heic)
        #expect(plan.outputPixelWidth == 4032)
        #expect(plan.outputPixelHeight == 3300)
        #expect(plan.shouldCopySourceMetadata)
        #expect(plan.shouldCopyRenderedPixels)
        #expect(plan.preserves(.exif))
        #expect(plan.preserves(.gpsLocation))
        #expect(plan.preserves(.appleMakerMetadata))
        #expect(plan.overrides(.pixelDimensions))
        #expect(plan.overrides(.orientation))
        #expect(plan.removes(.livePhotoPairingIdentifier))
        #expect(plan.warnings.isEmpty)
    }

    @Test("Carries PNG metadata limitation warnings into the write plan")
    func carriesPNGWarningsIntoWritePlan() throws {
        let policy =
            MetadataPolicyResolver.standard.plan(
                for:
                    MediaProcessingPlan(
                        route: .stillImage,
                        sourceContentType: .jpeg,
                        outputPlan:
                            .stillImage(
                                imageType: .png
                            ),
                        preservesLivePhotoMotion: false,
                        requiresLivePhotoPairedResources: false
                    )
            )

        let plan =
            try StillImageMetadataWritePlanner.standard.plan(
                StillImageMetadataWriteRequest(
                    sourceImageURL:
                        URL(fileURLWithPath: "/tmp/source.jpg"),
                    renderedImageURL:
                        URL(fileURLWithPath: "/tmp/rendered.png"),
                    destinationImageURL:
                        URL(fileURLWithPath: "/tmp/output.png"),
                    outputImageType: .png,
                    outputPixelWidth: 2000,
                    outputPixelHeight: 1500,
                    policyPlan: policy
                )
            )

        #expect(plan.outputImageType == .png)
        #expect(plan.preserves(.captureDate))
        #expect(plan.preserves(.colorProfile))
        #expect(plan.removes(.quickTimeContentIdentifier))
        #expect(!plan.warnings.isEmpty)
    }

    @Test("Rejects Live Photo pair policies in the still-image writer contract")
    func rejectsLivePhotoPairPolicies() throws {
        let livePhotoPolicy =
            MetadataPolicyResolver.standard.plan(
                for:
                    MediaProcessingPlan(
                        route: .livePhoto,
                        sourceContentType: .heic,
                        outputPlan:
                            .livePhotoPair(
                                stillImageType: .heic,
                                pairedVideoType:
                                    UTType(
                                        "com.apple.quicktime-movie"
                                    )
                                    ?? .movie
                            ),
                        preservesLivePhotoMotion: true,
                        requiresLivePhotoPairedResources: true
                    )
            )

        do {
            _ = try StillImageMetadataWritePlanner
                .standard
                .plan(
                    StillImageMetadataWriteRequest(
                        sourceImageURL:
                            URL(fileURLWithPath: "/tmp/source.heic"),
                        renderedImageURL:
                            URL(fileURLWithPath: "/tmp/rendered.heic"),
                        destinationImageURL:
                            URL(fileURLWithPath: "/tmp/output.heic"),
                        outputImageType: .heic,
                        outputPixelWidth: 4032,
                        outputPixelHeight: 3300,
                        policyPlan:
                            livePhotoPolicy
                    )
                )
            Issue.record(
                "Expected still-image writer to reject a Live Photo pair policy"
            )
        } catch let error as StillImageMetadataWritePlanningError {
            #expect(
                error == .unsupportedPolicyTargets(
                    [
                        .livePhotoStill,
                        .livePhotoVideo
                    ]
                )
            )
        }
    }

    @Test("Revises still-image metadata properties without writing files")
    func revisesStillImageMetadataPropertiesWithoutWritingFiles() throws {
        let policy =
            MetadataPolicyResolver.standard.plan(
                for:
                    MediaProcessingPlan(
                        route: .stillImage,
                        sourceContentType: .jpeg,
                        outputPlan:
                            .stillImage(
                                imageType: .jpeg
                            ),
                        preservesLivePhotoMotion: false,
                        requiresLivePhotoPairedResources: false
                    )
            )
        let plan =
            try StillImageMetadataWritePlanner
                .standard
                .plan(
                    StillImageMetadataWriteRequest(
                        sourceImageURL:
                            URL(fileURLWithPath: "/tmp/source.jpg"),
                        renderedImageURL:
                            URL(fileURLWithPath: "/tmp/rendered.jpg"),
                        destinationImageURL:
                            URL(fileURLWithPath: "/tmp/output.jpg"),
                        outputImageType: .jpeg,
                        outputPixelWidth: 4032,
                        outputPixelHeight: 3300,
                        policyPlan: policy
                    )
                )

        let revised =
            ImageIOStillImageMetadataPropertyReviser()
                .revisedProperties(
                    from: [
                        kCGImagePropertyPixelWidth: 3024,
                        kCGImagePropertyPixelHeight: 4032,
                        kCGImagePropertyOrientation: 6,
                        kCGImagePropertyExifDictionary: [
                            kCGImagePropertyExifPixelXDimension:
                                3024,
                            kCGImagePropertyExifPixelYDimension:
                                4032,
                            kCGImagePropertyExifLensModel:
                                "iPhone Lens"
                        ],
                        kCGImagePropertyGPSDictionary: [
                            kCGImagePropertyGPSLatitude:
                                22.543096
                        ],
                        kCGImagePropertyMakerAppleDictionary: [
                            "17" as CFString:
                                "live-photo-pair",
                            "31" as CFString:
                                "keep-me"
                        ],
                        ImageIOStillImageMetadataPropertyReviser
                            .quickTimeMetadataKey:
                            [
                                "com.apple.quicktime.content.identifier":
                                    "pair-id"
                            ]
                    ],
                    plan: plan
                )
        let exif =
            revised[
                kCGImagePropertyExifDictionary
            ] as? [CFString: Any] ?? [:]
        let gps =
            revised[
                kCGImagePropertyGPSDictionary
            ] as? [CFString: Any] ?? [:]
        let makerApple =
            revised[
                kCGImagePropertyMakerAppleDictionary
            ] as? [CFString: Any] ?? [:]

        #expect(
            revised[
                kCGImagePropertyPixelWidth
            ] as? Int == 4032
        )
        #expect(
            revised[
                kCGImagePropertyPixelHeight
            ] as? Int == 3300
        )
        #expect(
            revised[
                kCGImagePropertyOrientation
            ] as? Int == 1
        )
        #expect(
            exif[
                kCGImagePropertyExifPixelXDimension
            ] as? Int == 4032
        )
        #expect(
            exif[
                kCGImagePropertyExifPixelYDimension
            ] as? Int == 3300
        )
        #expect(
            exif[
                kCGImagePropertyExifLensModel
            ] as? String == "iPhone Lens"
        )
        #expect(
            gps[
                kCGImagePropertyGPSLatitude
            ] as? Double == 22.543096
        )
        #expect(
            makerApple[
                "17" as CFString
            ] == nil
        )
        #expect(
            makerApple[
                "31" as CFString
            ] as? String == "keep-me"
        )
        #expect(
            revised[
                ImageIOStillImageMetadataPropertyReviser
                    .quickTimeMetadataKey
            ] == nil
        )
    }

    @Test("Revises HEIC metadata while preserving non-pairing Apple metadata")
    func revisesHEICMetadataPreservingAppleMetadataWithoutPairing() throws {
        let policy =
            MetadataPolicyResolver.standard.plan(
                for:
                    MediaProcessingPlan(
                        route: .stillImage,
                        sourceContentType: .heic,
                        outputPlan:
                            .stillImage(
                                imageType: .heic
                            ),
                        preservesLivePhotoMotion: false,
                        requiresLivePhotoPairedResources: false
                    )
            )
        let plan =
            try StillImageMetadataWritePlanner
                .standard
                .plan(
                    StillImageMetadataWriteRequest(
                        sourceImageURL:
                            URL(fileURLWithPath: "/tmp/source.heic"),
                        renderedImageURL:
                            URL(fileURLWithPath: "/tmp/rendered.heic"),
                        destinationImageURL:
                            URL(fileURLWithPath: "/tmp/output.heic"),
                        outputImageType: .heic,
                        outputPixelWidth: 4032,
                        outputPixelHeight: 3704,
                        policyPlan: policy
                    )
                )

        let revised =
            ImageIOStillImageMetadataPropertyReviser()
                .revisedProperties(
                    from: [
                        kCGImagePropertyPixelWidth: 3024,
                        kCGImagePropertyPixelHeight: 4032,
                        kCGImagePropertyOrientation: 6,
                        kCGImagePropertyExifDictionary: [
                            kCGImagePropertyExifPixelXDimension:
                                3024,
                            kCGImagePropertyExifPixelYDimension:
                                4032
                        ],
                        kCGImagePropertyMakerAppleDictionary: [
                            "17" as CFString:
                                "live-photo-pair",
                            "31" as CFString:
                                "keep-heic-apple-metadata"
                        ],
                        ImageIOStillImageMetadataPropertyReviser
                            .quickTimeMetadataKey:
                            [
                                "com.apple.quicktime.content.identifier":
                                    "pair-id"
                            ]
                    ],
                    plan: plan
                )
        let makerApple =
            revised[
                kCGImagePropertyMakerAppleDictionary
            ] as? [CFString: Any] ?? [:]

        #expect(
            revised[
                kCGImagePropertyPixelWidth
            ] as? Int == 4032
        )
        #expect(
            revised[
                kCGImagePropertyPixelHeight
            ] as? Int == 3704
        )
        #expect(
            revised[
                kCGImagePropertyOrientation
            ] as? Int == 1
        )
        #expect(
            makerApple[
                "17" as CFString
            ] == nil
        )
        #expect(
            makerApple[
                "31" as CFString
            ] as? String == "keep-heic-apple-metadata"
        )
        #expect(
            revised[
                ImageIOStillImageMetadataPropertyReviser
                    .quickTimeMetadataKey
            ] == nil
        )
    }

    @Test("Preserves non-ASCII HEIC UserComment while revising metadata without writing files")
    func preservesNonASCIIHEICUserCommentWithoutWritingFiles() throws {
        let expectedComment =
            "右下默认说明"
        let policy =
            MetadataPolicyResolver.standard.plan(
                for:
                    MediaProcessingPlan(
                        route: .stillImage,
                        sourceContentType: .heic,
                        outputPlan:
                            .stillImage(
                                imageType: .heic
                            ),
                        preservesLivePhotoMotion: false,
                        requiresLivePhotoPairedResources: false
                    )
            )
        let plan =
            try StillImageMetadataWritePlanner
                .standard
                .plan(
                    StillImageMetadataWriteRequest(
                        sourceImageURL:
                            URL(fileURLWithPath: "/tmp/source.heic"),
                        renderedImageURL:
                            URL(fileURLWithPath: "/tmp/rendered.heic"),
                        destinationImageURL:
                            URL(fileURLWithPath: "/tmp/output.heic"),
                        outputImageType: .heic,
                        outputPixelWidth: 4032,
                        outputPixelHeight: 3024,
                        policyPlan: policy
                    )
                )

        let revised =
            ImageIOStillImageMetadataPropertyReviser()
            .revisedProperties(
                from: [
                    kCGImagePropertyExifDictionary: [
                        "UserComment" as CFString:
                            expectedComment
                    ]
                ],
                plan: plan
            )
        let exif =
            try #require(
                revised[
                    kCGImagePropertyExifDictionary
                ] as? [CFString: Any]
            )

        #expect(
            exif[
                "UserComment" as CFString
            ] as? String == expectedComment
        )
    }

    @Test("Removes numeric MakerApple Live Photo pairing keys")
    func removesNumericMakerAppleLivePhotoPairingKeys() {
        var properties: [CFString: Any] = [
            kCGImagePropertyMakerAppleDictionary: [
                AnyHashable(17):
                    "numeric-live-photo-pair",
                AnyHashable("31"):
                    "keep-me"
            ]
        ]

        ImageIOStillImageMetadataCleanup
            .removeAppleLivePhotoPairingIdentifier(
                from: &properties
            )

        let makerApple =
            properties[
                kCGImagePropertyMakerAppleDictionary
            ] as? [AnyHashable: Any] ?? [:]

        #expect(
            makerApple[
                AnyHashable(17)
            ] == nil
        )
        #expect(
            makerApple[
                AnyHashable("31")
            ] as? String == "keep-me"
        )
    }

    @Test("Revises PNG metadata using the container-limited policy")
    func revisesPNGMetadataUsingContainerLimitedPolicy() throws {
        let policy =
            MetadataPolicyResolver.standard.plan(
                for:
                    MediaProcessingPlan(
                        route: .stillImage,
                        sourceContentType: .heic,
                        outputPlan:
                            .stillImage(
                                imageType: .png
                            ),
                        preservesLivePhotoMotion: false,
                        requiresLivePhotoPairedResources: false
                    )
            )
        let plan =
            try StillImageMetadataWritePlanner
                .standard
                .plan(
                    StillImageMetadataWriteRequest(
                        sourceImageURL:
                            URL(fileURLWithPath: "/tmp/source.heic"),
                        renderedImageURL:
                            URL(fileURLWithPath: "/tmp/rendered.png"),
                        destinationImageURL:
                            URL(fileURLWithPath: "/tmp/output.png"),
                        outputImageType: .png,
                        outputPixelWidth: 2048,
                        outputPixelHeight: 1536,
                        policyPlan: policy
                    )
                )

        let revised =
            ImageIOStillImageMetadataPropertyReviser()
                .revisedProperties(
                    from: [
                        kCGImagePropertyPixelWidth: 3024,
                        kCGImagePropertyPixelHeight: 4032,
                        kCGImagePropertyOrientation: 8,
                        kCGImagePropertyGPSDictionary: [
                            kCGImagePropertyGPSLongitude:
                                113.943062
                        ],
                        kCGImagePropertyMakerAppleDictionary: [
                            "17" as CFString:
                                "live-photo-pair",
                            "31" as CFString:
                                "drop-for-png"
                        ],
                        ImageIOStillImageMetadataPropertyReviser
                            .quickTimeMetadataKey:
                            [
                                "com.apple.quicktime.content.identifier":
                                    "pair-id"
                            ]
                    ],
                    plan: plan
                )
        let gps =
            revised[
                kCGImagePropertyGPSDictionary
            ] as? [CFString: Any] ?? [:]

        #expect(
            revised[
                kCGImagePropertyPixelWidth
            ] as? Int == 2048
        )
        #expect(
            revised[
                kCGImagePropertyPixelHeight
            ] as? Int == 1536
        )
        #expect(
            revised[
                kCGImagePropertyOrientation
            ] as? Int == 1
        )
        #expect(
            gps[
                kCGImagePropertyGPSLongitude
            ] as? Double == 113.943062
        )
        #expect(
            revised[
                kCGImagePropertyMakerAppleDictionary
            ] == nil
        )
        #expect(
            revised[
                ImageIOStillImageMetadataPropertyReviser
                    .quickTimeMetadataKey
            ] == nil
        )
    }

    @MainActor
    @Test(
        "Writes a JPEG with source metadata and rendered output dimensions",
        .disabled(
            "Manual ImageIO regression: Xcode 26.5 macOS test runner currently hangs while finalizing logs for this fixture-writing case."
        )
    )
    func writesJPEGWithSourceMetadataAndRenderedDimensions() throws {
        let sourceURL =
            try SyntheticFixtureLibrary.fixtureURL(
                .gpsJPEG
            )
        let renderedURL =
            try SyntheticFixtureLibrary.fixtureURL(
                .lowMetadataJPEG
            )
        let renderedProperties =
            try SyntheticFixtureLibrary.properties(
                at: renderedURL
            )
        let outputWidth =
            try #require(
                renderedProperties[
                    kCGImagePropertyPixelWidth
                ] as? Int
            )
        let outputHeight =
            try #require(
                renderedProperties[
                    kCGImagePropertyPixelHeight
                ] as? Int
            )
        let temporaryFolder =
            FileManager.default.temporaryDirectory
                .appendingPathComponent(
                    "StillImageMetadataWriter-\(UUID().uuidString)",
                    isDirectory: true
                )
        try FileManager.default.createDirectory(
            at: temporaryFolder,
            withIntermediateDirectories: true
        )
        defer {
            try? FileManager.default.removeItem(
                at: temporaryFolder
            )
        }
        let destinationURL =
            temporaryFolder
                .appendingPathComponent(
                    "output.jpg"
                )
        let policy =
            MetadataPolicyResolver.standard.plan(
                for:
                    MediaProcessingPlan(
                        route: .stillImage,
                        sourceContentType: .jpeg,
                        outputPlan:
                            .stillImage(
                                imageType: .jpeg
                            ),
                        preservesLivePhotoMotion: false,
                        requiresLivePhotoPairedResources: false
                    )
            )
        let plan =
            try StillImageMetadataWritePlanner
                .standard
                .plan(
                    StillImageMetadataWriteRequest(
                        sourceImageURL: sourceURL,
                        renderedImageURL: renderedURL,
                        destinationImageURL:
                            destinationURL,
                        outputImageType: .jpeg,
                        outputPixelWidth: outputWidth,
                        outputPixelHeight: outputHeight,
                        policyPlan: policy
                    )
                )

        try ImageIOStillImageMetadataWriter()
            .write(plan)

        #expect(
            FileManager.default.fileExists(
                atPath: destinationURL.path
            )
        )

        let outputProperties =
            try SyntheticFixtureLibrary.properties(
                at: destinationURL
            )
        let outputMetadata =
            PhotoMetadataReader().read(
                from: destinationURL
            )
        let sourceMetadata =
            PhotoMetadataReader().read(
                from: sourceURL
            )
        let exif =
            outputProperties[
                kCGImagePropertyExifDictionary
            ] as? [CFString: Any] ?? [:]
        let orientation =
            outputProperties[
                kCGImagePropertyOrientation
            ] as? Int

        #expect(outputMetadata.imageWidth == outputWidth)
        #expect(outputMetadata.imageHeight == outputHeight)
        #expect(orientation == 1)
        #expect(
            exif[
                kCGImagePropertyExifPixelXDimension
            ] as? Int == outputWidth
        )
        #expect(
            exif[
                kCGImagePropertyExifPixelYDimension
            ] as? Int == outputHeight
        )
        #expect(
            outputMetadata.captureDate
            == sourceMetadata.captureDate
        )
        #expect(
            outputMetadata.deviceBrand
            == sourceMetadata.deviceBrand
        )
        #expect(
            outputMetadata.deviceModel
            == sourceMetadata.deviceModel
        )
        #expect(
            outputMetadata.lensModel
            == sourceMetadata.lensModel
        )
        #expect(
            isApproximatelyEqual(
                outputMetadata.latitude,
                sourceMetadata.latitude
            )
        )
        #expect(
            isApproximatelyEqual(
                outputMetadata.longitude,
                sourceMetadata.longitude
            )
        )
    }
}

private func isApproximatelyEqual(
    _ lhs: Double?,
    _ rhs: Double?,
    tolerance: Double = 0.000001
) -> Bool {
    guard let lhs, let rhs else {
        return lhs == nil && rhs == nil
    }

    return abs(lhs - rhs) <= tolerance
}
