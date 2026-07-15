#if !PHOTOMEMO_SHARE_EXTENSION
import CryptoKit
import Foundation
import Testing
@testable import PhotoMemo

@Suite("Configuration backup restore coordinator")
struct ConfigurationBackupRestoreCoordinatorTests {

    @MainActor
    @Test("restore and make current reconciles revision and pairs security scope")
    func restoreAndMakeCurrentReconcilesRevision() async throws {
        let rootURL = Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        let documentURL = rootURL.appendingPathComponent("backup.memomarkconfig")
        let missingAvatar = try PortableAssetReference(
            relativePath: "Assets/missing-avatar.heic"
        )
        var importedSubject = Self.makeSubject(id: Self.importedSubjectID)
        importedSubject.identity.avatarImagePath = missingAvatar.relativePath
        let document = Self.signedDocument(
            subject: importedSubject,
            configuration: Self.makeConfiguration(
                id: Self.importedConfigurationID,
                title: "Restored"
            ),
            manifest: .init(entries: [
                .init(role: .subjectAvatar, reference: missingAvatar)
            ])
        )
        try Self.encode(document).write(to: documentURL)
        var startCount = 0
        var stopCount = 0
        var appliedAggregate: ConfigurationLibraryRecord?
        let coordinator = ConfigurationBackupRestoreCoordinator(
            dependencies: .init(
                backup: { _, _, _ in throw TestFailure.expected },
                listBackups: { _ in [] },
                deleteBackup: { _, _ in throw TestFailure.expected },
                saveAggregate: { aggregate in
                    appliedAggregate = aggregate
                    return Self.makeSaveReceipt(
                        revision: 42,
                        subjectID: Self.importedSubjectID,
                        configurationID: Self.importedConfigurationID
                    )
                },
                readData: { try Data(contentsOf: $0) },
                startSecurityScopedAccess: { _ in
                    startCount += 1
                    return true
                },
                stopSecurityScopedAccess: { _ in
                    stopCount += 1
                }
            )
        )

        let result = await coordinator.restore(
            .init(
                fileURL: documentURL,
                assetRootURL: rootURL,
                makeCurrent: true,
                aggregate: Self.makeAggregate(),
                availableAlbumIdentifiers: [],
                currentSubjectID: Self.liveSubjectID,
                previousBackups: []
            )
        )

        #expect(result.succeeded)
        #expect(result.aggregate?.revision == 42)
        #expect(
            result.aggregate?.activeSubjectID == Self.importedSubjectID
        )
        #expect(
            result.aggregate?.activeConfigurationID
            == Self.importedConfigurationID
        )
        #expect(
            appliedAggregate?.activeConfigurationID
            == Self.importedConfigurationID
        )
        #expect(result.shouldApplyCurrentConfiguration)
        #expect(
            result.warnings.contains(
                .missingAsset(
                    role: .subjectAvatar,
                    path: missingAvatar.relativePath
                )
            )
        )
        #expect(result.status == .replace("已恢复并设为当前配置。 部分缺失资源已使用安全回退。"))
        #expect(startCount == 1)
        #expect(stopCount == 1)
    }

    @MainActor
    @Test("restore copy preserves current selection and reconciles revision")
    func restoreCopyPreservesCurrentSelection() async throws {
        let document = Self.signedDocument(
            subject: Self.makeSubject(id: Self.importedSubjectID),
            configuration: Self.makeConfiguration(
                id: Self.importedConfigurationID,
                title: "Copy"
            )
        )
        let coordinator = ConfigurationBackupRestoreCoordinator(
            dependencies: .init(
                backup: { _, _, _ in throw TestFailure.expected },
                listBackups: { _ in [] },
                deleteBackup: { _, _ in throw TestFailure.expected },
                saveAggregate: { aggregate in
                    #expect(aggregate.activeSubjectID == Self.liveSubjectID)
                    #expect(
                        aggregate.activeConfigurationID
                        == Self.liveConfigurationID
                    )
                    return Self.makeSaveReceipt(revision: 19)
                },
                readData: { _ in try Self.encode(document) },
                startSecurityScopedAccess: { _ in false },
                stopSecurityScopedAccess: { _ in
                    Issue.record("Security scope should not stop when start returned false")
                }
            )
        )

        let result = await coordinator.restore(
            .init(
                fileURL: URL(fileURLWithPath: "/tmp/copy.memomarkconfig"),
                assetRootURL: nil,
                makeCurrent: false,
                aggregate: Self.makeAggregate(),
                availableAlbumIdentifiers: [],
                currentSubjectID: Self.liveSubjectID,
                previousBackups: []
            )
        )

        #expect(result.succeeded)
        #expect(result.aggregate?.revision == 19)
        #expect(result.aggregate?.activeSubjectID == Self.liveSubjectID)
        #expect(
            result.aggregate?.activeConfigurationID
            == Self.liveConfigurationID
        )
        #expect(!result.shouldApplyCurrentConfiguration)
        #expect(result.status == .replace("已恢复配置副本。"))
    }

    @MainActor
    @Test("read failure still balances security scope and retains backups")
    func readFailureBalancesScopeAndRetainsBackups() async {
        let previous = [Self.makeBackupRecord()]
        var stopCount = 0
        let coordinator = ConfigurationBackupRestoreCoordinator(
            dependencies: .init(
                backup: { _, _, _ in throw TestFailure.expected },
                listBackups: { _ in [] },
                deleteBackup: { _, _ in throw TestFailure.expected },
                saveAggregate: { _ in Self.makeSaveReceipt() },
                readData: { _ in throw TestFailure.expected },
                startSecurityScopedAccess: { _ in true },
                stopSecurityScopedAccess: { _ in stopCount += 1 }
            )
        )

        let result = await coordinator.restore(
            .init(
                fileURL: URL(fileURLWithPath: "/tmp/missing.memomarkconfig"),
                assetRootURL: nil,
                makeCurrent: true,
                aggregate: Self.makeAggregate(),
                availableAlbumIdentifiers: [],
                currentSubjectID: Self.liveSubjectID,
                previousBackups: previous
            )
        )

        #expect(!result.succeeded)
        #expect(result.backups == previous)
        #expect(result.aggregate == nil)
        #expect(result.status == .replace("导入或恢复失败：expected"))
        #expect(stopCount == 1)
    }

    @MainActor
    @Test("backup core success and list refresh success returns receipt")
    func backupCoreSuccessAndRefreshSuccess() async {
        let receipt = Self.makeBackupReceipt()
        let coordinator = ConfigurationBackupRestoreCoordinator(
            dependencies: .init(
                backup: { _, _, _ in receipt },
                listBackups: { _ in [] },
                deleteBackup: { _, _ in throw TestFailure.expected },
                saveAggregate: nil,
                readData: { _ in Data() },
                startSecurityScopedAccess: { _ in false },
                stopSecurityScopedAccess: { _ in }
            )
        )

        let result = await coordinator.backup(
            .init(
                subject: Self.makeSubject(id: Self.liveSubjectID),
                configuration: Self.makeConfiguration(
                    id: Self.liveConfigurationID,
                    title: "Stable"
                ),
                sourceURLs: [:],
                previousBackups: []
            )
        )

        #expect(result.succeeded)
        #expect(result.backupListRefreshSucceeded)
        #expect(result.receipt == receipt)
        #expect(
            result.status
            == .replace("已保存“Stable”版本 4 到本地配置库。")
        )
    }

    @MainActor
    @Test("backup core failure does not return a receipt")
    func backupCoreFailure() async {
        let coordinator = ConfigurationBackupRestoreCoordinator(
            dependencies: .init(
                backup: { _, _, _ in throw TestFailure.expected },
                listBackups: { _ in [] },
                deleteBackup: { _, _ in throw TestFailure.expected },
                saveAggregate: nil,
                readData: { _ in Data() },
                startSecurityScopedAccess: { _ in false },
                stopSecurityScopedAccess: { _ in }
            )
        )

        let result = await coordinator.backup(
            .init(
                subject: Self.makeSubject(id: Self.liveSubjectID),
                configuration: Self.makeConfiguration(
                    id: Self.liveConfigurationID,
                    title: "Stable"
                ),
                sourceURLs: [:],
                previousBackups: [Self.makeBackupRecord()]
            )
        )

        #expect(!result.succeeded)
        #expect(!result.backupListRefreshSucceeded)
        #expect(result.receipt == nil)
        #expect(result.backups == [Self.makeBackupRecord()])
    }

    @MainActor
    @Test("backup core success keeps receipt when list refresh fails")
    func backupCoreSuccessAndRefreshFailure() async {
        let receipt = Self.makeBackupReceipt()
        let previous = [Self.makeBackupRecord()]
        let coordinator = ConfigurationBackupRestoreCoordinator(
            dependencies: .init(
                backup: { _, _, _ in receipt },
                listBackups: { _ in throw TestFailure.expected },
                deleteBackup: { _, _ in throw TestFailure.expected },
                saveAggregate: nil,
                readData: { _ in Data() },
                startSecurityScopedAccess: { _ in false },
                stopSecurityScopedAccess: { _ in }
            )
        )

        let result = await coordinator.backup(
            .init(
                subject: Self.makeSubject(id: Self.liveSubjectID),
                configuration: Self.makeConfiguration(
                    id: Self.liveConfigurationID,
                    title: "Stable"
                ),
                sourceURLs: [:],
                previousBackups: previous
            )
        )

        #expect(result.succeeded)
        #expect(!result.backupListRefreshSucceeded)
        #expect(result.receipt == receipt)
        #expect(result.backups == previous)
        #expect(
            result.status
            == .replace("已完成备份，但本地备份列表刷新失败，请稍后刷新。")
        )
    }

    @MainActor
    @Test("restore success survives backup-list refresh failure")
    func restoreSuccessSurvivesRefreshFailure() async throws {
        let previous = [Self.makeBackupRecord()]
        let document = Self.signedDocument(
            subject: Self.makeSubject(id: Self.importedSubjectID),
            configuration: Self.makeConfiguration(
                id: Self.importedConfigurationID
            )
        )
        let coordinator = ConfigurationBackupRestoreCoordinator(
            dependencies: .init(
                backup: { _, _, _ in throw TestFailure.expected },
                listBackups: { _ in throw TestFailure.expected },
                deleteBackup: { _, _ in throw TestFailure.expected },
                saveAggregate: { _ in
                    Self.makeSaveReceipt(
                        revision: 31,
                        subjectID: Self.importedSubjectID,
                        configurationID: Self.importedConfigurationID
                    )
                },
                readData: { _ in try Self.encode(document) },
                startSecurityScopedAccess: { _ in false },
                stopSecurityScopedAccess: { _ in }
            )
        )

        let result = await coordinator.restore(
            .init(
                fileURL: URL(fileURLWithPath: "/tmp/refresh.memomarkconfig"),
                assetRootURL: nil,
                makeCurrent: true,
                aggregate: Self.makeAggregate(),
                availableAlbumIdentifiers: [],
                currentSubjectID: Self.liveSubjectID,
                previousBackups: previous
            )
        )

        #expect(result.succeeded)
        #expect(!result.backupListRefreshSucceeded)
        #expect(result.aggregate?.revision == 31)
        #expect(
            result.aggregate?.activeConfigurationID
            == Self.importedConfigurationID
        )
        #expect(result.shouldApplyCurrentConfiguration)
        #expect(result.backups == previous)
        #expect(
            result.status
            == .replace("已恢复并设为当前配置，但本地备份列表刷新失败，请稍后刷新。")
        )
    }

    @MainActor
    @Test("list and delete failures retain the previous backup list")
    func failuresRetainPreviousBackups() async {
        let previous = [Self.makeBackupRecord()]
        let coordinator = ConfigurationBackupRestoreCoordinator(
            dependencies: .init(
                backup: { _, _, _ in throw TestFailure.expected },
                listBackups: { _ in throw TestFailure.expected },
                deleteBackup: { _, _ in throw TestFailure.expected },
                saveAggregate: nil,
                readData: { _ in Data() },
                startSecurityScopedAccess: { _ in false },
                stopSecurityScopedAccess: { _ in }
            )
        )

        let listResult = await coordinator.listBackups(
            .init(subjectID: Self.liveSubjectID, previousBackups: previous)
        )
        let deleteResult = await coordinator.deleteBackup(
            .init(backup: previous[0], previousBackups: previous)
        )

        #expect(!listResult.succeeded)
        #expect(listResult.backups == previous)
        #expect(
            listResult.status
            == .replace("本地配置库操作失败：expected")
        )
        #expect(!deleteResult.succeeded)
        #expect(deleteResult.backups == previous)
        #expect(
            deleteResult.status
            == .replace("本地配置库操作失败：expected")
        )
    }

    @MainActor
    @Test("asset collection includes only existing absolute managed files")
    func assetCollectionUsesExistingManagedFiles() throws {
        let rootURL = Self.makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: rootURL) }
        let avatarURL = rootURL.appendingPathComponent("avatar.png")
        let logoURL = rootURL.appendingPathComponent("logo.png")
        try Data("avatar".utf8).write(to: avatarURL)
        try Data("logo".utf8).write(to: logoURL)
        var subject = Self.makeSubject(id: Self.liveSubjectID)
        subject.identity.avatarImagePath = avatarURL.path
        subject.identity.avatarBadgeImagePath = "relative/badge.png"

        let urls = ConfigurationBackupRestoreCoordinator.assetURLs(
            subject: subject,
            configuration: Self.makeConfiguration(
                id: Self.liveConfigurationID
            ),
            selectedConfigurationID: Self.liveConfigurationID,
            selectedCustomLogoPath: logoURL.path
        )

        #expect(urls == [
            .subjectAvatar: avatarURL,
            .customLogo: logoURL
        ])
    }
}

private extension ConfigurationBackupRestoreCoordinatorTests {

    enum TestFailure: Error, LocalizedError {
        case expected

        var errorDescription: String? { "expected" }
    }

    static let liveSubjectID = UUID(
        uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"
    )!
    static let importedSubjectID = UUID(
        uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
    )!
    static let liveConfigurationID = UUID(
        uuidString: "11111111-1111-1111-1111-111111111111"
    )!
    static let importedConfigurationID = UUID(
        uuidString: "22222222-2222-2222-2222-222222222222"
    )!

    static func makeTemporaryDirectory() -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(
            at: url,
            withIntermediateDirectories: true
        )
        return url
    }

    static func makeAggregate() -> ConfigurationLibraryRecord {
        ConfigurationLibraryRecord(
            revision: 7,
            subjects: [
                .init(
                    subject: makeSubject(id: liveSubjectID),
                    configurations: [
                        makeConfiguration(
                            id: liveConfigurationID,
                            title: "Current",
                            revision: 4
                        )
                    ],
                    assetManifest: .init(entries: [])
                )
            ],
            activeSubjectID: liveSubjectID,
            activeConfigurationID: liveConfigurationID
        )
    }

    static func makeSubject(id: UUID) -> MemorySubject {
        MemorySubject(
            id: id,
            identity: .init(displayName: "小宝", shortName: "小宝"),
            relationship: .init(role: "family", label: "成长记录"),
            referenceDate: Date(timeIntervalSince1970: 0),
            timeAnchors: [],
            activeTimeAnchorID: nil,
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
        title: String = "Imported",
        revision: Int = 3
    ) -> MemoryConfigurationRecord {
        MemoryConfigurationRecord(
            id: id,
            title: title,
            revision: revision,
            savedAt: Date(timeIntervalSince1970: 300),
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

    static func signedDocument(
        subject: MemorySubject,
        configuration: MemoryConfigurationRecord,
        manifest: PortableAssetManifest
    ) -> PortableMemoryConfigurationDocument {
        let unsigned = PortableMemoryConfigurationDocument(
            appVersion: "1.7",
            subject: subject,
            configuration: configuration,
            assetManifest: manifest,
            documentChecksum: ""
        )
        let checksum = "sha256:\(SHA256.hash(data: try! encode(unsigned)).hexString)"
        return PortableMemoryConfigurationDocument(
            appVersion: unsigned.appVersion,
            subject: unsigned.subject,
            configuration: unsigned.configuration,
            assetManifest: unsigned.assetManifest,
            documentChecksum: checksum
        )
    }

    static func signedDocument(
        subject: MemorySubject,
        configuration: MemoryConfigurationRecord
    ) -> PortableMemoryConfigurationDocument {
        signedDocument(
            subject: subject,
            configuration: configuration,
            manifest: .init(entries: [])
        )
    }

    static func encode(
        _ document: PortableMemoryConfigurationDocument
    ) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(document)
    }

    static func makeSaveReceipt(
        revision: Int = 8,
        subjectID: UUID = liveSubjectID,
        configurationID: UUID = liveConfigurationID
    ) -> ConfigurationLibrarySaveReceipt {
        ConfigurationLibrarySaveReceipt(
            revision: revision,
            subjectID: subjectID,
            configurationID: configurationID,
            configurationRevision: 4,
            compatibilityProjectionFailure: nil
        )
    }

    static func makeBackupReceipt() -> LocalConfigurationBackupReceipt {
        LocalConfigurationBackupReceipt(
            disposition: .saved,
            subjectID: liveSubjectID,
            configurationID: liveConfigurationID,
            revision: 4,
            savedAt: Date(timeIntervalSince1970: 100),
            checksum: "sha256:test",
            fileURL: URL(fileURLWithPath: "/tmp/stable.memomarkconfig")
        )
    }

    static func makeBackupRecord() -> LocalConfigurationBackupRecord {
        LocalConfigurationBackupRecord(
            subjectID: liveSubjectID,
            configurationID: liveConfigurationID,
            title: "Stable",
            revision: 4,
            savedAt: Date(timeIntervalSince1970: 100),
            checksum: "sha256:test",
            fileURL: URL(fileURLWithPath: "/tmp/stable.memomarkconfig")
        )
    }
}

private extension SHA256.Digest {
    nonisolated var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
}
#endif
