import Foundation
import ImageIO
import UniformTypeIdentifiers

nonisolated struct StillImageMetadataWriteRequest:
    Hashable,
    Sendable {

    let sourceImageURL: URL
    let renderedImageURL: URL
    let destinationImageURL: URL
    let outputImageType: UTType
    let outputPixelWidth: Int
    let outputPixelHeight: Int
    let policyPlan: MetadataPolicyPlan

    nonisolated init(
        sourceImageURL: URL,
        renderedImageURL: URL,
        destinationImageURL: URL,
        outputImageType: UTType,
        outputPixelWidth: Int,
        outputPixelHeight: Int,
        policyPlan: MetadataPolicyPlan
    ) {
        self.sourceImageURL = sourceImageURL
        self.renderedImageURL = renderedImageURL
        self.destinationImageURL = destinationImageURL
        self.outputImageType = outputImageType
        self.outputPixelWidth =
            max(outputPixelWidth, 1)
        self.outputPixelHeight =
            max(outputPixelHeight, 1)
        self.policyPlan = policyPlan
    }
}

nonisolated struct StillImageMetadataWritePlan:
    Hashable,
    Sendable {

    let sourceImageURL: URL
    let renderedImageURL: URL
    let destinationImageURL: URL
    let outputImageType: UTType
    let outputPixelWidth: Int
    let outputPixelHeight: Int
    let operations: [MetadataPolicyOperation]
    let warnings: [String]
    let shouldCopySourceMetadata: Bool
    let shouldCopyRenderedPixels: Bool

    nonisolated init(
        sourceImageURL: URL,
        renderedImageURL: URL,
        destinationImageURL: URL,
        outputImageType: UTType,
        outputPixelWidth: Int,
        outputPixelHeight: Int,
        operations: [MetadataPolicyOperation],
        warnings: [String],
        shouldCopySourceMetadata: Bool = true,
        shouldCopyRenderedPixels: Bool = true
    ) {
        self.sourceImageURL = sourceImageURL
        self.renderedImageURL = renderedImageURL
        self.destinationImageURL = destinationImageURL
        self.outputImageType = outputImageType
        self.outputPixelWidth = outputPixelWidth
        self.outputPixelHeight = outputPixelHeight
        self.operations = operations
        self.warnings = warnings
        self.shouldCopySourceMetadata =
            shouldCopySourceMetadata
        self.shouldCopyRenderedPixels =
            shouldCopyRenderedPixels
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
}

private extension StillImageMetadataWritePlan {

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

nonisolated enum StillImageMetadataWritePlanningError:
    LocalizedError,
    Equatable,
    Sendable {

    case unsupportedPolicyTargets(
        [MetadataPolicyTarget]
    )

    var errorDescription: String? {
        switch self {
        case .unsupportedPolicyTargets:
            return "The still-image metadata writer cannot handle the selected metadata policy targets."
        }
    }
}

nonisolated enum StillImageMetadataWritingError:
    LocalizedError,
    Equatable,
    Sendable {

    case sourceMetadataUnavailable
    case renderedImageUnavailable
    case destinationUnavailable
    case writeFailed

    var errorDescription: String? {
        switch self {
        case .sourceMetadataUnavailable:
            return "Source image metadata could not be read."
        case .renderedImageUnavailable:
            return "Rendered image pixels could not be read."
        case .destinationUnavailable:
            return "Destination image writer could not be created."
        case .writeFailed:
            return "Destination image writer failed to finalize."
        }
    }
}

protocol StillImageMetadataWriting {

    func write(
        _ plan: StillImageMetadataWritePlan
    ) throws
}

struct ImageIOStillImageMetadataWriter:
    StillImageMetadataWriting {

    func write(
        _ plan: StillImageMetadataWritePlan
    ) throws {
        guard let source =
            CGImageSourceCreateWithURL(
                plan.sourceImageURL as CFURL,
                nil
            ),
            let sourceProperties =
                CGImageSourceCopyPropertiesAtIndex(
                    source,
                    0,
                    nil
                ) as? [CFString: Any]
        else {
            throw StillImageMetadataWritingError
                .sourceMetadataUnavailable
        }

        guard let renderedSource =
            CGImageSourceCreateWithURL(
                plan.renderedImageURL as CFURL,
                nil
            ),
            let renderedImage =
                CGImageSourceCreateImageAtIndex(
                    renderedSource,
                    0,
                    nil
                )
        else {
            throw StillImageMetadataWritingError
                .renderedImageUnavailable
        }

        guard let destination =
            CGImageDestinationCreateWithURL(
                plan.destinationImageURL as CFURL,
                plan.outputImageType.identifier as CFString,
                1,
                nil
            )
        else {
            throw StillImageMetadataWritingError
                .destinationUnavailable
        }

        CGImageDestinationAddImage(
            destination,
            renderedImage,
            ImageIOStillImageMetadataPropertyReviser()
                .revisedProperties(
                    from: sourceProperties,
                    plan: plan
                ) as CFDictionary
        )

        guard CGImageDestinationFinalize(
            destination
        ) else {
            throw StillImageMetadataWritingError
                .writeFailed
        }
    }
}

struct ImageIOStillImageMetadataPropertyReviser {

    static let quickTimeMetadataKey:
        CFString =
            "QuickTime" as CFString

    func revisedProperties(
        from sourceProperties:
            [CFString: Any],
        plan: StillImageMetadataWritePlan
    ) -> [CFString: Any] {
        var properties =
            sourceProperties

        applyRemovals(
            to: &properties,
            plan: plan
        )
        applyContainerLimits(
            to: &properties,
            plan: plan
        )
        applyOutputGeometry(
            to: &properties,
            plan: plan
        )

        return properties
    }
}

private extension ImageIOStillImageMetadataPropertyReviser {

    func applyOutputGeometry(
        to properties: inout [CFString: Any],
        plan: StillImageMetadataWritePlan
    ) {
        guard plan.overrides(.pixelDimensions)
            || plan.overrides(.orientation)
        else {
            return
        }

        if plan.overrides(.pixelDimensions) {
            properties[kCGImagePropertyPixelWidth] =
                plan.outputPixelWidth
            properties[kCGImagePropertyPixelHeight] =
                plan.outputPixelHeight

            var exif =
                properties[
                    kCGImagePropertyExifDictionary
                ] as? [CFString: Any] ?? [:]

            exif[
                kCGImagePropertyExifPixelXDimension
            ] = plan.outputPixelWidth
            exif[
                kCGImagePropertyExifPixelYDimension
            ] = plan.outputPixelHeight

            properties[
                kCGImagePropertyExifDictionary
            ] = exif
        }

        if plan.overrides(.orientation) {
            properties[kCGImagePropertyOrientation] =
                1
        }
    }

    func applyRemovals(
        to properties: inout [CFString: Any],
        plan: StillImageMetadataWritePlan
    ) {
        if plan.removes(.quickTimeMetadata) {
            properties.removeValue(
                forKey:
                    Self.quickTimeMetadataKey
            )
        }

        if plan.removes(.livePhotoPairingIdentifier) {
            removeAppleLivePhotoPairingMetadata(
                from: &properties
            )
        }
    }

    func applyContainerLimits(
        to properties: inout [CFString: Any],
        plan: StillImageMetadataWritePlan
    ) {
        guard plan.outputImageType.conforms(to: .png)
        else {
            return
        }

        properties.removeValue(
            forKey:
                kCGImagePropertyMakerAppleDictionary
        )
    }

    func removeAppleLivePhotoPairingMetadata(
        from properties: inout [CFString: Any]
    ) {
        var makerApple =
            properties[
                kCGImagePropertyMakerAppleDictionary
            ] as? [CFString: Any]

        makerApple?.removeValue(
            forKey:
                "17" as CFString
        )

        if let makerApple,
           !makerApple.isEmpty {
            properties[
                kCGImagePropertyMakerAppleDictionary
            ] = makerApple
        } else {
            properties.removeValue(
                forKey:
                    kCGImagePropertyMakerAppleDictionary
            )
        }
    }
}

nonisolated struct StillImageMetadataWritePlanner:
    Hashable,
    Sendable {

    nonisolated static let standard =
        StillImageMetadataWritePlanner()

    nonisolated func plan(
        _ request: StillImageMetadataWriteRequest
    ) throws -> StillImageMetadataWritePlan {
        let unsupportedTargets =
            request.policyPlan.targets
                .filter {
                    !Self.supportedTargets
                        .contains($0)
                }

        guard unsupportedTargets.isEmpty else {
            throw StillImageMetadataWritePlanningError
                .unsupportedPolicyTargets(
                    request.policyPlan.targets
                )
        }

        return StillImageMetadataWritePlan(
            sourceImageURL:
                request.sourceImageURL,
            renderedImageURL:
                request.renderedImageURL,
            destinationImageURL:
                request.destinationImageURL,
            outputImageType:
                request.outputImageType,
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

private extension StillImageMetadataWritePlanner {

    nonisolated static let supportedTargets:
        Set<MetadataPolicyTarget> = [
            .jpegStill,
            .heicStill,
            .pngStill
        ]
}
