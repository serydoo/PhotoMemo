#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("V1 subject library support")
struct V1SubjectLibrarySupportTests {

    @Test("add default subject appends and selects the new subject")
    @MainActor
    func addDefaultSubjectAppendsAndSelects() throws {
        let existingSubject = makeSubject(
            displayName: "途途成长记录",
            shortName: "途途",
            relationship: "成长记录",
            anchorTitle: "生日",
            anchorDate: Date(timeIntervalSince1970: 0)
        )
        let session = ConfigurationSession(
            state: ConfigurationCenterState(
                subjects: [existingSubject],
                selectedSubjectID: existingSubject.id,
                memoryPresets: [],
                selectedMemoryPresetID: nil,
                cardSelection: .init(selectedRegion: .subject),
                selectedBlockID: nil,
                tokenLibrary: .init(),
                availableDecorations: [],
                regionPreviewTexts: [:]
            )
        )

        let insertedSubject = V1SubjectLibraryMutationCoordinator
            .addDefaultSubject(
                referenceDate: Date(timeIntervalSince1970: 86_400),
                to: session
            )

        #expect(session.state.subjects.count == 2)
        #expect(session.state.selectedSubjectID == insertedSubject.id)
        #expect(session.state.selectedSubject?.id == insertedSubject.id)
        #expect(insertedSubject.timeAnchors.count == 3)
        #expect(insertedSubject.primaryTimeAnchor?.title == "生日")
    }

    @Test("activating anchor updates the selected subject's active anchor state")
    @MainActor
    func activatingAnchorUpdatesSelectedSubjectState() throws {
        let birthday = MemorySubject.TimeAnchor(
            title: "生日",
            date: Date(timeIntervalSince1970: 0),
            note: "出生日期"
        )
        let school = MemorySubject.TimeAnchor(
            title: "入园",
            date: Date(timeIntervalSince1970: 86_400),
            note: "第一次上学"
        )
        let subject = MemorySubject(
            identity: .init(
                displayName: "途途成长记录",
                shortName: "途途"
            ),
            relationship: .init(
                role: "family",
                label: "成长记录"
            ),
            definition: "围绕成长阶段持续记录。",
            referenceDate: birthday.date,
            timeAnchors: [birthday, school],
            activeTimeAnchorID: birthday.id,
            behavior: .init(
                primaryAnchor: birthday.title,
                iconStrategy: .autoMatch,
                badgeStrategy: .fixed,
                memoryExpression: .init(
                    title: "默认表达",
                    blocks: []
                )
            ),
            decorations: []
        )
        let session = ConfigurationSession(
            state: ConfigurationCenterState(
                subjects: [subject],
                selectedSubjectID: subject.id,
                memoryPresets: [],
                selectedMemoryPresetID: nil,
                cardSelection: .init(selectedRegion: .subject),
                selectedBlockID: nil,
                tokenLibrary: .init(),
                availableDecorations: [],
                regionPreviewTexts: [:]
            )
        )

        let activatedAnchor = try #require(
            V1SubjectLibraryMutationCoordinator
                .activateAnchor(
                    school.id,
                    in: session
                )
        )

        #expect(activatedAnchor.id == school.id)
        #expect(session.state.selectedSubject?.activeTimeAnchorID == school.id)
        #expect(session.state.selectedSubject?.behavior.primaryAnchor == "入园")
        #expect(session.state.selectedSubject?.referenceDate == school.date)
    }

    @Test("deleting current subject removes it and selects a fallback subject")
    @MainActor
    func deletingCurrentSubjectRemovesItAndSelectsFallback() throws {
        let firstSubject = makeSubject(
            displayName: "途途成长记录",
            shortName: "途途",
            relationship: "成长记录",
            anchorTitle: "生日",
            anchorDate: Date(timeIntervalSince1970: 0)
        )
        let secondSubject = makeSubject(
            displayName: "妈妈",
            shortName: "妈妈",
            relationship: "家人",
            anchorTitle: "纪念日",
            anchorDate: Date(timeIntervalSince1970: 86_400)
        )
        let session = ConfigurationSession(
            state: ConfigurationCenterState(
                subjects: [firstSubject, secondSubject],
                selectedSubjectID: secondSubject.id,
                memoryPresets: [],
                selectedMemoryPresetID: nil,
                cardSelection: .init(selectedRegion: .subject),
                selectedBlockID: nil,
                tokenLibrary: .init(),
                availableDecorations: [],
                regionPreviewTexts: [:]
            )
        )

        let fallbackSubject = try #require(
            V1SubjectLibraryMutationCoordinator
                .deleteCurrentSubject(
                    from: session
                )
        )

        #expect(session.state.subjects.count == 1)
        #expect(session.state.subjects.first?.id == firstSubject.id)
        #expect(fallbackSubject.id == firstSubject.id)
        #expect(session.state.selectedSubjectID == firstSubject.id)
    }

    @Test("overview anchor confirmation returns a sync patch with updated birthday date")
    @MainActor
    func overviewAnchorConfirmationReturnsSyncPatch() throws {
        let birthday = MemorySubject.TimeAnchor(
            title: "生日",
            date: Date(timeIntervalSince1970: 0),
            note: "出生日期"
        )
        let school = MemorySubject.TimeAnchor(
            title: "入园",
            date: Date(timeIntervalSince1970: 86_400),
            note: "第一次上学"
        )
        let subject = MemorySubject(
            identity: .init(
                displayName: "途途成长记录",
                shortName: "途途"
            ),
            relationship: .init(
                role: "family",
                label: "成长记录"
            ),
            definition: "围绕成长阶段持续记录。",
            referenceDate: birthday.date,
            timeAnchors: [birthday, school],
            activeTimeAnchorID: birthday.id,
            behavior: .init(
                primaryAnchor: birthday.title,
                iconStrategy: .autoMatch,
                badgeStrategy: .fixed,
                memoryExpression: .init(
                    title: "默认表达",
                    blocks: []
                )
            ),
            decorations: []
        )
        let session = ConfigurationSession(
            state: ConfigurationCenterState(
                subjects: [subject],
                selectedSubjectID: subject.id,
                memoryPresets: [],
                selectedMemoryPresetID: nil,
                cardSelection: .init(selectedRegion: .subject),
                selectedBlockID: nil,
                tokenLibrary: .init(),
                availableDecorations: [],
                regionPreviewTexts: [:]
            )
        )

        let patch = try #require(
            V1SubjectOverviewActionCoordinator
                .activateAnchor(
                    school.id,
                    in: session,
                    shouldSaveSubjectLibrary: false,
                    configurationCoordinator: nil
                )
        )

        #expect(patch.birthdayDate == school.date)
        #expect(patch.activeConfigurationStatus == .subjectSynced)
        #expect(patch.shouldRefreshPreview == false)
        #expect(
            !patch.events.contains(
                .reopenSubjectLibraryPersistence
            )
        )
    }

    @Test("overview subject switch requests preview draft bootstrap")
    @MainActor
    func overviewSubjectSwitchRequestsPreviewDraftBootstrap() throws {
        let firstSubject = makeSubject(
            displayName: "途途成长记录",
            shortName: "途途",
            relationship: "成长记录",
            anchorTitle: "生日",
            anchorDate: Date(timeIntervalSince1970: 0)
        )
        let secondSubject = makeSubject(
            displayName: "纪念对象",
            shortName: "纪念",
            relationship: "事件",
            anchorTitle: "纪念日",
            anchorDate: Date(timeIntervalSince1970: 86_400)
        )
        let session = ConfigurationSession(
            state: ConfigurationCenterState(
                subjects: [firstSubject, secondSubject],
                selectedSubjectID: firstSubject.id,
                memoryPresets: [],
                selectedMemoryPresetID: nil,
                cardSelection: .init(selectedRegion: .subject),
                selectedBlockID: nil,
                tokenLibrary: .init(),
                availableDecorations: [],
                regionPreviewTexts: [:]
            )
        )

        let patch = try #require(
            V1SubjectOverviewActionCoordinator
                .selectSubject(
                    secondSubject.id,
                    in: session,
                    shouldSaveSubjectLibrary: false,
                    configurationCoordinator: nil
                )
        )

        #expect(session.state.selectedSubjectID == secondSubject.id)
        #expect(
            patch.birthdayDate
            == secondSubject.primaryTimeAnchor?.date
        )
        #expect(patch.activeConfigurationStatus == .subjectSynced)
        #expect(
            patch.events.contains(
                .rebootstrapPreviewDrafts
            )
        )
    }

    @Test("legacy demo subject is removed without deleting custom event subjects")
    func legacyDemoSubjectIsRemovedWithoutDeletingCustomEvents() throws {
        let demoSubject = makeSubject(
            displayName: "Kyoto Spring",
            shortName: "Kyoto",
            relationship: "事件",
            anchorTitle: "纪念日",
            anchorDate: Date(timeIntervalSince1970: 0)
        )
        let eventSubject = makeSubject(
            displayName: "纪念对象",
            shortName: "纪念",
            relationship: "事件",
            anchorTitle: "纪念日",
            anchorDate: Date(timeIntervalSince1970: 86_400)
        )

        let sanitized =
            V1SubjectLibraryResolver
            .sanitizedSubjectLibrary(
                [
                    demoSubject,
                    eventSubject
                ]
            )

        #expect(sanitized == [eventSubject])
    }

    @Test("subject switch persistence preserves saved memory presets")
    @MainActor
    func subjectSwitchPersistencePreservesMemoryPresets() async throws {
        let suiteName =
            "PhotoMemo.V1SubjectLibrarySupportTests.presetPreserve.\(UUID().uuidString)"
        let defaults =
            try #require(
                UserDefaults(
                    suiteName: suiteName
                )
            )
        defaults.removePersistentDomain(
            forName: suiteName
        )
        defer {
            defaults.removePersistentDomain(
                forName: suiteName
            )
        }

        let firstSubject = makeSubject(
            displayName: "途途成长记录",
            shortName: "途途",
            relationship: "成长记录",
            anchorTitle: "生日",
            anchorDate: Date(timeIntervalSince1970: 0)
        )
        let secondSubject = makeSubject(
            displayName: "纪念对象",
            shortName: "纪念",
            relationship: "事件",
            anchorTitle: "纪念日",
            anchorDate: Date(timeIntervalSince1970: 86_400)
        )
        let selectedPreset = MemoryPreset(
            title: "纪念配置",
            summary: "对象二配置",
            regionTemplateIDs: [
                .slotA: "recorder.configuration1",
                .slotB: "timeline.configuration1",
                .slotC: "context.configuration1",
                .slotD: "memory.configuration1"
            ],
            selectedSubjectID: secondSubject.id,
            selectedTimeAnchorID:
                secondSubject.primaryTimeAnchor?.id
        )
        let session = ConfigurationSession(
            state: ConfigurationCenterState(
                subjects: [firstSubject, secondSubject],
                selectedSubjectID: firstSubject.id,
                memoryPresets: [selectedPreset],
                selectedMemoryPresetID: selectedPreset.id,
                cardSelection: .init(selectedRegion: .subject),
                selectedBlockID: nil,
                tokenLibrary: .init(),
                availableDecorations: [],
                regionPreviewTexts: [:]
            )
        )
        let coordinator =
            Self.makeConfigurationCoordinator(
                defaults: defaults
            )

        _ = try #require(
            V1SubjectOverviewActionCoordinator
                .selectSubject(
                    secondSubject.id,
                    in: session,
                    shouldSaveSubjectLibrary: true,
                    configurationCoordinator: coordinator
                )
        )

        let savedData =
            try #require(
                defaults.data(
                    forKey:
                        "photomemo.v1.subjectLibrary"
                )
            )
        let savedRecord =
            try JSONDecoder().decode(
                V1SubjectLibraryRecord.self,
                from: savedData
            )

        #expect(savedRecord.memoryPresets == [selectedPreset])
        #expect(savedRecord.selectedMemoryPresetID == selectedPreset.id)
    }

    @Test("adding default subject keeps editing enabled without reopening corrupt-library persistence")
    @MainActor
    func addingDefaultSubjectDoesNotReopenCorruptLibraryPersistence() throws {
        let existingSubject = makeSubject(
            displayName: "途途成长记录",
            shortName: "途途",
            relationship: "成长记录",
            anchorTitle: "生日",
            anchorDate: Date(timeIntervalSince1970: 0)
        )
        let session = ConfigurationSession(
            state: ConfigurationCenterState(
                subjects: [existingSubject],
                selectedSubjectID: existingSubject.id,
                memoryPresets: [],
                selectedMemoryPresetID: nil,
                cardSelection: .init(selectedRegion: .subject),
                selectedBlockID: nil,
                tokenLibrary: .init(),
                availableDecorations: [],
                regionPreviewTexts: [:]
            )
        )

        let patch =
            V1SubjectOverviewActionCoordinator
            .addDefaultSubject(
                referenceDate: Date(timeIntervalSince1970: 86_400),
                to: session,
                shouldSaveSubjectLibrary: false,
                configurationCoordinator: nil,
                onPersistedSubject: { _ in }
            )

        #expect(patch.shouldCloseOverview)
        #expect(
            !patch.events.contains(
                .reopenSubjectLibraryPersistence
            )
        )
        #expect(patch.activeConfigurationStatus == .subjectSynced)
        #expect(patch.flowState != nil)
        #expect(session.state.subjects.count == 2)
    }

    @Test("adding default subject emits reopen event when library persistence is already enabled")
    @MainActor
    func addingDefaultSubjectEmitsReopenEventWhenPersistenceIsEnabled() throws {
        let existingSubject = makeSubject(
            displayName: "途途成长记录",
            shortName: "途途",
            relationship: "成长记录",
            anchorTitle: "生日",
            anchorDate: Date(timeIntervalSince1970: 0)
        )
        let session = ConfigurationSession(
            state: ConfigurationCenterState(
                subjects: [existingSubject],
                selectedSubjectID: existingSubject.id,
                memoryPresets: [],
                selectedMemoryPresetID: nil,
                cardSelection: .init(selectedRegion: .subject),
                selectedBlockID: nil,
                tokenLibrary: .init(),
                availableDecorations: [],
                regionPreviewTexts: [:]
            )
        )

        let patch =
            V1SubjectOverviewActionCoordinator
            .addDefaultSubject(
                referenceDate: Date(timeIntervalSince1970: 86_400),
                to: session,
                shouldSaveSubjectLibrary: true,
                configurationCoordinator: nil,
                onPersistedSubject: { _ in }
            )

        #expect(
            patch.events.contains(
                .reopenSubjectLibraryPersistence
            )
        )
    }

    @Test("adding subject after corrupt-library bootstrap preserves raw payload while keeping UI editable")
    @MainActor
    func addSubjectAfterCorruptBootstrapPreservesRawPayload() async throws {
        let suiteName =
            "PhotoMemo.V1SubjectLibrarySupportTests.corruptAdd.\(UUID().uuidString)"
        let defaults =
            try #require(
                UserDefaults(
                    suiteName: suiteName
                )
            )
        defaults.removePersistentDomain(
            forName: suiteName
        )
        defer {
            defaults.removePersistentDomain(
                forName: suiteName
            )
        }

        let corruptPayload =
            Data("corrupted-subject-library".utf8)
        defaults.set(
            corruptPayload,
            forKey: "photomemo.v1.subjectLibrary"
        )

        let fallbackSubject = makeSubject(
            displayName: "备用对象",
            shortName: "宝宝",
            relationship: "成长记录",
            anchorTitle: "生日",
            anchorDate: Date(timeIntervalSince1970: 0)
        )
        let coordinator =
            Self.makeConfigurationCoordinator(
                defaults: defaults
            )
        let bootstrap =
            try requireSuccess(
                await LoadV1ConfigurationBootstrapIntent(
                    coordinator: coordinator
                )
                .execute()
            )
        let session =
            ConfigurationSession(
                state: ConfigurationCenterState(
                    subjects: [fallbackSubject],
                    selectedSubjectID: fallbackSubject.id,
                    memoryPresets: [],
                    selectedMemoryPresetID: nil,
                    cardSelection: .init(selectedRegion: .subject),
                    selectedBlockID: nil,
                    tokenLibrary: .init(),
                    availableDecorations: [],
                    regionPreviewTexts: [:]
                )
            )

        let patch =
            V1SubjectOverviewActionCoordinator
            .addDefaultSubject(
                referenceDate: Date(timeIntervalSince1970: 86_400),
                to: session,
                shouldSaveSubjectLibrary:
                    bootstrap.subjectLibraryReadFailure == nil,
                configurationCoordinator: coordinator,
                onPersistedSubject: { _ in }
            )

        #expect(patch.flowState != nil)
        #expect(session.state.subjects.count == 2)
        #expect(
            !patch.events.contains(
                .reopenSubjectLibraryPersistence
            )
        )
        #expect(
            defaults.data(
                forKey: "photomemo.v1.subjectLibrary"
            )
            == corruptPayload
        )
    }

    @Test("explicit corrupt-library recovery preserves raw payload and saves recovered library")
    @MainActor
    func explicitCorruptLibraryRecoveryPreservesRawPayloadAndSavesLibrary() async throws {
        let suiteName =
            "PhotoMemo.V1SubjectLibrarySupportTests.corruptRecover.\(UUID().uuidString)"
        let defaults =
            try #require(
                UserDefaults(
                    suiteName: suiteName
                )
            )
        defaults.removePersistentDomain(
            forName: suiteName
        )
        defer {
            defaults.removePersistentDomain(
                forName: suiteName
            )
        }

        let corruptPayload =
            Data("corrupted-subject-library".utf8)
        defaults.set(
            corruptPayload,
            forKey: "photomemo.v1.subjectLibrary"
        )

        let recoveredSubject = makeSubject(
            displayName: "恢复对象",
            shortName: "恢复",
            relationship: "成长记录",
            anchorTitle: "生日",
            anchorDate: Date(timeIntervalSince1970: 0)
        )
        let coordinator =
            Self.makeConfigurationCoordinator(
                defaults: defaults
            )
        let bootstrap =
            try requireSuccess(
                await LoadV1ConfigurationBootstrapIntent(
                    coordinator: coordinator
                )
                .execute()
            )
        let readFailure =
            try #require(
                bootstrap.subjectLibraryReadFailure
            )

        let recovery =
            try #require(
                V1SubjectLibraryRecoveryCoordinator
                .recoverCorruptLibrary(
                    subjects: [recoveredSubject],
                    selectedSubjectID: recoveredSubject.id,
                    readFailure: readFailure,
                    configurationCoordinator: coordinator
                )
            )

        #expect(
            recovery.preservedRawPayload
            == corruptPayload
        )
        let savedData =
            try #require(
                defaults.data(
                    forKey:
                        "photomemo.v1.subjectLibrary"
                )
            )
        let savedRecord =
            try JSONDecoder().decode(
                V1SubjectLibraryRecord.self,
                from: savedData
            )
        #expect(
            savedRecord
            == V1SubjectLibraryRecord(
                subjects: [recoveredSubject],
                selectedSubjectID: recoveredSubject.id
            )
        )
    }

    @Test("deleting the selected preset persists the updated subject library immediately")
    @MainActor
    func deletingSelectedPresetPersistsUpdatedSubjectLibraryImmediately() throws {
        let suiteName =
            "PhotoMemo.V1SubjectLibrarySupportTests.deletePreset.\(UUID().uuidString)"
        let defaults =
            try #require(
                UserDefaults(
                    suiteName: suiteName
                )
            )
        defaults.removePersistentDomain(
            forName: suiteName
        )
        defer {
            defaults.removePersistentDomain(
                forName: suiteName
            )
        }

        let coordinator =
            Self.makeConfigurationCoordinator(
                defaults: defaults
            )
        var state = ConfigurationCenterState.mock
        let selectedSubject = try #require(
            state.subjects.first
        )
        let preservedPreset = MemoryPreset(
            title: "保留配置",
            summary: "继续使用",
            regionTemplateIDs:
                state.memoryPresets[0]
                .regionTemplateIDs,
            selectedSubjectID:
                selectedSubject.id
        )
        let deletedPreset = MemoryPreset(
            title: "待删除配置",
            summary: "删除后不应恢复",
            regionTemplateIDs:
                state.memoryPresets[0]
                .regionTemplateIDs,
            selectedSubjectID:
                selectedSubject.id
        )

        state.memoryPresets = [
            preservedPreset,
            deletedPreset
        ]
        state.selectedSubjectID = selectedSubject.id
        state.selectedMemoryPresetID =
            deletedPreset.id

        let session = ConfigurationSession(
            state: state
        )

        _ =
            V1PresetDeletionCoordinator
            .deleteSelectedPreset(
                in: session,
                configurationCoordinator:
                    coordinator
            )

        let bootstrap =
            try requireSuccess(
                coordinator
                    .loadV1ConfigurationBootstrapState()
            )

        #expect(
            bootstrap.memoryPresets
                .map(\.id)
            == [preservedPreset.id]
        )
        #expect(
            bootstrap.selectedMemoryPresetID
            == preservedPreset.id
        )
    }

    @Test("editor flow callback emits sync patch after saving")
    @MainActor
    func editorFlowCallbackEmitsSyncPatchAfterSaving() throws {
        let subject = makeSubject(
            displayName: "途途成长记录",
            shortName: "途途",
            relationship: "成长记录",
            anchorTitle: "生日",
            anchorDate: Date(timeIntervalSince1970: 0)
        )
        let session = ConfigurationSession(
            state: ConfigurationCenterState(
                subjects: [subject],
                selectedSubjectID: subject.id,
                memoryPresets: [],
                selectedMemoryPresetID: nil,
                cardSelection: .init(selectedRegion: .subject),
                selectedBlockID: nil,
                tokenLibrary: .init(),
                availableDecorations: [],
                regionPreviewTexts: [:]
            )
        )
        var emittedPatch: V1SubjectFlowPatch?

        let flowState = try #require(
            V1SubjectOverviewActionCoordinator
                .makeConfigurationFlowState(
                    from: session,
                    shouldSaveSubjectLibrary: false,
                    configurationCoordinator: nil,
                    savedStatus: .dirty,
                    onPersistedSubject: { patch in
                        emittedPatch = patch
                    }
                )
        )

        var updatedSubject =
            try #require(
                flowState.draftSession.state.selectedSubject
            )
        updatedSubject.identity.displayName = "新的名字"
        flowState.draftSession.updateSelectedSubject(updatedSubject)
        flowState.saveChanges()

        #expect(session.state.selectedSubject?.identity.displayName == "新的名字")
        #expect(emittedPatch?.activeConfigurationStatus == .dirty)
        #expect(emittedPatch?.shouldRefreshPreview == true)
        #expect(emittedPatch?.birthdayDate == updatedSubject.primaryTimeAnchor?.date)
    }

    private func makeSubject(
        displayName: String,
        shortName: String,
        relationship: String,
        anchorTitle: String,
        anchorDate: Date
    ) -> MemorySubject {
        let anchor = MemorySubject.TimeAnchor(
            title: anchorTitle,
            date: anchorDate,
            note: "\(displayName) 的锚点"
        )

        return MemorySubject(
            identity: .init(
                displayName: displayName,
                shortName: shortName
            ),
            relationship: .init(
                role: "family",
                label: relationship
            ),
            definition: "\(displayName) 的说明",
            referenceDate: anchor.date,
            timeAnchors: [anchor],
            activeTimeAnchorID: anchor.id,
            behavior: .init(
                primaryAnchor: anchor.title,
                iconStrategy: .autoMatch,
                badgeStrategy: .fixed,
                memoryExpression: .init(
                    title: "默认表达",
                    blocks: []
                )
            ),
            decorations: []
        )
    }

    @MainActor
    private static func makeConfigurationCoordinator(
        defaults: UserDefaults
    ) -> ConfigurationCoordinator {
        let settingsService =
            SettingsService(defaults: defaults)

        return ConfigurationCoordinator(
            settingsRepository:
                SettingsRepository(
                    settingsService:
                        settingsService
                ),
            configurationRepository:
                ConfigurationRepository(
                    settingsService:
                        settingsService,
                    sharedSnapshotService:
                        SharedBatchConfigurationSnapshotService(
                            defaults: defaults
                        )
                )
        )
    }

    private func requireSuccess<Value>(
        _ result: PhotoMemoResult<Value>
    ) throws -> Value {
        switch result {
        case .success(let value):
            return value
        case .failure(let error):
            Issue.record("\(error.message)")
            throw error
        }
    }
}
#endif
