import Foundation
import CoreGraphics
import Testing
import UniformTypeIdentifiers
@testable import PhotoMemo
#if os(macOS)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

@Suite("PhotoImportService")
struct PhotoImportServiceTests {

    @Test("Preserves explicit suggested file names for data imports")
    func preservesExplicitSuggestedFileNames() async throws {

        let sourceURL =
            try SyntheticFixtureLibrary.fixtureURL(
                .iphoneJPEG
            )
        let sourceData =
            try Data(contentsOf: sourceURL)

        let importedPhoto =
            try await PhotoImportService()
            .importPhoto(
                from: sourceData,
                suggestedFileName:
                    "IMG_9558.HEIC",
                contentType: .heic
            )

        defer {
            try? FileManager.default.removeItem(
                at: importedPhoto.sourceURL
            )
        }

        #expect(
            importedPhoto.sourceURL
            .lastPathComponent
            == "IMG_9558.HEIC"
        )
        #expect(
            importedPhoto.sourceInfo
            .originalFileName
            == "IMG_9558.HEIC"
        )
        #expect(
            importedPhoto.sourceInfo
            .contentTypeIdentifier
            == UTType.heic.identifier
        )
    }

    @Test("Falls back away from the Photo Library placeholder for data imports")
    func fallsBackAwayFromPhotoLibraryPlaceholder() async throws {

        let sourceURL =
            try SyntheticFixtureLibrary.fixtureURL(
                .portraitJPEG
            )
        let sourceData =
            try Data(contentsOf: sourceURL)

        let importedPhoto =
            try await PhotoImportService()
            .importPhoto(
                from: sourceData,
                suggestedFileName:
                    "Photo Library",
                contentType: .jpeg
            )

        defer {
            try? FileManager.default.removeItem(
                at: importedPhoto.sourceURL
            )
        }

        #expect(
            importedPhoto.sourceURL
            .lastPathComponent
            != "Photo Library.jpg"
        )
        #expect(
            importedPhoto.sourceURL
            .lastPathComponent
            .hasPrefix(
                "PhotoMemo Import"
            )
        )
        #expect(
            importedPhoto.sourceURL
            .pathExtension
            .lowercased()
            == "jpg"
        )
    }

    @Test("Repeated data imports keep the original source file name")
    func repeatedDataImportsKeepOriginalSourceFileName() async throws {

        let sourceURL =
            try SyntheticFixtureLibrary.fixtureURL(
                .landscapeJPEG
            )
        let sourceData =
            try Data(contentsOf: sourceURL)
        let service = PhotoImportService()

        let firstImport =
            try await service.importPhoto(
                from: sourceData,
                suggestedFileName:
                    "IMG_7065.JPEG",
                contentType: .jpeg
            )

        let secondImport =
            try await service.importPhoto(
                from: sourceData,
                suggestedFileName:
                    "IMG_7065.JPEG",
                contentType: .jpeg
            )

        defer {
            try? FileManager.default.removeItem(
                at: firstImport.sourceURL
            )
            try? FileManager.default.removeItem(
                at: secondImport.sourceURL
            )
            try? FileManager.default.removeItem(
                at: firstImport.sourceURL
                    .deletingLastPathComponent()
            )
            try? FileManager.default.removeItem(
                at: secondImport.sourceURL
                    .deletingLastPathComponent()
            )
        }

        #expect(
            firstImport.sourceURL
            .lastPathComponent
            == "IMG_7065.JPEG"
        )
        #expect(
            secondImport.sourceURL
            .lastPathComponent
            == "IMG_7065.JPEG"
        )
        #expect(
            firstImport.sourceInfo
            .originalFileName
            == "IMG_7065.JPEG"
        )
        #expect(
            secondImport.sourceInfo
            .originalFileName
            == "IMG_7065.JPEG"
        )
        #expect(
            firstImport.sourceURL
            .deletingLastPathComponent()
            != secondImport.sourceURL
            .deletingLastPathComponent()
        )
    }

    @Test("Carries source asset identifier and type into imported photos")
    func carriesSourceAssetIdentifierAndTypeIntoImportedPhotos() async throws {

        let sourceURL =
            try SyntheticFixtureLibrary.fixtureURL(
                .iphoneJPEG
            )
        let sourceData =
            try Data(contentsOf: sourceURL)

        let importedPhoto =
            try await PhotoImportService()
            .importPhoto(
                from: sourceData,
                suggestedFileName:
                    "IMG_6001.HEIC",
                contentType: .heic,
                assetLocalIdentifier:
                    "asset-local-123"
            )

        defer {
            try? FileManager.default.removeItem(
                at: importedPhoto.sourceURL
            )
        }

        #expect(
            importedPhoto.sourceInfo
            .originalFileName
            == "IMG_6001.HEIC"
        )
        #expect(
            importedPhoto.sourceInfo
            .assetLocalIdentifier
            == "asset-local-123"
        )
        #expect(
            importedPhoto.sourceInfo
            .contentTypeIdentifier
            == UTType.heic.identifier
        )
    }

    @Test("Removes narrow black left edge artifact while preserving size")
    func removesNarrowBlackLeftEdgeArtifact() throws {

        let sourceImage =
            PlatformImage.photoMemoImage(
                cgImage:
                    try makeSyntheticEdgeArtifactImage(
                        width: 400,
                        height: 640,
                        blackWidth: 6
                    )
            )

        let correctedImage =
            sourceImage
            .removingPhotoMemoLeftEdgeArtifact()

        #expect(
            correctedImage.photoMemoSize
            == sourceImage.photoMemoSize
        )

        let correctedCGImage =
            try #require(
                cgImage(
                    from: correctedImage
                )
            )
        let leftPixel =
            try pixel(
                in: correctedCGImage,
                x: 0,
                y: 0
            )

        #expect(
            max(
                leftPixel.red,
                leftPixel.green,
                leftPixel.blue
            ) > 45
        )
    }

    @Test("Removes wider portrait black left edge artifact while preserving size")
    func removesWiderPortraitBlackLeftEdgeArtifact() throws {

        let sourceImage =
            PlatformImage.photoMemoImage(
                cgImage:
                    try makeSyntheticEdgeArtifactImage(
                        width: 4_536,
                        height: 806,
                        blackWidth: 122
                    )
            )

        let correctedImage =
            sourceImage
            .removingPhotoMemoLeftEdgeArtifact()

        #expect(
            correctedImage.photoMemoSize
            == sourceImage.photoMemoSize
        )

        let correctedCGImage =
            try #require(
                cgImage(
                    from: correctedImage
                )
            )
        let leftPixel =
            try pixel(
                in: correctedCGImage,
                x: 0,
                y: 0
            )

        #expect(
            max(
                leftPixel.red,
                leftPixel.green,
                leftPixel.blue
            ) > 45
        )
    }

    @Test("Corrects rendered photo area edge without changing information bar")
    func correctsRenderedPhotoAreaEdgeWithoutChangingInformationBar() throws {

        let renderedImage =
            try makeSyntheticRenderedImage(
                width: 400,
                photoHeight: 640,
                barHeight: 80,
                blackWidth: 6
            )

        let correctedImage =
            PhotoMemoRenderedImageArtifactGuard
            .removingLeftPhotoEdgeArtifact(
                from: renderedImage,
                photoHeight: 640
            )

        #expect(correctedImage.width == renderedImage.width)
        #expect(correctedImage.height == renderedImage.height)

        let photoLeftPixel =
            try pixel(
                in: correctedImage,
                x: 0,
                y: 0
            )
        let barLeftPixel =
            try pixel(
                in: correctedImage,
                x: 0,
                y: 700
            )

        #expect(
            max(
                photoLeftPixel.red,
                photoLeftPixel.green,
                photoLeftPixel.blue
            ) > 45
        )
        #expect(barLeftPixel.red > 230)
        #expect(barLeftPixel.green > 230)
        #expect(barLeftPixel.blue > 230)
    }

    @Test("Corrects wider portrait rendered photo edge artifact")
    func correctsWiderPortraitRenderedPhotoEdgeArtifact() throws {

        let renderedImage =
            try makeSyntheticRenderedImage(
                width: 4_536,
                photoHeight: 806,
                barHeight: 75,
                blackWidth: 122
            )
        let originalPhotoLeftPixel =
            try pixel(
                in: renderedImage,
                x: 0,
                y: 0
            )

        #expect(
            max(
                originalPhotoLeftPixel.red,
                originalPhotoLeftPixel.green,
                originalPhotoLeftPixel.blue
            ) <= 24
        )
        #expect(
            PhotoMemoRenderedImageArtifactGuard
                .leftPhotoEdgeArtifactWidth(
                    in: renderedImage,
                    photoHeight: 806
                ) == 122
        )

        let correctedImage =
            PhotoMemoRenderedImageArtifactGuard
            .removingLeftPhotoEdgeArtifact(
                from: renderedImage,
                photoHeight: 806
            )

        #expect(correctedImage.width == renderedImage.width)
        #expect(correctedImage.height == renderedImage.height)

        let photoLeftPixel =
            try pixel(
                in: correctedImage,
                x: 0,
                y: 0
            )
        let barLeftPixel =
            try pixel(
                in: correctedImage,
                x: 0,
                y: 850
            )

        #expect(
            max(
                photoLeftPixel.red,
                photoLeftPixel.green,
                photoLeftPixel.blue
            ) > 45
        )
        #expect(barLeftPixel.red > 230)
        #expect(barLeftPixel.green > 230)
        #expect(barLeftPixel.blue > 230)
    }

    @Test("Replacing rendered photo area preserves original right edge")
    func replacingRenderedPhotoAreaPreservesOriginalRightEdge() throws {

        let sourceImage =
            try makeSyntheticHorizontalGradientImage(
                width: 4_536,
                height: 806
            )
        let renderedImage =
            try makeSyntheticShiftedRenderedImage(
                sourceImage: sourceImage,
                barHeight: 75,
                blackWidth: 122
            )

        let shiftedRightPixel =
            try pixel(
                in: renderedImage,
                x: renderedImage.width - 1,
                y: 0
            )

        #expect(shiftedRightPixel.red < 252)

        let correctedImage =
            PhotoMemoRenderedImageArtifactGuard
            .replacingPhotoArea(
                in: renderedImage,
                with: sourceImage,
                photoHeight: 806
            )

        let correctedLeftPixel =
            try pixel(
                in: correctedImage,
                x: 0,
                y: 0
            )
        let correctedRightPixel =
            try pixel(
                in: correctedImage,
                x: correctedImage.width - 1,
                y: 0
            )
        let barLeftPixel =
            try pixel(
                in: correctedImage,
                x: 0,
                y: 850
            )

        #expect(correctedLeftPixel.green == 100)
        #expect(correctedRightPixel.red > 252)
        #expect(correctedRightPixel.green == 100)
        #expect(barLeftPixel.red > 230)
        #expect(barLeftPixel.green > 230)
        #expect(barLeftPixel.blue > 230)
    }

    private func makeSyntheticEdgeArtifactImage(
        width: Int,
        height: Int,
        blackWidth: Int
    ) throws -> CGImage {

        let bytesPerPixel = 4
        let bytesPerRow =
            width * bytesPerPixel
        var pixels =
            [UInt8](
                repeating: 0,
                count:
                    bytesPerRow
                    * height
            )

        for y in 0..<height {
            for x in 0..<width {
                let offset =
                    y * bytesPerRow
                    + x * bytesPerPixel

                if x < blackWidth {
                    pixels[offset] = 0
                    pixels[offset + 1] = 0
                    pixels[offset + 2] = 0
                } else {
                    pixels[offset] = 120
                    pixels[offset + 1] = 118
                    pixels[offset + 2] = 112
                }

                pixels[offset + 3] = 255
            }
        }

        let context =
            try #require(
                CGContext(
                    data: &pixels,
                    width: width,
                    height: height,
                    bitsPerComponent: 8,
                    bytesPerRow: bytesPerRow,
                    space:
                        CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo:
                        CGImageAlphaInfo
                        .premultipliedLast
                        .rawValue
                )
            )

        return try #require(
            context.makeImage()
        )
    }

    private func makeSyntheticHorizontalGradientImage(
        width: Int,
        height: Int
    ) throws -> CGImage {

        let bytesPerPixel = 4
        let bytesPerRow =
            width * bytesPerPixel
        var pixels =
            [UInt8](
                repeating: 0,
                count:
                    bytesPerRow
                    * height
            )

        for y in 0..<height {
            for x in 0..<width {
                let offset =
                    y * bytesPerRow
                    + x * bytesPerPixel
                let red =
                    UInt8(
                        min(
                            255,
                            Int(
                                round(
                                    Double(x)
                                    * 255
                                    / Double(width - 1)
                                )
                            )
                        )
                    )

                pixels[offset] = red
                pixels[offset + 1] = 100
                pixels[offset + 2] = 50
                pixels[offset + 3] = 255
            }
        }

        let context =
            try #require(
                CGContext(
                    data: &pixels,
                    width: width,
                    height: height,
                    bitsPerComponent: 8,
                    bytesPerRow: bytesPerRow,
                    space:
                        CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo:
                        CGImageAlphaInfo
                        .premultipliedLast
                        .rawValue
                )
            )

        return try #require(
            context.makeImage()
        )
    }

    private func makeSyntheticShiftedRenderedImage(
        sourceImage: CGImage,
        barHeight: Int,
        blackWidth: Int
    ) throws -> CGImage {

        let width = sourceImage.width
        let photoHeight = sourceImage.height
        let height =
            photoHeight + barHeight
        let bytesPerPixel = 4
        let bytesPerRow =
            width * bytesPerPixel
        var sourcePixels =
            [UInt8](
                repeating: 0,
                count:
                    bytesPerRow
                    * photoHeight
            )
        var pixels =
            [UInt8](
                repeating: 0,
                count:
                    bytesPerRow
                    * height
            )

        let sourceContext =
            try #require(
                CGContext(
                    data: &sourcePixels,
                    width: width,
                    height: photoHeight,
                    bitsPerComponent: 8,
                    bytesPerRow: bytesPerRow,
                    space:
                        CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo:
                        CGImageAlphaInfo
                        .premultipliedLast
                        .rawValue
                )
            )
        sourceContext.draw(
            sourceImage,
            in:
                CGRect(
                    x: 0,
                    y: 0,
                    width: width,
                    height: photoHeight
                )
        )

        for y in 0..<height {
            for x in 0..<width {
                let offset =
                    y * bytesPerRow
                    + x * bytesPerPixel

                if y >= photoHeight {
                    pixels[offset] = 244
                    pixels[offset + 1] = 244
                    pixels[offset + 2] = 242
                } else if x < blackWidth {
                    pixels[offset] = 0
                    pixels[offset + 1] = 0
                    pixels[offset + 2] = 0
                } else {
                    let sourceX =
                        min(
                            x - blackWidth,
                            width - 1
                        )
                    let sourceOffset =
                        y * bytesPerRow
                        + sourceX * bytesPerPixel

                    pixels[offset] =
                        sourcePixels[sourceOffset]
                    pixels[offset + 1] =
                        sourcePixels[sourceOffset + 1]
                    pixels[offset + 2] =
                        sourcePixels[sourceOffset + 2]
                }

                pixels[offset + 3] = 255
            }
        }

        let context =
            try #require(
                CGContext(
                    data: &pixels,
                    width: width,
                    height: height,
                    bitsPerComponent: 8,
                    bytesPerRow: bytesPerRow,
                    space:
                        CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo:
                        CGImageAlphaInfo
                        .premultipliedLast
                        .rawValue
                )
            )

        return try #require(
            context.makeImage()
        )
    }

    private func makeSyntheticRenderedImage(
        width: Int,
        photoHeight: Int,
        barHeight: Int,
        blackWidth: Int
    ) throws -> CGImage {

        let height =
            photoHeight + barHeight
        let bytesPerPixel = 4
        let bytesPerRow =
            width * bytesPerPixel
        var pixels =
            [UInt8](
                repeating: 0,
                count:
                    bytesPerRow
                    * height
            )

        for y in 0..<height {
            for x in 0..<width {
                let offset =
                    y * bytesPerRow
                    + x * bytesPerPixel

                if y >= photoHeight {
                    pixels[offset] = 244
                    pixels[offset + 1] = 244
                    pixels[offset + 2] = 242
                } else if x < blackWidth {
                    pixels[offset] = 0
                    pixels[offset + 1] = 0
                    pixels[offset + 2] = 0
                } else {
                    pixels[offset] = 120
                    pixels[offset + 1] = 118
                    pixels[offset + 2] = 112
                }

                pixels[offset + 3] = 255
            }
        }

        let context =
            try #require(
                CGContext(
                    data: &pixels,
                    width: width,
                    height: height,
                    bitsPerComponent: 8,
                    bytesPerRow: bytesPerRow,
                    space:
                        CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo:
                        CGImageAlphaInfo
                        .premultipliedLast
                        .rawValue
                )
            )

        return try #require(
            context.makeImage()
        )
    }

    private func cgImage(
        from image: PlatformImage
    ) -> CGImage? {

#if os(macOS)
        var proposedRect =
            CGRect(
                origin: .zero,
                size: image.size
            )

        return image.cgImage(
            forProposedRect: &proposedRect,
            context: nil,
            hints: nil
        )
#else
        return image.cgImage
#endif
    }

    private func pixel(
        in image: CGImage,
        x: Int,
        y: Int
    ) throws -> (
        red: UInt8,
        green: UInt8,
        blue: UInt8
    ) {

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

        let context =
            try #require(
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
            )

        context.draw(
            image,
            in:
                CGRect(
                    x: 0,
                    y: 0,
                    width: image.width,
                    height: image.height
                )
        )

        let offset =
            y * bytesPerRow
            + x * bytesPerPixel

        return (
            pixels[offset],
            pixels[offset + 1],
            pixels[offset + 2]
        )
    }
}
