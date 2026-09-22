#if !MEMOMARK_SHARE_EXTENSION
import Foundation

enum ConfigurationOutputTarget:
    String,
    Codable,
    CaseIterable,
    Hashable,
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
            return MemoMarkLanguage.interfaceStored.localized(
                key: "output.destination.target.automatic",
                fallback: "Automatic"
            )
        case .applePhotos:
            return MemoMarkLanguage.interfaceStored.localized(
                key: "output.destination.target.apple_photos",
                fallback: "Apple Photos Library"
            )
        case .existingAlbum:
            return MemoMarkLanguage.interfaceStored.localized(
                key: "output.destination.target.existing_album",
                fallback: "Existing Album"
            )
        case .newAlbum:
            return MemoMarkLanguage.interfaceStored.localized(
                key: "output.destination.target.new_album",
                fallback: "New Album"
            )
        }
    }

    var note: String {
        switch self {
        case .automatic:
            return MemoMarkLanguage.interfaceStored.localized(
                key: "output.destination.target.automatic.note",
                fallback: "Generated photos go to the Photos library and the MemoMark album."
            )
        case .applePhotos:
            return MemoMarkLanguage.interfaceStored.localized(
                key: "output.destination.target.apple_photos.note",
                fallback: "Generated photos go only to the Photos library."
            )
        case .existingAlbum:
            return MemoMarkLanguage.interfaceStored.localized(
                key: "output.destination.target.existing_album.note",
                fallback: "Generated photos go to the Photos library and the selected album."
            )
        case .newAlbum:
            return MemoMarkLanguage.interfaceStored.localized(
                key: "output.destination.target.new_album.note",
                fallback: "The album is created or reused when you save this configuration."
            )
        }
    }
}

enum MediaOutputMode:
    String,
    CaseIterable,
    Identifiable,
    Codable,
    Hashable {

    case originalFormat
    case staticImage

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .originalFormat:
            return MemoMarkLanguage.interfaceStored.localized(
                key: "output.result.mode.original",
                fallback: "Original Format"
            )
        case .staticImage:
            return MemoMarkLanguage.interfaceStored.localized(
                key: "output.result.mode.static",
                fallback: "Still Image"
            )
        }
    }

    var note: String {
        switch self {
        case .originalFormat:
            return MemoMarkLanguage.interfaceStored.localized(
                key: "output.result.mode.original.note",
                fallback: "Still photos keep their format; Live Photos keep their motion."
            )
        case .staticImage:
            return MemoMarkLanguage.interfaceStored.localized(
                key: "output.result.mode.static.note",
                fallback: "Live Photos become still images; still photos keep the current card style."
            )
        }
    }

    var mediaProcessingIntent: MediaProcessingIntent {
        switch self {
        case .originalFormat:
            return MediaProcessingIntent(
                motionMode: .automatic,
                outputPreference: .sourceCompatible
            )
        case .staticImage:
            return MediaProcessingIntent(
                motionMode: .stillImageOnly,
                outputPreference: .sourceCompatible
            )
        }
    }
}

struct ResolvedAlbumSelection:
    Hashable {

    let identifier: String

    let title: String

    let pickerSelectionIdentifier:
        String?
}

struct OutputAlbumSelectionRequest:
    Hashable {

    let outputTarget:
        ConfigurationOutputTarget

    let availableAlbums:
        [PhotoAlbumOption]

    let selectedExistingAlbumIdentifier:
        String

    let newAlbumName: String
}

struct EnsureExportAlbumIntent:
    MemoMarkIntent {

    let title: String

    let coordinator:
        ExportCoordinator

    func execute()
    async -> MemoMarkResult<
        PhotoAlbumOption
    > {

        await coordinator
            .ensureAlbum(
                named: title
            )
    }
}

struct ResolveOutputAlbumSelectionIntent:
    MemoMarkIntent {

    let request:
        OutputAlbumSelectionRequest

    let coordinator:
        ExportCoordinator?

    func execute()
    async -> MemoMarkResult<
        ResolvedAlbumSelection
    > {

        switch request.outputTarget {
        case .automatic:
            return .success(
                ResolvedAlbumSelection(
                    identifier:
                        MemoMarkAlbumSelection
                        .automaticIdentifier,
                    title:
                        MemoMarkAlbumSelection
                        .defaultAlbumTitle,
                    pickerSelectionIdentifier:
                        nil
                )
            )

        case .applePhotos:
            return .success(
                ResolvedAlbumSelection(
                    identifier:
                        MemoMarkAlbumSelection
                        .systemLibraryIdentifier,
                    title: MemoMarkLanguage.interfaceStored.localized(
                        key: "output.destination.target.apple_photos",
                        fallback: "Apple Photos Library"
                    ),
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
                return .failure(
                    MemoMarkError(
                        code: .photoLibrarySaveFailed,
                        message: MemoMarkLanguage.interfaceStored.localized(
                            key: "output.destination.album_unavailable",
                            fallback: "你选择的相册已不可用，请重新选择。"
                        ),
                        diagnosticCode: "photoLibrary.album.notFound"
                    )
                )
            }

            return .success(
                ResolvedAlbumSelection(
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
            guard let coordinator else {
                return .failure(
                    MemoMarkError(
                        code: .configurationUnavailable,
                        message:
                            "Unable to prepare a new output album without an active export coordinator."
                    )
                )
            }

            switch await EnsureExportAlbumIntent(
                title:
                    request.newAlbumName,
                coordinator:
                    coordinator
            )
            .execute() {
            case .success(let album):
                return .success(
                    ResolvedAlbumSelection(
                        identifier:
                            album.localIdentifier
                            ?? album.id,
                        title:
                            album.title,
                        pickerSelectionIdentifier:
                            album.id
                    )
                )
            case .failure(let error):
                return .failure(error)
            }
        }
    }
}

// Historical names remain source-compatible while the active intent and
// application transaction use responsibility-based names.
typealias V1ResolvedAlbumSelection = ResolvedAlbumSelection
typealias V1OutputAlbumSelectionRequest = OutputAlbumSelectionRequest
typealias ResolveV1OutputAlbumSelectionIntent = ResolveOutputAlbumSelectionIntent
#endif
