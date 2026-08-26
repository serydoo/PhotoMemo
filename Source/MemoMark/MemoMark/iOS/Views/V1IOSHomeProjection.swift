#if !MEMOMARK_SHARE_EXTENSION
import Foundation

struct V1IOSHomeSubjectSummaryProjection: Equatable {
    let title: String
    let subtitle: String
    let anchorTitle: String
}

struct V1IOSHomeOutputSummaryProjection: Equatable {
    let title: String
    let detail: String
    let memoryWriteLabel: String
    let targetNote: String
    let memoryWriteDetail: String
}

struct V1IOSHomePresetSummaryProjection: Equatable {
    let title: String
    let subtitle: String
    let detail: String
    let statusLabel: String
    let emphasizesAppliedState: Bool
}

enum V1IOSHomeProjection {

    static func subjectSummary(
        subject: MemorySubject?,
        selectedAnchorTitle: String?,
        language: MemoMarkLanguage = .interfaceStored
    ) -> V1IOSHomeSubjectSummaryProjection {

        let title =
            subjectTitle(
                subject,
                language: language
            )

        let subtitle =
            normalizedSubjectSubtitle(
                subject,
                language: language
            )

        let anchorTitle =
            normalizedAnchorTitle(
                subject?
                .primaryTimeAnchor?
                .title
                ?? selectedAnchorTitle,
                language: language
            )

        return V1IOSHomeSubjectSummaryProjection(
            title: title,
            subtitle: subtitle,
            anchorTitle: anchorTitle
        )
    }

    static func outputSummary(
        outputTarget: V1IOSOutputTarget,
        selectedExistingAlbumTitle: String,
        newAlbumName: String,
        writesMemoryDescription: Bool,
        language: MemoMarkLanguage = .interfaceStored
    ) -> V1IOSHomeOutputSummaryProjection {

        V1IOSHomeOutputSummaryProjection(
            title: outputTarget.title,
            detail:
                normalizedOutputDetail(
                    outputTarget: outputTarget,
                    selectedExistingAlbumTitle:
                        selectedExistingAlbumTitle,
                    newAlbumName: newAlbumName,
                    language: language
                ),
            memoryWriteLabel:
                writesMemoryDescription
                ? language.localized(
                    key: "legacy.home.output.memory_write.enabled",
                    fallback: "Photo description enabled"
                )
                : language.localized(
                    key: "legacy.home.output.memory_write.disabled",
                    fallback: "Photo description disabled"
                ),
            targetNote:
                localizedOutputTargetNote(
                    outputTarget,
                    language: language
                ),
            memoryWriteDetail:
                writesMemoryDescription
                ? language.localized(
                    key: "legacy.home.output.memory_write.detail.enabled",
                    fallback: "The result will include the current Memory Expression."
                )
                : language.localized(
                    key: "legacy.home.output.memory_write.detail.disabled",
                    fallback: "The result will not include additional description text."
                )
        )
    }

    static func presetSummary(
        presetTitle: String,
        configurationLabel: String,
        presetSummary: String,
        activeConfigurationStatus:
            V1ConfigurationStatus,
        isApplied: Bool,
        language: MemoMarkLanguage = .interfaceStored
    ) -> V1IOSHomePresetSummaryProjection {

        return V1IOSHomePresetSummaryProjection(
            title:
                normalizedOptionalText(
                    presetTitle
                )
                ?? language.localized(
                    key: "legacy.home.preset.title",
                    fallback: "Memory Preset"
                ),
            subtitle:
                normalizedOptionalText(
                    configurationLabel
                )
                ?? language.localized(
                    key: "legacy.home.preset.subtitle",
                    fallback: "Active Configuration"
                ),
            detail:
                normalizedOptionalText(
                    presetSummary
                )
                ?? language.localized(
                    key: "legacy.home.preset.detail",
                    fallback: "Active configuration summary"
                ),
            statusLabel:
                isApplied
                ? language.localized(
                    key: "legacy.home.preset.status.applied",
                    fallback: "Applied"
                )
                : language.localized(
                    key: "legacy.home.preset.status.pending",
                    fallback: "Changes not saved"
                ),
            emphasizesAppliedState:
                isApplied
        )
    }

    static func emptyPresetSummary(
        configurationLabel: String,
        language: MemoMarkLanguage = .interfaceStored
    ) -> V1IOSHomePresetSummaryProjection {

        V1IOSHomePresetSummaryProjection(
            title: language.localized(
                key: "legacy.home.preset.empty.title",
                fallback: "This subject has no configuration yet"
            ),
            subtitle:
                normalizedOptionalText(
                    configurationLabel
                )
                ?? language.localized(
                    key: "legacy.home.preset.subtitle",
                    fallback: "Active Configuration"
                ),
            detail: language.localized(
                key: "legacy.home.preset.empty.detail",
                fallback: "Create a configuration at the bottom of Configuration Center, then select it here."
            ),
            statusLabel: language.localized(
                key: "legacy.home.preset.status.waiting",
                fallback: "Waiting for configuration"
            ),
            emphasizesAppliedState: false
        )
    }

    static func savedStatusValue(
        savedAt: Date?,
        timeZone: TimeZone = .autoupdatingCurrent,
        language: MemoMarkLanguage = .interfaceStored
    ) -> String {

        guard let savedAt else {
            return language.localized(
                key: "home.preset.not_saved",
                fallback: "Not saved"
            )
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        let components =
            calendar.dateComponents(
                [.month, .day, .hour, .minute],
                from: savedAt
            )

        guard
            components.month != nil,
            components.day != nil,
            components.hour != nil,
            components.minute != nil
        else {
            return language.localized(
                key: "home.preset.not_saved",
                fallback: "Not saved"
            )
        }

        let formatter = DateFormatter()
        formatter.locale = language.locale
        formatter.timeZone = timeZone
        formatter.dateFormat = language.localized(
            key: "home.preset.saved_date_format",
            fallback: "MMM d, HH:mm"
        )
        let format = language.localized(
            key: "home.preset.saved_status_format",
            fallback: "Saved %@"
        )
        return String(
            format: format,
            locale: language.locale,
            formatter.string(from: savedAt)
        )
    }

    static func subjectTitle(
        _ subject: MemorySubject?,
        language: MemoMarkLanguage = .interfaceStored
    ) -> String {

        let displayName =
            subject?
            .identity
            .displayName
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            ) ?? ""

        if !displayName.isEmpty {
            return displayName
        }

        let shortName =
            subject?
            .identity
            .shortName
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            ) ?? ""

        if !shortName.isEmpty {
            return shortName
        }

        return language.localized(
            key: "legacy.home.subject.title",
            fallback: "Memory Subject"
        )
    }

    private static func normalizedSubjectSubtitle(
        _ subject: MemorySubject?,
        language: MemoMarkLanguage
    ) -> String {

        let relationshipLabel =
            subject?
            .relationship
            .label
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            ) ?? ""

        if !relationshipLabel.isEmpty {
            return relationshipLabel
        }

        return language.localized(
            key: "legacy.home.subject.subtitle",
            fallback: "Add subject details"
        )
    }

    private static func normalizedAnchorTitle(
        _ selectedAnchorTitle: String?,
        language: MemoMarkLanguage
    ) -> String {

        let trimmed =
            selectedAnchorTitle?
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            ) ?? ""

        if !trimmed.isEmpty {
            return trimmed
        }

        return language.localized(
            key: "legacy.home.subject.anchor.unset",
            fallback: "Not set"
        )
    }

    private static func normalizedOutputDetail(
        outputTarget: V1IOSOutputTarget,
        selectedExistingAlbumTitle: String,
        newAlbumName: String,
        language: MemoMarkLanguage
    ) -> String {

        switch outputTarget {
        case .automatic:
            return language.localized(
                key: "legacy.home.output.detail.automatic",
                fallback: "Apple Photos Library + MemoMark album"
            )
        case .applePhotos:
            return language.localized(
                key: "legacy.home.output.detail.apple_photos",
                fallback: "Apple Photos Library only"
            )
        case .existingAlbum:
            let trimmed =
                selectedExistingAlbumTitle
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

            return trimmed.isEmpty
                ? language.localized(
                    key: "legacy.home.output.detail.existing_empty",
                    fallback: "No album selected"
                )
                : trimmed
        case .newAlbum:
            let trimmed =
                newAlbumName
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

            return trimmed.isEmpty
                ? language.localized(
                    key: "legacy.home.output.detail.new_empty",
                    fallback: "Create album when saving"
                )
                : trimmed
        }
    }

    private static func localizedOutputTargetNote(
        _ outputTarget: V1IOSOutputTarget,
        language: MemoMarkLanguage
    ) -> String {
        language.localized(
            key: "legacy.home.output.note.\(outputTarget.rawValue)",
            fallback: outputTarget.note
        )
    }

    private static func normalizedOptionalText(
        _ text: String
    ) -> String? {

        let trimmed =
            text.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return trimmed.isEmpty
            ? nil
            : trimmed
    }
}

#endif
