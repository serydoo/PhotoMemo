#if !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

extension PhotoMemoBackgroundPresentationState {

    var displayTitle: String {

        switch self {
        case .active:
            return "处理中"
        case .needsAttention:
            return "需要处理"
        case .completed:
            return "已完成"
        }
    }
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
                .presentationState
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

        date.formatted(
            .dateTime
                .month()
                .day()
                .hour()
                .minute()
        )
    }
}

struct V1IOSHomeQuickActionsContent: View {

    let openOutput: () -> Void

    let openEditor: () -> Void

    let openSettings: () -> Void

    var body: some View {
        V1IOSHomeInsetGroup {
            actionButtons
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        V1IOSHomeNavigationRowButton(
            title: "处理照片",
            subtitle: "查看默认输出与保存位置",
            systemImage: "arrow.up.circle.fill",
            action: openOutput
        )

        V1IOSHomeNavigationRowButton(
            title: "配置中心",
            subtitle: "继续校准当前配置",
            systemImage: "slider.horizontal.3",
            action: openEditor
        )

        V1IOSHomeNavigationRowButton(
            title: "最近处理",
            subtitle: "查看后台处理状态",
            systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90",
            showsDivider: false,
            action: openSettings
        )
    }
}

struct V1IOSHomeDefaultOutputSummaryContent: View {

    let summary:
        V1IOSHomeOutputSummaryProjection

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("下一次从 Apple Photos 分享进入 PhotoMemo 时，会默认沿用这套输出设置。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )

            V1IOSHomeInsetGroup {
                V1IOSHomeSemanticRow(
                    title: "输出方式",
                    value: summary.title,
                    detail: summary.targetNote,
                    systemImage:
                        "square.and.arrow.down"
                )

                V1IOSHomeSemanticRow(
                    title: "保存位置",
                    value: summary.detail,
                    detail: "完成后回到 Apple Photos",
                    systemImage:
                        "photo.on.rectangle.angled"
                )

                V1IOSHomeSemanticRow(
                    title: "记忆说明",
                    value:
                        summary
                        .memoryWriteLabel,
                    detail:
                        summary
                        .memoryWriteDetail,
                    systemImage:
                        "text.badge.checkmark",
                    showsDivider: false
                )
            }
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
