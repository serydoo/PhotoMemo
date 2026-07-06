import Foundation
import CoreGraphics

struct SubjectAvatarCropConfiguration: Hashable, Sendable {

    nonisolated static let minimumZoomScale: CGFloat = 1
    nonisolated static let maximumZoomScale: CGFloat = 4

    var zoomScale: CGFloat
    var normalizedOffset: CGSize

    nonisolated init(
        zoomScale: CGFloat = 1,
        normalizedOffset: CGSize = .zero
    ) {
        self.zoomScale =
            Self.clampedZoomScale(
                zoomScale
            )
        self.normalizedOffset =
            Self.clampedNormalizedOffset(
                normalizedOffset
            )
    }

    nonisolated static func clampedZoomScale(
        _ zoomScale: CGFloat
    ) -> CGFloat {
        min(
            max(zoomScale, minimumZoomScale),
            maximumZoomScale
        )
    }

    nonisolated static func clampedNormalizedOffset(
        _ offset: CGSize
    ) -> CGSize {
        CGSize(
            width: min(max(offset.width, -1), 1),
            height: min(max(offset.height, -1), 1)
        )
    }
}

enum SubjectAvatarCropSupport {

    nonisolated static func aspectFillRect(
        sourceSize: CGSize,
        canvasSize: CGSize,
        safeInsetRatio: CGFloat
    ) -> CGRect {
        let sourceWidth =
            max(sourceSize.width, 1)
        let sourceHeight =
            max(sourceSize.height, 1)
        let safeInset =
            canvasSize.width
            * safeInsetRatio
        let availableSize =
            CGSize(
                width:
                    max(canvasSize.width - safeInset * 2, 1),
                height:
                    max(canvasSize.height - safeInset * 2, 1)
            )
        let scale =
            max(
                availableSize.width / sourceWidth,
                availableSize.height / sourceHeight
            )
        let fittedSize =
            CGSize(
                width: sourceWidth * scale,
                height: sourceHeight * scale
            )

        return CGRect(
            x:
                (canvasSize.width - fittedSize.width) / 2,
            y:
                (canvasSize.height - fittedSize.height) / 2,
            width: fittedSize.width,
            height: fittedSize.height
        )
    }

    nonisolated static func maximumTranslation(
        sourceSize: CGSize,
        canvasSize: CGSize,
        safeInsetRatio: CGFloat,
        zoomScale: CGFloat
    ) -> CGSize {
        let baseRect =
            aspectFillRect(
                sourceSize: sourceSize,
                canvasSize: canvasSize,
                safeInsetRatio: safeInsetRatio
            )
        let resolvedZoomScale =
            SubjectAvatarCropConfiguration
            .clampedZoomScale(zoomScale)
        let scaledSize =
            CGSize(
                width: baseRect.width * resolvedZoomScale,
                height: baseRect.height * resolvedZoomScale
            )

        return CGSize(
            width:
                max(
                    (scaledSize.width - canvasSize.width) / 2,
                    0
                ),
            height:
                max(
                    (scaledSize.height - canvasSize.height) / 2,
                    0
                )
        )
    }

    nonisolated static func clampedTranslation(
        _ translation: CGSize,
        sourceSize: CGSize,
        canvasSize: CGSize,
        safeInsetRatio: CGFloat,
        zoomScale: CGFloat
    ) -> CGSize {
        let maxTranslation =
            maximumTranslation(
                sourceSize: sourceSize,
                canvasSize: canvasSize,
                safeInsetRatio: safeInsetRatio,
                zoomScale: zoomScale
            )

        return CGSize(
            width:
                min(
                    max(
                        translation.width,
                        -maxTranslation.width
                    ),
                    maxTranslation.width
                ),
            height:
                min(
                    max(
                        translation.height,
                        -maxTranslation.height
                    ),
                    maxTranslation.height
                )
        )
    }

    nonisolated static func normalizedOffset(
        for translation: CGSize,
        sourceSize: CGSize,
        canvasSize: CGSize,
        safeInsetRatio: CGFloat,
        zoomScale: CGFloat
    ) -> CGSize {
        let clampedTranslation =
            clampedTranslation(
                translation,
                sourceSize: sourceSize,
                canvasSize: canvasSize,
                safeInsetRatio: safeInsetRatio,
                zoomScale: zoomScale
            )
        let maxTranslation =
            maximumTranslation(
                sourceSize: sourceSize,
                canvasSize: canvasSize,
                safeInsetRatio: safeInsetRatio,
                zoomScale: zoomScale
            )

        return SubjectAvatarCropConfiguration
            .clampedNormalizedOffset(
                CGSize(
                    width:
                        maxTranslation.width > 0
                        ? clampedTranslation.width / maxTranslation.width
                        : 0,
                    height:
                        maxTranslation.height > 0
                        ? clampedTranslation.height / maxTranslation.height
                        : 0
                )
            )
    }

    nonisolated static func translation(
        for configuration: SubjectAvatarCropConfiguration,
        sourceSize: CGSize,
        canvasSize: CGSize,
        safeInsetRatio: CGFloat
    ) -> CGSize {
        let maxTranslation =
            maximumTranslation(
                sourceSize: sourceSize,
                canvasSize: canvasSize,
                safeInsetRatio: safeInsetRatio,
                zoomScale: configuration.zoomScale
            )
        let normalizedOffset =
            SubjectAvatarCropConfiguration
            .clampedNormalizedOffset(
                configuration.normalizedOffset
            )

        return CGSize(
            width:
                maxTranslation.width
                * normalizedOffset.width,
            height:
                maxTranslation.height
                * normalizedOffset.height
        )
    }

    nonisolated static func resolvedDrawRect(
        sourceSize: CGSize,
        canvasSize: CGSize,
        safeInsetRatio: CGFloat,
        configuration: SubjectAvatarCropConfiguration
    ) -> CGRect {
        let baseRect =
            aspectFillRect(
                sourceSize: sourceSize,
                canvasSize: canvasSize,
                safeInsetRatio: safeInsetRatio
            )
        let zoomScale =
            SubjectAvatarCropConfiguration
            .clampedZoomScale(
                configuration.zoomScale
            )
        let scaledSize =
            CGSize(
                width: baseRect.width * zoomScale,
                height: baseRect.height * zoomScale
            )
        let translation =
            self.translation(
                for: configuration,
                sourceSize: sourceSize,
                canvasSize: canvasSize,
                safeInsetRatio: safeInsetRatio
            )

        return CGRect(
            x:
                (canvasSize.width - scaledSize.width) / 2
                + translation.width,
            y:
                (canvasSize.height - scaledSize.height) / 2
                + translation.height,
            width: scaledSize.width,
            height: scaledSize.height
        )
    }
}
