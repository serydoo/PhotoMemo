#if !MEMOMARK_SHARE_EXTENSION
import Foundation

struct ConfigurationSavePayload {
    /// Compatibility projection for installations that have not yet produced
    /// a durable configuration aggregate. The active Configuration Center
    /// must select this path explicitly; it is never an aggregate-save
    /// fallback.
    let legacyCompatibilityRequest: SaveConfigurationCommand
    let aggregateDraft: ConfigurationAggregateDraft
    let configurationLibrary: ConfigurationLibraryRecord?
}

struct ConfigurationSavePayloadInput {
    let state: ConfigurationCenterState
    let shouldSaveSubjectLibrary: Bool
    let persistenceMemoryPresets: [MemoryPreset]
    let persistenceSelectedMemoryPresetID: MemoryPreset.ID
    let title: String
    let regionDrafts: [CardRegion: MemoryCardEditorDraft]
    let regionDraftsByPresentationStyle:
        [RecordCardPresentationStyle: [CardRegion: MemoryCardEditorDraft]]
    let regionTemplateIDs: [CardRegion: String]
    let locationConfiguration: ExpressionModuleConfiguration?
    let logoMode: ConfigurationLogoMode
    let badge: Badge
    let usesCustomMemoryWriteText: Bool
    let customMemoryWriteText: String
    let shouldWritePhotosDescription: Bool
    let photosDescriptionOverride: String
    let birthdayDate: Date
    let outputTarget: ConfigurationOutputTarget
    let mediaOutputMode: MediaOutputMode
    let availableAlbums: [PhotoAlbumOption]
    let selectedAlbumIdentifier: String
    let newAlbumName: String
    let configurationAlbumTitle: String
    let livePhotoPolicy:
        MemoryConfigurationRecord.Output.LivePhotoPolicy
    let presentationRoute:
        MemoryConfigurationRecord.Presentation.Route
    let selectedTimeAnchorID: UUID?
    let language: MemoMarkLanguage
    let savedAt: Date
}

enum ConfigurationSavePayloadBuilder {

    static func build(
        from input: ConfigurationSavePayloadInput
    ) -> ConfigurationSavePayload {
        // The two legacy output fields remain in the payload shape so older
        // snapshots and callers continue to decode. They are intentionally
        // canonicalized here: the source asset, not a hidden stale setting,
        // owns still-versus-motion output behavior.
        let sourceCompatibleMediaOutputMode =
            MediaOutputMode.originalFormat
        let sourceCompatibleLivePhotoPolicy =
            MemoryConfigurationRecord.Output.LivePhotoPolicy
            .preserveMotion
        let legacyCompatibilityRequest = SaveConfigurationCommandBuilder
            .buildRequest(
                from: ConfigurationSaveCommandInput(
                    selectedSubject: input.state.selectedSubject,
                    subjects: input.state.subjects,
                    selectedSubjectID: input.state.selectedSubjectID,
                    shouldSaveSubjectLibrary:
                        input.shouldSaveSubjectLibrary,
                    memoryPresets:
                        input.persistenceMemoryPresets,
                    selectedMemoryPresetID:
                        input.persistenceSelectedMemoryPresetID,
                    presentationRoute: input.presentationRoute,
                    presetTitle: input.title,
                    templateTextsByRegion: input.regionDrafts
                        .mapValues(\.singleLineTemplateText),
                    locationDisplayConfiguration:
                        input.locationConfiguration,
                    badge: input.badge,
                    usesCustomMemoryWriteText:
                        input.usesCustomMemoryWriteText,
                    customMemoryWriteText:
                        input.customMemoryWriteText,
                    birthdayDate: input.birthdayDate,
                    outputTarget: input.outputTarget,
                    mediaOutputMode: sourceCompatibleMediaOutputMode,
                    availableAlbums: input.availableAlbums,
                    selectedExistingAlbumIdentifier:
                        input.selectedAlbumIdentifier,
                    newAlbumName: input.newAlbumName
                )
            )

        let aggregateDraft = ConfigurationAggregateDraft(
            title: input.title,
            regionDrafts: input.regionDrafts,
            regionDraftsByPresentationStyle:
                input.regionDraftsByPresentationStyle,
            regionTemplateIDs: input.regionTemplateIDs,
            locationConfiguration: input.locationConfiguration,
            logoMode: input.logoMode,
            badge: input.badge,
            usesCustomMemoryWriteText:
                input.usesCustomMemoryWriteText,
            customMemoryWriteText: input.customMemoryWriteText,
            shouldWritePhotosDescription:
                input.shouldWritePhotosDescription,
            photosDescriptionOverride:
                input.photosDescriptionOverride,
            outputTarget: input.outputTarget,
            selectedAlbumIdentifier:
                input.selectedAlbumIdentifier,
            albumTitle: input.outputTarget == .newAlbum
                ? input.newAlbumName
                : input.configurationAlbumTitle,
            mediaOutputMode: sourceCompatibleMediaOutputMode,
            livePhotoPolicy: sourceCompatibleLivePhotoPolicy,
            presentationRoute: input.presentationRoute,
            selectedTimeAnchorID: input.selectedTimeAnchorID,
            savedAt: input.savedAt,
            language: input.language
        )

        let configurationLibrary: ConfigurationLibraryRecord?
        if let configurationID = input.state.selectedMemoryPresetID,
           let subject = input.state.selectedSubject {
            configurationLibrary = LocalConfigurationLibraryPresenter
                .preparingCurrentConfiguration(
                    configurationID,
                    subject: subject,
                    seedConfiguration:
                        ConfigurationAggregateCandidateBuilder
                        .seedConfiguration(
                            id: configurationID,
                            draft: aggregateDraft
                        ),
                    in: input.state.configurationLibrary
                )
        } else {
            configurationLibrary = input.state.configurationLibrary
        }

        return ConfigurationSavePayload(
            legacyCompatibilityRequest: legacyCompatibilityRequest,
            aggregateDraft: aggregateDraft,
            configurationLibrary: configurationLibrary
        )
    }
}
#endif
