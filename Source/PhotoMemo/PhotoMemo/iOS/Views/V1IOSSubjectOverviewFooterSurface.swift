#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct V1IOSSubjectOverviewFooter: View {

    let onOpenEditor: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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

            Text("当前生效时间锚点已经收拢到配置中心切换；如果还要维护头像、基本资料或锚点内容，再进入专属配置页继续编辑。")
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
