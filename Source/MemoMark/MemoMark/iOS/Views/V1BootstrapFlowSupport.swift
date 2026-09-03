#if !MEMOMARK_SHARE_EXTENSION
import Foundation

enum ConfigurationBootstrapSessionRestorePlan {

    case clearSession
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

struct ConfigurationBootstrapFlowPatch {

    let shouldSaveSubjectLibrary: Bool
    let customLogoBadge: Badge?
    let logoMode: ConfigurationLogoMode
    let logoStatusMessage: String?
    let outputTarget: ConfigurationOutputTarget
    let mediaOutputMode:
        MediaOutputMode
    let selectedExistingAlbumIdentifier: String
    let suggestedNewAlbumName: String?
    let locationDisplayConfiguration:
        ExpressionModuleConfiguration?
    let sessionRestorePlan:
        ConfigurationBootstrapSessionRestorePlan
    let birthdayDate: Date?
    let welcomeState: WelcomeFlowState
    let regionDrafts: [CardRegion: MemoryCardEditorDraft]
}

struct ConfigurationBootstrapFlowCoordinator {

    private let loadConfigurationState:
        () -> ConfigurationBootstrapState

    private let loadDrafts:
        (
            MemoryCardPreviewCompositionContext,
            (CardRegion) -> MemoryCardEditorDraft
        ) -> [CardRegion: MemoryCardEditorDraft]

    private let presentWelcome:
        (Bool) -> WelcomeFlowState

    init(
        loadConfigurationState:
            @escaping () -> ConfigurationBootstrapState,
        loadDrafts:
            @escaping (
                MemoryCardPreviewCompositionContext,
                (CardRegion) -> MemoryCardEditorDraft
            ) -> [CardRegion: MemoryCardEditorDraft],
        presentWelcome:
            @escaping (Bool) -> WelcomeFlowState
                = {
                    hasSeenWelcome in
                    WelcomeFlowCoordinator
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
            ConfigurationBootstrapCoordinator,
        session: ConfigurationSession,
        engine: MemoryCardPreviewCompositionEngine
    ) {
        self.init(
            loadConfigurationState: {
                configurationBootstrapCoordinator
                    .loadState()
            },
            loadDrafts: {
                context,
                makeDefaultDraft in
                ConfigurationDraftBootstrapCoordinator(
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
            (CardRegion) -> MemoryCardEditorDraft
    ) -> ConfigurationBootstrapFlowPatch {
        let state =
            loadConfigurationState()
        let projection =
            ConfigurationBootstrapPresenter
            .projection(from: state)
        let resolvedSubjects =
            state.subjects.map {
                SubjectLibraryResolver
                    .sanitizedSubjectLibrary($0)
            }
        let resolvedSubject =
            SubjectLibraryResolver
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
            MemoryCardPreviewCompositionContext(
                subject: resolvedSubject,
                birthdayDate:
                    resolvedBirthdayDate
                    ?? fallbackBirthdayDate,
                locationDisplayConfiguration:
                    state
                    .locationDisplayConfiguration
            )

        return ConfigurationBootstrapFlowPatch(
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
                state.configurationLibraryRecoveryFailed
                ? [:]
                : loadDrafts(
                    draftContext,
                    makeDefaultDraft
                )
        )
    }

    private func sessionRestorePlan(
        state: ConfigurationBootstrapState,
        resolvedSubjects: [MemorySubject]?,
        resolvedSubject: MemorySubject?
    ) -> ConfigurationBootstrapSessionRestorePlan {
        if state.configurationLibraryRecoveryFailed {
            if let subjects = resolvedSubjects,
               !subjects.isEmpty {
                return .restoreLibrary(
                    subjects: subjects,
                    selectedSubjectID:
                        state.selectedSubjectID,
                    memoryPresets: [],
                    selectedMemoryPresetID: nil
                )
            }
            if let resolvedSubject {
                return .restoreLibrary(
                    subjects: [resolvedSubject],
                    selectedSubjectID:
                        resolvedSubject.id,
                    memoryPresets: [],
                    selectedMemoryPresetID: nil
                )
            }
            return .clearSession
        }

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

        if state.subjectLibraryReadFailure != nil {
            if let resolvedSubject {
                return .restoreLibrary(
                    subjects: [resolvedSubject],
                    selectedSubjectID:
                        resolvedSubject.id,
                    memoryPresets: [],
                    selectedMemoryPresetID: nil
                )
            }
            return .clearSession
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
