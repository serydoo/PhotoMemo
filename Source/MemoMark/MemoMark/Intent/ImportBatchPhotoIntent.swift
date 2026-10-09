import Foundation

struct ImportBatchPhotoIntent:
    MemoMarkIntent {

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
    async -> MemoMarkResult<
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
