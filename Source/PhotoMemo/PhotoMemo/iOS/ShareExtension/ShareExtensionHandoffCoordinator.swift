#if os(iOS) && PHOTOMEMO_SHARE_EXTENSION
import UIKit

struct ShareExtensionHandoffRequest {
    let requestID: UUID?
}

enum ShareExtensionHandoffResult: Equatable {
    case openedThroughExtensionContext
    case openedThroughResponderChain
    case failed

    var opened: Bool {
        self != .failed
    }
}

@MainActor
final class ShareExtensionHandoffCoordinator {

    private let extensionContext: () -> NSExtensionContext?
    private let firstResponder: () -> UIResponder?

    init(
        extensionContext: @escaping () -> NSExtensionContext?,
        firstResponder: @escaping () -> UIResponder?
    ) {
        self.extensionContext = extensionContext
        self.firstResponder = firstResponder
    }

    func requestMainAppRefresh(
        _ request: ShareExtensionHandoffRequest
    ) async -> ShareExtensionHandoffResult {
        let deepLinkURL = PhotoMemoDeepLink.share.url
        let opened = await withCheckedContinuation {
            (continuation: CheckedContinuation<Bool, Never>) in
            guard let extensionContext = extensionContext() else {
                continuation.resume(returning: false)
                return
            }
            extensionContext.open(deepLinkURL) { success in
                continuation.resume(returning: success)
            }
        }

        PhotoMemoShareIntakeLog.notice(
            "Requested main-app refresh via deep link. success=\(opened)"
        )
        PhotoMemoShareDiagnostics.record(
            stage: .extensionHandoffPrimary,
            message: "extensionContext.open success=\(opened)"
        )

        if opened {
            return .openedThroughExtensionContext
        }

        let fallbackOpened = requestMainAppRefreshThroughResponderChain(
            deepLinkURL
        )
        PhotoMemoShareIntakeLog.notice(
            "Requested main-app refresh through responder chain. success=\(fallbackOpened)"
        )
        PhotoMemoShareDiagnostics.record(
            stage: .extensionHandoffFallback,
            message: "responderChain success=\(fallbackOpened)"
        )
        return fallbackOpened ? .openedThroughResponderChain : .failed
    }

    func waitForMainAppHandoffConfirmation(
        requestID: UUID?,
        source: String
    ) async -> Bool {
        guard let requestID else {
            PhotoMemoShareDiagnostics.record(
                stage: .extensionHandoffUnconfirmed,
                message: "\(source) opened, but no requestID was available."
            )
            return false
        }

        for _ in 0..<25 {
            if mainAppConsumedRequest(requestID) {
                PhotoMemoShareDiagnostics.record(
                    stage: .extensionHandoffConfirmed,
                    message: "\(source) confirmed request consumption.",
                    requestID: requestID
                )
                return true
            }
            try? await Task.sleep(nanoseconds: 200_000_000)
        }

        PhotoMemoShareDiagnostics.record(
            stage: .extensionHandoffUnconfirmed,
            message: "\(source) did not produce app drain/enqueue within timeout.",
            requestID: requestID
        )
        return false
    }

    func enqueuedJobID(for requestID: UUID) -> UUID? {
        PhotoMemoShareDiagnostics
            .loadEvents()
            .reversed()
            .first { event in
                event.requestID == requestID
                    && event.stage == .appEnqueueCreated
            }?
            .jobID
    }

    private func requestMainAppRefreshThroughResponderChain(
        _ url: URL
    ) -> Bool {
        let selector = NSSelectorFromString("openURL:")
        var responder = firstResponder()
        while let currentResponder = responder {
            if currentResponder.responds(to: selector) {
                currentResponder.perform(selector, with: url)
                return true
            }
            responder = currentResponder.next
        }
        return false
    }

    private func mainAppConsumedRequest(_ requestID: UUID) -> Bool {
        PhotoMemoShareDiagnostics.loadEvents().contains { event in
            guard event.requestID == requestID else {
                return false
            }
            switch event.stage {
            case .appEnqueueCreated,
                 .appEnqueueFailed,
                 .appRequestDropped:
                return true
            default:
                return false
            }
        }
    }
}
#endif
