#if !MEMOMARK_SHARE_EXTENSION
import UniformTypeIdentifiers

enum BatchTaskMemoryPolicy {

    static func processingRoute(
        for task: BatchTask
    ) -> BatchTaskProcessingRoute {
        if PhotoProcessingInputPolicy
            .isLivePhotoContentType(
                task.contentTypeIdentifier.flatMap(UTType.init)
            ) {
            return .livePhoto
        }

        if LivePhotoSourceBundleLocator.canResolveBundle(
            at: task.sourceURL
        ) {
            return .livePhoto
        }

        return .staticImage
    }

    static func mediaMemoryBudget(
        for task: BatchTask
    ) -> MediaMemoryBudget {

        MediaMemoryBudget(
            cost: MediaCost(
                fileURL: task.sourceURL,
                contentTypeIdentifier:
                    task.contentTypeIdentifier
            )
        )
    }

    static func shouldUseLivePhotoProcessing(
        for task: BatchTask
    ) -> Bool {
        processingRoute(
            for: task
        ) == .livePhoto
    }

    static func staticImportContentTypeIdentifier(
        for task: BatchTask,
        usesLivePhotoProcessing: Bool
    ) -> String? {

        guard !usesLivePhotoProcessing else {
            return task.contentTypeIdentifier
        }

        guard PhotoProcessingInputPolicy
            .isLivePhotoContentType(
                task.contentTypeIdentifier.flatMap(UTType.init)
            ) else {
            return task.contentTypeIdentifier
        }

        return UTType(
            filenameExtension:
                task.sourceURL
                .pathExtension
                .lowercased()
        )?.identifier
    }

    static func shouldRejectUnavailableLivePhotoSource(
        for task: BatchTask
    ) -> Bool {
        guard processingRoute(for: task) == .livePhoto else {
            return false
        }

        return task.sourceIdentifier?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty != false
            && !LivePhotoSourceBundleLocator.canResolveBundle(
                at: task.sourceURL
            )
    }
}
#endif
