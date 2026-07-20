#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

enum V1SubjectFlowEvent:
    Hashable {

    case reopenSubjectLibraryPersistence
    case rebootstrapPreviewDrafts
    case persistActiveConfigurationSelection
}

struct V1SubjectFlowPatch {

    let birthdayDate: Date?
    let shouldRefreshPreview: Bool
    let activeConfigurationStatus:
        V1ConfigurationStatus

    // One-shot commands consumed when the patch is applied.
    let events: [V1SubjectFlowEvent]

    let shouldCloseOverview: Bool
    let flowState: V1IOSSubjectConfigurationFlowState?
}

struct V1SubjectLibraryRecoveryReceipt:
    Hashable {

    let preservedRawPayload: Data
}

enum V1SubjectLibraryPersistenceCoordinator {

    static func persistSelectedSubject(
        _ subject: MemorySubject,
        subjects: [MemorySubject],
        memoryPresets: [MemoryPreset],
        selectedMemoryPresetID: MemoryPreset.ID?,
        shouldSaveSubjectLibrary: Bool,
        configurationCoordinator: ConfigurationCoordinator?
    ) {
        guard shouldSaveSubjectLibrary else {
            _ =
                configurationCoordinator?
                .saveSelectedMemorySubject(subject)
            return
        }

        V1SubjectLibraryResolver
            .persist(
                subjects:
                    V1SubjectLibraryResolver
                    .subjectsForSaving(
                        selectedSubject: subject,
                        subjects: subjects
                ),
                selectedSubjectID: subject.id,
                coordinator: configurationCoordinator,
                memoryPresets: memoryPresets,
                selectedMemoryPresetID:
                    selectedMemoryPresetID
            )
    }

    static func persistSubjectLibrary(
        subjects: [MemorySubject],
        selectedSubjectID: MemorySubject.ID?,
        selectedSubject: MemorySubject?,
        memoryPresets: [MemoryPreset],
        selectedMemoryPresetID: MemoryPreset.ID?,
        shouldSaveSubjectLibrary: Bool,
        configurationCoordinator: ConfigurationCoordinator?
    ) {
        guard shouldSaveSubjectLibrary else {
            if let selectedSubject {
                _ =
                    configurationCoordinator?
                    .saveSelectedMemorySubject(
                        selectedSubject
                    )
            }
            return
        }

        V1SubjectLibraryResolver
            .persist(
                subjects: subjects,
                selectedSubjectID: selectedSubjectID,
                coordinator: configurationCoordinator,
                memoryPresets: memoryPresets,
                selectedMemoryPresetID:
                    selectedMemoryPresetID
            )
    }
}

enum V1SubjectLibraryRecoveryCoordinator {

    static func recoverCorruptLibrary(
        subjects: [MemorySubject],
        selectedSubjectID: MemorySubject.ID?,
        readFailure: PhotoMemoSharedDefaultsReadFailure,
        configurationCoordinator: ConfigurationCoordinator?
    ) -> V1SubjectLibraryRecoveryReceipt? {
        guard let rawPayload =
            readFailure.rawPayload else {
            return nil
        }

        V1SubjectLibraryResolver
            .persist(
                subjects: subjects,
                selectedSubjectID: selectedSubjectID,
                coordinator: configurationCoordinator
            )

        return V1SubjectLibraryRecoveryReceipt(
            preservedRawPayload: rawPayload
        )
    }
}

@MainActor
enum V1SubjectOverviewActionCoordinator {

    static func activateAnchor(
        _ anchorID: UUID,
        in session: ConfigurationSession,
        shouldSaveSubjectLibrary: Bool,
        configurationCoordinator: ConfigurationCoordinator?
    ) -> V1SubjectFlowPatch? {
        guard let anchor =
            V1SubjectLibraryMutationCoordinator
            .activateAnchor(
                anchorID,
                in: session
            ) else {
            return nil
        }

        V1SubjectLibraryPersistenceCoordinator
            .persistSubjectLibrary(
                subjects: session.state.subjects,
                selectedSubjectID:
                    session.state.selectedSubjectID,
                selectedSubject:
                    session.state.selectedSubject,
                memoryPresets:
                    session.state.memoryPresets,
                selectedMemoryPresetID:
                    session.state.selectedMemoryPresetID,
                shouldSaveSubjectLibrary:
                    shouldSaveSubjectLibrary,
                configurationCoordinator:
                    configurationCoordinator
            )

        return V1SubjectFlowPatch(
            birthdayDate: anchor.date,
            shouldRefreshPreview: false,
            activeConfigurationStatus:
                .subjectSynced,
            events: [],
            shouldCloseOverview: false,
            flowState: nil
        )
    }

    static func selectSubject(
        _ subjectID: MemorySubject.ID,
        in session: ConfigurationSession,
        shouldSaveSubjectLibrary: Bool,
        configurationCoordinator: ConfigurationCoordinator?
    ) -> V1SubjectFlowPatch? {
        guard let subject =
            V1SubjectLibraryMutationCoordinator
            .selectSubject(
                subjectID,
                in: session
            ) else {
            return nil
        }

        V1SubjectLibraryPersistenceCoordinator
            .persistSubjectLibrary(
                subjects: session.state.subjects,
                selectedSubjectID: subject.id,
                selectedSubject: subject,
                memoryPresets:
                    session.state.memoryPresets,
                selectedMemoryPresetID:
                    session.state.selectedMemoryPresetID,
                shouldSaveSubjectLibrary:
                    shouldSaveSubjectLibrary,
                configurationCoordinator:
                    configurationCoordinator
            )

        return V1SubjectFlowPatch(
            birthdayDate:
                subject.primaryTimeAnchor?.date
                ?? subject.referenceDate,
            shouldRefreshPreview: false,
            activeConfigurationStatus:
                .subjectSynced,
            events: [
                .rebootstrapPreviewDrafts,
                .persistActiveConfigurationSelection
            ],
            shouldCloseOverview: false,
            flowState: nil
        )
    }

    static func addDefaultSubject(
        referenceDate: Date,
        to session: ConfigurationSession,
        shouldSaveSubjectLibrary: Bool,
        configurationCoordinator: ConfigurationCoordinator?,
        onPersistedSubject:
            @escaping (V1SubjectFlowPatch) -> Void
    ) -> V1SubjectFlowPatch {
        let shouldPersistLibrary =
            shouldSaveSubjectLibrary
        let subject =
            V1SubjectLibraryMutationCoordinator
            .addDefaultSubject(
                referenceDate: referenceDate,
                to: session
            )

        V1SubjectLibraryPersistenceCoordinator
            .persistSubjectLibrary(
                subjects: session.state.subjects,
                selectedSubjectID: subject.id,
                selectedSubject: subject,
                memoryPresets:
                    session.state.memoryPresets,
                selectedMemoryPresetID:
                    session.state.selectedMemoryPresetID,
                shouldSaveSubjectLibrary:
                    shouldPersistLibrary,
                configurationCoordinator:
                    configurationCoordinator
            )

        return V1SubjectFlowPatch(
            birthdayDate:
                subject.primaryTimeAnchor?.date
                ?? subject.referenceDate,
            shouldRefreshPreview: false,
            activeConfigurationStatus:
                .subjectSynced,
            events:
                shouldPersistLibrary
                ? [
                    .reopenSubjectLibraryPersistence,
                    .rebootstrapPreviewDrafts
                ]
                : [.rebootstrapPreviewDrafts],
            shouldCloseOverview: true,
            flowState:
                makeConfigurationFlowState(
                    from: session,
                    shouldSaveSubjectLibrary:
                        shouldPersistLibrary,
                    configurationCoordinator:
                        configurationCoordinator,
                    savedStatus:
                        .subjectSynced,
                    onPersistedSubject:
                        onPersistedSubject
                )
        )
    }

    static func deleteCurrentSubject(
        from session: ConfigurationSession,
        shouldSaveSubjectLibrary: Bool,
        configurationCoordinator: ConfigurationCoordinator?
    ) -> V1SubjectFlowPatch? {
        guard session.state.subjects.count > 1,
              V1SubjectLibraryMutationCoordinator
            .deleteCurrentSubject(
                from: session
            ) != nil
        else {
            return nil
        }

        V1SubjectLibraryPersistenceCoordinator
            .persistSubjectLibrary(
                subjects: session.state.subjects,
                selectedSubjectID:
                    session.state.selectedSubjectID,
                selectedSubject:
                    session.state.selectedSubject,
                memoryPresets:
                    session.state.memoryPresets,
                selectedMemoryPresetID:
                    session.state.selectedMemoryPresetID,
                shouldSaveSubjectLibrary:
                    shouldSaveSubjectLibrary,
                configurationCoordinator:
                    configurationCoordinator
            )

        return V1SubjectFlowPatch(
            birthdayDate:
                session.state.selectedSubject?
                .primaryTimeAnchor?
                .date
                ?? session.state.selectedSubject?
                .referenceDate,
            shouldRefreshPreview: true,
            activeConfigurationStatus:
                .subjectSynced,
            events: [.rebootstrapPreviewDrafts],
            shouldCloseOverview: false,
            flowState: nil
        )
    }

    static func makeConfigurationFlowState(
        from session: ConfigurationSession,
        shouldSaveSubjectLibrary: Bool,
        configurationCoordinator: ConfigurationCoordinator?,
        savedStatus: V1ConfigurationStatus,
        onPersistedSubject:
            @escaping (V1SubjectFlowPatch) -> Void
    ) -> V1IOSSubjectConfigurationFlowState? {
        V1IOSSubjectConfigurationFlowPresenter
            .makeFlowState(
                from: session,
                persistSubject: { subject in
                    V1SubjectLibraryPersistenceCoordinator
                        .persistSelectedSubject(
                            subject,
                            subjects: session.state.subjects,
                            memoryPresets:
                                session.state.memoryPresets,
                            selectedMemoryPresetID:
                                session.state.selectedMemoryPresetID,
                            shouldSaveSubjectLibrary:
                                shouldSaveSubjectLibrary,
                            configurationCoordinator:
                                configurationCoordinator
                        )

                    onPersistedSubject(
                        V1SubjectFlowPatch(
                            birthdayDate:
                                subject
                                .primaryTimeAnchor?
                                .date,
                            shouldRefreshPreview: true,
                            activeConfigurationStatus:
                                savedStatus,
                            events: [],
                            shouldCloseOverview: false,
                            flowState: nil
                        )
                    )
                }
            )
    }
}
#endif
