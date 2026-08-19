#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
#if canImport(SwiftUI)
import SwiftUI
#endif

enum PhotoMemoiOSQueueDiagnosticsTint:
    Hashable {

    case blue

    case orange

    case green

    case secondary
}

#if canImport(SwiftUI)
extension PhotoMemoiOSQueueDiagnosticsTint {

    var color: Color {

        switch self {
        case .blue:
            return .blue
        case .orange:
            return .orange
        case .green:
            return .green
        case .secondary:
            return .secondary
        }
    }
}
#endif

struct PhotoMemoiOSQueueDiagnosticsHeaderProjection:
    Hashable {

    let headline: String

    let subheadline: String

    let symbolName: String

    let tint:
        PhotoMemoiOSQueueDiagnosticsTint

    let isRecovery: Bool

    init(
        headline: String,
        subheadline: String,
        symbolName: String,
        tint: PhotoMemoiOSQueueDiagnosticsTint,
        isRecovery: Bool = false
    ) {
        self.headline = headline
        self.subheadline = subheadline
        self.symbolName = symbolName
        self.tint = tint
        self.isRecovery = isRecovery
    }
}

struct PhotoMemoiOSQueuePipelineStepProjection:
    Hashable {

    let title: String

    let symbolName: String

    let tint:
        PhotoMemoiOSQueueDiagnosticsTint

    let emphasizesTitle: Bool

    let usesSecondaryTitleStyle: Bool
}

struct PhotoMemoiOSQueueProgressProjection:
    Hashable {

    let title: String

    let symbolName: String

    let tint:
        PhotoMemoiOSQueueDiagnosticsTint

    let progressFraction: Double

    let progressPercentText: String

    let statusMessage: String

    let showsPipeline: Bool

    let queueLines: [String]

    let overflowQueueCount: Int

    let pipelineSteps:
        [PhotoMemoiOSQueuePipelineStepProjection]
}

struct PhotoMemoiOSQueueDiagnosticEventProjection:
    Identifiable,
    Hashable {

    let id: UUID

    let timestamp: Date

    let title: String

    let message: String
}

enum PhotoMemoiOSQueueDiagnosticsProjectionEngine {

    static func headerProjection(
        backgroundSnapshot:
            PhotoMemoBackgroundJobSnapshot?,
        processingDiagnosticsSnapshot:
            PhotoMemoiOSProcessingDiagnosticsSnapshot,
        events:
            [PhotoMemoShareDiagnosticEvent],
        language: MemoMarkLanguage = .simplifiedChinese
    ) -> PhotoMemoiOSQueueDiagnosticsHeaderProjection {

        if let backgroundSnapshot,
           !shouldPrioritizeLatestShareDiagnostic(
                events: events,
                over: backgroundSnapshot
           ) {
            let progressProjection =
                progressProjection(
                    for: backgroundSnapshot,
                    language: language
                )

            return PhotoMemoiOSQueueDiagnosticsHeaderProjection(
                headline:
                    progressProjection.title,
                subheadline:
                    backgroundSnapshot.statusMessage,
                symbolName:
                    progressProjection.symbolName,
                tint:
                    progressProjection.tint
            )
        }

        guard let latestEvent =
            events.last else {
            if processingDiagnosticsSnapshot
                .hasCorruptedPersistence {
                return PhotoMemoiOSQueueDiagnosticsHeaderProjection(
                    headline:
                        language.localized(
                            key: "task.diagnostics.recovery_headline",
                            fallback: "Shared progress needs recovery"
                        ),
                    subheadline:
                        processingDiagnosticsSnapshot
                        .recoveryMessage
                        ?? language.localized(
                            key: "task.diagnostics.recovery_subheadline",
                            fallback: "Share a photo once to create a new local progress record."
                        ),
                    symbolName:
                        "exclamationmark.triangle.fill",
                    tint: .orange,
                    isRecovery: true
                )
            }

            return PhotoMemoiOSQueueDiagnosticsHeaderProjection(
                headline:
                    language.localized(
                        key: "task.diagnostics.waiting_headline",
                        fallback: "Waiting for the next share"
                    ),
                subheadline:
                    language.localized(
                        key: "task.diagnostics.waiting_subheadline",
                        fallback: "Share a photo once to see intake, queue, and progress results here."
                    ),
                symbolName:
                    "square.stack.3d.down.forward",
                tint:
                    .secondary
            )
        }

        return PhotoMemoiOSQueueDiagnosticsHeaderProjection(
            headline:
                diagnosticsHeadline(
                    latestEvent: latestEvent,
                    events: events,
                    language: language
                ),
            subheadline:
                diagnosticsSubheadline(
                    processingDiagnosticsSnapshot:
                        processingDiagnosticsSnapshot,
                    events: events,
                    language: language
                ),
            symbolName:
                diagnosticsSymbolName(
                    latestEvent: latestEvent,
                    processingDiagnosticsSnapshot:
                        processingDiagnosticsSnapshot,
                    events: events
                ),
            tint:
                diagnosticsTint(
                    latestEvent: latestEvent,
                    processingDiagnosticsSnapshot:
                        processingDiagnosticsSnapshot,
                    events: events
                )
        )
    }

    static func progressProjection(
        for snapshot:
            PhotoMemoBackgroundJobSnapshot,
        language:
            MemoMarkLanguage = .simplifiedChinese
    ) -> PhotoMemoiOSQueueProgressProjection {

        let clampedProgress =
            min(
                max(
                    snapshot.progressFraction,
                    0
                ),
                1
            )

        return PhotoMemoiOSQueueProgressProjection(
            title:
                progressTitle(
                    snapshot,
                    language: language
                ),
            symbolName:
                progressSymbolName(snapshot),
            tint:
                progressTint(snapshot),
            progressFraction:
                clampedProgress,
            progressPercentText:
                "\(Int(round(clampedProgress * 100)))%",
            statusMessage:
                snapshot.statusMessage,
            showsPipeline:
                snapshot.overflowQueueCount == 0
                && snapshot.queueLines.count <= 1,
            queueLines:
                snapshot.queueLines,
            overflowQueueCount:
                snapshot.overflowQueueCount,
            pipelineSteps:
                snapshot.pipelineSteps.map {
                    pipelineStepProjection(
                        for: $0,
                        language: language
                    )
                }
        )
    }

    static func eventDisplayProjections(
        from events:
            [PhotoMemoShareDiagnosticEvent],
        language:
            MemoMarkLanguage = .simplifiedChinese
    ) -> [PhotoMemoiOSQueueDiagnosticEventProjection] {

        var seenKeys = Set<String>()

        return events
            .reversed()
            .compactMap { event in
                guard let title =
                    diagnosticDisplayTitle(
                        for: event,
                        language: language
                    )
                else {
                    return nil
                }

                let message =
                    diagnosticDisplayMessage(
                        for: event,
                        language: language
                    )
                let dedupeKey =
                    "\(title)|\(message)"

                guard !seenKeys.contains(dedupeKey) else {
                    return nil
                }

                seenKeys.insert(dedupeKey)

                return PhotoMemoiOSQueueDiagnosticEventProjection(
                    id: event.id,
                    timestamp:
                        event.timestamp,
                    title: title,
                    message: message
                )
            }
            .prefix(3)
            .map { $0 }
    }
}

private extension PhotoMemoiOSQueueDiagnosticsProjectionEngine {

    static func shouldPrioritizeLatestShareDiagnostic(
        events:
            [PhotoMemoShareDiagnosticEvent],
        over snapshot:
            PhotoMemoBackgroundJobSnapshot
    ) -> Bool {

        guard let latestEvent =
            events.last else {
            return false
        }

        guard latestEvent.timestamp
            > snapshot.updatedAt else {
            return false
        }

        switch snapshot.presentationState {
        case .completed:
            return true
        case .active,
             .needsAttention:
            return false
        }
    }

    static func diagnosticsHeadline(
        latestEvent:
            PhotoMemoShareDiagnosticEvent,
        events:
            [PhotoMemoShareDiagnosticEvent],
        language:
            MemoMarkLanguage = .simplifiedChinese
    ) -> String {

        if containsStage(
            .extensionSourcePrepare,
            in: events
        ),
           !containsAnyStage(
                [
                    .extensionSourceReady,
                    .appEnqueueCreated
                ],
                in: events
           ) {
            return language.localized(
                key: "task.diagnostics.headline.preparing_original",
                fallback: "Preparing the iCloud original"
            )
        }

        if containsStage(
            .appEnqueueCreated,
            in: events
        ) {
            return language.localized(
                key: "task.diagnostics.headline.queued",
                fallback: "Photo added to the processing queue"
            )
        }

        if containsStage(
            .extensionSourceReady,
            in: events
        ) {
            return language.localized(
                key: "task.diagnostics.headline.original_ready",
                fallback: "Original ready for MemoMark"
            )
        }

        if containsStage(
            .appOpenURLShare,
            in: events
        ) {
            return language.localized(
                key: "task.diagnostics.headline.app_awakened",
                fallback: "MemoMark was opened"
            )
        }

        if isFailureStage(
            latestEvent.stage
        ) {
            return language.localized(
                key: "task.diagnostics.headline.needs_review",
                fallback: "This share needs your attention"
            )
        }

        return language.localized(
            key: "task.diagnostics.headline.handoff",
            fallback: "Handing the photo to MemoMark"
        )
    }

    static func diagnosticsSubheadline(
        processingDiagnosticsSnapshot:
            PhotoMemoiOSProcessingDiagnosticsSnapshot,
        events:
            [PhotoMemoShareDiagnosticEvent],
        language:
            MemoMarkLanguage = .simplifiedChinese
    ) -> String {

        guard !events.isEmpty else {
            if let recoveryMessage =
                processingDiagnosticsSnapshot
                .recoveryMessage {
                return recoveryMessage
            }

            return language.localized(
                key: "task.diagnostics.detail.empty",
                fallback: "Share a photo once to see intake, queue, and progress results here."
            )
        }

        if containsStage(
            .appRequestDropped,
            in: events
        ) {
            return language.localized(
                key: "task.diagnostics.detail.duplicate",
                fallback: "Duplicate or invalid photos were skipped; originals are unchanged."
            )
        }

        if containsStage(
            .extensionSourcePrepare,
            in: events
        ),
           !containsAnyStage(
                [
                    .extensionSourceReady,
                    .appEnqueueCreated
                ],
                in: events
           ) {
            return language.localized(
                key: "task.diagnostics.detail.preparing_original",
                fallback: "The system is preparing the original from iCloud."
            )
        }

        if containsStage(
            .extensionSourceReady,
            in: events
        ),
           !containsStage(
                .appEnqueueCreated,
                in: events
           ) {
            return language.localized(
                key: "task.diagnostics.detail.original_ready",
                fallback: "The original is ready and is being handed to MemoMark."
            )
        }

        if containsAnyStage(
            [
                .extensionHandoffUnconfirmed,
                .extensionHandoffFailed
            ],
            in: events
        ),
           !containsStage(
                .appEnqueueCreated,
                in: events
           ) {
            return language.localized(
                key: "task.diagnostics.detail.handoff_waiting",
                fallback: "The original was received and is waiting for MemoMark to continue."
            )
        }

        if containsStage(
            .appEnqueueCreated,
            in: events
        ) {
            return language.localized(
                key: "task.diagnostics.detail.queued",
                fallback: "The photo is in the background queue and will be saved to Apple Photos when complete."
            )
        }

        return language.localized(
            key: "task.diagnostics.detail.receiving",
            fallback: "MemoMark is receiving this share."
        )
    }

    static func diagnosticsSymbolName(
        latestEvent:
            PhotoMemoShareDiagnosticEvent,
        processingDiagnosticsSnapshot:
            PhotoMemoiOSProcessingDiagnosticsSnapshot,
        events:
            [PhotoMemoShareDiagnosticEvent]
    ) -> String {

        if containsStage(
            .liveActivityRequestCreated,
            in: events
        ) {
            return "checkmark.circle.fill"
        }

        if containsStage(
            .extensionSourcePrepare,
            in: events
        ),
           !containsStage(
                .extensionSourceReady,
                in: events
           ) {
            return "icloud.and.arrow.down"
        }

        if isFailureStage(
            latestEvent.stage
        ) {
            return "exclamationmark.triangle.fill"
        }

        if processingDiagnosticsSnapshot
            .hasCorruptedPersistence {
            return "exclamationmark.triangle.fill"
        }

        if events.isEmpty {
            return "square.stack.3d.down.forward"
        }

        return "arrow.trianglehead.2.clockwise.circle.fill"
    }

    static func diagnosticsTint(
        latestEvent:
            PhotoMemoShareDiagnosticEvent,
        processingDiagnosticsSnapshot:
            PhotoMemoiOSProcessingDiagnosticsSnapshot,
        events:
            [PhotoMemoShareDiagnosticEvent]
    ) -> PhotoMemoiOSQueueDiagnosticsTint {

        if containsStage(
            .liveActivityRequestCreated,
            in: events
        ) {
            return .green
        }

        if containsStage(
            .extensionSourcePrepare,
            in: events
        ),
           !containsStage(
                .extensionSourceReady,
                in: events
           ) {
            return .blue
        }

        if isFailureStage(
            latestEvent.stage
        ) {
            return .orange
        }

        if processingDiagnosticsSnapshot
            .hasCorruptedPersistence {
            return .orange
        }

        if events.isEmpty {
            return .secondary
        }

        return .blue
    }

    static func progressTitle(
        _ snapshot:
            PhotoMemoBackgroundJobSnapshot,
        language:
            MemoMarkLanguage = .simplifiedChinese
    ) -> String {

        let key: String
        let fallback: String
        switch snapshot.feedbackState {
        case .preparing:
            key = "task.diagnostics.progress.preparing_format"
            fallback = "%@ Preparing"
        case .processing:
            key = "task.diagnostics.progress.processing_format"
            fallback = "%@ Processing"
        case .completed:
            key = "task.diagnostics.progress.completed_format"
            fallback = "%@ Completed"
        case .partialSuccess:
            key = "task.diagnostics.progress.partial_success_format"
            fallback = "%@ Partially completed"
        case .needsAttention:
            key = "task.diagnostics.progress.needs_attention_format"
            fallback = "%@ Needs attention"
        case .unsupported:
            key = "task.diagnostics.progress.unsupported_format"
            fallback = "%@ Unsupported"
        }

        return String(
            format: language.localized(
                key: key,
                fallback: fallback
            ),
            locale: language.locale,
            snapshot.title
        )
    }

    static func progressSymbolName(
        _ snapshot:
            PhotoMemoBackgroundJobSnapshot
    ) -> String {

        switch snapshot.feedbackState {
        case .preparing,
             .processing:
            return "arrow.trianglehead.2.clockwise.circle.fill"
        case .partialSuccess,
             .needsAttention,
             .unsupported:
            return "exclamationmark.triangle.fill"
        case .completed:
            return "checkmark.circle.fill"
        }
    }

    static func progressTint(
        _ snapshot:
            PhotoMemoBackgroundJobSnapshot
    ) -> PhotoMemoiOSQueueDiagnosticsTint {

        switch snapshot.feedbackState {
        case .preparing,
             .processing:
            return .blue
        case .partialSuccess,
             .needsAttention,
             .unsupported:
            return .orange
        case .completed:
            return .green
        }
    }

    static func pipelineStepProjection(
        for step:
            PhotoMemoBackgroundPipelineStep,
        language:
            MemoMarkLanguage = .simplifiedChinese
    ) -> PhotoMemoiOSQueuePipelineStepProjection {

        PhotoMemoiOSQueuePipelineStepProjection(
            title:
                localizedPipelineStepTitle(
                    step.title,
                    language: language
                ),
            symbolName:
                pipelineSymbolName(
                    for: step.state
                ),
            tint:
                pipelineTint(
                    for: step.state
                ),
            emphasizesTitle:
                step.state == .active,
            usesSecondaryTitleStyle:
                step.state == .pending
        )
    }

    static func pipelineSymbolName(
        for state:
            PhotoMemoBackgroundPipelineStepState
    ) -> String {

        switch state {
        case .pending:
            return "circle"
        case .active:
            return "arrow.trianglehead.2.clockwise.circle.fill"
        case .completed:
            return "checkmark.circle.fill"
        case .needsAttention:
            return "exclamationmark.triangle.fill"
        }
    }

    static func pipelineTint(
        for state:
            PhotoMemoBackgroundPipelineStepState
    ) -> PhotoMemoiOSQueueDiagnosticsTint {

        switch state {
        case .pending:
            return .secondary
        case .active:
            return .blue
        case .completed:
            return .green
        case .needsAttention:
            return .orange
        }
    }

    static func diagnosticDisplayTitle(
        for event:
            PhotoMemoShareDiagnosticEvent,
        language:
            MemoMarkLanguage = .simplifiedChinese
    ) -> String? {

        let key: String
        switch event.stage {
        case .extensionRequestPersisted,
             .extensionPersisted:
            key = "task.diagnostics.event.title.received"
        case .extensionSourcePrepare:
            key = "task.diagnostics.event.title.preparing_original"
        case .extensionSourceReady:
            key = "task.diagnostics.event.title.original_ready"
        case .extensionSourceUnavailable:
            key = "task.diagnostics.event.title.original_unavailable"
        case .extensionHandoffUnconfirmed,
             .extensionHandoffFailed:
            key = "task.diagnostics.event.title.handoff_waiting"
        case .appDrain:
            key = "task.diagnostics.event.title.draining"
        case .appRequestValidated:
            key = "task.diagnostics.event.title.validated"
        case .appEnqueueCreated:
            key = "task.diagnostics.event.title.queued"
        case .appRequestDropped:
            key = "task.diagnostics.event.title.duplicate"
        case .liveActivityRequestCreated:
            key = "task.diagnostics.event.title.live_activity"
        case .liveActivityPayloadTerminal:
            key = "task.diagnostics.event.title.completed"
        default:
            return nil
        }

        return language.localized(
            key: key,
            fallback: event.message
        )
    }

    static func diagnosticDisplayMessage(
        for event:
            PhotoMemoShareDiagnosticEvent,
        language:
            MemoMarkLanguage = .simplifiedChinese
    ) -> String {

        let key: String
        let fallback: String
        switch event.stage {
        case .extensionRequestPersisted,
             .extensionPersisted:
            key = "task.diagnostics.event.message.received"
            fallback = "The original was staged and MemoMark will continue with the current configuration."
        case .extensionSourcePrepare:
            key = "task.diagnostics.event.message.preparing_original"
            fallback = "The system is preparing the original from iCloud."
        case .extensionSourceReady:
            key = "task.diagnostics.event.message.original_ready"
            fallback = "The original is ready and is being handed to MemoMark."
        case .extensionSourceUnavailable:
            key = "task.diagnostics.event.message.original_unavailable"
            fallback = "The system has not provided the complete original yet. Try again later or open it in Photos first."
        case .extensionHandoffUnconfirmed,
             .extensionHandoffFailed:
            key = "task.diagnostics.event.message.handoff_waiting"
            fallback = "The photo was received. If MemoMark did not open automatically, open it to continue."
        case .appDrain:
            key = "task.diagnostics.event.message.draining"
            fallback = "MemoMark is reading the received photo."
        case .appRequestValidated:
            key = "task.diagnostics.event.message.validated"
            fallback = "The photo is ready to process and will be added to the background queue."
        case .appEnqueueCreated:
            key = "task.diagnostics.event.message.queued"
            fallback = "The photo will be created and saved with the current default configuration."
        case .appRequestDropped:
            key = "task.diagnostics.event.message.duplicate"
            fallback = "The same photo is already in the queue, so it will not be created again."
        case .liveActivityRequestCreated:
            key = "task.diagnostics.event.message.live_activity"
            fallback = "You can view processing status in the system progress area."
        case .liveActivityPayloadTerminal:
            key = "task.diagnostics.event.message.completed"
            fallback = "Processing is complete and the result will appear in the target album."
        default:
            return event.message
        }

        return language.localized(
            key: key,
            fallback: fallback
        )
    }

    static func localizedPipelineStepTitle(
        _ title: String,
        language: MemoMarkLanguage
    ) -> String {
        let key: String
        switch title {
        case "接收照片":
            key = "task.diagnostics.pipeline.receive"
        case "读取信息":
            key = "task.diagnostics.pipeline.read_metadata"
        case "生成卡片":
            key = "task.diagnostics.pipeline.create_card"
        case "写入图库":
            key = "task.diagnostics.pipeline.save_photo"
        case "完成":
            key = "task.diagnostics.pipeline.completed"
        default:
            return title
        }

        return language.localized(
            key: key,
            fallback: title
        )
    }

    static func containsStage(
        _ stage:
            PhotoMemoShareDiagnosticStage,
        in events:
            [PhotoMemoShareDiagnosticEvent]
    ) -> Bool {

        events.contains {
            $0.stage == stage
        }
    }

    static func containsAnyStage(
        _ stages:
            [PhotoMemoShareDiagnosticStage],
        in events:
            [PhotoMemoShareDiagnosticEvent]
    ) -> Bool {

        events.contains { event in
            stages.contains(
                event.stage
            )
        }
    }

    static func isFailureStage(
        _ stage:
            PhotoMemoShareDiagnosticStage
    ) -> Bool {

        stage.rawValue.contains(
            "failed"
        )
        || stage.rawValue.contains(
            "error"
        )
    }
}
#endif
