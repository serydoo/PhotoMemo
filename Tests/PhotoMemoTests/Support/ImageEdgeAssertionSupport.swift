import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

struct ImageEdgeRowStatistics {

    let minimumAlpha: UInt8
    let maximumAlpha: UInt8
    let minimumRed: UInt8
    let maximumRed: UInt8
    let minimumGreen: UInt8
    let maximumGreen: UInt8
    let minimumBlue: UInt8
    let maximumBlue: UInt8
    let minimumRGB: UInt8
    let maximumRGB: UInt8

    var isFullyOpaque: Bool {
        minimumAlpha == 255
            && maximumAlpha == 255
    }

    func isApproximatelySolid(
        red: UInt8,
        green: UInt8,
        blue: UInt8,
        rgbTolerance: UInt8
    ) -> Bool {
        isFullyOpaque
            && isWithinTolerance(
                minimumRed,
                expected: red,
                tolerance: rgbTolerance
            )
            && isWithinTolerance(
                maximumRed,
                expected: red,
                tolerance: rgbTolerance
            )
            && isWithinTolerance(
                minimumGreen,
                expected: green,
                tolerance: rgbTolerance
            )
            && isWithinTolerance(
                maximumGreen,
                expected: green,
                tolerance: rgbTolerance
            )
            && isWithinTolerance(
                minimumBlue,
                expected: blue,
                tolerance: rgbTolerance
            )
            && isWithinTolerance(
                maximumBlue,
                expected: blue,
                tolerance: rgbTolerance
            )
    }

    private func isWithinTolerance(
        _ value: UInt8,
        expected: UInt8,
        tolerance: UInt8
    ) -> Bool {
        abs(Int(value) - Int(expected))
            <= Int(tolerance)
    }
}

enum ImageEdgeAssertionSupport {

    static func solidImage(
        width: Int,
        height: Int,
        red: UInt8,
        green: UInt8,
        blue: UInt8
    ) throws -> CGImage {
        let bytesPerRow = width * 4
        var pixels = [UInt8](
            repeating: 0,
            count: bytesPerRow * height
        )

        for offset in stride(
            from: 0,
            to: pixels.count,
            by: 4
        ) {
            pixels[offset] = red
            pixels[offset + 1] = green
            pixels[offset + 2] = blue
            pixels[offset + 3] = 255
        }

        guard
            let context = CGContext(
                data: &pixels,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo
                    .premultipliedLast.rawValue
            ),
            let image = context.makeImage()
        else {
            throw ImageEdgeAssertionError.contextUnavailable
        }

        return image
    }

    static func writeJPEG(
        _ image: CGImage,
        to url: URL
    ) throws {
        guard
            let destination = CGImageDestinationCreateWithURL(
                url as CFURL,
                UTType.jpeg.identifier as CFString,
                1,
                nil
            )
        else {
            throw ImageEdgeAssertionError.destinationUnavailable
        }

        CGImageDestinationAddImage(
            destination,
            image,
            [
                kCGImageDestinationLossyCompressionQuality:
                    1.0
            ] as CFDictionary
        )

        guard CGImageDestinationFinalize(destination) else {
            throw ImageEdgeAssertionError.writeFailed
        }
    }

    static func image(at url: URL) throws -> CGImage {
        guard
            let source = CGImageSourceCreateWithURL(
                url as CFURL,
                nil
            ),
            let image = CGImageSourceCreateImageAtIndex(
                source,
                0,
                nil
            )
        else {
            throw ImageEdgeAssertionError.unreadableImage
        }

        return image
    }

    static func bottomRows(
        in image: CGImage,
        count: Int
    ) throws -> [ImageEdgeRowStatistics] {
        let pixels = try rgbaPixels(in: image)
        let rowCount = min(max(count, 0), image.height)

        return (image.height - rowCount..<image.height).map { y in
            var minimumAlpha = UInt8.max
            var maximumAlpha = UInt8.min
            var minimumRed = UInt8.max
            var maximumRed = UInt8.min
            var minimumGreen = UInt8.max
            var maximumGreen = UInt8.min
            var minimumBlue = UInt8.max
            var maximumBlue = UInt8.min
            var minimumRGB = UInt8.max
            var maximumRGB = UInt8.min

            for x in 0..<image.width {
                let offset = (y * image.width + x) * 4
                let red = pixels[offset]
                let green = pixels[offset + 1]
                let blue = pixels[offset + 2]
                let alpha = pixels[offset + 3]
                let pixelMinimum = min(red, green, blue)
                let pixelMaximum = max(red, green, blue)

                minimumAlpha = min(minimumAlpha, alpha)
                maximumAlpha = max(maximumAlpha, alpha)
                minimumRed = min(minimumRed, red)
                maximumRed = max(maximumRed, red)
                minimumGreen = min(minimumGreen, green)
                maximumGreen = max(maximumGreen, green)
                minimumBlue = min(minimumBlue, blue)
                maximumBlue = max(maximumBlue, blue)
                minimumRGB = min(minimumRGB, pixelMinimum)
                maximumRGB = max(maximumRGB, pixelMaximum)
            }

            return ImageEdgeRowStatistics(
                minimumAlpha: minimumAlpha,
                maximumAlpha: maximumAlpha,
                minimumRed: minimumRed,
                maximumRed: maximumRed,
                minimumGreen: minimumGreen,
                maximumGreen: maximumGreen,
                minimumBlue: minimumBlue,
                maximumBlue: maximumBlue,
                minimumRGB: minimumRGB,
                maximumRGB: maximumRGB
            )
        }
    }

    private static func rgbaPixels(
        in image: CGImage
    ) throws -> [UInt8] {
        let bytesPerRow = image.width * 4
        var pixels = [UInt8](
            repeating: 0,
            count: bytesPerRow * image.height
        )

        guard
            let context = CGContext(
                data: &pixels,
                width: image.width,
                height: image.height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo
                    .premultipliedLast.rawValue
            )
        else {
            throw ImageEdgeAssertionError.contextUnavailable
        }

        context.interpolationQuality = .none
        context.draw(
            image,
            in: CGRect(
                x: 0,
                y: 0,
                width: image.width,
                height: image.height
            )
        )
        return pixels
    }
}

enum ImageEdgeAssertionError: Error {
    case unreadableImage
    case contextUnavailable
    case destinationUnavailable
    case writeFailed
}
