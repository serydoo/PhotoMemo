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

#if !MEMOMARK_SHARE_EXTENSION
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
    case missingFilmMarkConfiguration
    case missingFilmMarkContent
    case emptyResolvedContent
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
                from: frozenSubject,
                language: configuration.language
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

        if configuration.presentation.route == .filmMark,
           configuration.editor.filmMarkContent == nil {
            throw ProductionConfigurationContractError
                .missingFilmMarkContent
        }

        let snapshot = BatchConfigurationSnapshot(
            configurationID: configuration.id,
            configurationRevision: configuration.revision,
            productionContractVersion:
                reference.contractVersion,
            template:
                configuration.editor.template(
                    for: configuration.presentation.route
                )
                .normalizedForEditing,
            badge: ConfigurationLogoResolver.badge(
                from: configuration.presentation.logo,
                subject: frozenSubject
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
            filmMarkConfiguration:
                configuration.presentation.route == .filmMark
                    ? configuration.presentation.filmMark
                    : nil,
            filmMarkContent:
                configuration.presentation.route == .filmMark
                    ? configuration.editor.filmMarkContent
                    : nil,
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
                // `mediaMode` is a legacy persisted field. Production
                // snapshots now derive output format from the source asset,
                // so an old static-image value must not affect processing.
                MediaOutputMode.originalFormat.rawValue,
            livePhotoPolicyRawValue:
                MemoryConfigurationRecord.Output.LivePhotoPolicy
                    .preserveMotion.rawValue,
            language: configuration.language
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

    private static func albumIdentifier(
        from album:
            MemoryConfigurationRecord.Output.AlbumDescriptor
    ) -> String {
        switch album.destination {
        case .automatic:
            return MemoMarkAlbumSelection.automaticIdentifier
        case .applePhotos:
            return MemoMarkAlbumSelection.systemLibraryIdentifier
        case .existingAlbum,
             .newAlbum:
            return album.identifier
        }
    }
}

/// Resolves the configuration that the user is actively editing for an
/// in-app processing request. The durable processing default remains a
/// separate concept for Apple Photos Share requests, but the Configuration
/// Center's explicit "process these photos" action must not silently borrow
/// that older default after the user has selected another Preset.
enum ConfigurationSnapshotSelectionResolver {

    static func resolve(
        selectedConfigurationID: UUID?,
        aggregate: ConfigurationLibraryRecord?,
        fallback: BatchConfigurationSnapshot,
        selectedPresentationStyle:
            RecordCardPresentationStyle? = nil
    ) -> BatchConfigurationSnapshot? {
        guard let aggregate,
              let selectedConfigurationID else {
            guard let selectedPresentationStyle else {
                return fallback
            }
            var compatibilitySnapshot = fallback
            compatibilitySnapshot.presentationRouteRawValue =
                selectedPresentationStyle.rawValue
            return compatibilitySnapshot
        }

        guard let configuration = aggregate.subjects
            .lazy
            .flatMap(\.configurations)
            .first(where: { $0.id == selectedConfigurationID }) else {
            // A selected ID that cannot be resolved is a configuration
            // consistency failure, not permission to process with a stale
            // Classic White snapshot.
            return nil
        }

        do {
            var snapshot = try ProductionConfigurationSnapshotFactory.resolve(
                reference: ProductionConfigurationReference(
                    configurationID: configuration.id,
                    revision: configuration.revision
                ),
                from: aggregate
            )
            // Time expression is a shared compatibility setting rather than
            // part of the per-preset durable configuration. Preserve the
            // current value while replacing the stale default's presentation
            // and output fields with the selected editor configuration.
            snapshot.timeDisplayConfiguration =
                fallback.timeDisplayConfiguration
            return snapshot
        } catch {
            return nil
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
        if snapshot.presentationRouteRawValue ==
            RecordCardPresentationStyle.filmMark.rawValue,
            snapshot.filmMarkConfiguration == nil {
            throw ProductionConfigurationContractError
                .missingFilmMarkConfiguration
        }
        if snapshot.presentationRouteRawValue ==
            RecordCardPresentationStyle.filmMark.rawValue,
            snapshot.filmMarkContent == nil {
            throw ProductionConfigurationContractError
                .missingFilmMarkContent
        }
        if snapshot.usesEnabledMemorySummary,
            canonical.primaryAnchor == nil {
            throw ProductionConfigurationContractError
                .missingPrimaryAnchor
        }
    }
}

enum ResolvedContentValidator {

    static func validate(
        card: RecordCard,
        configuration: BatchConfigurationSnapshot
    ) throws -> [CardTextBlock] {
        let blocks = FilmMarkPresentationResolver.resolvedContentBlocks(
            for: card
        )
        guard !blocks.isEmpty else {
            throw ProductionConfigurationContractError
                .emptyResolvedContent
        }
        guard configuration.usesEnabledMemorySummary else {
            return blocks
        }
        let token = MetadataContext.Key.memorySummary
        let resolved = CardVariableProvider.build(from: card)[token]
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !resolved.isEmpty else {
            return blocks
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

enum ProductionRenderHealthCheck {

    static func validate(
        card: RecordCard,
        configuration: BatchConfigurationSnapshot
    ) throws -> [CardTextBlock] {
        try ResolvedContentValidator.validate(
            card: card,
            configuration: configuration
        )
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
