import Foundation
import ImageIO
#if canImport(CoreImage)
import CoreImage
#endif

final class MediaDecodeService {

    nonisolated init() {
    }

    nonisolated func previewImage(
        for mediaAsset: MediaAsset
    ) throws -> PlatformImage {

        if mediaAsset.isRAW {
            return try rawDisplayImage(
                from: mediaAsset.fileURL
            )
        }

        if let image =
            imageIODisplayImage(
                from: mediaAsset.fileURL
            ) {
            return image
        }

        guard let data =
            try? Data(
                contentsOf: mediaAsset.fileURL
            ),
              let image =
            PlatformImage.loadPhotoMemoImage(
                from: data
            ) else {

            throw PhotoImportError.imageLoadFailed
        }

        return image
    }

    nonisolated func thumbnailImage(
        from url: URL,
        maxPixelDimension: Int
    ) -> PlatformImage? {

        imageIODisplayImage(
            from: url,
            maxPixelDimension:
                maxPixelDimension
        )
    }

    private nonisolated func rawDisplayImage(
        from url: URL
    ) throws -> PlatformImage {

        if let image =
            PlatformImage.loadPhotoMemoImage(
                contentsOfFile: url.path
            ) {
            return image
        }

        if let image =
            imageIODisplayImage(
                from: url
            ) {
            return image
        }

#if canImport(CoreImage)
        if let image =
            coreImageDisplayImage(
                from: url
            ) {
            return image
        }
#endif

        throw PhotoImportError
            .rawDisplayRenderFailed
    }

    private nonisolated func imageIODisplayImage(
        from url: URL,
        maxPixelDimension: Int =
            PhotoProcessingInputPolicy
            .standard
            .maximumPixelDimension
    ) -> PlatformImage? {

        guard let source =
            CGImageSourceCreateWithURL(
                url as CFURL,
                [
                    kCGImageSourceShouldCache:
                        false
                ] as CFDictionary
            ) else {
            return nil
        }

        let maxPixelSize =
            max(
                maxPixelDimension,
                1
            )

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageIfAbsent:
                true,
            kCGImageSourceCreateThumbnailWithTransform:
                true,
            kCGImageSourceShouldCacheImmediately:
                true,
            kCGImageSourceThumbnailMaxPixelSize:
                maxPixelSize
        ]

        guard let cgImage =
            CGImageSourceCreateThumbnailAtIndex(
                source,
                0,
                options as CFDictionary
            ) else {
            return nil
        }

        return PlatformImage.photoMemoImage(
            cgImage: cgImage
        )
    }

#if canImport(CoreImage)
    private nonisolated func coreImageDisplayImage(
        from url: URL
    ) -> PlatformImage? {

        guard let ciImage =
            CIImage(
                contentsOf: url,
                options: [
                    .applyOrientationProperty:
                        true
                ]
            ) else {
            return nil
        }

        let maxPixelSize =
            CGFloat(
                PhotoProcessingInputPolicy
                    .standard
                    .maximumPixelDimension
            )
        let extent =
            ciImage.extent.integral

        guard extent.width > 0,
              extent.height > 0 else {
            return nil
        }

        let scale =
            min(
                maxPixelSize
                    / max(
                        extent.width,
                        extent.height
                    ),
                1
            )

        let displayImage =
            scale < 1
            ? ciImage.transformed(
                by: CGAffineTransform(
                    scaleX: scale,
                    y: scale
                )
            )
            : ciImage

        let context =
            CIContext(
                options: [
                    .cacheIntermediates:
                        false
                ]
            )

        guard let cgImage =
            context.createCGImage(
                displayImage,
                from:
                    displayImage.extent
                    .integral
            ) else {
            return nil
        }

        return PlatformImage.photoMemoImage(
            cgImage: cgImage
        )
    }
#endif
}
