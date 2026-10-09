#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI
import UIKit
import Combine

@MainActor
final class MemoMarkiOSBackgroundExecutionService {

    private let batchQueueStore:
        BatchQueueStore

    private let productionDiagnostics:
        ProductionDiagnosticsRepository

    private var scenePhase:
        ScenePhase = .active

    private var backgroundTaskID:
        UIBackgroundTaskIdentifier = .invalid

    private var cancellables:
        Set<AnyCancellable> = []

    init(
        batchQueueStore: BatchQueueStore,
        productionDiagnostics:
            ProductionDiagnosticsRepository
    ) {
        self.batchQueueStore =
            batchQueueStore
        self.productionDiagnostics =
            productionDiagnostics

        bind()
    }

    func scenePhaseDidChange(
        _ newPhase: ScenePhase
    ) {

        scenePhase = newPhase
        if newPhase == .background,
           !batchQueueStore.processingPaused,
           batchQueueStore.executablePendingTaskCount > 0 {
            _ = MemoMarkBackgroundTaskSubmission
                .submit()
        }
        if newPhase == .active {
            _ = batchQueueStore.transitionForegroundExecution(to: .foreground)
        }
        reconcileBackgroundExecution()
    }
}

private extension MemoMarkiOSBackgroundExecutionService {

    func bind() {
        batchQueueStore.$executionLease.sink { [weak self] _ in
            Task { @MainActor in self?.reconcileBackgroundExecution() }
        }.store(in: &cancellables)

        batchQueueStore.$isProcessing
            .sink { [weak self] _ in
                self?
                    .reconcileBackgroundExecution()
            }
            .store(in: &cancellables)
    }

    func reconcileBackgroundExecution() {

        let shouldHoldBackgroundTime =
            batchQueueStore.executionLease != nil
            && scenePhase == .background
            && (batchQueueStore.executionLease?.owner == .foreground
                || batchQueueStore.executionLease?.owner == .backgroundGrace)

        if shouldHoldBackgroundTime {
            beginBackgroundTaskIfNeeded()
        } else {
            endBackgroundTaskIfNeeded()
        }
    }

    func beginBackgroundTaskIfNeeded() {

        guard backgroundTaskID == .invalid else {
            return
        }

        guard let lease = batchQueueStore.transitionForegroundExecution(to: .backgroundGrace) else { return }
        backgroundTaskID =
            UIApplication.shared
            .beginBackgroundTask(
                withName:
                    "MemoMarkBatchProcessing"
            ) { [weak self] in
                Task { @MainActor in
                    await self?
                        .handleBackgroundTimeExpiration(lease: lease)
                }
            }
    }

    func handleBackgroundTimeExpiration(lease: ExecutionLease) async {
        guard batchQueueStore.executionLease == lease else { return }
        await batchQueueStore
            .stopProcessingForBackgroundExpiration(lease: lease)
        if batchQueueStore.executablePendingTaskCount > 0 {
            _ = MemoMarkBackgroundTaskSubmission.submit()
        }
        MemoMarkShareDiagnostics.record(
            stage: .appBackgroundTimeExpired,
            message:
                "pendingTasks=\(batchQueueStore.pendingTaskCount)"
        )

        let operationID = UUID()
        let pendingTaskCount =
            batchQueueStore.pendingTaskCount
        Task {
            await productionDiagnostics.record(
                ProductionDiagnosticEvent(
                    operationID: operationID,
                    category: .processing,
                    stage:
                        "processing.background.expired",
                    outcome: .cancelled,
                    errorCode:
                        .processingBackgroundExpired,
                    context:
                        ProductionDiagnosticContext(
                            itemCount:
                                pendingTaskCount
                        )
                )
            )
        }
        endBackgroundTaskIfNeeded()
    }

    func endBackgroundTaskIfNeeded() {

        guard backgroundTaskID != .invalid else {
            return
        }

        UIApplication.shared
            .endBackgroundTask(
                backgroundTaskID
            )
        backgroundTaskID = .invalid
    }
}
#endif
