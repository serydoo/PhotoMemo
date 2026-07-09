import CoreGraphics
import Foundation
import Testing
@testable import PhotoMemo

@Suite("Live Photo render output geometry")
struct LivePhotoRenderOutputGeometryTests {

    @Test("Classic White geometry follows the V1 fixed bottom-bar height")
    func classicWhiteGeometryFollowsV1FixedBottomBarHeight() throws {
        let sourceSize =
            CGSize(width: 4032, height: 3024)
        let renderedSize =
            CGSize(
                width: sourceSize.width,
                height:
                    sourceSize.height
                    + ClassicWhiteRenderer
                    .theme
                    .bottomBar
                    .height
            )

        let geometry =
            try LivePhotoRenderOutputGeometry
            .resolved(
                renderedPixelSize: renderedSize,
                sourcePhotoPixelSize: sourceSize
            )

        #expect(
            geometry.canvasSize == renderedSize
        )
        #expect(
            geometry.photoFrame
            == CGRect(
                x: 0,
                y: 260,
                width: 4032,
                height: 3024
            )
        )
        #expect(
            geometry.footerFrame
            == CGRect(
                x: 0,
                y: 0,
                width: 4032,
                height: 260
            )
        )
    }

    @Test("Immers geometry follows the V1 orientation-specific output size")
    func immersGeometryFollowsV1OrientationSpecificOutputSize() throws {
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
            ImmersWhiteRenderer
            .outputPixelSize(
                for: landscapeMetadata,
                fallbackSize:
                    CGSize(width: 4032, height: 3024)
            )
        let portraitOutput =
            ImmersWhiteRenderer
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

        #expect(
            abs(
                landscapeGeometry.footerFrame.height
                - 3024
                * ImmersWhiteRenderer
                .layout(for: .landscape)
                .borderToImageHeightRatio
            ) < 0.001
        )
        #expect(
            abs(
                portraitGeometry.footerFrame.height
                - 4032
                * ImmersWhiteRenderer
                .layout(for: .portrait)
                .borderToImageHeightRatio
            ) < 0.001
        )
        #expect(
            landscapeGeometry.footerFrame.height
            != portraitGeometry.footerFrame.height
        )
    }

    @Test("Extracts the footer image from the V1 rendered output bottom area")
    func extractsFooterImageFromRenderedOutputBottomArea() throws {
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
            photoHeight + footerHeight
        let bytesPerPixel = 4
        let bytesPerRow =
            width * bytesPerPixel
        var data =
            [UInt8](
                repeating: 0,
                count: bytesPerRow * height
            )

        for row in 0 ..< height {
            let color: RGBAColor =
                row < photoHeight
                ? .red
                : .blue

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
