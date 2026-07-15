#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

enum ConfigurationLibraryActionIntent: Equatable {
    case create
    case reset
    case beginRename(title: String)
    case commitRename(title: String)
    case saveCurrent
    case saveToLocalLibrary(ConfigurationLibrarySaveRequest)
    case activate(MemoryPreset)
    case delete(ConfigurationLibraryDeletionRequest)
}

enum ConfigurationLibraryActionDecision: Equatable {
    case create
    case reset
    case beginRename(title: String)
    case commitRename(title: String)
    case saveCurrent
    case applyCurrentThenSave(MemoryPreset)
    case saveDurableConfiguration(MemoryPreset)
    case activate(MemoryPreset)
    case applyCurrentThenDelete(MemoryPreset)
    case persistDeletion(ConfigurationLibraryDeletionResult)
    case unavailable(message: String)
}

struct ConfigurationLibraryDeletionRequest: Equatable {
    let preset: MemoryPreset
    let aggregate: ConfigurationLibraryRecord?
    let subjectID: UUID?
    let selectedConfigurationID: UUID?
    let isCurrentConfigurationDirty: Bool
    let visibleConfigurationIDs: [UUID]
    let isPersistenceAvailable: Bool
    let isSavingConfiguration: Bool

    init(
        preset: MemoryPreset,
        aggregate: ConfigurationLibraryRecord?,
        subjectID: UUID?,
        selectedConfigurationID: UUID?,
        isCurrentConfigurationDirty: Bool,
        visibleConfigurationIDs: [UUID],
        isPersistenceAvailable: Bool = true,
        isSavingConfiguration: Bool = false
    ) {
        self.preset = preset
        self.aggregate = aggregate
        self.subjectID = subjectID
        self.selectedConfigurationID = selectedConfigurationID
        self.isCurrentConfigurationDirty = isCurrentConfigurationDirty
        self.visibleConfigurationIDs = visibleConfigurationIDs
        self.isPersistenceAvailable = isPersistenceAvailable
        self.isSavingConfiguration = isSavingConfiguration
    }
}

struct ConfigurationLibrarySaveRequest: Equatable {
    let preset: MemoryPreset
    let selectedConfigurationID: UUID?
    let isCurrentConfigurationDirty: Bool
    let isSavingConfiguration: Bool
    let durableConfigurationIDs: [UUID]
}

struct ConfigurationLibraryDeletionResult: Equatable {
    let deletedPreset: MemoryPreset
    let candidate: ConfigurationLibraryRecord

    func reconcilingRevision(
        _ revision: Int
    ) -> ConfigurationLibraryDeletionResult {
        var durableCandidate = candidate
        durableCandidate.revision = revision
        return ConfigurationLibraryDeletionResult(
            deletedPreset: deletedPreset,
            candidate: durableCandidate
        )
    }
}

@MainActor
struct ConfigurationLibraryActions {

    func decide(
        _ intent: ConfigurationLibraryActionIntent
    ) -> ConfigurationLibraryActionDecision {
        switch intent {
        case .create:
            return .create
        case .reset:
            return .reset
        case .beginRename(let title):
            return .beginRename(title: title)
        case .commitRename(let title):
            return .commitRename(title: title)
        case .saveCurrent:
            return .saveCurrent
        case .saveToLocalLibrary(let request):
            return saveDecision(for: request)
        case .activate(let preset):
            return .activate(preset)
        case .delete(let request):
            return deletionDecision(for: request)
        }
    }
}

private extension ConfigurationLibraryActions {

    func saveDecision(
        for request: ConfigurationLibrarySaveRequest
    ) -> ConfigurationLibraryActionDecision {
        guard !request.isSavingConfiguration else {
            return .unavailable(
                message: "当前配置还没有可备份的持久化记录。"
            )
        }
        if request.preset.id == request.selectedConfigurationID,
           request.isCurrentConfigurationDirty {
            return .applyCurrentThenSave(request.preset)
        }
        guard request.durableConfigurationIDs.contains(request.preset.id) else {
            return .unavailable(
                message: "找不到这条配置的持久化版本。"
            )
        }
        return .saveDurableConfiguration(request.preset)
    }

    func deletionDecision(
        for request: ConfigurationLibraryDeletionRequest
    ) -> ConfigurationLibraryActionDecision {
        guard !request.isSavingConfiguration,
              request.isPersistenceAvailable,
              let aggregate = request.aggregate,
              let subjectID = request.subjectID,
              let subjectIndex = aggregate.subjects.firstIndex(
                  where: { $0.subject.id == subjectID }
              ) else {
            return .unavailable(
                message: "当前配置库不可用，请稍后重试。"
            )
        }

        let durableConfigurationIDs =
            aggregate.subjects[subjectIndex].configurations.map(\.id)

        guard durableConfigurationIDs.contains(request.preset.id),
              request.visibleConfigurationIDs.count > 1 else {
            return .unavailable(
                message: "请至少保留一条已保存配置；可以先保存当前新增配置。"
            )
        }

        if durableConfigurationIDs.count == 1,
           let selectedConfigurationID = request.selectedConfigurationID,
           selectedConfigurationID != request.preset.id,
           request.isCurrentConfigurationDirty,
           !durableConfigurationIDs.contains(selectedConfigurationID) {
            return .applyCurrentThenDelete(request.preset)
        }

        guard durableConfigurationIDs.count > 1 else {
            return .unavailable(
                message: "请至少保留一条已保存配置；可以先保存当前新增配置。"
            )
        }

        var candidate = aggregate
        candidate.subjects[subjectIndex].configurations.removeAll {
            $0.id == request.preset.id
        }

        if candidate.activeConfigurationID == request.preset.id,
           let sibling = candidate.subjects[subjectIndex]
            .configurations.first {
            candidate.activeSubjectID = subjectID
            candidate.activeConfigurationID = sibling.id
        }

        return .persistDeletion(
            ConfigurationLibraryDeletionResult(
                deletedPreset: request.preset,
                candidate: candidate
            )
        )
    }
}
#endif
