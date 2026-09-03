#if !MEMOMARK_SHARE_EXTENSION
import Foundation

struct ConfigurationBootstrapViewProjection:
    Equatable {

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
    let birthdayDate: Date?
    let regionDrafts: [CardRegion: MemoryCardEditorDraft]
}

@MainActor
struct ConfigurationBootstrapRuntimeCoordinator {

    private let setApplyingBootstrapState:
        (Bool) -> Void
    private let updateProjection:
        (ConfigurationBootstrapViewProjection) -> Void
    private let restoreSubjectLibrary:
        (
            [MemorySubject],
            MemorySubject.ID?,
            [MemoryPreset],
            MemoryPreset.ID?
        ) -> Void
    private let restoreConfigurationLibrary:
        (ConfigurationLibraryRecord) -> Void
    private let applyConfigurationDraftProjection:
        (ConfigurationDraftProjection) -> Void
    private let restoreSelectedSubject:
        (MemorySubject) -> Void
    private let clearSession:
        () -> Void
    private let applyWelcomeState:
        (WelcomeFlowState) -> Void
    private let refreshDynamicPreview:
        () -> Void

    init(
        setApplyingBootstrapState: @escaping (
            Bool
        ) -> Void,
        updateProjection: @escaping (
            ConfigurationBootstrapViewProjection
        ) -> Void,
        restoreSubjectLibrary: @escaping (
            [MemorySubject],
            MemorySubject.ID?,
            [MemoryPreset],
            MemoryPreset.ID?
        ) -> Void,
        restoreConfigurationLibrary: @escaping (
            ConfigurationLibraryRecord
        ) -> Void = { _ in },
        applyConfigurationDraftProjection: @escaping (
            ConfigurationDraftProjection
        ) -> Void = { _ in },
        restoreSelectedSubject: @escaping (
            MemorySubject
        ) -> Void,
        clearSession: @escaping () -> Void = {},
        applyWelcomeState: @escaping (
            WelcomeFlowState
        ) -> Void,
        refreshDynamicPreview: @escaping () -> Void
    ) {
        self.setApplyingBootstrapState =
            setApplyingBootstrapState
        self.updateProjection = updateProjection
        self.restoreSubjectLibrary =
            restoreSubjectLibrary
        self.restoreConfigurationLibrary =
            restoreConfigurationLibrary
        self.applyConfigurationDraftProjection =
            applyConfigurationDraftProjection
        self.restoreSelectedSubject =
            restoreSelectedSubject
        self.clearSession = clearSession
        self.applyWelcomeState =
            applyWelcomeState
        self.refreshDynamicPreview =
            refreshDynamicPreview
    }

    func apply(
        _ patch:
            ConfigurationBootstrapFlowPatch
    ) {
        setApplyingBootstrapState(true)
        updateProjection(
            ConfigurationBootstrapViewProjection(
                shouldSaveSubjectLibrary:
                    patch.shouldSaveSubjectLibrary,
                customLogoBadge:
                    patch.customLogoBadge,
                logoMode: patch.logoMode,
                logoStatusMessage:
                    patch.logoStatusMessage,
                outputTarget:
                    patch.outputTarget,
                mediaOutputMode:
                    patch.mediaOutputMode,
                selectedExistingAlbumIdentifier:
                    patch
                    .selectedExistingAlbumIdentifier,
                suggestedNewAlbumName:
                    patch.suggestedNewAlbumName,
                locationDisplayConfiguration:
                    patch.locationDisplayConfiguration,
                birthdayDate:
                    patch.birthdayDate,
                regionDrafts:
                    patch.regionDrafts
            )
        )

        switch patch.sessionRestorePlan {
        case .clearSession:
            clearSession()
        case .restoreConfigurationLibrary(let aggregate):
            restoreConfigurationLibrary(aggregate)
            if let activeSubjectID = aggregate.activeSubjectID,
               let activeConfigurationID =
                aggregate.activeConfigurationID,
               let activeConfiguration = aggregate.subjects
                .first(where: {
                    $0.subject.id == activeSubjectID
                })?
                .configurations
                .first(where: {
                    $0.id == activeConfigurationID
                }) {
                applyConfigurationDraftProjection(
                    ConfigurationDraftProjection(
                        configuration: activeConfiguration
                    )
                )
            }
        case .restoreLibrary(
            let subjects,
            let selectedSubjectID,
            let memoryPresets,
            let selectedMemoryPresetID
        ):
            restoreSubjectLibrary(
                subjects,
                selectedSubjectID,
                memoryPresets,
                selectedMemoryPresetID
            )
        case .restoreSelectedSubject(let subject):
            restoreSelectedSubject(subject)
        case .none:
            break
        }

        applyWelcomeState(
            patch.welcomeState
        )
        setApplyingBootstrapState(false)
        refreshDynamicPreview()
    }
}
#endif
