#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

enum V1LocalConfigurationBackupAction: Hashable {
    case applyCurrentThenBackup
    case backupDurableConfiguration
    case unavailable
}

enum V1LiveConfigurationDeletionAction: Hashable {
    case applyCurrentThenDelete
    case deleteDurableConfiguration
    case unavailable
}

struct V1LocalConfigurationLibraryRow: Identifiable, Hashable {
    let id: UUID
    let title: String
    let revision: Int
    let savedAt: Date
    let isCurrent: Bool
}

enum V1LocalConfigurationLibraryPresenter {

    static func rows(
        subjectID: UUID,
        aggregate: ConfigurationLibraryRecord
    ) -> [V1LocalConfigurationLibraryRow] {
        guard let subjectRecord = aggregate.subjects.first(
            where: { $0.subject.id == subjectID }
        ) else {
            return []
        }

        return subjectRecord.configurations.map { configuration in
            V1LocalConfigurationLibraryRow(
                id: configuration.id,
                title: configuration.title,
                revision: configuration.revision,
                savedAt: configuration.savedAt,
                isCurrent:
                    aggregate.activeSubjectID == subjectID
                    && aggregate.activeConfigurationID
                        == configuration.id
            )
        }
    }

    static func backupAction(
        configurationID: UUID,
        currentConfigurationID: UUID?,
        isCurrentConfigurationDirty: Bool,
        isSavingConfiguration: Bool = false,
        durableConfigurationIDs: [UUID]
    ) -> V1LocalConfigurationBackupAction {
        guard !isSavingConfiguration else {
            return .unavailable
        }
        if configurationID == currentConfigurationID,
           isCurrentConfigurationDirty {
            return .applyCurrentThenBackup
        }
        guard durableConfigurationIDs.contains(configurationID) else {
            return .unavailable
        }
        return .backupDurableConfiguration
    }

    static func deletionAction(
        configurationID: UUID,
        currentConfigurationID: UUID?,
        isCurrentConfigurationDirty: Bool,
        durableConfigurationIDs: [UUID],
        visibleConfigurationIDs: [UUID]
    ) -> V1LiveConfigurationDeletionAction {
        guard durableConfigurationIDs.contains(configurationID),
              visibleConfigurationIDs.count > 1 else {
            return .unavailable
        }
        if durableConfigurationIDs.count == 1,
           let currentConfigurationID,
           currentConfigurationID != configurationID,
           isCurrentConfigurationDirty,
           !durableConfigurationIDs.contains(currentConfigurationID) {
            return .applyCurrentThenDelete
        }
        guard durableConfigurationIDs.count > 1 else {
            return .unavailable
        }
        return .deleteDurableConfiguration
    }

    static func preparingCurrentConfiguration(
        _ configurationID: UUID,
        subjectID: UUID,
        in aggregate: ConfigurationLibraryRecord
    ) -> ConfigurationLibraryRecord? {
        var candidate = aggregate
        guard let subjectIndex = candidate.subjects.firstIndex(
            where: { $0.subject.id == subjectID }
        ) else {
            return nil
        }
        if candidate.subjects[subjectIndex].configurations.contains(
            where: { $0.id == configurationID }
        ) {
            candidate.activeSubjectID = subjectID
            candidate.activeConfigurationID = configurationID
            return candidate
        }
        guard let source = candidate.subjects[subjectIndex]
            .configurations.first(where: {
                $0.id == candidate.activeConfigurationID
            })
            ?? candidate.subjects[subjectIndex].configurations.first else {
            return nil
        }
        let inserted = MemoryConfigurationRecord(
            id: configurationID,
            title: source.title,
            revision: 0,
            savedAt: source.savedAt,
            selectedTimeAnchorID: source.selectedTimeAnchorID,
            editor: source.editor,
            presentation: source.presentation,
            output: source.output
        )
        candidate.subjects[subjectIndex].configurations.append(inserted)
        candidate.activeSubjectID = subjectID
        candidate.activeConfigurationID = configurationID
        return candidate
    }

    static func backupFeedback(
        title: String,
        receipt: LocalConfigurationBackupReceipt
    ) -> String {
        switch receipt.disposition {
        case .saved:
            return "已保存“\(title)”版本 \(receipt.revision) 到本地配置库。"
        case .noOpRevisionConflict(let existingRevision, _):
            return "本地配置库已有更新的版本 \(existingRevision)，未覆盖“\(title)”。"
        }
    }

    static func deletingConfiguration(
        _ configurationID: UUID,
        from aggregate: ConfigurationLibraryRecord
    ) -> ConfigurationLibraryRecord? {
        var candidate = aggregate
        guard let subjectIndex = candidate.subjects.firstIndex(
            where: {
                $0.configurations.contains {
                    $0.id == configurationID
                }
            }
        ) else {
            return nil
        }

        candidate.subjects[subjectIndex].configurations.removeAll {
            $0.id == configurationID
        }
        let remainingSelections = candidate.subjects.flatMap {
            subjectRecord in
            subjectRecord.configurations.map {
                (subjectRecord.subject.id, $0.id)
            }
        }
        guard !remainingSelections.isEmpty else {
            return nil
        }

        if candidate.activeConfigurationID == configurationID {
            let selection = candidate.subjects[subjectIndex]
                .configurations.first.map {
                    (candidate.subjects[subjectIndex].subject.id, $0.id)
                }
                ?? remainingSelections[0]
            candidate.activeSubjectID = selection.0
            candidate.activeConfigurationID = selection.1
        }
        return candidate
    }
}
#endif
