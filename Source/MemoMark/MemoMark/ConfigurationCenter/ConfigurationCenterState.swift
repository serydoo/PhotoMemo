#if !MEMOMARK_SHARE_EXTENSION
import Foundation

struct ConfigurationCenterState:
    Hashable {

    var subjects: [MemorySubject]
    var selectedSubjectID: MemorySubject.ID?
    var memoryPresets: [MemoryPreset]
    var selectedMemoryPresetID: MemoryPreset.ID?
    var configurationLibrary: ConfigurationLibraryRecord? = nil
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
            return nil
        }

        return memoryPresets.first {
            $0.id == selectedMemoryPresetID
        }
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
    var logoMode: ConfigurationLogoMode
    var usesCustomMemoryWriteText: Bool
    var customMemoryWriteText: String
    var savedOutputConfiguration:
        SavedOutputConfigurationSchemaV1?
    var language: MemoMarkLanguage

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
        logoMode: ConfigurationLogoMode = .appleMini,
        usesCustomMemoryWriteText: Bool = false,
        customMemoryWriteText: String = "",
        savedOutputConfiguration:
            SavedOutputConfigurationSchemaV1? = nil,
        language: MemoMarkLanguage = .simplifiedChinese
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
        self.language = language
    }

    func templateID(
        for region: CardRegion
    ) -> String? {
        regionTemplateIDs[region]
    }

    func replacingID(
        with id: UUID
    ) -> MemoryPreset {
        MemoryPreset(
            id: id,
            title: title,
            summary: summary,
            regionTemplateIDs: regionTemplateIDs,
            savedAt: savedAt,
            selectedSubjectID: selectedSubjectID,
            selectedTimeAnchorID: selectedTimeAnchorID,
            outputOption: outputOption,
            storageOption: storageOption,
            logoMode: logoMode,
            usesCustomMemoryWriteText:
                usesCustomMemoryWriteText,
            customMemoryWriteText:
                customMemoryWriteText,
            savedOutputConfiguration:
                savedOutputConfiguration,
            language: language
        )
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case summary
        case regionTemplateIDs
        case savedAt
        case selectedSubjectID
        case selectedTimeAnchorID
        case outputOption
        case storageOption
        case logoMode
        case usesCustomMemoryWriteText
        case customMemoryWriteText
        case savedOutputConfiguration
        case language
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        summary = try container.decode(String.self, forKey: .summary)
        regionTemplateIDs = try container.decode([CardRegion: String].self, forKey: .regionTemplateIDs)
        savedAt = try container.decodeIfPresent(Date.self, forKey: .savedAt)
        selectedSubjectID = try container.decodeIfPresent(MemorySubject.ID.self, forKey: .selectedSubjectID)
        selectedTimeAnchorID = try container.decodeIfPresent(UUID.self, forKey: .selectedTimeAnchorID)
        outputOption = try container.decode(ConfigurationOutputOption.self, forKey: .outputOption)
        storageOption = try container.decode(ConfigurationStorageOption.self, forKey: .storageOption)
        logoMode = try container.decode(ConfigurationLogoMode.self, forKey: .logoMode)
        usesCustomMemoryWriteText = try container.decode(Bool.self, forKey: .usesCustomMemoryWriteText)
        customMemoryWriteText = try container.decode(String.self, forKey: .customMemoryWriteText)
        savedOutputConfiguration = try container.decodeIfPresent(SavedOutputConfigurationSchemaV1.self, forKey: .savedOutputConfiguration)
        language = try container.decodeIfPresent(MemoMarkLanguage.self, forKey: .language) ?? .simplifiedChinese
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(summary, forKey: .summary)
        try container.encode(regionTemplateIDs, forKey: .regionTemplateIDs)
        try container.encodeIfPresent(savedAt, forKey: .savedAt)
        try container.encodeIfPresent(selectedSubjectID, forKey: .selectedSubjectID)
        try container.encodeIfPresent(selectedTimeAnchorID, forKey: .selectedTimeAnchorID)
        try container.encode(outputOption, forKey: .outputOption)
        try container.encode(storageOption, forKey: .storageOption)
        try container.encode(logoMode, forKey: .logoMode)
        try container.encode(usesCustomMemoryWriteText, forKey: .usesCustomMemoryWriteText)
        try container.encode(customMemoryWriteText, forKey: .customMemoryWriteText)
        try container.encodeIfPresent(savedOutputConfiguration, forKey: .savedOutputConfiguration)
        try container.encode(language, forKey: .language)
    }
}

/// Historical saved-output Codable payload embedded in legacy presets.
/// The schema label is explicit; field names and encoding remain unchanged.
struct SavedOutputConfigurationSchemaV1:
    Codable,
    Hashable {

    var outputTarget: ConfigurationOutputTarget
    var mediaOutputMode: MediaOutputMode
    var selectedExistingAlbumIdentifier: String
    var newAlbumName: String

    init(
        outputTarget: ConfigurationOutputTarget,
        mediaOutputMode: MediaOutputMode,
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

@available(*, deprecated, renamed: "SavedOutputConfigurationSchemaV1")
typealias V1SavedOutputConfiguration = SavedOutputConfigurationSchemaV1
#endif
