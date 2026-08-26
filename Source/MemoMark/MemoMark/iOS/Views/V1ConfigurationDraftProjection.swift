#if !MEMOMARK_SHARE_EXTENSION
import Foundation

struct V1ConfigurationDraftProjection: Hashable {

    let configurationID: UUID
    let configurationRevision: Int
    let title: String
    let templatesByPresentationStyle:
        [RecordCardPresentationStyle: Template]
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

    var template: Template {
        templatesByPresentationStyle[route]
            ?? templatesByPresentationStyle[.classicWhite]
            ?? Template.classicWhite
    }

    var regionDraftsByPresentationStyle:
        [RecordCardPresentationStyle: [CardRegion: V1EditorDraft]] {
        Dictionary(
            uniqueKeysWithValues:
                templatesByPresentationStyle.map { style, template in
                    (
                        style,
                        Self.regionDrafts(
                            from: template,
                            interfaceLanguage: interfaceLanguage
                        )
                    )
                }
        )
    }

    var regionDrafts: [CardRegion: V1EditorDraft] {
        regionDraftsByPresentationStyle[route]
            ?? Self.regionDrafts(
                from: template,
                interfaceLanguage: interfaceLanguage
            )
    }

    init(
        configuration: MemoryConfigurationRecord,
        interfaceLanguage: MemoMarkLanguage = .interfaceStored
    ) {
        configurationID = configuration.id
        configurationRevision = configuration.revision
        title = configuration.title
        templatesByPresentationStyle =
            configuration.editor.effectiveTemplatesByPresentationStyle
        regionTemplateIDs =
            configuration.editor.regionTemplateIDs
        locationConfiguration =
            configuration.presentation.locationConfiguration
        logoMode = configuration.presentation.logo.mode
        badge = configuration.presentation.logo.mode == .customUpload
            ? Self.badge(
                from: configuration.presentation.logo.badge
            )
            : nil
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
        // Keep the retired persisted field readable, but never project its
        // old static-image choice back into the active V4 workflow.
        mediaOutputMode = .originalFormat
        livePhotoPolicy = .preserveMotion
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
    let regionDraftsByPresentationStyle:
        [RecordCardPresentationStyle: [CardRegion: V1EditorDraft]]
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
    let presentationRoute:
        MemoryConfigurationRecord.Presentation.Route
    let selectedTimeAnchorID: UUID?
    let savedAt: Date
    let language: MemoMarkLanguage

    init(
        title: String,
        regionDrafts: [CardRegion: V1EditorDraft],
        regionDraftsByPresentationStyle:
            [RecordCardPresentationStyle: [CardRegion: V1EditorDraft]] = [:],
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
        presentationRoute:
            MemoryConfigurationRecord.Presentation.Route = .classicWhite,
        selectedTimeAnchorID: UUID?,
        savedAt: Date,
        language: MemoMarkLanguage = .simplifiedChinese
    ) {
        self.title = title
        self.regionDrafts = regionDrafts
        self.regionDraftsByPresentationStyle =
            regionDraftsByPresentationStyle
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
        self.presentationRoute = presentationRoute
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
        let logo = normalizedLogo(from: draft)
        let baseTemplate = Template(
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
        )
        let templates = templates(
            basedOn: [.classicWhite: baseTemplate],
            title: draft.title,
            draft: draft
        )
        return MemoryConfigurationRecord(
            id: id,
            title: draft.title,
            revision: 0,
            savedAt: draft.savedAt,
            selectedTimeAnchorID: draft.selectedTimeAnchorID,
            language: draft.language,
            editor: .init(
                template: templates[draft.presentationRoute]
                    ?? templates[.classicWhite]!,
                templatesByPresentationStyle: templates,
                regionTemplateIDs: draft.regionTemplateIDs,
                memoryCopy: .init(
                    usesCustomText: draft.usesCustomMemoryWriteText,
                    customText: draft.customMemoryWriteText
                )
            ),
            presentation: .init(
                route: draft.presentationRoute,
                locationConfiguration: draft.locationConfiguration,
                logo: logo
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
        let logo = normalizedLogo(
            from: draft,
            subject: aggregate.subjects[subjectIndex].subject
        )
        let templates = templates(
            basedOn: previous.editor.effectiveTemplatesByPresentationStyle,
            title: draft.title,
            draft: draft
        )
        let configuration = MemoryConfigurationRecord(
            id: previous.id,
            title: draft.title,
            revision: previous.revision + 1,
            savedAt: draft.savedAt,
            selectedTimeAnchorID: draft.selectedTimeAnchorID,
            language: draft.language,
            editor: .init(
                template: templates[draft.presentationRoute]
                    ?? templates[.classicWhite]!,
                templatesByPresentationStyle: templates,
                regionTemplateIDs: draft.regionTemplateIDs,
                memoryCopy: .init(
                    usesCustomText:
                        draft.usesCustomMemoryWriteText,
                    customText: draft.customMemoryWriteText
                )
            ),
            presentation: .init(
                route: draft.presentationRoute,
                locationConfiguration:
                    draft.locationConfiguration,
                logo: logo
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
        candidate.subjects[subjectIndex].assetManifest =
            manifestRegisteringCustomLogoReferences(
                configurations:
                    candidate.subjects[subjectIndex].configurations,
                existing:
                    candidate.subjects[subjectIndex].assetManifest
            )
        return V1ConfigurationAggregateCandidate(
            aggregate: candidate,
            configuration: configuration
        )
    }

    private static func templates(
        basedOn existing: [RecordCardPresentationStyle: Template],
        title: String,
        draft: V1ConfigurationAggregateDraft
    ) -> [RecordCardPresentationStyle: Template] {
        Dictionary(
            uniqueKeysWithValues:
                RecordCardPresentationStyle.allCases.map { style in
                    let base = existing[style]
                        ?? existing[.classicWhite]
                        ?? Template.classicWhite
                    let styleDrafts = draft
                        .regionDraftsByPresentationStyle[style]
                        ?? draft.regionDrafts
                    return (
                        style,
                        template(
                            basedOn: base,
                            title: title,
                            regionDrafts: styleDrafts
                        )
                    )
                }
        )
    }

    private static func manifestRegisteringCustomLogoReferences(
        configurations: [MemoryConfigurationRecord],
        existing: PortableAssetManifest
    ) -> PortableAssetManifest {
        let referencedCustomLogoPaths = Set<String>(
            configurations.compactMap { configuration in
                guard configuration.presentation.logo.mode
                    == .customUpload else {
                    return nil
                }
                return configuration.presentation.logo.badge?
                    .assetReference?.relativePath
            }
        )

        // Custom-logo ownership exists only while a configuration uses
        // customUpload. This also removes stale entries when the user
        // switches to Apple or subjectAvatar.
        var manifest = PortableAssetManifest(
            entries: existing.entries.filter { entry in
                entry.role != .customLogo
                || referencedCustomLogoPaths.contains(
                    entry.reference.relativePath
                )
            }
        )

        for configuration in configurations where configuration.presentation
            .logo.mode == .customUpload {
            guard let reference = configuration.presentation.logo.badge?
                .assetReference,
                  !manifest.entries.contains(where: {
                      $0.reference == reference
                  }) else {
                continue
            }
            manifest.entries.append(
                PortableAssetManifest.Entry(
                    id: MemoryConfigurationRecord.deterministicUUID(
                        basedOn: configuration.id,
                        discriminator: 0xA4
                    ),
                    role: .customLogo,
                    reference: reference,
                    originalFileName: URL(
                        fileURLWithPath: reference.relativePath
                    ).lastPathComponent
                )
            )
        }
        return manifest
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
        from badge: Badge?,
        logoMode: V1LogoMode
    ) -> MemoryConfigurationRecord.Presentation.Logo.BadgeDescriptor? {
        // The subject avatar is owned by MemorySubject and is resolved by
        // ProductionConfigurationContract. It must never be persisted as a
        // configuration-owned custom logo reference.
        guard logoMode == .customUpload else {
            return nil
        }

        return badge.map {
            MemoryConfigurationRecord.Presentation.Logo.BadgeDescriptor(
                id: $0.id,
                name: $0.name,
                type: $0.type,
                imageName: $0.imageName,
                systemSymbol: $0.systemSymbol,
                isSystemDefault: $0.isSystemDefault,
                assetReference: ConfigurationSubjectAssetMapper()
                    .makePortablePath($0.imagePath)
                    .flatMap {
                        try? PortableAssetReference(
                            relativePath: $0
                        )
                    }
            )
        }
    }

    private static func normalizedLogo(
        from draft: V1ConfigurationAggregateDraft,
        subject: MemorySubject? = nil
    ) -> MemoryConfigurationRecord.Presentation.Logo {
        let descriptor = badgeDescriptor(
            from: draft.badge,
            logoMode: draft.logoMode
        )
        switch draft.logoMode {
        case .appleMini:
            return .init(mode: .appleMini, badge: nil)
        case .customUpload:
            guard descriptor?.assetReference != nil else {
                return .init(mode: .appleMini, badge: nil)
            }
            return .init(
                mode: .customUpload,
                badge: descriptor
            )
        case .subjectAvatar:
            guard subject == nil
                || subject?.identity.avatarBadgeImagePath != nil
                || subject?.identity.avatarImagePath != nil else {
                return .init(mode: .appleMini, badge: nil)
            }
            return .init(mode: .subjectAvatar, badge: nil)
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
            imagePath: ConfigurationSubjectAssetMapper()
                .makeRuntimePath(
                    descriptor.assetReference?.relativePath
                ),
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

    static func regionDrafts(
        from template: Template,
        interfaceLanguage: MemoMarkLanguage
    ) -> [CardRegion: V1EditorDraft] {
        [
            .slotA: draft(
                from: template.leftTopArea,
                interfaceLanguage: interfaceLanguage
            ),
            .slotB: draft(
                from: template.leftBottomArea,
                interfaceLanguage: interfaceLanguage
            ),
            .slotC: draft(
                from: template.rightTopArea,
                interfaceLanguage: interfaceLanguage
            ),
            .slotD: draft(
                from: template.rightBottomArea,
                interfaceLanguage: interfaceLanguage
            )
        ]
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
