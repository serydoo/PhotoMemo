import Foundation
import CoreGraphics
import ImageIO
#if os(macOS)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

struct OptimizedLogoAsset: Hashable {

    let fileURL: URL

    let pixelSize: Int

    var badge: Badge {
        Badge(
            name: "自选标识",
            type: .customUpload,
            imagePath: fileURL.path,
            isSystemDefault: false
        )
    }
}

enum LogoAssetOptimizationError: LocalizedError {

    case invalidImage

    case pngEncodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "无法读取这张 Logo 图片。"
        case .pngEncodingFailed:
            return "无法优化这张 Logo 图片。"
        }
    }
}

enum LogoAssetPresentation {

    nonisolated static let defaultAlphaThreshold: UInt8 = 8

    nonisolated static let maximumAnalysisPixelSize = 4096

    nonisolated static func normalizedSourceImage(
        from data: Data,
        maximumPixelSize: Int = maximumAnalysisPixelSize
    ) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(
            data as CFData,
            nil
        ) else {
            return nil
        }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: max(maximumPixelSize, 1)
        ]
        return CGImageSourceCreateThumbnailAtIndex(
            source,
            0,
            options as CFDictionary
        )
    }

    nonisolated static func visibleArtworkBounds(
        for image: CGImage,
        alphaThreshold: UInt8 = defaultAlphaThreshold
    ) -> CGRect? {
        let width = image.width
        let height = image.height
        guard width > 0, height > 0,
              let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ),
              let data = context.data
        else {
            return nil
        }

        context.clear(CGRect(x: 0, y: 0, width: width, height: height))
        context.interpolationQuality = .high
        context.draw(
            image,
            in: CGRect(x: 0, y: 0, width: width, height: height)
        )

        let bytes = data.assumingMemoryBound(to: UInt8.self)
        var minX = width
        var minY = height
        var maxX = -1
        var maxY = -1

        for y in 0..<height {
            for x in 0..<width {
                let alpha = bytes[(y * width + x) * 4 + 3]
                guard alpha > alphaThreshold else { continue }
                minX = min(minX, x)
                minY = min(minY, y)
                maxX = max(maxX, x)
                maxY = max(maxY, y)
            }
        }

        guard maxX >= minX, maxY >= minY else { return nil }
        return CGRect(
            x: minX,
            y: minY,
            width: maxX - minX + 1,
            height: maxY - minY + 1
        )
    }

    nonisolated static func aspectFitRect(
        contentSize: CGSize,
        canvasSize: CGSize,
        safeInsetRatio: CGFloat
    ) -> CGRect {
        let contentWidth = max(contentSize.width, 1)
        let contentHeight = max(contentSize.height, 1)
        let safeInset = min(canvasSize.width, canvasSize.height)
            * max(safeInsetRatio, 0)
        let availableSize = CGSize(
            width: max(canvasSize.width - safeInset * 2, 1),
            height: max(canvasSize.height - safeInset * 2, 1)
        )
        // The final asset is clipped to a circle. Fit the complete artwork
        // inside that circular aperture, not only inside its bounding square.
        let circleDiameter = min(availableSize.width, availableSize.height)
        let contentDiagonal = max(
            hypot(contentWidth, contentHeight),
            1
        )
        let scale = circleDiameter / contentDiagonal
        let fittedSize = CGSize(
            width: contentWidth * scale,
            height: contentHeight * scale
        )

        return CGRect(
            x: (canvasSize.width - fittedSize.width) / 2,
            y: (canvasSize.height - fittedSize.height) / 2,
            width: fittedSize.width,
            height: fittedSize.height
        )
    }
}

final class LogoAssetOptimizationService {

    nonisolated static let minimumUploadPixelSize = 1024

    nonisolated static let recommendedUploadPixelSize = 2048

    nonisolated static let optimizedPixelSize = 2048

    nonisolated static let safeInsetRatio: CGFloat = 0.04

    func optimize(
        data: Data
    ) async throws -> OptimizedLogoAsset {

        let canvasPixelSize =
            Self.optimizedPixelSize
        let safeInsetRatio =
            Self.safeInsetRatio
        let folderURL =
            MemoMarkSharedContainer
            .baseDirectoryURL
            .appendingPathComponent(
                "LogoAssets",
                isDirectory: true
            )

        try MemoMarkSharedContainer
            .ensureDirectory(at: folderURL)

        return try await Task.detached(priority: .utility) {
            let pngData =
                try Self.normalizedCircularPNGData(
                    from: data,
                    canvasPixelSize:
                        canvasPixelSize,
                    safeInsetRatio:
                        safeInsetRatio
                )

            let fileURL =
                folderURL.appendingPathComponent(
                    "memomark-logo-\(UUID().uuidString).png"
                )

            try pngData.write(
                to: fileURL,
                options: .atomic
            )

            return OptimizedLogoAsset(
                fileURL: fileURL,
                pixelSize:
                    canvasPixelSize
            )
        }.value
    }

    nonisolated static func discardUncommittedAsset(
        atPath path: String
    ) {
        let logoFolderURL = MemoMarkSharedContainer
            .baseDirectoryURL
            .appendingPathComponent("LogoAssets", isDirectory: true)
            .standardizedFileURL
        let assetURL = URL(fileURLWithPath: path).standardizedFileURL
        guard isUncommittedAsset(
            assetURL,
            in: logoFolderURL
        ) else {
            return
        }
        try? FileManager.default.removeItem(at: assetURL)
    }

    nonisolated static func isUncommittedAsset(
        _ assetURL: URL,
        in logoFolderURL: URL
    ) -> Bool {
        let normalizedAssetURL = assetURL.standardizedFileURL
        let normalizedLogoFolderURL = logoFolderURL.standardizedFileURL
        return normalizedAssetURL.deletingLastPathComponent()
            .path == normalizedLogoFolderURL.path
            && normalizedAssetURL.pathExtension.lowercased() == "png"
            && normalizedAssetURL.lastPathComponent
                .hasPrefix("memomark-logo-")
    }

    static func estimatedDisplayedLogoPixels(
        outputWidth: CGFloat,
        orientation: CompactInformationBarOrientation
    ) -> CGFloat {

        let spec =
            RendererConstants
            .CompactInformationBar
            .spec(for: orientation)

        return outputWidth
            * spec.barHeightToWidth
            * spec.logoSizeToBarHeight
    }

    nonisolated static func normalizedCircularPNGData(
        from data: Data,
        canvasPixelSize: Int
    ) throws -> Data {
        try normalizedCircularPNGData(
            from: data,
            canvasPixelSize: canvasPixelSize,
            safeInsetRatio: safeInsetRatio
        )
    }
}

private extension LogoAssetOptimizationService {

#if canImport(UIKit)
    nonisolated static func normalizedCircularPNGData(
        from data: Data,
        canvasPixelSize: Int,
        safeInsetRatio: CGFloat
    ) throws -> Data {

        guard let sourceCGImage = LogoAssetPresentation.normalizedSourceImage(
            from: data
        ) else {
            throw LogoAssetOptimizationError.invalidImage
        }

        let canvasSize =
            CGSize(
                width: canvasPixelSize,
                height: canvasPixelSize
            )

        let format =
            UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false

        guard let artworkBounds = LogoAssetPresentation
            .visibleArtworkBounds(for: sourceCGImage),
              let artworkImage = sourceCGImage.cropping(
                  to: artworkBounds.integral
              )
        else {
            throw LogoAssetOptimizationError.invalidImage
        }

        let renderer =
            UIGraphicsImageRenderer(
                size: canvasSize,
                format: format
            )

        let renderedImage =
            renderer.image { context in
                UIColor.clear.setFill()
                context.cgContext.fill(
                    CGRect(origin: .zero, size: canvasSize)
                )

                let clipPath = UIBezierPath(
                    ovalIn: CGRect(origin: .zero, size: canvasSize)
                )
                clipPath.addClip()
                let drawRect = LogoAssetPresentation.aspectFitRect(
                    contentSize: CGSize(
                        width: artworkImage.width,
                        height: artworkImage.height
                    ),
                    canvasSize: canvasSize,
                    safeInsetRatio: safeInsetRatio
                )
                context.cgContext.interpolationQuality = .high
                context.cgContext.draw(artworkImage, in: drawRect)
            }

        guard let pngData = renderedImage.pngData() else {
            throw LogoAssetOptimizationError.pngEncodingFailed
        }

        return pngData
    }

#elseif os(macOS)
    nonisolated static func normalizedCircularPNGData(
        from data: Data,
        canvasPixelSize: Int,
        safeInsetRatio: CGFloat
    ) throws -> Data {

        guard let sourceCGImage = LogoAssetPresentation.normalizedSourceImage(
            from: data
        ) else {
            throw LogoAssetOptimizationError.invalidImage
        }

        let canvasSize =
            CGSize(
                width: canvasPixelSize,
                height: canvasPixelSize
            )

        guard let colorSpace = CGColorSpace(
            name: CGColorSpace.sRGB
        ),
        let graphicsContext = CGContext(
            data: nil,
            width: canvasPixelSize,
            height: canvasPixelSize,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw LogoAssetOptimizationError.pngEncodingFailed
        }

        graphicsContext.clear(
            CGRect(origin: .zero, size: canvasSize)
        )
        graphicsContext.saveGState()
        graphicsContext.addEllipse(
            in: CGRect(origin: .zero, size: canvasSize)
        )
        graphicsContext.clip()
        guard let artworkBounds = LogoAssetPresentation
            .visibleArtworkBounds(for: sourceCGImage),
              let artworkImage = sourceCGImage.cropping(
                  to: artworkBounds.integral
              )
        else {
            throw LogoAssetOptimizationError.invalidImage
        }
        let drawRect = LogoAssetPresentation.aspectFitRect(
            contentSize: CGSize(
                width: artworkImage.width,
                height: artworkImage.height
            ),
            canvasSize: canvasSize,
            safeInsetRatio: safeInsetRatio
        )
        graphicsContext.interpolationQuality = .high
        graphicsContext.draw(artworkImage, in: drawRect)
        graphicsContext.restoreGState()

        guard let renderedCGImage = graphicsContext.makeImage() else {
            throw LogoAssetOptimizationError.pngEncodingFailed
        }
        let representation = NSBitmapImageRep(
            cgImage: renderedCGImage
        )

        guard let pngData =
            representation.representation(
                using: .png,
                properties: [:]
            )
        else {
            throw LogoAssetOptimizationError.pngEncodingFailed
        }

        return pngData
    }
#endif

}
