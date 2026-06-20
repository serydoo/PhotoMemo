#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct PhotoMemoiOSBackgroundStatusSheet:
    View {

    @ObservedObject
    var backgroundStatusService:
        PhotoMemoBackgroundStatusService

    @ObservedObject
    var batchQueueStore:
        BatchQueueStore

    @Environment(\.dismiss)
    private var dismiss

    var body: some View {

        NavigationStack {

            Group {
                if let snapshot =
                    backgroundStatusService
                    .currentSnapshot {
                    content(
                        for: snapshot
                    )
                } else {
                    emptyState
                }
            }
            .navigationTitle("后台状态")
            .navigationBarTitleDisplayMode(
                .inline
            )
            .toolbar {
                ToolbarItem(
                    placement: .topBarTrailing
                ) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([
            .medium,
            .large
        ])
    }
}

private extension PhotoMemoiOSBackgroundStatusSheet {

    var currentJob: BatchJob? {

        guard let jobID =
            backgroundStatusService
            .currentSnapshot?
            .jobID
        else {
            return nil
        }

        return batchQueueStore.jobs.first {
            $0.id == jobID
        }
    }

    func content(
        for snapshot:
            PhotoMemoBackgroundJobSnapshot
    ) -> some View {

        ScrollView {
            VStack(
                alignment: .leading,
                spacing: 18
            ) {

                statusHero(
                    snapshot
                )

                if let job = currentJob {
                    processingFocusCard(
                        snapshot,
                        job: job
                    )
                }

                if snapshot.canRetryFailures {
                    Button("重试失败项") {
                        batchQueueStore
                            .retryFailedTasks(
                        in:
                            snapshot.jobID
                        )
                    }
                    .buttonStyle(.borderedProminent)
                }

                if let latestFailureSummary =
                    batchQueueStore
                    .latestFailureSummary {
                    latestFailureCard(
                        latestFailureSummary
                    )
                }
            }
            .padding(20)
        }
    }

    var emptyState: some View {

        ContentUnavailableView(
            "暂时没有后台任务",
            systemImage:
                "square.stack.3d.down.forward",
            description: Text(
                "这里只保留当前处理、失败重试和最近一次失败。"
            )
        )
    }

    func statusHero(
        _ snapshot:
            PhotoMemoBackgroundJobSnapshot
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            Label(
                heroTitle(
                    snapshot
                ),
                systemImage:
                    heroSymbol(
                        snapshot
                    )
            )
            .font(.headline)

            Text(snapshot.title)
                .font(.subheadline.weight(.medium))

            Text(snapshot.statusMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )

            ProgressView(
                value:
                    snapshot.progressFraction
            )

            Text(
                progressSummary(
                    snapshot
                )
            )
            .font(.caption)
            .foregroundStyle(.secondary)

            HStack(
                spacing: 10
            ) {
                statusPill(
                    title: "来源",
                    value:
                        launchSourceTitle(
                            snapshot.launchSource
                        )
                )

                statusPill(
                    title: "阶段",
                    value:
                        snapshot.currentPhaseTitle
                        ?? snapshot.jobState.displayTitle
                )
            }
        }
        .padding(16)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
            .fill(
                Color(
                    uiColor:
                        .secondarySystemBackground
                )
            )
        )
    }

    func statusCounts(
        _ snapshot:
            PhotoMemoBackgroundJobSnapshot
    ) -> some View {

        HStack(
            spacing: 12
        ) {
            countCard(
                title: "已完成",
                value:
                    "\(snapshot.completedCount)"
            )

            countCard(
                title: "失败",
                value:
                    "\(snapshot.failedCount)"
            )

            countCard(
                title: "总数",
                value:
                    "\(snapshot.totalCount)"
            )
        }
    }

    func processingFocusCard(
        _ snapshot:
            PhotoMemoBackgroundJobSnapshot,
        job: BatchJob
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {
            Text("当前处理焦点")
                .font(.headline)

            if let currentFileName =
                snapshot.currentFileName?
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                ),
               !currentFileName.isEmpty {
                infoRow(
                    title: "当前照片",
                    value: currentFileName
                )
            }

            infoRow(
                title: "任务状态",
                value:
                    snapshot.jobState
                    .displayTitle
            )

            infoRow(
                title: "最近更新",
                value:
                    snapshot.updatedAt
                    .formatted(
                        date: .abbreviated,
                        time: .shortened
                    )
            )

            if snapshot.failedCount > 0 {
                Text(
                    attentionSummary(
                        snapshot
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
            }
        }
        .padding(16)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
            .fill(
                Color(
                    uiColor:
                        .secondarySystemBackground
                )
            )
        )
    }

    func currentConfigurationCard(
        for job: BatchJob
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {
            Text("本批次配置")
                .font(.headline)

            infoRow(
                title: "模板",
                value:
                    resolvedTemplateTitle(
                        for: job
                    )
            )

            infoRow(
                title: "时间锚点",
                value:
                    resolvedAnchorTitle(
                        for: job
                    )
            )

            infoRow(
                title: "照片说明",
                value:
                    job.configuration
                    .shouldWritePhotoDescription
                    ? "写入说明"
                    : "不写入说明"
            )

            infoRow(
                title: "保存去向",
                value:
                    resolvedDestinationTitle(
                        for: job
                    )
            )
        }
        .padding(16)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
            .fill(
                Color(
                    uiColor:
                        .secondarySystemBackground
                )
            )
        )
    }

    func intakeSummaryCard(
        _ intakeSummary:
            ExternalPhotoImportSummary
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {
            Text("本次接收结果")
                .font(.headline)

            infoRow(
                title: "分享选中",
                value:
                    "\(intakeSummary.selectedCount) 张"
            )

            infoRow(
                title: "成功入队",
                value:
                    "\(intakeSummary.importedCount) 张"
            )

            if intakeSummary.skippedCount > 0 {
                infoRow(
                    title: "重复跳过",
                    value:
                        "\(intakeSummary.skippedCount) 张"
                )
            }

            if intakeSummary.failedCount > 0 {
                infoRow(
                    title: "导入失败",
                    value:
                        "\(intakeSummary.failedCount) 张"
                )
            }

            if intakeSummary.hasWarnings {
                Text(
                    intakeExplanation(
                        intakeSummary
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
            }
        }
        .padding(16)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
            .fill(
                Color(
                    uiColor:
                        .secondarySystemBackground
                )
            )
        )
    }

    func currentJobTimelineCard(
        for job: BatchJob
    ) -> some View {

        let records =
            jobTimelineRecords(
                for: job
            )

        guard !records.isEmpty else {
            return AnyView(EmptyView())
        }

        return AnyView(
            VStack(
                alignment: .leading,
                spacing: 10
            ) {
                Text("本批次最近记录")
                    .font(.headline)

                ForEach(records) { record in
                    VStack(
                        alignment: .leading,
                        spacing: 4
                    ) {
                        Label(
                            record.fileName,
                            systemImage:
                                record.symbolName
                        )
                        .font(
                            .subheadline
                            .weight(.medium)
                        )

                        Text(record.phaseTitle)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(
                                record.tint
                            )

                        if let detail =
                            record.detail {
                            Text(detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(
                                    horizontal: false,
                                    vertical: true
                                )
                        }
                    }
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                }
            }
            .padding(16)
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
            .background(
                RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
                .fill(
                    Color(
                        uiColor:
                            .secondarySystemBackground
                    )
                )
            )
        )
    }

    func latestFailureCard(
        _ summary:
            BatchFailureSummary
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {
            Text("最近失败")
                .font(.headline)

            Text(
                "失败阶段：\(summary.latestFailure.phaseTitle)"
            )
            .font(.subheadline.weight(.medium))

            Text(summary.latestFailure.message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )

            Text(
                "最近更新：\(summary.updatedAt.formatted(date: .abbreviated, time: .shortened))"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
            .fill(
                Color(
                    uiColor:
                        .secondarySystemBackground
                )
            )
        )
    }

    var recentFailuresCard: some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            Text("最近失败记录")
                .font(.headline)

            ForEach(
                Array(
                    batchQueueStore
                    .recentFailureRecords
                    .prefix(5)
                )
            ) { record in
                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {
                    Text(
                        "\(record.fileName) · \(record.failure.phaseTitle)"
                    )
                    .font(.subheadline.weight(.medium))

                    Text(record.failure.message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(
                            horizontal: false,
                            vertical: true
                        )
                }
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
            }
        }
        .padding(16)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
            .fill(
                Color(
                    uiColor:
                        .secondarySystemBackground
                )
            )
        )
    }

    func statusPill(
        title: String,
        value: String
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 3
        ) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.caption.weight(.medium))
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .circular)
                .fill(
                    Color(
                        uiColor: .systemBackground
                    )
            )
        )
    }

    func infoRow(
        title: String,
        value: String
    ) -> some View {

        HStack(
            alignment: .top,
            spacing: 12
        ) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(
                    width: 66,
                    alignment: .leading
                )

            Text(value)
                .font(.subheadline)
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
        }
    }

    func countCard(
        title: String,
        value: String
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 6
        ) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title3.weight(.semibold))
        }
        .padding(14)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            RoundedRectangle(
                cornerRadius: 16,
                style: .continuous
            )
            .fill(
                Color(
                    uiColor:
                        .secondarySystemBackground
                )
            )
        )
    }

    func heroTitle(
        _ snapshot:
            PhotoMemoBackgroundJobSnapshot
    ) -> String {

        switch snapshot
            .presentationState {

        case .active:
            return "正在后台处理"

        case .needsAttention:
            return "有任务需要处理"

        case .completed:
            return "最近后台任务已完成"
        }
    }

    func heroSymbol(
        _ snapshot:
            PhotoMemoBackgroundJobSnapshot
    ) -> String {

        switch snapshot
            .presentationState {

        case .active:
            return "arrow.trianglehead.2.clockwise.circle.fill"

        case .needsAttention:
            return "exclamationmark.triangle.fill"

        case .completed:
            return "checkmark.circle.fill"
        }
    }

    func launchSourceTitle(
        _ source:
            BatchJobLaunchSource
    ) -> String {
        source.displayTitle
    }

    func progressSummary(
        _ snapshot:
            PhotoMemoBackgroundJobSnapshot
    ) -> String {

        let percent =
            Int(
                (
                    snapshot.progressFraction
                    * 100
                )
                .rounded()
            )

        return "整体进度 \(percent)% · 已完成 \(snapshot.completedCount)/\(snapshot.totalCount)"
    }

    func attentionSummary(
        _ snapshot:
            PhotoMemoBackgroundJobSnapshot
    ) -> String {

        if snapshot.canRetryFailures {
            return "本批次有 \(snapshot.failedCount) 张未成功，可直接在这里重试失败项。"
        }

        return "本批次有 \(snapshot.failedCount) 张未成功，当前更适合先查看失败原因。"
    }

    func intakeExplanation(
        _ summary:
            ExternalPhotoImportSummary
    ) -> String {

        var parts: [String] = []

        if summary.skippedCount > 0 {
            parts.append(
                "重复内容不会重复入队"
            )
        }

        if summary.failedCount > 0 {
            parts.append(
                "导入失败的图片不会进入本批次，可回到来源重新分享"
            )
        }

        return parts.joined(separator: "；")
    }

    func resolvedTemplateTitle(
        for job: BatchJob
    ) -> String {

        let trimmedName =
            job.configuration.template.name
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        if !trimmedName.isEmpty {
            return trimmedName
        }

        return job.configuration
            .template.preset.displayName
    }

    func resolvedAnchorTitle(
        for job: BatchJob
    ) -> String {

        let trimmedTitle =
            job.configuration.anchor?.title
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            ) ?? ""

        if !trimmedTitle.isEmpty {
            return trimmedTitle
        }

        return "未设置"
    }

    func resolvedDestinationTitle(
        for job: BatchJob
    ) -> String {

        if let albumName =
            job.tasks.compactMap(
                \.savedAlbumName
            ).first,
           !albumName
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .isEmpty {
            return albumName
        }

        let identifier =
            job.configuration
            .selectedAlbumIdentifier
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        if identifier.isEmpty {
            return "系统图库 / 默认相册"
        }

        return "已指定目标相册"
    }

    func jobTimelineRecords(
        for job: BatchJob
    ) -> [JobTimelineRecord] {

        let prioritizedTasks =
            job.tasks.sorted {
                taskPriority($0)
                    < taskPriority($1)
            }

        return Array(
            prioritizedTasks
                .prefix(6)
                .map {
                    JobTimelineRecord(
                        task: $0
                    )
                }
        )
    }

    func taskPriority(
        _ task: BatchTask
    ) -> Int {

        switch task.phase {

        case .importing,
             .metadataReady,
             .previewReady,
             .waitingForExport,
             .exporting,
             .savingToPhotoLibrary:
            return 0

        case .failed:
            return 1

        case .queued:
            return 2

        case .completed:
            return 3

        case .cancelled:
            return 4
        }
    }
}

private struct JobTimelineRecord:
    Identifiable {

    let id: UUID

    let fileName: String

    let phaseTitle: String

    let detail: String?

    let symbolName: String

    let tint: Color

    init(
        task: BatchTask
    ) {
        self.id = task.id
        self.fileName = task.fileName
        self.phaseTitle = task.phase.displayTitle

        let trimmedMessage =
            task.failure?.message
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            ?? task.progress
            .statusMessage
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        self.detail =
            trimmedMessage.isEmpty
            ? nil
            : trimmedMessage

        switch task.phase {

        case .completed:
            self.symbolName =
                "checkmark.circle.fill"
            self.tint = .green

        case .failed:
            self.symbolName =
                "exclamationmark.triangle.fill"
            self.tint = .orange

        case .cancelled:
            self.symbolName =
                "xmark.circle.fill"
            self.tint = .secondary

        case .queued:
            self.symbolName = "clock"
            self.tint = .secondary

        case .importing,
             .metadataReady,
             .previewReady,
             .waitingForExport,
             .exporting,
             .savingToPhotoLibrary:
            self.symbolName =
                "arrow.trianglehead.2.clockwise.circle.fill"
            self.tint = .blue
        }
    }
}
#endif
