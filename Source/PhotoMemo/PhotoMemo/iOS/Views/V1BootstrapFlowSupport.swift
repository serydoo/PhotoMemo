#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

enum V1BootstrapSessionRestorePlan {

    case none
    case restoreConfigurationLibrary(
        ConfigurationLibraryRecord
    )
    case restoreLibrary(
        subjects: [MemorySubject],
        selectedSubjectID: MemorySubject.ID?,
        memoryPresets: [MemoryPreset],
        selectedMemoryPresetID: MemoryPreset.ID?
    )
    case restoreSelectedSubject(
        MemorySubject
    )
}

struct V1BootstrapFlowPatch {

    let shouldSaveSubjectLibrary: Bool
    let customLogoBadge: Badge?
    let logoMode: V1LogoMode
    let logoStatusMessage: String?
    let outputTarget: V1IOSOutputTarget
    let mediaOutputMode:
        V1MediaOutputMode
    let selectedExistingAlbumIdentifier: String
    let suggestedNewAlbumName: String?
    let locationDisplayConfiguration:
        ExpressionModuleConfiguration?
    let sessionRestorePlan:
        V1BootstrapSessionRestorePlan
    let birthdayDate: Date?
    let welcomeState: V1WelcomeFlowState
    let regionDrafts: [CardRegion: V1EditorDraft]
}

struct V1BootstrapFlowCoordinator {

    private let loadConfigurationState:
        () -> V1ConfigurationBootstrapState

    private let loadDrafts:
        (
            V1PreviewCompositionContext,
            (CardRegion) -> V1EditorDraft
        ) -> [CardRegion: V1EditorDraft]

    private let presentWelcome:
        (Bool) -> V1WelcomeFlowState

    init(
        loadConfigurationState:
            @escaping () -> V1ConfigurationBootstrapState,
        loadDrafts:
            @escaping (
                V1PreviewCompositionContext,
                (CardRegion) -> V1EditorDraft
            ) -> [CardRegion: V1EditorDraft],
        presentWelcome:
            @escaping (Bool) -> V1WelcomeFlowState
                = {
                    hasSeenWelcome in
                    V1WelcomeFlowCoordinator
                        .presentWelcome(
                            hasSeenWelcome:
                                hasSeenWelcome
                        )
                }
    ) {
        self.loadConfigurationState =
            loadConfigurationState
        self.loadDrafts = loadDrafts
        self.presentWelcome =
            presentWelcome
    }

    init(
        configurationBootstrapCoordinator:
            V1ConfigurationBootstrapCoordinator,
        session: ConfigurationSession,
        engine: V1PreviewCompositionEngine
    ) {
        self.init(
            loadConfigurationState: {
                configurationBootstrapCoordinator
                    .loadState()
            },
            loadDrafts: {
                context,
                makeDefaultDraft in
                V1DraftBootstrapCoordinator(
                    session: session,
                    context: context,
                    engine: engine
                )
                .bootstrapDrafts(
                    makeDefaultDraft:
                        makeDefaultDraft
                )
            }
        )
    }

    func bootstrap(
        hasSeenWelcome: Bool,
        fallbackBirthdayDate: Date,
        makeDefaultDraft:
            (CardRegion) -> V1EditorDraft
    ) -> V1BootstrapFlowPatch {
        let state =
            loadConfigurationState()
        let projection =
            V1ConfigurationBootstrapPresenter
            .projection(from: state)
        let resolvedSubjects =
            state.subjects.map {
                V1SubjectLibraryResolver
                    .sanitizedSubjectLibrary($0)
            }
        let resolvedSubject =
            V1SubjectLibraryResolver
            .resolvedBootstrapSubject(
                subjects: resolvedSubjects,
                selectedSubjectID:
                    state.selectedSubjectID,
                fallbackSubject:
                    state.selectedSubject
            )
        let resolvedBirthdayDate =
            resolvedSubject?.primaryTimeAnchor?.date
            ?? resolvedSubject?.referenceDate
        let draftContext =
            V1PreviewCompositionContext(
                subject: resolvedSubject,
                birthdayDate:
                    resolvedBirthdayDate
                    ?? fallbackBirthdayDate,
                locationDisplayConfiguration:
                    state
                    .locationDisplayConfiguration
            )

        return V1BootstrapFlowPatch(
            shouldSaveSubjectLibrary:
                state.subjectLibraryReadFailure == nil,
            customLogoBadge:
                projection.customLogoBadge,
            logoMode:
                projection.logoMode,
            logoStatusMessage:
                projection.logoMode == .customUpload
                && projection.customLogoBadge != nil
                ? "已使用自选 Logo。"
                : nil,
            outputTarget:
                projection.outputTarget,
            mediaOutputMode:
                projection.mediaOutputMode,
            selectedExistingAlbumIdentifier:
                projection
                .selectedExistingAlbumIdentifier,
            suggestedNewAlbumName:
                projection
                .suggestedNewAlbumName,
            locationDisplayConfiguration:
                projection
                .locationDisplayConfiguration,
            sessionRestorePlan:
                sessionRestorePlan(
                    state: state,
                    resolvedSubjects:
                        resolvedSubjects,
                    resolvedSubject:
                        resolvedSubject
                ),
            birthdayDate:
                resolvedBirthdayDate,
            welcomeState:
                presentWelcome(
                    hasSeenWelcome
                ),
            regionDrafts:
                loadDrafts(
                    draftContext,
                    makeDefaultDraft
                )
        )
    }

    private func sessionRestorePlan(
        state: V1ConfigurationBootstrapState,
        resolvedSubjects: [MemorySubject]?,
        resolvedSubject: MemorySubject?
    ) -> V1BootstrapSessionRestorePlan {
        if let configurationLibrary =
            state.configurationLibrary {
            return .restoreConfigurationLibrary(
                configurationLibrary
            )
        }

        if let subjects = resolvedSubjects,
           !subjects.isEmpty {
            return .restoreLibrary(
                subjects: subjects,
                selectedSubjectID:
                    state.selectedSubjectID,
                memoryPresets:
                    state.memoryPresets,
                selectedMemoryPresetID:
                    state.selectedMemoryPresetID
            )
        }

        if let resolvedSubject {
            return .restoreSelectedSubject(
                resolvedSubject
            )
        }

        return .none
    }
}
#endif
