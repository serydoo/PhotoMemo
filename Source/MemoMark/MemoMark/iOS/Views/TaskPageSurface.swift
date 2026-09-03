#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI
import UIKit

struct TaskPageSurface: View {

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
    let onOpenPhotoLibrary: (TaskPhotoLibraryLink) -> Void
    let onRetryFailedTasks: () -> Void
    let onDismissKeyboard: () -> Void

    private var interfaceLanguage: MemoMarkLanguage {
        .interfaceStored
    }

    @State
    private var isRecentTasksSheetPresented = false

    private var presentation:
        TaskPagePresentation {
        TaskPagePresenter
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
                AdaptivePageLayout
                    .scrollBottomPadding(
                        for: navigationStyle
                    )
            )
            .adaptiveScrollContent(
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
    }

    private var navigationStyle:
        EntryNavigationStyle {
        AdaptivePageLayout.navigationStyle(
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
        ConfigurationPageHeader(
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
        ConfigurationTitledSectionCard(
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
        ConfigurationTitledSectionCard(
            title: interfaceLanguage.localized(
                key: "task.processing.title",
                fallback: "正在处理"
            ),
            subtitle: interfaceLanguage.localized(
                key: "task.processing.subtitle",
                fallback: "完成后会保存到 Apple Photos。"
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
                    HorizontalDivider(horizontalInset: 4)
                    photoLibraryLinkRow
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .v1CardChrome()
        }
    }

    private var needsAttentionTaskCard: some View {
        ConfigurationTitledSectionCard(
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
                        UserFacingDateFormatter.dateTime(updatedAt),
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
                    HorizontalDivider(horizontalInset: 10)
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
        _ step: TaskPipelineStepPresentation
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
        _ step: TaskPipelineStepPresentation
    ) -> some View {
        Image(systemName: step.symbolName)
            .font(.caption2.weight(.bold))
            .foregroundStyle(step.tint.color)
            .frame(width: 16, height: 16)
    }

    private func pipelineStepTitle(
        _ step: TaskPipelineStepPresentation
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
        _ step: TaskPipelineStepPresentation
    ) -> some View {
        Text(step.statusText)
            .font(.caption.weight(.medium))
            .foregroundStyle(step.tint.color)
            .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 2)
    }

    private var recentTasksSection: some View {
        TaskRecentHistorySurface(
            rows: presentation.historyRows,
            onOpenPhotoLibrary: onOpenPhotoLibrary,
            isSheetPresented: $isRecentTasksSheetPresented
        )
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


    @ViewBuilder
    private func taskThumbnail(
        url: URL?,
        symbolName: String,
        tint: MemoMarkiOSQueueDiagnosticsTint,
        size: CGSize,
        itemCount: Int = 1
    ) -> some View {
        TaskLocalThumbnail(
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

#endif
