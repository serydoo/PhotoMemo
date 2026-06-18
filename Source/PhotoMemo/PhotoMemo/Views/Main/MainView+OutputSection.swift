import SwiftUI

struct MainOutputSection: View {

    @Binding
    var selectedAlbumIdentifier: String

    let availableAlbums: [PhotoAlbumOption]

    let isLoadingAlbums: Bool

    let selectedAlbumSummary: String

    let isSavingToAlbum: Bool

    let isPreparingMetadataValidation: Bool

    let isPreparingLibraryMetadataValidation:
        Bool

    let canExportCurrentCard: Bool

    let reloadAlbums: () -> Void

    let saveCurrentCardToAlbum: () -> Void

    let validateExportedMetadata: () -> Void

    let saveAndValidatePhotoLibraryMetadata:
        () -> Void

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            HStack(
                alignment: .center,
                spacing: 8
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

                Button(
                    action: reloadAlbums
                ) {

                    Image(
                        systemName:
                            isLoadingAlbums
                            ? "arrow.trianglehead.2.clockwise.rotate.90"
                            : "arrow.clockwise"
                    )
                }
                .buttonStyle(.borderless)
                .disabled(isLoadingAlbums)
            }

            MinimalInsetCard {
                LabeledContent("写入位置") {
                    Text(selectedAlbumSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider()

                Text(
                    "处理后的图片会直接写入系统图库；不选现有相册时，会自动创建或复用 PhotoMemo 相册。除分辨率变化外，会尽量保留原图 EXIF、拍摄时间与元数据。"
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

            Button(
                isPreparingMetadataValidation
                    ? "正在验证导出元数据..."
                    : "验证导出元数据",
                action: validateExportedMetadata
            )
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(
                !canExportCurrentCard
                || isSavingToAlbum
                || isPreparingMetadataValidation
            )

            Button(
                isPreparingLibraryMetadataValidation
                    ? "正在验证图库元数据..."
                    : "写回后验证图库元数据",
                action:
                    saveAndValidatePhotoLibraryMetadata
            )
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(
                !canExportCurrentCard
                || isSavingToAlbum
                || isPreparingLibraryMetadataValidation
            )
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }
}
