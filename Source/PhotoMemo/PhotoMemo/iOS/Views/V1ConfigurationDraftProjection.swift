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
    let language: MemoMarkLanguage
    let interfaceLanguage: MemoMarkLanguage

    var regionDrafts: [CardRegion: V1EditorDraft] {
        [
            .slotA: Self.draft(
                from: template.leftTopArea,
                interfaceLanguage: interfaceLanguage
            ),
            .slotB: Self.draft(
                from: template.leftBottomArea,
                interfaceLanguage: interfaceLanguage
            ),
            .slotC: Self.draft(
                from: template.rightTopArea,
                interfaceLanguage: interfaceLanguage
            ),
            .slotD: Self.draft(
                from: template.rightBottomArea,
                interfaceLanguage: interfaceLanguage
            )
        ]
    }

    init(
        configuration: MemoryConfigurationRecord,
        interfaceLanguage: MemoMarkLanguage = .interfaceStored
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
        language = configuration.language
        self.interfaceLanguage = interfaceLanguage
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
    let language: MemoMarkLanguage

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
        savedAt: Date,
        language: MemoMarkLanguage = .simplifiedChinese
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
        self.language = language
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
            language: draft.language,
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
            language: draft.language,
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
            basedOn: template.leftTopArea,
            draft: regionDrafts[.slotA]
        )
        result.leftBottomArea = area(
            basedOn: template.leftBottomArea,
            draft: regionDrafts[.slotB]
        )
        result.rightTopArea = area(
            basedOn: template.rightTopArea,
            draft: regionDrafts[.slotC]
        )
        result.rightBottomArea = area(
            basedOn: template.rightBottomArea,
            draft: regionDrafts[.slotD]
        )
        return result
    }

    private static func area(
        basedOn existingArea: TemplateArea,
        draft: V1EditorDraft?
    ) -> TemplateArea {
        var itemGroups: [[V1ContentItem]] = []
        for item in draft?.items ?? [] {
            if let sourceItemID = item.sourceItemID,
               itemGroups.last?.first?.sourceItemID == sourceItemID {
                itemGroups[itemGroups.count - 1].append(item)
            } else {
                itemGroups.append([item])
            }
        }
        let editableItems: [TemplateItem] =
            itemGroups.compactMap { group -> TemplateItem? in
                guard let firstItem = group.first else {
                    return nil
                }
                let value = group.map(\.templateValue).joined()
                guard !value.isEmpty else {
                    return nil
                }
                return TemplateItem(
                    id: firstItem.sourceItemID ?? firstItem.id,
                    type: group.contains(where: { $0.kind == .token })
                        && value.contains("{{")
                        ? .variable
                        : .text,
                    name: persistedItemName(
                        for: firstItem,
                        value: value
                    ),
                    value: value,
                    isEnabled: true,
                    moduleID: group.contains(where: {
                        $0.kind == .token
                    })
                        ? MemoryCardTemplateTokenCatalog.module(
                            matching: value
                        )
                        : .custom
                )
            }
        var mergedItems: [TemplateItem] = []
        var editableIndex = 0
        for existingItem in existingArea.items {
            if existingItem.isEnabled {
                guard editableIndex < editableItems.count else {
                    continue
                }
                mergedItems.append(editableItems[editableIndex])
                editableIndex += 1
            } else {
                mergedItems.append(existingItem)
            }
        }
        if editableIndex < editableItems.count {
            mergedItems.append(
                contentsOf: editableItems[editableIndex...]
            )
        }
        return TemplateArea(
            id: existingArea.id,
            name: existingArea.name,
            items: mergedItems
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

    private static func persistedItemName(
        for item: V1ContentItem,
        value: String
    ) -> String {
        guard item.kind == .token else {
            return "Text"
        }
        if let module = MemoryCardTemplateTokenCatalog.module(
            matching: value
        ) {
            return module.rawValue
        }
        return MemoryCardTemplateTokenCatalog.tokenName(
            from: value
        ) ?? "UnsupportedToken"
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
        from area: TemplateArea,
        interfaceLanguage: MemoMarkLanguage
    ) -> V1EditorDraft {
        var items: [V1ContentItem] = []
        for item in area.items where item.isEnabled {
            items.append(
                contentsOf: contentItems(
                    from: item,
                    interfaceLanguage: interfaceLanguage
                )
            )
        }
        var draft = V1EditorDraft(
            items: items
        )
        draft.normalizeTrailingTextInput()
        return draft
    }

    static func contentItems(
        from item: TemplateItem,
        interfaceLanguage: MemoMarkLanguage
    ) -> [V1ContentItem] {
        switch item.type {
        case .text:
            return [textItem(
                id: item.id,
                value: item.value,
                sourceItemID: item.id,
                interfaceLanguage: interfaceLanguage
            )]
        case .variable:
            return variableItems(
                from: item,
                interfaceLanguage: interfaceLanguage
            )
        case .badge:
            return []
        }
    }

    static func variableItems(
        from item: TemplateItem,
        interfaceLanguage: MemoMarkLanguage
    ) -> [V1ContentItem] {
        if item.moduleID == .custom {
            return [textItem(
                id: item.id,
                value: item.value,
                sourceItemID: item.id,
                interfaceLanguage: interfaceLanguage
            )]
        }
        if let module = item.moduleID
            ?? MemoryCardTemplateTokenCatalog.module(
                matching: item.value
            ) {
            return [tokenItem(
                id: item.id,
                expression: item.value,
                module: module,
                sourceItemID: item.id,
                interfaceLanguage: interfaceLanguage
            )]
        }

        let expression = item.value as NSString
        let pattern = #"\{\{[a-zA-Z0-9_\-]+\}\}"#
        guard let regex = try? NSRegularExpression(pattern: pattern)
        else {
            return [textItem(
                id: item.id,
                value: item.value,
                sourceItemID: item.id,
                interfaceLanguage: interfaceLanguage
            )]
        }
        let matches = regex.matches(
            in: item.value,
            range: NSRange(location: 0, length: expression.length)
        )
        guard !matches.isEmpty else {
            return [textItem(
                id: item.id,
                value: item.value,
                sourceItemID: item.id,
                interfaceLanguage: interfaceLanguage
            )]
        }

        var result: [V1ContentItem] = []
        var cursor = 0
        var componentIndex = 0
        for match in matches {
            if match.range.location > cursor {
                let literalRange = NSRange(
                    location: cursor,
                    length: match.range.location - cursor
                )
                result.append(
                    textItem(
                        id: derivedID(
                            from: item.id,
                            componentIndex: componentIndex
                        ),
                        value: expression.substring(with: literalRange),
                        sourceItemID: item.id,
                        interfaceLanguage: interfaceLanguage
                    )
                )
                componentIndex += 1
            }

            let savedExpression = expression.substring(
                with: match.range
            )
            let module = MemoryCardTemplateTokenCatalog.module(
                matching: savedExpression
            )
            result.append(
                tokenItem(
                    id: derivedID(
                        from: item.id,
                        componentIndex: componentIndex
                    ),
                    expression: savedExpression,
                    module: module,
                    sourceItemID: item.id,
                    interfaceLanguage: interfaceLanguage
                )
            )
            componentIndex += 1
            cursor = NSMaxRange(match.range)
        }

        if cursor < expression.length {
            result.append(
                textItem(
                    id: derivedID(
                        from: item.id,
                        componentIndex: componentIndex
                    ),
                    value: expression.substring(
                        from: cursor
                    ),
                    sourceItemID: item.id,
                    interfaceLanguage: interfaceLanguage
                )
            )
        }
        return result
    }

    static func textItem(
        id: UUID,
        value: String,
        sourceItemID: UUID? = nil,
        interfaceLanguage: MemoMarkLanguage
    ) -> V1ContentItem {
        let kind: V1ContentItem.Kind = value == "\n"
            ? .lineBreak
            : .text
        return V1ContentItem(
            id: id,
            sourceItemID: sourceItemID,
            kind: kind,
            title: interfaceLanguage.localized(
                key: "module.literal_text",
                fallback: interfaceLanguage == .simplifiedChinese
                    ? "文字"
                    : "Text"
            ),
            value: value,
            savedValue: value,
            systemImage: MemoMarkSymbol.expressionFormula.name
        )
    }

    static func tokenItem(
        id: UUID,
        expression: String,
        module: MemoryCardModuleID?,
        sourceItemID: UUID? = nil,
        interfaceLanguage: MemoMarkLanguage
    ) -> V1ContentItem {
        let unsupportedTitle = interfaceLanguage.localized(
            key: "module.unsupported_content",
            fallback: interfaceLanguage == .simplifiedChinese
                ? "无法识别的内容"
                : "Unsupported content"
        )
        let title = module?.title(for: interfaceLanguage)
            ?? MemoryCardTemplateTokenCatalog.title(
                for: expression,
                language: interfaceLanguage
            )
            ?? unsupportedTitle
        return V1ContentItem(
            id: id,
            sourceItemID: sourceItemID,
            kind: .token,
            title: title,
            value: title,
            savedValue: expression,
            systemImage: module?.systemImage ?? "curlybraces"
        )
    }

    static func derivedID(
        from sourceID: UUID,
        componentIndex: Int
    ) -> UUID {
        let seed = "\(sourceID.uuidString)#\(componentIndex)"
        var firstHash: UInt64 = 14_695_981_039_346_656_037
        var secondHash: UInt64 = 10_995_116_282_112
        for byte in seed.utf8 {
            firstHash ^= UInt64(byte)
            firstHash &*= 1_099_511_628_211
        }
        for byte in seed.utf8.reversed() {
            secondHash ^= UInt64(byte)
            secondHash &*= 1_099_511_628_211
        }
        let value = String(
            format: "%08llX-%04llX-5%03llX-A%03llX-%012llX",
            firstHash >> 32,
            (firstHash >> 16) & 0xFFFF,
            firstHash & 0x0FFF,
            (secondHash >> 48) & 0x0FFF,
            secondHash & 0x0000_FFFF_FFFF_FFFF
        )
        return UUID(uuidString: value) ?? sourceID
    }
}
#endif
