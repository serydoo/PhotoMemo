#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct V1IOSSubjectOverviewFooter: View {

    let hasAnchors: Bool
    let resolvedPendingAnchorID: UUID?
    let hasAnchorSelectionChange: Bool
    let onConfirmActiveAnchor: (UUID) -> Void
    let onOpenEditor: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let resolvedPendingAnchorID,
               hasAnchors {
                Button {
                    onConfirmActiveAnchor(
                        resolvedPendingAnchorID
                    )
                } label: {
                    Label(
                        "设为生效",
                        systemImage: "checkmark.circle.fill"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!hasAnchorSelectionChange)
            }

            Button {
                onOpenEditor()
            } label: {
                Label(
                    "进入当前对象配置",
                    systemImage:
                        "slider.horizontal.3"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Text("这里可以快速切换当前生效时间锚点；如果还要调整头像、基本资料或锚点内容，再进入专属配置页继续编辑。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
        }
    }
}
#endif
