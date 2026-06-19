#if os(iOS) && PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct PhotoMemoShareExtensionImportResult {

    let importedCount: Int

    let skippedCount: Int

    let failedCount: Int

    var hasWarnings: Bool {
        skippedCount > 0 || failedCount > 0
    }
}
#endif
