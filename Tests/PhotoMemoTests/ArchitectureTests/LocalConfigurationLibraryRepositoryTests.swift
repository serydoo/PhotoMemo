#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

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

    static func makeDocument(
        configurationID: UUID = UUID(
            uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
        )!,
        title: String,
        revision: Int,
        savedAt: Date
    ) -> PortableMemoryConfigurationDocument {
        PortableMemoryConfigurationDocument(
            appVersion: "1.6",
            subject: makeSubject(),
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

    static func makeSubject() -> MemorySubject {
        MemorySubject(
            id: UUID(
                uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"
            )!,
            identity: .init(displayName: "途途", shortName: "途途"),
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
#endif
