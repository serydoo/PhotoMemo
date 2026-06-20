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

            HStack(
                alignment: .center,
                spacing: 10
            ) {
                Text("保存至")
                    .font(.subheadline.weight(.medium))

                Picker(
                    "系统相册",
                    selection: $selectedAlbumIdentifier
                ) {

                    Text("系统相册")
                        .tag(
                            PhotoMemoAlbumSelection
                                .systemLibraryIdentifier
                        )

                    Text("PhotoMemo")
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
            }

            Text("如果不指定相册，会默认保存到 PhotoMemo 相册。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )

            VStack(
                alignment: .leading,
                spacing: 8
            ) {

                Button(
                    isSavingToAlbum
                        ? "正在存入系统相册..."
                        : saveButtonTitle,
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

    private var saveButtonTitle: String {

        if selectedAlbumIdentifier
            == PhotoMemoAlbumSelection
            .systemLibraryIdentifier {
            return "保存到系统相册"
        }

        if selectedAlbumIdentifier
            == PhotoAlbumOption.automaticIdentifier {
            return "保存到 PhotoMemo 相册"
        }

        return "保存到“\(selectedAlbumSummary)”"
    }
}
