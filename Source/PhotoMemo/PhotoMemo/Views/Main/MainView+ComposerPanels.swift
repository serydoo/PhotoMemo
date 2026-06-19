import SwiftUI

struct MainVariableLibraryPanel: View {

    let title: String

    let variables: [TemplateVariable]

    let isEnabled: Bool

    let onInsertVariable:
        (TemplateVariable) -> Void

    let onDismissArrangeMode: () -> Void

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            Text(title)
                .font(.headline)

            if let guidanceText {

                MainDismissibleGuideCard(
                    storageKey:
                        "photomemo.guide.smartModule.dismissed",
                    title: "智能模块说明",
                    message: guidanceText
                )
            }

            ScrollView(
                .horizontal,
                showsIndicators: false
            ) {

                HStack(spacing: 10) {

                    ForEach(variables) { variable in

                        Button(variable.title) {
                            onInsertVariable(variable)
                        }
                        .buttonStyle(
                            MinimalChipStyle()
                        )
                        .disabled(!isEnabled)
                    }
                }
                .padding(.vertical, 1)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onDismissArrangeMode()
        }
    }

    private var guidanceText: String? {

        guard title == "智能数据" else {
            return nil
        }

        return "过去时间点常用：年岁、纪念时长、已过天数、第几天；未来目标常用：倒计时；扩展结果可用周数、月龄、里程碑。如果想让系统自动判断当前更适合哪种结果，直接插入“智能结果（自动匹配场景）”即可。"
    }
}
