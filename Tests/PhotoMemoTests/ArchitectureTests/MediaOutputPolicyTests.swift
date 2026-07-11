import Testing
import UniformTypeIdentifiers
@testable import PhotoMemo

@Suite("Media output policy")
struct MediaOutputPolicyTests {

    @Test("Keeps compatible still-image source formats when automatic")
    func keepsCompatibleStillImageSourceFormatsWhenAutomatic() throws {
        let policy =
            MediaOutputPolicy.standard

        #expect(
            try policy.plan(
                for: .stillImage,
                sourceContentType: .jpeg,
                preference: .automatic
            ) == .stillImage(
                imageType: .jpeg
            )
        )
        #expect(
            try policy.plan(
                for: .stillImage,
                sourceContentType: .png,
                preference: .automatic
            ) == .stillImage(
                imageType: .png
            )
        )
        #expect(
            try policy.plan(
                for: .stillImage,
                sourceContentType: .heic,
                preference: .automatic
            ) == .stillImage(
                imageType: .heic
            )
        )
    }

    @Test("Falls back to HEIC when still-image source format is not an output format")
    func fallsBackToHEICForUnsupportedStillOutputSourceFormats() throws {
        let tiffPlan =
            try MediaOutputPolicy.standard.plan(
                for: .stillImage,
                sourceContentType: .tiff,
                preference: .sourceCompatible
            )

        #expect(
            tiffPlan == .stillImage(
                imageType: .heic
            )
        )
    }

    @Test("Honors explicit still-image output preferences")
    func honorsExplicitStillImageOutputPreferences() throws {
        let policy =
            MediaOutputPolicy.standard

        #expect(
            try policy.plan(
                for: .stillImage,
                sourceContentType: .heic,
                preference: .jpeg
            ) == .stillImage(
                imageType: .jpeg
            )
        )
        #expect(
            try policy.plan(
                for: .stillImage,
                sourceContentType: .jpeg,
                preference: .png
            ) == .stillImage(
                imageType: .png
            )
        )
    }

    @Test("Routes RAW output to rendered still formats rather than RAW copy")
    func routesRawOutputToRenderedStillFormats() throws {
        let policy =
            MediaOutputPolicy.standard

        #expect(
            try policy.plan(
                for: .rawStillImage,
                sourceContentType:
                    UTType(filenameExtension: "dng"),
                preference: .automatic
            ) == .stillImage(
                imageType: .heic
            )
        )
        #expect(
            try policy.plan(
                for: .rawStillImage,
                sourceContentType:
                    UTType(filenameExtension: "dng"),
                preference: .png
            ) == .stillImage(
                imageType: .png
            )
        )
        #expect(
            try policy.plan(
                for: .rawStillImage,
                sourceContentType:
                    UTType(exportedAs: "com.apple.proraw"),
                preference: .jpeg
            ) == .stillImage(
                imageType: .jpeg
            )
        )
    }

    @Test("Plans Live Photo output as a motion-preserving HEIC and MOV pair")
    func plansLivePhotoOutputAsMotionPreservingPair() throws {
        let plan =
            try MediaOutputPolicy.standard.plan(
                for: .livePhoto,
                sourceContentType: .heic,
                preference: .automatic
            )

        guard case let .livePhotoPair(
            stillImageType,
            pairedVideoType
        ) = plan else {
            Issue.record(
                "Expected Live Photo pair output plan"
            )
            return
        }

        #expect(stillImageType == .heic)
        #expect(
            pairedVideoType.identifier
                == "com.apple.quicktime-movie"
        )
        #expect(plan.preservesLivePhotoMotion)
    }

    @Test("Rejects JPEG and PNG Live Photo preferences when motion preservation is required")
    func rejectsIncompatibleLivePhotoStillOnlyPreferences() throws {
        do {
            _ = try MediaOutputPolicy.standard.plan(
                for: .livePhoto,
                sourceContentType: .heic,
                preference: .jpeg
            )
            Issue.record(
                "Expected JPEG Live Photo preference to be rejected"
            )
        } catch let error as MediaOutputPlanningError {
            #expect(
                error ==
                    .livePhotoMotionRequiresPairedHEICOutput(
                        requested: .jpeg
                    )
            )
        }

        do {
            _ = try MediaOutputPolicy.standard.plan(
                for: .livePhoto,
                sourceContentType: .heic,
                preference: .png
            )
            Issue.record(
                "Expected PNG Live Photo preference to be rejected"
            )
        } catch let error as MediaOutputPlanningError {
            #expect(
                error ==
                    .livePhotoMotionRequiresPairedHEICOutput(
                        requested: .png
                    )
            )
        }
    }

    @Test("Allows explicit Live Photo static extraction into still-image formats")
    func allowsLivePhotoStaticExtractionIntoStillImageFormats() throws {
        let jpegPlan =
            try MediaOutputPolicy.standard.plan(
                for: .livePhoto,
                sourceContentType: .heic,
                intent:
                    MediaProcessingIntent(
                        motionMode: .stillImageOnly,
                        outputPreference: .jpeg
                    )
            )

        #expect(
            jpegPlan == .stillImage(
                imageType: .jpeg
            )
        )
        #expect(!jpegPlan.preservesLivePhotoMotion)

        let automaticPlan =
            try MediaOutputPolicy.standard.plan(
                for: .livePhoto,
                sourceContentType: .heic,
                intent:
                    MediaProcessingIntent(
                        motionMode: .stillImageOnly,
                        outputPreference: .automatic
                    )
            )

        #expect(
            automaticPlan == .stillImage(
                imageType: .heic
            )
        )
    }

    @Test("Maps V1 output mode choices to Live Photo processing intent")
    func mapsV1OutputModeChoicesToLivePhotoProcessingIntent() throws {
        let originalFormatIntent =
            V1MediaOutputMode
            .originalFormat
            .mediaProcessingIntent
        let staticImageIntent =
            V1MediaOutputMode
            .staticImage
            .mediaProcessingIntent

        #expect(
            originalFormatIntent.motionMode == .automatic
        )
        #expect(
            originalFormatIntent.outputPreference
                == .sourceCompatible
        )
        #expect(
            staticImageIntent.motionMode == .stillImageOnly
        )
        #expect(
            staticImageIntent.outputPreference
                == .sourceCompatible
        )

        #expect(
            try MediaOutputPolicy.standard.plan(
                for: .livePhoto,
                sourceContentType: .heic,
                intent: originalFormatIntent
            )
            .preservesLivePhotoMotion
        )
        #expect(
            try MediaOutputPolicy.standard.plan(
                for: .livePhoto,
                sourceContentType: .heic,
                intent: staticImageIntent
            )
            == .stillImage(
                imageType: .heic
            )
        )
    }

    @Test("Batch configuration snapshot preserves V1 media output mode")
    func batchConfigurationSnapshotPreservesV1MediaOutputMode() {
        let snapshot =
            BatchConfigurationSnapshot(
                template:
                    .classicWhite.normalizedForEditing,
                badge: nil,
                anchor: nil,
                shouldWritePhotoDescription: false,
                photoDescriptionOverride: "",
                selectedAlbumIdentifier: "",
                mediaOutputModeRawValue:
                    V1MediaOutputMode
                    .staticImage
                    .rawValue
            )

        #expect(
            snapshot.v1MediaOutputMode == .staticImage
        )
    }

    @Test("Rejects unsupported media routes")
    func rejectsUnsupportedMediaRoutes() throws {
        do {
            _ = try MediaOutputPolicy.standard.plan(
                for: .unsupported,
                sourceContentType: nil,
                preference: .automatic
            )
            Issue.record(
                "Expected unsupported route to be rejected"
            )
        } catch let error as MediaOutputPlanningError {
            #expect(
                error == .unsupportedRoute(
                    .unsupported
                )
            )
        }
    }
}
