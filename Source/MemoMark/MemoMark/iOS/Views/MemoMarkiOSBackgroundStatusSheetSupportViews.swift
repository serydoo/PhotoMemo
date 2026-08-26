#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI

struct MemoMarkiOSBackgroundStatusHeroCard:
    View {

    let language: MemoMarkLanguage
    let title: String
    let symbolName: String
    let snapshotTitle: String
    let statusMessage: String
    let displayMode: MemoMarkBackgroundDisplayMode
    let queueLines: [String]
    let overflowQueueCount: Int
    let progressFraction: Double
    let progressSummary: String
    let launchSourceTitle: String
    let phaseTitle: String

    var body: some View {
        MemoMarkiOSBackgroundCardChrome {
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
                    MemoMarkiOSBackgroundStatusPill(
                        title: language.localized(key: "processing.source", fallback: "来源"),
                        value:
                            launchSourceTitle
                    )

                    MemoMarkiOSBackgroundStatusPill(
                        title: language.localized(key: "processing.phase", fallback: "阶段"),
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
                Text(String(
                    format: language.localized(
                        key: "processing.queue_overflow_format",
                        fallback: "另有 %lld 个队列"
                    ),
                    locale: language.locale,
                    Int64(overflowQueueCount)
                ))
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

struct MemoMarkiOSBackgroundPipelineCard:
    View {

    let language: MemoMarkLanguage
    let steps: [MemoMarkBackgroundPipelineStep]

    var body: some View {
        MemoMarkiOSBackgroundCardChrome {
            VStack(
                alignment: .leading,
                spacing: 12
            ) {
                Text(language.localized(
                    key: "processing.pipeline.title",
                    fallback: "处理流程"
                ))
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
            MemoMarkBackgroundPipelineStepState
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
            MemoMarkBackgroundPipelineStepState
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

struct MemoMarkiOSBackgroundProcessingFocusCard:
    View {

    let language: MemoMarkLanguage
    let currentFileName: String?
    let jobStateTitle: String
    let updatedAt: Date
    let attentionSummary: String?

    var body: some View {
        MemoMarkiOSBackgroundCardChrome {
            VStack(
                alignment: .leading,
                spacing: 10
            ) {
                Text(language.localized(
                    key: "processing.focus.title",
                    fallback: "当前处理焦点"
                ))
                    .font(.headline)

                if let currentFileName {
                    MemoMarkiOSBackgroundInfoRow(
                        title: language.localized(key: "processing.focus.photo", fallback: "当前照片"),
                        value:
                            currentFileName
                    )
                }

                MemoMarkiOSBackgroundInfoRow(
                    title: language.localized(key: "processing.focus.task", fallback: "任务状态"),
                    value:
                        jobStateTitle
                )

                MemoMarkiOSBackgroundInfoRow(
                    title: language.localized(key: "processing.focus.updated", fallback: "最近更新"),
                    value:
                        V1UserFacingDateFormatter.dateTime(
                            updatedAt
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

struct MemoMarkiOSBackgroundLatestFailureCard:
    View {

    let language: MemoMarkLanguage
    let phaseTitle: String
    let message: String
    let updatedAt: Date

    var body: some View {
        MemoMarkiOSBackgroundCardChrome {
            VStack(
                alignment: .leading,
                spacing: 8
            ) {
                Text(language.localized(
                    key: "processing.failure.title",
                    fallback: "最近失败"
                ))
                    .font(.headline)

                Text(String(
                    format: language.localized(
                        key: "processing.failure.phase_format",
                        fallback: "失败阶段：%@"
                    ),
                    locale: language.locale,
                    phaseTitle
                ))
                    .font(.subheadline.weight(.medium))

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )

                Text(String(
                    format: language.localized(
                        key: "processing.failure.updated_format",
                        fallback: "最近更新：%@"
                    ),
                    locale: language.locale,
                    V1UserFacingDateFormatter.dateTime(updatedAt)
                ))
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }
}

private struct MemoMarkiOSBackgroundStatusPill:
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

private struct MemoMarkiOSBackgroundInfoRow:
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

private struct MemoMarkiOSBackgroundCardChrome<
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
