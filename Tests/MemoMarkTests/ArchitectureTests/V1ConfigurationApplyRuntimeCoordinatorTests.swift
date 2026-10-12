#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing
@testable import MemoMark

@Suite("V1 configuration apply runtime coordinator")
struct ConfigurationSaveRuntimeCoordinatorTests {

    @Test("aggregate apply saves the complete candidate and reconciles the durable receipt")
    @MainActor
    func aggregateApplySavesCandidateAndReconcilesReceipt() async throws {
        let aggregate = try Self.makeAggregate()
        let draft = Self.makeAggregateDraft(title: "After")
        let expectedReceipt = ConfigurationLibrarySaveReceipt(
            revision: 12,
            subjectID: try #require(aggregate.activeSubjectID),
            configurationID: try #require(aggregate.activeConfigurationID),
            configurationRevision: 4,
            compatibilityProjectionFailure: nil
        )
        var savedAggregate: ConfigurationLibraryRecord?
        var reconciledCandidate: ConfigurationAggregateCandidate?
        var reconciledReceipt: ConfigurationLibrarySaveReceipt?
        var projectedConfiguration: MemoryConfigurationRecord?
        var legacyApplyCount = 0
        var statuses: [ConfigurationSaveViewStatus] = []
        let applyCoordinator = SaveConfigurationTransaction(
            resolveAlbumSelection: { _ in
                .success(
                    .init(
                        identifier: "album-after",
                        title: "After Album",
                        pickerSelectionIdentifier: nil
                    )
                )
            },
            saveConfiguration: { _ in
                Issue.record(
                    "Aggregate apply must not use legacy save."
                )
                return .failure(
                    MemoMarkError(
                        code: .invalidState,
                        message: "Unexpected legacy save."
                    )
                )
            },
            saveConfigurationLibrary: { candidate in
                savedAggregate = candidate
                return expectedReceipt
            }
        )

        let coordinator = ConfigurationSaveRuntimeCoordinator(
            applyLegacyRequest: { _ in
                legacyApplyCount += 1
                return .failure(
                    MemoMarkError(
                        code: .invalidState,
                        message: "Aggregate apply must not use legacy save."
                    )
                )
            },
            applyAggregateRequest: { candidate, albums in
                await applyCoordinator.apply(
                    candidate: candidate,
                    availableAlbums: albums
                )
            },
            reloadAlbums: {},
            setSelectedExistingAlbumIdentifier: { _ in },
            restoreSubject: { _ in },
            reconcileConfigurationLibrary: { candidate, receipt in
                reconciledCandidate = candidate
                reconciledReceipt = receipt
                return .applied
            },
            applySavedConfigurationProjection: {
                projectedConfiguration = $0
            },
            applySelectedMemoryPreset: {},
            updateStatus: { statuses.append($0) }
        )

        let wasSuccessful = await coordinator.applyAggregate(
            configurationLibrary: aggregate,
            aggregateDraft: draft,
            availableAlbums: []
        )

        #expect(wasSuccessful)
        #expect(legacyApplyCount == 0)
        #expect(savedAggregate?.subjects[0].configurations[0].title == "After")
        #expect(savedAggregate?.subjects[0].configurations[0].revision == 4)
        #expect(
            savedAggregate?.subjects[0].configurations[0]
                .output.album.destination == .existingAlbum
        )
        #expect(
            savedAggregate?.subjects[0].configurations[0]
                .output.album.identifier == "album-after"
        )
        #expect(reconciledCandidate?.aggregate == savedAggregate)
        #expect(reconciledReceipt == expectedReceipt)
        #expect(projectedConfiguration == reconciledCandidate?.configuration)
        #expect(
            statuses == [
                .init(status: .saving),
                .init(status: .saved)
            ]
        )
    }

    @Test("compatibility projection failure reports saved configuration with a concrete warning")
    @MainActor
    func compatibilityProjectionFailureReportsWarning() async throws {
        let aggregate = try Self.makeAggregate()
        let draft = Self.makeAggregateDraft(title: "After")
        let operationID = UUID(
            uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE"
        )!
        let receipt = ConfigurationLibrarySaveReceipt(
            revision: 12,
            subjectID: try #require(aggregate.activeSubjectID),
            configurationID:
                try #require(aggregate.activeConfigurationID),
            configurationRevision: 4,
            compatibilityProjectionFailure:
                ConfigurationLibraryProjectionFailure(
                    underlyingDescription: "projection failed"
                ),
            diagnosticOperationID: operationID
        )
        var statuses: [ConfigurationSaveViewStatus] = []
        let coordinator = ConfigurationSaveRuntimeCoordinator(
            applyLegacyRequest: { _ in
                Issue.record("Aggregate apply must not use legacy save.")
                return .failure(
                    MemoMarkError(
                        code: .invalidState,
                        message: "Unexpected legacy save."
                    )
                )
            },
            applyAggregateRequest: { candidate, _ in
                .success(
                    SaveConfigurationAggregateReceipt(
                        candidate: candidate,
                        saveReceipt: receipt,
                        albumSelection: .init(
                            identifier: "",
                            title: "",
                            pickerSelectionIdentifier: nil
                        )
                    )
                )
            },
            reloadAlbums: {},
            setSelectedExistingAlbumIdentifier: { _ in },
            restoreSubject: { _ in },
            reconcileConfigurationLibrary: { _, _ in .applied },
            applySelectedMemoryPreset: {},
            updateStatus: { statuses.append($0) }
        )

        let wasSuccessful = await coordinator.applyAggregate(
            configurationLibrary: aggregate,
            aggregateDraft: draft,
            availableAlbums: []
        )

        #expect(wasSuccessful)
        #expect(statuses.count == 2)
        guard case .savedWithWarning(let message) =
            statuses.last?.status else {
            Issue.record("Expected a saved-with-warning status.")
            return
        }
        #expect(message.contains("配置已保存"))
        #expect(message.contains("CFG-AAAAAAAA"))
    }

    @Test("aggregate apply does not project a stale receipt when newer edits win reconciliation")
    @MainActor
    func aggregateApplyDoesNotProjectStaleReceipt() async throws {
        let aggregate = try Self.makeAggregate()
        let draft = Self.makeAggregateDraft(title: "Saved Candidate")
        let subjectID = try #require(aggregate.activeSubjectID)
        let configurationID = try #require(
            aggregate.activeConfigurationID
        )
        var projectedConfiguration: MemoryConfigurationRecord?
        var statuses: [ConfigurationSaveViewStatus] = []
        let coordinator = ConfigurationSaveRuntimeCoordinator(
            applyLegacyRequest: { _ in
                Issue.record("Aggregate apply must not use legacy save.")
                return .failure(
                    MemoMarkError(
                        code: .invalidState,
                        message: "Unexpected legacy save."
                    )
                )
            },
            applyAggregateRequest: { candidate, _ in
                .success(
                    SaveConfigurationAggregateReceipt(
                        candidate: candidate,
                        saveReceipt: ConfigurationLibrarySaveReceipt(
                            revision: 12,
                            subjectID: subjectID,
                            configurationID: configurationID,
                            configurationRevision: 4,
                            compatibilityProjectionFailure:
                                ConfigurationLibraryProjectionFailure(
                                    underlyingDescription: "projection failed"
                                ),
                            diagnosticOperationID: UUID(
                                uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE"
                            )
                        ),
                        albumSelection: .init(
                            identifier: "",
                            title: "",
                            pickerSelectionIdentifier: nil
                        )
                    )
                )
            },
            reloadAlbums: {},
            setSelectedExistingAlbumIdentifier: { _ in },
            restoreSubject: { _ in },
            reconcileConfigurationLibrary: { _, _ in
                .newerEditsPreserved
            },
            applySavedConfigurationProjection: {
                projectedConfiguration = $0
            },
            applySelectedMemoryPreset: {},
            updateStatus: { statuses.append($0) }
        )

        let wasSuccessful = await coordinator.applyAggregate(
            configurationLibrary: aggregate,
            aggregateDraft: draft,
            availableAlbums: []
        )

        #expect(wasSuccessful)
        #expect(projectedConfiguration == nil)
        #expect(statuses.last?.status.hasUncommittedChanges == true)
    }

    @Test("aggregate apply forwards the save-start editor generation")
    @MainActor
    func aggregateApplyForwardsEditorGeneration() async throws {
        let aggregate = try Self.makeAggregate()
        let subjectID = try #require(aggregate.activeSubjectID)
        let configurationID = try #require(aggregate.activeConfigurationID)
        var receivedGeneration: UInt64?
        let coordinator = ConfigurationSaveRuntimeCoordinator(
            applyLegacyRequest: { _ in
                .failure(
                    MemoMarkError(
                        code: .invalidState,
                        message: "Unexpected legacy save."
                    )
                )
            },
            applyAggregateRequest: { candidate, _ in
                .success(
                    SaveConfigurationAggregateReceipt(
                        candidate: candidate,
                        saveReceipt: ConfigurationLibrarySaveReceipt(
                            revision: 3,
                            subjectID: subjectID,
                            configurationID: configurationID,
                            configurationRevision: 2,
                            compatibilityProjectionFailure: nil
                        ),
                        albumSelection: .init(
                            identifier: "",
                            title: "",
                            pickerSelectionIdentifier: nil
                        )
                    )
                )
            },
            reloadAlbums: {},
            setSelectedExistingAlbumIdentifier: { _ in },
            restoreSubject: { _ in },
            reconcileConfigurationLibraryWithGeneration: { _, _, generation in
                receivedGeneration = generation
                return .applied
            },
            applySelectedMemoryPreset: {},
            updateStatus: { _ in }
        )

        _ = await coordinator.applyAggregate(
            configurationLibrary: aggregate,
            aggregateDraft: Self.makeAggregateDraft(title: "Generation"),
            availableAlbums: [],
            editorGeneration: 17
        )

        #expect(receivedGeneration == 17)
    }

    @Test("aggregate save failure keeps the old production state dirty without legacy fallback")
    @MainActor
    func aggregateSaveFailureKeepsOldProductionDirty() async throws {
        let aggregate = try Self.makeAggregate()
        let draft = Self.makeAggregateDraft(title: "Unsaved")
        let configuration = try #require(
            aggregate.subjects.first?.configurations.first
        )
        var state = ConfigurationCenterState.mock
        state.configurationLibrary = aggregate
        state.subjects = aggregate.subjects.map(\.subject)
        state.memoryPresets = [
            MemoryPreset(
                id: configuration.id,
                title: configuration.title,
                summary: "",
                regionTemplateIDs:
                    configuration.editor.regionTemplateIDs,
                selectedSubjectID: aggregate.activeSubjectID
            )
        ]
        state.selectedSubjectID = aggregate.activeSubjectID
        state.selectedMemoryPresetID = configuration.id
        let session = ConfigurationSession(state: state)
        session.appliedMemoryPresetID = configuration.id
        session.updateSelectedMemoryPresetTitle("Unsaved")
        var legacyApplyCount = 0
        var reconcileCount = 0
        var statuses: [ConfigurationSaveViewStatus] = []
        let applyCoordinator = SaveConfigurationTransaction(
            resolveAlbumSelection: { _ in
                .success(
                    .init(
                        identifier: "album-after",
                        title: "After Album",
                        pickerSelectionIdentifier: nil
                    )
                )
            },
            saveConfiguration: { _ in
                Issue.record(
                    "Aggregate failure must not use legacy save."
                )
                return .failure(
                    MemoMarkError(
                        code: .invalidState,
                        message: "Unexpected legacy save."
                    )
                )
            },
            saveConfigurationLibrary: { _ in
                throw MemoMarkError(
                    code: .persistenceWriteFailed,
                    message: "保存配置失败。"
                )
            }
        )

        let coordinator = ConfigurationSaveRuntimeCoordinator(
            applyLegacyRequest: { _ in
                legacyApplyCount += 1
                return .failure(
                    MemoMarkError(
                        code: .invalidState,
                        message: "Aggregate failure must not fall back."
                    )
                )
            },
            applyAggregateRequest: { candidate, albums in
                await applyCoordinator.apply(
                    candidate: candidate,
                    availableAlbums: albums
                )
            },
            reloadAlbums: {},
            setSelectedExistingAlbumIdentifier: { _ in },
            restoreSubject: { _ in },
            reconcileConfigurationLibrary: { candidate, receipt in
                reconcileCount += 1
                return session.reconcileConfigurationLibrarySave(
                    candidate: candidate,
                    receipt: receipt
                )
            },
            applySelectedMemoryPreset: {},
            updateStatus: { statuses.append($0) }
        )

        let wasSuccessful = await coordinator.applyAggregate(
            configurationLibrary: aggregate,
            aggregateDraft: draft,
            availableAlbums: []
        )

        #expect(wasSuccessful == false)
        #expect(legacyApplyCount == 0)
        #expect(reconcileCount == 0)
        #expect(
            session.state.configurationLibrary?.subjects[0]
                .configurations[0].title == "Before"
        )
        #expect(session.state.configurationLibrary?.revision == 11)
        #expect(session.selectedMemoryPresetIsApplied == false)
        #expect(statuses.count == 2)
        #expect(statuses.first == .init(status: .saving))
        guard case .failure(let message) =
            statuses.last?.status else {
            Issue.record("Expected a detailed save failure status.")
            return
        }
        #expect(message.contains("写入设备存储"))
        #expect(message.contains("故障编号：CFG-"))
    }

    @Test("legacy compatibility requires an explicit apply path")
    @MainActor
    func missingAggregateUsesLegacyApplyPath() async {
        let request = Self.makeRequest(
            subject: ConfigurationCenterState.mock.selectedSubject
        )
        let receipt = SaveConfigurationReceipt(
            saveReceipt: V1ConfigurationSaveReceipt(
                anchor: Anchor(
                    type: .birthday,
                    title: "生日",
                    date: Date(timeIntervalSince1970: 86_400)
                )
            ),
            albumSelection: .init(
                identifier: "",
                title: "",
                pickerSelectionIdentifier: nil
            )
        )
        var legacyApplyCount = 0
        var aggregateApplyCount = 0

        let coordinator = ConfigurationSaveRuntimeCoordinator(
            applyLegacyRequest: { _ in
                legacyApplyCount += 1
                return .success(receipt)
            },
            applyAggregateRequest: { _, _ in
                aggregateApplyCount += 1
                return .failure(
                    MemoMarkError(
                        code: .invalidState,
                        message: "Unexpected aggregate apply."
                    )
                )
            },
            reloadAlbums: {},
            setSelectedExistingAlbumIdentifier: { _ in },
            restoreSubject: { _ in },
            applySelectedMemoryPreset: {},
            updateStatus: { _ in }
        )

        let wasSuccessful = await coordinator.applyLegacyCompatibility(
            request,
            outputTarget: .automatic,
        )

        #expect(wasSuccessful)
        #expect(legacyApplyCount == 1)
        #expect(aggregateApplyCount == 0)
    }

    @Test("success applies reconciliation side effects and reports saving state transitions")
    @MainActor
    func successAppliesReconciliationSideEffectsAndReportsSavingStateTransitions() async {
        let subject =
            ConfigurationCenterState.mock.selectedSubject
        let request =
            Self.makeRequest(subject: subject)
        let receipt =
            SaveConfigurationReceipt(
                saveReceipt: V1ConfigurationSaveReceipt(
                    anchor: Anchor(
                        type: .birthday,
                        title: "生日",
                        date: Date(timeIntervalSince1970: 86_400)
                    )
                ),
                albumSelection: V1ResolvedAlbumSelection(
                    identifier: "album-1",
                    title: "成长记录",
                    pickerSelectionIdentifier:
                        "picker-album-1"
                )
            )

        var didReloadAlbums = false
        var restoredSubject: MemorySubject?
        var didSaveCurrentPreset = false
        var didApplySelectedPreset = false
        var selectedExistingAlbumIdentifier = ""
        var outputTarget = ConfigurationOutputTarget.newAlbum
        var statuses: [ConfigurationSaveViewStatus] = []
        let coordinator =
            ConfigurationSaveRuntimeCoordinator(
                applyLegacyRequest: { receivedRequest in
                    #expect(receivedRequest == request)
                    return .success(receipt)
                },
                reloadAlbums: {
                    didReloadAlbums = true
                },
                setOutputTarget: {
                    outputTarget = $0
                },
                setSelectedExistingAlbumIdentifier: {
                    selectedExistingAlbumIdentifier = $0
                },
                restoreSubject: {
                    restoredSubject = $0
                },
                saveCurrentMemoryPreset: {
                    didSaveCurrentPreset = true
                },
                applySelectedMemoryPreset: {
                    didApplySelectedPreset = true
                },
                updateStatus: {
                    statuses.append($0)
                }
            )

        let wasSuccessful =
            await coordinator.apply(
                request,
                outputTarget: .newAlbum
            )

        #expect(wasSuccessful == true)
        #expect(didReloadAlbums == true)
        #expect(outputTarget == .existingAlbum)
        #expect(
            selectedExistingAlbumIdentifier
            == "picker-album-1"
        )
        #expect(restoredSubject == subject)
        #expect(didSaveCurrentPreset == true)
        #expect(didApplySelectedPreset == true)
        #expect(
            statuses == [
                ConfigurationSaveViewStatus(
                    status: .saving
                ),
                ConfigurationSaveViewStatus(
                    status: .saved
                )
            ]
        )
    }

    @Test("first save reconciles the persistence candidate UUID into the session")
    @MainActor
    func firstSaveReconcilesPersistenceCandidateUUIDIntoSession() async {
        var state = ConfigurationCenterState.mock
        state.memoryPresets = []
        state.selectedMemoryPresetID = nil

        let session = ConfigurationSession(state: state)
        let candidate =
            session.persistenceSnapshotForCurrentConfiguration(
                savedAt: Date(timeIntervalSince1970: 123)
            )
        let request = Self.makeRequest(
            subject: session.state.selectedSubject,
            memoryPresets: candidate.memoryPresets,
            selectedMemoryPresetID:
                candidate.selectedMemoryPresetID
        )
        let receipt = SaveConfigurationReceipt(
            saveReceipt: V1ConfigurationSaveReceipt(
                anchor: Anchor(
                    type: .birthday,
                    title: "生日",
                    date: Date(timeIntervalSince1970: 86_400)
                )
            ),
            albumSelection: V1ResolvedAlbumSelection(
                identifier: "album-1",
                title: "成长记录",
                pickerSelectionIdentifier: nil
            )
        )
        let coordinator =
            ConfigurationSaveRuntimeCoordinator(
                applyLegacyRequest: { _ in
                    .success(receipt)
                },
                reloadAlbums: {},
                setSelectedExistingAlbumIdentifier: { _ in },
                restoreSubject: {
                    session.restoreSelectedSubject($0)
                },
                saveCurrentMemoryPreset: {
                    Issue.record(
                        "First-save success should reconcile the persistence candidate."
                    )
                },
                reconcileCurrentMemoryPreset: { request in
                    session.reconcilePersistenceSnapshot(
                        memoryPresets:
                            request.memoryPresets,
                        selectedMemoryPresetID:
                            request.selectedMemoryPresetID
                    )
                },
                applySelectedMemoryPreset: {
                    Issue.record(
                        "Reconcile success should own applied state."
                    )
                },
                updateStatus: { _ in }
            )

        let wasSuccessful = await coordinator.apply(
            request,
            outputTarget: ConfigurationOutputTarget.automatic
        )

        #expect(wasSuccessful)
        #expect(
            session.state.selectedMemoryPresetID
            == candidate.selectedMemoryPresetID
        )
        #expect(
            session.state.memoryPresets.map(\.id)
            == [candidate.selectedMemoryPresetID]
        )
    }

    @Test("aggregate apply success reconciles the exact receipt identity")
    @MainActor
    func aggregateApplySuccessReconcilesExactReceiptIdentity() async {
        let request = Self.makeRequest(
            subject: ConfigurationCenterState.mock.selectedSubject
        )
        let durableID = UUID(
            uuidString: "94949494-9494-9494-9494-949494949494"
        )!
        let receipt = SaveConfigurationReceipt(
            saveReceipt: V1ConfigurationSaveReceipt(
                anchor: Anchor(
                    type: .birthday,
                    title: "生日",
                    date: Date(timeIntervalSince1970: 86_400)
                )
            ),
            albumSelection: V1ResolvedAlbumSelection(
                identifier: "",
                title: "",
                pickerSelectionIdentifier: nil
            )
        )
        var reconciledIdentity: (UUID?, Int?)?
        let coordinator = ConfigurationSaveRuntimeCoordinator(
            applyLegacyRequest: { _ in .success(receipt) },
            reloadAlbums: {},
            setSelectedExistingAlbumIdentifier: { _ in },
            restoreSubject: { _ in },
            reconcileSavedConfiguration: {
                _, configurationID, configurationRevision in
                reconciledIdentity = (
                    configurationID,
                    configurationRevision
                )
                return .applied
            },
            applySelectedMemoryPreset: {},
            updateStatus: { _ in }
        )

        let wasSuccessful = await coordinator.apply(
            request,
            outputTarget: ConfigurationOutputTarget.automatic,
            configurationSaveReceipt:
                ConfigurationLibrarySaveReceipt(
                    revision: 11,
                    subjectID: request.subject!.id,
                    configurationID: durableID,
                    configurationRevision: 5,
                    compatibilityProjectionFailure: nil
                )
        )

        #expect(wasSuccessful)
        #expect(reconciledIdentity?.0 == durableID)
        #expect(reconciledIdentity?.1 == 5)
    }

    @Test("reconcile success preserves a concurrent same-preset edit as dirty")
    @MainActor
    func reconcileSuccessPreservesConcurrentSamePresetEditAsDirty() async {
        let session = ConfigurationSession()
        let candidate =
            session.persistenceSnapshotForCurrentConfiguration(
                savedAt: Date(timeIntervalSince1970: 123)
            )
        let request = Self.makeRequest(
            subject: session.state.selectedSubject,
            memoryPresets: candidate.memoryPresets,
            selectedMemoryPresetID:
                candidate.selectedMemoryPresetID
        )
        let receipt = SaveConfigurationReceipt(
            saveReceipt: V1ConfigurationSaveReceipt(
                anchor: Anchor(
                    type: .birthday,
                    title: "生日",
                    date: Date(timeIntervalSince1970: 86_400)
                )
            ),
            albumSelection: V1ResolvedAlbumSelection(
                identifier: "album-1",
                title: "成长记录",
                pickerSelectionIdentifier: nil
            )
        )
        var statuses: [ConfigurationSaveViewStatus] = []

        let coordinator =
            ConfigurationSaveRuntimeCoordinator(
                applyLegacyRequest: { _ in
                    session.updateSelectedMemoryPresetTitle(
                        "等待期间更新的配置"
                    )
                    return .success(receipt)
                },
                reloadAlbums: {},
                setSelectedExistingAlbumIdentifier: { _ in },
                restoreSubject: {
                    session.restoreSelectedSubject($0)
                },
                saveCurrentMemoryPreset: {
                    Issue.record(
                        "Reconcile success should not use the legacy save path."
                    )
                },
                reconcileCurrentMemoryPreset: { request in
                    session.reconcilePersistenceSnapshot(
                        memoryPresets:
                            request.memoryPresets,
                        selectedMemoryPresetID:
                            request.selectedMemoryPresetID
                    )
                },
                applySelectedMemoryPreset: {
                    Issue.record(
                        "Reconcile success should not apply after preserving a concurrent edit."
                    )
                },
                updateStatus: {
                    statuses.append($0)
                }
            )

        let wasSuccessful = await coordinator.apply(
            request,
            outputTarget: .automatic
        )

        #expect(wasSuccessful)
        #expect(
            session.state.selectedMemoryPreset?.title
            == "等待期间更新的配置"
        )
        #expect(session.selectedMemoryPresetIsApplied == false)
        #expect(
            statuses == [
                ConfigurationSaveViewStatus(
                    status: .saving
                ),
                ConfigurationSaveViewStatus(
                    status: .dirty
                )
            ]
        )
    }

    @Test("failure skips success side effects and surfaces error state")
    @MainActor
    func failureSkipsSuccessSideEffectsAndSurfacesErrorState() async {
        let request =
            Self.makeRequest(subject: nil)
        let error =
            MemoMarkError(
                code: .invalidInput,
                message: "保存失败"
            )

        var didReloadAlbums = false
        var didRestoreSubject = false
        var didSaveCurrentPreset = false
        var didApplySelectedPreset = false
        var reconcileCount = 0
        var statuses: [ConfigurationSaveViewStatus] = []

        let coordinator =
            ConfigurationSaveRuntimeCoordinator(
                applyLegacyRequest: { _ in
                    .failure(error)
                },
                reloadAlbums: {
                    didReloadAlbums = true
                },
                setSelectedExistingAlbumIdentifier: { _ in
                    Issue.record(
                        "Failure flow should not update album selection."
                    )
                },
                restoreSubject: { _ in
                    didRestoreSubject = true
                },
                saveCurrentMemoryPreset: {
                    didSaveCurrentPreset = true
                },
                reconcileSavedConfiguration: { _, _, _ in
                    reconcileCount += 1
                    return .applied
                },
                applySelectedMemoryPreset: {
                    didApplySelectedPreset = true
                },
                updateStatus: {
                    statuses.append($0)
                }
            )

        let wasSuccessful =
            await coordinator.apply(
                request,
                outputTarget: ConfigurationOutputTarget.automatic
            )

        #expect(wasSuccessful == false)
        #expect(didReloadAlbums == false)
        #expect(didRestoreSubject == false)
        #expect(didSaveCurrentPreset == false)
        #expect(didApplySelectedPreset == false)
        #expect(reconcileCount == 0)
        #expect(
            statuses == [
                ConfigurationSaveViewStatus(
                    status: .saving
                ),
                ConfigurationSaveViewStatus(
                    status: .failure(message: "保存失败")
                )
            ]
        )
    }

    @Test("a durable receipt advances the save baseline while preserving edits made during save")
    @MainActor
    func newerEditsRetainDurableRevisionForNextSave() async throws {
        let aggregate = try Self.makeAggregate()
        let configuration = try #require(aggregate.subjects.first?.configurations.first)
        let session = ConfigurationSession(state: .mock)
        session.restoreConfigurationLibrary(aggregate)
        let saveStartGeneration = session.editorGeneration
        let candidate = try ConfigurationAggregateCandidateBuilder.build(
            from: aggregate,
            draft: Self.makeAggregateDraft(title: "First save"),
            configurationID: configuration.id
        )
        session.updateSelectedMemoryPresetTitle("Newer edit")
        let generationAfterEdit = session.editorGeneration
        let receipt = ConfigurationLibrarySaveReceipt(
            revision: aggregate.revision + 1,
            subjectID: try #require(aggregate.activeSubjectID),
            configurationID: configuration.id,
            configurationRevision: candidate.configuration.revision,
            compatibilityProjectionFailure: nil
        )

        let outcome = session.reconcileConfigurationLibrarySave(
            candidate: candidate,
            receipt: receipt,
            editorGeneration: saveStartGeneration
        )

        #expect(outcome == .newerEditsPreserved)
        #expect(session.currentMemoryPresetTitle == "Newer edit")
        #expect(session.editorGeneration == generationAfterEdit)
        // The next candidate must start from the revision accepted by durable
        // storage, or ConfigurationLibraryRepository rejects it as stale.
        let nextCandidate = try ConfigurationAggregateCandidateBuilder.build(
            from: try #require(session.state.configurationLibrary),
            draft: Self.makeAggregateDraft(title: session.currentMemoryPresetTitle),
            configurationID: configuration.id
        )
        #expect(nextCandidate.aggregate.revision == receipt.revision)
        #expect(nextCandidate.configuration.title == "Newer edit")
        #expect(nextCandidate.configuration.revision > candidate.configuration.revision)
    }

    @Test("a successful receipt advances durable baseline without replacing another selected draft", arguments: [false, true])
    @MainActor
    func receiptAfterSelectionChangePreservesCurrentDraft(differentSubject: Bool) throws {
        var aggregate = try Self.makeAggregate()
        let firstRecord = aggregate.subjects[0]
        let original = firstRecord.configurations[0]
        let secondID = UUID(uuidString: "82828282-8282-8282-8282-828282828282")!
        let second = MemoryConfigurationRecord(
            id: secondID,
            title: "Second configuration",
            revision: original.revision,
            savedAt: original.savedAt,
            selectedTimeAnchorID: original.selectedTimeAnchorID,
            language: original.language,
            editor: original.editor,
            presentation: original.presentation,
            output: original.output
        )
        let secondSubject: MemorySubject
        if differentSubject {
            let originalSubject = firstRecord.subject
            secondSubject = MemorySubject(
                id: UUID(uuidString: "83838383-8383-8383-8383-838383838383")!,
                identity: originalSubject.identity,
                relationship: originalSubject.relationship,
                referenceDate: originalSubject.referenceDate,
                timeAnchors: originalSubject.timeAnchors,
                activeTimeAnchorID: originalSubject.activeTimeAnchorID,
                behavior: originalSubject.behavior,
                decorations: []
            )
            aggregate.subjects.append(.init(
                subject: secondSubject,
                configurations: [second],
                assetManifest: .init(entries: [])
            ))
        } else {
            secondSubject = firstRecord.subject
            aggregate.subjects[0].configurations.append(second)
        }
        let session = ConfigurationSession(state: .mock)
        session.restoreConfigurationLibrary(aggregate)
        let generation = session.editorGeneration
        let candidate = try ConfigurationAggregateCandidateBuilder.build(
            from: aggregate,
            draft: Self.makeAggregateDraft(title: "First persisted"),
            configurationID: original.id
        )
        if differentSubject {
            session.selectSubject(secondSubject)
        }
        session.selectMemoryPreset(try #require(session.state.memoryPresets.first { $0.id == secondID }))
        session.updateSelectedMemoryPresetTitle("Second unsaved draft")
        let liveDraft = session.selectedMemoryConfiguration
        let appliedID = session.appliedMemoryPresetID
        let liveGeneration = session.editorGeneration
        let receipt = ConfigurationLibrarySaveReceipt(
            revision: aggregate.revision + 1,
            subjectID: firstRecord.subject.id,
            configurationID: original.id,
            configurationRevision: candidate.configuration.revision,
            compatibilityProjectionFailure: nil
        )

        let outcome = session.reconcileConfigurationLibrarySave(
            candidate: candidate,
            receipt: receipt,
            editorGeneration: generation
        )

        #expect(outcome == .newerEditsPreserved)
        #expect(session.state.configurationLibrary?.revision == receipt.revision)
        #expect(session.state.configurationLibrary?.subjects[0].configurations[0].title == "First persisted")
        #expect(session.state.selectedSubjectID == secondSubject.id)
        #expect(session.state.selectedMemoryPresetID == secondID)
        #expect(session.currentMemoryPresetTitle == "Second unsaved draft")
        #expect(session.selectedMemoryConfiguration == liveDraft)
        #expect(session.appliedMemoryPresetID == appliedID)
        #expect(session.editorGeneration == liveGeneration)
    }

    @Test("an older save receipt cannot downgrade durable baseline or overwrite current draft")
    @MainActor
    func olderReceiptCannotDowngradeDurableBaseline() throws {
        let aggregate = try Self.makeAggregate()
        let configuration = aggregate.subjects[0].configurations[0]
        let oldCandidate = try ConfigurationAggregateCandidateBuilder.build(
            from: aggregate,
            draft: Self.makeAggregateDraft(title: "Old receipt"),
            configurationID: configuration.id
        )
        var latestAggregate = aggregate
        latestAggregate.revision += 2
        latestAggregate.subjects[0].configurations[0].title = "Latest durable"
        let session = ConfigurationSession(state: .mock)
        session.restoreConfigurationLibrary(latestAggregate)
        session.updateSelectedMemoryPresetTitle("Latest draft")
        let liveDraft = session.selectedMemoryConfiguration
        let receipt = ConfigurationLibrarySaveReceipt(
            revision: aggregate.revision + 1,
            subjectID: aggregate.subjects[0].subject.id,
            configurationID: configuration.id,
            configurationRevision: oldCandidate.configuration.revision,
            compatibilityProjectionFailure: nil
        )

        let outcome = session.reconcileConfigurationLibrarySave(
            candidate: oldCandidate,
            receipt: receipt
        )

        #expect(outcome == .newerEditsPreserved)
        #expect(session.state.configurationLibrary == latestAggregate)
        #expect(session.currentMemoryPresetTitle == "Latest draft")
        #expect(session.selectedMemoryConfiguration == liveDraft)
    }

    @Test("album catalogue refresh never lets an older receipt overwrite newer output edits", arguments: [false, true])
    @MainActor
    func albumRefreshPreservesEdits(editBeforeReceipt: Bool) async throws {
        let aggregate = try Self.makeAggregate()
        let subjectID = try #require(aggregate.activeSubjectID)
        let configurationID = try #require(aggregate.activeConfigurationID)
        let session = ConfigurationSession(state: .mock)
        session.restoreConfigurationLibrary(aggregate)
        let generation = session.editorGeneration
        var outputTarget = ConfigurationOutputTarget.applePhotos
        var selectedAlbum = "user-selected-album"
        var displayedTitle = "Initial"
        var events: [String] = []
        var status = ConfigurationPersistenceStatus.dirty
        let coordinator = ConfigurationSaveRuntimeCoordinator(
            applyLegacyRequest: { _ in
                Issue.record("Unexpected legacy save")
                return .failure(.init(code: .invalidState, message: "Unexpected legacy save"))
            },
            applyAggregateRequest: { candidate, _ in
                if editBeforeReceipt {
                    session.updateSelectedMemoryPresetTitle("Newer edit")
                    displayedTitle = "Newer edit"
                }
                return .success(.init(
                    candidate: candidate,
                    saveReceipt: .init(
                        revision: aggregate.revision + 1,
                        subjectID: subjectID,
                        configurationID: configurationID,
                        configurationRevision: candidate.configuration.revision,
                        compatibilityProjectionFailure: nil
                    ),
                    albumSelection: .init(
                        identifier: "saved-album",
                        title: "Saved Album",
                        pickerSelectionIdentifier: "saved-picker-album"
                    )
                ))
            },
            reloadAlbums: {
                events.append("reload")
                await Task.yield()
                if !editBeforeReceipt {
                    // A real user edit can happen while an asynchronous
                    // catalogue refresh is suspended after durable save.
                    session.updateSelectedMemoryPresetTitle("Newer edit")
                    displayedTitle = "Newer edit"
                    outputTarget = .applePhotos
                    selectedAlbum = "user-selected-album"
                    status = .dirty
                }
            },
            setOutputTarget: {
                events.append("output")
                outputTarget = $0
            },
            setSelectedExistingAlbumIdentifier: {
                events.append("album")
                selectedAlbum = $0
            },
            restoreSubject: { _ in },
            reconcileConfigurationLibraryWithGeneration: { candidate, receipt, generation in
                events.append("reconcile")
                return session.reconcileConfigurationLibrarySave(
                    candidate: candidate,
                    receipt: receipt,
                    editorGeneration: generation
                )
            },
            applySavedConfigurationProjection: {
                events.append("projection")
                displayedTitle = $0.title
            },
            applySelectedMemoryPreset: {},
            updateStatus: {
                events.append("status")
                status = $0.status
            }
        )

        let saved = await coordinator.applyAggregate(
            configurationLibrary: aggregate,
            aggregateDraft: Self.makeAggregateDraft(title: "Saved candidate"),
            availableAlbums: [],
            editorGeneration: generation
        )

        #expect(saved)
        #expect(events.filter { $0 == "reload" }.count == 1)
        #expect(events.last == "reload")
        #expect(displayedTitle == "Newer edit")
        #expect(session.currentMemoryPresetTitle == "Newer edit")
        #expect(outputTarget == .applePhotos)
        #expect(selectedAlbum == "user-selected-album")
        #expect(status == .dirty)
        if editBeforeReceipt {
            #expect(!events.contains("output"))
            #expect(!events.contains("album"))
            #expect(!events.contains("projection"))
        } else {
            #expect(events.contains("projection"))
        }
    }

    private static func makeRequest(
        subject: MemorySubject?,
        memoryPresets: [MemoryPreset] = [],
        selectedMemoryPresetID: MemoryPreset.ID? = nil
    ) -> SaveConfigurationCommand {
        SaveConfigurationCommand(
            subject: subject,
            subjects: subject.map { [$0] } ?? [],
            selectedSubjectID: subject?.id,
            shouldSaveSubjectLibrary: true,
            memoryPresets: memoryPresets,
            selectedMemoryPresetID:
                selectedMemoryPresetID,
            template: .classicWhite,
            badge: nil,
            shouldWritePhotoDescription: false,
            photoDescriptionOverride: "",
            timeAnchorTitle: "生日",
            timeAnchorDate: Date(timeIntervalSince1970: 86_400),
            outputTarget: .automatic,
            availableAlbums: [],
            selectedExistingAlbumIdentifier: "",
            newAlbumName: "成长记录"
        )
    }

    private static func makeAggregate() throws
    -> ConfigurationLibraryRecord {
        let subject = try #require(
            ConfigurationCenterState.mock.selectedSubject
        )
        let configuration = MemoryConfigurationRecord(
            id: UUID(uuidString: "81818181-8181-8181-8181-818181818181")!,
            title: "Before",
            revision: 3,
            savedAt: Date(timeIntervalSince1970: 300),
            selectedTimeAnchorID: subject.primaryTimeAnchor?.id,
            editor: .init(
                template: .classicWhite,
                regionTemplateIDs: [.slotA: "before.recorder"],
                memoryCopy: .init(usesCustomText: false, customText: "")
            ),
            presentation: .init(
                route: .classicWhite,
                locationConfiguration: nil,
                logo: .init(mode: .appleMini, badge: nil)
            ),
            output: .init(
                mediaMode: .staticImage,
                livePhotoPolicy: .staticImageOnly,
                photosDescriptionPolicy: .init(
                    isEnabled: false,
                    overrideText: ""
                ),
                album: .automatic
            )
        )
        return ConfigurationLibraryRecord(
            revision: 11,
            subjects: [
                .init(
                    subject: subject,
                    configurations: [configuration],
                    assetManifest: .init(entries: [])
                )
            ],
            activeSubjectID: subject.id,
            activeConfigurationID: configuration.id
        )
    }

    private static func makeAggregateDraft(
        title: String
    ) -> ConfigurationAggregateDraft {
        ConfigurationAggregateDraft(
            title: title,
            regionDrafts: [
                .slotA: MemoryCardEditorDraft(items: [.text("After Recorder")])
            ],
            regionTemplateIDs: [.slotA: "after.recorder"],
            locationConfiguration: nil,
            logoMode: .appleMini,
            badge: nil,
            usesCustomMemoryWriteText: true,
            customMemoryWriteText: "After Memory",
            shouldWritePhotosDescription: true,
            photosDescriptionOverride: "After Description",
            outputTarget: .newAlbum,
            selectedAlbumIdentifier: "",
            albumTitle: "After Album",
            mediaOutputMode: .originalFormat,
            livePhotoPolicy: .preserveMotion,
            selectedTimeAnchorID:
                ConfigurationCenterState.mock.selectedSubject?
                    .primaryTimeAnchor?.id,
            savedAt: Date(timeIntervalSince1970: 400)
        )
    }
}
#endif
