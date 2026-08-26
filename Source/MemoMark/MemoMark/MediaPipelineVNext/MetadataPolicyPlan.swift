import Foundation
import UniformTypeIdentifiers

nonisolated enum MetadataPolicyTarget:
    String,
    Codable,
    Hashable,
    Sendable {
    case jpegStill
    case heicStill
    case pngStill
    case livePhotoStill
    case livePhotoVideo
}

nonisolated enum MetadataPolicyField:
    String,
    Codable,
    Hashable,
    Sendable {
    case captureDate
    case cameraMakeModel
    case lens
    case gpsLocation
    case orientation
    case pixelDimensions
    case colorProfile
    case userDescription
    case exif
    case tiff
    case iptc
    case xmp
    case appleMakerMetadata
    case livePhotoPairingIdentifier
    case livePhotoStillImageTime
    case quickTimeCreationDate
    case quickTimeContentIdentifier
    case quickTimeMetadata
    case videoDimensions
    case videoTracks
    case audioTracks
}

nonisolated enum MetadataPolicyAction:
    String,
    Codable,
    Hashable,
    Sendable {
    case preserve
    case override
    case remove
    case synthesize
}

nonisolated struct MetadataPolicyOperation:
    Codable,
    Hashable,
    Sendable {

    let action: MetadataPolicyAction
    let field: MetadataPolicyField

    nonisolated init(
        action: MetadataPolicyAction,
        field: MetadataPolicyField
    ) {
        self.action = action
        self.field = field
    }
}

nonisolated struct MetadataPolicyPlan:
    Codable,
    Hashable,
    Sendable {

    let identifier: String
    let targets: [MetadataPolicyTarget]
    let operations: [MetadataPolicyOperation]
    let warnings: [String]

    nonisolated init(
        identifier: String,
        targets: [MetadataPolicyTarget],
        operations: [MetadataPolicyOperation],
        warnings: [String] = []
    ) {
        self.identifier = identifier
        self.targets = targets
        self.operations = operations
        self.warnings = warnings
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

    nonisolated func removes(
        _ field: MetadataPolicyField
    ) -> Bool {
        contains(
            .remove,
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

private extension MetadataPolicyPlan {

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

nonisolated struct MetadataPolicyResolver:
    Hashable,
    Sendable {

    nonisolated static let standard =
        MetadataPolicyResolver()

    nonisolated func plan(
        for processingPlan: MediaProcessingPlan
    ) -> MetadataPolicyPlan {
        switch processingPlan.outputPlan {
        case .stillImage(let imageType):
            return stillImagePolicy(
                imageType: imageType,
                route: processingPlan.route
            )

        case .livePhotoPair:
            return livePhotoPairPolicy()
        }
    }
}

private extension MetadataPolicyResolver {

    nonisolated func stillImagePolicy(
        imageType: UTType,
        route: MediaProcessingRoute
    ) -> MetadataPolicyPlan {
        if imageType.conforms(to: .jpeg) {
            return MetadataPolicyPlan(
                identifier: "jpeg",
                targets: [.jpegStill],
                operations:
                    stillImagePreservationOperations()
                    + outputGeometryOverrideOperations()
                    + staticOutputRemovalOperations(),
                warnings:
                    rawGeneratedStillWarnings(
                        route: route
                    )
            )
        }

        if imageType.conforms(to: .png) {
            return MetadataPolicyPlan(
                identifier: "png",
                targets: [.pngStill],
                operations:
                    pngPreservationOperations()
                    + outputGeometryOverrideOperations()
                    + staticOutputRemovalOperations(),
                warnings:
                    rawGeneratedStillWarnings(
                        route: route
                    )
                    + [
                    "PNG metadata support is container-limited and may not round-trip all EXIF/IPTC/XMP fields in Apple Photos."
                    ]
            )
        }

        return MetadataPolicyPlan(
            identifier: "heic",
            targets: [.heicStill],
            operations:
                stillImagePreservationOperations()
                + [
                    operation(
                        .preserve,
                        .appleMakerMetadata
                    )
                ]
                + outputGeometryOverrideOperations()
                + staticOutputRemovalOperations(),
            warnings:
                rawGeneratedStillWarnings(
                    route: route
                )
        )
    }

    nonisolated func livePhotoPairPolicy()
        -> MetadataPolicyPlan {
        MetadataPolicyPlan(
            identifier:
                "livePhotoStill+livePhotoVideo",
            targets: [
                .livePhotoStill,
                .livePhotoVideo
            ],
            operations:
                stillImagePreservationOperations()
                + [
                    operation(
                        .preserve,
                        .appleMakerMetadata
                    ),
                    operation(
                        .preserve,
                        .videoTracks
                    ),
                    operation(
                        .preserve,
                        .audioTracks
                    ),
                    operation(
                        .preserve,
                        .quickTimeCreationDate
                    ),
                    operation(
                        .preserve,
                        .livePhotoStillImageTime
                    ),
                    operation(
                        .override,
                        .videoDimensions
                    ),
                    operation(
                        .synthesize,
                        .quickTimeContentIdentifier
                    ),
                    operation(
                        .synthesize,
                        .livePhotoPairingIdentifier
                    )
                ]
                + outputGeometryOverrideOperations()
        )
    }

    nonisolated func stillImagePreservationOperations()
        -> [MetadataPolicyOperation] {
        [
            operation(
                .preserve,
                .captureDate
            ),
            operation(
                .preserve,
                .cameraMakeModel
            ),
            operation(
                .preserve,
                .lens
            ),
            operation(
                .preserve,
                .gpsLocation
            ),
            operation(
                .preserve,
                .colorProfile
            ),
            operation(
                .preserve,
                .userDescription
            ),
            operation(
                .preserve,
                .exif
            ),
            operation(
                .preserve,
                .tiff
            ),
            operation(
                .preserve,
                .iptc
            ),
            operation(
                .preserve,
                .xmp
            )
        ]
    }

    nonisolated func pngPreservationOperations()
        -> [MetadataPolicyOperation] {
        [
            operation(
                .preserve,
                .captureDate
            ),
            operation(
                .preserve,
                .gpsLocation
            ),
            operation(
                .preserve,
                .colorProfile
            ),
            operation(
                .preserve,
                .userDescription
            )
        ]
    }

    nonisolated func outputGeometryOverrideOperations()
        -> [MetadataPolicyOperation] {
        [
            operation(
                .override,
                .pixelDimensions
            ),
            operation(
                .override,
                .orientation
            )
        ]
    }

    nonisolated func staticOutputRemovalOperations()
        -> [MetadataPolicyOperation] {
        [
            operation(
                .remove,
                .livePhotoPairingIdentifier
            ),
            operation(
                .remove,
                .livePhotoStillImageTime
            ),
            operation(
                .remove,
                .quickTimeContentIdentifier
            ),
            operation(
                .remove,
                .quickTimeMetadata
            )
        ]
    }

    nonisolated func rawGeneratedStillWarnings(
        route: MediaProcessingRoute
    ) -> [String] {

        guard route == .rawStillImage else {
            return []
        }

        return [
            "MemoMark generates a normal still image output from RAW/ProRAW input; it does not preserve RAW/ProRAW as output."
        ]
    }

    nonisolated func operation(
        _ action: MetadataPolicyAction,
        _ field: MetadataPolicyField
    ) -> MetadataPolicyOperation {
        MetadataPolicyOperation(
            action: action,
            field: field
        )
    }
}
