import AVFoundation
import Foundation

nonisolated struct LivePhotoVideoMetadataWriteRequest:
    Hashable,
    Sendable {

    let sourceVideoURL: URL
    let renderedVideoURL: URL
    let destinationVideoURL: URL
    let pairingIdentifier: String
    let outputPixelWidth: Int
    let outputPixelHeight: Int
    let policyPlan: MetadataPolicyPlan

    nonisolated init(
        sourceVideoURL: URL,
        renderedVideoURL: URL,
        destinationVideoURL: URL,
        pairingIdentifier: String,
        outputPixelWidth: Int,
        outputPixelHeight: Int,
        policyPlan: MetadataPolicyPlan
    ) {
        self.sourceVideoURL = sourceVideoURL
        self.renderedVideoURL = renderedVideoURL
        self.destinationVideoURL = destinationVideoURL
        self.pairingIdentifier =
            pairingIdentifier.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
        self.outputPixelWidth =
            max(outputPixelWidth, 1)
        self.outputPixelHeight =
            max(outputPixelHeight, 1)
        self.policyPlan = policyPlan
    }
}

nonisolated struct LivePhotoVideoMetadataWritePlan:
    Hashable,
    Sendable {

    let sourceVideoURL: URL
    let renderedVideoURL: URL
    let destinationVideoURL: URL
    let pairingIdentifier: String
    let outputPixelWidth: Int
    let outputPixelHeight: Int
    let operations: [MetadataPolicyOperation]
    let warnings: [String]
    let shouldCopySourceAssetMetadata: Bool

    nonisolated init(
        sourceVideoURL: URL,
        renderedVideoURL: URL,
        destinationVideoURL: URL,
        pairingIdentifier: String,
        outputPixelWidth: Int,
        outputPixelHeight: Int,
        operations: [MetadataPolicyOperation],
        warnings: [String],
        shouldCopySourceAssetMetadata: Bool = true
    ) {
        self.sourceVideoURL = sourceVideoURL
        self.renderedVideoURL = renderedVideoURL
        self.destinationVideoURL = destinationVideoURL
        self.pairingIdentifier = pairingIdentifier
        self.outputPixelWidth = outputPixelWidth
        self.outputPixelHeight = outputPixelHeight
        self.operations = operations
        self.warnings = warnings
        self.shouldCopySourceAssetMetadata =
            shouldCopySourceAssetMetadata
    }

    nonisolated func preserves(
        _ field: MetadataPolicyField
    ) -> Bool {
        contains(
            .preserve,
            field
        )
    }

    nonisolated func overrides(
        _ field: MetadataPolicyField
    ) -> Bool {
        contains(
            .override,
            field
        )
    }

    nonisolated func synthesizes(
        _ field: MetadataPolicyField
    ) -> Bool {
        contains(
            .synthesize,
            field
        )
    }
}

private extension LivePhotoVideoMetadataWritePlan {

    nonisolated func contains(
        _ action: MetadataPolicyAction,
        _ field: MetadataPolicyField
    ) -> Bool {
        operations.contains {
            $0.action == action
                && $0.field == field
        }
    }
}

nonisolated enum LivePhotoVideoMetadataWritePlanningError:
    LocalizedError,
    Equatable,
    Sendable {

    case unsupportedPolicyTargets(
        [MetadataPolicyTarget]
    )
    case missingLivePhotoVideoTarget
    case missingPairingIdentifier

    var errorDescription: String? {
        switch self {
        case .unsupportedPolicyTargets:
            return "The Live Photo video metadata writer cannot handle the selected metadata policy targets."
        case .missingLivePhotoVideoTarget:
            return "The selected metadata policy does not contain a Live Photo video target."
        case .missingPairingIdentifier:
            return "A generated Live Photo pairing identifier is required for MOV metadata writing."
        }
    }
}

nonisolated struct LivePhotoVideoMetadataWritePlanner:
    Hashable,
    Sendable {

    nonisolated static let standard =
        LivePhotoVideoMetadataWritePlanner()

    nonisolated func plan(
        _ request: LivePhotoVideoMetadataWriteRequest
    ) throws -> LivePhotoVideoMetadataWritePlan {
        let unsupportedTargets =
            request.policyPlan.targets.filter {
                !Self.supportedTargets.contains($0)
            }

        guard unsupportedTargets.isEmpty else {
            throw LivePhotoVideoMetadataWritePlanningError
                .unsupportedPolicyTargets(
                    request.policyPlan.targets
                )
        }

        guard request.policyPlan.targets
            .contains(.livePhotoVideo)
        else {
            throw LivePhotoVideoMetadataWritePlanningError
                .missingLivePhotoVideoTarget
        }

        guard !request.pairingIdentifier.isEmpty else {
            throw LivePhotoVideoMetadataWritePlanningError
                .missingPairingIdentifier
        }

        return LivePhotoVideoMetadataWritePlan(
            sourceVideoURL:
                request.sourceVideoURL,
            renderedVideoURL:
                request.renderedVideoURL,
            destinationVideoURL:
                request.destinationVideoURL,
            pairingIdentifier:
                request.pairingIdentifier,
            outputPixelWidth:
                request.outputPixelWidth,
            outputPixelHeight:
                request.outputPixelHeight,
            operations:
                request.policyPlan.operations,
            warnings:
                request.policyPlan.warnings
        )
    }
}

private extension LivePhotoVideoMetadataWritePlanner {

    nonisolated static let supportedTargets:
        Set<MetadataPolicyTarget> = [
            .livePhotoStill,
            .livePhotoVideo
        ]
}

struct AVFoundationLivePhotoVideoMetadataReviser {

    static let livePhotoAutoIdentifier =
        AVMetadataIdentifier(
            rawValue:
                "com.apple.quicktime.live-photo.auto"
        )
    static let livePhotoStillImageTimeIdentifier =
        AVMetadataIdentifier(
            rawValue:
                "com.apple.quicktime.still-image-time"
        )

    func revisedMetadata(
        from sourceMetadata: [AVMetadataItem],
        plan: LivePhotoVideoMetadataWritePlan
    ) -> [AVMetadataItem] {
        var revised =
            sourceMetadata.filter {
                $0.identifier
                    != .quickTimeMetadataContentIdentifier
            }

        if plan.synthesizes(.quickTimeContentIdentifier)
            || plan.synthesizes(.livePhotoPairingIdentifier) {
            revised.append(
                metadataItem(
                    identifier:
                        .quickTimeMetadataContentIdentifier,
                    value:
                        plan.pairingIdentifier
                )
            )
        }

        return revised
    }
}

private extension AVFoundationLivePhotoVideoMetadataReviser {

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
}
