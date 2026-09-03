#if !MEMOMARK_SHARE_EXTENSION
import Foundation

private enum SubjectPersistenceError: LocalizedError {
    case subjectMappingFailed(MemorySubject.ID)

    var errorDescription: String? {
        switch self {
        case .subjectMappingFailed(let subjectID):
            return "Configuration subject mapping failed for \(subjectID.uuidString)."
        }
    }
}

enum SubjectFlowEvent:
    Hashable {

    case reopenSubjectLibraryPersistence
    case rebootstrapPreviewDrafts
    case persistActiveConfigurationSelection
}

struct SubjectFlowPatch {

    let birthdayDate: Date?
    let shouldRefreshPreview: Bool
    let activeConfigurationStatus:
        ConfigurationPersistenceStatus

    // One-shot commands consumed when the patch is applied.
    let events: [SubjectFlowEvent]

    let shouldCloseOverview: Bool
    let flowState: SubjectConfigurationFlowState?
}

struct SubjectLibraryRecoveryReceipt:
    Hashable {

    let preservedRawPayload: Data
}

enum SubjectLibraryPersistenceCoordinator {

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

        SubjectLibraryResolver
            .persist(
                subjects:
                    SubjectLibraryResolver
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

        SubjectLibraryResolver
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

enum SubjectLibraryRecoveryCoordinator {

    static func recoverCorruptLibrary(
        subjects: [MemorySubject],
        selectedSubjectID: MemorySubject.ID?,
        readFailure: MemoMarkSharedDefaultsReadFailure,
        configurationCoordinator: ConfigurationCoordinator?
    ) -> SubjectLibraryRecoveryReceipt? {
        guard let rawPayload =
            readFailure.rawPayload else {
            return nil
        }

        SubjectLibraryResolver
            .persist(
                subjects: subjects,
                selectedSubjectID: selectedSubjectID,
                coordinator: configurationCoordinator
            )

        return SubjectLibraryRecoveryReceipt(
            preservedRawPayload: rawPayload
        )
    }
}

@MainActor
enum SubjectOverviewActionCoordinator {

    static func activateAnchor(
        _ anchorID: UUID,
        in session: ConfigurationSession,
        shouldSaveSubjectLibrary: Bool,
        configurationCoordinator: ConfigurationCoordinator?
    ) -> SubjectFlowPatch? {
        guard let anchor =
            SubjectLibraryMutationCoordinator
            .activateAnchor(
                anchorID,
                in: session
            ) else {
            return nil
        }

        SubjectLibraryPersistenceCoordinator
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

        return SubjectFlowPatch(
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
    ) -> SubjectFlowPatch? {
        guard let subject =
            SubjectLibraryMutationCoordinator
            .selectSubject(
                subjectID,
                in: session
            ) else {
            return nil
        }

        SubjectLibraryPersistenceCoordinator
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

        return SubjectFlowPatch(
            birthdayDate:
                subject.primaryTimeAnchor?.date
                ?? subject.referenceDate,
            shouldRefreshPreview: false,
            activeConfigurationStatus:
                session.selectedMemoryPresetIsDurable
                ? .saved
                : .subjectSynced,
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
            @escaping (SubjectFlowPatch) -> Void
    ) -> SubjectFlowPatch {
        let shouldPersistLibrary =
            shouldSaveSubjectLibrary
        let subject =
            SubjectLibraryMutationCoordinator
            .addDefaultSubject(
                referenceDate: referenceDate,
                to: session
            )

        SubjectLibraryPersistenceCoordinator
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

        return SubjectFlowPatch(
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
    ) -> SubjectFlowPatch? {
        guard session.state.subjects.count > 1,
              SubjectLibraryMutationCoordinator
            .deleteCurrentSubject(
                from: session
            ) != nil
        else {
            return nil
        }

        SubjectLibraryPersistenceCoordinator
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

        return SubjectFlowPatch(
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
        savedStatus: ConfigurationPersistenceStatus,
        onPersistedSubject:
            @escaping (SubjectFlowPatch) -> Void
    ) -> SubjectConfigurationFlowState? {
        SubjectConfigurationFlowPresenter
            .makeFlowState(
                from: session,
                persistSubject: { subject in
                    var durableAggregate: ConfigurationLibraryRecord?
                    if let configurationCoordinator {
                        let aggregate: ConfigurationLibraryRecord?
                        do {
                            aggregate = try await configurationCoordinator
                                .loadConfigurationLibrary()
                                .aggregate
                        } catch ConfigurationLibraryPersistenceError
                            .noStoredAggregate {
                            aggregate = nil
                        }
                        if let aggregate,
                           aggregate.subjects.contains(where: {
                            $0.subject.id == subject.id
                           }) {
                            guard let candidate =
                                LocalConfigurationLibraryPresenter
                                .updatingSubject(
                                    subject: subject,
                                    in: aggregate
                                ) else {
                                throw SubjectPersistenceError
                                    .subjectMappingFailed(subject.id)
                            }
                            if candidate != aggregate {
                                let receipt = try await configurationCoordinator
                                    .saveConfigurationLibrary(candidate)
                                var durableCandidate = candidate
                                durableCandidate.revision = receipt.revision
                                durableAggregate = durableCandidate
                            }
                        }
                    }

                    SubjectLibraryPersistenceCoordinator
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

                    if let durableAggregate {
                        session.updateConfigurationLibraryReference(
                            durableAggregate
                        )
                    }

                },
                didPersistSubject: { subject in
                    onPersistedSubject(
                        SubjectFlowPatch(
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
