#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct V1TaskPageSurface: View {

    let header: PhotoMemoiOSQueueDiagnosticsHeaderProjection
    let snapshot: PhotoMemoBackgroundJobSnapshot?
    let recoveryMessage: String?
    let events: [PhotoMemoShareDiagnosticEvent]
    let onRefresh: () -> Void
    let onClearCompletedHistory: () -> Void
    let onDismissKeyboard: () -> Void

    private var presentation:
        V1SettingsPagePresentation {
        V1SettingsPagePresenter
            .presentation(
                header: header,
                snapshot: snapshot,
                recoveryMessage: recoveryMessage,
                events: events
            )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                currentTaskSection
                historySection
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 34)
        }
        .scrollDismissesKeyboard(.interactively)
        .simultaneousGesture(
            TapGesture()
                .onEnded {
                    onDismissKeyboard()
                }
        )
        .background(
            ConfigurationUI.appBackground
                .ignoresSafeArea()
        )
        .navigationTitle("任务")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var currentTaskSection: some View {
        V1CardSurface(title: "当前处理") {
            VStack(alignment: .leading, spacing: 14) {
                Text("这里集中查看当前批次的处理状态、结果回执和需要你介入的项目。原图不会被修改，生成结果仍按既有本地流程写回目标位置。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(alignment: .top, spacing: 14) {
                    currentTaskThumbnail

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .center, spacing: 10) {
                            Text(presentation.currentTask.headline)
                                .font(.headline.weight(.semibold))
                                .fixedSize(horizontal: false, vertical: true)

                            Spacer(minLength: 0)

                            taskStatusPill(
                                title: presentation.currentTask.statusText,
                                tint:
                                    presentation
                                    .currentTask
                                    .tint
                            )
                        }

                        Text(presentation.currentTask.subtitleText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        taskMetaFlow

                        if let progressFraction =
                            presentation
                            .currentTask
                            .progressFraction {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 8) {
                                    Text("当前进度")
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(.secondary)

                                    Spacer(minLength: 0)

                                    Text(
                                        progressPercentText(
                                            progressFraction
                                        )
                                    )
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(
                                        presentation
                                        .currentTask
                                        .tint
                                        .color
                                    )
                                }

                                ProgressView(value: progressFraction)
                                    .progressViewStyle(.linear)
                                    .tint(
                                        presentation
                                        .currentTask
                                        .tint
                                        .color
                                    )
                            }
                        }

                        Text(presentation.currentTask.detailText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(
                                    cornerRadius: 12,
                                    style: .continuous
                                )
                                .fill(
                                    ConfigurationUI
                                    .controlBackground
                                    .opacity(0.78)
                                )
                            )
                    }
                }

                HStack(spacing: 10) {
                    Button(action: onRefresh) {
                        Label("刷新状态", systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    if presentation.canClearCompletedHistory {
                        Button(action: onClearCompletedHistory) {
                            Label("清理历史", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
    }

    private var historySection: some View {
        V1CardSurface(title: "最近记录") {
            VStack(alignment: .leading, spacing: 12) {
                Text("按行查看最近的接收、交接、完成和需处理结果。这里展示结果摘要，详细原因仍以当前批次状态页为准。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if presentation.historyRows.isEmpty {
                    emptyHistoryState
                } else {
                    VStack(spacing: 10) {
                        ForEach(
                            presentation.historyRows
                        ) { row in
                            historyRow(
                                row
                            )
                        }
                    }
                }
            }
        }
    }

    private var currentTaskThumbnail: some View {
        ZStack {
            RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
            .fill(
                LinearGradient(
                    colors: [
                        presentation.currentTask.tint.color.opacity(0.22),
                        Color.white,
                        presentation.currentTask.tint.color.opacity(0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 98, height: 126)
            .overlay(
                RoundedRectangle(
                    cornerRadius: 22,
                    style: .continuous
                )
                .stroke(ConfigurationUI.faintHairline)
            )

            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(
                        cornerRadius: 18,
                        style: .continuous
                    )
                    .fill(
                        presentation
                            .currentTask
                            .tint
                            .color
                            .opacity(0.14)
                    )
                    .frame(width: 56, height: 56)

                    Image(systemName: presentation.currentTask.thumbnailSymbolName)
                        .font(.system(size: 27, weight: .semibold))
                        .foregroundStyle(
                            presentation.currentTask.tint.color
                        )
                }

                Text(
                    presentation.currentTask.itemCountText
                    ?? presentation.currentTask.statusText
                )
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.horizontal, 8)
            }
            .frame(width: 98, height: 126)
        }
    }

    private var emptyHistoryState: some View {
        HStack(alignment: .center, spacing: 12) {
            RoundedRectangle(
                cornerRadius: 12,
                style: .continuous
            )
            .fill(ConfigurationUI.controlBackground)
            .frame(width: 52, height: 52)
            .overlay {
                Image(systemName: "clock.badge.questionmark")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("还没有可展示的最近记录")
                    .font(.subheadline.weight(.semibold))

                Text("下一次从 Apple Photos 分享照片后，这里会开始按时间沉淀最近的处理状态。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(
                cornerRadius: 14,
                style: .continuous
            )
            .fill(ConfigurationUI.controlBackground.opacity(0.78))
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 14,
                style: .continuous
            )
            .stroke(ConfigurationUI.faintHairline)
        )
    }

    private func historyRow(
        _ row:
            V1SettingsHistoryRowPresentation
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            historyThumbnail(
                row
            )

            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .center, spacing: 8) {
                    Text(row.title)
                        .font(.subheadline.weight(.semibold))

                    Spacer(minLength: 0)

                    taskStatusPill(
                        title: row.statusText,
                        tint: row.tint
                    )
                }

                Text(row.detailText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    taskInfoChip(
                        title:
                            row.timestamp.formatted(
                                date: .omitted,
                                time: .shortened
                            ),
                        systemImage: "clock"
                    )

                    if let itemCountText =
                        row.itemCountText {
                        taskInfoChip(
                            title: itemCountText,
                            systemImage: "photo.stack"
                        )
                    }

                    taskInfoChip(
                        title: row.statusText,
                        systemImage: row.symbolName
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(
                cornerRadius: 16,
                style: .continuous
            )
            .fill(ConfigurationUI.controlBackground.opacity(0.82))
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 16,
                style: .continuous
            )
            .stroke(ConfigurationUI.faintHairline)
        )
    }

    private var taskMetaFlow: some View {
        ViewThatFits(in: .vertical) {
            HStack(spacing: 8) {
                taskMetaChips
            }

            VStack(alignment: .leading, spacing: 8) {
                taskMetaChips
            }
        }
    }

    @ViewBuilder
    private var taskMetaChips: some View {
        if let itemCountText =
            presentation
            .currentTask
            .itemCountText {
            taskInfoChip(
                title: itemCountText,
                systemImage: "photo.on.rectangle"
            )
        }

        if let progressText =
            presentation
            .currentTask
            .progressText {
            taskInfoChip(
                title: progressText,
                systemImage: "chart.bar.fill"
            )
        }

        if let updatedAt =
            presentation
            .currentTask
            .updatedAt {
            taskInfoChip(
                title:
                    updatedAt
                    .formatted(
                        date: .omitted,
                        time: .shortened
                    ),
                systemImage: "clock"
            )
        }
    }

    private func historyThumbnail(
        _ row:
            V1SettingsHistoryRowPresentation
    ) -> some View {
        ZStack {
            RoundedRectangle(
                cornerRadius: 14,
                style: .continuous
            )
            .fill(
                LinearGradient(
                    colors: [
                        row.tint.color.opacity(0.22),
                        Color.white
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 62, height: 74)
            .overlay(
                RoundedRectangle(
                    cornerRadius: 14,
                    style: .continuous
                )
                .stroke(ConfigurationUI.faintHairline)
            )

            VStack(spacing: 6) {
                Image(systemName: row.symbolName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(row.tint.color)

                Text(
                    row.itemCountText
                    ?? row.statusText
                )
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 6)
            }
            .frame(width: 62, height: 74)
        }
        .frame(width: 72, height: 80)
    }

    private func progressPercentText(
        _ fraction: Double
    ) -> String {
        "\(Int((fraction * 100).rounded()))%"
    }

    private func taskStatusPill(
        title: String,
        tint:
            PhotoMemoiOSQueueDiagnosticsTint
    ) -> some View {
        Text(title)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(tint.color)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(
                Capsule(style: .continuous)
                    .fill(tint.color.opacity(0.14))
            )
    }

    private func taskInfoChip(
        title: String,
        systemImage: String
    ) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption2.weight(.medium))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(ConfigurationUI.controlBackground)
            )
    }
}
#endif
