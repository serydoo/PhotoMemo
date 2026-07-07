#if os(iOS) && canImport(ActivityKit) && canImport(WidgetKit) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI
import ActivityKit
import WidgetKit

private enum PhotoMemoLiveActivityFeedbackState:
    String {

    case preparing

    case processing

    case completed

    case partialSuccess

    case needsAttention

    case unsupported
}

struct PhotoMemoLiveActivityWidgetDefinition:
    Widget {

    var body: some WidgetConfiguration {

        ActivityConfiguration(
            for:
                PhotoMemoBackgroundActivityAttributes
                .self
        ) { context in
            PhotoMemoLiveActivityLockScreenView(
                context: context
            )
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(
                    .leading
                ) {
                    PhotoMemoLiveActivityExpandedLeadingView(
                        context: context
                    )
                }

                DynamicIslandExpandedRegion(
                    .trailing
                ) {
                    PhotoMemoLiveActivityExpandedTrailingView(
                        context: context
                    )
                }

                DynamicIslandExpandedRegion(
                    .bottom
                ) {
                    PhotoMemoLiveActivityExpandedBottomView(
                        context: context
                    )
                }
            } compactLeading: {
                Image(
                    systemName:
                        compactSymbolName(
                            for: context
                        )
                )
                .foregroundStyle(
                    compactTint(
                        for: context
                    )
                )
            } compactTrailing: {
                Text(
                    "\(context.state.progressPercent)%"
                )
                .font(
                    .caption2
                    .monospacedDigit()
                )
            } minimal: {
                Image(
                    systemName:
                        compactSymbolName(
                            for: context
                        )
                )
                .foregroundStyle(
                    compactTint(
                        for: context
                    )
                )
            }
            .keylineTint(
                compactTint(
                    for: context
                )
            )
        }
    }
}

private struct PhotoMemoLiveActivityLockScreenView:
    View {

    let context:
        ActivityViewContext<
            PhotoMemoBackgroundActivityAttributes
        >

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            HStack(
                alignment: .center,
                spacing: 8
            ) {
                Label(
                    "时光记",
                    systemImage:
                        compactSymbolName(
                            for: context
                        )
                )
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .labelStyle(.titleAndIcon)
                .foregroundStyle(
                    compactTint(
                        for: context
                    )
                )

                Spacer(minLength: 10)

                Text(
                    "\(context.state.progressPercent)%"
                )
                .font(
                    .subheadline
                    .weight(.semibold)
                    .monospacedDigit()
                )
                .foregroundStyle(.secondary)
            }

            Text(
                primaryTitle(
                    for: context
                )
            )
            .font(.headline.weight(.semibold))
            .lineLimit(2)

            Text(
                context.attributes.jobTitle
            )
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
            .lineLimit(1)

            if isSingleTask(context) {
                Text(
                    statusLine(for: context)
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

                pipelineView(
                    for: context
                )
            } else {
                queueLinesView(
                    for: context,
                    font: .caption2,
                    secondaryFont: .caption2
                )
            }

            if context.state.presentationStateRawValue
                != "completed" {
                ProgressView(
                    value:
                        Double(
                            context.state
                            .progressPercent
                        ) / 100
                )
                .controlSize(.small)
            }

            if !isSingleTask(context) {
                HStack(
                    spacing: 12
                ) {
                    countPill(
                        title: "完成",
                        value:
                            "\(context.state.completedCount)"
                    )

                    countPill(
                        title: "失败",
                        value:
                            "\(context.state.failedCount)"
                    )

                    countPill(
                        title: "总数",
                        value:
                            "\(context.state.totalCount)"
                    )
                }
            }

            if context.isStale {
                Label(
                    "状态可能已过期，正在等待新进度",
                    systemImage:
                        "arrow.trianglehead.2.clockwise"
                )
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    func countPill(
        title: String,
        value: String
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 2
        ) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(value)
                .font(
                    .caption
                    .weight(.semibold)
                )
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(.white.opacity(0.1))
        )
    }
}

private struct PhotoMemoLiveActivityExpandedLeadingView:
    View {

    let context:
        ActivityViewContext<
            PhotoMemoBackgroundActivityAttributes
        >

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 4
        ) {
            Text("来源")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(
                context.attributes
                .launchSourceTitle
            )
            .font(.caption.weight(.semibold))

            Text(
                context.state.phaseTitle
            )
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }
}

private struct PhotoMemoLiveActivityExpandedTrailingView:
    View {

    let context:
        ActivityViewContext<
            PhotoMemoBackgroundActivityAttributes
        >

    var body: some View {

        VStack(
            alignment: .trailing,
            spacing: 4
        ) {
            Text(
                "\(context.state.progressPercent)%"
            )
            .font(
                .title3
                .weight(.semibold)
                .monospacedDigit()
            )

            Text(
                "\(context.state.completedCount)/\(context.state.totalCount)"
            )
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .frame(
            maxWidth: .infinity,
            alignment: .trailing
        )
    }
}

private struct PhotoMemoLiveActivityExpandedBottomView:
    View {

    let context:
        ActivityViewContext<
            PhotoMemoBackgroundActivityAttributes
        >

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 6
        ) {
            if let currentFileName =
                resolvedCurrentFileName(
                    for: context
                ) {
                Text(currentFileName)
                    .font(.caption.weight(.medium))
                    .lineLimit(1)
            }

            if isSingleTask(context) {
                Text(
                    statusLine(for: context)
                )
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)

                pipelineView(
                    for: context
                )
            } else {
                queueLinesView(
                    for: context,
                    font: .caption2,
                    secondaryFont: .caption2
                )
            }
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }
}

private func isSingleTask(
    _ context:
        ActivityViewContext<
            PhotoMemoBackgroundActivityAttributes
        >
) -> Bool {

    context.state.displayModeRawValue
    == "singleTask"
}

private func compactSymbolName(
    for context:
        ActivityViewContext<
            PhotoMemoBackgroundActivityAttributes
        >
) -> String {

    switch feedbackState(
        for: context
    ) {
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

private func compactTint(
    for context:
        ActivityViewContext<
            PhotoMemoBackgroundActivityAttributes
        >
) -> Color {

    switch feedbackState(
        for: context
    ) {
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

private func primaryTitle(
    for context:
        ActivityViewContext<
            PhotoMemoBackgroundActivityAttributes
        >
) -> String {

    switch feedbackState(
        for: context
    ) {
    case .preparing:
        return "正在准备照片"
    case .processing:
        if isSingleTask(context) {
            return context.state.phaseTitle
        }

        return "正在处理 \(context.state.totalCount) 张照片"
    case .completed:
        return "处理已完成"
    case .partialSuccess:
        return "部分照片已完成"
    case .needsAttention:
        return "有照片需要处理"
    case .unsupported:
        return "这批照片暂不支持处理"
    }
}

private func feedbackState(
    for context:
        ActivityViewContext<
            PhotoMemoBackgroundActivityAttributes
        >
) -> PhotoMemoLiveActivityFeedbackState {

    PhotoMemoLiveActivityFeedbackState(
        rawValue:
            context.state
            .feedbackStateRawValue
    )
    ?? fallbackFeedbackState(
        for: context
    )
}

private func fallbackFeedbackState(
    for context:
        ActivityViewContext<
            PhotoMemoBackgroundActivityAttributes
        >
) -> PhotoMemoLiveActivityFeedbackState {

    switch context.state
        .presentationStateRawValue {
    case "active":
        return .processing
    case "needsAttention":
        return .needsAttention
    case "completed":
        return .completed
    default:
        return .processing
    }
}

private func resolvedCurrentFileName(
    for context:
        ActivityViewContext<
            PhotoMemoBackgroundActivityAttributes
        >
) -> String? {

    let trimmedValue =
        context.state.currentFileName?
        .trimmingCharacters(
            in: .whitespacesAndNewlines
        ) ?? ""

    if trimmedValue.isEmpty {
        return nil
    }

    return trimmedValue
}

private func statusLine(
    for context:
        ActivityViewContext<
            PhotoMemoBackgroundActivityAttributes
        >
) -> String {

    let base =
        context.state.statusMessage
        .trimmingCharacters(
            in: .whitespacesAndNewlines
        )

    if base.isEmpty {
        return context.state.phaseTitle
    }

    return base
}

@ViewBuilder
private func pipelineView(
    for context:
        ActivityViewContext<
            PhotoMemoBackgroundActivityAttributes
        >
) -> some View {

    let titles =
        context.state.pipelineStepTitles
    let activeIndex =
        context.state.activePipelineStepIndex

    VStack(spacing: 0) {
        HStack(
            spacing: 4
        ) {
            ForEach(
                Array(titles.enumerated()),
                id: \.offset
            ) { index, title in
                Circle()
                    .fill(
                        pipelineStepTint(
                            index: index,
                            activeIndex: activeIndex,
                            context: context
                        )
                    )
                    .frame(
                        width: 5,
                        height: 5
                    )
                    .accessibilityLabel(title)

                if index < titles.count - 1 {
                    Capsule()
                        .fill(
                            Color.secondary
                                .opacity(
                                    index < activeIndex
                                    ? 0.38
                                    : 0.14
                                )
                        )
                        .frame(height: 1)
                }
            }
        }
        .padding(.horizontal, 6)
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(
        resolvedPipelineAccessibilityLabel(
            titles: titles,
            activeIndex: activeIndex
        )
    )
}

private func pipelineStepTint(
    index: Int,
    activeIndex: Int,
    context:
        ActivityViewContext<
            PhotoMemoBackgroundActivityAttributes
        >
) -> Color {

    let currentFeedbackState =
        feedbackState(
            for: context
        )

    if currentFeedbackState == .needsAttention
        || currentFeedbackState == .partialSuccess
        || currentFeedbackState == .unsupported,
       index == activeIndex {
        return .orange
    }

    if index < activeIndex
        || currentFeedbackState == .completed {
        return .green
    }

    if index == activeIndex {
        return .blue
    }

    return .secondary.opacity(0.35)
}

private func resolvedPipelineAccessibilityLabel(
    titles: [String],
    activeIndex: Int
) -> String {

    guard titles.indices.contains(activeIndex) else {
        return "处理进度"
    }

    return "当前步骤：\(titles[activeIndex])"
}

@ViewBuilder
private func queueLinesView(
    for context:
        ActivityViewContext<
            PhotoMemoBackgroundActivityAttributes
        >,
    font: Font,
    secondaryFont: Font
) -> some View {

    let lines =
        resolvedQueueLines(
            for: context
        )

    VStack(
        alignment: .leading,
        spacing: 4
    ) {
        ForEach(
            Array(lines.enumerated()),
            id: \.offset
        ) { _, line in
            Text(line)
                .font(font)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }

        if context.state.overflowQueueCount > 0 {
            Text("另有 \(context.state.overflowQueueCount) 个队列")
                .font(secondaryFont)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
        }
    }
    .fixedSize(
        horizontal: false,
        vertical: true
    )
}

private func resolvedQueueLines(
    for context:
        ActivityViewContext<
            PhotoMemoBackgroundActivityAttributes
        >
) -> [String] {

    let lines =
        context.state.queueLines
        .map {
            $0.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
        }
        .filter {
            !$0.isEmpty
        }

    if lines.isEmpty {
        return [
            statusLine(
                for: context
            )
        ]
    }

    return Array(
        lines.prefix(3)
    )
}
#endif
