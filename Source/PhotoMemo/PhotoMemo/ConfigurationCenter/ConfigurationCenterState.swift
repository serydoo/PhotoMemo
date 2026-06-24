#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct ConfigurationCenterState:
    Hashable {

    var subjects: [MemorySubject]
    var selectedSubjectID: MemorySubject.ID?
    var memoryPresets: [MemoryPreset]
    var selectedMemoryPresetID: MemoryPreset.ID?
    var cardSelection: CardSelection
    var selectedBlockID: MemoryBlock.ID?
    var tokenLibrary: TokenLibrary
    var availableDecorations: [DecorationAsset]
    var regionPreviewTexts: [CardRegion: String]

    var selectedSubject: MemorySubject? {
        guard let selectedSubjectID else {
            return subjects.first
        }

        return subjects.first {
            $0.id == selectedSubjectID
        } ?? subjects.first
    }

    var selectedMemoryPreset: MemoryPreset? {
        guard let selectedMemoryPresetID else {
            return memoryPresets.first
        }

        return memoryPresets.first {
            $0.id == selectedMemoryPresetID
        } ?? memoryPresets.first
    }

    var selectedRegion: CardRegion {
        get {
            cardSelection.selectedRegion
        }
        set {
            cardSelection.selectedRegion = newValue
        }
    }

    var hoveredRegion: CardRegion? {
        get {
            cardSelection.hoveredRegion
        }
        set {
            cardSelection.hoveredRegion = newValue
        }
    }
}

struct MemoryPreset:
    Identifiable,
    Hashable {

    let id: UUID
    var title: String
    var summary: String
    var regionTemplateIDs: [CardRegion: String]

    init(
        id: UUID = UUID(),
        title: String,
        summary: String,
        regionTemplateIDs: [CardRegion: String]
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.regionTemplateIDs = regionTemplateIDs
    }

    func templateID(
        for region: CardRegion
    ) -> String? {
        regionTemplateIDs[region]
    }
}
#endif
