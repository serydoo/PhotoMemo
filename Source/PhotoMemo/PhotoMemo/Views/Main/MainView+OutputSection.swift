import SwiftUI

struct MainOutputSection: View {

    @Binding
    var selectedAlbumIdentifier: String

    let availableAlbums: [PhotoAlbumOption]

    let selectedAlbumSummary: String

    let isSavingToAlbum: Bool

    let canExportCurrentCard: Bool

    let saveCurrentCardToAlbum: () -> Void

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
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider()

                LabeledContent("保存策略") {
                    Text("新图写回系统图库，尽量保留原图元数据")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                }
            }

            Button(
                isSavingToAlbum
                    ? "正在存入系统相册..."
                    : "存入系统相册",
                action: saveCurrentCardToAlbum
            )
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .disabled(
                !canExportCurrentCard
                || isSavingToAlbum
            )
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }
}
