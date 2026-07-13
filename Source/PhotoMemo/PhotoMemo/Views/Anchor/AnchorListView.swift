import SwiftUI

struct AnchorListView: View {

    @Environment(\.dismiss)
    private var dismiss

    @Binding
    var anchors: [Anchor]

    @Binding
    var selectedAnchorID: Anchor.ID?

    let onSave: () -> Void

    @State
    private var editingAnchor: Anchor?

    @State
    private var showEditor = false

    var body: some View {

        List {

            if anchors.isEmpty {

                ContentUnavailableView(
                    "还没有时间锚点",
                    systemImage: "calendar"
                )

            } else {

                ForEach(
                    anchorItems,
                    id: \.id
                ) { anchor in

                    VStack(
                        alignment: .leading,
                        spacing: 10
                    ) {

                        Button {

                            selectedAnchorID = anchor.id

                        } label: {

                            HStack(
                                alignment: .top,
                                spacing: 12
                            ) {

                                VStack(
                                    alignment: .leading,
                                    spacing: 4
                                ) {

                                    Text(anchor.title)
                                        .font(.headline)

                                    Text(
                                        "\(anchor.type.displayName) · \(anchorModeText(for: anchor)) · \(chineseDate(anchor.date))"
                                    )
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }
                                .frame(
                                    maxWidth: .infinity,
                                    alignment: .leading
                                )

                                Image(
                                    systemName:
                                        selectedAnchorID
                                        == anchor.id
                                        ? "checkmark.circle.fill"
                                        : "circle"
                                )
                                .font(.title3)
                                .foregroundStyle(
                                    selectedAnchorID
                                    == anchor.id
                                    ? Color.accentColor
                                    : .secondary
                                )
                            }
                        }
                        .buttonStyle(.plain)

                        HStack(spacing: 10) {
                            Button("编辑") {
                                editingAnchor = anchor
                                showEditor = true
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                    .padding(.vertical, 6)
                }
                .onDelete(
                    perform: delete
                )
            }
        }
        .navigationTitle("时间锚点")
        .toolbar {

            ToolbarItem(
                placement: .cancellationAction
            ) {

                Button("完成") {
                    dismiss()
                }
            }

            ToolbarItem(
                placement: .primaryAction
            ) {

                Button {

                    editingAnchor = nil
                    showEditor = true

                } label: {

                        Label(
                            "新建时间锚点",
                            systemImage: "plus"
                        )
                }
            }
        }
        .sheet(
            isPresented: $showEditor
        ) {

            NavigationStack {

                AnchorEditorView(
                    anchor: editingAnchor
                ) { anchor in

                    upsert(anchor)
                }
            }
#if os(iOS)
            .presentationDetents([
                .medium,
                .large
            ])
            .presentationDragIndicator(.visible)
#else
            .frame(
                minWidth: 420,
                minHeight: 280
            )
#endif
        }
    }

    private func chineseDate(_ date: Date) -> String {
        date.formatted(
            .dateTime
                .year(.defaultDigits)
                .month(.defaultDigits)
                .day(.defaultDigits)
                .locale(Locale(identifier: "zh_CN"))
        )
    }

    private func upsert(
        _ anchor: Anchor
    ) {

        if let index = anchors.firstIndex(
            where: {
                $0.id == anchor.id
            }
        ) {

            anchors[index] = anchor

        } else {

            anchors.append(anchor)
        }

        anchors.sort {
            $0.date < $1.date
        }

        selectedAnchorID = anchor.id
        onSave()
    }

    private func delete(
        at offsets: IndexSet
    ) {

        let removedIDs =
            offsets.map {
                anchors[$0].id
            }

        anchors.remove(
            atOffsets: offsets
        )

        if let selectedAnchorID,
           removedIDs.contains(
            selectedAnchorID
           ) {

            self.selectedAnchorID =
                anchors.first?.id
        }

        onSave()
    }

    private var anchorItems: [Anchor] {

        anchors.map { $0 }
    }

    private func anchorModeText(
        for anchor: Anchor
    ) -> String {

        anchor.isCountdown
            ? "未来倒计时"
            : "已发生纪念"
    }
}
