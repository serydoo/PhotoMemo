#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI

struct MemoMarkiOSBackgroundStatusSheet:
    View {

    @AppStorage(
        MemoMarkLanguage.interfacePreferenceStorageKey,
        store: MemoMarkSharedContainer.sharedUserDefaults
    )
    private var interfaceLanguagePreferenceRawValue =
        MemoMarkInterfaceLanguagePreference.system.rawValue

    @ObservedObject
    var backgroundStatusService:
        MemoMarkBackgroundStatusService

    @ObservedObject
    var batchQueueStore:
        BatchQueueStore

    @ObservedObject
    var permissionCenter:
        PermissionCenter

    let authorizePhotoWorkflow:
        @MainActor () async -> Void

    let authorizeNotificationWorkflow:
        @MainActor () async -> Void

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
            .navigationTitle(MemoMarkLanguage.interfaceStored.localized(
                key: "processing.navigation.title",
                fallback: "处理进度"
            ))
            .navigationBarTitleDisplayMode(
                .inline
            )
            .toolbar {
                ToolbarItem(
                    placement: .topBarTrailing
                ) {
                    Button(MemoMarkLanguage.interfaceStored.localized(
                        key: "processing.navigation.done",
                        fallback: "完成"
                    )) {
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

private extension MemoMarkiOSBackgroundStatusSheet {

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
            MemoMarkBackgroundJobSnapshot
    ) -> some View {

        ScrollView {
            VStack(
                alignment: .leading,
                spacing: 18
            ) {

                if batchQueueStore.isPersistenceBlocked {
                    persistenceRecoveryCard
                }

                permissionCards

                statusHero(
                    snapshot
                )

                if snapshot.displayMode
                    == .singleTask {
                    pipelineCard(snapshot)
                }

                if let job = currentJob {
                    processingFocusCard(
                        snapshot,
                        job: job
                    )
                }

                if snapshot.canRetryFailures {
                    Button(MemoMarkLanguage.interfaceStored.localized(
                        key: "processing.retry_failed",
                        fallback: "重试失败项"
                    )) {
                        Task { @MainActor in
                            await batchQueueStore
                                .retryFailedTasks(
                                    in:
                                        snapshot.jobID
                                )
                        }
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
            .padding(.vertical, 20)
            .adaptiveScrollContent(
                horizontalPadding: 20
            )
        }
    }

    @ViewBuilder
    var permissionCards: some View {
        if !permissionCenter.canAccessPhotoLibrary {
            photoPermissionCard
        }
        if !permissionCenter.canDeliverNotifications {
            notificationPermissionCard
        }
    }

    var photoPermissionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(
                localized(
                    "processing.permission.photo.title",
                    fallback: "允许保存到 Apple Photos"
                ),
                systemImage: "photo.badge.checkmark"
            )
            .font(.headline)
            Text(
                localized(
                    "processing.permission.photo.detail",
                    fallback: "后台任务需要照片权限，才能把生成结果保存回系统相册。"
                )
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
            Button(
                permissionCenter.photoLibraryState == .denied
                ? localized(
                    "processing.permission.photo.open_settings",
                    fallback: "打开系统设置"
                )
                : localized(
                    "processing.permission.photo.allow",
                    fallback: "允许照片访问"
                )
            ) {
                if permissionCenter.photoLibraryState == .denied {
                    permissionCenter.openSystemSettings(
                        for: .photoLibrary
                    )
                } else {
                    Task {
                        await authorizePhotoWorkflow()
                    }
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(16)
        .background(
            Color.secondary.opacity(0.08),
            in: RoundedRectangle(cornerRadius: 16)
        )
    }

    var notificationPermissionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(
                localized(
                    "processing.permission.notification.title",
                    fallback: "允许完成提醒"
                ),
                systemImage: "bell.badge"
            )
            .font(.headline)
            Text(
                localized(
                    "processing.permission.notification.detail",
                    fallback: "处理结束后，时光记可以通过系统通知告诉你结果。"
                )
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
            Button(
                permissionCenter.notificationState == .denied
                ? localized(
                    "processing.permission.notification.open_settings",
                    fallback: "打开通知设置"
                )
                : localized(
                    "processing.permission.notification.allow",
                    fallback: "允许完成提醒"
                )
            ) {
                if permissionCenter.notificationState == .denied {
                    permissionCenter.openSystemSettings(
                        for: .notifications
                    )
                } else {
                    Task {
                        await authorizeNotificationWorkflow()
                    }
                }
            }
            .buttonStyle(.bordered)
        }
        .padding(16)
        .background(
            Color.secondary.opacity(0.08),
            in: RoundedRectangle(cornerRadius: 16)
        )
    }

    var emptyState: some View {
        VStack(spacing: 20) {
            if batchQueueStore.isPersistenceBlocked {
                persistenceRecoveryCard
            }
            permissionCards
            ContentUnavailableView(
                "暂时没有后台任务",
                systemImage:
                    "square.stack.3d.down.forward",
                description: Text(
                    "这里只保留当前处理、失败重试和最近一次失败。"
                )
            )
        }
        .padding(20)
    }

    var persistenceRecoveryCard: some View {
        VStack(
            alignment: .leading,
            spacing: 12
        ) {
            Label(
                localized(
                    "processing.persistence.title",
                    fallback: "暂时无法保存处理进度"
                ),
                systemImage: "externaldrive.badge.exclamationmark"
            )
            .font(.headline)

            Text(
                batchQueueStore.lastErrorMessage.isEmpty
                ? localized(
                    "processing.persistence.detail",
                    fallback: "处理已暂停。恢复存储后可以继续，不会覆盖已有记录。"
                )
                : batchQueueStore.lastErrorMessage
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .fixedSize(
                horizontal: false,
                vertical: true
            )

            Button(
                localized(
                    "processing.persistence.retry",
                    fallback: "重试保存进度"
                )
            ) {
                Task {
                    await batchQueueStore
                        .retryPersistence()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(16)
        .background(
            Color.orange.opacity(0.10),
            in: RoundedRectangle(cornerRadius: 16)
        )
    }

    func statusHero(
        _ snapshot:
            MemoMarkBackgroundJobSnapshot
    ) -> some View {

        MemoMarkiOSBackgroundStatusHeroCard(
            language: MemoMarkLanguage.interfaceStored,
            title:
                heroTitle(
                    snapshot
                ),
            symbolName:
                heroSymbol(
                    snapshot
                ),
            snapshotTitle:
                snapshot.title,
            statusMessage:
                snapshot.localizedStatusMessage(
                    for: .interfaceStored
                ),
            displayMode:
                snapshot.displayMode,
            queueLines:
                snapshot.queueLines,
            overflowQueueCount:
                snapshot.overflowQueueCount,
            progressFraction:
                snapshot.progressFraction,
            progressSummary:
                progressSummary(
                    snapshot
                ),
            launchSourceTitle:
                launchSourceTitle(
                    snapshot.launchSource
                ),
            phaseTitle:
                snapshot.currentPhaseTitle
                ?? localizedJobStateTitle(
                    snapshot.jobState
                )
        )
    }

    func pipelineCard(
        _ snapshot:
            MemoMarkBackgroundJobSnapshot
    ) -> some View {

        MemoMarkiOSBackgroundPipelineCard(
            language: MemoMarkLanguage.interfaceStored,
            steps:
                snapshot.pipelineSteps
        )
    }

    func processingFocusCard(
        _ snapshot:
            MemoMarkBackgroundJobSnapshot,
        job: BatchJob
    ) -> some View {

        let trimmedCurrentFileName =
            snapshot.currentFileName?
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        let resolvedCurrentFileName:
            String?

        if let trimmedCurrentFileName,
           !trimmedCurrentFileName.isEmpty {
            resolvedCurrentFileName =
                trimmedCurrentFileName
        } else {
            resolvedCurrentFileName =
                nil
        }

        return MemoMarkiOSBackgroundProcessingFocusCard(
            language: MemoMarkLanguage.interfaceStored,
            currentFileName:
                resolvedCurrentFileName,
            jobStateTitle:
                localizedJobStateTitle(
                    snapshot.jobState
                ),
            updatedAt:
                snapshot.updatedAt,
            attentionSummary:
                snapshot.failedCount > 0
                ? attentionSummary(
                    snapshot
                )
                : nil
        )
    }

    func latestFailureCard(
        _ summary:
            BatchFailureSummary
    ) -> some View {

        MemoMarkiOSBackgroundLatestFailureCard(
            language: MemoMarkLanguage.interfaceStored,
            phaseTitle:
                summary.latestFailure.phaseTitle,
            message:
                summary.latestFailure.message,
            updatedAt:
                summary.updatedAt
        )
    }

    func heroTitle(
        _ snapshot:
            MemoMarkBackgroundJobSnapshot
    ) -> String {

        switch snapshot.feedbackState {
        case .preparing:
            return localized(
                "processing.hero.preparing",
                fallback: "正在准备处理"
            )
        case .processing:
            return localized(
                "processing.hero.processing",
                fallback: "正在后台处理"
            )
        case .completed:
            return localized(
                "processing.hero.completed",
                fallback: "最近后台任务已完成"
            )
        case .partialSuccess:
            return localized(
                "processing.hero.partial_success",
                fallback: "部分照片已完成"
            )
        case .needsAttention:
            return localized(
                "processing.hero.needs_attention",
                fallback: "有照片需要处理"
            )
        case .unsupported:
            return localized(
                "processing.hero.unsupported",
                fallback: "有照片暂不支持"
            )
        }
    }

    func heroSymbol(
        _ snapshot:
            MemoMarkBackgroundJobSnapshot
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

    func launchSourceTitle(
        _ source:
            BatchJobLaunchSource
    ) -> String {
        localized(
            "legacy.home.recent.source.\(source.rawValue)",
            fallback: source.displayTitle
        )
    }

    func localizedJobStateTitle(
        _ state: BatchJobState
    ) -> String {
        localized(
            "processing.background.job_state.\(state.rawValue)",
            fallback: state.displayTitle
        )
    }

    func progressSummary(
        _ snapshot:
            MemoMarkBackgroundJobSnapshot
    ) -> String {

        let percent =
            Int(
                (
                    snapshot.progressFraction
                * 100
                )
                .rounded()
            )

        switch snapshot.feedbackState {
        case .preparing,
             .processing:
            return formatted(
                "processing.progress.active",
                fallback: "整体进度 %lld%% · 已完成 %lld/%lld",
                percent,
                snapshot.completedCount,
                snapshot.totalCount
            )
        case .completed:
            return formatted(
                "processing.progress.completed",
                fallback: "已完成 %lld 张，结果已写回系统相册",
                snapshot.completedCount
            )
        case .partialSuccess:
            return formatted(
                "processing.progress.partial_success",
                fallback: "已完成 %lld 张，仍有 %lld 张需处理",
                snapshot.completedCount,
                snapshot.failedCount
            )
        case .needsAttention:
            return formatted(
                "processing.progress.needs_attention",
                fallback: "%lld 张需要回到时光记查看",
                snapshot.failedCount
            )
        case .unsupported:
            return localized(
                "processing.progress.unsupported",
                fallback: "这批照片当前不在支持范围内"
            )
        }
    }

    func attentionSummary(
        _ snapshot:
            MemoMarkBackgroundJobSnapshot
    ) -> String {

        if snapshot.feedbackState == .unsupported {
            return localized(
                "processing.attention.unsupported",
                fallback: "这批照片当前不在支持范围内，建议改用支持的照片格式再试。"
            )
        }

        if snapshot.canRetryFailures {
            return formatted(
                "processing.attention.retry",
                fallback: "本批次有 %lld 张未成功，可直接在这里重试失败项。",
                snapshot.failedCount
            )
        }

        return formatted(
            "processing.attention.failure",
            fallback: "本批次有 %lld 张未成功，当前更适合先查看失败原因。",
            snapshot.failedCount
        )
    }

    var interfaceLanguage: MemoMarkLanguage {
        MemoMarkInterfaceLanguagePreference(
            rawValue: interfaceLanguagePreferenceRawValue
        )?.resolvedLanguage ?? .interfaceStored
    }

    func localized(
        _ key: String,
        fallback: String
    ) -> String {
        interfaceLanguage.localized(
            key: key,
            fallback: fallback
        )
    }

    func formatted(
        _ key: String,
        fallback: String,
        _ arguments: CVarArg...
    ) -> String {
        String(
            format: localized(key, fallback: fallback),
            locale: interfaceLanguage.locale,
            arguments: arguments
        )
    }
}
#endif
