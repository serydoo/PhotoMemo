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
