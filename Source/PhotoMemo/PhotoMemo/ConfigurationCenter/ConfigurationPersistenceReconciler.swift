#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

enum ConfigurationPersistenceReconciliationOutcome:
    Equatable {
    case applied
    case newerEditsPreserved
}

struct ConfigurationPersistenceSnapshot:
    Equatable {
    let memoryPresets: [MemoryPreset]
    let selectedMemoryPresetID: MemoryPreset.ID
}

struct ConfigurationPersistenceReconciler {

    func persistenceSnapshotForCurrentConfiguration(
        editingState: ConfigurationEditingState,
        logoMode: V1LogoMode? = nil,
        outputConfiguration:
            V1SavedOutputConfiguration? = nil,
        savedAt: Date = Date()
    ) -> ConfigurationPersistenceSnapshot {
        if let presetIndex =
            editingState.writableSelectedMemoryPresetIndex() {
            var memoryPresets = editingState.state.memoryPresets
            let selectedPreset = configurationSnapshot(
                in: memoryPresets[presetIndex],
                editingState: editingState,
                savedAt: savedAt,
                logoMode: logoMode,
                outputConfiguration: outputConfiguration
            )
            memoryPresets[presetIndex] = selectedPreset
            return ConfigurationPersistenceSnapshot(
                memoryPresets: memoryPresets,
                selectedMemoryPresetID: selectedPreset.id
            )
        }

        let selectedPreset = configurationSnapshot(
            in: MemoryPreset(
                title:
                    editingState.currentDefaultMemoryPresetTitle,
                summary:
                    editingState.state.selectedMemoryPreset?
                    .summary
                    ?? "当前区域组合",
                regionTemplateIDs:
                    editingState.currentRegionTemplateIDs
            ),
            editingState: editingState,
            savedAt: savedAt,
            logoMode: logoMode,
            outputConfiguration: outputConfiguration
        )
        return ConfigurationPersistenceSnapshot(
            memoryPresets:
                editingState.state.memoryPresets
                + [selectedPreset],
            selectedMemoryPresetID: selectedPreset.id
        )
    }

    @discardableResult
    func reconcilePersistenceSnapshot(
        _ snapshot: ConfigurationPersistenceSnapshot,
        editingState: inout ConfigurationEditingState,
        configurationID: UUID? = nil,
        configurationRevision: Int? = nil
    ) -> ConfigurationPersistenceReconciliationOutcome {
        let selectedMemoryPresetID =
            snapshot.selectedMemoryPresetID
        guard let selectedPreset =
            snapshot.memoryPresets.first(where: {
                $0.id == selectedMemoryPresetID
            })
        else {
            return .newerEditsPreserved
        }

        if let currentPresetIndex =
            editingState.state.memoryPresets.firstIndex(where: {
                $0.id == selectedMemoryPresetID
            }) {
            let currentPersistenceCandidate =
                configurationSnapshot(
                    in: editingState.state
                        .memoryPresets[currentPresetIndex],
                    editingState: editingState,
                    savedAt: selectedPreset.savedAt,
                    logoMode: selectedPreset.logoMode,
                    outputConfiguration:
                        selectedPreset.savedOutputConfiguration
                )

            guard currentPersistenceCandidate == selectedPreset else {
                editingState.state.selectedMemoryPresetID =
                    selectedMemoryPresetID
                editingState.appliedMemoryPresetID = nil
                return .newerEditsPreserved
            }

            editingState.state.memoryPresets[currentPresetIndex] =
                selectedPreset.replacingID(
                    with: configurationID
                        ?? selectedMemoryPresetID
                )
        } else {
            editingState.state.memoryPresets.append(
                selectedPreset.replacingID(
                    with: configurationID
                        ?? selectedMemoryPresetID
                )
            )
        }

        let reconciledConfigurationID =
            configurationID ?? selectedMemoryPresetID
        editingState.state.selectedMemoryPresetID =
            reconciledConfigurationID
        editingState.appliedMemoryPresetID =
            reconciledConfigurationID
        reconcileConfigurationLibraryIdentity(
            candidateID: selectedMemoryPresetID,
            configurationID: reconciledConfigurationID,
            configurationRevision: configurationRevision,
            editingState: &editingState
        )
        editingState.restorePresentationContext(
            from: selectedPreset
        )
        editingState.refreshPresetDrivenPreview()
        return .applied
    }

    func restoreConfigurationLibrary(
        _ aggregate: ConfigurationLibraryRecord,
        editingState: inout ConfigurationEditingState
    ) {
        editingState.state.configurationLibrary = aggregate
        editingState.state.subjects =
            aggregate.subjects.map {
                ConfigurationSubjectAssetMapper()
                    .makeRuntime(subject: $0.subject)
            }
        editingState.state.memoryPresets =
            aggregate.subjects.flatMap { subjectRecord in
                subjectRecord.configurations.map { configuration in
                    MemoryPreset(
                        id: configuration.id,
                        title: configuration.title,
                        summary: "",
                        regionTemplateIDs:
                            configuration.editor.regionTemplateIDs,
                        savedAt: configuration.savedAt,
                        selectedSubjectID:
                            subjectRecord.subject.id,
                        selectedTimeAnchorID:
                            configuration.selectedTimeAnchorID,
                        logoMode:
                            configuration.presentation.logo.mode,
                        usesCustomMemoryWriteText:
                            configuration.editor.memoryCopy
                                .usesCustomText,
                        customMemoryWriteText:
                            configuration.editor.memoryCopy
                                .customText
                    )
                }
            }
        editingState.state.selectedSubjectID =
            aggregate.activeSubjectID
        editingState.state.selectedMemoryPresetID =
            aggregate.activeConfigurationID
        editingState.appliedMemoryPresetID =
            aggregate.activeConfigurationID

        guard let activePreset =
            editingState.state.selectedMemoryPreset else {
            editingState.presentationState
                .draftMemoryConfiguration = nil
            return
        }

        editingState.selectMemoryPreset(activePreset)
    }

    @discardableResult
    func reconcileConfigurationLibrarySave(
        candidate: V1ConfigurationAggregateCandidate,
        receipt: ConfigurationLibrarySaveReceipt,
        editingState: inout ConfigurationEditingState
    ) -> ConfigurationPersistenceReconciliationOutcome {
        guard candidate.aggregate.activeSubjectID
                == receipt.subjectID,
              candidate.aggregate.activeConfigurationID
                == receipt.configurationID,
              editingState.state.selectedMemoryPresetID
                == receipt.configurationID else {
            return .newerEditsPreserved
        }

        var durableAggregate = candidate.aggregate
        durableAggregate.revision = receipt.revision
        restoreConfigurationLibrary(
            durableAggregate,
            editingState: &editingState
        )
        return .applied
    }

    func configurationSnapshot(
        in preset: MemoryPreset,
        editingState: ConfigurationEditingState,
        savedAt: Date?,
        logoMode: V1LogoMode?,
        outputConfiguration:
            V1SavedOutputConfiguration?
    ) -> MemoryPreset {
        var updatedPreset = preset
        updatedPreset.savedAt = savedAt
        updatedPreset.selectedSubjectID =
            editingState.state.selectedSubject?.id
        updatedPreset.selectedTimeAnchorID =
            editingState.state.selectedSubject?
            .primaryTimeAnchor?
            .id
        updatedPreset.outputOption =
            editingState.selectedOutputOption
        updatedPreset.storageOption =
            editingState.selectedStorageOption
        updatedPreset.logoMode =
            logoMode ?? preset.logoMode
        updatedPreset.usesCustomMemoryWriteText =
            editingState.usesCustomMemoryWriteText
        updatedPreset.customMemoryWriteText =
            editingState.customMemoryWriteText
        updatedPreset.savedOutputConfiguration =
            outputConfiguration
            ?? preset.savedOutputConfiguration
        return updatedPreset
    }

    private func reconcileConfigurationLibraryIdentity(
        candidateID: UUID,
        configurationID: UUID,
        configurationRevision: Int?,
        editingState: inout ConfigurationEditingState
    ) {
        guard var library =
            editingState.state.configurationLibrary else {
            return
        }

        for subjectIndex in library.subjects.indices {
            guard let configurationIndex =
                library.subjects[subjectIndex]
                .configurations.firstIndex(where: {
                    $0.id == candidateID
                })
            else {
                continue
            }

            let candidate = library.subjects[subjectIndex]
                .configurations[configurationIndex]
            library.subjects[subjectIndex]
                .configurations[configurationIndex] =
                MemoryConfigurationRecord(
                    id: configurationID,
                    title: candidate.title,
                    revision:
                        configurationRevision
                        ?? candidate.revision,
                    savedAt: candidate.savedAt,
                    selectedTimeAnchorID:
                        candidate.selectedTimeAnchorID,
                    editor: candidate.editor,
                    presentation: candidate.presentation,
                    output: candidate.output
                )
            break
        }
        library.activeConfigurationID = configurationID
        editingState.state.configurationLibrary = library
    }
}
#endif
