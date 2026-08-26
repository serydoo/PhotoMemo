#if os(iOS) && canImport(ActivityKit) && canImport(WidgetKit) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI
import ActivityKit
import WidgetKit

private enum MemoMarkLiveActivityFeedbackState:
    String {

    case preparing

    case processing

    case completed

    case partialSuccess

    case needsAttention

    case unsupported
}

struct MemoMarkLiveActivityWidgetDefinition:
    Widget {

    var body: some WidgetConfiguration {

        ActivityConfiguration(
            for:
                MemoMarkBackgroundActivityAttributes
                .self
        ) { context in
            MemoMarkLiveActivityLockScreenView(
                context: context
            )
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(
                    .leading
                ) {
                    MemoMarkLiveActivityExpandedLeadingView(
                        context: context
                    )
                }

                DynamicIslandExpandedRegion(
                    .trailing
                ) {
                    MemoMarkLiveActivityExpandedTrailingView(
                        context: context
                    )
                }

                DynamicIslandExpandedRegion(
                    .bottom
                ) {
                    MemoMarkLiveActivityExpandedBottomView(
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

private struct MemoMarkLiveActivityLockScreenView:
    View {

    let context:
        ActivityViewContext<
            MemoMarkBackgroundActivityAttributes
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
                    widgetLocalized(
                        "widget.brand",
                        fallback: "MemoMark"
                    ),
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
                        title: widgetLocalized(
                            "widget.count.completed",
                            fallback: "Completed"
                        ),
                        value:
                            "\(context.state.completedCount)"
                    )

                    countPill(
                        title: widgetLocalized(
                            "widget.count.failed",
                            fallback: "Failed"
                        ),
                        value:
                            "\(context.state.failedCount)"
                    )

                    countPill(
                        title: widgetLocalized(
                            "widget.count.total",
                            fallback: "Total"
                        ),
                        value:
                            "\(context.state.totalCount)"
                    )
                }
            }

            if context.isStale {
                Label(
                    widgetLocalized(
                        "widget.stale",
                        fallback: "This status may be out of date while new progress is pending"
                    ),
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

private struct MemoMarkLiveActivityExpandedLeadingView:
    View {

    let context:
        ActivityViewContext<
            MemoMarkBackgroundActivityAttributes
        >

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 4
        ) {
            Text(
                widgetLocalized(
                    "widget.source",
                    fallback: "Source"
                )
            )
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

private struct MemoMarkLiveActivityExpandedTrailingView:
    View {

    let context:
        ActivityViewContext<
            MemoMarkBackgroundActivityAttributes
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

private struct MemoMarkLiveActivityExpandedBottomView:
    View {

    let context:
        ActivityViewContext<
            MemoMarkBackgroundActivityAttributes
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
            MemoMarkBackgroundActivityAttributes
        >
) -> Bool {

    context.state.displayModeRawValue
    == "singleTask"
}

private func compactSymbolName(
    for context:
        ActivityViewContext<
            MemoMarkBackgroundActivityAttributes
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
            MemoMarkBackgroundActivityAttributes
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
            MemoMarkBackgroundActivityAttributes
        >
) -> String {

    switch feedbackState(
        for: context
    ) {
    case .preparing:
        return widgetLocalized(
            "widget.title.preparing",
            fallback: "Preparing Photos"
        )
    case .processing:
        if isSingleTask(context) {
            return context.state.phaseTitle
        }

        return widgetFormatted(
            "widget.title.processing_format",
            fallback: "Processing %lld Photos",
            Int64(context.state.totalCount)
        )
    case .completed:
        return widgetLocalized(
            "widget.title.completed",
            fallback: "Processing Complete"
        )
    case .partialSuccess:
        return widgetLocalized(
            "widget.title.partial_success",
            fallback: "Some Photos Completed"
        )
    case .needsAttention:
        return widgetLocalized(
            "widget.title.needs_attention",
            fallback: "Some Photos Need Attention"
        )
    case .unsupported:
        return widgetLocalized(
            "widget.title.unsupported",
            fallback: "This Batch Is Not Supported"
        )
    }
}

private func feedbackState(
    for context:
        ActivityViewContext<
            MemoMarkBackgroundActivityAttributes
        >
) -> MemoMarkLiveActivityFeedbackState {

    MemoMarkLiveActivityFeedbackState(
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
            MemoMarkBackgroundActivityAttributes
        >
) -> MemoMarkLiveActivityFeedbackState {

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
            MemoMarkBackgroundActivityAttributes
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
            MemoMarkBackgroundActivityAttributes
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
            MemoMarkBackgroundActivityAttributes
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
            MemoMarkBackgroundActivityAttributes
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
        return widgetLocalized(
            "widget.accessibility.progress",
            fallback: "Processing progress"
        )
    }

    return widgetFormatted(
        "widget.accessibility.current_step",
        fallback: "Current step: %@",
        titles[activeIndex]
    )
}

@ViewBuilder
private func queueLinesView(
    for context:
        ActivityViewContext<
            MemoMarkBackgroundActivityAttributes
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
            Text(
                widgetFormatted(
                    "widget.queue.overflow_format",
                    fallback: "%lld more queued",
                    Int64(context.state.overflowQueueCount)
                )
            )
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
            MemoMarkBackgroundActivityAttributes
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

private func widgetLocalized(
    _ key: String,
    fallback: String
) -> String {
    MemoMarkLanguage.interfaceStored.localized(
        key: key,
        fallback: fallback
    )
}

private func widgetFormatted(
    _ key: String,
    fallback: String,
    _ arguments: CVarArg...
) -> String {
    String(
        format: widgetLocalized(key, fallback: fallback),
        locale: MemoMarkLanguage.interfaceStored.locale,
        arguments: arguments
    )
}
#endif
