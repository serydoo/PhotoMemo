#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

@MainActor
final class BatchTaskDiagnosticsRecorder {

    private let defaults: UserDefaults

    init(
        defaults: UserDefaults =
            PhotoMemoSharedContainer.sharedUserDefaults
    ) {
        self.defaults = defaults
    }

    static func routeDiagnosticMessage(
        for task: BatchTask,
        sourceURLIsLivePhotoBundle: Bool,
        route: String
    ) -> String {
        [
            "taskID=\(task.id.uuidString)",
            "fileName=\(task.fileName)",
            "contentType=\(task.contentTypeIdentifier ?? "nil")",
            "hasSourceIdentifier=\(task.sourceIdentifier?.isEmpty == false)",
            "sourceURLIsLivePhotoBundle=\(sourceURLIsLivePhotoBundle)",
            "route=\(route)"
        ]
        .joined(separator: ", ")
    }

    static func admissionDiagnosticMessage(
        for task: BatchTask,
        budget: MediaMemoryBudget
    ) -> String {
        let pixelSize = budget.cost.pixelSize

        return [
            "taskID=\(task.id.uuidString)",
            "fileName=\(task.fileName)",
            "contentType=\(task.contentTypeIdentifier ?? "nil")",
            "isRAW=\(budget.cost.isRAW)",
            "pixelWidth=\(pixelSize?.width ?? 0)",
            "pixelHeight=\(pixelSize?.height ?? 0)",
            "pixelCount=\(budget.cost.pixelCount)",
            "estimatedDecodedByteCount=\(budget.cost.estimatedDecodedByteCount)",
            "memoryTier=\(budget.tier.rawValue)",
            "requiresExtendedPreviewPreparation=\(budget.requiresExtendedPreviewPreparation)",
            "maxConcurrentDecodes=\(budget.maxConcurrentDecodes)",
            "maxConcurrentRenders=\(budget.maxConcurrentRenders)",
            "maxConcurrentExports=\(budget.maxConcurrentExports)",
            "schedulerMode=singleTaskLoop",
            "admission=queued"
        ]
        .joined(separator: ", ")
    }

    func recordAdmissionDiagnostics(
        for job: BatchJob
    ) {
        for task in job.tasks {
            _ = PhotoMemoShareDiagnostics.recordResult(
                stage: .batchTaskAdmission,
                message: Self.admissionDiagnosticMessage(
                    for: task,
                    budget: BatchTaskMemoryPolicy.mediaMemoryBudget(for: task)
                ),
                jobID: job.id,
                defaults: defaults
            )
        }
    }

    func recordRoute(
        for task: BatchTask,
        sourceURLIsLivePhotoBundle: Bool,
        route: String,
        jobID: UUID?
    ) {
        PhotoMemoShareDiagnostics.record(
            stage: .batchTaskRoute,
            message: Self.routeDiagnosticMessage(
                for: task,
                sourceURLIsLivePhotoBundle: sourceURLIsLivePhotoBundle,
                route: route
            ),
            jobID: jobID
        )
    }

    func recordRenderHealthCheckPassed(
        task: BatchTask,
        launchSource: BatchJobLaunchSource?,
        configuration: BatchConfigurationSnapshot,
        jobID: UUID?
    ) {
        _ = PhotoMemoShareDiagnostics.recordResult(
            stage: .renderHealthCheckPassed,
            message:
                "taskID=\(task.id.uuidString) source=\(launchSource?.rawValue ?? "unknown") configurationID=\(configuration.configurationID?.uuidString ?? "nil") revision=\(configuration.configurationRevision.map(String.init) ?? "nil")",
            jobID: jobID,
            defaults: defaults
        )
    }

    func recordRenderHealthCheckFailed(
        task: BatchTask,
        configuration: BatchConfigurationSnapshot,
        error: Error,
        jobID: UUID?
    ) {
        _ = PhotoMemoShareDiagnostics.recordResult(
            stage: .renderHealthCheckFailed,
            message:
                "taskID=\(task.id.uuidString) configurationID=\(configuration.configurationID?.uuidString ?? "nil") revision=\(configuration.configurationRevision.map(String.init) ?? "nil") reason=\(String(describing: error))",
            jobID: jobID,
            defaults: defaults
        )
    }

    func recordTaskDuration(
        startedAt: Date,
        route: String,
        phase: BatchTaskPhase,
        task: BatchTask,
        jobID: UUID?
    ) {
        let durationSeconds = max(
            Date().timeIntervalSince(startedAt),
            0
        )

        PhotoMemoShareDiagnostics.record(
            stage: .batchTaskDuration,
            message:
                "taskID=\(task.id.uuidString), fileName=\(task.fileName), contentType=\(task.contentTypeIdentifier ?? "nil"), route=\(route), runtimeStage=total, phase=\(phase.rawValue), durationSeconds=\(String(format: "%.3f", durationSeconds))",
            jobID: jobID
        )
    }

    func measureStageDuration<Value>(
        _ stageName: String,
        route: String,
        task: BatchTask,
        jobID: UUID?,
        operation: () async throws -> Value
    ) async throws -> Value {
        let startedAt = Date()

        do {
            let value = try await operation()
            recordStageDuration(
                stageName: stageName,
                startedAt: startedAt,
                route: route,
                outcome: "completed",
                task: task,
                jobID: jobID
            )
            return value
        } catch {
            recordStageDuration(
                stageName: stageName,
                startedAt: startedAt,
                route: route,
                outcome: "failed",
                task: task,
                jobID: jobID
            )
            throw error
        }
    }

    func measureNotificationAttachmentStage(
        route: String,
        task: BatchTask,
        jobID: UUID?,
        operation: () -> URL?
    ) -> URL? {
        let startedAt = Date()
        let attachmentURL = operation()
        recordStageDuration(
            stageName: "notificationAttachment",
            startedAt: startedAt,
            route: route,
            outcome: "completed",
            task: task,
            jobID: jobID,
            extraFields: [
                "attachmentCreated": attachmentURL == nil ? "false" : "true"
            ]
        )
        return attachmentURL
    }

    private func recordStageDuration(
        stageName: String,
        startedAt: Date,
        route: String,
        outcome: String,
        task: BatchTask,
        jobID: UUID?,
        extraFields: [String: String] = [:]
    ) {
        let durationSeconds = max(
            Date().timeIntervalSince(startedAt),
            0
        )
        let extraMessage = extraFields
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: ", ")
        let suffix = extraMessage.isEmpty ? "" : ", \(extraMessage)"

        PhotoMemoShareDiagnostics.record(
            stage: .batchTaskStageDuration,
            message:
                "taskID=\(task.id.uuidString), fileName=\(task.fileName), contentType=\(task.contentTypeIdentifier ?? "nil"), route=\(route), stageName=\(stageName), outcome=\(outcome), durationSeconds=\(String(format: "%.3f", durationSeconds))\(suffix)",
            jobID: jobID
        )
    }
}
#endif
