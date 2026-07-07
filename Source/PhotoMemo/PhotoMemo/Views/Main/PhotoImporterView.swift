import SwiftUI
import PhotosUI
import Photos
import UniformTypeIdentifiers
import CoreTransferable

struct PhotoImporterView: View {

    let onImport: (SelectedPhoto) -> Void

    @State
    private var showImporter = false

    @State
    private var selectedPhotoItem:
        PhotosPickerItem?

    @State
    private var errorMessage: String?

    private let importService =
        PhotoImportService()

    var body: some View {

        VStack(spacing: 16) {

            VStack(
                alignment: .leading,
                spacing: 10
            ) {

                PhotosPicker(
                    selection: $selectedPhotoItem,
                    matching: .images
                ) {
                    Label(
                        "从照片中选择",
                        systemImage: "photo.on.rectangle"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

#if os(iOS)
                Text("直接从系统照片中选一张做校准，后续分享和保存会更顺手。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
#else
                Button {

                    showImporter = true

                } label: {

                    Label(
                        "从文件导入",
                        systemImage: "folder"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)

                Text("优先直接从系统照片中选一张做校准；文件导入保留给外部图片或桌面素材。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
#endif
            }

            if let errorMessage {

                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.caption)
            }
        }
#if !os(iOS)
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes:
                importService.supportedTypes(),
            allowsMultipleSelection: false
        ) { result in

            handle(result)
        }
#endif
        .onChange(
            of: selectedPhotoItem
        ) { _, newValue in

            guard let newValue else {
                return
            }

            Task {
                await handlePhotosPickerItem(
                    newValue
                )
            }
        }
    }
}

private extension PhotoImporterView {

    func handlePhotosPickerItem(
        _ item: PhotosPickerItem
    ) async {

        do {

            let contentType =
                resolvedSupportedContentType(
                    for: item
                )

            if contentType == nil,
               !item.supportedContentTypes.isEmpty {

                await MainActor.run {
                    errorMessage =
                        unsupportedInputMessage(
                            contentType:
                                item
                                .supportedContentTypes
                                .first
                        )
                    selectedPhotoItem = nil
                }
                return
            }

            if let fileRepresentation =
                try? await item.loadTransferable(
                    type:
                        PhotoImporterPickedFileRepresentation
                        .self
                ) {
                let photo =
                    try await importService.importPhoto(
                        from:
                            fileRepresentation.url,
                        sourceInfo:
                            PhotoSourceInfo(
                                originalFileName:
                                    resolvedSuggestedFileName(
                                        for: item,
                                        contentType:
                                            contentType
                                    )
                                    ?? fileRepresentation
                                    .url
                                    .lastPathComponent,
                                assetLocalIdentifier:
                                    item.itemIdentifier,
                                contentTypeIdentifier:
                                    contentType?.identifier
                                    ?? UTType(
                                        filenameExtension:
                                            fileRepresentation
                                            .url
                                            .pathExtension
                                            .lowercased()
                                    )?.identifier
                            )
                    )

                await MainActor.run {
                    errorMessage = nil
                    selectedPhotoItem = nil
                    onImport(photo)
                }
                return
            }

            guard
                let data =
                    try await item.loadTransferable(
                        type: Data.self
                    )
            else {

                await MainActor.run {
                    errorMessage =
                        PhotoImportError
                        .imageLoadFailed
                        .errorDescription
                    selectedPhotoItem = nil
                }
                return
            }

            let suggestedFileName =
                resolvedSuggestedFileName(
                    for: item,
                    contentType: contentType
                )

            let photo =
                try await importService.importPhoto(
                    from: data,
                    suggestedFileName:
                        suggestedFileName,
                    contentType: contentType,
                    assetLocalIdentifier:
                        item.itemIdentifier
                )

            await MainActor.run {
                errorMessage = nil
                selectedPhotoItem = nil
                onImport(photo)
            }

        } catch {

            await MainActor.run {
                errorMessage =
                    importErrorMessage(error)
                selectedPhotoItem = nil
            }
        }
    }

    func handle(
        _ result: Result<[URL], Error>
    ) {

        do {

            let urls =
                try result.get()

            guard let url = urls.first else {
                return
            }

            guard
                importService.isSupported(url)
            else {

                errorMessage =
                    unsupportedInputMessage(
                        fileURL: url
                    )

                return
            }

            Task {

                do {

                    let photo =
                        try await importService.importPhoto(
                            from: url
                        )

                    await MainActor.run {

                        errorMessage = nil
                        selectedPhotoItem = nil
                        onImport(photo)
                    }

                } catch {

                    await MainActor.run {

                        errorMessage =
                            importErrorMessage(error)
                    }
                }
            }

        } catch {

            errorMessage =
                error.localizedDescription
        }
    }

    func resolvedSuggestedFileName(
        for item: PhotosPickerItem,
        contentType: UTType?
    ) -> String? {

        if let itemIdentifier =
            item.itemIdentifier,
           let originalPhotoLibraryFileName =
            originalPhotoLibraryFileName(
                for: itemIdentifier
            ) {
            return originalPhotoLibraryFileName
        }

        if let itemIdentifier =
            item.itemIdentifier,
           let sanitizedIdentifier =
            importService
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

        return "MemoMark Import.\(fileExtension)"
    }

    func unsupportedInputMessage(
        contentType: UTType?
    ) -> String {

        unsupportedInputMessage(
            for:
                PhotoProcessingInputPolicy
                .standard
                .verdict(
                    contentType: contentType,
                    pixelWidth: 1,
                    pixelHeight: 1
                )
        )
    }

    func unsupportedInputMessage(
        fileURL: URL
    ) -> String {

        unsupportedInputMessage(
            for:
                PhotoProcessingInputPolicy
                .standard
                .verdict(
                    fileURL: fileURL,
                    declaredContentTypeIdentifier: nil
                )
        )
    }

    func unsupportedInputMessage(
        for verdict:
            PhotoProcessingInputPolicy.Verdict
    ) -> String {

        [
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

    func importErrorMessage(
        _ error: Error
    ) -> String {

        guard let localizedError =
            error as? LocalizedError else {
            return error.localizedDescription
        }

        let title =
            localizedError.errorDescription
            ?? error.localizedDescription
        let reason =
            localizedError.failureReason

        return [
            title,
            reason
        ]
        .compactMap { $0 }
        .filter {
            !$0.isEmpty
        }
        .joined(
            separator: "\n"
        )
    }

    func resolvedSupportedContentType(
        for item: PhotosPickerItem
    ) -> UTType? {
        item.supportedContentTypes.first {
            importService.isSupported(
                $0
            )
        }
    }

    func originalPhotoLibraryFileName(
        for itemIdentifier: String
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

        return importService
            .sanitizedSuggestedFileName(
                fileName
            )
    }
}

struct PhotoImporterPickedFileRepresentation:
    Transferable {

    let url: URL

    static var transferRepresentation:
        some TransferRepresentation {

        FileRepresentation(
            importedContentType: .image
        ) { receivedFile in
            let copiedURL =
                try PhotoImporterFileRepresentationResolver
                .copyTemporaryFileRepresentation(
                    from:
                        receivedFile.file
                )

            return PhotoImporterPickedFileRepresentation(
                url: copiedURL
            )
        }
    }
}

enum PhotoImporterFileRepresentationResolver {

    nonisolated static func copyTemporaryFileRepresentation(
        from sourceURL: URL,
        contentType: UTType? = nil,
        fileManager: FileManager = .default
    ) throws -> URL {
        let temporaryURL =
            try makeTemporaryURL(
                sourceURL:
                    sourceURL,
                contentType:
                    contentType,
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

    private nonisolated static func makeTemporaryURL(
        sourceURL: URL,
        contentType: UTType?,
        fileManager: FileManager
    ) throws -> URL {
        let baseDirectory =
            fileManager.temporaryDirectory
            .appendingPathComponent(
                "MemoMarkPickerFileRepresentations",
                isDirectory: true
            )

        try fileManager.createDirectory(
            at: baseDirectory,
            withIntermediateDirectories: true
        )

        let sanitizedFileName =
            PhotoFileNameResolver
            .sanitizedOriginalFileName(
                sourceURL.lastPathComponent
            )
        let baseName =
            sanitizedFileName
            .map {
                URL(fileURLWithPath: $0)
                    .deletingPathExtension()
                    .lastPathComponent
            }
            .flatMap { value in
                let trimmed =
                    value.trimmingCharacters(
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
            .flatMap { value in
                let trimmed =
                    value.trimmingCharacters(
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
}

#Preview {

    PhotoImporterView { _ in

    }
}
