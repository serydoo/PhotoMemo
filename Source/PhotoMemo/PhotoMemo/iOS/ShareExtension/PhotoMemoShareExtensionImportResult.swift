#if os(iOS) && PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct PhotoMemoShareExtensionImportResult {

    let summary:
        ExternalPhotoImportSummary

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
