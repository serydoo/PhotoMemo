import Foundation

struct ProductionConfigurationReference:
    Codable,
    Hashable,
    Sendable {

    static let currentContractVersion = 1

    let configurationID: UUID
    let revision: Int
    let contractVersion: Int

    init(
        configurationID: UUID,
        revision: Int,
        contractVersion: Int = currentContractVersion
    ) {
        self.configurationID = configurationID
        self.revision = revision
        self.contractVersion = contractVersion
    }
}

#if !PHOTOMEMO_SHARE_EXTENSION
enum ProductionConfigurationContractError:
    Error,
    Equatable {

    case missingReference
    case invalidReference
    case configurationNotFound(UUID)
    case revisionMismatch(
        configurationID: UUID,
        requested: Int,
        durable: Int
    )
    case missingSelectedAnchor(
        configurationID: UUID,
        anchorID: UUID?
    )
    case missingCanonicalSnapshot
    case snapshotIdentityMismatch
    case missingMemorySubject
    case missingPrimaryAnchor
    case emptySemanticOutput(String)
    case emptyRendererOutput(String)
}

enum ProductionConfigurationSnapshotFactory {

    static func resolve(
        reference: ProductionConfigurationReference,
        from aggregate: ConfigurationLibraryRecord
    ) throws -> BatchConfigurationSnapshot {
        guard reference.contractVersion
            == ProductionConfigurationReference
            .currentContractVersion,
            reference.revision > 0
        else {
            throw ProductionConfigurationContractError
                .invalidReference
        }

        guard let match = aggregate.subjects.lazy.compactMap({
            subjectRecord -> (
                SubjectConfigurationRecord,
                MemoryConfigurationRecord
            )? in
            guard let configuration =
                subjectRecord.configurations.first(where: {
                    $0.id == reference.configurationID
                })
            else {
                return nil
            }
            return (subjectRecord, configuration)
        }).first else {
            throw ProductionConfigurationContractError
                .configurationNotFound(
                    reference.configurationID
                )
        }

        let subjectRecord = match.0
        let configuration = match.1

        guard configuration.revision == reference.revision else {
            throw ProductionConfigurationContractError
                .revisionMismatch(
                    configurationID: configuration.id,
                    requested: reference.revision,
                    durable: configuration.revision
                )
        }

        var frozenSubject = subjectRecord.subject
        frozenSubject.activeTimeAnchorID =
            configuration.selectedTimeAnchorID

        let selectedAnchor: MemorySubject.TimeAnchor?
        if let selectedTimeAnchorID =
            configuration.selectedTimeAnchorID {
            guard let anchor = frozenSubject.timeAnchor(
                id: selectedTimeAnchorID
            ) else {
                throw ProductionConfigurationContractError
                    .missingSelectedAnchor(
                        configurationID: configuration.id,
                        anchorID: selectedTimeAnchorID
                    )
            }
            selectedAnchor = anchor
        } else {
            selectedAnchor = frozenSubject.primaryTimeAnchor
        }

        var canonicalSnapshot =
            ConfigurationSnapshotBuilder.build(
                from: frozenSubject
            )
        canonicalSnapshot.configurationID = configuration.id
        canonicalSnapshot.configurationRevision =
            configuration.revision

        let legacyAnchor: Anchor?
        if let selectedAnchor {
            legacyAnchor = anchor(from: selectedAnchor)
        } else {
            legacyAnchor = nil
        }

        let snapshot = BatchConfigurationSnapshot(
            configurationID: configuration.id,
            configurationRevision: configuration.revision,
            productionContractVersion:
                reference.contractVersion,
            template:
                configuration.editor.template
                .normalizedForEditing,
            badge: badge(
                from:
                    configuration.presentation.logo.badge
            ),
            anchor: legacyAnchor,
            memorySubjectText:
                frozenSubject
                .resolvedExpressionSubjectText,
            locationDisplayConfiguration:
                configuration.presentation
                .locationConfiguration,
            usesCustomMemoryWriteText:
                configuration.editor.memoryCopy
                .usesCustomText,
            customMemoryWriteText:
                configuration.editor.memoryCopy
                .customText,
            presentationRouteRawValue:
                configuration.presentation.route.rawValue,
            logoModeRawValue:
                configuration.presentation.logo.mode.rawValue,
            shouldWritePhotoDescription:
                configuration.output
                .photosDescriptionPolicy.isEnabled,
            photoDescriptionOverride:
                configuration.output
                .photosDescriptionPolicy.overrideText,
            selectedAlbumIdentifier:
                albumIdentifier(
                    from: configuration.output.album
                ),
            mediaOutputModeRawValue:
                configuration.output.mediaMode.rawValue,
            livePhotoPolicyRawValue:
                configuration.output.livePhotoPolicy.rawValue
        )
        .withCanonicalProductionSnapshot(
            canonicalSnapshot
        )

        try ProductionConfigurationSnapshotContract
            .validate(snapshot)
        return snapshot
    }

    private static func anchor(
        from anchor: MemorySubject.TimeAnchor
    ) -> Anchor {
        let type = anchor.resolvedAnchorType
        return Anchor(
            id: anchor.id,
            type: type,
            title: anchor.title,
            date: anchor.date,
            isCountdown: type.defaultCountdown,
            expressionStyle:
                anchor.resolvedExpressionStyle
        )
    }

    private static func badge(
        from descriptor:
            MemoryConfigurationRecord.Presentation.Logo
            .BadgeDescriptor?
    ) -> Badge? {
        guard let descriptor else {
            return nil
        }
        return Badge(
            id: descriptor.id,
            name: descriptor.name,
            type: descriptor.type,
            imageName: descriptor.imageName,
            imagePath:
                descriptor.assetReference?.relativePath,
            systemSymbol: descriptor.systemSymbol,
            isSystemDefault: descriptor.isSystemDefault
        )
    }

    private static func albumIdentifier(
        from album:
            MemoryConfigurationRecord.Output.AlbumDescriptor
    ) -> String {
        switch album.destination {
        case .automatic:
            return PhotoMemoAlbumSelection.automaticIdentifier
        case .applePhotos:
            return PhotoMemoAlbumSelection.systemLibraryIdentifier
        case .existingAlbum,
             .newAlbum:
            return album.identifier
        }
    }
}

enum ProductionConfigurationSnapshotContract {

    static func validate(
        _ snapshot: BatchConfigurationSnapshot
    ) throws {
        guard snapshot.productionContractVersion
            == ProductionConfigurationReference
            .currentContractVersion,
            let configurationID = snapshot.configurationID,
            let configurationRevision =
                snapshot.configurationRevision,
            configurationRevision > 0
        else {
            throw ProductionConfigurationContractError
                .missingReference
        }
        guard let canonical =
            snapshot.canonicalProductionSnapshot
        else {
            throw ProductionConfigurationContractError
                .missingCanonicalSnapshot
        }
        guard canonical.configurationID == configurationID,
            canonical.configurationRevision
                == configurationRevision
        else {
            throw ProductionConfigurationContractError
                .snapshotIdentityMismatch
        }
        guard canonical.memorySubject != nil else {
            throw ProductionConfigurationContractError
                .missingMemorySubject
        }
        if snapshot.usesEnabledMemorySummary,
            canonical.primaryAnchor == nil {
            throw ProductionConfigurationContractError
                .missingPrimaryAnchor
        }
    }
}

enum ProductionRenderHealthCheck {

    static func validate(
        card: RecordCard,
        configuration: BatchConfigurationSnapshot
    ) throws -> [CardTextBlock] {
        let blocks = CardTextBlockEngine().build(from: card)
        guard configuration.usesEnabledMemorySummary else {
            return blocks
        }
        let token = MetadataContext.Key.memorySummary
        let resolved = CardVariableProvider.build(from: card)[token]
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !resolved.isEmpty else {
            throw ProductionConfigurationContractError
                .emptySemanticOutput(token)
        }
        guard configuration.enabledMemorySummaryAreas
            .allSatisfy({ area in
                blocks.contains(where: {
                    $0.area == area
                        && $0.value.contains(resolved)
                })
            }) else {
            throw ProductionConfigurationContractError
                .emptyRendererOutput(token)
        }
        return blocks
    }
}

private extension BatchConfigurationSnapshot {

    var usesEnabledMemorySummary: Bool {
        !enabledMemorySummaryAreas.isEmpty
    }

    var enabledMemorySummaryAreas: Set<CardTextArea> {
        let token = "{{\(MetadataContext.Key.memorySummary)}}"
        let areas: [(CardTextArea, TemplateArea)] = [
            (.leftTop, template.leftTopArea),
            (.leftBottom, template.leftBottomArea),
            (.rightTop, template.rightTopArea),
            (.rightBottom, template.rightBottomArea),
            (.badge, template.badgeArea)
        ]
        return Set(
            areas.compactMap { cardArea, templateArea in
                templateArea.items.contains {
                $0.isEnabled && $0.value.contains(token)
                } ? cardArea : nil
            }
        )
    }
}
#endif
