#if !MEMOMARK_SHARE_EXTENSION
import Foundation

struct BuildPreviewIntent:
    MemoMarkIntent {

    let photo: SelectedPhoto

    let configuration:
        BatchConfigurationSnapshot

    let coordinator:
        PreviewCoordinator

    func execute()
    async -> MemoMarkResult<
        RecordCard
    > {

        coordinator.buildCard(
            from: photo,
            configuration: configuration
        )
    }
}

struct ExportRecordCardIntent:
    MemoMarkIntent {

    let photo: SelectedPhoto

    let card: RecordCard

    let coordinator:
        ExportCoordinator

    func execute()
    async -> MemoMarkResult<URL> {

        await coordinator.exportCard(
            photo: photo,
            card: card
        )
    }
}

struct SaveRenderedPhotoIntent:
    MemoMarkIntent {

    let fileURL: URL

    let metadata: PhotoMetadata

    let preferredAlbumIdentifier:
        String

    let idempotencyKey: String?

    let coordinator:
        ExportCoordinator

    init(
        fileURL: URL,
        metadata: PhotoMetadata,
        preferredAlbumIdentifier: String,
        coordinator: ExportCoordinator,
        idempotencyKey: String? = nil
    ) {
        self.fileURL = fileURL
        self.metadata = metadata
        self.preferredAlbumIdentifier = preferredAlbumIdentifier
        self.coordinator = coordinator
        self.idempotencyKey = idempotencyKey
    }

    func execute()
    async -> MemoMarkResult<
        PhotoLibrarySaveResult
    > {

        await coordinator
            .saveRenderedPhoto(
                at: fileURL,
                metadata: metadata,
                preferredAlbumIdentifier:
                    preferredAlbumIdentifier,
                idempotencyKey:
                    idempotencyKey ?? ""
            )
    }
}

struct LoadConfigurationSnapshotIntent:
    MemoMarkIntent {

    enum Source {
        case live
        case shared
    }

    let source: Source

    let coordinator:
        ConfigurationCoordinator

    func execute()
    async -> MemoMarkResult<
        BatchConfigurationSnapshot
    > {

        switch source {
        case .live:
            return coordinator
                .loadDefaultBatchConfigurationSnapshot()
        case .shared:
            return coordinator
                .loadSharedBatchConfigurationSnapshot()
        }
    }
}
#endif
