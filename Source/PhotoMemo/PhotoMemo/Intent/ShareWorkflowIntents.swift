#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct ProcessedShareRequest:
    Hashable {

    let requestID: UUID

    let requestedPayloadCount: Int

    let validPayloadCount: Int

    let uniquePayloadCount: Int

    let consumedPayloadKeys:
        Set<String>

    let intakeSummary:
        ExternalPhotoImportSummary?

    let job: BatchJob?

    let droppedReason: String?
}

struct ProcessShareIntent:
    PhotoMemoIntent {

    let request:
        ExternalPhotoIntakeRequest

    let consumedPayloadKeys:
        Set<String>

    let coordinator:
        ShareCoordinator

    func execute()
    async -> PhotoMemoResult<
        ProcessedShareRequest
    > {

        executeSynchronously()
    }

    func executeSynchronously()
    -> PhotoMemoResult<
        ProcessedShareRequest
    > {

        coordinator.process(
            request: request,
            consumedPayloadKeys:
                consumedPayloadKeys
        )
    }
}

struct ImportBatchPhotoIntent:
    PhotoMemoIntent {

    let task: BatchTask

    let contentTypeIdentifierOverride: String?

    let repository:
        PhotoRepository

    init(
        task: BatchTask,
        contentTypeIdentifierOverride: String? = nil,
        repository: PhotoRepository
    ) {
        self.task = task
        self.contentTypeIdentifierOverride =
            contentTypeIdentifierOverride
        self.repository = repository
    }

    func execute()
    async -> PhotoMemoResult<
        SelectedPhoto
    > {

        await repository.importPhoto(
            from: task.sourceURL,
            sourceInfo:
                PhotoSourceInfo(
                    originalFileName:
                        task.fileName,
                    assetLocalIdentifier:
                        task.sourceIdentifier,
                    contentTypeIdentifier:
                        contentTypeIdentifierOverride
                        ?? task.contentTypeIdentifier
                )
        )
    }
}
#endif
