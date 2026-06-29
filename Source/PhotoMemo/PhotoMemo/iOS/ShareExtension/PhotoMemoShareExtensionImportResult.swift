#if os(iOS) && PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct PhotoMemoShareExtensionImportResult {

    let requestID: UUID

    let itemProviderCount: Int

    let supportedProviderCount: Int

    let requestedCount: Int

    let summary:
        ExternalPhotoImportSummary

    let failureStage:
        PhotoMemoShareIntakeFailureStage?

    let failureContext:
        PhotoMemoShareIntakeFailureContext?

    var importedCount: Int {
        summary.importedCount
    }

    var skippedCount: Int {
        summary.skippedCount
    }

    var failedCount: Int {
        summary.failedCount
    }

    var hasWarnings: Bool {
        summary.hasWarnings
    }
}
#endif
