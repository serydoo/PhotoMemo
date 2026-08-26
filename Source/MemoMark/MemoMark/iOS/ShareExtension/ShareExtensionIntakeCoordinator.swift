#if os(iOS) && MEMOMARK_SHARE_EXTENSION
import Foundation

struct ShareExtensionIntakeFailure {
    let title: String
    let message: String
    let suggestion: String
}

enum ShareExtensionIntakeCoordinatorResult {
    case received(MemoMarkShareExtensionImportResult)
    case handoffFailed(MemoMarkShareExtensionImportResult)
    case failed(ShareExtensionIntakeFailure)
}

@MainActor
final class ShareExtensionIntakeCoordinator {

    private let intakeService:
        MemoMarkShareExtensionIntakeService
    private let handoffCoordinator:
        ShareExtensionHandoffCoordinator

    init(
        intakeService: MemoMarkShareExtensionIntakeService,
        handoffCoordinator: ShareExtensionHandoffCoordinator
    ) {
        self.intakeService = intakeService
        self.handoffCoordinator = handoffCoordinator
    }

    func persistIncomingItems(
        _ inputItems: [NSExtensionItem],
        onIntakeStarted:
            @escaping @MainActor () -> Void,
        onPersisted:
            @escaping @MainActor (
                MemoMarkShareExtensionImportResult
            ) -> Void
    ) async -> ShareExtensionIntakeCoordinatorResult {
        MemoMarkShareDiagnostics.reset(
            reason: "Share confirmation started"
        )

        guard !inputItems.isEmpty else {
            MemoMarkShareIntakeLog.error(
                "persistIncomingItems failed before intake: inputItems was empty."
            )
            MemoMarkShareDiagnostics.record(
                stage: .extensionInputEmpty,
                message: "No NSExtensionItem was available."
            )
            return .failed(
                ShareExtensionIntakeFailure(
                    title: localized(
                        "share.error.unexpected.title",
                        fallback: "This Share Did Not Finish"
                    ),
                    message: localized(
                        "share.error.unexpected.message",
                        fallback: "MemoMark could not receive this share."
                    ),
                    suggestion: localized(
                        "share.error.unexpected.recovery",
                        fallback: "Return to Apple Photos and share again."
                    )
                )
            )
        }

        onIntakeStarted()

        do {
            let result = try await intakeService
                .persistSharedItems(inputItems)

            MemoMarkShareDiagnostics.record(
                stage: .extensionPersisted,
                message:
                    "imported=\(result.importedCount), requested=\(result.requestedCount), skipped=\(result.skippedCount), failed=\(result.failedCount), livePhotoStaticFallback=\(result.livePhotoStaticFallbackCount)"
            )
            onPersisted(result)
            let backgroundRequestSubmitted =
                MemoMarkBackgroundTaskSubmission.submit()
            let hostAppRequiresPhotoAuthorization =
                MemoMarkBackgroundTaskSubmission
                .requiresHostAppForPhotoAuthorization
            guard !backgroundRequestSubmitted
                    || hostAppRequiresPhotoAuthorization
            else {
                return .received(result)
            }

            let fallbackReason =
                hostAppRequiresPhotoAuthorization
                ? "Host app requires Apple Photos authorization"
                : "Background scheduling failed"
            MemoMarkShareDiagnostics.record(
                stage: .extensionHandoffRequested,
                message:
                    "\(fallbackReason); requesting host app fallback.",
                requestID: result.requestID
            )
            let fallbackHandoff =
                await handoffCoordinator.requestMainAppRefresh()
            guard fallbackHandoff.opened else {
                MemoMarkShareDiagnostics.record(
                    stage: .extensionHandoffFailed,
                    message:
                        "Task is durably queued; host app handoff was unavailable.",
                    requestID: result.requestID
                )
                return .handoffFailed(result)
            }
            return .received(result)
        } catch let shareError as MemoMarkShareExtensionError {
            MemoMarkShareIntakeLog.error(
                "Share extension caught a categorized intake error."
            )
            MemoMarkShareDiagnostics.record(
                stage: .extensionError,
                message: "categorizedIntakeError=true"
            )
            return .failed(
                ShareExtensionIntakeFailure(
                    title: shareError.localizedFailureTitle(
                        for: .interfaceStored
                    ),
                    message: detailedFailureMessage(
                        for: shareError
                    ),
                    suggestion: detailedSuggestion(
                        for: shareError
                    )
                )
            )
        } catch {
            let nsError = error as NSError
            MemoMarkShareIntakeLog.error(
                "Share extension caught an unexpected intake error. domain=\(nsError.domain), code=\(nsError.code)"
            )
            MemoMarkShareDiagnostics.record(
                stage: .extensionErrorUnexpected,
                message: "domain=\(nsError.domain), code=\(nsError.code)"
            )
            return .failed(
                ShareExtensionIntakeFailure(
                    title: localized(
                        "share.error.unexpected.title",
                        fallback: "This Share Did Not Finish"
                    ),
                    message: localized(
                        "share.error.unexpected.message",
                        fallback: "MemoMark could not receive this share."
                    ),
                    suggestion: localized(
                        "share.error.unexpected.recovery",
                        fallback: "Return to Apple Photos and share again."
                    )
                )
            )
        }
    }

    private func detailedFailureMessage(
        for error: MemoMarkShareExtensionError
    ) -> String {
        if let diagnosticSummary =
            error.diagnosticSummaryLine {
            MemoMarkShareIntakeLog.error(
                "User-facing intake failure detail: \(diagnosticSummary)"
            )
        }
        return error.localizedDescription(
            for: .interfaceStored
        )
    }

    private func detailedSuggestion(
        for error: MemoMarkShareExtensionError
    ) -> String {
        if let errorSummary =
            error.resolvedFailureContext?
            .errorSummary {
            MemoMarkShareIntakeLog.error(
                "Intake recovery context: \(errorSummary.domain) / \(errorSummary.code)"
            )
        }
        return error.localizedRecoverySuggestion(
            for: .interfaceStored
        )
    }

    private func localized(
        _ key: String,
        fallback: String
    ) -> String {
        MemoMarkLanguage.interfaceStored.localized(
            key: key,
            fallback: fallback
        )
    }
}
#endif
