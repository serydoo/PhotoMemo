#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
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

    let header: PhotoMemoiOSQueueDiagnosticsHeaderProjection
    let snapshot: PhotoMemoBackgroundJobSnapshot?
    let taskOverview: PhotoMemoBackgroundTaskOverview
    let recentJobSummaries: [PhotoMemoBackgroundJobSummary]
    let recoveryMessage: String?
    let events: [PhotoMemoShareDiagnosticEvent]
    let fallbackConfigurationName: String
    let onOpenPhotoLibrary: (V1TaskPhotoLibraryLink) -> Void
    let onRetryFailedTasks: () -> Void
    let onDismissKeyboard: () -> Void

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
                    fallbackConfigurationName
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
            "进展",
            subtitle: "从 Apple Photos 分享后，这里会告诉你进展。"
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
            title: "准备好了",
            subtitle: "从 Apple Photos 分享照片后，这里会告诉你进展。"
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
                    Text("准备就绪")
                        .font(.subheadline.weight(.semibold))

                    Text("从 Apple Photos 分享照片，就能开始记录。")
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
            title: "正在处理",
            subtitle: "完成后会自动保存到 Apple Photos。"
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
        V1TitledSectionCard(
            title: "刚刚完成",
            subtitle: "已生成并保存到 Apple Photos。"
        ) {
            taskStatusPill(
                title: presentation.currentTask.statusText,
                tint: presentation.currentTask.tint
            )
        } content: {
            completedResultSummary

            if presentation.currentTask.photoLibraryLink != nil {
                photoLibraryLinkRow
            }
        }
    }

    private var needsAttentionTaskCard: some View {
        V1TitledSectionCard(
            title: "需要处理",
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
                    "再次尝试",
                    action: onRetryFailedTasks
                )
                .buttonStyle(.borderedProminent)
                .accessibilityHint(
                    "重新处理这次失败的照片"
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
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 1)

                Text(taskSummarySubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 1)

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
                size: CGSize(width: 56, height: 56)
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(presentation.currentTask.headline)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 1)

                Text(taskSummarySubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 1)

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
                size: CGSize(width: 56, height: 56)
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(presentation.currentTask.headline)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 1)

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

        return [
            presentation.currentTask.templateName,
            presentation.currentTask.itemCountText
        ]
        .compactMap { item in
            guard let item,
                  !item.isEmpty else {
                return nil
            }

            return item
        }
        .joined(separator: " · ")
    }

    private var currentProgressLine: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 8) {
                Text(
                    presentation.currentTask.progressText
                    ?? presentation.currentTask.itemCountText
                    ?? "等待照片进入处理"
                )
                .font(.caption.weight(.medium))
                .foregroundStyle(.primary)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)

                Spacer(minLength: 0)
            }

            if let progressFraction =
                presentation.currentTask.progressFraction {
                ProgressView(value: progressFraction)
                    .progressViewStyle(.linear)
                    .tint(presentation.currentTask.tint.color)
                    .accessibilityLabel("当前任务进度")
                    .accessibilityValue(
                        presentation.currentTask.progressText
                        ?? presentation.currentTask.itemCountText
                        ?? "处理中"
                    )
            } else {
                ProgressView()
                    .progressViewStyle(.linear)
                    .tint(presentation.currentTask.tint.color)
                    .accessibilityLabel("当前任务正在处理")
            }
        }
    }

    private var pipelineDetailsDisclosure: some View {
        DisclosureGroup("本次进展") {
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
            .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 1)
    }

    private func pipelineStepStatus(
        _ step: V1TaskPipelineStepPresentation
    ) -> some View {
        Text(step.statusText)
            .font(.caption.weight(.medium))
            .foregroundStyle(step.tint.color)
            .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 1)
    }

    private var recentTasksSection: some View {
        V1TitledSectionCard(
            title: "最近保存",
            subtitle: "最近完成的回忆会在这里出现。",
            trailingAccessory: {
                if presentation.historyRows.count > 2 {
                    V1CardHeaderIconButton(
                        systemImage: "ellipsis",
                        accessibilityLabel: "查看更多最近保存的回忆"
                    ) {
                        isRecentTasksSheetPresented = true
                    }
                }
            }
        ) {
            if presentation.historyRows.isEmpty {
                emptyRecentState
            } else {
                VStack(spacing: 0) {
                    ForEach(
                        presentation.historyRows.prefix(2)
                    ) { row in
                        recentTaskRow(row)

                        if row.id != presentation.historyRows.prefix(2).last?.id {
                            V1HorizontalDivider(
                                horizontalInset:
                                    V1CompactInformationRowMetrics
                                    .horizontalPadding
                            )
                        }
                    }
                }
                .v1CardChrome()
            }
        }
    }

    private var recentTasksSheet: some View {
        NavigationStack {
            List(presentation.historyRows) { row in
                recentTaskRow(row)
                    .listRowSeparator(.visible)
            }
            .listStyle(.plain)
            .navigationTitle("最近保存的回忆")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") {
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
                Text("还没有保存的回忆")
                    .font(.subheadline.weight(.semibold))
                Text("从 Apple Photos 分享照片后，这里会显示最近保存的回忆。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
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
                    Text("查看 Apple Photos")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(
                            dynamicTypeSize.isAccessibilitySize ? 3 : 1
                        )

                    Text(
                        presentation
                        .currentTask
                        .photoLibraryLink?
                        .displayTitle
                        ?? "系统照片"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(
                        dynamicTypeSize.isAccessibilitySize ? 3 : 1
                    )
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            .background(
                RoundedRectangle(
                    cornerRadius: 14,
                    style: .continuous
                )
                .fill(ConfigurationUI.controlBackground)
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius: 14,
                    style: .continuous
                )
                .stroke(ConfigurationUI.faintHairline)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("打开 Apple Photos 查看已保存的回忆")
    }

    private func recentTaskRowContent(
        _ row: V1SettingsHistoryRowPresentation
    ) -> some View {
        HStack(spacing: 12) {
            taskThumbnail(
                url: row.previewSourceURL,
                symbolName: row.symbolName,
                tint: row.tint,
                size: CGSize(width: 64, height: 54)
            )

            VStack(alignment: .leading, spacing: 5) {
                Text(row.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 1)

                Text(row.detailText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 4 : 1)

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
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 1)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.accentColor)
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 78)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func taskThumbnail(
        url: URL?,
        symbolName: String,
        tint: PhotoMemoiOSQueueDiagnosticsTint,
        size: CGSize
    ) -> some View {
        V1TaskLocalThumbnail(
            sourceURL: url,
            symbolName: symbolName,
            tint: tint,
            size: size
        )
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
}

private struct V1TaskLocalThumbnail: View {

    let sourceURL: URL?
    let symbolName: String
    let tint: PhotoMemoiOSQueueDiagnosticsTint
    let size: CGSize

    @State
    private var image: UIImage?

    var body: some View {
        ZStack {
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
