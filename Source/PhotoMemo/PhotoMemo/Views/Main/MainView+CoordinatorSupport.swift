import Foundation

extension MainView {

    func handleImportedPhoto(
        _ photo: SelectedPhoto
    ) {

        selectedPhoto = photo

        if titleText.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty {
            titleText =
                selectedAnchor?.title
                ?? "PhotoMemo"
        }
    }

    func syncSelectedAnchor(
        with anchors: [Anchor]
    ) {

        guard let selectedAnchorID else {

            self.selectedAnchorID =
                anchors.first?.id
            return
        }

        if !anchors.contains(
            where: {
                $0.id == selectedAnchorID
            }
        ) {

            self.selectedAnchorID =
                anchors.first?.id
        }
    }

    func previewCardMaxWidth(
        for selectedPhoto: SelectedPhoto
    ) -> CGFloat {

        let width =
            CGFloat(
                selectedPhoto.metadata.imageWidth
                ?? Int(
                    selectedPhoto.image
                        .photoMemoSize.width
                )
            )

        let height =
            CGFloat(
                selectedPhoto.metadata.imageHeight
                ?? Int(
                    selectedPhoto.image
                        .photoMemoSize.height
                )
            )

        guard height > 0 else {
            return 900
        }

        return width >= height ? 900 : 560
    }
}
