import Foundation
#if canImport(Photos)
import Photos
#endif

struct OutputFileNamingResolver {

    private let outputFilenameSequenceStore:
        LivePhotoOutputFilenameSequenceStore

    init(
        outputFilenameSequenceStore:
            LivePhotoOutputFilenameSequenceStore? = nil
    ) {
        self.outputFilenameSequenceStore =
            outputFilenameSequenceStore
            ?? .shared
    }

    func defaultFileName(
        for photo: SelectedPhoto
    ) -> String {

        let baseName =
            PhotoFileNameResolver
            .outputCopyBaseName(
                from: resolvedOutputBaseName(
                    for: photo
                ),
                index: 1
            )

        return baseName + ".jpg"
    }

    func uniqueTemporaryURL(
        in folderURL: URL,
        for photo: SelectedPhoto
    ) async throws -> URL {

        let originalBaseName =
            resolvedOutputBaseName(
                for: photo
            )

        var baseName =
            try await outputFilenameSequenceStore
            .nextOutputBaseName(
                from: originalBaseName
            )

        while FileManager.default.fileExists(
            atPath:
                folderURL
                .appendingPathComponent(baseName)
                .appendingPathExtension("jpg")
                .path
        ) {
            baseName =
                try await outputFilenameSequenceStore
                .nextOutputBaseName(
                    from: originalBaseName
                )
        }

        return folderURL
            .appendingPathComponent(
                baseName
            )
            .appendingPathExtension("jpg")
    }

    func uniqueIntermediateTemporaryURL(
        in folderURL: URL,
        for photo: SelectedPhoto
    ) -> URL {

        uniqueOutputURL(
            for:
                folderURL
                .appendingPathComponent(
                    resolvedOutputBaseName(
                        for: photo
                    )
                )
                .appendingPathExtension("jpg")
        )
    }

    private func resolvedOutputBaseName(
        for photo: SelectedPhoto
    ) -> String {

        PhotoFileNameResolver
            .outputBaseName(
                preferredOriginalFileName:
                    photo.sourceInfo
                    .originalFileName,
                assetOriginalFileName:
                    originalPhotoLibraryFileName(
                        for:
                            photo
                            .sourceInfo
                            .assetLocalIdentifier
                    ),
                captureDate:
                    photo.metadata.captureDate,
                timeZone:
                    photo.metadata
                    .captureTimeZone,
                fallbackBaseName:
                    sourceURLFallbackBaseName(
                        for: photo
                    )
            )
    }

    private func sourceURLFallbackBaseName(
        for photo: SelectedPhoto
    ) -> String {

        let fileName =
            PhotoFileNameResolver
            .sanitizedOriginalFileName(
                photo.sourceURL
                .lastPathComponent
            )

        let baseName =
            fileName.map {
                URL(fileURLWithPath: $0)
                    .deletingPathExtension()
                    .lastPathComponent
            }?
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return baseName?.isEmpty == false
            ? baseName ?? "MemoMark"
            : "MemoMark"
    }

    private func originalPhotoLibraryFileName(
        for assetLocalIdentifier: String?
    ) -> String? {

#if canImport(Photos)
        guard
            let assetLocalIdentifier,
            !assetLocalIdentifier
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .isEmpty
        else {
            return nil
        }

        let assets =
            PHAsset.fetchAssets(
                withLocalIdentifiers: [
                    assetLocalIdentifier
                ],
                options: nil
            )

        guard let asset = assets.firstObject else {
            return nil
        }

        let resources =
            PHAssetResource.assetResources(
                for: asset
            )

        let preferredFileName =
            resources.first {
                switch $0.type {
                case .photo,
                     .fullSizePhoto,
                     .alternatePhoto:
                    return true

                default:
                    return false
                }
            }?.originalFilename
            ?? resources.first?.originalFilename

        return PhotoFileNameResolver
            .sanitizedOriginalFileName(
                preferredFileName
            )
#else
        return nil
#endif
    }

    func uniqueOutputURL(
        for url: URL
    ) -> URL {

        guard FileManager.default.fileExists(
            atPath: url.path
        ) else {
            return url
        }

        let folderURL =
            url.deletingLastPathComponent()
        let baseName =
            url.deletingPathExtension()
            .lastPathComponent
        let pathExtension =
            url.pathExtension

        let candidateBaseName =
            PhotoFileNameResolver
            .nextOutputCopyBaseName(
                from: baseName
            ) { candidate in
                FileManager.default.fileExists(
                    atPath:
                        folderURL
                        .appendingPathComponent(candidate)
                        .appendingPathExtension(pathExtension)
                        .path
                )
            }

        return folderURL
            .appendingPathComponent(
                candidateBaseName
            )
            .appendingPathExtension(
                pathExtension
            )
    }
}
