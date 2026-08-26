#if !MEMOMARK_SHARE_EXTENSION
import CryptoKit
import Foundation

nonisolated enum LocalConfigurationLibraryError:
    Error {

    case invalidDocument(
        [ConfigurationRecordValidationIssue]
    )
    case encodingFailed(String)
    case readFailed(String)
    case writeFailed(String)
    case deleteFailed(String)
    case backupNotFound(
        subjectID: UUID,
        configurationID: UUID
    )
    case checksumMismatch(
        expected: String,
        actual: String
    )
    case pathIdentityMismatch(
        expectedSubjectID: UUID,
        actualSubjectID: UUID,
        expectedConfigurationID: UUID,
        actualConfigurationID: UUID
    )
}

nonisolated struct LocalConfigurationBackupReceipt:
    Equatable,
    Sendable {

    let disposition: LocalConfigurationBackupSaveDisposition
    let subjectID: UUID
    let configurationID: UUID
    let revision: Int
    let savedAt: Date
    let checksum: String
    let fileURL: URL
}

nonisolated enum LocalConfigurationBackupSaveDisposition:
    Equatable,
    Sendable {

    case saved
    case noOpRevisionConflict(
        existingRevision: Int,
        attemptedRevision: Int
    )
}

nonisolated struct LocalConfigurationBackupRecord:
    Equatable,
    Sendable {

    let subjectID: UUID
    let configurationID: UUID
    let title: String
    let revision: Int
    let savedAt: Date
    let checksum: String
    let fileURL: URL
}

nonisolated struct LocalConfigurationBackupDeletionReceipt:
    Equatable,
    Sendable {

    let subjectID: UUID
    let configurationID: UUID
    let fileURL: URL
}

nonisolated protocol LocalConfigurationLibraryAtomicWriting:
    Sendable {

    func writeAtomically(
        _ data: Data,
        to url: URL
    ) throws
}

nonisolated struct FoundationLocalConfigurationLibraryAtomicWriter:
    LocalConfigurationLibraryAtomicWriting {

    func writeAtomically(
        _ data: Data,
        to url: URL
    ) throws {
        try data.write(to: url, options: .atomic)
    }
}

nonisolated private struct PreparedLocalConfigurationBackup:
    Sendable {

    let data: Data
    let subjectID: UUID
    let configurationID: UUID
    let revision: Int
    let savedAt: Date
    let checksum: String
}

nonisolated private struct StoredLocalConfigurationBackup:
    Sendable {

    let data: Data
    let fileURL: URL
    let configurationID: UUID
}

actor LocalConfigurationLibraryRepository {

    private let applicationSupportURL: URL
    private let atomicWriter:
        any LocalConfigurationLibraryAtomicWriting
    private var persistenceGateIsLocked = false
    private var persistenceGateWaiters:
        [CheckedContinuation<Void, Never>] = []

    init(
        applicationSupportURL: URL? = nil,
        atomicWriter:
            any LocalConfigurationLibraryAtomicWriting =
                FoundationLocalConfigurationLibraryAtomicWriter()
    ) {
        self.applicationSupportURL = applicationSupportURL
            ?? FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            )[0]
        self.atomicWriter = atomicWriter
    }

    nonisolated func save(
        _ document: PortableMemoryConfigurationDocument
    ) async throws -> LocalConfigurationBackupReceipt {
        let prepared = try await Self.prepare(document)
        let receipt = LocalConfigurationBackupReceipt(
            disposition: .saved,
            subjectID: prepared.subjectID,
            configurationID: prepared.configurationID,
            revision: prepared.revision,
            savedAt: prepared.savedAt,
            checksum: prepared.checksum,
            fileURL: configurationURLForPreparedBackup(
                subjectID: prepared.subjectID,
                configurationID: prepared.configurationID
            )
        )
        return try await persist(
            prepared.data,
            receipt: receipt
        )
    }

    private func persist(
        _ data: Data,
        receipt: LocalConfigurationBackupReceipt
    ) async throws -> LocalConfigurationBackupReceipt {
        await acquirePersistenceGate()
        defer { releasePersistenceGate() }

        if let existingReceipt = try await existingReceipt(
            matching: receipt
        ), receipt.revision < existingReceipt.revision {
            return LocalConfigurationBackupReceipt(
                disposition: .noOpRevisionConflict(
                    existingRevision: existingReceipt.revision,
                    attemptedRevision: receipt.revision
                ),
                subjectID: existingReceipt.subjectID,
                configurationID: existingReceipt.configurationID,
                revision: existingReceipt.revision,
                savedAt: existingReceipt.savedAt,
                checksum: existingReceipt.checksum,
                fileURL: existingReceipt.fileURL
            )
        }

        do {
            try FileManager.default.createDirectory(
                at: receipt.fileURL
                    .deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try atomicWriter.writeAtomically(
                data,
                to: receipt.fileURL
            )
        } catch {
            throw LocalConfigurationLibraryError.writeFailed(
                String(describing: error)
            )
        }
        return receipt
    }

    private func existingReceipt(
        matching receipt: LocalConfigurationBackupReceipt
    ) async throws -> LocalConfigurationBackupReceipt? {
        guard FileManager.default.fileExists(
            atPath: receipt.fileURL.path
        ) else {
            return nil
        }
        let stored = try storedBackup(
            subjectID: receipt.subjectID,
            configurationID: receipt.configurationID
        )
        let document: PortableMemoryConfigurationDocument
        do {
            document = try await Self.decodeAndValidate(
                stored,
                subjectID: receipt.subjectID
            )
        } catch {
            return nil
        }
        return LocalConfigurationBackupReceipt(
            disposition: .saved,
            subjectID: receipt.subjectID,
            configurationID: receipt.configurationID,
            revision: document.configuration.revision,
            savedAt: document.configuration.savedAt,
            checksum: document.documentChecksum,
            fileURL: receipt.fileURL
        )
    }

    nonisolated func load(
        subjectID: UUID,
        configurationID: UUID
    ) async throws -> PortableMemoryConfigurationDocument {
        let stored = try await storedBackup(
            subjectID: subjectID,
            configurationID: configurationID
        )
        return try await Self.decodeAndValidate(
            stored,
            subjectID: subjectID
        )
    }

    private func storedBackup(
        subjectID: UUID,
        configurationID: UUID
    ) throws -> StoredLocalConfigurationBackup {
        let fileURL = configurationURL(
            subjectID: subjectID,
            configurationID: configurationID
        )
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw LocalConfigurationLibraryError.backupNotFound(
                subjectID: subjectID,
                configurationID: configurationID
            )
        }

        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch {
            throw LocalConfigurationLibraryError.readFailed(
                String(describing: error)
            )
        }
        return StoredLocalConfigurationBackup(
            data: data,
            fileURL: fileURL,
            configurationID: configurationID
        )
    }

    nonisolated func list(
        subjectID: UUID
    ) async throws -> [LocalConfigurationBackupRecord] {
        let stored = try await storedBackups(
            subjectID: subjectID
        )
        return await Self.backupRecords(
            from: stored,
            subjectID: subjectID
        )
    }

    nonisolated func listAll()
    async throws -> [LocalConfigurationBackupRecord] {
        guard FileManager.default.fileExists(
            atPath: memorySubjectsRootURL.path
        ) else {
            return []
        }

        let subjectURLs: [URL]
        do {
            subjectURLs = try FileManager.default.contentsOfDirectory(
                at: memorySubjectsRootURL,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )
        } catch {
            throw LocalConfigurationLibraryError.readFailed(
                String(describing: error)
            )
        }

        var records: [LocalConfigurationBackupRecord] = []
        for subjectURL in subjectURLs {
            guard let subjectID = UUID(
                uuidString: subjectURL.lastPathComponent
            ) else {
                continue
            }
            do {
                records.append(
                    contentsOf: try await list(subjectID: subjectID)
                )
            } catch {
                continue
            }
        }
        return records.sorted {
            if $0.savedAt != $1.savedAt {
                return $0.savedAt > $1.savedAt
            }
            return $0.configurationID.uuidString
                > $1.configurationID.uuidString
        }
    }

    private func storedBackups(
        subjectID: UUID
    ) throws -> [StoredLocalConfigurationBackup] {
        let directoryURL = configurationsDirectoryURL(
            subjectID: subjectID
        )
        guard FileManager.default.fileExists(
            atPath: directoryURL.path
        ) else {
            return []
        }

        let fileURLs: [URL]
        do {
            fileURLs = try FileManager.default.contentsOfDirectory(
                at: directoryURL,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )
        } catch {
            throw LocalConfigurationLibraryError.readFailed(
                String(describing: error)
            )
        }

        return fileURLs
            .filter { $0.pathExtension == "memomarkconfig" }
            .compactMap { fileURL in
                guard let configurationID = UUID(
                    uuidString: fileURL.deletingPathExtension()
                        .lastPathComponent
                ) else {
                    return nil
                }
                return try? storedBackup(
                    subjectID: subjectID,
                    configurationID: configurationID
                )
            }
    }

    func deleteBackup(
        subjectID: UUID,
        configurationID: UUID
    ) throws -> LocalConfigurationBackupDeletionReceipt {
        let fileURL = configurationURL(
            subjectID: subjectID,
            configurationID: configurationID
        )
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw LocalConfigurationLibraryError.backupNotFound(
                subjectID: subjectID,
                configurationID: configurationID
            )
        }
        do {
            try FileManager.default.removeItem(at: fileURL)
        } catch {
            throw LocalConfigurationLibraryError.deleteFailed(
                String(describing: error)
            )
        }
        return LocalConfigurationBackupDeletionReceipt(
            subjectID: subjectID,
            configurationID: configurationID,
            fileURL: fileURL
        )
    }

    func referencedAssetPaths(
        subjectID: UUID
    ) async -> Set<String>? {
        let directoryURL = configurationsDirectoryURL(
            subjectID: subjectID
        )
        guard FileManager.default.fileExists(
            atPath: directoryURL.path
        ) else {
            return []
        }
        guard let fileURLs = try? FileManager.default
            .contentsOfDirectory(
                at: directoryURL,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )
        else {
            return nil
        }

        var paths: Set<String> = []
        for fileURL in fileURLs
        where fileURL.pathExtension == "memomarkconfig" {
            guard let configurationID = UUID(
                uuidString: fileURL.deletingPathExtension()
                    .lastPathComponent
            ),
            let stored = try? storedBackup(
                subjectID: subjectID,
                configurationID: configurationID
            ),
            let document = try? await Self.decodeAndValidate(
                stored,
                subjectID: subjectID
            ) else {
                return nil
            }
            paths.formUnion(
                document.assetManifest.entries.map {
                    $0.reference.relativePath
                }
            )
        }
        return paths
    }

    private func acquirePersistenceGate() async {
        guard persistenceGateIsLocked else {
            persistenceGateIsLocked = true
            return
        }
        await withCheckedContinuation {
            persistenceGateWaiters.append($0)
        }
    }

    private func releasePersistenceGate() {
        guard !persistenceGateWaiters.isEmpty else {
            persistenceGateIsLocked = false
            return
        }
        persistenceGateWaiters.removeFirst().resume()
    }

    nonisolated func subjectRootURL(
        subjectID: UUID
    ) -> URL {
        applicationSupportURL
            .appendingPathComponent("MemoMark", isDirectory: true)
            .appendingPathComponent(
                "MemorySubjects",
                isDirectory: true
            )
            .appendingPathComponent(
                subjectID.uuidString,
                isDirectory: true
            )
    }

    nonisolated private func configurationURLForPreparedBackup(
        subjectID: UUID,
        configurationID: UUID
    ) -> URL {
        subjectRootURL(subjectID: subjectID)
            .appendingPathComponent(
                "Configurations",
                isDirectory: true
            )
            .appendingPathComponent(
                "\(configurationID.uuidString).memomarkconfig"
            )
    }
}

private extension LocalConfigurationLibraryRepository {

    nonisolated var memorySubjectsRootURL: URL {
        applicationSupportURL
            .appendingPathComponent("MemoMark", isDirectory: true)
            .appendingPathComponent(
                "MemorySubjects",
                isDirectory: true
            )
    }

    func configurationsDirectoryURL(
        subjectID: UUID
    ) -> URL {
        subjectRootURL(subjectID: subjectID)
            .appendingPathComponent(
                "Configurations",
                isDirectory: true
            )
    }

    func configurationURL(
        subjectID: UUID,
        configurationID: UUID
    ) -> URL {
        configurationsDirectoryURL(subjectID: subjectID)
            .appendingPathComponent(
                "\(configurationID.uuidString).memomarkconfig"
            )
    }

    @MainActor
    static func prepare(
        _ document: PortableMemoryConfigurationDocument
    ) throws -> PreparedLocalConfigurationBackup {
        let canonical = document.canonicalizingLogoOwnership()
        try validate(canonical)
        let finalized = try documentWithChecksum(canonical)
        return PreparedLocalConfigurationBackup(
            data: try encode(finalized),
            subjectID: finalized.subject.id,
            configurationID: finalized.configuration.id,
            revision: finalized.configuration.revision,
            savedAt: finalized.configuration.savedAt,
            checksum: finalized.documentChecksum
        )
    }

    @MainActor
    static func decodeAndValidate(
        _ stored: StoredLocalConfigurationBackup,
        subjectID: UUID
    ) throws -> PortableMemoryConfigurationDocument {
        let document: PortableMemoryConfigurationDocument
        do {
            document = try JSONDecoder().decode(
                PortableMemoryConfigurationDocument.self,
                from: stored.data
            )
        } catch {
            throw LocalConfigurationLibraryError.readFailed(
                String(describing: error)
            )
        }
        let actualChecksum = try checksum(for: document)
        guard actualChecksum == document.documentChecksum else {
            throw LocalConfigurationLibraryError.checksumMismatch(
                expected: document.documentChecksum,
                actual: actualChecksum
            )
        }
        let canonical = document.canonicalizingLogoOwnership()
        try validate(canonical)
        let finalized = try documentWithChecksum(canonical)
        guard finalized.subject.id == subjectID,
              finalized.configuration.id == stored.configurationID
        else {
            throw LocalConfigurationLibraryError.pathIdentityMismatch(
                expectedSubjectID: subjectID,
                actualSubjectID: finalized.subject.id,
                expectedConfigurationID: stored.configurationID,
                actualConfigurationID: finalized.configuration.id
            )
        }
        return finalized
    }

    @MainActor
    static func backupRecords(
        from storedBackups: [StoredLocalConfigurationBackup],
        subjectID: UUID
    ) -> [LocalConfigurationBackupRecord] {
        storedBackups
            .compactMap { stored in
                guard let document = try? decodeAndValidate(
                    stored,
                    subjectID: subjectID
                ) else {
                    return nil
                }
                return LocalConfigurationBackupRecord(
                    subjectID: subjectID,
                    configurationID: stored.configurationID,
                    title: document.configuration.title,
                    revision: document.configuration.revision,
                    savedAt: document.configuration.savedAt,
                    checksum: document.documentChecksum,
                    fileURL: stored.fileURL
                )
            }
            .sorted {
                if $0.savedAt != $1.savedAt {
                    return $0.savedAt > $1.savedAt
                }
                return $0.configurationID.uuidString
                    > $1.configurationID.uuidString
            }
    }

    @MainActor
    static func validate(
        _ document: PortableMemoryConfigurationDocument
    ) throws {
        switch document.validationResult {
        case .valid:
            return
        case .invalid(let issues):
            throw LocalConfigurationLibraryError
                .invalidDocument(issues)
        }
    }

    @MainActor
    static func documentWithChecksum(
        _ document: PortableMemoryConfigurationDocument
    ) throws -> PortableMemoryConfigurationDocument {
        PortableMemoryConfigurationDocument(
            appVersion: document.appVersion,
            subject: document.subject,
            configuration: document.configuration,
            assetManifest: document.assetManifest,
            documentChecksum: try checksum(for: document)
        )
    }

    @MainActor
    static func checksum(
        for document: PortableMemoryConfigurationDocument
    ) throws -> String {
        let unsigned = PortableMemoryConfigurationDocument(
            appVersion: document.appVersion,
            subject: document.subject,
            configuration: document.configuration,
            assetManifest: document.assetManifest,
            documentChecksum: ""
        )
        let data = try encode(unsigned)
        return "sha256:\(SHA256.hash(data: data).hexString)"
    }

    @MainActor
    static func encode(
        _ document: PortableMemoryConfigurationDocument
    ) throws -> Data {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys]
            return try encoder.encode(document)
        } catch {
            throw LocalConfigurationLibraryError.encodingFailed(
                String(describing: error)
            )
        }
    }
}

private extension SHA256.Digest {

    nonisolated var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
}
#endif
