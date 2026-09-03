#if !MEMOMARK_SHARE_EXTENSION
import Foundation

/// Semantic transitions accepted from a media task executor. This value is
/// deliberately independent of the application event payload so queue rules
/// remain deterministic and platform-free.
nonisolated enum BatchTaskExecutionTransition:
    Sendable {

    case startProcessing
    case recordMetadata
    case recordPreview
    case startExport
    case startPhotoLibrarySave
    case complete
    case awaitPhotoLibraryReadback
    case fail
    case disableRetry
}

nonisolated struct BatchTaskExecutionTransitionPolicy:
    Sendable {

    func canApply(
        _ transition: BatchTaskExecutionTransition,
        from phase: BatchTaskPhase
    ) -> Bool {
        switch transition {
        case .startProcessing:
            return phase == .queued

        case .recordMetadata:
            return phase == .importing

        case .recordPreview:
            return phase == .metadataReady

        case .startExport:
            // Static photos export after preview construction. Live Photos
            // enter their paired-resource processor directly after admission.
            return phase == .previewReady
                || phase == .waitingForExport
                || phase == .importing

        case .startPhotoLibrarySave:
            return phase == .exporting

        case .complete:
            // Live Photo processing owns its paired PhotoKit commit and emits
            // completion directly from exporting. Static photos expose the
            // intermediate save phase to support receipt reconciliation.
            return phase == .exporting
                || phase == .savingToPhotoLibrary

        case .awaitPhotoLibraryReadback:
            // An ambiguous commit can originate from either the static save
            // stage or the paired Live Photo transaction.
            return phase == .exporting
                || phase == .savingToPhotoLibrary

        case .fail:
            return phase.isPending

        case .disableRetry:
            return phase == .failed
        }
    }
}
#endif
