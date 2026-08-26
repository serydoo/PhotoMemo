#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import ImageIO
import SwiftUI
import UIKit

struct V1TaskPageSurface: View {

    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize

    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass

    @Environment(\.verticalSizeClass)
    private var verticalSizeClass

    let header: MemoMarkiOSQueueDiagnosticsHeaderProjection
    let snapshot: MemoMarkBackgroundJobSnapshot?
    let taskOverview: MemoMarkBackgroundTaskOverview
    let recentJobSummaries: [MemoMarkBackgroundJobSummary]
    let recoveryMessage: String?
    let events: [MemoMarkShareDiagnosticEvent]
    let fallbackConfigurationName: String
    let onOpenPhotoLibrary: (V1TaskPhotoLibraryLink) -> Void
    let onRetryFailedTasks: () -> Void
    let onDismissKeyboard: () -> Void

    private var interfaceLanguage: MemoMarkLanguage {
        .interfaceStored
    }

    @State
    private var isRecentTasksSheetPresented = false

    private var presentation:
        V1SettingsPagePresentation {
        V1SettingsPagePresenter
            .presentation(
                header: header,
                snapshot: snapshot,
                recoveryMessage: recoveryMessage,
                events: events,
                overview: taskOverview,
                recentJobs: recentJobSummaries,
                fallbackConfigurationName:
                    fallbackConfigurationName,
                language: interfaceLanguage
            )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                pageHeader
                currentTaskCard
                recentTasksSection
            }
            .padding(.top, 10)
            .padding(
                .bottom,
                V1AdaptivePageLayout
                    .scrollBottomPadding(
                        for: navigationStyle
                    )
            )
            .v1AdaptiveScrollContent(
                horizontalPadding: ConfigurationUI.contentColumnPadding
            )
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
        .navigationTitle("")
        .toolbar(.hidden, for: .navigationBar)
        .sheet(
            isPresented: $isRecentTasksSheetPresented
        ) {
            recentTasksSheet
        }
    }

    private var navigationStyle:
        V1EntryNavigationStyle {
        V1AdaptivePageLayout.navigationStyle(
            isPad:
                UIDevice.current
                .userInterfaceIdiom == .pad,
            hasRegularHorizontalSizeClass:
                horizontalSizeClass == .regular,
            hasCompactVerticalSizeClass:
                verticalSizeClass == .compact
        )
    }

    private var pageHeader: some View {
        V1PageHeader(
            interfaceLanguage.localized(
                key: "task.page.title",
                fallback: "进展"
            ),
            subtitle: interfaceLanguage.localized(
                key: "task.page.subtitle",
                fallback: "从 Apple Photos 分享后，可以在这里看到是否已经完成。"
            )
        )
    }

    @ViewBuilder
    private var currentTaskCard: some View {
        switch presentation.currentTask.displayMode {
        case .waiting:
            waitingTaskCard
        case .processing:
            processingTaskCard
        case .completed:
            completedResultCard
        case .needsAttention:
            needsAttentionTaskCard
        }
    }

    private var waitingTaskCard: some View {
        V1TitledSectionCard(
            title: interfaceLanguage.localized(
                key: "task.waiting.card.title",
                fallback: "准备好了"
            ),
            subtitle: interfaceLanguage.localized(
                key: "task.waiting.card.subtitle",
                fallback: "从 Apple Photos 分享照片后，可以在这里看到是否已经完成。"
            )
        ) {
            HStack(spacing: 12) {
                Image(systemName: "photo.badge.plus")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(
                                ConfigurationUI.controlBackground
                            )
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(
                        interfaceLanguage.localized(
                            key: "task.waiting.ready",
                            fallback: "准备就绪"
                        )
                    )
                        .font(.subheadline.weight(.semibold))

                    Text(
                        interfaceLanguage.localized(
                            key: "task.waiting.detail",
                            fallback: "从 Apple Photos 分享照片，即可开始生成。"
                        )
                    )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 4)
        }
    }

    private var processingTaskCard: some View {
        V1TitledSectionCard(
            title: interfaceLanguage.localized(
                key: "task.processing.title",
                fallback: "正在处理"
            ),
            subtitle: interfaceLanguage.localized(
                key: "task.processing.subtitle",
                fallback: "完成后会自动保存到 Apple Photos。"
            )
        ) {
            taskStatusPill(
                title: presentation.currentTask.statusText,
                tint: presentation.currentTask.tint
            )
        } content: {
            currentTaskSummary

            if presentation.currentTask.stepRows.count > 1 {
                pipelineDetailsDisclosure
            }
        }
    }

    private var completedResultCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(
                        interfaceLanguage.localized(
                            key: "task.completed.title",
                            fallback: "刚刚完成"
                        )
                    )
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .accessibilityAddTraits(.isHeader)

                    Text(
                        interfaceLanguage.localized(
                            key: "task.completed.subtitle",
                            fallback: "已生成并保存到 Apple Photos。"
                        )
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                taskStatusPill(
                    title: presentation.currentTask.statusText,
                    tint: presentation.currentTask.tint
                )
            }
            .padding(.horizontal, 4)

            VStack(spacing: 0) {
                completedResultSummary

                if presentation.currentTask.photoLibraryLink != nil {
                    V1HorizontalDivider(horizontalInset: 4)
                    photoLibraryLinkRow
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .v1CardChrome()
        }
    }

    private var needsAttentionTaskCard: some View {
        V1TitledSectionCard(
            title: interfaceLanguage.localized(
                key: "task.attention.title",
                fallback: "需要处理"
            ),
            subtitle: presentation.currentTask.detailText
        ) {
            taskStatusPill(
                title: presentation.currentTask.statusText,
                tint: presentation.currentTask.tint
            )
        } content: {
            attentionTaskSummary

            if !presentation.currentTask.stepRows.isEmpty {
                pipelineRows
            }

            if presentation.currentTask.canRetryFailures {
                Button(
                    interfaceLanguage.localized(
                        key: "task.retry",
                        fallback: "再次尝试"
                    ),
                    action: onRetryFailedTasks
                )
                .buttonStyle(.borderedProminent)
                .accessibilityHint(
                    interfaceLanguage.localized(
                        key: "task.retry.hint",
                        fallback: "重新处理这次失败的照片"
                    )
                )
            }
        }
    }

    private var currentTaskSummary: some View {
        HStack(alignment: .center, spacing: 12) {
            taskThumbnail(
                url:
                    presentation
                    .currentTask
                    .previewSourceURL,
                symbolName:
                    presentation
                    .currentTask
                    .thumbnailSymbolName,
                tint:
                    presentation.currentTask.tint,
                size:
                    CGSize(width: 64, height: 64)
            )

            VStack(alignment: .leading, spacing: 6) {
                Text(presentation.currentTask.headline)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(taskSummarySubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 2)
                    .fixedSize(horizontal: false, vertical: true)

                currentProgressLine
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(10)
        .background(
            RoundedRectangle(
                cornerRadius: 16,
                style: .continuous
            )
            .fill(ConfigurationUI.controlBackground.opacity(0.54))
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 16,
                style: .continuous
            )
            .stroke(ConfigurationUI.faintHairline)
        )
    }

    private var completedResultSummary: some View {
        HStack(alignment: .center, spacing: 12) {
            taskThumbnail(
                url: presentation.currentTask.previewSourceURL,
                symbolName: presentation.currentTask.thumbnailSymbolName,
                tint: .secondary,
                size: CGSize(width: 56, height: 56),
                itemCount: presentation.currentTask.totalCount
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(presentation.currentTask.headline)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(taskSummarySubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 2)
                    .fixedSize(horizontal: false, vertical: true)

                if let updatedAt = presentation.currentTask.updatedAt {
                    Label(
                        V1UserFacingDateFormatter.dateTime(updatedAt),
                        systemImage: "clock"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 4)
    }

    private var attentionTaskSummary: some View {
        HStack(alignment: .center, spacing: 12) {
            taskThumbnail(
                url: presentation.currentTask.previewSourceURL,
                symbolName: presentation.currentTask.thumbnailSymbolName,
                tint: presentation.currentTask.tint,
                size: CGSize(width: 56, height: 56),
                itemCount: presentation.currentTask.totalCount
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(presentation.currentTask.headline)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(presentation.currentTask.detailText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 4)
    }

    private var taskSummarySubtitle: String {
        guard presentation.currentTask.itemCountText != nil else {
            return presentation.currentTask.subtitleText
        }

        let styleText = String(
            format: interfaceLanguage.localized(
                key: "task.style.format",
                fallback: "%@ style"
            ),
            locale: interfaceLanguage.locale,
            presentation.currentTask.templateName
        )
        let processedCountText = String(
            format: interfaceLanguage.localized(
                key: "task.processed_count.format",
                fallback: "Processed %@"
            ),
            locale: interfaceLanguage.locale,
            presentation.currentTask.itemCountText ?? ""
        )

        return [styleText, processedCountText]
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }

    private var currentProgressLine: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 8) {
                Text(
                    presentation.currentTask.progressText
                    ?? presentation.currentTask.itemCountText
                    ?? interfaceLanguage.localized(
                        key: "task.progress.waiting",
                        fallback: "等待照片进入处理"
                    )
                )
                .font(.caption.weight(.medium))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }

            if let progressFraction =
                presentation.currentTask.progressFraction {
                ProgressView(value: progressFraction)
                    .progressViewStyle(.linear)
                    .tint(presentation.currentTask.tint.color)
                    .accessibilityLabel(
                        interfaceLanguage.localized(
                            key: "task.progress.accessibility",
                            fallback: "当前任务进度"
                        )
                    )
                    .accessibilityValue(
                        presentation.currentTask.progressText
                        ?? presentation.currentTask.itemCountText
                        ?? interfaceLanguage.localized(
                            key: "task.progress.processing",
                            fallback: "处理中"
                        )
                    )
            } else {
                ProgressView()
                    .progressViewStyle(.linear)
                    .tint(presentation.currentTask.tint.color)
                    .accessibilityLabel(
                        interfaceLanguage.localized(
                            key: "task.processing.accessibility",
                            fallback: "当前任务正在处理"
                        )
                    )
            }
        }
    }

    private var pipelineDetailsDisclosure: some View {
        DisclosureGroup(
            interfaceLanguage.localized(
                key: "task.pipeline.title",
                fallback: "本次进展"
            )
        ) {
            pipelineRows
                .padding(.top, 8)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
        .tint(.secondary)
    }

    private var pipelineRows: some View {
        VStack(spacing: 0) {
            ForEach(
                presentation.currentTask.stepRows
            ) { step in
                pipelineRow(step)

                if step.id != presentation.currentTask.stepRows.last?.id {
                    V1HorizontalDivider(horizontalInset: 10)
                }
            }
        }
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(
                cornerRadius: 14,
                style: .continuous
            )
            .fill(ConfigurationUI.controlBackground.opacity(0.36))
        )
    }

    private func pipelineRow(
        _ step: V1TaskPipelineStepPresentation
    ) -> some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) {
                        pipelineStepIcon(step)
                        pipelineStepTitle(step)
                    }
                    pipelineStepStatus(step)
                }
            } else {
                HStack(spacing: 10) {
                    pipelineStepIcon(step)
                    pipelineStepTitle(step)
                    pipelineStepStatus(step)
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .frame(minHeight: 28)
        .accessibilityElement(children: .combine)
    }

    private func pipelineStepIcon(
        _ step: V1TaskPipelineStepPresentation
    ) -> some View {
        Image(systemName: step.symbolName)
            .font(.caption2.weight(.bold))
            .foregroundStyle(step.tint.color)
            .frame(width: 16, height: 16)
    }

    private func pipelineStepTitle(
        _ step: V1TaskPipelineStepPresentation
    ) -> some View {
        Text(step.title)
            .font(
                .callout
                .weight(
                    step.emphasizesTitle
                    ? .semibold
                    : .regular
                )
            )
            .foregroundStyle(step.tint == .secondary ? .secondary : .primary)
            .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 2)
    }

    private func pipelineStepStatus(
        _ step: V1TaskPipelineStepPresentation
    ) -> some View {
        Text(step.statusText)
            .font(.caption.weight(.medium))
            .foregroundStyle(step.tint.color)
            .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 2)
    }

    private var recentTasksSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(
                        interfaceLanguage.localized(
                            key: "task.recent.title",
                            fallback: "最近保存"
                        )
                    )
                    .font(.headline.weight(.semibold))

                    Text(
                        interfaceLanguage.localized(
                            key: "task.recent.subtitle",
                            fallback: "最近完成的回忆会在这里出现。"
                        )
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                if presentation.historyRows.count > inlineHistoryRows.count {
                    V1CardHeaderIconButton(
                        systemImage: "ellipsis",
                        accessibilityLabel: interfaceLanguage.localized(
                            key: "task.recent.more",
                            fallback: "查看更多最近保存的回忆"
                        )
                    ) {
                        isRecentTasksSheetPresented = true
                    }
                }
            }
            .padding(.horizontal, 4)

            if presentation.historyRows.isEmpty {
                emptyRecentState
            } else {
                groupedRecentHistory
            }
        }
    }

    private var inlineHistoryRows:
        [V1SettingsHistoryRowPresentation] {
        Array(presentation.historyRows.prefix(4))
    }

    private var groupedRecentHistory: some View {
        VStack(spacing: 0) {
            ForEach(
                Array(groupedHistoryRows.enumerated()),
                id: \.element.id
            ) { groupIndex, group in
                historyGroupHeader(
                    title: group.title,
                    isFirst: groupIndex == 0
                )

                ForEach(group.rows) { row in
                    recentTaskRow(row)

                    if row.id != group.rows.last?.id {
                        V1HorizontalDivider(
                            horizontalInset:
                                V1CompactInformationRowMetrics
                                .horizontalPadding
                        )
                    }
                }
            }
        }
        .v1CardChrome()
    }

    private var groupedHistoryRows:
        [V1TaskHistoryGroup] {
        let calendar = Calendar.autoupdatingCurrent
        let rowsByDay = Dictionary(
            grouping: inlineHistoryRows
        ) { row in
            calendar.startOfDay(for: row.timestamp)
        }

        return rowsByDay.keys
            .sorted(by: >)
            .map { date in
                V1TaskHistoryGroup(
                    id: date,
                    title: historyGroupTitle(for: date),
                    rows: rowsByDay[date] ?? []
                )
            }
    }

    private func historyGroupHeader(
        title: String,
        isFirst: Bool
    ) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Rectangle()
                .fill(ConfigurationUI.faintHairline)
                .frame(height: 1)
        }
        .padding(.horizontal, 12)
        .padding(.top, isFirst ? 12 : 16)
        .padding(.bottom, 4)
    }

    private func historyGroupTitle(for date: Date) -> String {
        let calendar = Calendar.autoupdatingCurrent

        if calendar.isDateInToday(date) {
            return interfaceLanguage.localized(
                key: "task.history.today",
                fallback: "今天"
            )
        }

        if calendar.isDateInYesterday(date) {
            return interfaceLanguage.localized(
                key: "task.history.yesterday",
                fallback: "昨天"
            )
        }

        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = interfaceLanguage.locale
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private var recentTasksSheet: some View {
        NavigationStack {
            List(presentation.historyRows) { row in
                recentTaskRow(row)
                    .listRowSeparator(.visible)
            }
            .listStyle(.plain)
            .navigationTitle(
                interfaceLanguage.localized(
                    key: "task.recent.sheet.title",
                    fallback: "最近保存的回忆"
                )
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(
                        interfaceLanguage.localized(
                            key: "common.done",
                            fallback: "完成"
                        )
                    ) {
                        isRecentTasksSheetPresented = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var emptyRecentState: some View {
        HStack(spacing: 10) {
            Image(systemName: "clock.badge.questionmark")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 34, height: 34)
                .background(
                    Circle()
                        .fill(ConfigurationUI.controlBackground)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(
                    interfaceLanguage.localized(
                        key: "task.recent.empty.title",
                        fallback: "还没有保存的回忆"
                    )
                )
                    .font(.subheadline.weight(.semibold))
                Text(
                    interfaceLanguage.localized(
                        key: "task.recent.empty.detail",
                        fallback: "从 Apple Photos 分享照片后，这里会显示最近保存的回忆。"
                    )
                )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .v1CardChrome()
    }

    @ViewBuilder
    private func recentTaskRow(
        _ row: V1SettingsHistoryRowPresentation
    ) -> some View {
        if let link = row.photoLibraryLink {
            Button {
                onOpenPhotoLibrary(link)
            } label: {
                recentTaskRowContent(row)
            }
            .buttonStyle(.plain)
        } else {
            recentTaskRowContent(row)
        }
    }

    private var photoLibraryLinkRow: some View {
        Button {
            guard let link =
                presentation
                .currentTask
                .photoLibraryLink else {
                return
            }

            onOpenPhotoLibrary(link)
        } label: {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: MemoMarkSymbol.applePhotos.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 22, height: 22)

                VStack(alignment: .leading, spacing: 2) {
                    Text(
                        presentation
                        .currentTask
                        .photoLibraryLink?
                        .actionTitle(language: interfaceLanguage)
                        ?? interfaceLanguage.localized(
                            key: "task.photoLibrary.open",
                            fallback: "打开照片 App 查看"
                        )
                    )
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(
                            dynamicTypeSize.isAccessibilitySize ? 3 : 2
                        )
                        .fixedSize(horizontal: false, vertical: true)

                    Text(
                        presentation
                        .currentTask
                        .photoLibraryLink?
                        .saveDestinationText(language: interfaceLanguage)
                        ?? interfaceLanguage.localized(
                            key: "task.photoLibrary.saved",
                            fallback: "已保存到系统图库"
                        )
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(
                        dynamicTypeSize.isAccessibilitySize ? 3 : 2
                    )
                    .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint(
            presentation
            .currentTask
            .photoLibraryLink?
            .accessibilityHint(language: interfaceLanguage)
            ?? interfaceLanguage.localized(
                key: "task.photoLibrary.hint",
                fallback: "打开照片 App 查看已保存的回忆"
            )
        )
    }

    private func recentTaskRowContent(
        _ row: V1SettingsHistoryRowPresentation
    ) -> some View {
        HStack(spacing: 10) {
            taskThumbnail(
                url: row.previewSourceURL,
                symbolName: row.symbolName,
                tint: row.tint,
                size: CGSize(width: 56, height: 48),
                itemCount: row.totalCount
            )

            VStack(alignment: .leading, spacing: 5) {
                Text(row.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(row.detailText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 4 : 2)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 12) {
                    Label(
                        V1UserFacingDateFormatter.dateTime(
                            row.timestamp
                        ),
                        systemImage: "clock"
                    )

                    Label(
                        row.statusText,
                        systemImage: row.symbolName
                    )
                    .foregroundStyle(row.tint.color)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 2)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.accentColor)
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 70)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func taskThumbnail(
        url: URL?,
        symbolName: String,
        tint: MemoMarkiOSQueueDiagnosticsTint,
        size: CGSize,
        itemCount: Int = 1
    ) -> some View {
        V1TaskLocalThumbnail(
            sourceURL: url,
            symbolName: symbolName,
            tint: tint,
            size: size,
            itemCount: itemCount
        )
    }

    private func taskStatusPill(
        title: String,
        tint:
            MemoMarkiOSQueueDiagnosticsTint
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
}

private struct V1TaskHistoryGroup: Identifiable {

    let id: Date
    let title: String
    let rows: [V1SettingsHistoryRowPresentation]
}

private struct V1TaskLocalThumbnail: View {

    private var interfaceLanguage: MemoMarkLanguage {
        .interfaceStored
    }

    let sourceURL: URL?
    let symbolName: String
    let tint: MemoMarkiOSQueueDiagnosticsTint
    let size: CGSize
    let itemCount: Int

    @State
    private var image: UIImage?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if itemCount > 1 {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(tint.color.opacity(0.12))
                    .frame(width: size.width - 8, height: size.height - 8)
                    .offset(x: 5, y: -4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(ConfigurationUI.faintHairline)
                            .offset(x: 5, y: -4)
                    )
            }

            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    tint.color.opacity(0.12)
                )

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: symbolName)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(tint.color)
            }

            if itemCount > 1 {
                Text("\(itemCount)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.black.opacity(0.68)))
                    .padding(5)
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(ConfigurationUI.faintHairline)
        )
        .task(id: sourceURL) {
            image =
                await loadThumbnail(
                    from: sourceURL,
                    maxPixelSize:
                        max(size.width, size.height) * 3
                )
        }
        .accessibilityLabel(
            itemCount > 1
                ? interfaceLanguage.localized(
                    key: "task.thumbnail.multiple",
                    fallback: "共 %@ 张照片，显示第一张已保存结果作为封面"
                ).replacingOccurrences(
                    of: "%@",
                    with: String(itemCount)
                )
                : interfaceLanguage.localized(
                    key: "task.thumbnail.single",
                    fallback: "照片缩略图"
                )
        )
    }

    private func loadThumbnail(
        from url: URL?,
        maxPixelSize: CGFloat
    ) async -> UIImage? {
        guard let url else {
            return nil
        }

        return await Task.detached(priority: .utility) {
            guard let source =
                CGImageSourceCreateWithURL(
                    url as CFURL,
                    nil
                )
            else {
                return UIImage(contentsOfFile: url.path)
            }

            let options:
                [CFString: Any] = [
                    kCGImageSourceCreateThumbnailFromImageAlways:
                        true,
                    kCGImageSourceCreateThumbnailWithTransform:
                        true,
                    kCGImageSourceThumbnailMaxPixelSize:
                        Int(maxPixelSize)
                ]

            guard let cgImage =
                CGImageSourceCreateThumbnailAtIndex(
                    source,
                    0,
                    options as CFDictionary
                )
            else {
                return UIImage(contentsOfFile: url.path)
            }

            return UIImage(cgImage: cgImage)
        }
        .value
    }
}
#endif
