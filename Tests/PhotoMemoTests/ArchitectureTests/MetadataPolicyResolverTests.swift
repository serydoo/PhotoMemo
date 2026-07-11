import Testing
import UniformTypeIdentifiers
@testable import PhotoMemo

@Suite("Metadata policy resolver")
struct MetadataPolicyResolverTests {

    @Test("Resolves JPEG still policy with preservation and output overrides")
    func resolvesJPEGStillPolicy() {
        let plan =
            MetadataPolicyResolver.standard.plan(
                for:
                    MediaProcessingPlan(
                        route: .stillImage,
                        sourceContentType: .heic,
                        outputPlan:
                            .stillImage(
                                imageType: .jpeg
                            ),
                        preservesLivePhotoMotion: false,
                        requiresLivePhotoPairedResources: false
                    )
            )

        #expect(plan.identifier == "jpeg")
        #expect(plan.targets == [.jpegStill])
        #expect(plan.preserves(.exif))
        #expect(plan.preserves(.gpsLocation))
        #expect(plan.preserves(.colorProfile))
        #expect(plan.overrides(.pixelDimensions))
        #expect(plan.overrides(.orientation))
        #expect(plan.removes(.livePhotoPairingIdentifier))
        #expect(plan.warnings.isEmpty)
    }

    @Test("Resolves HEIC still policy with Apple metadata preservation")
    func resolvesHEICStillPolicy() {
        let plan =
            MetadataPolicyResolver.standard.plan(
                for:
                    MediaProcessingPlan(
                        route: .stillImage,
                        sourceContentType: .jpeg,
                        outputPlan:
                            .stillImage(
                                imageType: .heic
                            ),
                        preservesLivePhotoMotion: false,
                        requiresLivePhotoPairedResources: false
                    )
            )

        #expect(plan.identifier == "heic")
        #expect(plan.targets == [.heicStill])
        #expect(plan.preserves(.exif))
        #expect(plan.preserves(.appleMakerMetadata))
        #expect(plan.overrides(.pixelDimensions))
        #expect(plan.removes(.livePhotoPairingIdentifier))
    }

    @Test("Resolves PNG still policy with container limitation warning")
    func resolvesPNGStillPolicy() {
        let plan =
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

        #expect(plan.identifier == "png")
        #expect(plan.targets == [.pngStill])
        #expect(plan.preserves(.captureDate))
        #expect(plan.preserves(.gpsLocation))
        #expect(plan.preserves(.colorProfile))
        #expect(plan.overrides(.pixelDimensions))
        #expect(plan.removes(.quickTimeContentIdentifier))
        #expect(!plan.warnings.isEmpty)
    }

    @Test("Resolves RAW JPEG still policy with generated-still warning")
    func resolvesRawJPEGStillPolicyWithGeneratedStillWarning() {
        let plan =
            MetadataPolicyResolver.standard.plan(
                for:
                    MediaProcessingPlan(
                        route: .rawStillImage,
                        sourceContentType:
                            UTType(filenameExtension: "dng"),
                        outputPlan:
                            .stillImage(
                                imageType: .jpeg
                            ),
                        preservesLivePhotoMotion: false,
                        requiresLivePhotoPairedResources: false
                    )
            )

        #expect(plan.identifier == "jpeg")
        #expect(plan.targets == [.jpegStill])
        #expect(plan.preserves(.exif))
        #expect(plan.preserves(.gpsLocation))
        #expect(plan.overrides(.pixelDimensions))
        #expect(plan.removes(.livePhotoPairingIdentifier))
        #expect(
            plan.warnings.contains {
                $0.contains("RAW/ProRAW")
                    && $0.contains("normal still image")
                    && $0.contains("does not preserve")
            }
        )
    }

    @Test("Resolves RAW HEIC still policy with generated-still warning")
    func resolvesRawHEICStillPolicyWithGeneratedStillWarning() {
        let prorawType =
            UTType(exportedAs: "com.apple.proraw")
        let plan =
            MetadataPolicyResolver.standard.plan(
                for:
                    MediaProcessingPlan(
                        route: .rawStillImage,
                        sourceContentType:
                            prorawType,
                        outputPlan:
                            .stillImage(
                                imageType: .heic
                            ),
                        preservesLivePhotoMotion: false,
                        requiresLivePhotoPairedResources: false
                    )
            )

        #expect(plan.identifier == "heic")
        #expect(plan.targets == [.heicStill])
        #expect(plan.preserves(.appleMakerMetadata))
        #expect(plan.overrides(.orientation))
        #expect(
            plan.warnings.contains {
                $0.contains("RAW/ProRAW")
                    && $0.contains("normal still image")
                    && $0.contains("does not preserve")
            }
        )
    }

    @Test("Resolves RAW PNG still policy with generated-still and container warnings")
    func resolvesRawPNGStillPolicyWithGeneratedStillAndContainerWarnings() {
        let plan =
            MetadataPolicyResolver.standard.plan(
                for:
                    MediaProcessingPlan(
                        route: .rawStillImage,
                        sourceContentType:
                            UTType(filenameExtension: "dng"),
                        outputPlan:
                            .stillImage(
                                imageType: .png
                            ),
                        preservesLivePhotoMotion: false,
                        requiresLivePhotoPairedResources: false
                    )
            )

        #expect(plan.identifier == "png")
        #expect(plan.targets == [.pngStill])
        #expect(plan.preserves(.captureDate))
        #expect(plan.preserves(.colorProfile))
        #expect(plan.removes(.quickTimeContentIdentifier))
        #expect(
            plan.warnings.contains {
                $0.contains("RAW/ProRAW")
                    && $0.contains("normal still image")
                    && $0.contains("does not preserve")
            }
        )
        #expect(
            plan.warnings.contains {
                $0.contains("PNG metadata support")
            }
        )
    }

    @Test("Resolves Live Photo pair policy for still and video metadata")
    func resolvesLivePhotoPairPolicy() {
        let plan =
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

        #expect(
            plan.identifier
                == "livePhotoStill+livePhotoVideo"
        )
        #expect(
            plan.targets == [
                .livePhotoStill,
                .livePhotoVideo
            ]
        )
        #expect(plan.preserves(.exif))
        #expect(plan.preserves(.videoTracks))
        #expect(plan.preserves(.audioTracks))
        #expect(plan.overrides(.videoDimensions))
        #expect(plan.synthesizes(.quickTimeContentIdentifier))
        #expect(plan.synthesizes(.livePhotoPairingIdentifier))
    }
}
