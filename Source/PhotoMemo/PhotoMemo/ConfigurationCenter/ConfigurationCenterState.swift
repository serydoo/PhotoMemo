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
    Codable,
    Hashable {

    let id: UUID
    var title: String
    var summary: String
    var regionTemplateIDs: [CardRegion: String]
    var savedAt: Date?
    var selectedSubjectID: MemorySubject.ID?
    var selectedTimeAnchorID: UUID?
    var outputOption: ConfigurationOutputOption
    var storageOption: ConfigurationStorageOption
    var logoMode: V1LogoMode
    var usesCustomMemoryWriteText: Bool
    var customMemoryWriteText: String
    var savedOutputConfiguration:
        V1SavedOutputConfiguration?

    init(
        id: UUID = UUID(),
        title: String,
        summary: String,
        regionTemplateIDs: [CardRegion: String],
        savedAt: Date? = nil,
        selectedSubjectID: MemorySubject.ID? = nil,
        selectedTimeAnchorID: UUID? = nil,
        outputOption: ConfigurationOutputOption = .processedImage,
        storageOption: ConfigurationStorageOption = .appFolder,
        logoMode: V1LogoMode = .appleMini,
        usesCustomMemoryWriteText: Bool = false,
        customMemoryWriteText: String = "",
        savedOutputConfiguration:
            V1SavedOutputConfiguration? = nil
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.regionTemplateIDs = regionTemplateIDs
        self.savedAt = savedAt
        self.selectedSubjectID = selectedSubjectID
        self.selectedTimeAnchorID = selectedTimeAnchorID
        self.outputOption = outputOption
        self.storageOption = storageOption
        self.logoMode = logoMode
        self.usesCustomMemoryWriteText = usesCustomMemoryWriteText
        self.customMemoryWriteText = customMemoryWriteText
        self.savedOutputConfiguration =
            savedOutputConfiguration
    }

    func templateID(
        for region: CardRegion
    ) -> String? {
        regionTemplateIDs[region]
    }
}

struct V1SavedOutputConfiguration:
    Codable,
    Hashable {

    var outputTarget: V1IOSOutputTarget
    var mediaOutputMode: V1MediaOutputMode
    var selectedExistingAlbumIdentifier: String
    var newAlbumName: String

    init(
        outputTarget: V1IOSOutputTarget,
        mediaOutputMode: V1MediaOutputMode,
        selectedExistingAlbumIdentifier: String,
        newAlbumName: String
    ) {
        self.outputTarget = outputTarget
        self.mediaOutputMode = mediaOutputMode
        self.selectedExistingAlbumIdentifier =
            selectedExistingAlbumIdentifier
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
        self.newAlbumName =
            newAlbumName
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
    }
}
#endif
