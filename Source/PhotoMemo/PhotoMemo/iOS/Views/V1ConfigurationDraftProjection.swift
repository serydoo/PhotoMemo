#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct V1ConfigurationDraftProjection: Hashable {

    let configurationID: UUID
    let configurationRevision: Int
    let title: String
    let template: Template
    let regionTemplateIDs: [CardRegion: String]
    let locationConfiguration:
        ExpressionModuleConfiguration?
    let logoMode: V1LogoMode
    let badge: Badge?
    let usesCustomMemoryWriteText: Bool
    let customMemoryWriteText: String
    let shouldWritePhotosDescription: Bool
    let photosDescriptionOverride: String
    let outputTarget: V1IOSOutputTarget
    let selectedAlbumIdentifier: String
    let albumTitle: String
    let mediaOutputMode: V1MediaOutputMode
    let livePhotoPolicy:
        MemoryConfigurationRecord.Output.LivePhotoPolicy
    let route: MemoryConfigurationRecord.Presentation.Route
    let selectedTimeAnchorID: UUID?

    var regionDrafts: [CardRegion: V1EditorDraft] {
        [
            .slotA: Self.draft(from: template.leftTopArea),
            .slotB: Self.draft(from: template.leftBottomArea),
            .slotC: Self.draft(from: template.rightTopArea),
            .slotD: Self.draft(from: template.rightBottomArea)
        ]
    }

    init(
        configuration: MemoryConfigurationRecord
    ) {
        configurationID = configuration.id
        configurationRevision = configuration.revision
        title = configuration.title
        template = configuration.editor.template
        regionTemplateIDs =
            configuration.editor.regionTemplateIDs
        locationConfiguration =
            configuration.presentation.locationConfiguration
        logoMode = configuration.presentation.logo.mode
        badge = Self.badge(
            from: configuration.presentation.logo.badge
        )
        usesCustomMemoryWriteText =
            configuration.editor.memoryCopy.usesCustomText
        customMemoryWriteText =
            configuration.editor.memoryCopy.customText
        shouldWritePhotosDescription =
            configuration.output.photosDescriptionPolicy.isEnabled
        photosDescriptionOverride =
            configuration.output.photosDescriptionPolicy.overrideText
        outputTarget = Self.outputTarget(
            for: configuration.output.album.destination
        )
        selectedAlbumIdentifier =
            configuration.output.album.destination == .existingAlbum
            ? configuration.output.album.identifier
            : ""
        albumTitle = configuration.output.album.title
        mediaOutputMode = configuration.output.mediaMode
        livePhotoPolicy = configuration.output.livePhotoPolicy
        route = configuration.presentation.route
        selectedTimeAnchorID =
            configuration.selectedTimeAnchorID
    }
}

struct V1ConfigurationAggregateDraft: Hashable {

    let title: String
    let regionDrafts: [CardRegion: V1EditorDraft]
    let regionTemplateIDs: [CardRegion: String]
    let locationConfiguration: ExpressionModuleConfiguration?
    let logoMode: V1LogoMode
    let badge: Badge?
    let usesCustomMemoryWriteText: Bool
    let customMemoryWriteText: String
    let shouldWritePhotosDescription: Bool
    let photosDescriptionOverride: String
    let outputTarget: V1IOSOutputTarget
    let selectedAlbumIdentifier: String
    let albumTitle: String
    let mediaOutputMode: V1MediaOutputMode
    let livePhotoPolicy:
        MemoryConfigurationRecord.Output.LivePhotoPolicy
    let selectedTimeAnchorID: UUID?
    let savedAt: Date

    init(
        title: String,
        regionDrafts: [CardRegion: V1EditorDraft],
        regionTemplateIDs: [CardRegion: String],
        locationConfiguration: ExpressionModuleConfiguration?,
        logoMode: V1LogoMode,
        badge: Badge?,
        usesCustomMemoryWriteText: Bool,
        customMemoryWriteText: String,
        shouldWritePhotosDescription: Bool,
        photosDescriptionOverride: String,
        outputTarget: V1IOSOutputTarget,
        selectedAlbumIdentifier: String,
        albumTitle: String,
        mediaOutputMode: V1MediaOutputMode,
        livePhotoPolicy:
            MemoryConfigurationRecord.Output.LivePhotoPolicy,
        selectedTimeAnchorID: UUID?,
        savedAt: Date
    ) {
        self.title = title
        self.regionDrafts = regionDrafts
        self.regionTemplateIDs = regionTemplateIDs
        self.locationConfiguration = locationConfiguration
        self.logoMode = logoMode
        self.badge = badge
        self.usesCustomMemoryWriteText =
            usesCustomMemoryWriteText
        self.customMemoryWriteText = customMemoryWriteText
        self.shouldWritePhotosDescription =
            shouldWritePhotosDescription
        self.photosDescriptionOverride =
            photosDescriptionOverride
        self.outputTarget = outputTarget
        self.selectedAlbumIdentifier =
            selectedAlbumIdentifier
        self.albumTitle = albumTitle
        self.mediaOutputMode = mediaOutputMode
        self.livePhotoPolicy = livePhotoPolicy
        self.selectedTimeAnchorID = selectedTimeAnchorID
        self.savedAt = savedAt
    }

}

struct V1ConfigurationAggregateCandidate: Hashable {

    let aggregate: ConfigurationLibraryRecord
    let configuration: MemoryConfigurationRecord

    func resolvingAlbumSelection(
        _ selection: V1ResolvedAlbumSelection
    ) -> Self {
        var resolvedConfiguration = configuration
        if resolvedConfiguration.output.album.destination
            == .newAlbum {
            resolvedConfiguration.output.album.destination =
                .existingAlbum
        }
        resolvedConfiguration.output.album.identifier =
            resolvedConfiguration.output.album.destination
                == .existingAlbum
            ? selection.identifier
            : ""
        resolvedConfiguration.output.album.title =
            selection.title
        var resolvedAggregate = aggregate
        for subjectIndex in resolvedAggregate.subjects.indices {
            guard let configurationIndex =
                resolvedAggregate.subjects[subjectIndex]
                .configurations.firstIndex(where: {
                    $0.id == configuration.id
                }) else {
                continue
            }
            resolvedAggregate.subjects[subjectIndex]
                .configurations[configurationIndex] =
                resolvedConfiguration
            break
        }
        return Self(
            aggregate: resolvedAggregate,
            configuration: resolvedConfiguration
        )
    }
}

enum V1ConfigurationAggregateCandidateError: Error {
    case missingActiveSubject
    case missingActiveConfiguration
}

enum V1ConfigurationAggregateCandidateBuilder {

    static func seedConfiguration(
        id: UUID,
        draft: V1ConfigurationAggregateDraft
    ) -> MemoryConfigurationRecord {
        MemoryConfigurationRecord(
            id: id,
            title: draft.title,
            revision: 0,
            savedAt: draft.savedAt,
            selectedTimeAnchorID: draft.selectedTimeAnchorID,
            editor: .init(
                template: template(
                    basedOn: Template(
                        preset: .classicWhite,
                        name: draft.title,
                        leftTopArea: TemplateArea(
                            name: "Recorder",
                            items: []
                        ),
                        leftBottomArea: TemplateArea(
                            name: "Timeline",
                            items: []
                        ),
                        rightTopArea: TemplateArea(
                            name: "Capture Summary",
                            items: []
                        ),
                        rightBottomArea: TemplateArea(
                            name: "Memory",
                            items: []
                        ),
                        badgeArea: .badge
                    ),
                    title: draft.title,
                    regionDrafts: draft.regionDrafts
                ),
                regionTemplateIDs: draft.regionTemplateIDs,
                memoryCopy: .init(
                    usesCustomText: draft.usesCustomMemoryWriteText,
                    customText: draft.customMemoryWriteText
                )
            ),
            presentation: .init(
                route: .classicWhite,
                locationConfiguration: draft.locationConfiguration,
                logo: .init(
                    mode: draft.logoMode,
                    badge: badgeDescriptor(from: draft.badge)
                )
            ),
            output: .init(
                mediaMode: draft.mediaOutputMode,
                livePhotoPolicy: draft.livePhotoPolicy,
                photosDescriptionPolicy: .init(
                    isEnabled: draft.shouldWritePhotosDescription,
                    overrideText: draft.photosDescriptionOverride
                ),
                album: albumDescriptor(from: draft)
            )
        )
    }

    static func build(
        from aggregate: ConfigurationLibraryRecord,
        draft: V1ConfigurationAggregateDraft
    ) throws -> V1ConfigurationAggregateCandidate {
        guard let subjectID = aggregate.activeSubjectID,
              let subjectIndex = aggregate.subjects.firstIndex(
                where: { $0.subject.id == subjectID }
              ) else {
            throw V1ConfigurationAggregateCandidateError
                .missingActiveSubject
        }
        guard let configurationID = aggregate.activeConfigurationID,
              let configurationIndex = aggregate.subjects[subjectIndex]
                .configurations.firstIndex(
                    where: { $0.id == configurationID }
                ) else {
            throw V1ConfigurationAggregateCandidateError
                .missingActiveConfiguration
        }

        let previous = aggregate.subjects[subjectIndex]
            .configurations[configurationIndex]
        let configuration = MemoryConfigurationRecord(
            id: previous.id,
            title: draft.title,
            revision: previous.revision + 1,
            savedAt: draft.savedAt,
            selectedTimeAnchorID: draft.selectedTimeAnchorID,
            editor: .init(
                template: template(
                    basedOn: previous.editor.template,
                    title: draft.title,
                    regionDrafts: draft.regionDrafts
                ),
                regionTemplateIDs: draft.regionTemplateIDs,
                memoryCopy: .init(
                    usesCustomText:
                        draft.usesCustomMemoryWriteText,
                    customText: draft.customMemoryWriteText
                )
            ),
            presentation: .init(
                route: .classicWhite,
                locationConfiguration:
                    draft.locationConfiguration,
                logo: .init(
                    mode: draft.logoMode,
                    badge: badgeDescriptor(from: draft.badge)
                )
            ),
            output: .init(
                mediaMode: draft.mediaOutputMode,
                livePhotoPolicy: draft.livePhotoPolicy,
                photosDescriptionPolicy: .init(
                    isEnabled:
                        draft.shouldWritePhotosDescription,
                    overrideText:
                        draft.photosDescriptionOverride
                ),
                album: albumDescriptor(from: draft)
            )
        )
        var candidate = aggregate
        candidate.subjects[subjectIndex]
            .configurations[configurationIndex] = configuration
        return V1ConfigurationAggregateCandidate(
            aggregate: candidate,
            configuration: configuration
        )
    }

    private static func template(
        basedOn template: Template,
        title: String,
        regionDrafts: [CardRegion: V1EditorDraft]
    ) -> Template {
        var result = template
        result.name = title
        result.leftTopArea = area(
            named: "Recorder",
            draft: regionDrafts[.slotA]
        )
        result.leftBottomArea = area(
            named: "Timeline",
            draft: regionDrafts[.slotB]
        )
        result.rightTopArea = area(
            named: "Capture Summary",
            draft: regionDrafts[.slotC]
        )
        result.rightBottomArea = area(
            named: "Memory",
            draft: regionDrafts[.slotD]
        )
        return result
    }

    private static func area(
        named name: String,
        draft: V1EditorDraft?
    ) -> TemplateArea {
        TemplateArea(
            name: name,
            items: (draft?.items ?? []).compactMap { item in
                let value = item.templateValue
                guard !value.isEmpty else {
                    return nil
                }
                return TemplateItem(
                    id: item.id,
                    type: item.kind == .token ? .variable : .text,
                    name: item.title,
                    value: value,
                    isEnabled: true
                )
            }
        )
    }

    private static func badgeDescriptor(
        from badge: Badge?
    ) -> MemoryConfigurationRecord.Presentation.Logo.BadgeDescriptor? {
        badge.map {
            .init(
                id: $0.id,
                name: $0.name,
                type: $0.type,
                imageName: $0.imageName,
                systemSymbol: $0.systemSymbol,
                isSystemDefault: $0.isSystemDefault,
                assetReference: $0.imagePath.flatMap {
                    try? PortableAssetReference(
                        relativePath: $0
                    )
                }
            )
        }
    }

    private static func albumDescriptor(
        from draft: V1ConfigurationAggregateDraft
    ) -> MemoryConfigurationRecord.Output.AlbumDescriptor {
        let destination:
            MemoryConfigurationRecord.Output.AlbumDescriptor.Destination
        switch draft.outputTarget {
        case .automatic:
            destination = .automatic
        case .applePhotos:
            destination = .applePhotos
        case .existingAlbum:
            destination = .existingAlbum
        case .newAlbum:
            destination = .newAlbum
        }
        return .init(
            destination: destination,
            identifier: destination == .existingAlbum
                ? draft.selectedAlbumIdentifier
                : "",
            title: draft.albumTitle
        )
    }
}

private extension V1ConfigurationDraftProjection {

    static func outputTarget(
        for destination:
            MemoryConfigurationRecord.Output.AlbumDescriptor.Destination
    ) -> V1IOSOutputTarget {
        switch destination {
        case .automatic:
            return .automatic
        case .applePhotos:
            return .applePhotos
        case .existingAlbum:
            return .existingAlbum
        case .newAlbum:
            return .newAlbum
        }
    }

    static func badge(
        from descriptor:
            MemoryConfigurationRecord.Presentation.Logo.BadgeDescriptor?
    ) -> Badge? {
        guard let descriptor else {
            return nil
        }

        return Badge(
            id: descriptor.id,
            name: descriptor.name,
            type: descriptor.type,
            imageName: descriptor.imageName,
            imagePath: descriptor.assetReference?.relativePath,
            systemSymbol: descriptor.systemSymbol,
            isSystemDefault: descriptor.isSystemDefault
        )
    }

    static func draft(
        from area: TemplateArea
    ) -> V1EditorDraft {
        var items: [V1ContentItem] = []
        for item in area.items where item.isEnabled {
            if let contentItem = contentItem(from: item) {
                items.append(contentItem)
            }
        }
        var draft = V1EditorDraft(
            items: items
        )
        draft.normalizeTrailingTextInput()
        return draft
    }

    static func contentItem(
        from item: TemplateItem
    ) -> V1ContentItem? {
        switch item.type {
        case .text:
            return V1ContentItem(
                id: item.id,
                kind: .text,
                title: item.name,
                value: item.value,
                savedValue: item.value,
                systemImage: "textformat"
            )
        case .variable:
            let module = module(for: item)
            return V1ContentItem(
                id: item.id,
                kind: .token,
                title: module?.title ?? item.name,
                value: item.value,
                savedValue: item.value,
                systemImage: module?.systemImage ?? "curlybraces"
            )
        case .badge:
            return nil
        }
    }

    static func module(
        for item: TemplateItem
    ) -> IOSInsertableModule? {
        IOSInsertableModule.allCases.first { module in
            item.value == module.rendererToken
            || item.value == module.token
            || item.name == module.title
        }
    }
}
#endif
