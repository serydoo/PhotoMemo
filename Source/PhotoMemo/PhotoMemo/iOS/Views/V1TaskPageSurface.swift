#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import ImageIO
import SwiftUI
import UIKit

struct V1TaskPageSurface: View {

    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass

    let header: PhotoMemoiOSQueueDiagnosticsHeaderProjection
    let snapshot: PhotoMemoBackgroundJobSnapshot?
    let taskOverview: PhotoMemoBackgroundTaskOverview
    let recentJobSummaries: [PhotoMemoBackgroundJobSummary]
    let recoveryMessage: String?
    let events: [PhotoMemoShareDiagnosticEvent]
    let fallbackConfigurationName: String
    let onOpenPhotoLibrary: (V1TaskPhotoLibraryLink) -> Void
    let onStartProcessing: () -> Void
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
                overviewStrip
                currentTaskCard
                recentTasksSection
            }
            .padding(.top, 10)
            .padding(
                .bottom,
                V1AdaptivePageLayout
                    .scrollBottomPadding(
                        isPad:
                            UIDevice.current
                            .userInterfaceIdiom == .pad,
                        hasRegularHorizontalSizeClass:
                            horizontalSizeClass == .regular
                    )
            )
            .v1AdaptiveScrollContent(
                horizontalPadding: 16
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

    private var pageHeader: some View {
        V1PageHeader(
            "任务",
            subtitle: "所有处理都在本地完成，原图不会被修改。"
        )
    }

    private var overviewStrip: some View {
        HStack(spacing: 0) {
            ForEach(presentation.overviewItems) { item in
                overviewItem(item)

                if item.id != presentation.overviewItems.last?.id {
                    Rectangle()
                        .fill(ConfigurationUI.faintHairline)
                        .frame(width: 1, height: 36)
                }
            }
        }
        .frame(height: 86)
        .v1CardChrome()
    }

    private func overviewItem(
        _ item: V1TaskOverviewItemPresentation
    ) -> some View {
        VStack(spacing: 5) {
            Label {
                Text(item.title)
                    .font(.caption.weight(.semibold))
            } icon: {
                Image(systemName: item.symbolName)
                    .font(.caption.weight(.bold))
            }
            .foregroundStyle(item.tint.color)
            .lineLimit(1)

            Text(item.value)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.primary)
                .monospacedDigit()

            Text(item.unit)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var currentTaskCard: some View {
        if snapshot == nil {
            currentTaskEmptyState
        } else {
            currentTaskActiveCard
        }
    }

    private var currentTaskEmptyState: some View {
        VStack(alignment: .center, spacing: 12) {
            ZStack {
                RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
                .fill(Color.accentColor.opacity(0.10))

                Image(systemName: MemoMarkSymbol.processing.name)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
            }
            .frame(width: 58, height: 58)

            VStack(spacing: 4) {
                Text("还没有处理任务")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text("从首页选择照片开始。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button(action: onStartProcessing) {
                HStack(spacing: 8) {
                    Image(systemName: MemoMarkSymbol.processing.name)
                        .font(.caption.weight(.semibold))

                    Text("开始处理")
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)

                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color.white.opacity(0.82))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .frame(width: 168)
                .frame(height: 44)
                .background(
                    RoundedRectangle(
                        cornerRadius: 14,
                        style: .continuous
                    )
                    .fill(Color.accentColor)
                )
                .shadow(
                    color: Color.accentColor.opacity(0.16),
                    radius: 10,
                    y: 4
                )
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 18)
        .padding(.vertical, 22)
        .v1CardChrome()
    }

    private var currentTaskActiveCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Circle()
                    .fill(presentation.currentTask.tint.color)
                    .frame(width: 7, height: 7)

                Text("当前任务")
                    .font(.subheadline.weight(.semibold))

                Spacer(minLength: 0)

                taskStatusPill(
                    title:
                        presentation.currentTask.statusText,
                    tint:
                        presentation.currentTask.tint
                )
            }

            currentTaskSummary

            pipelineRows
            photoLibraryLinkRow
        }
        .padding(14)
        .v1CardChrome()
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
                    .lineLimit(1)

                Text(taskSummarySubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

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
                .lineLimit(1)

                Spacer(minLength: 0)

                if let progressFraction =
                    presentation.currentTask.progressFraction {
                    Text(progressPercentText(progressFraction))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(
                            presentation.currentTask.tint.color
                        )
                        .monospacedDigit()
                }
            }

            if let progressFraction =
                presentation.currentTask.progressFraction {
                ProgressView(value: progressFraction)
                    .progressViewStyle(.linear)
                    .tint(presentation.currentTask.tint.color)
                    .accessibilityLabel("当前任务进度")
                    .accessibilityValue(
                        progressPercentText(progressFraction)
                    )
            } else {
                ProgressView()
                    .progressViewStyle(.linear)
                    .tint(presentation.currentTask.tint.color)
                    .accessibilityLabel("当前任务正在处理")
            }
        }
    }

    private var pipelineRows: some View {
        VStack(spacing: 0) {
            ForEach(
                presentation.currentTask.stepRows
            ) { step in
                pipelineRow(step)

                if step.id != presentation.currentTask.stepRows.last?.id {
                    Divider()
                        .padding(.leading, 28)
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
        HStack(spacing: 10) {
            Image(systemName: step.symbolName)
                .font(.caption2.weight(.bold))
                .foregroundStyle(step.tint.color)
                .frame(width: 16, height: 16)

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
                .lineLimit(1)

            Text(step.statusText)
                .font(.caption.weight(.medium))
                .foregroundStyle(step.tint.color)
                .lineLimit(1)

            Spacer(minLength: 0)

            if let timeText = step.timeText {
                Text(timeText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 28)
        .accessibilityElement(children: .combine)
    }

    private var recentTasksSection: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .center, spacing: 12) {
                V1SectionHeading("最近任务")

                if presentation.historyRows.count > 2 {
                    Button {
                        isRecentTasksSheetPresented = true
                    } label: {
                        Text("…")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 34, height: 30)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(ConfigurationUI.controlBackground)
                            )
                            .overlay(
                                Capsule(style: .continuous)
                                    .stroke(ConfigurationUI.faintHairline)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("查看更多最近任务")
                }
            }

            if presentation.historyRows.isEmpty {
                emptyRecentState
            } else {
                VStack(spacing: 0) {
                    ForEach(
                        presentation.historyRows.prefix(2)
                    ) { row in
                        recentTaskRow(row)

                        if row.id != presentation.historyRows.prefix(2).last?.id {
                            Divider()
                                .padding(.leading, 86)
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
            .navigationTitle("近期完成任务")
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
                Text("还没有最近任务")
                    .font(.subheadline.weight(.semibold))
                Text("从 Apple Photos 分享照片后，这里会显示最近处理。")
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
        HStack {
            Spacer(minLength: 0)

            Button {
                guard let link =
                    presentation
                    .currentTask
                    .photoLibraryLink else {
                    return
                }

                onOpenPhotoLibrary(link)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: MemoMarkSymbol.applePhotos.name)
                        .font(.caption.weight(.semibold))
                        .frame(width: 16)

                    VStack(alignment: .leading, spacing: 1) {
                        Text("查看相册")
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)

                        Text(
                            presentation
                            .currentTask
                            .photoLibraryLink?
                            .displayTitle
                            ?? "系统照片"
                        )
                        .font(.caption2)
                        .lineLimit(1)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "arrow.up.forward")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color.white.opacity(0.82))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .frame(width: 178)
                .frame(height: 44)
                .background(
                    RoundedRectangle(
                        cornerRadius: 14,
                        style: .continuous
                    )
                    .fill(Color.accentColor)
                )
                .shadow(
                    color: Color.accentColor.opacity(0.16),
                    radius: 10,
                    y: 4
                )
            }
            .buttonStyle(.plain)
            .disabled(
                presentation.currentTask.photoLibraryLink == nil
            )
            .opacity(
                presentation.currentTask.photoLibraryLink == nil
                ? 0.56
                : 1
            )
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
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
                    .lineLimit(1)

                Text(row.detailText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

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
                .lineLimit(1)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 12)
        .frame(height: 78)
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
