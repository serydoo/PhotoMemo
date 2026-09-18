#if os(macOS) && !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing
@testable import MemoMark

@Suite("macOS configuration editing context")
struct MacConfigurationEditingContextTests {

    @Test("a subject or configuration change requires a fresh projection")
    func contextChangeRequiresProjection() {
        let first = MacConfigurationEditingContext(
            subjectID: UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"),
            configuration: nil
        )
        let same = MacConfigurationEditingContext(
            subjectID: first.subjectID,
            configuration: nil
        )
        let other = MacConfigurationEditingContext(
            subjectID: UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"),
            configuration: nil
        )

        #expect(!same.requiresProjection(comparedWith: first))
        #expect(other.requiresProjection(comparedWith: first))
    }

    @Test("reprojecting a new context clears the previous dirty status")
    func projectionStatusDoesNotLeakAcrossContexts() {
        #expect(
            MacConfigurationEditingContext.statusAfterProjection(
                isDurable: true
            ) == .saved
        )
        #expect(
            MacConfigurationEditingContext.statusAfterProjection(
                isDurable: false
            ) == .idle
        )
    }

    @MainActor
    @Test("draft undo and redo stay inside the current editing session")
    func draftUndoRedoRoundTrip() {
        let firstDraft = MemoryCardEditorDraft(items: [.text("第一段")])
        let secondDraft = MemoryCardEditorDraft(items: [.text("第二段")])
        let first = MacConfigurationDraftSnapshot(
            regionDraftsByPresentationStyle: [.classicWhite: [.slotA: firstDraft]]
        )
        let second = MacConfigurationDraftSnapshot(
            regionDraftsByPresentationStyle: [.classicWhite: [.slotA: secondDraft]]
        )
        let history = MacConfigurationUndoCoordinator()
        history.reset(to: first)
        history.record(before: first, after: second)

        #expect(history.canUndo)
        #expect(!history.canRedo)
        #expect(history.undo() == first)
        #expect(history.canRedo)
        #expect(history.redo() == second)
    }

    @MainActor
    @Test("a new draft edit clears redo history")
    func newDraftEditClearsRedoHistory() {
        let first = MacConfigurationDraftSnapshot(
            regionDraftsByPresentationStyle: [.classicWhite: [.slotA: .init(items: [.text("一")])]]
        )
        let second = MacConfigurationDraftSnapshot(
            regionDraftsByPresentationStyle: [.classicWhite: [.slotA: .init(items: [.text("二")])]]
        )
        let third = MacConfigurationDraftSnapshot(
            regionDraftsByPresentationStyle: [.classicWhite: [.slotA: .init(items: [.text("三")])]]
        )
        let history = MacConfigurationUndoCoordinator()
        history.reset(to: first)
        history.record(before: first, after: second)
        #expect(history.undo() == first)
        history.record(before: first, after: third)

        #expect(!history.canRedo)
        #expect(history.undo() == first)
    }

    @Test("adding a text item creates an editable empty input")
    func appendTextInputCreatesEmptyTextItem() {
        var draft = MemoryCardEditorDraft(items: [.text("已有内容")])

        let itemID = draft.appendTextInput()

        #expect(draft.items.last?.id == itemID)
        #expect(draft.items.last?.kind == .text)
        #expect(draft.items.last?.value == "")
    }

    @Test("a Mac module draft retains its canonical token for saving")
    func moduleDraftRetainsCanonicalToken() {
        var draft = MemoryCardEditorDraft(items: [.text("")])
        draft.appendComposedItem(
            .token(
                "拍摄时间",
                value: "2026年9月10日",
                templateValue: "{{capture_time}}",
                systemImage: "calendar"
            )
        )

        #expect(draft.singleLineTemplateText.contains("{{capture_time}}"))
    }

    @MainActor
    @Test("time display uses the shared repository round trip")
    func timeDisplayRoundTripsThroughSharedRepository() {
        let suiteName = "MacConfigurationEditingContextTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let repository = SettingsRepository(
            settingsService: SettingsService(defaults: defaults)
        )
        let expected = TimeDisplayInspectorPresenter.configuration(
            baseStyle: .photography,
            supplement: .lunarAndSolarTerm
        )

        repository.saveTimeDisplayConfiguration(expected)

        #expect(repository.loadTimeDisplayConfiguration() == expected)
    }

    @MainActor
    @Test("inserted module survives candidate save, reconciliation, and reload")
    func insertedModuleSurvivesDurableRoundTrip() async throws {
        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacConfigurationEditingContextTests")
            .appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: rootURL) }

        let subject = ConfigurationCenterMockSeed.makeState().subjects[0]
        let initialDraft = Self.makeDraft()
        var initialConfiguration =
            ConfigurationAggregateCandidateBuilder.seedConfiguration(
                id: UUID(),
                draft: initialDraft
            )
        initialConfiguration.revision = 1
        let aggregate = ConfigurationLibraryRecord(
            revision: 1,
            subjects: [
                SubjectConfigurationRecord(
                    subject: subject,
                    configurations: [initialConfiguration],
                    assetManifest: .init(entries: [])
                )
            ],
            activeSubjectID: subject.id,
            activeConfigurationID: initialConfiguration.id
        )

        let storage = FileConfigurationLibraryStorage(
            baseDirectoryURL: rootURL,
            legacyDefaults: nil
        )
        let repository = ConfigurationLibraryRepository(
            persistence: ConfigurationLibraryPersistence(storage: storage)
        )
        _ = try await repository.save(aggregate)

        let projection = ConfigurationDraftProjection(
            configuration: initialConfiguration
        )
        var styleDrafts = projection.regionDraftsByPresentationStyle
        var classicDrafts =
            styleDrafts[.classicWhite] ?? projection.regionDrafts
        var recorderDraft =
            classicDrafts[.slotA]
            ?? MemoryCardEditorDraft(items: [.text("")])
        recorderDraft.appendComposedItem(
            .token(
                IOSInsertableModule.cameraModel.title,
                value: "iPhone 17 Pro Max",
                templateValue:
                    IOSInsertableModule.cameraModel.rendererToken,
                systemImage: IOSInsertableModule.cameraModel.systemImage
            )
        )
        classicDrafts[.slotA] = recorderDraft
        styleDrafts[.classicWhite] = classicDrafts

        let candidate = try ConfigurationAggregateCandidateBuilder.build(
            from: aggregate,
            draft: Self.makeDraft(
                from: projection,
                styleDrafts: styleDrafts
            )
        )
        let receipt = try await repository.save(candidate.aggregate)

        var editingState = ConfigurationEditingState(
            state: .mock
        )
        let reconciler = ConfigurationPersistenceReconciler()
        reconciler.restoreConfigurationLibrary(
            aggregate,
            editingState: &editingState
        )
        let outcome = reconciler.reconcileConfigurationLibrarySave(
            candidate: candidate,
            receipt: receipt,
            editingState: &editingState
        )
        #expect(outcome == .applied)

        let reconciledConfiguration = try #require(
            editingState.state.configurationLibrary?
                .subjects.first?.configurations.first
        )
        let reloadedReceipt = try await repository.load()
        let reloadedConfiguration = try #require(
            reloadedReceipt.aggregate.subjects.first?.configurations.first
        )

        for configuration in [
            reconciledConfiguration,
            reloadedConfiguration
        ] {
            let reloadedProjection = ConfigurationDraftProjection(
                configuration: configuration
            )
            #expect(
                reloadedProjection.regionDrafts[.slotA]?.items.contains {
                    $0.templateValue
                        == IOSInsertableModule.cameraModel.rendererToken
                } == true
            )
        }
    }

    private static func makeDraft(
        from projection: ConfigurationDraftProjection? = nil,
        styleDrafts:
            [RecordCardPresentationStyle: [CardRegion: MemoryCardEditorDraft]]
            = [:]
    ) -> ConfigurationAggregateDraft {
        let resolvedProjection = projection
        let defaultRegionDrafts: [CardRegion: MemoryCardEditorDraft] = [
            .slotA: MemoryCardEditorDraft(items: [.text("记录")]),
            .slotB: MemoryCardEditorDraft(items: [.text("时间")]),
            .slotC: MemoryCardEditorDraft(items: [.text("地点")]),
            .slotD: MemoryCardEditorDraft(items: [.text("回忆")])
        ]
        let resolvedStyleDrafts = styleDrafts.isEmpty
            ? [.classicWhite: defaultRegionDrafts]
            : styleDrafts

        return ConfigurationAggregateDraft(
            title: resolvedProjection?.title ?? "Mac 回归配置",
            regionDrafts:
                resolvedStyleDrafts[resolvedProjection?.route ?? .classicWhite]
                ?? resolvedProjection?.regionDrafts
                ?? defaultRegionDrafts,
            regionDraftsByPresentationStyle: resolvedStyleDrafts,
            regionTemplateIDs:
                resolvedProjection?.regionTemplateIDs ?? [:],
            locationConfiguration:
                resolvedProjection?.locationConfiguration,
            logoMode: resolvedProjection?.logoMode ?? .appleMini,
            badge: resolvedProjection?.badge ?? .appleClassic,
            usesCustomMemoryWriteText:
                resolvedProjection?.usesCustomMemoryWriteText ?? false,
            customMemoryWriteText:
                resolvedProjection?.customMemoryWriteText ?? "",
            shouldWritePhotosDescription:
                resolvedProjection?.shouldWritePhotosDescription ?? true,
            photosDescriptionOverride:
                resolvedProjection?.photosDescriptionOverride ?? "",
            outputTarget: resolvedProjection?.outputTarget ?? .automatic,
            selectedAlbumIdentifier:
                resolvedProjection?.selectedAlbumIdentifier ?? "",
            albumTitle: resolvedProjection?.albumTitle ?? "",
            mediaOutputMode:
                resolvedProjection?.mediaOutputMode ?? .originalFormat,
            livePhotoPolicy:
                resolvedProjection?.livePhotoPolicy ?? .preserveMotion,
            presentationRoute:
                resolvedProjection?.route ?? .classicWhite,
            selectedTimeAnchorID:
                resolvedProjection?.selectedTimeAnchorID,
            savedAt: Date(timeIntervalSince1970: 200),
            language: resolvedProjection?.language ?? .simplifiedChinese
        )
    }
}
#endif
