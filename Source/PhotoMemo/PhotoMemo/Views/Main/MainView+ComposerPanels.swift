import SwiftUI

struct MainLiteralComposerSheetView: View {

    let targetSlotTitle: String

    @Binding
    var draft: String

    let onCancel: () -> Void

    let onCommit: () -> Void

    var body: some View {

        NavigationStack {

            VStack(
                alignment: .leading,
                spacing: 16
            ) {

                Text("为\(targetSlotTitle)添加文字")
                    .font(.headline)

                TextField(
                    "例如：儿子到今天 / 高考冲刺 / 旅行第",
                    text: $draft,
                    axis: .vertical
                )
                .lineLimit(3...5)
                .textFieldStyle(.roundedBorder)

                Text(
                    "保存后会作为一个独立模块加入当前区域，可继续和 EXIF、智能数据自由组合。"
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                Spacer(minLength: 0)
            }
            .padding(24)
            .navigationTitle("添加文字")
            .toolbar {

                ToolbarItem(
                    placement: .cancellationAction
                ) {

                    Button("取消") {
                        onCancel()
                    }
                }

                ToolbarItem(
                    placement: .confirmationAction
                ) {

                    Button("加入") {
                        onCommit()
                    }
                    .disabled(
                        draft
                        .trimmingCharacters(
                            in: .whitespacesAndNewlines
                        )
                        .isEmpty
                    )
                }
            }
        }
        .frame(
            minWidth: 360,
            minHeight: 220
        )
    }
}

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

                Text(guidanceText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
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

        return "过去时间点常用：{{anchor_age_text}} 表示年岁，{{anchor_duration_text}} 表示纪念时长，{{anchor_elapsed_text}} 表示已过天数，{{anchor_day_index_text}} 表示第几天；未来目标常用：{{anchor_countdown_text}} 表示倒计时；扩展结果可用 {{anchor_week_text}}、{{anchor_month_age_text}}、{{anchor_milestone_text}}，想让系统自动判断时可用 {{anchor_smart_text}}。"
    }
}
