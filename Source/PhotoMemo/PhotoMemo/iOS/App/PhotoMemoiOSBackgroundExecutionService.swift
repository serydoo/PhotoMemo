#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI
import UIKit
import Combine

@MainActor
final class PhotoMemoiOSBackgroundExecutionService {

    private let batchQueueStore:
        BatchQueueStore

    private var scenePhase:
        ScenePhase = .active

    private var backgroundTaskID:
        UIBackgroundTaskIdentifier = .invalid

    private var cancellables:
        Set<AnyCancellable> = []

    init(
        batchQueueStore: BatchQueueStore
    ) {
        self.batchQueueStore =
            batchQueueStore

        bind()
    }

    func scenePhaseDidChange(
        _ newPhase: ScenePhase
    ) {

        scenePhase = newPhase
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
                        .endBackgroundTaskIfNeeded()
                }
            }
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
