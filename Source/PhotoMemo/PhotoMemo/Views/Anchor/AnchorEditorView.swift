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
                "设定时间",
                selection: $date,
                displayedComponents: [
                    .date,
                    .hourAndMinute
                ]
            )
#if os(iOS)
            .datePickerStyle(.compact)
#endif

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
}
