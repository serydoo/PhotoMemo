#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

enum V1ConfigurationDeletionOutcome: Equatable {
    case deleted(ConfigurationLibraryDeletionResult)
    case rejected(message: String)
}

@MainActor
struct V1ConfigurationDeletionRuntimeCoordinator {

    private let actions: ConfigurationLibraryActions
    private let currentRequest:
        (MemoryPreset) -> ConfigurationLibraryDeletionRequest
    private let applyCurrentConfiguration: () async -> Bool
    private let persistConfigurationLibrary:
        (ConfigurationLibraryRecord) async throws ->
            ConfigurationLibrarySaveReceipt
    private let setPersistenceInProgress: (Bool) -> Void

    init(
        actions: ConfigurationLibraryActions,
        currentRequest: @escaping (
            MemoryPreset
        ) -> ConfigurationLibraryDeletionRequest,
        applyCurrentConfiguration: @escaping () async -> Bool,
        persistConfigurationLibrary: @escaping (
            ConfigurationLibraryRecord
        ) async throws -> ConfigurationLibrarySaveReceipt,
        setPersistenceInProgress: @escaping (Bool) -> Void = { _ in }
    ) {
        self.actions = actions
        self.currentRequest = currentRequest
        self.applyCurrentConfiguration = applyCurrentConfiguration
        self.persistConfigurationLibrary = persistConfigurationLibrary
        self.setPersistenceInProgress = setPersistenceInProgress
    }

    func delete(
        _ preset: MemoryPreset
    ) async -> V1ConfigurationDeletionOutcome {
        await delete(
            preset,
            mayApplyCurrentConfiguration: true
        )
    }
}

private extension V1ConfigurationDeletionRuntimeCoordinator {

    func delete(
        _ preset: MemoryPreset,
        mayApplyCurrentConfiguration: Bool
    ) async -> V1ConfigurationDeletionOutcome {
        switch actions.decide(
            .delete(currentRequest(preset))
        ) {
        case .applyCurrentThenDelete:
            guard mayApplyCurrentConfiguration else {
                return .rejected(
                    message: "删除配置失败，原配置仍然保留。"
                )
            }
            guard await applyCurrentConfiguration() else {
                return .rejected(
                    message: "当前新增配置保存失败，未删除原配置。"
                )
            }
            return await delete(
                preset,
                mayApplyCurrentConfiguration: false
            )
        case .persistDeletion(let result):
            setPersistenceInProgress(true)
            defer { setPersistenceInProgress(false) }
            do {
                let receipt = try await persistConfigurationLibrary(
                    result.candidate
                )
                return .deleted(
                    result.reconcilingRevision(receipt.revision)
                )
            } catch {
                return .rejected(
                    message: "删除配置失败，原配置仍然保留。"
                )
            }
        case .unavailable(let message):
            return .rejected(message: message)
        default:
            return .rejected(
                message: "删除配置失败，原配置仍然保留。"
            )
        }
    }
}
#endif
