#if os(iOS) && PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct ShareExtensionIntakeFailure {
    let title: String
    let message: String
    let suggestion: String
}

enum ShareExtensionIntakeCoordinatorResult {
    case received(PhotoMemoShareExtensionImportResult)
    case handoffFailed(PhotoMemoShareExtensionImportResult)
    case failed(ShareExtensionIntakeFailure)
}

@MainActor
final class ShareExtensionIntakeCoordinator {

    private let intakeService:
        PhotoMemoShareExtensionIntakeService
    private let handoffCoordinator:
        ShareExtensionHandoffCoordinator

    init(
        intakeService: PhotoMemoShareExtensionIntakeService,
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
                PhotoMemoShareExtensionImportResult
            ) -> Void
    ) async -> ShareExtensionIntakeCoordinatorResult {
        PhotoMemoShareDiagnostics.reset(
            reason: "Share confirmation started"
        )

        guard !inputItems.isEmpty else {
            PhotoMemoShareIntakeLog.error(
                "persistIncomingItems failed before intake: inputItems was empty."
            )
            PhotoMemoShareDiagnostics.record(
                stage: .extensionInputEmpty,
                message: "No NSExtensionItem was available."
            )
            return .failed(
                ShareExtensionIntakeFailure(
                    title: "无法读取这次分享",
                    message: "时光记没有收到这次分享的原始内容。",
                    suggestion:
                        "请返回系统相册重新分享；如果重复出现，请打开时光记检查默认风格后再试。"
                )
            )
        }

        onIntakeStarted()

        do {
            let result = try await intakeService
                .persistSharedItems(inputItems)

            PhotoMemoShareDiagnostics.record(
                stage: .extensionPersisted,
                message:
                    "imported=\(result.importedCount), requested=\(result.requestedCount), skipped=\(result.skippedCount), failed=\(result.failedCount), livePhotoStaticFallback=\(result.livePhotoStaticFallbackCount)"
            )
            onPersisted(result)
            let backgroundRequestSubmitted =
                PhotoMemoBackgroundTaskSubmission.submit()
            let hostAppRequiresPhotoAuthorization =
                PhotoMemoBackgroundTaskSubmission
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
            PhotoMemoShareDiagnostics.record(
                stage: .extensionHandoffRequested,
                message:
                    "\(fallbackReason); requesting host app fallback.",
                requestID: result.requestID
            )
            let fallbackHandoff =
                await handoffCoordinator.requestMainAppRefresh()
            if !fallbackHandoff.opened {
                PhotoMemoShareDiagnostics.record(
                    stage: .extensionHandoffFailed,
                    message:
                        "Task is durably queued; host app handoff was unavailable.",
                    requestID: result.requestID
                )
            }
            return .received(result)
        } catch let shareError as PhotoMemoShareExtensionError {
            PhotoMemoShareIntakeLog.error(
                "Share extension caught PhotoMemoShareExtensionError.\n\(shareError.diagnosticsDescription ?? "no diagnostics")"
            )
            PhotoMemoShareDiagnostics.record(
                stage: .extensionError,
                message:
                    shareError.errorDescription
                    ?? shareError.failureTitle
            )
            return .failed(
                ShareExtensionIntakeFailure(
                    title: shareError.failureTitle,
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
            PhotoMemoShareIntakeLog.error(
                """
                Share extension caught unexpected error.
                localizedDescription: \(nsError.localizedDescription)
                domain: \(nsError.domain)
                code: \(nsError.code)
                underlyingError: \(((nsError.userInfo[NSUnderlyingErrorKey] as? NSError)?.localizedDescription) ?? "nil")
                """
            )
            PhotoMemoShareDiagnostics.record(
                stage: .extensionErrorUnexpected,
                message:
                    "\(nsError.domain) / \(nsError.code): \(nsError.localizedDescription)"
            )
            return .failed(
                ShareExtensionIntakeFailure(
                    title: "这次分享没有完成",
                    message:
                        (error as? LocalizedError)?
                        .errorDescription
                        ?? "无法把内容交给时光记。",
                    suggestion:
                        "请先返回系统相册重新分享；如果仍失败，请打开时光记检查默认风格和系统相册权限。"
                )
            )
        }
    }

    private func detailedFailureMessage(
        for error: PhotoMemoShareExtensionError
    ) -> String {
        if let diagnosticSummary =
            error.diagnosticSummaryLine {
            return "\(error.errorDescription ?? "这次分享没有完成。")\n\n\(diagnosticSummary)"
        }
        return error.errorDescription
            ?? "这次分享没有完成。"
    }

    private func detailedSuggestion(
        for error: PhotoMemoShareExtensionError
    ) -> String {
        if let errorSummary =
            error.resolvedFailureContext?
            .errorSummary {
            return "\(error.recoverySuggestion)\n\nNSError: \(errorSummary.domain) / \(errorSummary.code)"
        }
        return error.recoverySuggestion
    }
}
#endif
