#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI
import UIKit
import Combine

@MainActor
final class PhotoMemoiOSBackgroundExecutionService {

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
           batchQueueStore.pendingTaskCount > 0 {
            _ = PhotoMemoBackgroundTaskSubmission
                .submit()
        }
        reconcileBackgroundExecution()
    }
}

private extension PhotoMemoiOSBackgroundExecutionService {

    func bind() {

        batchQueueStore.$isProcessing
            .sink { [weak self] _ in
                self?
                    .reconcileBackgroundExecution()
            }
            .store(in: &cancellables)
    }

    func reconcileBackgroundExecution() {

        let shouldHoldBackgroundTime =
            batchQueueStore.isProcessing
            && scenePhase == .background

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

        backgroundTaskID =
            UIApplication.shared
            .beginBackgroundTask(
                withName:
                    "MemoMarkBatchProcessing"
            ) { [weak self] in
                Task { @MainActor in
                    self?
                        .handleBackgroundTimeExpiration()
                }
            }
    }

    func handleBackgroundTimeExpiration() {
        batchQueueStore
            .stopProcessingForBackgroundExpiration()
        _ = PhotoMemoBackgroundTaskSubmission
            .submit()
        PhotoMemoShareDiagnostics.record(
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
