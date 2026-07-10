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
                "MemoMarkV1Picker",
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
            ?? "MemoMark Picked Photo"

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
        let submittedItems:
            [ExternalPhotoIntakeItem]

        init(
            status: Status,
            submittedURLs: [URL],
            submittedItems:
                [ExternalPhotoIntakeItem] = []
        ) {
            self.status = status
            self.submittedURLs =
                submittedURLs
            self.submittedItems =
                submittedItems
        }
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

    static func processPickedPhotoItems(
        saveCurrentConfiguration: () async -> Bool,
        importItems:
            () async -> [ExternalPhotoIntakeItem],
        submit: ([ExternalPhotoIntakeItem]) -> Void
    ) async -> Result {
        guard await saveCurrentConfiguration() else {
            return Result(
                status: .configurationSaveFailed,
                submittedURLs: []
            )
        }

        let resolvedItems =
            await importItems()

        guard !resolvedItems.isEmpty else {
            return Result(
                status: .noSupportedPhotos,
                submittedURLs: []
            )
        }

        submit(resolvedItems)

        return Result(
            status: .submitted,
            submittedURLs:
                resolvedItems.map(
                    \.managedURL
                ),
            submittedItems:
                resolvedItems
        )
    }
}

enum V1PhotoIntakeUnsupportedMessagePresenter {

    nonisolated static let fallbackMessage =
        "未找到可处理的照片"

    nonisolated static func message(
        for contentTypes: [UTType]
    ) -> String {

        let policy =
            PhotoProcessingInputPolicy.standard

        guard !contentTypes.isEmpty,
              !contentTypes.contains(
                where:
                    policy.isSupportedContentType
              ) else {
            return fallbackMessage
        }

        guard let verdict =
            contentTypes
            .map({
                policy.verdict(
                    contentType: $0,
                    pixelWidth: 1,
                    pixelHeight: 1
                )
            })
            .first(where: {
                !$0.isSupported
            }) else {
            return fallbackMessage
        }

        return [
            verdict.title,
            verdict.message
        ]
        .filter {
            !$0.isEmpty
        }
        .joined(
            separator: "\n"
        )
    }
}

#if os(iOS)
import CoreTransferable
import Photos
import PhotosUI
import SwiftUI
import UIKit

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

    private static let livePhotoContentType =
        UTType(
            "com.apple.live-photo"
        )

    private static let internalTestingPolicy =
        PhotoProcessingInputPolicy(
            allowsLivePhoto: true
        )

    static func importURLs(
        from items: [PhotosPickerItem]
    ) async -> [URL] {
        await importItems(
            from: items
        )
        .map(
            \.managedURL
        )
    }

    static func importItems(
        from items: [PhotosPickerItem]
    ) async -> [ExternalPhotoIntakeItem] {
        let photoImportService =
            PhotoImportService()
        var importedItems:
            [ExternalPhotoIntakeItem] = []

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

            let treatsAsLivePhoto =
                isLivePhotoItem(
                    item,
                    resolvedContentType:
                        contentType
                )
            let itemContentType =
                treatsAsLivePhoto
                ? livePhotoContentType
                : contentType
            PhotoMemoShareDiagnostics.record(
                stage: .appPickerItemObserved,
                message:
                    pickerItemObservedMessage(
                        item: item,
                        resolvedContentType:
                            contentType,
                        treatsAsLivePhoto:
                            treatsAsLivePhoto,
                        itemContentType:
                            itemContentType
                    )
            )

            if let fileRepresentation =
                try? await item.loadTransferable(
                    type:
                        V1PickedPhotoFileRepresentation
                        .self
                ) {
                importedItems.append(
                    intakeItem(
                        for: item,
                        managedURL:
                            fileRepresentation.url,
                        contentType:
                            itemContentType,
                        photoImportService:
                            photoImportService
                    )
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
                                contentType: itemContentType,
                                photoImportService:
                                    photoImportService
                            ),
                        contentType: itemContentType
                    )
            else {
                continue
            }

            do {
                try data.write(
                    to: temporaryURL,
                    options: .atomic
                )
                importedItems.append(
                    intakeItem(
                        for: item,
                        managedURL:
                            temporaryURL,
                        contentType:
                            itemContentType,
                        photoImportService:
                            photoImportService
                    )
                )
            } catch {
                continue
            }
        }

        return importedItems
            .reduce(into: [ExternalPhotoIntakeItem]()) {
                result,
                item in

                if !result.contains(
                    where: {
                        $0.managedURL
                            .standardizedFileURL
                            .path
                        == item.managedURL
                            .standardizedFileURL
                            .path
                    }
                ) {
                    result.append(item)
                }
            }
    }

    static func importPHPickerResults(
        from results: [PHPickerResult]
    ) async -> [ExternalPhotoIntakeItem] {
        let photoImportService =
            PhotoImportService()
        var importedItems:
            [ExternalPhotoIntakeItem] = []

        for result in results {
            let provider =
                result.itemProvider
            let registeredContentTypes =
                registeredContentTypes(
                    for: provider
                )
            let resolvedContentType =
                resolvedSupportedContentType(
                    for:
                        registeredContentTypes
                )
            let treatsAsLivePhoto =
                phpPickerResultIsLivePhoto(
                    result,
                    registeredContentTypes:
                        registeredContentTypes,
                    resolvedContentType:
                        resolvedContentType
                )
            let itemContentType =
                treatsAsLivePhoto
                ? livePhotoContentType
                : resolvedContentType

            PhotoMemoShareDiagnostics.record(
                stage: .appPickerItemObserved,
                message:
                    phpPickerResultObservedMessage(
                        result: result,
                        registeredContentTypes:
                            registeredContentTypes,
                        resolvedContentType:
                            resolvedContentType,
                        treatsAsLivePhoto:
                            treatsAsLivePhoto,
                        itemContentType:
                            itemContentType
                    )
            )

            guard let fileContentType =
                resolvedImageContentType(
                    for:
                        registeredContentTypes
                )
                ?? resolvedContentType
            else {
                continue
            }

            guard let temporaryURL =
                await copyProviderRepresentation(
                    provider,
                    contentType:
                        fileContentType,
                    suggestedFileName:
                        resolvedSuggestedFileName(
                            for:
                                result,
                            contentType:
                                itemContentType,
                            photoImportService:
                                photoImportService
                        )
                )
            else {
                continue
            }

            importedItems.append(
                ExternalPhotoIntakeItem(
                    managedURL:
                        temporaryURL,
                    originalFileName:
                        resolvedSuggestedFileName(
                            for:
                                result,
                            contentType:
                                itemContentType,
                            photoImportService:
                                photoImportService
                        )
                        ?? temporaryURL
                        .lastPathComponent,
                    sourceIdentifier:
                        result.assetIdentifier,
                    contentTypeIdentifier:
                        itemContentType?
                        .identifier
                )
            )
        }

        return deduplicatedItems(
            importedItems
        )
    }

    private static func resolvedSupportedContentType(
        for item: PhotosPickerItem,
        photoImportService: PhotoImportService
    ) -> UTType? {
        item.supportedContentTypes.first {
            internalTestingPolicy
                .isSupportedContentType(
                $0
            )
        }
    }

    private static func resolvedSupportedContentType(
        for contentTypes: [UTType]
    ) -> UTType? {
        contentTypes.first {
            internalTestingPolicy
                .isSupportedContentType(
                    $0
                )
        }
    }

    private static func resolvedImageContentType(
        for contentTypes: [UTType]
    ) -> UTType? {
        contentTypes.first { contentType in
            PhotoProcessingInputPolicy
                .supportedImageTypes
                .contains { supportedType in
                    contentType.conforms(
                        to:
                            supportedType
                    )
                    || contentType.identifier
                        == supportedType.identifier
                }
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

        return "MemoMark Picked Photo.\(fileExtension)"
    }

    private static func resolvedSuggestedFileName(
        for result: PHPickerResult,
        contentType: UTType?,
        photoImportService: PhotoImportService
    ) -> String? {
        if let assetIdentifier =
            result.assetIdentifier,
           let originalFileName =
            originalPhotoLibraryFileName(
                for: assetIdentifier,
                photoImportService:
                    photoImportService
            ) {
            return originalFileName
        }

        if let assetIdentifier =
            result.assetIdentifier,
           let sanitizedIdentifier =
            photoImportService
            .sanitizedSuggestedFileName(
                assetIdentifier
            ),
           sanitizedIdentifier.contains(".") {
            return sanitizedIdentifier
        }

        guard let fileExtension =
            contentType?
            .preferredFilenameExtension else {
            return nil
        }

        return "MemoMark Picked Photo.\(fileExtension)"
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

    private static func isLivePhotoItem(
        _ item: PhotosPickerItem,
        resolvedContentType:
            UTType?
    ) -> Bool {

        if PhotoProcessingInputPolicy
            .isLivePhotoContentType(
                resolvedContentType
            ) {
            return true
        }

        if item.supportedContentTypes.contains(
            where:
                PhotoProcessingInputPolicy
                .isLivePhotoContentType
        ) {
            return true
        }

        guard let itemIdentifier =
            item.itemIdentifier else {
            return false
        }

        return photoLibraryAssetIsLivePhoto(
            itemIdentifier
        )
    }

    private static func phpPickerResultIsLivePhoto(
        _ result: PHPickerResult,
        registeredContentTypes: [UTType],
        resolvedContentType: UTType?
    ) -> Bool {
        if PhotoProcessingInputPolicy
            .isLivePhotoContentType(
                resolvedContentType
            ) {
            return true
        }

        if registeredContentTypes.contains(
            where:
                PhotoProcessingInputPolicy
                .isLivePhotoContentType
        ) {
            return true
        }

        guard let assetIdentifier =
            result.assetIdentifier else {
            return false
        }

        return photoLibraryAssetIsLivePhoto(
            assetIdentifier
        )
    }

    private static func photoLibraryAssetIsLivePhoto(
        _ itemIdentifier: String
    ) -> Bool {

        let assets =
            PHAsset.fetchAssets(
                withLocalIdentifiers: [
                    itemIdentifier
                ],
                options: nil
            )

        guard let asset =
            assets.firstObject else {
            return false
        }

        return asset.mediaSubtypes
            .contains(
                .photoLive
            )
    }

    private static func pickerItemObservedMessage(
        item: PhotosPickerItem,
        resolvedContentType: UTType?,
        treatsAsLivePhoto: Bool,
        itemContentType: UTType?
    ) -> String {

        [
            "supportedContentTypes=\(item.supportedContentTypes.map { $0.identifier }.joined(separator: "|"))",
            "resolvedContentType=\(resolvedContentType?.identifier ?? "nil")",
            "treatsAsLivePhoto=\(treatsAsLivePhoto)",
            "itemContentType=\(itemContentType?.identifier ?? "nil")",
            "hasItemIdentifier=\(item.itemIdentifier?.isEmpty == false)"
        ]
        .joined(separator: ", ")
    }

    private static func phpPickerResultObservedMessage(
        result: PHPickerResult,
        registeredContentTypes: [UTType],
        resolvedContentType: UTType?,
        treatsAsLivePhoto: Bool,
        itemContentType: UTType?
    ) -> String {

        [
            "source=uiKitPHPicker",
            "registeredTypes=\(registeredContentTypes.map { $0.identifier }.joined(separator: "|"))",
            "resolvedContentType=\(resolvedContentType?.identifier ?? "nil")",
            "treatsAsLivePhoto=\(treatsAsLivePhoto)",
            "itemContentType=\(itemContentType?.identifier ?? "nil")",
            "hasAssetIdentifier=\(result.assetIdentifier?.isEmpty == false)"
        ]
        .joined(separator: ", ")
    }

    private static func registeredContentTypes(
        for provider: NSItemProvider
    ) -> [UTType] {
        provider.registeredTypeIdentifiers
            .compactMap(UTType.init)
    }

    private static func copyProviderRepresentation(
        _ provider: NSItemProvider,
        contentType: UTType,
        suggestedFileName: String?
    ) async -> URL? {
        if let fileURL =
            await copyProviderFileRepresentation(
                provider,
                contentType:
                    contentType,
                suggestedFileName:
                    suggestedFileName
            ) {
            return fileURL
        }

        return await copyProviderDataRepresentation(
            provider,
            contentType:
                contentType,
            suggestedFileName:
                suggestedFileName
        )
    }

    private static func copyProviderFileRepresentation(
        _ provider: NSItemProvider,
        contentType: UTType,
        suggestedFileName: String?
    ) async -> URL? {
        await withCheckedContinuation { continuation in
            provider.loadFileRepresentation(
                forTypeIdentifier:
                    contentType.identifier
            ) { url, _ in
                guard let url else {
                    continuation.resume(
                        returning: nil
                    )
                    return
                }

                let copiedURL =
                    try? V1PhotoIntakeURLResolver
                    .copyTemporaryFileRepresentation(
                        from: url,
                        suggestedFileName:
                            suggestedFileName,
                        contentType:
                            contentType
                    )

                continuation.resume(
                    returning:
                        copiedURL
                )
            }
        }
    }

    private static func copyProviderDataRepresentation(
        _ provider: NSItemProvider,
        contentType: UTType,
        suggestedFileName: String?
    ) async -> URL? {
        await withCheckedContinuation { continuation in
            provider.loadDataRepresentation(
                forTypeIdentifier:
                    contentType.identifier
            ) { data, _ in
                guard let data else {
                    continuation.resume(
                        returning: nil
                    )
                    return
                }

                guard let temporaryURL =
                    try? V1PhotoIntakeURLResolver
                    .makeTemporaryURL(
                        suggestedFileName:
                            suggestedFileName,
                        contentType:
                            contentType
                    )
                else {
                    continuation.resume(
                        returning: nil
                    )
                    return
                }

                do {
                    try data.write(
                        to: temporaryURL,
                        options: .atomic
                    )
                    continuation.resume(
                        returning:
                            temporaryURL
                            .standardizedFileURL
                    )
                } catch {
                    continuation.resume(
                        returning: nil
                    )
                }
            }
        }
    }

    private static func deduplicatedItems(
        _ items: [ExternalPhotoIntakeItem]
    ) -> [ExternalPhotoIntakeItem] {
        items.reduce(
            into:
                [ExternalPhotoIntakeItem]()
        ) { result, item in
            if !result.contains(
                where: {
                    $0.managedURL
                        .standardizedFileURL
                        .path
                    == item.managedURL
                        .standardizedFileURL
                        .path
                }
            ) {
                result.append(item)
            }
        }
    }

    private static func intakeItem(
        for item: PhotosPickerItem,
        managedURL: URL,
        contentType: UTType?,
        photoImportService:
            PhotoImportService
    ) -> ExternalPhotoIntakeItem {

        ExternalPhotoIntakeItem(
            managedURL:
                managedURL,
            originalFileName:
                resolvedSuggestedFileName(
                    for: item,
                    contentType: contentType,
                    photoImportService:
                        photoImportService
                )
                ?? managedURL.lastPathComponent,
            sourceIdentifier:
                item.itemIdentifier,
            contentTypeIdentifier:
                contentType?.identifier
        )
    }
}

struct V1UIKitPhotoPicker:
    UIViewControllerRepresentable {

    let selectionLimit: Int
    let onCancel: () -> Void
    let onSelect: ([PHPickerResult]) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(
        context: Context
    ) -> PHPickerViewController {
        var configuration =
            PHPickerConfiguration(
                photoLibrary:
                    .shared()
            )
        configuration.filter = .images
        configuration.selectionLimit =
            selectionLimit
        configuration
            .preferredAssetRepresentationMode =
            .current

        let picker =
            PHPickerViewController(
                configuration:
                    configuration
            )
        picker.delegate =
            context.coordinator
        return picker
    }

    func updateUIViewController(
        _ uiViewController:
            PHPickerViewController,
        context: Context
    ) {}

    final class Coordinator:
        NSObject,
        PHPickerViewControllerDelegate {

        private let parent:
            V1UIKitPhotoPicker

        init(
            parent:
                V1UIKitPhotoPicker
        ) {
            self.parent = parent
        }

        func picker(
            _ picker: PHPickerViewController,
            didFinishPicking results: [PHPickerResult]
        ) {
            picker.dismiss(animated: true)

            guard !results.isEmpty else {
                parent.onCancel()
                return
            }

            parent.onSelect(results)
        }
    }
}
#endif
#endif
