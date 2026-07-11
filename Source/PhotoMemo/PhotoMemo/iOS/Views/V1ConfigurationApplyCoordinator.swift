#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct V1ConfigurationApplyRequest:
    Hashable {

    let subject: MemorySubject?
    let subjects: [MemorySubject]
    let selectedSubjectID: MemorySubject.ID?
    let shouldSaveSubjectLibrary: Bool
    let memoryPresets: [MemoryPreset]
    let selectedMemoryPresetID: MemoryPreset.ID?
    let template: Template
    let badge: Badge?
    let locationDisplayConfiguration:
        ExpressionModuleConfiguration?
    let shouldWritePhotoDescription: Bool
    let photoDescriptionOverride: String
    let timeAnchorTitle: String
    let timeAnchorDate: Date
    let outputTarget: V1IOSOutputTarget
    let mediaOutputMode:
        V1MediaOutputMode
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
        template: Template,
        badge: Badge?,
        locationDisplayConfiguration:
            ExpressionModuleConfiguration? = nil,
        shouldWritePhotoDescription: Bool,
        photoDescriptionOverride: String,
        timeAnchorTitle: String,
        timeAnchorDate: Date,
        outputTarget: V1IOSOutputTarget,
        mediaOutputMode:
            V1MediaOutputMode = .originalFormat,
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

struct V1ConfigurationApplyReceipt:
    Hashable {

    let saveReceipt: V1ConfigurationSaveReceipt
    let albumSelection: V1ResolvedAlbumSelection
}

struct V1ConfigurationAggregateApplyReceipt {

    let candidate: V1ConfigurationAggregateCandidate
    let saveReceipt: ConfigurationLibrarySaveReceipt
    let albumSelection: V1ResolvedAlbumSelection
}

@MainActor
struct V1ConfigurationApplyCoordinator {

    private let resolveAlbumSelection:
        (V1OutputAlbumSelectionRequest) async -> PhotoMemoResult<
            V1ResolvedAlbumSelection
        >

    private let saveConfiguration:
        (V1ConfigurationSaveRequest) async -> PhotoMemoResult<
            V1ConfigurationSaveReceipt
        >

    private let saveConfigurationLibrary:
        ((ConfigurationLibraryRecord) async throws ->
            ConfigurationLibrarySaveReceipt)?

    init(
        resolveAlbumSelection: @escaping (
            V1OutputAlbumSelectionRequest
        ) async -> PhotoMemoResult<
            V1ResolvedAlbumSelection
        >,
        saveConfiguration: @escaping (
            V1ConfigurationSaveRequest
        ) async -> PhotoMemoResult<
            V1ConfigurationSaveReceipt
        >,
        saveConfigurationLibrary: ((
            ConfigurationLibraryRecord
        ) async throws -> ConfigurationLibrarySaveReceipt)? = nil
    ) {
        self.resolveAlbumSelection =
            resolveAlbumSelection
        self.saveConfiguration =
            saveConfiguration
        self.saveConfigurationLibrary =
            saveConfigurationLibrary
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
                await ResolveV1OutputAlbumSelectionIntent(
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
                        PhotoMemoError(
                            code:
                                PhotoMemoErrorCode.configurationUnavailable,
                            message:
                                "Unable to save the current V1 configuration without an active configuration coordinator."
                        )
                    )
                }

                return await SaveV1ConfigurationIntent(
                    request: request,
                    coordinator:
                        configurationCoordinator
                )
                .execute()
            },
            saveConfigurationLibrary: { aggregate in
                guard let configurationCoordinator else {
                    throw PhotoMemoError(
                        code: .configurationUnavailable,
                        message:
                            "Unable to save the current configuration library without an active configuration coordinator."
                    )
                }
                return try await configurationCoordinator
                    .saveConfigurationLibrary(aggregate)
            }
        )
    }

    func apply(
        candidate: V1ConfigurationAggregateCandidate,
        availableAlbums: [PhotoAlbumOption]
    ) async -> PhotoMemoResult<
        V1ConfigurationAggregateApplyReceipt
    > {
        let album = candidate.configuration.output.album
        let albumRequest = V1OutputAlbumSelectionRequest(
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
                guard let saveConfigurationLibrary else {
                    return .failure(
                        PhotoMemoError(
                            code: .configurationUnavailable,
                            message:
                                "Unable to save the current configuration library without an active configuration coordinator."
                        )
                    )
                }
                let receipt = try await saveConfigurationLibrary(
                    resolvedCandidate.aggregate
                )
                return .success(
                    V1ConfigurationAggregateApplyReceipt(
                        candidate: resolvedCandidate,
                        saveReceipt: receipt,
                        albumSelection: albumSelection
                    )
                )
            } catch let error as PhotoMemoError {
                return .failure(error)
            } catch {
                return .failure(
                    PhotoMemoError.wrapped(
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

    func apply(
        _ request:
            V1ConfigurationApplyRequest
    ) async -> PhotoMemoResult<
        V1ConfigurationApplyReceipt
    > {
        let albumRequest =
            V1OutputAlbumSelectionRequest(
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
                V1ConfigurationSaveRequest(
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
                    V1ConfigurationApplyReceipt(
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
