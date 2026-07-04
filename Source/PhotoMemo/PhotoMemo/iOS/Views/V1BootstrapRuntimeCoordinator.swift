#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct V1BootstrapViewProjection:
    Equatable {

    let shouldSaveSubjectLibrary: Bool
    let customLogoBadge: Badge?
    let logoMode: V1LogoMode
    let logoStatusMessage: String?
    let outputTarget: V1IOSOutputTarget
    let selectedExistingAlbumIdentifier: String
    let suggestedNewAlbumName: String?
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
            MemorySubject.ID?
        ) -> Void
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
            MemorySubject.ID?
        ) -> Void,
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
                selectedExistingAlbumIdentifier:
                    patch
                    .selectedExistingAlbumIdentifier,
                suggestedNewAlbumName:
                    patch.suggestedNewAlbumName,
                birthdayDate:
                    patch.birthdayDate,
                regionDrafts:
                    patch.regionDrafts
            )
        )

        switch patch.sessionRestorePlan {
        case .restoreLibrary(
            let subjects,
            let selectedSubjectID
        ):
            restoreSubjectLibrary(
                subjects,
                selectedSubjectID
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
