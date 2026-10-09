#if !MEMOMARK_SHARE_EXTENSION
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
    MemoMarkIntent {

    let request:
        ExternalPhotoIntakeRequest

    let consumedPayloadKeys:
        Set<String>

    let coordinator:
        ShareCoordinator

    func execute()
    async -> MemoMarkResult<
        ProcessedShareRequest
    > {

        await coordinator.process(
            request: request,
            consumedPayloadKeys:
                consumedPayloadKeys
        )
    }
}
#endif
