import Foundation
import CoreGraphics
#if os(macOS)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

struct OptimizedSubjectAvatarAsset: Hashable {

    static let subjectAvatarBadgeName = "对象头像"

    let displayFileURL: URL
    let badgeFileURL: URL
    let previewFileURL: URL

    var displayImagePath: String {
        displayFileURL.path
    }

    var badgeImagePath: String {
        badgeFileURL.path
    }

    var previewImagePath: String {
        previewFileURL.path
    }

    var badge: Badge {
        Badge(
            name: Self.subjectAvatarBadgeName,
            type: .customUpload,
            imagePath: badgeFileURL.path,
            isSystemDefault: false
        )
    }
}

enum SubjectAvatarAssetOptimizationError: LocalizedError {

    case invalidImage

    case pngEncodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "无法读取这张头像图片。"
        case .pngEncodingFailed:
            return "无法优化这张头像图片。"
        }
    }
}

final class SubjectAvatarAssetOptimizationService {

    nonisolated static let displayPixelSize = 512

    nonisolated static let badgePixelSize = 256

    nonisolated static let previewPixelSize = 128

    nonisolated static let safeInsetRatio: CGFloat = 0.04

    func optimize(
        data: Data,
        cropConfiguration:
            SubjectAvatarCropConfiguration = .init()
    ) async throws -> OptimizedSubjectAvatarAsset {

        let displayPixelSize = Self.displayPixelSize
        let badgePixelSize = Self.badgePixelSize
        let previewPixelSize = Self.previewPixelSize
        let safeInsetRatio = Self.safeInsetRatio
        let folderURL =
            PhotoMemoSharedContainer
            .baseDirectoryURL
            .appendingPathComponent(
                "SubjectAssets",
                isDirectory: true
            )

        try PhotoMemoSharedContainer
            .ensureDirectory(at: folderURL)

        return try await Task.detached(priority: .utility) {
            let displayData =
                try Self.normalizedPNGData(
                    from: data,
                    canvasPixelSize: displayPixelSize,
                    safeInsetRatio: safeInsetRatio,
                    cropConfiguration: cropConfiguration
                )
            let badgeData =
                try Self.normalizedPNGData(
                    from: data,
                    canvasPixelSize: badgePixelSize,
                    safeInsetRatio: safeInsetRatio,
                    cropConfiguration: cropConfiguration
                )
            let previewData =
                try Self.normalizedPNGData(
                    from: data,
                    canvasPixelSize: previewPixelSize,
                    safeInsetRatio: safeInsetRatio,
                    cropConfiguration: cropConfiguration
                )

            let displayURL =
                folderURL.appendingPathComponent(
                    "memomark-subject-avatar-display-\(UUID().uuidString)-\(displayPixelSize).png"
                )
            let badgeURL =
                folderURL.appendingPathComponent(
                    "memomark-subject-avatar-badge-\(UUID().uuidString)-\(badgePixelSize).png"
                )
            let previewURL =
                folderURL.appendingPathComponent(
                    "memomark-subject-avatar-preview-\(UUID().uuidString)-\(previewPixelSize).png"
                )

            try displayData.write(
                to: displayURL,
                options: .atomic
            )
            try badgeData.write(
                to: badgeURL,
                options: .atomic
            )
            try previewData.write(
                to: previewURL,
                options: .atomic
            )

            return OptimizedSubjectAvatarAsset(
                displayFileURL: displayURL,
                badgeFileURL: badgeURL,
                previewFileURL: previewURL
            )
        }.value
    }
}

private extension SubjectAvatarAssetOptimizationService {

#if canImport(UIKit)
    nonisolated static func normalizedPNGData(
        from data: Data,
        canvasPixelSize: Int,
        safeInsetRatio: CGFloat,
        cropConfiguration:
            SubjectAvatarCropConfiguration
    ) throws -> Data {

        guard let sourceImage = UIImage(data: data) else {
            throw SubjectAvatarAssetOptimizationError.invalidImage
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

                let drawingRect =
                    SubjectAvatarCropSupport
                    .resolvedDrawRect(
                        sourceSize: sourceImage.size,
                        canvasSize: canvasSize,
                        safeInsetRatio: safeInsetRatio,
                        configuration:
                            cropConfiguration
                    )

                let clipPath =
                    UIBezierPath(
                        ovalIn: CGRect(
                            origin: .zero,
                            size: canvasSize
                        )
                    )
                clipPath.addClip()
                sourceImage.draw(in: drawingRect)
            }

        guard let pngData = renderedImage.pngData() else {
            throw SubjectAvatarAssetOptimizationError.pngEncodingFailed
        }

        return pngData
    }
#elseif os(macOS)
    nonisolated static func normalizedPNGData(
        from data: Data,
        canvasPixelSize: Int,
        safeInsetRatio: CGFloat,
        cropConfiguration:
            SubjectAvatarCropConfiguration
    ) throws -> Data {

        guard let sourceImage = NSImage(data: data) else {
            throw SubjectAvatarAssetOptimizationError.invalidImage
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
            throw SubjectAvatarAssetOptimizationError.pngEncodingFailed
        }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current =
            NSGraphicsContext(bitmapImageRep: representation)
        NSColor.clear.setFill()
        CGRect(origin: .zero, size: canvasSize).fill()

        let clipPath =
            NSBezierPath(
                ovalIn: CGRect(
                    origin: .zero,
                    size: canvasSize
                )
            )
        clipPath.addClip()

        sourceImage.draw(
            in: SubjectAvatarCropSupport
                .resolvedDrawRect(
                sourceSize: sourceImage.size,
                canvasSize: canvasSize,
                safeInsetRatio: safeInsetRatio,
                configuration:
                    cropConfiguration
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
            throw SubjectAvatarAssetOptimizationError.pngEncodingFailed
        }

        return pngData
    }
#endif

}
