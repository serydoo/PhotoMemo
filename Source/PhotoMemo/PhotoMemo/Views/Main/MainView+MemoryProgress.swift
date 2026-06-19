import SwiftUI

struct MainMemoryProgressPanel: View {

    let snapshot: BatchUsageSnapshot

    let defaultConfigurationSnapshot:
        BatchConfigurationSnapshot

    let availableAlbums: [PhotoAlbumOption]

    let latestExternalIntakeSummary:
        ExternalIntakeSummary?

    let latestFailureSummary:
        BatchFailureSummary?

    let recentFailureRecords: [BatchFailureRecord]

    let retryFailedTasks: (UUID) -> Void

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            MainDismissibleGuideCard(
                storageKey:
                    "photomemo.guide.memoryProgress.dismissed",
                title: "记忆进度说明",
                message: "这里会累计 PhotoMemo 的处理进度、默认配置去向和最近的后台结果。如果你已经熟悉这块用途，可以直接关闭，完整说明会继续保留在右侧操作指南里。"
            )

            MinimalInsetCard {
                HStack(
                    alignment: .top,
                    spacing: 14
                ) {

                    VStack(
                        alignment: .leading,
                        spacing: 6
                    ) {

                        Text("记忆进度")
                            .font(.subheadline.weight(.medium))

                        Text(memoryProgressHeadline)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    VStack(
                        alignment: .trailing,
                        spacing: 6
                    ) {

                        progressStatLine(
                            title: "累计盖章",
                            value:
                                "\(snapshot.completedPhotoCount) 张"
                        )

                        progressStatLine(
                            title: "完成批次",
                            value:
                                "\(snapshot.completedBatchCount) 次"
                        )

                        progressStatLine(
                            title: "后台状态",
                            value: backgroundStatusTitle
                        )
                    }
                }

                Text(defaultConfigurationSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if let latestExternalIntakeSummary {

                    Text(
                        externalIntakeSummaryText(
                            latestExternalIntakeSummary
                        )
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                }

                if shouldShowInsights {

                    Divider()

                    VStack(
                        alignment: .leading,
                        spacing: 8
                    ) {

                        if let templateChampion =
                            snapshot.templateChampion {

                            Text("最常用模板“\(templateChampion.title)”已经陪你处理了 \(templateChampion.count) 张照片。")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        if let anchorChampion =
                            snapshot.anchorChampion {

                            Text("最常出现的时间点是“\(anchorChampion.title)”，目前已经用了 \(anchorChampion.count) 次。")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        if let lastCompletedAt =
                            snapshot.lastCompletedAt {

                            Text("最近一次完成：\(lastCompletedAt.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if let latestFailureSummary {

                            VStack(
                                alignment: .leading,
                                spacing: 8
                            ) {

                                Text(
                                    failureSummaryHeadline(
                                        latestFailureSummary
                                    )
                                )
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)

                                Text("失败阶段：\(latestFailureSummary.latestFailure.phaseTitle)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Text(
                                    latestFailureSummary
                                    .latestFailure.message
                                )
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)

                                HStack(spacing: 10) {

                                    if latestFailureSummary
                                        .hasRetryableFailures {
                                        Button("重试失败项") {
                                            retryFailedTasks(
                                                latestFailureSummary
                                                .jobID
                                            )
                                        }
                                        .buttonStyle(.bordered)
                                        .controlSize(.small)
                                    } else {
                                        Text("该失败项当前不可重试")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Text("最近更新：\(latestFailureSummary.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }

                        if !recentFailureRecords.isEmpty {

                            Divider()

                            VStack(
                                alignment: .leading,
                                spacing: 8
                            ) {

                                Text("最近失败记录")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.secondary)

                                ForEach(recentFailureRecords) {
                                    record in

                                    VStack(
                                        alignment: .leading,
                                        spacing: 4
                                    ) {

                                        Text(
                                            failureRecordHeadline(
                                                record
                                            )
                                        )
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)

                                        Text(record.failure.message)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var shouldShowInsights: Bool {

        snapshot.templateChampion != nil
            || snapshot.anchorChampion != nil
            || snapshot.lastCompletedAt != nil
            || snapshot.failedPhotoCount > 0
    }

    private var memoryProgressHeadline: String {

        if snapshot.completedPhotoCount == 0 {
            return "等你第一次处理完成后，这里会慢慢积累属于 PhotoMemo 的小记录。"
        }

        return "PhotoMemo 已经帮你把 \(snapshot.completedPhotoCount) 张照片整理成带记忆注脚的样子。"
    }

    private var backgroundStatusTitle: String {

        snapshot.activePhotoCount > 0
            ? "处理中 \(snapshot.activePhotoCount) 张"
            : "当前空闲"
    }

    private var defaultConfigurationSummary: String {

        let templateName =
            defaultConfigurationSnapshot.template
            .name
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .isEmpty
            ? defaultConfigurationSnapshot
                .template
                .preset.displayName
            : defaultConfigurationSnapshot
                .template.name

        let anchorTitle =
            {
                let trimmedTitle =
                    defaultConfigurationSnapshot
                    .anchor?.title
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ) ?? ""

                return trimmedTitle.isEmpty
                    ? "未设置时间点"
                    : trimmedTitle
            }()

        let albumTitle: String

        if defaultConfigurationSnapshot
            .selectedAlbumIdentifier.isEmpty {

            albumTitle = "自动存入 PhotoMemo"

        } else {

            albumTitle =
                availableAlbums.first {
                    $0.id
                    == defaultConfigurationSnapshot
                        .selectedAlbumIdentifier
                }?.title ?? "指定相册"
        }

        return "后台默认会沿用当前配置快照：模板“\(templateName)”，时间点“\(anchorTitle)”，相册“\(albumTitle)”。"
    }

    private func externalIntakeSummaryText(
        _ summary: ExternalIntakeSummary
    ) -> String {

        let sourceTitle: String

        switch summary.launchSource {

        case .inAppPreview:
            sourceTitle = "主界面"

        case .shareExtension:
            sourceTitle = "分享入口"

        case .fileOpen:
            sourceTitle = "打开文件"

        case .quickAction:
            sourceTitle = "快捷操作"

        case .automation:
            sourceTitle = "自动化"
        }

        let stateTitle: String

        switch summary.state {

        case .draft:
            stateTitle = "草稿"

        case .queued:
            stateTitle = "排队中"

        case .preparing:
            stateTitle = "准备中"

        case .ready:
            stateTitle = "待导出"

        case .running:
            stateTitle = "处理中"

        case .completed:
            stateTitle = "已完成"

        case .failed:
            stateTitle = "有失败项"

        case .cancelled:
            stateTitle = "已取消"
        }

        let anchorTitle =
            summary.anchorTitle
            ?? "未设置时间点"

        return "最近一次外部导入来自\(sourceTitle)：\(summary.taskCount) 张，当前\(stateTitle)。使用模板“\(summary.templateName)”，时间点“\(anchorTitle)”。"
    }

    private func failureRecordHeadline(
        _ record: BatchFailureRecord
    ) -> String {

        let retrySuffix =
            record.retryCount > 0
            ? " · 已重试\(record.retryCount)次"
            : ""

        return "《\(record.fileName)》在“\(record.jobTitle)”的\(record.failure.phaseTitle)阶段失败\(retrySuffix)。"
    }

    private func failureSummaryHeadline(
        _ summary: BatchFailureSummary
    ) -> String {

        if summary.completedTaskCount > 0,
           Double(summary.completedTaskCount)
            / Double(max(1, summary.totalTaskCount))
            >= 0.8 {
            return "“\(summary.jobTitle)”这批里大部分图片已经处理完成，另有 \(summary.failedTaskCount) 张作为例外未处理。"
        }

        return "最近有 \(summary.failedTaskCount) 张图片在“\(summary.jobTitle)”里处理失败。"
    }

    @ViewBuilder
    private func progressStatLine(
        title: String,
        value: String
    ) -> some View {

        HStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.caption.weight(.medium))
                .multilineTextAlignment(.trailing)
        }
    }
}
