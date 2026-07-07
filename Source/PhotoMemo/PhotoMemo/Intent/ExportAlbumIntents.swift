#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

enum V1IOSOutputTarget:
    String,
    CaseIterable,
    Identifiable {

    case automatic
    case applePhotos
    case existingAlbum
    case newAlbum

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .automatic:
            return "自动"
        case .applePhotos:
            return "系统图库"
        case .existingAlbum:
            return "已有相册"
        case .newAlbum:
            return "新建相册"
        }
    }

    var note: String {
        switch self {
        case .automatic:
            return "不选择时，生成照片会进入系统图库，并自动归入时光记相册。"
        case .applePhotos:
            return "生成照片只写入系统图库，不额外加入时光记指定相册。"
        case .existingAlbum:
            return "生成照片会写入系统图库，并加入选中的相册。"
        case .newAlbum:
            return "保存配置时会创建或复用这个相册。"
        }
    }
}

struct V1ResolvedAlbumSelection:
    Hashable {

    let identifier: String

    let title: String

    let pickerSelectionIdentifier:
        String?
}

struct V1OutputAlbumSelectionRequest:
    Hashable {

    let outputTarget:
        V1IOSOutputTarget

    let availableAlbums:
        [PhotoAlbumOption]

    let selectedExistingAlbumIdentifier:
        String

    let newAlbumName: String
}

struct LoadExportAlbumOptionsIntent:
    PhotoMemoIntent {

    let coordinator:
        ExportCoordinator

    func execute()
    async -> PhotoMemoResult<
        [PhotoAlbumOption]
    > {

        await coordinator
            .fetchAlbumOptions()
    }
}

struct LoadV1ExportAlbumOptionsIntent:
    PhotoMemoIntent {

    let coordinator:
        ExportCoordinator?

    func execute()
    async -> PhotoMemoResult<
        [PhotoAlbumOption]
    > {

        if let coordinator {
            return await LoadExportAlbumOptionsIntent(
                coordinator: coordinator
            )
            .execute()
        }

        do {
            return .success(
                try await PhotoLibraryExportService()
                .fetchAlbumOptions()
            )
        } catch {
            return .failure(
                .wrapped(
                    error,
                    code: .photoLibrarySaveFailed,
                    message:
                        error
                        .localizedDescription
                )
            )
        }
    }
}

struct EnsureExportAlbumIntent:
    PhotoMemoIntent {

    let title: String

    let coordinator:
        ExportCoordinator

    func execute()
    async -> PhotoMemoResult<
        PhotoAlbumOption
    > {

        await coordinator
            .ensureAlbum(
                named: title
            )
    }
}

struct ResolveV1OutputAlbumSelectionIntent:
    PhotoMemoIntent {

    let request:
        V1OutputAlbumSelectionRequest

    let coordinator:
        ExportCoordinator?

    func execute()
    async -> PhotoMemoResult<
        V1ResolvedAlbumSelection
    > {

        switch request.outputTarget {
        case .automatic:
            return .success(
                V1ResolvedAlbumSelection(
                    identifier:
                        PhotoMemoAlbumSelection
                        .automaticIdentifier,
                    title:
                        PhotoMemoAlbumSelection
                        .defaultAlbumTitle,
                    pickerSelectionIdentifier:
                        nil
                )
            )

        case .applePhotos:
            return .success(
                V1ResolvedAlbumSelection(
                    identifier:
                        PhotoMemoAlbumSelection
                        .systemLibraryIdentifier,
                    title: "系统图库",
                    pickerSelectionIdentifier:
                        nil
                )
            )

        case .existingAlbum:
            guard
                !request
                .selectedExistingAlbumIdentifier
                .isEmpty,
                let selectedAlbum =
                    request
                    .availableAlbums
                    .first(where: {
                        $0.id
                        == request
                        .selectedExistingAlbumIdentifier
                    })
            else {
                return .success(
                    V1ResolvedAlbumSelection(
                        identifier:
                            PhotoMemoAlbumSelection
                            .automaticIdentifier,
                        title:
                            PhotoMemoAlbumSelection
                            .defaultAlbumTitle,
                        pickerSelectionIdentifier:
                            nil
                    )
                )
            }

            return .success(
                V1ResolvedAlbumSelection(
                    identifier:
                        selectedAlbum.localIdentifier
                        ?? selectedAlbum.id,
                    title:
                        selectedAlbum.title,
                    pickerSelectionIdentifier:
                        selectedAlbum.id
                )
            )

        case .newAlbum:
            do {
                let album: PhotoAlbumOption

                if let coordinator {
                    switch await EnsureExportAlbumIntent(
                        title:
                            request.newAlbumName,
                        coordinator:
                            coordinator
                    )
                    .execute() {
                    case .success(let ensuredAlbum):
                        album = ensuredAlbum
                    case .failure(let error):
                        return .failure(error)
                    }
                } else {
                    album =
                        try await PhotoLibraryExportService()
                        .ensureAlbum(
                            named:
                                request
                                .newAlbumName
                        )
                }

                return .success(
                    V1ResolvedAlbumSelection(
                        identifier:
                            album.localIdentifier
                            ?? album.id,
                        title:
                            album.title,
                        pickerSelectionIdentifier:
                            album.id
                    )
                )
            } catch {
                return .failure(
                    .wrapped(
                        error,
                        code:
                            .photoLibrarySaveFailed,
                        message:
                            error
                            .localizedDescription
                    )
                )
            }
        }
    }
}
#endif
