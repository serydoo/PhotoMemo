#if !MEMOMARK_SHARE_EXTENSION
import Foundation

struct ConfigurationSaveViewStatus:
    Equatable {

    let status: ConfigurationPersistenceStatus
}

@MainActor
struct ConfigurationSaveRuntimeCoordinator {

    private let applyLegacyRequest:
        (SaveConfigurationCommand) async -> MemoMarkResult<
            SaveConfigurationReceipt
        >

    private let applyAggregateRequest:
        ((
            ConfigurationAggregateCandidate,
            [PhotoAlbumOption]
        ) async -> MemoMarkResult<
            SaveConfigurationAggregateReceipt
        >)?

    private let reloadAlbums: () async -> Void
    private let setOutputTarget:
        (ConfigurationOutputTarget) -> Void
    private let setSelectedExistingAlbumIdentifier:
        (String) -> Void
    private let restoreSubject:
        (MemorySubject) -> Void
    private let saveCurrentMemoryPreset:
        () -> Void
    private let reconcileCurrentMemoryPreset:
        ((SaveConfigurationCommand) ->
            ConfigurationPersistenceReconciliationOutcome)?
    private let reconcileSavedConfiguration:
        ((
            SaveConfigurationCommand,
            UUID?,
            Int?
        ) -> ConfigurationPersistenceReconciliationOutcome)?
    private let reconcileConfigurationLibrary:
        ((
            ConfigurationAggregateCandidate,
            ConfigurationLibrarySaveReceipt
        ) -> ConfigurationPersistenceReconciliationOutcome)?
    private let applySavedConfigurationProjection:
        (MemoryConfigurationRecord) -> Void
    private let applySelectedMemoryPreset:
        () -> Void
    private let updateStatus:
        (ConfigurationSaveViewStatus) -> Void
    private let recordDiagnostic:
        (ProductionDiagnosticEvent) async -> Void

    init(
        applyLegacyRequest: @escaping (
            SaveConfigurationCommand
        ) async -> MemoMarkResult<
            SaveConfigurationReceipt
        >,
        applyAggregateRequest: ((
            ConfigurationAggregateCandidate,
            [PhotoAlbumOption]
        ) async -> MemoMarkResult<
            SaveConfigurationAggregateReceipt
        >)? = nil,
        reloadAlbums: @escaping () async -> Void,
        setOutputTarget: @escaping (
            ConfigurationOutputTarget
        ) -> Void = { _ in },
        setSelectedExistingAlbumIdentifier: @escaping (
            String
        ) -> Void,
        restoreSubject: @escaping (
            MemorySubject
        ) -> Void,
        saveCurrentMemoryPreset: @escaping () -> Void = {},
        reconcileCurrentMemoryPreset: ((
            SaveConfigurationCommand
        ) -> ConfigurationPersistenceReconciliationOutcome)? = nil,
        reconcileSavedConfiguration: ((
            SaveConfigurationCommand,
            UUID?,
            Int?
        ) -> ConfigurationPersistenceReconciliationOutcome)? = nil,
        reconcileConfigurationLibrary: ((
            ConfigurationAggregateCandidate,
            ConfigurationLibrarySaveReceipt
        ) -> ConfigurationPersistenceReconciliationOutcome)? = nil,
        applySavedConfigurationProjection: @escaping (
            MemoryConfigurationRecord
        ) -> Void = { _ in },
        applySelectedMemoryPreset: @escaping () -> Void,
        updateStatus: @escaping (
            ConfigurationSaveViewStatus
        ) -> Void,
        recordDiagnostic: @escaping (
            ProductionDiagnosticEvent
        ) async -> Void = { _ in }
    ) {
        self.applyLegacyRequest = applyLegacyRequest
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
        self.recordDiagnostic = recordDiagnostic
    }

    init(
        coordinator: SaveConfigurationTransaction,
        reloadAlbums: @escaping () async -> Void,
        setOutputTarget: @escaping (
            ConfigurationOutputTarget
        ) -> Void = { _ in },
        setSelectedExistingAlbumIdentifier: @escaping (
            String
        ) -> Void,
        restoreSubject: @escaping (
            MemorySubject
        ) -> Void,
        saveCurrentMemoryPreset: @escaping () -> Void = {},
        reconcileCurrentMemoryPreset: ((
            SaveConfigurationCommand
        ) -> ConfigurationPersistenceReconciliationOutcome)? = nil,
        reconcileSavedConfiguration: ((
            SaveConfigurationCommand,
            UUID?,
            Int?
        ) -> ConfigurationPersistenceReconciliationOutcome)? = nil,
        reconcileConfigurationLibrary: ((
            ConfigurationAggregateCandidate,
            ConfigurationLibrarySaveReceipt
        ) -> ConfigurationPersistenceReconciliationOutcome)? = nil,
        applySavedConfigurationProjection: @escaping (
            MemoryConfigurationRecord
        ) -> Void = { _ in },
        applySelectedMemoryPreset: @escaping () -> Void,
        updateStatus: @escaping (
            ConfigurationSaveViewStatus
        ) -> Void,
        recordDiagnostic: @escaping (
            ProductionDiagnosticEvent
        ) async -> Void = { _ in }
    ) {
        self.init(
            applyLegacyRequest: { request in
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
            updateStatus: updateStatus,
            recordDiagnostic: recordDiagnostic
        )
    }

    @discardableResult
    func applyAggregate(
        configurationLibrary: ConfigurationLibraryRecord,
        aggregateDraft: ConfigurationAggregateDraft,
        availableAlbums: [PhotoAlbumOption]
    ) async -> Bool {
        updateStatus(.init(status: .saving))

        let runtimeOperationID = UUID()
        let diagnosticContext =
            ProductionDiagnosticContext
            .configurationLibrary(
                configurationLibrary
            )

        let candidate: ConfigurationAggregateCandidate
        do {
            candidate = try ConfigurationAggregateCandidateBuilder
                .build(
                    from: configurationLibrary,
                    draft: aggregateDraft
                )
        } catch {
            let failure = ProductionDiagnosticFailureClassifier
                .candidateConstruction(
                    error,
                    operationID: runtimeOperationID,
                    language: .interfaceStored
                )
            await recordDiagnostic(
                ProductionDiagnosticEvent(
                    operationID: runtimeOperationID,
                    category: .configuration,
                    stage: "configuration.candidate",
                    outcome: .failed,
                    errorCode: failure.code,
                    systemError: failure.systemError,
                    context: diagnosticContext
                )
            )
            updateStatus(
                .init(
                    status: .failure(
                        message: failure.userMessage
                    )
                )
            )
            return false
        }

        guard let applyAggregateRequest else {
            let unavailableError = MemoMarkError(
                code: .configurationUnavailable,
                message: "Configuration service unavailable."
            )
            let failure = ProductionDiagnosticFailureClassifier
                .configurationSave(
                    unavailableError,
                    operationID: runtimeOperationID,
                    language: .interfaceStored
                )
            await recordDiagnostic(
                ProductionDiagnosticEvent(
                    operationID: runtimeOperationID,
                    category: .configuration,
                    stage: "configuration.service",
                    outcome: .failed,
                    errorCode: failure.code,
                    systemError: failure.systemError,
                    context: diagnosticContext
                )
            )
            updateStatus(
                .init(
                    status: .failure(
                        message: failure.userMessage
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
            let displayedError: MemoMarkError
            if error.supportID != nil {
                displayedError = error
            } else {
                let failure = ProductionDiagnosticFailureClassifier
                    .configurationSave(
                        error,
                        operationID: runtimeOperationID,
                        language: .interfaceStored
                    )
                await recordDiagnostic(
                    ProductionDiagnosticEvent(
                        operationID: runtimeOperationID,
                        category: .configuration,
                        stage: "configuration.apply",
                        outcome: .failed,
                        errorCode: failure.code,
                        systemError: failure.systemError,
                        context: diagnosticContext
                    )
                )
                displayedError = MemoMarkError(
                    code: error.code,
                    message: failure.userMessage,
                    diagnosticCode: failure.code.rawValue,
                    supportID: failure.supportID
                )
            }
            updateStatus(
                .init(
                    status: .failure(
                        message: displayedError.message
                    )
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
            let status: ConfigurationPersistenceStatus
            if let operationID = receipt.saveReceipt
                .diagnosticOperationID,
               receipt.saveReceipt
                .compatibilityProjectionFailure != nil {
                let failure = ProductionDiagnosticFailureClassifier
                    .compatibilityProjection(
                        operationID: operationID,
                        language: .interfaceStored
                    )
                status = .savedWithWarning(
                    message: failure.userMessage
                )
            } else {
                status = outcome == .applied
                    ? .saved
                    : .dirty
            }
            updateStatus(.init(status: status))
            return true
        }
    }

    @discardableResult
    func applyLegacyCompatibility(
        _ request: SaveConfigurationCommand,
        outputTarget: ConfigurationOutputTarget,
        configurationSaveReceipt:
            ConfigurationLibrarySaveReceipt? = nil
    ) async -> Bool {
        await apply(
            request,
            outputTarget: outputTarget,
            configurationSaveReceipt: configurationSaveReceipt
        )
    }

    /// Historical projection entry point retained for compatibility callers.
    /// The active Configuration Center uses `applyLegacyCompatibility(_:)`
    /// so its migration boundary is visible at the call site.
    func apply(
        _ request:
            SaveConfigurationCommand,
        outputTarget: ConfigurationOutputTarget,
        configurationSaveReceipt:
            ConfigurationLibrarySaveReceipt? = nil
    ) async -> Bool {
        updateStatus(
            ConfigurationSaveViewStatus(
                status: .saving
            )
        )

        let patch: ConfigurationSaveResultPatch
        let wasSuccessful: Bool

        switch await applyLegacyRequest(request) {
        case .failure(let error):
            patch =
                ConfigurationSaveResultPresenter
                .failurePatch(error: error)
            wasSuccessful = false
        case .success(let receipt):
            patch =
                ConfigurationSaveResultPresenter
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
            ConfigurationSaveResultPatch
    ) async {
        await apply(
            patch,
            persistenceRequest: nil,
            configurationSaveReceipt: nil
        )
    }

    private func apply(
        _ patch:
            ConfigurationSaveResultPatch,
        persistenceRequest:
            SaveConfigurationCommand?,
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
                            .configurationRevision
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
            ConfigurationSaveViewStatus(
                status: resolvedStatus
            )
        )
    }
}
#endif
