#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct V1BootstrapViewProjection:
    Equatable {

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
    let birthdayDate: Date?
    let regionDrafts: [CardRegion: V1EditorDraft]
}

@MainActor
struct V1BootstrapRuntimeCoordinator {

    private let setApplyingBootstrapState:
        (Bool) -> Void
    private let updateProjection:
        (V1BootstrapViewProjection) -> Void
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
        (V1ConfigurationDraftProjection) -> Void
    private let restoreSelectedSubject:
        (MemorySubject) -> Void
    private let applyWelcomeState:
        (V1WelcomeFlowState) -> Void
    private let refreshDynamicPreview:
        () -> Void

    init(
        setApplyingBootstrapState: @escaping (
            Bool
        ) -> Void,
        updateProjection: @escaping (
            V1BootstrapViewProjection
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
            V1ConfigurationDraftProjection
        ) -> Void = { _ in },
        restoreSelectedSubject: @escaping (
            MemorySubject
        ) -> Void,
        applyWelcomeState: @escaping (
            V1WelcomeFlowState
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
        self.applyWelcomeState =
            applyWelcomeState
        self.refreshDynamicPreview =
            refreshDynamicPreview
    }

    func apply(
        _ patch:
            V1BootstrapFlowPatch
    ) {
        setApplyingBootstrapState(true)
        updateProjection(
            V1BootstrapViewProjection(
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
                    V1ConfigurationDraftProjection(
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
