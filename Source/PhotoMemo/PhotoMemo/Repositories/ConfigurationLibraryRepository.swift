#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

protocol ConfigurationLibraryRecordEncoding {

    func encode(
        _ aggregate: ConfigurationLibraryRecord
    ) throws -> Data
}

struct JSONConfigurationLibraryRecordEncoder:
    ConfigurationLibraryRecordEncoding {

    func encode(
        _ aggregate: ConfigurationLibraryRecord
    ) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(aggregate)
    }
}

enum ConfigurationLibraryPersistenceError: Error {

    case validationFailed(
        [ConfigurationRecordValidationIssue]
    )
    case missingActiveSelection
    case encodingFailed(String)
    case readFailed(String)
    case writeFailed(String)
    case revisionOverflow
    case noStoredAggregate
    case corruptedPrimaryAndLastKnownGood(
        primaryDescription: String?,
        lastKnownGoodDescription: String?
    )
}

nonisolated struct ConfigurationLibraryProjectionFailure:
    Equatable,
    Sendable {

    let underlyingDescription: String
}

nonisolated struct ConfigurationLibrarySaveReceipt:
    Equatable,
    Sendable {

    let revision: Int
    let subjectID: UUID
    let configurationID: UUID
    let compatibilityProjectionFailure:
        ConfigurationLibraryProjectionFailure?
}

enum ConfigurationLibraryLoadSource:
    Equatable {

    case primary
    case lastKnownGood
}

struct ConfigurationLibraryLoadReceipt {

    let aggregate: ConfigurationLibraryRecord
    let source: ConfigurationLibraryLoadSource
}

struct ConfigurationLibraryRecoveredAggregate {

    let aggregate: ConfigurationLibraryRecord
    let data: Data
    let source: ConfigurationLibraryLoadSource
}

enum ConfigurationLibraryRecordRecovery {

    static func validate(
        _ aggregate: ConfigurationLibraryRecord
    ) throws {
        switch aggregate.validationResult {
        case .valid:
            return
        case .invalid(let issues):
            throw ConfigurationLibraryPersistenceError
                .validationFailed(issues)
        }
    }

    static func recover(
        from snapshot: ConfigurationLibraryPersistenceSnapshot,
        allowNoValue: Bool
    ) throws -> ConfigurationLibraryRecoveredAggregate? {
        var primaryDescription: String?
        if let primaryData = snapshot.primaryData {
            do {
                let aggregate = try decodeAndValidate(
                    primaryData
                )
                return ConfigurationLibraryRecoveredAggregate(
                    aggregate: aggregate,
                    data: primaryData,
                    source: .primary
                )
            } catch {
                primaryDescription = String(describing: error)
            }
        }

        var lastKnownGoodDescription: String?
        if let lastKnownGoodData = snapshot.lastKnownGoodData {
            do {
                let aggregate = try decodeAndValidate(
                    lastKnownGoodData
                )
                return ConfigurationLibraryRecoveredAggregate(
                    aggregate: aggregate,
                    data: lastKnownGoodData,
                    source: .lastKnownGood
                )
            } catch {
                lastKnownGoodDescription =
                    String(describing: error)
            }
        }

        if allowNoValue,
           snapshot.primaryData == nil,
           snapshot.lastKnownGoodData == nil {
            return nil
        }
        if !allowNoValue,
           snapshot.primaryData == nil,
           snapshot.lastKnownGoodData == nil {
            throw ConfigurationLibraryPersistenceError
                .noStoredAggregate
        }
        throw ConfigurationLibraryPersistenceError
            .corruptedPrimaryAndLastKnownGood(
                primaryDescription: primaryDescription,
                lastKnownGoodDescription:
                    lastKnownGoodDescription
            )
    }

    private static func decodeAndValidate(
        _ data: Data
    ) throws -> ConfigurationLibraryRecord {
        let aggregate = try JSONDecoder().decode(
            ConfigurationLibraryRecord.self,
            from: data
        )
        try validate(aggregate)
        return aggregate
    }
}

@MainActor
final class ConfigurationLibraryRepository {

    private let persistence:
        ConfigurationLibraryPersistence

    private let encoder:
        any ConfigurationLibraryRecordEncoding

    init(
        persistence: ConfigurationLibraryPersistence =
            ConfigurationLibraryPersistence()
    ) {
        self.persistence = persistence
        self.encoder =
            JSONConfigurationLibraryRecordEncoder()
    }

    init(
        persistence: ConfigurationLibraryPersistence,
        encoder: any ConfigurationLibraryRecordEncoding
    ) {
        self.persistence = persistence
        self.encoder = encoder
    }

    func save(
        _ aggregate: ConfigurationLibraryRecord,
        compatibilityProjection:
            @MainActor (
                ConfigurationLibraryRecord,
                ConfigurationLibrarySaveReceipt
            ) throws -> Void = { _, _ in }
    ) async throws -> ConfigurationLibrarySaveReceipt {
        var candidate = aggregate
        candidate.revision = 0
        try validate(candidate)
        let subjectID = try requiredActiveSubjectID(candidate)
        let configurationID =
            try requiredActiveConfigurationID(candidate)

        while true {
            let persistenceSnapshot = try await loadSnapshot()
            let current = try recoverCurrentAggregate(
                from: persistenceSnapshot,
                allowNoValue: true
            )
            let currentRevision = current?.aggregate.revision ?? 0
            guard currentRevision < Int.max - 1 else {
                throw ConfigurationLibraryPersistenceError
                    .revisionOverflow
            }

            candidate.revision = currentRevision + 1
            let data = try encode(candidate)

            do {
                try await persistence.replacePrimaryData(
                    data,
                    expectedPrimaryData:
                        persistenceSnapshot.primaryData,
                    lastKnownGoodData: current?.data
                )
            } catch ConfigurationLibraryPersistenceTransportError
                .primaryChanged {
                continue
            } catch ConfigurationLibraryPersistenceTransportError
                .writeFailed(let description) {
                throw ConfigurationLibraryPersistenceError
                    .writeFailed(description)
            } catch ConfigurationLibraryPersistenceTransportError
                .readFailed(let description) {
                throw ConfigurationLibraryPersistenceError
                    .readFailed(description)
            }

            let provisionalReceipt =
                ConfigurationLibrarySaveReceipt(
                    revision: candidate.revision,
                    subjectID: subjectID,
                    configurationID: configurationID,
                    compatibilityProjectionFailure: nil
                )
            let projectionFailure:
                ConfigurationLibraryProjectionFailure?
            do {
                try compatibilityProjection(
                    candidate,
                    provisionalReceipt
                )
                projectionFailure = nil
            } catch {
                projectionFailure =
                    ConfigurationLibraryProjectionFailure(
                        underlyingDescription:
                            String(describing: error)
                    )
            }

            guard let projectionFailure else {
                return provisionalReceipt
            }
            return ConfigurationLibrarySaveReceipt(
                revision: provisionalReceipt.revision,
                subjectID: provisionalReceipt.subjectID,
                configurationID:
                    provisionalReceipt.configurationID,
                compatibilityProjectionFailure: projectionFailure
            )
        }
    }

    func load() async throws
    -> ConfigurationLibraryLoadReceipt {
        let snapshot = try await loadSnapshot()
        guard let recovered = try recoverCurrentAggregate(
            from: snapshot,
            allowNoValue: false
        ) else {
            throw ConfigurationLibraryPersistenceError
                .noStoredAggregate
        }
        return ConfigurationLibraryLoadReceipt(
            aggregate: recovered.aggregate,
            source: recovered.source
        )
    }
}

private extension ConfigurationLibraryRepository {

    func validate(
        _ aggregate: ConfigurationLibraryRecord
    ) throws {
        try ConfigurationLibraryRecordRecovery
            .validate(aggregate)
    }

    func requiredActiveSubjectID(
        _ aggregate: ConfigurationLibraryRecord
    ) throws -> UUID {
        guard let subjectID = aggregate.activeSubjectID else {
            throw ConfigurationLibraryPersistenceError
                .missingActiveSelection
        }
        return subjectID
    }

    func requiredActiveConfigurationID(
        _ aggregate: ConfigurationLibraryRecord
    ) throws -> UUID {
        guard let configurationID =
            aggregate.activeConfigurationID
        else {
            throw ConfigurationLibraryPersistenceError
                .missingActiveSelection
        }
        return configurationID
    }

    func encode(
        _ aggregate: ConfigurationLibraryRecord
    ) throws -> Data {
        do {
            return try encoder.encode(aggregate)
        } catch {
            throw ConfigurationLibraryPersistenceError
                .encodingFailed(String(describing: error))
        }
    }

    func loadSnapshot() async throws
    -> ConfigurationLibraryPersistenceSnapshot {
        do {
            return try await persistence.snapshot()
        } catch ConfigurationLibraryPersistenceTransportError
            .readFailed(let description) {
            throw ConfigurationLibraryPersistenceError
                .readFailed(description)
        } catch {
            throw ConfigurationLibraryPersistenceError
                .readFailed(String(describing: error))
        }
    }

    func recoverCurrentAggregate(
        from snapshot: ConfigurationLibraryPersistenceSnapshot,
        allowNoValue: Bool
    ) throws -> ConfigurationLibraryRecoveredAggregate? {
        try ConfigurationLibraryRecordRecovery.recover(
            from: snapshot,
            allowNoValue: allowNoValue
        )
    }
}
#endif
