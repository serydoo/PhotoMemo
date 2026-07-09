import Foundation
import UniformTypeIdentifiers

struct MediaProcessingRouter:
    MediaProcessingRouting {

    private let inputPolicy:
        PhotoProcessingInputPolicy

    init(
        inputPolicy:
            PhotoProcessingInputPolicy =
                .standard
    ) {
        self.inputPolicy = inputPolicy
    }

    func decision(
        for descriptor: MediaProcessingInputDescriptor
    ) -> MediaProcessingDecision {

        let resolvedContentType =
            descriptor.resolvedContentType

        if descriptor.isLivePhotoAsset
            || PhotoProcessingInputPolicy
            .isLivePhotoContentType(
                resolvedContentType
            ) {
            return .route(.livePhoto)
        }

        if PhotoProcessingInputPolicy
            .isRawContentType(
                resolvedContentType
            )
            || descriptor.fileURL.map(
                PhotoProcessingInputPolicy
                    .isRawFileURL
            ) == true {

            let verdict = inputPolicy.verdict(
                contentType: resolvedContentType,
                pixelWidth:
                    descriptor.pixelWidth,
                pixelHeight:
                    descriptor.pixelHeight
            )

            guard verdict.isSupported else {
                return .unsupported(
                    verdict.reason
                    ?? .unsupportedFormat
                )
            }

            return .route(.rawStillImage)
        }

        let verdict = inputPolicy.verdict(
            contentType: resolvedContentType,
            pixelWidth: descriptor.pixelWidth,
            pixelHeight:
                descriptor.pixelHeight
        )

        guard verdict.isSupported else {
            return .unsupported(
                verdict.reason
                ?? .unsupportedFormat
            )
        }

        return .route(.stillImage)
    }
}
