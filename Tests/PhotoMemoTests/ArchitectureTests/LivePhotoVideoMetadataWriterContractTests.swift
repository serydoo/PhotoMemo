import AVFoundation
import Foundation
import Testing
import UniformTypeIdentifiers
@testable import PhotoMemo

@Suite(
    "Live Photo video metadata writer contract",
    .serialized
)
struct LivePhotoVideoMetadataWriterContractTests {

    @Test("Builds a Live Photo video metadata write plan without touching files")
    func buildsLivePhotoVideoMetadataWritePlanWithoutTouchingFiles() throws {
        let policy =
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
        let plan =
            try LivePhotoVideoMetadataWritePlanner
                .standard
                .plan(
                    LivePhotoVideoMetadataWriteRequest(
                        sourceVideoURL:
                            URL(fileURLWithPath: "/tmp/source.mov"),
                        renderedVideoURL:
                            URL(fileURLWithPath: "/tmp/rendered.mov"),
                        destinationVideoURL:
                            URL(fileURLWithPath: "/tmp/output.mov"),
                        pairingIdentifier:
                            "2AB295AF-CFD8-4C47-9579-90249E28F68F",
                        outputPixelWidth: 4032,
                        outputPixelHeight: 3704,
                        policyPlan: policy
                    )
                )

        #expect(
            plan.sourceVideoURL
            == URL(fileURLWithPath: "/tmp/source.mov")
        )
        #expect(
            plan.renderedVideoURL
            == URL(fileURLWithPath: "/tmp/rendered.mov")
        )
        #expect(
            plan.destinationVideoURL
            == URL(fileURLWithPath: "/tmp/output.mov")
        )
        #expect(
            plan.pairingIdentifier
            == "2AB295AF-CFD8-4C47-9579-90249E28F68F"
        )
        #expect(plan.outputPixelWidth == 4032)
        #expect(plan.outputPixelHeight == 3704)
        #expect(plan.shouldCopySourceAssetMetadata)
        #expect(plan.preserves(.videoTracks))
        #expect(plan.preserves(.audioTracks))
        #expect(plan.preserves(.quickTimeCreationDate))
        #expect(plan.preserves(.livePhotoStillImageTime))
        #expect(plan.overrides(.videoDimensions))
        #expect(plan.synthesizes(.quickTimeContentIdentifier))
        #expect(plan.synthesizes(.livePhotoPairingIdentifier))
    }

    @Test("Rejects still-image metadata policies in the Live Photo video writer contract")
    func rejectsStillImagePolicies() throws {
        let stillImagePolicy =
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

        do {
            _ = try LivePhotoVideoMetadataWritePlanner
                .standard
                .plan(
                    LivePhotoVideoMetadataWriteRequest(
                        sourceVideoURL:
                            URL(fileURLWithPath: "/tmp/source.mov"),
                        renderedVideoURL:
                            URL(fileURLWithPath: "/tmp/rendered.mov"),
                        destinationVideoURL:
                            URL(fileURLWithPath: "/tmp/output.mov"),
                        pairingIdentifier:
                            "pair-id",
                        outputPixelWidth: 1920,
                        outputPixelHeight: 1080,
                        policyPlan:
                            stillImagePolicy
                    )
                )
            Issue.record(
                "Expected the Live Photo video metadata writer to reject a still-image policy"
            )
        } catch let error as LivePhotoVideoMetadataWritePlanningError {
            #expect(
                error == .unsupportedPolicyTargets(
                    [.jpegStill]
                )
            )
        } catch {
            Issue.record(
                "Received unexpected error: \(error)"
            )
        }
    }

    @Test("Revises MOV metadata by replacing the pairing content identifier")
    func revisesMOVMetadataByReplacingPairingContentIdentifier() async throws {
        let policy =
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
        let plan =
            try LivePhotoVideoMetadataWritePlanner
                .standard
                .plan(
                    LivePhotoVideoMetadataWriteRequest(
                        sourceVideoURL:
                            URL(fileURLWithPath: "/tmp/source.mov"),
                        renderedVideoURL:
                            URL(fileURLWithPath: "/tmp/rendered.mov"),
                        destinationVideoURL:
                            URL(fileURLWithPath: "/tmp/output.mov"),
                        pairingIdentifier:
                            "generated-pair-id",
                        outputPixelWidth: 4032,
                        outputPixelHeight: 3704,
                        policyPlan:
                            policy
                    )
                )
        let sourceMetadata = [
            metadataItem(
                identifier:
                    .quickTimeMetadataContentIdentifier,
                value:
                    "source-pair-id"
            ),
            metadataItem(
                identifier:
                    .quickTimeMetadataCreationDate,
                value:
                    "2026-06-25T10:11:12+0800"
            ),
            metadataItem(
                identifier:
                    AVFoundationLivePhotoVideoMetadataReviser
                    .livePhotoAutoIdentifier,
                value:
                    "1"
            ),
            metadataItem(
                identifier:
                    AVFoundationLivePhotoVideoMetadataReviser
                    .livePhotoStillImageTimeIdentifier,
                value:
                    "0"
            )
        ]

        let revised =
            AVFoundationLivePhotoVideoMetadataReviser()
            .revisedMetadata(
                from: sourceMetadata,
                plan: plan
            )

        #expect(
            try await stringValue(
                for: .quickTimeMetadataContentIdentifier,
                in: revised
            ) == "generated-pair-id"
        )
        #expect(
            try await stringValue(
                for: .quickTimeMetadataCreationDate,
                in: revised
            ) == "2026-06-25T10:11:12+0800"
        )
        #expect(
            try await stringValue(
                for:
                    AVFoundationLivePhotoVideoMetadataReviser
                    .livePhotoAutoIdentifier,
                in: revised
            ) == "1"
        )
        #expect(
            try await stringValue(
                for:
                    AVFoundationLivePhotoVideoMetadataReviser
                    .livePhotoStillImageTimeIdentifier,
                in: revised
            ) == "0"
        )
        #expect(
            revised.filter {
                $0.identifier == .quickTimeMetadataContentIdentifier
            }.count == 1
        )
    }
}

private extension LivePhotoVideoMetadataWriterContractTests {

    func metadataItem(
        identifier: AVMetadataIdentifier,
        value: String
    ) -> AVMetadataItem {
        let item =
            AVMutableMetadataItem()
        item.identifier = identifier
        item.value = value as NSString
        item.dataType =
            kCMMetadataBaseDataType_UTF8 as String

        return item.copy() as! AVMetadataItem
    }

    func stringValue(
        for identifier: AVMetadataIdentifier,
        in metadata: [AVMetadataItem]
    ) async throws -> String? {
        try await metadata
            .first {
                $0.identifier == identifier
            }?
            .load(.stringValue)
    }
}
