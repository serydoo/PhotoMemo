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

    nonisolated static let safeInsetRatio: CGFloat = 0.04

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

        try PhotoMemoSharedContainer
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
        let logoFolderURL = PhotoMemoSharedContainer
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

                let clipPath = UIBezierPath(
                    ovalIn: CGRect(origin: .zero, size: canvasSize)
                )
                clipPath.addClip()
                sourceImage.draw(
                    in: SubjectAvatarCropSupport.resolvedDrawRect(
                        sourceSize: sourceImage.size,
                        canvasSize: canvasSize,
                        safeInsetRatio: safeInsetRatio,
                        configuration: .init()
                    )
                )
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

        guard let sourceImage = NSImage(data: data) else {
            throw LogoAssetOptimizationError.invalidImage
        }

        var proposedRect = CGRect(
            origin: .zero,
            size: sourceImage.size
        )
        guard let sourceCGImage = sourceImage.cgImage(
            forProposedRect: &proposedRect,
            context: nil,
            hints: nil
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
        graphicsContext.draw(
            sourceCGImage,
            in: SubjectAvatarCropSupport.resolvedDrawRect(
                sourceSize: CGSize(
                    width: sourceCGImage.width,
                    height: sourceCGImage.height
                ),
                canvasSize: canvasSize,
                safeInsetRatio: safeInsetRatio,
                configuration: .init()
            )
        )
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
