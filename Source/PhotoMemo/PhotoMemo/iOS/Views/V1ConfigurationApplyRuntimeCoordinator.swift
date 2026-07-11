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

    private let applyAggregateRequest:
        ((
            V1ConfigurationAggregateCandidate,
            [PhotoAlbumOption]
        ) async -> PhotoMemoResult<
            V1ConfigurationAggregateApplyReceipt
        >)?

    private let reloadAlbums: () async -> Void
    private let setOutputTarget:
        (V1IOSOutputTarget) -> Void
    private let setSelectedExistingAlbumIdentifier:
        (String) -> Void
    private let restoreSubject:
        (MemorySubject) -> Void
    private let saveCurrentMemoryPreset:
        () -> Void
    private let reconcileCurrentMemoryPreset:
        ((V1ConfigurationApplyRequest) ->
            ConfigurationPersistenceReconciliationOutcome)?
    private let reconcileSavedConfiguration:
        ((
            V1ConfigurationApplyRequest,
            UUID?,
            Int?
        ) -> ConfigurationPersistenceReconciliationOutcome)?
    private let reconcileConfigurationLibrary:
        ((
            V1ConfigurationAggregateCandidate,
            ConfigurationLibrarySaveReceipt
        ) -> ConfigurationPersistenceReconciliationOutcome)?
    private let applySavedConfigurationProjection:
        (MemoryConfigurationRecord) -> Void
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
        applyAggregateRequest: ((
            V1ConfigurationAggregateCandidate,
            [PhotoAlbumOption]
        ) async -> PhotoMemoResult<
            V1ConfigurationAggregateApplyReceipt
        >)? = nil,
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
        reconcileCurrentMemoryPreset: ((
            V1ConfigurationApplyRequest
        ) -> ConfigurationPersistenceReconciliationOutcome)? = nil,
        reconcileSavedConfiguration: ((
            V1ConfigurationApplyRequest,
            UUID?,
            Int?
        ) -> ConfigurationPersistenceReconciliationOutcome)? = nil,
        reconcileConfigurationLibrary: ((
            V1ConfigurationAggregateCandidate,
            ConfigurationLibrarySaveReceipt
        ) -> ConfigurationPersistenceReconciliationOutcome)? = nil,
        applySavedConfigurationProjection: @escaping (
            MemoryConfigurationRecord
        ) -> Void = { _ in },
        applySelectedMemoryPreset: @escaping () -> Void,
        updateStatus: @escaping (
            V1ConfigurationApplyViewStatus
        ) -> Void
    ) {
        self.applyRequest = applyRequest
        self.applyAggregateRequest =
            applyAggregateRequest
        self.reloadAlbums = reloadAlbums
        self.setOutputTarget = setOutputTarget
        self.setSelectedExistingAlbumIdentifier =
            setSelectedExistingAlbumIdentifier
        self.restoreSubject = restoreSubject
        self.saveCurrentMemoryPreset =
            saveCurrentMemoryPreset
        self.reconcileCurrentMemoryPreset =
            reconcileCurrentMemoryPreset
        self.reconcileSavedConfiguration =
            reconcileSavedConfiguration
        self.reconcileConfigurationLibrary =
            reconcileConfigurationLibrary
        self.applySavedConfigurationProjection =
            applySavedConfigurationProjection
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
        reconcileCurrentMemoryPreset: ((
            V1ConfigurationApplyRequest
        ) -> ConfigurationPersistenceReconciliationOutcome)? = nil,
        reconcileSavedConfiguration: ((
            V1ConfigurationApplyRequest,
            UUID?,
            Int?
        ) -> ConfigurationPersistenceReconciliationOutcome)? = nil,
        reconcileConfigurationLibrary: ((
            V1ConfigurationAggregateCandidate,
            ConfigurationLibrarySaveReceipt
        ) -> ConfigurationPersistenceReconciliationOutcome)? = nil,
        applySavedConfigurationProjection: @escaping (
            MemoryConfigurationRecord
        ) -> Void = { _ in },
        applySelectedMemoryPreset: @escaping () -> Void,
        updateStatus: @escaping (
            V1ConfigurationApplyViewStatus
        ) -> Void
    ) {
        self.init(
            applyRequest: { request in
                await coordinator.apply(request)
            },
            applyAggregateRequest: { candidate, availableAlbums in
                await coordinator.apply(
                    candidate: candidate,
                    availableAlbums: availableAlbums
                )
            },
            reloadAlbums: reloadAlbums,
            setOutputTarget:
                setOutputTarget,
            setSelectedExistingAlbumIdentifier:
                setSelectedExistingAlbumIdentifier,
            restoreSubject: restoreSubject,
            saveCurrentMemoryPreset:
                saveCurrentMemoryPreset,
            reconcileCurrentMemoryPreset:
                reconcileCurrentMemoryPreset,
            reconcileSavedConfiguration:
                reconcileSavedConfiguration,
            reconcileConfigurationLibrary:
                reconcileConfigurationLibrary,
            applySavedConfigurationProjection:
                applySavedConfigurationProjection,
            applySelectedMemoryPreset:
                applySelectedMemoryPreset,
            updateStatus: updateStatus
        )
    }

    @discardableResult
    func apply(
        configurationLibrary: ConfigurationLibraryRecord?,
        aggregateDraft: V1ConfigurationAggregateDraft?,
        legacyRequest: V1ConfigurationApplyRequest,
        outputTarget: V1IOSOutputTarget,
        availableAlbums: [PhotoAlbumOption]
    ) async -> Bool {
        guard let configurationLibrary,
              let aggregateDraft else {
            return await apply(
                legacyRequest,
                outputTarget: outputTarget
            )
        }

        updateStatus(.init(status: .saving))

        let candidate: V1ConfigurationAggregateCandidate
        do {
            candidate = try V1ConfigurationAggregateCandidateBuilder
                .build(
                    from: configurationLibrary,
                    draft: aggregateDraft
                )
        } catch {
            updateStatus(
                .init(
                    status: .failure(
                        message: "保存配置失败。"
                    )
                )
            )
            return false
        }

        guard let applyAggregateRequest else {
            updateStatus(
                .init(
                    status: .failure(
                        message: "保存配置失败。"
                    )
                )
            )
            return false
        }

        switch await applyAggregateRequest(
            candidate,
            availableAlbums
        ) {
        case .failure(let error):
            updateStatus(
                .init(
                    status: .failure(message: error.message)
                )
            )
            return false
        case .success(let receipt):
            if let pickerSelectionIdentifier =
                receipt.albumSelection
                .pickerSelectionIdentifier {
                await reloadAlbums()
                setOutputTarget(.existingAlbum)
                setSelectedExistingAlbumIdentifier(
                    pickerSelectionIdentifier
                )
            }
            let outcome = reconcileConfigurationLibrary?(
                receipt.candidate,
                receipt.saveReceipt
            ) ?? .newerEditsPreserved
            if outcome == .applied {
                applySavedConfigurationProjection(
                    receipt.candidate.configuration
                )
            }
            updateStatus(
                .init(
                    status: outcome == .applied
                    ? .saved
                    : .dirty
                )
            )
            return true
        }
    }

    @discardableResult
    func apply(
        _ request:
            V1ConfigurationApplyRequest,
        outputTarget: V1IOSOutputTarget,
        configurationSaveReceipt:
            ConfigurationLibrarySaveReceipt? = nil
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

        await apply(
            patch,
            persistenceRequest:
                wasSuccessful ? request : nil,
            configurationSaveReceipt:
                wasSuccessful
                ? configurationSaveReceipt
                : nil
        )
        return wasSuccessful
    }

    func apply(
        _ patch:
            V1ConfigurationApplyResultPatch
    ) async {
        await apply(
            patch,
            persistenceRequest: nil,
            configurationSaveReceipt: nil
        )
    }

    private func apply(
        _ patch:
            V1ConfigurationApplyResultPatch,
        persistenceRequest:
            V1ConfigurationApplyRequest?,
        configurationSaveReceipt:
            ConfigurationLibrarySaveReceipt?
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

        var resolvedStatus =
            patch.activeConfigurationStatus

        if patch.shouldApplySelectedMemoryPreset {
            if let persistenceRequest,
               reconcileSavedConfiguration != nil
                || reconcileCurrentMemoryPreset != nil {
                let reconciliationOutcome =
                    reconcileSavedConfiguration?(
                        persistenceRequest,
                        configurationSaveReceipt?
                            .configurationID,
                        configurationSaveReceipt?
                            .revision
                    )
                    ?? reconcileCurrentMemoryPreset?(
                        persistenceRequest
                    )
                    ?? .newerEditsPreserved
                if reconciliationOutcome
                    == .newerEditsPreserved {
                    resolvedStatus = .dirty
                }
            } else {
                saveCurrentMemoryPreset()
                applySelectedMemoryPreset()
            }
        }

        updateStatus(
            V1ConfigurationApplyViewStatus(
                status: resolvedStatus
            )
        )
    }
}
#endif
