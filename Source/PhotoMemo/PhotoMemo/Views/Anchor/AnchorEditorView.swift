import SwiftUI

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
            initialValue: anchor?.isCountdown ?? false
        )
    }

    var body: some View {

        Form {

            Picker(
                "Type",
                selection: $type
            ) {

                ForEach(
                    AnchorType.allCases,
                    id: \.self
                ) { anchorType in

                    Text(
                        anchorType.rawValue.capitalized
                    )
                    .tag(anchorType)
                }
            }

            TextField(
                "Title",
                text: $title
            )

            DatePicker(
                "Date & Time",
                selection: $date,
                displayedComponents: [
                    .date,
                    .hourAndMinute
                ]
            )

            Text(
                "PhotoMemo will compare this anchor time with the photo EXIF capture time."
            )
            .font(.caption)
            .foregroundStyle(.secondary)

            Toggle(
                "Countdown",
                isOn: $isCountdown
            )
        }
        .navigationTitle("Time Anchor")
        .toolbar {

            ToolbarItem(
                placement: .cancellationAction
            ) {

                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(
                placement: .confirmationAction
            ) {

                Button("Save") {
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
