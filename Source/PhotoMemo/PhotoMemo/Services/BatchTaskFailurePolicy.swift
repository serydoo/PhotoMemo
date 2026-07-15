#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

enum BatchTaskFailurePolicy {

    static func failureClassification(
        for error: Error
    ) -> BatchTaskFailure.Classification {

        if let importError = error as? PhotoImportError {
            switch importError {
            case .unsupportedInput:
                return .unsupportedInput
            case .imageLoadFailed,
                 .temporaryImportPreparationFailed:
                return .interrupted
            case .rawDisplayRenderFailed:
                return .processingFailure
            }
        }

        return .processingFailure
    }

    static func canRetryTaskAfterFailure(
        sourceURL: URL,
        fileManager: FileManager = .default
    ) -> Bool {

        if isManagedIntakeSourceURL(sourceURL) {
            return fileManager.fileExists(
                atPath: sourceURL.standardizedFileURL.path
            )
        }

        return true
    }

    static func shouldAbortFurtherProcessing(
        currentPhase: BatchTaskPhase?
    ) -> Bool {

        guard let currentPhase else {
            return true
        }

        return currentPhase.isTerminal
    }

    static func shouldIgnoreErrorBecauseTaskEnded(
        currentPhase: BatchTaskPhase?
    ) -> Bool {

        guard let currentPhase else {
            return true
        }

        return currentPhase.isTerminal
    }

    static func isManagedIntakeSourceURL(
        _ url: URL
    ) -> Bool {

        url.standardizedFileURL.path.hasPrefix(
            PhotoMemoSharedContainer
            .externalIntakeDirectoryURL
            .standardizedFileURL
            .path
        )
    }
}
#endif
