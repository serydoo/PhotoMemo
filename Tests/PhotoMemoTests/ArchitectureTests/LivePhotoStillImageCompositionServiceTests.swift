import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import PhotoMemo

@Suite("Live Photo still-image composition service")
struct LivePhotoStillImageCompositionServiceTests {

    @Test("Composes a still image with matching footer geometry and revised metadata")
    func composesStillImageWithMatchingFooterGeometryAndRevisedMetadata() throws {
        let temporaryFolder =
            FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "LivePhotoStillImageCompositionServiceTests-\(UUID().uuidString)",
                isDirectory: true
            )
        try FileManager.default.createDirectory(
            at: temporaryFolder,
            withIntermediateDirectories: true
        )
        defer {
            try? FileManager.default.removeItem(
                at: temporaryFolder
            )
        }

        let sourceStillURL =
            temporaryFolder.appendingPathComponent(
                "source.jpg"
            )
        try writeSourceImage(
            at: sourceStillURL,
            size: CGSize(width: 40, height: 30),
            color: .red
        )

        let outputStillURL =
            temporaryFolder.appendingPathComponent(
                "output.png"
            )
        let footerImage =
            try makeSolidColorImage(
                color: .blue,
                size: CGSize(width: 40, height: 11)
            )
        let descriptor =
            try FixedFooterOverlayDescriptor(
                canvasSize: CGSize(width: 40, height: 41),
                photoFrame: CGRect(x: 0, y: 11, width: 40, height: 30),
                footerFrame: CGRect(x: 0, y: 0, width: 40, height: 11),
                footerImage: footerImage
            )

        let resultURL =
            try LivePhotoStillImageCompositionService()
            .composeStillImage(
                sourceStillURL: sourceStillURL,
                overlay: descriptor,
                outputURL: outputStillURL,
                outputType: .png
            )

        let resultImage =
            try loadImage(
                at: resultURL
            )
        let resultProperties =
            try loadProperties(
                at: resultURL
            )

        #expect(
            resultImage.width == 40
        )
        #expect(
            resultImage.height == 40
        )
        #expect(
            resultProperties[
                kCGImagePropertyPixelWidth
            ] as? Int == 40
        )
        #expect(
            resultProperties[
                kCGImagePropertyPixelHeight
            ] as? Int == 40
        )
        #expect(
            resultProperties[
                kCGImagePropertyOrientation
            ] as? Int == 1
        )

        let exif =
            try #require(
                resultProperties[
                    kCGImagePropertyExifDictionary
                ] as? [CFString: Any]
            )
        #expect(
            exif[
                kCGImagePropertyExifPixelXDimension
            ] as? Int == 40
        )
        #expect(
            exif[
                kCGImagePropertyExifPixelYDimension
            ] as? Int == 40
        )
        #expect(
            exif[
                kCGImagePropertyExifDateTimeOriginal
            ] as? String == "2026:06:25 12:34:56"
        )

        let tiff =
            try #require(
                resultProperties[
                    kCGImagePropertyTIFFDictionary
                ] as? [CFString: Any]
            )
        #expect(
            tiff[
                kCGImagePropertyTIFFMake
            ] as? String == "Apple"
        )
        #expect(
            tiff[
                kCGImagePropertyTIFFModel
            ] as? String == "iPhone"
        )
        #expect(
            tiff[
                kCGImagePropertyTIFFSoftware
            ] as? String == "MemoMark"
        )

        let gps =
            try #require(
                resultProperties[
                    kCGImagePropertyGPSDictionary
                ] as? [CFString: Any]
            )
        #expect(
            gps[
                kCGImagePropertyGPSLatitude
            ] as? Double == 34.414
        )
        #expect(
            gps[
                kCGImagePropertyGPSLongitude
            ] as? Double == 115.656
        )

        let footerAverage =
            averageColor(
                in: resultImage,
                rect: CGRect(x: 0, y: 0, width: 40, height: 10)
            )
        let photoAverage =
            averageColor(
                in: resultImage,
                rect: CGRect(x: 0, y: 10, width: 40, height: 30)
            )

        #expect(
            colorDistance(footerAverage, .blue) <= 10
        )
        #expect(
            colorDistance(photoAverage, .red) <= 10
        )
    }

    @Test("Synthesizes generated Live Photo pairing metadata into composed still image")
    func synthesizesGeneratedLivePhotoPairingMetadataIntoComposedStillImage() throws {
        let temporaryFolder =
            FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "LivePhotoStillImageCompositionServiceTests-\(UUID().uuidString)",
                isDirectory: true
            )
        try FileManager.default.createDirectory(
            at: temporaryFolder,
            withIntermediateDirectories: true
        )
        defer {
            try? FileManager.default.removeItem(
                at: temporaryFolder
            )
        }

        let sourceStillURL =
            temporaryFolder.appendingPathComponent(
                "source.jpg"
            )
        try writeSourceImage(
            at: sourceStillURL,
            size: CGSize(width: 40, height: 30),
            color: .red
        )

        let outputStillURL =
            temporaryFolder.appendingPathComponent(
                "output.heic"
            )
        let descriptor =
            try FixedFooterOverlayDescriptor(
                canvasSize: CGSize(width: 40, height: 40),
                photoFrame: CGRect(x: 0, y: 10, width: 40, height: 30),
                footerFrame: CGRect(x: 0, y: 0, width: 40, height: 10),
                footerImage:
                    makeSolidColorImage(
                        color: .blue,
                        size: CGSize(width: 40, height: 10)
                    )
            )

        let resultURL =
            try LivePhotoStillImageCompositionService()
            .composeStillImage(
                sourceStillURL: sourceStillURL,
                overlay: descriptor,
                outputURL: outputStillURL,
                outputType: .heic,
                pairingIdentifier:
                    "2AB295AF-CFD8-4C47-9579-90249E28F68F"
            )
        let properties =
            try loadProperties(
                at: resultURL
            )

        #expect(
            LivePhotoPairingIdentityVerifier
                .stillContentIdentifier(
                    from: properties as [String: Any]
                )
            == "2AB295AF-CFD8-4C47-9579-90249E28F68F"
        )
    }

    @Test("Writes MemoMark export description metadata into composed still image")
    func writesExportDescriptionMetadataIntoComposedStillImage() throws {
        let temporaryFolder =
            FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "LivePhotoStillImageCompositionServiceTests-\(UUID().uuidString)",
                isDirectory: true
            )
        try FileManager.default.createDirectory(
            at: temporaryFolder,
            withIntermediateDirectories: true
        )
        defer {
            try? FileManager.default.removeItem(
                at: temporaryFolder
            )
        }

        let sourceStillURL =
            temporaryFolder.appendingPathComponent(
                "source.jpg"
            )
        try writeSourceImage(
            at: sourceStillURL,
            size: CGSize(width: 40, height: 30),
            color: .red
        )

        let outputStillURL =
            temporaryFolder.appendingPathComponent(
                "output.heic"
            )
        let descriptor =
            try FixedFooterOverlayDescriptor(
                canvasSize: CGSize(width: 40, height: 40),
                photoFrame: CGRect(x: 0, y: 10, width: 40, height: 30),
                footerFrame: CGRect(x: 0, y: 0, width: 40, height: 10),
                footerImage:
                    makeSolidColorImage(
                        color: .blue,
                        size: CGSize(width: 40, height: 10)
                    )
            )
        let expectedDescription =
            "右下默认说明"

        let resultURL =
            try LivePhotoStillImageCompositionService()
            .composeStillImage(
                sourceStillURL: sourceStillURL,
                overlay: descriptor,
                outputURL: outputStillURL,
                outputType: .heic,
                outputDescription:
                    expectedDescription
            )
        let properties =
            try loadProperties(
                at: resultURL
            )
        let exif =
            try #require(
                properties[
                    kCGImagePropertyExifDictionary
                ] as? [CFString: Any]
            )
        let tiff =
            try #require(
                properties[
                    kCGImagePropertyTIFFDictionary
                ] as? [CFString: Any]
            )
        let iptc =
            try #require(
                properties[
                    kCGImagePropertyIPTCDictionary
                ] as? [CFString: Any]
            )

        let exifUserComment =
            exif[
                "UserComment" as CFString
            ] as? String
        #expect(
            exifUserComment == nil
            || exifUserComment == expectedDescription
        )
        #expect(
            tiff[
                kCGImagePropertyTIFFImageDescription
            ] as? String == expectedDescription
        )
        #expect(
            iptc[
                kCGImagePropertyIPTCCaptionAbstract
            ] as? String == expectedDescription
        )
    }

    @Test("Composes source still into the renderer photo frame without stretching")
    func composesSourceStillWithoutStretching() throws {
        let temporaryFolder =
            FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "LivePhotoStillImageCompositionServiceTests-\(UUID().uuidString)",
                isDirectory: true
            )
        try FileManager.default.createDirectory(
            at: temporaryFolder,
            withIntermediateDirectories: true
        )
        defer {
            try? FileManager.default.removeItem(
                at: temporaryFolder
            )
        }

        let sourceStillURL =
            temporaryFolder.appendingPathComponent(
                "source.png"
            )
        try writeHorizontalStripeImage(
            at: sourceStillURL,
            size: CGSize(width: 40, height: 20)
        )

        let outputStillURL =
            temporaryFolder.appendingPathComponent(
                "output.png"
            )
        let descriptor =
            try FixedFooterOverlayDescriptor(
                canvasSize: CGSize(width: 40, height: 50),
                photoFrame: CGRect(x: 0, y: 10, width: 40, height: 40),
                footerFrame: CGRect(x: 0, y: 0, width: 40, height: 10),
                footerImage:
                    makeSolidColorImage(
                        color: .blue,
                        size: CGSize(width: 40, height: 10)
                    )
            )

        let resultURL =
            try LivePhotoStillImageCompositionService()
            .composeStillImage(
                sourceStillURL: sourceStillURL,
                overlay: descriptor,
                outputURL: outputStillURL,
                outputType: .png
            )
        let resultImage =
            try loadImage(
                at: resultURL
            )
        let photoAverage =
            averageColor(
                in: resultImage,
                rect: CGRect(x: 0, y: 10, width: 40, height: 40)
            )

        #expect(
            colorDistance(photoAverage, .green) <= 20
        )
    }
}

private extension LivePhotoStillImageCompositionServiceTests {

    struct RGBAColor:
        Equatable,
        Sendable {
        let red: UInt8
        let green: UInt8
        let blue: UInt8
        let alpha: UInt8

        static let red = RGBAColor(
            red: 255,
            green: 0,
            blue: 0,
            alpha: 255
        )
        static let blue = RGBAColor(
            red: 0,
            green: 0,
            blue: 255,
            alpha: 255
        )
        static let green = RGBAColor(
            red: 0,
            green: 255,
            blue: 0,
            alpha: 255
        )
    }

    func writeSourceImage(
        at url: URL,
        size: CGSize,
        color: RGBAColor
    ) throws {
        let image =
            try makeSolidColorImage(
                color: color,
                size: size
            )
        let properties: [CFString: Any] = [
            kCGImagePropertyPixelWidth:
                Int(size.width),
            kCGImagePropertyPixelHeight:
                Int(size.height),
            kCGImagePropertyOrientation:
                6,
            kCGImagePropertyExifDictionary: [
                kCGImagePropertyExifPixelXDimension:
                    Int(size.width),
                kCGImagePropertyExifPixelYDimension:
                    Int(size.height),
                kCGImagePropertyExifDateTimeOriginal:
                    "2026:06:25 12:34:56"
            ],
            kCGImagePropertyTIFFDictionary: [
                kCGImagePropertyTIFFMake:
                    "Apple",
                kCGImagePropertyTIFFModel:
                    "iPhone"
            ],
            kCGImagePropertyGPSDictionary: [
                kCGImagePropertyGPSLatitude:
                    34.414,
                kCGImagePropertyGPSLatitudeRef:
                    "N",
                kCGImagePropertyGPSLongitude:
                    115.656,
                kCGImagePropertyGPSLongitudeRef:
                    "E"
            ]
        ]

        let destination =
            try #require(
                CGImageDestinationCreateWithURL(
                    url as CFURL,
                    UTType.jpeg.identifier as CFString,
                    1,
                    nil
                )
            )
        CGImageDestinationAddImage(
            destination,
            image,
            properties as CFDictionary
        )
        #expect(
            CGImageDestinationFinalize(destination)
        )
    }

    func writeHorizontalStripeImage(
        at url: URL,
        size: CGSize
    ) throws {
        let image =
            try makeHorizontalStripeImage(
                size: size
            )
        let destination =
            try #require(
                CGImageDestinationCreateWithURL(
                    url as CFURL,
                    UTType.png.identifier as CFString,
                    1,
                    nil
                )
            )
        CGImageDestinationAddImage(
            destination,
            image,
            nil
        )
        #expect(
            CGImageDestinationFinalize(destination)
        )
    }

    func makeSolidColorImage(
        color: RGBAColor,
        size: CGSize
    ) throws -> CGImage {
        let width = Int(size.width)
        let height = Int(size.height)
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var data =
            [UInt8](
                repeating: 0,
                count: bytesPerRow * height
            )

        for index in stride(
            from: 0,
            to: data.count,
            by: 4
        ) {
            data[index] = color.red
            data[index + 1] = color.green
            data[index + 2] = color.blue
            data[index + 3] = color.alpha
        }

        let provider =
            try #require(
                CGDataProvider(
                    data: Data(data) as CFData
                )
            )

        return try #require(
            CGImage(
                width: width,
                height: height,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: bytesPerRow,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo:
                    CGBitmapInfo(
                        rawValue:
                            CGImageAlphaInfo
                            .premultipliedLast
                            .rawValue
                    ),
                provider: provider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
            )
        )
    }

    func makeHorizontalStripeImage(
        size: CGSize
    ) throws -> CGImage {
        let width = Int(size.width)
        let height = Int(size.height)
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var data =
            [UInt8](
                repeating: 0,
                count: bytesPerRow * height
            )

        for row in 0 ..< height {
            for column in 0 ..< width {
                let color: RGBAColor =
                    if column < width / 4 {
                        .red
                    } else if column >= width * 3 / 4 {
                        .blue
                    } else {
                        .green
                    }
                let offset =
                    row * bytesPerRow
                    + column * bytesPerPixel
                data[offset] = color.red
                data[offset + 1] = color.green
                data[offset + 2] = color.blue
                data[offset + 3] = color.alpha
            }
        }

        let provider =
            try #require(
                CGDataProvider(
                    data: Data(data) as CFData
                )
            )

        return try #require(
            CGImage(
                width: width,
                height: height,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: bytesPerRow,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo:
                    CGBitmapInfo(
                        rawValue:
                            CGImageAlphaInfo
                            .premultipliedLast
                            .rawValue
                    ),
                provider: provider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
            )
        )
    }

    func loadImage(
        at url: URL
    ) throws -> CGImage {
        let source =
            try #require(
                CGImageSourceCreateWithURL(
                    url as CFURL,
                    nil
                )
            )
        return try #require(
            CGImageSourceCreateImageAtIndex(
                source,
                0,
                nil
            )
        )
    }

    func loadProperties(
        at url: URL
    ) throws -> [CFString: Any] {
        let source =
            try #require(
                CGImageSourceCreateWithURL(
                    url as CFURL,
                    nil
                )
            )
        return try #require(
            CGImageSourceCopyPropertiesAtIndex(
                source,
                0,
                nil
            ) as? [CFString: Any]
        )
    }

    func pixelColor(
        in image: CGImage,
        at point: CGPoint
    ) -> RGBAColor {
        guard
            let dataProvider =
                image.dataProvider,
            let bytes =
                CFDataGetBytePtr(
                    dataProvider.data
                )
        else {
            return RGBAColor(
                red: 0,
                green: 0,
                blue: 0,
                alpha: 0
            )
        }

        let x =
            min(
                max(Int(point.x), 0),
                image.width - 1
            )
        let yFromBottom =
            min(
                max(Int(point.y), 0),
                image.height - 1
            )
        let y =
            image.height - 1 - yFromBottom
        let offset =
            y * image.bytesPerRow
            + x * 4

        return RGBAColor(
            red: bytes[offset],
            green: bytes[offset + 1],
            blue: bytes[offset + 2],
            alpha: bytes[offset + 3]
        )
    }

    func averageColor(
        in image: CGImage,
        rect: CGRect
    ) -> RGBAColor {
        var redTotal = 0
        var greenTotal = 0
        var blueTotal = 0
        var alphaTotal = 0
        var count = 0

        for x in Int(rect.minX) ..< Int(rect.maxX) {
            for y in Int(rect.minY) ..< Int(rect.maxY) {
                let color =
                    pixelColor(
                        in: image,
                        at: CGPoint(x: x, y: y)
                    )
                redTotal += Int(color.red)
                greenTotal += Int(color.green)
                blueTotal += Int(color.blue)
                alphaTotal += Int(color.alpha)
                count += 1
            }
        }

        return RGBAColor(
            red: UInt8(redTotal / max(count, 1)),
            green: UInt8(greenTotal / max(count, 1)),
            blue: UInt8(blueTotal / max(count, 1)),
            alpha: UInt8(alphaTotal / max(count, 1))
        )
    }

    func colorDistance(
        _ lhs: RGBAColor,
        _ rhs: RGBAColor
    ) -> Int {
        abs(Int(lhs.red) - Int(rhs.red))
            + abs(Int(lhs.green) - Int(rhs.green))
            + abs(Int(lhs.blue) - Int(rhs.blue))
    }
}
