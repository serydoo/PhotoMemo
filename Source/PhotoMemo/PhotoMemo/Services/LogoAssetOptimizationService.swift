import Foundation
import CoreGraphics
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

final class LogoAssetOptimizationService {

    nonisolated static let minimumUploadPixelSize = 1024

    nonisolated static let recommendedUploadPixelSize = 2048

    nonisolated static let optimizedPixelSize = 2048

    nonisolated static let safeInsetRatio: CGFloat = 0.12

    func optimize(
        data: Data
    ) async throws -> OptimizedLogoAsset {

        let canvasPixelSize =
            Self.optimizedPixelSize
        let safeInsetRatio =
            Self.safeInsetRatio
        let folderURL =
            PhotoMemoSharedContainer
            .baseDirectoryURL
            .appendingPathComponent(
                "LogoAssets",
                isDirectory: true
            )

        PhotoMemoSharedContainer
            .ensureDirectory(at: folderURL)

        return try await Task.detached(priority: .utility) {
            let pngData =
                try Self.normalizedPNGData(
                    from: data,
                    canvasPixelSize:
                        canvasPixelSize,
                    safeInsetRatio:
                        safeInsetRatio
                )

            let fileURL =
                folderURL.appendingPathComponent(
                    "photomemo-logo-\(UUID().uuidString).png"
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
}

private extension LogoAssetOptimizationService {

#if canImport(UIKit)
    nonisolated static func normalizedPNGData(
        from data: Data,
        canvasPixelSize: Int,
        safeInsetRatio: CGFloat
    ) throws -> Data {

        guard let sourceImage = UIImage(data: data) else {
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

                sourceImage.draw(
                    in: aspectFitRect(
                        sourceSize:
                            sourceImage.size,
                        canvasSize: canvasSize,
                        safeInsetRatio:
                            safeInsetRatio
                    )
                )
            }

        guard let pngData = renderedImage.pngData() else {
            throw LogoAssetOptimizationError.pngEncodingFailed
        }

        return pngData
    }
#elseif os(macOS)
    nonisolated static func normalizedPNGData(
        from data: Data,
        canvasPixelSize: Int,
        safeInsetRatio: CGFloat
    ) throws -> Data {

        guard let sourceImage = NSImage(data: data) else {
            throw LogoAssetOptimizationError.invalidImage
        }

        let canvasSize =
            CGSize(
                width: canvasPixelSize,
                height: canvasPixelSize
            )

        guard let representation =
            NSBitmapImageRep(
                bitmapDataPlanes: nil,
                pixelsWide: canvasPixelSize,
                pixelsHigh: canvasPixelSize,
                bitsPerSample: 8,
                samplesPerPixel: 4,
                hasAlpha: true,
                isPlanar: false,
                colorSpaceName: .deviceRGB,
                bitmapFormat: .alphaNonpremultiplied,
                bytesPerRow: 0,
                bitsPerPixel: 0
            )
        else {
            throw LogoAssetOptimizationError.pngEncodingFailed
        }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current =
            NSGraphicsContext(bitmapImageRep: representation)
        NSColor.clear.setFill()
        CGRect(origin: .zero, size: canvasSize).fill()
        sourceImage.draw(
            in: aspectFitRect(
                sourceSize: sourceImage.size,
                canvasSize: canvasSize,
                safeInsetRatio: safeInsetRatio
            ),
            from: .zero,
            operation: .sourceOver,
            fraction: 1
        )
        NSGraphicsContext.restoreGraphicsState()

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

    nonisolated static func aspectFitRect(
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
            min(
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
}
