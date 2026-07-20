#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@MainActor
@Suite("Configuration session configuration lifecycle")
struct ConfigurationSessionConfigurationLifecycleTests {

    @Test("restoring aggregate selects its active record and ignores legacy selection")
    func restoringAggregateSelectsActiveRecord() throws {
        var state = ConfigurationCenterState.mock
        let subject = try #require(state.selectedSubject)
        let first = Self.makeCompleteConfiguration(
            id: UUID(uuidString: "91919191-9191-9191-9191-919191919191")!,
            title: "First",
            templateValue: "First",
            locationStyle: "city",
            logoMode: .appleMini,
            badge: .family,
            memoryText: "First Memory",
            descriptionEnabled: false,
            descriptionOverride: "First Description",
            albumIdentifier: "first-album",
            albumTitle: "First Album",
            mediaMode: .staticImage
        )
        let active = Self.makeCompleteConfiguration(
            id: UUID(uuidString: "92929292-9292-9292-9292-929292929292")!,
            title: "Active",
            templateValue: "Aggregate Wins",
            locationStyle: "provinceCity",
            logoMode: .customUpload,
            badge: .travel,
            memoryText: "Aggregate Memory",
            descriptionEnabled: true,
            descriptionOverride: "Aggregate Description",
            albumIdentifier: "aggregate-album",
            albumTitle: "Aggregate Album",
            mediaMode: .originalFormat
        )
        let aggregate = ConfigurationLibraryRecord(
            revision: 12,
            subjects: [
                .init(
                    subject: subject,
                    configurations: [first, active],
                    assetManifest: .init(entries: [])
                )
            ],
            activeSubjectID: subject.id,
            activeConfigurationID: active.id
        )
        state.selectedMemoryPresetID = state.memoryPresets.first?.id
        let session = ConfigurationSession(state: state)

        session.restoreConfigurationLibrary(aggregate)

        #expect(session.state.configurationLibrary == aggregate)
        #expect(session.state.selectedSubjectID == subject.id)
        #expect(session.state.selectedMemoryPresetID == active.id)
        #expect(session.selectedMemoryConfiguration == active)
        #expect(session.appliedMemoryPresetID == active.id)
        #expect(session.usesCustomMemoryWriteText)
        #expect(session.customMemoryWriteText == "Aggregate Memory")
    }

    @Test("selecting complete configurations restores independent drafts without changing production")
    func selectingCompleteConfigurationsRestoresIndependentDraftsWithoutChangingProduction() throws {
        var state = ConfigurationCenterState.mock
        let subject = try #require(state.selectedSubject)
        let firstConfiguration = Self.makeCompleteConfiguration(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            title: "海边",
            templateValue: "海边记录",
            locationStyle: "city",
            logoMode: .appleMini,
            badge: .family,
            memoryText: "第一次看海",
            descriptionEnabled: false,
            descriptionOverride: "海边照片说明",
            albumIdentifier: "album-sea",
            albumTitle: "海边",
            mediaMode: .staticImage
        )
        let secondConfiguration = Self.makeCompleteConfiguration(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            title: "生日",
            templateValue: "生日记录",
            locationStyle: "provinceCity",
            logoMode: .customUpload,
            badge: .travel,
            memoryText: "两岁生日",
            descriptionEnabled: true,
            descriptionOverride: "生日照片说明",
            albumIdentifier: "album-birthday",
            albumTitle: "生日",
            mediaMode: .originalFormat
        )
        state.configurationLibrary = ConfigurationLibraryRecord(
            revision: 8,
            subjects: [
                SubjectConfigurationRecord(
                    subject: subject,
                    configurations: [firstConfiguration, secondConfiguration],
                    assetManifest: .init(entries: [])
                )
            ],
            activeSubjectID: subject.id,
            activeConfigurationID: firstConfiguration.id
        )
        state.memoryPresets = [
            MemoryPreset(
                id: firstConfiguration.id,
                title: firstConfiguration.title,
                summary: "legacy projection",
                regionTemplateIDs: firstConfiguration.editor.regionTemplateIDs,
                selectedSubjectID: subject.id
            ),
            MemoryPreset(
                id: secondConfiguration.id,
                title: secondConfiguration.title,
                summary: "legacy projection",
                regionTemplateIDs: secondConfiguration.editor.regionTemplateIDs,
                selectedSubjectID: subject.id
            )
        ]
        state.selectedMemoryPresetID = firstConfiguration.id
        let session = ConfigurationSession(state: state)
        session.appliedMemoryPresetID = firstConfiguration.id

        session.selectMemoryPreset(state.memoryPresets[1])

        let selected = try #require(session.selectedMemoryConfiguration)
        #expect(selected == secondConfiguration)
        #expect(selected.editor.template.leftTopArea.items.count == 2)
        #expect(selected.editor.template.leftTopArea.items[1].value == "生日记录补充")
        #expect(selected.presentation.locationConfiguration?.options["displayStyle"] == "provinceCity")
        #expect(selected.presentation.logo.mode == .customUpload)
        #expect(selected.presentation.logo.badge?.id == Badge.travel.id)
        #expect(selected.editor.memoryCopy.customText == "两岁生日")
        #expect(selected.output.photosDescriptionPolicy.isEnabled)
        #expect(selected.output.photosDescriptionPolicy.overrideText == "生日照片说明")
        #expect(selected.output.album.identifier == "album-birthday")
        #expect(selected.output.album.title == "生日")
        #expect(selected.presentation.route == .classicWhite)
        #expect(selected.output.mediaMode == .originalFormat)
        #expect(session.appliedMemoryPresetID == firstConfiguration.id)
        #expect(session.selectedMemoryPresetIsApplied == false)

        session.selectMemoryPreset(state.memoryPresets[0])

        #expect(session.selectedMemoryConfiguration == firstConfiguration)
        #expect(session.appliedMemoryPresetID == firstConfiguration.id)
    }

    @Test("restart bootstrap preserves each configuration's complete region drafts")
    func restartBootstrapPreservesCompleteRegionDrafts() throws {
        let subject = try #require(
            ConfigurationCenterState.mock.selectedSubject
        )
        let firstConfiguration = Self.makeCompleteConfiguration(
            id: UUID(uuidString: "31313131-3131-3131-3131-313131313131")!,
            title: "海边重启",
            templateValue: "海边保存内容",
            locationStyle: "city",
            logoMode: .appleMini,
            badge: .family,
            memoryText: "第一次看海",
            descriptionEnabled: false,
            descriptionOverride: "",
            albumIdentifier: "album-restart-sea",
            albumTitle: "海边重启",
            mediaMode: .staticImage
        )
        let secondConfiguration = Self.makeCompleteConfiguration(
            id: UUID(uuidString: "32323232-3232-3232-3232-323232323232")!,
            title: "生日重启",
            templateValue: "生日保存内容",
            locationStyle: "provinceCity",
            logoMode: .customUpload,
            badge: .travel,
            memoryText: "两岁生日",
            descriptionEnabled: true,
            descriptionOverride: "生日照片说明",
            albumIdentifier: "album-restart-birthday",
            albumTitle: "生日重启",
            mediaMode: .originalFormat
        )
        let aggregate = ConfigurationLibraryRecord(
            revision: 12,
            subjects: [
                SubjectConfigurationRecord(
                    subject: subject,
                    configurations: [firstConfiguration, secondConfiguration],
                    assetManifest: .init(entries: [])
                )
            ],
            activeSubjectID: subject.id,
            activeConfigurationID: secondConfiguration.id
        )
        let session = ConfigurationSession()

        session.restoreConfigurationLibrary(aggregate)

        let context = V1PreviewCompositionContext(
            subject: subject,
            birthdayDate: subject.referenceDate,
            locationDisplayConfiguration: nil
        )
        let engine = V1PreviewCompositionEngine()

        func draftsAfterStartupBootstrap() throws -> [CardRegion: V1EditorDraft] {
            let configuration = try #require(
                session.selectedMemoryConfiguration
            )
            var drafts = V1ConfigurationDraftProjection(
                configuration: configuration
            ).regionDrafts
            drafts = V1DraftBootstrapCoordinator(
                session: session,
                context: context,
                engine: engine
            ).bootstrapDrafts { region in
                V1DraftBridge.editorDraft(
                    from: engine.defaultDraft(
                        for: region,
                        templateID: session.activeTemplateID(for: region),
                        context: context
                    )
                )
            }
            return drafts
        }

        var restoredDrafts = try draftsAfterStartupBootstrap()
        #expect(
            restoredDrafts[.slotA]?.items.map(\.value)
            == ["生日保存内容", "生日保存内容补充", ""]
        )

        let firstPreset = try #require(
            session.state.memoryPresets.first {
                $0.id == firstConfiguration.id
            }
        )
        session.selectMemoryPreset(firstPreset)
        restoredDrafts = try draftsAfterStartupBootstrap()

        #expect(
            restoredDrafts[.slotA]?.items.map(\.value)
            == ["海边保存内容", "海边保存内容补充", ""]
        )
    }

    @Test("saving the current configuration captures subject, anchor, output, logo, and custom memory-write state")
    func savingCurrentConfigurationCapturesContext() {
        let session = ConfigurationSession()
        let selectedSubject = session.state.subjects[0]

        session.selectSubject(selectedSubject)

        var updatedSubject = selectedSubject
        let selectedAnchor = updatedSubject.timeAnchors[1]
        updatedSubject.activeTimeAnchorID = selectedAnchor.id
        updatedSubject.behavior.primaryAnchor = selectedAnchor.title
        updatedSubject.referenceDate = selectedAnchor.date
        session.updateSelectedSubject(updatedSubject)

        session.selectedStorageOption = .targetAlbum
        session.usesCustomMemoryWriteText = true
        session.customMemoryWriteText = "纪念相册说明"

        session.saveCurrentMemoryPreset(
            logoMode: .subjectAvatar
        )

        let savedPreset = try! #require(
            session.state.selectedMemoryPreset
        )

        #expect(savedPreset.savedAt != nil)
        #expect(savedPreset.selectedSubjectID == updatedSubject.id)
        #expect(savedPreset.selectedTimeAnchorID == selectedAnchor.id)
        #expect(savedPreset.outputOption == .processedImage)
        #expect(savedPreset.storageOption == .targetAlbum)
        #expect(savedPreset.logoMode == .subjectAvatar)
        #expect(savedPreset.usesCustomMemoryWriteText == true)
        #expect(savedPreset.customMemoryWriteText == "纪念相册说明")
        #expect(session.selectedMemoryPresetIsApplied)
    }

    @Test("saving the current configuration makes an unbound preset available for the selected subject")
    func savingCurrentConfigurationMakesUnboundPresetAvailableForSelectedSubject() {
        var state = ConfigurationCenterState.mock
        let selectedSubject = state.subjects[0]
        let unboundPreset = MemoryPreset(
            title: "当前配置",
            summary: "尚未绑定对象",
            regionTemplateIDs:
                state.memoryPresets[0]
                .regionTemplateIDs
        )

        state.memoryPresets = [unboundPreset]
        state.selectedSubjectID = selectedSubject.id
        state.selectedMemoryPresetID = unboundPreset.id

        let session = ConfigurationSession(state: state)

        #expect(
            session
                .availableMemoryPresetsForSelectedSubject
                .isEmpty
        )

        session.saveCurrentMemoryPreset()

        #expect(
            session
                .availableMemoryPresetsForSelectedSubject
                .map(\.id)
            == [unboundPreset.id]
        )
        #expect(
            session
                .state
                .selectedMemoryPreset?
                .selectedSubjectID
            == selectedSubject.id
        )
    }

    @Test("selecting a configuration restores the saved subject, anchor, and output context")
    func selectingConfigurationRestoresSavedContext() {
        var state = Self.makeStateWithSecondSubject()
        let firstSubject = state.subjects[0]
        let secondSubject = state.subjects[1]

        let defaultPreset = MemoryPreset(
            title: "成长记录",
            summary: "默认对象配置",
            regionTemplateIDs: state.memoryPresets[0].regionTemplateIDs,
            savedAt: Date(timeIntervalSince1970: 10),
            selectedSubjectID: firstSubject.id,
            selectedTimeAnchorID: firstSubject.timeAnchors[0].id,
            outputOption: .processedImage,
            storageOption: .appFolder,
            usesCustomMemoryWriteText: false,
            customMemoryWriteText: ""
        )
        let secondPreset = MemoryPreset(
            title: "纪念配置",
            summary: "第二对象配置",
            regionTemplateIDs: state.memoryPresets[1].regionTemplateIDs,
            savedAt: Date(timeIntervalSince1970: 20),
            selectedSubjectID: secondSubject.id,
            selectedTimeAnchorID: secondSubject.timeAnchors[1].id,
            outputOption: .processedImage,
            storageOption: .targetAlbum,
            usesCustomMemoryWriteText: true,
            customMemoryWriteText: "纪念相册说明"
        )

        state.memoryPresets = [defaultPreset, secondPreset]
        state.selectedMemoryPresetID = defaultPreset.id

        let session = ConfigurationSession(state: state)

        session.selectMemoryPreset(secondPreset)

        #expect(session.state.selectedMemoryPresetID == secondPreset.id)
        #expect(session.state.selectedSubject?.id == secondSubject.id)
        #expect(session.state.selectedSubject?.primaryTimeAnchor?.id == secondSubject.timeAnchors[1].id)
        #expect(session.selectedStorageOption == .targetAlbum)
        #expect(session.usesCustomMemoryWriteText == true)
        #expect(session.customMemoryWriteText == "纪念相册说明")
        #expect(session.selectedMemoryPresetIsApplied == false)
    }

    @Test("restoring a saved configuration does not mark it pending")
    func restoringSavedConfigurationDoesNotMarkItPending() {
        var state = Self.makeStateWithSecondSubject()
        let selectedSubject = state.subjects[1]
        let selectedAnchor = selectedSubject.timeAnchors[1]
        let savedPreset = MemoryPreset(
            title: "纪念配置",
            summary: "已保存配置",
            regionTemplateIDs: state.memoryPresets[0].regionTemplateIDs,
            savedAt: Date(timeIntervalSince1970: 20),
            selectedSubjectID: selectedSubject.id,
            selectedTimeAnchorID: selectedAnchor.id,
            outputOption: .processedImage,
            storageOption: .targetAlbum,
            usesCustomMemoryWriteText: true,
            customMemoryWriteText: "纪念说明"
        )

        state.memoryPresets = [savedPreset]
        state.selectedSubjectID = selectedSubject.id
        state.selectedMemoryPresetID = savedPreset.id

        let session = ConfigurationSession(state: state)

        #expect(session.state.selectedMemoryPresetID == savedPreset.id)
        #expect(session.selectedStorageOption == .targetAlbum)
        #expect(session.usesCustomMemoryWriteText == true)
        #expect(session.customMemoryWriteText == "纪念说明")
        #expect(session.currentTimeAnchorTitle == selectedAnchor.title)
        #expect(session.selectedMemoryPresetIsApplied)
    }

    @Test("creating a configuration from the current state duplicates context and switches to the new unsaved configuration")
    func creatingConfigurationFromCurrentDuplicatesContext() {
        let session = ConfigurationSession()
        let selectedSubject = session.state.subjects[0]
        let originalPresetID = session.state.selectedMemoryPreset?.id

        session.selectSubject(selectedSubject)
        session.selectedStorageOption = .existingFolder
        session.usesCustomMemoryWriteText = true
        session.customMemoryWriteText = "批量纪念说明"

        let originalCount = session.state.memoryPresets.count

        session.createMemoryPresetFromCurrent(
            logoMode: .customUpload
        )

        let createdPreset = try! #require(
            session.state.selectedMemoryPreset
        )

        #expect(session.state.memoryPresets.count == originalCount + 1)
        #expect(createdPreset.id != originalPresetID)
        #expect(createdPreset.title == "小宝 生日")
        #expect(createdPreset.savedAt == nil)
        #expect(createdPreset.selectedSubjectID == selectedSubject.id)
        #expect(createdPreset.outputOption == .processedImage)
        #expect(createdPreset.storageOption == .existingFolder)
        #expect(createdPreset.logoMode == .customUpload)
        #expect(createdPreset.usesCustomMemoryWriteText == true)
        #expect(createdPreset.customMemoryWriteText == "批量纪念说明")
        #expect(session.selectedMemoryPresetIsApplied == false)
    }

    @Test("saving for a subject without configurations creates a default-named configuration for the home picker")
    func savingSubjectWithoutConfigurationsCreatesDefaultNamedConfiguration() {
        var state = Self.makeStateWithSecondSubject()
        let firstSubject = state.subjects[0]
        let secondSubject = state.subjects[1]

        let firstPreset = MemoryPreset(
            title: "宝宝配置",
            summary: "对象一配置",
            regionTemplateIDs: state.memoryPresets[0].regionTemplateIDs,
            selectedSubjectID: firstSubject.id
        )

        state.memoryPresets = [firstPreset]
        state.selectedSubjectID = secondSubject.id
        state.selectedMemoryPresetID = nil

        let session = ConfigurationSession(state: state)

        #expect(
            session.availableMemoryPresetsForSelectedSubject.isEmpty
        )

        session.saveCurrentMemoryPreset()

        let createdPreset = try! #require(
            session.state.selectedMemoryPreset
        )

        #expect(createdPreset.title == "纪念对象 纪念日")
        #expect(createdPreset.savedAt != nil)
        #expect(createdPreset.selectedSubjectID == secondSubject.id)
        #expect(
            session.availableMemoryPresetsForSelectedSubject
                .map(\.id)
            == [createdPreset.id]
        )
        #expect(session.selectedMemoryPresetIsApplied)
    }

    @Test("nil selected configuration does not fall back to another subject configuration")
    func nilSelectedConfigurationDoesNotFallBackToAnotherSubjectConfiguration() {
        var state = Self.makeStateWithSecondSubject()
        let firstSubject = state.subjects[0]
        let secondSubject = state.subjects[1]
        let firstPreset = MemoryPreset(
            title: "宝宝配置",
            summary: "对象一配置",
            regionTemplateIDs: [
                .slotA: "subject-one-recorder",
                .slotD: "subject-one-memory"
            ],
            selectedSubjectID: firstSubject.id
        )

        state.memoryPresets = [firstPreset]
        state.selectedSubjectID = secondSubject.id
        state.selectedMemoryPresetID = nil

        let session = ConfigurationSession(state: state)

        #expect(session.state.selectedMemoryPreset == nil)
    }

    @Test("new subject persistence snapshot does not inherit another subject configuration")
    func newSubjectPersistenceSnapshotDoesNotInheritAnotherSubjectConfiguration() {
        var state = Self.makeStateWithSecondSubject()
        let firstSubject = state.subjects[0]
        let secondSubject = state.subjects[1]
        let firstPreset = MemoryPreset(
            title: "宝宝配置",
            summary: "对象一配置",
            regionTemplateIDs: [
                .slotA: "subject-one-recorder",
                .slotD: "subject-one-memory"
            ],
            selectedSubjectID: firstSubject.id
        )

        state.memoryPresets = [firstPreset]
        state.selectedSubjectID = secondSubject.id
        state.selectedMemoryPresetID = nil

        let session = ConfigurationSession(state: state)
        let snapshot =
            session.persistenceSnapshotForCurrentConfiguration(
                savedAt: Date(timeIntervalSince1970: 123)
            )
        let createdPreset = try! #require(
            snapshot.memoryPresets.first {
                $0.id == snapshot.selectedMemoryPresetID
            }
        )

        #expect(createdPreset.summary == "当前区域组合")
        #expect(createdPreset.regionTemplateIDs.isEmpty)
        #expect(createdPreset.selectedSubjectID == secondSubject.id)
    }

    @Test("reconciling a saved candidate preserves newer unrelated preset mutations")
    func reconcilingSavedCandidatePreservesNewerUnrelatedPresetMutations() {
        var state = ConfigurationCenterState.mock
        let selectedSubject = state.subjects[0]
        let selectedPreset = MemoryPreset(
            title: "待保存配置",
            summary: "保存候选",
            regionTemplateIDs: [.slotA: "saved-recorder"],
            selectedSubjectID: selectedSubject.id
        )
        let unrelatedPreset = MemoryPreset(
            title: "其他配置",
            summary: "保存开始时的状态",
            regionTemplateIDs: [.slotD: "unrelated-memory"],
            selectedSubjectID: selectedSubject.id
        )

        state.memoryPresets = [selectedPreset, unrelatedPreset]
        state.selectedMemoryPresetID = selectedPreset.id

        let session = ConfigurationSession(state: state)
        let candidate =
            session.persistenceSnapshotForCurrentConfiguration(
                savedAt: Date(timeIntervalSince1970: 123)
            )
        let insertedPreset = MemoryPreset(
            title: "等待期间新增",
            summary: "较新的新增配置",
            regionTemplateIDs: [.slotB: "newer-timeline"],
            selectedSubjectID: selectedSubject.id
        )

        session.state.memoryPresets[1].summary =
            "等待期间更新后的状态"
        session.state.memoryPresets.append(insertedPreset)

        session.reconcilePersistenceSnapshot(
            memoryPresets: candidate.memoryPresets,
            selectedMemoryPresetID:
                candidate.selectedMemoryPresetID
        )

        #expect(
            session.state.memoryPresets.first {
                $0.id == unrelatedPreset.id
            }?.summary
            == "等待期间更新后的状态"
        )
        #expect(
            session.state.memoryPresets.contains {
                $0.id == insertedPreset.id
            }
        )
        #expect(
            session.state.selectedMemoryPresetID
            == candidate.selectedMemoryPresetID
        )
        #expect(session.selectedMemoryPresetIsApplied)
    }

    @Test("reconciling a saved candidate preserves a newer edit to the same preset")
    func reconcilingSavedCandidatePreservesNewerEditToSamePreset() {
        let session = ConfigurationSession()
        let candidate =
            session.persistenceSnapshotForCurrentConfiguration(
                savedAt: Date(timeIntervalSince1970: 123)
            )

        session.updateSelectedMemoryPresetTitle(
            "等待期间更新的配置"
        )

        #expect(session.selectedMemoryPresetIsApplied == false)

        session.reconcilePersistenceSnapshot(
            memoryPresets: candidate.memoryPresets,
            selectedMemoryPresetID:
                candidate.selectedMemoryPresetID
        )

        #expect(
            session.state.selectedMemoryPreset?.title
            == "等待期间更新的配置"
        )
        #expect(
            session.state.selectedMemoryPresetID
            == candidate.selectedMemoryPresetID
        )
        #expect(session.selectedMemoryPresetIsApplied == false)
    }

    @Test("aggregate receipt identity replaces the candidate identity and becomes selected and applied")
    func aggregateReceiptIdentityReconcilesSelectedConfiguration() throws {
        let state = ConfigurationCenterState.mock
        let candidate = try #require(state.selectedMemoryPreset)
        let durableID = UUID(
            uuidString: "93939393-9393-9393-9393-939393939393"
        )!
        let session = ConfigurationSession(state: state)
        let persistenceCandidate =
            session.persistenceSnapshotForCurrentConfiguration(
                savedAt: Date(timeIntervalSince1970: 123)
            )

        let outcome = session.reconcilePersistenceSnapshot(
            memoryPresets:
                persistenceCandidate.memoryPresets,
            selectedMemoryPresetID:
                persistenceCandidate.selectedMemoryPresetID,
            configurationID: durableID,
            configurationRevision: 7
        )

        #expect(outcome == .applied)
        #expect(session.state.selectedMemoryPresetID == durableID)
        #expect(session.appliedMemoryPresetID == durableID)
        #expect(session.state.selectedMemoryPreset?.id == durableID)
        #expect(session.state.selectedMemoryPreset?.title == candidate.title)
        #expect(
            session.state.memoryPresets.contains {
                $0.id == persistenceCandidate.selectedMemoryPresetID
            } == false
        )
    }

    @Test("aggregate save receipt reconciles the complete candidate into session state")
    func aggregateSaveReceiptReconcilesCompleteCandidate() throws {
        var state = ConfigurationCenterState.mock
        let subject = try #require(state.selectedSubject)
        let configuration = Self.makeCompleteConfiguration(
            id: UUID(uuidString: "95959595-9595-9595-9595-959595959595")!,
            title: "Before",
            templateValue: "Before",
            locationStyle: "city",
            logoMode: .appleMini,
            badge: .family,
            memoryText: "Before Memory",
            descriptionEnabled: false,
            descriptionOverride: "Before Description",
            albumIdentifier: "before-album",
            albumTitle: "Before Album",
            mediaMode: .staticImage
        )
        let aggregate = ConfigurationLibraryRecord(
            revision: 8,
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
        state.configurationLibrary = aggregate
        state.memoryPresets = [
            MemoryPreset(
                id: configuration.id,
                title: configuration.title,
                summary: "",
                regionTemplateIDs:
                    configuration.editor.regionTemplateIDs,
                selectedSubjectID: subject.id
            )
        ]
        state.selectedMemoryPresetID = configuration.id
        let session = ConfigurationSession(state: state)
        let candidate = try V1ConfigurationAggregateCandidateBuilder.build(
            from: aggregate,
            draft: V1ConfigurationAggregateDraft(
                title: "After",
                regionDrafts: [
                    .slotA: V1EditorDraft(items: [.text("After")])
                ],
                regionTemplateIDs: [.slotA: "after.recorder"],
                locationConfiguration: nil,
                logoMode: .appleMini,
                badge: .family,
                usesCustomMemoryWriteText: true,
                customMemoryWriteText: "After Memory",
                shouldWritePhotosDescription: true,
                photosDescriptionOverride: "After Description",
                outputTarget: .existingAlbum,
                selectedAlbumIdentifier: "after-album",
                albumTitle: "After Album",
                mediaOutputMode: .originalFormat,
                livePhotoPolicy: .preserveMotion,
                selectedTimeAnchorID:
                    subject.primaryTimeAnchor?.id,
                savedAt: Date(timeIntervalSince1970: 900)
            )
        )
        let receipt = ConfigurationLibrarySaveReceipt(
            revision: 9,
            subjectID: subject.id,
            configurationID: configuration.id,
            configurationRevision: 4,
            compatibilityProjectionFailure: nil
        )

        let outcome = session.reconcileConfigurationLibrarySave(
            candidate: candidate,
            receipt: receipt
        )

        #expect(outcome == .applied)
        #expect(session.state.configurationLibrary?.revision == 9)
        #expect(session.selectedMemoryConfiguration?.title == "After")
        #expect(session.selectedMemoryConfiguration?.revision == 4)
        #expect(session.customMemoryWriteText == "After Memory")
        #expect(session.appliedMemoryPresetID == configuration.id)
        #expect(session.selectedMemoryPresetIsApplied)
    }

    @Test("creating a configuration in the configuration center immediately makes it available in the home-page picker for the same subject")
    func creatingConfigurationImmediatelyAppearsInSubjectPicker() {
        var state = Self.makeStateWithSecondSubject()
        let firstSubject = state.subjects[0]
        let secondSubject = state.subjects[1]

        let firstPreset = MemoryPreset(
            title: "宝宝配置",
            summary: "对象一配置",
            regionTemplateIDs: state.memoryPresets[0].regionTemplateIDs,
            selectedSubjectID: firstSubject.id
        )
        let secondPreset = MemoryPreset(
            title: "纪念配置",
            summary: "对象二配置",
            regionTemplateIDs: state.memoryPresets[1].regionTemplateIDs,
            selectedSubjectID: secondSubject.id
        )

        state.memoryPresets = [firstPreset, secondPreset]
        state.selectedSubjectID = secondSubject.id
        state.selectedMemoryPresetID = secondPreset.id

        let session = ConfigurationSession(state: state)
        let originalCount =
            session.availableMemoryPresetsForSelectedSubject.count

        session.createMemoryPresetFromCurrent()

        let createdPreset = try! #require(
            session.state.selectedMemoryPreset
        )

        #expect(
            session.availableMemoryPresetsForSelectedSubject.count
            == originalCount + 1
        )
        #expect(
            session.availableMemoryPresetsForSelectedSubject
                .contains(createdPreset)
        )
        #expect(createdPreset.selectedSubjectID == secondSubject.id)
        #expect(session.state.selectedMemoryPresetID == createdPreset.id)
    }

    @Test("persistence snapshot folds current output settings into the selected configuration")
    func persistenceSnapshotFoldsCurrentOutputSettingsIntoSelectedConfiguration() {
        let session = ConfigurationSession()

        let snapshot =
            session
            .persistenceSnapshotForCurrentConfiguration(
                logoMode: .customUpload,
                outputConfiguration:
                    V1SavedOutputConfiguration(
                        outputTarget: .newAlbum,
                        mediaOutputMode: .staticImage,
                        selectedExistingAlbumIdentifier: "",
                        newAlbumName: "成长记录"
                    ),
                savedAt:
                    Date(
                        timeIntervalSince1970: 123
                    )
            )

        let savedPreset = try! #require(
            snapshot.memoryPresets.first {
                $0.id == snapshot.selectedMemoryPresetID
            }
        )

        #expect(savedPreset.savedAt == Date(timeIntervalSince1970: 123))
        #expect(savedPreset.logoMode == .customUpload)
        #expect(
            savedPreset.savedOutputConfiguration
            == V1SavedOutputConfiguration(
                outputTarget: .newAlbum,
                mediaOutputMode: .staticImage,
                selectedExistingAlbumIdentifier: "",
                newAlbumName: "成长记录"
            )
        )
    }

    @Test("saving without output context preserves the selected configuration output settings")
    func savingWithoutOutputContextPreservesSelectedConfigurationOutputSettings() {
        let session = ConfigurationSession()
        let outputConfiguration =
            V1SavedOutputConfiguration(
                outputTarget: .existingAlbum,
                mediaOutputMode: .originalFormat,
                selectedExistingAlbumIdentifier:
                    "album-123",
                newAlbumName: ""
            )

        session.saveCurrentMemoryPreset(
            outputConfiguration:
                outputConfiguration
        )
        session.selectedStorageOption = .targetAlbum
        session.saveCurrentMemoryPreset()

        #expect(
            session
                .state
                .selectedMemoryPreset?
                .savedOutputConfiguration
            == outputConfiguration
        )
    }

    @Test("editing a saved configuration marks it pending again")
    func editingSavedConfigurationMarksPresetPending() {
        let storageSession = ConfigurationSession()
        storageSession.saveCurrentMemoryPreset()
        #expect(storageSession.selectedMemoryPresetIsApplied)

        storageSession.selectedStorageOption = .targetAlbum

        #expect(storageSession.selectedMemoryPresetIsApplied == false)

        let subjectSession = ConfigurationSession(
            state: Self.makeStateWithSecondSubject()
        )
        subjectSession.saveCurrentMemoryPreset()
        #expect(subjectSession.selectedMemoryPresetIsApplied)

        subjectSession.selectSubject(
            subjectSession.state.subjects[1]
        )

        #expect(subjectSession.selectedMemoryPresetIsApplied == false)
    }

    @Test("selecting a time anchor updates the selected subject context")
    func selectingTimeAnchorUpdatesSelectedSubjectContext() {
        let session = ConfigurationSession(
            state: Self.makeStateWithSecondSubject()
        )
        let subject = session.state.subjects[1]
        let targetAnchor = subject.timeAnchors[2]

        session.saveCurrentMemoryPreset()
        #expect(session.selectedMemoryPresetIsApplied)

        session.selectSubject(subject)
        session.selectTimeAnchor(id: targetAnchor.id)

        #expect(session.state.selectedSubject?.activeTimeAnchorID == targetAnchor.id)
        #expect(session.state.selectedSubject?.behavior.primaryAnchor == targetAnchor.title)
        #expect(session.state.selectedSubject?.referenceDate == targetAnchor.date)
        #expect(session.currentTimeAnchorTitle == targetAnchor.title)
        #expect(session.selectedMemoryPresetIsApplied == false)
    }

    @Test("changing the current time-anchor expression style updates the active anchor context")
    func changingCurrentTimeAnchorExpressionStyleUpdatesActiveAnchor() {
        let session = ConfigurationSession(
            state: Self.makeStateWithSecondSubject()
        )
        let subject = session.state.subjects[1]
        let targetAnchor = subject.timeAnchors[0]

        session.saveCurrentMemoryPreset()
        #expect(session.selectedMemoryPresetIsApplied)

        session.selectSubject(subject)
        session.selectTimeAnchor(id: targetAnchor.id)
        session.selectCurrentTimeAnchorExpressionStyle(.birthdayWarm)

        let updatedAnchor = try! #require(
            session.state.selectedSubject?.primaryTimeAnchor
        )

        #expect(updatedAnchor.id == targetAnchor.id)
        #expect(updatedAnchor.resolvedExpressionStyle == .birthdayWarm)
        #expect(session.selectedMemoryPresetIsApplied == false)
    }

    @Test("available configurations are filtered to the selected memory subject")
    func availableConfigurationsAreFilteredToSelectedSubject() {
        var state = Self.makeStateWithSecondSubject()
        let firstSubject = state.subjects[0]
        let secondSubject = state.subjects[1]

        let firstPreset = MemoryPreset(
            title: "成长记录",
            summary: "对象一",
            regionTemplateIDs: state.memoryPresets[0].regionTemplateIDs,
            selectedSubjectID: firstSubject.id
        )
        let secondPreset = MemoryPreset(
            title: "纪念记录",
            summary: "对象二",
            regionTemplateIDs: state.memoryPresets[1].regionTemplateIDs,
            selectedSubjectID: secondSubject.id
        )

        state.memoryPresets = [firstPreset, secondPreset]
        state.selectedSubjectID = firstSubject.id
        state.selectedMemoryPresetID = firstPreset.id

        let session = ConfigurationSession(state: state)

        #expect(
            session.availableMemoryPresetsForSelectedSubject
                .map(\.id)
            == [firstPreset.id]
        )

        session.selectSubject(secondSubject)

        #expect(
            session.availableMemoryPresetsForSelectedSubject
                .map(\.id)
            == [secondPreset.id]
        )
    }

    @Test("switching memory subjects aligns the current configuration to that subject")
    func switchingMemorySubjectsAlignsCurrentConfiguration() {
        var state = Self.makeStateWithSecondSubject()
        let firstSubject = state.subjects[0]
        let secondSubject = state.subjects[1]

        let firstPreset = MemoryPreset(
            title: "宝宝配置",
            summary: "对象一配置",
            regionTemplateIDs: state.memoryPresets[0].regionTemplateIDs,
            savedAt: Date(timeIntervalSince1970: 10),
            selectedSubjectID: firstSubject.id,
            selectedTimeAnchorID: firstSubject.timeAnchors[0].id,
            outputOption: .processedImage,
            storageOption: .appFolder,
            usesCustomMemoryWriteText: false,
            customMemoryWriteText: ""
        )
        let secondPreset = MemoryPreset(
            title: "纪念配置",
            summary: "对象二配置",
            regionTemplateIDs: state.memoryPresets[1].regionTemplateIDs,
            savedAt: Date(timeIntervalSince1970: 20),
            selectedSubjectID: secondSubject.id,
            selectedTimeAnchorID: secondSubject.timeAnchors[1].id,
            outputOption: .processedImage,
            storageOption: .targetAlbum,
            usesCustomMemoryWriteText: true,
            customMemoryWriteText: "纪念说明"
        )

        state.memoryPresets = [firstPreset, secondPreset]
        state.selectedSubjectID = firstSubject.id
        state.selectedMemoryPresetID = firstPreset.id

        let session = ConfigurationSession(state: state)

        session.selectSubject(secondSubject)

        #expect(session.state.selectedSubjectID == secondSubject.id)
        #expect(session.state.selectedMemoryPresetID == secondPreset.id)
        #expect(session.currentMemoryPresetTitle == "纪念配置")
        #expect(session.selectedStorageOption == .targetAlbum)
        #expect(session.usesCustomMemoryWriteText == true)
        #expect(session.customMemoryWriteText == "纪念说明")
        #expect(session.currentTimeAnchorTitle == secondSubject.timeAnchors[1].title)
    }

    @Test("switching memory subjects aligns the durable active configuration without saving")
    func switchingMemorySubjectsAlignsDurableActiveConfigurationWithoutSaving() throws {
        var state = Self.makeStateWithSecondSubject()
        let firstSubject = state.subjects[0]
        let secondSubject = state.subjects[1]
        let firstConfiguration = Self.makeCompleteConfiguration(
            id: UUID(uuidString: "51515151-5151-5151-5151-515151515151")!,
            title: "对象一配置",
            templateValue: "对象一智能模块",
            locationStyle: "city",
            logoMode: .appleMini,
            badge: .family,
            memoryText: "对象一自定义内容",
            descriptionEnabled: false,
            descriptionOverride: "",
            albumIdentifier: "subject-one",
            albumTitle: "对象一",
            mediaMode: .staticImage
        )
        var secondConfiguration = Self.makeCompleteConfiguration(
            id: UUID(uuidString: "52525252-5252-5252-5252-525252525252")!,
            title: "对象二配置",
            templateValue: "对象二智能模块",
            locationStyle: "provinceCity",
            logoMode: .customUpload,
            badge: .travel,
            memoryText: "对象二自定义内容",
            descriptionEnabled: true,
            descriptionOverride: "对象二说明",
            albumIdentifier: "subject-two",
            albumTitle: "对象二",
            mediaMode: .originalFormat
        )
        secondConfiguration.selectedTimeAnchorID =
            secondSubject.timeAnchors[1].id
        let aggregate = ConfigurationLibraryRecord(
            revision: 4,
            subjects: [
                .init(
                    subject: firstSubject,
                    configurations: [firstConfiguration],
                    assetManifest: .init(entries: [])
                ),
                .init(
                    subject: secondSubject,
                    configurations: [secondConfiguration],
                    assetManifest: .init(entries: [])
                )
            ],
            activeSubjectID: firstSubject.id,
            activeConfigurationID: firstConfiguration.id
        )
        state.configurationLibrary = aggregate
        state.memoryPresets = [
            MemoryPreset(
                id: firstConfiguration.id,
                title: firstConfiguration.title,
                summary: "",
                regionTemplateIDs: firstConfiguration.editor.regionTemplateIDs,
                savedAt: firstConfiguration.savedAt,
                selectedSubjectID: firstSubject.id,
                selectedTimeAnchorID: firstSubject.timeAnchors[0].id
            ),
            MemoryPreset(
                id: secondConfiguration.id,
                title: secondConfiguration.title,
                summary: "",
                regionTemplateIDs: secondConfiguration.editor.regionTemplateIDs,
                savedAt: secondConfiguration.savedAt,
                selectedSubjectID: secondSubject.id,
                selectedTimeAnchorID: secondSubject.timeAnchors[1].id
            )
        ]
        state.selectedSubjectID = firstSubject.id
        state.selectedMemoryPresetID = firstConfiguration.id
        let session = ConfigurationSession(state: state)

        session.selectSubject(secondSubject)

        #expect(session.state.selectedMemoryPresetID == secondConfiguration.id)
        #expect(session.state.configurationLibrary?.activeSubjectID == secondSubject.id)
        #expect(session.state.configurationLibrary?.activeConfigurationID == secondConfiguration.id)
        #expect(session.selectedMemoryConfiguration == secondConfiguration)
        let restoredDrafts = V1ConfigurationDraftProjection(
            configuration: try #require(session.selectedMemoryConfiguration)
        ).regionDrafts
        #expect(
            restoredDrafts[.slotA]?.items.map(\.value)
            == ["对象二智能模块", "对象二智能模块补充", ""]
        )
    }

    @Test("switching memory subjects rebuilds region preview text from that subject's configuration")
    func switchingMemorySubjectsRebuildsRegionPreviewTextFromConfiguration() {
        var state = Self.makeStateWithSecondSubject()
        let firstSubject = state.subjects[0]
        let secondSubject = state.subjects[1]

        let firstPreset = MemoryPreset(
            title: "宝宝配置",
            summary: "对象一配置",
            regionTemplateIDs: [
                .slotA: "recorder.configuration1",
                .slotB: "timeline.configuration1",
                .slotC: "context.configuration1",
                .slotD: "memory.configuration1"
            ],
            savedAt: Date(timeIntervalSince1970: 10),
            selectedSubjectID: firstSubject.id,
            selectedTimeAnchorID: firstSubject.timeAnchors[0].id
        )
        let secondPreset = MemoryPreset(
            title: "纪念配置",
            summary: "对象二配置",
            regionTemplateIDs: [
                .slotA: "recorder.configuration2",
                .slotB: "timeline.configuration2",
                .slotC: "context.configuration2",
                .slotD: "memory.configuration2"
            ],
            savedAt: Date(timeIntervalSince1970: 20),
            selectedSubjectID: secondSubject.id,
            selectedTimeAnchorID: secondSubject.timeAnchors[1].id
        )

        state.memoryPresets = [firstPreset, secondPreset]
        state.selectedSubjectID = firstSubject.id
        state.selectedMemoryPresetID = firstPreset.id
        state.regionPreviewTexts[.slotA] = "旧对象记录内容"
        state.regionPreviewTexts[.slotB] = "旧对象时间线"
        state.regionPreviewTexts[.slotC] = "旧对象拍摄参数"
        state.regionPreviewTexts[.slotD] = "旧对象记忆表达"

        let session = ConfigurationSession(state: state)

        session.selectSubject(secondSubject)

        #expect(session.state.selectedMemoryPresetID == secondPreset.id)
        #expect(session.previewText(for: .slotA) == " ")
        #expect(session.previewText(for: .slotB) == "2026.06.01")
        #expect(session.previewText(for: .slotC) == "24mm f/1.78 1/100s ISO125")
        #expect(session.previewText(for: .slotD) == " ")
    }

    @Test("switching to a memory subject without configurations clears the stale current configuration")
    func switchingToSubjectWithoutConfigurationsClearsStaleCurrentConfiguration() {
        var state = Self.makeStateWithSecondSubject()
        let firstSubject = state.subjects[0]
        let secondSubject = state.subjects[1]

        let firstPreset = MemoryPreset(
            title: "宝宝配置",
            summary: "对象一配置",
            regionTemplateIDs: state.memoryPresets[0].regionTemplateIDs,
            savedAt: Date(timeIntervalSince1970: 10),
            selectedSubjectID: firstSubject.id,
            selectedTimeAnchorID: firstSubject.timeAnchors[0].id
        )

        state.memoryPresets = [firstPreset]
        state.selectedSubjectID = firstSubject.id
        state.selectedMemoryPresetID = firstPreset.id

        let session = ConfigurationSession(state: state)

        session.selectSubject(secondSubject)

        #expect(session.state.selectedSubjectID == secondSubject.id)
        #expect(session.availableMemoryPresetsForSelectedSubject.isEmpty)
        #expect(session.state.selectedMemoryPresetID == nil)
        #expect(session.currentMemoryPresetTitle == "当前对象还没有配置")
        #expect(session.currentMemoryPresetSummary == "为当前记忆对象新建配置后即可使用。")
        #expect(session.selectedMemoryPresetIsApplied == false)
    }

    private static func makeStateWithSecondSubject()
        -> ConfigurationCenterState {
        var state = ConfigurationCenterState.mock
        let calendar = Calendar(identifier: .gregorian)
        let date = { (year: Int, month: Int, day: Int) in
            calendar.date(
                from: DateComponents(
                    year: year,
                    month: month,
                    day: day
                )
            ) ?? Date()
        }

        let icon = DecorationAsset(
            kind: .icon,
            title: "星标",
            systemSymbolName: "star.fill"
        )
        let badge = DecorationAsset(
            kind: .badge,
            title: "纪念",
            systemSymbolName: "sparkles"
        )
        let anchors = [
            MemorySubject.TimeAnchor(
                title: "纪念日",
                date: date(2025, 8, 18),
                note: "重要纪念日"
            ),
            MemorySubject.TimeAnchor(
                title: "相识",
                date: date(2025, 8, 20),
                note: "相识日期"
            ),
            MemorySubject.TimeAnchor(
                title: "入学",
                date: date(2026, 9, 1),
                note: "入学日期"
            )
        ]

        let subject = MemorySubject(
            identity: .init(
                displayName: "纪念对象",
                shortName: "纪念"
            ),
            relationship: .init(
                role: "事件",
                label: "纪念"
            ),
            definition: "用于覆盖多记忆对象配置切换的测试对象。",
            referenceDate: anchors[0].date,
            timeAnchors: anchors,
            activeTimeAnchorID: anchors[0].id,
            behavior: MemoryBehavior(
                primaryAnchor: anchors[0].title,
                iconStrategy: .fixed,
                badgeStrategy: .autoMatch,
                memoryExpression: MemoryExpression(
                    title: "纪念表达",
                    blocks: [
                        .text(""),
                        MemoryBlock(
                            type: .memory,
                            title: "对象",
                            value: "对象"
                        ),
                        .text(" · "),
                        MemoryBlock(
                            type: .memory,
                            title: "时间锚点",
                            value: "时间锚点"
                        )
                    ]
                )
            ),
            decorations: [
                icon,
                badge
            ]
        )

        state.subjects.append(subject)
        return state
    }

    private static func makeCompleteConfiguration(
        id: UUID,
        title: String,
        templateValue: String,
        locationStyle: String,
        logoMode: V1LogoMode,
        badge: Badge,
        memoryText: String,
        descriptionEnabled: Bool,
        descriptionOverride: String,
        albumIdentifier: String,
        albumTitle: String,
        mediaMode: V1MediaOutputMode
    ) -> MemoryConfigurationRecord {
        var template = Template.classicWhite
        template.name = title
        template.leftTopArea.items = [
            TemplateItem(
                type: .text,
                name: "主记录",
                value: templateValue,
                isEnabled: true
            ),
            TemplateItem(
                type: .variable,
                name: "补充记录",
                value: "\(templateValue)补充",
                isEnabled: true
            )
        ]
        return MemoryConfigurationRecord(
            id: id,
            title: title,
            revision: 3,
            savedAt: Date(timeIntervalSince1970: 300),
            selectedTimeAnchorID: nil,
            editor: .init(
                template: template,
                regionTemplateIDs: [.slotA: "\(title).recorder"],
                memoryCopy: .init(
                    usesCustomText: true,
                    customText: memoryText
                )
            ),
            presentation: .init(
                route: .classicWhite,
                locationConfiguration: .init(
                    token: "{{location}}",
                    options: ["displayStyle": locationStyle]
                ),
                logo: .init(
                    mode: logoMode,
                    badge: .init(
                        id: badge.id,
                        name: badge.name,
                        type: badge.type,
                        imageName: badge.imageName,
                        systemSymbol: badge.systemSymbol,
                        isSystemDefault: badge.isSystemDefault
                    )
                )
            ),
            output: .init(
                mediaMode: mediaMode,
                livePhotoPolicy: .preserveMotion,
                photosDescriptionPolicy: .init(
                    isEnabled: descriptionEnabled,
                    overrideText: descriptionOverride
                ),
                album: .init(
                    destination: .existingAlbum,
                    identifier: albumIdentifier,
                    title: albumTitle
                )
            )
        )
    }
}
#endif
