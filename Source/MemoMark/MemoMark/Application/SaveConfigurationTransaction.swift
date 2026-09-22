#if !MEMOMARK_SHARE_EXTENSION
import Foundation

struct SaveConfigurationCommand:
    Hashable {

    let subject: MemorySubject?
    let subjects: [MemorySubject]
    let selectedSubjectID: MemorySubject.ID?
    let shouldSaveSubjectLibrary: Bool
    let memoryPresets: [MemoryPreset]
    let selectedMemoryPresetID: MemoryPreset.ID?
    let presentationRoute:
        MemoryConfigurationRecord.Presentation.Route
    let template: Template
    let badge: Badge?
    let locationDisplayConfiguration:
        ExpressionModuleConfiguration?
    let shouldWritePhotoDescription: Bool
    let photoDescriptionOverride: String
    let timeAnchorTitle: String
    let timeAnchorDate: Date
    let outputTarget: ConfigurationOutputTarget
    let mediaOutputMode:
        MediaOutputMode
    let availableAlbums: [PhotoAlbumOption]
    let selectedExistingAlbumIdentifier: String
    let newAlbumName: String

    init(
        subject: MemorySubject?,
        subjects: [MemorySubject],
        selectedSubjectID: MemorySubject.ID?,
        shouldSaveSubjectLibrary: Bool = true,
        memoryPresets: [MemoryPreset] = [],
        selectedMemoryPresetID: MemoryPreset.ID? = nil,
        presentationRoute:
            MemoryConfigurationRecord.Presentation.Route = .classicWhite,
        template: Template,
        badge: Badge?,
        locationDisplayConfiguration:
            ExpressionModuleConfiguration? = nil,
        shouldWritePhotoDescription: Bool,
        photoDescriptionOverride: String,
        timeAnchorTitle: String,
        timeAnchorDate: Date,
        outputTarget: ConfigurationOutputTarget,
        mediaOutputMode:
            MediaOutputMode = .originalFormat,
        availableAlbums: [PhotoAlbumOption],
        selectedExistingAlbumIdentifier: String,
        newAlbumName: String
    ) {
        self.subject = subject
        self.subjects = subjects
        self.selectedSubjectID = selectedSubjectID
        self.shouldSaveSubjectLibrary =
            shouldSaveSubjectLibrary
        self.memoryPresets =
            memoryPresets
        self.selectedMemoryPresetID =
            selectedMemoryPresetID
        self.presentationRoute = presentationRoute
        self.template = template
        self.badge = badge
        self.locationDisplayConfiguration =
            locationDisplayConfiguration
        self.shouldWritePhotoDescription =
            shouldWritePhotoDescription
        self.photoDescriptionOverride =
            photoDescriptionOverride
        self.timeAnchorTitle = timeAnchorTitle
        self.timeAnchorDate = timeAnchorDate
        self.outputTarget = outputTarget
        self.mediaOutputMode =
            mediaOutputMode
        self.availableAlbums = availableAlbums
        self.selectedExistingAlbumIdentifier =
            selectedExistingAlbumIdentifier
        self.newAlbumName = newAlbumName
    }
}

struct SaveConfigurationReceipt:
    Hashable {

    let saveReceipt: ConfigurationSaveReceipt
    let albumSelection: ResolvedAlbumSelection
}

struct SaveConfigurationAggregateReceipt {

    let candidate: ConfigurationAggregateCandidate
    let saveReceipt: ConfigurationLibrarySaveReceipt
    let albumSelection: ResolvedAlbumSelection
}

/// Explicitly changes the durable configuration used by future processing.
/// This command is intentionally independent from Open and Save: activating a
/// persisted configuration must not serialize the editor's current draft.
struct ActivateConfigurationCommand: Hashable {
    let subjectID: UUID
    let configurationID: UUID
}

struct ActivateConfigurationReceipt {
    let candidate: ConfigurationLibraryRecord
    let saveReceipt: ConfigurationLibrarySaveReceipt
}

enum ConfigurationActivationCommandError: Error {
    case configurationUnavailable
    case targetConfigurationNotFound
    case activationProjectionUnavailable
}

@MainActor
struct ActivateConfigurationTransaction {

    private let saveConfigurationLibrary:
        (ConfigurationLibraryRecord) async throws
        -> ConfigurationLibrarySaveReceipt
    private let validateActivation:
        (ConfigurationLibraryRecord) throws -> Void

    init(
        configurationCoordinator: ConfigurationCoordinator?
    ) {
        self.validateActivation = { aggregate in
            guard let configurationCoordinator else {
                throw ConfigurationActivationCommandError
                    .configurationUnavailable
            }
            do {
                try configurationCoordinator
                    .validateConfigurationActivation(aggregate)
            } catch {
                throw ConfigurationActivationCommandError
                    .activationProjectionUnavailable
            }
        }
        self.saveConfigurationLibrary = { aggregate in
            guard let configurationCoordinator else {
                throw ConfigurationActivationCommandError
                    .configurationUnavailable
            }
            return try await configurationCoordinator
                .saveConfigurationLibrary(aggregate)
        }
    }

    init(
        saveConfigurationLibrary: @escaping (
            ConfigurationLibraryRecord
        ) async throws -> ConfigurationLibrarySaveReceipt,
        validateActivation: @escaping (
            ConfigurationLibraryRecord
        ) throws -> Void = { _ in }
    ) {
        self.saveConfigurationLibrary = saveConfigurationLibrary
        self.validateActivation = validateActivation
    }

    static func candidate(
        for command: ActivateConfigurationCommand,
        in aggregate: ConfigurationLibraryRecord
    ) -> ConfigurationLibraryRecord? {
        guard aggregate.subjects.contains(where: { subjectRecord in
            subjectRecord.subject.id == command.subjectID
                && subjectRecord.configurations.contains(where: {
                    $0.id == command.configurationID
                })
        }) else {
            return nil
        }

        var candidate = aggregate
        candidate.activeSubjectID = command.subjectID
        candidate.activeConfigurationID = command.configurationID
        return candidate
    }

    func apply(
        _ command: ActivateConfigurationCommand,
        in aggregate: ConfigurationLibraryRecord
    ) async throws -> ActivateConfigurationReceipt {
        guard let candidate = Self.candidate(
            for: command,
            in: aggregate
        ) else {
            throw ConfigurationActivationCommandError
                .targetConfigurationNotFound
        }

        do {
            try validateActivation(candidate)
        } catch let error as ConfigurationActivationCommandError {
            throw error
        } catch {
            throw ConfigurationActivationCommandError
                .activationProjectionUnavailable
        }

        let receipt = try await saveConfigurationLibrary(candidate)
        guard receipt.compatibilityProjectionFailure == nil else {
            throw ConfigurationActivationCommandError
                .activationProjectionUnavailable
        }
        var durableCandidate = candidate
        durableCandidate.revision = receipt.revision
        return ActivateConfigurationReceipt(
            candidate: durableCandidate,
            saveReceipt: receipt
        )
    }
}

@MainActor
struct SaveConfigurationTransaction {

    // This compatibility-stage transaction accepts both the canonical
    // aggregate command and the historical settings projection. Both paths
    // resolve album identity before issuing exactly one durable save.

    private let resolveAlbumSelection:
        (OutputAlbumSelectionRequest) async -> MemoMarkResult<
            ResolvedAlbumSelection
        >

    private let saveConfiguration:
        (ConfigurationSaveRequest) async -> MemoMarkResult<
            ConfigurationSaveReceipt
        >

    private let saveConfigurationLibrary:
        ((ConfigurationLibraryRecord) async throws ->
            ConfigurationLibrarySaveReceipt)?
    private let saveConfigurationLibraryWithIdentity:
        ((ConfigurationLibraryRecord, UUID) async throws ->
            ConfigurationLibrarySaveReceipt)?

    init(
        resolveAlbumSelection: @escaping (
            OutputAlbumSelectionRequest
        ) async -> MemoMarkResult<
            ResolvedAlbumSelection
        >,
        saveConfiguration: @escaping (
            ConfigurationSaveRequest
        ) async -> MemoMarkResult<
            ConfigurationSaveReceipt
        >,
        saveConfigurationLibrary: ((
            ConfigurationLibraryRecord
        ) async throws -> ConfigurationLibrarySaveReceipt)? = nil,
        saveConfigurationLibraryWithIdentity: ((
            ConfigurationLibraryRecord,
            UUID
        ) async throws -> ConfigurationLibrarySaveReceipt)? = nil
    ) {
        self.resolveAlbumSelection =
            resolveAlbumSelection
        self.saveConfiguration =
            saveConfiguration
        self.saveConfigurationLibrary =
            saveConfigurationLibrary
        self.saveConfigurationLibraryWithIdentity =
            saveConfigurationLibraryWithIdentity
    }

    init(
        configurationCoordinator:
            ConfigurationCoordinator?,
        exportCoordinator:
            ExportCoordinator?
    ) {
        self.init(
            resolveAlbumSelection: {
                request in
                await ResolveOutputAlbumSelectionIntent(
                    request: request,
                    coordinator:
                        exportCoordinator
                )
                .execute()
            },
            saveConfiguration: {
                request in
                guard let configurationCoordinator else {
                    return .failure(
                        MemoMarkError(
                            code:
                                MemoMarkErrorCode.configurationUnavailable,
                            message:
                                "Unable to save the current configuration without an active configuration coordinator."
                        )
                    )
                }

                return await SaveConfigurationIntent(
                    request: request,
                    coordinator:
                        configurationCoordinator
                )
                .execute()
            },
            saveConfigurationLibrary: { aggregate in
                guard let configurationCoordinator else {
                    throw MemoMarkError(
                        code: .configurationUnavailable,
                        message:
                            "Unable to save the current configuration library without an active configuration coordinator."
                    )
                }
                return try await configurationCoordinator
                    .saveConfigurationLibrary(aggregate)
            },
            saveConfigurationLibraryWithIdentity: {
                aggregate,
                changedConfigurationID in
                guard let configurationCoordinator else {
                    throw MemoMarkError(
                        code: .configurationUnavailable,
                        message:
                            "Unable to save the current configuration library without an active configuration coordinator."
                    )
                }
                return try await configurationCoordinator
                    .saveConfigurationLibrary(
                        aggregate,
                        changedConfigurationID: changedConfigurationID
                    )
            }
        )
    }

    func apply(
        candidate: ConfigurationAggregateCandidate,
        availableAlbums: [PhotoAlbumOption]
    ) async -> MemoMarkResult<
        SaveConfigurationAggregateReceipt
    > {
        let album = candidate.configuration.output.album
        let albumRequest = OutputAlbumSelectionRequest(
            outputTarget: Self.outputTarget(for: album.destination),
            availableAlbums: availableAlbums,
            selectedExistingAlbumIdentifier:
                album.destination == .existingAlbum
                ? album.identifier
                : "",
            newAlbumName: album.title
        )

        switch await resolveAlbumSelection(albumRequest) {
        case .failure(let error):
            return .failure(error)
        case .success(let albumSelection):
            do {
                let resolvedCandidate = candidate
                    .resolvingAlbumSelection(albumSelection)
                guard saveConfigurationLibrary != nil
                        || saveConfigurationLibraryWithIdentity != nil else {
                    return .failure(
                        MemoMarkError(
                            code: .configurationUnavailable,
                            message:
                                "Unable to save the current configuration library without an active configuration coordinator."
                        )
                    )
                }
                let receipt: ConfigurationLibrarySaveReceipt
                if let saveConfigurationLibraryWithIdentity {
                    receipt = try await saveConfigurationLibraryWithIdentity(
                        resolvedCandidate.aggregate,
                        resolvedCandidate.configuration.id
                    )
                } else if let saveConfigurationLibrary {
                    receipt = try await saveConfigurationLibrary(
                        resolvedCandidate.aggregate
                    )
                } else {
                    return .failure(
                        MemoMarkError(
                            code: .configurationUnavailable,
                            message:
                                "Unable to save the current configuration library without an active configuration coordinator."
                        )
                    )
                }
                return .success(
                    SaveConfigurationAggregateReceipt(
                        candidate: resolvedCandidate,
                        saveReceipt: receipt,
                        albumSelection: albumSelection
                    )
                )
            } catch let error as MemoMarkError {
                return .failure(error)
            } catch {
                return .failure(
                    MemoMarkError.wrapped(
                        error,
                        code: .persistenceWriteFailed,
                        message: "保存配置失败。"
                    )
                )
            }
        }
    }

    private static func outputTarget(
        for destination:
            MemoryConfigurationRecord.Output.AlbumDescriptor.Destination
    ) -> ConfigurationOutputTarget {
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

    func apply(
        _ request:
            SaveConfigurationCommand
    ) async -> MemoMarkResult<
        SaveConfigurationReceipt
    > {
        let albumRequest =
            OutputAlbumSelectionRequest(
                outputTarget:
                    request.outputTarget,
                availableAlbums:
                    request.availableAlbums,
                selectedExistingAlbumIdentifier:
                    request
                    .selectedExistingAlbumIdentifier,
                newAlbumName:
                    request.newAlbumName
            )

        switch await resolveAlbumSelection(
            albumRequest
        ) {
        case .success(let albumSelection):
            let saveRequest =
                ConfigurationSaveRequest(
                    subject: request.subject,
                    subjects: request.subjects,
                    selectedSubjectID:
                        request.selectedSubjectID,
                    shouldSaveSubjectLibrary:
                        request.shouldSaveSubjectLibrary,
                    memoryPresets:
                        request.memoryPresets,
                    selectedMemoryPresetID:
                        request.selectedMemoryPresetID,
                    presentationRoute:
                        request.presentationRoute,
                    template: request.template,
                    badge: request.badge,
                    locationDisplayConfiguration:
                        request.locationDisplayConfiguration,
                    shouldWritePhotoDescription:
                        request
                        .shouldWritePhotoDescription,
                    photoDescriptionOverride:
                        request
                        .photoDescriptionOverride,
                    timeAnchor:
                        .init(
                            title:
                                request
                                .timeAnchorTitle,
                            date:
                                request
                                .timeAnchorDate
                        ),
                    albumSelection:
                        .init(
                            identifier:
                                albumSelection
                                .identifier,
                            title:
                                albumSelection
                                .title
                        ),
                    mediaOutputMode:
                        request.mediaOutputMode
                )

            switch await saveConfiguration(
                saveRequest
            ) {
            case .success(let saveReceipt):
                return .success(
                    SaveConfigurationReceipt(
                        saveReceipt:
                            saveReceipt,
                        albumSelection:
                            albumSelection
                    )
                )
            case .failure(let error):
                return .failure(error)
            }
        case .failure(let error):
            return .failure(error)
        }
    }

}
#endif
