#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

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

    static func preparingCurrentConfiguration(
        _ configurationID: UUID,
        subject: MemorySubject,
        seedConfiguration: MemoryConfigurationRecord,
        in aggregate: ConfigurationLibraryRecord?
    ) -> ConfigurationLibraryRecord? {
        if let aggregate,
           let prepared = preparingCurrentConfiguration(
               configurationID,
               subjectID: subject.id,
               in: aggregate
           ) {
            return prepared
        }

        guard seedConfiguration.id == configurationID else {
            return nil
        }
        var candidate = aggregate ?? ConfigurationLibraryRecord(
            revision: 0,
            subjects: [],
            activeSubjectID: nil,
            activeConfigurationID: nil
        )
        if let subjectIndex = candidate.subjects.firstIndex(
            where: { $0.subject.id == subject.id }
        ) {
            candidate.subjects[subjectIndex].subject = subject
            candidate.subjects[subjectIndex]
                .configurations.append(seedConfiguration)
        } else {
            candidate.subjects.append(
                .init(
                    subject: subject,
                    configurations: [seedConfiguration],
                    assetManifest: .init(entries: [])
                )
            )
        }
        candidate.activeSubjectID = subject.id
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

}
#endif
