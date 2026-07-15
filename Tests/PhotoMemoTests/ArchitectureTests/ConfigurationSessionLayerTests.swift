#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Combine
import Testing
@testable import PhotoMemo

@Suite("Configuration session responsibility layers")
struct ConfigurationSessionLayerTests {

    @Test("facade publishes editing-state mutations")
    @MainActor
    func facadePublishesEditingStateMutations() {
        let session = ConfigurationSession()
        var emissionCount = 0
        let observation = session.objectWillChange.sink {
            emissionCount += 1
        }

        session.selectRegion(.slotB)
        session.updateRegionPreview(
            region: .slotB,
            text: "新的时间线预览"
        )

        withExtendedLifetime(observation) {
            #expect(emissionCount > 0)
        }
        #expect(session.state.selectedRegion == .slotB)
        #expect(
            session.previewText(for: .slotB)
            == "新的时间线预览"
        )
    }

    @Test("editing state owns region composition and preset invalidation")
    @MainActor
    func editingStateOwnsRegionCompositionAndPresetInvalidation() throws {
        var editingState = ConfigurationEditingState(
            state: .mock
        )
        let selectedPresetID = try #require(
            editingState.state.selectedMemoryPresetID
        )

        #expect(
            editingState.appliedMemoryPresetID
            == selectedPresetID
        )

        editingState.selectRegion(.slotA)
        editingState.updateRegionPreview(
            region: .slotA,
            text: "拍摄于"
        )
        editingState.appendPreviewModule(
            title: "日期",
            value: "2026.07.16",
            token: "{{capture_date}}"
        )

        #expect(editingState.state.selectedRegion == .slotA)
        #expect(
            editingState.previewText(for: .slotA)
            == "拍摄于2026.07.16"
        )
        #expect(
            editingState.latestModuleInsertion?.token
            == "{{capture_date}}"
        )

        editingState.updateActiveTemplate(
            for: .slotA,
            templateID: "recorder.layer-test"
        )

        #expect(
            editingState.activeTemplateID(for: .slotA)
            == "recorder.layer-test"
        )
        #expect(editingState.appliedMemoryPresetID == nil)
    }

    @Test("editing state does not depend on persistence reconciliation")
    func editingStateDoesNotDependOnPersistenceReconciliation() throws {
        let source = try String(
            contentsOf:
                URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .appendingPathComponent(
                    "Source/PhotoMemo/PhotoMemo/ConfigurationCenter/ConfigurationEditingState.swift"
                ),
            encoding: .utf8
        )

        #expect(
            !source.contains(
                "ConfigurationPersistenceReconciler"
            )
        )
    }

    @Test("persistence reconciler projects candidates and preserves newer edits")
    @MainActor
    func persistenceReconcilerProjectsCandidatesAndPreservesNewerEdits() throws {
        var editingState = ConfigurationEditingState(
            state: .mock
        )
        let reconciler = ConfigurationPersistenceReconciler()
        let savedAt = Date(timeIntervalSince1970: 123)
        let output = V1SavedOutputConfiguration(
            outputTarget: .existingAlbum,
            mediaOutputMode: .originalFormat,
            selectedExistingAlbumIdentifier: "album-layer-test",
            newAlbumName: ""
        )

        editingState.selectedStorageOption = .targetAlbum
        editingState.usesCustomMemoryWriteText = true
        editingState.customMemoryWriteText = "独立持久化投影"

        let snapshot = reconciler
            .persistenceSnapshotForCurrentConfiguration(
                editingState: editingState,
                logoMode: .customUpload,
                outputConfiguration: output,
                savedAt: savedAt
            )
        let candidate = try #require(
            snapshot.memoryPresets.first {
                $0.id == snapshot.selectedMemoryPresetID
            }
        )

        #expect(candidate.savedAt == savedAt)
        #expect(candidate.storageOption == .targetAlbum)
        #expect(candidate.logoMode == .customUpload)
        #expect(candidate.usesCustomMemoryWriteText)
        #expect(candidate.customMemoryWriteText == "独立持久化投影")
        #expect(candidate.savedOutputConfiguration == output)

        editingState.updateSelectedMemoryPresetTitle(
            "等待保存期间的新标题"
        )

        let outcome = reconciler.reconcilePersistenceSnapshot(
            snapshot,
            editingState: &editingState
        )

        #expect(outcome == .newerEditsPreserved)
        #expect(
            editingState.state.selectedMemoryPreset?.title
            == "等待保存期间的新标题"
        )
        #expect(editingState.appliedMemoryPresetID == nil)
    }
}
#endif
