#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

@MainActor
final class ConfigurationLibraryStore {

    private let repository: ConfigurationLibraryRepository
    private let storage: (any ConfigurationLibraryDataStorage)?

    private(set) var recoveredAggregate:
        ConfigurationLibraryRecord?
    private(set) var startupRecoveryError:
        ConfigurationLibraryPersistenceError?

    init(
        repository: ConfigurationLibraryRepository,
        storage: (any ConfigurationLibraryDataStorage)?
    ) {
        self.repository = repository
        self.storage = storage
        self.recoveredAggregate = nil
        self.startupRecoveryError = nil
    }

    func replayProjectionIfAvailable(
        _ projection:
            @MainActor (ConfigurationLibraryRecord) throws -> Void
    ) {
        guard let storage else {
            return
        }
        do {
            let snapshot = try
                ConfigurationLibrarySynchronousStorageLoader
                .snapshot(from: storage)
            guard let recovered = try
                ConfigurationLibraryRecordRecovery.recover(
                    from: snapshot,
                    allowNoValue: true
                )
            else {
                return
            }
            recoveredAggregate = recovered.aggregate
            try projection(recovered.aggregate)
        } catch ConfigurationLibraryPersistenceTransportError
            .readFailed(let description) {
            startupRecoveryError = .readFailed(description)
        } catch let error as ConfigurationLibraryPersistenceError {
            startupRecoveryError = error
        } catch {
            startupRecoveryError =
                .encodingFailed(String(describing: error))
        }
    }

    func save(
        _ aggregate: ConfigurationLibraryRecord,
        compatibilityProjection:
            @MainActor (
                ConfigurationLibraryRecord,
                ConfigurationLibrarySaveReceipt
            ) throws -> Void
    ) async throws -> ConfigurationLibrarySaveReceipt {
        try await repository.save(
            aggregate,
            compatibilityProjection: {
                [weak self]
                saved,
                provisionalReceipt in
                self?.recoveredAggregate = saved
                try compatibilityProjection(
                    saved,
                    provisionalReceipt
                )
            }
        )
    }

    func load() async throws -> ConfigurationLibraryLoadReceipt {
        try await repository.load()
    }

    func resolveDurableProductionConfiguration(
        _ reference: ProductionConfigurationReference
    ) throws -> BatchConfigurationSnapshot {
        guard let recoveredAggregate else {
            throw ProductionConfigurationContractError
                .configurationNotFound(reference.configurationID)
        }
        return try ProductionConfigurationSnapshotFactory.resolve(
            reference: reference,
            from: recoveredAggregate
        )
    }
}
#endif
