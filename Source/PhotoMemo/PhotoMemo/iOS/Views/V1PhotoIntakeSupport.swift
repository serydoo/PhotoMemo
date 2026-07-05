#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import UniformTypeIdentifiers

enum V1PhotoIntakeURLResolver {

    nonisolated static func resolve(
        _ urls: [URL]
    ) -> [URL] {
        return urls.reduce(into: [URL]()) { result, url in
            let normalized = url.standardizedFileURL
            let contentType =
                UTType(
                    filenameExtension:
                        normalized.pathExtension
                        .lowercased()
                )

            guard PhotoProcessingInputPolicy.standard
                .isSupportedContentType(
                    contentType
                ) else {
                return
            }

            if !result.contains(normalized) {
                result.append(normalized)
            }
        }
    }

    nonisolated static func makeTemporaryURL(
        suggestedFileName: String?,
        contentType: UTType?,
        fileManager: FileManager = .default
    ) throws -> URL {
        let baseDirectory =
            fileManager.temporaryDirectory
            .appendingPathComponent(
                "PhotoMemoV1Picker",
                isDirectory: true
            )

        try fileManager.createDirectory(
            at: baseDirectory,
            withIntermediateDirectories: true
        )

        let sanitizedFileName =
            PhotoFileNameResolver
            .sanitizedOriginalFileName(
                suggestedFileName
            )

        let baseName =
            sanitizedFileName
            .map {
                URL(fileURLWithPath: $0)
                    .deletingPathExtension()
                    .lastPathComponent
            }
            .flatMap { text in
                let trimmed =
                    text.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                return trimmed.isEmpty ? nil : trimmed
            }
            ?? "PhotoMemo Picked Photo"

        let fileExtension =
            sanitizedFileName
            .map {
                URL(fileURLWithPath: $0)
                    .pathExtension
            }
            .flatMap { text in
                let trimmed =
                    text.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                return trimmed.isEmpty ? nil : trimmed.lowercased()
            }
            ?? contentType?.preferredFilenameExtension
            ?? "jpg"

        return baseDirectory
            .appendingPathComponent(
                "\(baseName)-\(UUID().uuidString)"
            )
            .appendingPathExtension(fileExtension)
    }

    nonisolated static func copyTemporaryFileRepresentation(
        from sourceURL: URL,
        suggestedFileName: String? = nil,
        contentType: UTType? = nil,
        fileManager: FileManager = .default
    ) throws -> URL {
        let resolvedContentType =
            contentType
            ?? UTType(
                filenameExtension:
                    sourceURL.pathExtension
                    .lowercased()
            )

        let temporaryURL =
            try makeTemporaryURL(
                suggestedFileName:
                    suggestedFileName
                    ?? sourceURL.lastPathComponent,
                contentType:
                    resolvedContentType,
                fileManager:
                    fileManager
            )

        if fileManager.fileExists(
            atPath: temporaryURL.path
        ) {
            try fileManager.removeItem(
                at: temporaryURL
            )
        }

        try fileManager.copyItem(
            at: sourceURL,
            to: temporaryURL
        )

        return temporaryURL.standardizedFileURL
    }
}

enum V1PhotoProcessingQuickActionCoordinator {

    struct Result:
        Equatable {

        enum Status:
            Equatable {

            case configurationSaveFailed
            case noSupportedPhotos
            case submitted
        }

        let status: Status
        let submittedURLs: [URL]
    }

    static func processPickedPhotos(
        saveCurrentConfiguration: () async -> Bool,
        importURLs: () async -> [URL],
        submit: ([URL]) -> Void
    ) async -> Result {
        guard await saveCurrentConfiguration() else {
            return Result(
                status: .configurationSaveFailed,
                submittedURLs: []
            )
        }

        let resolvedURLs =
            await importURLs()

        guard !resolvedURLs.isEmpty else {
            return Result(
                status: .noSupportedPhotos,
                submittedURLs: []
            )
        }

        submit(resolvedURLs)

        return Result(
            status: .submitted,
            submittedURLs: resolvedURLs
        )
    }
}

#if os(iOS)
import CoreTransferable
import Photos
import PhotosUI
import SwiftUI

struct V1PickedPhotoFileRepresentation:
    Transferable {

    let url: URL

    static var transferRepresentation:
        some TransferRepresentation {

        FileRepresentation(
            importedContentType: .image
        ) { receivedFile in
            let copiedURL =
                try V1PhotoIntakeURLResolver
                .copyTemporaryFileRepresentation(
                    from:
                        receivedFile.file
                )

            return V1PickedPhotoFileRepresentation(
                url: copiedURL
            )
        }
    }
}

enum V1PhotoIntakeImporter {

    static func importURLs(
        from items: [PhotosPickerItem]
    ) async -> [URL] {
        let photoImportService =
            PhotoImportService()
        var importedURLs: [URL] = []

        for item in items {
            let contentType =
                resolvedSupportedContentType(
                    for: item,
                    photoImportService:
                        photoImportService
                )

            if contentType == nil,
               !item.supportedContentTypes.isEmpty {
                continue
            }

            if let fileRepresentation =
                try? await item.loadTransferable(
                    type:
                        V1PickedPhotoFileRepresentation
                        .self
                ) {
                importedURLs.append(
                    fileRepresentation.url
                )
                continue
            }

            guard
                let data =
                    try? await item.loadTransferable(
                        type: Data.self
                    )
            else {
                continue
            }

            guard
                let temporaryURL =
                    try? V1PhotoIntakeURLResolver
                    .makeTemporaryURL(
                        suggestedFileName:
                            resolvedSuggestedFileName(
                                for: item,
                                contentType: contentType,
                                photoImportService:
                                    photoImportService
                            ),
                        contentType: contentType
                    )
            else {
                continue
            }

            do {
                try data.write(
                    to: temporaryURL,
                    options: .atomic
                )
                importedURLs.append(temporaryURL)
            } catch {
                continue
            }
        }

        return V1PhotoIntakeURLResolver.resolve(
            importedURLs
        )
    }

    private static func resolvedSupportedContentType(
        for item: PhotosPickerItem,
        photoImportService: PhotoImportService
    ) -> UTType? {
        item.supportedContentTypes.first {
            photoImportService.isSupported(
                $0
            )
        }
    }

    private static func resolvedSuggestedFileName(
        for item: PhotosPickerItem,
        contentType: UTType?,
        photoImportService: PhotoImportService
    ) -> String? {
        if let itemIdentifier =
            item.itemIdentifier,
           let originalFileName =
            originalPhotoLibraryFileName(
                for: itemIdentifier,
                photoImportService:
                    photoImportService
            ) {
            return originalFileName
        }

        if let itemIdentifier =
            item.itemIdentifier,
           let sanitizedIdentifier =
            photoImportService
            .sanitizedSuggestedFileName(
                itemIdentifier
            ),
           sanitizedIdentifier.contains(".") {
            return sanitizedIdentifier
        }

        guard let fileExtension =
            contentType?
            .preferredFilenameExtension else {
            return nil
        }

        return "PhotoMemo Picked Photo.\(fileExtension)"
    }

    private static func originalPhotoLibraryFileName(
        for itemIdentifier: String,
        photoImportService: PhotoImportService
    ) -> String? {
        let assets =
            PHAsset.fetchAssets(
                withLocalIdentifiers: [
                    itemIdentifier
                ],
                options: nil
            )

        guard let asset =
            assets.firstObject else {
            return nil
        }

        let resources =
            PHAssetResource.assetResources(
                for: asset
            )

        let preferredResource =
            resources.first {
                switch $0.type {
                case .photo,
                     .fullSizePhoto,
                     .alternatePhoto:
                    return true
                default:
                    return false
                }
            }

        let fileName =
            preferredResource?.originalFilename
            ?? resources.first?.originalFilename

        return photoImportService
            .sanitizedSuggestedFileName(
                fileName
            )
    }
}
#endif
#endif
