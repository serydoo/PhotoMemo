import Foundation
import Testing
import UniformTypeIdentifiers
@testable import PhotoMemo

@Suite("Media processing planner")
struct MediaProcessingPlannerTests {

    @Test("Plans still-image output from resolved source file type")
    func plansStillImageOutputFromResolvedSourceFileType() throws {
        let plan =
            try MediaProcessingPlanner.standard.plan(
                for: MediaProcessingInputDescriptor(
                    fileURL:
                        URL(
                            fileURLWithPath:
                                "/tmp/photo.png"
                        ),
                    pixelWidth: 3024,
                    pixelHeight: 4032
                ),
                outputPreference: .automatic
            )

        #expect(plan.route == .stillImage)
        #expect(plan.sourceContentType == .png)
        #expect(
            plan.outputPlan == .stillImage(
                imageType: .png
            )
        )
        #expect(!plan.preservesLivePhotoMotion)
        #expect(!plan.requiresLivePhotoPairedResources)
    }

    @Test("Plans RAW output as rendered still output")
    func plansRawOutputAsRenderedStillOutput() throws {
        let rawType =
            try #require(
                UTType(filenameExtension: "dng")
            )

        let plan =
            try MediaProcessingPlanner.standard.plan(
                for: MediaProcessingInputDescriptor(
                    contentType: rawType,
                    pixelWidth: 3024,
                    pixelHeight: 4032
                ),
                outputPreference: .automatic
            )

        #expect(plan.route == .rawStillImage)
        #expect(
            plan.outputPlan == .stillImage(
                imageType: .heic
            )
        )
        #expect(!plan.preservesLivePhotoMotion)
    }

    @Test("Plans broad image declarations with RAW filename as rendered HEIC output")
    func plansBroadImageDeclarationsWithRAWFilenameAsRenderedHEICOutput() throws {
        let plan =
            try MediaProcessingPlanner.standard.plan(
                for: MediaProcessingInputDescriptor(
                    contentType: .image,
                    fileURL:
                        URL(
                            fileURLWithPath:
                                "/tmp/IMG_9001.DNG"
                        ),
                    pixelWidth: 8064,
                    pixelHeight: 6048
                ),
                outputPreference: .automatic
            )

        #expect(plan.route == .rawStillImage)
        #expect(
            plan.sourceContentType?
                .conforms(to: .rawImage)
            == true
        )
        #expect(
            plan.outputPlan == .stillImage(
                imageType: .heic
            )
        )
        #expect(!plan.preservesLivePhotoMotion)
    }

    @Test("Plans Live Photo output as a motion-preserving paired output")
    func plansLivePhotoOutputAsMotionPreservingPair() throws {
        let planner =
            MediaProcessingPlanner(
                runtimeGate:
                    .internalTesting(
                        allowedRoutes: [.livePhoto]
                    )
            )
        let plan =
            try planner.plan(
                for: MediaProcessingInputDescriptor(
                    contentType: .heic,
                    pixelWidth: 4032,
                    pixelHeight: 3024,
                    isLivePhotoAsset: true
                ),
                outputPreference: .sourceCompatible
            )

        guard case let .livePhotoPair(
            stillImageType,
            pairedVideoType
        ) = plan.outputPlan else {
            Issue.record(
                "Expected Live Photo pair output plan"
            )
            return
        }

        #expect(plan.route == .livePhoto)
        #expect(stillImageType == .heic)
        #expect(
            pairedVideoType.identifier
                == "com.apple.quicktime-movie"
        )
        #expect(plan.preservesLivePhotoMotion)
        #expect(plan.requiresLivePhotoPairedResources)
    }

    @Test("Rejects Live Photo planning unless the runtime gate allows it")
    func rejectsLivePhotoPlanningUnlessRuntimeGateAllowsIt() throws {
        do {
            _ = try MediaProcessingPlanner.standard.plan(
                for: MediaProcessingInputDescriptor(
                    contentType: .heic,
                    pixelWidth: 4032,
                    pixelHeight: 3024,
                    isLivePhotoAsset: true
                ),
                outputPreference: .sourceCompatible
            )
            Issue.record(
                "Expected default planner to reject Live Photo planning"
            )
        } catch let error as MediaProcessingPlanningError {
            #expect(
                error == .routeDisabledByRuntimeGate(
                    .livePhoto
                )
            )
        } catch {
            Issue.record(
                "Received unexpected error: \(error)"
            )
        }
    }

    @Test("Rejects unsupported input before output planning")
    func rejectsUnsupportedInputBeforeOutputPlanning() throws {
        do {
            _ = try MediaProcessingPlanner.standard.plan(
                for: MediaProcessingInputDescriptor(
                    contentType: .gif,
                    pixelWidth: 1200,
                    pixelHeight: 1200
                ),
                outputPreference: .automatic
            )
            Issue.record(
                "Expected unsupported input to be rejected"
            )
        } catch let error as MediaProcessingPlanningError {
            #expect(
                error == .unsupportedInput(
                    .unsupportedFormat
                )
            )
        } catch {
            Issue.record(
                "Received unexpected error: \(error)"
            )
        }
    }

    @Test("Rejects Live Photo still-only preferences before processing")
    func rejectsLivePhotoStillOnlyPreferencesBeforeProcessing() throws {
        let planner =
            MediaProcessingPlanner(
                runtimeGate:
                    .internalTesting(
                        allowedRoutes: [.livePhoto]
                    )
            )
        do {
            _ = try planner.plan(
                for: MediaProcessingInputDescriptor(
                    contentType: .heic,
                    pixelWidth: 4032,
                    pixelHeight: 3024,
                    isLivePhotoAsset: true
                ),
                outputPreference: .jpeg
            )
            Issue.record(
                "Expected Live Photo JPEG preference to be rejected"
            )
        } catch let error as MediaProcessingPlanningError {
            #expect(
                error ==
                    .outputPlanningFailed(
                        .livePhotoMotionRequiresPairedHEICOutput(
                            requested: .jpeg
                        )
                    )
            )
        } catch {
            Issue.record(
                "Received unexpected error: \(error)"
            )
        }
    }

    @Test("Plans explicit Live Photo static extraction as still-image output")
    func plansExplicitLivePhotoStaticExtractionAsStillImageOutput() throws {
        let planner =
            MediaProcessingPlanner(
                runtimeGate:
                    .internalTesting(
                        allowedRoutes: [.livePhoto]
                    )
            )
        let plan =
            try planner.plan(
                for: MediaProcessingInputDescriptor(
                    contentType: .heic,
                    pixelWidth: 4032,
                    pixelHeight: 3024,
                    isLivePhotoAsset: true
                ),
                intent:
                    MediaProcessingIntent(
                        motionMode: .stillImageOnly,
                        outputPreference: .jpeg
                    )
            )

        #expect(plan.route == .livePhoto)
        #expect(
            plan.outputPlan == .stillImage(
                imageType: .jpeg
            )
        )
        #expect(!plan.preservesLivePhotoMotion)
        #expect(!plan.requiresLivePhotoPairedResources)
    }
}
