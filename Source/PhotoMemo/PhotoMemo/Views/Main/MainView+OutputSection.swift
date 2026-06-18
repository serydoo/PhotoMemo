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

                Text(
                    "处理后的图片会直接写入系统图库；不选现有相册时，会自动创建或复用 PhotoMemo 相册。PhotoMemo 会继续按当前链路尽量复刻原图 EXIF、拍摄时间与可保留元数据，并把新图写入你指定的相册。"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
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
