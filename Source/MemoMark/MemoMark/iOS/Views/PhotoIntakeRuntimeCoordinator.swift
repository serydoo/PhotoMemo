#if !MEMOMARK_SHARE_EXTENSION
import Foundation

/// Owns one active in-app picker intake lifecycle without owning picker
/// presentation, configuration truth, or the durable intake queue. A newer
/// request invalidates an older delayed import before it can submit or update
/// the root presentation state.
@MainActor
final class PhotoIntakeRuntimeCoordinator {

    private var activeRequestID: UUID?

    func perform(
        requestedCount: Int,
        saveCurrentConfiguration:
            () async -> BatchConfigurationSnapshot?,
        importItems:
            () async -> [ExternalPhotoIntakeItem],
        submit:
            ([ExternalPhotoIntakeItem], BatchConfigurationSnapshot) -> Void,
        discardUnsubmittedItems:
            ([ExternalPhotoIntakeItem]) -> Void = { _ in }
    ) async ->
        PhotoProcessingQuickActionCoordinator.Result? {

        let requestID = UUID()
        activeRequestID = requestID

        guard let configuration =
                await saveCurrentConfiguration() else {
            return finish(
                .init(
                    status: .configurationSaveFailed,
                    submittedURLs: [],
                    requestedCount: requestedCount
                ),
                requestID: requestID
            )
        }

        guard isCurrent(requestID) else {
            clearIfCurrentIdentity(requestID)
            return nil
        }

        let importedItems = await importItems()

        guard isCurrent(requestID) else {
            discardUnsubmittedItems(importedItems)
            clearIfCurrentIdentity(requestID)
            return nil
        }

        guard !importedItems.isEmpty else {
            return finish(
                .init(
                    status: .noSupportedPhotos,
                    submittedURLs: [],
                    requestedCount: requestedCount
                ),
                requestID: requestID
            )
        }

        submit(importedItems, configuration)

        return finish(
            .init(
                status: .submitted,
                submittedURLs:
                    importedItems.map(\.managedURL),
                submittedItems: importedItems,
                requestedCount:
                    max(requestedCount, importedItems.count)
            ),
            requestID: requestID
        )
    }

    func cancelActiveRequest() {
        activeRequestID = nil
    }

    private func isCurrent(_ requestID: UUID) -> Bool {
        activeRequestID == requestID
        && !Task.isCancelled
    }

    private func finish(
        _ result:
            PhotoProcessingQuickActionCoordinator.Result,
        requestID: UUID
    ) -> PhotoProcessingQuickActionCoordinator.Result? {
        guard isCurrent(requestID) else {
            clearIfCurrentIdentity(requestID)
            return nil
        }
        activeRequestID = nil
        return result
    }

    private func clearIfCurrentIdentity(_ requestID: UUID) {
        if activeRequestID == requestID {
            activeRequestID = nil
        }
    }
}
#endif
