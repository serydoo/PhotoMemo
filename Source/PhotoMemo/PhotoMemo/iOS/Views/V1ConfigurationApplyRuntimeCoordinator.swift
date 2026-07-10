#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct V1ConfigurationApplyViewStatus:
    Equatable {

    let status: V1ConfigurationStatus
}

@MainActor
struct V1ConfigurationApplyRuntimeCoordinator {

    private let applyRequest:
        (V1ConfigurationApplyRequest) async -> PhotoMemoResult<
            V1ConfigurationApplyReceipt
        >

    private let reloadAlbums: () async -> Void
    private let setOutputTarget:
        (V1IOSOutputTarget) -> Void
    private let setSelectedExistingAlbumIdentifier:
        (String) -> Void
    private let restoreSubject:
        (MemorySubject) -> Void
    private let saveCurrentMemoryPreset:
        () -> Void
    private let applySelectedMemoryPreset:
        () -> Void
    private let updateStatus:
        (V1ConfigurationApplyViewStatus) -> Void

    init(
        applyRequest: @escaping (
            V1ConfigurationApplyRequest
        ) async -> PhotoMemoResult<
            V1ConfigurationApplyReceipt
        >,
        reloadAlbums: @escaping () async -> Void,
        setOutputTarget: @escaping (
            V1IOSOutputTarget
        ) -> Void = { _ in },
        setSelectedExistingAlbumIdentifier: @escaping (
            String
        ) -> Void,
        restoreSubject: @escaping (
            MemorySubject
        ) -> Void,
        saveCurrentMemoryPreset: @escaping () -> Void = {},
        applySelectedMemoryPreset: @escaping () -> Void,
        updateStatus: @escaping (
            V1ConfigurationApplyViewStatus
        ) -> Void
    ) {
        self.applyRequest = applyRequest
        self.reloadAlbums = reloadAlbums
        self.setOutputTarget = setOutputTarget
        self.setSelectedExistingAlbumIdentifier =
            setSelectedExistingAlbumIdentifier
        self.restoreSubject = restoreSubject
        self.saveCurrentMemoryPreset =
            saveCurrentMemoryPreset
        self.applySelectedMemoryPreset =
            applySelectedMemoryPreset
        self.updateStatus = updateStatus
    }

    init(
        coordinator: V1ConfigurationApplyCoordinator,
        reloadAlbums: @escaping () async -> Void,
        setOutputTarget: @escaping (
            V1IOSOutputTarget
        ) -> Void = { _ in },
        setSelectedExistingAlbumIdentifier: @escaping (
            String
        ) -> Void,
        restoreSubject: @escaping (
            MemorySubject
        ) -> Void,
        saveCurrentMemoryPreset: @escaping () -> Void = {},
        applySelectedMemoryPreset: @escaping () -> Void,
        updateStatus: @escaping (
            V1ConfigurationApplyViewStatus
        ) -> Void
    ) {
        self.init(
            applyRequest: { request in
                await coordinator.apply(request)
            },
            reloadAlbums: reloadAlbums,
            setOutputTarget:
                setOutputTarget,
            setSelectedExistingAlbumIdentifier:
                setSelectedExistingAlbumIdentifier,
            restoreSubject: restoreSubject,
            saveCurrentMemoryPreset:
                saveCurrentMemoryPreset,
            applySelectedMemoryPreset:
                applySelectedMemoryPreset,
            updateStatus: updateStatus
        )
    }

    @discardableResult
    func apply(
        _ request:
            V1ConfigurationApplyRequest,
        outputTarget: V1IOSOutputTarget
    ) async -> Bool {
        updateStatus(
            V1ConfigurationApplyViewStatus(
                status: .saving
            )
        )

        let patch: V1ConfigurationApplyResultPatch
        let wasSuccessful: Bool

        switch await applyRequest(request) {
        case .failure(let error):
            patch =
                V1ConfigurationApplyResultPresenter
                .failurePatch(error: error)
            wasSuccessful = false
        case .success(let receipt):
            patch =
                V1ConfigurationApplyResultPresenter
                .successPatch(
                    receipt: receipt,
                    outputTarget: outputTarget,
                    subjectForSaving: request.subject
                )
            wasSuccessful = true
        }

        await apply(patch)
        return wasSuccessful
    }

    func apply(
        _ patch:
            V1ConfigurationApplyResultPatch
    ) async {
        if patch.shouldReloadAlbums {
            await reloadAlbums()
        }

        if let outputTarget = patch.outputTarget {
            setOutputTarget(outputTarget)
        }

        if let selectedExistingAlbumIdentifier =
            patch.selectedExistingAlbumIdentifier {
            setSelectedExistingAlbumIdentifier(
                selectedExistingAlbumIdentifier
            )
        }

        if let subjectToRestore =
            patch.subjectToRestore {
            restoreSubject(subjectToRestore)
        }

        if patch.shouldApplySelectedMemoryPreset {
            saveCurrentMemoryPreset()
            applySelectedMemoryPreset()
        }

        updateStatus(
            V1ConfigurationApplyViewStatus(
                status:
                    patch.activeConfigurationStatus
            )
        )
    }
}
#endif
