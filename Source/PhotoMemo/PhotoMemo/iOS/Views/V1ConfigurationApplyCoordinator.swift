#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct V1ConfigurationApplyRequest:
    Hashable {

    let subject: MemorySubject?
    let template: Template
    let badge: Badge?
    let shouldWritePhotoDescription: Bool
    let photoDescriptionOverride: String
    let timeAnchorTitle: String
    let timeAnchorDate: Date
    let outputTarget: V1IOSOutputTarget
    let availableAlbums: [PhotoAlbumOption]
    let selectedExistingAlbumIdentifier: String
    let newAlbumName: String
}

struct V1ConfigurationApplyReceipt:
    Hashable {

    let saveReceipt: V1ConfigurationSaveReceipt
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
        >
    ) {
        self.resolveAlbumSelection =
            resolveAlbumSelection
        self.saveConfiguration =
            saveConfiguration
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
                                .configurationUnavailable,
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
            }
        )
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
                    template: request.template,
                    badge: request.badge,
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
                        )
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
