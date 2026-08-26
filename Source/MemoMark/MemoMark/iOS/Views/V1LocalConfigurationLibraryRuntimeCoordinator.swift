#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import Foundation

struct V1LocalConfigurationLibraryRuntimeSnapshot {
    let aggregate: ConfigurationLibraryRecord?
    let selectedSubjectID: MemorySubject.ID?
    let availablePresets: [MemoryPreset]
    let selectedPresetID: MemoryPreset.ID?
    let isCurrentConfigurationDirty: Bool
    let isSavingConfiguration: Bool
    let availableAlbumIdentifiers: Set<String>
    let selectedCustomLogoPath: String?
}

@MainActor
struct V1LocalConfigurationLibraryRuntimeCoordinator {
    private let actions: ConfigurationLibraryActions
    private let backupRestoreCoordinator:
        ConfigurationBackupRestoreCoordinator
    private let snapshot: () -> V1LocalConfigurationLibraryRuntimeSnapshot
    private let presentation:
        () -> V1LocalConfigurationLibraryPresentationState
    private let updatePresentation:
        (V1LocalConfigurationLibraryPresentationState) -> Void
    private let applyCurrentConfiguration: () async -> Bool
    private let restoreAggregate: (ConfigurationLibraryRecord) -> Void
    private let applyRestoredCurrentConfiguration: () -> Void
    private let presentFeedback: (String, Bool) -> Void

    init(
        actions: ConfigurationLibraryActions,
        backupRestoreCoordinator: ConfigurationBackupRestoreCoordinator,
        snapshot: @escaping () -> V1LocalConfigurationLibraryRuntimeSnapshot,
        presentation: @escaping () -> V1LocalConfigurationLibraryPresentationState,
        updatePresentation: @escaping (
            V1LocalConfigurationLibraryPresentationState
        ) -> Void,
        applyCurrentConfiguration: @escaping () async -> Bool,
        restoreAggregate: @escaping (ConfigurationLibraryRecord) -> Void,
        applyRestoredCurrentConfiguration: @escaping () -> Void,
        presentFeedback: @escaping (String, Bool) -> Void
    ) {
        self.actions = actions
        self.backupRestoreCoordinator = backupRestoreCoordinator
        self.snapshot = snapshot
        self.presentation = presentation
        self.updatePresentation = updatePresentation
        self.applyCurrentConfiguration = applyCurrentConfiguration
        self.restoreAggregate = restoreAggregate
        self.applyRestoredCurrentConfiguration =
            applyRestoredCurrentConfiguration
        self.presentFeedback = presentFeedback
    }

    func listBackups() async {
        guard beginWork() else { return }
        defer { endWork() }
        let current = snapshot()
        let result = await backupRestoreCoordinator.listBackups(
            ConfigurationBackupListRequest(
                subjectID: current.selectedSubjectID,
                previousBackups: presentation().backups
            )
        )
        updateBackups(result.backups, status: result.status)
    }

    func backup(
        configurationID: UUID
    ) async {
        let initial = snapshot()
        guard let aggregate = initial.aggregate,
              let subjectID = initial.selectedSubjectID,
              let subjectRecord = aggregate.subjects.first(
                  where: { $0.subject.id == subjectID }
              ),
              let preset = initial.availablePresets.first(
                  where: { $0.id == configurationID }
              ) else {
            presentFeedback(
                "当前配置还没有可备份的持久化记录。",
                true
            )
            return
        }

        let decision = actions.decide(
            .saveToLocalLibrary(
                ConfigurationLibrarySaveRequest(
                    preset: preset,
                    selectedConfigurationID: initial.selectedPresetID,
                    isCurrentConfigurationDirty:
                        initial.isCurrentConfigurationDirty,
                    isSavingConfiguration: initial.isSavingConfiguration,
                    durableConfigurationIDs:
                        subjectRecord.configurations.map(\.id)
                )
            )
        )
        if case .unavailable(let message) = decision {
            presentFeedback(message, true)
            return
        }
        if case .applyCurrentThenSave = decision,
           !(await applyCurrentConfiguration()) {
            presentFeedback(
                "当前修改保存失败，未创建本地备份。",
                true
            )
            return
        }

        guard beginWork() else { return }
        defer { endWork() }
        let current = snapshot()
        guard let durableAggregate = current.aggregate,
              let durableSubjectRecord = durableAggregate.subjects.first(
                  where: { $0.subject.id == subjectID }
              ),
              let configuration = durableSubjectRecord.configurations.first(
                  where: { $0.id == configurationID }
              ) else {
            presentFeedback(
                "保存后未找到对应的持久化配置。",
                true
            )
            return
        }

        let result = await backupRestoreCoordinator.backup(
            ConfigurationBackupRequest(
                subject: durableSubjectRecord.subject,
                configuration: configuration,
                sourceURLs: ConfigurationBackupRestoreCoordinator.assetURLs(
                    subject: durableSubjectRecord.subject,
                    configuration: configuration,
                    selectedConfigurationID: current.selectedPresetID,
                    selectedCustomLogoPath: current.selectedCustomLogoPath
                ),
                previousBackups: presentation().backups
            )
        )
        var next = presentation()
        next.backups = result.backups
        updatePresentation(next)
        if case .replace(let message) = result.status {
            presentFeedback(message, !result.succeeded)
        }
    }

    func restore(
        fileURL: URL,
        assetRootURL: URL,
        makeCurrent: Bool
    ) async {
        guard beginWork() else { return }
        defer { endWork() }
        let current = snapshot()
        let result = await backupRestoreCoordinator.restore(
            ConfigurationRestoreRequest(
                fileURL: fileURL,
                assetRootURL: assetRootURL,
                makeCurrent: makeCurrent,
                aggregate: current.aggregate,
                availableAlbumIdentifiers:
                    current.availableAlbumIdentifiers,
                currentSubjectID: current.selectedSubjectID,
                previousBackups: presentation().backups
            )
        )
        if let aggregate = result.aggregate {
            restoreAggregate(aggregate)
            if result.shouldApplyCurrentConfiguration {
                applyRestoredCurrentConfiguration()
            }
        }
        updateBackups(result.backups, status: result.status)
    }

    func delete(
        _ backup: LocalConfigurationBackupRecord
    ) async {
        guard beginWork() else { return }
        defer { endWork() }
        let result = await backupRestoreCoordinator.deleteBackup(
            ConfigurationBackupDeletionRequest(
                backup: backup,
                previousBackups: presentation().backups
            )
        )
        updateBackups(result.backups, status: result.status)
    }
}

private extension V1LocalConfigurationLibraryRuntimeCoordinator {
    func beginWork() -> Bool {
        var next = presentation()
        guard !next.isWorking else { return false }
        next.isWorking = true
        updatePresentation(next)
        return true
    }

    func endWork() {
        var next = presentation()
        next.isWorking = false
        updatePresentation(next)
    }

    func updateBackups(
        _ backups: [LocalConfigurationBackupRecord],
        status: ConfigurationBackupRestoreStatusUpdate
    ) {
        var next = presentation()
        next.backups = backups
        if case .replace(let message) = status {
            next.statusMessage = message
        }
        updatePresentation(next)
    }
}
#endif
