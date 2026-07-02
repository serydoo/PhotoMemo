#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct PhotoMemoiOSBackgroundStatusHeroCard:
    View {

    let title: String
    let symbolName: String
    let snapshotTitle: String
    let statusMessage: String
    let displayMode: PhotoMemoBackgroundDisplayMode
    let queueLines: [String]
    let overflowQueueCount: Int
    let progressFraction: Double
    let progressSummary: String
    let launchSourceTitle: String
    let phaseTitle: String

    var body: some View {
        PhotoMemoiOSBackgroundCardChrome {
            VStack(
                alignment: .leading,
                spacing: 12
            ) {
                Label(
                    title,
                    systemImage:
                        symbolName
                )
                .font(.headline)

                Text(snapshotTitle)
                    .font(.subheadline.weight(.medium))

                Text(statusMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )

                if displayMode
                    != .singleTask {
                    queueLinesCard
                }

                ProgressView(
                    value:
                        progressFraction
                )

                Text(progressSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(
                    spacing: 10
                ) {
                    PhotoMemoiOSBackgroundStatusPill(
                        title: "来源",
                        value:
                            launchSourceTitle
                    )

                    PhotoMemoiOSBackgroundStatusPill(
                        title: "阶段",
                        value:
                            phaseTitle
                    )
                }
            }
        }
    }

    private var queueLinesCard: some View {
        VStack(
            alignment: .leading,
            spacing: 8
        ) {
            ForEach(
                Array(
                    queueLines
                    .prefix(3)
                    .enumerated()
                ),
                id: \.offset
            ) { _, line in
                Text(line)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            if overflowQueueCount > 0 {
                Text("另有 \(overflowQueueCount) 个队列")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding(12)
        .background(
            RoundedRectangle(
                cornerRadius: 12,
                style: .continuous
            )
            .fill(Color.secondary.opacity(0.08))
        )
    }
}

struct PhotoMemoiOSBackgroundPipelineCard:
    View {

    let steps: [PhotoMemoBackgroundPipelineStep]

    var body: some View {
        PhotoMemoiOSBackgroundCardChrome {
            VStack(
                alignment: .leading,
                spacing: 12
            ) {
                Text("处理流程")
                    .font(.headline)

                ForEach(
                    Array(
                        steps.enumerated()
                    ),
                    id: \.offset
                ) { _, step in
                    HStack(
                        alignment: .firstTextBaseline,
                        spacing: 10
                    ) {
                        Image(
                            systemName:
                                pipelineSymbolName(
                                    for: step.state
                                )
                        )
                        .foregroundStyle(
                            pipelineTint(
                                for: step.state
                            )
                        )
                        .frame(width: 18)

                        Text(step.title)
                            .font(
                                step.state == .active
                                ? .subheadline.weight(.semibold)
                                : .subheadline
                            )
                            .foregroundStyle(
                                step.state == .pending
                                ? .secondary
                                : .primary
                            )

                        Spacer(minLength: 8)
                    }
                }
            }
        }
    }

    private func pipelineSymbolName(
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

    private func pipelineTint(
        for state:
            PhotoMemoBackgroundPipelineStepState
    ) -> Color {

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
}

struct PhotoMemoiOSBackgroundProcessingFocusCard:
    View {

    let currentFileName: String?
    let jobStateTitle: String
    let updatedAt: Date
    let attentionSummary: String?

    var body: some View {
        PhotoMemoiOSBackgroundCardChrome {
            VStack(
                alignment: .leading,
                spacing: 10
            ) {
                Text("当前处理焦点")
                    .font(.headline)

                if let currentFileName {
                    PhotoMemoiOSBackgroundInfoRow(
                        title: "当前照片",
                        value:
                            currentFileName
                    )
                }

                PhotoMemoiOSBackgroundInfoRow(
                    title: "任务状态",
                    value:
                        jobStateTitle
                )

                PhotoMemoiOSBackgroundInfoRow(
                    title: "最近更新",
                    value:
                        updatedAt.formatted(
                            date: .abbreviated,
                            time: .shortened
                        )
                )

                if let attentionSummary {
                    Text(attentionSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(
                            horizontal: false,
                            vertical: true
                        )
                }
            }
        }
    }
}

struct PhotoMemoiOSBackgroundLatestFailureCard:
    View {

    let phaseTitle: String
    let message: String
    let updatedAt: Date

    var body: some View {
        PhotoMemoiOSBackgroundCardChrome {
            VStack(
                alignment: .leading,
                spacing: 8
            ) {
                Text("最近失败")
                    .font(.headline)

                Text("失败阶段：\(phaseTitle)")
                    .font(.subheadline.weight(.medium))

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )

                Text(
                    "最近更新：\(updatedAt.formatted(date: .abbreviated, time: .shortened))"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }
}

private struct PhotoMemoiOSBackgroundStatusPill:
    View {

    let title: String
    let value: String

    var body: some View {
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
}

private struct PhotoMemoiOSBackgroundInfoRow:
    View {

    let title: String
    let value: String

    var body: some View {
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
}

private struct PhotoMemoiOSBackgroundCardChrome<
    Content: View
>: View {

    let content: Content

    init(
        @ViewBuilder content: () -> Content
    ) {
        self.content =
            content()
    }

    var body: some View {
        content
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
}
#endif
