import Foundation
import UniformTypeIdentifiers

final class PhotoImportService {

    private let metadataReader = PhotoMetadataReader()
    private let mediaDecodeService = MediaDecodeService()

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
            let sourceProperties =
                metadataReader.properties(
                    from: data
                )

            return try importPhotoSync(
                from: temporaryURL,
                sourceProperties: sourceProperties,
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
        sourceProperties: [CFString: Any]? = nil,
        sourceInfo: PhotoSourceInfo? = nil
    ) throws -> SelectedPhoto {

        let accessGranted = url.startAccessingSecurityScopedResource()
        defer {
            if accessGranted {
                url.stopAccessingSecurityScopedResource()
            }
        }

        guard PhotoMemoImageFileReadiness
            .waitForReadableImageFile(
                at: url,
                timeout: 5,
                pollInterval: 0.12
            ) else {
            throw PhotoImportError.imageLoadFailed
        }

        let resolvedSourceProperties =
            sourceProperties
            ?? metadataReader.properties(
                from: url
            )
            ?? [:]

        let resolvedSourceInfo =
            sourceInfo
            ?? resolvedSourceInfo(
                fileURL: url,
                contentType: nil,
                assetLocalIdentifier: nil
            )
        let metadata =
            metadataReader.read(
                from: resolvedSourceProperties
            )
        let mediaAsset =
            MediaAsset(
                fileURL: url,
                sourceInfo: resolvedSourceInfo,
                sourceProperties:
                    resolvedSourceProperties,
                contentType:
                    resolvedImportContentType(
                        fileURL: url,
                        sourceInfo:
                            resolvedSourceInfo
                    )
            )

        let image =
            try mediaDecodeService
            .previewImage(
                for: mediaAsset
            )
            .removingPhotoMemoLeftEdgeArtifact()
        let previewRepresentation =
            MediaRepresentation.preview(
                asset: mediaAsset,
                pixelSize:
                    MediaPixelSize(
                        size:
                            image.photoMemoSize
                    ),
                maxPixelDimension:
                    PhotoProcessingInputPolicy
                    .standard
                    .maximumPixelDimension
            )

        return SelectedPhoto(
            sourceURL: url,
            sourceProperties: resolvedSourceProperties,
            image: image,
            metadata: metadata,
            sourceInfo: resolvedSourceInfo,
            mediaAsset: mediaAsset,
            previewRepresentation:
                previewRepresentation
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
