#if !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct V1IOSHomeQuickAction:
    Equatable,
    Identifiable {

    enum Destination:
        Hashable {
        case processPhotos
        case configurationCenter
        case timeAnchor
        case usageGuide
    }

    let id: Destination
    let title: String
    let subtitle: String
    let compactDetail: String
    let systemImage: String

    static let defaultActions: [Self] = [
        .init(
            id: .processPhotos,
            title: "处理照片",
            subtitle: "直接从系统图库选择照片并开始处理",
            compactDetail: "从图库开始",
            systemImage: "photo.on.rectangle.angled"
        ),
        .init(
            id: .configurationCenter,
            title: "配置中心",
            subtitle: "继续查看当前生效配置",
            compactDetail: "查看当前配置",
            systemImage: "slider.horizontal.3"
        ),
        .init(
            id: .timeAnchor,
            title: "时间锚点",
            subtitle: "查看记忆对象与生效锚点",
            compactDetail: "切换生效锚点",
            systemImage: "calendar.badge.clock"
        ),
        .init(
            id: .usageGuide,
            title: "使用说明",
            subtitle: "查看 Apple Photos 使用流程与说明",
            compactDetail: "查看使用流程",
            systemImage: "book.pages"
        )
    ]
}

struct V1IOSHomeRecentProcessingPresentation:
    Equatable {

    let headline: String

    let subheadline: String

    let symbolName: String

    let tint:
        PhotoMemoiOSQueueDiagnosticsTint

    let statusValue: String

    let sourceValue: String

    let updatedAtValue: String

    let recoveryMessage: String?
}

enum V1IOSHomeRecentProcessingPresenter {

    static func presentation(
        header:
            PhotoMemoiOSQueueDiagnosticsHeaderProjection,
        snapshot:
            PhotoMemoBackgroundJobSnapshot?,
        recoveryMessage: String?
    ) -> V1IOSHomeRecentProcessingPresentation {

        V1IOSHomeRecentProcessingPresentation(
            headline:
                header.headline,
            subheadline:
                header.subheadline,
            symbolName:
                header.symbolName,
            tint:
                header.tint,
            statusValue:
                snapshot?
                .feedbackState
                .displayTitle
                ?? (
                    recoveryMessage == nil
                    ? "等待下一次分享"
                    : "需要恢复"
                ),
            sourceValue:
                snapshot?
                .launchSource
                .displayTitle
                ?? "Apple Photos 分享",
            updatedAtValue:
                snapshot.map {
                    formattedUpdatedAt(
                        $0.updatedAt
                    )
                }
                ?? "暂无",
            recoveryMessage:
                recoveryMessage
        )
    }
}

private extension V1IOSHomeRecentProcessingPresenter {

    static func formattedUpdatedAt(
        _ date: Date
    ) -> String {

        V1UserFacingDateFormatter.dateTime(date)
    }
}

struct V1IOSHomeQuickActionsContent: View {

    let openPhotoPicker: () -> Void

    let openEditor: () -> Void

    let openTimeAnchor: () -> Void

    let openUsageGuide: () -> Void

    var body: some View {
        actionButtons
    }

    @ViewBuilder
    private var actionButtons: some View {
        LazyVGrid(
            columns: Array(
                repeating: GridItem(
                    .flexible(),
                    spacing: 8
                ),
                count: 4
            ),
            spacing: 8
        ) {
            ForEach(
                V1IOSHomeQuickAction.defaultActions
            ) { action in
                V1IOSHomeActionTileButton(
                    title: action.title,
                    detail: action.compactDetail,
                    systemImage: action.systemImage,
                    action: {
                        perform(action.id)
                    }
                )
            }
        }
    }

    private func perform(
        _ destination: V1IOSHomeQuickAction.Destination
    ) {
        switch destination {
        case .processPhotos:
            openPhotoPicker()
        case .configurationCenter:
            openEditor()
        case .timeAnchor:
            openTimeAnchor()
        case .usageGuide:
            openUsageGuide()
        }
    }
}

struct V1IOSHomeRecentProcessingContent: View {

    let presentation:
        V1IOSHomeRecentProcessingPresentation

    let openStatus: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: presentation.symbolName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(
                        presentation.tint.color
                    )
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 2) {
                    Text(presentation.headline)
                        .font(.subheadline.weight(.semibold))

                    Text(presentation.subheadline)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(
                            horizontal: false,
                            vertical: true
                        )
                }

                Spacer(minLength: 0)

                Button("查看全部") {
                    openStatus()
                }
                .buttonStyle(.plain)
                .font(.caption.weight(.semibold))
            }

            V1IOSHomeInsetGroup {
                facts
            }

            if let recoveryMessage =
                presentation.recoveryMessage {
                Label(
                    recoveryMessage,
                    systemImage:
                        "exclamationmark.triangle.fill"
                )
                .font(.caption)
                .foregroundStyle(.orange)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
            }
        }
    }

    @ViewBuilder
    private var facts: some View {
        V1IOSHomeSemanticRow(
            title: "状态",
            value: presentation.statusValue,
            detail: presentation.headline,
            systemImage:
                "circle.dotted.circle"
        )

        V1IOSHomeSemanticRow(
            title: "来源",
            value: presentation.sourceValue,
            detail: presentation.subheadline,
            systemImage:
                "square.and.arrow.up"
        )

        V1IOSHomeSemanticRow(
            title: "最近更新",
            value: presentation.updatedAtValue,
            detail: "保留最近一次后台进度时间",
            systemImage:
                "clock.arrow.circlepath",
            showsDivider: false
        )
    }
}

#endif
