#if os(iOS) && PHOTOMEMO_SHARE_EXTENSION
import UIKit

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

    func requestMainAppRefresh()
    async -> ShareExtensionHandoffResult {
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

}
#endif
