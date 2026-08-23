#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

enum BatchTaskFailurePolicy {

    static func shouldResumeAfterCancellation(
        error: Error,
        taskIsCancelled: Bool
    ) -> Bool {

        taskIsCancelled || error is CancellationError
    }

    static func shouldAwaitPhotoLibraryReadback(
        error: Error
    ) -> Bool {
        if let exportError =
            error as? PhotoLibraryExportError {
            if case .savedAssetReadbackPending =
                exportError {
                return true
            }
            return false
        }

        if let livePhotoError =
            error as? LivePhotoAssetWritingError {
            switch livePhotoError {
            case .savedAssetReadbackPending,
                 .savedAssetReadbackFailed:
                return true
            default:
                return false
            }
        }

        return (error as? PhotoMemoError)?
            .diagnosticCode
            == ProductionDiagnosticErrorCode
            .photoLibraryAssetReadbackPending
            .rawValue
    }

    static func failureClassification(
        for error: Error
    ) -> BatchTaskFailure.Classification {

        if let importError = error as? PhotoImportError {
            switch importError {
            case .unsupportedInput:
                return .unsupportedInput
            case .imageLoadFailed,
                 .sourceMissing,
                 .sourceUnreadable,
                 .cloudDownloadTimedOut,
                 .temporaryImportPreparationFailed:
                return .interrupted
            case .rawDisplayRenderFailed:
                return .processingFailure
            }
        }

        if let photoMemoError = error as? PhotoMemoError,
           let diagnosticCode = photoMemoError.diagnosticCode {
            if diagnosticCode == ProductionDiagnosticErrorCode
                .processingBackgroundExpired
                .rawValue {
                return .interrupted
            }
            if PhotoProcessingInputPolicy.RejectionReason(
                rawValue: diagnosticCode
            ) != nil {
                return .unsupportedInput
            }
            if [
                "imageLoadFailed",
                "sourceMissing",
                "sourceUnreadable",
                "cloudDownloadTimedOut",
                "temporaryImportPreparationFailed"
            ].contains(diagnosticCode) {
                return .interrupted
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
