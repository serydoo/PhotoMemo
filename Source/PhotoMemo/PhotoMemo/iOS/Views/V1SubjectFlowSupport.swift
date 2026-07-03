#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct V1SubjectFlowPatch {

    let birthdayDate: Date?
    let shouldRefreshPreview: Bool
    let activeConfigurationMessage: String
    let shouldEnableSubjectLibraryPersistence: Bool
    let shouldCloseOverview: Bool
    let flowState: V1IOSSubjectConfigurationFlowState?
}

enum V1SubjectLibraryPersistenceCoordinator {

    static func persistSelectedSubject(
        _ subject: MemorySubject,
        subjects: [MemorySubject],
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
                coordinator: configurationCoordinator
            )
    }

    static func persistSubjectLibrary(
        subjects: [MemorySubject],
        selectedSubjectID: MemorySubject.ID?,
        selectedSubject: MemorySubject?,
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
                coordinator: configurationCoordinator
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
                shouldSaveSubjectLibrary:
                    shouldSaveSubjectLibrary,
                configurationCoordinator:
                    configurationCoordinator
            )

        return V1SubjectFlowPatch(
            birthdayDate: anchor.date,
            shouldRefreshPreview: false,
            activeConfigurationMessage: "记忆对象已同步",
            shouldEnableSubjectLibraryPersistence: false,
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
                shouldSaveSubjectLibrary:
                    shouldSaveSubjectLibrary,
                configurationCoordinator:
                    configurationCoordinator
            )

        return V1SubjectFlowPatch(
            birthdayDate: nil,
            shouldRefreshPreview: false,
            activeConfigurationMessage: "记忆对象已同步",
            shouldEnableSubjectLibraryPersistence: false,
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
        let shouldPersistLibrary = true
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
                shouldSaveSubjectLibrary:
                    shouldPersistLibrary,
                configurationCoordinator:
                    configurationCoordinator
            )

        return V1SubjectFlowPatch(
            birthdayDate: nil,
            shouldRefreshPreview: false,
            activeConfigurationMessage: "记忆对象已同步",
            shouldEnableSubjectLibraryPersistence:
                shouldPersistLibrary,
            shouldCloseOverview: true,
            flowState:
                makeConfigurationFlowState(
                    from: session,
                    shouldSaveSubjectLibrary:
                        shouldPersistLibrary,
                    configurationCoordinator:
                        configurationCoordinator,
                    savedMessage:
                        "记忆对象已同步",
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
                shouldSaveSubjectLibrary:
                    shouldSaveSubjectLibrary,
                configurationCoordinator:
                    configurationCoordinator
            )

        return V1SubjectFlowPatch(
            birthdayDate: nil,
            shouldRefreshPreview: true,
            activeConfigurationMessage: "记忆对象已同步",
            shouldEnableSubjectLibraryPersistence: false,
            shouldCloseOverview: false,
            flowState: nil
        )
    }

    static func makeConfigurationFlowState(
        from session: ConfigurationSession,
        shouldSaveSubjectLibrary: Bool,
        configurationCoordinator: ConfigurationCoordinator?,
        savedMessage: String,
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
                            activeConfigurationMessage:
                                savedMessage,
                            shouldEnableSubjectLibraryPersistence:
                                false,
                            shouldCloseOverview: false,
                            flowState: nil
                        )
                    )
                }
            )
    }
}
#endif
