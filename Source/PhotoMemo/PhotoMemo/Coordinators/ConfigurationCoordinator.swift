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

    func saveV1SubjectLibrary(
        subjects: [MemorySubject],
        selectedSubjectID: MemorySubject.ID?
    ) -> PhotoMemoResult<Void> {

        settingsRepository
            .saveV1SubjectLibrary(
                subjects: subjects,
                selectedSubjectID: selectedSubjectID
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
            .syncAnchors(
                from: request.subject,
                fallbackTitle:
                    request.timeAnchor.title,
                fallbackDate:
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
            .saveLocationDisplayConfiguration(
                request.locationDisplayConfiguration
            )
        settingsRepository
            .saveSelectedMemorySubject(
                request.subject
            )
        if request.shouldSaveSubjectLibrary,
           !request.subjects.isEmpty || request.subject != nil {
            settingsRepository
                .saveV1SubjectLibrary(
                    subjects:
                        subjectsForSaving(
                            selectedSubject:
                                request.subject,
                            subjects:
                                request.subjects
                        ),
                    selectedSubjectID:
                        request.selectedSubjectID
                        ?? request.subject?.id
                )
        }
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

private extension ConfigurationCoordinator {

    func subjectsForSaving(
        selectedSubject: MemorySubject?,
        subjects: [MemorySubject]
    ) -> [MemorySubject] {
        guard let selectedSubject else {
            return subjects
        }

        var resolvedSubjects = subjects
        if let index =
            resolvedSubjects.firstIndex(
                where: {
                    $0.id == selectedSubject.id
                }
            ) {
            resolvedSubjects[index] = selectedSubject
        } else {
            resolvedSubjects.append(selectedSubject)
        }

        return resolvedSubjects
    }
}
#endif
