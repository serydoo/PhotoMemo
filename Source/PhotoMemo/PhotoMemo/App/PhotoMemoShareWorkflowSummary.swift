import Foundation

struct PhotoMemoShareWorkflowSummary: Hashable {

    let styleTitle: String

    let outputTitle: String

    let memoryDateTitle: String?
}

struct PhotoMemoShareWorkflowSummaryBuilder {

    private let albumTitleResolver:
        (String) -> String?

    init(
        albumTitleResolver: @escaping (String) -> String? = {
            _ in nil
        }
    ) {
        self.albumTitleResolver =
            albumTitleResolver
    }

    func build(
        from snapshot: BatchConfigurationSnapshot
    ) -> PhotoMemoShareWorkflowSummary {

        PhotoMemoShareWorkflowSummary(
            styleTitle:
                resolvedConfigurationTitle(
                    from: snapshot.template
                ),
            outputTitle:
                resolvedOutputTitle(
                    from: snapshot.selectedAlbumIdentifier
                ),
            memoryDateTitle:
                resolvedMemoryDateTitle(
                    from: snapshot.anchor
                )
        )
    }
}

private extension PhotoMemoShareWorkflowSummaryBuilder {

    func resolvedConfigurationTitle(
        from template: Template
    ) -> String {

        let trimmedName =
            template.name.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        if trimmedName.isEmpty {
            return template.preset.displayName
        }

        return trimmedName
    }

    func resolvedMemoryDateTitle(
        from anchor: Anchor?
    ) -> String? {

        guard let anchor else {
            return nil
        }

        let trimmedTitle =
            anchor.title.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        let baseTitle =
            trimmedTitle.isEmpty
            ? anchor.type.displayName
            : trimmedTitle

        if anchor.isCountdown {
            return "\(baseTitle) · 倒计时"
        }

        return baseTitle
    }

    func resolvedOutputTitle(
        from selectedAlbumIdentifier: String
    ) -> String {

        if selectedAlbumIdentifier
            == PhotoMemoAlbumSelection
            .systemLibraryIdentifier {
            return "系统相册"
        }

        if selectedAlbumIdentifier.isEmpty {
            return "photomemo 相册"
        }

        if let resolvedAlbumTitle =
            albumTitleResolver(
                selectedAlbumIdentifier
            )?
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            ),
           !resolvedAlbumTitle.isEmpty {
            return "“\(resolvedAlbumTitle)”相册"
        }

        return "当前选定相册"
    }
}
