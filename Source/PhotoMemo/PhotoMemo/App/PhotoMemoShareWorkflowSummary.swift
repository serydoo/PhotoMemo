import Foundation

struct PhotoMemoShareWorkflowSummary: Hashable {

    let configurationTitle: String

    let anchorTitle: String

    let outputTitle: String
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
            configurationTitle:
                resolvedConfigurationTitle(
                    from: snapshot.template
                ),
            anchorTitle:
                resolvedAnchorTitle(
                    from: snapshot.anchor
                ),
            outputTitle:
                resolvedOutputTitle(
                    from: snapshot.selectedAlbumIdentifier
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

    func resolvedAnchorTitle(
        from anchor: Anchor?
    ) -> String {

        guard let anchor else {
            return "不使用时间点"
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
            return "写入系统相册"
        }

        if selectedAlbumIdentifier.isEmpty {
            return "自动存入 PhotoMemo"
        }

        if let resolvedAlbumTitle =
            albumTitleResolver(
                selectedAlbumIdentifier
            )?
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            ),
           !resolvedAlbumTitle.isEmpty {
            return "存入“\(resolvedAlbumTitle)”"
        }

        return "按当前选定相册保存"
    }
}
