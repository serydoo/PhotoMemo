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

/// The editor depends on this narrow capability rather than the concrete
/// asset writer. Keeping optimization behind a protocol makes request
/// identity, cancellation and stale-result behavior testable without
/// touching PhotoKit or the shared asset directory.
protocol SubjectAvatarAssetOptimizing {

    func optimize(
        data: Data,
        cropConfiguration: SubjectAvatarCropConfiguration
    ) async throws -> OptimizedSubjectAvatarAsset
}

final class SubjectAvatarAssetOptimizationService {

    nonisolated static let displayPixelSize = 512

    nonisolated static let badgePixelSize = 256

    nonisolated static let previewPixelSize = 128

    nonisolated static let safeInsetRatio: CGFloat = 0.04

    nonisolated static let generatedAssetPrefix =
        "memomark-subject-avatar-"

    nonisolated static let temporaryAssetPrefix =
        ".memomark-subject-avatar-"

    nonisolated init() {
        Self.cleanupTemporaryAssetDirectories()
    }

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
            MemoMarkSharedContainer
            .baseDirectoryURL
            .appendingPathComponent(
                "SubjectAssets",
                isDirectory: true
            )

        try MemoMarkSharedContainer
            .ensureDirectory(at: folderURL)

        return try await Task.detached(priority: .utility) {
            let fileManager = FileManager.default
            let transactionID = UUID().uuidString
            let temporaryDirectory = folderURL.appendingPathComponent(
                ".memomark-subject-avatar-\(transactionID).tmp",
                isDirectory: true
            )

            try fileManager.createDirectory(
                at: temporaryDirectory,
                withIntermediateDirectories: true
            )

            let displayFilename =
                "memomark-subject-avatar-display-\(transactionID)-\(displayPixelSize).png"
            let badgeFilename =
                "memomark-subject-avatar-badge-\(transactionID)-\(badgePixelSize).png"
            let previewFilename =
                "memomark-subject-avatar-preview-\(transactionID)-\(previewPixelSize).png"

            let temporaryDisplayURL = temporaryDirectory
                .appendingPathComponent(displayFilename)
            let temporaryBadgeURL = temporaryDirectory
                .appendingPathComponent(badgeFilename)
            let temporaryPreviewURL = temporaryDirectory
                .appendingPathComponent(previewFilename)

            let committedDirectory = folderURL.appendingPathComponent(
                "\(Self.generatedAssetPrefix)\(transactionID)",
                isDirectory: true
            )
            do {
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

                try displayData.write(
                    to: temporaryDisplayURL,
                    options: .atomic
                )
                try badgeData.write(
                    to: temporaryBadgeURL,
                    options: .atomic
                )
                try previewData.write(
                    to: temporaryPreviewURL,
                    options: .atomic
                )

                // The three files become visible as one directory move. A
                // process termination can leave the hidden staging directory,
                // but cannot expose a committed group with only one or two
                // resources.
                try fileManager.moveItem(
                    at: temporaryDirectory,
                    to: committedDirectory
                )
                return OptimizedSubjectAvatarAsset(
                    displayFileURL:
                        committedDirectory
                        .appendingPathComponent(displayFilename),
                    badgeFileURL:
                        committedDirectory
                        .appendingPathComponent(badgeFilename),
                    previewFileURL:
                        committedDirectory
                        .appendingPathComponent(previewFilename)
                )
            } catch {
                try? fileManager.removeItem(at: temporaryDirectory)
                try? fileManager.removeItem(at: committedDirectory)
                throw error
            }
        }.value
    }

    nonisolated static func cleanupTemporaryAssetDirectories(
        at folderURL: URL = MemoMarkSharedContainer.baseDirectoryURL
            .appendingPathComponent(
                "SubjectAssets",
                isDirectory: true
            )
    ) {
        guard let children = try? FileManager.default
            .contentsOfDirectory(
                at: folderURL,
                includingPropertiesForKeys: nil,
                options: []
            ) else {
            return
        }

        for childURL in children where
            childURL.lastPathComponent.hasPrefix(
                temporaryAssetPrefix
            ) {
            try? FileManager.default.removeItem(at: childURL)
        }
    }

    nonisolated static func discardUncommittedAssets(
        atPaths paths: [String]
    ) {
        for path in paths {
            discardUncommittedAsset(atPath: path)
        }
    }

    nonisolated static func discardUncommittedAsset(
        atPath path: String,
        in subjectFolderURL: URL = MemoMarkSharedContainer
            .baseDirectoryURL
            .appendingPathComponent(
                "SubjectAssets",
                isDirectory: true
            )
    ) {
        let subjectFolderURL = subjectFolderURL
            .standardizedFileURL
        let assetURL = URL(fileURLWithPath: path).standardizedFileURL
        guard isGeneratedAsset(assetURL, in: subjectFolderURL) else {
            return
        }

        let parentURL = assetURL.deletingLastPathComponent()
        if parentURL.path != subjectFolderURL.path,
           parentURL.lastPathComponent.hasPrefix(
               generatedAssetPrefix
           ) {
            try? FileManager.default.removeItem(at: parentURL)
        } else {
            try? FileManager.default.removeItem(at: assetURL)
        }
    }

    nonisolated static func isGeneratedAsset(
        _ assetURL: URL,
        in subjectFolderURL: URL
    ) -> Bool {
        let normalizedAssetURL = assetURL.standardizedFileURL
        let normalizedFolderURL = subjectFolderURL.standardizedFileURL
        guard normalizedAssetURL.pathExtension.lowercased() == "png",
              normalizedAssetURL.lastPathComponent.hasPrefix(
                  generatedAssetPrefix
              ) else {
            return false
        }

        let parentPath = normalizedAssetURL
            .deletingLastPathComponent()
            .path
        if parentPath == normalizedFolderURL.path {
            return true
        }

        guard parentPath.hasPrefix(
            normalizedFolderURL.path + "/"
        ) else {
            return false
        }

        let transactionDirectory = URL(
            fileURLWithPath: parentPath
        ).lastPathComponent
        return transactionDirectory.hasPrefix(
            generatedAssetPrefix
        )
    }
}

extension SubjectAvatarAssetOptimizationService:
    SubjectAvatarAssetOptimizing {}

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
