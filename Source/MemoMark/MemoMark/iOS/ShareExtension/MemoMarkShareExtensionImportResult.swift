#if os(iOS) && MEMOMARK_SHARE_EXTENSION
import Foundation

struct MemoMarkShareExtensionImportResult {

    let requestID: UUID

    let itemProviderCount: Int

    let supportedProviderCount: Int

    let requestedCount: Int

    let summary:
        ExternalPhotoImportSummary

    let failureStage:
        MemoMarkShareIntakeFailureStage?

    let failureContext:
        MemoMarkShareIntakeFailureContext?

    let unsupportedRejectionReports:
        [MemoMarkMediaIntakeRejectionReport]

    let livePhotoStaticFallbackCount:
        Int

    init(
        requestID: UUID,
        itemProviderCount: Int,
        supportedProviderCount: Int,
        requestedCount: Int,
        summary: ExternalPhotoImportSummary,
        failureStage:
            MemoMarkShareIntakeFailureStage?,
        failureContext:
            MemoMarkShareIntakeFailureContext?,
        unsupportedRejectionReports:
            [MemoMarkMediaIntakeRejectionReport] = [],
        livePhotoStaticFallbackCount:
            Int = 0
    ) {
        self.requestID =
            requestID
        self.itemProviderCount =
            itemProviderCount
        self.supportedProviderCount =
            supportedProviderCount
        self.requestedCount =
            requestedCount
        self.summary =
            summary
        self.failureStage =
            failureStage
        self.failureContext =
            failureContext
        self.unsupportedRejectionReports =
            unsupportedRejectionReports
        self.livePhotoStaticFallbackCount =
            livePhotoStaticFallbackCount
    }

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
        || livePhotoStaticFallbackCount > 0
    }

    var firstUnsupportedRejectionReport:
        MemoMarkMediaIntakeRejectionReport? {

        unsupportedRejectionReports.first
    }
}
#endif
