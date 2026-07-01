#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

@MainActor
final class ConfigurationCoordinator {

    private let settingsRepository:
        SettingsRepository

    private let configurationRepository:
        ConfigurationRepository

    private let applyLiveDefaultConfiguration:
        (BatchConfigurationSnapshot) -> Void

    init(
        settingsRepository:
            SettingsRepository,
        configurationRepository:
            ConfigurationRepository,
        applyLiveDefaultConfiguration:
            @escaping (BatchConfigurationSnapshot) -> Void = { _ in }
    ) {
        self.settingsRepository =
            settingsRepository
        self.configurationRepository =
            configurationRepository
        self.applyLiveDefaultConfiguration =
            applyLiveDefaultConfiguration
    }

    func loadDefaultBatchConfigurationSnapshot()
    -> PhotoMemoResult<
        BatchConfigurationSnapshot
    > {

        .success(
            configurationRepository
            .loadDefaultBatchConfigurationSnapshot()
        )
    }

    func loadSharedBatchConfigurationSnapshot()
    -> PhotoMemoResult<
        BatchConfigurationSnapshot
    > {

        .success(
            configurationRepository
            .loadSharedBatchConfigurationSnapshot()
        )
    }

    func resolvedAlbumTitle(
        for identifier: String
    ) -> PhotoMemoResult<String?> {

        .success(
            configurationRepository
            .resolvedAlbumTitle(
                for: identifier
            )
        )
    }

    func updateActiveConfigurationSlotID(
        _ slotID:
            WorkspaceConfigurationSlotID
    ) -> PhotoMemoResult<Void> {

        settingsRepository
            .updateActiveConfigurationSlotID(
                slotID
            )
        return .success(())
    }

    func saveSelectedMemorySubject(
        _ subject: MemorySubject?
    ) -> PhotoMemoResult<Void> {

        settingsRepository
            .saveSelectedMemorySubject(
                subject
            )
        return .success(())
    }

    func saveV1Configuration(
        _ request:
            V1ConfigurationSaveRequest
    ) -> PhotoMemoResult<
        V1ConfigurationSaveReceipt
    > {

        let anchor =
            configurationRepository
            .upsertBirthdayAnchor(
                title:
                    request.timeAnchor.title,
                date:
                    request.timeAnchor.date
            )

        settingsRepository
            .saveSelectedTemplate(
                request.template
                .normalizedForEditing
            )
        settingsRepository
            .saveSelectedBadge(
                request.badge
            )
        settingsRepository
            .saveSelectedMemorySubject(
                request.subject
            )
        settingsRepository
            .savePhotoDescriptionSettings(
                shouldWrite:
                    request
                    .shouldWritePhotoDescription,
                override:
                    request
                    .photoDescriptionOverride
            )
        settingsRepository
            .saveEditorState(
                selectedAnchorID:
                    anchor.id,
                selectedAlbumIdentifier:
                    request
                    .albumSelection
                    .identifier,
                selectedAlbumTitle:
                    request
                    .albumSelection
                    .title
            )
        applyLiveDefaultConfiguration(
            configurationRepository
            .loadDefaultBatchConfigurationSnapshot()
        )

        return .success(
            V1ConfigurationSaveReceipt(
                anchor: anchor
            )
        )
    }

    func loadV1ConfigurationBootstrapState()
    -> PhotoMemoResult<
        V1ConfigurationBootstrapState
    > {

        .success(
            settingsRepository
            .loadV1ConfigurationBootstrapState()
        )
    }
}
#endif
