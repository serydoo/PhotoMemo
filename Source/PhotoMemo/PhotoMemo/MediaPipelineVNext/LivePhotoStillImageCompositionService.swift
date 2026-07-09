import CoreGraphics
import Foundation
import UniformTypeIdentifiers

protocol LivePhotoStillImageComposing {

    func composeStillImage(
        sourceStillURL: URL,
        overlay: FixedFooterOverlayDescriptor,
        outputURL: URL,
        outputType: UTType
    ) throws -> URL

    func composeStillImage(
        sourceStillURL: URL,
        overlay: FixedFooterOverlayDescriptor,
        outputURL: URL,
        outputType: UTType,
        outputDescription: String?
    ) throws -> URL
}

protocol LivePhotoStillImagePairingComposing {

    func composeStillImage(
        sourceStillURL: URL,
        geometry: CanonicalGeometry,
        overlay: FixedFooterOverlayDescriptor,
        outputURL: URL,
        outputType: UTType,
        pairingIdentifier: String?,
        outputDescription: String?
    ) throws -> URL
}

enum LivePhotoStillImageCompositionError:
    LocalizedError,
    Equatable {
    case sourceStillUnreadable
    case sourceStillImageMissing
    case outputContextUnavailable
    case destinationPrepareFailed
    case destinationCreateFailed
    case writeFailed

    var errorDescription: String? {
        switch self {
        case .sourceStillUnreadable:
            return "The source Live Photo still image could not be read."
        case .sourceStillImageMissing:
            return "The source still image does not contain a readable image."
        case .outputContextUnavailable:
            return "Unable to prepare the composed still-image canvas."
        case .destinationPrepareFailed:
            return "Unable to prepare the output still-image destination."
        case .destinationCreateFailed:
            return "Unable to create the output still-image file."
        case .writeFailed:
            return "Unable to write the composed still image."
        }
    }
}

final class LivePhotoStillImageCompositionService:
    LivePhotoStillImageComposing,
    LivePhotoStillImagePairingComposing {

    private let sourcePreparer:
        any LivePhotoStillImageSourcePreparing
    private let writer:
        any LivePhotoStillImageWriting

    init(
        sourcePreparer:
            any LivePhotoStillImageSourcePreparing =
                ImageIOLivePhotoStillImageSourcePreparer(),
        writer:
            any LivePhotoStillImageWriting =
                ImageIOLivePhotoStillImageWriter()
    ) {
        self.sourcePreparer =
            sourcePreparer
        self.writer =
            writer
    }

    func composeStillImage(
        sourceStillURL: URL,
        overlay: FixedFooterOverlayDescriptor,
        outputURL: URL,
        outputType: UTType
    ) throws -> URL {
        try composeStillImage(
            sourceStillURL:
                sourceStillURL,
            overlay:
                overlay,
            outputURL:
                outputURL,
            outputType:
                outputType,
            outputDescription:
                nil,
            pairingIdentifier:
                nil
        )
    }

    func composeStillImage(
        sourceStillURL: URL,
        overlay: FixedFooterOverlayDescriptor,
        outputURL: URL,
        outputType: UTType,
        outputDescription: String?
    ) throws -> URL {
        try composeStillImage(
            sourceStillURL:
                sourceStillURL,
            overlay:
                overlay,
            outputURL:
                outputURL,
            outputType:
                outputType,
            outputDescription:
                outputDescription,
            pairingIdentifier:
                nil
        )
    }

    func composeStillImage(
        sourceStillURL: URL,
        overlay: FixedFooterOverlayDescriptor,
        outputURL: URL,
        outputType: UTType,
        pairingIdentifier: String?
    ) throws -> URL {
        try composeStillImage(
            sourceStillURL:
                sourceStillURL,
            overlay:
                overlay,
            outputURL:
                outputURL,
            outputType:
                outputType,
            outputDescription:
                nil,
            pairingIdentifier:
                pairingIdentifier
        )
    }

    func composeStillImage(
        sourceStillURL: URL,
        geometry: CanonicalGeometry,
        overlay: FixedFooterOverlayDescriptor,
        outputURL: URL,
        outputType: UTType,
        pairingIdentifier: String?,
        outputDescription: String?
    ) throws -> URL {
        let geometryOverlay =
            try FixedFooterOverlayDescriptor(
                canvasSize:
                    geometry
                    .canvas
                    .canvasSize,
                photoFrame:
                    geometry
                    .canvas
                    .photoFrame,
                footerFrame:
                    geometry
                    .canvas
                    .footerFrame,
                footerImage:
                    overlay
                    .footerImage
            )

        return try composeStillImage(
            sourceStillURL:
                sourceStillURL,
            overlay:
                geometryOverlay,
            outputURL:
                outputURL,
            outputType:
                outputType,
            outputDescription:
                outputDescription,
            pairingIdentifier:
                pairingIdentifier
        )
    }

    func composeStillImage(
        sourceStillURL: URL,
        overlay: FixedFooterOverlayDescriptor,
        outputURL: URL,
        outputType: UTType,
        outputDescription: String?,
        pairingIdentifier: String?
    ) throws -> URL {

        let preparedOverlay =
            try overlay.normalizedForEncoder()

        let preparedSource =
            try sourcePreparer
            .preparedStillImage(
                sourceStillURL:
                    sourceStillURL,
                targetFrame:
                    preparedOverlay
                    .photoFrame
            )

        guard
            let context =
                CGContext(
                    data: nil,
                    width: Int(preparedOverlay.canvasSize.width),
                    height: Int(preparedOverlay.canvasSize.height),
                    bitsPerComponent: 8,
                    bytesPerRow: 0,
                    space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo:
                        CGImageAlphaInfo
                        .premultipliedLast
                        .rawValue
                )
        else {
            throw LivePhotoStillImageCompositionError
                .outputContextUnavailable
        }

        context.setFillColor(
            CGColor(
                red: 1,
                green: 1,
                blue: 1,
                alpha: 1
            )
        )
        context.fill(
            CGRect(
                origin: .zero,
                size: preparedOverlay.canvasSize
            )
        )
        context.interpolationQuality = .high
        context.saveGState()
        context.clip(
            to:
                preparedOverlay
                .photoFrame
        )
        context.draw(
            preparedSource
                .image,
            in:
                aspectFillRect(
                    sourceSize:
                        CGSize(
                            width:
                                preparedSource
                                .image
                                .width,
                            height:
                                preparedSource
                                .image
                                .height
                        ),
                    targetFrame:
                        preparedOverlay
                        .photoFrame
                )
        )
        context.restoreGState()
        context.draw(
            preparedOverlay.footerImage,
            in: preparedOverlay.footerFrame
        )

        guard let composedImage =
            context.makeImage()
        else {
            throw LivePhotoStillImageCompositionError
                .outputContextUnavailable
        }

        return try writer
            .writeComposedStillImage(
                composedImage,
                sourceProperties:
                    preparedSource
                    .properties,
                outputURL:
                    outputURL,
                outputType:
                    outputType,
                outputDescription:
                    outputDescription,
                pairingIdentifier:
                    pairingIdentifier
            )
    }
}

private extension LivePhotoStillImageCompositionService {

    func aspectFillRect(
        sourceSize: CGSize,
        targetFrame: CGRect
    ) -> CGRect {
        let scale =
            max(
                targetFrame.width
                / max(sourceSize.width, 1),
                targetFrame.height
                / max(sourceSize.height, 1)
            )
        let fittedSize =
            CGSize(
                width: sourceSize.width * scale,
                height: sourceSize.height * scale
            )

        return CGRect(
            x: targetFrame.midX - fittedSize.width / 2,
            y: targetFrame.midY - fittedSize.height / 2,
            width: fittedSize.width,
            height: fittedSize.height
        )
    }
}
