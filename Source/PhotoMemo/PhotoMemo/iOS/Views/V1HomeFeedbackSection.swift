#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct V1HomeFeedbackSection: View {

    @AppStorage("photomemo.v1.homeFeedbackExpanded")
    private var isExpanded = true

    var body: some View {
        V1CardSurface(
            title: "意见反馈",
            systemImage: MemoMarkSymbol.feedback.name,
            tint: .pink
        ) {
            VStack(alignment: .leading, spacing: 12) {
                disclosureControl

                if isExpanded {
                    expandedChannels
                        .transition(
                            .opacity.combined(
                                with: .move(edge: .top)
                            )
                        )
                }
            }
        }
    }

    private var disclosureControl: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.20)) {
                isExpanded.toggle()
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text("直接联系开发者")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(isExpanded ? "收起渠道说明" : "展开渠道说明")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                Image(
                    systemName: isExpanded
                    ? "chevron.up"
                    : "chevron.down"
                )
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("意见反馈")
        .accessibilityValue(isExpanded ? "已展开" : "已折叠")
        .accessibilityHint("显示或隐藏反馈渠道")
    }

    private var expandedChannels: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()

            feedbackRow(
                title: "小红书、抖音",
                detail: "搜索 MemoMark，可直达开发者本人。",
                systemImage: "magnifyingglass",
                tint: .red
            )

            feedbackRow(
                title: "QQ 交流群",
                detail: "群号 955680366",
                systemImage: "person.3.fill",
                tint: .teal
            )

            Label(
                "欢迎交流使用体验、反馈问题，也欢迎提出定制意见。",
                systemImage: "text.bubble.fill"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)

            Text("TestFlight 用户仍可使用系统内置反馈，提交截图、录屏和崩溃信息。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func feedbackRow(
        title: String,
        detail: String,
        systemImage: String,
        tint: Color
    ) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)

                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
            }
        }
    }
}
#endif
