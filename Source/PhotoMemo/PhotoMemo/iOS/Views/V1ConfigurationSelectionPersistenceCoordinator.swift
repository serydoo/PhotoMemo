#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct V1ConfigurationSelectionPersistencePatch: Equatable {
    let expectedRevision: Int
    let expectedSubjectID: UUID?
    let expectedConfigurationID: UUID?
    let durableRevision: Int

    func reconcile(
        current: ConfigurationLibraryRecord?
    ) -> ConfigurationLibraryRecord? {
        guard var current,
              current.revision == expectedRevision,
              current.activeSubjectID == expectedSubjectID,
              current.activeConfigurationID == expectedConfigurationID else {
            return nil
        }
        current.revision = durableRevision
        return current
    }
}

enum V1ConfigurationSelectionPersistenceResult: Equatable {
    case saved(V1ConfigurationSelectionPersistencePatch)
    case failed(message: String)
}

struct V1ConfigurationSelectionPersistenceCoordinator {

    private let saveConfigurationLibrary:
        (ConfigurationLibraryRecord) async throws ->
            ConfigurationLibrarySaveReceipt

    init(
        saveConfigurationLibrary: @escaping (
            ConfigurationLibraryRecord
        ) async throws -> ConfigurationLibrarySaveReceipt
    ) {
        self.saveConfigurationLibrary = saveConfigurationLibrary
    }

    func persist(
        _ candidate: ConfigurationLibraryRecord
    ) async -> V1ConfigurationSelectionPersistenceResult {
        do {
            let receipt = try await saveConfigurationLibrary(candidate)
            return .saved(
                V1ConfigurationSelectionPersistencePatch(
                    expectedRevision: candidate.revision,
                    expectedSubjectID: candidate.activeSubjectID,
                    expectedConfigurationID:
                        candidate.activeConfigurationID,
                    durableRevision: receipt.revision
                )
            )
        } catch {
            return .failed(
                message: "当前配置切换保存失败，请重试。"
            )
        }
    }
}
#endif
