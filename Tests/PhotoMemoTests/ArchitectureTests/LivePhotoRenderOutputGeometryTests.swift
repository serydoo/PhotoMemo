import CoreGraphics
import Foundation
import Testing
@testable import PhotoMemo

@Suite("Live Photo render output geometry")
struct LivePhotoRenderOutputGeometryTests {

    @Test("Classic White geometry follows the current orientation-specific output size")
    func classicWhiteGeometryFollowsCurrentOrientationSpecificOutputSize() throws {
        let landscapeMetadata =
            PhotoMetadata(
                imageWidth: 4032,
                imageHeight: 3024
            )
        let portraitMetadata =
            PhotoMetadata(
                imageWidth: 3024,
                imageHeight: 4032
            )

        let landscapeOutput =
            ClassicWhiteRenderer
            .outputPixelSize(
                for: landscapeMetadata,
                fallbackSize:
                    CGSize(width: 4032, height: 3024)
            )
        let portraitOutput =
            ClassicWhiteRenderer
            .outputPixelSize(
                for: portraitMetadata,
                fallbackSize:
                    CGSize(width: 3024, height: 4032)
            )

        let landscapeGeometry =
            try LivePhotoRenderOutputGeometry
            .resolved(
                renderedPixelSize:
                    landscapeOutput,
                sourcePhotoPixelSize:
                    CGSize(width: 4032, height: 3024)
            )
        let portraitGeometry =
            try LivePhotoRenderOutputGeometry
            .resolved(
                renderedPixelSize:
                    portraitOutput,
                sourcePhotoPixelSize:
                    CGSize(width: 3024, height: 4032)
            )

        let landscapeFooterHeight =
            landscapeOutput.height - 3024
        let portraitFooterHeight =
            portraitOutput.height - 4032

        #expect(
            landscapeGeometry.footerFrame.height
            == landscapeFooterHeight
        )
        #expect(
            portraitGeometry.footerFrame.height
            == portraitFooterHeight
        )
        let expectedLandscapeFooterHeight = Int(
            ceil(
                3024
                    * ClassicWhiteRenderer
                    .layout(for: .landscape)
                    .borderToImageHeightRatio
            )
        )
        let expectedPortraitFooterHeight = Int(
            ceil(
                4032
                    * ClassicWhiteRenderer
                    .layout(for: .portrait)
                    .borderToImageHeightRatio
            )
        )
        #expect(
            Int(landscapeFooterHeight) == expectedLandscapeFooterHeight
                || Int(landscapeFooterHeight) == expectedLandscapeFooterHeight + 1
        )
        #expect(
            Int(portraitFooterHeight) == expectedPortraitFooterHeight
                || Int(portraitFooterHeight) == expectedPortraitFooterHeight + 1
        )
        #expect(
            landscapeGeometry.footerFrame.height
            != portraitGeometry.footerFrame.height
        )
    }

    @Test("Extracts the footer image from the canonical footer frame")
    func extractsFooterImageFromCanonicalFooterFrame() throws {
        let renderedImage =
            try makeRenderedOutputImage(
                width: 40,
                photoHeight: 30,
                footerHeight: 10
            )

        let descriptor =
            try LivePhotoRenderOutputGeometry
            .overlayDescriptor(
                renderedOutputImage: renderedImage,
                sourcePhotoPixelSize:
                    CGSize(width: 40, height: 30)
            )

        #expect(
            descriptor.canvasSize
            == CGSize(width: 40, height: 40)
        )
        #expect(
            descriptor.photoFrame
            == CGRect(x: 0, y: 10, width: 40, height: 30)
        )
        #expect(
            descriptor.footerFrame
            == CGRect(x: 0, y: 0, width: 40, height: 10)
        )
        #expect(
            averageColor(
                in: descriptor.footerImage
            ) == .blue
        )
    }

    @Test("Extracts footer by renderer footer height instead of source photo size")
    func extractsFooterByRendererFooterHeight() throws {
        let renderedImage =
            try makeRenderedOutputImage(
                width: 40,
                photoHeight: 30,
                footerHeight: 10
            )

        let descriptor =
            try LivePhotoRenderOutputGeometry
            .overlayDescriptor(
                renderedOutputImage: renderedImage,
                footerHeight: 10
            )

        #expect(
            descriptor.photoFrame
            == CGRect(x: 0, y: 10, width: 40, height: 30)
        )
        #expect(
            descriptor.footerFrame
            == CGRect(x: 0, y: 0, width: 40, height: 10)
        )
        #expect(
            averageColor(
                in: descriptor.footerImage
            ) == .blue
        )
    }

    @Test("Appended output geometry keeps photo and footer as distinct regions")
    func acceptsAppendedOutputGeometry() throws {
        let descriptor = try FixedFooterOverlayDescriptor(
            canvasSize: CGSize(width: 40, height: 40),
            photoFrame: CGRect(x: 0, y: 10, width: 40, height: 30),
            footerFrame: CGRect(x: 0, y: 0, width: 40, height: 10),
            footerImage: makeRenderedOutputImage(
                width: 40,
                photoHeight: 10,
                footerHeight: 0
            )
        )

        #expect(descriptor.placement == .footer)
        #expect(descriptor.canvasBackground == .opaqueWhite)
        #expect(descriptor.photoFrame == CGRect(x: 0, y: 10, width: 40, height: 30))
        #expect(descriptor.footerFrame == CGRect(x: 0, y: 0, width: 40, height: 10))
        #expect(
            descriptor.photoFrame
            .intersection(descriptor.footerFrame)
            .height == 0
        )
    }
}

private extension LivePhotoRenderOutputGeometryTests {

    struct RGBAColor:
        Equatable,
        Sendable {
        let red: UInt8
        let green: UInt8
        let blue: UInt8
        let alpha: UInt8

        static let red =
            RGBAColor(
                red: 255,
                green: 0,
                blue: 0,
                alpha: 255
            )
        static let blue =
            RGBAColor(
                red: 0,
                green: 0,
                blue: 255,
                alpha: 255
            )
    }

    func makeRenderedOutputImage(
        width: Int,
        photoHeight: Int,
        footerHeight: Int
    ) throws -> CGImage {
        let height =
            max(photoHeight + footerHeight, 1)
        let bytesPerPixel = 4
        let bytesPerRow =
            width * bytesPerPixel
        var data =
            [UInt8](
                repeating: 0,
                count: bytesPerRow * height
            )

        for row in 0 ..< height {
            // The export artifact guard writes the footer into the
            // canonical footer band at y = 0, followed by the preserved
            // photo area. This mirrors the production output consumed by
            // `overlayDescriptor`.
            let color: RGBAColor =
                row < footerHeight
                ? .blue
                : .red

            for column in 0 ..< width {
                let offset =
                    row * bytesPerRow
                    + column * 4
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
                space:
                    CGColorSpaceCreateDeviceRGB(),
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

    func averageColor(
        in image: CGImage
    ) -> RGBAColor {
        guard
            let provider =
                image.dataProvider,
            let bytes =
                CFDataGetBytePtr(
                    provider.data
                )
        else {
            return RGBAColor(
                red: 0,
                green: 0,
                blue: 0,
                alpha: 0
            )
        }

        var redTotal = 0
        var greenTotal = 0
        var blueTotal = 0
        var alphaTotal = 0
        var count = 0

        for row in 0 ..< image.height {
            for column in 0 ..< image.width {
                let offset =
                    row * image.bytesPerRow
                    + column * 4
                redTotal += Int(bytes[offset])
                greenTotal += Int(bytes[offset + 1])
                blueTotal += Int(bytes[offset + 2])
                alphaTotal += Int(bytes[offset + 3])
                count += 1
            }
        }

        return RGBAColor(
            red:
                UInt8(redTotal / max(count, 1)),
            green:
                UInt8(greenTotal / max(count, 1)),
            blue:
                UInt8(blueTotal / max(count, 1)),
            alpha:
                UInt8(alphaTotal / max(count, 1))
        )
    }
}
