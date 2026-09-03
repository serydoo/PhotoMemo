#if !MEMOMARK_SHARE_EXTENSION
import Foundation

@MainActor
final class ConfigurationCoordinator {

    private let settingsRepository:
        SettingsRepository

    private let configurationRepository:
        ConfigurationRepository

    private let productionDiagnostics:
        ProductionDiagnosticsRepository

    private let applyLiveDefaultConfiguration:
        (BatchConfigurationSnapshot) -> Void

    private let onConfigurationLibrarySaved:
        (ConfigurationLibrarySaveReceipt) -> Void

    private let applyConfigurationLibrarySnapshot:
        (
            BatchConfigurationSnapshot,
            ConfigurationLibrarySaveReceipt
        ) -> Void

    init(
        settingsRepository:
            SettingsRepository,
        configurationRepository:
            ConfigurationRepository,
        productionDiagnostics:
            ProductionDiagnosticsRepository? = nil,
        applyLiveDefaultConfiguration:
            @escaping (BatchConfigurationSnapshot) -> Void = { _ in },
        applyConfigurationLibrarySnapshot:
            ((
                BatchConfigurationSnapshot,
                ConfigurationLibrarySaveReceipt
            ) -> Void)? = nil,
        onConfigurationLibrarySaved:
            @escaping (ConfigurationLibrarySaveReceipt) -> Void = { _ in }
    ) {
        self.settingsRepository =
            settingsRepository
        self.configurationRepository =
            configurationRepository
        self.productionDiagnostics =
            productionDiagnostics
            ?? ProductionDiagnosticsRepository()
        self.applyLiveDefaultConfiguration =
            applyLiveDefaultConfiguration
        self.applyConfigurationLibrarySnapshot =
            applyConfigurationLibrarySnapshot
            ?? { snapshot, _ in
                applyLiveDefaultConfiguration(snapshot)
            }
        self.onConfigurationLibrarySaved =
            onConfigurationLibrarySaved
    }

    func loadDefaultBatchConfigurationSnapshot()
    -> MemoMarkResult<
        BatchConfigurationSnapshot
    > {

        .success(
            configurationRepository
            .loadDefaultBatchConfigurationSnapshot()
        )
    }

    func loadSharedBatchConfigurationSnapshot()
    -> MemoMarkResult<
        BatchConfigurationSnapshot
    > {

        .success(
            configurationRepository
            .loadSharedBatchConfigurationSnapshot()
        )
    }

    func resolvedAlbumTitle(
        for identifier: String
    ) -> MemoMarkResult<String?> {

        .success(
            configurationRepository
            .resolvedAlbumTitle(
                for: identifier
            )
        )
    }

    func updateActiveConfigurationSlotID(
        _ slotID:
            WorkspaceConfigurationSlotID
    ) -> MemoMarkResult<Void> {

        settingsRepository
            .updateActiveConfigurationSlotID(
                slotID
            )
        return .success(())
    }

    func saveSelectedMemorySubject(
        _ subject: MemorySubject?
    ) -> MemoMarkResult<Void> {

        settingsRepository
            .saveSelectedMemorySubject(
                subject
            )
        return .success(())
    }

    func saveLocationDisplayConfiguration(
        _ configuration:
            ExpressionModuleConfiguration
    ) -> MemoMarkResult<Void> {

        settingsRepository
            .saveLocationDisplayConfiguration(
                configuration
            )
        return .success(())
    }

    func saveTimeDisplayConfiguration(
        _ configuration: ExpressionModuleConfiguration
    ) -> MemoMarkResult<Void> {
        settingsRepository.saveTimeDisplayConfiguration(configuration)
        return .success(())
    }

    func loadTimeDisplayConfiguration()
    -> ExpressionModuleConfiguration? {
        settingsRepository.loadTimeDisplayConfiguration()
    }

    func saveSubjectLibrary(
        subjects: [MemorySubject],
        selectedSubjectID: MemorySubject.ID?,
        memoryPresets: [MemoryPreset] = [],
        selectedMemoryPresetID: MemoryPreset.ID? = nil
    ) -> MemoMarkResult<Void> {

        settingsRepository
            .saveSubjectLibrary(
                subjects: subjects,
                selectedSubjectID: selectedSubjectID,
                memoryPresets: memoryPresets,
                selectedMemoryPresetID:
                    selectedMemoryPresetID
            )
        return .success(())
    }

    @available(*, deprecated, message: "Use saveSubjectLibrary(...) instead.")
    func saveV1SubjectLibrary(
        subjects: [MemorySubject],
        selectedSubjectID: MemorySubject.ID?,
        memoryPresets: [MemoryPreset] = [],
        selectedMemoryPresetID: MemoryPreset.ID? = nil
    ) -> MemoMarkResult<Void> {
        saveSubjectLibrary(
            subjects: subjects,
            selectedSubjectID: selectedSubjectID,
            memoryPresets: memoryPresets,
            selectedMemoryPresetID: selectedMemoryPresetID
        )
    }

    func saveConfiguration(
        _ request:
            ConfigurationSaveRequest
    ) -> MemoMarkResult<
        ConfigurationSaveReceipt
    > {

        let anchor =
            configurationRepository
            .syncAnchors(
                from: request.subject,
                fallbackTitle:
                    request.timeAnchor.title,
                fallbackDate:
                    request.timeAnchor.date
            )

        settingsRepository
            .saveSelectedTemplate(
                request.template
                .normalizedForEditing
            )
        settingsRepository
            .saveSelectedBadge(
                request.badge
            )
        if let locationDisplayConfiguration =
            request.locationDisplayConfiguration {
            settingsRepository
                .saveLocationDisplayConfiguration(
                    locationDisplayConfiguration
                )
        }
        settingsRepository
            .saveMediaOutputMode(
                request.mediaOutputMode
            )
        settingsRepository
            .saveSelectedMemorySubject(
                request.subject
            )
        if request.shouldSaveSubjectLibrary,
           !request.subjects.isEmpty || request.subject != nil {
            settingsRepository
                .saveSubjectLibrary(
                    subjects:
                        subjectsForSaving(
                            selectedSubject:
                                request.subject,
                            subjects:
                                request.subjects
                        ),
                    selectedSubjectID:
                        request.selectedSubjectID
                        ?? request.subject?.id,
                    memoryPresets:
                        request.memoryPresets,
                    selectedMemoryPresetID:
                        request.selectedMemoryPresetID
                )
        }
        settingsRepository
            .savePhotoDescriptionSettings(
                shouldWrite:
                    request
                    .shouldWritePhotoDescription,
                override:
                    request
                    .photoDescriptionOverride
            )
        settingsRepository
            .saveEditorState(
                selectedAnchorID:
                    anchor.id,
                selectedAlbumIdentifier:
                    request
                    .albumSelection
                    .identifier,
                selectedAlbumTitle:
                    request
                    .albumSelection
                    .title
            )
        var snapshot = configurationRepository
            .loadDefaultBatchConfigurationSnapshot()
        // The legacy MemoryPreset has no presentation route. Carry the
        // current route through this compatibility save path so preview,
        // export, and batch processing stay aligned for the current session.
        snapshot.presentationRouteRawValue = request
            .presentationRoute
            .rawValue
        applyLiveDefaultConfiguration(snapshot)

        return .success(
            ConfigurationSaveReceipt(
                anchor: anchor
            )
        )
    }

    /// Compatibility entry point for callers that still submit the historical
    /// configuration transport. New application code should use
    /// `saveConfiguration(_:)` so the active path carries stable vocabulary.
    @available(*, deprecated, message: "Use saveConfiguration(_:) instead.")
    func saveV1Configuration(
        _ request: ConfigurationSaveRequest
    ) -> MemoMarkResult<ConfigurationSaveReceipt> {
        saveConfiguration(request)
    }

    func loadConfigurationBootstrapState()
    -> MemoMarkResult<
        ConfigurationBootstrapState
    > {

        .success(
            settingsRepository
            .loadConfigurationBootstrapState()
        )
    }

    func saveConfigurationLibrary(
        _ aggregate: ConfigurationLibraryRecord
    ) async throws -> ConfigurationLibrarySaveReceipt {
        let operationID = UUID()
        let startedAt = Date()
        let context = ProductionDiagnosticContext
            .configurationLibrary(aggregate)
        await productionDiagnostics.record(
            ProductionDiagnosticEvent(
                operationID: operationID,
                category: .configuration,
                stage: "configuration.save",
                outcome: .started,
                context: context
            )
        )

        do {
            let receipt = try await settingsRepository
                .saveConfigurationLibrary(
                    aggregate,
                    afterSuccessfulProjection: {
                        [applyConfigurationLibrarySnapshot]
                        snapshot,
                        provisionalReceipt in
                        applyConfigurationLibrarySnapshot(
                            snapshot,
                            provisionalReceipt
                                .attachingDiagnosticOperationID(
                                    operationID
                                )
                        )
                    }
                )
                .attachingDiagnosticOperationID(
                    operationID
                )
            let duration = Self.durationMilliseconds(
                since: startedAt
            )
            if receipt.compatibilityProjectionFailure != nil {
                await productionDiagnostics.record(
                    ProductionDiagnosticEvent(
                        operationID: operationID,
                        category: .configuration,
                        stage:
                            "configuration.compatibilityProjection",
                        outcome: .degraded,
                        errorCode:
                            .configurationCompatibilityProjectionFailed,
                        durationMilliseconds: duration,
                        context: context
                    )
                )
            } else {
                await productionDiagnostics.record(
                    ProductionDiagnosticEvent(
                        operationID: operationID,
                        category: .configuration,
                        stage: "configuration.save",
                        outcome: .succeeded,
                        durationMilliseconds: duration,
                        context: context
                    )
                )
            }
            onConfigurationLibrarySaved(receipt)
            return receipt
        } catch {
            let failure = ProductionDiagnosticFailureClassifier
                .configurationSave(
                    error,
                    operationID: operationID,
                    language: .interfaceStored
                )
            await productionDiagnostics.record(
                ProductionDiagnosticEvent(
                    operationID: operationID,
                    category: .configuration,
                    stage: "configuration.save",
                    outcome: .failed,
                    errorCode: failure.code,
                    systemError: failure.systemError,
                    durationMilliseconds:
                        Self.durationMilliseconds(
                            since: startedAt
                        ),
                    context: context
                )
            )
            throw MemoMarkError(
                code: Self.photoMemoErrorCode(
                    for: failure.code
                ),
                message: failure.userMessage,
                diagnosticCode: failure.code.rawValue,
                supportID: failure.supportID
            )
        }
    }

    func loadConfigurationLibrary()
    async throws -> ConfigurationLibraryLoadReceipt {
        try await settingsRepository
            .loadConfigurationLibrary()
    }
}

private extension ConfigurationCoordinator {

    static func durationMilliseconds(
        since date: Date
    ) -> Int {
        Int(
            max(Date().timeIntervalSince(date), 0)
            * 1_000
        )
    }

    static func photoMemoErrorCode(
        for diagnosticCode:
            ProductionDiagnosticErrorCode
    ) -> MemoMarkErrorCode {
        switch diagnosticCode {
        case .configurationReadFailed,
             .configurationCorrupted:
            return .persistenceReadFailed
        case .configurationUnavailable:
            return .configurationUnavailable
        case .configurationCandidateInvalid,
             .configurationSelectionMissing,
             .configurationValidationFailed:
            return .invalidInput
        default:
            return .persistenceWriteFailed
        }
    }
}

private extension ConfigurationCoordinator {

    func subjectsForSaving(
        selectedSubject: MemorySubject?,
        subjects: [MemorySubject]
    ) -> [MemorySubject] {
        guard let selectedSubject else {
            return subjects
        }

        var resolvedSubjects = subjects
        if let index =
            resolvedSubjects.firstIndex(
                where: {
                    $0.id == selectedSubject.id
                }
            ) {
            resolvedSubjects[index] = selectedSubject
        } else {
            resolvedSubjects.append(selectedSubject)
        }

        return resolvedSubjects
    }
}
#endif
