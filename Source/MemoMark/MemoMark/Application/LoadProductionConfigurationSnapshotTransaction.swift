#if !MEMOMARK_SHARE_EXTENSION
import Foundation

/// Opens one persisted configuration into an editor context. This is a pure
/// lookup: it never changes the active configuration and never writes a draft.
struct OpenConfigurationCommand: Hashable {
    let subjectID: UUID
    let configurationID: UUID
}

struct OpenConfigurationContext: Hashable {
    let subject: MemorySubject
    let configuration: MemoryConfigurationRecord
}

enum OpenConfigurationCommandError: Error, Equatable {
    case subjectNotFound
    case configurationNotFound
}

struct OpenConfigurationTransaction {

    static func apply(
        _ command: OpenConfigurationCommand,
        in aggregate: ConfigurationLibraryRecord
    ) throws -> OpenConfigurationContext {
        guard let subjectRecord = aggregate.subjects.first(where: {
            $0.subject.id == command.subjectID
        }) else {
            throw OpenConfigurationCommandError.subjectNotFound
        }
        guard let configuration = subjectRecord.configurations.first(where: {
            $0.id == command.configurationID
        }) else {
            throw OpenConfigurationCommandError.configurationNotFound
        }
        return OpenConfigurationContext(
            subject: subjectRecord.subject,
            configuration: configuration
        )
    }
}

/// Produces the immutable configuration snapshot handed to processing. The
/// returned value is the batch's frozen snapshot; subsequent editor changes
/// cannot affect it. An explicit target that cannot be resolved fails closed.
struct FreezeForProcessingCommand: Hashable {
    let subjectID: UUID
    let configurationID: UUID
}

enum FreezeForProcessingCommandError: Error, Equatable {
    case subjectNotFound
    case configurationNotFound
    case snapshotUnavailable
}

struct FreezeForProcessingTransaction {

    static func apply(
        _ command: FreezeForProcessingCommand,
        in aggregate: ConfigurationLibraryRecord,
        fallback: BatchConfigurationSnapshot,
        selectedPresentationStyle: RecordCardPresentationStyle? = nil
    ) throws -> BatchConfigurationSnapshot {
        guard aggregate.subjects.contains(where: {
            $0.subject.id == command.subjectID
        }) else {
            throw FreezeForProcessingCommandError.subjectNotFound
        }
        guard aggregate.subjects.contains(where: {
            $0.subject.id == command.subjectID
                && $0.configurations.contains(where: {
                    $0.id == command.configurationID
                })
        }) else {
            throw FreezeForProcessingCommandError.configurationNotFound
        }
        guard let snapshot = ConfigurationSnapshotSelectionResolver.resolve(
            selectedConfigurationID: command.configurationID,
            aggregate: aggregate,
            fallback: fallback,
            selectedPresentationStyle: selectedPresentationStyle
        ) else {
            throw FreezeForProcessingCommandError.snapshotUnavailable
        }
        do {
            try ProductionConfigurationSnapshotContract.validate(snapshot)
        } catch {
            throw FreezeForProcessingCommandError.snapshotUnavailable
        }
        return snapshot
    }
}

/// Reads the canonical durable configuration after a successful save so an
/// intake request receives one immutable production snapshot rather than a
/// view-created settings service.
@MainActor
struct LoadProductionConfigurationSnapshotTransaction {

    private let loadSnapshot:
        () -> BatchConfigurationSnapshot

    init(
        loadSnapshot: @escaping () -> BatchConfigurationSnapshot
    ) {
        self.loadSnapshot =
            loadSnapshot
    }

    init(
        configurationRepository:
            ConfigurationRepository
    ) {
        self.init(
            loadSnapshot: {
                configurationRepository
                    .loadDefaultBatchConfigurationSnapshot()
            }
        )
    }

    func apply() -> BatchConfigurationSnapshot {
        loadSnapshot()
    }
}
#endif
