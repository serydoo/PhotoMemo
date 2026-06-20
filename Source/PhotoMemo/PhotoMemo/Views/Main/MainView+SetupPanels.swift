import SwiftUI

struct MainPhotoSectionView<Importer: View>: View {

    let selectedPhotoDeviceModel: String?

    let selectedPhotoCaptureDateText: String?

    @ViewBuilder
    let importer: () -> Importer

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            importer()

            if let selectedPhotoDeviceModel {

                MainPhotoMetadataSummaryView(
                    deviceModel: selectedPhotoDeviceModel,
                    captureDateText:
                        selectedPhotoCaptureDateText
                )
            }
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }
}

private struct MainPhotoMetadataSummaryView: View {

    let deviceModel: String

    let captureDateText: String?

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 4
        ) {

            Text(deviceModel)
                .font(.headline)

            if let captureDateText {

                Text(captureDateText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct MainAnchorQuickFact: Identifiable, Hashable {

    let label: String

    let value: String

    var id: String {
        label
    }
}

private struct MainAnchorFactPillView: View {

    let title: String

    let value: String

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 2
        ) {

            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.78))
        )
        .overlay(
            Capsule()
                .stroke(MinimalPalette.border)
        )
    }
}

struct MainAnchorSectionView: View {

    let anchors: [Anchor]

    @Binding
    var selectedAnchorID: Anchor.ID?

    let onPresentAnchorManager: () -> Void

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            HStack(spacing: 10) {
                Picker(
                    "选择记忆日期",
                    selection: $selectedAnchorID
                ) {

                    Text("未选择")
                        .tag(Optional<Anchor.ID>.none)

                    ForEach(anchors) { anchor in

                        Text(anchor.title)
                            .tag(Optional(anchor.id))
                    }
                }
                .pickerStyle(.menu)
                .controlSize(.small)

                Button(action: onPresentAnchorManager) {
                    Label(
                        "管理与编辑",
                        systemImage: "calendar.badge.plus"
                    )
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            Text("切换记忆日期后，预览会立即刷新。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }
}
