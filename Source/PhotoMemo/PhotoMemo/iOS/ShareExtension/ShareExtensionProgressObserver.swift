#if os(iOS) && PHOTOMEMO_SHARE_EXTENSION
import Foundation

enum ShareExtensionIntakeDiagnosticUpdate {
    case preparingSource
    case sourceReady
}

@MainActor
final class ShareExtensionProgressObserver {

    private var intakeDiagnosticTask: Task<Void, Never>?

    func startIntakeDiagnosticMonitoring(
        onUpdate: @escaping @MainActor (ShareExtensionIntakeDiagnosticUpdate) -> Void
    ) {
        stopIntakeDiagnosticMonitoring()
        intakeDiagnosticTask = Task { @MainActor [weak self] in
            for _ in 0..<40 {
                guard let self, !Task.isCancelled else {
                    return
                }
                if let update = self.latestIntakeDiagnosticUpdate() {
                    onUpdate(update)
                }
                do {
                    try await Task.sleep(
                        nanoseconds: 180_000_000
                    )
                } catch {
                    return
                }
            }
        }
    }

    func stopIntakeDiagnosticMonitoring() {
        intakeDiagnosticTask?.cancel()
        intakeDiagnosticTask = nil
    }

    private func latestIntakeDiagnosticUpdate()
    -> ShareExtensionIntakeDiagnosticUpdate? {
        let events = PhotoMemoShareDiagnostics.loadEvents()
        if events.contains(where: {
            $0.stage == .extensionSourcePrepare
        }), !events.contains(where: {
            $0.stage == .extensionSourceReady
        }) {
            return .preparingSource
        }
        if events.contains(where: {
            $0.stage == .extensionSourceReady
        }) {
            return .sourceReady
        }
        return nil
    }
}
#endif
