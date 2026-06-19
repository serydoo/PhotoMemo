import SwiftUI

struct MainOutputSection: View {

    @Binding
    var selectedAlbumIdentifier: String

    let availableAlbums: [PhotoAlbumOption]

    let selectedAlbumSummary: String

    let isSavingToAlbum: Bool

    let canExportCurrentCard: Bool

    let isCompactLayout: Bool

    let saveCurrentCardToAlbum: () -> Void

    let saveFeedbackTitle: String?

    let saveFeedbackMessage: String?

    let showsSaveFeedback: Bool

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            MainDismissibleGuideCard(
                storageKey:
                    "photomemo.guide.output.dismissed",
                title: "输出说明",
                message: "输出区现在只保留目标相册选择和保存动作。更完整的元数据保留与相册写回说明已经整理进右侧操作指南，确认后可以关闭这条提示。"
            )

            Picker(
                "系统相册",
                selection: $selectedAlbumIdentifier
            ) {

                Text("自动存入 PhotoMemo")
                    .tag(
                        PhotoAlbumOption
                            .automaticIdentifier
                    )

                ForEach(availableAlbums) { album in

                    Text(album.title)
                        .tag(album.id)
                }
            }
            .pickerStyle(.menu)
            .controlSize(.small)

            MinimalInsetCard {
                LabeledContent("写入位置") {
                    Text(selectedAlbumSummary)
                        .font(
                            isCompactLayout
                            ? .subheadline.weight(.medium)
                            : .caption
                        )
                        .foregroundStyle(
                            isCompactLayout
                            ? .primary
                            : .secondary
                        )
                }

                Divider()

                LabeledContent("保存策略") {
                    Text("新图写回系统图库，尽量保留原图元数据")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                }
            }

            VStack(
                alignment: .leading,
                spacing: 8
            ) {

                Button(
                    isSavingToAlbum
                        ? "正在存入系统相册..."
                        : "保存新图到“\(selectedAlbumSummary)”",
                    action: saveCurrentCardToAlbum
                )
                .buttonStyle(.borderedProminent)
                .controlSize(
                    isCompactLayout
                    ? .regular
                    : .small
                )
                .frame(maxWidth: .infinity)
                .disabled(
                    !canExportCurrentCard
                    || isSavingToAlbum
                )

                if isCompactLayout {
                    Text("iPhone 上建议先确认上方预览正确，再直接保存到当前相册。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(
                            horizontal: false,
                            vertical: true
                        )
                }
            }

            if isCompactLayout,
               showsSaveFeedback,
               let saveFeedbackTitle,
               let saveFeedbackMessage {

                MinimalInsetCard {
                    Label(
                        saveFeedbackTitle,
                        systemImage: "checkmark.circle.fill"
                    )
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(
                        MinimalPalette.accent
                    )

                    Text(saveFeedbackMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(
                            horizontal: false,
                            vertical: true
                        )
                }
                .transition(.opacity)
            }
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }
}
