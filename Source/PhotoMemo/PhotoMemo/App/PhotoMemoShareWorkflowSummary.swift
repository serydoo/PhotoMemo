import Foundation

struct PhotoMemoShareWorkflowSummary: Hashable {

    let styleTitle: String

    let memorySubjectTitle: String?

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

#if !PHOTOMEMO_SHARE_EXTENSION
        let memoryDateTitle =
            resolvedProductionMemoryDateTitle(
                from: snapshot
            )
#else
        let memoryDateTitle =
            resolvedMemoryDateTitle(
                from: snapshot.legacyAnchor
            )
#endif

        return PhotoMemoShareWorkflowSummary(
            styleTitle:
                resolvedConfigurationTitle(
                    from: snapshot.template
                ),
            memorySubjectTitle:
                resolvedMemorySubjectTitle(
                    from: snapshot.memorySubjectText
                ),
            outputTitle:
                resolvedOutputTitle(
                    from: snapshot.selectedAlbumIdentifier
                ),
            memoryDateTitle:
                memoryDateTitle
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

    func resolvedMemorySubjectTitle(
        from text: String?
    ) -> String? {

        guard let text else {
            return nil
        }

        let trimmedText =
            text.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return trimmedText.isEmpty
            ? nil
            : trimmedText
    }

#if !PHOTOMEMO_SHARE_EXTENSION
    func resolvedProductionMemoryDateTitle(
        from snapshot: BatchConfigurationSnapshot
    ) -> String? {

        if let frozenSnapshot =
            snapshot
            .canonicalProductionSnapshot {
            return resolvedMemoryDateTitle(
                from: frozenSnapshot
                    .primaryAnchor
            )
        }

        return resolvedMemoryDateTitle(
            from: snapshot.legacyAnchor
        )
    }

    func resolvedMemoryDateTitle(
        from anchor: MemoryAnchor?
    ) -> String? {

        guard let anchor else {
            return nil
        }

        let trimmedTitle =
            anchor.title.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
        let fallbackTitle =
            anchor.anchorType?
            .displayName ?? ""

        let baseTitle =
            trimmedTitle.isEmpty
            ? fallbackTitle
            : trimmedTitle

        guard !baseTitle.isEmpty else {
            return nil
        }

        if anchor.anchorType?
            .defaultCountdown == true {
            return "\(baseTitle) · 倒计时"
        }

        return baseTitle
    }
#endif

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
            return "时光记相册"
        }

        if let resolvedAlbumTitle =
            albumTitleResolver(
                selectedAlbumIdentifier
            )?
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            ),
           !resolvedAlbumTitle.isEmpty {
            return resolvedAlbumTitle
        }

        return "当前选定相册"
    }
}
