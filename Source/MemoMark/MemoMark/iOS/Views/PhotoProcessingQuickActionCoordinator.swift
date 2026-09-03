#if !MEMOMARK_SHARE_EXTENSION
import Foundation

/// Coordinates the foreground photo-intake handoff without owning picker
/// resolution, request lifecycle, queue persistence, or export behavior.
enum PhotoProcessingQuickActionCoordinator {

    struct Result:
        Equatable {

        enum Status:
            Equatable {

            case configurationSaveFailed
            case noSupportedPhotos
            case submitted
        }

        let status: Status
        let submittedURLs: [URL]
        let submittedItems:
            [ExternalPhotoIntakeItem]
        let requestedCount: Int
        let failedCount: Int

        init(
            status: Status,
            submittedURLs: [URL],
            submittedItems:
                [ExternalPhotoIntakeItem] = [],
            requestedCount: Int? = nil
        ) {
            self.status = status
            self.submittedURLs =
                submittedURLs
            self.submittedItems =
                submittedItems
            self.requestedCount = requestedCount ?? submittedItems.count
            self.failedCount = max(
                0,
                (requestedCount ?? submittedItems.count)
                    - submittedItems.count
            )
        }
    }

    static func processPickedPhotos(
        saveCurrentConfiguration: () async -> Bool,
        importURLs: () async -> [URL],
        submit: ([URL]) -> Void
    ) async -> Result {
        guard await saveCurrentConfiguration() else {
            return Result(
                status: .configurationSaveFailed,
                submittedURLs: []
            )
        }

        let resolvedURLs =
            await importURLs()

        guard !resolvedURLs.isEmpty else {
            return Result(
                status: .noSupportedPhotos,
                submittedURLs: []
            )
        }

        submit(resolvedURLs)

        return Result(
            status: .submitted,
            submittedURLs: resolvedURLs
        )
    }

    static func processPickedPhotoItems(
        saveCurrentConfiguration: () async -> Bool,
        requestedCount: Int = 0,
        importItems:
            () async -> [ExternalPhotoIntakeItem],
        submit: ([ExternalPhotoIntakeItem]) -> Void
    ) async -> Result {
        guard await saveCurrentConfiguration() else {
            return Result(
                status: .configurationSaveFailed,
                submittedURLs: [],
                requestedCount: requestedCount
            )
        }

        let resolvedItems =
            await importItems()

        guard !resolvedItems.isEmpty else {
            return Result(
                status: .noSupportedPhotos,
                submittedURLs: [],
                requestedCount: requestedCount
            )
        }

        submit(resolvedItems)

        return Result(
            status: .submitted,
            submittedURLs:
                resolvedItems.map(
                    \.managedURL
                ),
            submittedItems:
                resolvedItems,
            requestedCount: max(requestedCount, resolvedItems.count)
        )
    }

    /// Saves the visible configuration and returns the exact immutable
    /// snapshot that must travel with this intake request. The photo picker
    /// import is asynchronous, so reading a mutable default configuration
    /// after import would otherwise allow a later edit to change the task
    /// that the user already confirmed.
    static func processPickedPhotoItems(
        saveCurrentConfiguration:
            () async -> BatchConfigurationSnapshot?,
        requestedCount: Int = 0,
        importItems:
            () async -> [ExternalPhotoIntakeItem],
        submit:
            ([ExternalPhotoIntakeItem], BatchConfigurationSnapshot) -> Void
    ) async -> Result {
        guard let configuration =
                await saveCurrentConfiguration() else {
            return Result(
                status: .configurationSaveFailed,
                submittedURLs: [],
                requestedCount: requestedCount
            )
        }

        let resolvedItems = await importItems()

        guard !resolvedItems.isEmpty else {
            return Result(
                status: .noSupportedPhotos,
                submittedURLs: [],
                requestedCount: requestedCount
            )
        }

        submit(resolvedItems, configuration)

        return Result(
            status: .submitted,
            submittedURLs: resolvedItems.map(\.managedURL),
            submittedItems: resolvedItems,
            requestedCount: max(requestedCount, resolvedItems.count)
        )
    }
}
#endif
