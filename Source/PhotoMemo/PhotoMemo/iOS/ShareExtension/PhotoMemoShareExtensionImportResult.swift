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

    let unsupportedRejectionReports:
        [PhotoMemoMediaIntakeRejectionReport]

    let livePhotoStaticFallbackCount:
        Int

    init(
        requestID: UUID,
        itemProviderCount: Int,
        supportedProviderCount: Int,
        requestedCount: Int,
        summary: ExternalPhotoImportSummary,
        failureStage:
            PhotoMemoShareIntakeFailureStage?,
        failureContext:
            PhotoMemoShareIntakeFailureContext?,
        unsupportedRejectionReports:
            [PhotoMemoMediaIntakeRejectionReport] = [],
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
        PhotoMemoMediaIntakeRejectionReport? {

        unsupportedRejectionReports.first
    }
}
#endif
