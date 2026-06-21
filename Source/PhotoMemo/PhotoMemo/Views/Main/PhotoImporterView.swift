import SwiftUI
import PhotosUI
import Photos
import UniformTypeIdentifiers

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
                item.supportedContentTypes.first

            if let contentType,
               !importService.isSupported(
                contentType
               ) {

                await MainActor.run {
                    errorMessage =
                        "Unsupported image format"
                    selectedPhotoItem = nil
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
                    (error as? LocalizedError)?
                    .errorDescription
                    ?? error.localizedDescription
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
                    "Unsupported image format"

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
                            (error as? LocalizedError)?
                            .errorDescription
                            ?? error.localizedDescription
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

        return "PhotoMemo Import.\(fileExtension)"
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

#Preview {

    PhotoImporterView { _ in

    }
}
