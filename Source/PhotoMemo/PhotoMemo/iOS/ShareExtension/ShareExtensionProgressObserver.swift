#if os(iOS) && PHOTOMEMO_SHARE_EXTENSION
import Foundation

enum ShareExtensionProgressObserverUpdate {
    case waitingForQueue(photoCount: Int)
    case snapshot(SharedBatchJobSnapshot)
    case waitingForApp(photoCount: Int)
    case finished(SharedBatchJobSnapshot?)
}

enum ShareExtensionIntakeDiagnosticUpdate {
    case preparingSource
    case sourceReady
}

@MainActor
final class ShareExtensionProgressObserver {

    private let batchSnapshotService: SharedBatchQueueSnapshotService
    private let enqueuedJobID: (UUID) -> UUID?
    private var intakeDiagnosticTask: Task<Void, Never>?

    init(
        batchSnapshotService: SharedBatchQueueSnapshotService,
        enqueuedJobID: @escaping (UUID) -> UUID?
    ) {
        self.batchSnapshotService = batchSnapshotService
        self.enqueuedJobID = enqueuedJobID
    }

    func observe(
        requestID: UUID,
        fallbackPhotoCount: Int,
        onUpdate: @escaping @MainActor (ShareExtensionProgressObserverUpdate) -> Void
    ) async {
        let startedAt = Date()
        var latestSnapshot: SharedBatchJobSnapshot?

        repeat {
            if let jobID = enqueuedJobID(requestID),
               let snapshot = batchSnapshotService.loadSnapshot(for: jobID) {
                latestSnapshot = snapshot
                onUpdate(.snapshot(snapshot))
                if snapshot.isTerminal {
                    break
                }
            } else {
                onUpdate(.waitingForQueue(photoCount: fallbackPhotoCount))
            }

            try? await Task.sleep(nanoseconds: 250_000_000)
        } while Date().timeIntervalSince(startedAt) < 3.5

        if let latestSnapshot {
            onUpdate(.snapshot(latestSnapshot))
            if !latestSnapshot.isTerminal {
                onUpdate(.finished(latestSnapshot))
            }
        } else {
            onUpdate(.waitingForApp(photoCount: fallbackPhotoCount))
            onUpdate(.finished(nil))
            return
        }

        onUpdate(.finished(latestSnapshot))
    }

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
                try? await Task.sleep(nanoseconds: 180_000_000)
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
