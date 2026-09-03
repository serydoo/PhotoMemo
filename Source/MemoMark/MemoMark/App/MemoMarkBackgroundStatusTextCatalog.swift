#if !MEMOMARK_SHARE_EXTENSION
import Foundation

struct MemoMarkBackgroundStatusTextCatalog {

    let language: MemoMarkLanguage

    func statusMessage(
        for job: BatchJob,
        activeTask: BatchTask?,
        feedbackState: MemoMarkBackgroundFeedbackState
    ) -> String {
        if let failureMessage = activeTask?
            .failure?.message
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            ),
           !failureMessage.isEmpty {
            return failureMessage
        }

        if activeTask?.phase == .cancelled {
            return localized(
                key: "processing.background.status.cancelled",
                fallback: "这次处理已停止。需要时请从 Apple Photos 重新分享照片。"
            )
        }

        if let activeTask {
            let progressMessage = activeTask.progress
                .localizedStatusMessage(
                    for: language
                )
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

            if !progressMessage.isEmpty {
                let fileName = activeTask.fileName
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                return fileName.isEmpty
                    ? progressMessage
                    : "\(progressMessage) · \(fileName)"
            }
        }

        switch feedbackState {
        case .preparing:
            switch job.state {
            case .draft,
                 .queued:
                return localized(
                    key: "processing.background.status.received",
                    fallback: "已接收，正在准备照片"
                )
            case .preparing,
                 .ready,
                 .running,
                 .completed,
                 .failed,
                 .cancelled:
                return localized(
                    key: "processing.background.status.preparing",
                    fallback: "正在准备原图与处理信息"
                )
            }
        case .processing:
            return localized(
                key: job.totalTaskCount <= 1
                    ? "processing.background.status.processing_single"
                    : "processing.background.status.processing_batch",
                fallback: job.totalTaskCount <= 1
                    ? "正在生成新的结果图并写回系统相册"
                    : "正在继续处理这批照片，结果会写回系统相册"
            )
        case .completed:
            return localized(
                key: "processing.background.status.completed",
                fallback: "本批照片已完成并写回系统相册"
            )
        case .partialSuccess:
            return localized(
                key: job.hasRetryableFailures
                    ? "processing.background.status.partial_retryable"
                    : "processing.background.status.partial_attention",
                fallback: job.hasRetryableFailures
                    ? "大部分照片已完成，剩余项目可回到时光记继续处理"
                    : "部分照片已完成，剩余项目需要回到时光记查看"
            )
        case .needsAttention:
            return localized(
                key: job.hasRetryableFailures
                    ? "processing.background.status.retryable_attention"
                    : "processing.background.status.attention",
                fallback: job.hasRetryableFailures
                    ? "这批照片需要回到时光记处理"
                    : "这批照片需要回到时光记查看原因"
            )
        case .unsupported:
            return localized(
                key: "processing.background.status.unsupported",
                fallback: "这批照片当前暂不支持处理"
            )
        }
    }

    var pipelineTitles: [String] {
        [
            localized(
                key: "processing.background.pipeline.receive",
                fallback: "接收照片"
            ),
            localized(
                key: "processing.background.pipeline.read",
                fallback: "读取信息"
            ),
            localized(
                key: "processing.background.pipeline.create",
                fallback: "生成卡片"
            ),
            localized(
                key: "processing.background.pipeline.save",
                fallback: "写入图库"
            ),
            localized(
                key: "processing.background.pipeline.complete",
                fallback: "完成"
            )
        ]
    }

    func aggregateQueueLine(
        runningCount: Int,
        waitingCount: Int,
        completedCount: Int,
        failedCount: Int
    ) -> String {
        if failedCount > 0 {
            return localizedFormat(
                key: "processing.background.queue.aggregate_attention_format",
                fallback: "%lld 张需要处理 · 已完成 %lld 张",
                Int64(failedCount),
                Int64(completedCount)
            )
        }

        return localizedFormat(
            key: "processing.background.queue.aggregate_active_format",
            fallback: "进行中 %lld 张 · 等待 %lld 张 · 已完成 %lld 张",
            Int64(runningCount),
            Int64(waitingCount),
            Int64(completedCount)
        )
    }

    func queueDisplayTitle(
        for job: BatchJob
    ) -> String {
        MemoMarkQueueDisplayFormatter.title(
            startedAt: job.createdAt,
            photoCount: job.totalTaskCount,
            language: language
        )
    }

    func queueLineBody(
        for job: BatchJob,
        activeTaskID: UUID?
    ) -> String {
        if job.totalTaskCount <= 1 {
            return singlePhotoQueueLineBody(
                for: job,
                activeTaskID: activeTaskID
            )
        }

        if job.completedTaskCount == job.totalTaskCount,
           job.failedTaskCount == 0 {
            return localizedFormat(
                key: "processing.background.queue.saved_format",
                fallback: "已保存 %lld 张",
                Int64(job.totalTaskCount)
            )
        }

        if job.failedTaskCount > 0,
           job.tasks.allSatisfy(\.phase.isTerminal) {
            if job.completedTaskCount > 0 {
                return localizedFormat(
                    key: "processing.background.queue.saved_attention_format",
                    fallback: "已保存 %lld 张 · %lld 张需要处理",
                    Int64(job.completedTaskCount),
                    Int64(job.failedTaskCount)
                )
            }

            return localizedFormat(
                key: "processing.background.queue.attention_format",
                fallback: "%lld 张需要处理",
                Int64(job.failedTaskCount)
            )
        }

        if !job.tasks.allSatisfy(\.phase.isTerminal) {
            return localizedFormat(
                key: "processing.background.queue.progress_format",
                fallback: "已完成 %lld/%lld",
                Int64(job.completedTaskCount),
                Int64(job.totalTaskCount)
            )
        }

        return localizedFormat(
            key: "processing.background.queue.count_format",
            fallback: "%lld/%lld",
            Int64(job.completedTaskCount),
            Int64(job.totalTaskCount)
        )
    }

    func taskPhaseTitle(
        _ phase: BatchTaskPhase?
    ) -> String? {
        guard let phase else {
            return nil
        }

        return localized(
            key: "processing.background.phase.\(phase.rawValue)",
            fallback: phase.displayTitle
        )
    }
}

private extension MemoMarkBackgroundStatusTextCatalog {

    func singlePhotoQueueLineBody(
        for job: BatchJob,
        activeTaskID: UUID?
    ) -> String {
        if job.completedTaskCount == 1,
           job.failedTaskCount == 0 {
            return localized(
                key: "processing.background.queue.single_saved",
                fallback: "已保存 1 张"
            )
        }

        if job.failedTaskCount > 0 {
            return localized(
                key: "processing.background.queue.single_attention",
                fallback: "1 张需要处理"
            )
        }

        guard let activeTask = job.tasks.first(where: {
            $0.id == activeTaskID
        }) ?? job.tasks.first(where: {
            !$0.phase.isTerminal
        }) else {
            return localized(
                key: "processing.background.queue.single_count",
                fallback: "1 张"
            )
        }

        return singlePhotoPhaseText(activeTask)
    }

    func singlePhotoPhaseText(
        _ task: BatchTask
    ) -> String {
        if task.progress.stage == .preparingRAWPhoto
            || task.progress.stage == .preparedRAWRepresentation
            || task.progress.statusMessage.contains("RAW") {
            switch task.phase {
            case .importing:
                return localized(
                    key: "processing.background.queue.phase.raw_preparing",
                    fallback: "准备 RAW"
                )
            case .metadataReady:
                return localized(
                    key: "processing.background.queue.phase.raw_representation",
                    fallback: "RAW 显示版本"
                )
            default:
                break
            }
        }

        switch task.phase {
        case .queued:
            return localized(
                key: "processing.background.queue.phase.queued",
                fallback: "等待开始"
            )
        case .importing:
            return localized(
                key: "processing.background.queue.phase.importing",
                fallback: "读取原图"
            )
        case .metadataReady,
             .previewReady:
            return localized(
                key: "processing.background.queue.phase.metadata",
                fallback: "整理信息"
            )
        case .waitingForExport,
             .exporting:
            return localized(
                key: "processing.background.queue.phase.exporting",
                fallback: "生成图片"
            )
        case .savingToPhotoLibrary:
            return localized(
                key: "processing.background.queue.phase.saving",
                fallback: "写入图库"
            )
        case .completed:
            return localized(
                key: "processing.background.queue.phase.completed",
                fallback: "已保存"
            )
        case .failed:
            return localized(
                key: "processing.background.queue.phase.failed",
                fallback: "需要查看"
            )
        case .cancelled:
            return localized(
                key: "processing.background.queue.phase.cancelled",
                fallback: "已取消"
            )
        }
    }

    func localized(
        key: String,
        fallback: String
    ) -> String {
        language.localized(
            key: key,
            fallback: fallback
        )
    }

    func localizedFormat(
        key: String,
        fallback: String,
        _ arguments: CVarArg...
    ) -> String {
        String(
            format: localized(
                key: key,
                fallback: fallback
            ),
            locale: language.locale,
            arguments: arguments
        )
    }
}
#endif
