#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct V1ConfigurationApplyBuildInput: Hashable {

    let selectedSubject: MemorySubject?
    let subjects: [MemorySubject]
    let selectedSubjectID: MemorySubject.ID?
    let shouldSaveSubjectLibrary: Bool
    let memoryPresets: [MemoryPreset]
    let selectedMemoryPresetID: MemoryPreset.ID?
    let presetTitle: String
    let templateTextsByRegion: [CardRegion: String]
    let locationDisplayConfiguration:
        ExpressionModuleConfiguration?
    let badge: Badge?
    let usesCustomMemoryWriteText: Bool
    let customMemoryWriteText: String
    let birthdayDate: Date
    let outputTarget: V1IOSOutputTarget
    let mediaOutputMode:
        V1MediaOutputMode
    let availableAlbums: [PhotoAlbumOption]
    let selectedExistingAlbumIdentifier: String
    let newAlbumName: String
}

struct V1ConfigurationApplyResultPatch: Hashable {

    let shouldReloadAlbums: Bool
    let outputTarget: V1IOSOutputTarget?
    let selectedExistingAlbumIdentifier: String?
    let subjectToRestore: MemorySubject?
    let shouldApplySelectedMemoryPreset: Bool
    let activeConfigurationStatus:
        V1ConfigurationStatus
    let isSavingConfiguration: Bool
}

enum V1ConfigurationApplyRequestBuilder {

    static func buildRequest(
        from input: V1ConfigurationApplyBuildInput
    ) -> V1ConfigurationApplyRequest {
        let resolvedAnchorDate =
            input
            .selectedSubject?
            .primaryTimeAnchor?
            .date
            ?? input.birthdayDate
        let subjectForSaving =
            alignedSelectedSubject(
                from: input.selectedSubject,
                birthdayDate: resolvedAnchorDate
            )

        return V1ConfigurationApplyRequest(
            subject: subjectForSaving,
            subjects:
                resolvedSubjectsForSaving(
                    subjectForSaving,
                    subjects: input.subjects
                ),
            selectedSubjectID:
                subjectForSaving?.id
                ?? input.selectedSubjectID,
            shouldSaveSubjectLibrary:
                input.shouldSaveSubjectLibrary,
            memoryPresets:
                input.memoryPresets,
            selectedMemoryPresetID:
                input.selectedMemoryPresetID,
            template:
                Template(
                    preset: .immersWhite,
                    name: input.presetTitle,
                    leftTopArea:
                        templateArea(
                            name: "Recorder",
                            value:
                                input
                                .templateTextsByRegion[
                                    .slotA
                                ] ?? ""
                        ),
                    leftBottomArea:
                        templateArea(
                            name: "Timeline",
                            value:
                                input
                                .templateTextsByRegion[
                                    .slotB
                                ] ?? ""
                        ),
                    rightTopArea:
                        templateArea(
                            name: "Capture Summary",
                            value:
                                input
                                .templateTextsByRegion[
                                    .slotC
                                ] ?? ""
                        ),
                    rightBottomArea:
                        templateArea(
                            name: "Memory",
                            value:
                                input
                                .templateTextsByRegion[
                                    .slotD
                                ] ?? ""
                        ),
                    badgeArea: .badge
                ),
            badge: input.badge,
            locationDisplayConfiguration:
                input.locationDisplayConfiguration,
            shouldWritePhotoDescription:
                true,
            photoDescriptionOverride:
                input.usesCustomMemoryWriteText
                ? input.customMemoryWriteText
                : "",
            timeAnchorTitle:
                V1ResolvedMemoryWriteTextPresenter
                .legacyBirthdayAnchorTitle(
                    subject: subjectForSaving
                        ?? input.selectedSubject
                ),
            timeAnchorDate:
                resolvedAnchorDate,
            outputTarget:
                input.outputTarget,
            mediaOutputMode:
                input.mediaOutputMode,
            availableAlbums:
                input.availableAlbums,
            selectedExistingAlbumIdentifier:
                input
                .selectedExistingAlbumIdentifier,
            newAlbumName:
                input.newAlbumName
        )
    }

    static func alignedSelectedSubject(
        from selectedSubject: MemorySubject?,
        birthdayDate: Date
    ) -> MemorySubject? {
        guard
            var subject =
                selectedSubject
        else {
            return nil
        }

        if let activeAnchorID =
            subject.activeTimeAnchorID,
           let activeAnchorIndex =
            subject.timeAnchors.firstIndex(
                where: {
                    $0.id == activeAnchorID
                }
            ) {
            subject.timeAnchors[activeAnchorIndex].date =
                birthdayDate
            subject.behavior.primaryAnchor =
                subject.timeAnchors[activeAnchorIndex]
                .title
            subject.referenceDate = birthdayDate
            return subject
        }

        if let primaryAnchorIndex =
            subject.timeAnchors.firstIndex(
                where: {
                    $0.title == subject.behavior.primaryAnchor
                }
            ) {
            subject.timeAnchors[primaryAnchorIndex].date =
                birthdayDate
            subject.referenceDate = birthdayDate
            return subject
        }

        subject.referenceDate = birthdayDate
        return subject
    }

    private static func resolvedSubjectsForSaving(
        _ selectedSubject: MemorySubject?,
        subjects: [MemorySubject]
    ) -> [MemorySubject] {
        guard let selectedSubject else {
            return subjects
        }

        return V1SubjectLibraryResolver
            .subjectsForSaving(
                selectedSubject:
                    selectedSubject,
                subjects: subjects
            )
    }

    private static func templateArea(
        name: String,
        value: String
    ) -> TemplateArea {
        let trimmedValue =
            value.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return TemplateArea(
            name: name,
            items: [
                TemplateItem(
                    type: .variable,
                    name: name,
                    value: trimmedValue,
                    isEnabled:
                        !trimmedValue.isEmpty
                )
            ]
        )
    }
}

enum V1ConfigurationApplyResultPresenter {

    static func successPatch(
        receipt: V1ConfigurationApplyReceipt,
        outputTarget: V1IOSOutputTarget,
        subjectForSaving: MemorySubject?
    ) -> V1ConfigurationApplyResultPatch {
        let pickerSelectionIdentifier =
            outputTarget == .newAlbum
            ? receipt.albumSelection
                .pickerSelectionIdentifier
            : nil

        return V1ConfigurationApplyResultPatch(
            shouldReloadAlbums:
                pickerSelectionIdentifier != nil,
            outputTarget:
                pickerSelectionIdentifier != nil
                ? .existingAlbum
                : nil,
            selectedExistingAlbumIdentifier:
                pickerSelectionIdentifier,
            subjectToRestore:
                subjectForSaving,
            shouldApplySelectedMemoryPreset:
                true,
            activeConfigurationStatus:
                .saved,
            isSavingConfiguration: false
        )
    }

    static func failurePatch(
        error: PhotoMemoError
    ) -> V1ConfigurationApplyResultPatch {
        V1ConfigurationApplyResultPatch(
            shouldReloadAlbums: false,
            outputTarget: nil,
            selectedExistingAlbumIdentifier:
                nil,
            subjectToRestore: nil,
            shouldApplySelectedMemoryPreset:
                false,
            activeConfigurationStatus:
                .failure(
                    message:
                        error.message
                ),
            isSavingConfiguration: false
        )
    }
}
#endif
