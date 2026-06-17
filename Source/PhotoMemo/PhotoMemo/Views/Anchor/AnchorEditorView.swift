import SwiftUI

private enum AnchorComputationMode: String, CaseIterable {

    case elapsed

    case countdown
}

private extension AnchorComputationMode {

    var displayName: String {

        switch self {

        case .elapsed:
            return "已发生纪念"

        case .countdown:
            return "未来倒计时"
        }
    }

    var helperText: String {

        switch self {

        case .elapsed:
            return "锚点是已经发生的事件，系统会用照片 EXIF 拍摄时间减去这个锚点时间。"

        case .countdown:
            return "锚点是未来目标时间，系统会用这个锚点时间减去照片 EXIF 拍摄时间。"
        }
    }
}

struct AnchorEditorView: View {

    @Environment(\.dismiss)
    private var dismiss

    private let anchorID: UUID

    let onSave: (Anchor) -> Void

    @State
    private var type: AnchorType

    @State
    private var title: String

    @State
    private var date: Date

    @State
    private var isCountdown: Bool

    @State
    private var mode: AnchorComputationMode

    init(
        anchor: Anchor? = nil,
        onSave: @escaping (Anchor) -> Void
    ) {
        anchorID = anchor?.id ?? UUID()
        self.onSave = onSave
        _type = State(
            initialValue: anchor?.type ?? .custom
        )
        _title = State(
            initialValue: anchor?.title ?? ""
        )
        _date = State(
            initialValue: anchor?.date ?? Date()
        )
        _isCountdown = State(
            initialValue:
                anchor?.isCountdown
                ?? anchor?.type.defaultCountdown
                ?? false
        )
        _mode = State(
            initialValue:
                (anchor?.isCountdown
                 ?? anchor?.type.defaultCountdown
                 ?? false)
                ? .countdown
                : .elapsed
        )
    }

    var body: some View {

        Form {

            Picker(
                "方案类型",
                selection: $type
            ) {

                ForEach(
                    AnchorType.allCases,
                    id: \.self
                ) { anchorType in

                    Text(
                        anchorType.displayName
                    )
                    .tag(anchorType)
                }
            }

            TextField(
                "名称",
                text: $title
            )

            DatePicker(
                "锚点时间",
                selection: $date,
                displayedComponents: [
                    .date,
                    .hourAndMinute
                ]
            )

            Text(
                "锚点是你设定的关键时间，系统会把它和照片 EXIF 拍摄时间做差值计算。"
            )
            .font(.caption)
            .foregroundStyle(.secondary)

            Picker(
                "计算方式",
                selection: $mode
            ) {

                ForEach(
                    AnchorComputationMode.allCases,
                    id: \.self
                ) { mode in

                    Text(mode.displayName)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)

            VStack(
                alignment: .leading,
                spacing: 8
            ) {

                Text(type.helperText)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(type.sceneExamples)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(mode.helperText)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(sampleScenarioText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("时间锚点")
        .toolbar {

            ToolbarItem(
                placement: .cancellationAction
            ) {

                Button("取消") {
                    dismiss()
                }
            }

            ToolbarItem(
                placement: .confirmationAction
            ) {

                Button("保存") {
                    save()
                }
                .disabled(
                    title.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ).isEmpty
                )
            }
        }
    }

    private func save() {

        isCountdown = mode == .countdown

        onSave(
            Anchor(
                id: anchorID,
                type: type,
                title: title.trimmingCharacters(
                    in: .whitespacesAndNewlines
                ),
                date: date,
                isCountdown: isCountdown
            )
        )

        dismiss()
    }

    private var sampleScenarioText: String {

        let resolvedTitle =
            title.trimmingCharacters(
                in: .whitespacesAndNewlines
            ).isEmpty
            ? type.suggestedTitle
            : title.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        switch (type, mode) {

        case (.birthday, .elapsed):
            return "示例：\(resolvedTitle) 2025.05.26 出生，照片拍摄于 2026.05.26，可生成“\(resolvedTitle)今天1岁”或“\(resolvedTitle)到今天1岁0个月0天”。"

        case (.relationship, .elapsed):
            return "示例：2024.02.14 在一起，照片拍摄于 2025.02.14，可生成“我们已经在一起1年”或“恋爱365天”。"

        case (.marriage, .elapsed):
            return "示例：2023.10.01 结婚，照片拍摄于 2026.10.01，可生成“结婚纪念3年”。"

        case (.exam, .elapsed):
            return "示例：毕业时间设为 2026.06.30，照片拍摄于 2027.06.30，可生成“毕业1年”；如果刚毕业不久，也可生成“已毕业30天”。"

        case (.exam, .countdown):
            return "示例：高考设为 2027.06.07，照片拍摄于 2027.05.08，可生成“距离高考还有30天”；毕业设为 2027.06.30，也可生成“距离毕业还有XX天”。"

        case (_, .countdown):
            return "示例：把毕业、入学、旅行出发、演唱会、回家日期设为未来时间，系统会生成“还有XX天”。"

        case (_, .elapsed):
            return "示例：恋爱、出生、结婚、纪念日等已发生事件设为过去时间，系统会生成“已经XX天 / XX岁 / X年X个月X天”。"
        }
    }
}
