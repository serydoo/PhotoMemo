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

    let anchorPhotoSummary: String

    let selectedAnchorDateText: String?

    let previewSummaryText: String?

    let quickFacts: [MainAnchorQuickFact]

    let emptyStateText: String

    let onPresentAnchorManager: () -> Void

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            MainDismissibleGuideCard(
                storageKey:
                    "photomemo.guide.anchorSection.dismissed",
                title: "时间点说明",
                message: "时间点决定 PhotoMemo 该算年岁、纪念时长、倒计时还是第几天。选中不同时间点后，右侧预览和右下智能结果会一起刷新。"
            )

            HStack(spacing: 10) {
                Picker(
                    "选择时间点",
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
                        "设置时间点",
                        systemImage: "calendar.badge.plus"
                    )
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            MinimalInsetCard {
                LabeledContent("照片时间") {
                    Text(anchorPhotoSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                }

                if let selectedAnchorDateText {

                    Divider()

                    LabeledContent("基准时间") {
                        Text(selectedAnchorDateText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let previewSummaryText {

                        Divider()

                        VStack(
                            alignment: .leading,
                            spacing: 8
                        ) {

                            Text(previewSummaryText)
                                .font(.subheadline.weight(.medium))

                            ScrollView(
                                .horizontal,
                                showsIndicators: false
                            ) {

                                HStack(spacing: 8) {

                                    ForEach(quickFacts) { fact in

                                        MainAnchorFactPillView(
                                            title: fact.label,
                                            value: fact.value
                                        )
                                    }
                                }
                                .padding(.vertical, 1)
                            }
                        }
                    }

                } else {

                    Divider()

                    Text(emptyStateText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }
}
