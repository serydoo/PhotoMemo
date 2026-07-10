#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@MainActor
@Suite("Configuration session configuration lifecycle")
struct ConfigurationSessionConfigurationLifecycleTests {

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
        #expect(session.selectedMemoryPresetIsApplied)
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
        #expect(createdPreset.title == "途途 生日")
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
        #expect(session.previewText(for: .slotB) == "2026.05.24")
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
}
#endif
