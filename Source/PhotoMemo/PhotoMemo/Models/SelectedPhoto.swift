import Foundation
import CoreGraphics
import SwiftUI
import UniformTypeIdentifiers
#if os(macOS)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

#if os(macOS)
typealias PlatformImage = NSImage
#elseif canImport(UIKit)
typealias PlatformImage = UIImage
#endif

extension PlatformImage {

    static func loadPhotoMemoImage(
        from data: Data
    ) -> PlatformImage? {

        PlatformImage(data: data)
    }

    static func loadPhotoMemoImage(
        contentsOfFile path: String
    ) -> PlatformImage? {

#if os(macOS)
        return PlatformImage(contentsOfFile: path)
#else
        return PlatformImage(contentsOfFile: path)
#endif
    }

    static func photoMemoImage(
        cgImage: CGImage
    ) -> PlatformImage {

#if os(macOS)
        return PlatformImage(
            cgImage: cgImage,
            size: CGSize(
                width: cgImage.width,
                height: cgImage.height
            )
        )
#else
        return PlatformImage(
            cgImage: cgImage,
            scale: 1,
            orientation: .up
        )
#endif
    }

    func removingPhotoMemoLeftEdgeArtifact()
        -> PlatformImage {

        guard let cgImage =
            photoMemoCGImage else {
            return self
        }

        let trimWidth =
            Self.photoMemoLeftEdgeArtifactWidth(
                in: cgImage
            )

        guard trimWidth > 0,
              trimWidth < cgImage.width else {
            return self
        }

        let cropRect =
            CGRect(
                x: trimWidth,
                y: 0,
                width: cgImage.width - trimWidth,
                height: cgImage.height
            )

        guard
            let croppedImage =
                cgImage.cropping(to: cropRect),
            let correctedImage =
                Self.photoMemoImage(
                    stretching: croppedImage,
                    toWidth: cgImage.width,
                    height: cgImage.height
                )
        else {
            return self
        }

        return Self.photoMemoImage(
            cgImage: correctedImage
        )
    }

    var photoMemoSize: CGSize {

#if os(macOS)
        return size
#else
        return size
#endif
    }

    var swiftUIImage: Image {

#if os(macOS)
        return Image(nsImage: self)
#else
        return Image(uiImage: self)
#endif
    }

    var photoMemoExportCGImage: CGImage? {

        photoMemoCGImage
    }
}

private extension PlatformImage {

    var photoMemoCGImage: CGImage? {

#if os(macOS)
        var proposedRect =
            CGRect(
                origin: .zero,
                size: size
            )

        return cgImage(
            forProposedRect: &proposedRect,
            context: nil,
            hints: nil
        )
#else
        return cgImage
#endif
    }

    static func photoMemoLeftEdgeArtifactWidth(
        in image: CGImage
    ) -> Int {

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

        guard sampleWidth > 2,
              image.height > 0 else {
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
                    * image.height
            )

        guard let context =
            CGContext(
                data: &pixels,
                width: sampleWidth,
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
            return 0
        }

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

        var trimWidth = 0

        for x in 0..<maxTrimWidth {
            guard photoMemoColumnLooksLikeBlackArtifact(
                pixels: pixels,
                x: x,
                height: image.height,
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
            photoMemoAverageBrightness(
                pixels: pixels,
                x:
                    min(
                        trimWidth + 4,
                        sampleWidth - 1
                    ),
                height: image.height,
                bytesPerRow: bytesPerRow
            )

        return transitionBrightness > 45
            ? trimWidth
            : 0
    }

    static func photoMemoColumnLooksLikeBlackArtifact(
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

    static func photoMemoAverageBrightness(
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

    static func photoMemoImage(
        stretching image: CGImage,
        toWidth width: Int,
        height: Int
    ) -> CGImage? {

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

        guard let context =
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
        else {
            return nil
        }

        context.interpolationQuality = .high
        context.draw(
            image,
            in:
                CGRect(
                    x: 0,
                    y: 0,
                    width: width,
                    height: height
                )
        )

        return context.makeImage()
    }
}

struct SelectedPhoto: Identifiable {

    let id: UUID

    var sourceURL: URL

    var sourceInfo: PhotoSourceInfo

    var sourceProperties: [CFString: Any]

    var image: PlatformImage

    var metadata: PhotoMetadata

    var mediaAsset: MediaAsset

    var previewRepresentation: MediaRepresentation?

    var importReport: MediaImportReport {
        MediaImportReport(
            asset: mediaAsset,
            representation:
                previewRepresentation
        )
    }

    init(
        id: UUID = UUID(),
        sourceURL: URL,
        sourceProperties: [CFString: Any] = [:],
        image: PlatformImage,
        metadata: PhotoMetadata,
        sourceInfo: PhotoSourceInfo? = nil,
        mediaAsset: MediaAsset? = nil,
        previewRepresentation: MediaRepresentation? = nil
    ) {
        self.id = id
        self.sourceURL = sourceURL
        let resolvedSourceInfo =
            sourceInfo
            ?? PhotoSourceInfo(
                originalFileName:
                    sourceURL.lastPathComponent,
                contentTypeIdentifier:
                    UTType(
                        filenameExtension:
                            sourceURL.pathExtension
                            .lowercased()
                    )?.identifier
            )
        self.sourceInfo = resolvedSourceInfo
        self.sourceProperties = sourceProperties
        self.image = image
        self.metadata = metadata
        self.mediaAsset =
            mediaAsset
            ?? MediaAsset(
                fileURL: sourceURL,
                sourceInfo: resolvedSourceInfo,
                sourceProperties: sourceProperties,
                contentType:
                    resolvedSourceInfo
                    .contentTypeIdentifier
                    .flatMap(UTType.init)
                    ?? UTType(
                        filenameExtension:
                            sourceURL.pathExtension
                            .lowercased()
                    )
            )
        self.previewRepresentation =
            previewRepresentation
    }
}

struct PhotoSourceInfo:
    Hashable,
    Codable {

    var originalFileName: String

    var assetLocalIdentifier: String?

    var contentTypeIdentifier: String?

    init(
        originalFileName: String,
        assetLocalIdentifier: String? = nil,
        contentTypeIdentifier: String? = nil
    ) {
        self.originalFileName =
            PhotoFileNameResolver
            .sanitizedOriginalFileName(
                originalFileName
            )
            ?? "PhotoMemo Import.jpg"
        self.assetLocalIdentifier =
            assetLocalIdentifier?
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
        self.contentTypeIdentifier =
            contentTypeIdentifier?
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
    }

    var originalBaseName: String {

        let baseName =
            URL(
                fileURLWithPath:
                    originalFileName
            )
            .deletingPathExtension()
            .lastPathComponent
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return baseName.isEmpty
            ? "PhotoMemo Import"
            : baseName
    }
}
