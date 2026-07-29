#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct V1ConfigurationApplyPayload {
    let legacyRequest: V1ConfigurationApplyRequest
    let aggregateDraft: V1ConfigurationAggregateDraft
    let configurationLibrary: ConfigurationLibraryRecord?
}

struct V1ConfigurationApplyPayloadInput {
    let state: ConfigurationCenterState
    let shouldSaveSubjectLibrary: Bool
    let persistenceMemoryPresets: [MemoryPreset]
    let persistenceSelectedMemoryPresetID: MemoryPreset.ID
    let title: String
    let regionDrafts: [CardRegion: V1EditorDraft]
    let regionTemplateIDs: [CardRegion: String]
    let locationConfiguration: ExpressionModuleConfiguration?
    let logoMode: V1LogoMode
    let badge: Badge
    let usesCustomMemoryWriteText: Bool
    let customMemoryWriteText: String
    let shouldWritePhotosDescription: Bool
    let photosDescriptionOverride: String
    let birthdayDate: Date
    let outputTarget: V1IOSOutputTarget
    let mediaOutputMode: V1MediaOutputMode
    let availableAlbums: [PhotoAlbumOption]
    let selectedAlbumIdentifier: String
    let newAlbumName: String
    let configurationAlbumTitle: String
    let livePhotoPolicy:
        MemoryConfigurationRecord.Output.LivePhotoPolicy
    let selectedTimeAnchorID: UUID?
    let language: MemoMarkLanguage
    let savedAt: Date
}

enum V1ConfigurationApplyPayloadBuilder {

    static func build(
        from input: V1ConfigurationApplyPayloadInput
    ) -> V1ConfigurationApplyPayload {
        let legacyRequest = V1ConfigurationApplyRequestBuilder
            .buildRequest(
                from: V1ConfigurationApplyBuildInput(
                    selectedSubject: input.state.selectedSubject,
                    subjects: input.state.subjects,
                    selectedSubjectID: input.state.selectedSubjectID,
                    shouldSaveSubjectLibrary:
                        input.shouldSaveSubjectLibrary,
                    memoryPresets:
                        input.persistenceMemoryPresets,
                    selectedMemoryPresetID:
                        input.persistenceSelectedMemoryPresetID,
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
                    mediaOutputMode: input.mediaOutputMode,
                    availableAlbums: input.availableAlbums,
                    selectedExistingAlbumIdentifier:
                        input.selectedAlbumIdentifier,
                    newAlbumName: input.newAlbumName
                )
            )

        let aggregateDraft = V1ConfigurationAggregateDraft(
            title: input.title,
            regionDrafts: input.regionDrafts,
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
            mediaOutputMode: input.mediaOutputMode,
            livePhotoPolicy: input.livePhotoPolicy,
            selectedTimeAnchorID: input.selectedTimeAnchorID,
            savedAt: input.savedAt,
            language: input.language
        )

        let configurationLibrary: ConfigurationLibraryRecord?
        if let configurationID = input.state.selectedMemoryPresetID,
           let subject = input.state.selectedSubject {
            configurationLibrary = V1LocalConfigurationLibraryPresenter
                .preparingCurrentConfiguration(
                    configurationID,
                    subject: subject,
                    seedConfiguration:
                        V1ConfigurationAggregateCandidateBuilder
                        .seedConfiguration(
                            id: configurationID,
                            draft: aggregateDraft
                        ),
                    in: input.state.configurationLibrary
                )
        } else {
            configurationLibrary = input.state.configurationLibrary
        }

        return V1ConfigurationApplyPayload(
            legacyRequest: legacyRequest,
            aggregateDraft: aggregateDraft,
            configurationLibrary: configurationLibrary
        )
    }
}
#endif
