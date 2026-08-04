#if !PHOTOMEMO_SHARE_EXTENSION
import UniformTypeIdentifiers

enum BatchTaskMemoryPolicy {

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

        if PhotoProcessingInputPolicy
            .canUseLivePhotoProcessing(
                contentTypeIdentifier:
                    task.contentTypeIdentifier,
                sourceIdentifier:
                    task.sourceIdentifier
            ) {
            return true
        }

        guard PhotoProcessingInputPolicy
            .isLivePhotoContentType(
                task
                    .contentTypeIdentifier
                    .flatMap(UTType.init)
            ) else {
            return false
        }

        return LivePhotoSourceBundleLocator
            .canResolveBundle(
                at: task.sourceURL
            )
    }

    static func staticImportContentTypeIdentifier(
        for task: BatchTask,
        usesLivePhotoProcessing: Bool
    ) -> String? {

        guard !usesLivePhotoProcessing,
              PhotoProcessingInputPolicy
              .isLivePhotoContentType(
                  task
                      .contentTypeIdentifier
                      .flatMap(UTType.init)
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

    static func shouldRejectUnavailableLivePhotoMotion(
        for task: BatchTask,
        usesLivePhotoProcessing: Bool,
        outputMode: V1MediaOutputMode
    ) -> Bool {

        outputMode == .originalFormat
            && !usesLivePhotoProcessing
            && PhotoProcessingInputPolicy
            .isLivePhotoContentType(
                task
                    .contentTypeIdentifier
                    .flatMap(UTType.init)
            )
    }
}
#endif
