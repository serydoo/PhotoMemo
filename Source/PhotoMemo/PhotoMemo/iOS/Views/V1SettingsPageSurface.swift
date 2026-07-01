#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct V1SettingsPageSurface: View {

    let header: PhotoMemoiOSQueueDiagnosticsHeaderProjection
    let snapshot: PhotoMemoBackgroundJobSnapshot?
    let recoveryMessage: String?
    let displayEvents: [PhotoMemoiOSQueueDiagnosticEventProjection]
    let onRefresh: () -> Void
    let onClearCompletedHistory: () -> Void
    let onDismissKeyboard: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                diagnosticsSection

                V1CardSurface(title: "设置") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("当前版本会继续向更稳定的 V1.0 配置体验收口。此阶段优先整理首页、记忆对象入口与默认输出层级，后台处理与生成规范保持不变。")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 34)
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
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var diagnosticsSection: some View {
        V1CardSurface(title: "处理进度") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 10) {
                    Image(systemName: header.symbolName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(header.tint.color)
                        .frame(width: 20)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(header.headline)
                            .font(.subheadline.weight(.semibold))

                        Text(header.subheadline)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    Button(action: onRefresh) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .accessibilityLabel("刷新处理进度")
                }

                if let snapshot {
                    progressSummary(snapshot)
                }

                if let recoveryMessage {
                    Label(
                        recoveryMessage,
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .fixedSize(horizontal: false, vertical: true)
                }

                if !displayEvents.isEmpty {
                    VStack(alignment: .leading, spacing: 7) {
                        ForEach(displayEvents) { event in
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text(
                                    event.timestamp.formatted(
                                        date: .omitted,
                                        time: .standard
                                    )
                                )
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.secondary)
                                .frame(width: 72, alignment: .leading)

                                VStack(alignment: .leading, spacing: 1) {
                                    Text(event.title)
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(.secondary)

                                    Text(event.message)
                                        .font(.caption)
                                        .lineLimit(2)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func progressSummary(
        _ snapshot: PhotoMemoBackgroundJobSnapshot
    ) -> some View {
        let progress =
            PhotoMemoiOSQueueDiagnosticsProjectionEngine
            .progressProjection(for: snapshot)

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Label(
                    progress.title,
                    systemImage: progress.symbolName
                )
                .font(.caption.weight(.semibold))
                .foregroundStyle(progress.tint.color)

                Spacer(minLength: 0)

                Text(progress.progressPercentText)
                    .font(.caption2.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: progress.progressFraction)
                .progressViewStyle(.linear)
                .tint(progress.tint.color)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(progress.statusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                if snapshot.overflowQueueCount > 0 {
                    Button("清除历史") {
                        onClearCompletedHistory()
                    }
                    .font(.caption2.weight(.semibold))
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("清除已完成的处理历史")
                }
            }

            if progress.showsPipeline {
                pipelineSteps(progress)
            } else if !progress.queueLines.isEmpty {
                queueLines(progress)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(
                cornerRadius: 12,
                style: .continuous
            )
            .fill(Color(.secondarySystemBackground))
        )
    }

    private func pipelineSteps(
        _ progress: PhotoMemoiOSQueueProgressProjection
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            ForEach(progress.pipelineSteps, id: \.self) { step in
                HStack(spacing: 8) {
                    Image(systemName: step.symbolName)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(step.tint.color)
                        .frame(width: 16)

                    Text(step.title)
                        .font(
                            step.emphasizesTitle
                            ? .caption.weight(.semibold)
                            : .caption
                        )
                        .foregroundStyle(
                            step.usesSecondaryTitleStyle
                            ? .secondary
                            : .primary
                        )

                    Spacer(minLength: 0)
                }
            }
        }
        .padding(.top, 2)
    }

    private func queueLines(
        _ progress: PhotoMemoiOSQueueProgressProjection
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(
                Array(progress.queueLines.prefix(3).enumerated()),
                id: \.offset
            ) { _, line in
                HStack(spacing: 8) {
                    Image(systemName: "photo.stack")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 16)

                    Text(line)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            if progress.overflowQueueCount > 0 {
                Text("另有 \(progress.overflowQueueCount) 个队列")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.leading, 24)
            }
        }
        .padding(.top, 2)
    }
}
#endif
