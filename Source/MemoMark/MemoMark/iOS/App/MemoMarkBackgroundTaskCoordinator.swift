#if os(iOS)
import BackgroundTasks
import Foundation

#if !MEMOMARK_SHARE_EXTENSION
@MainActor
final class MemoMarkBackgroundTaskCoordinator {

    static let taskIdentifier = MemoMarkBackgroundTaskSubmission.taskIdentifier
    private static var didRegister = false
    private static var didRegisterContinued = false

    private let worker: BackgroundBatchQueueWorker

    init(
        queueRuntime: any BackgroundQueueRuntime,
        prepareQueue: @escaping @MainActor () async -> BackgroundQueuePreparationResult
    ) {
        self.worker = BackgroundBatchQueueWorker(
            queueRuntime: queueRuntime,
            prepareQueue: prepareQueue
        )
    }

    func register() {
        if #available(iOS 26.0, *) { registerContinuedProcessing() }
        guard !Self.didRegister else {
            return
        }
        Self.didRegister = BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.taskIdentifier,
            using: nil
        ) { [weak self] task in
            guard let processingTask = task as? BGProcessingTask else {
                task.setTaskCompleted(success: false)
                return
            }
            Task { @MainActor in
                guard let self else {
                    processingTask.setTaskCompleted(
                        success: false
                    )
                    return
                }
                await self.handle(processingTask)
            }
        }
    }

    /// The production-capable host handler is registered separately from the
    /// development extension experiment. Submission remains gated by device certification.
    @available(iOS 26.0, *)
    func registerContinuedProcessing() {
        guard !Self.didRegisterContinued else { return }
        Self.didRegisterContinued = BGTaskScheduler.shared.register(
            forTaskWithIdentifier: MemoMarkBackgroundTaskSubmission.continuedTaskIdentifier, using: nil
        ) { [weak self] task in
            guard let continued = task as? BGContinuedProcessingTask else {
                task.setTaskCompleted(success: false)
                return
            }
            Task { @MainActor in
                guard let self else { continued.setTaskCompleted(success: false); return }
                await self.handleContinued(continued)
            }
        }
#if DEBUG
        MemoMarkBackgroundProbe.record("host.continuedQueueRegistration",
            detail: "accepted=\(Self.didRegisterContinued);identifier=\(MemoMarkBackgroundTaskSubmission.continuedTaskIdentifier)")
        if Self.didRegisterContinued,
           ProcessInfo.processInfo.arguments.contains("-uiTesting"),
           (ProcessInfo.processInfo.arguments.contains("-continuedFormalHostForegroundControl")
            || ProcessInfo.processInfo.arguments.contains("-continuedHostUniqueQueueProbe")) {
            var controlIdentifier = MemoMarkBackgroundTaskSubmission.continuedTaskIdentifier
            if ProcessInfo.processInfo.arguments.contains("-continuedFormalHostUniqueIdentifierControl")
                || ProcessInfo.processInfo.arguments.contains("-continuedHostUniqueQueueProbe") {
                controlIdentifier = "com.serydoo.PhotoMemo.iOS.continued-processing." + UUID().uuidString
                let accepted = BGTaskScheduler.shared.register(forTaskWithIdentifier: controlIdentifier, using: nil) { [weak self] task in
                    guard let continued = task as? BGContinuedProcessingTask else {
                        task.setTaskCompleted(success: false)
                        return
                    }
                    Task { @MainActor in
                        guard let self else { continued.setTaskCompleted(success: false); return }
                        await self.handleContinued(continued)
                    }
                }
                MemoMarkBackgroundProbe.record("host.continuedQueueControlRegistration",
                    detail: "accepted=\(accepted);identifier=\(controlIdentifier)")
                guard accepted else { return }
            }
            if ProcessInfo.processInfo.arguments.contains("-continuedHostUniqueQueueProbe") {
                let defaults = MemoMarkSharedContainer.sharedUserDefaults
                defaults.set(controlIdentifier, forKey: ContinuedProcessingSpike.hostQueueIdentifierKey)
                defaults.synchronize()
                return
            }
            let submittedIdentifier = controlIdentifier
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(2))
                do {
                    _ = try await ContinuedProcessingSubmission.submit(
                        identifier: submittedIdentifier,
                        title: "MemoMark", subtitle: "验证执行入口", immediate: true)
                    MemoMarkBackgroundProbe.record("host.continuedQueueSelfSubmission", detail: "accepted=true;identifier=\(submittedIdentifier)")
                } catch {
                    MemoMarkBackgroundProbe.record("host.continuedQueueSelfSubmission", detail: "accepted=false;error=\(error)")
                }
            }
        }
#endif
    }

    @available(iOS 26.0, *)
    private func handleContinued(_ task: BGContinuedProcessingTask) async {
#if DEBUG
        MemoMarkBackgroundProbe.record("host.continuedQueueCallback", detail: task.identifier)
#endif
        let runID = UUID()
        let defaults = MemoMarkSharedContainer.sharedUserDefaults
        var latestSession: ExecutionSession?
        ProcessingPresentationAuthority.renew(leaseID: runID, defaults: defaults)
        let heartbeat = Task { @MainActor in
            while !Task.isCancelled {
                do { try await Task.sleep(for: .seconds(5)) } catch { return }
                ProcessingPresentationAuthority.renew(leaseID: runID, defaults: defaults)
            }
        }
        defer {
            heartbeat.cancel()
            ProcessingPresentationAuthority.release(leaseID: runID, defaults: defaults)
        }
        let operation = Task { @MainActor in
            await worker.run(runID: runID, owner: .continuedProcessing) { session in
                latestSession = session
                guard let session else { return }
                task.progress.totalUnitCount = Int64(session.totalProgressUnits)
                task.progress.completedUnitCount = Int64(session.completedProgressUnits)
                let message = ContinuedProcessingMessageFormatter.message(for: session, language: .interfaceStored)
                task.updateTitle(message.title, subtitle: message.subtitle)
            }
        }
        task.expirationHandler = { [weak self] in
            operation.cancel()
            Task { @MainActor in await self?.worker.cancel(runID: runID) }
        }
        let result = await operation.value
        let succeeded = !operation.isCancelled && result.continuedTaskSucceeded(session: latestSession)
#if DEBUG
        MemoMarkBackgroundProbe.record("host.continuedQueueFinished", detail: "success=\(succeeded);result=\(result)")
#endif
        task.setTaskCompleted(success: succeeded)
        if result == .retryScheduled && !operation.isCancelled { scheduleIfNeeded() }
    }

    func scheduleIfNeeded() {
        _ = MemoMarkBackgroundTaskSubmission.submit()
    }

    private func handle(_ task: BGProcessingTask) async {
#if DEBUG
        MemoMarkBackgroundProbe.record("bgProcessing.callback")
#endif
        let runID = UUID()
        let operation = Task { @MainActor in await worker.run(runID: runID) }
        task.expirationHandler = { [weak self] in
            operation.cancel()
            Task { @MainActor in
                await self?.worker.cancel(runID: runID)
            }
        }

        let result = await operation.value
#if DEBUG
        MemoMarkBackgroundProbe.record("bgProcessing.finished", detail: String(describing: result))
#endif
        if result == .retryScheduled {
            scheduleIfNeeded()
        }
        complete(task, with: result)
    }

    private func complete(
        _ task: BGProcessingTask,
        with result: BackgroundQueueRunResult
    ) {
        task.setTaskCompleted(
            success: result.systemTaskSucceeded
        )
    }

}
#endif
#endif
