#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing

@Suite("Background processing contract")
struct BackgroundProcessingContractTests {

    @Test("iOS declares the batch processing task")
    func iOSDeclaresBatchProcessingTask() throws {
        let plist = try sourceText(
            "Source/MemoMark/MemoMarkiOS-Info.plist"
        )
        let coordinator = try sourceText(
            "Source/MemoMark/MemoMark/iOS/App/MemoMarkBackgroundTaskCoordinator.swift"
        )
        let submission = try sourceText(
            "Source/MemoMark/MemoMark/iOS/ShareExtension/MemoMarkBackgroundTaskSubmission.swift"
        )
        let worker = try sourceText(
            "Source/MemoMark/MemoMark/iOS/App/BackgroundBatchQueueWorker.swift"
        )
        let environment = try sourceText(
            "Source/MemoMark/MemoMark/Architecture/AppEnvironment.swift"
        )
        let permissionSurface = try sourceText(
            "Source/MemoMark/MemoMark/iOS/Views/MemoMarkiOSBackgroundStatusSheet.swift"
        )
        let runtime = try sourceText(
            "Source/MemoMark/MemoMark/App/MemoMarkAppRuntime.swift"
        )
        let executionService = try sourceText(
            "Source/MemoMark/MemoMark/iOS/App/MemoMarkiOSBackgroundExecutionService.swift"
        )

        #expect(plist.contains("BGTaskSchedulerPermittedIdentifiers"))
        #expect(plist.contains("com.serydoo.PhotoMemo.batch-processing"))
        #expect(plist.contains("<string>processing</string>"))
        #expect(coordinator.contains("BGTaskScheduler.shared.register"))
        #expect(submission.contains("BGProcessingTaskRequest"))
        #expect(coordinator.contains("setTaskCompleted"))
        #expect(coordinator.contains("BackgroundBatchQueueWorker"))
        #expect(!coordinator.contains("startProcessingIfNeeded"))
        #expect(worker.contains("runResultWithoutProcessing"))
        #expect(worker.contains("startProcessingIfNeeded"))
        #expect(worker.contains("stopProcessingForBackgroundExpiration"))
        #expect(submission.contains("BGTaskScheduler.shared.submit"))
        #expect(environment.contains("automaticallyStartsBatchProcessing = false"))
        #expect(permissionSurface.contains("允许照片访问"))
        #expect(permissionSurface.contains("authorizePhotoWorkflow"))
        #expect(permissionSurface.contains("允许完成提醒"))
        #expect(permissionSurface.contains("authorizeNotificationWorkflow"))
        #expect(runtime.contains("guard permissionCenter.canAccessPhotoLibrary"))
        #expect(executionService.contains("pendingTaskCount > 0"))
        #expect(executionService.contains("MemoMarkBackgroundTaskSubmission"))
        #expect(executionService.contains("stopProcessingForBackgroundExpiration"))
        #expect(executionService.contains("processing.background.expired"))
        #expect(executionService.contains("processingBackgroundExpired"))
    }

    @Test("Share completion does not depend on host app handoff")
    func shareCompletionDoesNotDependOnHostAppHandoff() throws {
        let coordinator = try sourceText(
            "Source/MemoMark/MemoMark/iOS/ShareExtension/ShareExtensionIntakeCoordinator.swift"
        )

        #expect(coordinator.contains("Task is durably queued"))
        #expect(coordinator.contains("return .received(result)"))
        #expect(coordinator.contains("return .handoffFailed(result)"))
        #expect(coordinator.contains("guard fallbackHandoff.opened else"))
        #expect(coordinator.contains("hostAppRequiresPhotoAuthorization"))
        #expect(coordinator.contains("|| hostAppRequiresPhotoAuthorization"))
        #expect(coordinator.contains("host app fallback"))

        let renderer = try sourceText(
            "Source/MemoMark/MemoMark/iOS/ShareExtension/ShareExtensionViewStateRenderer.swift"
        )
        #expect(renderer.contains("照片已经接收，需要打开时光记继续处理。"))

        let notificationService = try sourceText(
            "Source/MemoMark/MemoMark/Services/BatchNotificationService.swift"
        )
        #expect(notificationService.contains("didReceive response"))
        #expect(notificationService.contains("configureNotificationRoute"))
        #expect(notificationService.contains(".photoMemoNotificationOpened"))

        let root = try sourceText(
            "Source/MemoMark/MemoMark/App/MemoMarkRootSceneView.swift"
        )
        let statusService = try sourceText(
            "Source/MemoMark/MemoMark/App/MemoMarkBackgroundStatusService.swift"
        )
        #expect(root.contains("photoMemoNotificationOpened"))
        #expect(root.contains("pendingNotificationDeepLink"))
        #expect(statusService.contains("func focus(jobID: UUID)"))
    }
}

private extension BackgroundProcessingContractTests {

    var repositoryRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    func sourceText(_ relativePath: String) throws -> String {
        try String(
            contentsOf: repositoryRoot.appendingPathComponent(relativePath),
            encoding: .utf8
        )
    }
}
#endif
