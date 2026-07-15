import CoreGraphics

enum PhotoMemoRenderedImageArtifactGuard {

    static func replacingPhotoArea(
        in renderedImage: CGImage,
        with sourceImage: CGImage,
        photoHeight: Int
    ) -> CGImage {

        let resolvedPhotoHeight =
            min(
                max(photoHeight, 1),
                renderedImage.height
            )
        let bytesPerPixel = 4
        let bytesPerRow =
            renderedImage.width * bytesPerPixel
        var pixels =
            [UInt8](
                repeating: 0,
                count:
                    bytesPerRow
                    * renderedImage.height
            )

        guard let context =
            CGContext(
                data: &pixels,
                width: renderedImage.width,
                height: renderedImage.height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space:
                    CGColorSpaceCreateDeviceRGB(),
                bitmapInfo:
                    CGImageAlphaInfo
                    .premultipliedLast
                    .rawValue
            )
        else {
            return renderedImage
        }

        context.interpolationQuality = .high
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
                x: 0,
                y: 0,
                width: renderedImage.width,
                height: renderedImage.height
            )
        )

        if resolvedPhotoHeight < renderedImage.height,
           let infoBarCrop =
            renderedImage.cropping(
                to:
                    CGRect(
                        x: 0,
                        y: resolvedPhotoHeight,
                        width: renderedImage.width,
                        height:
                            renderedImage.height
                            - resolvedPhotoHeight
                    )
            ) {
            context.draw(
                infoBarCrop,
                in:
                    CGRect(
                        x: 0,
                        y: 0,
                        width: renderedImage.width,
                        height:
                            renderedImage.height
                            - resolvedPhotoHeight
                    )
            )
        }

        context.draw(
            sourceImage,
            in:
                CGRect(
                    x: 0,
                    y:
                        renderedImage.height
                        - resolvedPhotoHeight,
                    width: renderedImage.width,
                    height: resolvedPhotoHeight
                )
        )

        return context.makeImage()
            ?? renderedImage
    }

    static func removingLeftPhotoEdgeArtifact(
        from image: CGImage,
        photoHeight: Int
    ) -> CGImage {

        let resolvedPhotoHeight =
            min(
                max(photoHeight, 1),
                image.height
            )
        let trimWidth =
            leftPhotoEdgeArtifactWidth(
                in: image,
                photoHeight:
                    resolvedPhotoHeight
            )

        guard trimWidth > 0,
              trimWidth < image.width else {
            return image
        }

        let photoCropRect =
            CGRect(
                x: trimWidth,
                y: 0,
                width: image.width - trimWidth,
                height: resolvedPhotoHeight
            )

        guard let photoCrop =
            image.cropping(
                to: photoCropRect
            )
        else {
            return image
        }

        let bytesPerPixel = 4
        let bytesPerRow =
            image.width * bytesPerPixel
        var pixels =
            [UInt8](
                repeating: 0,
                count:
                    bytesPerRow
                    * image.height
            )

        guard let context =
            CGContext(
                data: &pixels,
                width: image.width,
                height: image.height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space:
                    CGColorSpaceCreateDeviceRGB(),
                bitmapInfo:
                    CGImageAlphaInfo
                    .premultipliedLast
                    .rawValue
            )
        else {
            return image
        }

        context.interpolationQuality = .high
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
                x: 0,
                y: 0,
                width: image.width,
                height: image.height
            )
        )

        if resolvedPhotoHeight < image.height,
           let infoBarCrop =
            image.cropping(
                to:
                    CGRect(
                        x: 0,
                        y: resolvedPhotoHeight,
                        width: image.width,
                        height:
                            image.height
                            - resolvedPhotoHeight
                    )
            ) {
            context.draw(
                infoBarCrop,
                in:
                    CGRect(
                        x: 0,
                        y: 0,
                        width: image.width,
                        height:
                            image.height
                            - resolvedPhotoHeight
                    )
            )
        }

        context.draw(
            photoCrop,
            in:
                CGRect(
                    x: 0,
                    y:
                        image.height
                        - resolvedPhotoHeight,
                    width: image.width,
                    height: resolvedPhotoHeight
                )
        )

        return context.makeImage() ?? image
    }

    static func leftPhotoEdgeArtifactWidth(
        in image: CGImage,
        photoHeight: Int
    ) -> Int {

        let resolvedPhotoHeight =
            min(
                max(photoHeight, 1),
                image.height
            )
        let maxTrimWidth =
            min(
                max(
                    Int(
                        ceil(
                            Double(image.width)
                            * 0.03
                        )
                    ),
                    2
                ),
                160
            )
        let sampleWidth =
            min(
                image.width,
                maxTrimWidth + 8
            )

        guard sampleWidth > 2 else {
            return 0
        }

        let bytesPerPixel = 4
        let bytesPerRow =
            sampleWidth * bytesPerPixel
        var pixels =
            [UInt8](
                repeating: 0,
                count:
                    bytesPerRow
                    * resolvedPhotoHeight
            )

        guard let context =
            CGContext(
                data: &pixels,
                width: sampleWidth,
                height: resolvedPhotoHeight,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space:
                    CGColorSpaceCreateDeviceRGB(),
                bitmapInfo:
                    CGImageAlphaInfo
                    .premultipliedLast
                    .rawValue
            )
        else {
            return 0
        }

        context.draw(
            image,
            in:
                CGRect(
                    x: 0,
                    y:
                        -(image.height
                          - resolvedPhotoHeight),
                    width: image.width,
                    height: image.height
                )
        )

        var trimWidth = 0

        for x in 0..<maxTrimWidth {
            guard columnLooksLikeBlackArtifact(
                pixels: pixels,
                x: x,
                height: resolvedPhotoHeight,
                bytesPerRow: bytesPerRow
            ) else {
                break
            }

            trimWidth += 1
        }

        guard trimWidth >= 2,
              trimWidth < maxTrimWidth,
              trimWidth + 1 < sampleWidth else {
            return 0
        }

        let transitionBrightness =
            averageBrightness(
                pixels: pixels,
                x:
                    min(
                        trimWidth + 4,
                        sampleWidth - 1
                    ),
                height: resolvedPhotoHeight,
                bytesPerRow: bytesPerRow
            )

        return transitionBrightness > 45
            ? trimWidth
            : 0
    }
}

private extension PhotoMemoRenderedImageArtifactGuard {

    static func columnLooksLikeBlackArtifact(
        pixels: [UInt8],
        x: Int,
        height: Int,
        bytesPerRow: Int
    ) -> Bool {

        let sampleStep =
            max(
                height / 640,
                1
            )
        var sampleCount = 0
        var darkCount = 0

        for y in stride(
            from: 0,
            to: height,
            by: sampleStep
        ) {
            let index =
                y * bytesPerRow + x * 4
            let maxChannel =
                max(
                    pixels[index],
                    pixels[index + 1],
                    pixels[index + 2]
                )

            sampleCount += 1

            if maxChannel <= 24 {
                darkCount += 1
            }
        }

        guard sampleCount > 0 else {
            return false
        }

        return Double(darkCount)
            / Double(sampleCount)
            >= 0.96
    }

    static func averageBrightness(
        pixels: [UInt8],
        x: Int,
        height: Int,
        bytesPerRow: Int
    ) -> Double {

        let sampleStep =
            max(
                height / 640,
                1
            )
        var sampleCount = 0
        var total = 0.0

        for y in stride(
            from: 0,
            to: height,
            by: sampleStep
        ) {
            let index =
                y * bytesPerRow + x * 4

            total +=
                (
                    Double(pixels[index])
                    + Double(pixels[index + 1])
                    + Double(pixels[index + 2])
                ) / 3
            sampleCount += 1
        }

        guard sampleCount > 0 else {
            return 0
        }

        return total / Double(sampleCount)
    }
}
