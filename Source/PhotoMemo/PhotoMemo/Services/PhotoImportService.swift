import Foundation
import ImageIO
import UniformTypeIdentifiers
#if canImport(CoreImage)
import CoreImage
#endif

enum PhotoImportError: LocalizedError {

    case imageLoadFailed

    case rawDisplayRenderFailed

    case temporaryImportPreparationFailed

    var errorDescription: String? {

        switch self {

        case .imageLoadFailed:
            return "Unable to load this image."

        case .rawDisplayRenderFailed:
            return "Unable to prepare a display image for this RAW photo."

        case .temporaryImportPreparationFailed:
            return "Unable to prepare the selected photo."
        }
    }
}

final class PhotoImportService {

    private let metadataReader = PhotoMetadataReader()

    func importPhoto(
        from url: URL,
        sourceInfo: PhotoSourceInfo? = nil
    ) async throws -> SelectedPhoto {

        try importPhotoSync(
            from: url,
            sourceInfo: sourceInfo
        )
    }

    func importPhoto(
        from data: Data,
        suggestedFileName: String?,
        contentType: UTType?,
        assetLocalIdentifier: String? = nil
    ) async throws -> SelectedPhoto {

        let temporaryURL =
            try prepareTemporaryImportURL(
                suggestedFileName: suggestedFileName,
                contentType: contentType
            )

        do {

            try data.write(
                to: temporaryURL,
                options: .atomic
            )

            let sourceInfo =
                resolvedSourceInfo(
                    fileURL: temporaryURL,
                    contentType: contentType,
                    assetLocalIdentifier:
                        assetLocalIdentifier
                )

            return try importPhotoSync(
                from: temporaryURL,
                sourceInfo: sourceInfo
            )

        } catch {

            try? FileManager.default.removeItem(
                at: temporaryURL
            )

            throw error
        }
    }

    func importPhotoOffMainThread(
        from url: URL,
        sourceInfo: PhotoSourceInfo? = nil
    ) async throws -> SelectedPhoto {

        try await withCheckedThrowingContinuation {
            continuation in

            DispatchQueue.global(
                qos: .userInitiated
            ).async {

                do {

                    let photo =
                        try self.importPhotoSync(
                            from: url,
                            sourceInfo: sourceInfo
                        )

                    continuation.resume(
                        returning: photo
                    )

                } catch {

                    continuation.resume(
                        throwing: error
                    )
                }
            }
        }
    }

    private func importPhotoSync(
        from url: URL,
        sourceInfo: PhotoSourceInfo? = nil
    ) throws -> SelectedPhoto {

        let accessGranted = url.startAccessingSecurityScopedResource()
        defer {
            if accessGranted {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let sourceProperties =
            metadataReader.properties(from: url)
            ?? [:]

        let metadata =
            metadataReader.read(
                from: sourceProperties
            )

        let image =
            try loadDisplayImage(
                from: url,
                sourceInfo: sourceInfo
            )
            .removingPhotoMemoLeftEdgeArtifact()

        return SelectedPhoto(
            sourceURL: url,
            sourceProperties: sourceProperties,
            image: image,
            metadata: metadata,
            sourceInfo:
                sourceInfo
                ?? resolvedSourceInfo(
                    fileURL: url,
                    contentType: nil,
                    assetLocalIdentifier: nil
                )
        )
    }

    func supportedTypes() -> [UTType] {
        PhotoProcessingInputPolicy.supportedImageTypes
    }

    func isSupported(_ url: URL) -> Bool {

        PhotoProcessingInputPolicy.standard
            .isSupportedContentType(
                UTType(
                    filenameExtension:
                        url.pathExtension
                        .lowercased()
                )
            )
    }

    func isSupported(
        _ contentType: UTType?
    ) -> Bool {

        PhotoProcessingInputPolicy.standard
            .isSupportedContentType(contentType)
    }

    private func loadDisplayImage(
        from url: URL,
        sourceInfo: PhotoSourceInfo?
    ) throws -> PlatformImage {

        let contentType =
            resolvedImportContentType(
                fileURL: url,
                sourceInfo: sourceInfo
            )

        let isRAW =
            PhotoProcessingInputPolicy
            .isRawContentType(contentType)
            || PhotoProcessingInputPolicy
            .isRawFileURL(url)

        if isRAW {
            return try loadRAWDisplayImage(
                from: url
            )
        }

        if let image =
            imageIODisplayImage(
                from: url
            ) {
            return image
        }

        guard let data = try? Data(contentsOf: url),
              let image =
            PlatformImage.loadPhotoMemoImage(
                from: data
            ) else {

            throw PhotoImportError.imageLoadFailed
        }

        return image
    }

    private func loadRAWDisplayImage(
        from url: URL
    ) throws -> PlatformImage {

        if let image =
            PlatformImage.loadPhotoMemoImage(
                contentsOfFile: url.path
            ) {
            return image
        }

        if let image =
            imageIODisplayImage(
                from: url
            ) {
            return image
        }

#if canImport(CoreImage)
        if let image =
            coreImageDisplayImage(
                from: url
            ) {
            return image
        }
#endif

        throw PhotoImportError
            .rawDisplayRenderFailed
    }

    private func imageIODisplayImage(
        from url: URL
    ) -> PlatformImage? {

        guard let source =
            CGImageSourceCreateWithURL(
                url as CFURL,
                [
                    kCGImageSourceShouldCache:
                        false
                ] as CFDictionary
            ) else {
            return nil
        }

        let maxPixelSize =
            PhotoProcessingInputPolicy
            .standard
            .maximumPixelDimension

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageIfAbsent:
                true,
            kCGImageSourceCreateThumbnailWithTransform:
                true,
            kCGImageSourceShouldCacheImmediately:
                true,
            kCGImageSourceThumbnailMaxPixelSize:
                maxPixelSize
        ]

        guard let cgImage =
            CGImageSourceCreateThumbnailAtIndex(
                source,
                0,
                options as CFDictionary
            ) else {
            return nil
        }

        return PlatformImage.photoMemoImage(
            cgImage: cgImage
        )
    }

#if canImport(CoreImage)
    private func coreImageDisplayImage(
        from url: URL
    ) -> PlatformImage? {

        guard let ciImage =
            CIImage(
                contentsOf: url,
                options: [
                    .applyOrientationProperty:
                        true
                ]
            ) else {
            return nil
        }

        let maxPixelSize =
            CGFloat(
                PhotoProcessingInputPolicy
                    .standard
                    .maximumPixelDimension
            )
        let extent =
            ciImage.extent.integral

        guard extent.width > 0,
              extent.height > 0 else {
            return nil
        }

        let scale =
            min(
                maxPixelSize
                    / max(
                        extent.width,
                        extent.height
                    ),
                1
            )

        let displayImage =
            scale < 1
            ? ciImage.transformed(
                by: CGAffineTransform(
                    scaleX: scale,
                    y: scale
                )
            )
            : ciImage

        let context =
            CIContext(
                options: [
                    .cacheIntermediates:
                        false
                ]
            )

        guard let cgImage =
            context.createCGImage(
                displayImage,
                from:
                    displayImage.extent
                    .integral
            ) else {
            return nil
        }

        return PlatformImage.photoMemoImage(
            cgImage: cgImage
        )
    }
#endif

    private func resolvedImportContentType(
        fileURL: URL,
        sourceInfo: PhotoSourceInfo?
    ) -> UTType? {

        if let contentTypeIdentifier =
            sourceInfo?
            .contentTypeIdentifier,
           let contentType =
            UTType(contentTypeIdentifier) {
            return contentType
        }

        return UTType(
            filenameExtension:
                fileURL.pathExtension
                .lowercased()
        )
    }

    private func prepareTemporaryImportURL(
        suggestedFileName: String?,
        contentType: UTType?
    ) throws -> URL {

        let rootFolderURL =
            FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "PhotoMemoPickerImports",
                isDirectory: true
            )

        do {

            try FileManager.default.createDirectory(
                at: rootFolderURL,
                withIntermediateDirectories: true
            )

        } catch {

            throw PhotoImportError
                .temporaryImportPreparationFailed
        }

        let folderURL =
            rootFolderURL.appendingPathComponent(
                UUID().uuidString,
                isDirectory: true
            )

        do {

            try FileManager.default.createDirectory(
                at: folderURL,
                withIntermediateDirectories: true
            )

        } catch {

            throw PhotoImportError
                .temporaryImportPreparationFailed
        }

        let baseName =
            normalizedImportBaseName(
                suggestedFileName
            )

        let fileExtension =
            preferredImportExtension(
                suggestedFileName: suggestedFileName,
                contentType: contentType
            )

        return uniqueImportURL(
            in: folderURL,
            baseName: baseName,
            fileExtension: fileExtension
        )
    }

    private func normalizedImportBaseName(
        _ suggestedFileName: String?
    ) -> String {

        let fallback = "PhotoMemo Import"

        guard let sanitizedFileName =
            sanitizedSuggestedFileName(
                suggestedFileName
            )
        else {
            return fallback
        }

        let baseName =
            URL(fileURLWithPath: sanitizedFileName)
            .deletingPathExtension()
            .lastPathComponent
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return baseName.isEmpty
            ? fallback
            : baseName
    }

    func sanitizedSuggestedFileName(
        _ suggestedFileName: String?
    ) -> String? {
        PhotoFileNameResolver
            .sanitizedOriginalFileName(
                suggestedFileName
            )
    }

    private func preferredImportExtension(
        suggestedFileName: String?,
        contentType: UTType?
    ) -> String {

        if let suggestedFileName {

            let extensionCandidate =
                URL(fileURLWithPath: suggestedFileName)
                .pathExtension

            if !extensionCandidate.isEmpty {
                return extensionCandidate
            }
        }

        if let contentType,
           let preferredFilenameExtension =
            contentType.preferredFilenameExtension {

            return normalizedImportExtension(
                preferredFilenameExtension
            )
        }

        return "jpg"
    }

    private func normalizedImportExtension(
        _ fileExtension: String
    ) -> String {

        switch fileExtension.lowercased() {
        case "jpeg":
            return "jpg"

        default:
            return fileExtension.lowercased()
        }
    }

    private func uniqueImportURL(
        in folderURL: URL,
        baseName: String,
        fileExtension: String
    ) -> URL {

        let safeExtension =
            fileExtension.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        let extensionSuffix =
            safeExtension.isEmpty
            ? ""
            : ".\(safeExtension)"

        var candidateURL =
            folderURL.appendingPathComponent(
                baseName + extensionSuffix
            )

        var index = 1

        while FileManager.default.fileExists(
            atPath: candidateURL.path
        ) {

            candidateURL =
                folderURL.appendingPathComponent(
                    "\(baseName) (\(index))"
                    + extensionSuffix
                )
            index += 1
        }

        return candidateURL
    }

    private func resolvedSourceInfo(
        fileURL: URL,
        contentType: UTType?,
        assetLocalIdentifier: String?
    ) -> PhotoSourceInfo {

        PhotoSourceInfo(
            originalFileName:
                fileURL.lastPathComponent,
            assetLocalIdentifier:
                assetLocalIdentifier,
            contentTypeIdentifier:
                contentType?.identifier
                ?? UTType(
                    filenameExtension:
                        fileURL.pathExtension
                        .lowercased()
                )?.identifier
        )
    }
}
