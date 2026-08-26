#if !MEMOMARK_SHARE_EXTENSION
import CryptoKit
import Foundation
import Testing
@testable import MemoMark

@Suite("Local configuration library repository")
struct LocalConfigurationLibraryRepositoryTests {

    @Test("backup uses subject UUID path, atomically replaces, and validates checksum")
    func savesAtSubjectPathAndReplacesAtomically() async throws {
        let rootURL = Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        let repository = LocalConfigurationLibraryRepository(
            applicationSupportURL: rootURL
        )
        let firstDocument = Self.makeDocument(
            title: "First",
            revision: 4,
            savedAt: Date(timeIntervalSince1970: 100)
        )

        let firstReceipt = try await repository.save(firstDocument)
        let secondReceipt = try await repository.save(
            Self.makeDocument(
                title: "Second",
                revision: 5,
                savedAt: Date(timeIntervalSince1970: 200)
            )
        )
        let stored = try await repository.load(
            subjectID: firstDocument.subject.id,
            configurationID: firstDocument.configuration.id
        )
        let expectedURL = rootURL
            .appendingPathComponent("MemoMark")
            .appendingPathComponent("MemorySubjects")
            .appendingPathComponent(
                firstDocument.subject.id.uuidString
            )
            .appendingPathComponent("Configurations")
            .appendingPathComponent(
                "\(firstDocument.configuration.id.uuidString).memomarkconfig"
            )

        #expect(firstReceipt.fileURL == expectedURL)
        #expect(secondReceipt.fileURL == expectedURL)
        #expect(secondReceipt.revision == 5)
        #expect(secondReceipt.checksum.hasPrefix("sha256:"))
        #expect(stored.configuration.title == "Second")
        #expect(stored.documentChecksum == secondReceipt.checksum)
        #expect(firstReceipt.checksum != secondReceipt.checksum)
        #expect(
            try FileManager.default.contentsOfDirectory(
                atPath: expectedURL.deletingLastPathComponent().path
            ) == [expectedURL.lastPathComponent]
        )

        let storedJSON = try #require(
            String(
                data: Data(contentsOf: expectedURL),
                encoding: .utf8
            )
        )
        let tamperedJSON = storedJSON.replacingOccurrences(
            of: "Second",
            with: "Tamper"
        )
        try Data(tamperedJSON.utf8).write(
            to: expectedURL,
            options: .atomic
        )
        do {
            _ = try await repository.load(
                subjectID: firstDocument.subject.id,
                configurationID: firstDocument.configuration.id
            )
            Issue.record("Expected checksum mismatch")
        } catch let error as LocalConfigurationLibraryError {
            guard case .checksumMismatch = error else {
                Issue.record("Unexpected error: \(error)")
                return
            }
        }
    }

    @Test("legacy subject-avatar backups repair duplicate custom-logo ownership after checksum validation")
    func legacySubjectAvatarBackupRepairsDuplicateLogoOwnership() async throws {
        let rootURL = Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        let repository = LocalConfigurationLibraryRepository(
            applicationSupportURL: rootURL
        )
        var subject = Self.makeSubject()
        let avatarReference = try PortableAssetReference(
            relativePath: "Assets/subjectAvatarBadge/avatar.png"
        )
        subject.identity.avatarBadgeImagePath =
            avatarReference.relativePath
        var configuration = Self.makeConfiguration(
            id: UUID(
                uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
            )!,
            title: "Legacy Subject Avatar",
            revision: 4,
            savedAt: Date(timeIntervalSince1970: 100)
        )
        configuration.presentation.logo = .init(
            mode: .subjectAvatar,
            badge: .init(
                id: UUID(),
                name: OptimizedSubjectAvatarAsset
                    .subjectAvatarBadgeName,
                type: .customUpload,
                assetReference: avatarReference
            )
        )
        let unsigned = PortableMemoryConfigurationDocument(
            appVersion: "2.1.2",
            subject: subject,
            configuration: configuration,
            assetManifest: .init(entries: [
                .init(
                    role: .subjectAvatarBadge,
                    reference: avatarReference
                ),
                .init(
                    role: .customLogo,
                    reference: avatarReference
                )
            ]),
            documentChecksum: ""
        )
        let unsignedData = try Self.stableEncode(unsigned)
        let document = PortableMemoryConfigurationDocument(
            appVersion: unsigned.appVersion,
            subject: unsigned.subject,
            configuration: unsigned.configuration,
            assetManifest: unsigned.assetManifest,
            documentChecksum:
                "sha256:\(SHA256.hash(data: unsignedData).hexString)"
        )
        let configurationURL = rootURL
            .appendingPathComponent("MemoMark")
            .appendingPathComponent("MemorySubjects")
            .appendingPathComponent(subject.id.uuidString)
            .appendingPathComponent("Configurations")
            .appendingPathComponent(
                "\(configuration.id.uuidString).memomarkconfig"
            )
        try FileManager.default.createDirectory(
            at: configurationURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Self.stableEncode(document).write(
            to: configurationURL,
            options: .atomic
        )

        let loaded = try await repository.load(
            subjectID: subject.id,
            configurationID: configuration.id
        )

        #expect(loaded.configuration.presentation.logo.mode == .subjectAvatar)
        #expect(loaded.configuration.presentation.logo.badge == nil)
        #expect(
            loaded.assetManifest.entries.map(\.role)
            == [.subjectAvatarBadge]
        )
        #expect(loaded.documentChecksum != document.documentChecksum)
        let loadedUnsigned = PortableMemoryConfigurationDocument(
            appVersion: loaded.appVersion,
            subject: loaded.subject,
            configuration: loaded.configuration,
            assetManifest: loaded.assetManifest,
            documentChecksum: ""
        )
        #expect(
            loaded.documentChecksum
            == "sha256:\(SHA256.hash(data: try Self.stableEncode(loadedUnsigned)).hexString)"
        )
    }

    @Test("lower revision save is a no-op and preserves the newer backup")
    func lowerRevisionDoesNotReplaceNewerBackup() async throws {
        let rootURL = Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        let repository = LocalConfigurationLibraryRepository(
            applicationSupportURL: rootURL
        )
        let newer = Self.makeDocument(
            title: "Newer",
            revision: 8,
            savedAt: Date(timeIntervalSince1970: 200)
        )
        let older = Self.makeDocument(
            title: "Older",
            revision: 7,
            savedAt: Date(timeIntervalSince1970: 100)
        )

        let newerReceipt = try await repository.save(newer)
        let olderReceipt = try await repository.save(older)
        let stored = try await repository.load(
            subjectID: newer.subject.id,
            configurationID: newer.configuration.id
        )

        #expect(stored.configuration.title == "Newer")
        #expect(stored.configuration.revision == 8)
        #expect(olderReceipt.revision == newerReceipt.revision)
        #expect(olderReceipt.savedAt == newerReceipt.savedAt)
        #expect(olderReceipt.checksum == newerReceipt.checksum)
        #expect(
            olderReceipt.disposition
            == .noOpRevisionConflict(
                existingRevision: 8,
                attemptedRevision: 7
            )
        )
    }

    @Test("failed atomic replacement preserves the previous backup and assets")
    func failedReplacementPreservesPreviousBackupAndAssets() async throws {
        let rootURL = Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        let writer = ToggleLocalConfigurationLibraryAtomicWriter()
        let repository = LocalConfigurationLibraryRepository(
            applicationSupportURL: rootURL,
            atomicWriter: writer
        )
        let coordinator = LocalConfigurationLibraryCoordinator(
            repository: repository,
            appVersion: "1.6"
        )
        try FileManager.default.createDirectory(
            at: rootURL,
            withIntermediateDirectories: true
        )
        let sourceURL = rootURL.appendingPathComponent("avatar.png")
        try FileManager.default.createDirectory(
            at: rootURL,
            withIntermediateDirectories: true
        )
        try Data("old-avatar".utf8).write(to: sourceURL)
        let subject = Self.makeSubject()
        let configuration = Self.makeConfiguration(
            id: UUID(
                uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
            )!,
            title: "Stable",
            revision: 4,
            savedAt: Date(timeIntervalSince1970: 100)
        )
        _ = try await coordinator.backup(
            subject: subject,
            configuration: configuration,
            sourceURLs: [.subjectAvatar: sourceURL]
        )

        try Data("new-avatar".utf8).write(
            to: sourceURL,
            options: .atomic
        )
        writer.failNextWrite()
        do {
            var replacement = configuration
            replacement.title = "Rejected"
            replacement.revision = 5
            replacement.savedAt = Date(timeIntervalSince1970: 200)
            _ = try await coordinator.backup(
                subject: subject,
                configuration: replacement,
                sourceURLs: [.subjectAvatar: sourceURL]
            )
            Issue.record("Expected typed write failure")
        } catch let error as LocalConfigurationLibraryError {
            guard case .writeFailed(let description) = error else {
                Issue.record("Unexpected error: \(error)")
                return
            }
            #expect(description == "forced atomic write failure")
        }

        let stored = try await repository.load(
            subjectID: subject.id,
            configurationID: configuration.id
        )
        let restored = try await coordinator.restore(
            subjectID: subject.id,
            configurationID: configuration.id,
            destinationRootURL: rootURL.appendingPathComponent("Restored")
        )
        let restoredAvatarURL = try #require(
            restored.assetURL(for: .subjectAvatar)
        )

        #expect(stored.configuration.title == "Stable")
        #expect(stored.configuration.revision == 4)
        #expect(
            try Data(contentsOf: restoredAvatarURL)
            == Data("old-avatar".utf8)
        )
    }

    @Test("concurrent saves retain the highest configuration revision")
    func concurrentSavesRetainHighestRevision() async throws {
        let rootURL = Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        let repository = LocalConfigurationLibraryRepository(
            applicationSupportURL: rootURL
        )
        let seed = Self.makeDocument(
            title: "Seed",
            revision: 8,
            savedAt: Date(timeIntervalSince1970: 8)
        )
        _ = try await repository.save(seed)

        await withTaskGroup(of: Void.self) { group in
            for revision in stride(from: 40, through: 9, by: -1) {
                group.addTask {
                    _ = try? await repository.save(
                        Self.makeDocument(
                            title: "Revision \(revision)",
                            revision: revision,
                            savedAt: Date(
                                timeIntervalSince1970: TimeInterval(revision)
                            )
                        )
                    )
                }
            }
        }

        let stored = try await repository.load(
            subjectID: seed.subject.id,
            configurationID: seed.configuration.id
        )
        #expect(stored.configuration.revision == 40)
        #expect(stored.configuration.title == "Revision 40")
    }

    @Test("list is newest first and backup deletion is isolated from live state")
    func listsNewestFirstAndKeepsLiveDeletionSeparate() async throws {
        let rootURL = Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        let repository = LocalConfigurationLibraryRepository(
            applicationSupportURL: rootURL
        )
        let coordinator = LocalConfigurationLibraryCoordinator(
            repository: repository,
            appVersion: "1.6"
        )
        let older = Self.makeDocument(
            configurationID: UUID(
                uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBB1"
            )!,
            title: "Older",
            revision: 2,
            savedAt: Date(timeIntervalSince1970: 100)
        )
        let newer = Self.makeDocument(
            configurationID: UUID(
                uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBB2"
            )!,
            title: "Newer",
            revision: 3,
            savedAt: Date(timeIntervalSince1970: 200)
        )
        _ = try await repository.save(older)
        _ = try await repository.save(newer)

        var liveConfigurationIDs: Set<UUID> = [
            older.configuration.id,
            newer.configuration.id
        ]
        liveConfigurationIDs.remove(newer.configuration.id)
        let afterLiveDeletion = try await coordinator.listBackups(
            subjectID: older.subject.id
        )

        #expect(
            afterLiveDeletion.map(\.configurationID) == [
                newer.configuration.id,
                older.configuration.id
            ]
        )
        #expect(!liveConfigurationIDs.contains(newer.configuration.id))
        #expect(
            afterLiveDeletion.contains {
                $0.configurationID == newer.configuration.id
            }
        )

        let deletionReceipt = try await coordinator.deleteBackup(
            subjectID: older.subject.id,
            configurationID: newer.configuration.id
        )
        let remaining = try await repository.list(
            subjectID: older.subject.id
        )

        #expect(deletionReceipt.configurationID == newer.configuration.id)
        #expect(remaining.map(\.configurationID) == [older.configuration.id])
        #expect(liveConfigurationIDs.contains(older.configuration.id))
    }

    @Test("list all keeps backups discoverable without a current subject")
    func listAllKeepsBackupsDiscoverableWithoutCurrentSubject() async throws {
        let rootURL = Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        let repository = LocalConfigurationLibraryRepository(
            applicationSupportURL: rootURL
        )
        let firstSubjectID = UUID(
            uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAA1"
        )!
        let secondSubjectID = UUID(
            uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAA2"
        )!
        let older = Self.makeDocument(
            subjectID: firstSubjectID,
            configurationID: UUID(
                uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBB1"
            )!,
            title: "Older Subject",
            revision: 2,
            savedAt: Date(timeIntervalSince1970: 100)
        )
        let newer = Self.makeDocument(
            subjectID: secondSubjectID,
            configurationID: UUID(
                uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBB2"
            )!,
            title: "Newer Subject",
            revision: 3,
            savedAt: Date(timeIntervalSince1970: 200)
        )
        _ = try await repository.save(older)
        _ = try await repository.save(newer)

        let records = try await repository.listAll()

        #expect(records.map(\.subjectID) == [secondSubjectID, firstSubjectID])
        #expect(records.map(\.title) == ["Newer Subject", "Older Subject"])
    }

    @Test("list skips malformed and corrupted backups without hiding healthy records")
    func listSkipsMalformedAndCorruptedBackups() async throws {
        let rootURL = Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        let repository = LocalConfigurationLibraryRepository(
            applicationSupportURL: rootURL
        )
        let healthy = Self.makeDocument(
            title: "Healthy",
            revision: 3,
            savedAt: Date(timeIntervalSince1970: 300)
        )
        _ = try await repository.save(healthy)
        let configurationsURL = repository.subjectRootURL(
            subjectID: healthy.subject.id
        ).appendingPathComponent("Configurations")
        try Data("not-json".utf8).write(
            to: configurationsURL.appendingPathComponent(
                "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC.memomarkconfig"
            )
        )
        try Data("not-json".utf8).write(
            to: configurationsURL.appendingPathComponent(
                "not-a-uuid.memomarkconfig"
            )
        )

        let records = try await repository.list(
            subjectID: healthy.subject.id
        )

        #expect(records.map(\.configurationID) == [healthy.configuration.id])
    }

    @Test("list all isolates a corrupted subject and keeps other subjects visible")
    func listAllIsolatesCorruptedSubject() async throws {
        let rootURL = Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        let repository = LocalConfigurationLibraryRepository(
            applicationSupportURL: rootURL
        )
        let healthy = Self.makeDocument(
            subjectID: UUID(
                uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAA1"
            )!,
            title: "Healthy",
            revision: 3,
            savedAt: Date(timeIntervalSince1970: 300)
        )
        _ = try await repository.save(healthy)
        let corruptedSubjectID = UUID(
            uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAA2"
        )!
        let corruptedDirectory = repository.subjectRootURL(
            subjectID: corruptedSubjectID
        ).appendingPathComponent("Configurations")
        try FileManager.default.createDirectory(
            at: corruptedDirectory,
            withIntermediateDirectories: true
        )
        try Data("not-json".utf8).write(
            to: corruptedDirectory.appendingPathComponent(
                "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC.memomarkconfig"
            )
        )

        let records = try await repository.listAll()

        #expect(records.map(\.configurationID) == [healthy.configuration.id])
    }

    @Test("a newer valid revision replaces a corrupted existing backup")
    func newerRevisionReplacesCorruptedExistingBackup() async throws {
        let rootURL = Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        let repository = LocalConfigurationLibraryRepository(
            applicationSupportURL: rootURL
        )
        let original = Self.makeDocument(
            title: "Original",
            revision: 4,
            savedAt: Date(timeIntervalSince1970: 400)
        )
        let originalReceipt = try await repository.save(original)
        try Data("corrupted".utf8).write(
            to: originalReceipt.fileURL,
            options: .atomic
        )
        let replacement = Self.makeDocument(
            title: "Recovered",
            revision: 5,
            savedAt: Date(timeIntervalSince1970: 500)
        )

        let receipt = try await repository.save(replacement)
        let stored = try await repository.load(
            subjectID: replacement.subject.id,
            configurationID: replacement.configuration.id
        )

        #expect(receipt.disposition == .saved)
        #expect(stored.configuration.title == "Recovered")
        #expect(stored.configuration.revision == 5)
    }

    @Test("failed document save removes only newly written orphan assets")
    func failedDocumentSaveRemovesNewlyWrittenOrphanAssets() async throws {
        let rootURL = Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        let writer = ToggleLocalConfigurationLibraryAtomicWriter()
        let repository = LocalConfigurationLibraryRepository(
            applicationSupportURL: rootURL,
            atomicWriter: writer
        )
        let coordinator = LocalConfigurationLibraryCoordinator(
            repository: repository,
            appVersion: "1.7"
        )
        try FileManager.default.createDirectory(
            at: rootURL,
            withIntermediateDirectories: true
        )
        let sourceURL = rootURL.appendingPathComponent("avatar.png")
        try Data("orphan".utf8).write(to: sourceURL)
        writer.failNextWrite()

        do {
            _ = try await coordinator.backup(
                subject: Self.makeSubject(),
                configuration: Self.makeConfiguration(
                    id: UUID(
                        uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
                    )!,
                    title: "Rejected",
                    revision: 4,
                    savedAt: Date(timeIntervalSince1970: 400)
                ),
                sourceURLs: [.subjectAvatar: sourceURL]
            )
            Issue.record("Expected document write failure")
        } catch {
            #expect(error is LocalConfigurationLibraryError)
        }

        let assetsURL = repository.subjectRootURL(
            subjectID: Self.makeSubject().id
        ).appendingPathComponent("Assets")
        let assetFiles = FileManager.default.enumerator(
            at: assetsURL,
            includingPropertiesForKeys: nil
        )?.allObjects.compactMap { $0 as? URL }.filter {
            !$0.hasDirectoryPath
        } ?? []
        #expect(assetFiles.isEmpty)
    }

    @Test("lower revision no-op removes newly written unreferenced assets")
    func lowerRevisionNoOpRemovesNewlyWrittenAssets() async throws {
        let rootURL = Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        let repository = LocalConfigurationLibraryRepository(
            applicationSupportURL: rootURL
        )
        let coordinator = LocalConfigurationLibraryCoordinator(
            repository: repository,
            appVersion: "1.7"
        )
        try FileManager.default.createDirectory(
            at: rootURL,
            withIntermediateDirectories: true
        )
        let sourceURL = rootURL.appendingPathComponent("avatar.png")
        let subject = Self.makeSubject()
        let newer = Self.makeConfiguration(
            id: UUID(
                uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
            )!,
            title: "Newer",
            revision: 8,
            savedAt: Date(timeIntervalSince1970: 800)
        )
        try Data("newer-avatar".utf8).write(to: sourceURL)
        _ = try await coordinator.backup(
            subject: subject,
            configuration: newer,
            sourceURLs: [.subjectAvatar: sourceURL]
        )
        try Data("rejected-avatar".utf8).write(
            to: sourceURL,
            options: .atomic
        )
        let older = Self.makeConfiguration(
            id: newer.id,
            title: "Older",
            revision: 7,
            savedAt: Date(timeIntervalSince1970: 700)
        )

        let receipt = try await coordinator.backup(
            subject: subject,
            configuration: older,
            sourceURLs: [.subjectAvatar: sourceURL]
        )
        let assetsURL = repository.subjectRootURL(
            subjectID: subject.id
        ).appendingPathComponent("Assets")
        let assetFiles = FileManager.default.enumerator(
            at: assetsURL,
            includingPropertiesForKeys: nil
        )?.allObjects.compactMap { $0 as? URL }.filter {
            !$0.hasDirectoryPath
        } ?? []

        #expect(
            receipt.disposition
            == .noOpRevisionConflict(
                existingRevision: 8,
                attemptedRevision: 7
            )
        )
        #expect(assetFiles.count == 1)
        #expect(try Data(contentsOf: assetFiles[0]) == Data("newer-avatar".utf8))
    }

    @Test("deleting backups collects assets only after their last reference")
    func deletingBackupsCollectsOnlyUnreferencedAssets() async throws {
        let rootURL = Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        let repository = LocalConfigurationLibraryRepository(
            applicationSupportURL: rootURL
        )
        let coordinator = LocalConfigurationLibraryCoordinator(
            repository: repository,
            appVersion: "1.7"
        )
        try FileManager.default.createDirectory(
            at: rootURL,
            withIntermediateDirectories: true
        )
        let sourceURL = rootURL.appendingPathComponent("shared-avatar.png")
        try Data("shared".utf8).write(to: sourceURL)
        let subject = Self.makeSubject()
        let first = Self.makeConfiguration(
            id: UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBB1")!,
            title: "First",
            revision: 3,
            savedAt: Date(timeIntervalSince1970: 300)
        )
        let second = Self.makeConfiguration(
            id: UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBB2")!,
            title: "Second",
            revision: 4,
            savedAt: Date(timeIntervalSince1970: 400)
        )
        _ = try await coordinator.backup(
            subject: subject,
            configuration: first,
            sourceURLs: [.subjectAvatar: sourceURL]
        )
        _ = try await coordinator.backup(
            subject: subject,
            configuration: second,
            sourceURLs: [.subjectAvatar: sourceURL]
        )
        let assetURL = try #require(
            FileManager.default.enumerator(
                at: repository.subjectRootURL(subjectID: subject.id)
                    .appendingPathComponent("Assets"),
                includingPropertiesForKeys: nil
            )?.allObjects.compactMap { $0 as? URL }.first {
                !$0.hasDirectoryPath
            }
        )

        _ = try await coordinator.deleteBackup(
            subjectID: subject.id,
            configurationID: first.id
        )
        #expect(FileManager.default.fileExists(atPath: assetURL.path))

        _ = try await coordinator.deleteBackup(
            subjectID: subject.id,
            configurationID: second.id
        )
        #expect(!FileManager.default.fileExists(atPath: assetURL.path))
    }
}

nonisolated final class ToggleLocalConfigurationLibraryAtomicWriter:
    LocalConfigurationLibraryAtomicWriting,
    @unchecked Sendable {

    private let lock = NSLock()
    private var shouldFail = false

    func failNextWrite() {
        lock.lock()
        shouldFail = true
        lock.unlock()
    }

    func writeAtomically(
        _ data: Data,
        to url: URL
    ) throws {
        lock.lock()
        let fails = shouldFail
        shouldFail = false
        lock.unlock()

        if fails {
            throw LocalConfigurationLibraryAtomicWriterTestError.forced
        }
        try data.write(to: url, options: .atomic)
    }
}

nonisolated enum LocalConfigurationLibraryAtomicWriterTestError:
    Error,
    CustomStringConvertible {

    case forced

    var description: String {
        "forced atomic write failure"
    }
}

private extension LocalConfigurationLibraryRepositoryTests {

    static func makeTemporaryDirectory() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
    }

    static func stableEncode<Value: Encodable>(
        _ value: Value
    ) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(value)
    }

    static func makeDocument(
        subjectID: UUID = UUID(
            uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"
        )!,
        configurationID: UUID = UUID(
            uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
        )!,
        title: String,
        revision: Int,
        savedAt: Date
    ) -> PortableMemoryConfigurationDocument {
        PortableMemoryConfigurationDocument(
            appVersion: "1.6",
            subject: makeSubject(id: subjectID),
            configuration: makeConfiguration(
                id: configurationID,
                title: title,
                revision: revision,
                savedAt: savedAt
            ),
            assetManifest: .init(entries: []),
            documentChecksum: "pending"
        )
    }

    static func makeSubject(
        id: UUID = UUID(
            uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"
        )!
    ) -> MemorySubject {
        MemorySubject(
            id: id,
            identity: .init(displayName: "小宝", shortName: "小宝"),
            relationship: .init(role: "family", label: "成长记录"),
            referenceDate: Date(timeIntervalSince1970: 0),
            behavior: .init(
                primaryAnchor: "生日",
                iconStrategy: .autoMatch,
                badgeStrategy: .fixed,
                memoryExpression: .init(title: "默认表达", blocks: [])
            ),
            decorations: []
        )
    }

    static func makeConfiguration(
        id: UUID,
        title: String,
        revision: Int,
        savedAt: Date
    ) -> MemoryConfigurationRecord {
        MemoryConfigurationRecord(
            id: id,
            title: title,
            revision: revision,
            savedAt: savedAt,
            selectedTimeAnchorID: nil,
            editor: .init(
                template: .classicWhite,
                regionTemplateIDs: [:],
                memoryCopy: .init(usesCustomText: false, customText: "")
            ),
            presentation: .init(
                route: .classicWhite,
                locationConfiguration: nil,
                logo: .init(mode: .appleMini, badge: nil)
            ),
            output: .init(
                mediaMode: .originalFormat,
                livePhotoPolicy: .preserveMotion,
                photosDescriptionPolicy: .init(
                    isEnabled: false,
                    overrideText: ""
                ),
                album: .automatic
            )
        )
    }
}

private extension SHA256.Digest {

    nonisolated var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
}
#endif
